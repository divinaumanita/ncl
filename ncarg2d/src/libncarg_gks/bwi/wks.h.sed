/*
 *	$Id: wks.h.sed,v 1.1.1.1 1992-04-17 22:34:02 ncargd Exp $
 */
/***********************************************************************
* 
*	NCAR Graphics - UNIX Version 3.1.2
*	Copyright (C) 1987, 1988, 1989, 1991
*	University Corporation for Atmospheric Research
*	All Rights Reserved
*     
***********************************************************************/

/*
** This macro is one factor in the determination of the buffer size
** used for buffered I/O. The real value is edited into the file at
** system build time. Refer to the notes contained in wks.c.
*/

#define DEFAULT_GKS_BUFSIZE	SED_GKS_BUFFER_SIZE

#define DEFAULT_GKS_OUTPUT	"gmeta"
#define DEFAULT_TRANSLATOR	"cgmtrans"

#define MAX_UNITS		200

/* Information below should, in general, not be altered */

#define RECORDSIZE		1440

#define MF_CLOSED		(FILE *) NULL

#define NO_OUTPUT		0
#define FILE_OUTPUT		1
#define PIPE_OUTPUT		2

#define MF_READ_ERROR		302
#define MF_WRITE_ERROR		303

/* For those systems that don't define the constants for lseek(). */

#ifndef L_SET
#define L_SET 0
#endif

#ifndef L_INCR
#define L_INCR 1
#endif

/*
The Ardent handles strings in argument lists differently from
most other machines. This structure is used to deal with this
problem.
*/

#ifdef ardent
typedef struct
{
	char	*text;
	int	length;
} FortranString;
#endif
