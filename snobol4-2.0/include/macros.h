/*
 * $Id: macros.h,v 1.42 2014/02/22 22:43:58 phil Exp $
 *
 * macros for data access and implementation of SIL ops
 */

#ifdef FINITE_IN_IEEEFP_H
#include <ieeefp.h>
#endif

/* descriptor at address x */
#define D(x)	(*(struct descr *)(x))

/* access descr fields */
#define D_A(x)	(D(x).a.i)
#define D_F(x)	(D(x).f)
#define D_V(x)	(D(x).v)

#define D_RV(x) (D(x).a.f)
#define D_PTR(x) ((void *)D(x).a.i)	/* works w/ long long */

/*
 * compare two descrs (returns boolean)
 *
 * NOTE! requires sizeof(real_t) == sizeof(int_t) or else DIFFER/IDENT
 * will fail for shorter datatype.
 *
 * comparing A field based on type (V field) does NOT
 * work because V field and A field are sometimes BOTH used to hold
 * a pair of integer datatype codes.
 */
#if SIZEOF_INT_T == SIZEOF_REAL_T
#define DCMP(A,B) (D_A(A) == D_A(B) && D_F(A) == D_F(B) && D_V(A) == D_V(B))
#else
#define DCMP(A,B) (D_F(A) == D_F(B) && D_V(A) == D_V(B) && \
		   ((D_V(A) == R && D_RV(A) == D_RV(B)) || D_A(A) == D_A(B)))
#endif

/* clear B+1 descriptor block */
#define ZERBLK(A,B) bzero((void *)(A), (long)((B)+DESCR)) /* XXX SIZE_T */

/*
 * copy descriptor block
 *
 * NOTE: may overlap!!
 * (bcopy deals with this but some memcpy's do not)!!!
 */
#define MOVBLK(A,B,C) bcopy((void *)((B)+DESCR),(void *)((A)+DESCR),(long)(C) )
#ifdef BLOCKS
#define MOVBLK2(A,B,C) movblk2((struct descr *)(A),(struct descr *)(B),(C))
#endif

/****************
 * string specifiers (qualifiers)
 */

/* specifier at address x */
#define _SPEC(x) (*(struct spec *)(x))

/* access spec fields */
#ifdef SPEC_FIELD_NAMES
#define S_A(x) (_SPEC(x).a.i)
#define S_F(x) (_SPEC(x).f)
#define S_V(x) (_SPEC(x).v)
#define S_L(x) (_SPEC(x).l.i)
#define S_O(x) (_SPEC(x).o)
#else  /* SPEC_FIELD_NAMES not defined */
/* alignment safe version (esp when using long long / double) */
#define S_A(x) (_SPEC(x).d[1].a.i)
#define S_F(x) (_SPEC(x).d[1].f)
#define S_V(x) (_SPEC(x).d[1].v)
#define S_L(x) (_SPEC(x).d[0].a.i)
#define S_O(x) (_SPEC(x).d[0].v)
#endif /* SPEC_FIELD_NAMES not defined */

#define S_SP(x) ((char *)S_A(x) + S_O(x))

#if 0
#define CLR_S_UNUSED(x) (_SPEC(x).unused = 0)
#else  /* not 0 */
#define CLR_S_UNUSED(x)
#endif /* not 0 */

/*
 * zero is most common case?!
 * one is next most common!?
 * bcopy handles anything else as well as simple loop!!
 *	should NEVER need to check for overlap!
 */
#define APDSP(BASE,STR) \
    if (S_L(STR) > 0) { apdsp((struct spec *)(BASE), (struct spec *)(STR)); }

/* must deal with A == C
 * 10/28/93
 */
#define X_REMSP(A,B,C) \
    S_A(A) = S_A(B); \
    S_F(A) = S_F(B); \
    S_V(A) = S_V(B); \
    S_O(A) = S_O(B) + S_L(C); \
    S_L(A) = S_L(B) - S_L(C); \
    CLR_S_UNUSED(A)

#define X_LOCSP(A,B) \
    if (D_A(B) == 0) S_L(A) = 0; \
    else { \
       S_A(A) = D_A(B); S_F(A) = D_F(B); S_V(A) = D_V(B); \
       S_O(A) = BCDFLD; S_L(A) = D_V(D_A(B)); CLR_S_UNUSED(A); \
    }

