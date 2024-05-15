const std = @import("std");

const allocator = std.heap.c_allocator;
const assert = std.debug.assert;
const rand = std.crypto.random;
const ArrayList = std.ArrayList;

const raylib = @cImport({
    @cInclude("raylib.h");
});

const int2 = struct {
    x: i32,
    y: i32
};

const SnakeDirection = enum { 
    up, down, left, right,

    fn getDeltaDirection(self: SnakeDirection) int2 {
        switch (self) {
            SnakeDirection.up => return .{ .x = 0, .y = 1 },
            SnakeDirection.down => return .{ .x = 0, .y = -1 },
            SnakeDirection.left => return .{ .x = -1, .y = 0 },
            SnakeDirection.right => return .{ .x = 1, .y = 0 },
        }
    }
};

const GameState = struct {
    gameOver: bool,
    score: i32,
    mapSize: int2,
    snake: ArrayList(int2),
    food: int2,
    snakeDirection: SnakeDirection,
    nextSnakeDirection: SnakeDirection,

    fn generateFood(gameState: *GameState) void {
        while (true) {
            const randTile: int2 = .{
                .x = rand.intRangeAtMost(i32, 0, gameState.mapSize.x - 1),
                .y = rand.intRangeAtMost(i32, 0, gameState.mapSize.y - 1)
            };

            var alreadyOccupiedBySnake = false;
            for (gameState.snake.items) |snakeTilePart| {
                if (snakeTilePart.x == randTile.x and snakeTilePart.y == randTile.y) {
                    alreadyOccupiedBySnake = true;
                    break;
                }
            }

            if (!alreadyOccupiedBySnake) {
                gameState.food = randTile;
                break;
            }
        }
    }

    fn init(gameState: *GameState, x: i32, y: i32) !void {
        assert(x > 0 and x < 30);
        assert(y > 0 and y < 30);
        
        gameState.gameOver = false;
        gameState.score = 0;
        gameState.mapSize.x = x;
        gameState.mapSize.y = y;
        gameState.snakeDirection = SnakeDirection.right;
        gameState.nextSnakeDirection = gameState.snakeDirection;

        gameState.snake = try ArrayList(int2).initCapacity(allocator, 5);

        const middlePoint: int2 = .{ .x = @divTrunc(gameState.mapSize.x, 2), .y = @divTrunc(gameState.mapSize.y, 2) };

        var i: i32 = 0;
        while (i < 5) : (i += 1) {
            try gameState.snake.append(.{.x = middlePoint.x - i, .y = middlePoint.y});
        }

        generateFood(gameState);
    }

    fn free(gameState: *GameState) void {
        gameState.snake.deinit();
    }
};

fn initGameState() !*GameState {
    const gameState = try allocator.create(GameState);
    try gameState.init(20, 20);

    return gameState;
}

