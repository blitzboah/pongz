const std = @import("std");
const c = @cImport({
    @cInclude("raylib.h");
});

const max_trail = 10;

const TrailPoint = struct {
    pos: c.Vector2,
    vel: c.Vector2,
};

var ball_trail: [max_trail]TrailPoint = undefined;
var trail_index: usize = 0;

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

    pub fn update(self: *Rectangle, ball: *Circle, dt: f32) void {
        const paddle_half_height = 45.0;
        const targetY = ball.pos.y - paddle_half_height;
        const clampedTargetY = std.math.clamp(targetY, 10.0, 720.0 - 90.0 - 10.0);
        const maxSpeed = 300.0;
        const maxMove = maxSpeed * dt;
        const diff = clampedTargetY - self.pos.y;

        if (@abs(diff) <= maxMove) {
            self.pos.y = clampedTargetY;
        } else {
            self.pos.y += if (diff > 0) maxMove else -maxMove;
        }
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
    return (dx * dx + dy * dy) <= (radius * radius);
}

fn UpdatePlayer(player: *Rectangle, dt: f32, rectSize: c.Vector2) void {
    const speed : f32 = 300.0;
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

fn updateBallTrail(pos: c.Vector2, vel: c.Vector2) void {
    ball_trail[trail_index] = TrailPoint{ .pos = pos, .vel = vel };
    trail_index = (trail_index + 1) % max_trail;
}

fn drawBallTrail(radius: f32) void {
    var i: usize = 2;
    while (i < max_trail) : (i += 1) {
        const index = (trail_index + max_trail + 1 - i) % max_trail;
        const point = ball_trail[index];

        const t = @as(f32, @floatFromInt(i)) / @as(f32, @floatFromInt(max_trail));
        const alpha = 1.0 - t;
        const scale = 1.0 - t;
        const tail_radius = radius * scale * 0.9;
        const offset = c.Vector2{
            .x = point.vel.x * t * -0.008,
            .y = point.vel.y * t * -0.008,
        };
        const trail_pos = c.Vector2{
            .x = point.pos.x + offset.x,
            .y = point.pos.y + offset.y,
        };
        const faded_color = c.Color{
            .r = c.WHITE.r,
            .g = c.WHITE.g,
            .b = c.WHITE.b,
            .a = @intCast(@as(u8, @intFromFloat(155.0 * alpha))),
        };
        c.DrawCircleV(trail_pos, tail_radius, faded_color);
    }
}

pub fn main() void {
    c.InitWindow(1280, 720, "window");
    c.SetTargetFPS(60);

    const shader = c.LoadShader(null, "src/shader.fs");
    if (shader.id == 0) {
        std.debug.print("shader failed to load.\n", .{});
    }
    const uCenterLoc = c.GetShaderLocation(shader, "uCenter");
    const iResolutionLoc = c.GetShaderLocation(shader, "iResolution");
    const iTimeLoc = c.GetShaderLocation(shader, "iTime");

    var resolution: [3]f32 = .{1280.0, 720.0, 0.0};

    const fixed_dt = 1.0 / 60.0;
    defer c.CloseWindow();

    var ball = Circle.init(300, 200, 300, 300);
    var leftPaddle = Rectangle.init(100, 400, 0, 300);
    var playerPaddle = Rectangle.init(1180, 400, 0, 100);

    var start_time: f64 = 0.0;
    var zaWarudo: bool = false;
    var savedBall = Circle.init(0, 0, 0, 0);
    var savedLeftPaddle = Rectangle.init(0, 0, 0, 0);

    const radius: f32 = 10.0;
    const rectSize = c.Vector2{ .x = 20, .y = 90 };
    var accumulator : f32 = 0.0;
    var botScore : u64 = 0;
    var playerScore : u64 = 0;

    while (!c.WindowShouldClose()) {
        const dt = c.GetFrameTime();
        accumulator += dt;

        UpdatePlayer(&playerPaddle, dt, rectSize);


        if (c.IsKeyPressed(c.KEY_Z) and !zaWarudo) {
            zaWarudo = !zaWarudo;

            if (zaWarudo) {
                savedBall = ball;
                savedLeftPaddle = leftPaddle;
                start_time = c.GetTime(); // start timing from now
            } else {
                ball = savedBall;
                leftPaddle = savedLeftPaddle;
            }
        }


        if(!zaWarudo){
            ball.update(dt);
            updateBallTrail(ball.pos, ball.vel);
            leftPaddle.update(&ball, dt);
        }

        // fixed update
        while (accumulator >= fixed_dt){
            if (!zaWarudo) {
                if (checkCircleRectCollision(ball.pos, radius, playerPaddle.pos, rectSize)) {
                    const paddleCenterY = playerPaddle.pos.y + rectSize.y / 2;
                    const ballRelativeY = ball.pos.y - paddleCenterY;
                    if (ball.pos.x < playerPaddle.pos.x + rectSize.x / 2) {
                        ball.vel.x = -@abs(ball.vel.x);
                    } else {
                        ball.vel.y *= -1;
                        ball.vel.x += ballRelativeY * 0.1;
                    }
                }

                if (checkCircleRectCollision(ball.pos, radius, leftPaddle.pos, rectSize)) {
                    const paddleCenterY = leftPaddle.pos.y + rectSize.y / 2;
                    const ballRelativeY = ball.pos.y - paddleCenterY;
                    if (ball.pos.x > leftPaddle.pos.x + rectSize.x / 2) {
                        ball.vel.x = @abs(ball.vel.x);
                    } else {
                        ball.vel.y *= -1;
                        ball.vel.x += ballRelativeY * 0.1;
                    }
                    
                    ball.vel.x *= 1.05;
                    ball.vel.y *= 1.05;
                }

                if (ball.pos.y - radius <= 10 or ball.pos.y + radius >= 710) {
                    ball.vel.y *= -1;
                }

                if (ball.pos.x - radius <= 10 or ball.pos.x + radius >= 1270) {
                    ball.vel.x *= -1;
                    if (ball.pos.x <= 20) {
                        updateScore(&playerScore);
                    } else {
                        updateScore(&botScore);
                    }

                    ball.pos.x = 640;
                    ball.pos.y = 360;

                    ball.vel.x = -300;
                    ball.vel.y = 300;
                }
            }
            accumulator -= fixed_dt;
        }

        c.BeginDrawing();
        defer c.EndDrawing();


        if (zaWarudo) {
            var time: f32 = @floatCast(c.GetTime() - start_time);


            if (time >= 2) {
                zaWarudo = false;
                ball = savedBall;
                leftPaddle = savedLeftPaddle;
            }

            var uCenter: [2]f32 = .{
                playerPaddle.pos.x + rectSize.x / 2,
                720.0 - (playerPaddle.pos.y + rectSize.y / 2) 
            };

            c.SetShaderValue(shader, iResolutionLoc, &resolution, c.SHADER_UNIFORM_VEC3);
            c.SetShaderValue(shader, iTimeLoc, &time, c.SHADER_UNIFORM_FLOAT);
            c.SetShaderValue(shader, uCenterLoc, &uCenter, c.SHADER_UNIFORM_VEC2);

            c.ClearBackground(c.BLACK);

            c.BeginBlendMode(c.BLEND_ADDITIVE);
            c.BeginShaderMode(shader);
            c.DrawRectangle(0, 0, 1280, 720, c.WHITE);
            c.EndShaderMode();
            c.EndBlendMode();


        } else {
            c.ClearBackground(c.BLACK);
        }

        //drawing
        c.DrawText("pongz", 20, 20, 20, c.WHITE);
        c.DrawRectangle(0, 0, 1280, 10, c.GRAY);
        c.DrawRectangle(0, 710, 1280, 10, c.GRAY);
        c.DrawRectangle(0, 0, 10, 720, c.GRAY);
        c.DrawRectangle(1270, 0, 10, 720, c.GRAY);

        //score
        c.DrawText(c.TextFormat("%01i", botScore), 70, 650, 30, c.RED);
        c.DrawText(c.TextFormat("%01i", playerScore), 1210, 650, 30, c.SKYBLUE);
        
        //c.DrawFPS(600, 100);

        drawBallTrail(radius);
        ball.draw(radius, c.GOLD);
        leftPaddle.draw(rectSize, c.RED);
        playerPaddle.draw(rectSize, c.SKYBLUE);
    }
}
