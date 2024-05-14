const std = @import("std");
const raylib = @cImport({
    @cInclude("raylib.h");
});

pub fn main() !void {
    var windowConfigs: raylib.ConfigFlags = 0;
    windowConfigs |= raylib.FLAG_WINDOW_RESIZABLE;

    raylib.SetConfigFlags(windowConfigs);
    raylib.InitWindow(800, 800, "hello world!");
    raylib.SetTargetFPS(144);

    defer raylib.CloseWindow();

    while (!raylib.WindowShouldClose()) {
        raylib.BeginDrawing();
        defer raylib.EndDrawing();
        
        raylib.ClearBackground(raylib.BLACK);
        raylib.DrawFPS(10, 10);

        raylib.DrawText("hello world!", 100, 100, 20, raylib.YELLOW);
        raylib.DrawRectangle(0, 0, 10, 5,  raylib.RED);
    }

    // Prints to stderr (it's a shortcut based on `std.io.getStdErr()`)
    // std.debug.print("All your {s} are belong to us.\n", .{"codebase"});
    // ray.InitWindow(800, 450, "raylib [core] example - basic window");

    // // stdout is for the actual output of your application, for example if you
    // // are implementing gzip, then only the compressed bytes should be sent to
    // // stdout, not any debugging messages.
    // const stdout_file = std.io.getStdOut().writer();
    // var bw = std.io.bufferedWriter(stdout_file);
    // const stdout = bw.writer();

    // try stdout.print("Run `zig build test` to run the tests.\n", .{});

    // try bw.flush(); // don't forget to flush!
}

test "simple test" {
    var list = std.ArrayList(i32).init(std.testing.allocator);
    defer list.deinit(); // try commenting this out and see if zig detects the memory leak!
    try list.append(42);
    try std.testing.expectEqual(@as(i32, 42), list.pop());
}
