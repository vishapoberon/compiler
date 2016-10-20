#ifndef SYSTEM__h
#define SYSTEM__h


// 64 bit system detection

#if (__SIZEOF_POINTER__ == 8) || defined (_LP64) || defined(__LP64__) || defined(_WIN64)
  #define __o_64
#endif


// Declare memcpy in a way compatible with C compilers intrinsic
// built in implementations.

#if defined (__o_64)
  #if defined(_WIN64)
    typedef unsigned long long size_t;
  #else
    typedef unsigned long      size_t;
  #endif
#else
  typedef unsigned int         size_t;
#endif

#define _SIZE_T_DECLARED // For FreeBSD
#define _SIZE_T_DEFINED_ // For OpenBSD

void *memcpy(void *dest, const void *source, size_t size);


// Declare fixed size versions of basic intger types

#if defined (__o_64) && !defined(_WIN64)
  // LP64
  typedef long               int64;
  typedef unsigned long      uint64;
#else
  // ILP32 or LLP64
  typedef long long          int64;
  typedef unsigned long long uint64;
#endif

typedef int                  int32;
typedef unsigned int         uint32;

typedef short int            int16;
typedef unsigned short int   uint16;

typedef signed char          int8;
typedef unsigned char        uint8;


// The compiler uses 'import' and 'export' which translate to 'extern' and
// nothing respectively.

#define import extern
#define export



// Known constants

#define NIL          ((void*)0)
#define __MAXEXT     16
#define POINTER__typ ((address*)(1))  // not NIL and not a valid type


// Oberon types

typedef int8   BOOLEAN;
typedef int8   SYSTEM_BYTE;
typedef uint8  CHAR;
typedef float  REAL;
typedef double LONGREAL;
typedef void*  SYSTEM_PTR;



// 'address' is a synonym for an int of pointer size

#if defined (__o_64)
  #define address int64
#else
  #define address int32
#endif





// ----------------------------------------------------------------------
// ----------------------------------------------------------------------



// OS Memory allocation interfaces are in PlatformXXX.Mod

extern address Platform_OSAllocate (address size);
extern void    Platform_OSFree     (address addr);


// Assertions and Halts

extern void Platform_Halt(int32 x);
extern void Platform_AssertFail(int32 x);

#define __HALT(x)         Platform_Halt(x)
#define __ASSERT(cond, x) if (!(cond)) Platform_AssertFail((int32)(x))


// Index checking

static inline int64 __XF(uint64 i, uint64 ub) {if (i >= ub) {__HALT(-2);} return i;}
#define __X(i, ub) (((i)<(ub))?i:(__HALT(-2),0))


// Range checking, and checked SHORT and CHR functions

static inline int64 __RF(uint64 i, uint64 ub) {if (i >= ub) {__HALT(-8);} return i;}
#define __R(i, ub)      (((i)<(ub))?i:(__HALT(-8),0))
#define __SHORT(x, ub)  ((int)((uint64)(x)+(ub)<(ub)+(ub)?(x):(__HALT(-8),0)))
#define __SHORTF(x, ub) ((int)(__RF((x)+(ub),(ub)+(ub))-(ub)))
#define __CHR(x)        ((CHAR)__R(x, 256))
#define __CHRF(x)       ((CHAR)__RF(x, 256))



// Signal handling in SYSTEM.c

#ifndef _WIN32
  extern void SystemSetHandler(int s, address h);
#else
  extern void SystemSetInterruptHandler(address h);
  extern void SystemSetQuitHandler     (address h);
#endif



// String comparison

static inline int __str_cmp(CHAR *x, CHAR *y){
  int64 i = 0;
  CHAR ch1, ch2;
  do {ch1 = x[i]; ch2 = y[i]; i++;
    if (!ch1) return -(int)ch2;
  } while (ch1==ch2);
  return (int)ch1 - (int)ch2;
}
#define __STRCMP(a,b) __str_cmp((CHAR*)(a), (CHAR*)(b))



// Inline string, record and array copy

#define __COPY(s, d, n) {char*_a=(void*)s,*_b=(void*)d; LONGINT _i=0,_t=n-1; \
                         while(_i<_t&&((_b[_i]=_a[_i])!=0)){_i++;};_b[_i]=0;}
