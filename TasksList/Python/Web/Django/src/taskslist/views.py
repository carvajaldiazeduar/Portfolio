import json
import os
from django.conf import settings
from django.core.cache import cache
from django.http import FileResponse, JsonResponse
from django.shortcuts import render
from django.views.decorators.csrf import csrf_exempt
from .models import Task

CACHE_TTL = getattr(settings, 'CACHE_TTL', 300)

def index(request):
    return render(request, 'taskslist/index.html')

def openapi_spec(request):
    path = os.path.join(os.path.dirname(__file__), 'static', 'openapi.json')
    return FileResponse(open(path, 'rb'), content_type='application/json')

def swagger(request):
    path = os.path.join(os.path.dirname(__file__), 'static', 'swagger.html')
    return FileResponse(open(path, 'rb'), content_type='text/html')

@csrf_exempt
def tasks_handler(request):
    if request.method == 'GET':
        cached = cache.get('tasks:all')
        if cached is not None:
            return JsonResponse({'tasks': cached})
        tasks = list(Task.objects.values())
        cache.set('tasks:all', tasks, CACHE_TTL)
        return JsonResponse({'tasks': tasks})
    elif request.method == 'POST':
        try:
            data = json.loads(request.body)
        except json.JSONDecodeError:
            return JsonResponse({'error': 'Invalid JSON'}, status=400)
        title = data.get('title', '').strip()
        if not title:
            return JsonResponse({'error': 'Title is required'}, status=400)
        task = Task.objects.create(title=title)
        cache.delete('tasks:all')
        return JsonResponse({'task': {'id': task.id, 'title': task.title, 'completed': task.completed}}, status=201)
    return JsonResponse({'error': 'Method not allowed'}, status=405)

@csrf_exempt
def complete_task(request, task_id):
    if request.method == 'PUT':
        updated = Task.objects.filter(id=task_id).update(completed=True)
        if updated:
            cache.delete('tasks:all')
            task = Task.objects.get(id=task_id)
            return JsonResponse({'task': {'id': task.id, 'title': task.title, 'completed': task.completed}})
        return JsonResponse({'error': 'Task not found'}, status=404)
    return JsonResponse({'error': 'Method not allowed'}, status=405)

@csrf_exempt
def task_detail(request, task_id):
    if request.method == 'DELETE':
        deleted = Task.objects.filter(id=task_id).delete()[0]
        if deleted:
            cache.delete('tasks:all')
            return JsonResponse({'deleted': True})
        return JsonResponse({'error': 'Task not found'}, status=404)
    return JsonResponse({'error': 'Method not allowed'}, status=405)
