<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;

class Esp1Arang extends Model {
    protected $table = 'esp1_arang';
    // Field disesuaikan dengan yang dikirim ESP32
    protected $fillable = ['suhu1', 'suhu2', 'tinggi', 'volume'];
    public $timestamps = false;
}
