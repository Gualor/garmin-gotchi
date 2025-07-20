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

#include "tamalib/cpu.h"
#include "tamalib/utils/cast.h"

using Toybox.Lang as std;

module tamalib {

class CPU_impl {

    #define TICK_FREQUENCY 32768          // Hz
    #define OSC1_FREQUENCY TICK_FREQUENCY // Hz
    #define OSC3_FREQUENCY 1000000        // Hz

    #define TIMER_2HZ_PERIOD   (TICK_FREQUENCY / 2)   // in ticks
    #define TIMER_4HZ_PERIOD   (TICK_FREQUENCY / 4)   // in ticks
    #define TIMER_8HZ_PERIOD   (TICK_FREQUENCY / 8)   // in ticks
    #define TIMER_16HZ_PERIOD  (TICK_FREQUENCY / 16)  // in ticks
    #define TIMER_32HZ_PERIOD  (TICK_FREQUENCY / 32)  // in ticks
    #define TIMER_64HZ_PERIOD  (TICK_FREQUENCY / 64)  // in ticks
    #define TIMER_128HZ_PERIOD (TICK_FREQUENCY / 128) // in ticks
    #define TIMER_256HZ_PERIOD (TICK_FREQUENCY / 256) // in ticks

    #define MASK_4B  0xF00
    #define MASK_6B  0xFC0
    #define MASK_7B  0xFE0
    #define MASK_8B  0xFF0
    #define MASK_10B 0xFFC
    #define MASK_12B 0xFFF

    #define PCS  (pc & 0xFF)
    #define PCSL (pc & 0xF)
    #define PCSH ((pc >> 4) & 0xF)
    #define PCP  ((pc >> 8) & 0xF)
    #define PCB  ((pc >> 12) & 0x1)

    #define NBP ((np >> 4) & 0x1)
    #define NPP (np & 0xF)

    #define TO_PC(bank, page, step) (((step) & 0xFF) | (((page) & 0xF) << 8) | ((bank) & 0x1) << 12)
    #define TO_NP(bank, page)       (((page) & 0x0F) | (((bank) & 0x1) << 4))

    #define XHL (x & 0xFF)
    #define XL  (x & 0xF)
    #define XH  ((x >> 4) & 0xF)
    #define XP  ((x >> 8) & 0xF)
    #define YHL (y & 0xFF)
    #define YL  (y & 0xF)
    #define YH  ((y >> 4) & 0xF)
    #define YP  ((y >> 8) & 0xF)

    #define M(n)        get_memory((n))
    #define SET_M(n, v) set_memory((n), (v))

    #define RQ(i)        get_rq((i))
    #define SET_RQ(i, v) set_rq((i), (v))

    #define SPL() (sp & 0xF)
    #define SPH() ((sp >> 4) & 0xF)

    #define FLAG_C (0x1 << 0)
    #define FLAG_Z (0x1 << 1)
    #define FLAG_D (0x1 << 2)
    #define FLAG_I (0x1 << 3)

    #define C BOOL(flags & FLAG_C)
    #define Z BOOL(flags & FLAG_Z)
    #define D BOOL(flags & FLAG_D)
    #define I BOOL(flags & FLAG_I)

    #define SET_C   flags |=  FLAG_C
    #define CLEAR_C flags &= ~FLAG_C
    #define SET_Z   flags |=  FLAG_Z
    #define CLEAR_Z flags &= ~FLAG_Z
    #define SET_D   flags |=  FLAG_D
    #define CLEAR_D flags &= ~FLAG_D
    #define SET_I   flags |=  FLAG_I
    #define CLEAR_I flags &= ~FLAG_I

    #define REG_CLK_INT_FACTOR_FLAGS       0xF00
    #define REG_SW_INT_FACTOR_FLAGS        0xF01
    #define REG_PROG_INT_FACTOR_FLAGS      0xF02
    #define REG_SERIAL_INT_FACTOR_FLAGS    0xF03
    #define REG_K00_K03_INT_FACTOR_FLAGS   0xF04
    #define REG_K10_K13_INT_FACTOR_FLAGS   0xF05
    #define REG_CLOCK_INT_MASKS            0xF10
    #define REG_SW_INT_MASKS               0xF11
    #define REG_PROG_INT_MASKS             0xF12
    #define REG_SERIAL_INT_MASKS           0xF13
    #define REG_K00_K03_INT_MASKS          0xF14
    #define REG_K10_K13_INT_MASKS          0xF15
    #define REG_CLOCK_TIMER_DATA_1         0xF20
    #define REG_CLOCK_TIMER_DATA_2         0xF21
    #define REG_SW_TIMER_DATA_L            0xF22
    #define REG_SW_TIMER_DATA_H            0xF23
    #define REG_PROG_TIMER_DATA_L          0xF24
    #define REG_PROG_TIMER_DATA_H          0xF25
    #define REG_PROG_TIMER_RELOAD_DATA_L   0xF26
    #define REG_PROG_TIMER_RELOAD_DATA_H   0xF27
    #define REG_SERIAL_IF_DATA_L           0xF30
    #define REG_SERIAL_IF_DATA_H           0xF31
    #define REG_K00_K03_INPUT_PORT         0xF40
    #define REG_K00_K03_INPUT_RELATION     0xF41
    #define REG_K10_K13_INPUT_PORT         0xF42
    #define REG_R00_R03_OUTPUT_PORT        0xF50
    #define REG_R10_R13_OUTPUT_PORT        0xF51
    #define REG_R20_R23_OUTPUT_PORT        0xF52
    #define REG_R30_R33_OUTPUT_PORT        0xF53
    #define REG_R40_R43_BZ_OUTPUT_PORT     0xF54
    #define REG_P00_P03_IO_PORT            0xF60
    #define REG_P10_P13_IO_PORT            0xF61
    #define REG_P20_P23_IO_PORT            0xF62
    #define REG_P30_P33_IO_PORT            0xF63
    #define REG_CPU_OSC3_CTRL              0xF70
    #define REG_LCD_CTRL                   0xF71
    #define REG_LCD_CONTRAST               0xF72
    #define REG_SVD_CTRL                   0xF73
    #define REG_BUZZER_CTRL1               0xF74
    #define REG_BUZZER_CTRL2               0xF75
    #define REG_CLK_WD_TIMER_CTRL          0xF76
    #define REG_SW_TIMER_CTRL              0xF77
    #define REG_PROG_TIMER_CTRL            0xF78
    #define REG_PROG_TIMER_CLK_SEL         0xF79
    #define REG_SERIAL_IF_CLK_SEL          0xF7A
    #define REG_HIGH_IMPEDANCE_OUTPUT_CTRL 0xF7B
    #define REG_IO_CTRL                    0xF7D
    #define REG_IO_PULLUP_CFG              0xF7E

    #define INPUT_PORT_NUM 2

    class Op {
        typedef OpCallback as (Method(arg0 as U8, arg1 as U8) as Void);

        var log as String;
        var code as U12;
        var mask as U12;
        var shift_arg0 as U12;
        var mask_arg0 as U12; // != 0 only if there are two arguments
        var cycles as U8;
        var cb as OpCallback;

        function initialize(
            log as String,
            code as U12,
            mask as U12,
            shift_arg0 as U12,
            mask_arg0 as U12,
            cycles as U8,
            cb as OpCallback
        ) {
            me.log = log;
            me.code = code;
            me.mask = mask;
            me.shift_arg0 = shift_arg0;
            me.mask_arg0 = mask_arg0;
            me.cycles = cycles;
            me.cb = cb;
        }
    }

    typedef Ops as std.Array<Op>;

    class InputPort {
        var states as U4;

        function initialize(states as U4) {
            me.states = states;
        }
    }

    typedef InputPorts as std.Array<InputPort>;

    class MemoryRange {
        var addr as U12;
        var size as U12;

        function initialize(addr as U12, size as U12) {
            me.addr = addr;
            me.size = size;
        }
    }

    typedef MemoryRanges as std.Array<MemoryRange>;

    (:initialized) var g_hal as HAL;
    (:initialized) var g_hw as HW;
    (:initialized) var g_program as Program;
    var g_breakpoints as Breakpoints? = null;

    (:initialized) var pc as U13, next_pc as U13;
    (:initialized) var x as U12, y as U12;
    (:initialized) var a as U4, b as U4;
    (:initialized) var np as U5;
    (:initialized) var sp as U8;

    (:initialized) var flags as U4;

    var memory as Memory = new [MEM_BUFFER_SIZE]b;

    var inputs as InputPorts = [
        new InputPort(0),
        new InputPort(0),
    ];

    const refresh_locs as MemoryRanges = [
        new MemoryRange(MEM_DISPLAY1_ADDR, MEM_DISPLAY1_SIZE), // Display Memory 1
        new MemoryRange(MEM_DISPLAY2_ADDR, MEM_DISPLAY2_SIZE), // Display Memory 2
        new MemoryRange(REG_BUZZER_CTRL1, 1),                  // Buzzer frequency
        new MemoryRange(REG_R40_R43_BZ_OUTPUT_PORT, 1),        // Buzzer enabled
    ];

    var interrupts as Interrupts = [
        new Interrupt(0x0, 0x0, false, 0x0C), // Prog timer
        new Interrupt(0x0, 0x0, false, 0x0A), // Serial interface
        new Interrupt(0x0, 0x0, false, 0x08), // Input (K10-K13)
        new Interrupt(0x0, 0x0, false, 0x06), // Input (K00-K03)
        new Interrupt(0x0, 0x0, false, 0x04), // Stopwatch timer
        new Interrupt(0x0, 0x0, false, 0x02), // Clock timer
    ];

    const interrupt_names as Strings = [
        "INT_PROG_TIMER_SLOT",
        "INT_SERIAL_SLOT",
        "INT_K10_K13_SLOT",
        "INT_K00_K03_SLOT",
        "INT_STOPWATCH_SLOT",
        "INT_CLOCK_TIMER_SLOT",
    ];

    var call_depth as U32 = 0;

    var clk_timer_2hz_timestamp as U32 = 0;   // in ticks
    var clk_timer_4hz_timestamp as U32 = 0;   // in ticks
    var clk_timer_8hz_timestamp as U32 = 0;   // in ticks
    var clk_timer_16hz_timestamp as U32 = 0;  // in ticks
    var clk_timer_32hz_timestamp as U32 = 0;  // in ticks
    var clk_timer_64hz_timestamp as U32 = 0;  // in ticks
    var clk_timer_128hz_timestamp as U32 = 0; // in ticks
    var clk_timer_256hz_timestamp as U32 = 0; // in ticks
    var prog_timer_timestamp as U32 = 0;      // in ticks
    var prog_timer_enabled as Bool = false;
    var prog_timer_data as U8 = 0;
    var prog_timer_rld as U8 = 0;

    var tick_counter as U32 = 0;
    (:initialized) var ts_freq as U32;
    var speed_ratio as U8 = 1;
    (:initialized) var ref_ts as Timestamp;

    var cpu_halted as Bool = false;
    (:initialized) var cpu_frequency as U32; // in hz
    var scaled_cycle_accumulator as U32 = 0;
    var previous_cycles as U8 = 0;

    class CPUState_impl {
        var g_cpu as CPU_impl;
        function initialize(cpu as CPU_impl) { g_cpu = cpu; }

