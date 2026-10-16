MODULE netForker;
IMPORT SYSTEM;

PROCEDURE -A000 "#include <unistd.h>";
PROCEDURE -fork*(): LONGINT "(LONGINT)fork()";


END netForker.
