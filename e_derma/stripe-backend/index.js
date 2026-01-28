require('dotenv').config();
const express = require('express');
const bodyParser = require('body-parser');
const stripe = require('stripe')(process.env.STRIPE_SECRET_KEY);
const { GoogleAuth } = require('google-auth-library');
const axios = require('axios');
const path = require('path');
const cors = require('cors');

const admin = require('firebase-admin');
const serviceAccount = require('./e-derma-firebase-adminsdk-fbsvc-fff72f77ee.json');

admin.initializeApp({
  credential: admin.credential.cert(serviceAccount),
});

const firestore = admin.firestore();



const endpointSecret = process.env.STRIPE_WEBHOOK_SECRET;

const app = express();
const port = 3000;

// Firebase Auth Setup
const keyPath = path.join(__dirname, 'e-derma-firebase-adminsdk-fbsvc-fff72f77ee.json');
const auth = new GoogleAuth({
  keyFile: keyPath,
  scopes: ['https://www.googleapis.com/auth/firebase.messaging'],
});



async function getAccessToken() {
  const client = await auth.getClient();
  const tokenResponse = await client.getAccessToken();
  return tokenResponse.token;
}

async function sendNotificationToTopic(title, body, topic = 'pusat_derma') {
  const accessToken = await getAccessToken();

  const message = {
    message: {
      topic: topic,
      notification: {
        title: title,
        body: body,
      },
    },
  };

  await axios.post(
    'https://fcm.googleapis.com/v1/projects/e-derma/messages:send',
    message,
    {
      headers: {
        'Authorization': `Bearer ${accessToken}`,
        'Content-Type': 'application/json',
      },
    }
  );
}

// Middleware
app.use(cors());
app.use(bodyParser.json());

// Routes
app.post('/create-payment-intent', async (req, res) => {
  const { amount } = req.body;

  try {
    const paymentIntent = await stripe.paymentIntents.create({
      amount: amount, // in cents
      currency: 'myr',
    });

    res.send({
      client_secret: paymentIntent.client_secret,
    });
  } catch (error) {
    res.status(500).send({ error: error.message });
  }
});

app.post('/create-subscription', async (req, res) => {
  const { email, name, amount } = req.body;

  try {
    const customer = await stripe.customers.create({
      email,
      name,
    });

    const price = await stripe.prices.create({
      unit_amount: amount * 100,
      currency: 'myr',
      recurring: { interval: 'month' },
      product_data: { name: 'Automated Donation' },
    });

    const subscription = await stripe.subscriptions.create({
      customer: customer.id,
      items: [{ price: price.id }],
      payment_behavior: 'default_incomplete',
      expand: ['latest_invoice.payment_intent'],
    });

    res.send({
      subscriptionId: subscription.id,
      clientSecret: subscription.latest_invoice.payment_intent.client_secret,
    });
  } catch (error) {
    console.error(error);
    res.status(500).send({ error: error.message });
  }
});

app.post('/webhook', express.raw({ type: 'application/json' }), (req, res) => {
  const sig = req.headers['stripe-signature'];
  let event;

  try {
    event = stripe.webhooks.constructEvent(req.body, sig, endpointSecret);
  } catch (err) {
    return res.status(400).send(`Webhook Error: ${err.message}`);
  }

  switch (event.type) {
    case 'invoice.payment_succeeded':
      const paymentIntent = event.data.object;
      console.log('Payment for subscription succeeded:', paymentIntent);
      break;
    case 'invoice.payment_failed':
      console.log('Payment for subscription failed:', event.data.object);
      break;
    default:
      console.log(`Unhandled event type ${event.type}`);
  }

  res.json({ received: true });
});

app.post('/add-pusat-derma', async (req, res) => {
  const { name, location, description } = req.body;

  try {
    console.log('New Pusat Derma added:', { name, location, description });

    await sendNotificationToTopic(
      'Pusat Derma Baru!',
      `Pusat derma ${name} telah mendaftar!`
    );

    res.status(200).json({ message: 'Pusat derma added and notification sent.' });
  } catch (error) {
    console.error('Error adding pusat derma:', error);
    res.status(500).json({ error: 'Failed to add pusat derma' });
  }
});

app.post('/notify-pengguna', async (req, res) => {
  const { pusatDermaName } = req.body;

  console.log("Received pusatDermaName:", pusatDermaName); // <-- Add this

  try {
    await sendNotificationToTopic(
      'Pusat Derma Baharu',
      `Pusat derma ${pusatDermaName} telah ditambah!`
    );

    res.status(200).send({ message: 'Notification sent to pengguna.' });
  } catch (error) {
    console.error("❌ Failed to send notification:", error.message);
    res.status(500).send({ error: 'Failed to send notification.' });
  }
});



// POST /pusat-notify-pengguna
app.post('/pusat-notify-pengguna', async (req, res) => {
  const { title, body } = req.body;

  const message = {
    topic: 'pengguna',
    notification: {
      title,
      body,
    },
  };

  try {
    const response = await admin.messaging().send(message);
    console.log('✅ Notification sent to pengguna:', response);
    res.status(200).send({ success: true });
  } catch (error) {
    console.error('❌ Error sending notification to pengguna:', error);
    res.status(500).send({ error: 'Notification failed' });
  }
});

// POST /delete-auth-user
app.post('/delete-auth-user', async (req, res) => {
  const { email } = req.body;

  if (!email) {
    return res.status(400).json({ error: 'Email is required.' });
  }

  try {
    const userRecord = await admin.auth().getUserByEmail(email);
    await admin.auth().deleteUser(userRecord.uid);
    console.log(`✅ Deleted user with email: ${email}`);
    res.status(200).json({ success: true, message: 'User deleted successfully.' });
  } catch (error) {
    console.error(`❌ Failed to delete user with email ${email}:`, error);
    res.status(500).json({ success: false, error: error.message });
  }
});




// Start the server
app.listen(port,'0.0.0.0', () => {
  console.log(`Server running on http://localhost:${port}`);
});
