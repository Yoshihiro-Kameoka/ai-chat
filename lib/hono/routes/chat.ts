import { Hono } from 'hono';
import { zValidator } from '@hono/zod-validator';
import { chatRequestSchema } from '@/types/chat';
import { chatAgent } from '@/lib/mastra/agent';
import type { ChatResponse } from '@/types/chat';
import type { CoreMessage } from 'ai';

const chat = new Hono();

// POST /api/chat - Send a message and get AI response
chat.post('/', zValidator('json', chatRequestSchema), async (c) => {
  try {
    const { message, conversationHistory } = c.req.valid('json');

    // Build conversation history for context
    const messages: CoreMessage[] = [
      ...(conversationHistory || []).map((msg) => ({
        role: msg.role,
        content: msg.content,
      })),
      { role: 'user', content: message },
    ];

    // Generate response using Mastra agent
    const response = await chatAgent.generate(messages);

    const result: ChatResponse = {
      message: {
        role: 'assistant',
        content: response.text || '',
      },
    };

    return c.json(result);
  } catch (error) {
    console.error('Chat error:', error);
    return c.json(
      {
        error: 'Failed to generate response',
        message: error instanceof Error ? error.message : 'Unknown error',
      },
      500
    );
  }
});

// POST /api/chat/stream - Stream AI response
chat.post('/stream', zValidator('json', chatRequestSchema), async (c) => {
  try {
    const { message, conversationHistory } = c.req.valid('json');

    // Build conversation history for context
    const messages: CoreMessage[] = [
      ...(conversationHistory || []).map((msg) => ({
        role: msg.role,
        content: msg.content,
      })),
      { role: 'user', content: message },
    ];

    // Stream response using Mastra agent
    const streamResult = await chatAgent.stream(messages);

    // Create ReadableStream for SSE
    const encoder = new TextEncoder();
    const readable = new ReadableStream({
      async start(controller) {
        try {
          for await (const chunk of streamResult.textStream) {
            controller.enqueue(encoder.encode(`data: ${JSON.stringify({ text: chunk })}\n\n`));
          }
          controller.enqueue(encoder.encode('data: [DONE]\n\n'));
          controller.close();
        } catch (error) {
          console.error('Streaming error:', error);
          controller.error(error);
        }
      },
    });

    return new Response(readable, {
      headers: {
        'Content-Type': 'text/event-stream',
        'Cache-Control': 'no-cache',
        'Connection': 'keep-alive',
      },
    });
  } catch (error) {
    console.error('Chat stream error:', error);
    return c.json(
      {
        error: 'Failed to stream response',
        message: error instanceof Error ? error.message : 'Unknown error',
      },
      500
    );
  }
});

export default chat;
