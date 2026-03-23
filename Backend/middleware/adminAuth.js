const jwt = require('jsonwebtoken');

// List of hardcoded admin emails
const ADMIN_EMAILS = [
  'admin@accessora.com',
  'phanny@accessora.com', // Add your email here
  'phanny2@accessora.com',
  'sophannycmd@gmail.com',
];

const adminAuth = (req, res, next) => {
  try {
    const authHeader = req.headers['authorization'];
    const token = authHeader && authHeader.split(' ')[1]; // Bearer TOKEN

    if (!token) {
      return res.status(401).json({ error: 'No authentication token provided' });
    }

    jwt.verify(token, process.env.JWT_SECRET, (err, user) => {
      if (err) {
        return res.status(403).json({ error: 'Invalid or expired token' });
      }

      // Check if user email is in admin list
      if (!ADMIN_EMAILS.includes(user.email)) {
        return res.status(403).json({ error: 'Access denied. Admin privileges required.' });
      }

      req.user = user;
      next();
    });
  } catch (error) {
    res.status(401).json({ error: 'Authentication failed' });
  }
};

module.exports = adminAuth;
