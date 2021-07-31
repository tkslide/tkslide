/* $Id: load.h,v 1.46 2020-11-19 02:31:31 phil Exp $ */

/*
 * API for LOADable function modules
 */

/*
 * plb 6/2/94
 */

/* macros for loadable user functions;
 *
 * ie;
 * lret_t
 * myfunc(LA_ALIST) {
 *   RETFAIL;
 * }
 */

#define pmlret_t int			/* built-in functions (PML) */
#define lret_t EXPORT(pmlret_t)

#define LA_ALIST LOAD_PROTO
#define LA_DCL				/* K&R compat artifact */

/*
 * macros to fetch arguments
 * XXX check nargs?  check datatypes???
 */
#define LA_DESCR(N) (args + (N))	/* pointer to descr for n'th arg */
#define LA_TYPE(N) D_V(LA_DESCR(N))	/* datatype of n'th arg */
#define LA_INT(N) D_A(LA_DESCR(N))	/* n'th arg as integer */
#define LA_REAL(N) D_RV(LA_DESCR(N))	/* n'th arg as real */
#define LA_PTR(N) ((void *)LA_INT(N))	/* n'th arg as pointer */

/* avoid copying raw with getstring() */
#define LA_STR_LEN(N) (LA_PTR(N) ? D_V(LA_PTR(N)) : 0)

/* NOT NUL TERMINATED!!! MUST NOT BE MODIFIED!!! */
/* used to use "const char *" but turned it off for NDBM on VMS */
#define LA_STR_PTR(N) (LA_PTR(N) ? ((char *)LA_PTR(N) + BCDFLD) : NULL)

/*
 * macros to return values;
 * NOTE: use of do { .... } while (0) allows user to 
 * place macro invocations anywhere, and to use a ';' after
 */

#define SETRETVAL(VAL, TYPE) \
    do { \
	VAL; \
	D_F(retval) = 0; \
	RETTYPE = (TYPE); \
	return TRUE; \
    } while (0)

#define RETINT(x) SETRETVAL(D_A(retval) = (x), I)
#define RETREAL(x) SETRETVAL(D_RV(retval) = (x), R)
#define RETNULL SETRETVAL(D_A(retval) = 0, S)

/*
 * return a string from loaded function.
 * need not be a NUL terminated C-string.
 * buffer will be malloc'ed by retstring, and freed by relstring
 */
#define RETSTR2(CP,LEN) do { \
	retstring(retval, CP, LEN); \
	return TRUE;		\
    } while (0)

/*
 * return a counted (possibly non-NUL terminated) string in malloc'ed
 * memory.  Memory will be freed by call to relstring.
 */
#define RETSTR2_FREE(CP,LEN) do { \
	retstring_free(retval, CP, LEN); \
	return TRUE;		\
    } while (0)

/*
 * improved!! old version now called RETSTR2().
 * NOTE: evaluates argument once, so it can be a function call.
 * handles NULL pointer (returns NULL string)
 *	have an alternate version that returns failure for NULL??
 */
#define RETSTR(CP) \
    do { \
	const char *cp = (CP); \
        if (cp == NULL) RETNULL; \
	RETSTR2(cp, strlen(cp)); \
    } while (0)

/*
 * return (& free) a malloc'ed C-string.
 * As of v2.2, returns pointer to SNOBOL as type 'M' (malloc'ed linked string)
 * After string "interned" (variable generated), relstring is called.
 * (used by ffi & readline).  Binaries built with this .h file are not
 * backwards compatible (returned string will appear as EXTERNAL,
 * memory will not be freed).  Old version kept static pointer to a malloc'ed
 * buffer that was large enough to hold the largest string returned
 * (and was not freed unless a larger buffer was needed).
 */
#define RETSTR_FREE(CP) \
    do { \
	char *cp = (CP); \
        if (cp == NULL) RETNULL; \
	retstring_free(retval, (cp), strlen(cp)); \
	return TRUE; \
    } while (0)

/* return failure */
#define RETFAIL return FALSE

/* access return value type */
#define RETTYPE D_V(retval)

/* return predicate value */
#define RETPRED(SUCC) \
    do { \
	if (SUCC) RETNULL; \
	else RETFAIL; \
    } while (0)

#ifdef SNOBOL4 /* building snobol4 (or shared library) */
#define SNOLOAD_API(TYPE) EXPORT(TYPE)
#else		/* building dynamically loadable module */
#define SNOLOAD_API(TYPE) IMPORT(TYPE)
#endif

/* lib/snolib/retstring.c (not for direct use: use RETSTR[2]_FREE) */
SNOLOAD_API(void) retstring(struct descr *retval, const char *cp, int len);
SNOLOAD_API(void) retstring_free(struct descr *retval, const char *cp, int len);

/*
 * functions for use by loadable code
 */

/* lib/snolib/getstring.c; */
SNOLOAD_API(void) getstring(const void *, char *, unsigned int); /* use mgetstring!! */
SNOLOAD_API(char *) mgetstring(const void *); /* must free after use! */

/* lib/io.c; */
SNOLOAD_API(int) io_findunit(void);  /* find a free (external) unit */
SNOLOAD_API(int) io_closeall(int iunit); /* **INTERNAL** (zero-based unit) */
SNOLOAD_API(int) io_attached(int xunit);	/* boolean */
EXPORT(const char *) io_fname(int xunit);
EXPORT(int) io_skip(int xunit);

#ifdef EOF				/* stdio included */
SNOLOAD_API(int) io_mkfile(int xunit, FILE *, const char*); /* external unit */
SNOLOAD_API(int) io_mkfile_noclose(int xunit, FILE *, const char *name);
/* temporarily(?) unavailable in 2.2: */
SNOLOAD_API(FILE *) io_getfp(int xunit); /* external unit */
#endif /* EOF defined */
