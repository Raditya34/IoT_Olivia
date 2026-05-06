<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;

class Esp2Bleaching extends Model
{
    protected $table = 'esp2_bleaching';
    protected $fillable = ['suhu', 'valve', 'pompa_1', 'pompa_2', 'pompa_3', 'heater_1', 'heater_2', 'heater_3', 'heater_4','motor_ac_speed']; // Kolom yang boleh diisi
    public $timestamps = false;
}
