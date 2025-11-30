import json
from channels.generic.websocket import AsyncWebsocketConsumer
from channels.db import database_sync_to_async
from conversations.models import ChatSession, Message


class ChatConsumer(AsyncWebsocketConsumer):
    async def connect(self):
        self.room_id = self.scope['url_route']['kwargs']['room_id']
        self.room_group_name = f'chat_{self.room_id}'

        # Unirse al grupo
        await self.channel_layer.group_add(
            self.room_group_name,
            self.channel_name
        )

        await self.accept()

        # Crear o obtener sesión de chat
        self.chat_session = await self.get_or_create_session()

        # Enviar historial de mensajes
        messages = await self.get_messages()
        await self.send(text_data=json.dumps({
            'type': 'chat_history',
            'messages': messages
        }))

    async def disconnect(self, close_code):
        # Salir del grupo
        await self.channel_layer.group_discard(
            self.room_group_name,
            self.channel_name
        )

    async def receive(self, text_data):
        text_data_json = json.loads(text_data)
        message = text_data_json.get('message', '')
        sender = text_data_json.get('sender', 'user')
        sender_name = text_data_json.get('sender_name', 'Usuario')

        if message:
            # Guardar mensaje en BD
            saved_message = await self.save_message(message, sender, sender_name)

            # Enviar mensaje al grupo
            await self.channel_layer.group_send(
                self.room_group_name,
                {
                    'type': 'chat_message',
                    'message': message,
                    'sender': sender,
                    'sender_name': sender_name,
                    'message_id': saved_message['id'],
                    'timestamp': saved_message['timestamp']
                }
            )

    async def chat_message(self, event):
        # Enviar mensaje al WebSocket
        await self.send(text_data=json.dumps({
            'type': 'chat_message',
            'message': event['message'],
            'sender': event['sender'],
            'sender_name': event['sender_name'],
            'message_id': event['message_id'],
            'timestamp': event['timestamp']
        }))

    @database_sync_to_async
    def get_or_create_session(self):
        session, created = ChatSession.objects.get_or_create(
            room_id=self.room_id,
            defaults={
                'status': 'active'
            }
        )
        return session

    @database_sync_to_async
    def save_message(self, content, sender, sender_name):
        conversation = self.chat_session.conversation if hasattr(self.chat_session, 'conversation') else None
        
        if not conversation:
            from conversations.models import Conversation
            conversation = Conversation.objects.create(
                user_id=f'user_{self.room_id}',
                conversation_type='live_chat'
            )
            self.chat_session.conversation = conversation
            self.chat_session.save()

        message = Message.objects.create(
            conversation=conversation,
            content=content,
            sender=sender,
            sender_name=sender_name,
            message_type='text'
        )

        return {
            'id': message.id,
            'timestamp': message.created_at.isoformat()
        }

    @database_sync_to_async
    def get_messages(self):
        if not hasattr(self.chat_session, 'conversation') or not self.chat_session.conversation:
            return []

        messages = Message.objects.filter(
            conversation=self.chat_session.conversation
        ).order_by('created_at')[:50]

        return [
            {
                'id': msg.id,
                'content': msg.content,
                'sender': msg.sender,
                'sender_name': msg.sender_name or 'Usuario',
                'timestamp': msg.created_at.isoformat()
            }
            for msg in messages
        ]

