MODULE TestCommandNative;
  (* The signal callback is compiled without modular instrumentation: only
     sig_atomic_t access is safe there. NativeCallback deliberately exercises
     a native-to-Oberon callback under the caller's cancellation guard. *)
  IMPORT SYSTEM, Platform;
  TYPE Handler = PROCEDURE(signal: SYSTEM.INT32);
  VAR nativeReturned-: BOOLEAN;
    previousAction, previousMask, listenerAddress: SYSTEM.ADDRESS;
    interrupter: SYSTEM.INT32;

  PROCEDURE -A0Feature '#ifndef _POSIX_C_SOURCE';
  PROCEDURE -A0Feature1 '#define _POSIX_C_SOURCE 200809L';
  PROCEDURE -A0Feature2 '#endif';
  PROCEDURE -AInclude '#include <errno.h>';
  PROCEDURE -AIncludeSignal* '#include <signal.h>';
  PROCEDURE -AInclude1* '#include <sys/socket.h>';
  PROCEDURE -AInclude2 '#include <sys/wait.h>';
  PROCEDURE -AInclude3 '#include <netinet/in.h>';
  PROCEDURE -AInclude4 '#include <time.h>';
  PROCEDURE -AInclude5* '#include <unistd.h>';
  PROCEDURE -AInclude6 '#include <string.h>';
  PROCEDURE -counterBuffer 'static volatile sig_atomic_t counter';
  PROCEDURE -increment '++counter';
  PROCEDURE -signals(): SYSTEM.INT32 'counter';
  PROCEDURE -reset 'counter = 0';
  PROCEDURE -Interrupt* 'raise(SIGINT)';
  PROCEDURE -NativeCallback*(callback: Platform.Command)
    '(TestCommandNative_nativeReturned = 0, raise(SIGINT), callback(), TestCommandNative_nativeReturned = 1)';
  PROCEDURE -InterruptingCondition*(): BOOLEAN '(raise(SIGINT), 1)';
  PROCEDURE -actionSize(): SYSTEM.ADDRESS 'sizeof(struct sigaction)';
  PROCEDURE -maskSize(): SYSTEM.ADDRESS 'sizeof(sigset_t)';
  PROCEDURE -addressSize(): SYSTEM.ADDRESS 'sizeof(struct sockaddr_in)';
  PROCEDURE -actionBuffer 'struct sigaction action = {0}';
  PROCEDURE -install(handler: Handler; previous: SYSTEM.ADDRESS): SYSTEM.INT32
    '(action.sa_handler = handler, sigemptyset(&action.sa_mask), sigaction(SIGINT, &action, (struct sigaction*)previous))';
  PROCEDURE -restore(previous: SYSTEM.ADDRESS): SYSTEM.INT32 'sigaction(SIGINT, (struct sigaction*)previous, NULL)';
  PROCEDURE -pid(): SYSTEM.INT32 'getpid()';
  PROCEDURE -fork(): SYSTEM.INT32 'fork()';
  PROCEDURE -sleepBuffer 'struct timespec delay = {0, 50000000}';
  PROCEDURE -sleep(): SYSTEM.INT32 'nanosleep(&delay, &delay)';
  PROCEDURE -interrupted(): BOOLEAN 'errno == EINTR';
  PROCEDURE -kill(parent: SYSTEM.INT32): SYSTEM.INT32 'kill(parent, SIGINT)';
  PROCEDURE -exit(code: SYSTEM.INT32) '_exit(code)';
  PROCEDURE -wait(child: SYSTEM.INT32; VAR status: SYSTEM.INT32): SYSTEM.INT32 'waitpid(child, status, 0)';
  PROCEDURE -exited(status: SYSTEM.INT32): BOOLEAN 'WIFEXITED(status) && WEXITSTATUS(status) == 0';
  PROCEDURE -socket(): SYSTEM.INT32 'socket(AF_INET, SOCK_STREAM, 0)';
  PROCEDURE -clear(address: SYSTEM.ADDRESS) 'memset((void*)address, 0, sizeof(struct sockaddr_in))';
  PROCEDURE -family(address: SYSTEM.ADDRESS) '((struct sockaddr_in*)address)->sin_family = AF_INET';
  PROCEDURE -loopback(address: SYSTEM.ADDRESS) '((struct sockaddr_in*)address)->sin_addr.s_addr = htonl(INADDR_LOOPBACK)';
  PROCEDURE -bind(fd: SYSTEM.INT32; address: SYSTEM.ADDRESS): SYSTEM.INT32
    'bind(fd, (struct sockaddr*)address, sizeof(struct sockaddr_in))';
  PROCEDURE -lengthBuffer 'socklen_t length = sizeof(struct sockaddr_in)';
  PROCEDURE -sockname(fd: SYSTEM.INT32; address: SYSTEM.ADDRESS): SYSTEM.INT32
    'getsockname(fd, (struct sockaddr*)address, &length)';
  PROCEDURE -listen(fd: SYSTEM.INT32): SYSTEM.INT32 'listen(fd, 1)';
  PROCEDURE -Accept*(fd: SYSTEM.INT32): SYSTEM.INT32 'accept(fd, NULL, NULL)';
  PROCEDURE -Close*(fd: SYSTEM.INT32) 'close(fd)';
  PROCEDURE -maskBuffer 'sigset_t interrupt';
  PROCEDURE -interruptMask 'sigemptyset(&interrupt); sigaddset(&interrupt, SIGINT)';
  PROCEDURE -block(previous: SYSTEM.ADDRESS): SYSTEM.INT32 'sigprocmask(SIG_BLOCK, &interrupt, (sigset_t*)previous)';
  PROCEDURE -restoreMask(previous: SYSTEM.ADDRESS): SYSTEM.INT32 'sigprocmask(SIG_SETMASK, (sigset_t*)previous, NULL)';

  PROCEDURE Counter(operation: INTEGER): SYSTEM.INT32;
  BEGIN
    counterBuffer;
    IF operation = 1 THEN increment ELSIF operation = 0 THEN reset END;
    RETURN signals()
  END Counter;

  PROCEDURE PreviousInterrupt(signal: SYSTEM.INT32);
    VAR ignored: SYSTEM.INT32;
  BEGIN ignored := Counter(1) END PreviousInterrupt;

  PROCEDURE NativeReturned*(): BOOLEAN;
  BEGIN RETURN nativeReturned END NativeReturned;

  PROCEDURE PreviousSignals*(): SYSTEM.INT32;
  BEGIN RETURN Counter(-1) END PreviousSignals;

  PROCEDURE SignalHandler*(enabled: BOOLEAN);
    VAR ignored: SYSTEM.INT32;
  BEGIN
    actionBuffer;
    IF enabled THEN
      previousAction := Platform.OSAllocate(actionSize()); ASSERT(previousAction # 0);
      ignored := Counter(0); ASSERT(install(PreviousInterrupt, previousAction) = 0)
    ELSE
      ASSERT(restore(previousAction) = 0);
      Platform.OSFree(previousAction); previousAction := 0;
      IF listenerAddress # 0 THEN Platform.OSFree(listenerAddress); listenerAddress := 0 END
    END
  END SignalHandler;

  PROCEDURE StartInterrupt*(): BOOLEAN;
    VAR parent: SYSTEM.INT32;
  BEGIN
    parent := pid(); interrupter := fork();
    IF interrupter = 0 THEN
      sleepBuffer;
      WHILE (sleep() < 0) & interrupted() DO END;
      IF kill(parent) < 0 THEN exit(1) ELSE exit(0) END
    END;
    RETURN interrupter > 0
  END StartInterrupt;

  PROCEDURE WaitInterrupt*(): BOOLEAN;
    VAR result, status: SYSTEM.INT32;
  BEGIN
    REPEAT result := wait(interrupter, status) UNTIL (result >= 0) OR ~interrupted();
    interrupter := -1; RETURN (result > 0) & exited(status)
  END WaitInterrupt;

  PROCEDURE Listen*(): SYSTEM.INT32;
    VAR fd: SYSTEM.INT32;
  BEGIN
    lengthBuffer;
    IF listenerAddress = 0 THEN listenerAddress := Platform.OSAllocate(addressSize()) END;
    IF listenerAddress = 0 THEN RETURN -1 END;
    clear(listenerAddress); family(listenerAddress); loopback(listenerAddress);
    fd := socket(); IF fd < 0 THEN RETURN -1 END;
    IF (bind(fd, listenerAddress) < 0) OR (sockname(fd, listenerAddress) < 0) OR (listen(fd) < 0) THEN
      Close(fd); RETURN -1
    END;
    RETURN fd
  END Listen;

  PROCEDURE ListenerClosed*(): BOOLEAN;
    VAR fd, result: SYSTEM.INT32;
  BEGIN
    fd := socket(); IF fd < 0 THEN RETURN FALSE END;
    result := bind(fd, listenerAddress); Close(fd); RETURN result = 0
  END ListenerClosed;

  PROCEDURE BlockInterrupt*(enabled: BOOLEAN);
  BEGIN
    maskBuffer;
    IF enabled THEN
      previousMask := Platform.OSAllocate(maskSize()); ASSERT(previousMask # 0);
      interruptMask; ASSERT(block(previousMask) = 0)
    ELSE
      ASSERT(restoreMask(previousMask) = 0); Platform.OSFree(previousMask); previousMask := 0
    END
  END BlockInterrupt;

BEGIN interrupter := -1
END TestCommandNative.
