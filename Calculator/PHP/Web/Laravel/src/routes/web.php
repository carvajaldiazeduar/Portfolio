<?php

use Illuminate\Support\Facades\Route;
use App\Http\Controllers\CalculatorController;

Route::get('/', function () {
    return view('calculator');
});

Route::post('/calculate', [CalculatorController::class, 'calculate']);

Route::get('/openapi.json', function () {
    return response()->file(public_path('openapi.json'));
});

Route::get('/swagger', function () {
    return response()->file(public_path('swagger.html'));
});
