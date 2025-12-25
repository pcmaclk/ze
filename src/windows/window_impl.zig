const std = @import("std");

// 简化的 Win32 绑定 (callconv(.c))
const HWND = ?*anyopaque;
const HINSTANCE = ?*anyopaque;
const LPARAM = isize;
const WPARAM = usize;
const UINT = c_uint;
const LRESULT = isize;
const BOOL = i32;

// DPI 常量
const DPI_AWARENESS_CONTEXT_PER_MONITOR_AWARE_V2: isize = -4;

extern "user32" fn CreateWindowExW(
    dwExStyle: u32,
    lpClassName: [*:0]const u16,
    lpWindowName: [*:0]const u16,
    dwStyle: u32,
    X: i32,
    Y: i32,
    nWidth: i32,
    nHeight: i32,
    hWndParent: HWND,
    hMenu: ?*anyopaque,
    hInstance: HINSTANCE,
    lpParam: ?*anyopaque,
) callconv(.c) HWND;

extern "user32" fn ShowWindow(hWnd: HWND, nCmdShow: i32) callconv(.c) i32;
extern "user32" fn UpdateWindow(hWnd: HWND) callconv(.c) i32;
extern "user32" fn GetMessageW(lpMsg: *MSG, hWnd: HWND, wMsgFilterMin: UINT, wMsgFilterMax: UINT) callconv(.c) i32;
extern "user32" fn TranslateMessage(lpMsg: *const MSG) callconv(.c) i32;
extern "user32" fn DispatchMessageW(lpMsg: *const MSG) callconv(.c) LRESULT;
extern "user32" fn DefWindowProcW(hWnd: HWND, Msg: UINT, wParam: WPARAM, lParam: LPARAM) callconv(.c) LRESULT;
extern "user32" fn PostQuitMessage(nExitCode: i32) callconv(.c) void;
extern "user32" fn RegisterClassExW(lpWndClass: *const WNDCLASSEXW) callconv(.c) u16;
extern "user32" fn LoadCursorW(hInstance: HINSTANCE, lpCursorName: ?[*:0]const u16) callconv(.c) ?*anyopaque;
extern "kernel32" fn GetModuleHandleW(lpModuleName: ?[*:0]const u16) callconv(.c) HINSTANCE;
extern "user32" fn BeginPaint(hWnd: HWND, lpPaint: *PAINTSTRUCT) callconv(.c) ?*anyopaque;
extern "user32" fn EndPaint(hWnd: HWND, lpPaint: *const PAINTSTRUCT) callconv(.c) i32;
extern "user32" fn GetClientRect(hWnd: HWND, lpRect: *RECT) callconv(.c) i32;
extern "user32" fn DrawTextW(hdc: ?*anyopaque, lpchText: [*:0]const u16, cchText: i32, lprc: *RECT, format: UINT) callconv(.c) i32;

// DPI 相关函数
extern "user32" fn SetProcessDpiAwarenessContext(value: isize) callconv(.c) BOOL;
extern "user32" fn GetDpiForWindow(hwnd: HWND) callconv(.c) u32;

const MSG = extern struct {
    hwnd: HWND,
    message: UINT,
    wParam: WPARAM,
    lParam: LPARAM,
    time: u32,
    pt: POINT,
    lPrivate: u32,
};

const POINT = extern struct {
    x: i32,
    y: i32,
};

const WNDCLASSEXW = extern struct {
    cbSize: UINT,
    style: UINT,
    lpfnWndProc: *const fn (HWND, UINT, WPARAM, LPARAM) callconv(.c) LRESULT,
    cbClsExtra: i32,
    cbWndExtra: i32,
    hInstance: HINSTANCE,
    hIcon: ?*anyopaque,
    hCursor: ?*anyopaque,
    hbrBackground: ?*anyopaque,
    lpszMenuName: ?[*:0]const u16,
    lpszClassName: [*:0]const u16,
    hIconSm: ?*anyopaque,
};

const PAINTSTRUCT = extern struct {
    hdc: ?*anyopaque,
    fErase: i32,
    rcPaint: RECT,
    fRestore: i32,
    fIncUpdate: i32,
    rgbReserved: [32]u8,
};

const RECT = extern struct {
    left: i32,
    top: i32,
    right: i32,
    bottom: i32,
};

