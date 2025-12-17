import { Agent } from '@mastra/core/agent';

let _chatAgent: Agent | null = null;

// Create AI agent with Claude 3.5 Sonnet (lazy initialization)
export function getChatAgent(): Agent {
  if (!_chatAgent) {
    if (!process.env.ANTHROPIC_API_KEY) {
      throw new Error('ANTHROPIC_API_KEY environment variable is required');
    }

    _chatAgent = new Agent({
      id: 'chat-agent',
      name: 'AI Chat Assistant',
      instructions: `You are a helpful AI assistant.
You provide clear, concise, and friendly responses.
You maintain a professional yet approachable tone.
When you don't know something, you admit it honestly.`,
      model: {
        id: 'anthropic/claude-3-5-haiku-20241022', // Claude 3.5 Haiku - 約1/4のコスト
        apiKey: process.env.ANTHROPIC_API_KEY,
      },
    });
  }

  return _chatAgent;
}

// For backward compatibility
export const chatAgent = {
  generate: (...args: Parameters<Agent['generate']>) => getChatAgent().generate(...args),
  stream: (...args: Parameters<Agent['stream']>) => getChatAgent().stream(...args),
};
