<?php
use Illuminate\Support\Facades\Route;
use App\Http\Controllers\InboxesController;

Route::get('/', [InboxesController::class, 'index']);
Route::get('/api/messages', [InboxesController::class, 'list']);
Route::get('/api/messages/{id}', [InboxesController::class, 'read']);
Route::post('/api/messages', [InboxesController::class, 'create']);
Route::delete('/api/messages/{id}', [InboxesController::class, 'delete']);
