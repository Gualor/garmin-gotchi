#include "tamalib/utils/cast.h"

using Toybox.Lang as std;

module tamalib {

function int(val as Bool) as Int { return INT(val); }

function bool(val as Int) as Bool { return BOOL(val); }

function float(val as Int) as Float { return FLOAT(val); }

}
