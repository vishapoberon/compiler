(* Ulm's Oberon Library
   Copyright (C) 1989-1994 by University of Ulm, SAI, D-89069 Ulm, Germany
   ----------------------------------------------------------------------------
   Ulm's Oberon Library is free software; you can redistribute it
   and/or modify it under the terms of the GNU Library General Public
   License as published by the Free Software Foundation; either version
   2 of the License, or (at your option) any later version.

   Ulm's Oberon Library is distributed in the hope that it will be
   useful, but WITHOUT ANY WARRANTY; without even the implied warranty
   of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
   Library General Public License for more details.

   You should have received a copy of the GNU Library General Public
   License along with this library; if not, write to the Free Software
   Foundation, Inc., 675 Mass Ave, Cambridge, MA 02139, USA.
   ----------------------------------------------------------------------------
   E-mail contact: oberon@mathematik.uni-ulm.de
   ----------------------------------------------------------------------------
   $Id: SysIO.om,v 1.1 1994/02/23 07:59:15 borchert Exp $
   ----------------------------------------------------------------------------
   $Log: SysIO.om,v $
   Revision 1.1  1994/02/23  07:59:15  borchert
   Initial revision

   ----------------------------------------------------------------------------
   AFB 6/89
   ----------------------------------------------------------------------------
*)

