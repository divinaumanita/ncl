/*
 *      $Id: Error.h,v 1.1 1993-04-30 17:21:57 boote Exp $
 */
/************************************************************************
*									*
*			     Copyright (C)  1992			*
*	     University Corporation for Atmospheric Research		*
*			     All Rights Reserved			*
*									*
************************************************************************/
/*
 *	File:		Error.h
 *
 *	Author:		Jeff W. Boote
 *			National Center for Atmospheric Research
 *			PO 3000, Boulder, Colorado
 *
 *	Date:		Tue Oct 20 11:38:28 MDT 1992
 *
 *	Description:	The Error reporting object.  All errors are processed
 *			by this object.  To modify the error reporting
 *			mechanism the user needs to set resources in this
 *			object.  At this time, it will only be possible to
 *			have one error reporting object.
 */
#ifndef _NError_h
#define _NError_h

#include <ncarg/hlu/Base.h>

/* Resource Names */

#define NhlNbufferErrors	"bufferErrors"
#define NhlCbufferErrors	"BufferErrors"
#define NhlNerrorLevel		"errorLevel"
#define NhlCerrorLevel		"ErrorLevel"
#define NhlNprintErrors		"printErrors"
#define NhlCprintErrors		"PrintErrors"
#define NhlNerrorFile		"errorFile"
#define NhlCerrorFile		"ErrorFile"
/*
 * This resource is a TEMPORARY resource used to determine if the error
 * INIT will print the UNSUPPORTED message to stderr.
 */
#define NhlNunsupportedMsg	"unsupportedMsg"
#define NhlCunsupportedMsg	"UnsupportedMsg"

/* new type names */

#define NhlTErrorTypes		"ErrorTypes"

/* usefull const's for error stuff */
#define MAXERRMSGLEN	1024
#define E_UNKNOWN	1000


typedef struct _ErrorLayerRec *ErrorLayer;
typedef struct _ErrorLayerClassRec *ErrorLayerClass;

extern LayerClass errorLayerClass;

/************************************************************************
*									*
*	Global Functions - Error API					*
*									*
************************************************************************/

typedef struct _NhlErrMsg{
	NhlErrorTypes	severity;
	char		*msg;
	int		errorno;
	Const char	*sysmsg;
	int		line;
	char		*fname;
} NhlErrMsg, *NhlErrMsgList;

/*VARARGS3*/
extern Const char *NhlPError(
#if	NeedVarArgProto
	NhlErrorTypes	severity,	/* error severity	*/
	int		errnum,		/* errornum in table	*/
	char		*fmt,		/* fmt string		*/
	...				/* args for fmt string	*/
#endif
);

/*
 * Macro:	NHLPERROR
 *
 * Description:	This macro adds __LINE__ and __FILE__ information to the
 *		error message being reported.  The arguements are identical
 *		to NhlPError except that an additional set of parend's must
 *		be used to allow variable args in the macro.  ex.
 *		NHLPERROR((severity,errnum,fmt [,args ...]));
 *
 * In Args:
 *		NhlErrorTypes	severity,	error severity
 *		int		errnum,		errornum in table
 *		char		*fmt,		fmt string
 *		...				args for fmt string
 *
 * Out Args:	
 *
 * Scope:	Global Public
 * Returns:	void
 * Side Effect:	
 */
#define NHLPERROR(vargs)	{_NhlPErrorHack(__LINE__,__FILE__);\
				(void)NhlPError vargs;}

extern void _NhlPErrorHack(
#if	NhlNeedProto
	int		line,	/* line number	*/
	Const char	*fname	/* file name	*/
#endif
);

extern int NhlErrGetID(
#if	NhlNeedProto
	void
#endif
);

extern int NhlErrNumMsgs(
#if	NhlNeedProto
	void
#endif
);

extern NhlErrorTypes NhlErrGetMsg(
#if	NhlNeedProto
	int		msgnum,	/* msg num to retrieve	*/
	Const NhlErrMsg	**msg	/* return msg		*/
#endif
);

extern NhlErrorTypes NhlErrClearMsgs(
#if	NhlNeedProto
	void
#endif
);

extern NhlErrorTypes NhlErrAddTable(
#if	NhlNeedProto
	int		start,		/* starting number		*/
	int		tlen,		/* table length			*/
	Const char	**etable	/* table of err messages	*/
#endif
);

extern Const char *NhlErrFPrintMsg(
#if	NhlNeedProto
	FILE		*fp,	/* file to print to	*/
	Const NhlErrMsg	*msg	/* message to print	*/
#endif
);

extern char *NhlErrSPrintMsg(
#if	NhlNeedProto
	char		*buffer,	/* buffer to print message to	*/
	Const NhlErrMsg	*msg		/* message to print		*/
#endif
);

#endif  /* _NError_h */
