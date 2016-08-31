/* voc 1.95 [2016/08/31] for gcc LP64 on cygwin tspkaSfF */
#include "SYSTEM.h"
#include "Configuration.h"
#include "Console.h"
#include "Heap.h"
#include "Platform.h"
#include "Strings.h"

typedef
	struct Files_FileDesc *Files_File;

typedef
	struct Files_BufDesc {
		Files_File f;
		BOOLEAN chg;
		LONGINT org, size;
		SYSTEM_BYTE data[4096];
	} Files_BufDesc;

typedef
	Files_BufDesc *Files_Buffer;

typedef
	CHAR Files_FileName[101];

typedef
	struct Files_FileDesc {
		Files_FileName workName, registerName;
		BOOLEAN tempFile;
		Platform_FileIdentity identity;
		LONGINT fd, len, pos;
		Files_Buffer bufs[4];
		INTEGER swapper, state;
		Files_File next;
	} Files_FileDesc;

typedef
	struct Files_Rider {
		LONGINT res;
		BOOLEAN eof;
		Files_Buffer buf;
		LONGINT org, offset;
	} Files_Rider;


static Files_File Files_files;
static INTEGER Files_tempno;
static CHAR Files_HOME[1024];
static struct {
	LONGINT len[1];
	CHAR data[1];
} *Files_SearchPath;

export LONGINT *Files_FileDesc__typ;
export LONGINT *Files_BufDesc__typ;
export LONGINT *Files_Rider__typ;

export Files_File Files_Base (Files_Rider *r, LONGINT *r__typ);
static Files_File Files_CacheEntry (Platform_FileIdentity identity);
export void Files_ChangeDirectory (CHAR *path, LONGINT path__len, INTEGER *res);
export void Files_Close (Files_File f);
static void Files_CloseOSFile (Files_File f);
static void Files_Create (Files_File f);
export void Files_Delete (CHAR *name, LONGINT name__len, INTEGER *res);
static void Files_Err (CHAR *s, LONGINT s__len, Files_File f, INTEGER errcode);
static void Files_Finalize (SYSTEM_PTR o);
static void Files_FlipBytes (SYSTEM_BYTE *src, LONGINT src__len, SYSTEM_BYTE *dest, LONGINT dest__len);
static void Files_Flush (Files_Buffer buf);
export void Files_GetDate (Files_File f, LONGINT *t, LONGINT *d);
export void Files_GetName (Files_File f, CHAR *name, LONGINT name__len);
static void Files_GetTempName (CHAR *finalName, LONGINT finalName__len, CHAR *name, LONGINT name__len);
static BOOLEAN Files_HasDir (CHAR *name, LONGINT name__len);
export LONGINT Files_Length (Files_File f);
static void Files_MakeFileName (CHAR *dir, LONGINT dir__len, CHAR *name, LONGINT name__len, CHAR *dest, LONGINT dest__len);
export Files_File Files_New (CHAR *name, LONGINT name__len);
export Files_File Files_Old (CHAR *name, LONGINT name__len);
export LONGINT Files_Pos (Files_Rider *r, LONGINT *r__typ);
export void Files_Purge (Files_File f);
export void Files_Read (Files_Rider *r, LONGINT *r__typ, SYSTEM_BYTE *x);
export void Files_ReadBool (Files_Rider *R, LONGINT *R__typ, BOOLEAN *x);
export void Files_ReadByte (Files_Rider *r, LONGINT *r__typ, SYSTEM_BYTE *x, LONGINT x__len);
export void Files_ReadBytes (Files_Rider *r, LONGINT *r__typ, SYSTEM_BYTE *x, LONGINT x__len, LONGINT n);
export void Files_ReadInt (Files_Rider *R, LONGINT *R__typ, INTEGER *x);
export void Files_ReadLInt (Files_Rider *R, LONGINT *R__typ, LONGINT *x);
export void Files_ReadLReal (Files_Rider *R, LONGINT *R__typ, LONGREAL *x);
export void Files_ReadLine (Files_Rider *R, LONGINT *R__typ, CHAR *x, LONGINT x__len);
export void Files_ReadNum (Files_Rider *R, LONGINT *R__typ, LONGINT *x);
export void Files_ReadReal (Files_Rider *R, LONGINT *R__typ, REAL *x);
export void Files_ReadSet (Files_Rider *R, LONGINT *R__typ, SET *x);
export void Files_ReadString (Files_Rider *R, LONGINT *R__typ, CHAR *x, LONGINT x__len);
export void Files_Register (Files_File f);
export void Files_Rename (CHAR *old, LONGINT old__len, CHAR *new, LONGINT new__len, INTEGER *res);
static void Files_ScanPath (INTEGER *pos, CHAR *dir, LONGINT dir__len);
export void Files_Set (Files_Rider *r, LONGINT *r__typ, Files_File f, LONGINT pos);
export void Files_SetSearchPath (CHAR *path, LONGINT path__len);
export void Files_Write (Files_Rider *r, LONGINT *r__typ, SYSTEM_BYTE x);
export void Files_WriteBool (Files_Rider *R, LONGINT *R__typ, BOOLEAN x);
export void Files_WriteBytes (Files_Rider *r, LONGINT *r__typ, SYSTEM_BYTE *x, LONGINT x__len, LONGINT n);
export void Files_WriteInt (Files_Rider *R, LONGINT *R__typ, INTEGER x);
export void Files_WriteLInt (Files_Rider *R, LONGINT *R__typ, LONGINT x);
export void Files_WriteLReal (Files_Rider *R, LONGINT *R__typ, LONGREAL x);
export void Files_WriteNum (Files_Rider *R, LONGINT *R__typ, LONGINT x);
export void Files_WriteReal (Files_Rider *R, LONGINT *R__typ, REAL x);
export void Files_WriteSet (Files_Rider *R, LONGINT *R__typ, SET x);
export void Files_WriteString (Files_Rider *R, LONGINT *R__typ, CHAR *x, LONGINT x__len);

