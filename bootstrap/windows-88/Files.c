/* voc 5.4.0 [2026/11/24] for gcc LP64 on gentoo xnrtspaSF */

#define SHORTINT INT8
#define INTEGER  INT16
#define LONGINT  INT32
#define SET      UINT32

#include "SYSTEM.h"
#include "Heap.h"
#include "Out.h"
#include "Platform.h"
#include "Strings.h"

typedef
	struct Files_FileDesc *Files_File;

typedef
	struct Files_BufDesc {
		Files_File f;
		BOOLEAN chg;
		INT32 org, size;
		SYSTEM_BYTE data[4096];
	} Files_BufDesc;

typedef
	Files_BufDesc *Files_Buffer;

typedef
	struct {
		ADDRESS len[1];
		CHAR data[1];
	} *Files_Bytes;

typedef
	CHAR Files_FileName[256];

typedef
	struct Files_FileDesc {
		Files_FileName workName, registerName;
		BOOLEAN tempFile;
		Platform_FileIdentity identity;
		INT64 fd;
		INT32 len, pos;
		Files_Buffer bufs[4];
		INT16 swapper, state;
		struct Files_FileDesc *next;
		Files_Bytes memory;
		INT32 memoryCapacity;
		BOOLEAN memoryFailed;
	} Files_FileDesc;

typedef
	struct Files_Rider {
		INT32 res;
		BOOLEAN eof;
		Files_Buffer buf;
		INT32 org, offset;
	} Files_Rider;


export INT16 Files_MaxPathLength, Files_MaxNameLength;
static Files_FileDesc *Files_files;
static INT16 Files_tempno;
static CHAR Files_HOME[1024];
static struct {
	ADDRESS len[1];
	CHAR data[1];
} *Files_SearchPath;

export ADDRESS *Files_FileDesc__typ;
export ADDRESS *Files_BufDesc__typ;
export ADDRESS *Files_Rider__typ;

static void Files_Assert (BOOLEAN truth);
export Files_File Files_Base (Files_Rider *r, ADDRESS *r__typ);
static Files_File Files_CacheEntry (Platform_FileIdentity identity);
export void Files_ChangeDirectory (CHAR *path, ADDRESS path__len, INT16 *res);
export void Files_Close (Files_File f);
static void Files_CloseOSFile (Files_File f);
static void Files_Create (Files_File f);
export void Files_Delete (CHAR *name, ADDRESS name__len, INT16 *res);
static void Files_Deregister (CHAR *name, ADDRESS name__len);
static void Files_Err (CHAR *s, ADDRESS s__len, Files_File f, INT16 errcode);
static void Files_Finalize (SYSTEM_PTR o);
static void Files_FlipBytes (SYSTEM_BYTE *src, ADDRESS src__len, SYSTEM_BYTE *dest, ADDRESS dest__len);
static void Files_Flush (Files_Buffer buf);
export Files_File Files_FromBytes (CHAR *data, ADDRESS data__len, INT32 length);
export void Files_GetDate (Files_File f, INT32 *t, INT32 *d);
export void Files_GetName (Files_File f, CHAR *name, ADDRESS name__len);
export BOOLEAN Files_GetSearchPath (CHAR *path, ADDRESS path__len);
static void Files_GetTempName (CHAR *finalName, ADDRESS finalName__len, CHAR *name, ADDRESS name__len);
static BOOLEAN Files_HasDir (CHAR *name, ADDRESS name__len);
export BOOLEAN Files_IsMemory (Files_File f);
export INT32 Files_Length (Files_File f);
static void Files_MakeFileName (CHAR *dir, ADDRESS dir__len, CHAR *name, ADDRESS name__len, CHAR *dest, ADDRESS dest__len);
export Files_Bytes Files_MemoryData (Files_File f, INT32 *length);
export BOOLEAN Files_MemoryFailed (Files_File f);
export Files_File Files_New (CHAR *name, ADDRESS name__len);
export Files_File Files_NewMemory (INT32 capacity);
export Files_File Files_Old (CHAR *name, ADDRESS name__len);
static Files_File Files_OldFile (CHAR *name, ADDRESS name__len);
export INT32 Files_Pos (Files_Rider *r, ADDRESS *r__typ);
export void Files_Purge (Files_File f);
export void Files_Read (Files_Rider *r, ADDRESS *r__typ, SYSTEM_BYTE *x);
export void Files_ReadBool (Files_Rider *R, ADDRESS *R__typ, BOOLEAN *x);
export void Files_ReadByte (Files_Rider *r, ADDRESS *r__typ, SYSTEM_BYTE *x);
export void Files_ReadBytes (Files_Rider *r, ADDRESS *r__typ, SYSTEM_BYTE *x, ADDRESS x__len, INT32 n);
export void Files_ReadInt (Files_Rider *R, ADDRESS *R__typ, INT16 *x);
export void Files_ReadLInt (Files_Rider *R, ADDRESS *R__typ, INT32 *x);
export void Files_ReadLReal (Files_Rider *R, ADDRESS *R__typ, LONGREAL *x);
export void Files_ReadLine (Files_Rider *R, ADDRESS *R__typ, CHAR *x, ADDRESS x__len);
export void Files_ReadNum (Files_Rider *R, ADDRESS *R__typ, SYSTEM_BYTE *x, ADDRESS x__len);
export void Files_ReadReal (Files_Rider *R, ADDRESS *R__typ, REAL *x);
export void Files_ReadSet (Files_Rider *R, ADDRESS *R__typ, UINT32 *x);
export void Files_ReadString (Files_Rider *R, ADDRESS *R__typ, CHAR *x, ADDRESS x__len);
export void Files_Register (Files_File f);
export void Files_Rename (CHAR *old, ADDRESS old__len, CHAR *new, ADDRESS new__len, INT16 *res);
static void Files_RenameFile (CHAR *old, ADDRESS old__len, CHAR *new, ADDRESS new__len, INT16 *res);
static void Files_ScanPath (INT16 *pos, CHAR *dir, ADDRESS dir__len);
export void Files_Set (Files_Rider *r, ADDRESS *r__typ, Files_File f, INT32 pos);
export void Files_SetSearchPath (CHAR *path, ADDRESS path__len);
export void Files_Write (Files_Rider *r, ADDRESS *r__typ, SYSTEM_BYTE x);
export void Files_WriteBool (Files_Rider *R, ADDRESS *R__typ, BOOLEAN x);
export void Files_WriteBytes (Files_Rider *r, ADDRESS *r__typ, SYSTEM_BYTE *x, ADDRESS x__len, INT32 n);
export void Files_WriteInt (Files_Rider *R, ADDRESS *R__typ, INT16 x);
export void Files_WriteLInt (Files_Rider *R, ADDRESS *R__typ, INT32 x);
export void Files_WriteLReal (Files_Rider *R, ADDRESS *R__typ, LONGREAL x);
export void Files_WriteNum (Files_Rider *R, ADDRESS *R__typ, INT64 x);
export void Files_WriteReal (Files_Rider *R, ADDRESS *R__typ, REAL x);
export void Files_WriteSet (Files_Rider *R, ADDRESS *R__typ, UINT32 x);
export void Files_WriteString (Files_Rider *R, ADDRESS *R__typ, CHAR *x, ADDRESS x__len);

#define Files_IdxTrap()	__HALT(-1)

static void Files_Assert (BOOLEAN truth)
{
	if (!truth) {
		Out_Ln();
		__ASSERT(truth, 0);
	}
}

static void Files_Err (CHAR *s, ADDRESS s__len, Files_File f, INT16 errcode)
{
	__DUP(s, s__len, CHAR);
	Out_Ln();
	Out_String((CHAR*)"-- ", 4);
	Out_String(s, s__len);
	Out_String((CHAR*)": ", 3);
	if (f != NIL) {
		if (((Files_File)__NIL_AT((ADDRESS)(f), (CHAR*)"../../src/library/Files.Mod", 28, (CHAR*)"Files", 6, 83, 11, 2513))->registerName[0] != 0x00) {
			Out_String(((Files_File)__NIL_AT((ADDRESS)(f), (CHAR*)"../../src/library/Files.Mod", 28, (CHAR*)"Files", 6, 83, 47, 2549))->registerName, 256);
		} else {
			Out_String(((Files_File)__NIL_AT((ADDRESS)(f), (CHAR*)"../../src/library/Files.Mod", 28, (CHAR*)"Files", 6, 83, 79, 2581))->workName, 256);
		}
		if (((Files_File)__NIL_AT((ADDRESS)(f), (CHAR*)"../../src/library/Files.Mod", 28, (CHAR*)"Files", 6, 84, 11, 2607))->fd != 0) {
			Out_String((CHAR*)", f.fd = ", 10);
			Out_Int(((Files_File)__NIL_AT((ADDRESS)(f), (CHAR*)"../../src/library/Files.Mod", 28, (CHAR*)"Files", 6, 84, 58, 2654))->fd, 1);
		}
	}
	if (errcode != 0) {
		Out_String((CHAR*)", errcode = ", 13);
		Out_Int(errcode, 1);
	}
	Out_Ln();
	__HALT(99);
	__DEL(s);
}

static void Files_MakeFileName (CHAR *dir, ADDRESS dir__len, CHAR *name, ADDRESS name__len, CHAR *dest, ADDRESS dest__len)
{
	INT16 i, j, ld, ln;
	__DUP(dir, dir__len, CHAR);
	__DUP(name, name__len, CHAR);
	ld = Strings_Length(dir, dir__len);
	ln = Strings_Length(name, name__len);
	while ((ld > 0 && dir[__X_AT(ld - 1, dir__len, (CHAR*)"../../src/library/Files.Mod", 28, (CHAR*)"Files", 6, 94, 27, 2984)] == '/')) {
		ld -= 1;
	}
	if (((ld + ln) + 2) > dest__len) {
		Files_Err((CHAR*)"File name too long", 19, NIL, 0);
	}
	i = 0;
	while (i < ld) {
		dest[__X_AT(i, dest__len, (CHAR*)"../../src/library/Files.Mod", 28, (CHAR*)"Files", 6, 97, 26, 3125)] = dir[__X_AT(i, dir__len, (CHAR*)"../../src/library/Files.Mod", 28, (CHAR*)"Files", 6, 97, 36, 3135)];
		i += 1;
	}
	if (i > 0) {
		dest[__X_AT(i, dest__len, (CHAR*)"../../src/library/Files.Mod", 28, (CHAR*)"Files", 6, 98, 24, 3174)] = '/';
		i += 1;
	}
	j = 0;
	while (j < ln) {
		dest[__X_AT(i, dest__len, (CHAR*)"../../src/library/Files.Mod", 28, (CHAR*)"Files", 6, 100, 26, 3234)] = name[__X_AT(j, name__len, (CHAR*)"../../src/library/Files.Mod", 28, (CHAR*)"Files", 6, 100, 37, 3245)];
		i += 1;
		j += 1;
	}
	dest[__X_AT(i, dest__len, (CHAR*)"../../src/library/Files.Mod", 28, (CHAR*)"Files", 6, 101, 10, 3278)] = 0x00;
	__DEL(dir);
	__DEL(name);
}

static void Files_GetTempName (CHAR *finalName, ADDRESS finalName__len, CHAR *name, ADDRESS name__len)
{
	INT16 i, n;
	__DUP(finalName, finalName__len, CHAR);
	if (finalName[0] == '/') {
		__COPY(finalName, name, name__len);
	} else {
		Files_MakeFileName(Platform_CWD, 4096, finalName, finalName__len, (void*)name, name__len);
	}
	i = Strings_Length(name, name__len) - 1;
	while ((i > 0 && name[__X_AT(i, name__len, (CHAR*)"../../src/library/Files.Mod", 28, (CHAR*)"Files", 6, 109, 27, 3578)] != '/')) {
		i -= 1;
	}
	if ((i + 16) >= name__len) {
		Files_Err((CHAR*)"File name too long", 19, NIL, 0);
	}
	Files_tempno += 1;
	n = Files_tempno;
	name[__X_AT(i + 1, name__len, (CHAR*)"../../src/library/Files.Mod", 28, (CHAR*)"Files", 6, 112, 10, 3711)] = '.';
	name[__X_AT(i + 2, name__len, (CHAR*)"../../src/library/Files.Mod", 28, (CHAR*)"Files", 6, 112, 28, 3729)] = 't';
	name[__X_AT(i + 3, name__len, (CHAR*)"../../src/library/Files.Mod", 28, (CHAR*)"Files", 6, 112, 46, 3747)] = 'm';
	name[__X_AT(i + 4, name__len, (CHAR*)"../../src/library/Files.Mod", 28, (CHAR*)"Files", 6, 112, 64, 3765)] = 'p';
	name[__X_AT(i + 5, name__len, (CHAR*)"../../src/library/Files.Mod", 28, (CHAR*)"Files", 6, 112, 82, 3783)] = '.';
	i += 6;
	while (n > 0) {
		name[__X_AT(i, name__len, (CHAR*)"../../src/library/Files.Mod", 28, (CHAR*)"Files", 6, 113, 25, 3831)] = __CHR((int)__MOD(n, 10) + 48);
		n = __DIV(n, 10);
		i += 1;
	}
	name[__X_AT(i, name__len, (CHAR*)"../../src/library/Files.Mod", 28, (CHAR*)"Files", 6, 114, 10, 3899)] = '.';
	i += 1;
	n = Platform_PID;
	while (n > 0) {
		name[__X_AT(i, name__len, (CHAR*)"../../src/library/Files.Mod", 28, (CHAR*)"Files", 6, 115, 25, 3961)] = __CHR((int)__MOD(n, 10) + 48);
		n = __DIV(n, 10);
		i += 1;
	}
	name[__X_AT(i, name__len, (CHAR*)"../../src/library/Files.Mod", 28, (CHAR*)"Files", 6, 116, 10, 4030)] = 0x00;
	__DEL(finalName);
}

