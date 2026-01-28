require('dotenv').config(); 
const express = require("express");
const cors = require("cors");
const bodyParser = require("body-parser");
const admin = require("firebase-admin");

const app = express();
app.use(cors());
app.use(bodyParser.json());

// Initialize Firebase Admin SDK with service account
const serviceAccount = JSON.parse(process.env.FIREBASE_CONFIG);

admin.initializeApp({
  credential: admin.credential.cert(serviceAccount),
});

app.post("/pusat-notify-pengguna", async (req, res) => {
  const { title, body } = req.body;

  if (!title || !body) {
    return res.status(400).json({ error: "Title and body required." });
  }

  try {
    const message = {
      notification: { title, body },
      topic: "pengguna", // or use registration token(s)
    };

    const response = await admin.messaging().send(message);
    console.log("✅ Notification sent:", response);
    res.status(200).json({ success: true });
  } catch (err) {
    console.error("❌ Error sending notification:", err);
    res.status(500).json({ error: "Notification failed." });
  }
});

app.get("/", (req, res) => {
  res.send("FCM Push Server is running");
});

const PORT = process.env.PORT || 3000;
app.listen(PORT, () => console.log(`🚀 Server running on port ${PORT}`));
