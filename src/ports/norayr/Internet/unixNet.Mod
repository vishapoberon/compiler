MODULE unixNet;  (** voc: the Linux0 calls of polpo that Sockets and DNS use, through the C library *)

(* polpo's Sockets.Mod and DNS.Mod compile with this module, imported as Linux0 := unixNet (in polpo
   the kernel's own Linux0, so only the IMPORT line differs): the same names and
   parameters, negative Linux error numbers as results. Addresses are SYSTEM.ADDRESS here
   (64 bits on LP64), LONGINT in polpo. The socket constants of Sockets are those of Linux
   (MIPS excepted), so this is for voc on Linux. *)

IMPORT SYSTEM;

CONST
  ARCH* = "voc";
  ATFDCWD* = -100;
  ORDonly* = 0;
  SOLSOCKET = 1; SORCVTIMEO = 20; SOSNDTIMEO = 21;

PROCEDURE -AAincSocket "#include <sys/socket.h>";
PROCEDURE -AAincTime "#include <sys/time.h>";
PROCEDURE -AAincSelect "#include <sys/select.h>";
PROCEDURE -AAincUnistd "#include <unistd.h>";
PROCEDURE -AAincFcntl "#include <fcntl.h>";
PROCEDURE -AAincErrno "#include <errno.h>";
PROCEDURE -AAincSyscall "#include <sys/syscall.h>";

PROCEDURE -errno(): LONGINT "(LONGINT)errno";

PROCEDURE Res(r: LONGINT): LONGINT;
BEGIN
  IF r < 0 THEN RETURN -errno() END;
  RETURN r
END Res;

PROCEDURE -openat0(dirfd: LONGINT; name: SYSTEM.ADDRESS; flags, mode: LONGINT): LONGINT
  "(LONGINT)openat(dirfd, (char*)name, flags, mode)";
PROCEDURE -close0(fd: LONGINT): LONGINT "(LONGINT)close(fd)";
PROCEDURE -read0(fd: LONGINT; buf: SYSTEM.ADDRESS; num: LONGINT): LONGINT "(LONGINT)read(fd, (void*)buf, num)";
PROCEDURE -write0(fd: LONGINT; buf: SYSTEM.ADDRESS; num: LONGINT): LONGINT "(LONGINT)write(fd, (void*)buf, num)";
PROCEDURE -socket0(domain, type, protocol: LONGINT): LONGINT "(LONGINT)socket(domain, type, protocol)";
PROCEDURE -connect0(fd: LONGINT; addr: SYSTEM.ADDRESS; len: LONGINT): LONGINT
  "(LONGINT)connect(fd, (struct sockaddr*)addr, len)";
PROCEDURE -bind0(fd: LONGINT; addr: SYSTEM.ADDRESS; len: LONGINT): LONGINT
  "(LONGINT)bind(fd, (struct sockaddr*)addr, len)";
PROCEDURE -listen0(fd, backlog: LONGINT): LONGINT "(LONGINT)listen(fd, backlog)";
PROCEDURE -accept40(fd: LONGINT; addr, lenadr: SYSTEM.ADDRESS; flags: LONGINT): LONGINT
  "(LONGINT)syscall(SYS_accept4, fd, (void*)addr, (void*)lenadr, flags)";
PROCEDURE -getsockname0(fd: LONGINT; addr, lenadr: SYSTEM.ADDRESS): LONGINT
  "(LONGINT)getsockname(fd, (struct sockaddr*)addr, (socklen_t*)lenadr)";
PROCEDURE -getpeername0(fd: LONGINT; addr, lenadr: SYSTEM.ADDRESS): LONGINT
  "(LONGINT)getpeername(fd, (struct sockaddr*)addr, (socklen_t*)lenadr)";
PROCEDURE -setsockopt0(fd, level, name: LONGINT; val: SYSTEM.ADDRESS; len: LONGINT): LONGINT
  "(LONGINT)setsockopt(fd, level, name, (void*)val, len)";
PROCEDURE -settimeout0(fd, name: LONGINT; val: SYSTEM.ADDRESS): LONGINT
  "({struct timeval tv; tv.tv_sec = ((int*)val)[0]; tv.tv_usec = ((int*)val)[1]; (LONGINT)setsockopt(fd, SOL_SOCKET, name, &tv, sizeof tv);})";
PROCEDURE -getsockopt0(fd, level, name: LONGINT; val, lenadr: SYSTEM.ADDRESS): LONGINT
  "(LONGINT)getsockopt(fd, level, name, (void*)val, (socklen_t*)lenadr)";
PROCEDURE -shutdown0(fd, how: LONGINT): LONGINT "(LONGINT)shutdown(fd, how)";
PROCEDURE -sendto0(fd: LONGINT; buf: SYSTEM.ADDRESS; len, flags: LONGINT; addr: SYSTEM.ADDRESS; addrlen: LONGINT): LONGINT
  "(LONGINT)sendto(fd, (void*)buf, len, flags, (struct sockaddr*)addr, addrlen)";
PROCEDURE -recvfrom0(fd: LONGINT; buf: SYSTEM.ADDRESS; len, flags: LONGINT; addr, lenadr: SYSTEM.ADDRESS): LONGINT
  "(LONGINT)recvfrom(fd, (void*)buf, len, flags, (struct sockaddr*)addr, (socklen_t*)lenadr)";