        function get_pc()                        as U13        { return g_cpu.pc;                        } function set_pc(                       in as U13)        as Void { g_cpu.pc = in;                        }
        function get_x()                         as U12        { return g_cpu.x;                         } function set_x(                        in as U12)        as Void { g_cpu.x = in;                         }
        function get_y()                         as U12        { return g_cpu.y;                         } function set_y(                        in as U12)        as Void { g_cpu.y = in;                         }
        function get_a()                         as U4         { return g_cpu.a;                         } function set_a(                        in as U4)         as Void { g_cpu.a = in;                         }
        function get_b()                         as U4         { return g_cpu.b;                         } function set_b(                        in as U4)         as Void { g_cpu.b = in;                         }
        function get_np()                        as U5         { return g_cpu.np;                        } function set_np(                       in as U5)         as Void { g_cpu.np = in;                        }
        function get_sp()                        as U8         { return g_cpu.sp;                        } function set_sp(                       in as U8)         as Void { g_cpu.sp = in;                        }
        function get_flags()                     as U4         { return g_cpu.flags;                     } function set_flags(                    in as U4)         as Void { g_cpu.flags = in;                     }
        function get_tick_counter()              as U32        { return g_cpu.tick_counter;              } function set_tick_counter(             in as U32)        as Void { g_cpu.tick_counter = in;              }
        function get_clk_timer_2hz_timestamp()   as U32        { return g_cpu.clk_timer_2hz_timestamp;   } function set_clk_timer_2hz_timestamp(  in as U32)        as Void { g_cpu.clk_timer_2hz_timestamp = in;   }
        function get_clk_timer_4hz_timestamp()   as U32        { return g_cpu.clk_timer_4hz_timestamp;   } function set_clk_timer_4hz_timestamp(  in as U32)        as Void { g_cpu.clk_timer_4hz_timestamp = in;   }
        function get_clk_timer_8hz_timestamp()   as U32        { return g_cpu.clk_timer_8hz_timestamp;   } function set_clk_timer_8hz_timestamp(  in as U32)        as Void { g_cpu.clk_timer_8hz_timestamp = in;   }
        function get_clk_timer_16hz_timestamp()  as U32        { return g_cpu.clk_timer_16hz_timestamp;  } function set_clk_timer_16hz_timestamp( in as U32)        as Void { g_cpu.clk_timer_16hz_timestamp = in;  }
        function get_clk_timer_32hz_timestamp()  as U32        { return g_cpu.clk_timer_32hz_timestamp;  } function set_clk_timer_32hz_timestamp( in as U32)        as Void { g_cpu.clk_timer_32hz_timestamp = in;  }
        function get_clk_timer_64hz_timestamp()  as U32        { return g_cpu.clk_timer_64hz_timestamp;  } function set_clk_timer_64hz_timestamp( in as U32)        as Void { g_cpu.clk_timer_64hz_timestamp = in;  }
        function get_clk_timer_128hz_timestamp() as U32        { return g_cpu.clk_timer_128hz_timestamp; } function set_clk_timer_128hz_timestamp(in as U32)        as Void { g_cpu.clk_timer_128hz_timestamp = in; }
        function get_clk_timer_256hz_timestamp() as U32        { return g_cpu.clk_timer_256hz_timestamp; } function set_clk_timer_256hz_timestamp(in as U32)        as Void { g_cpu.clk_timer_256hz_timestamp = in; }
        function get_prog_timer_timestamp()      as U32        { return g_cpu.prog_timer_timestamp;      } function set_prog_timer_timestamp(     in as U32)        as Void { g_cpu.prog_timer_timestamp = in;      }
        function get_prog_timer_enabled()        as Bool       { return g_cpu.prog_timer_enabled;        } function set_prog_timer_enabled(       in as Bool)       as Void { g_cpu.prog_timer_enabled = in;        }
        function get_prog_timer_data()           as U8         { return g_cpu.prog_timer_data;           } function set_prog_timer_data(          in as U8)         as Void { g_cpu.prog_timer_data = in;           }
        function get_prog_timer_rld()            as U8         { return g_cpu.prog_timer_rld;            } function set_prog_timer_rld(           in as U8)         as Void { g_cpu.prog_timer_rld = in;            }
        function get_call_depth()                as U32        { return g_cpu.call_depth;                } function set_call_depth(               in as U32)        as Void { g_cpu.call_depth = in;                }
        function get_interrupts()                as Interrupts { return g_cpu.interrupts;                } function set_interrupts(               in as Interrupts) as Void { g_cpu.interrupts = in;                }
        function get_cpu_halted()                as Bool       { return g_cpu.cpu_halted;                } function set_cpu_halted(               in as Bool)       as Void { g_cpu.cpu_halted = in;                }
        function get_memory()                    as Memory     { return g_cpu.memory;                    } function set_memory(                   in as Memory)     as Void { g_cpu.memory = in;                    }
    }

    function add_bp(list as Breakpoints, addr as U13) as Void {
        list.add(new Breakpoint(addr));
    }

    function free_bp(list as Breakpoints) as Void {
        while (list.size() > 0) {
            list.remove(list[0]);
        }
    }

    function set_speed(speed as U8) as Void {
        speed_ratio = speed;
    }

    function get_state() as CPUState {
        return new CPUState_impl(me);
    }

    function get_depth() as U32 {
        return call_depth;
    }

    function generate_interrupt(slot as IntSlot, bit as U8) as Void {
        /* Set the factor flag no matter what */
        interrupts[slot].factor_flag_reg = interrupts[slot].factor_flag_reg | (0x1 << bit);

        /* Trigger the INT only if not masked */
        if (BOOL(interrupts[slot].mask_reg & (0x1 << bit))) {
            interrupts[slot].triggered = true;
        }
    }

    function set_input_pin(pin as Pin, state as PinState) as Void {
        var old_state = (inputs[pin & 0x4].states >> (pin & 0x3)) & 0x1;

        /* Trigger the interrupt if the state changed */
        if (state != old_state) {
            switch ((pin & 0x4) >> 2) {
                case 0:
                    /* Active HIGH/LOW depending on the relation register */
                    if (state != ((GET_IO_MEMORY(memory, REG_K00_K03_INPUT_RELATION) >> (pin & 0x3)) & 0x1)) {
                        generate_interrupt(INT_K00_K03_SLOT, pin & 0x3);
                    }
                    break;

                case 1:
                    /* Active LOW */
                    if (state == PIN_STATE_LOW) {
                        generate_interrupt(INT_K10_K13_SLOT, pin & 0x3);
                    }
                    break;
            }
        }

        /* Set the I/O */
        inputs[pin & 0x4].states = (inputs[pin & 0x4].states & ~(0x1 << (pin & 0x3))) | (state << (pin & 0x3));
    }

    function sync_ref_timestamp() as Void {
        ref_ts = g_hal.get_timestamp();
    }

    function get_io(n as U12) as U4 {
        var tmp;

        switch (n) {
            case REG_CLK_INT_FACTOR_FLAGS:
                /* Interrupt factor flags (clock timer) */
                tmp = interrupts[INT_CLOCK_TIMER_SLOT].factor_flag_reg;
                interrupts[INT_CLOCK_TIMER_SLOT].factor_flag_reg = 0;
                return tmp;

            case REG_SW_INT_FACTOR_FLAGS:
                /* Interrupt factor flags (stopwatch) */
                tmp = interrupts[INT_STOPWATCH_SLOT].factor_flag_reg;
                interrupts[INT_STOPWATCH_SLOT].factor_flag_reg = 0;
                return tmp;

            case REG_PROG_INT_FACTOR_FLAGS:
                /* Interrupt factor flags (prog timer) */
                tmp = interrupts[INT_PROG_TIMER_SLOT].factor_flag_reg;
                interrupts[INT_PROG_TIMER_SLOT].factor_flag_reg = 0;
                return tmp;

            case REG_SERIAL_INT_FACTOR_FLAGS:
                /* Interrupt factor flags (serial) */
                tmp = interrupts[INT_SERIAL_SLOT].factor_flag_reg;
                interrupts[INT_SERIAL_SLOT].factor_flag_reg = 0;
                return tmp;

            case REG_K00_K03_INT_FACTOR_FLAGS:
                /* Interrupt factor flags (K00-K03) */
                tmp = interrupts[INT_K00_K03_SLOT].factor_flag_reg;
                interrupts[INT_K00_K03_SLOT].factor_flag_reg = 0;
                return tmp;

            case REG_K10_K13_INT_FACTOR_FLAGS:
                /* Interrupt factor flags (K10-K13) */
                tmp = interrupts[INT_K10_K13_SLOT].factor_flag_reg;
                interrupts[INT_K10_K13_SLOT].factor_flag_reg = 0;
                return tmp;

            case REG_CLOCK_INT_MASKS:
                /* Clock timer interrupt masks */
                return interrupts[INT_CLOCK_TIMER_SLOT].mask_reg;

            case REG_SW_INT_MASKS:
                /* Stopwatch interrupt masks */
                return interrupts[INT_STOPWATCH_SLOT].mask_reg & 0x3;

            case REG_PROG_INT_MASKS:
                /* Prog timer interrupt masks */
                return interrupts[INT_PROG_TIMER_SLOT].mask_reg & 0x1;

            case REG_SERIAL_INT_MASKS:
                /* Serial interface interrupt masks */
                return interrupts[INT_SERIAL_SLOT].mask_reg & 0x1;

            case REG_K00_K03_INT_MASKS:
                /* Input (K00-K03) interrupt masks */
                return interrupts[INT_K00_K03_SLOT].mask_reg;

            case REG_K10_K13_INT_MASKS:
                /* Input (K10-K13) interrupt masks */
                return interrupts[INT_K10_K13_SLOT].mask_reg;

            case REG_CLOCK_TIMER_DATA_1:
                /* Clock timer data (16-128Hz) */
                return GET_IO_MEMORY(memory, n);

            case REG_CLOCK_TIMER_DATA_2:
                /* Clock timer data (1-8Hz) */
                return GET_IO_MEMORY(memory, n);

            case REG_PROG_TIMER_DATA_L:
                /* Prog timer data (low) */
                return prog_timer_data & 0xF;

            case REG_PROG_TIMER_DATA_H:
                /* Prog timer data (high) */
                return (prog_timer_data >> 4) & 0xF;

            case REG_PROG_TIMER_RELOAD_DATA_L:
                /* Prog timer reload data (low) */
                return prog_timer_rld & 0xF;

            case REG_PROG_TIMER_RELOAD_DATA_H:
                /* Prog timer reload data (high) */
                return (prog_timer_rld >> 4) & 0xF;

            case REG_K00_K03_INPUT_PORT:
                /* Input port (K00-K03) */
                return inputs[0].states;

            case REG_K00_K03_INPUT_RELATION:
                /* Input relation register (K00-K03) */
                return GET_IO_MEMORY(memory, n);

            case REG_K10_K13_INPUT_PORT:
                /* Input port (K10-K13) */
                return inputs[1].states;

            case REG_R40_R43_BZ_OUTPUT_PORT:
                /* Output port (R40-R43) */
                return GET_IO_MEMORY(memory, n);

            case REG_CPU_OSC3_CTRL:
                /* CPU/OSC3 clocks switch, CPU voltage switch */
                return GET_IO_MEMORY(memory, n);

            case REG_LCD_CTRL:
                /* LCD control */
                return GET_IO_MEMORY(memory, n);

            case REG_LCD_CONTRAST:
                /* LCD contrast */
                break;

            case REG_SVD_CTRL:
                /* SVD */
                return GET_IO_MEMORY(memory, n) & 0x7; // Voltage always OK

            case REG_BUZZER_CTRL1:
                /* Buzzer config 1 */
                return GET_IO_MEMORY(memory, n);

            case REG_BUZZER_CTRL2:
                /* Buzzer config 2 */
                return GET_IO_MEMORY(memory, n) & 0x3; // Buzzer ready

            case REG_CLK_WD_TIMER_CTRL:
                /* Clock/Watchdog timer reset */
                break;

            case REG_SW_TIMER_CTRL:
                /* Stopwatch stop/run/reset */
                break;

            case REG_PROG_TIMER_CTRL:
                /* Prog timer stop/run/reset */
                return INT(prog_timer_enabled);

            case REG_PROG_TIMER_CLK_SEL:
                /* Prog timer clock selection */
                break;

            default:
                g_hal.log(LOG_ERROR, "Read from unimplemented I/O 0x%03X - PC = 0x%04X\n", [n, pc]);
        }

        return 0;
    }

