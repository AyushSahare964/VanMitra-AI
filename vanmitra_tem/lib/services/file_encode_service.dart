import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:path_provider/path_provider.dart';

/// Replaces Firebase Storage.
/// Compresses files and stores them as Base64 subdocuments in Firestore.
class FileEncodeService {
  /// Compresses an image file and returns a base64 string safely under the
  /// 900 KB Firestore-rules cap. Retries at lower quality if still too big.
  static Future<String> encodeImage(File file, {int maxBytes = 850000}) async {
    var quality = 60;
    Uint8List? bytes = await FlutterImageCompress.compressWithFile(
      file.path,
      quality: quality,
      minWidth: 1000,
    );
    
    while (bytes != null && base64.encode(bytes).length > maxBytes && quality > 20) {
      quality -= 10;
      bytes = await FlutterImageCompress.compressWithFile(
        file.path,
        quality: quality,
        minWidth: 800,
      );
    }
    
    if (bytes == null || base64.encode(bytes).length > maxBytes) {
      throw Exception('Image too large even after compression — ask user to retake at lower resolution');
    }
    
    return base64.encode(bytes);
  }

  /// Uploads a claim document image as a subdocument under the claim.
  static Future<void> uploadClaimDocument({
    required String claimId,
    required String villageId,
    required File file,
    required String category, // sitePhoto | rationCard | voterId | otherDoc
  }) async {
    final base64Data = await encodeImage(file);
    final docRef = FirebaseFirestore.instance
        .collection('claims').doc(claimId)
        .collection('documents').doc();

    await docRef.set({
      'id': docRef.id,
      'claimId': claimId,
      'villageId': villageId,
      'claimantUserId': FirebaseAuth.instance.currentUser!.uid,
      'category': category,
      'mimeType': 'image/jpeg',
      'base64Data': base64Data,
      'sizeBytes': base64Data.length,
      'uploadedAt': FieldValue.serverTimestamp(),
    });

    // Keep a lightweight reference on the parent claim
    await FirebaseFirestore.instance.collection('claims').doc(claimId).update({
      'documentRefs': FieldValue.arrayUnion([docRef.id]),
    });
  }

  /// Splits a large PDF into ~850KB chunks and stores them as subdocuments.
  static Future<void> uploadMeetingMinutes(String meetingId, String villageId, File pdf) async {
    final bytes = await pdf.readAsBytes();
    final base64Full = base64.encode(bytes);
    const chunkSize = 850000; // chars per chunk, safely under the rules cap
    final chunks = <String>[];
    
    for (var i = 0; i < base64Full.length; i += chunkSize) {
      chunks.add(base64Full.substring(i, (i + chunkSize).clamp(0, base64Full.length)));
    }

    final batch = FirebaseFirestore.instance.batch();
    final col = FirebaseFirestore.instance
        .collection('gram_sabha_meetings').doc(meetingId)
        .collection('minutes_chunks');

    for (var i = 0; i < chunks.length; i++) {
      batch.set(col.doc('chunk_${i.toString().padLeft(4, '0')}'), {
        'chunkIndex': i,
        'totalChunks': chunks.length,
        'base64Chunk': chunks[i],
        'mimeType': 'application/pdf',
        'createdAt': FieldValue.serverTimestamp(),
      });
    }
    
    await batch.commit();

    await FirebaseFirestore.instance.collection('gram_sabha_meetings').doc(meetingId).update({
      'minutesChunkCount': chunks.length,
    });
  }

  /// Reassembles a chunked PDF from Firestore.
  static Future<File> downloadMeetingMinutes(String meetingId) async {
    final snap = await FirebaseFirestore.instance
        .collection('gram_sabha_meetings').doc(meetingId)
        .collection('minutes_chunks')
        .orderBy('chunkIndex')
        .get();
        
    final full = snap.docs.map((d) => d['base64Chunk'] as String).join();
    final bytes = base64.decode(full);
    
    final tempDir = await getTemporaryDirectory();
    final file = File('${tempDir.path}/minutes_$meetingId.pdf');
    return file.writeAsBytes(bytes);
  }
}
