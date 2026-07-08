<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;

class MasterControl extends Model {
    protected $table = 'master_controls';
    protected $fillable = ['system_on', 'process_step', 'current_step'];
}
