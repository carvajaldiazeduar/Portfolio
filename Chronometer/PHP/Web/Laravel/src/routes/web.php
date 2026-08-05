<?php
use Illuminate\Support\Facades\Route;
use App\Http\Controllers\ChronometerController;

Route::get('/', [ChronometerController::class, 'index']);
Route::get('/api/state', [ChronometerController::class, 'state']);
Route::post('/api/start', [ChronometerController::class, 'start']);
Route::post('/api/stop', [ChronometerController::class, 'stop']);
Route::post('/api/reset', [ChronometerController::class, 'reset']);
Route::post('/api/lap', [ChronometerController::class, 'lap']);
