<?php

namespace App\Http\Controllers;

use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;

class ChronometerController extends Controller
{
    private static $running = false;
    private static $startedAt = 0.0;
    private static $elapsed = 0.0;
    private static $laps = [];

    public function index()
    {
        return view('chronometer');
    }

    public function state(): JsonResponse
    {
        return response()->json([
            'running' => self::$running,
            'elapsed' => self::$running ? (microtime(true) - self::$startedAt + self::$elapsed) : self::$elapsed,
            'laps' => self::$laps,
        ]);
    }

    public function start(): JsonResponse
    {
        if (self::$running) {
            return response()->json(['error' => 'Already running'], 400);
        }
        self::$running = true;
        self::$startedAt = microtime(true);
        return response()->json(['message' => 'Started']);
    }

    public function stop(): JsonResponse
    {
        if (!self::$running) {
            return response()->json(['error' => 'Not running'], 400);
        }
        self::$elapsed += microtime(true) - self::$startedAt;
        self::$running = false;
        return response()->json(['elapsed' => self::$elapsed]);
    }

    public function reset(): JsonResponse
    {
        self::$running = false;
        self::$startedAt = 0.0;
        self::$laps = [];
        self::$elapsed = 0.0;
        return response()->json(['message' => 'Reset']);
    }

    public function lap(): JsonResponse
    {
        if (!self::$running) {
            return response()->json(['error' => 'Not running'], 400);
        }
        $lap = microtime(true) - self::$startedAt + self::$elapsed;
        self::$laps[] = $lap;
        return response()->json(['lap' => $lap, 'laps' => self::$laps]);
    }
}
