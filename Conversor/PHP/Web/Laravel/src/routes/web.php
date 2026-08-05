<?php
use Illuminate\Support\Facades\Route;
use App\Http\Controllers\ConversorController;

Route::get('/', [ConversorController::class, 'index']);
Route::post('/api/convert', [ConversorController::class, 'convert']);
