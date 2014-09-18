

compiler does show only character position, not the line number
===============================================================

Yes, by default it shows you the character position, because it's faster to go to character position in vim
:goto number

In case you still want to use line numbers then pass -l option to voc

voc -ls m.Mod

compilation crashes on ARM or Raspberry Pi with recent (like 3.12) kernels.
===========================================================================

> echo 1 > /proc/sys/vm/legacy_va_layout

should fix that.

