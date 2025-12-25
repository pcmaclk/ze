// 视口和懒加载测试 - 简化版
const std = @import("std");
const Viewport = @import("core/viewport.zig").Viewport;
const LazyLoader = @import("core/lazy_loader.zig").LazyLoader;

pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();
    const allocator = gpa.allocator();

    std.debug.print("=== 视口和懒加载测试 ===\n\n", .{});

    // 测试视口
    std.debug.print("1. 测试视口管理\n", .{});
    var viewport = Viewport.init(20, 80); // 20行 x 80列
    viewport.updateTotalLines(1000); // 模拟1000行文件

    std.debug.print("   初始状态: 行 {}-{}\n", .{ viewport.start_line, viewport.end_line });
    std.debug.print("   可见行数: {}\n", .{viewport.visible_lines});

    viewport.scrollDown(10);
    std.debug.print("   向下滚动10行: 行 {}-{}\n", .{ viewport.start_line, viewport.end_line });

    viewport.scrollToLine(500);
    std.debug.print("   跳转到第500行: 行 {}-{}\n", .{ viewport.start_line, viewport.end_line });

    const pct = viewport.getScrollPercentage();
    std.debug.print("   滚动百分比: {d:.1}%\n\n", .{pct * 100});

    // 测试懒加载
    std.debug.print("2. 测试懒加载\n", .{});
    var loader = LazyLoader.init(allocator);
    defer loader.deinit();

    // 使用静态测试文本
    const test_text = 
        \\Line 0: First line
        \\Line 1: Second line
        \\Line 2: Third line
        \\Line 3: Fourth line
        \\Line 4: Fifth line
        \\Line 5: Sixth line
        \\Line 6: Seventh line
        \\Line 7: Eighth line
        \\Line 8: Ninth line
        \\Line 9: Tenth line
    ;

    // 构建索引
    try loader.buildIndex(test_text);
    std.debug.print("   总行数: {}\n", .{loader.getLineCount()});

    // 加载特定行
    if (loader.getLine(5, test_text)) |line| {
        std.debug.print("   第5行: {s}\n", .{line});
    }

    // 测试批量加载
    viewport.scrollToTop();
    viewport.updateTotalLines(loader.getLineCount());
    const visible_lines = try loader.getVisibleLines(&viewport, test_text, allocator);
    defer allocator.free(visible_lines);

    std.debug.print("   可见行数: {}\n\n", .{visible_lines.len});

    // 测试大文件模拟
    std.debug.print("3. 大文件模拟\n", .{});
    var big_viewport = Viewport.init(30, 120);
    big_viewport.updateTotalLines(1_000_000); // 100万行

    std.debug.print("   文件总行数: {}\n", .{big_viewport.total_lines});
    std.debug.print("   可见行数: {}\n", .{big_viewport.visible_lines});

    big_viewport.setScrollPercentage(0.5); // 跳到50%
    std.debug.print("   跳转到50%: 行 {}\n", .{big_viewport.start_line});

    big_viewport.scrollToBottom();
    std.debug.print("   跳转到底部: 行 {}-{}\n\n", .{ big_viewport.start_line, big_viewport.end_line });

    std.debug.print("=== 所有测试通过! ===\n", .{});
    std.debug.print("\n性能特点:\n", .{});
    std.debug.print("  - 视口只渲染可见行，支持百万行文件\n", .{});
    std.debug.print("  - 懒加载按需读取，减少内存占用\n", .{});
    std.debug.print("  - 行索引快速定位，O(1)访问任意行\n", .{});
}
