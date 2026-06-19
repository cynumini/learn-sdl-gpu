const std = @import("std");

pub const c = @import("c");

pub const alpha_opaque_float = c.SDL_ALPHA_OPAQUE_FLOAT;
pub const pi_d = c.SDL_PI_D;

const WindowFlags = packed struct(c.SDL_WindowFlags) {
    _pad0: u5 = 0,
    resizable: bool = true,
    _pad1: u58 = 0,

    fn toInt(self: WindowFlags) c.SDL_WindowFlags {
        return @bitCast(self);
    }
};

test WindowFlags {
    try std.testing.expectEqual(
        (WindowFlags{ .resizable = true }).toInt(),
        c.SDL_WINDOW_RESIZABLE,
    );
}

const InitFlags = packed struct(c.SDL_InitFlags) {
    _pad0: u5 = 0,
    video: bool = true,
    _pad1: u26 = 0,

    fn toInt(self: InitFlags) c.SDL_InitFlags {
        return @bitCast(self);
    }
};

test InitFlags {
    try std.testing.expectEqual(
        (InitFlags{ .video = true }).toInt(),
        c.SDL_INIT_VIDEO,
    );
}

const RendererLogicalPresentation = enum(c.SDL_RendererLogicalPresentation) {
    letterbox = c.SDL_LOGICAL_PRESENTATION_LETTERBOX,
};

const Window = opaque {
    pub fn destroy(self: *Window) void {
        c.SDL_DestroyWindow(@ptrCast(self));
    }
};

const Renderer = opaque {
    pub fn destroy(self: *Renderer) void {
        c.SDL_DestroyRenderer(@ptrCast(self));
    }

    pub fn setLogicalPresentation(
        self: *Renderer,
        w: i32,
        h: i32,
        mode: RendererLogicalPresentation,
    ) !void {
        try checkError(c.SDL_SetRenderLogicalPresentation(
            @ptrCast(self),
            w,
            h,
            @intFromEnum(mode),
        ));
    }

    pub fn clear(self: *Renderer) !void {
        try checkError(c.SDL_RenderClear(@ptrCast(self)));
    }

    pub fn present(self: *Renderer) !void {
        try checkError(c.SDL_RenderPresent(@ptrCast(self)));
    }

    pub fn setDrawColorFloat(self: *Renderer, r: f32, g: f32, b: f32, a: f32) !void {
        try checkError(c.SDL_SetRenderDrawColorFloat(@ptrCast(self), r, g, b, a));
    }
};

pub const Event = extern union {
    type: enum(u32) {
        quit = c.SDL_EVENT_QUIT,
    },
    common: c.SDL_CommonEvent,
    display: c.SDL_DisplayEvent,
    window: c.SDL_WindowEvent,
    kdevice: c.SDL_KeyboardDeviceEvent,
    key: c.SDL_KeyboardEvent,
    edit: c.SDL_TextEditingEvent,
    edit_candidates: c.SDL_TextEditingCandidatesEvent,
    text: c.SDL_TextInputEvent,
    mdevice: c.SDL_MouseDeviceEvent,
    motion: c.SDL_MouseMotionEvent,
    button: c.SDL_MouseButtonEvent,
    wheel: c.SDL_MouseWheelEvent,
    jdevice: c.SDL_JoyDeviceEvent,
    jaxis: c.SDL_JoyAxisEvent,
    jball: c.SDL_JoyBallEvent,
    jhat: c.SDL_JoyHatEvent,
    jbutton: c.SDL_JoyButtonEvent,
    jbattery: c.SDL_JoyBatteryEvent,
    gdevice: c.SDL_GamepadDeviceEvent,
    gaxis: c.SDL_GamepadAxisEvent,
    gbutton: c.SDL_GamepadButtonEvent,
    gtouchpad: c.SDL_GamepadTouchpadEvent,
    gsensor: c.SDL_GamepadSensorEvent,
    adevice: c.SDL_AudioDeviceEvent,
    cdevice: c.SDL_CameraDeviceEvent,
    sensor: c.SDL_SensorEvent,
    quit: c.SDL_QuitEvent,
    user: c.SDL_UserEvent,
    tfinger: c.SDL_TouchFingerEvent,
    pinch: c.SDL_PinchFingerEvent,
    pproximity: c.SDL_PenProximityEvent,
    ptouch: c.SDL_PenTouchEvent,
    pmotion: c.SDL_PenMotionEvent,
    pbutton: c.SDL_PenButtonEvent,
    paxis: c.SDL_PenAxisEvent,
    render: c.SDL_RenderEvent,
    drop: c.SDL_DropEvent,
    clipboard: c.SDL_ClipboardEvent,
    padding: [128]u8,
};

fn checkError(result: bool) !void {
    if (!result) {
        std.log.err("Couldn't initialize SDL: {s}", .{c.SDL_GetError()});
        return error.SDLError;
    }
}

pub fn createWindowAndRenderer(
    title: [*c]const u8,
    width: c_int,
    height: c_int,
    window_flags: WindowFlags,
) !struct { *Window, *Renderer } {
    var window: *Window = undefined;
    var renderer: *Renderer = undefined;
    try checkError(c.SDL_CreateWindowAndRenderer(
        title,
        width,
        height,
        window_flags.toInt(),
        @ptrCast(&window),
        @ptrCast(&renderer),
    ));
    return .{ window, renderer };
}

pub fn init(flags: InitFlags) !void {
    try checkError(c.SDL_Init(flags.toInt()));
}

pub fn pollEvent() ?Event {
    var event: Event = undefined;
    if (c.SDL_PollEvent(@ptrCast(&event))) {
        return event;
    }
    return null;
}

pub fn setAppMetadata(
    appname: [*:0]const u8,
    appversion: [*:0]const u8,
    appidentifier: [*:0]const u8,
) !void {
    try checkError(c.SDL_SetAppMetadata(appname, appversion, appidentifier));
}

pub const getTicks = c.SDL_GetTicks;
pub const quit = c.SDL_Quit;
pub const sin = c.SDL_sin;
