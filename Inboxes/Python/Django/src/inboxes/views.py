import json
import os
from django.conf import settings
from django.core.cache import cache
from django.http import FileResponse, JsonResponse
from django.shortcuts import render
from django.views.decorators.csrf import csrf_exempt
from .models import Message

CACHE_TTL = getattr(settings, 'CACHE_TTL', 300)

def index(request):
    return render(request, 'inboxes/index.html')

def openapi_spec(request):
    path = os.path.join(os.path.dirname(__file__), 'static', 'openapi.json')
    return FileResponse(open(path, 'rb'), content_type='application/json')

def swagger(request):
    path = os.path.join(os.path.dirname(__file__), 'static', 'swagger.html')
    return FileResponse(open(path, 'rb'), content_type='text/html')

@csrf_exempt
def messages_handler(request):
    if request.method == 'GET':
        cached = cache.get('messages:all')
        if cached is not None:
            return JsonResponse({'messages': cached})
        msgs = list(Message.objects.values())
        cache.set('messages:all', msgs, CACHE_TTL)
        return JsonResponse({'messages': msgs})
    elif request.method == 'POST':
        try:
            data = json.loads(request.body)
        except json.JSONDecodeError:
            return JsonResponse({'error': 'Invalid JSON'}, status=400)
        sender = data.get('sender', '').strip()
        subject = data.get('subject', '').strip()
        body = data.get('body', '').strip()
        if not sender:
            return JsonResponse({'error': 'Sender is required'}, status=400)
        msg = Message.objects.create(sender=sender, subject=subject, body=body)
        cache.delete('messages:all')
        return JsonResponse({'message': {'id': msg.id, 'sender': msg.sender, 'subject': msg.subject, 'body': msg.body, 'timestamp': msg.created_at.isoformat()}}, status=201)
    return JsonResponse({'error': 'Method not allowed'}, status=405)

@csrf_exempt
def message_detail(request, message_id):
    if request.method == 'GET':
        cached = cache.get('message:' + str(message_id))
        if cached is not None:
            return JsonResponse({'message': cached})
        try:
            msg = Message.objects.get(id=message_id)
            msg.read = True
            msg.save()
            data = {'id': msg.id, 'sender': msg.sender, 'subject': msg.subject, 'body': msg.body, 'read': msg.read, 'timestamp': msg.created_at.isoformat()}
            cache.set('message:' + str(message_id), data, CACHE_TTL)
            cache.delete('messages:all')
            return JsonResponse({'message': data})
        except Message.DoesNotExist:
            return JsonResponse({'error': 'Message not found'}, status=404)
    elif request.method == 'DELETE':
        deleted = Message.objects.filter(id=message_id).delete()[0]
        if deleted:
            cache.delete('messages:all')
            cache.delete('message:' + str(message_id))
            return JsonResponse({'deleted': True})
        return JsonResponse({'error': 'Message not found'}, status=404)
    return JsonResponse({'error': 'Method not allowed'}, status=405)
