const std = @import("std");

pub fn build(b: *std.Build) void {
    const target = b.standardTargetOptions(.{});
    const optimize = b.standardOptimizeOption(.{});

    const exe = b.addExecutable(.{
        .name = "ze",
        .root_module = b.createModule(.{
            .root_source_file = b.path("src/main.zig"),
            .target = target,
            .optimize = optimize,
            .link_libc = true,
        }),
    });

    // 根据目标平台链接系统库
    const target_os = target.result.os.tag;
    if (target_os == .windows) {
        exe.root_module.linkSystemLibrary("user32", .{});
        exe.root_module.linkSystemLibrary("gdi32", .{});
        exe.root_module.linkSystemLibrary("comdlg32", .{});
        exe.root_module.linkSystemLibrary("gdiplus", .{});
        exe.root_module.linkSystemLibrary("shcore", .{});
    } else if (target_os == .macos) {
        exe.root_module.linkFramework("Cocoa", .{});
        exe.root_module.linkFramework("Foundation", .{});
        exe.root_module.linkFramework("CoreGraphics", .{});
    }

    b.installArtifact(exe);

    const run_cmd = b.addRunArtifact(exe);
    run_cmd.step.dependOn(b.getInstallStep());

    if (b.args) |args| {
        run_cmd.addArgs(args);
    }

    const run_step = b.step("run", "Run the editor");
    run_step.dependOn(&run_cmd.step);
}
