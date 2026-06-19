const std = @import("std");
const cast = std.math.lossyCast;

const sdl = @import("sdl.zig");

pub fn main(_: std.process.Init) !void {
    try sdl.setAppMetadata("Example Renderer Clear", "1.0", "com.example.renderer-clear");

    try sdl.init(.{ .video = true });
    defer sdl.quit();

    const window, const renderer = try sdl.createWindowAndRenderer(
        "learn-sdl-gpu",
        640,
        480,
        .{ .resizable = true },
    );
    defer window.destroy();
    defer renderer.destroy();

    try renderer.setLogicalPresentation(640, 480, .letterbox);

    var running = true;

    while (running) {
        while (sdl.pollEvent()) |event| {
            if (event.type == .quit) {
                running = false;
            }
        }

        const now: f64 = cast(f64, sdl.getTicks()) / 1000.0;
        const red: f32 = @floatCast(0.5 + 0.5 * sdl.sin(now));
        const green: f32 = @floatCast(0.5 + 0.5 * sdl.sin(now + sdl.pi_d * 2 / 3));
        const blue: f32 = @floatCast(0.5 + 0.5 * sdl.sin(now + sdl.pi_d * 4 / 3));
        try renderer.setDrawColorFloat(red, green, blue, sdl.alpha_opaque_float);

        try renderer.clear();

        try renderer.present();
    }
}

test {
    std.testing.refAllDecls(@This());
}
