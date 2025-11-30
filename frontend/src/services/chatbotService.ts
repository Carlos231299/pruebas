import axios from 'axios';

const API_BASE_URL = import.meta.env.VITE_API_URL || 'http://localhost:8000/api';

export interface ChatbotMessage {
  message: string;
  conversation_id?: string;
  user_id?: string;
}

export interface ChatbotResponse {
  response: string;
  conversation_id: string;
  message_id: string;
}

export const chatbotService = {
  async sendMessage(data: ChatbotMessage): Promise<ChatbotResponse> {
    const response = await axios.post<ChatbotResponse>(
      `${API_BASE_URL}/chatbot/message/`,
      data
    );
    return response.data;
  },
};

