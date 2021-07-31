/*
 * $Id: h.h,v 1.19 2020-10-17 05:03:12 phil Exp $
 *
 * language extensions
 */

#ifndef TRUE
#define TRUE	1
#endif /* TRUE not defined */

#ifndef FALSE
#define FALSE	0
#endif /* FALSE not defined */

#ifndef NULL
#define NULL	0
#endif /* NULL not defined */

/*
 * For Windoze DLL's
 * MSC and Borland want the decl on different sides of the type!!
 */

#ifndef EXPORT
#define EXPORT(TYPE) TYPE
#endif /* EXPORT not defined */

#ifndef IMPORT
#define IMPORT(TYPE) TYPE
#endif /* IMPORT not defined */

/*
 * all statically allocated variables (both global and private)
 * *MUST* be marked as "VAR" (which should always appear AFTER
 * "static" or "extern", but before the data type (so that C99
 * __tls can be used), and SHOULD *NEVER* have an initializer
 * (other than zero), so that the state of static storage can
 * be reset for a shared library on (re)entry!!!
 */

#ifndef VAR
#ifdef SHARED
#if defined(__gcc__) || defined(__GNUC__) /* gcc-like? (clang, icc?) */
#include "gcc/vars.h"			  /* include/gcc/vars.h */
#elif defined(_MSC_VER)
#include "msvc/vars.h"
#else  /* unknown compiler */
#error "don't know how to build shared library with your compiler"
#endif /* unknown compiler */
#else  /* not SHARED library */
#define VAR
#endif /* not SHARED library */
#endif /* VAR not defined */

/* reminder for variables that need to be per-thread! */
#define TLS VAR
