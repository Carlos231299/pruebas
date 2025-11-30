from django.db import models
import uuid


class Conversation(models.Model):
    id = models.UUIDField(primary_key=True, default=uuid.uuid4, editable=False)
    user_id = models.CharField(max_length=255)
    conversation_type = models.CharField(
        max_length=50,
        choices=[
            ('chatbot', 'Chatbot'),
            ('live_chat', 'Chat en Vivo'),
        ],
        default='chatbot'
    )
    created_at = models.DateTimeField(auto_now_add=True)
    updated_at = models.DateTimeField(auto_now=True)

    class Meta:
        ordering = ['-created_at']

    def __str__(self):
        return f"{self.conversation_type} - {self.user_id}"


class Message(models.Model):
    id = models.UUIDField(primary_key=True, default=uuid.uuid4, editable=False)
    conversation = models.ForeignKey(
        Conversation,
        related_name='messages',
        on_delete=models.CASCADE
    )
    content = models.TextField()
    sender = models.CharField(
        max_length=50,
        choices=[
            ('user', 'Usuario'),
            ('bot', 'Bot'),
            ('advisor', 'Asesor'),
        ]
    )
    sender_name = models.CharField(max_length=255, null=True, blank=True)
    message_type = models.CharField(
        max_length=50,
        choices=[
            ('text', 'Texto'),
            ('image', 'Imagen'),
            ('file', 'Archivo'),
        ],
        default='text'
    )
    created_at = models.DateTimeField(auto_now_add=True)

    class Meta:
        ordering = ['created_at']

    def __str__(self):
        return f"{self.sender} - {self.content[:50]}"


class ChatSession(models.Model):
    id = models.UUIDField(primary_key=True, default=uuid.uuid4, editable=False)
    room_id = models.CharField(max_length=255, unique=True)
    conversation = models.OneToOneField(
        Conversation,
        related_name='chat_session',
        on_delete=models.CASCADE,
        null=True,
        blank=True
    )
    status = models.CharField(
        max_length=50,
        choices=[
            ('waiting', 'Esperando Asesor'),
            ('active', 'Activa'),
            ('closed', 'Cerrada'),
        ],
        default='waiting'
    )
    advisor_id = models.CharField(max_length=255, null=True, blank=True)
    created_at = models.DateTimeField(auto_now_add=True)
    updated_at = models.DateTimeField(auto_now=True)

    class Meta:
        ordering = ['-created_at']

    def __str__(self):
        return f"Sesión {self.room_id} - {self.status}"

