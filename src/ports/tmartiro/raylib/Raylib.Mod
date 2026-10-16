MODULE Raylib;
(* Copyright 2024 Tigran Martirosyan. MIT licence: see LICENSE.
   VOC adaptation: isolate native types and calls in RaylibNative. *)
IMPORT RaylibNative;
CONST
    KeyA*               = 65;       (* Key: A | a *)
    KeyB*               = 66;       (* Key: B | b *)
    KeyC*               = 67;       (* Key: C | c *)
    KeyD*               = 68;       (* Key: D | d *)
    KeyE*               = 69;       (* Key: E | e *)
    KeyF*               = 70;       (* Key: F | f *)
    KeyG*               = 71;       (* Key: G | g *)
    KeyH*               = 72;       (* Key: H | h *)
    KeyI*               = 73;       (* Key: I | i *)
    KeyJ*               = 74;       (* Key: J | j *)
    KeyK*               = 75;       (* Key: K | k *)
    KeyL*               = 76;       (* Key: L | l *)
    KeyM*               = 77;       (* Key: M | m *)
    KeyN*               = 78;       (* Key: N | n *)
    KeyO*               = 79;       (* Key: O | o *)
    KeyP*               = 80;       (* Key: P | p *)
    KeyQ*               = 81;       (* Key: Q | q *)
    KeyR*               = 82;       (* Key: R | r *)
    KeyS*               = 83;       (* Key: S | s *)
    KeyT*               = 84;       (* Key: T | t *)
    KeyU*               = 85;       (* Key: U | u *)
    KeyV*               = 86;       (* Key: V | v *)
    KeyW*               = 87;       (* Key: W | w *)
    KeyX*               = 88;       (* Key: X | x *)
    KeyY*               = 89;       (* Key: Y | y *)
    KeyZ*               = 90;       (* Key: Z | z *)
    KeySpace*           = 32;       (* Key: Space *)
    KeyEscape*          = 256;      (* Key: Esc *)
    KeyEnter*           = 257;      (* Key: Enter *)
    KeyTab*             = 258;      (* Key: Tab *)
    KeyBackspace*       = 259;      (* Key: Backspace *)
    KeyInsert*          = 260;      (* Key: Ins *)
    KeyDelete*          = 261;      (* Key: Del *)
    KeyRight*           = 262;      (* Key: Cursor right *)
    KeyLeft*            = 263;      (* Key: Cursor left *)
    KeyDown*            = 264;      (* Key: Cursor down *)
    KeyUp*              = 265;      (* Key: Cursor up *)

TYPE
  TColor* = RECORD
    r*: CHAR;
    g*: CHAR;
    b*: CHAR;
    a*: CHAR;
  END;

  TVector2* = RECORD
    x*: REAL;
    y*: REAL;
  END;

  TRect* = RECORD
    x*: REAL;
    y*: REAL;
    width*: REAL;
    height*: REAL;
  END;



PROCEDURE InitWindow*(width, height: LONGINT; title: ARRAY OF CHAR);
BEGIN RaylibNative.InitWindow(width, height, title) END InitWindow;
PROCEDURE CloseWindow*;
BEGIN RaylibNative.CloseWindow END CloseWindow;
PROCEDURE BeginDrawing*;
BEGIN RaylibNative.BeginDrawing END BeginDrawing;
PROCEDURE EndDrawing*;
BEGIN RaylibNative.EndDrawing END EndDrawing;
PROCEDURE WindowShouldClose*(): BOOLEAN;
BEGIN RETURN RaylibNative.WindowShouldClose() END WindowShouldClose;
PROCEDURE SetTargetFPS*(fps: LONGINT);
BEGIN RaylibNative.SetTargetFPS(fps) END SetTargetFPS;
PROCEDURE GetColor*(hexValue: SET; VAR color: TColor);
BEGIN RaylibNative.GetColor(hexValue, color.r, color.g, color.b, color.a) END GetColor;
PROCEDURE GetScreenWidth*(): LONGINT;
BEGIN RETURN RaylibNative.GetScreenWidth() END GetScreenWidth;
PROCEDURE GetScreenHeight*(): LONGINT;
BEGIN RETURN RaylibNative.GetScreenHeight() END GetScreenHeight;
PROCEDURE ToggleFullscreen*;
BEGIN RaylibNative.ToggleFullscreen END ToggleFullscreen;
PROCEDURE IsKeyPressed*(key: LONGINT): BOOLEAN;
BEGIN RETURN RaylibNative.IsKeyPressed(key) END IsKeyPressed;
PROCEDURE GetFrameTime*(): REAL;
BEGIN RETURN RaylibNative.GetFrameTime() END GetFrameTime;
PROCEDURE GetRandomValue*(min, max: LONGINT): LONGINT;
BEGIN RETURN RaylibNative.GetRandomValue(min, max) END GetRandomValue;
PROCEDURE SetRandomSeed*(seed: LONGINT);
BEGIN RaylibNative.SetRandomSeed(seed) END SetRandomSeed;
PROCEDURE GetTime*(): LONGREAL;
BEGIN RETURN RaylibNative.GetTime() END GetTime;
PROCEDURE SetWindowSize*(width, height: LONGINT);
BEGIN RaylibNative.SetWindowSize(width, height) END SetWindowSize;
PROCEDURE DrawText*(text: ARRAY OF CHAR; posx, posy, fontSize: LONGINT; color: TColor);
BEGIN RaylibNative.DrawText(text, posx, posy, fontSize, color.r, color.g, color.b, color.a) END DrawText;
PROCEDURE DrawRectangle*(posx, posy, width, height: LONGINT; color: TColor);
BEGIN RaylibNative.DrawRectangle(posx, posy, width, height, color.r, color.g, color.b, color.a) END DrawRectangle;
PROCEDURE DrawRectangleV*(pos, size: TVector2; color: TColor);
BEGIN RaylibNative.DrawRectangleV(pos.x, pos.y, size.x, size.y, color.r, color.g, color.b, color.a) END DrawRectangleV;
PROCEDURE ClearBackground*(color: TColor);
BEGIN RaylibNative.ClearBackground(color.r, color.g, color.b, color.a) END ClearBackground;

END Raylib.
