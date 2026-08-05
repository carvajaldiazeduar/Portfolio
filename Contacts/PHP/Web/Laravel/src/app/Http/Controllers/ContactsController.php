<?php
namespace App\Http\Controllers;
use App\Models\Contact;
use App\Services\CacheService;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;

class ContactsController extends Controller
{
    private $cache;

    public function __construct()
    {
        $this->cache = new CacheService();
    }

    public function index()
    {
        return view('contacts');
    }

    public function list(): JsonResponse
    {
        $cached = $this->cache->get('contacts:all');
        if ($cached !== null) {
            return response()->json($cached);
        }
        $contacts = Contact::orderBy('id')->get();
        $data = $contacts->toArray();
        $this->cache->set('contacts:all', $data);
        return response()->json($data);
    }

    public function create(Request $request): JsonResponse
    {
        $validated = $request->validate([
            'name' => 'required|string|max:255',
            'email' => 'nullable|email|max:255',
            'phone' => 'nullable|string|max:50',
        ]);
        $contact = Contact::create([
            'name' => $validated['name'],
            'email' => $validated['email'] ?? '',
            'phone' => $validated['phone'] ?? '',
        ]);
        $this->cache->delete('contacts:all');
        return response()->json($contact, 201);
    }

    public function delete(int $id): JsonResponse
    {
        $contact = Contact::find($id);
        if (!$contact) {
            return response()->json(['error' => 'Not found'], 404);
        }
        $contact->delete();
        $this->cache->delete('contacts:all');
        return response()->json(['message' => 'Deleted']);
    }
}
