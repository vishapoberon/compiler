
RISC crosscompiler
==================

This is a version of re re revised Oberon compiler for Wirth's RISC machine which can be compiled and run with VOC (Vishap Oberon Compiler) on supported platforms.

Files generated can be transferred to RISC machine or emulator and be run there.

Compile
=======

If you have vishap oberon compiler installed, just type  
>make

Run
===

>./ORP test.Mod /s

like that.

you may need symbol (.smb) files from RISC Oberon system in order to write programs that import some modules.

some answers
============

- why Oberon10.Scn.Fnt ?
- it's actually not really necessary. because Texts are patched (test for NIL) to not crash if this file does not exist. however, unless I remove dependency from Fonts.Mod I have decided to keep this file here, and thus my added test for NIL is not necessary, and generated output file is completely correct Oberon Text file. Otherwise it would not contain the font name, for instance.

