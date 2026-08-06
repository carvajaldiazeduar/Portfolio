import json
import os
from django.conf import settings
from django.core.cache import cache
from django.http import FileResponse, JsonResponse
from django.shortcuts import render
from django.views.decorators.csrf import csrf_exempt
from .models import Contact

CACHE_TTL = getattr(settings, 'CACHE_TTL', 300)

def index(request):
    return render(request, 'contacts/index.html')

def openapi_spec(request):
    path = os.path.join(os.path.dirname(__file__), 'static', 'openapi.json')
    return FileResponse(open(path, 'rb'), content_type='application/json')

def swagger(request):
    path = os.path.join(os.path.dirname(__file__), 'static', 'swagger.html')
    return FileResponse(open(path, 'rb'), content_type='text/html')

@csrf_exempt
def contacts_handler(request):
    if request.method == 'GET':
        cached = cache.get('contacts:all')
        if cached is not None:
            return JsonResponse({'contacts': cached})
        contacts = list(Contact.objects.values())
        cache.set('contacts:all', contacts, CACHE_TTL)
        return JsonResponse({'contacts': contacts})

    elif request.method == 'POST':
        try:
            data = json.loads(request.body)
        except json.JSONDecodeError:
            return JsonResponse({'error': 'Invalid JSON'}, status=400)
        name = data.get('name', '').strip()
        phone = data.get('phone', '').strip()
        email = data.get('email', '').strip()
        if not name:
            return JsonResponse({'error': 'Name is required'}, status=400)
        contact = Contact.objects.create(name=name, phone=phone, email=email)
        cache.delete('contacts:all')
        return JsonResponse({'contact': {'id': contact.id, 'name': contact.name, 'phone': contact.phone, 'email': contact.email}}, status=201)

    return JsonResponse({'error': 'Method not allowed'}, status=405)

@csrf_exempt
def contact_detail(request, contact_id):
    if request.method == 'DELETE':
        deleted = Contact.objects.filter(id=contact_id).delete()[0]
        if deleted:
            cache.delete('contacts:all')
            return JsonResponse({'deleted': True})
        return JsonResponse({'error': 'Contact not found'}, status=404)
    return JsonResponse({'error': 'Method not allowed'}, status=405)
