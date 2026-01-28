const functions = require("firebase-functions");
const admin = require("firebase-admin");

admin.initializeApp();

exports.sendPushOnNewNotification = functions.firestore
  .document('notifikasi/{notifId}')
  .onCreate(async (snap, context) => {
    const data = snap.data();
    const title = data.tajuk || 'Notifikasi Baru';
    const body = data.penerangan || '';

    // 🔄 Get all pengguna with fcmToken
    const usersSnapshot = await admin.firestore().collection('pengguna').get();

    const tokens = [];
    usersSnapshot.forEach(doc => {
      const userData = doc.data();
      if (userData.fcmToken) {
        tokens.push(userData.fcmToken);
      }
    });

    if (tokens.length === 0) {
      console.log('❌ No user tokens found.');
      return null;
    }

    const message = {
      notification: {
        title: title,
        body: body,
      },
      tokens: tokens,
    };

    try {
      const response = await admin.messaging().sendMulticast(message);
      console.log(`✅ Notification sent to ${response.successCount} users.`);
    } catch (error) {
      console.error('❌ Error sending notification:', error);
    }

    return null;
  });
