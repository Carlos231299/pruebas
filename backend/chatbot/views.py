from rest_framework.decorators import api_view
from rest_framework.response import Response
from rest_framework import status
from django.conf import settings
from openai import OpenAI
from conversations.models import Conversation, Message
import json

client = OpenAI(api_key=settings.OPENAI_API_KEY) if settings.OPENAI_API_KEY else None


@api_view(['POST'])
def chatbot_message(request):
    """
    Endpoint para recibir mensajes del chatbot y obtener respuestas de OpenAI
    """
    if not client:
        return Response(
            {'error': 'OpenAI API key no configurada'},
            status=status.HTTP_500_INTERNAL_SERVER_ERROR
        )

    message = request.data.get('message', '')
    conversation_id = request.data.get('conversation_id', None)
    user_id = request.data.get('user_id', 'anonymous')

    if not message:
        return Response(
            {'error': 'El mensaje es requerido'},
            status=status.HTTP_400_BAD_REQUEST
        )

    # Obtener o crear conversación
    if conversation_id:
        try:
            conversation = Conversation.objects.get(id=conversation_id)
        except Conversation.DoesNotExist:
            conversation = None
    else:
        conversation = None

    if not conversation:
        conversation = Conversation.objects.create(
            user_id=user_id,
            conversation_type='chatbot'
        )

    # Guardar mensaje del usuario
    user_message = Message.objects.create(
        conversation=conversation,
        content=message,
        sender='user',
        message_type='text'
    )

    # Obtener historial de mensajes para contexto
    previous_messages = Message.objects.filter(
        conversation=conversation
    ).order_by('created_at')[:10]

    # Construir mensajes para OpenAI
    messages = []
    for msg in previous_messages:
        role = 'user' if msg.sender == 'user' else 'assistant'
        messages.append({
            'role': role,
            'content': msg.content
        })

    try:
        # Llamar a OpenAI
        response = client.chat.completions.create(
            model="gpt-3.5-turbo",
            messages=messages,
            temperature=0.7,
            max_tokens=500
        )

        bot_response = response.choices[0].message.content

        # Guardar respuesta del bot
        bot_message = Message.objects.create(
            conversation=conversation,
            content=bot_response,
            sender='bot',
            message_type='text'
        )

        return Response({
            'response': bot_response,
            'conversation_id': conversation.id,
            'message_id': bot_message.id
        }, status=status.HTTP_200_OK)

    except Exception as e:
        return Response(
            {'error': f'Error al procesar mensaje: {str(e)}'},
            status=status.HTTP_500_INTERNAL_SERVER_ERROR
        )

