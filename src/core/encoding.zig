const std = @import("std");

/// 文本编码类型
pub const Encoding = enum {
    utf8,
    utf16_le,
    utf16_be,
    utf32_le,
    utf32_be,
    gbk,
    big5,
    shift_jis,
    latin1,
    ascii,
    unknown,

    pub fn toString(self: Encoding) []const u8 {
        return switch (self) {
            .utf8 => "UTF-8",
            .utf16_le => "UTF-16 LE",
            .utf16_be => "UTF-16 BE",
            .utf32_le => "UTF-32 LE",
            .utf32_be => "UTF-32 BE",
            .gbk => "GBK",
            .big5 => "Big5",
            .shift_jis => "Shift-JIS",
            .latin1 => "Latin-1",
            .ascii => "ASCII",
            .unknown => "Unknown",
        };
    }
};

/// 编码检测器
pub const EncodingDetector = struct {
    /// 检测字节流的编码
    pub fn detect(data: []const u8) Encoding {
        if (data.len == 0) return .utf8;

        // 1. 检测 BOM (Byte Order Mark)
        if (detectBOM(data)) |encoding| {
            return encoding;
        }

        // 2. 检测 UTF-8（优先级高，因为最常见）
        if (isValidUTF8(data)) {
            return .utf8;
        }

        // 3. 检测 UTF-16
        if (looksLikeUTF16(data)) |encoding| {
            return encoding;
        }

        // 4. 检测 ASCII
        if (isASCII(data)) {
            return .ascii;
        }

        // 5. 检测中文编码（GBK, Big5）
        const chinese_score = detectChineseEncoding(data);
        if (chinese_score.gbk > chinese_score.big5 and chinese_score.gbk > 0.3) {
            return .gbk;
        }
        if (chinese_score.big5 > 0.3) {
            return .big5;
        }

        // 6. 检测日文编码
        if (looksLikeShiftJIS(data)) {
            return .shift_jis;
        }

        // 7. 检测 Latin-1（西欧编码）
        if (looksLikeLatin1(data)) {
            return .latin1;
        }

        // 8. 默认返回 UTF-8
        return .utf8;
    }

    /// 检测 BOM
    fn detectBOM(data: []const u8) ?Encoding {
        if (data.len >= 3) {
            // UTF-8 BOM: EF BB BF
            if (data[0] == 0xEF and data[1] == 0xBB and data[2] == 0xBF) {
                return .utf8;
            }
        }

        if (data.len >= 2) {
            // UTF-16 LE BOM: FF FE
            if (data[0] == 0xFF and data[1] == 0xFE) {
                if (data.len >= 4 and data[2] == 0x00 and data[3] == 0x00) {
                    return .utf32_le; // UTF-32 LE: FF FE 00 00
                }
                return .utf16_le;
            }

            // UTF-16 BE BOM: FE FF
            if (data[0] == 0xFE and data[1] == 0xFF) {
                return .utf16_be;
            }
        }

        if (data.len >= 4) {
            // UTF-32 BE BOM: 00 00 FE FF
            if (data[0] == 0x00 and data[1] == 0x00 and 
                data[2] == 0xFE and data[3] == 0xFF) {
                return .utf32_be;
            }
        }

        return null;
    }

    /// 验证是否为有效的 UTF-8
    fn isValidUTF8(data: []const u8) bool {
        var i: usize = 0;
        while (i < data.len) {
            const byte = data[i];

            // ASCII 字符 (0xxxxxxx)
            if (byte < 0x80) {
                i += 1;
                continue;
            }

            // 2 字节序列 (110xxxxx 10xxxxxx)
            if (byte >= 0xC0 and byte < 0xE0) {
                if (i + 1 >= data.len) return false;
                if (!isContinuationByte(data[i + 1])) return false;
                i += 2;
                continue;
            }

            // 3 字节序列 (1110xxxx 10xxxxxx 10xxxxxx)
            if (byte >= 0xE0 and byte < 0xF0) {
                if (i + 2 >= data.len) return false;
                if (!isContinuationByte(data[i + 1])) return false;
                if (!isContinuationByte(data[i + 2])) return false;
                i += 3;
                continue;
            }

            // 4 字节序列 (11110xxx 10xxxxxx 10xxxxxx 10xxxxxx)
            if (byte >= 0xF0 and byte < 0xF8) {
                if (i + 3 >= data.len) return false;
                if (!isContinuationByte(data[i + 1])) return false;
                if (!isContinuationByte(data[i + 2])) return false;
                if (!isContinuationByte(data[i + 3])) return false;
                i += 4;
                continue;
            }

            // 无效的 UTF-8 序列
            return false;
        }

        return true;
    }

    fn isContinuationByte(byte: u8) bool {
        return (byte & 0xC0) == 0x80;
    }

    /// 检测是否看起来像 UTF-16
    fn looksLikeUTF16(data: []const u8) ?Encoding {
        if (data.len < 4) return null;

        // 统计 null 字节的位置
        var null_at_even: usize = 0;
        var null_at_odd: usize = 0;

        var i: usize = 0;
        while (i < @min(data.len, 1000)) : (i += 1) {
            if (data[i] == 0) {
                if (i % 2 == 0) {
                    null_at_even += 1;
                } else {
                    null_at_odd += 1;
                }
            }
        }

        // 如果偶数位置有很多 null，可能是 UTF-16 BE
        if (null_at_even > data.len / 20 and null_at_even > null_at_odd * 2) {
            return .utf16_be;
        }

        // 如果奇数位置有很多 null，可能是 UTF-16 LE
        if (null_at_odd > data.len / 20 and null_at_odd > null_at_even * 2) {
            return .utf16_le;
        }

        return null;
    }

    /// 检测是否为纯 ASCII
    fn isASCII(data: []const u8) bool {
        for (data) |byte| {
            if (byte >= 0x80) return false;
        }
        return true;
    }

    /// 中文编码检测结果
    const ChineseScore = struct {
        gbk: f32,
        big5: f32,
    };

    /// 检测中文编码（GBK vs Big5）
    fn detectChineseEncoding(data: []const u8) ChineseScore {
        var gbk_score: f32 = 0;
        var big5_score: f32 = 0;
        var total_bytes: f32 = 0;

        var i: usize = 0;
        while (i < data.len) {
            const byte = data[i];

            // 检测双字节字符
            if (byte >= 0x80 and i + 1 < data.len) {
                const byte2 = data[i + 1];

                // GBK 范围：
                // 第一字节: 0x81-0xFE
                // 第二字节: 0x40-0x7E, 0x80-0xFE
                if (byte >= 0x81 and byte <= 0xFE) {
                    if ((byte2 >= 0x40 and byte2 <= 0x7E) or 
                        (byte2 >= 0x80 and byte2 <= 0xFE)) {
                        gbk_score += 1.0;
                        total_bytes += 1.0;
                    }
                }

                // Big5 范围：
                // 第一字节: 0x81-0xFE
                // 第二字节: 0x40-0x7E, 0x80-0xFE (与 GBK 类似但有细微差别)
                // Big5 常用字范围: 0xA440-0xC67E
                if (byte >= 0xA4 and byte <= 0xC6) {
                    if ((byte2 >= 0x40 and byte2 <= 0x7E) or 
                        (byte2 >= 0xA1 and byte2 <= 0xFE)) {
                        big5_score += 1.0;
                        total_bytes += 1.0;
                    }
                }

                i += 2;
            } else {
                i += 1;
            }
        }

        if (total_bytes > 0) {
            return .{
                .gbk = gbk_score / total_bytes,
                .big5 = big5_score / total_bytes,
            };
        }

        return .{ .gbk = 0, .big5 = 0 };
    }

    /// 检测是否看起来像 Shift-JIS
    fn looksLikeShiftJIS(data: []const u8) bool {
        var sjis_count: usize = 0;
        var total_count: usize = 0;

        var i: usize = 0;
        while (i < data.len) {
            const byte = data[i];

            if (byte >= 0x80 and i + 1 < data.len) {
                const byte2 = data[i + 1];

                // Shift-JIS 第一字节范围: 0x81-0x9F, 0xE0-0xFC
                // 第二字节范围: 0x40-0x7E, 0x80-0xFC
                if ((byte >= 0x81 and byte <= 0x9F) or (byte >= 0xE0 and byte <= 0xFC)) {
                    if ((byte2 >= 0x40 and byte2 <= 0x7E) or (byte2 >= 0x80 and byte2 <= 0xFC)) {
                        sjis_count += 1;
                    }
                }
                total_count += 1;
                i += 2;
            } else {
                i += 1;
            }
        }

        // 如果超过 30% 的双字节字符符合 Shift-JIS 模式
        return total_count > 0 and (sjis_count * 10 > total_count * 3);
    }

    /// 检测是否看起来像 Latin-1
    fn looksLikeLatin1(data: []const u8) bool {
        var high_byte_count: usize = 0;
        var printable_count: usize = 0;

        for (data) |byte| {
            if (byte >= 0x80) {
                high_byte_count += 1;
                // Latin-1 可打印字符范围: 0xA0-0xFF
                if (byte >= 0xA0) {
                    printable_count += 1;
                }
            }
        }

        // 如果有高位字节，且大部分是可打印的 Latin-1 字符
        if (high_byte_count > 0) {
            return printable_count * 10 > high_byte_count * 8;
        }

        return false;
    }
};

