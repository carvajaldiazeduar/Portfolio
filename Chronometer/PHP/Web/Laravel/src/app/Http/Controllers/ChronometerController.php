<?php
namespace App\Http\Controllers;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;

class ChronometerController extends Controller
{
    private static \ = false;
    private static \ = 0.0;
    private static \ = 0.0;
    private static \ = [];

    public function index()
    {
        return view('chronometer');
    }

    public function state(): JsonResponse
    {
        return response()->json([
            'running' => self::\,
            'elapsed' => self::\ ? (microtime(true) - self::\ + self::\) : self::\,
            'laps' => self::\,
        ]);
    }

    public function start(): JsonResponse
    {
        if (self::\) {
            return response()->json(['error' => 'Already running'], 400);
        }
        self::\ = true;
        self::\ = microtime(true);
        return response()->json(['message' => 'Started']);
    }

    public function stop(): JsonResponse
    {
        if (!self::\) {
            return response()->json(['error' => 'Not running'], 400);
        }
        self::\ += microtime(true) - self::\;
        self::\ = false;
        return response()->json(['elapsed' => self::\]);
    }

    public function reset(): JsonResponse
    {
        self::\ = false;
        self::\ = 0.0;
        self::\ = [];
        self::\ = 0.0;
        return response()->json(['message' => 'Reset']);
    }

    public function lap(): JsonResponse
    {
        if (!self::\) {
            return response()->json(['error' => 'Not running'], 400);
        }
        \ = microtime(true) - self::\ + self::\;
        self::\[] = \;
        return response()->json(['lap' => \, 'laps' => self::\]);
    }
}
