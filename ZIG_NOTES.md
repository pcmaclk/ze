# Zig 0.16 开发注意事项

## ⚠️ 常见错误和解决方案

### 1. build.zig API 变化

**错误示例**：
```zig
// ❌ 错误 - Zig 0.16 不支持
const exe = b.addExecutable(.{
    .name = "ze",
    .root_source_file = b.path("src/main.zig"),  // 错误！
    .target = target,  // 错误！
    .optimize = optimize,  // 错误！
});
```

**正确写法**：
```zig
// ✅ 正确 - Zig 0.16
const exe = b.addExecutable(.{
    .name = "ze",
    .root_module = b.createModule(.{
        .root_source_file = b.path("src/main.zig"),
        .target = target,
        .optimize = optimize,
    }),
});
```

**关键点**：
- `addExecutable` 只接受 `name` 和 `root_module`
- 使用 `b.createModule()` 创建模块
- `target` 和 `optimize` 放在 `createModule` 内部

### 2. ArrayList 初始化

**错误示例**：
```zig
// ❌ 错误 - Zig 0.16 没有 init 方法
var list = std.ArrayList(u8).init(allocator);
```

**正确写法**：
```zig
// ✅ 正确 - 使用结构体字面量
var list = std.ArrayList(u8){ 
    .items = &.{}, 
    .capacity = 0, 
    .allocator = allocator  // 注意：某些版本可能没有此字段
};

// 或者使用切片
var list: []T = &.{};
```

**关键点**：
- ArrayList 在 Zig 0.16 中没有 `.init()` 方法
- 需要直接使用结构体字面量初始化
- 或者考虑使用简单的切片代替

### 3. C 导入和 Win32 API

**正确写法**：
```zig
const win32 = @cImport({
    @cDefine("UNICODE", "1");
    @cDefine("_UNICODE", "1");
    @cDefine("WINVER", "0x0A00");
    @cDefine("_WIN32_WINNT", "0x0A00");
    @cInclude("windows.h");
    @cInclude("shellscalingapi.h");  // DPI 支持
});
```

**关键点**：
- 必须定义 UNICODE 宏
- 设置正确的 Windows 版本
- DPI 支持需要 shellscalingapi.h 和 shcore.lib

### 4. 高 DPI 支持要点

**必需步骤**：
1. 链接 `shcore` 库
2. 调用 `SetProcessDpiAwarenessContext(DPI_AWARENESS_CONTEXT_PER_MONITOR_AWARE_V2)`
3. 处理 `WM_DPICHANGED` 消息
4. 使用 `GetDpiForWindow()` 获取当前 DPI

**示例**：
```zig
// 设置 DPI 感知
_ = win32.SetProcessDpiAwarenessContext(
    win32.DPI_AWARENESS_CONTEXT_PER_MONITOR_AWARE_V2
);

// 获取 DPI 缩放
const dpi = win32.GetDpiForWindow(hwnd);
const dpi_scale = @as(f32, @floatFromInt(dpi)) / 96.0;
```

## 📝 开发检查清单

在编写代码前检查：
- [ ] build.zig 使用 `createModule` 而不是直接传递参数
- [ ] ArrayList 使用结构体字面量或切片
- [ ] Windows 代码定义了 UNICODE 宏
- [ ] 高 DPI 应用链接了 shcore 库
- [ ] 测试代码在提交前运行通过

## 🔍 调试技巧

1. **编译错误**：仔细阅读错误信息中的 "note" 部分
2. **API 变化**：使用 `zig init` 创建新项目查看最新 API
3. **Win32 API**：查看 MSDN 文档确认函数签名
4. **内存问题**：使用 GeneralPurposeAllocator 的 deinit 检查泄漏

## 版本信息

- **Zig 版本**: 0.16.0-dev.1634+b27bdd5af
- **最后更新**: 2025-12-25
