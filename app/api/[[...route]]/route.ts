import { handle } from 'hono/vercel';
import { app } from '@/lib/hono/app';

export const runtime = 'nodejs';

// Export handlers for Next.js API routes
export const GET = handle(app);
export const POST = handle(app);
export const PUT = handle(app);
export const PATCH = handle(app);
export const DELETE = handle(app);
export const OPTIONS = handle(app);
