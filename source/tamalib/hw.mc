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

module tamalib {

enum ButtonState {
    BTN_STATE_RELEASED = 0,
    BTN_STATE_PRESSED,
}

function ButtonState_toString(state as ButtonState) as String {
    switch (state) {
        case BTN_STATE_PRESSED:  return "PRESSED";
        case BTN_STATE_RELEASED: return "RELEASED";
        default:                 return "UNKNOWN";
    }
}

enum Button {
    BTN_LEFT = 0,
    BTN_MIDDLE,
    BTN_RIGHT,
    BTN_TAP,
}

function Button_toString(button as Button) as String {
    switch (button) {
        case BTN_LEFT:   return "LEFT";
        case BTN_MIDDLE: return "MIDDLE";
        case BTN_RIGHT:  return "RIGHT";
        case BTN_TAP:    return "TAP";
        default:         return "UNKNOWN";
    }
}

typedef HW as interface {
    function init(hal as HAL, cpu as CPU) as Int;
    function release() as Void;
    function set_lcd_pin(seg as U8, com as U8, val as U8) as Void;
    function set_button(btn as Button, state as ButtonState) as Void;
    function set_buzzer_freq(freq as U4) as Void;
    function enable_buzzer(en as Bool) as Void;
};

}
