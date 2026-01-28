const express = require('express');
const cors = require('cors');
const createOrder = require('./create-paypal-order');
const captureOrder = require('./capture-paypal-order');

const app = express();
app.use(cors());
app.use(express.json());

app.use('/', createOrder);
app.use('/', captureOrder);

const PORT = process.env.PORT || 3000;
app.listen(PORT, () => console.log(`Server running on port ${PORT}`));
