/* $Id: config.h,v 1.52 2014/12/27 20:27:11 phil Exp $ */

/*
 * Windows32 config.h 1/27/2002
 * Windows64 too! 9/23/2013
 *
 * Used for Borland, MINGW, and MSVC
 */

#ifndef __STDC__
/*
 * MSVC: by default __STDC__ is undefined!?
 *	-Za defines __STDC__ to 1, but turns off useful non-ANSI extensions!!
 */
#define __STDC__	0
#endif /* __STDC__ not defined */

#define BLOCKS

/* datatypes; */
#define SIGFUNC_T	void __cdecl

/* paths; */
#define SNOLIB_FILE	"snolib.dll"
#define SNOLIB_BASE	"C:\\snobol4"
#define SHARED_OBJ_SUBDIR "shared"
#define DIR_SEP		"\\"
#define PATH_SEP	";"
#define DL_EXT		".dll"

/* includes; */
#define HAVE_STRING_H
#define HAVE_STDARG_H
#define HAVE_STDLIB_H
#define HAVE_WINSOCK_H
#define HAVE_SDBM_H

#define WIN32_LEAN_AND_MEAN

#define NEED_BINDRESVPORT
#define OSDEP_OPEN
#define TTY_READ_RAW
#define HAVE_GETVERSIONEX

#define SOCKLEN_T int

#ifdef __GNUC__
/* declarations for gcc builtins? */
#endif

/* DLL import/export macros */

#if defined(_MSC_VER) || defined(__MINGW32__)
#define EXPORT(TYPE) __declspec(dllexport) TYPE
#elif defined(__BORLANDC__)
#define EXPORT(TYPE) TYPE _export
#endif /* defined(__BORLANDC__) */

/* only define IMPORT when building a loadable DLL?? */
#ifdef DLL
#if defined(_MSC_VER) || defined(__MINGW32__)
#define IMPORT(TYPE) __declspec(dllimport) TYPE
#elif defined(__BORLANDC__)
#define IMPORT(TYPE) TYPE _import	/* ??? */
#endif /* defined(__BORLANDC__) */
#endif /* DLL defined */

/* non-standard functions; */
#define finite		_finite
#define isnan		_isnan
#define popen		_popen
#define pclose		_pclose

/****
 * for time module
 */
#define HAVE_SLEEP

#ifndef __GNUC__
#define HAVE_TIMEGM			/* not in MINGW 1.0.7(0.48/3/2) */
#define timegm		_mkgmtime
#endif
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
#define SIZEOF_INT_T 4
#define SIZEOF_REAL_T 4
#endif

/* use native routines */
#define USE_MEMMOVE
#define USE_MEMSET

#if defined(_MSC_VER)
#define OBJECT_EXT ".obj"
#define SETUP_SYS "win.msc"
/* DL_CFLAGS from ntmsvc.mak */
#define DL_LDFLAGS "/DLL /NOLOGO"
#elif defined(__GNUC__)
#define OBJECT_EXT ".o"
#define USE_WCHAR_H
#define SETUP_SYS "posix"		/* !!! */
#define DL_CFLAGS ""
#define DL_LDFLAGS "-shared -shared-libgcc"
#elif defined(__BORLANDC__)
#define OBJECT_EXT ".obj"
#define SETUP_SYS "win.borland"
#define CCOMPILER "bcc32"
#define DL_LDFLAGS "-tWD"
#endif /* defined(__BORLANDC__) */

#define SO_CFLAGS DL_CFLAGS
#define SO_DLFLAGS DL_DLFLAGS
