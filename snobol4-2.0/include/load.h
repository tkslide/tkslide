/* $Id: load.h,v 1.31 2014/12/25 00:35:30 phil Exp $ */

/*
 * plb 6/2/94
 */

/* prototype for external (LOADed) functions */
#ifdef __STDC__
#define LOAD_PROTO struct descr *retval, int nargs, struct descr *args
#define PML_FIND_ARG char *
#else  /* __STDC__ not defined */
#define LOAD_PROTO
#define PML_FIND_ARG
#endif /* __STDC__ not defined */

/* macros for loadable user functions;
 *
 * ie;
 * lret_t
 * myfunc(LA_ALIST) LA_DCL
 * {
 * }
 */

#define lret_t EXPORT(int)

#ifdef __STDC__
#define LA_ALIST LOAD_PROTO
#define LA_DCL
#else  /* __STDC__ not defined */
#define LA_ALIST retval, nargs, args
#define LA_DCL struct descr *retval, *args; int nargs;
#endif /* __STDC__ not defined */

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

/* strings */
#define RETSTR2(CP,LEN) \
    do { retstring(retval, (CP), (LEN)); return TRUE; } while(0)

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
 * return (& free) a malloc'ed C-string
 *
 * This is a quick and dirty implementation.  If this is used a lot, a
 * better implementation might be a retstring_free() function that
 * free'ed its existing buffer, and kept the new string and avoided
 * copying the data.
 */
#define RETSTR_FREE(CP) \
    do { \
	char *cp = (CP); \
        if (cp == NULL) RETNULL; \
	retstring(retval, (cp), strlen(cp)); \
	free(cp); \
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

/* lib/pml.c; used by system load.c files */
int (*pml_find(PML_FIND_ARG))(LOAD_PROTO);

#ifdef DLL
#define SNOEXP(X) IMPORT(X)
#else
#define SNOEXP(X) EXPORT(X)
#endif

/* extern/prototypes for functions; */
/* lib/snolib/getstring.c; */
SNOEXP(void) getstring __P((const void *, char *, int));
SNOEXP(char *) mgetstring __P((const void *));

/* lib/snolib/retstring.c; */
SNOEXP(void) retstring __P((struct descr *retval, const char *cp, int len));

/* lib/io.c; */
SNOEXP(int) io_findunit __P((void));	/* find a free (external) unit */
SNOEXP(int) io_closeall __P((int));	/* internal (zero-based unit) */

#ifdef EOF				/* stdio included */
SNOEXP(FILE *) io_getfp __P((int));	/* external (1-based unit) */
SNOEXP(int) io_mkfile __P((int, FILE *, char*)); /* external (1-based unit) */
#endif /* EOF defined */
