const std = @import("std");
const cast = std.math.lossyCast;

const c = @import("c");

pub fn main(_: std.process.Init) !void {
    _ = c.SDL_SetAppMetadata("Example Renderer Clear", "1.0", "com.example.renderer-clear");

    if (!c.SDL_Init(c.SDL_INIT_VIDEO)) {
        std.log.err("Couldn't initialize SDL: {s}", .{c.SDL_GetError()});
        return error.SDLAppFailure;
    }
    defer c.SDL_Quit();

    var window: ?*c.SDL_Window = undefined;
    var renderer: ?*c.SDL_Renderer = undefined;
    if (!c.SDL_CreateWindowAndRenderer(
        "learn-sdl-gpu",
        640,
        480,
        c.SDL_WINDOW_RESIZABLE,
        &window,
        &renderer,
    )) {
        std.log.err("Couldn't create window/renderer: {s}", .{c.SDL_GetError()});
        return error.SDLAppFailure;
    }
    defer c.SDL_DestroyWindow(window);
    defer c.SDL_DestroyRenderer(renderer);

    _ = c.SDL_SetRenderLogicalPresentation(
        renderer,
        640,
        480,
        c.SDL_LOGICAL_PRESENTATION_LETTERBOX,
    );

    var event: c.SDL_Event = undefined;

    blk: while (true) {
        while (c.SDL_PollEvent(&event)) {
            if (event.type == c.SDL_EVENT_QUIT) {
                break :blk;
            }
        }

        const now: f64 = cast(f64, c.SDL_GetTicks()) / 1000.0;
        const red: f32 = @floatCast(0.5 + 0.5 * c.SDL_sin(now));
        const green: f32 = @floatCast(0.5 + 0.5 * c.SDL_sin(now + c.SDL_PI_D * 2 / 3));
        const blue: f32 = @floatCast(0.5 + 0.5 * c.SDL_sin(now + c.SDL_PI_D * 4 / 3));
        _ = c.SDL_SetRenderDrawColorFloat(renderer, red, green, blue, c.SDL_ALPHA_OPAQUE_FLOAT);

        _ = c.SDL_RenderClear(renderer);

        _ = c.SDL_RenderPresent(renderer);
    }
}