#define __DUP(x, l, t)  x=(void*)memcpy((void*)Platform_OSAllocate(l*sizeof(t)),x,l*sizeof(t))
#define __DUPARR(v, t)  v=(void*)memcpy(v##__copy,v,sizeof(t))
#define __DEL(x)        Platform_OSFree((address)x)


/* SYSTEM ops */

#define __VAL(t, x)     (*(t*)&(x))


#define __GET(a, x, t)  x=*(t*)(address)(a)
#define __PUT(a, x, t)  *(t*)(address)(a)=x

#define __LSHL(x, n, s) ((int##s)((uint##s)(x)<<(n)))
#define __LSHR(x, n, s) ((int##s)((uint##s)(x)>>(n)))
#define __LSH(x, n, s)  ((n)>=0? __LSHL(x, n, s): __LSHR(x, -(n), s))

#define __ROTL(x, n, s) ((int##s)((uint##s)(x)<<(n)|(uint##s)(x)>>(s-(n))))
#define __ROTR(x, n, s) ((int##s)((uint##s)(x)>>(n)|(uint##s)(x)<<(s-(n))))
#define __ROT(x, n, s)  ((n)>=0? __ROTL(x, n, s): __ROTR(x, -(n), s))

#define __ASHL(x, n)    ((int64)(x)<<(n))
#define __ASHR(x, n)    ((int64)(x)>>(n))
#define __ASH(x, n)     ((n)>=0?__ASHL(x,n):__ASHR(x,-(n)))
static inline int64 SYSTEM_ASH(int64 x, int64 n) {return __ASH(x,n);}
#define __ASHF(x, n)    SYSTEM_ASH((int64)(x), (int64)(n))

#define __MOVE(s, d, n) memcpy((char*)(address)(d),(char*)(address)(s),n)


extern int64 SYSTEM_DIV(int64 x, int64 y);
#define __DIVF(x, y) SYSTEM_DIV(x, y)
#define __DIV(x, y) (((x)>0 && (y)>0) ? (x)/(y) : __DIVF(x, y))


extern int64 SYSTEM_MOD(int64 x, int64 y);
#define __MODF(x, y) SYSTEM_MOD(x, y)
#define __MOD(x, y) (((x)>0 && (y)>0) ? (x)%(y) : __MODF(x, y))


extern int64 SYSTEM_ENTIER (double x);
#define __ENTIER(x) SYSTEM_ENTIER(x)


#define __ABS(x) (((x)<0)?-(x):(x))

static inline int32 SYSTEM_ABS64(int64 i) {return i >= 0 ? i : -i;}
static inline int64 SYSTEM_ABS32(int32 i) {return i >= 0 ? i : -i;}
#define __ABSF(x) ((sizeof(x) <= 4) ? SYSTEM_ABS32(i) : SYSTEM_ABS64(i))

static inline double SYSTEM_ABSD(double i) {return i >= 0.0 ? i : -i;}
#define __ABSFD(x) SYSTEM_ABSD(x)

#define __CAP(ch)       ((CHAR)((ch)&0x5f))
#define __ODD(x)        ((x)&1)

#define __IN(x, s, size)     (((unsigned int)(x))<size && ((((uint##size)(s))>>(x))&1))
// todo tested versions of SETOF and SETRNG: check that x, l and h fit size
#define __SETOF(x, size)     ((uint##size)1<<(x))
#define __SETRNG(l, h, size) ((~(uint##size)0<<(l))&~(uint##size)0>>(size-1-(h)))

#define __MASK(x, m) ((x)&~(m))
#define __BIT(x, n)  (*(uint64*)(x)>>(n)&1)



// Runtime checks

#define __RETCHK     __retchk: __HALT(-3); return 0;
#define __CASECHK    __HALT(-4)
#define __WITHCHK    __HALT(-7)


#define __IS(tag, typ, level) (*(tag-(__BASEOFF-level))==(address)typ##__typ)
#define  __TYPEOF(p)          (*(((address**)(p))-1))
#define __ISP(p, typ, level)  __IS(__TYPEOF(p),typ,level)