#define Files_IdxTrap()	__HALT(-1)

static void Files_Err (CHAR *s, LONGINT s__len, Files_File f, INTEGER errcode)
{
	__DUP(s, s__len, CHAR);
	Console_Ln();
	Console_String((CHAR*)"-- ", 4);
	Console_String(s, s__len);
	Console_String((CHAR*)": ", 3);
	if (f != NIL) {
		if (f->registerName[0] != 0x00) {
			Console_String(f->registerName, 101);
		} else {
			Console_String(f->workName, 101);
		}
		if (f->fd != 0) {
			Console_String((CHAR*)"f.fd = ", 8);
			Console_Int(f->fd, 1);
		}
	}
	if (errcode != 0) {
		Console_String((CHAR*)" errcode = ", 12);
		Console_Int(errcode, 1);
	}
	Console_Ln();
	__HALT(99);
	__DEL(s);
}

static void Files_MakeFileName (CHAR *dir, LONGINT dir__len, CHAR *name, LONGINT name__len, CHAR *dest, LONGINT dest__len)
{
	INTEGER i, j;
	__DUP(dir, dir__len, CHAR);
	__DUP(name, name__len, CHAR);
	i = 0;
	j = 0;
	while (dir[i] != 0x00) {
		dest[i] = dir[i];
		i += 1;
	}
	if (dest[i - 1] != '/') {
		dest[i] = '/';
		i += 1;
	}
	while (name[j] != 0x00) {
		dest[i] = name[j];
		i += 1;
		j += 1;
	}
	dest[i] = 0x00;
	__DEL(dir);
	__DEL(name);
}

static void Files_GetTempName (CHAR *finalName, LONGINT finalName__len, CHAR *name, LONGINT name__len)
{
	LONGINT n, i, j;
	__DUP(finalName, finalName__len, CHAR);
	Files_tempno += 1;
	n = Files_tempno;
	i = 0;
	if (finalName[0] != '/') {
		while (Platform_CWD[i] != 0x00) {
			name[i] = Platform_CWD[i];
			i += 1;
		}
		if (Platform_CWD[i - 1] != '/') {
			name[i] = '/';
			i += 1;
		}
	}
	j = 0;
	while (finalName[j] != 0x00) {
		name[i] = finalName[j];
		i += 1;
		j += 1;
	}
	i -= 1;
	while (name[i] != '/') {
		i -= 1;
	}
	name[i + 1] = '.';
	name[i + 2] = 't';
	name[i + 3] = 'm';
	name[i + 4] = 'p';
	name[i + 5] = '.';
	i += 6;
	while (n > 0) {
		name[i] = (CHAR)((int)__MOD(n, 10) + 48);
		n = __DIV(n, 10);
		i += 1;
	}
	name[i] = '.';
	i += 1;
	n = Platform_PID;
	while (n > 0) {
		name[i] = (CHAR)((int)__MOD(n, 10) + 48);
		n = __DIV(n, 10);
		i += 1;
	}
	name[i] = 0x00;
	__DEL(finalName);
}

