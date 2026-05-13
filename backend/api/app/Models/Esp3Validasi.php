<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;

class Esp3Validasi extends Model
{
    use HasFactory;
    protected $table = 'esp3_validasi';
    protected $fillable = ['volume', 'turbidity', 'viskositas', 'warna']; // Kolom yang boleh diisi
    public $timestamps = false;
}
