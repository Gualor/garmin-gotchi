#ifndef TAMALIB_UTILS_MATH_H
#define TAMALIB_UTILS_MATH_H

using Toybox.Math;

#define ROUND(val) (Math.round(val).toNumber())

#define MAX(a, b) (((a) > (b)) ? (a) : (b))

#define MIN(a, b) (((a) < (b)) ? (a) : (b))

#endif // TAMALIB_UTILS_MATH_H
