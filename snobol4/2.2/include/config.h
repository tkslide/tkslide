/* $Id: config.h,v 1.84 2020-11-16 03:37:42 phil Exp $ */

/*
 * Native Windows32 config.h 1/27/2002
 * Windows64 too! 9/23/2013
 *
 * Used for Borland, MINGW, and MSVC
 * (builds using native Windows runtime)
 */

// no longer needed?
#ifndef __STDC__
/*
 * MSVC: by default __STDC__ is undefined!?
 *	-Za defines __STDC__ to 1, but turns off useful non-ANSI extensions!!
 */
#define __STDC__	0
#endif /* __STDC__ not defined */

// needed for ptyio
#define NTDDI_VERSION NTDDI_WIN10_RS5
#define _WIN32_WINNT _WIN32_WINNT_WIN10	// min WINXP for getaddrinfo

#define BLOCKS

/* datatypes; */
#define SIGFUNC_T	void __cdecl
#define SETSOCKOPT_ARG_CAST (const char *)

/* paths; */
#define SNOLIB_FILE	"snolib.dll"
#define SNOLIB_BASE	"C:\\Program Files\\SNOBOL4"
#define SHARED_OBJ_SUBDIR "shared"
#define DIR_SEP		"\\"
#define PATH_SEP	";"
#define DL_EXT		".dll"

/* includes; */
#define HAVE_SDBM_H
#define HAVE_IO_H		/* _dup */

#define WIN32_LEAN_AND_MEAN

#define UNLINK_IN_STDIO_H
#define OSDEP_OPEN
#define TTY_READ_RAW
#define HAVE_GETVERSIONEX
#define HAVE_STRFTIME
#define NEED_GETLINE
#define HAVE_FIND_SNOLIB_DIRECTORY

#ifdef HAVE_WINSOCK2_H
#define SOCKLEN_T socklen_t
#define NEED_BINDRESVPORT_SA		/* checked in bindresvport.h */
#else
#define SOCKLEN_T int
#define NEED_BINDRESVPORT		/* checked in bindresvport.[ch] */
#endif

/* trap of ^C sets EOF */
#define SIGINT_EOF_CHECK

/* DLL import/export macros */

/*
 * SNOBOL4 defined if building snobol4.exe or (experimental) snobol4.dll
 * SNOBOL4 & SHARED defined if building snobol4.dll
 * neither defined when building LOADable module
 *		shared library client (ssnobol.exe, tlib.exe)
 *
 * load.h (LOADable module API) defines SNOLOAD_API as:
 *	EXPORT if SNOBOL4 defined (building snobol4.exe, snobol4.dll)
 *	IMPORT otherwise (building LOADable module DLL)
 * snobol4.h (DLL API) defines SNOBOL4_API as:
 *	noop   if SNOBOL4 defined and SHARED not defined (building snobol4.exe)
 *	EXPORT if SNOBOL4 defined and SHARED defined (building snobol4.dll)
 *	IMPORT if neither defined (ssnobol4.exe tlib.exe , other DLL client)
 */

#if defined(_MSC_VER) || defined(__MINGW32__)
#define EXPORT(TYPE) __declspec(dllexport) TYPE
#elif defined(__BORLANDC__)
#define EXPORT(TYPE) TYPE _export
#endif /* defined(__BORLANDC__) */

#ifndef SNOBOL4	  /* building LOADable module DLL, snobol4.dll user */
#if defined(_MSC_VER) || defined(__MINGW32__)
#define IMPORT(TYPE) __declspec(dllimport) TYPE
#elif defined(__BORLANDC__)
#define IMPORT(TYPE) TYPE _import	/* ??? */
#endif  /* defined(__BORLANDC__) */
#endif /* SNOBOL4 not defined */

/* non-standard functions; */
#define finite		_finite
//#define isnan		_isnan		/* 2020: not needed w/ VSC or MINGW */
#define popen		_popen
#define pclose		_pclose
#define dup		_dup
#define read		_read
#define write		_write