static void Files_Create (Files_File f)
{
	Platform_FileIdentity identity;
	BOOLEAN done;
	INTEGER error;
	CHAR err[32];
	if (f->fd == -1) {
		if (f->state == 1) {
			Files_GetTempName(f->registerName, 101, (void*)f->workName, 101);
			f->tempFile = 1;
		} else if (f->state == 2) {
			__COPY(f->registerName, f->workName, 101);
			f->registerName[0] = 0x00;
			f->tempFile = 0;
		}
		error = Platform_Unlink((void*)f->workName, 101);
		error = Platform_New((void*)f->workName, 101, &f->fd);
		done = error == 0;
		if (done) {
			f->next = Files_files;
			Files_files = f;
			Heap_FileCount += 1;
			Heap_RegisterFinalizer((void*)f, Files_Finalize);
			f->state = 0;
			f->pos = 0;
			error = Platform_Identify(f->fd, &f->identity, Platform_FileIdentity__typ);
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
	INTEGER error;
	Files_File f = NIL;
	if (buf->chg) {
		f = buf->f;
		Files_Create(f);
		if (buf->org != f->pos) {
			error = Platform_Seek(f->fd, buf->org, Platform_SeekSet);
		}
		error = Platform_Write(f->fd, (SYSTEM_ADRINT)buf->data, buf->size);
		if (error != 0) {
			Files_Err((CHAR*)"error writing file", 19, f, error);
		}
		f->pos = buf->org + buf->size;
		buf->chg = 0;
		error = Platform_Identify(f->fd, &f->identity, Platform_FileIdentity__typ);
		if (error != 0) {
			Files_Err((CHAR*)"error identifying file", 23, f, error);
		}
	}
}

static void Files_CloseOSFile (Files_File f)
{
	Files_File prev = NIL;
	INTEGER error;
	if (Files_files == f) {
		Files_files = f->next;
	} else {
		prev = Files_files;
		while ((prev != NIL && prev->next != f)) {
			prev = prev->next;
		}
		if (prev->next != NIL) {
			prev->next = f->next;
		}
	}
	error = Platform_Close(f->fd);
	f->fd = -1;
	f->state = 1;
	Heap_FileCount -= 1;
}

void Files_Close (Files_File f)
{
	LONGINT i;
	INTEGER error;
	if (f->state != 1 || f->registerName[0] != 0x00) {
		Files_Create(f);
		i = 0;
		while ((i < 4 && f->bufs[i] != NIL)) {
			Files_Flush(f->bufs[i]);
			i += 1;
		}
		error = Platform_Sync(f->fd);
		if (error != 0) {
			Files_Err((CHAR*)"error writing file", 19, f, error);
		}
		Files_CloseOSFile(f);
	}
}

LONGINT Files_Length (Files_File f)
{
	LONGINT _o_result;
	_o_result = f->len;
	return _o_result;
}

Files_File Files_New (CHAR *name, LONGINT name__len)
{
	Files_File _o_result;
	Files_File f = NIL;
	__DUP(name, name__len, CHAR);
	__NEW(f, Files_FileDesc);
	f->workName[0] = 0x00;
	__COPY(name, f->registerName, 101);
	f->fd = -1;
	f->state = 1;
	f->len = 0;
	f->pos = 0;
	f->swapper = -1;
	_o_result = f;
	__DEL(name);
	return _o_result;
}

static void Files_ScanPath (INTEGER *pos, CHAR *dir, LONGINT dir__len)
{
	INTEGER i;
	CHAR ch;
	i = 0;
	if (Files_SearchPath == NIL) {
		if (*pos == 0) {
			dir[0] = '.';
			i = 1;
			*pos += 1;
		}
	} else {
		ch = (Files_SearchPath->data)[*pos];
		while (ch == ' ' || ch == ';') {
			*pos += 1;
			ch = (Files_SearchPath->data)[*pos];
		}
		if (ch == '~') {
			*pos += 1;
			ch = (Files_SearchPath->data)[*pos];
			while (Files_HOME[i] != 0x00) {
				dir[i] = Files_HOME[i];
				i += 1;
			}
			if ((((((ch != '/' && ch != 0x00)) && ch != ';')) && ch != ' ')) {
				while ((i > 0 && dir[i - 1] != '/')) {
					i -= 1;
				}
			}
		}
		while ((ch != 0x00 && ch != ';')) {
			dir[i] = ch;
			i += 1;
			*pos += 1;
			ch = (Files_SearchPath->data)[*pos];
		}
		while ((i > 0 && dir[i - 1] == ' ')) {
			i -= 1;
		}
	}
	dir[i] = 0x00;
}

static BOOLEAN Files_HasDir (CHAR *name, LONGINT name__len)
{
	BOOLEAN _o_result;
	INTEGER i;
	CHAR ch;
	i = 0;
	ch = name[0];
	while ((ch != 0x00 && ch != '/')) {
		i += 1;
		ch = name[i];
	}
	_o_result = ch == '/';
	return _o_result;
}

static Files_File Files_CacheEntry (Platform_FileIdentity identity)
{
	Files_File _o_result;
	Files_File f = NIL;
	INTEGER i, error;
	f = Files_files;
	while (f != NIL) {
		if (Platform_SameFile(identity, f->identity)) {
			if (!Platform_SameFileTime(identity, f->identity)) {
				i = 0;
				while (i < 4) {
					if (f->bufs[i] != NIL) {
						f->bufs[i]->org = -1;
						f->bufs[i] = NIL;
					}
					i += 1;
				}
				f->swapper = -1;
				f->identity = identity;
				error = Platform_Size(f->fd, &f->len);
			}
			_o_result = f;
			return _o_result;
		}
		f = f->next;
	}
	_o_result = NIL;
	return _o_result;
}

Files_File Files_Old (CHAR *name, LONGINT name__len)
{
	Files_File _o_result;
	Files_File f = NIL;
	LONGINT fd;
	INTEGER pos;
	BOOLEAN done;
	CHAR dir[256], path[256];
	INTEGER error;
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
				Console_String((CHAR*)"Warning: Files.Old ", 20);
				Console_String(name, name__len);
				Console_String((CHAR*)" error = ", 10);
				Console_Int(error, 0);
				Console_Ln();
			}
			if (done) {
				error = Platform_Identify(fd, &identity, Platform_FileIdentity__typ);
				f = Files_CacheEntry(identity);
				if (f != NIL) {
					_o_result = f;
					__DEL(name);
					return _o_result;
				} else {
					__NEW(f, Files_FileDesc);
					Heap_RegisterFinalizer((void*)f, Files_Finalize);
					f->fd = fd;
					f->state = 0;
					f->pos = 0;
					f->swapper = -1;
					error = Platform_Size(fd, &f->len);
					__COPY(name, f->workName, 101);
					f->registerName[0] = 0x00;
					f->tempFile = 0;
					f->identity = identity;
					f->next = Files_files;
					Files_files = f;
					Heap_FileCount += 1;
					_o_result = f;
					__DEL(name);
					return _o_result;
				}
			} else if (dir[0] == 0x00) {
				_o_result = NIL;
				__DEL(name);
				return _o_result;
			} else {
				Files_MakeFileName(dir, 256, name, name__len, (void*)path, 256);
				Files_ScanPath(&pos, (void*)dir, 256);
			}
		}
	} else {
		_o_result = NIL;
		__DEL(name);
		return _o_result;
	}
	__RETCHK;
}

