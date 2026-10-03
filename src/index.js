'use strict';

const express = require('express');
const app = express();
app.disable('x-powered-by');
app.use(express.json({ limit: '10kb' }));
app.get('/', (_request, response) => response.type('text/plain').send('Hello hackathon'));
app.get('/health', (_request, response) => response.status(200).json({ status: 'ok' }));
if (require.main === module) {
  const port = Number.parseInt(process.env.PORT || '3000', 10);
  app.listen(port, '0.0.0.0', () => console.log(`Hackathon app listening on port ${port}`));
}
module.exports = app;