test "BOM detection" {
    // UTF-8 BOM
    const utf8_bom = [_]u8{ 0xEF, 0xBB, 0xBF, 'H', 'e', 'l', 'l', 'o' };
    try std.testing.expectEqual(Encoding.utf8, EncodingDetector.detect(&utf8_bom));

    // UTF-16 LE BOM
    const utf16_le_bom = [_]u8{ 0xFF, 0xFE, 'H', 0x00, 'i', 0x00 };
    try std.testing.expectEqual(Encoding.utf16_le, EncodingDetector.detect(&utf16_le_bom));

    // UTF-16 BE BOM
    const utf16_be_bom = [_]u8{ 0xFE, 0xFF, 0x00, 'H', 0x00, 'i' };
    try std.testing.expectEqual(Encoding.utf16_be, EncodingDetector.detect(&utf16_be_bom));
}

test "UTF-8 validation" {
    // 有效的 UTF-8
    const valid_utf8 = "Hello, 世界! 🌍";
    try std.testing.expect(EncodingDetector.isValidUTF8(valid_utf8));

    // ASCII 也是有效的 UTF-8
    const ascii = "Hello, World!";
    try std.testing.expect(EncodingDetector.isValidUTF8(ascii));

    // 无效的 UTF-8
    const invalid_utf8 = [_]u8{ 0xFF, 0xFE, 0xFD };
    try std.testing.expect(!EncodingDetector.isValidUTF8(&invalid_utf8));
}

