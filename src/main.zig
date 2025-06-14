const std = @import("std");
const c = @cImport({
    @cInclude("raylib.h");
});

const Ball = struct {
    pos: c.Vector2,
    vel: c.Vector2,

    pub fn update(self: *Ball, dt: f32) void{
        const gravity = 10;

        self.vel.y += dt * gravity;

        self.pos.x += self.vel.x * dt;
        self.pos.y += self.vel.y * dt;
    }

    pub fn draw(self: Ball, r: f32, color: c.Color) void {
        c.DrawCircleV(self.pos, r, color);
    }
};

const Rectangle = struct {
    pos: c.Vector2,
    vel: c.Vector2,
    down: bool = true,

    pub fn update(self: *Rectangle, dt: f32) void {
        if (self.down) {
            self.pos.y += self.vel.y * dt;
            if (self.pos.y >= 300.0){
                self.down = false;
            }
        }
        else {
            self.pos.y -= self.vel.y * dt;
            if (self.pos.y <= 100.0){
                self.down = true;
            }
        }
    }

    pub fn draw(self: Rectangle, size: c.Vector2, color: c.Color) void {
        c.DrawRectangleV(self.pos, size, color);
    }
};

pub fn main() void {

    c.InitWindow(1280, 720, "window");
    c.SetTargetFPS(60);

    defer c.CloseWindow();

    var ball = Ball{
        .pos = c.Vector2{.x = 100.0, .y = 100.0},
        .vel = c.Vector2{.x = 50.0, .y = 0.0},
    };

    var rect1 = Rectangle{
        .pos = c.Vector2{.x = 100.0, .y = 100.0},
        .vel = c.Vector2{.x = 0.0, .y = 100.0},
    };

    var rect2 = Rectangle{
        .pos = c.Vector2{.x = 500.0, .y = 200.0},
        .vel = c.Vector2{.x = 0.0, .y = 100.0},
    };

    while (!c.WindowShouldClose()) {

        const dt = c.GetFrameTime();

        ball.update(dt);
        rect1.update(dt);
        rect2.update(dt);

        c.BeginDrawing();
        defer c.EndDrawing();

        c.ClearBackground(c.BLACK);
        
        c.DrawText("pongz", 0, 0, 20, c.WHITE);
        ball.draw(10, c.SKYBLUE);
        rect1.draw(c.Vector2{.x = 20, .y = 90}, c.WHITE);
        rect2.draw(c.Vector2{.x = 20, .y = 90}, c.WHITE);
    }
}