MODULE ulmSysIO;

   IMPORT RelatedEvents := ulmRelatedEvents, Sys := ulmSys, SYS := SYSTEM, ulmSYSTEM, SysErrors := ulmSysErrors, SysTypes := ulmSysTypes;

   CONST
      (* file control options: arguments of Fcntl and Open *)
      rdonly* = {};
      wronly* = { 0 };
      rdwr* = { 1 };
      append* = { 10 };
      ndelay* = { 11 }; (* O_NONBLOCK that works like former O_NDELAY *)
      creat* = { 6 };
      trunc* = { 9 };
      excl* = { 7 };
      noctty* = { 8 };
      sync* = { 12 };
      fasync* = { 13 };
      direct* = { 14 };
      largefile* = { 15 };
      directory* = { 16 };
      nofollow* = { 17 };

      (* Whence = (fromStart, fromPos, fromEnd); *)
      fromStart* = 0;
      fromPos* = 1;
      fromEnd* = 2;

      (* file descriptor flags *)
      closeonexec* = { 0 };

      (* Fcntl requests *)
      dupfd* = 0;	(* duplicate file descriptor *)
      getfd* = 1;	(* get file desc flags (close-on-exec) *)
      setfd* = 2;	(* set file desc flags (close-on-exec) *)
      getfl* = 3;	(* get file flags *)
      setfl* = 4;	(* set file flags (ndelay, append) *)
      getlk* = 5;	(* get file lock *)
      setlk* = 6;	(* set file lock *)
      setlkw* = 7;	(* set file lock and wait *)
      setown* = 8;       (* set owner (async IO) *)
      getown* = 9;       (* get owner (async IO) *)
      setsig* = 10;      (* set SIGIO replacement *)
      getsig* = 11;      (* get SIGIO replacement *)

   TYPE
      File* = SysTypes.File; (* file descriptor *)
      Address* = SysTypes.Address;
      Count* = SysTypes.Count;
      Protection* = LONGINT;
      Whence* = LONGINT;

   PROCEDURE OpenCreat*(VAR fd: File;
		       filename: ARRAY OF CHAR; options: SET;
		       protection: Protection;
		       errors: RelatedEvents.Object;
		       retry: BOOLEAN; VAR interrupted: BOOLEAN) : BOOLEAN;
      (* the filename must be 0X-terminated *)
      VAR
	 d0, d1: (*INTEGER*)LONGINT;
   BEGIN
      interrupted := FALSE;
      LOOP
	 IF ulmSYSTEM.UNIXCALL(Sys.open, d0, d1,
			 SYS.ADR(filename), SYS.VAL(LONGINT, options), protection) THEN
	    fd := d0;
	    RETURN TRUE
	 ELSE
	    IF d0 = SysErrors.intr THEN
	       interrupted := TRUE;
	    END;
	    IF (d0 # SysErrors.intr) OR ~retry THEN
	       SysErrors.Raise(errors, d0, Sys.open, filename);
	       RETURN FALSE
	    END;
	 END;
      END;
   END OpenCreat;

   PROCEDURE Open*(VAR fd: File;
		  filename: ARRAY OF CHAR; options: SET;
		  errors: RelatedEvents.Object;
		  retry: BOOLEAN; VAR interrupted: BOOLEAN) : BOOLEAN;
      (* the filename must be 0X-terminated *)
   BEGIN
      RETURN OpenCreat(fd, filename, options, 0, errors, retry, interrupted)
   END Open;

   PROCEDURE Close*(fd: File;
		   errors: RelatedEvents.Object;
		   retry: BOOLEAN; VAR interrupted: BOOLEAN) : BOOLEAN;
      VAR
	 d0, d1: LONGINT;
	 a0, a1 : LONGINT; (* just to match UNIXCALL interface *)
   BEGIN
      interrupted := FALSE;
      LOOP
	 IF ulmSYSTEM.UNIXCALL(Sys.close, d0, d1, fd, a0, a1) THEN
	 (*IF ulmSYSTEM.UNIXCALL(Sys.close, d0, d1, fd) THEN*)
	    RETURN TRUE
	 ELSE
	    IF d0 = SysErrors.intr THEN
	       interrupted := TRUE;
	    END;
	    IF (d0 # SysErrors.intr) OR ~retry THEN
	       SysErrors.Raise(errors, d0, Sys.close, "");
	       RETURN FALSE
	    END;
	 END;
      END;
   END Close;

   PROCEDURE Read*(fd: File; buf: Address; cnt: Count;
		  errors: RelatedEvents.Object;
		  retry: BOOLEAN; VAR interrupted: BOOLEAN) : Count;
      (* return value of  0: EOF
			 -1: I/O error
			 >0: number of bytes read
      *)
      VAR
	 d0, d1: LONGINT;
   BEGIN
      interrupted := FALSE;
      LOOP
	 IF ulmSYSTEM.UNIXCALL(Sys.read, d0, d1, fd, buf, cnt) THEN
	    RETURN d0
	 ELSE
	    IF d0 = SysErrors.intr THEN
	       interrupted := TRUE;
	    END;
	    IF (d0 # SysErrors.intr) OR ~retry THEN
	       SysErrors.Raise(errors, d0, Sys.read, "");
	       RETURN -1
	    END;
	 END;
      END;
   END Read;

   PROCEDURE Write*(fd: File; buf: Address; cnt: Count;
		   errors: RelatedEvents.Object;
		   retry: BOOLEAN; VAR interrupted: BOOLEAN) : Count;
      (* return value of    -1: I/O error
		           >=0: number of bytes written
      *)
      VAR
	 d0, d1: LONGINT;
   BEGIN
      interrupted := FALSE;
      LOOP
	 IF ulmSYSTEM.UNIXCALL(Sys.write, d0, d1, fd, buf, cnt) THEN
	    RETURN d0
	 ELSE
	    IF d0 = SysErrors.intr THEN
	       interrupted := TRUE;
	    END;
	    IF (d0 # SysErrors.intr) OR ~retry THEN
	       SysErrors.Raise(errors, d0, Sys.write, "");
	       RETURN -1
	    END;
	 END;
      END;
   END Write;

   PROCEDURE Seek*(fd: File; offset: Count; whence: Whence;
		  errors: RelatedEvents.Object) : BOOLEAN;
      VAR
	 d0, d1: LONGINT;
   BEGIN
      IF ulmSYSTEM.UNIXCALL(Sys.lseek, d0, d1, fd, offset, whence) THEN
	 RETURN TRUE
      ELSE
	 SysErrors.Raise(errors, d0, Sys.lseek, "");
	 RETURN FALSE
      END;
   END Seek;

   PROCEDURE Tell*(fd: File; VAR offset: Count;
		  errors: RelatedEvents.Object) : BOOLEAN;
      VAR
	 d0, d1: LONGINT;
   BEGIN
      IF ulmSYSTEM.UNIXCALL(Sys.lseek, d0, d1, fd, 0, fromPos) THEN
	 offset := d0;
	 RETURN TRUE
      ELSE
	 SysErrors.Raise(errors, d0, Sys.lseek, "");
	 RETURN FALSE
      END;
   END Tell;

   PROCEDURE Isatty*(fd: File) : BOOLEAN;
      CONST
	 sizeofStructTermIO = 18;
	 tcgeta = 00005405H;
      VAR
	 d0, d1: LONGINT;
	 buf: ARRAY 32 OF SYS.BYTE;  (* Should be more than sufficient *)
   BEGIN
      (* following system call fails for non-tty's *)
      RETURN ulmSYSTEM.UNIXCALL(Sys.ioctl, d0, d1, fd, tcgeta, SYS.ADR(buf))
   END Isatty;

   PROCEDURE Fcntl*(fd: File; request: INTEGER; VAR arg: LONGINT;
		   errors: RelatedEvents.Object;
		   retry: BOOLEAN; VAR interrupted: BOOLEAN) : BOOLEAN;
      VAR
	 d0, d1: LONGINT;
   BEGIN
      interrupted := FALSE;
      LOOP
	 IF ulmSYSTEM.UNIXCALL(Sys.fcntl, d0, d1, fd, request, arg) THEN
	    arg := d0;
	    RETURN TRUE
	 ELSE
	    IF d0 = SysErrors.intr THEN
	       interrupted := TRUE;
	    END;
	    IF (d0 # SysErrors.intr) OR ~retry THEN
	       SysErrors.Raise(errors, d0, Sys.fcntl, "");
	       RETURN FALSE
	    END;
	 END;
      END;
   END Fcntl;

   PROCEDURE FcntlSet*(fd: File; request: INTEGER; flags: SET;
		      errors: RelatedEvents.Object;
		      retry: BOOLEAN; VAR interrupted: BOOLEAN) : BOOLEAN;
      VAR
	 d0, d1: LONGINT;
   BEGIN
      interrupted := FALSE;
      LOOP
	 IF ulmSYSTEM.UNIXCALL(Sys.fcntl, d0, d1, fd, request, SYS.VAL(LONGINT, flags)) THEN
	    RETURN TRUE
	 ELSE
	    IF d0 = SysErrors.intr THEN
	       interrupted := TRUE;
	    END;
	    IF (d0 # SysErrors.intr) OR ~retry THEN
	       SysErrors.Raise(errors, d0, Sys.fcntl, "");
	       RETURN FALSE
	    END;
	 END;
      END;
   END FcntlSet;

   PROCEDURE FcntlGet*(fd: File; request: INTEGER; VAR flags: SET;
		      errors: RelatedEvents.Object) : BOOLEAN;
      VAR
	 d0, d1: LONGINT;
   BEGIN
      IF ulmSYSTEM.UNIXCALL(Sys.fcntl, d0, d1, fd, request, 0) THEN
	 ulmSYSTEM.WMOVE(SYS.ADR(d0), SYS.ADR(flags), 1);
	 RETURN TRUE
      ELSE
	 SysErrors.Raise(errors, d0, Sys.fcntl, "");
	 RETURN FALSE
      END;
   END FcntlGet;

   PROCEDURE Dup*(fd: File; VAR newfd: File;
		 errors: RelatedEvents.Object) : BOOLEAN;
      VAR
	 d0, d1: LONGINT;
	 a0, a1: LONGINT;
   BEGIN
      IF ulmSYSTEM.UNIXCALL(Sys.dup, d0, d1, fd, a0, a1) THEN
	 newfd := d0;
	 RETURN TRUE
      ELSE
	 SysErrors.Raise(errors, d0, Sys.dup, "");
	 RETURN FALSE
      END;
   END Dup;

   PROCEDURE Dup2*(fd, newfd: File; errors: RelatedEvents.Object) : BOOLEAN;
      VAR
	 d0, d1: LONGINT;
	 a0, a1: LONGINT;
	 fd2: File;
	 interrupted: BOOLEAN;
   BEGIN
      fd2 := newfd;
      (* handmade close to avoid unnecessary events *)
      IF ~ulmSYSTEM.UNIXCALL(Sys.close, d0, d1, newfd, a0, a1) THEN END;
      IF Fcntl(fd, dupfd, fd2, errors, TRUE, interrupted) THEN
	 IF fd2 = newfd THEN
	    RETURN TRUE
	 ELSE
	    RETURN Close(fd2, errors, TRUE, interrupted) & FALSE
	 END;
      ELSE
	 RETURN FALSE
      END;
   END Dup2;

   PROCEDURE Pipe*(VAR readfd, writefd: File;
		  errors: RelatedEvents.Object) : BOOLEAN;
      VAR
	 d0, d1: LONGINT;
	 a0, a1: LONGINT;
	 fds : ARRAY 2 OF (*File*)INTEGER; (* it needs int pipefd[2], and int is 4 bytes long on x86_64 -- noch *)
   BEGIN
      IF ulmSYSTEM.UNIXCALL(Sys.pipe, d0, d1, SYS.ADR (fds), a0, a1) THEN
	 readfd := fds[0]; writefd := fds[1];
	 RETURN TRUE
      ELSE
	 SysErrors.Raise(errors, d0, Sys.pipe, "");
	 RETURN FALSE
      END;
   END Pipe;

END ulmSysIO.
