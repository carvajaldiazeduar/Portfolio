<?php

use Illuminate\Support\Facades\Route;
use App\Http\Controllers\CalculatorController;

Route::get('/', function () {
    return view('calculator');
});

Route::post('/calculate', [CalculatorController::class, 'calculate']);
