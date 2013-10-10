MODULE ulmSYSTEM;
IMPORT SYSTEM(*, ulmObjects, ulmDisciplines, Console*);

  PROCEDURE TAS*(VAR flag:BOOLEAN): BOOLEAN; (* added for compatibility with ulmSYSTEM module; noch *)
  VAR oldflag : BOOLEAN;
  BEGIN
     oldflag := flag;
     flag := TRUE;
     RETURN oldflag;
  END TAS;

END ulmSYSTEM.
