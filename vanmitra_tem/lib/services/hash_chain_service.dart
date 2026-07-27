import 'dart:convert';
import 'package:crypto/crypto.dart';

/// Real SHA-256 hash-chaining service for the Gram Sabha Resolution Ledger
///
/// Implements: Hₙ = SHA256(Hₙ₋₁ ∥ Dₙ ∥ tₙ)
/// where:
///   Hₙ₋₁ = previous record hash
///   Dₙ = current resolution data (decision text, attendance, quorum status)
///   tₙ = timestamp
///   ∥ = concatenation
///   H₀ = fixed genesis hash for the village's ledger
///
/// Source: VanMitra-AI Technical Report, Section 8.3
class HashChainService {
  /// Create the genesis block (H₀) for a village's ledger
  ///
  /// H₀ = SHA256("VANMITRA_GENESIS_" + villageId + "_" + timestamp)
  ///
  /// This is the root of the chain. All subsequent resolutions
  /// are linked to this genesis hash.
  HashBlock createGenesisBlock({
    required String villageId,
    DateTime? genesisTime,
  }) {
    final timestamp = genesisTime ?? DateTime.now();
    final genesisData = 'VANMITRA_GENESIS_${villageId}_${timestamp.toIso8601String()}';
    final hash = _computeSHA256(genesisData);

    return HashBlock(
      index: 0,
      hash: hash,
      previousHash: '0' * 64, // Genesis has no predecessor
      data: genesisData,
      timestamp: timestamp,
      villageId: villageId,
      isGenesis: true,
    );
  }

  /// Add a new resolution block to the chain
  ///
  /// Hₙ = SHA256(Hₙ₋₁ ∥ Dₙ ∥ tₙ)
  ///
  /// The data payload Dₙ contains:
  /// - Resolution text
  /// - Resolution type
  /// - Attendance snapshot (total, women, ST, PVTG)
  /// - Quorum validity flag
  /// - Compliance flag
  HashBlock addBlock({
    required HashBlock previousBlock,
    required String resolutionId,
    required String resolutionText,
    required String resolutionType,
    required int totalPresent,
    required int totalRegistered,
    required int womenPresent,
    required int stPresent,
    required int pvtgPresent,
    required bool quorumValid,
    required bool isCompliant,
    required String villageId,
    DateTime? blockTime,
  }) {
    final timestamp = blockTime ?? DateTime.now();

    // Construct the data payload Dₙ
    final dataPayload = _buildDataPayload(
      resolutionId: resolutionId,
      resolutionText: resolutionText,
      resolutionType: resolutionType,
      totalPresent: totalPresent,
      totalRegistered: totalRegistered,
      womenPresent: womenPresent,
      stPresent: stPresent,
      pvtgPresent: pvtgPresent,
      quorumValid: quorumValid,
      isCompliant: isCompliant,
    );

    // Compute Hₙ = SHA256(Hₙ₋₁ ∥ Dₙ ∥ tₙ)
    final hashInput =
        '${previousBlock.hash}||$dataPayload||${timestamp.toIso8601String()}';
    final hash = _computeSHA256(hashInput);

    return HashBlock(
      index: previousBlock.index + 1,
      hash: hash,
      previousHash: previousBlock.hash,
      data: dataPayload,
      timestamp: timestamp,
      villageId: villageId,
      isGenesis: false,
    );
  }

