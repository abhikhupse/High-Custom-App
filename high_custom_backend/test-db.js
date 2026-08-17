require('dotenv').config();
const connectDB = require('./config/db');

connectDB()
  .then(() => {
    console.log('connectDB resolved');
    process.exit(0);
  })
  .catch((err) => {
    console.error('connectDB rejected', err);
    process.exit(1);
  });
