// 编码检测测试 - 测试各种编码的检测能力
const std = @import("std");
const EncodingDetector = @import("core/encoding.zig").EncodingDetector;
const Encoding = @import("core/encoding.zig").Encoding;

pub fn main() !void {
    std.debug.print("=== 编码检测测试 ===\n\n", .{});

    // 测试 UTF-8
    testEncoding("UTF-8 (中文)", "你好，世界！", .utf8);
    testEncoding("UTF-8 (日文)", "こんにちは", .utf8);
    testEncoding("UTF-8 (Emoji)", "Hello 🌍 World!", .utf8);

    // 测试 UTF-8 with BOM
    const utf8_bom = [_]u8{ 0xEF, 0xBB, 0xBF, 'H', 'e', 'l', 'l', 'o' };
    testEncodingBytes("UTF-8 with BOM", &utf8_bom, .utf8);

    // 测试 UTF-16 LE with BOM
    const utf16_le = [_]u8{ 0xFF, 0xFE, 'H', 0x00, 'i', 0x00 };
    testEncodingBytes("UTF-16 LE with BOM", &utf16_le, .utf16_le);

    // 测试 UTF-16 BE with BOM
    const utf16_be = [_]u8{ 0xFE, 0xFF, 0x00, 'H', 0x00, 'i' };
    testEncodingBytes("UTF-16 BE with BOM", &utf16_be, .utf16_be);

    // 测试 ASCII
    testEncoding("ASCII", "Hello, World!", .ascii);

    // 测试 GBK (简体中文)
    // "你好" in GBK: 0xC4E3 0xBAC3
    const gbk_text = [_]u8{ 0xC4, 0xE3, 0xBA, 0xC3 };
    testEncodingBytes("GBK (你好)", &gbk_text, .gbk);

    // 测试 Latin-1 (西欧字符)
    // "café" in Latin-1
    const latin1_text = [_]u8{ 'c', 'a', 'f', 0xE9 };
    testEncodingBytes("Latin-1 (café)", &latin1_text, .latin1);

    // 测试混合内容
    const mixed = "Hello, 世界! This is a test.";
    testEncoding("Mixed (ASCII + UTF-8)", mixed, .utf8);

    std.debug.print("\n=== 所有编码检测测试完成 ===\n", .{});
}

fn testEncoding(name: []const u8, text: []const u8, expected: Encoding) void {
    const detected = EncodingDetector.detect(text);
    const status = if (detected == expected) "✓" else "✗";
    std.debug.print("{s} {s}: 检测为 {s} (预期: {s})\n", .{
        status,
        name,
        detected.toString(),
        expected.toString(),
    });
}

fn testEncodingBytes(name: []const u8, bytes: []const u8, expected: Encoding) void {
    const detected = EncodingDetector.detect(bytes);
    const status = if (detected == expected) "✓" else "✗";
    std.debug.print("{s} {s}: 检测为 {s} (预期: {s})\n", .{
        status,
        name,
        detected.toString(),
        expected.toString(),
    });
}
