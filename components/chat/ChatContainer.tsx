'use client';

import { MessageList } from './MessageList';
import { MessageInput } from './MessageInput';
import { Button } from '@/components/ui/Button';
import { RefreshCw } from 'lucide-react';
import type { Message } from '@/types/chat';

interface ChatContainerProps {
  messages: Message[];
  onSendMessage: (message: string) => void;
  onNewChat: () => void;
  isLoading: boolean;
}

export const ChatContainer = ({
  messages,
  onSendMessage,
  onNewChat,
  isLoading,
}: ChatContainerProps) => {
  return (
    <div className="flex flex-col h-screen max-w-4xl mx-auto bg-white shadow-lg">
      {/* Header */}
      <div className="border-b border-gray-200 p-4 bg-white flex items-center justify-between">
        <div>
          <h1 className="text-2xl font-bold text-gray-900">AI Chat</h1>
          <p className="text-sm text-gray-500">Powered by Claude</p>
        </div>
        <Button
          onClick={onNewChat}
          variant="ghost"
          size="sm"
          disabled={isLoading}
        >
          <RefreshCw className="h-4 w-4 mr-2" />
          新規会話
        </Button>
      </div>

      {/* Messages */}
      <MessageList messages={messages} isLoading={isLoading} />

      {/* Input */}
      <MessageInput onSend={onSendMessage} disabled={isLoading} />
    </div>
  );
};
