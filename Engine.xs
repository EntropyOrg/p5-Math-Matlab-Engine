#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

#include "engine.h"

#define BUFSIZE 1024*256
#define MATH_MATLAB_ENGINE_DEBUG 0

typedef struct {
	Engine * ep;
	char * EvalBuf;
} EngineIface;

MODULE = Math::Matlab::Engine		PACKAGE = Math::Matlab::Engine	PREFIX = eng_
PROTOTYPES: ENABLE

EngineIface *
eng_new(CLASS)
	char *		CLASS
    CODE:
    {
	EngineIface *eng;

	if (NULL == (eng = malloc(sizeof(EngineIface))))
		croak ("Cannot allocate engine object");

	char* start_string = NULL;
	if (!(eng->ep = engOpen(start_string) ))
		croak ("Failed to start MATLAB engine");

	// Alloc the buffer for the output of evals
	if (NULL == (eng->EvalBuf = malloc(BUFSIZE)))
		croak ("Failed to allocate eval output buffer");

	engOutputBuffer(eng->ep, eng->EvalBuf, BUFSIZE);


	RETVAL = eng;
    }
    OUTPUT:
	RETVAL

int
eng_close(eng)
	EngineIface *	eng
	CODE:
	{
	RETVAL = 1 - engClose(eng->ep);
	}
	OUTPUT:
	RETVAL

void
eng_DESTROY(eng)
	EngineIface * eng
	CODE:
	{
	engClose(eng->ep);
	free(eng->EvalBuf);
	free(eng);
	}

SV*
eng__eval_helper(eng, string)
	EngineIface *	eng
	const char *	string
    CODE:
    {
	if (engEvalString(eng->ep, string) == 0) {
		if( MATH_MATLAB_ENGINE_DEBUG ) fprintf(stderr, "DEBUG: String from eval=%s$\n",eng->EvalBuf);
		if( MATH_MATLAB_ENGINE_DEBUG ) fprintf(stderr, "DEBUG: EvalString on MATLAB engine %x\n",eng->ep);
		RETVAL = newSVpv(eng->EvalBuf,0);
	} else {
		// We couldnt talk to the matlab engine.
		// return undef
		if( MATH_MATLAB_ENGINE_DEBUG ) fprintf(stderr, "ERROR: Could not talk to MATLAB engine: %x\n",eng->ep);
		XSRETURN_UNDEF;
	}
    }
    OUTPUT:
	RETVAL
