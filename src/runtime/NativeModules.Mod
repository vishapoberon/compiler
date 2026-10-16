MODULE NativeModules;

  (* Thin Unix dynamic-loader bindings. Search, validation and ownership policy
     belong to the Oberon modules which use these calls. The build also defines
     _GNU_SOURCE before SYSTEM.h: TCC's register-save binding includes libc. *)
  IMPORT SYSTEM;

  PROCEDURE -A0Feature '#ifndef _GNU_SOURCE';
  PROCEDURE -A0Feature1 '#define _GNU_SOURCE';
  PROCEDURE -A0Feature2 '#endif';
  PROCEDURE -AInclude '#include <dlfcn.h>';
  PROCEDURE -AInclude1 '#include <stdlib.h>';
  PROCEDURE -AResource '#ifndef VOC_RESOURCE_ROOT';
  PROCEDURE -AResource1 '#define VOC_RESOURCE_ROOT "/usr/share/voc"';
  PROCEDURE -AResource2 '#endif';
  PROCEDURE -ACore 'extern const INT32 VOC_CoreABI;';
  PROCEDURE -AUnload '#if defined(__GLIBC__) && defined(__linux__)';
  PROCEDURE -AUnload1 '#define VOC_NATIVE_UNLOAD 1';
  PROCEDURE -AUnload2 '#else';
  PROCEDURE -AUnload3 '#define VOC_NATIVE_UNLOAD 0';
  PROCEDURE -AUnload4 '#endif';

  PROCEDURE -open(name: ARRAY OF CHAR; flags: SYSTEM.INT32): SYSTEM.ADDRESS
    '(ADDRESS)dlopen((char*)name, flags)';
  PROCEDURE -now(): SYSTEM.INT32 'RTLD_NOW';
  PROCEDURE -global(): SYSTEM.INT32 'RTLD_GLOBAL';
  PROCEDURE -noLoad(): SYSTEM.INT32 'RTLD_NOLOAD';
  PROCEDURE -close(handle: SYSTEM.ADDRESS): SYSTEM.INT32 'dlclose((void*)handle)';
  PROCEDURE -symbol(handle: SYSTEM.ADDRESS; name: ARRAY OF CHAR): SYSTEM.ADDRESS
    '(ADDRESS)dlsym((void*)handle, (char*)name)';
  PROCEDURE -error(): SYSTEM.ADDRESS '(ADDRESS)dlerror()';
  PROCEDURE -info 'Dl_info info';
  PROCEDURE -locate(address: SYSTEM.ADDRESS): BOOLEAN 'dladdr((void*)address, &info) != 0';
  PROCEDURE -base(): SYSTEM.ADDRESS '(ADDRESS)info.dli_fbase';
  PROCEDURE -filename(): SYSTEM.ADDRESS '(ADDRESS)info.dli_fname';
  PROCEDURE -coreAddress(): SYSTEM.ADDRESS '(ADDRESS)&VOC_CoreABI';
  PROCEDURE -coreValue(): SYSTEM.INT32 'VOC_CoreABI';
  PROCEDURE -coreProfile(): SYSTEM.INT32 'VOC_CORE_ABI_PROFILE';
  PROCEDURE -abiFormat(): SYSTEM.INT32 'VOC_SHARED_ABI_FORMAT';
  PROCEDURE -unloading(): BOOLEAN 'VOC_NATIVE_UNLOAD';
  PROCEDURE -resourceRoot(): SYSTEM.ADDRESS '(ADDRESS)VOC_RESOURCE_ROOT';
  PROCEDURE -realpath(name: ARRAY OF CHAR): SYSTEM.ADDRESS '(ADDRESS)realpath((char*)name, NULL)';
  PROCEDURE -free(address: SYSTEM.ADDRESS) 'free((void*)address)';
  PROCEDURE -self(): SYSTEM.ADDRESS '(ADDRESS)NativeModules_Locate';
  PROCEDURE -abort 'abort()';

  PROCEDURE CopyString*(address: SYSTEM.ADDRESS; VAR text: ARRAY OF CHAR): BOOLEAN;
    VAR i: LONGINT; ch: CHAR;
  BEGIN
    IF LEN(text) = 0 THEN RETURN FALSE END;
    text[0] := 0X;
    IF address = 0 THEN RETURN FALSE END;
    i := 0;
    LOOP
      SYSTEM.GET(address + i, ch);
      IF i >= LEN(text) - 1 THEN text[i] := 0X; RETURN ch = 0X END;
      text[i] := ch;
      IF ch = 0X THEN RETURN TRUE END;
      INC(i)
    END
  END CopyString;

  PROCEDURE Open*(name: ARRAY OF CHAR): SYSTEM.ADDRESS;
  BEGIN RETURN open(name, now() + global()) END Open;

  PROCEDURE Pin*(name: ARRAY OF CHAR): SYSTEM.ADDRESS;
  BEGIN RETURN open(name, now() + noLoad()) END Pin;

  PROCEDURE Close*(handle: SYSTEM.ADDRESS): BOOLEAN;
  BEGIN RETURN close(handle) = 0 END Close;

  PROCEDURE Symbol*(handle: SYSTEM.ADDRESS; name: ARRAY OF CHAR): SYSTEM.ADDRESS;
  BEGIN RETURN symbol(handle, name) END Symbol;

  PROCEDURE Error*(VAR message: ARRAY OF CHAR);
  BEGIN IF ~CopyString(error(), message) THEN COPY("native loader error", message) END
  END Error;

  PROCEDURE Locate*(address: SYSTEM.ADDRESS; VAR image: SYSTEM.ADDRESS;
                    VAR name: ARRAY OF CHAR): BOOLEAN;
  BEGIN
    info;
    image := 0;
    IF LEN(name) = 0 THEN RETURN FALSE END;
    name[0] := 0X;
    IF ~locate(address) THEN RETURN FALSE END;
    image := base();
    RETURN CopyString(filename(), name)
  END Locate;

  PROCEDURE CoreAddress*(): SYSTEM.ADDRESS;
  BEGIN RETURN coreAddress() END CoreAddress;
  PROCEDURE CoreValue*(): SYSTEM.INT32;
  BEGIN RETURN coreValue() END CoreValue;
  PROCEDURE CoreProfile*(): SYSTEM.INT32;
  BEGIN RETURN coreProfile() END CoreProfile;
  PROCEDURE ABIFormat*(): SYSTEM.INT32;
  BEGIN RETURN abiFormat() END ABIFormat;
  PROCEDURE CanUnload*(): BOOLEAN;
  BEGIN RETURN unloading() END CanUnload;
  PROCEDURE ResourceRoot*(VAR root: ARRAY OF CHAR);
  BEGIN IF ~CopyString(resourceRoot(), root) THEN root[0] := 0X END
  END ResourceRoot;

  PROCEDURE CanonicalPath*(VAR name: ARRAY OF CHAR): BOOLEAN;
    VAR address: SYSTEM.ADDRESS; valid: BOOLEAN; resolved: ARRAY 4096 OF CHAR; n: LONGINT;
  BEGIN
    address := realpath(name);
    IF address = 0 THEN RETURN FALSE END;
    valid := CopyString(address, resolved); free(address);
    IF valid THEN
      n := 0; WHILE resolved[n] # 0X DO INC(n) END;
      valid := n < LEN(name);
      IF valid THEN COPY(resolved, name) END
    END;
    RETURN valid
  END CanonicalPath;

  PROCEDURE Address*(): SYSTEM.ADDRESS;
  BEGIN RETURN self() END Address;

  PROCEDURE Abort*;
  BEGIN abort END Abort;

END NativeModules.
