const express = require('express');
const bodyParser = require('body-parser');
const stripe = require('stripe')('sk_test_51RA1RxQ6gaeYFkZgIMycLqc9J0OoNKJA256YzZbU9MzEF96m5hEJ5OP8jJSW9qyU20wKwCddF8i1TVOgztHKBonB00eeSYw58A');  // Replace with your Stripe secret key

const app = express();
const port = 5000;

// Middleware
app.use(bodyParser.json());

// Endpoint to create payment intent
app.post('/create-payment-intent', async (req, res) => {
  const { amount } = req.body;

  try {
    const paymentIntent = await stripe.paymentIntents.create({
      amount: amount, // Amount in cents
      currency: 'myr', // Set your currency
    });
    res.send({
      clientSecret: paymentIntent.client_secret,
    });
  } catch (error) {
    console.error(error);
    res.status(500).send({ error: error.message });
  }
});

// Start the server
app.listen(port, () => {
  console.log(`Server running at http://localhost:${port}`);
});
