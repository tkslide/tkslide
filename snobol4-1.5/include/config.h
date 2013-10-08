/* $Id: config.h,v 1.29 2013/09/27 17:08:25 phil Exp $ */

/*
 * Windows32 config.h 1/27/2002
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

/* datatypes; */
#define SIGFUNC_T	void __cdecl

/* paths; */
#define SNOLIB_FILE	"snolib.dll"
#define SNOLIB_BASE	"C:\\snobol4"
#define DIR_SEP		"\\"
#define PATH_SEP	";"
#define DL_EXT	".dll"

/* includes; */
#define HAVE_STRING_H
#define HAVE_STDARG_H
#define HAVE_STDLIB_H
#define HAVE_WINSOCK_H

#define NEED_BINDRESVPORT
#define OSDEP_OPEN
#define TTY_READ_RAW
#define WIN32_LEAN_AND_MEAN
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

/* optional features: */
#define PML_TIME
#define PML_RANDOM
#define HAVE_SLEEP

#ifdef _WIN64
/*
 * I've cross compiled a 64-bit binary with VS2012, but not tested it!
 * It looks like it's an "LLP64" evironment:
 *	".... a 32-bit model with 64-bit addresses ...."
 *	http://www.unix.org/version2/whatsnew/lp64_wp.html
 */
#define NO_BITFIELDS
#define SIZLIM (~(VFLD_T)0)
#define INT_T long long
#define REAL_T double
#define REALST_FORMAT "%.15lg"
#endif

/* use native routines */
#define USE_MEMMOVE
#define USE_MEMSET
