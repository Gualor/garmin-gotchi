/*
 * TamaLIB - A hardware agnostic Tamagotchi P1 emulation library
 *
 * Copyright (C) 2021 Jean-Christophe Rona <jc@rona.fr>
 *
 * This program is free software; you can redistribute it and/or
 * modify it under the terms of the GNU General Public License
 * as published by the Free Software Foundation; either version 2
 * of the License, or (at your option) any later version.
 *
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with this program; if not, write to the Free Software
 * Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA  02110-1301, USA.
 */

#include "tamalib/utils/cast.h"

module tamalib {

class Tamalib_impl {

    #define DEFAULT_FRAMERATE 30 // fps

    var exec_mode as ExecMode = EXEC_MODE_RUN;
    var step_depth as U32 = 0;
    (:initialized) var screen_ts as Timestamp;
    (:initialized) var ts_freq as U32;
    var g_framerate as U8 = DEFAULT_FRAMERATE;

    (:initialized) var g_hal as HAL;
    var g_cpu as CPU = new CPU_impl() as CPU;
    var g_hw as HW = new HW_impl() as HW;

    function init(program as Program, breakpoints as Breakpoints?, freq as U32) as Int {
        var res = 0;

        res |= g_cpu.init(g_hal, g_hw, program, breakpoints, freq);
        res |= g_hw.init(g_hal, g_cpu);

        screen_ts = g_hal.get_timestamp();
        ts_freq = freq;

        return res;
    }

    function release() as Void {
        g_hw.release();
        g_cpu.release();
    }

    function set_framerate(framerate as U8) as Void {
        g_framerate = framerate;
    }

    function get_framerate() as U8 {
        return g_framerate;
    }

    function register_hal(hal as HAL) as Void {
        g_hal = hal;
    }

    function set_exec_mode(mode as ExecMode) as Void {
        exec_mode = mode;
        step_depth = g_cpu.get_depth();
        g_cpu.sync_ref_timestamp();
    }

    function step() as Void {
        if (exec_mode == EXEC_MODE_PAUSE) {
            return;
        }

        if (BOOL(g_cpu.step())) {
            exec_mode = EXEC_MODE_PAUSE;
            step_depth = g_cpu.get_depth();
        } else {
            switch (exec_mode) {
                case EXEC_MODE_PAUSE:
                case EXEC_MODE_RUN:
                    break;

                case EXEC_MODE_STEP:
                    exec_mode = EXEC_MODE_PAUSE;
                    break;

                case EXEC_MODE_NEXT:
                    if (g_cpu.get_depth() <= step_depth) {
                        exec_mode = EXEC_MODE_PAUSE;
                        step_depth = g_cpu.get_depth();
                    }
                    break;

                case EXEC_MODE_TO_CALL:
                    if (g_cpu.get_depth() > step_depth) {
                        exec_mode = EXEC_MODE_PAUSE;
                        step_depth = g_cpu.get_depth();
                    }
                    break;

                case EXEC_MODE_TO_RET:
                    if (g_cpu.get_depth() < step_depth) {
                        exec_mode = EXEC_MODE_PAUSE;
                        step_depth = g_cpu.get_depth();
                    }
                    break;
            }
        }
    }

    function mainloop() as Void {
        var ts;

        while (!BOOL(g_hal.handler())) {
            step();

            /* Update the screen @ g_framerate fps */
            ts = g_hal.get_timestamp();
            if (ts - screen_ts >= ts_freq/g_framerate) {
                screen_ts = ts;
                g_hal.update_screen();
            }
        }
    }

    function set_button(btn as Button, state as ButtonState) as Void {
        g_hw.set_button(btn, state);
    }

    function set_speed(speed as U8) as Void {
        g_cpu.set_speed(speed);
    }

    function get_state() as CPUState {
        return g_cpu.get_state();
    }

    function refresh_hw() as Void {
        g_cpu.refresh_hw();
    }

    function reset() as Void {
        g_cpu.reset();
    }

    (:release) function add_bp(list as Breakpoints, addr as U13) as Void {}
    (:debug)   function add_bp(list as Breakpoints, addr as U13) as Void {
        g_cpu.add_bp(list, addr);
    }

    (:release) function free_bp(list as Breakpoints) as Void {}
    (:debug)   function free_bp(list as Breakpoints) as Void {
        g_cpu.free_bp(list);
    }

}

}
