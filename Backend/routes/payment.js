const express = require('express');
const router = express.Router();
const axios = require('axios');
const { randomUUID } = require('crypto');
const Order = require('../models/Order');
const Product = require('../models/Product');
const Cart = require('../models/Cart');
const authMiddleware = require('../middleware/auth');

const PAYPAL_API = 'https://api-m.sandbox.paypal.com';
const PAYPAL_CLIENT_ID = process.env.PAYPAL_CLIENT_ID;
const PAYPAL_CLIENT_SECRET = process.env.PAYPAL_CLIENT_SECRET;
const PAYPAL_MOCK_MODE = process.env.PAYPAL_MOCK_MODE === 'true';

console.log('INFO: PayPal Mock Mode:', PAYPAL_MOCK_MODE ? 'ENABLED (Development)' : 'DISABLED (Production)');

// Get PayPal Access Token
async function getPayPalAccessToken() {
  if (PAYPAL_MOCK_MODE) {
    console.log('INFO: Using mock PayPal token');
    return 'mock_token_' + randomUUID();
  }

  try {
    console.log('DEBUG: PayPal Client ID:', PAYPAL_CLIENT_ID?.substring(0, 10) + '...');
    console.log('DEBUG: PayPal API URL:', `${PAYPAL_API}/v1/oauth2/token`);
    
    // Properly encode the request body
    const params = new URLSearchParams();
    params.append('grant_type', 'client_credentials');
    
    const response = await axios.post(
      `${PAYPAL_API}/v1/oauth2/token`,
      params,
      {
        auth: {
          username: PAYPAL_CLIENT_ID,
          password: PAYPAL_CLIENT_SECRET,
        },
        headers: {
          'Content-Type': 'application/x-www-form-urlencoded',
        },
      }
    );
    console.log('DEBUG: PayPal token obtained successfully');
    return response.data.access_token;
  } catch (error) {
    console.error('PayPal Token Error Response:', {
      status: error.response?.status,
      statusText: error.response?.statusText,
      data: error.response?.data,
    });
    console.error('PayPal Token Error Message:', error.message);
    throw new Error(`Failed to get PayPal access token: ${error.response?.data?.error_description || error.message}`);
  }
}

// Create PayPal Order
async function createPayPalOrder(accessToken, orderData) {
  if (PAYPAL_MOCK_MODE) {
    console.log('INFO: Using mock PayPal order creation');
    return {
      id: 'MOCK_ORDER_' + randomUUID(),
      status: 'CREATED',
      links: [
        {
          rel: 'approve',
          href: 'https://www.sandbox.paypal.com/checkoutnow?token=MOCK_TOKEN_' + randomUUID(),
        },
      ],
    };
  }

  try {
    const response = await axios.post(
      `${PAYPAL_API}/v2/checkout/orders`,
      orderData,
      {
        headers: {
          Authorization: `Bearer ${accessToken}`,
          'Content-Type': 'application/json',
        },
      }
    );
    console.log('INFO: PayPal order created successfully:', response.data.id);
    return response.data;
  } catch (error) {
    console.error('PayPal Create Order Error Response:', {
      status: error.response?.status,
      statusText: error.response?.statusText,
      data: error.response?.data,
    });
    console.error('PayPal Create Order Error Message:', error.message);
    throw new Error(`Failed to create PayPal order: ${JSON.stringify(error.response?.data) || error.message}`);
  }
}

// Capture PayPal Order
async function capturePayPalOrder(accessToken, orderId) {
  if (PAYPAL_MOCK_MODE) {
    console.log('INFO: Using mock PayPal order capture for:', orderId);
    return {
      id: orderId,
      status: 'COMPLETED',
      payer: {
        email_address: 'sandbox@example.com',
      },
    };
  }

  try {
    const response = await axios.post(
      `${PAYPAL_API}/v2/checkout/orders/${orderId}/capture`,
      {},
      {
        headers: {
          Authorization: `Bearer ${accessToken}`,
          'Content-Type': 'application/json',
        },
      }
    );
    console.log('INFO: PayPal order captured successfully:', orderId);
    return response.data;
  } catch (error) {
    console.error('PayPal Capture Error Response:', {
      status: error.response?.status,
      statusText: error.response?.statusText,
      data: error.response?.data,
    });
    console.error('PayPal Capture Error Message:', error.message);
    throw new Error(`Failed to capture PayPal payment: ${JSON.stringify(error.response?.data) || error.message}`);
  }
}

