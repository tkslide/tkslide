/*
 * $Id: h.h,v 1.12 2003/05/31 22:09:54 phil Exp $
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

#ifdef __STDC__
#define STRING(s) #s
#define CONC(a,b) a##b
#else  /* __STDC__ not defined */
#define STRING(s) "s"
#define CONC(a,b) a/**/b
#endif /* __STDC__ not defined */

/* HP unbundled cc defines __STDC__ as zero; does not implement const! */
#if __STDC__ == 0 && defined(__hpux)
#define NEED_CONST
#endif /* __STDC__ == 0 && defined(__hpux) */

#if !defined(__STDC__) || defined(NEED_CONST)
#define const
#define volatile
#endif /* !defined(__STDC__) || defined(NEED_CONST) */

#ifndef __P
#ifdef __STDC__
#define __P(proto) proto
#else  /* __STDC__ not defined */
#define __P(proto) ()
#endif /* __STDC__ not defined */
#endif /* __P not defined */

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


