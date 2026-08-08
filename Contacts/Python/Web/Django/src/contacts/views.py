import json
import os
import re
from django.conf import settings
from django.core.cache import cache
from django.http import FileResponse, JsonResponse
from django.shortcuts import render
from django.views.decorators.csrf import csrf_exempt
from .models import Contact

CACHE_TTL = getattr(settings, 'CACHE_TTL', 300)

NAME_RE = re.compile(r"^[A-Za-zÀ-ÿ' .-]+$")
PHONE_RE = re.compile(r"^[0-9 +().-]{7,20}$")
EMAIL_RE = re.compile(r"^[^\s@]+@[^\s@]+\.[^\s@]{2,}$")

NAME_REQUIRED = "Name is required"
PHONE_REQUIRED = "Phone is required"
EMAIL_REQUIRED = "Email is required"
NAME_FORMAT = "Name must be 2-100 characters (letters, spaces, apostrophes, hyphens, dots)"
PHONE_FORMAT = "Phone must be 7-20 characters (digits, spaces, +, parentheses, dashes)"
EMAIL_FORMAT = "Invalid email format"

def validate_contact(data):
    errors = {}
    name = (data.get('name') or '').strip() if data else ''
    phone = (data.get('phone') or '').strip() if data else ''
    email = (data.get('email') or '').strip() if data else ''
    if not name:
        errors['name'] = NAME_REQUIRED
    elif not (2 <= len(name) <= 100) or not NAME_RE.match(name):
        errors['name'] = NAME_FORMAT
    if not phone:
        errors['phone'] = PHONE_REQUIRED
    elif not PHONE_RE.match(phone):
        errors['phone'] = PHONE_FORMAT
    if not email:
        errors['email'] = EMAIL_REQUIRED
    elif not EMAIL_RE.match(email):
        errors['email'] = EMAIL_FORMAT
    return errors, {'name': name, 'phone': phone, 'email': email}

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
            return JsonResponse({'errors': {'name': NAME_REQUIRED, 'phone': PHONE_REQUIRED, 'email': EMAIL_REQUIRED}}, status=400)
        errors, values = validate_contact(data)
        if errors:
            return JsonResponse({'errors': errors}, status=400)
        contact = Contact.objects.create(name=values['name'], phone=values['phone'], email=values['email'])
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
