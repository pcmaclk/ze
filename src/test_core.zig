// 简单测试文件 - 直接运行测试核心模块
const std = @import("std");
const Rope = @import("core/rope.zig").Rope;
const EncodingDetector = @import("core/encoding.zig").EncodingDetector;
const Encoding = @import("core/encoding.zig").Encoding;
const TextBuffer = @import("core/text_buffer.zig").TextBuffer;

pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();
    const allocator = gpa.allocator();

    std.debug.print("=== Ze Editor - 核心模块测试 ===\n\n", .{});

    // 测试 Rope
    std.debug.print("1. 测试 Rope 数据结构\n", .{});
    var rope = try Rope.fromString(allocator, "Hello, World!");
    defer rope.deinit();
    
    std.debug.print("   长度: {}\n", .{rope.length()});
    std.debug.print("   第一个字符: {c}\n", .{rope.charAt(0).?});
    std.debug.print("   最后一个字符: {c}\n", .{rope.charAt(12).?});
    
    const rope_str = try rope.toString(allocator);
    defer allocator.free(rope_str);
    std.debug.print("   内容: {s}\n\n", .{rope_str});

    // 测试编码检测
    std.debug.print("2. 测试编码检测\n", .{});
    const utf8_text = "Hello, 世界! 🌍";
    const encoding = EncodingDetector.detect(utf8_text);
    std.debug.print("   检测到编码: {s}\n\n", .{encoding.toString()});

    // 测试 TextBuffer
    std.debug.print("3. 测试 TextBuffer\n", .{});
    var buffer = try TextBuffer.fromString(allocator, "Line 1\nLine 2\nLine 3");
    defer buffer.deinit();
    
    std.debug.print("   文本长度: {}\n", .{buffer.length()});
    std.debug.print("   行数: {}\n", .{buffer.lineCount()});
    std.debug.print("   编码: {s}\n", .{buffer.encoding.toString()});
    std.debug.print("   已修改: {}\n\n", .{buffer.isModified()});

    // 测试插入
    std.debug.print("4. 测试文本插入\n", .{});
    try buffer.insert(buffer.length(), "\nLine 4");
    std.debug.print("   插入后长度: {}\n", .{buffer.length()});
    std.debug.print("   插入后行数: {}\n", .{buffer.lineCount()});
    std.debug.print("   已修改: {}\n\n", .{buffer.isModified()});

    std.debug.print("=== 所有测试通过! ===\n", .{});
}