    function set_io(n as U12, v as U4) as Void {
        switch (n) {
            case REG_CLOCK_INT_MASKS:
                /* Clock timer interrupt masks */
                interrupts[INT_CLOCK_TIMER_SLOT].mask_reg = v;
                break;

            case REG_SW_INT_MASKS:
                /* Stopwatch interrupt masks */
                /* Assume all INT disabled */
                interrupts[INT_STOPWATCH_SLOT].mask_reg = v;
                break;

            case REG_PROG_INT_MASKS:
                /* Prog timer interrupt masks */
                /* Assume Prog timer INT enabled (0x1) */
                interrupts[INT_PROG_TIMER_SLOT].mask_reg = v;
                break;

            case REG_SERIAL_INT_MASKS:
                /* Serial interface interrupt masks */
                /* Assume all INT disabled */
                interrupts[INT_SERIAL_SLOT].mask_reg = v;
                break;

            case REG_K00_K03_INT_MASKS:
                /* Input (K00-K03) interrupt masks */
                /* Assume all INT disabled */
                interrupts[INT_K00_K03_SLOT].mask_reg = v;
                break;

            case REG_K10_K13_INT_MASKS:
                /* Input (K10-K13) interrupt masks */
                /* Assume all INT disabled */
                interrupts[INT_K10_K13_SLOT].mask_reg = v;
                break;

            case REG_CLOCK_TIMER_DATA_1:
                /* Write not allowed */
                /* Clock timer data (16-128Hz) */
                break;

            case REG_CLOCK_TIMER_DATA_2:
                /* Write not allowed */
                /* Clock timer data (1-8Hz) */
                break;

            case REG_PROG_TIMER_RELOAD_DATA_L:
                /* Prog timer reload data (low) */
                prog_timer_rld = v | (prog_timer_rld & 0xF0);
                break;

            case REG_PROG_TIMER_RELOAD_DATA_H:
                /* Prog timer reload data (high) */
                prog_timer_rld = (prog_timer_rld & 0xF) | (v << 4);
                break;

            case REG_K00_K03_INPUT_PORT:
                /* Input port (K00-K03) */
                /* Write not allowed */
                break;

            case REG_K00_K03_INPUT_RELATION:
                /* Input relation register (K00-K03) */
                break;

            case REG_R40_R43_BZ_OUTPUT_PORT:
                /* Output port (R40-R43) */
                //g_hal.log(LOG_INFO, "Output/Buzzer: 0x%X\n", [v]);
                g_hw.enable_buzzer(!BOOL(v & 0x8));
                break;

            case REG_CPU_OSC3_CTRL:
                /* CPU/OSC3 clocks switch, CPU voltage switch */
                /* Do not care about OSC3 state nor operating voltage */
                if (BOOL(v & 0x8) && cpu_frequency != OSC3_FREQUENCY) {
                    /* OSC3 */
                    cpu_frequency = OSC3_FREQUENCY;
                    scaled_cycle_accumulator = 0;
                    //g_hal.log(LOG_INFO, "Switch to OSC3\n", []);
                }
                if (!BOOL(v & 0x8) && cpu_frequency != OSC1_FREQUENCY) {
                    /* OSC1 */
                    cpu_frequency = OSC1_FREQUENCY;
                    scaled_cycle_accumulator = 0;
                    //g_hal.log(LOG_INFO, "Switch to OSC1\n", []);
                }
                break;

            case REG_LCD_CTRL:
                /* LCD control */
                break;

            case REG_LCD_CONTRAST:
                /* LCD contrast */
                /* Assume medium contrast (0x8) */
                break;

            case REG_SVD_CTRL:
                /* SVD */
                /* Assume battery voltage always OK (0x6) */
                break;

            case REG_BUZZER_CTRL1:
                /* Buzzer config 1 */
                g_hw.set_buzzer_freq(v & 0x7);
                break;

            case REG_BUZZER_CTRL2:
                /* Buzzer config 2 */
                break;

            case REG_CLK_WD_TIMER_CTRL:
                /* Clock/Watchdog timer reset */
                /* Ignore watchdog */
                break;

            case REG_SW_TIMER_CTRL:
                /* Stopwatch stop/run/reset */
                break;

            case REG_PROG_TIMER_CTRL:
                /* Prog timer stop/run/reset */
                if (BOOL(v & 0x2)) {
                    prog_timer_data = prog_timer_rld;
                }

                if (BOOL(v & 0x1) && !prog_timer_enabled) {
                    prog_timer_timestamp = tick_counter;
                }

                prog_timer_enabled = BOOL(v & 0x1);
                break;

            case REG_PROG_TIMER_CLK_SEL:
                /* Prog timer clock selection */
                /* Assume 256Hz, output disabled */
                break;

            default:
                g_hal.log(LOG_ERROR, "Write 0x%X to unimplemented I/O 0x%03X - PC = 0x%04X\n", [v, n, pc]);
        }
    }

    function set_lcd(n as U12, v as U4) as Void {
        var i;
        var seg, com0;

        seg = ((n & 0x7F) >> 1);
        com0 = (((n & 0x80) >> 7) * 8 + (n & 0x1) * 4);

        for (i = 0; i < 4; i++) {
            g_hw.set_lcd_pin(seg, com0 + i, (v >> i) & 0x1);
        }
    }

    function get_memory(n as U12) as U4 {
        var res = 0;

        if (n < MEM_RAM_SIZE) {
            /* RAM */
            g_hal.log(LOG_MEMORY, "RAM              - ", []);
            res = GET_RAM_MEMORY(memory, n);
        } else if (n >= MEM_DISPLAY1_ADDR && n < (MEM_DISPLAY1_ADDR + MEM_DISPLAY1_SIZE)) {
            /* Display Memory 1 */
            g_hal.log(LOG_MEMORY, "Display Memory 1 - ", []);
            res = GET_DISP1_MEMORY(memory, n);
        } else if (n >= MEM_DISPLAY2_ADDR && n < (MEM_DISPLAY2_ADDR + MEM_DISPLAY2_SIZE)) {
            /* Display Memory 2 */
            g_hal.log(LOG_MEMORY, "Display Memory 2 - ", []);
            res = GET_DISP2_MEMORY(memory, n);
        } else if (n >= MEM_IO_ADDR && n < (MEM_IO_ADDR + MEM_IO_SIZE)) {
            /* I/O Memory */
            g_hal.log(LOG_MEMORY, "I/O              - ", []);
            res = get_io(n);
        } else {
            g_hal.log(LOG_ERROR, "Read from invalid memory address 0x%03X - PC = 0x%04X\n", [n, pc]);
            return 0;
        }

        g_hal.log(LOG_MEMORY, "Read  0x%X - Address 0x%03X - PC = 0x%04X\n", [res, n, pc]);

        return res;
    }

    function set_memory(n as U12, v as U4) as Void {
        /* Cache any data written to a valid address, and process it */
        if (n < MEM_RAM_SIZE) {
            /* RAM */
            SET_RAM_MEMORY(memory, n, v);
            g_hal.log(LOG_MEMORY, "RAM              - ", []);
        } else if (n >= MEM_DISPLAY1_ADDR && n < (MEM_DISPLAY1_ADDR + MEM_DISPLAY1_SIZE)) {
            /* Display Memory 1 */
            SET_DISP1_MEMORY(memory, n, v);
            set_lcd(n, v);
            g_hal.log(LOG_MEMORY, "Display Memory 1 - ", []);
        } else if (n >= MEM_DISPLAY2_ADDR && n < (MEM_DISPLAY2_ADDR + MEM_DISPLAY2_SIZE)) {
            /* Display Memory 2 */
            SET_DISP2_MEMORY(memory, n, v);
            set_lcd(n, v);
            g_hal.log(LOG_MEMORY, "Display Memory 2 - ", []);
        } else if (n >= MEM_IO_ADDR && n < (MEM_IO_ADDR + MEM_IO_SIZE)) {
            /* I/O Memory */
            SET_IO_MEMORY(memory, n, v);
            set_io(n, v);
            g_hal.log(LOG_MEMORY, "I/O              - ", []);
        } else {
            g_hal.log(LOG_ERROR, "Write 0x%X to invalid memory address 0x%03X - PC = 0x%04X\n", [v, n, pc]);
            return;
        }

        g_hal.log(LOG_MEMORY, "Write 0x%X - Address 0x%03X - PC = 0x%04X\n", [v, n, pc]);
    }

    function refresh_hw() as Void {
        for (var i = 0; i < refresh_locs.size(); i++) {
            for (var n = refresh_locs[i].addr; n < (refresh_locs[i].addr + refresh_locs[i].size); n++) {
                set_memory(n, GET_MEMORY(memory, n));
            }
        }
    }

    function get_rq(rq as U12) as U4 {
        switch (rq & 0x3) {
            case 0x0:
                return a;

            case 0x1:
                return b;

            case 0x2:
                return M(x);

            case 0x3:
                return M(y);
        }

        return 0;
    }

    function set_rq(rq as U12, v as U4) as Void {
        switch (rq & 0x3) {
            case 0x0:
                a = v;
                break;

            case 0x1:
                b = v;
                break;

            case 0x2:
                SET_M(x, v);
                break;

            case 0x3:
                SET_M(y, v);
                break;
        }
    }

    /* Instructions */
    function op_pset_cb(arg0 as U8, arg1 as U8) as Void {
        np = arg0;
    }

    function op_jp_cb(arg0 as U8, arg1 as U8) as Void {
        next_pc = arg0 | (np << 8);
    }

    function op_jp_c_cb(arg0 as U8, arg1 as U8) as Void {
        if (BOOL(flags & FLAG_C)) {
            next_pc = arg0 | (np << 8);
        }
    }

    function op_jp_nc_cb(arg0 as U8, arg1 as U8) as Void {
        if (!BOOL(flags & FLAG_C)) {
            next_pc = arg0 | (np << 8);
        }
    }

    function op_jp_z_cb(arg0 as U8, arg1 as U8) as Void {
        if (BOOL(flags & FLAG_Z)) {
            next_pc = arg0 | (np << 8);
        }
    }

    function op_jp_nz_cb(arg0 as U8, arg1 as U8) as Void {
        if (!BOOL(flags & FLAG_Z)) {
            next_pc = arg0 | (np << 8);
        }
    }

    function op_jpba_cb(arg0 as U8, arg1 as U8) as Void {
        next_pc = a | (b << 4) | (np << 8);
    }

