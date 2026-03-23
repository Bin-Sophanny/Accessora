const express = require('express');
const router = express.Router();
const Order = require('../models/Order');
const Cart = require('../models/Cart');
const Product = require('../models/Product');

// Get all orders for user
router.get('/:userId', async (req, res) => {
  try {
    const userId = req.params.userId;
    const userOrders = await Order.find({ userId });
    res.json(userOrders);
  } catch (error) {
    res.status(500).json({ error: 'Failed to fetch orders' });
  }
});

// Create order
router.post('/:userId/create', async (req, res) => {
  try {
    const { userId } = req.params;
    const { shippingAddress, phoneNumber, province } = req.body;

    // Get cart
    const cart = await Cart.findOne({ userId });
    if (!cart || cart.items.length === 0) {
      return res.status(400).json({ error: 'Cart is empty' });
    }

    // Deduct stock for each item
    for (const item of cart.items) {
      const product = await Product.findById(item.productId);
      if (!product) {
        return res.status(404).json({ error: `Product ${item.name} not found` });
      }
      if (product.stock < item.quantity) {
        return res.status(400).json({ error: `Insufficient stock for ${item.name}. Available: ${product.stock}` });
      }
      // Deduct stock
      product.stock -= item.quantity;
      await product.save();
    }

    // Calculate total price
    const totalPrice = cart.items.reduce((sum, item) => sum + item.price * item.quantity, 0);

    // Create order
    const order = new Order({
      userId,
      items: cart.items,
      totalPrice,
      shippingAddress,
      phoneNumber,
      province,
      status: 'pending',
    });

    await order.save();

    // Clear cart after order
    await Cart.findOneAndDelete({ userId });

    res.json({ message: 'Order created successfully', order });
  } catch (error) {
    res.status(500).json({ error: 'Failed to create order' });
  }
});

// Get order by ID
router.get('/:userId/:orderId', async (req, res) => {
  try {
    const { userId, orderId } = req.params;
    const order = await Order.findById(orderId);

    if (!order || order.userId !== userId) {
      return res.status(404).json({ error: 'Order not found' });
    }

    res.json(order);
  } catch (error) {
    res.status(500).json({ error: 'Failed to fetch order' });
  }
});

module.exports = router;
