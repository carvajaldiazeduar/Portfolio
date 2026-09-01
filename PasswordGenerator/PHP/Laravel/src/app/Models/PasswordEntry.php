<?php
namespace App\Models;
use Illuminate\Database\Eloquent\Model;

class PasswordEntry extends Model
{
    protected $fillable = ['password', 'length'];
}
