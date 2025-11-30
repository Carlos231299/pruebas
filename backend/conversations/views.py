from rest_framework.decorators import api_view
from rest_framework.response import Response
from rest_framework import status
from .models import Conversation, Message
from .serializers import ConversationSerializer, MessageSerializer


@api_view(['GET'])
def conversation_list(request):
    """
    Lista todas las conversaciones de un usuario
    """
    user_id = request.query_params.get('user_id', 'anonymous')
    conversations = Conversation.objects.filter(user_id=user_id)
    serializer = ConversationSerializer(conversations, many=True)
    return Response(serializer.data)


@api_view(['GET'])
def conversation_detail(request, conversation_id):
    """
    Obtiene los detalles de una conversación
    """
    try:
        conversation = Conversation.objects.get(id=conversation_id)
        serializer = ConversationSerializer(conversation)
        return Response(serializer.data)
    except Conversation.DoesNotExist:
        return Response(
            {'error': 'Conversación no encontrada'},
            status=status.HTTP_404_NOT_FOUND
        )


@api_view(['GET'])
def message_list(request, conversation_id):
    """
    Obtiene todos los mensajes de una conversación
    """
    try:
        conversation = Conversation.objects.get(id=conversation_id)
        messages = Message.objects.filter(conversation=conversation)
        serializer = MessageSerializer(messages, many=True)
        return Response(serializer.data)
    except Conversation.DoesNotExist:
        return Response(
            {'error': 'Conversación no encontrada'},
            status=status.HTTP_404_NOT_FOUND
        )

