#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

#include "engine.h"
#define BUFSIZE 1024*256

static int
not_here(char *s)
{
    croak("%s not implemented on this architecture", s);
    return -1;
}

static double
constant(char *name, int len, int arg)
{
    errno = EINVAL;
    return 0;
}

typedef struct {
	Engine * ep;
	char * EvalBuf;
} EngineIface;

MODULE = Math::Matlab::Engine		PACKAGE = Math::Matlab::Engine	PREFIX = eng
PROTOTYPES: ENABLE

double
constant(sv,arg)
    PREINIT:
	STRLEN		len;
    INPUT:
	SV *		sv
	char *		s = SvPV(sv, len);
	int		arg
    CODE:
	RETVAL = constant(s,len,arg);
    OUTPUT:
	RETVAL



EngineIface *
new(CLASS)
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
engClose(eng)
	EngineIface *	eng
    CODE:
    {
	RETVAL = 1 - engClose(eng->ep);
    }
    OUTPUT:
	RETVAL

void
engDESTROY(eng)
	EngineIface * eng
	CODE:
	{
	engClose(eng->ep);
	free(eng->EvalBuf);
	free(eng);
	}

SV*
engEvalString(eng, string)
	EngineIface *	eng
	const char *	string
    CODE:
    {
	if (engEvalString(eng->ep, string) == 0) {
#		fprintf(stderr, "DEBUG: String frmo eval=%s$\n",eng->EvalBuf);
#		fprintf(stderr, "DEBUG: EvalString on MATLAB engine %x\n",eng->ep);
		RETVAL = newSVpv(eng->EvalBuf,0);
	} else {
		// We couldnt talk to the matlab engine.
		// return undef
#		fprintf(stderr, "ERROR: Could not talk to MATLAB engine: %x\n",eng->ep);
        XSRETURN_UNDEF;
	}
    }
    OUTPUT:
	RETVAL


AV *
engGetArrayList(eng, name)
	EngineIface *	eng
	const char *	name

    PPCODE:
    {
	mxArray *matrix;
	int *dims, i, nelem;
	int nrdim;
	double *vals;

	matrix = engGetVariable(eng->ep, name);
	if (matrix == NULL)
		XSRETURN_UNDEF;

	nrdim = (int) mxGetNumberOfDimensions(matrix);
//	printf("%d dimensions\n",nrdim);

	dims = (int*) mxGetDimensions(matrix);
	nelem = 1;
	for(i=0;i<nrdim;i++) {
//		printf("\t%d\n",*(dims+i));
		nelem *= *(dims+i);
	}
	vals = mxGetPr(matrix);
	for(i=0;i<nelem;i++) {
		XPUSHs(sv_2mortal(newSVnv(*(vals+i))));
//		printf("%6.4f,",*(vals+i));
	}
//	printf("\n");


    }

SV *
engGetArrayListRef(eng, name)
	EngineIface *	eng
	const char *	name

    CODE:
    {
	mxArray *matrix;
	int nrdim, *dims, i, nelem;
	double *vals;
	AV *arr;

	matrix = engGetVariable(eng->ep, name);
	if (matrix == NULL)
		XSRETURN_UNDEF;

	nrdim = mxGetNumberOfDimensions(matrix);
#	printf("%d dimensions\n",nrdim);

	dims = (int*) mxGetDimensions(matrix);
	nelem = 1;
	for(i=0;i<nrdim;i++) {
#		printf("\t%d\n",*(dims+i));
		nelem *= *(dims+i);
	}
	vals = mxGetPr(matrix);
	arr = newAV();
	for(i=0;i<nelem;i++) {
		av_push(arr, newSVnv(*(vals+i)));
#		printf("%6.4f,",*(vals+i));
	}
#	printf("\n");

	RETVAL = newRV_inc((SV *) arr);
    }
    OUTPUT:
	RETVAL

