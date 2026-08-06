import json
import os

from django.http import FileResponse, JsonResponse
from django.shortcuts import render
from django.views.decorators.csrf import csrf_exempt
from django.views.decorators.http import require_http_methods

CONVERSIONS = {
    'length': {
        'meter': 1.0, 'kilometer': 1000.0, 'centimeter': 0.01,
        'millimeter': 0.001, 'mile': 1609.344, 'yard': 0.9144,
        'foot': 0.3048, 'inch': 0.0254,
    },
    'weight': {
        'kilogram': 1.0, 'gram': 0.001, 'milligram': 0.000001,
        'pound': 0.453592, 'ounce': 0.0283495,
    },
    'temperature': {
        'celsius': 'celsius', 'fahrenheit': 'fahrenheit', 'kelvin': 'kelvin',
    },
}


def _convert_temperature(value, from_unit, to_unit):
    if from_unit == to_unit:
        return value
    if from_unit == 'celsius':
        if to_unit == 'fahrenheit':
            return value * 9/5 + 32
        if to_unit == 'kelvin':
            return value + 273.15
    if from_unit == 'fahrenheit':
        if to_unit == 'celsius':
            return (value - 32) * 5/9
        if to_unit == 'kelvin':
            return (value - 32) * 5/9 + 273.15
    if from_unit == 'kelvin':
        if to_unit == 'celsius':
            return value - 273.15
        if to_unit == 'fahrenheit':
            return (value - 273.15) * 9/5 + 32
    return value


def index(request):
    return render(request, 'conversor/index.html')


def openapi_spec(request):
    path = os.path.join(os.path.dirname(__file__), 'static', 'openapi.json')
    return FileResponse(open(path, 'rb'), content_type='application/json')


def swagger(request):
    path = os.path.join(os.path.dirname(__file__), 'static', 'swagger.html')
    return FileResponse(open(path, 'rb'), content_type='text/html')


@csrf_exempt
@require_http_methods(['POST'])
def convert(request):
    try:
        data = json.loads(request.body)
    except json.JSONDecodeError:
        return JsonResponse({'error': 'Invalid JSON'}, status=400)

    value = data.get('value')
    from_unit = data.get('from', '').lower()
    to_unit = data.get('to', '').lower()

    if value is None:
        return JsonResponse({'error': 'Value is required'}, status=400)
    try:
        value = float(value)
    except (TypeError, ValueError):
        return JsonResponse({'error': 'Value must be a number'}, status=400)

    if from_unit in CONVERSIONS['temperature'] and to_unit in CONVERSIONS['temperature']:
        result = _convert_temperature(value, from_unit, to_unit)
        return JsonResponse({'result': result, 'unit': to_unit})

    for category, units in CONVERSIONS.items():
        if isinstance(units, dict) and from_unit in units and to_unit in units:
            result = value * units[from_unit] / units[to_unit]
            return JsonResponse({'result': result, 'unit': to_unit})

    return JsonResponse({'error': 'Unsupported conversion'}, status=400)