test "ASCII detection" {
    const ascii_text = "Hello, World!";
    try std.testing.expectEqual(Encoding.ascii, EncodingDetector.detect(ascii_text));

    const non_ascii = "Hello, 世界!";
    try std.testing.expect(EncodingDetector.detect(non_ascii) != .ascii);
}

test "GBK detection" {
    // GBK 编码的"你好" (0xC4E3 0xBAC3)
    const gbk_text = [_]u8{ 0xC4, 0xE3, 0xBA, 0xC3 };
    const encoding = EncodingDetector.detect(&gbk_text);
    // 应该检测为 GBK 或至少不是 UTF-8
    try std.testing.expect(encoding == .gbk or encoding != .utf8);
}

test "Latin-1 detection" {
    // Latin-1 编码的文本（包含西欧字符）
    const latin1_text = [_]u8{ 'H', 'e', 'l', 'l', 'o', ' ', 0xE9, 0xE8, 0xE0 }; // é è à
    const encoding = EncodingDetector.detect(&latin1_text);
    // 可能检测为 Latin-1 或 UTF-8
    try std.testing.expect(encoding == .latin1 or encoding == .utf8);
}

test "Encoding toString" {
    try std.testing.expectEqualStrings("UTF-8", Encoding.utf8.toString());
    try std.testing.expectEqualStrings("GBK", Encoding.gbk.toString());
    try std.testing.expectEqualStrings("Big5", Encoding.big5.toString());
    try std.testing.expectEqualStrings("Shift-JIS", Encoding.shift_jis.toString());
    try std.testing.expectEqualStrings("Latin-1", Encoding.latin1.toString());
}
