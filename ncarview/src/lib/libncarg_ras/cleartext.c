/***********************************************************************
*                                                                      *
*                          Copyright (C)  1991                         *
*            University Corporation for Atmospheric Research           *
*                          All Rights Reserved                         *
*                                                                      *
*                                                                      *
***********************************************************************/
/*	File:	cleartext.c
 *
 *	Author: Don Middleton
 *		National Center for Atmospheric Research
 *		Scientific Visualization Group
 *		Boulder, Colorado 80307
 *
 *	Date:	1/31/91
 *
 *	Description:
 *		This file contains a collection of functions
 *		which provides access to a raster sequence
 *		using a general abstraction.
 *
 *		This particular set of routines provides
 *		a set of clear text functions that simply
 *		print calling information on stderr.
 *		
 */
#include <stdio.h>
#include <fcntl.h>
#include <string.h>
#include "ncarg_ras.h"

static char	*FormatName = "cleartext";
extern char	*ProgramName;

int
ClearTextProbe(name)
	char	*name;
{
	fprintf(stderr, "ClearTextProbe(%s)\n", name);
}

Raster *
ClearTextOpen(name)
	char	*name;
{
	Raster	*ras;
	char	*calloc();

	fprintf(stderr, "ClearTextOpen(%s)\n", name);

	ras = (Raster *) calloc(sizeof(Raster), 1);
	if (ras == (Raster *) NULL) {
		(void) RasterSetError(RAS_E_SYSTEM);
		return( (Raster *) NULL );
	}

	ras->name = (char *) calloc((unsigned) (strlen(name)+1), 1);
	(void) strcpy(ras->name, name);

	ras->format = (char *) calloc((unsigned) (strlen(FormatName) + 1), 1);
	(void) strcpy(ras->format, FormatName);

	ClearTextSetFunctions(ras);

	return(ras);
}

Raster *
ClearTextOpenWrite(name, nx, ny, comment, encoding)
	char		*name;
	int		nx;
	int		ny;
	char		*comment;
	int		encoding;
{
	Raster		*ras;

	if (name == (char *) NULL) {
		(void) RasterSetError(RAS_E_NULL_NAME);
		return( (Raster *) NULL );
	}

	ras = (Raster *) calloc(sizeof(Raster), 1);
	if (ras == (Raster *) NULL) {
		(void) RasterSetError(RAS_E_SYSTEM);
		return( (Raster *) NULL );
	}

	ras->dep = (char *) NULL;

	ras->name = (char *) calloc((unsigned) (strlen(name) + 1), 1);
	(void) strcpy(ras->name, name);

	ras->format = (char *) calloc((unsigned) (strlen(FormatName) + 1), 1);
	(void) strcpy(ras->format, FormatName);

	if (encoding == RAS_INDEXED) {
		ras->type	= RAS_INDEXED;
		ras->nx		= nx;
		ras->ny		= ny;
		ras->length	= ras->nx * ras->ny;
		ras->ncolor	= 256;
		ras->red = (unsigned char *) calloc((unsigned) ras->ncolor, 1);
		ras->green = (unsigned char *) calloc((unsigned)ras->ncolor, 1);
		ras->blue = (unsigned char *) calloc((unsigned) ras->ncolor, 1);
		ras->data = (unsigned char *) calloc((unsigned) ras->length, 1);
	}
	else if (encoding == RAS_DIRECT) {
		ras->type	= RAS_DIRECT;
		ras->nx		= nx;
		ras->ny		= ny;
		ras->length	= ras->nx * ras->ny * 3;
		ras->ncolor	= 0;
		ras->red	= (unsigned char *) NULL;
		ras->green	= (unsigned char *) NULL;
		ras->blue	= (unsigned char *) NULL;
		ras->data = (unsigned char *) calloc((unsigned) ras->length, 1);
	}
	else {
		(void) RasterSetError(RAS_E_UNSUPPORTED_ENCODING);
		return( (Raster *) NULL );
	}

	(void) ClearTextSetFunctions(ras);

	return(ras);
}

int
ClearTextWrite(ras)
	Raster	*ras;
{
	fprintf(stderr, "ClearTextPrintInfo(%s)\n", ras->name);
	return(RAS_OK);
}

int
ClearTextPrintInfo(ras)
	Raster		*ras;
{
	fprintf(stderr, "ClearTextPrintInfo(%s)\n", ras->name);
	return(RAS_OK);
}

int
ClearTextRead(ras)
	Raster	*ras;
{
	fprintf(stderr, "ClearTextRead(%s)\n", ras->name);
	return(RAS_OK);
}

int
ClearTextClose(ras)
	Raster	*ras;
{
	fprintf(stderr, "ClearTextClose(%s)\n", ras->name);
	return(RAS_OK);
}

int
ClearTextSetFunctions(ras)
	Raster	*ras;
{
	fprintf(stderr, "ClearTextSetFunctions(%s)\n", ras->name);
	ras->Open      = ClearTextOpen;
	ras->OpenWrite = ClearTextOpenWrite;
	ras->Read      = ClearTextRead;
	ras->Write     = ClearTextWrite;
	ras->Close     = ClearTextClose;
	ras->PrintInfo = ClearTextPrintInfo;
	return(RAS_OK);
}
