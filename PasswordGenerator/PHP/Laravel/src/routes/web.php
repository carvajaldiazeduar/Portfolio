<?php
use Illuminate\Support\Facades\Route;
use App\Http\Controllers\PasswordGeneratorController;

Route::get('/', [PasswordGeneratorController::class, 'index']);
Route::post('/api/generate', [PasswordGeneratorController::class, 'generate']);
Route::get('/openapi.json', function () {
    return response()->file(public_path('openapi.json'));
});
Route::get('/swagger', function () {
    return response()->file(public_path('swagger.html'));
});
