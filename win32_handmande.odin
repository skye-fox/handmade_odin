package game

import runtime "base:runtime"
import fmt "core:fmt"
import win "core:sys/windows"

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
            fmt.println("WM_SIZE")
        }
    case win.WM_DESTROY:
        {
            fmt.println("WM_DESTROY")
        }
    case win.WM_CLOSE:
        {
            fmt.println("WM_CLOSE")
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
            for {
                message_result: i32 = win.GetMessageW(&message, nil, 0, 0)
                if message_result > 0 {
                    win.TranslateMessage(&message)
                    win.DispatchMessageW(&message)
                }
            }
        }
    } else {
        // TODO: Logging
    }
}