static void Files_Deregister (CHAR *name, ADDRESS name__len)
{
	Platform_FileIdentity identity;
	Files_File osfile = NIL;
	INT16 error;
	__DUP(name, name__len, CHAR);
	if (Platform_IdentifyByName(name, name__len, &identity, Platform_FileIdentity__typ) == 0) {
		osfile = (Files_File)Files_files;
		while ((osfile != NIL && !Platform_SameFile(((Files_File)__NIL_AT((ADDRESS)(osfile), (CHAR*)"../../src/library/Files.Mod", 28, (CHAR*)"Files", 6, 137, 55, 5048))->identity, identity))) {
			osfile = (Files_File)((Files_File)__NIL_AT((ADDRESS)(osfile), (CHAR*)"../../src/library/Files.Mod", 28, (CHAR*)"Files", 6, 137, 95, 5088))->next;
		}
		if (osfile != NIL) {
			__ASSERT(!((Files_File)__NIL_AT((ADDRESS)(osfile), (CHAR*)"../../src/library/Files.Mod", 28, (CHAR*)"Files", 6, 141, 23, 5285))->tempFile, 0);
			__ASSERT(((Files_File)__NIL_AT((ADDRESS)(osfile), (CHAR*)"../../src/library/Files.Mod", 28, (CHAR*)"Files", 6, 141, 48, 5310))->fd >= 0, 0);
			__MOVE(((Files_File)__NIL_AT((ADDRESS)(osfile), (CHAR*)"../../src/library/Files.Mod", 28, (CHAR*)"Files", 6, 142, 38, 5358))->workName, ((Files_File)__NIL_AT((ADDRESS)(osfile), (CHAR*)"../../src/library/Files.Mod", 28, (CHAR*)"Files", 6, 142, 15, 5335))->registerName, 256);
			Files_GetTempName(((Files_File)__NIL_AT((ADDRESS)(osfile), (CHAR*)"../../src/library/Files.Mod", 28, (CHAR*)"Files", 6, 143, 27, 5395))->registerName, 256, (void*)((Files_File)__NIL_AT((ADDRESS)(osfile), (CHAR*)"../../src/library/Files.Mod", 28, (CHAR*)"Files", 6, 143, 48, 5416))->workName, 256);
			((Files_File)__NIL_AT((ADDRESS)(osfile), (CHAR*)"../../src/library/Files.Mod", 28, (CHAR*)"Files", 6, 144, 15, 5442))->tempFile = 1;
			((Files_File)__NIL_AT((ADDRESS)(osfile), (CHAR*)"../../src/library/Files.Mod", 28, (CHAR*)"Files", 6, 145, 15, 5475))->state = 0;
			error = Platform_Rename((void*)((Files_File)__NIL_AT((ADDRESS)(osfile), (CHAR*)"../../src/library/Files.Mod", 28, (CHAR*)"Files", 6, 146, 40, 5530))->registerName, 256, (void*)((Files_File)__NIL_AT((ADDRESS)(osfile), (CHAR*)"../../src/library/Files.Mod", 28, (CHAR*)"Files", 6, 146, 61, 5551))->workName, 256);
			if (error != 0) {
				Files_Err((CHAR*)"Couldn't rename previous version of file being registered", 58, osfile, error);
			}
		}
	}
	__DEL(name);
}

static void Files_Create (Files_File f)
{
	BOOLEAN done;
	INT16 error;
	CHAR err[32];
	if (((Files_File)__NIL_AT((ADDRESS)(f), (CHAR*)"../../src/library/Files.Mod", 28, (CHAR*)"Files", 6, 165, 9, 6106))->fd == -1) {
		if (((Files_File)__NIL_AT((ADDRESS)(f), (CHAR*)"../../src/library/Files.Mod", 28, (CHAR*)"Files", 6, 166, 11, 6134))->state == 1) {
			Files_GetTempName(((Files_File)__NIL_AT((ADDRESS)(f), (CHAR*)"../../src/library/Files.Mod", 28, (CHAR*)"Files", 6, 169, 22, 6304))->registerName, 256, (void*)((Files_File)__NIL_AT((ADDRESS)(f), (CHAR*)"../../src/library/Files.Mod", 28, (CHAR*)"Files", 6, 169, 38, 6320))->workName, 256);
			((Files_File)__NIL_AT((ADDRESS)(f), (CHAR*)"../../src/library/Files.Mod", 28, (CHAR*)"Files", 6, 169, 51, 6333))->tempFile = 1;
		} else {
			__ASSERT(((Files_File)__NIL_AT((ADDRESS)(f), (CHAR*)"../../src/library/Files.Mod", 28, (CHAR*)"Files", 6, 171, 17, 6378))->state == 2, 0);
			Files_Deregister(((Files_File)__NIL_AT((ADDRESS)(f), (CHAR*)"../../src/library/Files.Mod", 28, (CHAR*)"Files", 6, 174, 21, 6566))->registerName, 256);
			__MOVE(((Files_File)__NIL_AT((ADDRESS)(f), (CHAR*)"../../src/library/Files.Mod", 28, (CHAR*)"Files", 6, 175, 24, 6605))->registerName, ((Files_File)__NIL_AT((ADDRESS)(f), (CHAR*)"../../src/library/Files.Mod", 28, (CHAR*)"Files", 6, 175, 10, 6591))->workName, 256);
			((Files_File)__NIL_AT((ADDRESS)(f), (CHAR*)"../../src/library/Files.Mod", 28, (CHAR*)"Files", 6, 175, 40, 6621))->registerName[0] = 0x00;
			((Files_File)__NIL_AT((ADDRESS)(f), (CHAR*)"../../src/library/Files.Mod", 28, (CHAR*)"Files", 6, 175, 62, 6643))->tempFile = 0;
		}
		error = Platform_Unlink((void*)((Files_File)__NIL_AT((ADDRESS)(f), (CHAR*)"../../src/library/Files.Mod", 28, (CHAR*)"Files", 6, 177, 33, 6705))->workName, 256);
		error = Platform_New((void*)((Files_File)__NIL_AT((ADDRESS)(f), (CHAR*)"../../src/library/Files.Mod", 28, (CHAR*)"Files", 6, 178, 30, 6820))->workName, 256, &((Files_File)__NIL_AT((ADDRESS)(f), (CHAR*)"../../src/library/Files.Mod", 28, (CHAR*)"Files", 6, 178, 42, 6832))->fd);
		done = error == 0;
		if (done) {
			((Files_File)__NIL_AT((ADDRESS)(f), (CHAR*)"../../src/library/Files.Mod", 28, (CHAR*)"Files", 6, 181, 10, 6891))->next = Files_files;
			Files_files = f;
			Heap_FileCount += 1;
			Heap_RegisterFinalizer((void*)f, Files_Finalize);
			((Files_File)__NIL_AT((ADDRESS)(f), (CHAR*)"../../src/library/Files.Mod", 28, (CHAR*)"Files", 6, 184, 10, 7059))->state = 0;
			((Files_File)__NIL_AT((ADDRESS)(f), (CHAR*)"../../src/library/Files.Mod", 28, (CHAR*)"Files", 6, 185, 10, 7084))->pos = 0;
			error = Platform_Identify(((Files_File)__NIL_AT((ADDRESS)(f), (CHAR*)"../../src/library/Files.Mod", 28, (CHAR*)"Files", 6, 186, 39, 7135))->fd, &((Files_File)__NIL_AT((ADDRESS)(f), (CHAR*)"../../src/library/Files.Mod", 28, (CHAR*)"Files", 6, 186, 45, 7141))->identity, Platform_FileIdentity__typ);
		} else {
			if (Platform_NoSuchDirectory(error)) {
				__MOVE("no such directory", err, 18);
			} else if (Platform_TooManyFiles(error)) {
				__MOVE("too many files open", err, 20);
			} else {
				__MOVE("file not created", err, 17);
			}
			Files_Err(err, 32, f, error);
		}
	}
}

static void Files_Flush (Files_Buffer buf)
{
	INT16 error;
	Files_File f = NIL;
	if (((Files_Buffer)__NIL_AT((ADDRESS)(buf), (CHAR*)"../../src/library/Files.Mod", 28, (CHAR*)"Files", 6, 203, 11, 7599))->chg) {
		f = ((Files_Buffer)__NIL_AT((ADDRESS)(buf), (CHAR*)"../../src/library/Files.Mod", 28, (CHAR*)"Files", 6, 203, 29, 7617))->f;
		Files_Create(f);
		if (((Files_Buffer)__NIL_AT((ADDRESS)(buf), (CHAR*)"../../src/library/Files.Mod", 28, (CHAR*)"Files", 6, 204, 13, 7644))->org != ((Files_File)__NIL_AT((ADDRESS)(f), (CHAR*)"../../src/library/Files.Mod", 28, (CHAR*)"Files", 6, 204, 21, 7652))->pos) {
			error = Platform_Seek(((Files_File)__NIL_AT((ADDRESS)(f), (CHAR*)"../../src/library/Files.Mod", 28, (CHAR*)"Files", 6, 205, 33, 7694))->fd, ((Files_Buffer)__NIL_AT((ADDRESS)(buf), (CHAR*)"../../src/library/Files.Mod", 28, (CHAR*)"Files", 6, 205, 41, 7702))->org, Platform_SeekSet);
		}
		error = Platform_Write(((Files_File)__NIL_AT((ADDRESS)(f), (CHAR*)"../../src/library/Files.Mod", 28, (CHAR*)"Files", 6, 207, 32, 7769))->fd, (ADDRESS)((Files_Buffer)__NIL_AT((ADDRESS)(buf), (CHAR*)"../../src/library/Files.Mod", 28, (CHAR*)"Files", 6, 207, 51, 7788))->data, ((Files_Buffer)__NIL_AT((ADDRESS)(buf), (CHAR*)"../../src/library/Files.Mod", 28, (CHAR*)"Files", 6, 207, 62, 7799))->size);
		if (error != 0) {
			Files_Err((CHAR*)"error writing file", 19, f, error);
		}
		((Files_File)__NIL_AT((ADDRESS)(f), (CHAR*)"../../src/library/Files.Mod", 28, (CHAR*)"Files", 6, 209, 8, 7879))->pos = ((Files_Buffer)__NIL_AT((ADDRESS)(buf), (CHAR*)"../../src/library/Files.Mod", 28, (CHAR*)"Files", 6, 209, 19, 7890))->org + ((Files_Buffer)__NIL_AT((ADDRESS)(buf), (CHAR*)"../../src/library/Files.Mod", 28, (CHAR*)"Files", 6, 209, 29, 7900))->size;
		((Files_Buffer)__NIL_AT((ADDRESS)(buf), (CHAR*)"../../src/library/Files.Mod", 28, (CHAR*)"Files", 6, 210, 10, 7916))->chg = 0;
		error = Platform_Identify(((Files_File)__NIL_AT((ADDRESS)(f), (CHAR*)"../../src/library/Files.Mod", 28, (CHAR*)"Files", 6, 211, 35, 7965))->fd, &((Files_File)__NIL_AT((ADDRESS)(f), (CHAR*)"../../src/library/Files.Mod", 28, (CHAR*)"Files", 6, 211, 41, 7971))->identity, Platform_FileIdentity__typ);
		if (error != 0) {
			Files_Err((CHAR*)"error identifying file", 23, f, error);
		}
	}
}

void Files_Close (Files_File f)
{
	INT32 i;
	INT16 error;
	if (((Files_File)__NIL_AT((ADDRESS)(f), (CHAR*)"../../src/library/Files.Mod", 28, (CHAR*)"Files", 6, 220, 9, 8224))->memory != NIL) {
		return;
	}
	Platform_CommandCritical(1);
	if (((Files_File)__NIL_AT((ADDRESS)(f), (CHAR*)"../../src/library/Files.Mod", 28, (CHAR*)"Files", 6, 222, 10, 8300))->state != 1 || ((Files_File)__NIL_AT((ADDRESS)(f), (CHAR*)"../../src/library/Files.Mod", 28, (CHAR*)"Files", 6, 222, 32, 8322))->registerName[0] != 0x00) {
		Files_Create(f);
		i = 0;
		while ((i < 4 && ((Files_File)__NIL_AT((ADDRESS)(f), (CHAR*)"../../src/library/Files.Mod", 28, (CHAR*)"Files", 6, 224, 31, 8402))->bufs[__X_AT(i, 4, (CHAR*)"../../src/library/Files.Mod", 28, (CHAR*)"Files", 6, 224, 37, 8408)] != NIL)) {
			Files_Flush(((Files_File)__NIL_AT((ADDRESS)(f), (CHAR*)"../../src/library/Files.Mod", 28, (CHAR*)"Files", 6, 224, 57, 8428))->bufs[__X_AT(i, 4, (CHAR*)"../../src/library/Files.Mod", 28, (CHAR*)"Files", 6, 224, 63, 8434)]);
			i += 1;
		}
	}
	Platform_CommandCritical(0);
}

