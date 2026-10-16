MODULE RaylibNative;
(* VOC native boundary for Tigran Martirosyan's MIT-licensed Raylib port.
   Struct construction below only marshals arguments to the native API. *)
IMPORT SYSTEM;

PROCEDURE -AInclude '#include <raylib.h>';
PROCEDURE -initWindow(width, height: LONGINT; title: ARRAY OF CHAR)
  'InitWindow(width, height, (char*)title)';
PROCEDURE InitWindow*(width, height: LONGINT; title: ARRAY OF CHAR);
BEGIN initWindow(width, height, title) END InitWindow;
PROCEDURE -closeWindow 'CloseWindow()';
PROCEDURE CloseWindow*;
BEGIN closeWindow END CloseWindow;
PROCEDURE -beginDrawing 'BeginDrawing()';
PROCEDURE BeginDrawing*;
BEGIN beginDrawing END BeginDrawing;
PROCEDURE -endDrawing 'EndDrawing()';
PROCEDURE EndDrawing*;
BEGIN endDrawing END EndDrawing;
PROCEDURE -windowShouldClose(): BOOLEAN 'WindowShouldClose()';
PROCEDURE WindowShouldClose*(): BOOLEAN;
BEGIN RETURN windowShouldClose() END WindowShouldClose;
PROCEDURE -setTargetFPS(fps: LONGINT) 'SetTargetFPS(fps)';
PROCEDURE SetTargetFPS*(fps: LONGINT);
BEGIN setTargetFPS(fps) END SetTargetFPS;
PROCEDURE -getScreenWidth(): LONGINT 'GetScreenWidth()';
PROCEDURE GetScreenWidth*(): LONGINT;
BEGIN RETURN getScreenWidth() END GetScreenWidth;
PROCEDURE -getScreenHeight(): LONGINT 'GetScreenHeight()';
PROCEDURE GetScreenHeight*(): LONGINT;
BEGIN RETURN getScreenHeight() END GetScreenHeight;
PROCEDURE -toggleFullscreen 'ToggleFullscreen()';
PROCEDURE ToggleFullscreen*;
BEGIN toggleFullscreen END ToggleFullscreen;
PROCEDURE -isKeyPressed(key: LONGINT): BOOLEAN 'IsKeyPressed(key)';
PROCEDURE IsKeyPressed*(key: LONGINT): BOOLEAN;
BEGIN RETURN isKeyPressed(key) END IsKeyPressed;
PROCEDURE -getFrameTime(): REAL 'GetFrameTime()';
PROCEDURE GetFrameTime*(): REAL;
BEGIN RETURN getFrameTime() END GetFrameTime;
PROCEDURE -getRandomValue(min, max: LONGINT): LONGINT 'GetRandomValue(min, max)';
PROCEDURE GetRandomValue*(min, max: LONGINT): LONGINT;
BEGIN RETURN getRandomValue(min, max) END GetRandomValue;
PROCEDURE -setRandomSeed(seed: LONGINT) 'SetRandomSeed((unsigned int)seed)';
PROCEDURE SetRandomSeed*(seed: LONGINT);
BEGIN setRandomSeed(seed) END SetRandomSeed;
PROCEDURE -getTime(): LONGREAL 'GetTime()';
PROCEDURE GetTime*(): LONGREAL;
BEGIN RETURN getTime() END GetTime;
PROCEDURE -setWindowSize(width, height: LONGINT) 'SetWindowSize(width, height)';
PROCEDURE SetWindowSize*(width, height: LONGINT);
BEGIN setWindowSize(width, height) END SetWindowSize;

PROCEDURE -colorValue 'Color value';
PROCEDURE -getColor(hex: SET) 'value = GetColor((unsigned int)hex)';
PROCEDURE -red(): CHAR 'value.r';
PROCEDURE -green(): CHAR 'value.g';
PROCEDURE -blue(): CHAR 'value.b';
PROCEDURE -alpha(): CHAR 'value.a';
PROCEDURE GetColor*(hex: SET; VAR r, g, b, a: CHAR);
BEGIN colorValue; getColor(hex); r := red(); g := green(); b := blue(); a := alpha() END GetColor;

PROCEDURE -drawText(text: ARRAY OF CHAR; x, y, size: LONGINT; r, g, b, a: CHAR)
  'DrawText((char*)text, x, y, size, (Color){r, g, b, a})';
PROCEDURE DrawText*(text: ARRAY OF CHAR; x, y, size: LONGINT; r, g, b, a: CHAR);
BEGIN drawText(text, x, y, size, r, g, b, a) END DrawText;
PROCEDURE -drawRectangle(x, y, width, height: LONGINT; r, g, b, a: CHAR)
  'DrawRectangle(x, y, width, height, (Color){r, g, b, a})';
PROCEDURE DrawRectangle*(x, y, width, height: LONGINT; r, g, b, a: CHAR);
BEGIN drawRectangle(x, y, width, height, r, g, b, a) END DrawRectangle;
PROCEDURE -drawRectangleV(x, y, width, height: REAL; r, g, b, a: CHAR)
  'DrawRectangleV((Vector2){x, y}, (Vector2){width, height}, (Color){r, g, b, a})';
PROCEDURE DrawRectangleV*(x, y, width, height: REAL; r, g, b, a: CHAR);
BEGIN drawRectangleV(x, y, width, height, r, g, b, a) END DrawRectangleV;
PROCEDURE -clearBackground(r, g, b, a: CHAR) 'ClearBackground((Color){r, g, b, a})';
PROCEDURE ClearBackground*(r, g, b, a: CHAR);
BEGIN clearBackground(r, g, b, a) END ClearBackground;
END RaylibNative.
