<?php
namespace App\Models;
use Illuminate\Database\Eloquent\Model;

class Esp3Validasi extends Model {
    protected $table = 'esp3_validasi';
    protected $fillable = ['volume_validasi', 'turbidity', 'viscosity', 'r', 'g', 'b', 'kelayakan', 'status_layak'];
    public $timestamps = false;
}