INT32 Files_Length (Files_File f)
{
	return ((Files_File)__NIL_AT((ADDRESS)(f), (CHAR*)"../../src/library/Files.Mod", 28, (CHAR*)"Files", 6, 230, 17, 8566))->len;
}

Files_File Files_New (CHAR *name, ADDRESS name__len)
{
	Files_File f = NIL;
	__DUP(name, name__len, CHAR);
	__NEW(f, Files_FileDesc);
	((Files_File)__NIL_AT((ADDRESS)(f), (CHAR*)"../../src/library/Files.Mod", 28, (CHAR*)"Files", 6, 235, 14, 8668))->workName[0] = 0x00;
	__COPY(name, ((Files_File)__NIL_AT((ADDRESS)(f), (CHAR*)"../../src/library/Files.Mod", 28, (CHAR*)"Files", 6, 235, 43, 8697))->registerName, 256);
	((Files_File)__NIL_AT((ADDRESS)(f), (CHAR*)"../../src/library/Files.Mod", 28, (CHAR*)"Files", 6, 236, 6, 8718))->fd = -1;
	((Files_File)__NIL_AT((ADDRESS)(f), (CHAR*)"../../src/library/Files.Mod", 28, (CHAR*)"Files", 6, 236, 22, 8734))->state = 1;
	((Files_File)__NIL_AT((ADDRESS)(f), (CHAR*)"../../src/library/Files.Mod", 28, (CHAR*)"Files", 6, 236, 41, 8753))->len = 0;
	((Files_File)__NIL_AT((ADDRESS)(f), (CHAR*)"../../src/library/Files.Mod", 28, (CHAR*)"Files", 6, 236, 53, 8765))->pos = 0;
	((Files_File)__NIL_AT((ADDRESS)(f), (CHAR*)"../../src/library/Files.Mod", 28, (CHAR*)"Files", 6, 236, 65, 8777))->swapper = -1;
	__DEL(name);
	return f;
}

Files_File Files_NewMemory (INT32 capacity)
{
	Files_File f = NIL;
	if (capacity < 0) {
		return NIL;
	}
	f = Files_New((CHAR*)"", 1);
	((Files_File)__NIL_AT((ADDRESS)(f), (CHAR*)"../../src/library/Files.Mod", 28, (CHAR*)"Files", 6, 245, 20, 9053))->memoryCapacity = capacity;
	if (capacity == 0) {
		((Files_File)__NIL_AT((ADDRESS)(f), (CHAR*)"../../src/library/Files.Mod", 28, (CHAR*)"Files", 6, 246, 31, 9112))->memory = __NEWARR(NIL, 1, 1, 1, 1, ((INT64)(1)));
	} else {
		((Files_File)__NIL_AT((ADDRESS)(f), (CHAR*)"../../src/library/Files.Mod", 28, (CHAR*)"Files", 6, 246, 53, 9134))->memory = __NEWARR(NIL, 1, 1, 1, 1, ((ADDRESS)(capacity)));
	}
	((Files_File)__NIL_AT((ADDRESS)(f), (CHAR*)"../../src/library/Files.Mod", 28, (CHAR*)"Files", 6, 247, 6, 9163))->memoryFailed = 0;
	return f;
}

Files_File Files_FromBytes (CHAR *data, ADDRESS data__len, INT32 length)
{
	Files_File f = NIL;
	INT32 i, _for__15;
	__DUP(data, data__len, CHAR);
	if (length < 0 || length > data__len) {
		__DEL(data);
		return NIL;
	}
	f = Files_NewMemory(length);
	_for__15 = length - 1;
	i = 0;
	while (i <= _for__15) {
		(((Files_Bytes)__NIL_AT((ADDRESS)(((Files_File)__NIL_AT((ADDRESS)(f), (CHAR*)"../../src/library/Files.Mod", 28, (CHAR*)"Files", 6, 257, 34, 9522))->memory), (CHAR*)"../../src/library/Files.Mod", 28, (CHAR*)"Files", 6, 257, 41, 9529))->data)[__X_AT(i, ((Files_Bytes)__NIL_AT((ADDRESS)(((Files_File)__NIL_AT((ADDRESS)(f), (CHAR*)"../../src/library/Files.Mod", 28, (CHAR*)"Files", 6, 257, 34, 9522))->memory), (CHAR*)"../../src/library/Files.Mod", 28, (CHAR*)"Files", 6, 257, 41, 9529))->len[0], (CHAR*)"../../src/library/Files.Mod", 28, (CHAR*)"Files", 6, 257, 42, 9530)] = data[__X_AT(i, data__len, (CHAR*)"../../src/library/Files.Mod", 28, (CHAR*)"Files", 6, 257, 53, 9541)];
		i += 1;
	}
	((Files_File)__NIL_AT((ADDRESS)(f), (CHAR*)"../../src/library/Files.Mod", 28, (CHAR*)"Files", 6, 258, 6, 9554))->len = length;
	__DEL(data);
	return f;
}

BOOLEAN Files_IsMemory (Files_File f)
{
	return (f != NIL && ((Files_File)__NIL_AT((ADDRESS)(f), (CHAR*)"../../src/library/Files.Mod", 28, (CHAR*)"Files", 6, 262, 30, 9667))->memory != NIL);
}

BOOLEAN Files_MemoryFailed (Files_File f)
{
	return f == NIL || (((Files_File)__NIL_AT((ADDRESS)(f), (CHAR*)"../../src/library/Files.Mod", 28, (CHAR*)"Files", 6, 266, 32, 9831))->memory != NIL && ((Files_File)__NIL_AT((ADDRESS)(f), (CHAR*)"../../src/library/Files.Mod", 28, (CHAR*)"Files", 6, 266, 50, 9849))->memoryFailed);
}

Files_Bytes Files_MemoryData (Files_File f, INT32 *length)
{
	*length = 0;
	if (!Files_IsMemory(f) || ((Files_File)__NIL_AT((ADDRESS)(f), (CHAR*)"../../src/library/Files.Mod", 28, (CHAR*)"Files", 6, 273, 25, 10144))->memoryFailed) {
		return NIL;
	}
	*length = ((Files_File)__NIL_AT((ADDRESS)(f), (CHAR*)"../../src/library/Files.Mod", 28, (CHAR*)"Files", 6, 274, 16, 10194))->len;
	return ((Files_File)__NIL_AT((ADDRESS)(f), (CHAR*)"../../src/library/Files.Mod", 28, (CHAR*)"Files", 6, 274, 30, 10208))->memory;
}

static void Files_ScanPath (INT16 *pos, CHAR *dir, ADDRESS dir__len)
{
	INT16 i;
	CHAR ch;
	i = 0;
	if (Files_SearchPath == NIL) {
		if (*pos == 0) {
			dir[0] = '.';
			i = 1;
			*pos += 1;
		}
	} else {
		ch = (((struct {
			ADDRESS len[1];
			CHAR data[1];
		} *)__NIL_AT((ADDRESS)(Files_SearchPath), (CHAR*)"../../src/library/Files.Mod", 28, (CHAR*)"Files", 6, 289, 23, 10693))->data)[__X_AT(*pos, ((struct {
			ADDRESS len[1];
			CHAR data[1];
		} *)__NIL_AT((ADDRESS)(Files_SearchPath), (CHAR*)"../../src/library/Files.Mod", 28, (CHAR*)"Files", 6, 289, 23, 10693))->len[0], (CHAR*)"../../src/library/Files.Mod", 28, (CHAR*)"Files", 6, 289, 24, 10694)];
		while (ch == ' ' || ch == ';') {
			*pos += 1;
			ch = (((struct {
				ADDRESS len[1];
				CHAR data[1];
			} *)__NIL_AT((ADDRESS)(Files_SearchPath), (CHAR*)"../../src/library/Files.Mod", 28, (CHAR*)"Files", 6, 290, 67, 10766))->data)[__X_AT(*pos, ((struct {
				ADDRESS len[1];
				CHAR data[1];
			} *)__NIL_AT((ADDRESS)(Files_SearchPath), (CHAR*)"../../src/library/Files.Mod", 28, (CHAR*)"Files", 6, 290, 67, 10766))->len[0], (CHAR*)"../../src/library/Files.Mod", 28, (CHAR*)"Files", 6, 290, 68, 10767)];
		}
		if (ch == '~') {
			*pos += 1;
			ch = (((struct {
				ADDRESS len[1];
				CHAR data[1];
			} *)__NIL_AT((ADDRESS)(Files_SearchPath), (CHAR*)"../../src/library/Files.Mod", 28, (CHAR*)"Files", 6, 292, 35, 10834))->data)[__X_AT(*pos, ((struct {
				ADDRESS len[1];
				CHAR data[1];
			} *)__NIL_AT((ADDRESS)(Files_SearchPath), (CHAR*)"../../src/library/Files.Mod", 28, (CHAR*)"Files", 6, 292, 35, 10834))->len[0], (CHAR*)"../../src/library/Files.Mod", 28, (CHAR*)"Files", 6, 292, 36, 10835)];
			while (Files_HOME[__X_AT(i, 1024, (CHAR*)"../../src/library/Files.Mod", 28, (CHAR*)"Files", 6, 293, 20, 10860)] != 0x00) {
				dir[__X_AT(i, dir__len, (CHAR*)"../../src/library/Files.Mod", 28, (CHAR*)"Files", 6, 293, 35, 10875)] = Files_HOME[__X_AT(i, 1024, (CHAR*)"../../src/library/Files.Mod", 28, (CHAR*)"Files", 6, 293, 46, 10886)];
				i += 1;
			}
			if ((((((ch != '/' && ch != 0x00)) && ch != ';')) && ch != ' ')) {
				while ((i > 0 && dir[__X_AT(i - 1, dir__len, (CHAR*)"../../src/library/Files.Mod", 28, (CHAR*)"Files", 6, 295, 32, 10998)] != '/')) {
					i -= 1;
				}
			}
		}
		while ((ch != 0x00 && ch != ';')) {
			dir[__X_AT(i, dir__len, (CHAR*)"../../src/library/Files.Mod", 28, (CHAR*)"Files", 6, 298, 43, 11089)] = ch;
			i += 1;
			*pos += 1;
			ch = (((struct {
				ADDRESS len[1];
				CHAR data[1];
			} *)__NIL_AT((ADDRESS)(Files_SearchPath), (CHAR*)"../../src/library/Files.Mod", 28, (CHAR*)"Files", 6, 298, 87, 11133))->data)[__X_AT(*pos, ((struct {
				ADDRESS len[1];
				CHAR data[1];
			} *)__NIL_AT((ADDRESS)(Files_SearchPath), (CHAR*)"../../src/library/Files.Mod", 28, (CHAR*)"Files", 6, 298, 87, 11133))->len[0], (CHAR*)"../../src/library/Files.Mod", 28, (CHAR*)"Files", 6, 298, 88, 11134)];
		}
		while ((i > 0 && dir[__X_AT(i - 1, dir__len, (CHAR*)"../../src/library/Files.Mod", 28, (CHAR*)"Files", 6, 299, 28, 11171)] == ' ')) {
			i -= 1;
		}
	}
	dir[__X_AT(i, dir__len, (CHAR*)"../../src/library/Files.Mod", 28, (CHAR*)"Files", 6, 301, 9, 11214)] = 0x00;
}

static BOOLEAN Files_HasDir (CHAR *name, ADDRESS name__len)
{
	INT16 i;
	CHAR ch;
	i = 0;
	ch = name[0];
	while ((ch != 0x00 && ch != '/')) {
		i += 1;
		ch = name[__X_AT(i, name__len, (CHAR*)"../../src/library/Files.Mod", 28, (CHAR*)"Files", 6, 307, 56, 11410)];
	}
	return ch == '/';
}

static Files_File Files_CacheEntry (Platform_FileIdentity identity)
{
	Files_File f = NIL;
	INT16 i, error;
	f = (Files_File)Files_files;
	while (f != NIL) {
		if (Platform_SameFile(identity, ((Files_File)__NIL_AT((ADDRESS)(f), (CHAR*)"../../src/library/Files.Mod", 28, (CHAR*)"Files", 6, 315, 39, 11653))->identity)) {
			if (!Platform_SameFileTime(identity, ((Files_File)__NIL_AT((ADDRESS)(f), (CHAR*)"../../src/library/Files.Mod", 28, (CHAR*)"Files", 6, 316, 46, 11714))->identity)) {
				i = 0;
				while (i < 4) {
					if (((Files_File)__NIL_AT((ADDRESS)(f), (CHAR*)"../../src/library/Files.Mod", 28, (CHAR*)"Files", 6, 318, 17, 11785))->bufs[__X_AT(i, 4, (CHAR*)"../../src/library/Files.Mod", 28, (CHAR*)"Files", 6, 318, 23, 11791)] != NIL) {
						((Files_Buffer)__NIL_AT((ADDRESS)(((Files_File)__NIL_AT((ADDRESS)(f), (CHAR*)"../../src/library/Files.Mod", 28, (CHAR*)"Files", 6, 318, 38, 11806))->bufs[__X_AT(i, 4, (CHAR*)"../../src/library/Files.Mod", 28, (CHAR*)"Files", 6, 318, 44, 11812)]), (CHAR*)"../../src/library/Files.Mod", 28, (CHAR*)"Files", 6, 318, 46, 11814))->org = -1;
						((Files_File)__NIL_AT((ADDRESS)(f), (CHAR*)"../../src/library/Files.Mod", 28, (CHAR*)"Files", 6, 318, 59, 11827))->bufs[__X_AT(i, 4, (CHAR*)"../../src/library/Files.Mod", 28, (CHAR*)"Files", 6, 318, 65, 11833)] = NIL;
					}
					i += 1;
				}
				((Files_File)__NIL_AT((ADDRESS)(f), (CHAR*)"../../src/library/Files.Mod", 28, (CHAR*)"Files", 6, 321, 12, 11893))->swapper = -1;
				((Files_File)__NIL_AT((ADDRESS)(f), (CHAR*)"../../src/library/Files.Mod", 28, (CHAR*)"Files", 6, 321, 29, 11910))->identity = identity;
				error = Platform_Size(((Files_File)__NIL_AT((ADDRESS)(f), (CHAR*)"../../src/library/Files.Mod", 28, (CHAR*)"Files", 6, 322, 35, 11967))->fd, &((Files_File)__NIL_AT((ADDRESS)(f), (CHAR*)"../../src/library/Files.Mod", 28, (CHAR*)"Files", 6, 322, 41, 11973))->len);
			}
			return f;
		}
		f = (Files_File)((Files_File)__NIL_AT((ADDRESS)(f), (CHAR*)"../../src/library/Files.Mod", 28, (CHAR*)"Files", 6, 326, 13, 12033))->next;
	}
	return NIL;
}