/* fast compare for equality */
/* XXX SIZE_T */
#define LEXEQ(A,B) (S_L(A) == S_L(B) &&			\
		    (S_L(A) == 0 ||			\
		     (*S_SP(A) == *S_SP(B) &&		\
		      (S_L(A) == 1 ||			\
		       (S_SP(A)[1] == S_SP(B)[1] &&	\
			(S_L(A) == 2 ||			\
			 (bcmp(S_SP(A)+2,S_SP(B)+2,(long)S_L(A)-2) == 0)))))))

/* 11/4/97 - get length for string structure */
#define X_GETLTH(A) (DESCR * (3 + ((S_L(A) - 1) / CPD + 1)))

/* 11/4/97 - get block size for GC */
#define X_BKSIZE(A) \
    ((D_F(A) & STTL) ? (DESCR*(4+((D_V(A)-1)/CPD+1))) : D_V(A) + DESCR)

/****************
 * system stack
 */

#ifndef NO_STATIC_VARS
#ifndef S4_EXTERN
#define S4_EXTERN extern
#endif /* S4_EXTERN not defined */

S4_EXTERN struct descr *cstack;
S4_EXTERN struct descr ostack[1];	/* old stack pointer */
#endif /* NO_STATIC_VARS not defined */

/* RCALL support */
/* by the book, no C local ostack */

#define SAVSTK() START_CALL(); PUSH(ostack); D_A(ostack) = (int_t)cstack
#define RSTSTK() cstack = (struct descr *)D_A(ostack); POP(ostack)

/* overflow check */
#define OFCHK()	\
	{ if ((int_t)cstack > (int_t)D_A(STKEND)) OVER(NORET); }

#ifdef DO_UFCHK
/* for debug only (internal error); */
#define UFCHK()	{ if ((int_t)cstack < D_A(STKHED)) INTR10(NORET); }
#else  /* DO_UFCHK not defined */
#define UFCHK()
#endif /* DO_UFCHK not defined */

#define PUSH(x)	D(cstack+1) = D(x); cstack++; OFCHK()
#define POP(x)	cstack--; UFCHK(); D(x) = D(cstack+1)

#define SPUSH(x) _SPEC(cstack+1) = _SPEC(x); cstack += SPEC/DESCR; OFCHK()
#define SPOP(x)	 cstack -= SPEC/DESCR; UFCHK(); _SPEC(x) = _SPEC(cstack+1)

#define ISTACK() cstack = (struct descr *)D_A(STKHED);
#define PSTACK(x) D_A(x) = (int_t)(cstack-1); D_F(x) = D_V(x) = 0

/****************/

#ifdef PANIC_PUTS
#define PANIC(S) puts(S)
#else  /* PANIC_PUTS not defined */
#define PANIC(S)
#endif /* PANIC_PUTS not defined */

/****************/

#ifndef NO_STATIC_VARS
extern volatile int math_error;
#endif /* NO_STATIC_VARS not defined */

#define CLR_MATH_ERROR() math_error = FALSE
#define MATH_ERROR() math_error
#ifdef HAVE_ISFINITE
#define REAL_ISFINITE(RESULT) isfinite((RESULT))
#else
#define REAL_ISFINITE(RESULT) finite((RESULT))
#endif
#define RMATH_ERROR(RESULT) (MATH_ERROR() || !REAL_ISFINITE((RESULT)))

/****************/

#define ENTRY(NAME) 

#ifdef TRACE_DEPTH
/* on real call; increment call depth; clear tail call depth for this level */
#define START_CALL() cdepth++; tdepth[cdepth]=0;
/* on tail call; inrement tail calls for this level */
#define BRANCH(NAME) {tdepth[cdepth]++; return (NAME (retval));}
/* on real return; record returns from this tail call depth; decrement level */
#define RETURN(VALUE) {returns[tdepth[cdepth--]]++; RSTSTK(); return (VALUE);}
#else  /* TRACE_DEPTH not defined */
#define START_CALL()
#define BRANCH(NAME) return (NAME (retval));
#define RETURN(VALUE) {RSTSTK(); return (VALUE);}
#endif /* TRACE_DEPTH not defined */

struct descr _NORET[1];
#define NORET ((ptr_t)_NORET)

/****************/
/* cast parameters for library calls */

#define ADDSIB(A,B) addsib((struct descr *)(A),(struct descr *)(B))
#define ADDSON(A,B) addson((struct descr *)(A),(struct descr *)(B))
#define X_INSERT(A,B) insert((struct descr *)(A),(struct descr *)(B))
#define LINKOR(A,B) linkor((struct descr *)(A),(struct descr *)(B))
#define LVALUE(A,B) lvalue((struct descr *)(A),(struct descr *)(B))

#define TOP(A,B,C) \
     top((struct descr *)(A),(struct descr *)(B),(struct descr *)(C))
