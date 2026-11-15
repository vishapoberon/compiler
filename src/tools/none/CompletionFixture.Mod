MODULE CompletionFixture;

CONST Answer* = 42;
TYPE Item* = RECORD field*: INTEGER END;
VAR Counter*: INTEGER; ReadOnly-: INTEGER;

PROCEDURE Alpha*; BEGIN END Alpha;
PROCEDURE Beta*; BEGIN END Beta;
PROCEDURE Delta*; BEGIN END Delta;
PROCEDURE Epsilon*; BEGIN END Epsilon;
PROCEDURE Eta*; BEGIN END Eta;
PROCEDURE Gamma*; BEGIN END Gamma;
PROCEDURE Iota*; BEGIN END Iota;
PROCEDURE Kappa*; BEGIN END Kappa;
PROCEDURE Lambda*; BEGIN END Lambda;
PROCEDURE Swap*(VAR left, right: INTEGER);
VAR temp: INTEGER;
BEGIN temp := left; left := right; right := temp
END Swap;
PROCEDURE Value*(): INTEGER; BEGIN RETURN 42 END Value;
PROCEDURE private; BEGIN END private;

(* Completion reads the symbol file without running the initializer. *)
BEGIN HALT(99)
END CompletionFixture.
