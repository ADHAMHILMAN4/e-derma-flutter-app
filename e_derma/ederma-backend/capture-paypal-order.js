const express = require('express');
const axios = require('axios');
const router = express.Router();
require('dotenv').config();

router.post('/capture-paypal-order', async (req, res) => {
  const { orderId } = req.body;

  const auth = Buffer.from(`${process.env.PAYPAL_CLIENT_ID}:${process.env.PAYPAL_SECRET}`).toString('base64');

  const { data: tokenData } = await axios.post(
    'https://api-m.sandbox.paypal.com/v1/oauth2/token',
    'grant_type=client_credentials',
    { headers: { Authorization: `Basic ${auth}` } }
  );

  const { access_token } = tokenData;

  const { data: capture } = await axios.post(
    `https://api-m.sandbox.paypal.com/v2/checkout/orders/${orderId}/capture`,
    {},
    { headers: { Authorization: `Bearer ${access_token}` } }
  );

  res.json({ success: true, capture });
});

module.exports = router;
