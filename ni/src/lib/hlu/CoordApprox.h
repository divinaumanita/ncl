
/*
 *      $Id: CoordApprox.h,v 1.1 1993-04-30 17:21:36 boote Exp $
 */
/************************************************************************
*									*
*			     Copyright (C)  1992			*
*	     University Corporation for Atmospheric Research		*
*			     All Rights Reserved			*
*									*
************************************************************************/
/*
 *	File:		
 *
 *	Author:		Ethan Alpert
 *			National Center for Atmospheric Research
 *			PO 3000, Boulder, Colorado
 *
 *	Date:		Thu Oct 8 15:07:57 MDT 1992
 *
 *	Description:	
 */
#include <ncarg/hlu/hluP.h>
typedef enum {NONMONOTONIC, INCREASING, DECREASING} Ordering;
typedef enum {NONE,FORWARD,INVERSE,BOTH} Status;

#define BOGUS 0

typedef struct _NhlCoordDat {
	Status	xstatus;
	int	x_use_log;
	float	*x_orig_forward;
	float	*fx_orig_forward;
	float   *x_coefs_forward;
	float	*x_orig_inverse;
	float	*fx_orig_inverse;
	float   *x_coefs_inverse;
	int	nx_forward;
	int	nx_inverse;
	float	xsigma;
	float	x_min;
	float	x_max;
	float	x_int_min;
	float	x_int_max;
	Status	ystatus;
	int	y_use_log;
	float	*y_orig_forward;
	float	*fy_orig_forward;
	float   *y_coefs_forward;
	float	*y_orig_inverse;
	float	*fy_orig_inverse;
	float   *y_coefs_inverse;
	int	ny_forward;
	int	ny_inverse;
	float	ysigma;
	float	y_min;
	float	y_max;
	float	y_int_min;
	float	y_int_max;
} NhlCoordDat;

NhlErrorTypes _NhlCreateSplineCoordApprox(
#ifdef NhlNeedProto
NhlCoordDat * /*thedat */,
int	/* x_use_log */,
float	* /*x */,
float	* /*x_int*/,
int	/* nx */,
int	/* y_use_log */,
float	* /* y */,
float	* /* y_int */,
int	/* ny */,
float	/* xsigma */,
float	/* ysigma */,
int	/* xsample */,
int	/* ysample */,
Status	*/* xstatus */,
Status	*/* ystatus */
#endif
);

NhlErrorTypes _NhlDestroySplineCoordApprox(
#ifdef NhlNeedProto
NhlCoordDat */* thedat */
#endif
);

NhlErrorTypes _NhlEvalSplineCoordForward(
#ifdef NhlNeedProto
NhlCoordDat * 	/*thedat */,
float		/* x */,
float		/* y */,
float*		/* xout */,
float*		/* yout */,
float*		/* xmissing */,
float*		/* ymissing */
#endif
);

NhlErrorTypes _NhlEvalSplineCoordInverse(
#ifdef NhlNeedProto
NhlCoordDat * 	/*thedat */,
float		/* x */,
float		/* y */,
float*		/* xout */,
float*		/* yout */,
float*		/* xmissing */,
float*		/* ymissing */
#endif
);

NhlErrorTypes _NhlMultiEvalSplineCoordForward(
#ifdef NhlNeedProto
        NhlCoordDat     * /*thedat*/, 
        float           * /*x*/, 
        float           * /*y*/, 
        float           * /*xout*/, 
        float           * /*yout*/, 
        int             /*xnpts*/ ,
        int             /*ynpts*/ ,
float*		/* xmissing */,
float*		/* ymissing */
#endif
);

NhlErrorTypes _NhlMultiEvalSplineCoordInverse(
#ifdef NhlNeedProto
        NhlCoordDat     * /*thedat*/, 
        float           * /*x*/, 
        float           * /*y*/, 
        float           * /*xout*/, 
        float           * /*yout*/, 
        int             /*xnpts*/ ,
        int             /*ynpts*/ ,
float*		/* xmissing */,
float*		/* ymissing */
#endif
);
