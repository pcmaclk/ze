const std = @import("std");

pub fn build(b: *std.Build) void {
    const target = b.standardTargetOptions(.{});
    const optimize = b.standardOptimizeOption(.{});

    // 创建可执行文件
    const exe = b.addExecutable(.{
        .name = "ze",
        .root_source_file = b.path("src/main.zig"),
        .target = target,
        .optimize = optimize,
    });

    // 根据目标平台链接系统库
    switch (target.result.os.tag) {
        .windows => {
            exe.linkSystemLibrary("user32");
            exe.linkSystemLibrary("gdi32");
            exe.linkSystemLibrary("comdlg32");
            exe.linkSystemLibrary("gdiplus");
        },
        .macos => {
            exe.linkFramework("Cocoa");
            exe.linkFramework("Foundation");
            exe.linkFramework("CoreGraphics");
        },
        else => @compileError("不支持的平台"),
    }

    b.installArtifact(exe);

    // 运行命令
    const run_cmd = b.addRunArtifact(exe);
    run_cmd.step.dependOn(b.getInstallStep());
    
    if (b.args) |args| {
        run_cmd.addArgs(args);
    }

    const run_step = b.step("run", "Run the editor");
    run_step.dependOn(&run_cmd.step);

    // 测试
    const tests = b.addTest(.{
        .root_source_file = b.path("src/core/rope.zig"),
        .target = target,
        .optimize = optimize,
    });

    const run_tests = b.addRunArtifact(tests);
    const test_step = b.step("test", "Run unit tests");
    test_step.dependOn(&run_tests.step);
}
