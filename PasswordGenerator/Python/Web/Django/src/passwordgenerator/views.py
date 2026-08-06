import json
import os
import random
import string
from django.conf import settings
from django.core.cache import cache
from django.http import FileResponse, JsonResponse
from django.shortcuts import render
from django.views.decorators.csrf import csrf_exempt
from django.views.decorators.http import require_http_methods
from .models import PasswordEntry

CACHE_TTL = getattr(settings, 'CACHE_TTL', 300)

def index(request):
    return render(request, 'passwordgenerator/index.html')

def openapi_spec(request):
    path = os.path.join(os.path.dirname(__file__), 'static', 'openapi.json')
    return FileResponse(open(path, 'rb'), content_type='application/json')

def swagger(request):
    path = os.path.join(os.path.dirname(__file__), 'static', 'swagger.html')
    return FileResponse(open(path, 'rb'), content_type='text/html')

@csrf_exempt
@require_http_methods(['POST'])
def generate(request):
    try:
        data = json.loads(request.body)
    except json.JSONDecodeError:
        return JsonResponse({'error': 'Invalid JSON'}, status=400)
    length = data.get('length', 12)
    use_upper = data.get('use_upper', True)
    use_lower = data.get('use_lower', True)
    use_digits = data.get('use_digits', True)
    use_symbols = data.get('use_symbols', False)
    if not isinstance(length, int) or length < 4 or length > 128:
        return JsonResponse({'error': 'Length must be between 4 and 128'}, status=400)
    chars = ''
    if use_upper:
        chars += string.ascii_uppercase
    if use_lower:
        chars += string.ascii_lowercase
    if use_digits:
        chars += string.digits
    if use_symbols:
        chars += string.punctuation
    if not chars:
        return JsonResponse({'error': 'At least one character type must be selected'}, status=400)
    password = ''.join(random.choice(chars) for _ in range(length))
    entry = PasswordEntry.objects.create(password=password, length=length)
    cache.delete('passwords:recent')
    return JsonResponse({'password': password, 'id': entry.id})

@csrf_exempt
@require_http_methods(['GET'])
def history(request):
    cached = cache.get('passwords:recent')
    if cached is not None:
        return JsonResponse({'passwords': cached})
    entries = list(PasswordEntry.objects.values().order_by('-id')[:50])
    cache.set('passwords:recent', entries, CACHE_TTL)
    return JsonResponse({'passwords': entries})
