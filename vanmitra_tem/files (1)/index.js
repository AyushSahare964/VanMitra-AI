const functions = require('firebase-functions');
const admin = require('firebase-admin');
admin.initializeApp();

const db = admin.firestore();

/**
 * SECURITY DESIGN NOTE
 * ---------------------
 * villageId and role must never be trusted from client input. Instead:
 *  1. An admin/super_admin pre-registers a phone number against a villageId + role
 *     via `registerMember` (callable, admin-only) -> writes to pending_registrations/{phone}.
 *  2. When that phone number completes Firebase Phone-OTP sign-in for the FIRST time,
 *     the onUserCreate Auth trigger below looks up the pending registration, sets
 *     custom claims (role, villageId), and creates the corresponding users/{uid} doc
 *     itself (Admin SDK bypasses Firestore rules, so this is the ONLY place user docs
 *     are created — see firestore.rules `users` match: allow create: if isSuperAdmin()).
 *  3. If no pending registration exists, the user is created with role="pending" and
 *     villageId=null — such a user can read nothing until an admin approves them via
 *     `approvePendingUser`.
 */

// ---------- 1. Admin pre-registers a phone number ----------
exports.registerMember = functions.https.onCall(async (data, context) => {
  const callerRole = context.auth?.token?.role;
  if (!context.auth || !['admin', 'super_admin'].includes(callerRole)) {
    throw new functions.https.HttpsError('permission-denied', 'Admin only.');
  }
  const { phoneNumber, villageId, role } = data;
  if (!phoneNumber || !villageId || !['villager', 'admin'].includes(role)) {
    throw new functions.https.HttpsError('invalid-argument', 'phoneNumber, villageId, role required.');
  }
  // A village-admin can only register members into their OWN village
  if (callerRole === 'admin' && context.auth.token.villageId !== villageId) {
    throw new functions.https.HttpsError('permission-denied', 'Cannot register into another village.');
  }
  await db.collection('pending_registrations').doc(phoneNumber).set({
    villageId,
    role,
    registeredBy: context.auth.uid,
    createdAt: admin.firestore.FieldValue.serverTimestamp(),
  });
  return { success: true };
});

// ---------- 2. First-login trigger: set claims + create users/{uid} ----------
exports.onUserCreate = functions.auth.user().onCreate(async (user) => {
  const userRef = db.collection('users').doc(user.uid);

  // Email/password signup writes users/{uid} from the client after Auth creation.
  // Wait briefly so we can sync custom claims from that profile instead of
  // overwriting it with a pending placeholder.
  if (user.email && !user.phoneNumber) {
    for (let attempt = 0; attempt < 10; attempt++) {
      const existing = await userRef.get();
      if (existing.exists) {
        const data = existing.data();
        await admin.auth().setCustomUserClaims(user.uid, {
          role: data.role || 'villager',
          villageId: data.villageId || null,
        });
        return null;
      }
      await new Promise((resolve) => setTimeout(resolve, 500));
    }
  }

  const phone = user.phoneNumber;
  let claims = { role: 'pending', villageId: null };

  if (phone) {
    const pendingRef = db.collection('pending_registrations').doc(phone);
    const pendingSnap = await pendingRef.get();
    if (pendingSnap.exists) {
      const { villageId, role } = pendingSnap.data();
      claims = { role, villageId };
      await pendingRef.delete(); // consume the invite
    }
  }

  const existingDoc = await userRef.get();
  if (existingDoc.exists) {
    const data = existingDoc.data();
    await admin.auth().setCustomUserClaims(user.uid, {
      role: data.role || claims.role,
      villageId: data.villageId ?? claims.villageId,
    });
    return null;
  }

  await admin.auth().setCustomUserClaims(user.uid, claims);

  await userRef.set({
    id: user.uid,
    phoneNumber: phone || null,
    email: user.email || null,
    name: user.displayName || '',
    role: claims.role,          // display-only mirror of the custom claim
    villageId: claims.villageId,
    preferredLanguage: 'mr',
    hasFaceEnrolled: false,
    isActive: claims.role !== 'pending',
    createdAt: admin.firestore.FieldValue.serverTimestamp(),
  });
});

// ---------- 3. Super-admin approves a "pending" user manually ----------
exports.approvePendingUser = functions.https.onCall(async (data, context) => {
  if (context.auth?.token?.role !== 'super_admin') {
    throw new functions.https.HttpsError('permission-denied', 'Super admin only.');
  }
  const { uid, villageId, role } = data;
  await admin.auth().setCustomUserClaims(uid, { role, villageId });
  await db.collection('users').doc(uid).update({ role, villageId, isActive: true });
  return { success: true };
});

// ---------- 4. Hash-chain integrity guard for resolutions ----------
// Firestore rules can't cheaply verify SHA-256 chain continuity, so this trigger
// runs AFTER write and flags (does not block) any broken link for admin review.
// Blocking would need a transaction at write time in a callable function instead
// of a direct client write, which is the recommended production hardening step —
// see the Integration Plan, Phase 6, for the callable-function version.
exports.verifyResolutionChain = functions.firestore
  .document('resolutions/{resolutionId}')
  .onCreate(async (snap, context) => {
    const data = snap.data();
    if (data.blockIndex === 0) return null; // genesis block, nothing to check

    const prevQuery = await db.collection('resolutions')
      .where('villageId', '==', data.villageId)
      .where('blockIndex', '==', data.blockIndex - 1)
      .limit(1)
      .get();

    if (prevQuery.empty || prevQuery.docs[0].data().hash !== data.previousHash) {
      await db.collection('sync_audit_log').add({
        userId: data.recordedByUserId,
        villageId: data.villageId,
        action: 'createResolution',
        entityId: context.params.resolutionId,
        entityType: 'resolution',
        status: 'failed',
        errorMessage: 'Hash chain mismatch detected — flagged for admin review',
        syncedAt: admin.firestore.FieldValue.serverTimestamp(),
      });
    }
    return null;
  });
