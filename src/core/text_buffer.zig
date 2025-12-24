const std = @import("std");
const Rope = @import("rope.zig").Rope;
const Encoding = @import("encoding.zig").Encoding;
const EncodingDetector = @import("encoding.zig").EncodingDetector;

/// 文本缓冲区 - 基于 Rope 的文本管理
pub const TextBuffer = struct {
    rope: Rope,
    encoding: Encoding,
    modified: bool,
    line_count: usize,
    allocator: std.mem.Allocator,

    pub fn init(allocator: std.mem.Allocator) TextBuffer {
        return .{
            .rope = Rope.init(allocator),
            .encoding = .utf8,
            .modified = false,
            .line_count = 1,
            .allocator = allocator,
        };
    }

    pub fn deinit(self: *TextBuffer) void {
        self.rope.deinit();
    }

    /// 从文件加载
    pub fn loadFromFile(allocator: std.mem.Allocator, path: []const u8) !TextBuffer {
        const file = try std.fs.cwd().openFile(path, .{});
        defer file.close();

        const content = try file.readToEndAlloc(allocator, 100 * 1024 * 1024); // 最大 100MB
        defer allocator.free(content);

        return try TextBuffer.fromBytes(allocator, content);
    }

    /// 从字节数组创建
    pub fn fromBytes(allocator: std.mem.Allocator, data: []const u8) !TextBuffer {
        // 检测编码
        const encoding = EncodingDetector.detect(data);

        // 创建 Rope
        const rope = try Rope.fromString(allocator, data);

        // 计算行数
        const line_count = countLines(data);

        return .{
            .rope = rope,
            .encoding = encoding,
            .modified = false,
            .line_count = line_count,
            .allocator = allocator,
        };
    }

    /// 从字符串创建
    pub fn fromString(allocator: std.mem.Allocator, text: []const u8) !TextBuffer {
        return try TextBuffer.fromBytes(allocator, text);
    }

    /// 获取文本长度
    pub fn length(self: *const TextBuffer) usize {
        return self.rope.length();
    }

    /// 获取行数
    pub fn lineCount(self: *const TextBuffer) usize {
        return self.line_count;
    }

    /// 获取指定位置的字符
    pub fn charAt(self: *const TextBuffer, pos: usize) ?u8 {
        return self.rope.charAt(pos);
    }

    /// 在指定位置插入文本
    pub fn insert(self: *TextBuffer, pos: usize, text: []const u8) !void {
        try self.rope.insert(pos, text);
        self.modified = true;
        self.line_count += countLines(text);
    }

    /// 删除指定范围的文本
    pub fn delete(self: *TextBuffer, start: usize, end: usize) !void {
        try self.rope.delete(start, end);
        self.modified = true;
        // TODO: 更新行数
    }

    /// 转换为字符串
    pub fn toString(self: *const TextBuffer) ![]u8 {
        return try self.rope.toString(self.allocator);
    }

    /// 保存到文件
    pub fn saveToFile(self: *const TextBuffer, path: []const u8) !void {
        const content = try self.toString();
        defer self.allocator.free(content);

        const file = try std.fs.cwd().createFile(path, .{});
        defer file.close();

        try file.writeAll(content);
    }

    /// 是否已修改
    pub fn isModified(self: *const TextBuffer) bool {
        return self.modified;
    }

    /// 标记为未修改
    pub fn clearModified(self: *TextBuffer) void {
        self.modified = false;
    }
};

/// 计算文本中的行数
fn countLines(text: []const u8) usize {
    var count: usize = 1;
    for (text) |ch| {
        if (ch == '\n') count += 1;
    }
    return count;
}

test "TextBuffer basic operations" {
    const allocator = std.testing.allocator;

    var buffer = try TextBuffer.fromString(allocator, "Hello\nWorld\n!");
    defer buffer.deinit();

    try std.testing.expectEqual(@as(usize, 13), buffer.length());
    try std.testing.expectEqual(@as(usize, 3), buffer.lineCount());
    try std.testing.expectEqual(Encoding.ascii, buffer.encoding);

    // 测试字符访问
    try std.testing.expectEqual(@as(u8, 'H'), buffer.charAt(0).?);
    try std.testing.expectEqual(@as(u8, '\n'), buffer.charAt(5).?);
}

test "TextBuffer insert" {
    const allocator = std.testing.allocator;

    var buffer = try TextBuffer.fromString(allocator, "Hello");
    defer buffer.deinit();

    try buffer.insert(5, ", World!");
    try std.testing.expect(buffer.isModified());
    try std.testing.expectEqual(@as(usize, 13), buffer.length());
}

test "TextBuffer encoding detection" {
    const allocator = std.testing.allocator;

    // UTF-8 文本
    var buffer = try TextBuffer.fromString(allocator, "Hello, 世界!");
    defer buffer.deinit();
    try std.testing.expectEqual(Encoding.utf8, buffer.encoding);

    // ASCII 文本
    var buffer2 = try TextBuffer.fromString(allocator, "Hello, World!");
    defer buffer2.deinit();
    try std.testing.expectEqual(Encoding.ascii, buffer2.encoding);
}
