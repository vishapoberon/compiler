MODULE TestServerInit;
IMPORT server, Out, SYSTEM;

PROCEDURE -IncludeUnistd "#include <unistd.h>";
PROCEDURE -IncludeWait "#include <sys/wait.h>";
PROCEDURE -ChildCanBeWaited(): BOOLEAN
  "({pid_t pid=fork(); int status; if(pid==0) _exit(0); pid>0 && waitpid(pid,&status,0)==pid;})";

BEGIN
  (* Importing server must preserve the host's ability to wait for children. *)
  ASSERT(ChildCanBeWaited());
  Out.String('server import preserves child waiting'); Out.Ln
END TestServerInit.
