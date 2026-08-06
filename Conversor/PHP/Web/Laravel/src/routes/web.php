<?php
use Illuminate\Support\Facades\Route;
use App\Http\Controllers\ConversorController;

Route::get('/', [ConversorController::class, 'index']);
Route::post('/api/convert', [ConversorController::class, 'convert']);
Route::get('/openapi.json', function () {
    return response()->file(public_path('openapi.json'));
});
Route::get('/swagger', function () {
    return response()->file(public_path('swagger.html'));
});
