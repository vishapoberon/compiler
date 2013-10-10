voc
===

vishap oberon compiler

How to install - see COMPILE file.

How to use:

Type voc and it'll show you help.

voc -M will compile your module and link it statically to libVishapOberon.
voc -m will link the module dynamically.

If you have more than one module, and you want them to be compiled into elf filethen:
Let's assume we have module M0 which imports M1;

voc -l M1.Mod -s M0.Mod -M

Here -l is a global option.
Module M1 will be compiled with -s option, i. e. sym file will be generated.

Module M0 will be compiled and linked statically.

In case you have modules in different directories, like "ui", "logic", "math", then you need to export MODULES environment variable like this:

export MODULES=".:ui:logic:math"

and after call voc

voc -s ui0.Mod

Otherwise you can use full path:

voc -s ui/ui0.Mod