static Files_File Files_OldFile (CHAR *name, ADDRESS name__len)
{
	Files_File f = NIL;
	INT64 fd;
	INT16 pos;
	BOOLEAN done;
	CHAR dir[256], path[256];
	INT16 error;
	Platform_FileIdentity identity;
	__DUP(name, name__len, CHAR);
	if (name[0] != 0x00) {
		if (Files_HasDir((void*)name, name__len)) {
			dir[0] = 0x00;
			__COPY(name, path, 256);
		} else {
			pos = 0;
			Files_ScanPath(&pos, (void*)dir, 256);
			Files_MakeFileName(dir, 256, name, name__len, (void*)path, 256);
			Files_ScanPath(&pos, (void*)dir, 256);
		}
		for (;;) {
			error = Platform_OldRW((void*)path, 256, &fd);
			done = error == 0;
			if ((!done && Platform_TooManyFiles(error))) {
				Files_Err((CHAR*)"too many files open", 20, f, error);
			}
			if ((!done && Platform_Inaccessible(error))) {
				error = Platform_OldRO((void*)path, 256, &fd);
				done = error == 0;
			}
			if ((!done && !Platform_Absent(error))) {
				Out_String((CHAR*)"Warning: Files.Old ", 20);
				Out_String(name, name__len);
				Out_String((CHAR*)" error = ", 10);
				Out_Int(error, 0);
				Out_Ln();
			}
			if (done) {
				error = Platform_Identify(fd, &identity, Platform_FileIdentity__typ);
				f = Files_CacheEntry(identity);
				if (f != NIL) {
					error = Platform_Close(fd);
					__DEL(name);
					return f;
				} else {
					__NEW(f, Files_FileDesc);
					Heap_RegisterFinalizer((void*)f, Files_Finalize);
					((Files_File)__NIL_AT((ADDRESS)(f), (CHAR*)"../../src/library/Files.Mod", 28, (CHAR*)"Files", 6, 364, 14, 13473))->fd = fd;
					((Files_File)__NIL_AT((ADDRESS)(f), (CHAR*)"../../src/library/Files.Mod", 28, (CHAR*)"Files", 6, 364, 26, 13485))->state = 0;
					((Files_File)__NIL_AT((ADDRESS)(f), (CHAR*)"../../src/library/Files.Mod", 28, (CHAR*)"Files", 6, 364, 43, 13502))->pos = 0;
					((Files_File)__NIL_AT((ADDRESS)(f), (CHAR*)"../../src/library/Files.Mod", 28, (CHAR*)"Files", 6, 364, 55, 13514))->swapper = -1;
					error = Platform_Size(fd, &((Files_File)__NIL_AT((ADDRESS)(f), (CHAR*)"../../src/library/Files.Mod", 28, (CHAR*)"Files", 6, 365, 41, 13593))->len);
					__COPY(name, ((Files_File)__NIL_AT((ADDRESS)(f), (CHAR*)"../../src/library/Files.Mod", 28, (CHAR*)"Files", 6, 366, 25, 13624))->workName, 256);
					((Files_File)__NIL_AT((ADDRESS)(f), (CHAR*)"../../src/library/Files.Mod", 28, (CHAR*)"Files", 6, 366, 38, 13637))->registerName[0] = 0x00;
					((Files_File)__NIL_AT((ADDRESS)(f), (CHAR*)"../../src/library/Files.Mod", 28, (CHAR*)"Files", 6, 366, 60, 13659))->tempFile = 0;
					((Files_File)__NIL_AT((ADDRESS)(f), (CHAR*)"../../src/library/Files.Mod", 28, (CHAR*)"Files", 6, 367, 14, 13692))->identity = identity;
					((Files_File)__NIL_AT((ADDRESS)(f), (CHAR*)"../../src/library/Files.Mod", 28, (CHAR*)"Files", 6, 368, 14, 13728))->next = Files_files;
					Files_files = f;
					Heap_FileCount += 1;
					__DEL(name);
					return f;
				}
			} else if (dir[0] == 0x00) {
				__DEL(name);
				return NIL;
			} else {
				Files_MakeFileName(dir, 256, name, name__len, (void*)path, 256);
				Files_ScanPath(&pos, (void*)dir, 256);
			}
		}
	} else {
		__DEL(name);
		return NIL;
	}
	__RETCHK;
}

Files_File Files_Old (CHAR *name, ADDRESS name__len)
{
	Files_File f = NIL;
	__DUP(name, name__len, CHAR);
	Platform_CommandCritical(1);
	f = Files_OldFile(name, name__len);
	Platform_CommandCritical(0);
	__DEL(name);
	return f;
}

void Files_Purge (Files_File f)
{
	INT16 i;
	Platform_FileIdentity identity;
	INT16 error;
	if (((Files_File)__NIL_AT((ADDRESS)(f), (CHAR*)"../../src/library/Files.Mod", 28, (CHAR*)"Files", 6, 390, 9, 14365))->memory != NIL) {
		((Files_File)__NIL_AT((ADDRESS)(f), (CHAR*)"../../src/library/Files.Mod", 28, (CHAR*)"Files", 6, 390, 29, 14385))->len = 0;
		((Files_File)__NIL_AT((ADDRESS)(f), (CHAR*)"../../src/library/Files.Mod", 28, (CHAR*)"Files", 6, 390, 41, 14397))->memoryFailed = 0;
		return;
	}
	Platform_CommandCritical(1);
	i = 0;
	while (i < 4) {
		if (((Files_File)__NIL_AT((ADDRESS)(f), (CHAR*)"../../src/library/Files.Mod", 28, (CHAR*)"Files", 6, 393, 11, 14512))->bufs[__X_AT(i, 4, (CHAR*)"../../src/library/Files.Mod", 28, (CHAR*)"Files", 6, 393, 17, 14518)] != NIL) {
			((Files_Buffer)__NIL_AT((ADDRESS)(((Files_File)__NIL_AT((ADDRESS)(f), (CHAR*)"../../src/library/Files.Mod", 28, (CHAR*)"Files", 6, 393, 32, 14533))->bufs[__X_AT(i, 4, (CHAR*)"../../src/library/Files.Mod", 28, (CHAR*)"Files", 6, 393, 38, 14539)]), (CHAR*)"../../src/library/Files.Mod", 28, (CHAR*)"Files", 6, 393, 40, 14541))->org = -1;
			((Files_File)__NIL_AT((ADDRESS)(f), (CHAR*)"../../src/library/Files.Mod", 28, (CHAR*)"Files", 6, 393, 53, 14554))->bufs[__X_AT(i, 4, (CHAR*)"../../src/library/Files.Mod", 28, (CHAR*)"Files", 6, 393, 59, 14560)] = NIL;
		}
		i += 1;
	}
	if (((Files_File)__NIL_AT((ADDRESS)(f), (CHAR*)"../../src/library/Files.Mod", 28, (CHAR*)"Files", 6, 396, 9, 14605))->fd != -1) {
		error = Platform_Truncate(((Files_File)__NIL_AT((ADDRESS)(f), (CHAR*)"../../src/library/Files.Mod", 28, (CHAR*)"Files", 6, 397, 35, 14657))->fd, 0);
		error = Platform_Seek(((Files_File)__NIL_AT((ADDRESS)(f), (CHAR*)"../../src/library/Files.Mod", 28, (CHAR*)"Files", 6, 398, 31, 14696))->fd, 0, Platform_SeekSet);
	}
	((Files_File)__NIL_AT((ADDRESS)(f), (CHAR*)"../../src/library/Files.Mod", 28, (CHAR*)"Files", 6, 400, 6, 14736))->pos = 0;
	((Files_File)__NIL_AT((ADDRESS)(f), (CHAR*)"../../src/library/Files.Mod", 28, (CHAR*)"Files", 6, 400, 18, 14748))->len = 0;
	((Files_File)__NIL_AT((ADDRESS)(f), (CHAR*)"../../src/library/Files.Mod", 28, (CHAR*)"Files", 6, 400, 30, 14760))->swapper = -1;
	error = Platform_Identify(((Files_File)__NIL_AT((ADDRESS)(f), (CHAR*)"../../src/library/Files.Mod", 28, (CHAR*)"Files", 6, 401, 33, 14808))->fd, &identity, Platform_FileIdentity__typ);
	Platform_SetMTime(&((Files_File)__NIL_AT((ADDRESS)(f), (CHAR*)"../../src/library/Files.Mod", 28, (CHAR*)"Files", 6, 401, 68, 14843))->identity, Platform_FileIdentity__typ, identity);
	Platform_CommandCritical(0);
}

void Files_GetDate (Files_File f, INT32 *t, INT32 *d)
{
	Platform_FileIdentity identity;
	INT16 error;
	if (((Files_File)__NIL_AT((ADDRESS)(f), (CHAR*)"../../src/library/Files.Mod", 28, (CHAR*)"Files", 6, 409, 9, 15057))->memory != NIL) {
		*t = 0;
		*d = 0;
		return;
	}
	Platform_CommandCritical(1);
	Files_Create(f);
	error = Platform_Identify(((Files_File)__NIL_AT((ADDRESS)(f), (CHAR*)"../../src/library/Files.Mod", 28, (CHAR*)"Files", 6, 411, 44, 15183))->fd, &identity, Platform_FileIdentity__typ);
	Platform_MTimeAsClock(identity, &*t, &*d);
	Platform_CommandCritical(0);
}

INT32 Files_Pos (Files_Rider *r, ADDRESS *r__typ)
{
	if (((*r).buf != NIL && ((Files_File)__NIL_AT((ADDRESS)(((Files_Buffer)__NIL_AT((ADDRESS)((*r).buf), (CHAR*)"../../src/library/Files.Mod", 28, (CHAR*)"Files", 6, 418, 30, 15373))->f), (CHAR*)"../../src/library/Files.Mod", 28, (CHAR*)"Files", 6, 418, 32, 15375))->memory != NIL)) {
		return (*r).offset;
	}
	Files_Assert((*r).offset <= 4096);
	return (*r).org + (*r).offset;
}

