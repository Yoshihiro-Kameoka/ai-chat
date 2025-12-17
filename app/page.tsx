'use client';

import { ChatContainer } from '@/components/chat/ChatContainer';
import { useChat } from '@/hooks/useChat';

export default function Home() {
  const { messages, isLoading, sendMessage, clearMessages } = useChat();

  return (
    <main className="bg-gray-50">
      <ChatContainer
        messages={messages}
        onSendMessage={sendMessage}
        onNewChat={clearMessages}
        isLoading={isLoading}
      />
    </main>
  );
}
