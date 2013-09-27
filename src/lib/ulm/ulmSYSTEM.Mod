MODULE ulmSYSTEM;
IMPORT SYSTEM(*, ulmObjects, ulmDisciplines, Console*);


(* test *)
(*
VAR d0, d1 : ulmDisciplines.Discipline;
*)

   (* noch *)
(*   PROCEDURE -getaddr*(obj: ulmObjects.Object): LONGINT
   "(LONGINT)&obj";*)
(*
   PROCEDURE -assignObjectPointers* (VAR src,  dst : ulmObjects.Object)
   "*dst=*src";

   PROCEDURE assignObjectPointer*(src, dst : ulmObjects.Object);
   BEGIN
      assignObjectPointers(src, dst);
   END assignObjectPointer;

   PROCEDURE assignDisciplinePointer (src, dst : ulmDisciplines.Discipline);
   BEGIN
    assignObjectPointers(src, dst);
   END assignDisciplinePointer;
*)
  PROCEDURE TAS*(VAR flag:BOOLEAN): BOOLEAN; (* added for compatibility with ulmSYSTEM module; noch *)
  VAR oldflag : BOOLEAN;
  BEGIN
     oldflag := flag;
     flag := TRUE;
     RETURN oldflag;
  END TAS;


(*
BEGIN
NEW (d0);
NEW (d1);


d0.id := 0;
d1.id := 1;
Console.String ("d0.id=");Console.Int (d0.id, 0); Console.Ln;
Console.String ("d1.id=");Console.Int (d1.id, 0); Console.Ln;
(*
assignDisciplinePointer(d0, d1);
*)
Console.String ("d0.id=");Console.Int (d0.id, 0); Console.Ln;
Console.String ("d1.id=");Console.Int (d1.id, 0); Console.Ln;


*)
END ulmSYSTEM.
