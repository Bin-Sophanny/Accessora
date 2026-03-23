# Accessora Backend

Simple Express.js backend for Accessora e-commerce store (computer accessories).

## Setup

1. Install dependencies:
```bash
npm install
```

2. Create `.env` file (already created):
```
PORT=5000
NODE_ENV=development
```

3. Start the server:
```bash
npm start
```

The server will run on `http://localhost:5000`

## API Endpoints

### Products
- `GET /api/products` - Get all products
- `GET /api/products/:id` - Get product by ID
- `GET /api/products/category/:category` - Get products by category

### Cart
- `GET /api/cart/:userId` - Get user's cart
- `POST /api/cart/:userId/add` - Add product to cart
- `POST /api/cart/:userId/remove/:productId` - Remove product from cart
- `POST /api/cart/:userId/clear` - Clear cart

### Orders
- `GET /api/orders/:userId` - Get user's orders
- `POST /api/orders/:userId/create` - Create new order
- `GET /api/orders/:userId/:orderId` - Get order details

## Project Structure

```
Backend/
├── server.js          # Main server file
├── package.json       # Dependencies
├── .env              # Environment variables
├── .gitignore        # Git ignore rules
├── data/
│   └── products.json # Product data
└── routes/
    ├── products.js   # Product routes
    ├── cart.js       # Cart routes
    └── orders.js     # Order routes
```

## Next Steps
- Connect to a real database (MongoDB, PostgreSQL, etc.)
- Add authentication & user management
- Add payment integration
- Add email notifications