void Files_Purge (Files_File f)
{
	INTEGER i;
	Platform_FileIdentity identity;
	INTEGER error;
	i = 0;
	while (i < 4) {
		if (f->bufs[i] != NIL) {
			f->bufs[i]->org = -1;
			f->bufs[i] = NIL;
		}
		i += 1;
	}
	if (f->fd != -1) {
		error = Platform_Truncate(f->fd, 0);
		error = Platform_Seek(f->fd, 0, Platform_SeekSet);
	}
	f->pos = 0;
	f->len = 0;
	f->swapper = -1;
	error = Platform_Identify(f->fd, &identity, Platform_FileIdentity__typ);
	Platform_SetMTime(&f->identity, Platform_FileIdentity__typ, identity);
}

void Files_GetDate (Files_File f, LONGINT *t, LONGINT *d)
{
	Platform_FileIdentity identity;
	INTEGER error;
	Files_Create(f);
	error = Platform_Identify(f->fd, &identity, Platform_FileIdentity__typ);
	Platform_MTimeAsClock(identity, &*t, &*d);
}

LONGINT Files_Pos (Files_Rider *r, LONGINT *r__typ)
{
	LONGINT _o_result;
	_o_result = (*r).org + (*r).offset;
	return _o_result;
}

void Files_Set (Files_Rider *r, LONGINT *r__typ, Files_File f, LONGINT pos)
{
	LONGINT org, offset, i, n;
	Files_Buffer buf = NIL;
	INTEGER error;
	if (f != NIL) {
		if (pos > f->len) {
			pos = f->len;
		} else if (pos < 0) {
			pos = 0;
		}
		offset = __MASK(pos, -4096);
		org = pos - offset;
		i = 0;
		while ((((i < 4 && f->bufs[i] != NIL)) && org != f->bufs[i]->org)) {
			i += 1;
		}
		if (i < 4) {
			if (f->bufs[i] == NIL) {
				__NEW(buf, Files_BufDesc);
				buf->chg = 0;
				buf->org = -1;
				buf->f = f;
				f->bufs[i] = buf;
			} else {
				buf = f->bufs[i];
			}
		} else {
			f->swapper = __MASK(f->swapper + 1, -4);
			buf = f->bufs[f->swapper];
			Files_Flush(buf);
		}
		if (buf->org != org) {
			if (org == f->len) {
				buf->size = 0;
			} else {
				Files_Create(f);
				if (f->pos != org) {
					error = Platform_Seek(f->fd, org, Platform_SeekSet);
				}
				error = Platform_ReadBuf(f->fd, (void*)buf->data, 4096, &n);
				if (error != 0) {
					Files_Err((CHAR*)"read from file not done", 24, f, error);
				}
				f->pos = org + n;
				buf->size = n;
			}
			buf->org = org;
			buf->chg = 0;
		}
	} else {
		buf = NIL;
		org = 0;
		offset = 0;
	}
	(*r).buf = buf;
	(*r).org = org;
	(*r).offset = offset;
	(*r).eof = 0;
	(*r).res = 0;
}

