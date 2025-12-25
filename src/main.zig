const std = @import("std");
const builtin = @import("builtin");
const WindowsWindow = @import("windows/window_impl.zig").WindowsWindow;

pub fn main() !void {
    std.debug.print("Ze Editor - 启动中...\n", .{});
    std.debug.print("平台: {s}\n", .{@tagName(builtin.os.tag)});

    // 根据平台分发
    switch (builtin.os.tag) {
        .windows => {
            std.debug.print("创建 Windows 窗口（支持高 DPI）...\n", .{});

            var window = try WindowsWindow.create();
            std.debug.print("当前 DPI 缩放: {d:.2}x\n", .{window.getDpiScale()});

            window.show();
            try window.run();
        },
        .macos => {
            std.debug.print("macOS 平台暂未实现\n", .{});
        },
        else => @compileError("不支持的操作系统"),
    }
}

test "basic test" {
    try std.testing.expectEqual(1, 1);
}
