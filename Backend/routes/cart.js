const express = require('express');
const router = express.Router();
const Cart = require('../models/Cart');
const Product = require('../models/Product');

// Get cart for user
router.get('/:userId', async (req, res) => {
  try {
    const userId = req.params.userId;
    let cart = await Cart.findOne({ userId });
    
    if (!cart) {
      cart = new Cart({ userId, items: [] });
    }
    
    res.json(cart);
  } catch (error) {
    res.status(500).json({ error: 'Failed to fetch cart' });
  }
});

// Add to cart
router.post('/:userId/add', async (req, res) => {
  try {
    const { userId } = req.params;
    const { productId, quantity } = req.body;

    if (!productId || quantity === null || quantity === undefined || quantity === 0) {
      return res.status(400).json({ error: 'Invalid product or quantity' });
    }

    const product = await Product.findById(productId);
    if (!product && quantity > 0) {
      return res.status(404).json({ error: 'Product not found' });
    }

    let cart = await Cart.findOne({ userId });
    if (!cart) {
      cart = new Cart({ userId, items: [] });
    }

    const existingItem = cart.items.find(item => item.productId.toString() === productId);
    if (existingItem) {
      existingItem.quantity += quantity;
      // Remove item if quantity goes to 0 or below
      if (existingItem.quantity <= 0) {
        cart.items = cart.items.filter(item => item.productId.toString() !== productId);
      }
    } else if (quantity > 0) {
      cart.items.push({
        productId,
        name: product.name,
        price: product.price,
        image: product.image,
        quantity,
      });
    }

    await cart.save();
    res.json({ message: 'Product added to cart', cart });
  } catch (error) {
    res.status(500).json({ error: 'Failed to add to cart' });
  }
});

// Remove from cart
router.post('/:userId/remove/:productId', async (req, res) => {
  try {
    const { userId, productId } = req.params;
    
    let cart = await Cart.findOne({ userId });
    if (!cart) {
      return res.status(404).json({ error: 'Cart not found' });
    }

    cart.items = cart.items.filter(item => item.productId.toString() !== productId);
    await cart.save();

    res.json({ message: 'Product removed from cart', cart });
  } catch (error) {
    res.status(500).json({ error: 'Failed to remove from cart' });
  }
});

// Clear cart
router.post('/:userId/clear', async (req, res) => {
  try {
    const userId = req.params.userId;
    await Cart.findOneAndDelete({ userId });
    res.json({ message: 'Cart cleared' });
  } catch (error) {
    res.status(500).json({ error: 'Failed to clear cart' });
  }
});

module.exports = router;