    function op_call_cb(arg0 as U8, arg1 as U8) as Void {
        pc = (pc + 1) & 0x1FFF; // This does not actually change the PC register
        SET_M((sp - 1) & 0xFF, PCP);
        SET_M((sp - 2) & 0xFF, PCSH);
        SET_M((sp - 3) & 0xFF, PCSL);
        sp = (sp - 3) & 0xFF;
        next_pc = TO_PC(PCB, NPP, arg0);
        call_depth++;
    }

    function op_calz_cb(arg0 as U8, arg1 as U8) as Void {
        pc = (pc + 1) & 0x1FFF; // This does not actually change the PC register
        SET_M((sp - 1) & 0xFF, PCP);
        SET_M((sp - 2) & 0xFF, PCSH);
        SET_M((sp - 3) & 0xFF, PCSL);
        sp = (sp - 3) & 0xFF;
        next_pc = TO_PC(PCB, 0, arg0);
        call_depth++;
    }

    function op_ret_cb(arg0 as U8, arg1 as U8) as Void {
        next_pc = M(sp) | (M((sp + 1) & 0xFF) << 4) | (M((sp + 2) & 0xFF) << 8) | (PCB << 12);
        sp = (sp + 3) & 0xFF;
        if (call_depth > 0) {
            call_depth--;
        }
    }

    function op_rets_cb(arg0 as U8, arg1 as U8) as Void {
        next_pc = M(sp) | (M((sp + 1) & 0xFF) << 4) | (M((sp + 2) & 0xFF) << 8) | (PCB << 12);
        sp = (sp + 3) & 0xFF;
        next_pc = (next_pc + 1) & 0x1FFF;
        if (call_depth > 0) {
            call_depth--;
        }
    }

    function op_retd_cb(arg0 as U8, arg1 as U8) as Void {
        next_pc = M(sp) | (M((sp + 1) & 0xFF) << 4) | (M((sp + 2) & 0xFF) << 8) | (PCB << 12);
        sp = (sp + 3) & 0xFF;
        SET_M(x, arg0 & 0xF);
        SET_M(((x + 1) & 0xFF) | (XP << 8), (arg0 >> 4) & 0xF);
        x = ((x + 2) & 0xFF) | (XP << 8);
        if (call_depth > 0) {
            call_depth--;
        }
    }

    function op_nop5_cb(arg0 as U8, arg1 as U8) as Void {
    }

    function op_nop7_cb(arg0 as U8, arg1 as U8) as Void {
    }

    function op_halt_cb(arg0 as U8, arg1 as U8) as Void {
        cpu_halted = true;
    }

    function op_inc_x_cb(arg0 as U8, arg1 as U8) as Void {
        x = ((x + 1) & 0xFF) | (XP << 8);
    }

    function op_inc_y_cb(arg0 as U8, arg1 as U8) as Void {
        y = ((y + 1) & 0xFF) | (YP << 8);
    }

    function op_ld_x_cb(arg0 as U8, arg1 as U8) as Void {
        x = arg0 | (XP << 8);
    }

    function op_ld_y_cb(arg0 as U8, arg1 as U8) as Void {
        y = arg0 | (YP << 8);
    }

    function op_ld_xp_r_cb(arg0 as U8, arg1 as U8) as Void {
        x = XHL | (RQ(arg0) << 8);
    }

    function op_ld_xh_r_cb(arg0 as U8, arg1 as U8) as Void {
        x = XL | (RQ(arg0) << 4) | (XP << 8);
    }

    function op_ld_xl_r_cb(arg0 as U8, arg1 as U8) as Void {
        x = RQ(arg0) | (XH << 4) | (XP << 8);
    }

    function op_ld_yp_r_cb(arg0 as U8, arg1 as U8) as Void {
        y = YHL | (RQ(arg0) << 8);
    }

    function op_ld_yh_r_cb(arg0 as U8, arg1 as U8) as Void {
        y = YL | (RQ(arg0) << 4) | (YP << 8);
    }

    function op_ld_yl_r_cb(arg0 as U8, arg1 as U8) as Void {
        y = RQ(arg0) | (YH << 4) | (YP << 8);
    }

    function op_ld_r_xp_cb(arg0 as U8, arg1 as U8) as Void {
        SET_RQ(arg0, XP);
    }

    function op_ld_r_xh_cb(arg0 as U8, arg1 as U8) as Void {
        SET_RQ(arg0, XH);
    }

    function op_ld_r_xl_cb(arg0 as U8, arg1 as U8) as Void {
        SET_RQ(arg0, XL);
    }

    function op_ld_r_yp_cb(arg0 as U8, arg1 as U8) as Void {
        SET_RQ(arg0, YP);
    }

    function op_ld_r_yh_cb(arg0 as U8, arg1 as U8) as Void {
        SET_RQ(arg0, YH);
    }

    function op_ld_r_yl_cb(arg0 as U8, arg1 as U8) as Void {
        SET_RQ(arg0, YL);
    }

    function op_adc_xh_cb(arg0 as U8, arg1 as U8) as Void {
        var tmp;

        tmp = XH + arg0 + INT(C);
        x = XL | ((tmp & 0xF) << 4)| (XP << 8);
        if (BOOL(tmp >> 4)) { SET_C; } else { CLEAR_C; }
        if (!BOOL(tmp & 0xF)) { SET_Z; } else { CLEAR_Z; }
    }

    function op_adc_xl_cb(arg0 as U8, arg1 as U8) as Void {
        var tmp;

        tmp = XL + arg0 + INT(C);
        x = (tmp & 0xF) | (XH << 4) | (XP << 8);
        if (BOOL(tmp >> 4)) { SET_C; } else { CLEAR_C; }
        if (!BOOL(tmp & 0xF)) { SET_Z; } else { CLEAR_Z; }
    }

    function op_adc_yh_cb(arg0 as U8, arg1 as U8) as Void {
        var tmp;

        tmp = YH + arg0 + INT(C);
        y = YL | ((tmp & 0xF) << 4)| (YP << 8);
        if (BOOL(tmp >> 4)) { SET_C; } else { CLEAR_C; }
        if (!BOOL(tmp & 0xF)) { SET_Z; } else { CLEAR_Z; }
    }

    function op_adc_yl_cb(arg0 as U8, arg1 as U8) as Void {
        var tmp;

        tmp = YL + arg0 + INT(C);
        y = (tmp & 0xF) | (YH << 4) | (YP << 8);
        if (BOOL(tmp >> 4)) { SET_C; } else { CLEAR_C; }
        if (!BOOL(tmp & 0xF)) { SET_Z; } else { CLEAR_Z; }
    }

    function op_cp_xh_cb(arg0 as U8, arg1 as U8) as Void {
        if (XH < arg0) { SET_C; } else { CLEAR_C; }
        if (XH == arg0) { SET_Z; } else { CLEAR_Z; }
    }

    function op_cp_xl_cb(arg0 as U8, arg1 as U8) as Void {
        if (XL < arg0) { SET_C; } else { CLEAR_C; }
        if (XL == arg0) { SET_Z; } else { CLEAR_Z; }
    }

    function op_cp_yh_cb(arg0 as U8, arg1 as U8) as Void {
        if (YH < arg0) { SET_C; } else { CLEAR_C; }
        if (YH == arg0) { SET_Z; } else { CLEAR_Z; }
    }

    function op_cp_yl_cb(arg0 as U8, arg1 as U8) as Void {
        if (YL < arg0) { SET_C; } else { CLEAR_C; }
        if (YL == arg0) { SET_Z; } else { CLEAR_Z; }
    }

    function op_ld_r_i_cb(arg0 as U8, arg1 as U8) as Void {
        SET_RQ(arg0, arg1);
    }

    function op_ld_r_q_cb(arg0 as U8, arg1 as U8) as Void {
        SET_RQ(arg0, RQ(arg1));
    }

    function op_ld_a_mn_cb(arg0 as U8, arg1 as U8) as Void {
        a = M(arg0);
    }

    function op_ld_b_mn_cb(arg0 as U8, arg1 as U8) as Void {
        b = M(arg0);
    }

    function op_ld_mn_a_cb(arg0 as U8, arg1 as U8) as Void {
        SET_M(arg0, a);
    }

    function op_ld_mn_b_cb(arg0 as U8, arg1 as U8) as Void {
        SET_M(arg0, b);
    }

    function op_ldpx_mx_cb(arg0 as U8, arg1 as U8) as Void {
        SET_M(x, arg0);
        x = ((x + 1) & 0xFF) | (XP << 8);
    }

    function op_ldpx_r_cb(arg0 as U8, arg1 as U8) as Void {
        SET_RQ(arg0, RQ(arg1));
        x = ((x + 1) & 0xFF) | (XP << 8);
    }

    function op_ldpy_my_cb(arg0 as U8, arg1 as U8) as Void {
        SET_M(y, arg0);
        y = ((y + 1) & 0xFF) | (YP << 8);
    }

    function op_ldpy_r_cb(arg0 as U8, arg1 as U8) as Void {
        SET_RQ(arg0, RQ(arg1));
        y = ((y + 1) & 0xFF) | (YP << 8);
    }

    function op_lbpx_cb(arg0 as U8, arg1 as U8) as Void {
        SET_M(x, arg0 & 0xF);
        SET_M(((x + 1) & 0xFF) | (XP << 8), (arg0 >> 4) & 0xF);
        x = ((x + 2) & 0xFF) | (XP << 8);
    }

    function op_set_cb(arg0 as U8, arg1 as U8) as Void {
        flags |= arg0;
    }

    function op_rst_cb(arg0 as U8, arg1 as U8) as Void {
        flags &= arg0;
    }

    function op_scf_cb(arg0 as U8, arg1 as U8) as Void {
        SET_C;
    }

    function op_rcf_cb(arg0 as U8, arg1 as U8) as Void {
        CLEAR_C;
    }

    function op_szf_cb(arg0 as U8, arg1 as U8) as Void {
        SET_Z;
    }

    function op_rzf_cb(arg0 as U8, arg1 as U8) as Void {
        CLEAR_Z;
    }

    function op_sdf_cb(arg0 as U8, arg1 as U8) as Void {
        SET_D;
    }

    function op_rdf_cb(arg0 as U8, arg1 as U8) as Void {
        CLEAR_D;
    }

    function op_ei_cb(arg0 as U8, arg1 as U8) as Void {
        SET_I;
    }

    function op_di_cb(arg0 as U8, arg1 as U8) as Void {
        CLEAR_I;
    }

    function op_inc_sp_cb(arg0 as U8, arg1 as U8) as Void {
        sp = (sp + 1) & 0xFF;
    }

    function op_dec_sp_cb(arg0 as U8, arg1 as U8) as Void {
        sp = (sp - 1) & 0xFF;
    }

    function op_push_r_cb(arg0 as U8, arg1 as U8) as Void {
        sp = (sp - 1) & 0xFF;
        SET_M(sp, RQ(arg0));
    }

    function op_push_xp_cb(arg0 as U8, arg1 as U8) as Void {
        sp = (sp - 1) & 0xFF;
        SET_M(sp, XP);
    }

    function op_push_xh_cb(arg0 as U8, arg1 as U8) as Void {
        sp = (sp - 1) & 0xFF;
        SET_M(sp, XH);
    }