void Files_Set (Files_Rider *r, ADDRESS *r__typ, Files_File f, INT32 pos)
{
	INT32 org, offset, i, n;
	Files_Buffer buf = NIL;
	INT16 error;
	if ((f != NIL && ((Files_File)__NIL_AT((ADDRESS)(f), (CHAR*)"../../src/library/Files.Mod", 28, (CHAR*)"Files", 6, 426, 22, 15652))->memory != NIL)) {
		if (pos < 0) {
			pos = 0;
		} else if (pos > ((Files_File)__NIL_AT((ADDRESS)(f), (CHAR*)"../../src/library/Files.Mod", 28, (CHAR*)"Files", 6, 427, 45, 15716))->len) {
			pos = ((Files_File)__NIL_AT((ADDRESS)(f), (CHAR*)"../../src/library/Files.Mod", 28, (CHAR*)"Files", 6, 427, 63, 15734))->len;
		}
		if (((Files_File)__NIL_AT((ADDRESS)(f), (CHAR*)"../../src/library/Files.Mod", 28, (CHAR*)"Files", 6, 428, 11, 15754))->bufs[0] == NIL) {
			__NEW(((Files_File)__NIL_AT((ADDRESS)(f), (CHAR*)"../../src/library/Files.Mod", 28, (CHAR*)"Files", 6, 428, 36, 15779))->bufs[0], Files_BufDesc);
			((Files_Buffer)__NIL_AT((ADDRESS)(((Files_File)__NIL_AT((ADDRESS)(f), (CHAR*)"../../src/library/Files.Mod", 28, (CHAR*)"Files", 6, 428, 48, 15791))->bufs[0]), (CHAR*)"../../src/library/Files.Mod", 28, (CHAR*)"Files", 6, 428, 56, 15799))->f = f;
		}
		(*r).buf = ((Files_File)__NIL_AT((ADDRESS)(f), (CHAR*)"../../src/library/Files.Mod", 28, (CHAR*)"Files", 6, 429, 17, 15828))->bufs[0];
		(*r).org = 0;
		(*r).offset = pos;
		(*r).eof = 0;
		(*r).res = 0;
		return;
	}
	Platform_CommandCritical(1);
	if (f != NIL) {
		if (pos > ((Files_File)__NIL_AT((ADDRESS)(f), (CHAR*)"../../src/library/Files.Mod", 28, (CHAR*)"Files", 6, 434, 17, 15989))->len) {
			pos = ((Files_File)__NIL_AT((ADDRESS)(f), (CHAR*)"../../src/library/Files.Mod", 28, (CHAR*)"Files", 6, 434, 35, 16007))->len;
		} else if (pos < 0) {
			pos = 0;
		}
		offset = __MASK(pos, -4096);
		org = pos - offset;
		i = 0;
		while ((((i < 4 && ((Files_File)__NIL_AT((ADDRESS)(f), (CHAR*)"../../src/library/Files.Mod", 28, (CHAR*)"Files", 6, 436, 31, 16137))->bufs[__X_AT(i, 4, (CHAR*)"../../src/library/Files.Mod", 28, (CHAR*)"Files", 6, 436, 37, 16143)] != NIL)) && org != ((Files_Buffer)__NIL_AT((ADDRESS)(((Files_File)__NIL_AT((ADDRESS)(f), (CHAR*)"../../src/library/Files.Mod", 28, (CHAR*)"Files", 6, 436, 57, 16163))->bufs[__X_AT(i, 4, (CHAR*)"../../src/library/Files.Mod", 28, (CHAR*)"Files", 6, 436, 63, 16169)]), (CHAR*)"../../src/library/Files.Mod", 28, (CHAR*)"Files", 6, 436, 65, 16171))->org)) {
			i += 1;
		}
		if (i < 4) {
			if (((Files_File)__NIL_AT((ADDRESS)(f), (CHAR*)"../../src/library/Files.Mod", 28, (CHAR*)"Files", 6, 438, 13, 16230))->bufs[__X_AT(i, 4, (CHAR*)"../../src/library/Files.Mod", 28, (CHAR*)"Files", 6, 438, 19, 16236)] == NIL) {
				__NEW(buf, Files_BufDesc);
				((Files_Buffer)__NIL_AT((ADDRESS)(buf), (CHAR*)"../../src/library/Files.Mod", 28, (CHAR*)"Files", 6, 439, 24, 16273))->chg = 0;
				((Files_Buffer)__NIL_AT((ADDRESS)(buf), (CHAR*)"../../src/library/Files.Mod", 28, (CHAR*)"Files", 6, 439, 42, 16291))->org = -1;
				((Files_Buffer)__NIL_AT((ADDRESS)(buf), (CHAR*)"../../src/library/Files.Mod", 28, (CHAR*)"Files", 6, 439, 57, 16306))->f = f;
				((Files_File)__NIL_AT((ADDRESS)(f), (CHAR*)"../../src/library/Files.Mod", 28, (CHAR*)"Files", 6, 439, 67, 16316))->bufs[__X_AT(i, 4, (CHAR*)"../../src/library/Files.Mod", 28, (CHAR*)"Files", 6, 439, 73, 16322)] = buf;
			} else {
				buf = ((Files_File)__NIL_AT((ADDRESS)(f), (CHAR*)"../../src/library/Files.Mod", 28, (CHAR*)"Files", 6, 440, 22, 16353))->bufs[__X_AT(i, 4, (CHAR*)"../../src/library/Files.Mod", 28, (CHAR*)"Files", 6, 440, 28, 16359)];
			}
		} else {
			((Files_File)__NIL_AT((ADDRESS)(f), (CHAR*)"../../src/library/Files.Mod", 28, (CHAR*)"Files", 6, 443, 10, 16394))->swapper = __MASK(((Files_File)__NIL_AT((ADDRESS)(f), (CHAR*)"../../src/library/Files.Mod", 28, (CHAR*)"Files", 6, 443, 24, 16408))->swapper + 1, -4);
			buf = ((Files_File)__NIL_AT((ADDRESS)(f), (CHAR*)"../../src/library/Files.Mod", 28, (CHAR*)"Files", 6, 444, 17, 16451))->bufs[__X_AT(((Files_File)__NIL_AT((ADDRESS)(f), (CHAR*)"../../src/library/Files.Mod", 28, (CHAR*)"Files", 6, 444, 24, 16458))->swapper, 4, (CHAR*)"../../src/library/Files.Mod", 28, (CHAR*)"Files", 6, 444, 23, 16457)];
			Files_Flush(buf);
		}
		if (((Files_Buffer)__NIL_AT((ADDRESS)(buf), (CHAR*)"../../src/library/Files.Mod", 28, (CHAR*)"Files", 6, 447, 13, 16511))->org != org) {
			if (org == ((Files_File)__NIL_AT((ADDRESS)(f), (CHAR*)"../../src/library/Files.Mod", 28, (CHAR*)"Files", 6, 448, 19, 16545))->len) {
				((Files_Buffer)__NIL_AT((ADDRESS)(buf), (CHAR*)"../../src/library/Files.Mod", 28, (CHAR*)"Files", 6, 448, 32, 16558))->size = 0;
			} else {
				Files_Create(f);
				if (((Files_File)__NIL_AT((ADDRESS)(f), (CHAR*)"../../src/library/Files.Mod", 28, (CHAR*)"Files", 6, 450, 15, 16607))->pos != org) {
					error = Platform_Seek(((Files_File)__NIL_AT((ADDRESS)(f), (CHAR*)"../../src/library/Files.Mod", 28, (CHAR*)"Files", 6, 450, 55, 16647))->fd, org, Platform_SeekSet);
				}
				error = Platform_ReadBuf(((Files_File)__NIL_AT((ADDRESS)(f), (CHAR*)"../../src/library/Files.Mod", 28, (CHAR*)"Files", 6, 451, 38, 16717))->fd, (void*)((Files_Buffer)__NIL_AT((ADDRESS)(buf), (CHAR*)"../../src/library/Files.Mod", 28, (CHAR*)"Files", 6, 451, 46, 16725))->data, 4096, &n);
				if (error != 0) {
					Files_Err((CHAR*)"read from file not done", 24, f, error);
				}
				((Files_File)__NIL_AT((ADDRESS)(f), (CHAR*)"../../src/library/Files.Mod", 28, (CHAR*)"Files", 6, 453, 12, 16821))->pos = org + n;
				((Files_Buffer)__NIL_AT((ADDRESS)(buf), (CHAR*)"../../src/library/Files.Mod", 28, (CHAR*)"Files", 6, 454, 14, 16851))->size = n;
			}
			((Files_Buffer)__NIL_AT((ADDRESS)(buf), (CHAR*)"../../src/library/Files.Mod", 28, (CHAR*)"Files", 6, 456, 12, 16886))->org = org;
			((Files_Buffer)__NIL_AT((ADDRESS)(buf), (CHAR*)"../../src/library/Files.Mod", 28, (CHAR*)"Files", 6, 456, 28, 16902))->chg = 0;
		}
	} else {
		buf = NIL;
		org = 0;
		offset = 0;
	}
	Files_Assert(offset <= 4096);
	(*r).buf = buf;
	(*r).org = org;
	(*r).offset = offset;
	(*r).eof = 0;
	(*r).res = 0;
	Platform_CommandCritical(0);
}

void Files_Read (Files_Rider *r, ADDRESS *r__typ, SYSTEM_BYTE *x)
{
	INT32 offset;
	Files_Buffer buf = NIL;
	if (((Files_File)__NIL_AT((ADDRESS)(((Files_Buffer)__NIL_AT((ADDRESS)((*r).buf), (CHAR*)"../../src/library/Files.Mod", 28, (CHAR*)"Files", 6, 468, 13, 17249))->f), (CHAR*)"../../src/library/Files.Mod", 28, (CHAR*)"Files", 6, 468, 15, 17251))->memory != NIL) {
		if ((*r).offset < ((Files_File)__NIL_AT((ADDRESS)(((Files_Buffer)__NIL_AT((ADDRESS)((*r).buf), (CHAR*)"../../src/library/Files.Mod", 28, (CHAR*)"Files", 6, 469, 26, 17295))->f), (CHAR*)"../../src/library/Files.Mod", 28, (CHAR*)"Files", 6, 469, 28, 17297))->len) {
			*x = (((Files_Bytes)__NIL_AT((ADDRESS)(((Files_File)__NIL_AT((ADDRESS)(((Files_Buffer)__NIL_AT((ADDRESS)((*r).buf), (CHAR*)"../../src/library/Files.Mod", 28, (CHAR*)"Files", 6, 470, 19, 17325))->f), (CHAR*)"../../src/library/Files.Mod", 28, (CHAR*)"Files", 6, 470, 21, 17327))->memory), (CHAR*)"../../src/library/Files.Mod", 28, (CHAR*)"Files", 6, 470, 28, 17334))->data)[__X_AT((*r).offset, ((Files_Bytes)__NIL_AT((ADDRESS)(((Files_File)__NIL_AT((ADDRESS)(((Files_Buffer)__NIL_AT((ADDRESS)((*r).buf), (CHAR*)"../../src/library/Files.Mod", 28, (CHAR*)"Files", 6, 470, 19, 17325))->f), (CHAR*)"../../src/library/Files.Mod", 28, (CHAR*)"Files", 6, 470, 21, 17327))->memory), (CHAR*)"../../src/library/Files.Mod", 28, (CHAR*)"Files", 6, 470, 28, 17334))->len[0], (CHAR*)"../../src/library/Files.Mod", 28, (CHAR*)"Files", 6, 470, 29, 17335)];
			(*r).offset += 1;
			(*r).eof = 0;
		} else {
			*x = 0x00;
			(*r).eof = 1;
		}
		return;
	}
	Platform_CommandCritical(1);
	buf = (*r).buf;
	offset = (*r).offset;
	if ((*r).org != ((Files_Buffer)__NIL_AT((ADDRESS)(buf), (CHAR*)"../../src/library/Files.Mod", 28, (CHAR*)"Files", 6, 477, 19, 17535))->org) {
		Files_Set(&*r, r__typ, ((Files_Buffer)__NIL_AT((ADDRESS)(buf), (CHAR*)"../../src/library/Files.Mod", 28, (CHAR*)"Files", 6, 478, 17, 17561))->f, (*r).org + offset);
		buf = (*r).buf;
		offset = (*r).offset;
	}
	Files_Assert(offset <= ((Files_Buffer)__NIL_AT((ADDRESS)(buf), (CHAR*)"../../src/library/Files.Mod", 28, (CHAR*)"Files", 6, 480, 25, 17648))->size);
	if (offset < ((Files_Buffer)__NIL_AT((ADDRESS)(buf), (CHAR*)"../../src/library/Files.Mod", 28, (CHAR*)"Files", 6, 481, 21, 17676))->size) {
		*x = ((Files_Buffer)__NIL_AT((ADDRESS)(buf), (CHAR*)"../../src/library/Files.Mod", 28, (CHAR*)"Files", 6, 482, 15, 17702))->data[__X_AT(offset, 4096, (CHAR*)"../../src/library/Files.Mod", 28, (CHAR*)"Files", 6, 482, 21, 17708)];
		(*r).offset = offset + 1;
	} else if ((*r).org + offset < ((Files_File)__NIL_AT((ADDRESS)(((Files_Buffer)__NIL_AT((ADDRESS)(buf), (CHAR*)"../../src/library/Files.Mod", 28, (CHAR*)"Files", 6, 483, 31, 17770))->f), (CHAR*)"../../src/library/Files.Mod", 28, (CHAR*)"Files", 6, 483, 33, 17772))->len) {
		Files_Set(&*r, r__typ, ((Files_Buffer)__NIL_AT((ADDRESS)((*r).buf), (CHAR*)"../../src/library/Files.Mod", 28, (CHAR*)"Files", 6, 484, 19, 17800))->f, (*r).org + offset);
		*x = ((Files_Buffer)__NIL_AT((ADDRESS)((*r).buf), (CHAR*)"../../src/library/Files.Mod", 28, (CHAR*)"Files", 6, 485, 17, 17837))->data[0];
		(*r).offset = 1;
	} else {
		*x = 0x00;
		(*r).eof = 1;
	}
	Platform_CommandCritical(0);
}

void Files_ReadByte (Files_Rider *r, ADDRESS *r__typ, SYSTEM_BYTE *x)
{
	Files_Read(&*r, r__typ, &*x);
}

