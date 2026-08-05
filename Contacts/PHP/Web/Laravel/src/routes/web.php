<?php
use Illuminate\Support\Facades\Route;
use App\Http\Controllers\ContactsController;

Route::get('/', [ContactsController::class, 'index']);
Route::get('/api/contacts', [ContactsController::class, 'list']);
Route::post('/api/contacts', [ContactsController::class, 'create']);
Route::delete('/api/contacts/{id}', [ContactsController::class, 'delete']);
