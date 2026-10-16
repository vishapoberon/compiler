MODULE strTypes;

CONST
  StrLen = 8192;

TYPE
   string* = ARRAY StrLen OF CHAR;
   strings* = POINTER TO ARRAY OF string;
   pstring* = POINTER TO ARRAY OF CHAR;
   pstrings* = POINTER TO ARRAY OF pstring;

   TObject* = POINTER TO TObjectDesc;
   TObjectDesc* = RECORD
   END;

END strTypes.