void Files_Read (Files_Rider *r, LONGINT *r__typ, SYSTEM_BYTE *x)
{
	LONGINT offset;
	Files_Buffer buf = NIL;
	buf = (*r).buf;
	offset = (*r).offset;
	if ((*r).org != buf->org) {
		Files_Set(&*r, r__typ, buf->f, (*r).org + offset);
		buf = (*r).buf;
		offset = (*r).offset;
	}
	if (offset < buf->size) {
		*x = buf->data[offset];
		(*r).offset = offset + 1;
	} else if ((*r).org + offset < buf->f->len) {
		Files_Set(&*r, r__typ, (*r).buf->f, (*r).org + offset);
		*x = (*r).buf->data[0];
		(*r).offset = 1;
	} else {
		*x = 0x00;
		(*r).eof = 1;
	}
}

void Files_ReadBytes (Files_Rider *r, LONGINT *r__typ, SYSTEM_BYTE *x, LONGINT x__len, LONGINT n)
{
	LONGINT xpos, min, restInBuf, offset;
	Files_Buffer buf = NIL;
	if (n > x__len) {
		Files_IdxTrap();
	}
	xpos = 0;
	buf = (*r).buf;
	offset = (*r).offset;
	while (n > 0) {
		if ((*r).org != buf->org || offset >= 4096) {
			Files_Set(&*r, r__typ, buf->f, (*r).org + offset);
			buf = (*r).buf;
			offset = (*r).offset;
		}
		restInBuf = buf->size - offset;
		if (restInBuf == 0) {
			(*r).res = n;
			(*r).eof = 1;
			return;
		} else if (n > restInBuf) {
			min = restInBuf;
		} else {
			min = n;
		}
		__MOVE((SYSTEM_ADRINT)buf->data + offset, (SYSTEM_ADRINT)x + xpos, min);
		offset += min;
		(*r).offset = offset;
		xpos += min;
		n -= min;
	}
	(*r).res = 0;
	(*r).eof = 0;
}

