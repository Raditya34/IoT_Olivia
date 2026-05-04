<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;

class Esp1Arang extends Model {
    protected $table = 'esp1_arang'; // Pastikan nama tabel benar
    protected $fillable = ['suhu', 'volume']; // Daftarkan kolomnya di sini
    public $timestamps = false; // Karena di migration kita cuma pakai created_at manual
}
