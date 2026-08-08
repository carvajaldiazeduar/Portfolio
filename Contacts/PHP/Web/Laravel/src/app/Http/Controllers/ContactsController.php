<?php
namespace App\Http\Controllers;
use App\Models\Contact;
use App\Services\CacheService;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Validator;

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
        $data = array_map(function ($value) {
            return is_string($value) ? trim($value) : $value;
        }, $request->all());
        $validator = Validator::make($data, [
            'name' => 'required|min:2|max:100|regex:/^[A-Za-zÀ-ÿ\' .-]+$/',
            'phone' => 'required|regex:/^[0-9 +().-]{7,20}$/',
            'email' => 'required|email:rfc',
        ], [
            'name.required' => 'Name is required',
            'name.min' => 'Name must be 2-100 characters (letters, spaces, apostrophes, hyphens, dots)',
            'name.max' => 'Name must be 2-100 characters (letters, spaces, apostrophes, hyphens, dots)',
            'name.regex' => 'Name must be 2-100 characters (letters, spaces, apostrophes, hyphens, dots)',
            'phone.required' => 'Phone is required',
            'phone.regex' => 'Phone must be 7-20 characters (digits, spaces, +, parentheses, dashes)',
            'email.required' => 'Email is required',
            'email.email' => 'Invalid email format',
        ]);
        if ($validator->fails()) {
            $errors = [];
            foreach ($validator->errors()->toArray() as $field => $messages) {
                $errors[$field] = $messages[0];
            }
            return response()->json(['errors' => $errors], 400);
        }
        $contact = Contact::create([
            'name' => $data['name'],
            'email' => $data['email'],
            'phone' => $data['phone'],
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
