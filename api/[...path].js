const app = require('../backend/server');
const connectDB = require('../backend/config/db');

module.exports = async (req, res) => {
  try {
    await connectDB();
    app(req, res);
  } catch (error) {
    console.error('API initialization failed:', error);
    res.status(500).json({
      error: {
        code: 'INTERNAL_ERROR',
        message: 'The service is temporarily unavailable',
      },
    });
  }
};