# Ze - Zig 文本编辑器

一个使用 Zig 开发的跨平台代码编辑器，支持大文件、语法高亮、多标签页等高级功能。

## 当前状态

### 已完成
- ✅ 项目结构创建
- ✅ Rope 数据结构实现（基础版本）
- ✅ 编码检测模块（BOM、UTF-8、UTF-16、ASCII）
- ✅ TextBuffer 文本缓冲区

### 进行中
- 🔄 修复 build.zig 以兼容 Zig 0.16

### 待实现
- ⏳ 语法高亮（tree-sitter 集成）
- ⏳ 视口管理（虚拟滚动）
- ⏳ Windows 平台实现
- ⏳ macOS 平台实现

## 核心模块

### src/core/rope.zig
Rope 数据结构，用于高效处理大文本文件。
- `fromString()` - 从字符串创建
- `charAt()` - 获取指定位置字符
- `insert()` - 插入文本
- `toString()` - 转换为字符串

### src/core/encoding.zig
编码检测模块。
- BOM 检测（UTF-8, UTF-16 LE/BE, UTF-32 LE/BE）
- UTF-8 验证（完整的多字节序列验证）
- UTF-16 启发式检测
- ASCII 检测
- **GBK 检测**（简体中文）
- **Big5 检测**（繁体中文）
- **Shift-JIS 检测**（日文）
- **Latin-1 检测**（西欧语言）

**支持的编码**：
- UTF-8 (with/without BOM)
- UTF-16 LE/BE (with BOM)
- UTF-32 LE/BE (with BOM)
- GBK (简体中文)
- Big5 (繁体中文)
- Shift-JIS (日文)
- Latin-1 (ISO-8859-1)
- ASCII

### src/core/text_buffer.zig
文本缓冲区，基于 Rope 实现。
- 文件加载/保存
- 编码自动检测
- 行数统计
- 修改状态追踪

## 构建

注意：当前 build.zig 需要针对 Zig 0.16.0-dev API 进行调整。

```bash
# 构建
zig build

# 运行
zig build run

# 测试
zig build test
```

## 技术栈

- **语言**: Zig 0.16.0-dev
- **GUI**: Windows (Win32 API) / macOS (Cocoa/AppKit)
- **语法高亮**: tree-sitter (计划中)
- **数据结构**: Rope (平衡二叉树)

## 开发计划

详见 `implementation_plan.md`
