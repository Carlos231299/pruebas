import axios from 'axios';

const API_BASE_URL = import.meta.env.VITE_API_URL || 'http://localhost:8000/api';

export interface Message {
  id: string;
  content: string;
  sender: string;
  sender_name?: string;
  message_type: string;
  created_at: string;
}

export interface Conversation {
  id: string;
  user_id: string;
  conversation_type: string;
  created_at: string;
  updated_at: string;
  messages: Message[];
  message_count: number;
}

export const conversationService = {
  async getConversations(userId: string = 'anonymous'): Promise<Conversation[]> {
    const response = await axios.get<Conversation[]>(
      `${API_BASE_URL}/conversations/`,
      { params: { user_id: userId } }
    );
    return response.data;
  },

  async getConversation(conversationId: string): Promise<Conversation> {
    const response = await axios.get<Conversation>(
      `${API_BASE_URL}/conversations/${conversationId}/`
    );
    return response.data;
  },

  async getMessages(conversationId: string): Promise<Message[]> {
    const response = await axios.get<Message[]>(
      `${API_BASE_URL}/conversations/${conversationId}/messages/`
    );
    return response.data;
  },
};