/*
 * C90 & POSIX.1-2001:
 */
#ifndef __MINGW32__ /* fseeko in mingw stdio.h! */
#define io_off_t __int64
#define ftello(FP) _ftelli64(FP)
#define fseeko(FP,OFF,WHENCE) _fseeki64(FP,OFF,WHENCE)
#endif
#define HAVE_FSEEKO			/* now we do! */

/****
 * for time & random modules
 */

#if defined(_MSC_VER)

#define HAVE_TIMESPEC_GET		// in ucrt 10.0.18362.0?
#define GETPID_IN_PROCESS_H
#define NEED_GETOPT
#define NEED_GETOPT_EXTERNS
#define NEED_DIRNAME

#elif defined(__MINGW32__)

#define HAVE_UNISTD_H			// getpid !!!
#define HAVE_DIRNAME
#define HAVE_GETOPT

// in -lpthread w/ mingw-w64-x86-64-dev 7.0.0 (does not work?)
//#define HAVE_CLOCK_GETTIME_REALTIME 

#if defined(__LP64__) && !defined(_WIN64)
#define _WIN64
#endif

#endif // end __MINGW32__

#define HAVE_SLEEP

/*
 * in MINGW 1.0.19 time.h, which says:
 * "introduced in MSVCR80.DLL, and they subsequently
 *  appeared in MSVCRT.DLL, from Windows-Vista onwards."
 */
#define HAVE_TIMEGM			
#define timegm		_mkgmtime

/*
 * end for time module
 ****/

#ifdef _WIN64
/*
 * 64-bit binary cross-compiled with VS2012 worked (the first time!)
 * It looks like it's an "LLP64" evironment:
 *	".... a 32-bit model with 64-bit addresses ...."
 *	http://www.unix.org/version2/whatsnew/lp64_wp.html
 */
#define NO_BITFIELDS
#define SIZLIM (~(VFLD_T)0)
#define INT_T long long
#define REAL_T double
#define REALST_FORMAT "%.15lg"
#define SIZEOF_INT_T 8
#define SIZEOF_REAL_T 8
#else
// 32-bits:
#define INT_T long			/* default, but used below */
#define SIZEOF_INT_T 4
#define SIZEOF_REAL_T 4
#endif

/* INT_T should always be large enough to hold a pointer */
#define ssize_t INT_T

#define sock_t unsigned INT_T // SOCKET: unsigned that can hold a pointer
#define close_socket	closesocket

/* use native routines */
#define USE_MEMMOVE
#define USE_MEMSET

#if defined(_MSC_VER)			/* *** Microsoft C */

/* ignored if NO_BITFIELDS defined (64-bits) */
#define BITFIELDS_SAME_TYPE		/* or else won't pack them! */

#define OBJECT_EXT ".obj"
#define SETUP_SYS "win.msc"
/* from ntmsvc.mak: CC, COPT, SO_LD, DL_LD, DL_CFLAGS */
#define DL_LDFLAGS "/DLL /NOLOGO"
#define CC_IS "msc"

#elif defined(__GNUC__)			/* *** MINGW */

#define OBJECT_EXT ".o"
#define SETUP_SYS "posix" /* !!! */
/* from mingw.mak: CC, COPT, SO_LD, DL_LD */
#define DL_CFLAGS ""
#define DL_LDFLAGS "-shared -shared-libgcc"
#define CC_IS "gcc"

#elif defined(__BORLANDC__)		/* *** Borland */

#define OBJECT_EXT ".obj"
#define SETUP_SYS "win.borland"
#define CCOMPILER "bcc32"
#define DL_LDFLAGS "-tWD"
#define CC_IS "borland"

#endif /* defined(__BORLANDC__) */

#define SO_CFLAGS DL_CFLAGS
#define SO_DLFLAGS DL_DLFLAGS
