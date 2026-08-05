<?php
namespace App\Http\Controllers;

use App\Models\PasswordEntry;
use App\Services\CacheService;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;

class PasswordGeneratorController extends Controller
{
    private $cache;

    public function __construct()
    {
        $this->cache = new CacheService();
    }

    public function index()
    {
        return view('passwordgenerator');
    }

    public function generate(Request $request): JsonResponse
    {
        $length = (int) $request->input('length', 16);
        $useUpper = $request->input('use_upper', true);
        $useLower = $request->input('use_lower', true);
        $useDigits = $request->input('use_digits', true);
        $useSymbols = $request->input('use_symbols', false);

        $chars = '';
        if ($useUpper) $chars .= 'ABCDEFGHIJKLMNOPQRSTUVWXYZ';
        if ($useLower) $chars .= 'abcdefghijklmnopqrstuvwxyz';
        if ($useDigits) $chars .= '0123456789';
        if ($useSymbols) $chars .= '!@#$%^&*()_+-=[]{}|;:,.<>?';

        $password = '';
        $max = strlen($chars) - 1;
        for ($i = 0; $i < $length; $i++) {
            $password .= $chars[random_int(0, $max)];
        }

        $entry = PasswordEntry::create(['password' => $password, 'length' => $length]);
        $this->cache->delete('passwords:recent');
        return response()->json(['password' => $password, 'id' => $entry->id]);
    }

    public function history(): JsonResponse
    {
        $cached = $this->cache->get('passwords:recent');
        if ($cached !== null) {
            return response()->json($cached);
        }
        $entries = PasswordEntry::orderBy('id', 'desc')->take(50)->get();
        $this->cache->set('passwords:recent', $entries->toArray());
        return response()->json($entries);
    }
}
