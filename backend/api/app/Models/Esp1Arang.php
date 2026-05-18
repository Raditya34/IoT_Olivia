<?php
namespace App\Models;
use Illuminate\Database\Eloquent\Model;

class Esp1Arang extends Model {
    protected $table = 'esp1_arang';
    protected $fillable = ['suhu_arang', 'volume_arang'];
    public $timestamps = false;
}
