MODULE Snake;
IMPORT SYSTEM, Raylib, Math;

CONST
  title = "Odzik";
  MaxTailLen = 256;

TYPE
  (* pTSnake= POINTER TO TSnake; *)
  TSnake = RECORD
    color: Raylib.TColor;
    pos: Raylib.TVector2;
    size: Raylib.TVector2;
    len: INTEGER;
    tail: ARRAY MaxTailLen OF Raylib.TVector2;
  END;
  (* pTRabbit = POINTER TO TRabbit; *)
  TRabbit = RECORD
    color: Raylib.TColor;
    pos: Raylib.TVector2;
    size: Raylib.TVector2;

    END;


VAR
  BgColor: Raylib.TColor;
  SnakePos: Raylib.TVector2;
  DeltaPos: Raylib.TVector2;
  Velocity: REAL;
  Snake: TSnake;
  Rabbit: TRabbit;
  Score: ARRAY 10 OF CHAR;

PROCEDURE IntToStr(val: LONGINT; VAR str: ARRAY OF CHAR);
  VAR
    i, j: LONGINT;
    digits: ARRAY 16 OF LONGINT;
BEGIN
  IF val = MIN(LONGINT) THEN
    COPY("-2147483648", str);
    RETURN
  END;
  IF val < 0 THEN
    val := -val; str[0] := "-"; j := 1
  ELSE
    j := 0
  END;
  i := 0;
  REPEAT
    digits[i] := val MOD 10; INC(i); val := val DIV 10
  UNTIL val = 0;
  DEC(i);
  WHILE i >= 0 DO
    str[j] := CHR(digits[i]+ORD("0")); INC(j); DEC(i)
  END;
  str[j] := 0X
END IntToStr;

PROCEDURE NewRabbit(VAR r:TRabbit);
BEGIN
  r.color.r := 0FFX;
  r.color.g := 0X;
  r.color.b := 0AAX;
  r.color.a := 0FFX;
  r.size.x := 15.0;
  r.size.y := 15.0;
  r.pos.x := Raylib.GetRandomValue(0, Raylib.GetScreenWidth());
  r.pos.y := Raylib.GetRandomValue(0, Raylib.GetScreenHeight());
END NewRabbit;


PROCEDURE NewSnake(VAR s: TSnake);
BEGIN
  s.color.r := 0X;
  s.color.g := 0FFX;
  s.color.b := 0X;
  s.color.a := 0FFX;
  s.size.x := 25.0;
  s.size.y := 25.0;
  s.pos.x := 0;
  s.pos.y := 100;
  s.len := 0;
END NewSnake;

PROCEDURE DrawSnake(VAR s:TSnake);
VAR
  i:INTEGER;
BEGIN
  FOR i:= 0 TO s.len DO
    Raylib.DrawRectangleV(s.tail[i], s.size, s.color);
  END;
  Raylib.DrawRectangleV(s.pos, s.size, s.color);
END DrawSnake;

PROCEDURE DrawRabbit(VAR r:TRabbit);
VAR
  earpos : Raylib.TVector2;
  earsize: Raylib.TVector2;
BEGIN
  (* draw ears *)
  earpos.x := r.pos.x + 2; earpos.y := r.pos.y - 4;
  earsize.x := r.size.x/6; earsize.y := r.size.y/3;
  Raylib.DrawRectangleV(earpos, earsize, r.color);
  earpos.x := r.pos.x + r.size.x/1.5;
  Raylib.DrawRectangleV(earpos, earsize, r.color);

  (* draw body *)
  Raylib.DrawRectangleV(r.pos, r.size, r.color);
END DrawRabbit;


PROCEDURE Eat(VAR S:TSnake; VAR R:TRabbit);
VAR
X: REAL;
Y: REAL;
BEGIN
  IF (R.pos.x < S.pos.x+S.size.x) & (R.pos.x+R.size.x > S.pos.x) & (R.pos.y < S.pos.y+S.size.y) & (R.pos.y + R.size.y > S.pos.y ) THEN
    X:= Math.round(Raylib.GetRandomValue(0, Raylib.GetScreenWidth()-100) / 5.0) * 5.0;
    Y:= Math.round(Raylib.GetRandomValue(0, Raylib.GetScreenHeight()-100) / 5.0) * 5.0;
    R.pos.x := X+(R.size.x/2);
    R.pos.y := Y+(R.size.y/2);
    IF (S.len+1) < MaxTailLen THEN
      S.len := S.len + 1;
      (* Raylib.SetWindowSize(100, 200); *)
      (* Raylib.DrawText("Yow Win !", (Raylib.GetScreenWidth()/2 - 100), (Raylib.GetScreenHeight()/2), 50, Snake.color); *)
    END;
  END;