// 常量
const WS_OVERLAPPEDWINDOW: u32 = 0x00CF0000;
const CW_USEDEFAULT: i32 = @bitCast(@as(u32, 0x80000000));
const SW_SHOW: i32 = 5;
const CS_HREDRAW: UINT = 0x0002;
const CS_VREDRAW: UINT = 0x0001;
const IDC_ARROW: usize = 32512;
const COLOR_WINDOW: usize = 5;
const WM_DESTROY: UINT = 0x0002;
const WM_PAINT: UINT = 0x000F;
const DT_CENTER: UINT = 0x00000001;
const DT_VCENTER: UINT = 0x00000004;
const DT_SINGLELINE: UINT = 0x00000020;

pub const WindowsWindow = struct {
    hwnd: HWND,
    dpi_scale: f32,

    pub fn create() !WindowsWindow {
        // 设置 DPI 感知
        _ = SetProcessDpiAwarenessContext(DPI_AWARENESS_CONTEXT_PER_MONITOR_AWARE_V2);

        const h_instance = GetModuleHandleW(null);

        const class_name = std.unicode.utf8ToUtf16LeStringLiteral("ZeEditorClass");

        var wc: WNDCLASSEXW = undefined;
        wc.cbSize = @sizeOf(WNDCLASSEXW);
        wc.style = CS_HREDRAW | CS_VREDRAW;
        wc.lpfnWndProc = windowProc;
        wc.cbClsExtra = 0;
        wc.cbWndExtra = 0;
        wc.hInstance = h_instance;
        wc.hIcon = null;
        wc.hCursor = LoadCursorW(null, @ptrFromInt(IDC_ARROW));
        wc.hbrBackground = @ptrFromInt(COLOR_WINDOW + 1);
        wc.lpszMenuName = null;
        wc.lpszClassName = class_name;
        wc.hIconSm = null;

        _ = RegisterClassExW(&wc);

        const title = std.unicode.utf8ToUtf16LeStringLiteral("Ze - Text Editor (High DPI)");

        const hwnd = CreateWindowExW(
            0,
            class_name,
            title,
            WS_OVERLAPPEDWINDOW,
            CW_USEDEFAULT,
            CW_USEDEFAULT,
            1200,
            800,
            null,
            null,
            h_instance,
            null,
        );

        if (hwnd == null) {
            return error.CreateWindowFailed;
        }

        // 获取 DPI 缩放
        const dpi = GetDpiForWindow(hwnd);
        const dpi_scale = @as(f32, @floatFromInt(dpi)) / 96.0;

        return WindowsWindow{
            .hwnd = hwnd,
            .dpi_scale = dpi_scale,
        };
    }

    pub fn show(self: *WindowsWindow) void {
        _ = ShowWindow(self.hwnd, SW_SHOW);
        _ = UpdateWindow(self.hwnd);
    }

    pub fn run(self: *WindowsWindow) !void {
        _ = self;
        var msg: MSG = undefined;

        while (GetMessageW(&msg, null, 0, 0) > 0) {
            _ = TranslateMessage(&msg);
            _ = DispatchMessageW(&msg);
        }
    }

    pub fn getDpiScale(self: *const WindowsWindow) f32 {
        return self.dpi_scale;
    }

    fn windowProc(hwnd: HWND, msg: UINT, w_param: WPARAM, l_param: LPARAM) callconv(.c) LRESULT {
        switch (msg) {
            WM_DESTROY => {
                PostQuitMessage(0);
                return 0;
            },
            WM_PAINT => {
                var ps: PAINTSTRUCT = undefined;
                const hdc = BeginPaint(hwnd, &ps);

                const text = std.unicode.utf8ToUtf16LeStringLiteral("Ze Editor - High DPI Text");
                var rect: RECT = undefined;
                _ = GetClientRect(hwnd, &rect);

                // 简单的 GDI 绘制 - 以后会换成 Direct2D
                _ = DrawTextW(hdc, text, -1, &rect, DT_CENTER | DT_VCENTER | DT_SINGLELINE);

                _ = EndPaint(hwnd, &ps);
                return 0;
            },
            else => {},
        }

        return DefWindowProcW(hwnd, msg, w_param, l_param);
    }
};