PROCEDURE -select0(n: LONGINT; r, w, e, tv: SYSTEM.ADDRESS): LONGINT
  "({struct timeval t, *p = 0; if (tv) {t.tv_sec = ((int*)tv)[0]; t.tv_usec = ((int*)tv)[1]; p = &t;} (LONGINT)select(n, (fd_set*)r, (fd_set*)w, (fd_set*)e, p);})";
PROCEDURE -gettimeofday0(tv: SYSTEM.ADDRESS): LONGINT
  "({struct timeval t; int r = gettimeofday(&t, 0); ((int*)tv)[0] = (int)t.tv_sec; ((int*)tv)[1] = (int)t.tv_usec; (LONGINT)r;})";

(** seconds and microseconds since 1970 as two 32 bit numbers at tv, as in polpo; tz is ignored *)
PROCEDURE GetTimeOfDay*(tv: SYSTEM.ADDRESS; tz: LONGINT): LONGINT;
BEGIN RETURN Res(gettimeofday0(tv))
END GetTimeOfDay;

(** select(2); the descriptor sets are bit arrays (descriptor k: bit k MOD 8 of byte k DIV 8), the
  timeout is two 32 bit numbers (seconds, microseconds) as in polpo, or 0 to wait without end *)
PROCEDURE Select0*(n: LONGINT; readfds, writefds, exceptfds, timeout: SYSTEM.ADDRESS): LONGINT;
BEGIN RETURN Res(select0(n, readfds, writefds, exceptfds, timeout))
END Select0;

PROCEDURE Openat0*(dirfd: LONGINT; name: SYSTEM.ADDRESS; flags, mode: LONGINT): LONGINT;
BEGIN RETURN Res(openat0(dirfd, name, flags, mode))
END Openat0;

PROCEDURE Close0*(fd: LONGINT): LONGINT;
BEGIN RETURN Res(close0(fd))
END Close0;

PROCEDURE Read0*(fd: LONGINT; buf: SYSTEM.ADDRESS; num: LONGINT): LONGINT;
BEGIN RETURN Res(read0(fd, buf, num))
END Read0;

PROCEDURE Write0*(fd: LONGINT; buf: SYSTEM.ADDRESS; num: LONGINT): LONGINT;
BEGIN RETURN Res(write0(fd, buf, num))
END Write0;

PROCEDURE Socket0*(domain, type, protocol: LONGINT): LONGINT;
BEGIN RETURN Res(socket0(domain, type, protocol))
END Socket0;

PROCEDURE Connect0*(fd: LONGINT; addr: SYSTEM.ADDRESS; len: LONGINT): LONGINT;
BEGIN RETURN Res(connect0(fd, addr, len))
END Connect0;

PROCEDURE Bind0*(fd: LONGINT; addr: SYSTEM.ADDRESS; len: LONGINT): LONGINT;
BEGIN RETURN Res(bind0(fd, addr, len))
END Bind0;

PROCEDURE Listen0*(fd, backlog: LONGINT): LONGINT;
BEGIN RETURN Res(listen0(fd, backlog))
END Listen0;

PROCEDURE Accept40*(fd: LONGINT; addr, lenadr: SYSTEM.ADDRESS; flags: LONGINT): LONGINT;
BEGIN RETURN Res(accept40(fd, addr, lenadr, flags))
END Accept40;

PROCEDURE GetSockName0*(fd: LONGINT; addr, lenadr: SYSTEM.ADDRESS): LONGINT;
BEGIN RETURN Res(getsockname0(fd, addr, lenadr))
END GetSockName0;

PROCEDURE GetPeerName0*(fd: LONGINT; addr, lenadr: SYSTEM.ADDRESS): LONGINT;
BEGIN RETURN Res(getpeername0(fd, addr, lenadr))
END GetPeerName0;

(** a struct timeval for SO_RCVTIMEO or SO_SNDTIMEO comes as two 32 bit numbers, as in polpo,
  and is widened to the struct timeval of the machine here *)
PROCEDURE SetSockOpt0*(fd, level, name: LONGINT; val: SYSTEM.ADDRESS; len: LONGINT): LONGINT;
BEGIN
  IF (level = SOLSOCKET) & ((name = SORCVTIMEO) OR (name = SOSNDTIMEO)) & (len = 8) THEN
    RETURN Res(settimeout0(fd, name, val))
  END;
  RETURN Res(setsockopt0(fd, level, name, val, len))
END SetSockOpt0;

PROCEDURE GetSockOpt0*(fd, level, name: LONGINT; val, lenadr: SYSTEM.ADDRESS): LONGINT;
BEGIN RETURN Res(getsockopt0(fd, level, name, val, lenadr))
END GetSockOpt0;

PROCEDURE Shutdown0*(fd, how: LONGINT): LONGINT;
BEGIN RETURN Res(shutdown0(fd, how))
END Shutdown0;

PROCEDURE SendTo0*(fd: LONGINT; buf: SYSTEM.ADDRESS; len, flags: LONGINT; addr: SYSTEM.ADDRESS; addrlen: LONGINT): LONGINT;
BEGIN RETURN Res(sendto0(fd, buf, len, flags, addr, addrlen))
END SendTo0;

PROCEDURE RecvFrom0*(fd: LONGINT; buf: SYSTEM.ADDRESS; len, flags: LONGINT; addr, lenadr: SYSTEM.ADDRESS): LONGINT;
BEGIN RETURN Res(recvfrom0(fd, buf, len, flags, addr, lenadr))
END RecvFrom0;

END unixNet.