    function op_push_xl_cb(arg0 as U8, arg1 as U8) as Void {
        sp = (sp - 1) & 0xFF;
        SET_M(sp, XL);
    }

    function op_push_yp_cb(arg0 as U8, arg1 as U8) as Void {
        sp = (sp - 1) & 0xFF;
        SET_M(sp, YP);
    }

    function op_push_yh_cb(arg0 as U8, arg1 as U8) as Void {
        sp = (sp - 1) & 0xFF;
        SET_M(sp, YH);
    }

    function op_push_yl_cb(arg0 as U8, arg1 as U8) as Void {
        sp = (sp - 1) & 0xFF;
        SET_M(sp, YL);
    }

    function op_push_f_cb(arg0 as U8, arg1 as U8) as Void {
        sp = (sp - 1) & 0xFF;
        SET_M(sp, flags);
    }

    function op_pop_r_cb(arg0 as U8, arg1 as U8) as Void {
        SET_RQ(arg0, M(sp));
        sp = (sp + 1) & 0xFF;
    }

    function op_pop_xp_cb(arg0 as U8, arg1 as U8) as Void {
        x = XL | (XH << 4)| (M(sp) << 8);
        sp = (sp + 1) & 0xFF;
    }

    function op_pop_xh_cb(arg0 as U8, arg1 as U8) as Void {
        x = XL | (M(sp) << 4)| (XP << 8);
        sp = (sp + 1) & 0xFF;
    }

    function op_pop_xl_cb(arg0 as U8, arg1 as U8) as Void {
        x = M(sp) | (XH << 4)| (XP << 8);
        sp = (sp + 1) & 0xFF;
    }

    function op_pop_yp_cb(arg0 as U8, arg1 as U8) as Void {
        y = YL | (YH << 4)| (M(sp) << 8);
        sp = (sp + 1) & 0xFF;
    }

    function op_pop_yh_cb(arg0 as U8, arg1 as U8) as Void {
        y = YL | (M(sp) << 4)| (YP << 8);
        sp = (sp + 1) & 0xFF;
    }

    function op_pop_yl_cb(arg0 as U8, arg1 as U8) as Void {
        y = M(sp) | (YH << 4)| (YP << 8);
        sp = (sp + 1) & 0xFF;
    }

    function op_pop_f_cb(arg0 as U8, arg1 as U8) as Void {
        flags = M(sp);
        sp = (sp + 1) & 0xFF;
    }

    function op_ld_sph_r_cb(arg0 as U8, arg1 as U8) as Void {
        sp = SPL() | (RQ(arg0) << 4);
    }

    function op_ld_spl_r_cb(arg0 as U8, arg1 as U8) as Void {
        sp = RQ(arg0) | (SPH() << 4);
    }

    function op_ld_r_sph_cb(arg0 as U8, arg1 as U8) as Void {
        SET_RQ(arg0, SPH());
    }

    function op_ld_r_spl_cb(arg0 as U8, arg1 as U8) as Void {
        SET_RQ(arg0, SPL());
    }

    function op_add_r_i_cb(arg0 as U8, arg1 as U8) as Void {
        var tmp;

        tmp = RQ(arg0) + arg1;
        if (D) {
            if (tmp >= 10) {
                SET_RQ(arg0, (tmp - 10) & 0xF);
                SET_C;
            } else {
                SET_RQ(arg0, tmp);
                CLEAR_C;
            }
        } else {
            SET_RQ(arg0, tmp & 0xF);
            if (BOOL(tmp >> 4)) { SET_C; } else { CLEAR_C; }
        }
        if (!BOOL(RQ(arg0))) { SET_Z; } else { CLEAR_Z; }
    }

    function op_add_r_q_cb(arg0 as U8, arg1 as U8) as Void {
        var tmp;

        tmp = RQ(arg0) + RQ(arg1);
        if (D) {
            if (tmp >= 10) {
                SET_RQ(arg0, (tmp - 10) & 0xF);
                SET_C;
            } else {
                SET_RQ(arg0, tmp);
                CLEAR_C;
            }
        } else {
            SET_RQ(arg0, tmp & 0xF);
            if (BOOL(tmp >> 4)) { SET_C; } else { CLEAR_C; }
        }
        if (!BOOL(RQ(arg0))) { SET_Z; } else { CLEAR_Z; }
    }

    function op_adc_r_i_cb(arg0 as U8, arg1 as U8) as Void {
        var tmp;

        tmp = RQ(arg0) + arg1 + INT(C);
        if (D) {
            if (tmp >= 10) {
                SET_RQ(arg0, (tmp - 10) & 0xF);
                SET_C;
            } else {
                SET_RQ(arg0, tmp);
                CLEAR_C;
            }
        } else {
            SET_RQ(arg0, tmp & 0xF);
            if (BOOL(tmp >> 4)) { SET_C; } else { CLEAR_C; }
        }
        if (!BOOL(RQ(arg0))) { SET_Z; } else { CLEAR_Z; }
    }

    function op_adc_r_q_cb(arg0 as U8, arg1 as U8) as Void {
        var tmp;

        tmp = RQ(arg0) + RQ(arg1) + INT(C);
        if (D) {
            if (tmp >= 10) {
                SET_RQ(arg0, (tmp - 10) & 0xF);
                SET_C;
            } else {
                SET_RQ(arg0, tmp);
                CLEAR_C;
            }
        } else {
            SET_RQ(arg0, tmp & 0xF);
            if (BOOL(tmp >> 4)) { SET_C; } else { CLEAR_C; }
        }
        if (!BOOL(RQ(arg0))) { SET_Z; } else { CLEAR_Z; }
    }

    function op_sub_cb(arg0 as U8, arg1 as U8) as Void {
        var tmp;

        tmp = RQ(arg0) - RQ(arg1);
        if (D) {
            if (BOOL(tmp >> 4)) {
                SET_RQ(arg0, (tmp - 6) & 0xF);
            } else {
                SET_RQ(arg0, tmp);
            }
        } else {
            SET_RQ(arg0, tmp & 0xF);
        }
        if (BOOL(tmp >> 4)) { SET_C; } else { CLEAR_C; }
        if (!BOOL(RQ(arg0))) { SET_Z; } else { CLEAR_Z; }
    }

    function op_sbc_r_i_cb(arg0 as U8, arg1 as U8) as Void {
        var tmp;

        tmp = RQ(arg0) - arg1 - INT(C);
        if (D) {
            if (BOOL(tmp >> 4)) {
                SET_RQ(arg0, (tmp - 6) & 0xF);
            } else {
                SET_RQ(arg0, tmp);
            }
        } else {
            SET_RQ(arg0, tmp & 0xF);
        }
        if (BOOL(tmp >> 4)) { SET_C; } else { CLEAR_C; }
        if (!BOOL(RQ(arg0))) { SET_Z; } else { CLEAR_Z; }
    }

    function op_sbc_r_q_cb(arg0 as U8, arg1 as U8) as Void {
        var tmp;

        tmp = RQ(arg0) - RQ(arg1) - INT(C);
        if (D) {
            if (BOOL(tmp >> 4)) {
                SET_RQ(arg0, (tmp - 6) & 0xF);
            } else {
                SET_RQ(arg0, tmp);
            }
        } else {
            SET_RQ(arg0, tmp & 0xF);
        }
        if (BOOL(tmp >> 4)) { SET_C; } else { CLEAR_C; }
        if (!BOOL(RQ(arg0))) { SET_Z; } else { CLEAR_Z; }
    }

    function op_and_r_i_cb(arg0 as U8, arg1 as U8) as Void {
        SET_RQ(arg0, RQ(arg0) & arg1);
        if (!BOOL(RQ(arg0))) { SET_Z; } else { CLEAR_Z; }
    }

    function op_and_r_q_cb(arg0 as U8, arg1 as U8) as Void {
        SET_RQ(arg0, RQ(arg0) & RQ(arg1));
        if (!BOOL(RQ(arg0))) { SET_Z; } else { CLEAR_Z; }
    }

    function op_or_r_i_cb(arg0 as U8, arg1 as U8) as Void {
        SET_RQ(arg0, RQ(arg0) | arg1);
        if (!BOOL(RQ(arg0))) { SET_Z; } else { CLEAR_Z; }
    }

    function op_or_r_q_cb(arg0 as U8, arg1 as U8) as Void {
        SET_RQ(arg0, RQ(arg0) | RQ(arg1));
        if (!BOOL(RQ(arg0))) { SET_Z; } else { CLEAR_Z; }
    }

    function op_xor_r_i_cb(arg0 as U8, arg1 as U8) as Void {
        SET_RQ(arg0, RQ(arg0) ^ arg1);
        if (!BOOL(RQ(arg0))) { SET_Z; } else { CLEAR_Z; }
    }

    function op_xor_r_q_cb(arg0 as U8, arg1 as U8) as Void {
        SET_RQ(arg0, RQ(arg0) ^ RQ(arg1));
        if (!BOOL(RQ(arg0))) { SET_Z; } else { CLEAR_Z; }
    }

    function op_cp_r_i_cb(arg0 as U8, arg1 as U8) as Void {
        if (RQ(arg0) < arg1) { SET_C; } else { CLEAR_C; }
        if (RQ(arg0) == arg1) { SET_Z; } else { CLEAR_Z; }
    }

    function op_cp_r_q_cb(arg0 as U8, arg1 as U8) as Void {
        if (RQ(arg0) < RQ(arg1)) { SET_C; } else { CLEAR_C; }
        if (RQ(arg0) == RQ(arg1)) { SET_Z; } else { CLEAR_Z; }
    }

    function op_fan_r_i_cb(arg0 as U8, arg1 as U8) as Void {
        if (!BOOL(RQ(arg0) & arg1)) { SET_Z; } else { CLEAR_Z; }
    }

    function op_fan_r_q_cb(arg0 as U8, arg1 as U8) as Void {
        if (!BOOL(RQ(arg0) & RQ(arg1))) { SET_Z; } else { CLEAR_Z; }
    }

    function op_rlc_cb(arg0 as U8, arg1 as U8) as Void {
        var tmp;

        tmp = (RQ(arg0) << 1) | INT(C);
        if (BOOL(RQ(arg0) & 0x8)) { SET_C; } else { CLEAR_C; }
        SET_RQ(arg0, tmp & 0xF);
        /* No need to set Z (issue in DS) */
    }

    function op_rrc_cb(arg0 as U8, arg1 as U8) as Void {
        var tmp;

        tmp = (RQ(arg0) >> 1) | (INT(C) << 3);
        if (BOOL(RQ(arg0) & 0x1)) { SET_C; } else { CLEAR_C; }
        SET_RQ(arg0, tmp & 0xF);
        /* No need to set Z (issue in DS) */
    }

    function op_inc_mn_cb(arg0 as U8, arg1 as U8) as Void {
        var tmp;

        tmp = M(arg0) + 1;
        SET_M(arg0, tmp & 0xF);
        if (BOOL(tmp >> 4)) { SET_C; } else { CLEAR_C; }
        if (!BOOL(M(arg0))) { SET_Z; } else { CLEAR_Z; }
    }

    function op_dec_mn_cb(arg0 as U8, arg1 as U8) as Void {
        var tmp;

        tmp = M(arg0) - 1;
        SET_M(arg0, tmp & 0xF);
        if (BOOL(tmp >> 4)) { SET_C; } else { CLEAR_C; }
        if (!BOOL(M(arg0))) { SET_Z; } else { CLEAR_Z; }
    }

