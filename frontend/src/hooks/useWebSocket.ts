import { useEffect, useRef, useState, useCallback } from 'react';
import { ChatService, ChatMessage } from '../services/chatService';

export const useWebSocket = (roomId: string) => {
  const [messages, setMessages] = useState<ChatMessage[]>([]);
  const [isConnected, setIsConnected] = useState(false);
  const [error, setError] = useState<string | null>(null);
  const chatServiceRef = useRef<ChatService | null>(null);

  useEffect(() => {
    const chatService = new ChatService(roomId);
    chatServiceRef.current = chatService;

    chatService.onHistory((historyMessages) => {
      setMessages(historyMessages);
    });

    chatService.onMessage((message) => {
      setMessages((prev) => [...prev, message]);
    });

    chatService
      .connect()
      .then(() => {
        setIsConnected(true);
        setError(null);
      })
      .catch((err) => {
        setError('Error al conectar con el servidor');
        console.error(err);
      });

    return () => {
      chatService.disconnect();
    };
  }, [roomId]);

  const sendMessage = useCallback((message: string, sender: 'user' | 'advisor' = 'user', senderName: string = 'Usuario') => {
    if (chatServiceRef.current) {
      chatServiceRef.current.sendMessage(message, sender, senderName);
    }
  }, []);

  return {
    messages,
    isConnected,
    error,
    sendMessage,
  };
};

