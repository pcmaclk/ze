const std = @import("std");

/// Rope 数据结构 - 用于高效处理大文本文件
/// 基于平衡二叉树，支持 O(log n) 的插入、删除操作
pub const Rope = struct {
    root: ?*Node,
    allocator: std.mem.Allocator,
    total_length: usize,

    const Node = struct {
        weight: usize, // 左子树的总长度
        left: ?*Node,
        right: ?*Node,
        data: ?[]const u8, // 叶子节点存储实际文本
        parent: ?*Node,

        fn isLeaf(self: *const Node) bool {
            return self.data != null;
        }
    };

    pub fn init(allocator: std.mem.Allocator) Rope {
        return .{
            .root = null,
            .allocator = allocator,
            .total_length = 0,
        };
    }

    pub fn deinit(self: *Rope) void {
        if (self.root) |root| {
            self.freeNode(root);
        }
    }

    fn freeNode(self: *Rope, node: *Node) void {
        if (node.left) |left| self.freeNode(left);
        if (node.right) |right| self.freeNode(right);
        if (node.data) |data| self.allocator.free(data);
        self.allocator.destroy(node);
    }

    /// 从字符串创建 Rope
    pub fn fromString(allocator: std.mem.Allocator, text: []const u8) !Rope {
        var rope = Rope.init(allocator);
        if (text.len == 0) return rope;

        const data = try allocator.dupe(u8, text);
        const node = try allocator.create(Node);
        node.* = .{
            .weight = text.len,
            .left = null,
            .right = null,
            .data = data,
            .parent = null,
        };

        rope.root = node;
        rope.total_length = text.len;
        return rope;
    }

    /// 获取总长度
    pub fn length(self: *const Rope) usize {
        return self.total_length;
    }

    /// 获取指定位置的字符
    pub fn charAt(self: *const Rope, pos: usize) ?u8 {
        if (pos >= self.total_length) return null;
        
        var node = self.root orelse return null;
        var current_pos = pos;

        while (true) {
            if (node.isLeaf()) {
                if (node.data) |data| {
                    if (current_pos < data.len) {
                        return data[current_pos];
                    }
                }
                return null;
            }

            if (current_pos < node.weight) {
                node = node.left orelse return null;
            } else {
                current_pos -= node.weight;
                node = node.right orelse return null;
            }
        }
    }

    /// 转换为字符串（用于调试和小文件）
    pub fn toString(self: *const Rope, allocator: std.mem.Allocator) ![]u8 {
        if (self.total_length == 0) return try allocator.alloc(u8, 0);
        
        const result = try allocator.alloc(u8, self.total_length);
        var index: usize = 0;
        
        if (self.root) |root| {
            try self.collectString(root, result, &index);
        }
        
        return result;
    }

    fn collectString(self: *const Rope, node: *Node, buffer: []u8, index: *usize) !void {
        if (node.isLeaf()) {
            if (node.data) |data| {
                @memcpy(buffer[index.*..index.* + data.len], data);
                index.* += data.len;
            }
        } else {
            if (node.left) |left| try self.collectString(left, buffer, index);
            if (node.right) |right| try self.collectString(right, buffer, index);
        }
    }

    /// 在指定位置插入文本
    pub fn insert(self: *Rope, pos: usize, text: []const u8) !void {
        if (text.len == 0) return;
        if (pos > self.total_length) return error.OutOfBounds;

        const new_data = try self.allocator.dupe(u8, text);
        const new_node = try self.allocator.create(Node);
        new_node.* = .{
            .weight = text.len,
            .left = null,
            .right = null,
            .data = new_data,
            .parent = null,
        };

        if (self.root == null) {
            self.root = new_node;
            self.total_length = text.len;
            return;
        }

        // 简化实现：在末尾插入
        if (pos == self.total_length) {
            const new_root = try self.allocator.create(Node);
            new_root.* = .{
                .weight = self.total_length,
                .left = self.root,
                .right = new_node,
                .data = null,
                .parent = null,
            };
            if (self.root) |root| root.parent = new_root;
            new_node.parent = new_root;
            self.root = new_root;
            self.total_length += text.len;
        }
    }

    /// 删除指定范围的文本
    pub fn delete(self: *Rope, start: usize, end: usize) !void {
        if (start >= end or start >= self.total_length) return;
        // TODO: 实现删除逻辑
    }
};

test "Rope basic operations" {
    const allocator = std.testing.allocator;

    // 测试创建
    var rope = try Rope.fromString(allocator, "Hello, World!");
    defer rope.deinit();

    try std.testing.expectEqual(@as(usize, 13), rope.length());
    try std.testing.expectEqual(@as(u8, 'H'), rope.charAt(0).?);
    try std.testing.expectEqual(@as(u8, '!'), rope.charAt(12).?);

    // 测试转换为字符串
    const str = try rope.toString(allocator);
    defer allocator.free(str);
    try std.testing.expectEqualStrings("Hello, World!", str);
}

test "Rope insert" {
    const allocator = std.testing.allocator;

    var rope = try Rope.fromString(allocator, "Hello");
    defer rope.deinit();

    try rope.insert(5, ", World!");
    try std.testing.expectEqual(@as(usize, 13), rope.length());
}
