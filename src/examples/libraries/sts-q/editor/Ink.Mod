MODULE Ink;   (* :file: Ink.Mod  --  Color names and codes. *)
(* VOC adaptation, 2026-10-16: avoid the existing Ulm Sys module. *)
IMPORT Sys := ssqSys;


CONST
        YELLOW*     =  "240;200;100";
        LIGHTGRAY*  =  "128;128;128";
        GRAY*       =  "96;96;96";
        STRAW*      =  "255;160;70";
        OLIVE*      =  "128;128;0";
        RED*        =  "255;0;0";
        WHITE*      =  "255;255;255";
        SANDY*      =  "255;200;170";
        SKY*        =  "80;128;230";
        PINK*       =  "255;60;170";
        STD*        =  WHITE;

        BLACKBG*   =  "0;0;0";
        DARKERBG*  =  "16;16;16";
        DARKBG*    =  "32;32;32";
        GRAYBG*    =  "48;48;48";
        OLIVEBG*   =  "100;100;32";
        ROSEBG*    =  "200;150;170";
        SANDYBG*   =  "255;200;170";
        STDBG*     =  DARKERBG;


END Ink.   :file: (c) sts-q 2021-Aug  2022-Feb,Nov  2024-Feb
