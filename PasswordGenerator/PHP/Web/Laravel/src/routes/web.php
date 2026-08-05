<?php
use Illuminate\Support\Facades\Route;
use App\Http\Controllers\PasswordGeneratorController;

Route::get('/', [PasswordGeneratorController::class, 'index']);
Route::post('/api/generate', [PasswordGeneratorController::class, 'generate']);
