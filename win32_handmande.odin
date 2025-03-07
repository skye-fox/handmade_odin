package game

import runtime "base:runtime"
import fmt "core:fmt"
import win "core:sys/windows"

bitmap_info := win.BITMAPINFO{}
bitmap_memory: rawptr
bitmap_handle: win.HBITMAP
bitmap_device_context: win.HDC

global_running := false

win32_resize_dib_section :: proc(width: i32, height: i32) {

    if bitmap_handle != nil {
        win.DeleteObject(win.HGDIOBJ(bitmap_handle))
    }

    if bitmap_device_context == nil {
        bitmap_device_context = win.CreateCompatibleDC(nil)
    }

    bitmap_info.bmiHeader.biSize = size_of(bitmap_info.bmiHeader)
    bitmap_info.bmiHeader.biWidth = width
    bitmap_info.bmiHeader.biHeight = height
    bitmap_info.bmiHeader.biPlanes = 1
    bitmap_info.bmiHeader.biBitCount = 32
    bitmap_info.bmiHeader.biCompression = win.BI_RGB

    bitmap_handle = win.CreateDIBSection(
        bitmap_device_context,
        &bitmap_info,
        win.DIB_RGB_COLORS,
        &bitmap_memory,
        nil,
        0,
    )
    win.ReleaseDC(nil, bitmap_device_context)
}

win32_update_window :: proc(
    device_context: win.HDC,
    x: i32,
    y: i32,
    width: i32,
    height: i32,
) {
    win.StretchDIBits(
        device_context,
        x,
        y,
        width,
        height,
        x,
        y,
        width,
        height,
        bitmap_memory,
        &bitmap_info,
        win.DIB_RGB_COLORS,
        win.SRCCOPY,
    )
}

win32_main_window_callback :: proc "stdcall" (
    window: win.HWND,
    message: u32,
    w_param: win.WPARAM,
    l_param: win.LPARAM,
) -> win.LRESULT {
    context = runtime.default_context()

    result: win.LRESULT = 0

    switch message {
    case win.WM_SIZE:
        {
            client_rect := win.RECT{}
            win.GetClientRect(window, &client_rect)
            width: i32 = client_rect.right - client_rect.left
            height: i32 = client_rect.bottom - client_rect.top
            win32_resize_dib_section(width, height)
        }
    case win.WM_CLOSE:
        {
        };fallthrough
    case win.WM_DESTROY:
        {
            global_running = false
        }
    case win.WM_ACTIVATEAPP:
        {
            fmt.println("WM_ACTIVATEAPP")
        }
    case win.WM_PAINT:
        {
            paint := win.PAINTSTRUCT{}
            device_context: win.HDC = win.BeginPaint(window, &paint)
            x := paint.rcPaint.left
            y := paint.rcPaint.top
            width := paint.rcPaint.right - paint.rcPaint.left
            height := paint.rcPaint.bottom - paint.rcPaint.top
            win32_update_window(device_context, x, y, width, height)
            win.PatBlt(device_context, x, y, width, height, win.BLACKNESS)
            win.EndPaint(window, &paint)
        }
    case:
        {
            //fmt.println("default")
            result = win.DefWindowProcW(window, message, w_param, l_param)
        }
    }
    return result
}

main :: proc() {
    instance: win.HINSTANCE = win.HINSTANCE(win.GetModuleHandleW(nil))

    window_class := win.WNDCLASSW{}
    window_class.style = win.CS_OWNDC | win.CS_HREDRAW | win.CS_VREDRAW
    window_class.lpfnWndProc = win32_main_window_callback
    window_class.hInstance = instance
    window_class.lpszClassName = win.L("HandmadeHeroWindowClass")

    if win.RegisterClassW(&window_class) != 0 {
        window_handle: win.HWND = win.CreateWindowExW(
            0,
            window_class.lpszClassName,
            win.L("Handmade Hero"),
            win.WS_OVERLAPPEDWINDOW | win.WS_VISIBLE,
            win.CW_USEDEFAULT,
            win.CW_USEDEFAULT,
            win.CW_USEDEFAULT,
            win.CW_USEDEFAULT,
            nil,
            nil,
            instance,
            nil,
        )

        if window_handle != nil {
            message: win.MSG

            global_running = true
            for global_running {
                message_result: i32 = win.GetMessageW(&message, nil, 0, 0)
                if message_result > 0 {
                    win.TranslateMessage(&message)
                    win.DispatchMessageW(&message)
                } else {
                    break
                }
            }
        } else {
            // TODO: Logging
        }
    } else {
        // TODO: Logging
    }
}
