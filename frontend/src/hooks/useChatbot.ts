import { useState, useCallback } from 'react';
import { chatbotService, ChatbotResponse } from '../services/chatbotService';

export const useChatbot = () => {
  const [loading, setLoading] = useState(false);
  const [error, setError] = useState<string | null>(null);
  const [conversationId, setConversationId] = useState<string | null>(null);

  const sendMessage = useCallback(async (
    message: string,
    userId: string = 'anonymous'
  ): Promise<string | null> => {
    setLoading(true);
    setError(null);

    try {
      const response: ChatbotResponse = await chatbotService.sendMessage({
        message,
        conversation_id: conversationId || undefined,
        user_id: userId,
      });

      setConversationId(response.conversation_id);
      return response.response;
    } catch (err: any) {
      const errorMessage = err.response?.data?.error || 'Error al enviar mensaje';
      setError(errorMessage);
      return null;
    } finally {
      setLoading(false);
    }
  }, [conversationId]);

  return {
    sendMessage,
    loading,
    error,
    conversationId,
  };
};

