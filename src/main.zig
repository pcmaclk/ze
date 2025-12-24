const std = @import("std");
const builtin = @import("builtin");

pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();
    const allocator = gpa.allocator();

    std.debug.print("Ze Editor - 启动中...\n", .{});
    std.debug.print("平台: {s}\n", .{@tagName(builtin.os.tag)});

    // 根据平台分发
    switch (builtin.os.tag) {
        .windows => {
            std.debug.print("Windows 平台暂未实现\n", .{});
            // try @import("windows/window_impl.zig").run(allocator);
        },
        .macos => {
            std.debug.print("macOS 平台暂未实现\n", .{});
            // try @import("macos/window_impl.zig").run(allocator);
        },
        else => @compileError("不支持的操作系统"),
    }
}

test "basic test" {
    try std.testing.expectEqual(1, 1);
}