    function op_acpx_cb(arg0 as U8, arg1 as U8) as Void {
        var tmp;

        tmp = M(x) + RQ(arg0) + INT(C);
        if (D) {
            if (tmp >= 10) {
                SET_M(x, (tmp - 10) & 0xF);
                SET_C;
            } else {
                SET_M(x, tmp);
                CLEAR_C;
            }
        } else {
            SET_M(x, tmp & 0xF);
            if (BOOL(tmp >> 4)) { SET_C; } else { CLEAR_C; }
        }
        if (!BOOL(M(x))) { SET_Z; } else { CLEAR_Z; }
        x = ((x + 1) & 0xFF) | (XP << 8);
    }

    function op_acpy_cb(arg0 as U8, arg1 as U8) as Void {
        var tmp;

        tmp = M(y) + RQ(arg0) + INT(C);
        if (D) {
            if (tmp >= 10) {
                SET_M(y, (tmp - 10) & 0xF);
                SET_C;
            } else {
                SET_M(y, tmp);
                CLEAR_C;
            }
        } else {
            SET_M(y, tmp & 0xF);
            if (BOOL(tmp >> 4)) { SET_C; } else { CLEAR_C; }
        }
        if (!BOOL(M(y))) { SET_Z; } else { CLEAR_Z; }
        y = ((y + 1) & 0xFF) | (YP << 8);
    }

    function op_scpx_cb(arg0 as U8, arg1 as U8) as Void {
        var tmp;

        tmp = M(x) - RQ(arg0) - INT(C);
        if (D) {
            if (BOOL(tmp >> 4)) {
                SET_M(x, (tmp - 6) & 0xF);
            } else {
                SET_M(x, tmp);
            }
        } else {
            SET_M(x, tmp & 0xF);
        }
        if (BOOL(tmp >> 4)) { SET_C; } else { CLEAR_C; }
        if (!BOOL(M(x))) { SET_Z; } else { CLEAR_Z; }
        x = ((x + 1) & 0xFF) | (XP << 8);
    }

    function op_scpy_cb(arg0 as U8, arg1 as U8) as Void {
        var tmp;

        tmp = M(y) - RQ(arg0) - INT(C);
        if (D) {
            if (BOOL(tmp >> 4)) {
                SET_M(y, (tmp - 6) & 0xF);
            } else {
                SET_M(y, tmp);
            }
        } else {
            SET_M(y, tmp & 0xF);
        }
        if (BOOL(tmp >> 4)) { SET_C; } else { CLEAR_C; }
        if (!BOOL(M(y))) { SET_Z; } else { CLEAR_Z; }
        y = ((y + 1) & 0xFF) | (YP << 8);
    }

    function op_not_cb(arg0 as U8, arg1 as U8) as Void {
        SET_RQ(arg0, ~RQ(arg0) & 0xF);
        if (!BOOL(RQ(arg0))) { SET_Z; } else { CLEAR_Z; }
    }