SV *
engGetArray2dim(eng, name)
	EngineIface *	eng
	const char *	name

    CODE:
    {
	mxArray *matrix;
	int nrdim, *dims, i, j, nelem;
	double *vals;
	AV *arr, *mat;

	matrix = engGetVariable(eng->ep, name);
	if (matrix == NULL)
		XSRETURN_UNDEF;

	nrdim = mxGetNumberOfDimensions(matrix);
#	printf("%d dimensions\n",nrdim);

	if (nrdim != 2)
		XSRETURN_UNDEF;

	dims = (int*) mxGetDimensions(matrix);
	nelem = 1;
	for(i=0;i<nrdim;i++) {
#		printf("\t%d\n",*(dims+i));
		nelem *= *(dims+i);
	}
	vals = mxGetPr(matrix);
	mat = newAV();
	for(i=0;i<*(dims+1);i++) {
		arr = newAV();
		for(j=0;j<*dims;j++) {
#			printf("%6.4f,",*vals);
			av_push(arr, newSVnv(*(vals++)));
		}
		av_push(mat, newRV_inc((SV *) arr));
	}
#	printf("\n");

	RETVAL = newRV_inc((SV *) mat);
    }
    OUTPUT:
	RETVAL

SV *
engGetArray(eng, name)
	EngineIface *	eng
	const char *	name

    CODE:
    {
	mxArray *matrix;
	int dim, *dtmp, *d, i, j, nelem, newdim;
	double *data;
	AV **arrays;

	matrix = engGetVariable(eng->ep, name);
	if (matrix == NULL)
		XSRETURN_UNDEF;

	dim = mxGetNumberOfDimensions(matrix);

# 30.10.02: reverse order of d
	dtmp = (int*) mxGetDimensions(matrix);
	d = (int *) calloc(dim + 1, sizeof(int));
	for(i=0;i<dim;i++)
		*(d+dim-1-i) = *(dtmp+i);

#	printf("%d dimensions: ",dim);
#	for(i=0;i<dim;i++) printf(" %d",*(d+i));
#	for(i=0;i<dim;i++) printf(" %d",*(dtmp+i));
#	printf("\n");

	# allocate dim arrays and initialize
	New(1, arrays, dim, AV*);
	for(i=0;i<dim;i++)
		arrays[i] = newAV();

#	printf("memory allocated\n");

	# determine total number of elements
	nelem = 1;
	for(i=0;i<dim;i++)
		nelem *= *(d+i);

#	printf("total number of elements: %d\n",nelem);

	# data points to nelem doubles
	data = mxGetPr(matrix);

	for(i=0;i<nelem;i++) {
#		printf("i=%d\n",i);
		av_push(arrays[0], newSVnv(*(data+i)));

		newdim = 0;
		for(j=i;(j + 1) % d[newdim] == 0 && newdim < dim - 1;j=i / d[newdim++]) {
#			printf ("new dimension! step %d, j=%d\n",newdim,j);
			av_push(arrays[newdim+1], newRV_inc((SV *) arrays[newdim]));
			arrays[newdim] = newAV();
		}
	}

	RETVAL = newRV_inc((SV *) arrays[dim-1]);
    }
    OUTPUT:
	RETVAL

int
engPutArray(eng, name, dims, data)
	EngineIface *	eng
	const char *	name
	SV *		dims
	SV *		data
    CODE:
    {
	AV *arr, *dimarr;
	I32 nelem, ndim;
	int i, *d;
	double *values;
	SV *sv;
	SV **elem;
	mxArray *mat;

	# get dimensions
	dimarr = (AV *)SvRV(dims);
	ndim = av_len(dimarr);
#	printf("found %d dimensions\n", ndim + 1);
	d = (int *) calloc(ndim + 1, sizeof(int));
# 30.10.02: reverse order of creation of d
# 08.11.06: Reset this back to original order. Now is consistent wtih PutMatrix
	for(i=0;i<=ndim;i++) {
#	for(i=ndim;i>=0;i--) {
		sv = av_shift(dimarr);
		if (SvIOK(sv)) {
#			printf("Integer value: %d\n", SvIV(sv));
			*(d+i) = SvIV(sv);
		} else if (SvNOK(sv)) {
			*(d+i) = (int) SvNV(sv);
#			printf("Double value - rounded: %f\n", *(d+i));
		} else if (SvPOK(sv)) {
			STRLEN len;
#			printf("String value: %s\n", SvPV(sv, len));
			*(d+i) = atoi(SvPV(sv, len));
		} else {
#			printf("Don't know what it is!\n");
			*(d+i) = 1;
		}
		d[i] = (int) SvIV(sv);
#		printf("dimension %d: %d\n", i, d[i]);
	}

	arr = (AV *)SvRV(data);
	nelem = av_len(arr);

#	printf("Array has %d elements\n", nelem);

	mat = mxCreateNumericArray( ndim+1, (size_t*) d,  mxDOUBLE_CLASS, mxREAL);
	#mat = mxCreateDoubleMatrix(1, nelem + 1, mxREAL);
	values = mxGetPr(mat);

#	printf("array has %d elements\n", nelem + 1);
	for(i=0;i<=nelem;i++) {
#		sv = av_shift(arr);
		elem = av_fetch(arr, (I32) i, 0);
		sv = *elem;
		if (SvIOK(sv)) {
#			printf("Integer value: %d\n", SvIV(sv));
			*(values+i) = (double) SvIV(sv);
		} else if (SvNOK(sv)) {
			*(values+i) = SvNV(sv);
#			printf("Double value: %f\n", *(values+i));
		} else if (SvPOK(sv)) {
			STRLEN len;
#			printf("String value: %s\n", SvPV(sv, len));
			*(values+i) = atof(SvPV(sv, len));
		} else {
#			printf("Don't know what it is!\n");
			*(values+i) = 0.0;
		}

#		printf("value nr. %d is %f\n", i + 1, *(values+i));
	}

	// This is now obsolete. Not needed.
	//mxSetName(mat, name);

	// We now set the dims when we create the array
	//mxSetDimensions(mat, (mwSize*) d, ndim + 1);


	RETVAL = 1 - engPutVariable(eng->ep, name, mat);
#	RETVAL = 1;
    }
    OUTPUT:
	RETVAL

