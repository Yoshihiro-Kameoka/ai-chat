import { Hono } from 'hono';
import { cors } from 'hono/cors';
import { logger } from 'hono/logger';
import chat from './routes/chat';

// Create Hono app
export const app = new Hono().basePath('/api');

// Middleware
app.use('*', logger());
app.use(
  '*',
  cors({
    origin: process.env.NEXT_PUBLIC_APP_URL || 'http://localhost:3000',
    credentials: true,
  })
);

// Health check endpoint
app.get('/health', (c) => {
  return c.json({ status: 'ok', timestamp: new Date().toISOString() });
});

// Mount routes
app.route('/chat', chat);

export type AppType = typeof app;
