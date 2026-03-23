const mongoose = require('mongoose');
require('dotenv').config();
const Product = require('./models/Product');
const connectDB = require('./config/database');

const seedProducts = async () => {
  try {
    await connectDB();

    // Clear existing products
    await Product.deleteMany({});

    const products = [
      {
        name: 'Gaming Mouse',
        description: 'High precision gaming mouse with RGB lighting and 16000 DPI',
        price: 49.99,
        category: 'peripherals',
        stock: 20,
        image: 'https://via.placeholder.com/400x400?text=Gaming+Mouse',
      },
      {
        name: 'Mechanical Keyboard',
        description: 'RGB mechanical keyboard with cherry switches and programmable keys',
        price: 89.99,
        category: 'peripherals',
        stock: 15,
        image: 'https://via.placeholder.com/400x400?text=Mechanical+Keyboard',
      },
      {
        name: 'Gaming Headset',
        description: 'Wireless gaming headset with surround sound and noise cancellation',
        price: 79.99,
        category: 'audio',
        stock: 10,
        image: 'https://via.placeholder.com/400x400?text=Gaming+Headset',
      },
      {
        name: 'Monitor Stand',
        description: 'Adjustable monitor stand with storage drawer and cable management',
        price: 39.99,
        category: 'stands',
        stock: 25,
        image: 'https://via.placeholder.com/400x400?text=Monitor+Stand',
      },
      {
        name: 'Mouse Pad',
        description: 'Large gaming mouse pad with non-slip base and RGB support',
        price: 24.99,
        category: 'mousepads',
        stock: 30,
        image: 'https://via.placeholder.com/400x400?text=Mouse+Pad',
      },
      {
        name: 'USB Hub',
        description: '7-port USB 3.0 hub with power adapter and fast charging',
        price: 34.99,
        category: 'cables',
        stock: 18,
        image: 'https://via.placeholder.com/400x400?text=USB+Hub',
      },
      {
        name: 'Desk Lamp',
        description: 'LED desk lamp with adjustable brightness and eye protection',
        price: 44.99,
        category: 'lighting',
        stock: 12,
        image: 'https://via.placeholder.com/400x400?text=Desk+Lamp',
      },
    ];

    await Product.insertMany(products);
    console.log('Products seeded successfully');
    process.exit(0);
  } catch (error) {
    console.error('Error seeding products:', error);
    process.exit(1);
  }
};

seedProducts();