void Files_ReadByte (Files_Rider *r, LONGINT *r__typ, SYSTEM_BYTE *x, LONGINT x__len)
{
	Files_ReadBytes(&*r, r__typ, (void*)x, x__len * 1, 1);
}

Files_File Files_Base (Files_Rider *r, LONGINT *r__typ)
{
	Files_File _o_result;
	_o_result = (*r).buf->f;
	return _o_result;
}

void Files_Write (Files_Rider *r, LONGINT *r__typ, SYSTEM_BYTE x)
{
	Files_Buffer buf = NIL;
	LONGINT offset;
	buf = (*r).buf;
	offset = (*r).offset;
	if ((*r).org != buf->org || offset >= 4096) {
		Files_Set(&*r, r__typ, buf->f, (*r).org + offset);
		buf = (*r).buf;
		offset = (*r).offset;
	}
	buf->data[offset] = x;
	buf->chg = 1;
	if (offset == buf->size) {
		buf->size += 1;
		buf->f->len += 1;
	}
	(*r).offset = offset + 1;
	(*r).res = 0;
}

void Files_WriteBytes (Files_Rider *r, LONGINT *r__typ, SYSTEM_BYTE *x, LONGINT x__len, LONGINT n)
{
	LONGINT xpos, min, restInBuf, offset;
	Files_Buffer buf = NIL;
	if (n > x__len) {
		Files_IdxTrap();
	}
	xpos = 0;
	buf = (*r).buf;
	offset = (*r).offset;
	while (n > 0) {
		if ((*r).org != buf->org || offset >= 4096) {
			Files_Set(&*r, r__typ, buf->f, (*r).org + offset);
			buf = (*r).buf;
			offset = (*r).offset;
		}
		restInBuf = 4096 - offset;
		if (n > restInBuf) {
			min = restInBuf;
		} else {
			min = n;
		}
		__MOVE((SYSTEM_ADRINT)x + xpos, (SYSTEM_ADRINT)buf->data + offset, min);
		offset += min;
		(*r).offset = offset;
		if (offset > buf->size) {
			buf->f->len += offset - buf->size;
			buf->size = offset;
		}
		xpos += min;
		n -= min;
		buf->chg = 1;
	}
	(*r).res = 0;
}

void Files_Delete (CHAR *name, LONGINT name__len, INTEGER *res)
{
	__DUP(name, name__len, CHAR);
	*res = Platform_Unlink((void*)name, name__len);
	__DEL(name);
}