#define __GUARDP(p, typ, level)    ((typ*)(__ISP(p,typ,level)?p:(__HALT(-5),p)))
#define __GUARDR(r, typ, level)    (*((typ*)(__IS(r##__typ,typ,level)?r:(__HALT(-5),r))))
#define __GUARDA(p, typ, level)    ((struct typ*)(__IS(__TYPEOF(p),typ,level)?p:(__HALT(-5),p)))
#define __GUARDEQR(p, dyntyp, typ) if(dyntyp!=typ##__typ) __HALT(-6);*(p)
#define __GUARDEQP(p, typ)         if(__TYPEOF(p)!=typ##__typ)__HALT(-6);*(p)



// Module entry/registration/exit

extern void       Heap_REGCMD();
extern SYSTEM_PTR Heap_REGMOD();
extern void       Heap_REGTYP();
extern void       Heap_INCREF();

#define __DEFMOD              static void *m; if (m!=0) {return m;}
#define __REGCMD(name, cmd)   Heap_REGCMD(m, (CHAR*)name, cmd)
#define __REGMOD(name, enum)  if (m==0) {m = Heap_REGMOD((CHAR*)name,enum);}
#define __ENDMOD              return m
#define __MODULE_IMPORT(name) Heap_INCREF(name##__init())



// Main module initialisation, registration and finalisation

extern void Platform_Init(int32 argc, address argv);
extern void Heap_FINALL();

#define __INIT(argc, argv)    static void *m; Platform_Init(argc, (address)&argv);
#define __REGMAIN(name, enum) m = Heap_REGMOD((CHAR*)name,enum)
#define __FINI                Heap_FINALL(); return 0


// Memory allocation

extern SYSTEM_PTR Heap_NEWBLK (address size);
extern SYSTEM_PTR Heap_NEWREC (address tag);
extern SYSTEM_PTR SYSTEM_NEWARR(address*, address, int, int, int, ...);

#define __SYSNEW(p, len) p = Heap_NEWBLK((address)(len))
#define __NEW(p, t)      p = Heap_NEWREC((address)t##__typ)
#define __NEWARR         SYSTEM_NEWARR



/* Type handling */

extern void SYSTEM_INHERIT(address *t, address *t0);
extern void SYSTEM_ENUMP  (void *adr, address n, void (*P)());
extern void SYSTEM_ENUMR  (void *adr, address *typ, address size, address n, void (*P)());


#define __TDESC(t, m, n)                                                \
  static struct t##__desc {                                             \
    address  tproc[m];         /* Proc for each ptr field            */ \
    address  tag;                                                       \
    address  next;             /* Module table type list points here */ \
    address  level;                                                     \
    address  module;                                                    \
    char     name[24];                                                  \
    address  basep[__MAXEXT];  /* List of bases this extends         */ \
    address  reserved;                                                  \
    address  blksz;            /* xxx_typ points here                */ \
    address  ptr[n+1];         /* Offsets of ptrs up to -ve sentinel */ \
  } t##__desc

#define __BASEOFF   (__MAXEXT+1)                           // blksz as index to base.
#define __TPROC0OFF (__BASEOFF+24/sizeof(address)+5)       // blksz as index to tproc IFF m=1.
#define __EOM 1
#define __TDFLDS(name, size)          {__EOM}, 1, 0, 0, 0, name, {0}, 0, size
#define __ENUMP(adr, n, P)            SYSTEM_ENUMP(adr, (address)(n), P)
#define __ENUMR(adr, typ, size, n, P) SYSTEM_ENUMR(adr, typ, (address)(size), (address)(n), P)

#define __INITYP(t, t0, level) \
  t##__typ               = (address*)&t##__desc.blksz;                                                    \
  memcpy(t##__desc.basep, t0##__typ - __BASEOFF, level*sizeof(address));                                  \
  t##__desc.basep[level] = (address)t##__typ;                                                             \
  t##__desc.module       = (address)m;                                                                    \
  if(t##__desc.blksz!=sizeof(struct t)) __HALT(-15);                                                      \
  t##__desc.blksz        = (t##__desc.blksz+5*sizeof(address)-1)/(4*sizeof(address))*(4*sizeof(address)); \
  Heap_REGTYP(m, (address)&t##__desc.next);                                                               \
  SYSTEM_INHERIT(t##__typ, t0##__typ)

// Oberon-2 type bound procedures support
#define __INITBP(t, proc, num)            *(t##__typ-(__TPROC0OFF+num))=(address)proc
#define __SEND(typ, num, funtyp, parlist) ((funtyp)((address)*(typ-(__TPROC0OFF+num))))parlist




#endif