    /* The E0C6S46 supported instructions */
    const OPS as Ops = [
        new Op("PSET #0x%02X            ",  0xE40, MASK_7B,  0, 0,     5,  method(:op_pset_cb)    ), // PSET
        new Op("JP   #0x%02X            ",  0x000, MASK_4B,  0, 0,     5,  method(:op_jp_cb)      ), // JP
        new Op("JP   C #0x%02X          ",  0x200, MASK_4B,  0, 0,     5,  method(:op_jp_c_cb)    ), // JP_C
        new Op("JP   NC #0x%02X         ",  0x300, MASK_4B,  0, 0,     5,  method(:op_jp_nc_cb)   ), // JP_NC
        new Op("JP   Z #0x%02X          ",  0x600, MASK_4B,  0, 0,     5,  method(:op_jp_z_cb)    ), // JP_Z
        new Op("JP   NZ #0x%02X         ",  0x700, MASK_4B,  0, 0,     5,  method(:op_jp_nz_cb)   ), // JP_NZ
        new Op("JPBA                  ",    0xFE8, MASK_12B, 0, 0,     5,  method(:op_jpba_cb)    ), // JPBA
        new Op("CALL #0x%02X            ",  0x400, MASK_4B,  0, 0,     7,  method(:op_call_cb)    ), // CALL
        new Op("CALZ #0x%02X            ",  0x500, MASK_4B,  0, 0,     7,  method(:op_calz_cb)    ), // CALZ
        new Op("RET                   ",    0xFDF, MASK_12B, 0, 0,     7,  method(:op_ret_cb)     ), // RET
        new Op("RETS                  ",    0xFDE, MASK_12B, 0, 0,     12, method(:op_rets_cb)    ), // RETS
        new Op("RETD #0x%02X            ",  0x100, MASK_4B,  0, 0,     12, method(:op_retd_cb)    ), // RETD
        new Op("NOP5                  ",    0xFFB, MASK_12B, 0, 0,     5,  method(:op_nop5_cb)    ), // NOP5
        new Op("NOP7                  ",    0xFFF, MASK_12B, 0, 0,     7,  method(:op_nop7_cb)    ), // NOP7
        new Op("HALT                  ",    0xFF8, MASK_12B, 0, 0,     5,  method(:op_halt_cb)    ), // HALT
        new Op("INC  X #0x%02X          ",  0xEE0, MASK_12B, 0, 0,     5,  method(:op_inc_x_cb)   ), // INC_X
        new Op("INC  Y #0x%02X          ",  0xEF0, MASK_12B, 0, 0,     5,  method(:op_inc_y_cb)   ), // INC_Y
        new Op("LD   X #0x%02X          ",  0xB00, MASK_4B,  0, 0,     5,  method(:op_ld_x_cb)    ), // LD_X
        new Op("LD   Y #0x%02X          ",  0x800, MASK_4B,  0, 0,     5,  method(:op_ld_y_cb)    ), // LD_Y
        new Op("LD   XP R(%X)          ",   0xE80, MASK_10B, 0, 0,     5,  method(:op_ld_xp_r_cb) ), // LD_XP_R
        new Op("LD   XH R(%X)          ",   0xE84, MASK_10B, 0, 0,     5,  method(:op_ld_xh_r_cb) ), // LD_XH_R
        new Op("LD   XL R(%X)          ",   0xE88, MASK_10B, 0, 0,     5,  method(:op_ld_xl_r_cb) ), // LD_XL_R
        new Op("LD   YP R(%X)          ",   0xE90, MASK_10B, 0, 0,     5,  method(:op_ld_yp_r_cb) ), // LD_YP_R
        new Op("LD   YH R(%X)          ",   0xE94, MASK_10B, 0, 0,     5,  method(:op_ld_yh_r_cb) ), // LD_YH_R
        new Op("LD   YL R(%X)          ",   0xE98, MASK_10B, 0, 0,     5,  method(:op_ld_yl_r_cb) ), // LD_YL_R
        new Op("LD   R(%X) XP          ",   0xEA0, MASK_10B, 0, 0,     5,  method(:op_ld_r_xp_cb) ), // LD_R_XP
        new Op("LD   R(%X) XH          ",   0xEA4, MASK_10B, 0, 0,     5,  method(:op_ld_r_xh_cb) ), // LD_R_XH
        new Op("LD   R(%X) XL          ",   0xEA8, MASK_10B, 0, 0,     5,  method(:op_ld_r_xl_cb) ), // LD_R_XL
        new Op("LD   R(%X) YP          ",   0xEB0, MASK_10B, 0, 0,     5,  method(:op_ld_r_yp_cb) ), // LD_R_YP
        new Op("LD   R(%X) YH          ",   0xEB4, MASK_10B, 0, 0,     5,  method(:op_ld_r_yh_cb) ), // LD_R_YH
        new Op("LD   R(%X) YL          ",   0xEB8, MASK_10B, 0, 0,     5,  method(:op_ld_r_yl_cb) ), // LD_R_YL
        new Op("ADC  XH #0x%02X         ",  0xA00, MASK_8B,  0, 0,     7,  method(:op_adc_xh_cb)  ), // ADC_XH
        new Op("ADC  XL #0x%02X         ",  0xA10, MASK_8B,  0, 0,     7,  method(:op_adc_xl_cb)  ), // ADC_XL
        new Op("ADC  YH #0x%02X         ",  0xA20, MASK_8B,  0, 0,     7,  method(:op_adc_yh_cb)  ), // ADC_YH
        new Op("ADC  YL #0x%02X         ",  0xA30, MASK_8B,  0, 0,     7,  method(:op_adc_yl_cb)  ), // ADC_YL
        new Op("CP   XH #0x%02X         ",  0xA40, MASK_8B,  0, 0,     7,  method(:op_cp_xh_cb)   ), // CP_XH
        new Op("CP   XL #0x%02X         ",  0xA50, MASK_8B,  0, 0,     7,  method(:op_cp_xl_cb)   ), // CP_XL
        new Op("CP   YH #0x%02X         ",  0xA60, MASK_8B,  0, 0,     7,  method(:op_cp_yh_cb)   ), // CP_YH
        new Op("CP   YL #0x%02X         ",  0xA70, MASK_8B,  0, 0,     7,  method(:op_cp_yl_cb)   ), // CP_YL
        new Op("LD   R(%X) #0x%02X       ", 0xE00, MASK_6B,  4, 0x030, 5,  method(:op_ld_r_i_cb)  ), // LD_R_I
        new Op("LD   R(%X) Q(%X)        ",  0xEC0, MASK_8B,  2, 0x00C, 5,  method(:op_ld_r_q_cb)  ), // LD_R_Q
        new Op("LD   A M(#0x%02X)       ",  0xFA0, MASK_8B,  0, 0,     5,  method(:op_ld_a_mn_cb) ), // LD_A_MN
        new Op("LD   B M(#0x%02X)       ",  0xFB0, MASK_8B,  0, 0,     5,  method(:op_ld_b_mn_cb) ), // LD_B_MN
        new Op("LD   M(#0x%02X) A       ",  0xF80, MASK_8B,  0, 0,     5,  method(:op_ld_mn_a_cb) ), // LD_MN_A
        new Op("LD   M(#0x%02X) B       ",  0xF90, MASK_8B,  0, 0,     5,  method(:op_ld_mn_b_cb) ), // LD_MN_B
        new Op("LDPX MX #0x%02X         ",  0xE60, MASK_8B,  0, 0,     5,  method(:op_ldpx_mx_cb) ), // LDPX_MX
        new Op("LDPX R(%X) Q(%X)        ",  0xEE0, MASK_8B,  2, 0x00C, 5,  method(:op_ldpx_r_cb)  ), // LDPX_R
        new Op("LDPY MY #0x%02X         ",  0xE70, MASK_8B,  0, 0,     5,  method(:op_ldpy_my_cb) ), // LDPY_MY
        new Op("LDPY R(%X) Q(%X)        ",  0xEF0, MASK_8B,  2, 0x00C, 5,  method(:op_ldpy_r_cb)  ), // LDPY_R
        new Op("LBPX #0x%02X            ",  0x900, MASK_4B,  0, 0,     5,  method(:op_lbpx_cb)    ), // LBPX
        new Op("SET  #0x%02X            ",  0xF40, MASK_8B,  0, 0,     7,  method(:op_set_cb)     ), // SET
        new Op("RST  #0x%02X            ",  0xF50, MASK_8B,  0, 0,     7,  method(:op_rst_cb)     ), // RST
        new Op("SCF                   ",    0xF41, MASK_12B, 0, 0,     7,  method(:op_scf_cb)     ), // SCF
        new Op("RCF                   ",    0xF5E, MASK_12B, 0, 0,     7,  method(:op_rcf_cb)     ), // RCF
        new Op("SZF                   ",    0xF42, MASK_12B, 0, 0,     7,  method(:op_szf_cb)     ), // SZF
        new Op("RZF                   ",    0xF5D, MASK_12B, 0, 0,     7,  method(:op_rzf_cb)     ), // RZF
        new Op("SDF                   ",    0xF44, MASK_12B, 0, 0,     7,  method(:op_sdf_cb)     ), // SDF
        new Op("RDF                   ",    0xF5B, MASK_12B, 0, 0,     7,  method(:op_rdf_cb)     ), // RDF
        new Op("EI                    ",    0xF48, MASK_12B, 0, 0,     7,  method(:op_ei_cb)      ), // EI
        new Op("DI                    ",    0xF57, MASK_12B, 0, 0,     7,  method(:op_di_cb)      ), // DI
        new Op("INC  SP               ",    0xFDB, MASK_12B, 0, 0,     5,  method(:op_inc_sp_cb)  ), // INC_SP
        new Op("DEC  SP               ",    0xFCB, MASK_12B, 0, 0,     5,  method(:op_dec_sp_cb)  ), // DEC_SP
        new Op("PUSH R(%X)             ",   0xFC0, MASK_10B, 0, 0,     5,  method(:op_push_r_cb)  ), // PUSH_R
        new Op("PUSH XP               ",    0xFC4, MASK_12B, 0, 0,     5,  method(:op_push_xp_cb) ), // PUSH_XP
        new Op("PUSH XH               ",    0xFC5, MASK_12B, 0, 0,     5,  method(:op_push_xh_cb) ), // PUSH_XH
        new Op("PUSH XL               ",    0xFC6, MASK_12B, 0, 0,     5,  method(:op_push_xl_cb) ), // PUSH_XL
        new Op("PUSH YP               ",    0xFC7, MASK_12B, 0, 0,     5,  method(:op_push_yp_cb) ), // PUSH_YP
        new Op("PUSH YH               ",    0xFC8, MASK_12B, 0, 0,     5,  method(:op_push_yh_cb) ), // PUSH_YH
        new Op("PUSH YL               ",    0xFC9, MASK_12B, 0, 0,     5,  method(:op_push_yl_cb) ), // PUSH_YL
        new Op("PUSH F                ",    0xFCA, MASK_12B, 0, 0,     5,  method(:op_push_f_cb)  ), // PUSH_F
        new Op("POP  R(%X)             ",   0xFD0, MASK_10B, 0, 0,     5,  method(:op_pop_r_cb)   ), // POP_R
        new Op("POP  XP               ",    0xFD4, MASK_12B, 0, 0,     5,  method(:op_pop_xp_cb)  ), // POP_XP
        new Op("POP  XH               ",    0xFD5, MASK_12B, 0, 0,     5,  method(:op_pop_xh_cb)  ), // POP_XH
        new Op("POP  XL               ",    0xFD6, MASK_12B, 0, 0,     5,  method(:op_pop_xl_cb)  ), // POP_XL
        new Op("POP  YP               ",    0xFD7, MASK_12B, 0, 0,     5,  method(:op_pop_yp_cb)  ), // POP_YP
        new Op("POP  YH               ",    0xFD8, MASK_12B, 0, 0,     5,  method(:op_pop_yh_cb)  ), // POP_YH
        new Op("POP  YL               ",    0xFD9, MASK_12B, 0, 0,     5,  method(:op_pop_yl_cb)  ), // POP_YL
        new Op("POP  F                ",    0xFDA, MASK_12B, 0, 0,     5,  method(:op_pop_f_cb)   ), // POP_F
        new Op("LD   SPH R(%X)         ",   0xFE0, MASK_10B, 0, 0,     5,  method(:op_ld_sph_r_cb)), // LD_SPH_R
        new Op("LD   SPL R(%X)         ",   0xFF0, MASK_10B, 0, 0,     5,  method(:op_ld_spl_r_cb)), // LD_SPL_R
        new Op("LD   R(%X) SPH     ",       0xFE4, MASK_10B, 0, 0,     5,  method(:op_ld_r_sph_cb)), // LD_R_SPH
        new Op("LD   R(%X) SPL     ",       0xFF4, MASK_10B, 0, 0,     5,  method(:op_ld_r_spl_cb)), // LD_R_SPL
        new Op("ADD  R(%X) #0x%02X       ", 0xC00, MASK_6B,  4, 0x030, 7,  method(:op_add_r_i_cb) ), // ADD_R_I
        new Op("ADD  R(%X) Q(%X)        ",  0xA80, MASK_8B,  2, 0x00C, 7,  method(:op_add_r_q_cb) ), // ADD_R_Q
        new Op("ADC  R(%X) #0x%02X       ", 0xC40, MASK_6B,  4, 0x030, 7,  method(:op_adc_r_i_cb) ), // ADC_R_I
        new Op("ADC  R(%X) Q(%X)        ",  0xA90, MASK_8B,  2, 0x00C, 7,  method(:op_adc_r_q_cb) ), // ADC_R_Q
        new Op("SUB  R(%X) Q(%X)        ",  0xAA0, MASK_8B,  2, 0x00C, 7,  method(:op_sub_cb)     ), // SUB
        new Op("SBC  R(%X) #0x%02X       ", 0xD40, MASK_6B,  4, 0x030, 7,  method(:op_sbc_r_i_cb) ), // SBC_R_I
        new Op("SBC  R(%X) Q(%X)        ",  0xAB0, MASK_8B,  2, 0x00C, 7,  method(:op_sbc_r_q_cb) ), // SBC_R_Q
        new Op("AND  R(%X) #0x%02X       ", 0xC80, MASK_6B,  4, 0x030, 7,  method(:op_and_r_i_cb) ), // AND_R_I
        new Op("AND  R(%X) Q(%X)        ",  0xAC0, MASK_8B,  2, 0x00C, 7,  method(:op_and_r_q_cb) ), // AND_R_Q
        new Op("OR   R(%X) #0x%02X       ", 0xCC0, MASK_6B,  4, 0x030, 7,  method(:op_or_r_i_cb)  ), // OR_R_I
        new Op("OR   R(%X) Q(%X)        ",  0xAD0, MASK_8B,  2, 0x00C, 7,  method(:op_or_r_q_cb)  ), // OR_R_Q
        new Op("XOR  R(%X) #0x%02X       ", 0xD00, MASK_6B,  4, 0x030, 7,  method(:op_xor_r_i_cb) ), // XOR_R_I
        new Op("XOR  R(%X) Q(%X)        ",  0xAE0, MASK_8B,  2, 0x00C, 7,  method(:op_xor_r_q_cb) ), // XOR_R_Q
        new Op("CP   R(%X) #0x%02X       ", 0xDC0, MASK_6B,  4, 0x030, 7,  method(:op_cp_r_i_cb)  ), // CP_R_I
        new Op("CP   R(%X) Q(%X)        ",  0xF00, MASK_8B,  2, 0x00C, 7,  method(:op_cp_r_q_cb)  ), // CP_R_Q
        new Op("FAN  R(%X) #0x%02X       ", 0xD80, MASK_6B,  4, 0x030, 7,  method(:op_fan_r_i_cb) ), // FAN_R_I
        new Op("FAN  R(%X) Q(%X)        ",  0xF10, MASK_8B,  2, 0x00C, 7,  method(:op_fan_r_q_cb) ), // FAN_R_Q
        new Op("RLC  R(%X)             ",   0xAF0, MASK_8B,  0, 0,     7,  method(:op_rlc_cb)     ), // RLC
        new Op("RRC  R(%X)             ",   0xE8C, MASK_10B, 0, 0,     5,  method(:op_rrc_cb)     ), // RRC
        new Op("INC  M(#0x%02X)         ",  0xF60, MASK_8B,  0, 0,     7,  method(:op_inc_mn_cb)  ), // INC_MN
        new Op("DEC  M(#0x%02X)         ",  0xF70, MASK_8B,  0, 0,     7,  method(:op_dec_mn_cb)  ), // DEC_MN
        new Op("ACPX R(%X)             ",   0xF28, MASK_10B, 0, 0,     7,  method(:op_acpx_cb)    ), // ACPX
        new Op("ACPY R(%X)             ",   0xF2C, MASK_10B, 0, 0,     7,  method(:op_acpy_cb)    ), // ACPY
        new Op("SCPX R(%X)             ",   0xF38, MASK_10B, 0, 0,     7,  method(:op_scpx_cb)    ), // SCPX
        new Op("SCPY R(%X)             ",   0xF3C, MASK_10B, 0, 0,     7,  method(:op_scpy_cb)    ), // SCPY
        new Op("NOT  R(%X)             ",   0xD0F, 0xFCF,    4, 0,     7,  method(:op_not_cb)     ), // NOT
    ];

    function wait_for_cycles(since as Timestamp, cycles as U8) as Timestamp {
        /* The tick counter always works at TICK_FREQUENCY,
        * while the CPU runs at cpu_frequency
        */
        scaled_cycle_accumulator += cycles * TICK_FREQUENCY;
        var ticks_pending = scaled_cycle_accumulator / cpu_frequency;

        if (ticks_pending > 0) {
            tick_counter += ticks_pending;
            scaled_cycle_accumulator -= ticks_pending * cpu_frequency;
        }

        if (speed_ratio == 0) {
            /* Emulation will be as fast as possible */
            return g_hal.get_timestamp();
        }

        var deadline = since + (cycles * ts_freq) / (cpu_frequency * speed_ratio);
        g_hal.sleep_until(deadline);

        return deadline;
    }

    function process_interrupts() as Void {
        /* Process interrupts in priority order */
        for (var i = 0; i < INT_SLOT_NUM; i++) {
            if (interrupts[i].triggered) {
                g_hal.log(LOG_INT, "Interrupt %s (%u) triggered\n", [interrupt_names[i], i]);
                SET_M((sp - 1) & 0xFF, PCP);
                SET_M((sp - 2) & 0xFF, PCSH);
                SET_M((sp - 3) & 0xFF, PCSL);
                sp = (sp - 3) & 0xFF;
                CLEAR_I;
                np = TO_NP(NBP, 1);
                pc = TO_PC(PCB, 1, interrupts[i].vector);
                call_depth++;
                cpu_halted = false;

                ref_ts = wait_for_cycles(ref_ts, 12);
                interrupts[i].triggered = false;
                return;
            }
        }
    }

