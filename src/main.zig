const std = @import("std");
const c = @cImport({
    @cInclude("raylib.h");
});

const Circle = struct {
    pos: c.Vector2,
    vel: c.Vector2,

    pub fn init(posX: f32, posY: f32, velX: f32, velY: f32) Circle {
       return Circle {
           .pos = c.Vector2{.x = posX, .y = posY},
           .vel = c.Vector2{.x = velX, .y = velY},
       }; 
    }

    pub fn update(self: *Circle, dt: f32) void{
        self.pos.x += self.vel.x * dt;
        self.pos.y += self.vel.y * dt;
    }

    pub fn draw(self: Circle, r: f32, color: c.Color) void {
        c.DrawCircleV(self.pos, r, color);
    }
};

const Rectangle = struct {
    pos: c.Vector2,
    vel: c.Vector2,

    pub fn init(posX: f32, posY: f32, velX: f32, velY: f32) Rectangle {
       return Rectangle {
           .pos = c.Vector2{.x = posX, .y = posY},
           .vel = c.Vector2{.x = velX, .y = velY},
       }; 
    }

    pub fn update(self: *Rectangle, ball: *Circle) void {
        const paddle_half_height = 45.0;
        const targetY = ball.pos.y - paddle_half_height;
        self.pos.y = std.math.clamp(targetY, 10.0, 720.0 - 90.0 - 10.0);
    }

    pub fn draw(self: Rectangle, size: c.Vector2, color: c.Color) void {
        c.DrawRectangleV(self.pos, size, color);
    }
};

fn checkCircleRectCollision(ballPos: c.Vector2, radius: f32, rectPos: c.Vector2, rectSize: c.Vector2) bool {
    const clamp = std.math.clamp;

    const cX = clamp(ballPos.x, rectPos.x, rectPos.x + rectSize.x);
    const cY = clamp(ballPos.y, rectPos.y, rectPos.y + rectSize.y);

    const dx = ballPos.x - cX;
    const dy = ballPos.y - cY;

    return (dx * dx + dy * dy) < (radius * radius);
}

fn UpdatePlayer(player: *Rectangle, dt: f32, rectSize: c.Vector2) void {
    const speed : f32 = 200.0;
    var pos = player.pos;

    if(c.IsKeyDown(c.KEY_UP)) {
        pos.y -= speed * dt;
    }
    if(c.IsKeyDown(c.KEY_DOWN)) {
        pos.y += speed * dt;
    }

    player.pos = pos;
    player.pos.y = std.math.clamp(player.pos.y, 10.0, 720.0 - rectSize.y - 10.0);
}

fn updateScore(score: *u64) void {
    score.* += 1;
}

pub fn main() void {

    c.InitWindow(1280, 720, "window");
    c.SetTargetFPS(60);
    const fixed_dt = 1.0 / 60.0;

    defer c.CloseWindow();

    var ball = Circle.init(300, 200, 300, 300);
    var leftPaddle = Rectangle.init(100, 400, 0, 300);
    var playerPaddle = Rectangle.init(1180, 400, 0, 100);

    const radius: f32 = 10.0;
    const rectSize = c.Vector2{ .x = 20, .y = 90 };
    
    var accumulator : f32 = 0.0;

    var botScore : u64 = 0;
    var playerScore : u64 = 0;

    while (!c.WindowShouldClose()) {
        const dt = c.GetFrameTime();
        accumulator += dt;
        
        UpdatePlayer(&playerPaddle, dt, rectSize);
        ball.update(dt);
        leftPaddle.update(&ball);

        //fixed update
        while (accumulator >= fixed_dt){
            if (checkCircleRectCollision(ball.pos, radius, leftPaddle.pos, rectSize)) {
                ball.vel.x *= -1;
                ball.vel.y *= 1;
            }
            if (checkCircleRectCollision(ball.pos, radius, playerPaddle.pos, rectSize)) {
                ball.vel.x *= -1;
                ball.vel.y *= 1;
            }
            if (ball.pos.y - radius <= 10 or ball.pos.y + radius >= 710) {
                ball.vel.y *= -1;
            }
            if (ball.pos.x - radius <= 10 or ball.pos.x + radius >= 1270) {
                ball.vel.x *= -1;
                if(ball.pos.x <= 20) {
                    updateScore(&playerScore);
                } 
                else {
                    updateScore(&botScore);
                }
            }

            accumulator -= fixed_dt;
        }

        //drawing 
        c.BeginDrawing();
        defer c.EndDrawing();

        c.ClearBackground(c.BLACK);
        
        c.DrawText("pongz", 20, 20, 20, c.WHITE);

        //walls
        c.DrawRectangle(0, 0, 1280, 10, c.GRAY);   // top
        c.DrawRectangle(0, 710, 1280, 10, c.GRAY); // bottom
        c.DrawRectangle(0, 0, 10, 720, c.GRAY);    // left
        c.DrawRectangle(1270, 0, 10, 720, c.GRAY); // right
                                    
        //score
        c.DrawText(c.TextFormat("%01i", botScore), 70, 650, 30, c.RED);
        c.DrawText(c.TextFormat("%01i", playerScore), 1210, 650, 30, c.SKYBLUE);
        
        ball.draw(radius, c.GOLD);
        leftPaddle.draw(rectSize, c.RED);
        playerPaddle.draw(rectSize, c.SKYBLUE);
    }
}
