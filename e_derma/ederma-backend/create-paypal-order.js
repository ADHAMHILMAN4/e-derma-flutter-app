const express = require('express');
const axios = require('axios');
const router = express.Router();
require('dotenv').config();

router.post('/create-paypal-order', async (req, res) => {
  const { amount } = req.body;

  const auth = Buffer.from(`${process.env.PAYPAL_CLIENT_ID}:${process.env.PAYPAL_SECRET}`).toString('base64');

  const { data: tokenData } = await axios.post(
    'https://api-m.sandbox.paypal.com/v1/oauth2/token',
    'grant_type=client_credentials',
    { headers: { Authorization: `Basic ${auth}` } }
  );

  const { access_token } = tokenData;

  const { data: order } = await axios.post(
    'https://api-m.sandbox.paypal.com/v2/checkout/orders',
    {
      intent: 'CAPTURE',
      purchase_units: [{
        amount: {
          currency_code: 'MYR',
          value: amount.toFixed(2),
        },
      }],
      application_context: {
        return_url: 'https://example.com/return',
        cancel_url: 'https://example.com/cancel',
      },
    },
    { headers: { Authorization: `Bearer ${access_token}` } }
  );

  const approvalUrl = order.links.find(link => link.rel === 'approve').href;

  res.json({ approvalUrl, orderId: order.id });
});

module.exports = router;