// Create PayPal Payment
router.post('/create', authMiddleware, async (req, res) => {
  try {
    const { userId, email } = req.user;
    const { cartItems, shippingAddress, phone, province, shippingCost } = req.body;

    // Validate input
    if (!cartItems || cartItems.length === 0) {
      return res.status(400).json({ error: 'Cart is empty' });
    }

    if (!shippingAddress || !phone || !province) {
      return res.status(400).json({ error: 'Missing shipping information' });
    }

    // Calculate total amount
    let totalAmount = 0;
    const items = [];

    for (let item of cartItems) {
      const product = await Product.findById(item.productId);
      if (!product) {
        return res.status(404).json({ error: `Product ${item.productId} not found` });
      }

      const itemTotal = product.price * item.quantity;
      totalAmount += itemTotal;

      items.push({
        name: product.name,
        sku: product._id.toString(),
        unit_amount: {
          currency_code: 'USD',
          value: product.price.toFixed(2),
        },
        quantity: item.quantity.toString(),
      });
    }

    // Add shipping cost
    const total = totalAmount + (shippingCost || 0);

    // Get PayPal Access Token
    const accessToken = await getPayPalAccessToken();

    // Create PayPal Order
    const orderData = {
      intent: 'CAPTURE',
      payer: {
        email_address: email,
      },
      purchase_units: [
        {
          reference_id: randomUUID(),
          amount: {
            currency_code: 'USD',
            value: total.toFixed(2),
            breakdown: {
              item_total: {
                currency_code: 'USD',
                value: totalAmount.toFixed(2),
              },
              shipping: {
                currency_code: 'USD',
                value: (shippingCost || 0).toFixed(2),
              },
            },
          },
          items: items,
          shipping: {
            name: {
              full_name: req.user.name || 'Customer',
            },
            address: {
              address_line_1: shippingAddress,
              admin_area_2: province,
              admin_area_1: province,
              country_code: 'KH',
            },
          },
        },
      ],
      application_context: {
        return_url: 'com.example.accessora://payment-success',
        cancel_url: 'com.example.accessora://payment-cancel',
        brand_name: 'Accessora',
        locale: 'en-US',
        landing_page: 'LOGIN',
        user_action: 'PAY_NOW',
      },
    };

    const paypalOrder = await createPayPalOrder(accessToken, orderData);

    // Find approval URL
    const approvalUrl = paypalOrder.links.find((link) => link.rel === 'approve')?.href;

    if (!approvalUrl) {
      return res.status(400).json({ error: 'No approval URL from PayPal' });
    }

    res.json({
      success: true,
      approvalUrl,
      paypalOrderId: paypalOrder.id,
      cartItems,
      shippingAddress,
      phone,
      province,
      shippingCost,
      totalAmount: total,
      isMockMode: PAYPAL_MOCK_MODE,
    });
  } catch (error) {
    console.error('Payment Create Error:', error.message);
    res.status(500).json({ error: error.message || 'Payment creation failed' });
  }
});

// Confirm PayPal Payment & Create Order
router.post('/confirm', authMiddleware, async (req, res) => {
  try {
    const { userId, email } = req.user;
    const { paypalOrderId, cartItems, shippingAddress, phone, province, shippingCost } = req.body;

    // Validate input
    if (!paypalOrderId) {
      return res.status(400).json({ error: 'PayPal Order ID is required' });
    }

    if (!cartItems || cartItems.length === 0) {
      return res.status(400).json({ error: 'Cart items are required' });
    }

    console.log('INFO: Processing payment confirmation for PayPal Order:', paypalOrderId);

    // IMPORTANT: For WebView checkout, we MUST capture the PayPal order
    // Get PayPal Access Token
    const accessToken = await getPayPalAccessToken();
    
    // Capture the PayPal order (this takes the money)
    console.log('INFO: Capturing PayPal order:', paypalOrderId);
    const captureResult = await capturePayPalOrder(accessToken, paypalOrderId);
    
    if (!captureResult || captureResult.status !== 'COMPLETED') {
      console.error('PayPal Capture Failed:', captureResult);
      return res.status(400).json({ 
        error: 'PayPal payment capture failed. Payment was not processed.',
        details: captureResult
      });
    }

    console.log('✅ PayPal order captured successfully:', captureResult.id);
    
    // Calculate total
    let totalAmount = 0;
    for (let item of cartItems) {
      const product = await Product.findById(item.productId);
      if (!product) {
        return res.status(404).json({ error: `Product ${item.productId} not found` });
      }
      totalAmount += product.price * item.quantity;
    }
    const total = totalAmount + (shippingCost || 0);

    // Create Order in Database (ONLY AFTER successful capture)
    const order = new Order({
      userId,
      items: cartItems.map((item) => ({
        productId: item.productId,
        quantity: item.quantity,
        price: item.price,
      })),
      totalPrice: total,
      shippingAddress,
      phoneNumber: phone,
      province,
      status: 'confirmed', // Payment has been captured and confirmed
      paymentMethod: 'paypal',
      paypalOrderId: paypalOrderId,
    });

    // Deduct stock for each product
    for (let item of cartItems) {
      const product = await Product.findByIdAndUpdate(
        item.productId,
        { $inc: { stock: -item.quantity } },
        { new: true }
      );

      if (!product) {
        return res.status(404).json({ error: `Product ${item.productId} not found` });
      }

      console.log(`INFO: Deducted ${item.quantity} units from product ${item.productId}`);
    }

    // Save order
    await order.save();
    console.log('✅ Order created successfully:', order._id);

    // Clear user's cart
    await Cart.findOneAndDelete({ userId });
    console.log('INFO: User cart cleared');

    res.json({
      success: true,
      orderId: order._id,
      message: 'Payment confirmed and order created',
      paypalCaptureId: captureResult.id,
      order,
    });
  } catch (error) {
    console.error('Payment Confirm Error:', error.message);
    res.status(500).json({ error: error.message || 'Payment confirmation failed' });
  }
});

module.exports = router;
