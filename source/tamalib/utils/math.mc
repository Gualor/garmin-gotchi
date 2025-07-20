#include "tamalib/utils/math.h"

using Toybox.Math;

module tamalib {

function round(val as Float) as Int { return ROUND(val); }

function max(a as Num, b as Num) as Num { return MAX(a, b); }

function min(a as Num, b as Num) as Num { return MIN(a, b); }

}
