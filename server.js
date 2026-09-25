const app = require('./backend/server');

const PORT = process.env.PORT || 3000;

app.listen(PORT, () => {
  console.log(`TaskFlow server running on port ${PORT}`);
});