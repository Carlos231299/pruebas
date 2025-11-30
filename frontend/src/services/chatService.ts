export interface ChatMessage {
  id?: string;
  content: string;
  sender: 'user' | 'advisor' | 'bot';
  sender_name?: string;
  timestamp?: string;
}

export class ChatService {
  private ws: WebSocket | null = null;
  private roomId: string;
  private onMessageCallback: ((message: ChatMessage) => void) | null = null;
  private onHistoryCallback: ((messages: ChatMessage[]) => void) | null = null;
  private reconnectAttempts = 0;
  private maxReconnectAttempts = 5;

  constructor(roomId: string) {
    this.roomId = roomId;
  }

  connect(): Promise<void> {
    return new Promise((resolve, reject) => {
      const wsUrl = import.meta.env.VITE_WS_URL || 
        `ws://localhost:8000/ws/chat/${this.roomId}/`;
      
      this.ws = new WebSocket(wsUrl);

      this.ws.onopen = () => {
        this.reconnectAttempts = 0;
        resolve();
      };

      this.ws.onmessage = (event) => {
        const data = JSON.parse(event.data);
        
        if (data.type === 'chat_history' && this.onHistoryCallback) {
          this.onHistoryCallback(data.messages);
        } else if (data.type === 'chat_message' && this.onMessageCallback) {
          this.onMessageCallback({
            id: data.message_id,
            content: data.message,
            sender: data.sender,
            sender_name: data.sender_name,
            timestamp: data.timestamp,
          });
        }
      };

      this.ws.onerror = (error) => {
        reject(error);
      };

      this.ws.onclose = () => {
        if (this.reconnectAttempts < this.maxReconnectAttempts) {
          this.reconnectAttempts++;
          setTimeout(() => {
            this.connect().catch(console.error);
          }, 1000 * this.reconnectAttempts);
        }
      };
    });
  }

  sendMessage(message: string, sender: 'user' | 'advisor' = 'user', senderName: string = 'Usuario'): void {
    if (this.ws && this.ws.readyState === WebSocket.OPEN) {
      this.ws.send(JSON.stringify({
        message,
        sender,
        sender_name: senderName,
      }));
    }
  }

  onMessage(callback: (message: ChatMessage) => void): void {
    this.onMessageCallback = callback;
  }

  onHistory(callback: (messages: ChatMessage[]) => void): void {
    this.onHistoryCallback = callback;
  }

  disconnect(): void {
    if (this.ws) {
      this.ws.close();
      this.ws = null;
    }
  }

  isConnected(): boolean {
    return this.ws !== null && this.ws.readyState === WebSocket.OPEN;
  }
}

