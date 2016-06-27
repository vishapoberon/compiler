The following Oberon types are independent of compiler size:

| Types          | Size   |
| -----          | -------|
| CHAR, SHORTINT | 8 bit  |
| REAL           | 32 bit |
| LONGREAL       | 64 bit |

The following type sizes follow the built compiler size:

| Types          | 32 bit builds | 64 bit builds |
| -----          | ------------- | ------------- |
| INTEGER        | 16 bit        | 32 bit        |
| LONGINT, SET   | 32 bit        | 16 bit        |

HALT/exit code has been simplified. Exit now just calls the system exit API rather than calling the kill API and passing our own process ID. For runtime errors it now displayes the appropriate error message (e.g. Index out of range).

Compilation errors now include the line number at the start of the displayed source line. The pos (character offset) is still displayed on the error message line. The error handling code was already doing some walking of the source file to find start and end of line - I changed this to walk through the source file from the start identifying line end positions, counting lines and caching the position at the start of the last error line. The resultant code is simpler, and displays the line number without losing the pos. The performance cost of walking the source file is not an issue.


 - In his latest specs (around 2013) Wirth removed the 'COPY(a, b)' character array copy procedure, replacing it with 'b := a'. I have accordingly enabled 'b := a' in voc as an alternative to 'COPY(a, b)' (COPY is still supported.).

 - Oberon code often writes to Oberon.Log expecting the text to appear on the screen. While voc has an Oberon.DumpLog procedure, I looked into making the behaviour automatic. Interestingly the voc source declares the Text notifier constants replace, insert and delete, but omits implementation of the notifier calls. The implementation turned out to be very little code, and I have used it to echo all text written to Oberon.Log to the console. This has the advantage over DumpLog that text is written immediately rather than only when DumpLog is called, and allows existing program source to work unchanged.
