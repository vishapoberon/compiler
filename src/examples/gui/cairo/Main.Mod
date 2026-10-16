MODULE Main;
IMPORT MathL, Cairo;

TYPE POSITION = RECORD
    X, Y: REAL;
END;

TYPE RGB = RECORD
    Red, Green, Blue: REAL;
END;

TYPE BODY = RECORD
    Name: ARRAY 10 OF CHAR;
    Radius: REAL;
    Color: RGB;
    Position, LabelPosition: POSITION;
END;

VAR
    c: Cairo.Context;
    s: Cairo.Surface;
    i, j, n: INTEGER;
    status: Cairo.StatusType;
    body: ARRAY 6 OF BODY;
    color: RGB;
    position: POSITION;
    workspace: REAL;
    scale: INTEGER;

BEGIN
    workspace := 10.0;
    scale := 600;

    (* Earth *)
    color.Red := 0.4;
    color.Green := 0.4;
    color.Blue := 1.0;
    position.X := 0.15;
    position.Y := 0.75;
    body[n].Name := "Earth";
    body[n].Radius := 1.0;
    body[n].Color := color;
    body[n].Position := position;
    position.X := position.X - 0.06;
    position.Y := position.Y + 0.15;
    body[n].LabelPosition := position;

    (* Moon *)
    INC(n);
    color.Red := 0.9;
    color.Green := 0.9;
    color.Blue := 0.9;
    position.X := 0.45;
    position.Y := 0.75;
    body[n].Name := "Moon";
    body[n].Radius := 0.2727; (* https://en.wikipedia.org/wiki/Moon *)
    body[n].Color := color;
    body[n].Position := position;
    position.X := position.X - 0.06;
    position.Y := position.Y + 0.075;
    body[n].LabelPosition := position;

    (* Uranus *)
    INC(n);
    color.Red := 0.7;
    color.Green := 0.7;
    color.Blue := 1.0;
    position.X := 0.15;
    position.Y := 0.15;
    body[n].Name := "Uranus";
    body[n].Radius := 4.007; (* https://en.wikipedia.org/wiki/Uranus *)
    body[n].Color := color;
    body[n].Position := position;
    body[n].LabelPosition := position;

    (* Oberon *)
    INC(n);
    color.Red := 0.9;
    color.Green := 0.9;
    color.Blue := 1.0;
    position.X := 0.7;
    position.Y := 0.05;
    body[n].Name := "Oberon";
    body[n].Radius := 0.1194; (* https://en.wikipedia.org/wiki/Oberon_(moon) *)
    body[n].Color := color;
    body[n].Position := position;
    position.X := position.X - 0.07;
    position.Y := position.Y + 0.06;
    body[n].LabelPosition := position;

    (* Mars *)
    INC(n);
    color.Red := 0.7;
    color.Green := 0.2;
    color.Blue := 0.1;
    position.X := 0.6;
    position.Y := 0.35;
    body[n].Name := "Mars";
    body[n].Radius := 0.533; (* https://en.wikipedia.org/wiki/Mars *)
    body[n].Color := color;
    body[n].Position := position;
    position.X := position.X - 0.05;
    position.Y := position.Y + 0.1;
    body[n].LabelPosition := position;

    (* Jupiter *)
    INC(n);
    color.Red := 1.0;
    color.Green := 0.5;
    color.Blue := 0.2;
    position.X := 1.7;
    position.Y := 1.0;
    body[n].Name := "Jupiter";
    body[n].Radius := 10.973; (* https://en.wikipedia.org/wiki/Jupiter *)
    body[n].Color := color;
    body[n].Position := position;
    position.X := 0.75;
    position.Y := 0.7;
    body[n].LabelPosition := position;

    (* Initialize *)
    s := Cairo.ImageSurfaceCreate(Cairo.FARGB32, scale, scale);
    c := Cairo.Create(s);
    Cairo.Scale(c, scale, scale);

    (* Background *)
    Cairo.SetSourceRGB(c, 0.05, 0.05, 0.05);
    Cairo.Paint(c);
    Cairo.SetLineWidth(c, 0.004);

    (* Grid *)
    FOR i := 0 TO 9 DO
        FOR j := 0 TO 9 DO
            Cairo.Rectangle(c, i*0.1, j*0.1, 0.1, 0.1);
        END;
    END;
    Cairo.SetSourceRGB(c, 0.1, 0.1, 0.1);
    Cairo.Stroke(c);

    (* Bodies *)
    FOR i := 0 TO n DO
        Cairo.Arc(c, body[i].Position.X, body[i].Position.Y, body[i].Radius/workspace, 0.0, 2*MathL.pi);
        Cairo.SetSourceRGB(c, body[i].Color.Red, body[i].Color.Green, body[i].Color.Blue);
        Cairo.Fill(c);
    END;

    (* Font set-up *)
    Cairo.SelectFontFace(c, "Bitstream Charter", Cairo.FSNORMAL, Cairo.FWNORMAL);
    Cairo.SetFontSize(c, 30.0/scale);
    Cairo.SetSourceRGB(c, 1.0, 1.0, 1.0);

    (* Labels *)
    FOR i := 0 TO n DO
        Cairo.MoveTo(c, body[i].LabelPosition.X, body[i].LabelPosition.Y);
        Cairo.ShowText(c, body[i].Name);
        Cairo.Stroke(c);
    END;

    (* Write PNG To Disk *)
    status := Cairo.SurfaceWriteToPNG(s, "oberon.png");

    (* Destroy *)
    Cairo.Destroy(c);
    Cairo.SurfaceDestroy(s);

END Main.