const std = @import("std");

pub fn glslc(
    b: *std.Build,
    exe: *std.Build.Step.Compile,
    input: std.Build.LazyPath,
    name: []const u8,
) void {
    const tool_run = b.addSystemCommand(&.{"glslc"});
    tool_run.addFileArg(input);
    tool_run.addArg("-o");
    const path = tool_run.addOutputFileArg(name);
    exe.root_module.addAnonymousImport(name, .{ .root_source_file = path });
}

pub fn build(b: *std.Build) void {
    const target = b.standardTargetOptions(.{});
    const optimize = b.standardOptimizeOption(.{});
    const c = b.addTranslateC(.{
        .root_source_file = b.path("src/c.h"),
        .target = target,
        .optimize = optimize,
    });

    const exe = b.addExecutable(.{
        .name = "learn-sdl-gpu",
        .root_module = b.createModule(.{
            .root_source_file = b.path("src/main.zig"),
            .target = target,
            .optimize = optimize,
            .link_libc = true,
            .imports = &.{
                .{ .name = "c", .module = c.createModule() },
            },
        }),
    });

    glslc(b, exe, b.path("src/shader.glsl.frag"), "shader.spv.frag");
    glslc(b, exe, b.path("src/shader.glsl.vert"), "shader.spv.vert");

    b.installArtifact(exe);
    exe.root_module.linkSystemLibrary("SDL3", .{});
    const run_cmd = b.addRunArtifact(exe);
    run_cmd.step.dependOn(b.getInstallStep());
    if (b.args) |args| {
        run_cmd.addArgs(args);
    }
    const run_step = b.step("run", "Run learn-sdl-gpu");
    run_step.dependOn(&run_cmd.step);
    const exe_unit_tests = b.addTest(.{
        .root_module = exe.root_module,
    });
    const run_exe_unit_tests = b.addRunArtifact(exe_unit_tests);
    const test_step = b.step("test", "Run unit tests");
    test_step.dependOn(&run_exe_unit_tests.step);
}
