import { useState, useRef, useEffect } from 'react';
import { useChatbot } from '../hooks/useChatbot';
import { useWebSocket } from '../hooks/useWebSocket';
import './ChatInterface.css';

type ChatMode = 'chatbot' | 'advisor';

interface Message {
  id?: string;
  content: string;
  sender: 'user' | 'bot' | 'advisor';
  sender_name?: string;
  timestamp?: string;
}

export const ChatInterface = () => {
  const [mode, setMode] = useState<ChatMode>('chatbot');
  const [inputMessage, setInputMessage] = useState('');
  const [chatbotMessages, setChatbotMessages] = useState<Message[]>([]);
  const messagesEndRef = useRef<HTMLDivElement>(null);
  const roomIdRef = useRef<string>(`room_${Date.now()}`);

  const { sendMessage: sendChatbotMessage, loading: chatbotLoading, error: chatbotError } = useChatbot();
  const { messages: advisorMessages, isConnected, sendMessage: sendAdvisorMessage } = useWebSocket(roomIdRef.current);

  const scrollToBottom = () => {
    messagesEndRef.current?.scrollIntoView({ behavior: 'smooth' });
  };

  useEffect(() => {
    scrollToBottom();
  }, [chatbotMessages, advisorMessages]);

  const handleSendMessage = async () => {
    if (!inputMessage.trim()) return;

    const userMessage: Message = {
      content: inputMessage,
      sender: 'user',
      timestamp: new Date().toISOString(),
    };

    if (mode === 'chatbot') {
      setChatbotMessages((prev) => [...prev, userMessage]);
      const botResponse = await sendChatbotMessage(inputMessage);
      
      if (botResponse) {
        setChatbotMessages((prev) => [
          ...prev,
          {
            content: botResponse,
            sender: 'bot',
            timestamp: new Date().toISOString(),
          },
        ]);
      }
    } else {
      sendAdvisorMessage(inputMessage, 'user', 'Usuario');
    }

    setInputMessage('');
  };

  const handleKeyPress = (e: React.KeyboardEvent) => {
    if (e.key === 'Enter' && !e.shiftKey) {
      e.preventDefault();
      handleSendMessage();
    }
  };

  const currentMessages = mode === 'chatbot' ? chatbotMessages : advisorMessages;

  return (
    <div className="chat-container">
      <div className="chat-header">
        <h1>Plataforma de Recepción</h1>
        <div className="mode-toggle">
          <button
            className={mode === 'chatbot' ? 'active' : ''}
            onClick={() => setMode('chatbot')}
          >
            Chatbot
          </button>
          <button
            className={mode === 'advisor' ? 'active' : ''}
            onClick={() => setMode('advisor')}
          >
            Hablar con Asesor
          </button>
        </div>
      </div>

      <div className="chat-messages">
        {mode === 'advisor' && !isConnected && (
          <div className="connection-status">
            Conectando con el servidor...
          </div>
        )}
        {mode === 'advisor' && isConnected && (
          <div className="connection-status connected">
            Conectado - Esperando asesor disponible
          </div>
        )}
        {chatbotError && mode === 'chatbot' && (
          <div className="error-message">{chatbotError}</div>
        )}
        {currentMessages.length === 0 && (
          <div className="empty-state">
            {mode === 'chatbot'
              ? '¡Hola! Soy tu asistente virtual. ¿En qué puedo ayudarte?'
              : 'Conectado. Un asesor se pondrá en contacto contigo pronto.'}
          </div>
        )}
        {currentMessages.map((message, index) => (
          <div
            key={message.id || index}
            className={`message ${message.sender === 'user' ? 'user-message' : 'bot-message'}`}
          >
            <div className="message-header">
              <span className="sender-name">
                {message.sender === 'user'
                  ? 'Tú'
                  : message.sender_name || (message.sender === 'bot' ? 'Chatbot' : 'Asesor')}
              </span>
              {message.timestamp && (
                <span className="message-time">
                  {new Date(message.timestamp).toLocaleTimeString('es-ES', {
                    hour: '2-digit',
                    minute: '2-digit',
                  })}
                </span>
              )}
            </div>
            <div className="message-content">{message.content}</div>
          </div>
        ))}
        {chatbotLoading && mode === 'chatbot' && (
          <div className="message bot-message">
            <div className="message-content">
              <div className="typing-indicator">
                <span></span>
                <span></span>
                <span></span>
              </div>
            </div>
          </div>
        )}
        <div ref={messagesEndRef} />
      </div>

      <div className="chat-input-container">
        <input
          type="text"
          className="chat-input"
          placeholder={mode === 'chatbot' ? 'Escribe tu mensaje...' : 'Escribe tu mensaje al asesor...'}
          value={inputMessage}
          onChange={(e) => setInputMessage(e.target.value)}
          onKeyPress={handleKeyPress}
          disabled={chatbotLoading || (mode === 'advisor' && !isConnected)}
        />
        <button
          className="send-button"
          onClick={handleSendMessage}
          disabled={!inputMessage.trim() || chatbotLoading || (mode === 'advisor' && !isConnected)}
        >
          Enviar
        </button>
      </div>
    </div>
  );
};

