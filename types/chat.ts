import { z } from 'zod';

// Message type
export interface Message {
  id: string;
  role: 'user' | 'assistant';
  content: string;
  createdAt: Date;
}

// Chat request schema
export const chatRequestSchema = z.object({
  message: z.string().min(1, 'Message cannot be empty'),
  sessionId: z.string().optional(),
  conversationHistory: z.array(
    z.object({
      role: z.enum(['user', 'assistant']),
      content: z.string(),
    })
  ).optional(),
});

export type ChatRequest = z.infer<typeof chatRequestSchema>;

// Chat response type
export interface ChatResponse {
  message: {
    role: 'assistant';
    content: string;
  };
  sessionId?: string;
}
