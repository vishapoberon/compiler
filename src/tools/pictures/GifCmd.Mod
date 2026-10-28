MODULE GifCmd;
IMPORT Args, A := PictureArgs, P := gif;
VAR command: ARRAY 32 OF CHAR;
BEGIN
  Args.Get(1, command); A.Start(2);
  IF command = "Info" THEN P.Info
  ELSIF command = "ToPPM" THEN P.ToPPM
  ELSIF command = "ToPAM" THEN P.ToPAM
  ELSIF command = "FromPNM" THEN P.FromPNM
  ELSIF command = "Copy" THEN P.Copy
  ELSE P.Help
  END
END GifCmd.