END Eat;

PROCEDURE isWinner():BOOLEAN;
BEGIN
    RETURN Snake.len = (MaxTailLen-1)
END isWinner;

PROCEDURE HandleControls(VAR s:TSnake);
VAR
  i:INTEGER;
BEGIN
      IF isWinner() THEN
        RETURN;
      END;

      IF (Raylib.IsKeyPressed(Raylib.KeyDown)) & (DeltaPos.y # -1.0*Velocity) THEN
        DeltaPos.x := 0.0; DeltaPos.y := 1.0*Velocity;
      ELSIF (Raylib.IsKeyPressed(Raylib.KeyUp)) & (DeltaPos.y # 1.0*Velocity) THEN
        DeltaPos.x := 0.0; DeltaPos.y := -1.0*Velocity;
      ELSIF (Raylib.IsKeyPressed(Raylib.KeyRight)) & (DeltaPos.x # -1.0*Velocity) THEN
        DeltaPos.x := 1.0*Velocity; DeltaPos.y := 0.0;
      ELSIF (Raylib.IsKeyPressed(Raylib.KeyLeft)) & (DeltaPos.x # 1.0 *Velocity) THEN
        DeltaPos.x := -1.0*Velocity; DeltaPos.y := 0.0;
      END;

      (* Tail *)
      FOR i := s.len TO 0 BY -1 DO
        IF i = 0 THEN
          s.tail[0] := s.pos;
        ELSE
          s.tail[i] := s.tail[i - 1];
        END;
      END;


      (* Head *)
      s.pos.x := s.pos.x + DeltaPos.x;
      s.pos.y := s.pos.y + DeltaPos.y;

      IF s.pos.x > Raylib.GetScreenWidth() THEN
        s.pos.x := 0
      ELSIF s.pos.x < 0 THEN
        s.pos.x := Raylib.GetScreenWidth();
      END;

      IF s.pos.y > Raylib.GetScreenHeight() THEN
        s.pos.y := 0;
      ELSIF s.pos.y < 0 THEN
        s.pos.y := Raylib.GetScreenHeight();
      END;
END HandleControls;


PROCEDURE Update*();
VAR
  scoreX: INTEGER;
  scoreY: INTEGER;
BEGIN
    scoreX := 0; scoreY := 0;
    Raylib.BeginDrawing();
    Raylib.ClearBackground(BgColor);
    IntToStr(Snake.len, Score);
    Raylib.DrawText(Score,scoreX,scoreY,30,Snake.color);
    HandleControls(Snake);
    DrawSnake(Snake);
    DrawRabbit(Rabbit);
    Eat(Snake, Rabbit);
    IF isWinner() THEN
      Raylib.DrawText("You Win!", (Raylib.GetScreenWidth() DIV 2) - 100, (Raylib.GetScreenHeight() DIV 2) - 0, 50, Snake.color);
    END;
    Raylib.EndDrawing();
END Update;



PROCEDURE Init*();
VAR
  addr: SYSTEM.ADDRESS;
BEGIN
  BgColor.r := 0X;
  BgColor.g := 0X;
  BgColor.b := 0X;
  BgColor.a := 0FFX;
  Velocity := 5;
  DeltaPos.x := 1 * Velocity;
  DeltaPos.y := 0;
  Raylib.SetRandomSeed(0FAAH);
  Raylib.InitWindow(800, 600, title);
  Raylib.SetTargetFPS(60);
  NewSnake(Snake);
  NewRabbit(Rabbit);

  (* go fullscreen with native resolution *)
  (* Raylib.ToggleFullscreen(); *)
END Init;


BEGIN
  Init();
  WHILE ~Raylib.WindowShouldClose() DO
    Update();
  END;

  Raylib.CloseWindow();

END Snake.