void Files_ReadBytes (Files_Rider *r, ADDRESS *r__typ, SYSTEM_BYTE *x, ADDRESS x__len, INT32 n)
{
	INT32 xpos, min, restInBuf, offset;
	Files_Buffer buf = NIL;
	if (((Files_File)__NIL_AT((ADDRESS)(((Files_Buffer)__NIL_AT((ADDRESS)((*r).buf), (CHAR*)"../../src/library/Files.Mod", 28, (CHAR*)"Files", 6, 501, 13, 18276))->f), (CHAR*)"../../src/library/Files.Mod", 28, (CHAR*)"Files", 6, 501, 15, 18278))->memory != NIL) {
		if (n > x__len) {
			Files_IdxTrap();
		}
		xpos = 0;
		while ((xpos < n && (*r).offset < ((Files_File)__NIL_AT((ADDRESS)(((Files_Buffer)__NIL_AT((ADDRESS)((*r).buf), (CHAR*)"../../src/library/Files.Mod", 28, (CHAR*)"Files", 6, 504, 43, 18394))->f), (CHAR*)"../../src/library/Files.Mod", 28, (CHAR*)"Files", 6, 504, 45, 18396))->len)) {
			x[__X_AT(xpos, x__len, (CHAR*)"../../src/library/Files.Mod", 28, (CHAR*)"Files", 6, 505, 11, 18415)] = (((Files_Bytes)__NIL_AT((ADDRESS)(((Files_File)__NIL_AT((ADDRESS)(((Files_Buffer)__NIL_AT((ADDRESS)((*r).buf), (CHAR*)"../../src/library/Files.Mod", 28, (CHAR*)"Files", 6, 505, 25, 18429))->f), (CHAR*)"../../src/library/Files.Mod", 28, (CHAR*)"Files", 6, 505, 27, 18431))->memory), (CHAR*)"../../src/library/Files.Mod", 28, (CHAR*)"Files", 6, 505, 34, 18438))->data)[__X_AT((*r).offset, ((Files_Bytes)__NIL_AT((ADDRESS)(((Files_File)__NIL_AT((ADDRESS)(((Files_Buffer)__NIL_AT((ADDRESS)((*r).buf), (CHAR*)"../../src/library/Files.Mod", 28, (CHAR*)"Files", 6, 505, 25, 18429))->f), (CHAR*)"../../src/library/Files.Mod", 28, (CHAR*)"Files", 6, 505, 27, 18431))->memory), (CHAR*)"../../src/library/Files.Mod", 28, (CHAR*)"Files", 6, 505, 34, 18438))->len[0], (CHAR*)"../../src/library/Files.Mod", 28, (CHAR*)"Files", 6, 505, 35, 18439)];
			xpos += 1;
			(*r).offset += 1;
		}
		if (n > xpos) {
			(*r).res = n - xpos;
			(*r).eof = 1;
		} else {
			(*r).res = 0;
			(*r).eof = 0;
		}
		return;
	}
	Platform_CommandCritical(1);
	if (n > x__len) {
		Files_IdxTrap();
	}
	xpos = 0;
	buf = (*r).buf;
	offset = (*r).offset;
	while (n > 0) {
		if ((*r).org != ((Files_Buffer)__NIL_AT((ADDRESS)(buf), (CHAR*)"../../src/library/Files.Mod", 28, (CHAR*)"Files", 6, 516, 22, 18809))->org || offset >= 4096) {
			Files_Set(&*r, r__typ, ((Files_Buffer)__NIL_AT((ADDRESS)(buf), (CHAR*)"../../src/library/Files.Mod", 28, (CHAR*)"Files", 6, 517, 19, 18861))->f, (*r).org + offset);
			buf = (*r).buf;
			offset = (*r).offset;
		}
		restInBuf = ((Files_Buffer)__NIL_AT((ADDRESS)(buf), (CHAR*)"../../src/library/Files.Mod", 28, (CHAR*)"Files", 6, 519, 23, 18948))->size - offset;
		if (restInBuf == 0) {
			(*r).res = n;
			(*r).eof = 1;
			Platform_CommandCritical(0);
			return;
		} else if (n > restInBuf) {
			min = restInBuf;
		} else {
			min = n;
		}
		__MOVE((ADDRESS)&((Files_Buffer)__NIL_AT((ADDRESS)(buf), (CHAR*)"../../src/library/Files.Mod", 28, (CHAR*)"Files", 6, 522, 33, 19158))->data[__X_AT(offset, 4096, (CHAR*)"../../src/library/Files.Mod", 28, (CHAR*)"Files", 6, 522, 39, 19164)], (ADDRESS)&x[__X_AT(xpos, x__len, (CHAR*)"../../src/library/Files.Mod", 28, (CHAR*)"Files", 6, 522, 62, 19187)], min);
		offset += min;
		(*r).offset = offset;
		xpos += min;
		n -= min;
		Files_Assert(offset <= 4096);
	}
	(*r).res = 0;
	(*r).eof = 0;
	Platform_CommandCritical(0);
}

Files_File Files_Base (Files_Rider *r, ADDRESS *r__typ)
{
	return ((Files_Buffer)__NIL_AT((ADDRESS)((*r).buf), (CHAR*)"../../src/library/Files.Mod", 28, (CHAR*)"Files", 6, 531, 21, 19461))->f;
}

void Files_Write (Files_Rider *r, ADDRESS *r__typ, SYSTEM_BYTE x)
{
	Files_Buffer buf = NIL;
	INT32 offset;
	if (((Files_File)__NIL_AT((ADDRESS)(((Files_Buffer)__NIL_AT((ADDRESS)((*r).buf), (CHAR*)"../../src/library/Files.Mod", 28, (CHAR*)"Files", 6, 537, 13, 19586))->f), (CHAR*)"../../src/library/Files.Mod", 28, (CHAR*)"Files", 6, 537, 15, 19588))->memory != NIL) {
		if ((*r).offset > ((Files_File)__NIL_AT((ADDRESS)(((Files_Buffer)__NIL_AT((ADDRESS)((*r).buf), (CHAR*)"../../src/library/Files.Mod", 28, (CHAR*)"Files", 6, 538, 26, 19632))->f), (CHAR*)"../../src/library/Files.Mod", 28, (CHAR*)"Files", 6, 538, 28, 19634))->len) {
			(*r).offset = ((Files_File)__NIL_AT((ADDRESS)(((Files_Buffer)__NIL_AT((ADDRESS)((*r).buf), (CHAR*)"../../src/library/Files.Mod", 28, (CHAR*)"Files", 6, 538, 55, 19661))->f), (CHAR*)"../../src/library/Files.Mod", 28, (CHAR*)"Files", 6, 538, 57, 19663))->len;
		}
		if (((Files_File)__NIL_AT((ADDRESS)(((Files_Buffer)__NIL_AT((ADDRESS)((*r).buf), (CHAR*)"../../src/library/Files.Mod", 28, (CHAR*)"Files", 6, 539, 15, 19687))->f), (CHAR*)"../../src/library/Files.Mod", 28, (CHAR*)"Files", 6, 539, 17, 19689))->memoryFailed || (*r).offset >= ((Files_File)__NIL_AT((ADDRESS)(((Files_Buffer)__NIL_AT((ADDRESS)((*r).buf), (CHAR*)"../../src/library/Files.Mod", 28, (CHAR*)"Files", 6, 539, 52, 19724))->f), (CHAR*)"../../src/library/Files.Mod", 28, (CHAR*)"Files", 6, 539, 54, 19726))->memoryCapacity) {
			((Files_File)__NIL_AT((ADDRESS)(((Files_Buffer)__NIL_AT((ADDRESS)((*r).buf), (CHAR*)"../../src/library/Files.Mod", 28, (CHAR*)"Files", 6, 540, 14, 19761))->f), (CHAR*)"../../src/library/Files.Mod", 28, (CHAR*)"Files", 6, 540, 16, 19763))->memoryFailed = 1;
			(*r).res = 1;
			return;
		}
		(((Files_Bytes)__NIL_AT((ADDRESS)(((Files_File)__NIL_AT((ADDRESS)(((Files_Buffer)__NIL_AT((ADDRESS)((*r).buf), (CHAR*)"../../src/library/Files.Mod", 28, (CHAR*)"Files", 6, 542, 12, 19827))->f), (CHAR*)"../../src/library/Files.Mod", 28, (CHAR*)"Files", 6, 542, 14, 19829))->memory), (CHAR*)"../../src/library/Files.Mod", 28, (CHAR*)"Files", 6, 542, 21, 19836))->data)[__X_AT((*r).offset, ((Files_Bytes)__NIL_AT((ADDRESS)(((Files_File)__NIL_AT((ADDRESS)(((Files_Buffer)__NIL_AT((ADDRESS)((*r).buf), (CHAR*)"../../src/library/Files.Mod", 28, (CHAR*)"Files", 6, 542, 12, 19827))->f), (CHAR*)"../../src/library/Files.Mod", 28, (CHAR*)"Files", 6, 542, 14, 19829))->memory), (CHAR*)"../../src/library/Files.Mod", 28, (CHAR*)"Files", 6, 542, 21, 19836))->len[0], (CHAR*)"../../src/library/Files.Mod", 28, (CHAR*)"Files", 6, 542, 22, 19837)] = __VAL(CHAR, x);
		(*r).offset += 1;
		if ((*r).offset > ((Files_File)__NIL_AT((ADDRESS)(((Files_Buffer)__NIL_AT((ADDRESS)((*r).buf), (CHAR*)"../../src/library/Files.Mod", 28, (CHAR*)"Files", 6, 543, 26, 19911))->f), (CHAR*)"../../src/library/Files.Mod", 28, (CHAR*)"Files", 6, 543, 28, 19913))->len) {
			((Files_File)__NIL_AT((ADDRESS)(((Files_Buffer)__NIL_AT((ADDRESS)((*r).buf), (CHAR*)"../../src/library/Files.Mod", 28, (CHAR*)"Files", 6, 543, 43, 19928))->f), (CHAR*)"../../src/library/Files.Mod", 28, (CHAR*)"Files", 6, 543, 45, 19930))->len = (*r).offset;
		}
		(*r).res = 0;
		return;
	}
	Platform_CommandCritical(1);
	buf = (*r).buf;
	offset = (*r).offset;
	Files_Assert(offset <= 4096);
	if ((*r).org != ((Files_Buffer)__NIL_AT((ADDRESS)(buf), (CHAR*)"../../src/library/Files.Mod", 28, (CHAR*)"Files", 6, 549, 20, 20110))->org || offset >= 4096) {
		Files_Set(&*r, r__typ, ((Files_Buffer)__NIL_AT((ADDRESS)(buf), (CHAR*)"../../src/library/Files.Mod", 28, (CHAR*)"Files", 6, 550, 17, 20160))->f, (*r).org + offset);
		buf = (*r).buf;
		offset = (*r).offset;
	}
	Files_Assert(offset < 4096);
	((Files_Buffer)__NIL_AT((ADDRESS)(buf), (CHAR*)"../../src/library/Files.Mod", 28, (CHAR*)"Files", 6, 554, 8, 20266))->data[__X_AT(offset, 4096, (CHAR*)"../../src/library/Files.Mod", 28, (CHAR*)"Files", 6, 554, 14, 20272)] = x;
	((Files_Buffer)__NIL_AT((ADDRESS)(buf), (CHAR*)"../../src/library/Files.Mod", 28, (CHAR*)"Files", 6, 555, 8, 20293))->chg = 1;
	if (offset == ((Files_Buffer)__NIL_AT((ADDRESS)(buf), (CHAR*)"../../src/library/Files.Mod", 28, (CHAR*)"Files", 6, 556, 20, 20326))->size) {
		((Files_Buffer)__NIL_AT((ADDRESS)(buf), (CHAR*)"../../src/library/Files.Mod", 28, (CHAR*)"Files", 6, 557, 14, 20350))->size += 1;
		((Files_File)__NIL_AT((ADDRESS)(((Files_Buffer)__NIL_AT((ADDRESS)(buf), (CHAR*)"../../src/library/Files.Mod", 28, (CHAR*)"Files", 6, 557, 29, 20365))->f), (CHAR*)"../../src/library/Files.Mod", 28, (CHAR*)"Files", 6, 557, 31, 20367))->len += 1;
	}
	(*r).offset = offset + 1;
	(*r).res = 0;
	Platform_CommandCritical(0);
}

