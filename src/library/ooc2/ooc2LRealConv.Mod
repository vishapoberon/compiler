(* 	$Id: LRealConv.Mod,v 1.13 2003/04/06 12:11:15 mva Exp $	 *)
MODULE ooc2LRealConv;
(*  String to LONGREAL conversion functions.
    Copyright (C) 2002  Michael van Acken

    This module is free software; you can redistribute it and/or
    modify it under the terms of the GNU Lesser General Public License
    as published by the Free Software Foundation; either version 2 of
    the License, or (at your option) any later version.

    This module is distributed in the hope that it will be useful, but
    WITHOUT ANY WARRANTY; without even the implied warranty of
    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
    Lesser General Public License for more details.

    You should have received a copy of the GNU Lesser General Public
    License along with OOC. If not, write to the Free Software Foundation,
    59 Temple Place - Suite 330, Boston, MA 02111-1307, USA.
*)

IMPORT
  ConvTypes := ooc2ConvTypes, Real0 := ooc2Real0, Format := oocLRealConv;

(**

   The regular expression for a signed fixed-point real number is
   @samp{[+-]?\d+(\.\d* )?}.  For the optional exponent part, it is
   @samp{E[+-]?\d+}.
  
*)

TYPE
  ConvResults* = ConvTypes.ConvResults;
  (**One of @oconst{strAllRight}, @oconst{strOutOfRange},
     @oconst{strWrongFormat}, or @oconst{strEmpty}.  *)

CONST
  strAllRight*=ConvTypes.strAllRight;
  (**The string format is correct for the corresponding conversion.  *)
  strOutOfRange*=ConvTypes.strOutOfRange;
  (**The string is well-formed but the value cannot be represented.  *)
  strWrongFormat*=ConvTypes.strWrongFormat;
  (**The string is in the wrong format for the conversion.  *)
  strEmpty*=ConvTypes.strEmpty;
  (**The given string is empty.  *)

CONST
  maxValue = "17976931348623157";
  (* signifcant digits of the maximum value 1.7976931348623157D+308 *)
  maxExp = 308;
  (* maxium positive exponent of a normalized number *)
  
PROCEDURE ScanReal*(inputCh: CHAR;
                    VAR chClass: ConvTypes.ScanClass;
                    VAR nextState: ConvTypes.ScanState);
  BEGIN
    Real0.ScanReal (inputCh, chClass, nextState);
  END ScanReal;

PROCEDURE FormatReal* (str: ARRAY OF CHAR): ConvResults;
  BEGIN
    RETURN Real0.FormatReal (str, maxExp, maxValue);
  END FormatReal;
 
PROCEDURE ValueReal*(str: ARRAY OF CHAR): LONGREAL;
(* result is undefined if FormatReal(str) # strAllRight *)
  BEGIN
    RETURN Format.ValueReal(str)
  END ValueReal;

PROCEDURE LengthFloatReal*(real: LONGREAL; sigFigs: INTEGER): INTEGER;
  BEGIN
    RETURN Format.LengthFloatReal(real, sigFigs)
  END LengthFloatReal;
 
PROCEDURE LengthEngReal*(real: LONGREAL; sigFigs: INTEGER): INTEGER;
  BEGIN
    RETURN Format.LengthEngReal(real, sigFigs)
  END LengthEngReal;
 
PROCEDURE LengthFixedReal*(real: LONGREAL; place: INTEGER): INTEGER;
  BEGIN
    RETURN Format.LengthFixedReal(real, place)
  END LengthFixedReal;

END ooc2LRealConv.