pub fn main() !void {
    var windowConfigs: raylib.ConfigFlags = 0;
    windowConfigs |= raylib.FLAG_WINDOW_RESIZABLE;

    var gameState = try initGameState();
    defer allocator.destroy(gameState);

    const windowSize: int2 = .{.x = 800, .y = 800};

    raylib.SetConfigFlags(windowConfigs);
    raylib.InitWindow(windowSize.x, windowSize.y, "My snake");
    raylib.SetTargetFPS(144);
    
    var tileSize: int2 = .{
        .x = @divTrunc(raylib.GetRenderWidth(), gameState.mapSize.x), 
        .y = @divTrunc(raylib.GetRenderHeight(), gameState.mapSize.y)
    };

    defer raylib.CloseWindow();

    var deltaTime: f32 = 0.0;
    var nextTickThreshold: f32 = 0.2;
     
    while (!raylib.WindowShouldClose()) {
        // update game state
        deltaTime += raylib.GetFrameTime();

        if (!gameState.gameOver and deltaTime > nextTickThreshold) {
            deltaTime = 0.0;

            const snakeTailPosition = gameState.snake.getLast();
            var index: usize = gameState.snake.items.len - 1;
            while (index > 0) : (index -= 1) {
                gameState.snake.items[index] = gameState.snake.items[index - 1];
            }

            gameState.snakeDirection = gameState.nextSnakeDirection;
            const moveDirection = SnakeDirection.getDeltaDirection(gameState.snakeDirection);
            
            gameState.snake.items[0].x += moveDirection.x;
            gameState.snake.items[0].y += moveDirection.y;

            if (gameState.snake.items[0].x < 0) {
                gameState.snake.items[0].x = gameState.mapSize.x - 1;
            }
            else if (gameState.snake.items[0].y < 0) {
                gameState.snake.items[0].y = gameState.mapSize.y - 1;
            }
            else if (gameState.snake.items[0].x >= gameState.mapSize.x) {
                gameState.snake.items[0].x = 0;
            } 
            else if (gameState.snake.items[0].y >= gameState.mapSize.y) {
                gameState.snake.items[0].y = 0;
            }

            if (gameState.snake.items[0].x == gameState.food.x and gameState.snake.items[0].y == gameState.food.y) {
                gameState.generateFood();
                gameState.score += 1;
                try gameState.snake.append(snakeTailPosition);
            }

            const snakeTail = gameState.snake.items[0];
            for (gameState.snake.items[1..]) |snakeTilePart| {
                if (snakeTilePart.x == snakeTail.x and snakeTilePart.y == snakeTail.y) {
                    gameState.gameOver = true;
                    break;
                }
            }            
        }

        if (gameState.snakeDirection != SnakeDirection.up and raylib.IsKeyDown(raylib.KEY_W)) { 
            gameState.nextSnakeDirection = SnakeDirection.down;
        }
        
        if (gameState.snakeDirection != SnakeDirection.down and raylib.IsKeyDown(raylib.KEY_S)) {
            gameState.nextSnakeDirection = SnakeDirection.up;
        }
        
        if (gameState.snakeDirection != SnakeDirection.right and raylib.IsKeyDown(raylib.KEY_A)) { 
            gameState.nextSnakeDirection = SnakeDirection.left;
        }
        
        if (gameState.snakeDirection != SnakeDirection.left and raylib.IsKeyDown(raylib.KEY_D)) {
            gameState.nextSnakeDirection = SnakeDirection.right;
        }

        nextTickThreshold = 0.2;
        if (raylib.IsKeyDown(raylib.KEY_SPACE)) {
            nextTickThreshold = 0.08;
        }

        //std.debug.print("YEAH {d}\n", .{deltaTime});

        // drawing
        raylib.BeginDrawing();
        defer raylib.EndDrawing();
        
        raylib.ClearBackground(raylib.BLACK);

        const rendererWidth = raylib.GetRenderWidth();
        const rendererHeight = raylib.GetRenderHeight();
   
        const gridColor: raylib.Color = .{
            .r = 15,
            .g = 15,
            .b = 15,
            .a = 255,
        };

        for (1..@intCast(gameState.mapSize.x)) |xPos| {
            raylib.DrawRectangle(@as(i32, @intCast(xPos)) * tileSize.x, 0, 
            1, rendererHeight, gridColor);
        }
        
        for (1..@intCast(gameState.mapSize.y)) |yPos| {
            raylib.DrawRectangle(0, @as(i32, @intCast(yPos)) * tileSize.y, 
            rendererWidth, 1, gridColor);
        }

        for (gameState.snake.items[1..]) |snakeTilePart| {
            raylib.DrawRectangle(snakeTilePart.x * tileSize.x, snakeTilePart.y * tileSize.y, 
            tileSize.x, tileSize.y,  raylib.DARKBLUE);
        }
        raylib.DrawRectangle(gameState.snake.items[0].x * tileSize.x, gameState.snake.items[0].y * tileSize.y, 
            tileSize.x, tileSize.y,  raylib.BLUE);

        raylib.DrawRectangle(gameState.food.x * tileSize.x, gameState.food.y * tileSize.y, 
            tileSize.x, tileSize.y,  raylib.RED);

        if (gameState.gameOver) {
            const looseText = "GAME OVER!\n R - restart";
            const textWidth = raylib.MeasureText(looseText, 30);
            
            const rendererHalfWidth = @divTrunc(rendererWidth, 2);
            const rendererHalfHeight = @divTrunc(rendererHeight, 2);
            raylib.DrawText(looseText, rendererHalfWidth - @divTrunc(textWidth, 2), 
                rendererHalfHeight, 30, raylib.YELLOW);

            if (raylib.IsKeyPressed(raylib.KEY_R)) {
                gameState.gameOver = false;
                gameState.free();
                gameState = try initGameState();
            }
        }

        const scoreText = try std.fmt.allocPrintZ(allocator, "SCORE: {d}",.{ gameState.score });
        const scoreTextWidth = raylib.MeasureText(scoreText.ptr, 20);
        defer allocator.free(scoreText);

        raylib.DrawText(scoreText.ptr, rendererWidth - scoreTextWidth, 
                0, 20, raylib.YELLOW);
        raylib.DrawFPS(10, 10);

        tileSize = .{
            .x = @divTrunc(raylib.GetRenderWidth(), gameState.mapSize.x), 
            .y = @divTrunc(raylib.GetRenderHeight(), gameState.mapSize.y)
        };
    }
}

test "simple test" {
    var list = std.ArrayList(i32).init(std.testing.allocator);
    defer list.deinit(); // try commenting this out and see if zig detects the memory leak!
    try list.append(42);
    try std.testing.expectEqual(@as(i32, 42), list.pop());
}
