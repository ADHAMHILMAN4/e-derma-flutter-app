const express = require('express');
const Stripe = require('stripe');
const cors = require('cors');

const app = express();
const stripe = Stripe('sk_test_51RA1RxQ6gaeYFkZgIMycLqc9J0OoNKJA256YzZbU9MzEF96m5hEJ5OP8jJSW9qyU20wKwCddF8i1TVOgztHKBonB00eeSYw58A'); // Replace with your Secret Key

app.use(cors());
app.use(express.json());

app.post('/create-payment-intent', async (req, res) => {
  const { amount, currency } = req.body;

  try {
    const paymentIntent = await stripe.paymentIntents.create({
      amount: amount, // in cents
      currency: currency,
      payment_method_types: ['card'],
    });

    res.send({
      clientSecret: paymentIntent.client_secret,
    });
  } catch (err) {
    console.error(err);
    res.status(500).json({ error: 'Failed to create payment intent' });
  }
});

app.listen(3000, () => console.log('Server running on http://localhost:3000'));