    (:disable_log) function print_state(op_num as U8, op as U12, addr as U13) as Void {}
    (:enable_log)  function print_state(op_num as U8, op as U12, addr as U13) as Void {
        var i;

        if (!g_hal.is_log_enabled(LOG_CPU)) {
            return;
        }

        g_hal.log(LOG_CPU, "0x%04X: ", [addr]);

        if (call_depth < 100) {
            for (i = 0; i < call_depth; i++) {
                g_hal.log(LOG_CPU, "  ", []);
            }
        } else {
            /* Something went wrong with the call depth */
            g_hal.log(LOG_CPU, "<<< ", []);
        }

        if (OPS[op_num].mask_arg0 != 0) {
            /* Two arguments */
            g_hal.log(LOG_CPU, OPS[op_num].log, [(op & OPS[op_num].mask_arg0) >> OPS[op_num].shift_arg0, op & ~(OPS[op_num].mask | OPS[op_num].mask_arg0)]);
        } else {
            /* One argument */
            g_hal.log(LOG_CPU, OPS[op_num].log, [(op & ~OPS[op_num].mask) >> OPS[op_num].shift_arg0]);
        }

        if (call_depth < 10) {
            for (i = 0; i < (10 - call_depth); i++) {
                g_hal.log(LOG_CPU, "  ", []);
            }
        }

        g_hal.log(LOG_CPU, " ; 0x%03X - ", [op]);
        for (i = 0; i < 12; i++) {
            g_hal.log(LOG_CPU, "%s", [((op >> (11 - i)) & 0x1) ? "1" : "0"]);
        }
        g_hal.log(LOG_CPU, " - PC = 0x%04X, SP = 0x%02X, NP = 0x%02X, X = 0x%03X, Y = 0x%03X, A = 0x%X, B = 0x%X, F = 0x%X\n", [pc, sp, np, x, y, a, b, flags]);
    }

    function handle_timers() as Void {
        /* Handle timers using the internal tick counter */
        if (tick_counter - clk_timer_2hz_timestamp >= TIMER_2HZ_PERIOD) {
            do {
                clk_timer_2hz_timestamp += TIMER_2HZ_PERIOD;
            } while (tick_counter - clk_timer_2hz_timestamp >= TIMER_2HZ_PERIOD);

            /* Update clock timer data for 1Hz */
            SET_IO_MEMORY(memory, REG_CLOCK_TIMER_DATA_2, GET_IO_MEMORY(memory, REG_CLOCK_TIMER_DATA_2) ^ (0x1 << 3));

            /* Generate interrupt on falling edge only (1Hz) */
            if (!BOOL((GET_IO_MEMORY(memory, REG_CLOCK_TIMER_DATA_2) >> 3) & 0x1 )) {
                generate_interrupt(INT_CLOCK_TIMER_SLOT, 3);
            }
        }

        if (tick_counter - clk_timer_4hz_timestamp >= TIMER_4HZ_PERIOD) {
            do {
                clk_timer_4hz_timestamp += TIMER_4HZ_PERIOD;
            } while (tick_counter - clk_timer_4hz_timestamp >= TIMER_4HZ_PERIOD);

            /* Update clock timer data for 2Hz */
            SET_IO_MEMORY(memory, REG_CLOCK_TIMER_DATA_2, GET_IO_MEMORY(memory, REG_CLOCK_TIMER_DATA_2) ^ (0x1 << 2));

            /* Generate interrupt on falling edge only (2Hz) */
            if (!BOOL((GET_IO_MEMORY(memory, REG_CLOCK_TIMER_DATA_2) >> 2) & 0x1 )) {
                generate_interrupt(INT_CLOCK_TIMER_SLOT, 2);
            }
        }

        if (tick_counter - clk_timer_8hz_timestamp >= TIMER_8HZ_PERIOD) {
            do {
                clk_timer_8hz_timestamp += TIMER_8HZ_PERIOD;
            } while (tick_counter - clk_timer_8hz_timestamp >= TIMER_8HZ_PERIOD);

            /* Update clock timer data for 4Hz */
            SET_IO_MEMORY(memory, REG_CLOCK_TIMER_DATA_2, GET_IO_MEMORY(memory, REG_CLOCK_TIMER_DATA_2) ^ (0x1 << 1));
        }

        if (tick_counter - clk_timer_16hz_timestamp >= TIMER_16HZ_PERIOD) {
            do {
                clk_timer_16hz_timestamp += TIMER_16HZ_PERIOD;
            } while (tick_counter - clk_timer_16hz_timestamp >= TIMER_16HZ_PERIOD);

            /* Update clock timer data for 8Hz */
            SET_IO_MEMORY(memory, REG_CLOCK_TIMER_DATA_2, GET_IO_MEMORY(memory, REG_CLOCK_TIMER_DATA_2) ^ (0x1 << 0));

            /* Generate interrupt on falling edge only (8Hz) */
            if (!BOOL((GET_IO_MEMORY(memory, REG_CLOCK_TIMER_DATA_2) >>0) & 0x1 )) {
                generate_interrupt(INT_CLOCK_TIMER_SLOT, 1);
            }
        }

        if (tick_counter - clk_timer_32hz_timestamp >= TIMER_32HZ_PERIOD) {
            do {
                clk_timer_32hz_timestamp += TIMER_32HZ_PERIOD;
            } while (tick_counter - clk_timer_32hz_timestamp >= TIMER_32HZ_PERIOD);

            /* Update clock timer data for 16Hz */
            SET_IO_MEMORY(memory, REG_CLOCK_TIMER_DATA_1, GET_IO_MEMORY(memory, REG_CLOCK_TIMER_DATA_1) ^ (0x1 << 3));
        }

        if (tick_counter - clk_timer_64hz_timestamp >= TIMER_64HZ_PERIOD) {
            do {
                clk_timer_64hz_timestamp += TIMER_64HZ_PERIOD;
            } while (tick_counter - clk_timer_64hz_timestamp >= TIMER_64HZ_PERIOD);

            /* Update clock timer data for 32Hz */
            SET_IO_MEMORY(memory, REG_CLOCK_TIMER_DATA_1, GET_IO_MEMORY(memory, REG_CLOCK_TIMER_DATA_1) ^ (0x1 << 2));

            /* Generate interrupt on falling edge only (32Hz) */
            if (!BOOL((GET_IO_MEMORY(memory, REG_CLOCK_TIMER_DATA_1) >> 2) & 0x1 )) {
                generate_interrupt(INT_CLOCK_TIMER_SLOT, 0);
            }
        }

        if (tick_counter - clk_timer_128hz_timestamp >= TIMER_128HZ_PERIOD) {
            do {
                clk_timer_128hz_timestamp += TIMER_128HZ_PERIOD;
            } while (tick_counter - clk_timer_128hz_timestamp >= TIMER_128HZ_PERIOD);

            /* Update clock timer data for 64Hz */
            SET_IO_MEMORY(memory, REG_CLOCK_TIMER_DATA_1, GET_IO_MEMORY(memory, REG_CLOCK_TIMER_DATA_1) ^ (0x1 << 1));
        }

        if (tick_counter - clk_timer_256hz_timestamp >= TIMER_256HZ_PERIOD) {
            do {
                clk_timer_256hz_timestamp += TIMER_256HZ_PERIOD;
            } while (tick_counter - clk_timer_256hz_timestamp >= TIMER_256HZ_PERIOD);

            /* Update clock timer data for 128Hz */
            SET_IO_MEMORY(memory, REG_CLOCK_TIMER_DATA_1, GET_IO_MEMORY(memory, REG_CLOCK_TIMER_DATA_1) ^ (0x1 << 0));
        }

        if (prog_timer_enabled && tick_counter - prog_timer_timestamp >= TIMER_256HZ_PERIOD) {
            do {
                prog_timer_timestamp += TIMER_256HZ_PERIOD;
                prog_timer_data--;

                if (prog_timer_data == 0) {
                    prog_timer_data = prog_timer_rld;
                    generate_interrupt(INT_PROG_TIMER_SLOT, 0);
                }
            } while (tick_counter - prog_timer_timestamp >= TIMER_256HZ_PERIOD);
        }
    }

    function reset() as Void {
        /* Registers and variables init */
        pc = TO_PC(0, 1, 0x00); // PC starts at bank 0, page 1, step 0
        np = TO_NP(0, 1); // NP starts at page 1
        a = 0; // undef
        b = 0; // undef
        x = 0; // undef
        y = 0; // undef
        sp = 0; // undef
        flags = 0;

        /* Init RAM to zeros */
        for (var i = 0; i < MEM_BUFFER_SIZE; i++) {
            memory[i] = 0;
        }

        SET_IO_MEMORY(memory, REG_R40_R43_BZ_OUTPUT_PORT, 0xF); // Output port (R40-R43)
        SET_IO_MEMORY(memory, REG_LCD_CTRL, 0x8); // LCD control
        SET_IO_MEMORY(memory, REG_K00_K03_INPUT_RELATION, 0xF); // Active high

        cpu_frequency = OSC1_FREQUENCY;

        sync_ref_timestamp();
    }

    function init(hal as HAL, hw as HW, program as Program, breakpoints as Breakpoints?, freq as U32) as Int {
        g_hal = hal;
        g_hw = hw;
        g_program = program;
        g_breakpoints = breakpoints;
        ts_freq = freq;

        reset();

        return 0;
    }

    function release() as Void {
        g_hal = (null as HAL);
        g_hw = (null as HW);
        g_program = (null as Program);
        g_breakpoints = null;
    }

    function step() as Int {
        var i = 0;

        if (!cpu_halted) {
            var prg_i = pc * 2;
            var op = g_program[prg_i + 1] | ((g_program[prg_i] & 0xF) << 8);

            /* Lookup the OP code */
            var op_found = false;
            for (i = 0; i < OPS.size(); i++) {
                if ((op & OPS[i].mask) == OPS[i].code) {
                    op_found = true;
                    break;
                }
            }

            if (!op_found) {
                g_hal.log(LOG_ERROR, "Unknown op-code 0x%X (pc = 0x%04X)\n", [op, pc]);
                return 1;
            }

            next_pc = (pc + 1) & 0x1FFF;

            /* Display the operation along with the current state of the processor */
            print_state(i, op, pc);

            /* Match the speed of the real processor
            * NOTE: For better accuracy, the final wait should happen here, however
            * the downside is that all interrupts will likely be delayed by one OP
            */
            ref_ts = wait_for_cycles(ref_ts, previous_cycles);

            /* Process the OP code */
            if (OPS[i].cb != null) {
                if (OPS[i].mask_arg0 != 0) {
                    /* Two arguments */
                    OPS[i].cb.invoke((op & OPS[i].mask_arg0) >> OPS[i].shift_arg0, op & ~(OPS[i].mask | OPS[i].mask_arg0));
                } else {
                    /* One arguments */
                    OPS[i].cb.invoke((op & ~OPS[i].mask) >> OPS[i].shift_arg0, 0);
                }
            }

            /* Prepare for the next instruction */
            pc = next_pc;
            previous_cycles = OPS[i].cycles;

            if (i != 0) {
                /* OP code is not PSET, reset NP */
                np = (pc >> 8) & 0x1F;
            }
        } else {
            /* Wait at least once for the duration of a HALT and as long as required
            * (to increment the tick counter), but make sure there will be no wait once
            * the CPU is restarted
            */
            ref_ts = wait_for_cycles(ref_ts, 5);
            previous_cycles = 0;
        }

        handle_timers();

        /* Check if there is any pending interrupt */
        if (I && i != 0 && i != 58) { // Do not process interrupts after a PSET or EI operation
            process_interrupts();
        }

        /* Check if we could pause the execution */
        return check_breakpoint_pause();
    }

    (:release) function check_breakpoint_pause() as Int { return 0; }
    (:debug)   function check_breakpoint_pause() as Int {
        if (g_breakpoints != null) {
            var bp_i = 0;
            while (!cpu_halted && bp_i < g_breakpoints.size()) {
                if ((g_breakpoints as Breakpoints)[bp_i].addr == pc) {
                    return 1;
                }
                bp_i++;
            }
        }

        return 0;
    }
}

}