void Files_WriteBytes (Files_Rider *r, ADDRESS *r__typ, SYSTEM_BYTE *x, ADDRESS x__len, INT32 n)
{
	INT32 xpos, min, restInBuf, offset;
	Files_Buffer buf = NIL;
	INT32 _for__54;
	if (((Files_File)__NIL_AT((ADDRESS)(((Files_Buffer)__NIL_AT((ADDRESS)((*r).buf), (CHAR*)"../../src/library/Files.Mod", 28, (CHAR*)"Files", 6, 566, 13, 20633))->f), (CHAR*)"../../src/library/Files.Mod", 28, (CHAR*)"Files", 6, 566, 15, 20635))->memory != NIL) {
		if (n > x__len) {
			Files_IdxTrap();
		}
		if (n <= 0) {
			(*r).res = 0;
			return;
		}
		if ((*r).offset > ((Files_File)__NIL_AT((ADDRESS)(((Files_Buffer)__NIL_AT((ADDRESS)((*r).buf), (CHAR*)"../../src/library/Files.Mod", 28, (CHAR*)"Files", 6, 569, 26, 20762))->f), (CHAR*)"../../src/library/Files.Mod", 28, (CHAR*)"Files", 6, 569, 28, 20764))->len) {
			(*r).offset = ((Files_File)__NIL_AT((ADDRESS)(((Files_Buffer)__NIL_AT((ADDRESS)((*r).buf), (CHAR*)"../../src/library/Files.Mod", 28, (CHAR*)"Files", 6, 569, 55, 20791))->f), (CHAR*)"../../src/library/Files.Mod", 28, (CHAR*)"Files", 6, 569, 57, 20793))->len;
		}
		if (((Files_File)__NIL_AT((ADDRESS)(((Files_Buffer)__NIL_AT((ADDRESS)((*r).buf), (CHAR*)"../../src/library/Files.Mod", 28, (CHAR*)"Files", 6, 570, 15, 20817))->f), (CHAR*)"../../src/library/Files.Mod", 28, (CHAR*)"Files", 6, 570, 17, 20819))->memoryFailed || n > ((Files_File)__NIL_AT((ADDRESS)(((Files_Buffer)__NIL_AT((ADDRESS)((*r).buf), (CHAR*)"../../src/library/Files.Mod", 28, (CHAR*)"Files", 6, 570, 44, 20846))->f), (CHAR*)"../../src/library/Files.Mod", 28, (CHAR*)"Files", 6, 570, 46, 20848))->memoryCapacity - (*r).offset) {
			((Files_File)__NIL_AT((ADDRESS)(((Files_Buffer)__NIL_AT((ADDRESS)((*r).buf), (CHAR*)"../../src/library/Files.Mod", 28, (CHAR*)"Files", 6, 571, 14, 20894))->f), (CHAR*)"../../src/library/Files.Mod", 28, (CHAR*)"Files", 6, 571, 16, 20896))->memoryFailed = 1;
			(*r).res = n;
			return;
		}
		_for__54 = n - 1;
		xpos = 0;
		while (xpos <= _for__54) {
			(((Files_Bytes)__NIL_AT((ADDRESS)(((Files_File)__NIL_AT((ADDRESS)(((Files_Buffer)__NIL_AT((ADDRESS)((*r).buf), (CHAR*)"../../src/library/Files.Mod", 28, (CHAR*)"Files", 6, 573, 38, 20986))->f), (CHAR*)"../../src/library/Files.Mod", 28, (CHAR*)"Files", 6, 573, 40, 20988))->memory), (CHAR*)"../../src/library/Files.Mod", 28, (CHAR*)"Files", 6, 573, 47, 20995))->data)[__X_AT((*r).offset, ((Files_Bytes)__NIL_AT((ADDRESS)(((Files_File)__NIL_AT((ADDRESS)(((Files_Buffer)__NIL_AT((ADDRESS)((*r).buf), (CHAR*)"../../src/library/Files.Mod", 28, (CHAR*)"Files", 6, 573, 38, 20986))->f), (CHAR*)"../../src/library/Files.Mod", 28, (CHAR*)"Files", 6, 573, 40, 20988))->memory), (CHAR*)"../../src/library/Files.Mod", 28, (CHAR*)"Files", 6, 573, 47, 20995))->len[0], (CHAR*)"../../src/library/Files.Mod", 28, (CHAR*)"Files", 6, 573, 48, 20996)] = __VAL(CHAR, x[__X_AT(xpos, x__len, (CHAR*)"../../src/library/Files.Mod", 28, (CHAR*)"Files", 6, 573, 80, 21028)]);
			(*r).offset += 1;
			xpos += 1;
		}
		if ((*r).offset > ((Files_File)__NIL_AT((ADDRESS)(((Files_Buffer)__NIL_AT((ADDRESS)((*r).buf), (CHAR*)"../../src/library/Files.Mod", 28, (CHAR*)"Files", 6, 574, 26, 21080))->f), (CHAR*)"../../src/library/Files.Mod", 28, (CHAR*)"Files", 6, 574, 28, 21082))->len) {
			((Files_File)__NIL_AT((ADDRESS)(((Files_Buffer)__NIL_AT((ADDRESS)((*r).buf), (CHAR*)"../../src/library/Files.Mod", 28, (CHAR*)"Files", 6, 574, 43, 21097))->f), (CHAR*)"../../src/library/Files.Mod", 28, (CHAR*)"Files", 6, 574, 45, 21099))->len = (*r).offset;
		}
		(*r).res = 0;
		return;
	}
	Platform_CommandCritical(1);
	if (n > x__len) {
		Files_IdxTrap();
	}
	xpos = 0;
	buf = (*r).buf;
	offset = (*r).offset;
	while (n > 0) {
		Files_Assert(offset <= 4096);
		if ((*r).org != ((Files_Buffer)__NIL_AT((ADDRESS)(buf), (CHAR*)"../../src/library/Files.Mod", 28, (CHAR*)"Files", 6, 582, 22, 21349))->org || offset >= 4096) {
			Files_Set(&*r, r__typ, ((Files_Buffer)__NIL_AT((ADDRESS)(buf), (CHAR*)"../../src/library/Files.Mod", 28, (CHAR*)"Files", 6, 583, 19, 21401))->f, (*r).org + offset);
			buf = (*r).buf;
			offset = (*r).offset;
		}
		Files_Assert(offset <= 4096);
		restInBuf = 4096 - offset;
		if (n > restInBuf) {
			min = restInBuf;
		} else {
			min = n;
		}
		__MOVE((ADDRESS)&x[__X_AT(xpos, x__len, (CHAR*)"../../src/library/Files.Mod", 28, (CHAR*)"Files", 6, 589, 32, 21639)], (ADDRESS)&((Files_Buffer)__NIL_AT((ADDRESS)(buf), (CHAR*)"../../src/library/Files.Mod", 28, (CHAR*)"Files", 6, 589, 54, 21661))->data[__X_AT(offset, 4096, (CHAR*)"../../src/library/Files.Mod", 28, (CHAR*)"Files", 6, 589, 60, 21667)], min);
		offset += min;
		(*r).offset = offset;
		Files_Assert(offset <= 4096);
		if (offset > ((Files_Buffer)__NIL_AT((ADDRESS)(buf), (CHAR*)"../../src/library/Files.Mod", 28, (CHAR*)"Files", 6, 592, 22, 21781))->size) {
			((Files_File)__NIL_AT((ADDRESS)(((Files_Buffer)__NIL_AT((ADDRESS)(buf), (CHAR*)"../../src/library/Files.Mod", 28, (CHAR*)"Files", 6, 592, 40, 21799))->f), (CHAR*)"../../src/library/Files.Mod", 28, (CHAR*)"Files", 6, 592, 42, 21801))->len += offset - ((Files_Buffer)__NIL_AT((ADDRESS)(buf), (CHAR*)"../../src/library/Files.Mod", 28, (CHAR*)"Files", 6, 592, 60, 21819))->size;
			((Files_Buffer)__NIL_AT((ADDRESS)(buf), (CHAR*)"../../src/library/Files.Mod", 28, (CHAR*)"Files", 6, 592, 71, 21830))->size = offset;
		}
		xpos += min;
		n -= min;
		((Files_Buffer)__NIL_AT((ADDRESS)(buf), (CHAR*)"../../src/library/Files.Mod", 28, (CHAR*)"Files", 6, 593, 39, 21889))->chg = 1;
	}
	(*r).res = 0;
	Platform_CommandCritical(0);
}

void Files_Delete (CHAR *name, ADDRESS name__len, INT16 *res)
{
	__DUP(name, name__len, CHAR);
	Platform_CommandCritical(1);
	Files_Deregister(name, name__len);
	*res = Platform_Unlink((void*)name, name__len);
	Platform_CommandCritical(0);
	__DEL(name);
}

static void Files_RenameFile (CHAR *old, ADDRESS old__len, CHAR *new, ADDRESS new__len, INT16 *res)
{
	INT64 fdold, fdnew;
	INT32 n;
	INT16 error, ignore;
	Platform_FileIdentity oldidentity, newidentity;
	CHAR buf[4096];
	__DUP(old, old__len, CHAR);
	__DUP(new, new__len, CHAR);
	error = Platform_IdentifyByName(old, old__len, &oldidentity, Platform_FileIdentity__typ);
	if (error == 0) {
		error = Platform_IdentifyByName(new, new__len, &newidentity, Platform_FileIdentity__typ);
		if ((error != 0 && !Platform_SameFile(oldidentity, newidentity))) {
			Files_Delete(new, new__len, &error);
		}
		error = Platform_Rename((void*)old, old__len, (void*)new, new__len);
		if (!Platform_DifferentFilesystems(error)) {
			*res = error;
			__DEL(old);
			__DEL(new);
			return;
		} else {
			error = Platform_OldRO((void*)old, old__len, &fdold);
			if (error != 0) {
				*res = 2;
				__DEL(old);
				__DEL(new);
				return;
			}
			error = Platform_New((void*)new, new__len, &fdnew);
			if (error != 0) {
				error = Platform_Close(fdold);
				*res = 3;
				__DEL(old);
				__DEL(new);
				return;
			}
			error = Platform_Read(fdold, (ADDRESS)buf, 4096, &n);
			while (n > 0) {
				error = Platform_Write(fdnew, (ADDRESS)buf, n);
				if (error != 0) {
					ignore = Platform_Close(fdold);
					ignore = Platform_Close(fdnew);
					Files_Err((CHAR*)"cannot move file", 17, NIL, error);
				}
				error = Platform_Read(fdold, (ADDRESS)buf, 4096, &n);
			}
			ignore = Platform_Close(fdold);
			ignore = Platform_Close(fdnew);
			if (n == 0) {
				error = Platform_Unlink((void*)old, old__len);
				*res = 0;
			} else {
				Files_Err((CHAR*)"cannot move file", 17, NIL, error);
			}
		}
	} else {
		*res = 2;
	}
	__DEL(old);
	__DEL(new);
}

void Files_Rename (CHAR *old, ADDRESS old__len, CHAR *new, ADDRESS new__len, INT16 *res)
{
	__DUP(old, old__len, CHAR);
	__DUP(new, new__len, CHAR);
	Platform_CommandCritical(1);
	Files_RenameFile(old, old__len, new, new__len, &*res);
	Platform_CommandCritical(0);
	__DEL(old);
	__DEL(new);
}

void Files_Register (Files_File f)
{
	INT16 idx, errcode;
	Files_File f1 = NIL;
	Platform_CommandCritical(1);
	if ((((Files_File)__NIL_AT((ADDRESS)(f), (CHAR*)"../../src/library/Files.Mod", 28, (CHAR*)"Files", 6, 699, 10, 25528))->state == 1 && ((Files_File)__NIL_AT((ADDRESS)(f), (CHAR*)"../../src/library/Files.Mod", 28, (CHAR*)"Files", 6, 699, 31, 25549))->registerName[0] != 0x00)) {
		((Files_File)__NIL_AT((ADDRESS)(f), (CHAR*)"../../src/library/Files.Mod", 28, (CHAR*)"Files", 6, 699, 57, 25575))->state = 2;
	}
	Files_Close(f);
	if (((Files_File)__NIL_AT((ADDRESS)(f), (CHAR*)"../../src/library/Files.Mod", 28, (CHAR*)"Files", 6, 701, 9, 25642))->registerName[0] != 0x00) {
		Files_Deregister(((Files_File)__NIL_AT((ADDRESS)(f), (CHAR*)"../../src/library/Files.Mod", 28, (CHAR*)"Files", 6, 702, 19, 25684))->registerName, 256);
		Files_Rename(((Files_File)__NIL_AT((ADDRESS)(f), (CHAR*)"../../src/library/Files.Mod", 28, (CHAR*)"Files", 6, 703, 15, 25714))->workName, 256, ((Files_File)__NIL_AT((ADDRESS)(f), (CHAR*)"../../src/library/Files.Mod", 28, (CHAR*)"Files", 6, 703, 27, 25726))->registerName, 256, &errcode);
		if (errcode != 0) {
			Files_Err((CHAR*)"Couldn't rename temp name as register name", 43, f, errcode);
		}
		__MOVE(((Files_File)__NIL_AT((ADDRESS)(f), (CHAR*)"../../src/library/Files.Mod", 28, (CHAR*)"Files", 6, 705, 22, 25865))->registerName, ((Files_File)__NIL_AT((ADDRESS)(f), (CHAR*)"../../src/library/Files.Mod", 28, (CHAR*)"Files", 6, 705, 8, 25851))->workName, 256);
		((Files_File)__NIL_AT((ADDRESS)(f), (CHAR*)"../../src/library/Files.Mod", 28, (CHAR*)"Files", 6, 705, 38, 25881))->registerName[0] = 0x00;
		((Files_File)__NIL_AT((ADDRESS)(f), (CHAR*)"../../src/library/Files.Mod", 28, (CHAR*)"Files", 6, 705, 60, 25903))->tempFile = 0;
	}
	Platform_CommandCritical(0);
}

void Files_ChangeDirectory (CHAR *path, ADDRESS path__len, INT16 *res)
{
	__DUP(path, path__len, CHAR);
	Platform_CommandCritical(1);
	*res = Platform_Chdir((void*)path, path__len);
	Platform_CommandCritical(0);
	__DEL(path);
}

static void Files_FlipBytes (SYSTEM_BYTE *src, ADDRESS src__len, SYSTEM_BYTE *dest, ADDRESS dest__len)
{
	INT32 i, j;
	if (!Platform_LittleEndian) {
		i = src__len;
		j = 0;
		while (i > 0) {
			i -= 1;
			dest[__X_AT(j, dest__len, (CHAR*)"../../src/library/Files.Mod", 28, (CHAR*)"Files", 6, 721, 35, 26373)] = src[__X_AT(i, src__len, (CHAR*)"../../src/library/Files.Mod", 28, (CHAR*)"Files", 6, 721, 45, 26383)];
			j += 1;
		}
	} else {
		__MOVE((ADDRESS)src, (ADDRESS)dest, src__len);
	}
}

void Files_ReadBool (Files_Rider *R, ADDRESS *R__typ, BOOLEAN *x)
{
	Files_Read(&*R, R__typ, (CHAR*)(void*)&*x);
}

void Files_ReadInt (Files_Rider *R, ADDRESS *R__typ, INT16 *x)
{
	CHAR b[2];
	Files_ReadBytes(&*R, R__typ, (void*)b, 2, 2);
	*x = (INT16)b[0] + __ASHL((INT16)b[1], 8);
}

void Files_ReadLInt (Files_Rider *R, ADDRESS *R__typ, INT32 *x)
{
	CHAR b[4];
	Files_ReadBytes(&*R, R__typ, (void*)b, 4, 4);
	*x = (((INT16)b[0] + __ASHL((INT16)b[1], 8)) + __ASHL(b[2], 16)) + __ASHL(b[3], 24);
}

