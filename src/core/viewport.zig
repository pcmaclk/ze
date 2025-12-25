const std = @import("std");
const TextBuffer = @import("text_buffer.zig").TextBuffer;

/// 视口 - 管理可见文本区域和虚拟滚动
/// 用于高效渲染大文件，只处理可见行
pub const Viewport = struct {
    /// 视口起始行（从0开始）
    start_line: usize,
    /// 视口结束行（不包含）
    end_line: usize,
    /// 视口高度（可见行数）
    visible_lines: usize,
    /// 水平滚动偏移（字符数）
    horizontal_offset: usize,
    /// 视口宽度（可见字符数）
    visible_columns: usize,
    /// 总行数（来自 TextBuffer）
    total_lines: usize,

    pub fn init(visible_lines: usize, visible_columns: usize) Viewport {
        return .{
            .start_line = 0,
            .end_line = visible_lines,
            .visible_lines = visible_lines,
            .horizontal_offset = 0,
            .visible_columns = visible_columns,
            .total_lines = 0,
        };
    }

    /// 更新总行数
    pub fn updateTotalLines(self: *Viewport, total: usize) void {
        self.total_lines = total;
        // 确保视口不超出范围
        if (self.start_line >= total) {
            self.start_line = if (total > self.visible_lines) total - self.visible_lines else 0;
        }
        self.end_line = @min(self.start_line + self.visible_lines, total);
    }

    /// 更新视口大小（窗口调整时调用）
    pub fn resize(self: *Viewport, new_visible_lines: usize, new_visible_columns: usize) void {
        self.visible_lines = new_visible_lines;
        self.visible_columns = new_visible_columns;
        self.end_line = @min(self.start_line + self.visible_lines, self.total_lines);
    }

    /// 向下滚动指定行数
    pub fn scrollDown(self: *Viewport, lines: usize) void {
        const max_start = if (self.total_lines > self.visible_lines)
            self.total_lines - self.visible_lines
        else
            0;

        self.start_line = @min(self.start_line + lines, max_start);
        self.end_line = @min(self.start_line + self.visible_lines, self.total_lines);
    }

    /// 向上滚动指定行数
    pub fn scrollUp(self: *Viewport, lines: usize) void {
        if (self.start_line >= lines) {
            self.start_line -= lines;
        } else {
            self.start_line = 0;
        }
        self.end_line = @min(self.start_line + self.visible_lines, self.total_lines);
    }

    /// 滚动到指定行（使该行可见）
    pub fn scrollToLine(self: *Viewport, line: usize) void {
        if (line < self.start_line) {
            // 目标行在视口上方，滚动到该行
            self.start_line = line;
        } else if (line >= self.end_line) {
            // 目标行在视口下方，滚动使其可见
            self.start_line = if (line >= self.visible_lines)
                line - self.visible_lines + 1
            else
                0;
        }
        self.end_line = @min(self.start_line + self.visible_lines, self.total_lines);
    }

    /// 跳转到文件开头
    pub fn scrollToTop(self: *Viewport) void {
        self.start_line = 0;
        self.end_line = @min(self.visible_lines, self.total_lines);
    }

    /// 跳转到文件末尾
    pub fn scrollToBottom(self: *Viewport) void {
        if (self.total_lines > self.visible_lines) {
            self.start_line = self.total_lines - self.visible_lines;
        } else {
            self.start_line = 0;
        }
        self.end_line = self.total_lines;
    }

    /// 向右滚动
    pub fn scrollRight(self: *Viewport, columns: usize) void {
        self.horizontal_offset += columns;
    }

    /// 向左滚动
    pub fn scrollLeft(self: *Viewport, columns: usize) void {
        if (self.horizontal_offset >= columns) {
            self.horizontal_offset -= columns;
        } else {
            self.horizontal_offset = 0;
        }
    }

    /// 检查某行是否在视口内
    pub fn isLineVisible(self: *const Viewport, line: usize) bool {
        return line >= self.start_line and line < self.end_line;
    }

    /// 获取可见行范围
    pub fn getVisibleRange(self: *const Viewport) struct { start: usize, end: usize } {
        return .{ .start = self.start_line, .end = self.end_line };
    }

    /// 获取滚动百分比 (0.0 - 1.0)
    pub fn getScrollPercentage(self: *const Viewport) f32 {
        if (self.total_lines <= self.visible_lines) return 0.0;
        const scrollable = self.total_lines - self.visible_lines;
        return @as(f32, @floatFromInt(self.start_line)) / @as(f32, @floatFromInt(scrollable));
    }

    /// 通过百分比设置滚动位置
    pub fn setScrollPercentage(self: *Viewport, percentage: f32) void {
        const clamped = @max(0.0, @min(1.0, percentage));
        if (self.total_lines <= self.visible_lines) {
            self.start_line = 0;
        } else {
            const scrollable = self.total_lines - self.visible_lines;
            self.start_line = @intFromFloat(clamped * @as(f32, @floatFromInt(scrollable)));
        }
        self.end_line = @min(self.start_line + self.visible_lines, self.total_lines);
    }
};

test "Viewport basic operations" {
    var viewport = Viewport.init(10, 80);
    viewport.updateTotalLines(100);

    try std.testing.expectEqual(@as(usize, 0), viewport.start_line);
    try std.testing.expectEqual(@as(usize, 10), viewport.end_line);

    // 测试向下滚动
    viewport.scrollDown(5);
    try std.testing.expectEqual(@as(usize, 5), viewport.start_line);
    try std.testing.expectEqual(@as(usize, 15), viewport.end_line);

    // 测试向上滚动
    viewport.scrollUp(3);
    try std.testing.expectEqual(@as(usize, 2), viewport.start_line);
    try std.testing.expectEqual(@as(usize, 12), viewport.end_line);
}

test "Viewport scroll to line" {
    var viewport = Viewport.init(10, 80);
    viewport.updateTotalLines(100);

    // 滚动到第50行
    viewport.scrollToLine(50);
    try std.testing.expect(viewport.isLineVisible(50));

    // 滚动到顶部
    viewport.scrollToTop();
    try std.testing.expectEqual(@as(usize, 0), viewport.start_line);

    // 滚动到底部
    viewport.scrollToBottom();
    try std.testing.expectEqual(@as(usize, 90), viewport.start_line);
}

test "Viewport percentage" {
    var viewport = Viewport.init(10, 80);
    viewport.updateTotalLines(100);

    // 滚动到50%
    viewport.setScrollPercentage(0.5);
    try std.testing.expectEqual(@as(usize, 45), viewport.start_line);

    const pct = viewport.getScrollPercentage();
    try std.testing.expect(pct >= 0.49 and pct <= 0.51);
}