void Files_Rename (CHAR *old, LONGINT old__len, CHAR *new, LONGINT new__len, INTEGER *res)
{
	LONGINT fdold, fdnew, n;
	INTEGER error, ignore;
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
			return;
		} else {
			error = Platform_OldRO((void*)old, old__len, &fdold);
			if (error != 0) {
				*res = 2;
				return;
			}
			error = Platform_New((void*)new, new__len, &fdnew);
			if (error != 0) {
				error = Platform_Close(fdold);
				*res = 3;
				return;
			}
			error = Platform_Read(fdold, (SYSTEM_ADRINT)buf, 4096, &n);
			while (n > 0) {
				error = Platform_Write(fdnew, (SYSTEM_ADRINT)buf, n);
				if (error != 0) {
					ignore = Platform_Close(fdold);
					ignore = Platform_Close(fdnew);
					Files_Err((CHAR*)"cannot move file", 17, NIL, error);
				}
				error = Platform_Read(fdold, (SYSTEM_ADRINT)buf, 4096, &n);
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

void Files_Register (Files_File f)
{
	INTEGER idx, errcode;
	Files_File f1 = NIL;
	CHAR file[104];
	if ((f->state == 1 && f->registerName[0] != 0x00)) {
		f->state = 2;
	}
	Files_Close(f);
	if (f->registerName[0] != 0x00) {
		Files_Rename(f->workName, 101, f->registerName, 101, &errcode);
		if (errcode != 0) {
			__COPY(f->registerName, file, 104);
			__HALT(99);
		}
		__COPY(f->registerName, f->workName, 101);
		f->registerName[0] = 0x00;
		f->tempFile = 0;
	}
}

void Files_ChangeDirectory (CHAR *path, LONGINT path__len, INTEGER *res)
{
	__DUP(path, path__len, CHAR);
	*res = Platform_Chdir((void*)path, path__len);
	__DEL(path);
}

static void Files_FlipBytes (SYSTEM_BYTE *src, LONGINT src__len, SYSTEM_BYTE *dest, LONGINT dest__len)
{
	LONGINT i, j;
	if (!Platform_LittleEndian) {
		i = src__len;
		j = 0;
		while (i > 0) {
			i -= 1;
			dest[j] = src[i];
			j += 1;
		}
	} else {
		__MOVE((SYSTEM_ADRINT)src, (SYSTEM_ADRINT)dest, src__len);
	}
}

void Files_ReadBool (Files_Rider *R, LONGINT *R__typ, BOOLEAN *x)
{
	Files_Read(&*R, R__typ, (CHAR*)(void*)&*x);
}

void Files_ReadInt (Files_Rider *R, LONGINT *R__typ, INTEGER *x)
{
	CHAR b[2];
	Files_ReadBytes(&*R, R__typ, (void*)b, 2, 2);
	*x = (SYSTEM_INT16)b[0] + __ASHL((SYSTEM_INT16)b[1], 8);
}

void Files_ReadLInt (Files_Rider *R, LONGINT *R__typ, LONGINT *x)
{
	CHAR b[4];
	Files_ReadBytes(&*R, R__typ, (void*)b, 4, 4);
	*x = (((SYSTEM_INT16)b[0] + __ASHL((SYSTEM_INT16)b[1], 8)) + __ASHL(b[2], 16)) + __ASHL(b[3], 24);
}

void Files_ReadSet (Files_Rider *R, LONGINT *R__typ, SET *x)
{
	CHAR b[4];
	LONGINT l;
	Files_ReadBytes(&*R, R__typ, (void*)b, 4, 4);
	l = (((SYSTEM_INT16)b[0] + __ASHL((SYSTEM_INT16)b[1], 8)) + __ASHL(b[2], 16)) + __ASHL(b[3], 24);
	*x = (SET)l;
}

void Files_ReadReal (Files_Rider *R, LONGINT *R__typ, REAL *x)
{
	CHAR b[4];
	Files_ReadBytes(&*R, R__typ, (void*)b, 4, 4);
	Files_FlipBytes((void*)b, 4, (void*)&*x, 4);
}

void Files_ReadLReal (Files_Rider *R, LONGINT *R__typ, LONGREAL *x)
{
	CHAR b[8];
	Files_ReadBytes(&*R, R__typ, (void*)b, 8, 8);
	Files_FlipBytes((void*)b, 8, (void*)&*x, 8);
}

void Files_ReadString (Files_Rider *R, LONGINT *R__typ, CHAR *x, LONGINT x__len)
{
	INTEGER i;
	CHAR ch;
	i = 0;
	do {
		Files_Read(&*R, R__typ, (void*)&ch);
		x[i] = ch;
		i += 1;
	} while (!(ch == 0x00));
}

void Files_ReadLine (Files_Rider *R, LONGINT *R__typ, CHAR *x, LONGINT x__len)
{
	INTEGER i;
	CHAR ch;
	BOOLEAN b;
	i = 0;
	b = 0;
	do {
		Files_Read(&*R, R__typ, (void*)&ch);
		if ((ch == 0x00 || ch == 0x0a) || ch == 0x0d) {
			b = 1;
		} else {
			x[i] = ch;
			i += 1;
		}
	} while (!b);
}

void Files_ReadNum (Files_Rider *R, LONGINT *R__typ, LONGINT *x)
{
	SHORTINT s;
	CHAR ch;
	LONGINT n;
	s = 0;
	n = 0;
	Files_Read(&*R, R__typ, (void*)&ch);
	while ((SYSTEM_INT16)ch >= 128) {
		n += __ASH(((SYSTEM_INT16)ch - 128), s);
		s += 7;
		Files_Read(&*R, R__typ, (void*)&ch);
	}
	n += __ASH((__MASK((SYSTEM_INT16)ch, -64) - __ASHL(__ASHR((SYSTEM_INT16)ch, 6), 6)), s);
	*x = n;
}

void Files_WriteBool (Files_Rider *R, LONGINT *R__typ, BOOLEAN x)
{
	Files_Write(&*R, R__typ, __VAL(CHAR, x));
}

void Files_WriteInt (Files_Rider *R, LONGINT *R__typ, INTEGER x)
{
	CHAR b[2];
	b[0] = (CHAR)x;
	b[1] = (CHAR)__ASHR(x, 8);
	Files_WriteBytes(&*R, R__typ, (void*)b, 2, 2);
}

void Files_WriteLInt (Files_Rider *R, LONGINT *R__typ, LONGINT x)
{
	CHAR b[4];
	b[0] = (CHAR)x;
	b[1] = (CHAR)__ASHR(x, 8);
	b[2] = (CHAR)__ASHR(x, 16);
	b[3] = (CHAR)__ASHR(x, 24);
	Files_WriteBytes(&*R, R__typ, (void*)b, 4, 4);
}

void Files_WriteSet (Files_Rider *R, LONGINT *R__typ, SET x)
{
	CHAR b[4];
	LONGINT i;
	i = (LONGINT)x;
	b[0] = (CHAR)i;
	b[1] = (CHAR)__ASHR(i, 8);
	b[2] = (CHAR)__ASHR(i, 16);
	b[3] = (CHAR)__ASHR(i, 24);
	Files_WriteBytes(&*R, R__typ, (void*)b, 4, 4);
}

void Files_WriteReal (Files_Rider *R, LONGINT *R__typ, REAL x)
{
	CHAR b[4];
	Files_FlipBytes((void*)&x, 4, (void*)b, 4);
	Files_WriteBytes(&*R, R__typ, (void*)b, 4, 4);
}

void Files_WriteLReal (Files_Rider *R, LONGINT *R__typ, LONGREAL x)
{
	CHAR b[8];
	Files_FlipBytes((void*)&x, 8, (void*)b, 8);
	Files_WriteBytes(&*R, R__typ, (void*)b, 8, 8);
}

void Files_WriteString (Files_Rider *R, LONGINT *R__typ, CHAR *x, LONGINT x__len)
{
	INTEGER i;
	i = 0;
	while (x[i] != 0x00) {
		i += 1;
	}
	Files_WriteBytes(&*R, R__typ, (void*)x, x__len * 1, i + 1);
}

void Files_WriteNum (Files_Rider *R, LONGINT *R__typ, LONGINT x)
{
	while (x < -64 || x > 63) {
		Files_Write(&*R, R__typ, (CHAR)(__MASK(x, -128) + 128));
		x = __ASHR(x, 7);
	}
	Files_Write(&*R, R__typ, (CHAR)__MASK(x, -128));
}

void Files_GetName (Files_File f, CHAR *name, LONGINT name__len)
{
	__COPY(f->workName, name, name__len);
}

static void Files_Finalize (SYSTEM_PTR o)
{
	Files_File f = NIL;
	LONGINT res;
	f = (Files_File)(SYSTEM_ADRINT)o;
	if (f->fd >= 0) {
		Files_CloseOSFile(f);
		if (f->tempFile) {
			res = Platform_Unlink((void*)f->workName, 101);
		}
	}
}

void Files_SetSearchPath (CHAR *path, LONGINT path__len)
{
	__DUP(path, path__len, CHAR);
	if (Strings_Length(path, path__len) != 0) {
		Files_SearchPath = __NEWARR(NIL, 1, 1, 1, 1, ((SYSTEM_ADRINT)((Strings_Length(path, path__len) + 1))));
		__COPY(path, Files_SearchPath->data, Files_SearchPath->len[0]);
	} else {
		Files_SearchPath = NIL;
	}
	__DEL(path);
}

static void EnumPtrs(void (*P)(void*))
{
	P(Files_files);
	P(Files_SearchPath);
}

__TDESC(Files_FileDesc, 1, 5) = {__TDFLDS("FileDesc", 252), {228, 232, 236, 240, 248, -24}};
__TDESC(Files_BufDesc, 1, 1) = {__TDFLDS("BufDesc", 4112), {0, -8}};
__TDESC(Files_Rider, 1, 1) = {__TDFLDS("Rider", 20), {8, -8}};

export void *Files__init(void)
{
	__DEFMOD;
	__MODULE_IMPORT(Configuration);
	__MODULE_IMPORT(Console);
	__MODULE_IMPORT(Heap);
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
	__ENDMOD;
}