#define LOCAPT(A,B,C) \
     locapt((struct descr *)(A),(struct descr *)(B),(struct descr *)(C))
#define LOCAPV(A,B,C) \
     locapv((struct descr *)(A),(struct descr *)(B),(struct descr *)(C))
#define EXPINT(A,B,C) \
     expint((struct descr *)(A),(struct descr *)(B),(struct descr *)(C))
#define EXREAL(A,B,C) \
     exreal((struct descr *)(A),(struct descr *)(B),(struct descr *)(C))
#define IO_SEEK(A,B,C) \
     io_seek((struct descr *)(A),(struct descr *)(B),(struct descr *)(C))

#define CALLX(A,B,C,D) \
     callx((struct descr *)(A),(struct descr *)(B),\
	    (struct descr *)(C),(struct descr *)(D))

#define CPYPAT(A,B,C,D,E,F) \
     cpypat((struct descr *)(A),(struct descr *)(B),(struct descr *)(C),\
	    (struct descr *)(D),(struct descr *)(E),(struct descr *)(F))
#define MAKNOD(A,B,C,D,E,F) \
     maknod((struct descr *)(A),(struct descr *)(B),(struct descr *)(C),\
	    (struct descr *)(D),(struct descr *)(E),(struct descr *)(F))

/**/

#define RAISE1(A) raise1((struct spec *)(A))
#define _UNLOAD(A) unload((struct spec *)(A))
#define GETPARM(A) getparm((struct spec *)(A))

#define RAISE2(A,B) raise2((struct spec *)(A),(struct spec *)(B))
#define LEXCMP(A,B) lexcmp((struct spec *)(A),(struct spec *)(B))
#define TRIMSP(A,B) trimsp((struct spec *)(A),(struct spec *)(B))
#define REVERSE(A,B) reverse((struct spec *)(A),(struct spec *)(B))

#define _RPLACE(A,B,C) \
     rplace((struct spec *)(A),(struct spec *)(B),(struct spec *)(C))
/**/

#define XANY(A,B) any((struct spec *)(A),(struct descr *)(B))
#define _DATE(A,B) date((struct spec *)(A),(struct descr *)(B))
#define GETBAL(A,B) getbal((struct spec *)(A),(struct descr *)(B))
#define REALST(A,B) realst((struct spec *)(A),(struct descr *)(B))
#define INTSPC(A,B) intspc((struct spec *)(A),(struct descr *)(B))
#define GETPMPROTO(A,B) getpmproto((struct spec *)(A),(struct descr *)(B))

#define IO_PAD(A,B) io_pad((struct spec *)(A),(B))

#define HASH(A,B) hash((struct descr *)(A),(struct spec *)(B))
#define SPCINT(A,B) spcint((struct descr *)(A),(struct spec *)(B))
#define SPREAL(A,B) spreal((struct descr *)(A),(struct spec *)(B))
#define IO_READ(A,B) io_read((struct descr *)(A),(struct spec *)(B))
#define IO_FILE(A,B) io_file((struct descr *)(A),(struct spec *)(B))
#define IO_INCLUDE(A,B) io_include((struct descr *)(A),(struct spec *)(B))

#define IO_OPENO(A,B,C) \
     io_openo((struct descr *)(A),(struct spec *)(B),(struct spec *)(C))
#define _LOAD(A,B,C) \
     load((struct descr *)(A),(struct spec *)(B),(struct spec *)(C))

#define STREAM(A,B,C) stream((struct spec *)(A),(struct spec *)(B),(C))
#define PLUGTB(A,B,C) plugtb((A),(B),(struct spec *)(C))

#define IO_PRINT(A,B,C)\
	io_print((struct descr *)(A),(struct descr *)(B),(struct spec *)(C))

#define XSUBSTR(A,B,C) \
     substr((struct spec *)(A),(struct spec *)(B),(struct descr *)(C))

#define PAD(A,B,C,D) \
     pad((struct descr *)(A),(struct spec *)(B),\
	 (struct spec *)(C),(struct spec *)(D))

#define IO_OPENI(A,B,C,D) \
     io_openi((struct descr *)(A),(struct spec *)(B),\
	      (struct spec *)(C),(struct descr *)(D))

/* for BLOCKS! 9/26/2013 */
#define MERGSP(A,B,C) mergsp((struct spec *)(A),(struct spec *)(B),(struct spec *)(C))
#define FASTPR(A,B,C,S,T) \
	io_fastpr((struct descr *)(A),(struct descr *)(B),(struct descr *)(C),\
		  (struct spec *)(S),(struct spec *)(T))
