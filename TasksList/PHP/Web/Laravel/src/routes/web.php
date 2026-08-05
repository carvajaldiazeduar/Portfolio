<?php
use Illuminate\Support\Facades\Route;
use App\Http\Controllers\TasksListController;

Route::get('/', [TasksListController::class, 'index']);
Route::get('/api/tasks', [TasksListController::class, 'list']);
Route::post('/api/tasks', [TasksListController::class, 'create']);
Route::put('/api/tasks/{id}/complete', [TasksListController::class, 'complete']);
Route::delete('/api/tasks/{id}', [TasksListController::class, 'delete']);
