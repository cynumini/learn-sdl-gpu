const std = @import("std");
const cast = std.math.lossyCast;

const sdl = @import("sdl.zig");

fn logOutput(userdata: ?*anyopaque, category: c_int, priority: sdl.c.SDL_LogPriority, message: [*c]const u8) callconv(.c) void {
    _ = userdata; // autofix
    const level: std.log.Level, const priority_str = switch (priority) {
        sdl.c.SDL_LOG_PRIORITY_COUNT => .{ .debug, "Count" },
        sdl.c.SDL_LOG_PRIORITY_CRITICAL => .{ .debug, "Critical" },
        sdl.c.SDL_LOG_PRIORITY_INVALID => .{ .debug, "Invalid" },
        sdl.c.SDL_LOG_PRIORITY_TRACE => .{ .debug, "Trace" },
        sdl.c.SDL_LOG_PRIORITY_VERBOSE => .{ .debug, "Verbose" },
        sdl.c.SDL_LOG_PRIORITY_DEBUG => .{ .debug, null },
        sdl.c.SDL_LOG_PRIORITY_ERROR => .{ .err, null },
        sdl.c.SDL_LOG_PRIORITY_INFO => .{ .info, null },
        sdl.c.SDL_LOG_PRIORITY_WARN => .{ .warn, null },
        else => unreachable,
    };
    const category_str = switch (category) {
        sdl.c.SDL_LOG_CATEGORY_APPLICATION => "Application",
        sdl.c.SDL_LOG_CATEGORY_ASSERT => "Assert",
        sdl.c.SDL_LOG_CATEGORY_AUDIO => "Audio",
        sdl.c.SDL_LOG_CATEGORY_ERROR => "Error",
        sdl.c.SDL_LOG_CATEGORY_GPU => "GPU",
        sdl.c.SDL_LOG_CATEGORY_INPUT => "Input",
        sdl.c.SDL_LOG_CATEGORY_RENDER => "Render",
        sdl.c.SDL_LOG_CATEGORY_SYSTEM => "System",
        sdl.c.SDL_LOG_CATEGORY_TEST => "Test",
        sdl.c.SDL_LOG_CATEGORY_VIDEO => "Video",
        else => unreachable,
    };
    if (priority_str) |str| {
        std.log.debug("({s}) ({s}) {s}", .{ str, category_str, message });
        return;
    }
    switch (level) {
        .debug => std.log.debug("({s}) {s}", .{ category_str, message }),
        .err => std.log.err("({s}) {s}", .{ category_str, message }),
        .info => std.log.info("({s}) {s}", .{ category_str, message }),
        .warn => std.log.warn("({s}) {s}", .{ category_str, message }),
    }
}

fn loadShader(
    device: *sdl.c.SDL_GPUDevice,
    code: [:0]const u8,
    stage: sdl.c.SDL_GPUShaderStage,
) *sdl.c.SDL_GPUShader {
    return sdl.c.SDL_CreateGPUShader(device, &.{
        .code_size = code.len,
        .code = code,
        .entrypoint = "main",
        .format = sdl.c.SDL_GPU_SHADERFORMAT_SPIRV,
        .stage = stage,
    }).?;
}

pub fn main(_: std.process.Init) !void {
    try sdl.init(.{ .video = true });

    sdl.c.SDL_SetLogPriorities(sdl.c.SDL_LOG_PRIORITY_VERBOSE);
    sdl.c.SDL_SetLogOutputFunction(logOutput, null);

    const window = sdl.c.SDL_CreateWindow("Hello SDL3", 1280, 720, 0).?;

    const gpu = sdl.c.SDL_CreateGPUDevice(
        sdl.c.SDL_GPU_SHADERFORMAT_SPIRV,
        true,
        null,
    ).?;

    std.debug.assert(sdl.c.SDL_ClaimWindowForGPUDevice(gpu, window));

    const vert_shader = loadShader(
        gpu,
        @embedFile("shader.spv.vert"),
        sdl.c.SDL_GPU_SHADERSTAGE_VERTEX,
    );
    const frag_shader = loadShader(
        gpu,
        @embedFile("shader.spv.frag"),
        sdl.c.SDL_GPU_SHADERSTAGE_FRAGMENT,
    );

    const pipeline = sdl.c.SDL_CreateGPUGraphicsPipeline(gpu, &.{
        .vertex_shader = vert_shader,
        .fragment_shader = frag_shader,
        .primitive_type = sdl.c.SDL_GPU_PRIMITIVETYPE_TRIANGLELIST,
        .target_info = .{
            .num_color_targets = 1,
            .color_target_descriptions = &.{
                .format = sdl.c.SDL_GetGPUSwapchainTextureFormat(gpu, window),
            },
        },
    });

    sdl.c.SDL_ReleaseGPUShader(gpu, vert_shader);
    sdl.c.SDL_ReleaseGPUShader(gpu, frag_shader);

    main_loop: while (true) {
        // process event
        var ev: sdl.c.SDL_Event = undefined;
        while (sdl.c.SDL_PollEvent(&ev)) {
            switch (ev.type) {
                sdl.c.SDL_EVENT_QUIT => break :main_loop,
                sdl.c.SDL_EVENT_KEY_DOWN => {
                    if (ev.key.scancode == sdl.c.SDL_SCANCODE_ESCAPE) break :main_loop;
                },
                else => {},
            }
        }

        // update game state

        // render
        const cmd_buf = sdl.c.SDL_AcquireGPUCommandBuffer(gpu).?;
        var swapchain_tex: ?*sdl.c.SDL_GPUTexture = null;
        std.debug.assert(sdl.c.SDL_WaitAndAcquireGPUSwapchainTexture(
            cmd_buf,
            window,
            &swapchain_tex,
            null,
            null,
        ));

        if (swapchain_tex != null) {
            var color_target = sdl.c.SDL_GPUColorTargetInfo{
                .texture = swapchain_tex,
                .load_op = sdl.c.SDL_GPU_LOADOP_CLEAR,
                .clear_color = .{ .r = 0, .g = 0.2, .b = 0.4, .a = 1 },
                .store_op = sdl.c.SDL_GPU_STOREOP_STORE,
            };
            const render_pass = sdl.c.SDL_BeginGPURenderPass(
                cmd_buf,
                &color_target,
                1,
                null,
            ).?;
            // draw stuff
            sdl.c.SDL_BindGPUGraphicsPipeline(render_pass, pipeline);
            sdl.c.SDL_DrawGPUPrimitives(render_pass, 3, 1, 0, 0);
            sdl.c.SDL_EndGPURenderPass(render_pass);
        }

        std.debug.assert(sdl.c.SDL_SubmitGPUCommandBuffer(cmd_buf));
    }
}

test {
    std.testing.refAllDecls(@This());
}
