<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;

class Esp3Validasi extends Model
{
    use HasFactory;
    protected $table = 'esp3_validasi';
    // Field disesuaikan dengan yang dikirim ESP32 (NTU, Freq, RGB)
    protected $fillable = ['tinggi', 'volume', 'ntu', 'freq', 'tegangan', 'cP', 'r', 'g', 'b'];
    public $timestamps = false;
}
