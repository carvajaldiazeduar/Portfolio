import time

from django.http import JsonResponse
from django.shortcuts import render
from django.views.decorators.csrf import csrf_exempt
from django.views.decorators.http import require_http_methods

timer = {
    'running': False,
    'start_time': None,
    'elapsed': 0.0,
    'laps': [],
}


def index(request):
    return render(request, 'chronometer/index.html')


def _get_elapsed():
    if timer['running'] and timer['start_time']:
        return timer['elapsed'] + (time.time() - timer['start_time'])
    return timer['elapsed']


def state(request):
    return JsonResponse({
        'running': timer['running'],
        'elapsed': _get_elapsed(),
        'laps': timer['laps'],
    })


@csrf_exempt
@require_http_methods(['POST'])
def start(request):
    if not timer['running']:
        timer['running'] = True
        timer['start_time'] = time.time()
    return JsonResponse({'running': True, 'elapsed': _get_elapsed()})


@csrf_exempt
@require_http_methods(['POST'])
def stop(request):
    if timer['running']:
        timer['elapsed'] += (time.time() - timer['start_time'])
        timer['running'] = False
        timer['start_time'] = None
    return JsonResponse({'running': False, 'elapsed': timer['elapsed']})


@csrf_exempt
@require_http_methods(['POST'])
def reset(request):
    timer['running'] = False
    timer['start_time'] = None
    timer['elapsed'] = 0.0
    timer['laps'] = []
    return JsonResponse({'running': False, 'elapsed': 0.0, 'laps': []})


@csrf_exempt
@require_http_methods(['POST'])
def lap(request):
    if timer['running']:
        lap_time = _get_elapsed()
        timer['laps'].append(lap_time)
        return JsonResponse({'lap': lap_time, 'laps': timer['laps']})
    return JsonResponse({'error': 'Timer not running'}, status=400)
