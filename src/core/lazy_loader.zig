const std = @import("std");
const TextBuffer = @import("text_buffer.zig").TextBuffer;
const Viewport = @import("viewport.zig").Viewport;

/// 行信息 - 用于懒加载
pub const LineInfo = struct {
    /// 行号（从0开始）
    line_number: usize,
    /// 行在文件中的字节偏移
    byte_offset: usize,
    /// 行的字节长度
    byte_length: usize,

    pub fn init(line_number: usize, byte_offset: usize, byte_length: usize) LineInfo {
        return .{
            .line_number = line_number,
            .byte_offset = byte_offset,
            .byte_length = byte_length,
        };
    }
};

/// 懒加载管理器 - 按需加载文本行
/// 简化版本，使用切片而不是 ArrayList
pub const LazyLoader = struct {
    allocator: std.mem.Allocator,
    /// 行偏移数组
    line_offsets: []usize,
    /// 缓存大小限制
    max_cache_size: usize,

    pub fn init(allocator: std.mem.Allocator) LazyLoader {
        return .{
            .allocator = allocator,
            .line_offsets = &.{},
            .max_cache_size = 1000,
        };
    }

    pub fn deinit(self: *LazyLoader) void {
        if (self.line_offsets.len > 0) {
            self.allocator.free(self.line_offsets);
        }
    }

    /// 构建行索引（扫描整个文件）
    pub fn buildIndex(self: *LazyLoader, text: []const u8) !void {
        // 释放旧的索引
        if (self.line_offsets.len > 0) {
            self.allocator.free(self.line_offsets);
        }

        // 计算行数
        var line_count: usize = 1;
        for (text) |ch| {
            if (ch == '\n') line_count += 1;
        }

        // 分配索引数组
        self.line_offsets = try self.allocator.alloc(usize, line_count);
        self.line_offsets[0] = 0;

        var idx: usize = 1;
        for (text, 0..) |ch, i| {
            if (ch == '\n' and idx < line_count) {
                self.line_offsets[idx] = i + 1;
                idx += 1;
            }
        }
    }

    /// 获取总行数
    pub fn getLineCount(self: *const LazyLoader) usize {
        return self.line_offsets.len;
    }

    /// 获取指定行的信息
    pub fn getLineInfo(self: *const LazyLoader, line: usize, text_len: usize) ?LineInfo {
        if (line >= self.line_offsets.len) return null;

        const start = self.line_offsets[line];
        const end = if (line + 1 < self.line_offsets.len)
            self.line_offsets[line + 1]
        else
            text_len;

        return LineInfo.init(line, start, end - start);
    }

    /// 获取指定行的内容
    pub fn getLine(self: *const LazyLoader, line: usize, full_text: []const u8) ?[]const u8 {
        const info = self.getLineInfo(line, full_text.len) orelse return null;
        if (info.byte_offset + info.byte_length > full_text.len) return null;
        return full_text[info.byte_offset .. info.byte_offset + info.byte_length];
    }

    /// 获取可见行范围的内容
    pub fn getVisibleLines(
        self: *const LazyLoader,
        viewport: *const Viewport,
        full_text: []const u8,
        allocator: std.mem.Allocator,
    ) ![][]const u8 {
        const range = viewport.getVisibleRange();
        const count = range.end - range.start;
        
        const result = try allocator.alloc([]const u8, count);
        var i: usize = 0;
        var line = range.start;
        
        while (line < range.end) : (line += 1) {
            if (self.getLine(line, full_text)) |content| {
                result[i] = content;
                i += 1;
            }
        }

        return result[0..i];
    }
};

test "LazyLoader index building" {
    const allocator = std.testing.allocator;
    var loader = LazyLoader.init(allocator);
    defer loader.deinit();

    const text = "Line 1\nLine 2\nLine 3\n";
    try loader.buildIndex(text);

    try std.testing.expectEqual(@as(usize, 4), loader.getLineCount());

    const info0 = loader.getLineInfo(0, text.len).?;
    try std.testing.expectEqual(@as(usize, 0), info0.byte_offset);
    try std.testing.expectEqual(@as(usize, 7), info0.byte_length);
}

test "LazyLoader line loading" {
    const allocator = std.testing.allocator;
    var loader = LazyLoader.init(allocator);
    defer loader.deinit();

    const text = "Line 1\nLine 2\nLine 3\n";
    try loader.buildIndex(text);

    const line1 = loader.getLine(1, text);
    try std.testing.expect(line1 != null);
    try std.testing.expectEqualStrings("Line 2\n", line1.?);
}
