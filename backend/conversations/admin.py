from django.contrib import admin
from .models import Conversation, Message, ChatSession


@admin.register(Conversation)
class ConversationAdmin(admin.ModelAdmin):
    list_display = ['id', 'user_id', 'conversation_type', 'created_at']
    list_filter = ['conversation_type', 'created_at']
    search_fields = ['user_id']


@admin.register(Message)
class MessageAdmin(admin.ModelAdmin):
    list_display = ['id', 'conversation', 'sender', 'sender_name', 'created_at']
    list_filter = ['sender', 'message_type', 'created_at']
    search_fields = ['content']


@admin.register(ChatSession)
class ChatSessionAdmin(admin.ModelAdmin):
    list_display = ['id', 'room_id', 'status', 'advisor_id', 'created_at']
    list_filter = ['status', 'created_at']
    search_fields = ['room_id', 'advisor_id']

