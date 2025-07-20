#include "tamalib/utils/cast.h"
#include "tamalib/hw.h"

using Toybox.Application as app;
using Toybox.Graphics as gfx;
using Toybox.WatchUi as ui;
using Toybox.Timer as time;
using Toybox.Lang as std;

using tamalib as tama;

class GarminGotchiView extends ui.View {

    typedef BitmapResources as std.Array<ui.BitmapResource>;

    (:standard_colors) const COLOR_WHITE = gfx.COLOR_WHITE;
    (:inverted_colors) const COLOR_WHITE = gfx.COLOR_BLACK;
    (:standard_colors) const COLOR_BLACK = gfx.COLOR_BLACK;
    (:inverted_colors) const COLOR_BLACK = gfx.COLOR_WHITE;
                       const COLOR_EMPTY = gfx.COLOR_TRANSPARENT;

    (:initialized) var SCREEN as tama.Rect;
    (:initialized) var SUBSCREEN_RECT as tama.Rect;
    (:initialized) var SUBSCREEN_CIRCLE as tama.Circle;
    (:initialized) var MATRIX as tama.Rect;
    (:initialized) var PIXEL_SIZE as tama.Int;
    (:initialized) var ICON_BITMAPS as BitmapResources;

    var game as GarminGotchiApp;

    function initialize(game as GarminGotchiApp) {
        View.initialize();
        me.game = game;
    }

    function onLayout(dc as gfx.Dc) as Void {
        setLayout(Rez.Layouts.Layout(dc));
        compute_layout(dc);
    }

    function onShow() as Void {}

    function onUpdate(dc as gfx.Dc) as Void {
        View.onUpdate(dc);
        draw_screen(dc);
    }

    function onHide() as Void {}

    function compute_layout(dc as gfx.Dc) as Void {
        SCREEN = new tama.Rect(0, 0, dc.getWidth(), dc.getHeight());
        SUBSCREEN_RECT = tama.bbox_to_rect(ui.getSubscreen() as gfx.BoundingBox);
        SUBSCREEN_CIRCLE = tama.bbox_to_circle(ui.getSubscreen() as gfx.BoundingBox);
        PIXEL_SIZE = tama.min(SCREEN.width / LCD_WIDTH, SCREEN.height / LCD_HEIGHT) as tama.Int;
        var MATRIX_WIDTH = tama.min(SCREEN.width, LCD_WIDTH * PIXEL_SIZE) as tama.Int;
        var MATRIX_HEIGHT = tama.min(SCREEN.height, LCD_HEIGHT * PIXEL_SIZE) as tama.Int;
        MATRIX = new tama.Rect(
            (SCREEN.width - MATRIX_WIDTH) / 2,
            (SCREEN.height - MATRIX_HEIGHT) / 2,
            MATRIX_WIDTH,
            MATRIX_HEIGHT
        );
        ICON_BITMAPS = [
            app.loadResource(Rez.Drawables.IconFood),
            app.loadResource(Rez.Drawables.IconLight),
            app.loadResource(Rez.Drawables.IconGame),
            app.loadResource(Rez.Drawables.IconMedicine),
            app.loadResource(Rez.Drawables.IconBathroom),
            app.loadResource(Rez.Drawables.IconMeter),
            app.loadResource(Rez.Drawables.IconDiscipline),
            app.loadResource(Rez.Drawables.IconAttention),
        ] as BitmapResources;
    }

    function draw_timer_callback() as Void {
        game.update_screen();
    }

    function draw_screen(dc as gfx.Dc) as Void {
        clear_screen(dc);
        draw_matrix(dc);
        clear_subscreen(dc);
        draw_icon(dc);
    }

    function clear_screen(dc as gfx.Dc) as Void {
        dc.setColor(COLOR_WHITE, COLOR_EMPTY);
        dc.clear();
    }

    function clear_subscreen(dc as gfx.Dc) as Void {
        draw_circle(dc, SUBSCREEN_CIRCLE, COLOR_BLACK, true);
    }

    function draw_matrix(dc as gfx.Dc) as Void {
        for (var x = 0; x < LCD_WIDTH; x++) {
            for (var y = 0; y < LCD_HEIGHT; y++) {
                if (BOOL(game.matrix[x + y * LCD_WIDTH])) {
                    draw_pixel(dc, x, y);
                }
            }
        }
    }

    function draw_pixel(dc as gfx.Dc, x as tama.Int, y as tama.Int) as Void {
        var pixel = new tama.Rect(
            MATRIX.x + (x * PIXEL_SIZE),
            MATRIX.y + (y * PIXEL_SIZE),
            PIXEL_SIZE,
            PIXEL_SIZE
        );
        draw_rect(dc, pixel, COLOR_BLACK, true);
    }

    function draw_icon(dc as gfx.Dc) as Void {
        dc.setColor(COLOR_WHITE, COLOR_EMPTY);
        for (var i = 0; i < game.icons.size(); i++) {
            if (game.icons[i] != 0) {
                dc.drawBitmap(SUBSCREEN_RECT.x, SUBSCREEN_RECT.y, ICON_BITMAPS[i]);
                break;
            }
        }
    }

    function draw_circle(dc as gfx.Dc, circle as tama.Circle, color as gfx.ColorValue, fill as tama.Bool) as Void {
        dc.setColor(color, COLOR_EMPTY);
        if (fill) {
            dc.fillCircle(circle.x, circle.y, circle.r);
        } else {
            dc.drawCircle(circle.x, circle.y, circle.r);
        }
    }

    function draw_rect(dc as gfx.Dc, rect as tama.Rect, color as gfx.ColorValue, fill as tama.Bool) as Void {
        dc.setColor(color, COLOR_EMPTY);
        if (fill) {
            dc.fillRectangle(rect.x, rect.y, rect.width, rect.height);
        } else {
            dc.drawRectangle(rect.x, rect.y, rect.width, rect.height);
        }
    }

}
