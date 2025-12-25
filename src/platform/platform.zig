const std = @import("std");

/// 平台抽象 - 窗口接口
pub const Window = struct {
    /// 窗口句柄（平台特定）
    handle: *anyopaque,
    /// 窗口标题
    title: []const u8,
    /// 窗口宽度
    width: u32,
    /// 窗口高度
    height: u32,
    /// DPI 缩放比例
    dpi_scale: f32,

    /// 创建窗口
    pub fn create(title: []const u8, width: u32, height: u32) !Window {
        _ = title;
        _ = width;
        _ = height;
        @compileError("平台特定实现");
    }

    /// 显示窗口
    pub fn show(self: *Window) void {
        _ = self;
        @compileError("平台特定实现");
    }

    /// 运行消息循环
    pub fn run(self: *Window) !void {
        _ = self;
        @compileError("平台特定实现");
    }

    /// 获取 DPI 缩放比例
    pub fn getDpiScale(self: *const Window) f32 {
        return self.dpi_scale;
    }
};

/// 渲染器接口
pub const Renderer = struct {
    /// 开始绘制
    pub fn beginDraw(self: *Renderer) !void {
        _ = self;
        @compileError("平台特定实现");
    }

    /// 结束绘制
    pub fn endDraw(self: *Renderer) !void {
        _ = self;
        @compileError("平台特定实现");
    }

    /// 清空背景
    pub fn clear(self: *Renderer, color: u32) void {
        _ = self;
        _ = color;
        @compileError("平台特定实现");
    }

    /// 绘制文本
    pub fn drawText(
        self: *Renderer,
        text: []const u8,
        x: f32,
        y: f32,
        color: u32,
    ) !void {
        _ = self;
        _ = text;
        _ = x;
        _ = y;
        _ = color;
        @compileError("平台特定实现");
    }

    /// 绘制矩形
    pub fn drawRect(
        self: *Renderer,
        x: f32,
        y: f32,
        width: f32,
        height: f32,
        color: u32,
    ) void {
        _ = self;
        _ = x;
        _ = y;
        _ = width;
        _ = height;
        _ = color;
        @compileError("平台特定实现");
    }
};
