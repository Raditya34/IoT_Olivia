<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;

class Esp2Bleaching extends Model
{
    protected $table = 'esp2_bleaching';
    protected $fillable = ['suhu']; // Kolom yang boleh diisi
    public $timestamps = false;
}
