
vishap oberon compiler
======================

How to install
==============

just cd into source directory and type

>make -f makefile.linux.gcc.x86_64

if you are on linux x86_64 system and you want voc to use gcc as backend.

otherwise use corresponding makefile.

then type

>sudo make install

- or see COMPILE file.

How to use
==========

Type voc and it'll show you help.

voc -M will compile your module and link it statically to libVishapOberon.
voc -m will link the module dynamically.

If you have more than one module, and you want them to be compiled into elf filethen:
Let's assume we have module M0 which imports M1;

>voc -l M1.Mod -s M0.Mod -M

Here -l is a global option.
Module M1 will be compiled with -s option, i. e. sym file will be generated.

Module M0 will be compiled and linked statically.

In case you have modules in different directories, like "ui", "logic", "math", then you need to export MODULES environment variable like this:

>export MODULES=".:ui:logic:math"

and after call voc

>voc -s ui0.Mod

Otherwise you can use full path:

>voc -s ui/ui0.Mod

build rpm
=========

if you'd like to build an rpm installer, then

* compress sources as voc-1.0.src.tar.bz2  
  assuming you in voc directory
> cd ..
> tar -jcvpf voc-1.0.src.tar.bz2 voc
* put them to ~/rpmbuild/SOURCES (on some systems as root to /usr/src/redhat/SOURCES/) or other similar location.  
> mkdir -p ~/rpmbuild/SOURCES  
> cp voc-1.0.src.tar.bz2 ~/rpmbuild/SOURCES  
* cd to voc directory and run  
> rpmbuild -ba voc.spec

this should create voc rpm installers.