void Files_ReadSet (Files_Rider *R, ADDRESS *R__typ, UINT32 *x)
{
	CHAR b[4];
	INT32 l;
	Files_ReadBytes(&*R, R__typ, (void*)b, 4, 4);
	l = (((INT16)b[0] + __ASHL((INT16)b[1], 8)) + __ASHL(b[2], 16)) + __ASHL(b[3], 24);
	*x = (UINT32)l;
}

void Files_ReadReal (Files_Rider *R, ADDRESS *R__typ, REAL *x)
{
	CHAR b[4];
	Files_ReadBytes(&*R, R__typ, (void*)b, 4, 4);
	Files_FlipBytes((void*)b, 4, (void*)&*x, 4);
}

void Files_ReadLReal (Files_Rider *R, ADDRESS *R__typ, LONGREAL *x)
{
	CHAR b[8];
	Files_ReadBytes(&*R, R__typ, (void*)b, 8, 8);
	Files_FlipBytes((void*)b, 8, (void*)&*x, 8);
}

void Files_ReadString (Files_Rider *R, ADDRESS *R__typ, CHAR *x, ADDRESS x__len)
{
	INT32 i;
	CHAR ch;
	i = 0;
	do {
		Files_Read(&*R, R__typ, (void*)&ch);
		if (i < x__len - 1) {
			x[__X_AT(i, x__len, (CHAR*)"../../src/library/Files.Mod", 28, (CHAR*)"Files", 6, 766, 30, 27898)] = ch;
			i += 1;
		}
	} while (!(ch == 0x00));
	if (x__len > 0) {
		x[__X_AT(i, x__len, (CHAR*)"../../src/library/Files.Mod", 28, (CHAR*)"Files", 6, 768, 26, 27963)] = 0x00;
	}
}

void Files_ReadLine (Files_Rider *R, ADDRESS *R__typ, CHAR *x, ADDRESS x__len)
{
	INT32 i;
	CHAR ch;
	BOOLEAN truncated;
	i = 0;
	truncated = 0;
	for (;;) {
		Files_Read(&*R, R__typ, (void*)&ch);
		if (ch == 0x00 || ch == 0x0a) {
			break;
		}
		if (i < x__len - 1) {
			x[__X_AT(i, x__len, (CHAR*)"../../src/library/Files.Mod", 28, (CHAR*)"Files", 6, 778, 30, 28250)] = ch;
			i += 1;
		} else {
			truncated = 1;
		}
	}
	if ((((!truncated && i > 0)) && x[__X_AT(i - 1, x__len, (CHAR*)"../../src/library/Files.Mod", 28, (CHAR*)"Files", 6, 781, 34, 28415)] == 0x0d)) {
		i -= 1;
	}
	if (x__len > 0) {
		x[__X_AT(i, x__len, (CHAR*)"../../src/library/Files.Mod", 28, (CHAR*)"Files", 6, 782, 26, 28469)] = 0x00;
	}
}

void Files_ReadNum (Files_Rider *R, ADDRESS *R__typ, SYSTEM_BYTE *x, ADDRESS x__len)
{
	INT8 s, b;
	INT64 q;
	s = 0;
	q = 0;
	Files_Read(&*R, R__typ, (void*)&b);
	while (b < 0) {
		q += (INT64)__ASH(((INT16)b + 128), s);
		s += 7;
		Files_Read(&*R, R__typ, (void*)&b);
	}
	q += (INT64)__ASH((__MASK(b, -64) - __ASHL(__ASHR(b, 6), 6)), s);
	Files_Assert(x__len <= 8);
	if (Platform_LittleEndian) {
		__MOVE((ADDRESS)&q, (ADDRESS)x, x__len);
	} else {
		__MOVE(((ADDRESS)&q + 8) - (INT64)(__SHORT(x__len, 32768)), (ADDRESS)x, x__len);
	}
}

void Files_WriteBool (Files_Rider *R, ADDRESS *R__typ, BOOLEAN x)
{
	Files_Write(&*R, R__typ, __VAL(CHAR, x));
}

void Files_WriteInt (Files_Rider *R, ADDRESS *R__typ, INT16 x)
{
	CHAR b[2];
	b[0] = __CHR(x);
	b[1] = __CHR(__ASHR(x, 8));
	Files_WriteBytes(&*R, R__typ, (void*)b, 2, 2);
}

void Files_WriteLInt (Files_Rider *R, ADDRESS *R__typ, INT32 x)
{
	CHAR b[4];
	b[0] = __CHR(x);
	b[1] = __CHR(__ASHR(x, 8));
	b[2] = __CHR(__ASHR(x, 16));
	b[3] = __CHR(__ASHR(x, 24));
	Files_WriteBytes(&*R, R__typ, (void*)b, 4, 4);
}

void Files_WriteSet (Files_Rider *R, ADDRESS *R__typ, UINT32 x)
{
	CHAR b[4];
	INT32 i;
	i = (INT32)x;
	b[0] = __CHR(i);
	b[1] = __CHR(__ASHR(i, 8));
	b[2] = __CHR(__ASHR(i, 16));
	b[3] = __CHR(__ASHR(i, 24));
	Files_WriteBytes(&*R, R__typ, (void*)b, 4, 4);
}

void Files_WriteReal (Files_Rider *R, ADDRESS *R__typ, REAL x)
{
	CHAR b[4];
	Files_FlipBytes((void*)&x, 4, (void*)b, 4);
	Files_WriteBytes(&*R, R__typ, (void*)b, 4, 4);
}

void Files_WriteLReal (Files_Rider *R, ADDRESS *R__typ, LONGREAL x)
{
	CHAR b[8];
	Files_FlipBytes((void*)&x, 8, (void*)b, 8);
	Files_WriteBytes(&*R, R__typ, (void*)b, 8, 8);
}

void Files_WriteString (Files_Rider *R, ADDRESS *R__typ, CHAR *x, ADDRESS x__len)
{
	INT16 i;
	i = 0;
	while (x[__X_AT(i, x__len, (CHAR*)"../../src/library/Files.Mod", 28, (CHAR*)"Files", 6, 841, 13, 30311)] != 0x00) {
		i += 1;
	}
	Files_WriteBytes(&*R, R__typ, (void*)x, x__len * 1, i + 1);
}

void Files_WriteNum (Files_Rider *R, ADDRESS *R__typ, INT64 x)
{
	while (x < -64 || x > 63) {
		Files_Write(&*R, R__typ, __CHR(__MASK(x, -128) + 128));
		x = __ASHR(x, 7);
	}
	Files_Write(&*R, R__typ, __CHR(__MASK(x, -128)));
}

void Files_GetName (Files_File f, CHAR *name, ADDRESS name__len)
{
	__COPY(((Files_File)__NIL_AT((ADDRESS)(f), (CHAR*)"../../src/library/Files.Mod", 28, (CHAR*)"Files", 6, 853, 13, 30653))->workName, name, name__len);
}

static void Files_CloseOSFile (Files_File f)
{
	Files_File prev = NIL;
	INT16 error;
	if (Files_files == (void *) f) {
		Files_files = ((Files_File)__NIL_AT((ADDRESS)(f), (CHAR*)"../../src/library/Files.Mod", 28, (CHAR*)"Files", 6, 860, 33, 30867))->next;
	} else {
		prev = (Files_File)Files_files;
		while ((prev != NIL && ((Files_File)__NIL_AT((ADDRESS)(prev), (CHAR*)"../../src/library/Files.Mod", 28, (CHAR*)"Files", 6, 863, 33, 30935))->next != (void *) f)) {
			prev = (Files_File)((Files_File)__NIL_AT((ADDRESS)(prev), (CHAR*)"../../src/library/Files.Mod", 28, (CHAR*)"Files", 6, 863, 59, 30961))->next;
		}
		if (((Files_File)__NIL_AT((ADDRESS)(prev), (CHAR*)"../../src/library/Files.Mod", 28, (CHAR*)"Files", 6, 864, 14, 30985))->next != NIL) {
			((Files_File)__NIL_AT((ADDRESS)(prev), (CHAR*)"../../src/library/Files.Mod", 28, (CHAR*)"Files", 6, 864, 35, 31006))->next = ((Files_File)__NIL_AT((ADDRESS)(f), (CHAR*)"../../src/library/Files.Mod", 28, (CHAR*)"Files", 6, 864, 45, 31016))->next;
		}
	}
	error = Platform_Close(((Files_File)__NIL_AT((ADDRESS)(f), (CHAR*)"../../src/library/Files.Mod", 28, (CHAR*)"Files", 6, 866, 30, 31064))->fd);
	((Files_File)__NIL_AT((ADDRESS)(f), (CHAR*)"../../src/library/Files.Mod", 28, (CHAR*)"Files", 6, 867, 6, 31075))->fd = -1;
	((Files_File)__NIL_AT((ADDRESS)(f), (CHAR*)"../../src/library/Files.Mod", 28, (CHAR*)"Files", 6, 867, 22, 31091))->state = 1;
	Heap_FileCount -= 1;
}

static void Files_Finalize (SYSTEM_PTR o)
{
	Files_File f = NIL;
	INT32 res;
	f = (Files_File)(ADDRESS)o;
	if (((Files_File)__NIL_AT((ADDRESS)(f), (CHAR*)"../../src/library/Files.Mod", 28, (CHAR*)"Files", 6, 874, 9, 31264))->fd >= 0) {
		Files_CloseOSFile(f);
		if (((Files_File)__NIL_AT((ADDRESS)(f), (CHAR*)"../../src/library/Files.Mod", 28, (CHAR*)"Files", 6, 876, 11, 31310))->tempFile) {
			res = Platform_Unlink((void*)((Files_File)__NIL_AT((ADDRESS)(f), (CHAR*)"../../src/library/Files.Mod", 28, (CHAR*)"Files", 6, 876, 50, 31349))->workName, 256);
		}
	}
}

BOOLEAN Files_GetSearchPath (CHAR *path, ADDRESS path__len)
{
	path[0] = 0x00;
	if (Files_SearchPath != NIL) {
		if (Strings_Length(((struct {
			ADDRESS len[1];
			CHAR data[1];
		} *)__NIL_AT((ADDRESS)(Files_SearchPath), (CHAR*)"../../src/library/Files.Mod", 28, (CHAR*)"Files", 6, 884, 35, 31541))->data, ((struct {
			ADDRESS len[1];
			CHAR data[1];
		} *)__NIL_AT((ADDRESS)(Files_SearchPath), (CHAR*)"../../src/library/Files.Mod", 28, (CHAR*)"Files", 6, 884, 35, 31541))->len[0]) >= path__len) {
			return 0;
		}
		__COPY(((struct {
			ADDRESS len[1];
			CHAR data[1];
		} *)__NIL_AT((ADDRESS)(Files_SearchPath), (CHAR*)"../../src/library/Files.Mod", 28, (CHAR*)"Files", 6, 885, 22, 31601))->data, path, path__len);
	}
	return 1;
}

void Files_SetSearchPath (CHAR *path, ADDRESS path__len)
{
	__DUP(path, path__len, CHAR);
	Platform_CommandCritical(1);
	if (Strings_Length(path, path__len) != 0) {
		Files_SearchPath = __NEWARR(NIL, 1, 1, 1, 1, ((ADDRESS)((Strings_Length(path, path__len) + 1))));
		__COPY(path, ((struct {
			ADDRESS len[1];
			CHAR data[1];
		} *)__NIL_AT((ADDRESS)(Files_SearchPath), (CHAR*)"../../src/library/Files.Mod", 28, (CHAR*)"Files", 6, 895, 28, 31861))->data, ((struct {
			ADDRESS len[1];
			CHAR data[1];
		} *)__NIL_AT((ADDRESS)(Files_SearchPath), (CHAR*)"../../src/library/Files.Mod", 28, (CHAR*)"Files", 6, 895, 28, 31861))->len[0]);
	} else {
		Files_SearchPath = NIL;
	}
	Platform_CommandCritical(0);
	__DEL(path);
}

static void EnumPtrs(void (*P)(void*))
{
	P(Files_SearchPath);
}

__TDESC(Files_FileDesc, 1, 5) = {__TDFLDS("FileDesc", 616), {552, 560, 568, 576, 600, -48}};
__TDESC(Files_BufDesc, 1, 1) = {__TDFLDS("BufDesc", 4120), {0, -16}};
__TDESC(Files_Rider, 1, 1) = {__TDFLDS("Rider", 24), {8, -16}};

export void *Files__init(void)
{
	__DEFMOD;
	__MODULE_IMPORT(Heap);
	__MODULE_IMPORT(Out);
	__MODULE_IMPORT(Platform);
	__MODULE_IMPORT(Strings);
	__REGMOD("Files", EnumPtrs);
	__INITYP(Files_FileDesc, Files_FileDesc, 0);
	__INITYP(Files_BufDesc, Files_BufDesc, 0);
	__INITYP(Files_Rider, Files_Rider, 0);
/* BEGIN */
	Files_tempno = -1;
	Heap_FileCount = 0;
	Files_HOME[0] = 0x00;
	Platform_GetEnv((CHAR*)"HOME", 5, (void*)Files_HOME, 1024);
	Files_MaxPathLength = Platform_MaxPathLength();
	Files_MaxNameLength = Platform_MaxNameLength();
	__ENDMOD;
}