int
engPutMatrix(eng, name, rows, cols, data)
	EngineIface *	eng
	const char *	name
	SV *		rows
	SV *		cols
	SV *		data
    CODE:
    {
	AV *arr, *dimarr;
	I32 nelem, ndim;
	int n, m;
	int i, j, *d;
	double *values;
	SV *sv;
	SV **elem;
	mxArray *mat;

	# get dimensions
	n = SvIV(cols);
	m = SvIV(rows);

#	printf("%d columns, %d rows\n",n,m);

	arr = (AV *)SvRV(data);
	nelem = av_len(arr);

#	printf("Array has %d elements\n", nelem);

	mat = mxCreateDoubleMatrix(m, n, mxREAL);
	values = mxGetPr(mat);

#	printf("array has %d elements\n", nelem + 1);
	j = 0;
	for(i=0;i<=nelem;i++) {
		# calculate position of element
#		sv = av_shift(arr);
		elem = av_fetch(arr, (I32) i, 0);
		sv = *elem;
		if (SvIOK(sv)) {
#			printf("Integer value: %d\n", SvIV(sv));
			*(values+j) = (double) SvIV(sv);
		} else if (SvNOK(sv)) {
			*(values+j) = SvNV(sv);
#			printf("Double value: %f\n", *(values+i));
		} else if (SvPOK(sv)) {
			STRLEN len;
#			printf("String value: %s\n", SvPV(sv, len));
			*(values+j) = atof(SvPV(sv, len));
		} else {
#			printf("Don't know what it is!\n");
			*(values+j) = 0.0;
		}

#		printf("value nr. %d(%d) is %f\n", i + 1, j + 1, *(values+j));
		j+=m;
		if (j > nelem) j-=nelem;
	}

	// Obsolete. Now not needed
	// mxSetName(mat, name);

	RETVAL = 1 - engPutVariable(eng->ep, name, mat);
    }
    OUTPUT:
	RETVAL

SV *
engGetMatrix(eng, name)
	EngineIface *	eng
	const char *	name

    CODE:
    {
	mxArray *matrix;
	int nrdim, *dims, i, j, nelem;
	double *vals;
	AV *arr, *mat;

	matrix = engGetVariable(eng->ep, name);
	if (matrix == NULL)
		XSRETURN_UNDEF;

	nrdim = mxGetNumberOfDimensions(matrix);
#	printf("%d dimensions\n",nrdim);

	if (nrdim != 2)
		XSRETURN_UNDEF;

	dims = (int*) mxGetDimensions(matrix);
	nelem = 1;
	for(i=0;i<nrdim;i++) {
#		printf("\t%d\n",*(dims+i));
		nelem *= *(dims+i);
	}
	vals = mxGetPr(matrix);
	mat = newAV();
	for(i=0;i<*dims;i++) {
		arr = newAV();
		for(j=0;j<*(dims+1);j++) {
#			printf("%6.4f,",*(vals+i+j*(*dims)));
			av_push(arr, newSVnv(*(vals+i+j*(*dims))));
		}
		av_push(mat, newRV_noinc((SV *) arr));
	}
#	printf("\n");

	RETVAL = newRV_noinc((SV *) mat);
    }
    OUTPUT:
	RETVAL