  /// Verify the entire chain integrity from genesis
  ///
  /// Recomputes every hash and checks that each block's previousHash
  /// matches the actual hash of its predecessor.
  ///
  /// Returns verification result with details of any break.
  ChainVerificationResult verifyChain(List<HashBlock> chain) {
    if (chain.isEmpty) {
      return const ChainVerificationResult(
        isValid: false,
        totalBlocks: 0,
        brokenAtIndex: null,
        message: 'Chain is empty',
      );
    }

    // Verify genesis block
    if (!chain.first.isGenesis) {
      return ChainVerificationResult(
        isValid: false,
        totalBlocks: chain.length,
        brokenAtIndex: 0,
        message: 'First block is not a genesis block',
      );
    }

    // Verify genesis hash
    final genesisHash = _computeSHA256(chain.first.data);
    if (genesisHash != chain.first.hash) {
      return ChainVerificationResult(
        isValid: false,
        totalBlocks: chain.length,
        brokenAtIndex: 0,
        expectedHash: genesisHash,
        actualHash: chain.first.hash,
        message: 'Genesis block hash mismatch — possible tampering',
      );
    }

    // Verify each subsequent block
    for (int i = 1; i < chain.length; i++) {
      final current = chain[i];
      final previous = chain[i - 1];

      // Check previousHash reference
      if (current.previousHash != previous.hash) {
        return ChainVerificationResult(
          isValid: false,
          totalBlocks: chain.length,
          brokenAtIndex: i,
          expectedHash: previous.hash,
          actualHash: current.previousHash,
          message:
              'Block #$i previousHash does not match Block #${i - 1} hash — chain broken',
        );
      }

      // Recompute hash: Hₙ = SHA256(Hₙ₋₁ ∥ Dₙ ∥ tₙ)
      final expectedHash = _computeSHA256(
        '${current.previousHash}||${current.data}||${current.timestamp.toIso8601String()}',
      );

      if (expectedHash != current.hash) {
        return ChainVerificationResult(
          isValid: false,
          totalBlocks: chain.length,
          brokenAtIndex: i,
          expectedHash: expectedHash,
          actualHash: current.hash,
          message:
              'Block #$i hash mismatch — data may have been altered',
        );
      }
    }

    return ChainVerificationResult(
      isValid: true,
      totalBlocks: chain.length,
      brokenAtIndex: null,
      message:
          'Chain integrity verified — all ${chain.length} blocks authentic',
    );
  }

  /// Verify a single block against its predecessor
  bool verifyBlock(HashBlock block, HashBlock previousBlock) {
    if (block.previousHash != previousBlock.hash) return false;

    final expectedHash = _computeSHA256(
      '${block.previousHash}||${block.data}||${block.timestamp.toIso8601String()}',
    );

    return expectedHash == block.hash;
  }

  // ── Private helpers ────────────────────────────────────

  String _computeSHA256(String input) {
    final bytes = utf8.encode(input);
    final digest = sha256.convert(bytes);
    return digest.toString();
  }

  String _buildDataPayload({
    required String resolutionId,
    required String resolutionText,
    required String resolutionType,
    required int totalPresent,
    required int totalRegistered,
    required int womenPresent,
    required int stPresent,
    required int pvtgPresent,
    required bool quorumValid,
    required bool isCompliant,
  }) {
    return jsonEncode({
      'resolutionId': resolutionId,
      'type': resolutionType,
      'text': resolutionText,
      'attendance': {
        'present': totalPresent,
        'registered': totalRegistered,
        'women': womenPresent,
        'st': stPresent,
        'pvtg': pvtgPresent,
      },
      'quorumValid': quorumValid,
      'isCompliant': isCompliant,
    });
  }
}

/// A single block in the hash chain
class HashBlock {
  final int index;
  final String hash;
  final String previousHash;
  final String data;
  final DateTime timestamp;
  final String villageId;
  final bool isGenesis;

  const HashBlock({
    required this.index,
    required this.hash,
    required this.previousHash,
    required this.data,
    required this.timestamp,
    required this.villageId,
    required this.isGenesis,
  });

  /// Truncated hash for display (first 16 chars)
  String get shortHash => hash.substring(0, 16);

  /// Truncated previous hash for display
  String get shortPreviousHash => previousHash.substring(0, 16);

  Map<String, dynamic> toJson() => {
    'index': index,
    'hash': hash,
    'previousHash': previousHash,
    'data': data,
    'timestamp': timestamp.toIso8601String(),
    'villageId': villageId,
    'isGenesis': isGenesis,
  };

  factory HashBlock.fromJson(Map<String, dynamic> json) => HashBlock(
    index: json['index'] as int,
    hash: json['hash'] as String,
    previousHash: json['previousHash'] as String,
    data: json['data'] as String,
    timestamp: DateTime.parse(json['timestamp'] as String),
    villageId: json['villageId'] as String,
    isGenesis: json['isGenesis'] as bool,
  );
}

/// Result of chain verification
class ChainVerificationResult {
  final bool isValid;
  final int totalBlocks;
  final int? brokenAtIndex;
  final String? expectedHash;
  final String? actualHash;
  final String message;

  const ChainVerificationResult({
    required this.isValid,
    required this.totalBlocks,
    required this.brokenAtIndex,
    this.expectedHash,
    this.actualHash,
    required this.message,
  });
}
