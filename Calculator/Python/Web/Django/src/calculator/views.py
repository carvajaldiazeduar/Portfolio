import json

from django.http import JsonResponse
from django.shortcuts import render
from django.views.decorators.csrf import csrf_exempt
from django.views.decorators.http import require_http_methods


def index(request):
    return render(request, 'calculator/index.html')


@csrf_exempt
@require_http_methods(['POST'])
def calculate(request):
    try:
        data = json.loads(request.body)
    except json.JSONDecodeError:
        return JsonResponse({'error': 'Invalid JSON'}, status=400)

    a = data.get('a')
    b = data.get('b')
    operator = data.get('operator')

    if a is None or b is None or operator is None:
        return JsonResponse({'error': 'Missing required fields: a, b, operator'}, status=400)

    try:
        a = float(a)
        b = float(b)
    except (TypeError, ValueError):
        return JsonResponse({'error': 'a and b must be numbers'}, status=400)

    if operator == '+':
        result = a + b
    elif operator == '-':
        result = a - b
    elif operator == '*':
        result = a * b
    elif operator == '/':
        if b == 0:
            return JsonResponse({'error': 'Cannot divide by zero'}, status=400)
        result = a / b
    else:
        return JsonResponse({'error': f'Unsupported operator: {operator}'}, status=400)

    return JsonResponse({'result': result})
