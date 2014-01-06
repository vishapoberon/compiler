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
   $Id: SysStat.om,v 1.3 2000/11/12 13:02:09 borchert Exp $
   ----------------------------------------------------------------------------
   $Log: SysStat.om,v $
   Revision 1.3  2000/11/12  13:02:09  borchert
   door file type added

   Revision 1.2  2000/11/12  12:48:07  borchert
   - conversion adapted to Solaris 2.x
   - Lstat added

   Revision 1.1  1994/02/23  08:00:48  borchert
   Initial revision

   ----------------------------------------------------------------------------
   AFB 9/89
   ----------------------------------------------------------------------------
*)

MODULE ulmSysStat;

   (* examine inode: stat(2) and fstat(2) *)

   IMPORT RelatedEvents := ulmRelatedEvents, Sys := ulmSys, SYS := SYSTEM, uSYS := ulmSYSTEM, SysConversions := ulmSysConversions, SysErrors := ulmSysErrors,
      SysTypes := ulmSysTypes;

   CONST
      (* file mode:
         bit 0 = 1<<0   bit 31 = 1<<31
	 
                                user  group other
         3       1  1111   11
         1  ...  6  5432   109   876   543   210 
	 +--------+------+-----+-----+-----+-----+
	 | unused | type | sst | rwx | rwx | rwx |
	 +--------+------+-----+-----+-----+-----+
      *)

      type* = {12..15};
      prot* = {0..8};

      (* file types; example: (stat.mode * type = dir) *)
      reg* = {15};		(* regular *)
      dir* = {14};		(* directory *)
      chr* = {13};		(* character special *)
      fifo* = {12};		(* fifo *)
      blk* = {13..14};		(* block special *)
      symlink* = {13, 15};	(* symbolic link *)
      socket* = {14, 15};	(* socket *)

      (* special *)
      setuid* = 11;		(* set user id on execution *)
      setgid* = 10;		(* set group id on execution *)
      savetext* = 9;		(* save swapped text even after use *)

      (* protection *)
      uread* = 8;		(* read permission owner *)
      uwrite* = 7;		(* write permission owner *)
      uexec* = 6;		(* execute/search permission owner *)
      gread* = 5;		(* read permission group *)
      gwrite* = 4;		(* write permission group *)
      gexec* = 3;		(* execute/search permission group *)
      oread* = 2;		(* read permission other *)
      owrite* = 1;		(* write permission other *)
      oexec* = 0;		(* execute/search permission other *)

      (* example for "r-xr-x---": (read + exec) * (owner + group) *)
      owner* = {uread, uwrite, uexec};
      group* = {gread, gwrite, gexec};
      other* = {oread, owrite, oexec};
      read* = {uread, gread, oread};
      write* = {uwrite, gwrite, owrite};
      exec* = {uexec, gexec, oexec};
      rwx* = prot;

   TYPE
      StatRec* =				(* result of stat(2) and fstat(2) *)
	 RECORD
	    device*: SysTypes.Device;	(* ID of device containing
					   a directory entry for this file *)
	    inode*: SysTypes.Inode;	(* inode number *)
	    mode*: SET;			(* file mode; see mknod(2) *)
	    nlinks*: LONGINT;		(* number of links *)
	    uid*: LONGINT;		(* user id of the file's owner *)
	    gid*: LONGINT;		(* group id of the file's group *)
	    rdev*: SysTypes.Device;	(* ID of device
					   this entry is defined only for
					   character special or block
					   special files
					*)
	    size*: SysTypes.Offset;	(* file size in bytes *)
	    blksize*: LONGINT;		(* preferred blocksize *)
	    blocks*: LONGINT;		(* # of blocks allocated *)
	    atime*: SysTypes.Time;	(* time of last access *)
	    mtime*: SysTypes.Time;	(* time of last data modification *)
	    ctime*: SysTypes.Time;	(* time of last file status change *)
	 END;

(* Linux kernel struct stat (2.2.17)
      struct stat {
	      unsigned short st_dev;
	      unsigned short __pad1;
	      unsigned long st_ino;
	      unsigned short st_mode;
	      unsigned short st_nlink;
	      unsigned short st_uid;
	      unsigned short st_gid;
	      unsigned short st_rdev;
	      unsigned short __pad2;
	      unsigned long  st_size;
	      unsigned long  st_blksize;
	      unsigned long  st_blocks;
	      unsigned long  st_atime;
	      unsigned long  __unused1;
	      unsigned long  st_mtime;
	      unsigned long  __unused2;
	      unsigned long  st_ctime;
	      unsigned long  __unused3;
	      unsigned long  __unused4;
	      unsigned long  __unused5;
      };
*)

   CONST
      statbufsize = 88(*64*); (* see <sys/stat.h> *) (* sizeof struct stat gives us 144 on x86_64 and 88 on x86 *)
   TYPE
      UnixStatRec = ARRAY statbufsize OF SYS.BYTE;
   CONST
      statbufconv =
      (*"is=dev/-s=pad1/ll=ino/Ss=mode/4*is=nlink+uid+gid+rdev/-s=pad2/ll=size/2*ll=blksize,blocks/il=atime/-l/il=mtime/-l/il=ctime/3*-l";*)
      (*"ls=dev/-s=pad1/lL=ino/Ss=mode/4*is=nlink+uid+gid+rdev/-s=pad2/lL=size/2*lL=blksize,blocks/lL=atime/-l/lL=mtime/-l/lL=ctime/3*-l";*)
      "ll=dev/-l=devx/-s=pad1/ll=ino/Sl=mode/ll=nlink/ll=uid/ll=gid/ll=rdev/-l=rdevx/-s=pad2/ll=size/2*ll=blksize,blocks/lL=atime/-l/lL=mtime/-l/lL=ctime/3*-l";
   VAR
      statbuffmt: SysConversions.Format;

   PROCEDURE Stat*(path: ARRAY OF CHAR; VAR buf: StatRec;
		  errors: RelatedEvents.Object) : BOOLEAN;
      VAR
	 d0, d1, d2: LONGINT;
	 origbuf: UnixStatRec;
   BEGIN
      IF uSYS.UNIXCALL(Sys.newstat, d0, d1, SYS.ADR(path), SYS.ADR(origbuf), d2) THEN
	 SysConversions.ByFmtFromC(origbuf, buf, statbuffmt);
	 RETURN TRUE
      ELSE
	 SysErrors.Raise(errors, d0, Sys.newstat, path);
	 RETURN FALSE
      END;
   END Stat;
(*
   PROCEDURE Lstat*(path: ARRAY OF CHAR; VAR buf: StatRec;
		   errors: RelatedEvents.Object) : BOOLEAN;
      VAR
	 d0, d1: INTEGER;
	 origbuf: UnixStatRec;
   BEGIN
      IF SYS.UNIXCALL(Sys.newlstat, d0, d1, SYS.ADR(path), SYS.ADR(origbuf)) THEN
	 SysConversions.ByFmtFromC(origbuf, buf, statbuffmt);
	 RETURN TRUE
      ELSE
	 SysErrors.Raise(errors, d0, Sys.newlstat, path);
	 RETURN FALSE
      END;
   END Lstat;
*)
   PROCEDURE Fstat*(fd: SysTypes.File; VAR buf: StatRec;
		   errors: RelatedEvents.Object) : BOOLEAN;
      VAR
	 d0, d1, d2: LONGINT;
	 origbuf: UnixStatRec;
   BEGIN
      IF uSYS.UNIXCALL(Sys.newfstat, d0, d1, fd, SYS.ADR(origbuf), d2) THEN
	 SysConversions.ByFmtFromC(origbuf, buf, statbuffmt);
	 RETURN TRUE
      ELSE
	 SysErrors.Raise(errors, d0, Sys.newfstat, "");
	 RETURN FALSE
      END;
   END Fstat;

BEGIN
   SysConversions.Compile(statbuffmt, statbufconv);
END ulmSysStat.
