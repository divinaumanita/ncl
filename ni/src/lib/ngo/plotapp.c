/*
 *      $Id: plotapp.c,v 1.13 1999-12-07 19:08:45 dbrown Exp $
 */
/************************************************************************
*									*
*			     Copyright (C)  1996			*
*	     University Corporation for Atmospheric Research		*
*			     All Rights Reserved			*
*									*
************************************************************************/
/*
 *	File:		plotapp.c
 *
 *	Author:		David I. Brown
 *			National Center for Atmospheric Research
 *			PO 3000, Boulder, Colorado
 *
 *	Date:		Mon Mar 15 17:03:14 MST 1999
 *
 *	Description:	
 */


#include <ncarg/ngo/plotappP.h>
#include <ncarg/ngo/browseP.h>
#include <ncarg/hlu/App.h>
#include <ncarg/hlu/ConvertP.h>
#include <ncarg/ngo/nclstate.h>
#include <errno.h>
#include <sys/types.h>
#include <sys/wait.h>

typedef char ObjResType;

#define _NgRES_REGULAR		0
#define _NgRES_FAKE		1
#define _NgRES_PROFILE		2
#define _NgRES_UPDATE_FUNC	3

/*
 * Enhanced resource file key strings and characters
 */

#define DATACONFORM_RES "ndvData@ConformalGroup" 

#define PROFILESTRING "%Profile" /* signature for a Profile type resource */
#define DYNRES_TOKEN "@"      /* the dynamic resource binding token */
#define COORD_TOKEN "!"      /* indicates a coord resource  */


typedef struct _FuncFileRec {
	struct _FuncFileRec *next;
	NrmQuark	    qfuncdir;
	NrmQuark	    qfuncfile;
	int		    func_count;
	NrmQuark	    *qfuncs;
} FuncFileRec, *FuncFile;

/*
 * this record contains a list of functions along with the PlotApp that 
 * caused them to be loaded, and the file information that goes along with
 * them. If a func name occurs in more than one PlotApp, there need to 
 * be checks to ensure that the function is coming from the correct file
 * each time the PlotApp is updated. If not the correct func file needs to
 * be reloaded at update time. In essence this will give separate function
 * name spaces for each PlotApp.
 */

typedef struct _FuncInfoRec {
	struct _FuncInfoRec	*next;
	NrmQuark		qfunc;
	NrmQuark		qplotapp;
	FuncFile		ffile;
	NclApiDataList		*dl;
} FuncInfoRec, *FuncInfo;


/*
 * This record lists the functions referenced by a single resource value.
 */

#define RESFUNCMAX 8
#define DELIM_MAX 32

typedef struct _ResFuncRec {
	struct _ResFuncRec *next;
	FuncInfo 	finfo;
	short		func_pos; /* num chars from beginning of string */
	int		paren_level; /* nesting depth inside func parens */
	int		delim_count; /* == nparams + 1 (unless 0 params) */
	short		delim_pos[DELIM_MAX]; /* locs of '(', ',' ,')' */
} ResFuncRec, *ResFunc;
		

/*
 * This record type describes the data profile for a resource
 */

typedef struct _AppResProfileRec {
	NrmQuark	qname;
	NrmQuark	qrefres;
	int		init_only;
	int		vis;
	int		required;
	int		mindims;
	int		maxdims;
	NhlPointer	data;
	int		save_to_compare;
} AppResProfileRec, *AppResProfile;

/*
 * List of AppObject resources (identified by <object_name>DYNRES_TOKEN in the
 * res file).
 */

struct _AppObjectRec; /* forward reference */
struct _AppDataRec; /* forward reference */

typedef union _AppSym {
	struct _AppObjectRec *o;
	struct _AppDataRec   *d;
} AppSym;

typedef char RefKind;

#define _NgOBJ_REF	0
#define _NgDATA_REF	1

/*
 * When references to objects or data appear in the resfile they are 
 * dilimited by '$'. The character following the '$' may qualify the
 * the reference as a coordinate(!), an attribute(@) or as a subset((\..\)).
 * For subsets white space may be permitted eventually. It's not yet
 * understood.
 */
typedef char RefType;

#define _NgREF_REGULAR		0
#define _NgREF_COORD		1
#define _NgREF_ATTR		2
#define _NgREF_SUBSET		3

typedef struct _AppResSymRefRec {
	struct _AppResSymRefRec *next;
	RefKind			kind;	/* symbol is obj or data */
	AppSym			sym;
 	RefType			rtype;	 
	int			offset;  /* from start to first '$' */
	int			count;   /*  characters to final '$'*/
} AppResSymRefRec, *AppResSymRef;

typedef struct _AppObjResRec {
	struct _AppObjResRec	*next;
	NrmQuark		qres;
	NhlString		value;
	NhlBoolean		bogus;
	int    			bogus_pos;
	ObjResType		type;
	AppResProfile		prof;
	AppResSymRef		symrefs;
	ResFunc			rfuncs;
} AppObjResRec, *AppObjRes;

/*
 * Data resources are all synthetic, and attach to the data symbol, not
 * to HLU data objects
 */

typedef struct _AppDataResRec {
	struct _AppDataResRec	*next;
	NrmQuark		qres;
	NhlString		value;
	NhlBoolean		bogus;
	int			bogus_pos;
	NhlBoolean		is_coord;
	int			coord_ix;
	AppResSymRef		symrefs;
	ResFunc			rfuncs;
} AppDataResRec, *AppDataRes;

/*
 * Each AppData symbol in the res file is recorded here
 */

typedef struct _AppDataRec {		  
	struct _AppDataRec	*next;
	NrmQuark		qdataname;
	NhlString		description;
	NhlBoolean		required;
	int			ndims;
	int			conform_group;
	AppDataRes		datares;
} AppDataRec, *AppData;

/*
 * List of AppObject objects
 */

typedef struct _AppObjectRec {
	struct _AppObjectRec	*next;
	NrmQuark		qbasename;
	NhlClass		class;
	AppObjRes		objres;
} AppObjectRec, *AppObject;


/*
 * Central data structure for each PlotApp
 */

typedef struct _PlotAppRec {
	struct _PlotAppRec	*next;
	int			go_id;
	int			app_id;
	NhlString		class_name;	/* the 'lead' obj class */
	NrmQuark		qstyle_name;
	NhlString		priv_style_name;
	NhlBoolean		preview;
	int			ref_count;
	NrmQuark  		qname;
	NrmQuark		qdir;
	NrmQuark		*qapp_res;   /* NULL-terminated quark list */
	NrmQuark		*qobj_deps;  /* objects in dependency order */
	NhlClass		*obj_classes;  /* classes of the dep objects */
	int			obj_count;
	AppObject		objects;  
	int			data_count;
	AppData			data;
	int			ffile_count;
	FuncFile		*ffiles;
} PlotAppRec, *PlotApp;


static PlotApp PlotAppList = NULL; /* master list of active Plot Apps */

static FuncInfo FuncInfoList = NULL; /* list of plotapp referenced functions */

static FuncFile FuncFileList = NULL; /* list of files containing ref funcs */ 

static NclApiDataList *NclFuncs = NULL; /* return from NclGetProcFuncInfo */

typedef struct _DataTableRec {
	AppData		appdata;
	NrmQuark	qvar;
	NrmQuark	qfile;
	NrmQuark	qdims[10]; /* dims listed in fast to slow order */
	int		dim_ix[10]; /* indexes of the dims in the var */
	NhlBoolean	reorder;
	NclApiDataList	*dl;
	NhlBoolean	free_dl;
	NgVarDataRec	vd_rec;
	int		pat_ix;
} DataTableRec, *DataTable;

static DataTable Data_Table = NULL;  /* used while processing Data Profile */
static int DataTableAllocCount = 0;

/*
 * Each field in the data profile is recognized in the resource file within
 * a string array resource where each element is a name-value pair separated
 * by the colon character. The names are defined by a static array of the
 * following records. The index field matches the resource to the field in
 * the AppResProfile record. Note that not all resources are supported yet.
 */
typedef struct _ProfResRec {
	NhlString	name;
	int		len;
	int		index;
} ProfResRec;

static ProfResRec ProfRes[] = {
	{"Name", 0, 0},
	{"Reference", 0, 1},
	{"Visible", 0 , 2},
	{"SaveForCompare", 0, 3},
	{"InitializeOnly", 0, 4 },
	{"Required", 0, 5 },

};

#define BUFINC  256
static char	*Buffer;	/* growable buffer */
static int	BufSize;

static NrmQuark QString = NrmNULLQUARK;
static NrmQuark QndvData = NrmNULLQUARK;
static NrmQuark QndvObjects = NrmNULLQUARK;
static NrmQuark QndvFuncDirs = NrmNULLQUARK;
static NrmQuark QndvFuncFiles = NrmNULLQUARK;
static NrmQuark QndvFunctions = NrmNULLQUARK;
static NrmQuark QndvExecFunction = NrmNULLQUARK;
static NrmQuark QpmOverlays = NrmNULLQUARK;
static NrmQuark QmpDataLimitObject = NrmNULLQUARK;
static NrmQuark QndvUpdateFunc = NrmNULLQUARK;

static NrmQuark *QAppResList = NULL;


static NrmQuark *QFakeRes[] = { 
	&QpmOverlays,&QmpDataLimitObject,&QndvUpdateFunc
};

/*
 * There is a small subset of the legal Ncl keywords that may be 
 * legitimately encountered in a plot style file. This are listed below
 * so they can be recognized.
 */

static NhlString NclKeywords[] = {
	"True","False","noparent","defaultapp","null" };
static NrmQuark QNclKeywords[NhlNumber(NclKeywords)];

static NhlBoolean UpdateBufSize
(
	int req_size,
	NhlString *buffer,
	int *alloc_size /* in / out */
)
{
/*
 * always allocates one more than requested so caller does not need to
 * worry about room for NULL character at the end of a string
 */
	if (req_size < *alloc_size)
		return True;

	*buffer = NhlRealloc(*buffer,req_size+1);

	if (! *buffer) {
		NHLPERROR((NhlFATAL,ENOMEM,NULL));
		return False;
	}
	*alloc_size = req_size + 1;
	return True;
}

static _NhlConvertContext 
StringResToStringArray 
(
	NhlString	resval,
	int		*count,
	NhlString	**str_array,
	_NhlConvertContext context
)
{
	NhlGenArray	ga;
        NrmValue 	from, to;

/*
 * The user of this routine needs to free the context when done using the
 * string array. Do NOT free the string array itself.
 */

	from.size = sizeof(NhlString);
	from.data.ptrval = resval;
	to.size = sizeof(NhlGenArray);
	to.data.ptrval = &ga;

	if (! context)
		context = _NhlCreateConvertContext(NULL);
	if (! context)
		return NULL;

	_NhlConvertContextClass(context,NhlappClass);
	_NhlConvertData(context,
			NrmStringToQuark(NhlTString),
			NrmStringToQuark(NhlTStringGenArray),
			&from,&to);

	if (! ga || ga->num_dimensions != 1 || 
	    ga->num_elements < 1)
		return NULL;

	*count = ga->num_elements;

	*str_array = (NhlString *) ga->data;

	return context;
}

static void
FreeResFuncs
(
	ResFunc rfuncs
)
{
	while (rfuncs) {
		ResFunc rfunc = rfuncs;
		rfuncs = rfunc->next;
		NhlFree(rfunc);
	}
	return;
}

static void
SetAppResProfile
(
	AppObjRes objres,
	AppObjRes profres
	)
{
        _NhlConvertContext context = NULL;
	AppResProfile	resprof = NhlMalloc(sizeof(AppResProfileRec));
	NhlString	*prof_vals;
	int		prof_count;
	int		i,j;
	static NhlBoolean first = True;

	if (first) {
		for (i = 0; i < NhlNumber(ProfRes); i++) {
			ProfRes[i].len = strlen(ProfRes[i].name);
		}
		first = False;
	}

	if (! resprof) {
 		NHLPERROR((NhlFATAL,ENOMEM,NULL));
		return;
	}

	resprof->qname = NrmNULLQUARK;
	resprof->qrefres = NrmNULLQUARK;
	resprof->vis = -1;
	resprof->init_only = -1;
	resprof->required = -1;
	resprof->mindims = -1;
	resprof->maxdims = -1;
	resprof->data = (NhlPointer)-1;
	resprof->save_to_compare = -1;

	context = StringResToStringArray
		(profres->value,&prof_count,&prof_vals,NULL);

	for (i = 0; i < prof_count; i++) {
		for (j = 0; j < NhlNumber(ProfRes); j++) {
			char *cp;
			if (strncmp(prof_vals[i],
				    ProfRes[j].name,ProfRes[j].len))
				continue;
			cp = prof_vals[i] + ProfRes[j].len;
			while (*cp && isspace(*cp))
				cp++;
			if (*cp != ':')
				continue;
			cp++;
			while (*cp && isspace(*cp))
				cp++;
			if (*cp) {
				switch (ProfRes[j].index) {
				case 0:
					resprof->qname = NrmStringToQuark(cp);
					break;
				case 1:
					resprof->qrefres = 
						NrmStringToQuark(cp);
					break;
				case 2:
					if (! strcasecmp(cp,"False"))
						resprof->vis = False;
					else
						resprof->vis = True;
					break;
				case 3:
					if (! strcasecmp(cp,"False"))
						resprof->save_to_compare = 
							False;
					else
						resprof->save_to_compare = 
							True;
					break;
				case 4:
					if (! strcasecmp(cp,"False"))
						resprof->init_only = False;
					else
						resprof->init_only = True;
					break;
				case 5:
					if (! strcasecmp(cp,"False"))
						resprof->required = False;
					else
						resprof->required = True;
					break;
				}
			}
			break;
		}
	}
	if (resprof->init_only > 0 && resprof->vis == -1)
		resprof->vis = False;

	objres->prof = resprof;

	_NhlFreeConvertContext(context);

	return;
}

static NhlBoolean IsKeyword
(
	NhlString string
)
{
	int i;

	for (i = 0; i < NhlNumber(NclKeywords); i++) {
		if (! strcmp(string,NclKeywords[i]))
			return True;
	}
	return False;
}

static NclApiDataList *GetNclFuncData
(
	 NclApiDataList *ncl_funcs,
	 NrmQuark	qfunc
)
{
	NclApiDataList **dlp;
	NclApiDataList *func_dl;

	for (dlp = &ncl_funcs; *dlp; dlp = &(*dlp)->next) {
		NclApiFuncInfoRec *finfo = (*dlp)->u.func;
		if (finfo->name == qfunc) {
			func_dl = *dlp;
			*dlp = (*dlp)->next;
			func_dl->next = NULL;
			return func_dl;
		}
	}
		
	return NULL;
}

NhlBoolean IsFunc
(
	PlotApp		papp,
	NhlString	fsym,
	FuncInfo	*finfo
)
{
	NrmQuark qfsym = NrmStringToQuark(fsym);
	FuncInfo	tfinfo;
	NclApiDataList	*fdl;
/*
 * First see if the symbol has already been loaded.
 */
	for (tfinfo = FuncInfoList; tfinfo; tfinfo = tfinfo->next) {
		if (tfinfo->qfunc == qfsym) {
			*finfo = tfinfo;
			return True;
		}
	}
	fdl = GetNclFuncData(NclFuncs,qfsym);

	if (!fdl) 
		return False;

	tfinfo = NhlMalloc(sizeof(FuncInfoRec));
	
	if (!tfinfo) {
		NHLPERROR((NhlFATAL,ENOMEM,NULL));
		return False;
	}
	tfinfo->qfunc = qfsym;
	tfinfo->qplotapp = NrmNULLQUARK; /* not loaded from a plotapp */
	tfinfo->ffile = NULL; /* not loaded from a plotapp */
	tfinfo->dl = fdl;
	tfinfo->next = FuncInfoList;
	FuncInfoList = tfinfo;
	
	*finfo = tfinfo;

	return True;
}

NhlBoolean SingleFunctionResVal
(
	ResFunc rfunc,
	char	*buf
)
{
	if (rfunc->func_pos == 0 
	    && rfunc->delim_pos[rfunc->delim_count-1] == strlen(buf) - 1)
		return True;
	return False;
}
	

NhlBoolean CheckFunctions
(
	ResFunc rfuncs,
	char	*buf
)

{
	ResFunc rf;
	NhlBoolean param_error = False;

	for (rf = rfuncs; rf; rf = rf->next) {
		int i,j;
#if DEBUG_PLOTAPP
		char pbuf[256];

		fprintf(stderr,"func: %s -- ",
			NrmQuarkToString(rf->finfo->qfunc));
		if (SingleFunctionResVal(rf,buf))
			fprintf(stderr,"single-term func\n");
		else if (rf->paren_level > 1)
			fprintf(stderr,"func is parameter\n");
		else 
			fprintf(stderr,
			     "func is component of multi-term expression\n");

		for (j = 0; j < rf->delim_count - 1; j++) {
			int len = rf->delim_pos[j+1] 
				- rf->delim_pos[j] - 1;
			strncpy(pbuf,&buf[rf->delim_pos[j]+1],len);
			pbuf[len] = '\0';
			fprintf(stderr,"\tparam %d: %s\n",j+1,pbuf);
		}
#endif
		if (! rf->finfo->dl) {
			NHLPERROR((NhlFATAL,NhlEUNKNOWN,
			   "Ncl information for function %s not obtained",
				   NrmQuarkToString(rf->finfo->qfunc)));  
			return True;
		}
		if (rf->finfo->dl->u.func->nparams == 0) {
			if (rf->delim_count != 2)
				param_error = True;
			else {
				for (i = rf->delim_pos[0]+1; 
				     i < rf->delim_pos[1]; i++) {
					if (! isspace(buf[i])) {
						param_error = True;
						break;
					}
				}
			}
		}
		else if (rf->finfo->dl->u.func->nparams > 0 &&
		    rf->finfo->dl->u.func->nparams != 
		    rf->delim_count - 1) {
			param_error = True;
		}
		else {
			for (i = 0; i < rf->delim_count - 1; i++) {
				/* make sure it's not just blank */
				NhlBoolean blank = True;
				for (j = rf->delim_pos[i] + 1;
				     j < rf->delim_pos[i+1]; j++) {
					if (! isspace(buf[j])) {
						blank = False;
						break;
					}
				}
				if (blank) {
					param_error = True;
					break;
				}
			}
		}
					    
		if (param_error) {
			NhlPError(NhlWARNING,NhlEUNKNOWN,
			  "Error parsing function %s parameters",
				  NrmQuarkToString(rf->finfo->qfunc));
			return True;
		}
	}
	return False;
}


/*
 * states for the parser 
 */ 

#define BASIC 0
#define INQUOTES 1
#define INHANDLE 2
#define END_INHANDLE 3
#define INATTRIBUTE 4
#define INDIMENSION 5
#define INFILEVAR 6
#define INCOORDVAR 7
#define INSYMBOL 8

static NhlBoolean ParseResourceValue
(
	PlotApp papp,
	char	*res,
	char	*value,
	int	*bogus_pos,
	ResFunc *rfuncs_ret
)
{
	int state = BASIC;
	int  arraylevel = 0;
	int  parenlevel = 0;
	NhlBoolean begin = False;
	char *ch = value;
	NhlBoolean bogus = False,undefined = False;
	int bufpos = 0;
	NhlBoolean found_space = False;
	NhlBoolean symbol_end = False;
	char *start_sym = NULL;
	char symbuf[256];
	int len;
	ResFunc rf,rfuncs = NULL;
	FuncInfo finfo;
	int sym_start_pos;

	*rfuncs_ret = NULL;
/*
 * Finds some basic syntax errors
 * Also eliminates extra white space by copying the string w/o whitespace
 * to the Buffer.
 */
	if (! UpdateBufSize(strlen(value),&Buffer,&BufSize))
		return True;
	
	*bogus_pos = 0;
	while (*ch != '\0') {
		switch (state) {
		case INQUOTES:
			switch (*ch) {
			case '"':
				state = BASIC;
				break;
			default:
				break;
			}
			break;
		case BASIC:
			/* 
			 * replace any amount of whitespace with 1 space
			 */
			if (isspace(*ch)) {
				found_space = True;
				while (isspace(*ch))
				       ch++;
			}
/*
 * turns out to be unnecessary because the resource parser already removes
 * escaped newlines.
 */
#if 0
			if (*ch == '\\' && *(ch+1) == '\n') {
				ch += 2;
				found_space = True;
				continue;
			}
#endif
			if (found_space) {
				break;
			}
			switch (*ch) {
			case '"':
				state = INQUOTES;
				if (symbol_end)
					bogus = True;
				break;
			case '(':
				if (*(ch+1) == '/') {
					arraylevel++;
					break;
				}
				parenlevel++;
				for (rf = rfuncs; rf; rf = rf->next) {
					if (parenlevel == rf->paren_level)
					rf->delim_pos[rf->delim_count++] 
						 = bufpos;
				}
				break;

			case ')':
				if (*(ch-1) == '/') {
					arraylevel--;
					break;
				}
				for (rf = rfuncs; rf; rf = rf->next) {
					if (parenlevel == rf->paren_level)
					rf->delim_pos[rf->delim_count++] 
						 = bufpos;
				}
				parenlevel--;
				break;
			case '$':
				state = INHANDLE;
				begin = True;
				if (symbol_end)
					bogus = True;
				break;
			case ',':
				if (arraylevel > 0)
					break;
				for (rf = rfuncs; rf; rf = rf->next) {
					if (parenlevel == rf->paren_level)
					rf->delim_pos[rf->delim_count++] 
						 = bufpos;
				}
				break;
			case '@':
				if (! symbol_end) {
					bogus = True;
					break;
				}
				state = INATTRIBUTE;
				begin = True;
				break;
			case '&':
				if (! symbol_end) {
					bogus = True;
					break;
				}
				state = INCOORDVAR;
				begin = True;
				break;
			case '-':
				if (*(ch+1) != '>')
					break;
				if (! symbol_end) {
					bogus = True;
					break;
				}
				Buffer[bufpos++] = *ch;
				ch++;
				state = INFILEVAR;
				begin = True;
				break;
			default:
				if (isalpha(*ch) || *ch == '_') {
					start_sym = ch;
					sym_start_pos = bufpos;
					state = INSYMBOL;
				}
				break;
			}
			break;
		case INHANDLE:
			if (begin) {
				if (! (isalpha(*ch) || *ch == '_')) {
					bogus = True;
				}
				begin = False;
				break;
			}
			if (*ch == '$')
				state = END_INHANDLE;
			else if (! (isalnum(*ch) || *ch == '_')) {
				bogus = True;
			}
			break;
		case END_INHANDLE:
			if (*ch == '@') {
				begin = True;
				state = INATTRIBUTE;
			}
			else if (*ch == '!') {
				begin = True;
				state = INDIMENSION;
			}
			else {
				symbol_end = True;
				state = BASIC;
				continue; /* look at this char again */
			}
			break;
		case INATTRIBUTE:
		case INFILEVAR:
		case INCOORDVAR:
			if (begin) {
				if (! (isalpha(*ch) || *ch == '_'))
					bogus = True;
				begin = False;
			}
			else if (! (isalnum(*ch) || *ch == '_')) {
				symbol_end = True;
				state = BASIC;
				continue; /* look at this char again */
			}
			break;
		case INDIMENSION:
			if (begin) {
				if (! (isdigit(*ch) || *ch == '-'))
					bogus = True;
				begin = False;
			}
			else if (! isdigit(*ch)) {
				symbol_end = True;
				state = BASIC;
				continue; /* look at this char again */
			}
			break;
		case INSYMBOL:
			if (! (isalnum(*ch) || *ch == '_')) {
				symbol_end = True;
				state = BASIC;
			}
			if (symbol_end) {
				len = ch - start_sym;
				strncpy(symbuf,start_sym,len);
				symbuf[len] = '\0';
				
				if (IsKeyword(symbuf)) {
					continue; /* look at this char again */
				}
				if (! NclSymbolDefined(symbuf)) {
					bogus = True;
					undefined = True;
					break;
				}
#if DEBUG_PLOTAPP
				fprintf(stderr,"symbol found: %s\n",symbuf);
#endif
				if (IsFunc(papp,symbuf,&finfo)) {
					ResFunc rfunc = 
						NhlMalloc(sizeof(ResFuncRec));
					if (! rfunc) {
						NHLPERROR((NhlFATAL,
							   ENOMEM,NULL));
						bogus = True;
						break;
					}
					rfunc->paren_level = parenlevel + 1;
					rfunc->finfo = finfo;
					rfunc->delim_count = 0;
					rfunc->func_pos = sym_start_pos;
					rfunc->next = rfuncs;
					rfuncs = rfunc;
				}
				continue; /* look at this char again */
			}
			break;
		}

		symbol_end = False;
		if (parenlevel < 0 || arraylevel < 0)
			bogus = True;
		if (bogus)
			break;
		if (found_space) {
			found_space = False;
			/* no spaces at beginning */
			if (bufpos > 0) 
				Buffer[bufpos++] = ' ';
			/* don't increment ch (pointer into value) on space */
		}
		else {
			Buffer[bufpos++] = *ch;
			ch++;
		}
	}
	Buffer[bufpos] = '\0';
	if (parenlevel > 0 || arraylevel > 0)
		bogus = True;
	switch (state) {
	default:
	case INQUOTES:
	case INHANDLE:
		bogus = True;
		break;
	case END_INHANDLE:
	case INATTRIBUTE:
	case INDIMENSION:
	case BASIC:
		break;
	case INSYMBOL:
		strcpy(symbuf,start_sym);
				
		if (! IsKeyword(symbuf)) {
#if DEBUG_PLOTAPP
			fprintf(stderr,"symbol found: %s\n",symbuf);
#endif
			if (! NclSymbolDefined(symbuf)) {
				bogus = True;
				undefined = True;
				break;
			}
		}
		break;
	}

	if (CheckFunctions(rfuncs,Buffer)) {
		bogus = True;
		*bogus_pos = strlen(Buffer);
	}
	if (bogus) {
		char *error;
		*bogus_pos = ch - value;
		Buffer[*bogus_pos] = '\0';
		if (undefined) {
			error = " Undefined symbol in resource %s; suspending parsing at: \n%s\n\tplot style is : %s\n\tplot style file is: %s/%s.res";
		}
		else {
			error = " Resource %s syntax error; suspending parsing at: \n%s\n\tplot style is : %s\n\tplot style file is: %s/%s.res";
		}
		NhlPError(NhlWARNING,NhlEUNKNOWN,
			  error,res,Buffer,NrmQuarkToString(papp->qstyle_name),
			  NrmQuarkToString(papp->qdir),
			  NrmQuarkToString(papp->qname));
	}

	/*
	 * Assertion:
	 * strlen(Buffer) should always be less than or equal to strlen(value).
	 */
	strcpy(value,Buffer);
	*rfuncs_ret = rfuncs;
	return bogus;
}

static void ParseAppObjRes
(
	PlotApp		papp,
 	AppObject	appobj
)
{
	int 		i,j;
	char 		*obj_name = NrmQuarkToString(appobj->qbasename);
	int 		len, toklen;
	AppObjRes 	objres;
	int		update_func_len = strlen(NhlNndvUpdateFunc);

	len = strlen(obj_name);
	toklen = strlen(DYNRES_TOKEN);

	for (i = 0; papp->qapp_res[i] != NrmNULLQUARK; i++) {
		char *res,*cp;
		NrmQuark qobjres;
		NhlString value,objresstr;

		res = NrmQuarkToString(papp->qapp_res[i]);

		if (strncmp(res,obj_name,len))
		    continue;
		if (! strlen(res) > len + toklen )
			continue;
		if (strncmp(&res[len],DYNRES_TOKEN,toklen))
			continue;
		objresstr = &res[len+toklen];

		objres = NhlMalloc(sizeof(AppObjResRec));
		objres->next = appobj->objres;
		appobj->objres = objres;

		NhlVAGetValues(papp->app_id,
			       res,&value,
			       NULL);
		objres->value = value;
		objres->type = _NgRES_REGULAR;
		objres->prof = NULL;
		objres->symrefs = NULL;
		objres->rfuncs = NULL;
		if (! objres->value) {
			char *error = " Error retrieving resource %s value;\n\tplot style is : %s\n\tplot style file is: %s/%s.res";

			objres->bogus = True;
			objres->bogus_pos = 0;
			NhlPError(NhlWARNING,NhlEUNKNOWN,
				  error,res,
				  NrmQuarkToString(papp->qstyle_name),
				  NrmQuarkToString(papp->qdir),
				  NrmQuarkToString(papp->qname));
		}
		else if ((cp = strstr(objresstr,PROFILESTRING))) {
			int reslen = cp - objresstr;
			objres->type = _NgRES_PROFILE;
			if (! UpdateBufSize(reslen,&Buffer,&BufSize))
				return;
			strncpy(Buffer,objresstr,reslen);
			Buffer[reslen] = '\0';
			qobjres = NrmStringToQuark(Buffer); /* overwritable */
			objres->qres = qobjres;
			objres->bogus = False;
			objres->bogus_pos = -1;
		}
		else {
			objres->bogus = ParseResourceValue
				(papp,res,value,&objres->bogus_pos,
				 &objres->rfuncs);
			if (! strncmp(objresstr,
				      NhlNndvUpdateFunc,update_func_len)) {
				qobjres = NrmStringToQuark(objresstr);
				objres->qres = qobjres;
				objres->type = _NgRES_UPDATE_FUNC;
			}
			else {
				qobjres = NrmStringToQuark(objresstr);
				objres->qres = qobjres;
				for (j = 0; j < NhlNumber(QFakeRes); j++) {
					if (*QFakeRes[j] == qobjres) {
						objres->type = _NgRES_FAKE;
						break;
					}
				}
			}
		}
				
#if DEBUG_PLOTAPP
		fprintf(stderr,"\tobject: %s type: %d res: %s value: %s\n",
		       obj_name,objres->type,
		       NrmQuarkToString(objres->qres),
		       objres->value);
#endif
	}
	for (objres = appobj->objres; objres; objres = objres->next) {
		if (objres->bogus)
			continue;
		if (objres->type == _NgRES_PROFILE) {
			AppObjRes 	refres;
			for (refres = appobj->objres; refres; 
			     refres = refres->next) {
				if (refres == objres)
					continue;
				if (objres->qres == refres->qres) {
					SetAppResProfile(refres,objres);
				}
			}
		}
	}
	
			
		
}
 
static void RecordObjects
(
	PlotApp		papp,
	NhlString	objres
)
{
	NgGO		go;
	int		i;
	NhlString	objects_str;
	NhlString	*objs;
	int		obj_count;
        _NhlConvertContext context = NULL;
	AppObject 	appobj,last_appobj;

	go = (NgGO)_NhlGetLayer(papp->go_id);
	if (! go)
		return;

	NhlVAGetValues(papp->app_id,
		       objres,&objects_str,
		       NULL);

	if (! objects_str)
		return;

	context = StringResToStringArray(objects_str,&obj_count,&objs,NULL);

	papp->obj_count = obj_count;
	for (i = 0, last_appobj = NULL; i < obj_count; i++) {
		NhlClass class;
		char *str,*name, *class_str;
	       
		str = objs[i];
		while (*str && isspace(*str))
			str++;
		name = str;
		while (*str && ! (isspace(*str) || *str == ':'))
			str++;
		*str = '\0';
		str++;
		while (*str && (isspace(*str) || *str == ':'))
			str++;
		class_str = str;
#if DEBUG_PLOTAPP
		fprintf(stderr,"name %s class %s\n",name,class_str);
#endif
		class = NgNclHluClassPtrFromName(go->go.nclstate,class_str);
		if (! class)
			continue;
		appobj = NhlMalloc(sizeof(AppObjectRec));
		appobj->qbasename = NrmStringToQuark(name);
		appobj->class = class;
		appobj->objres = NULL;
		appobj->next = NULL;
		if (last_appobj)
			last_appobj->next = appobj;
		else
			papp->objects = appobj;
			
		last_appobj = appobj;
		ParseAppObjRes(papp,appobj);
	}
#if 0
	/*
	 * Now that all resources have been parsed, find references from
	 * one object to another.
	 */
	for (appobj = papp->objects; appobj; appobj = appobj->next) {
		appobj->olocs = GetAppRefLocs
			(papp,NrmQuarkToString(appobj->qbasename));
	}
#endif
	NhlFree(objects_str);
	_NhlFreeConvertContext(context);
	return;
}


static void ParseAppDataRes
(
	PlotApp		papp,
	AppData		appdata
)
{
	int 		i;
	char 		*data_sym = NrmQuarkToString(appdata->qdataname);
	int 		len, toklen, coord_toklen;
	AppDataRes 	datares;

	len = strlen(data_sym);
	toklen = strlen(DYNRES_TOKEN);
	coord_toklen = strlen(COORD_TOKEN);

	for (i = 0; papp->qapp_res[i] != NrmNULLQUARK; i++) {
		char *res,*cp;
		NrmQuark qdatares;
		NhlString value,dataresstr;
		NhlBoolean is_coord = False;
		int	coord_ix = 0;

		res = NrmQuarkToString(papp->qapp_res[i]);

		if (strncmp(res,data_sym,len))
		    continue;
		if (! strlen(res) > len + toklen )
			continue;
		cp = &res[len];
		if (! strncmp(cp,COORD_TOKEN,coord_toklen)) {
			char *tcp;
			coord_ix = strtol(cp+1,&tcp,10);
			is_coord = tcp > cp + 1 ? True : False;
			cp = tcp;
		}
		
		if (strncmp(cp,DYNRES_TOKEN,toklen))
			continue;
		dataresstr = cp + toklen;
		NhlVAGetValues(papp->app_id,
			       res,&value,
			       NULL);
/*
 * certain pseudo resources are stored globally
 */
		if (! strcmp(dataresstr,"Description")) {
			appdata->description = value;
#if DEBUG_PLOTAPP
			fprintf(stderr,"\tdata sym: %s res: %s value: %s\n",
			       data_sym,dataresstr,value);
#endif
		}
		else if (! strcmp(dataresstr,"Required")) {
			if (! strcasecmp(value,"True"))
				appdata->required = True;
#if DEBUG_PLOTAPP
			fprintf(stderr,"\tdata sym: %s res: %s value: %s\n",
			       data_sym,dataresstr,value);
#endif
		}
		else {
			datares = NhlMalloc(sizeof(AppDataResRec));
			datares->next = appdata->datares;
			appdata->datares = datares;
			datares->value = value;

			if (! strcmp(dataresstr,"Pattern")) {
				datares->bogus = False;
				datares->bogus_pos = -1;
			}
			else {
				datares->bogus = ParseResourceValue
					(papp,res,value,&datares->bogus_pos,
					 &datares->rfuncs);
			}
			datares->is_coord = is_coord;
			datares->coord_ix = coord_ix;
			datares->symrefs = NULL;
			datares->rfuncs = NULL;

			qdatares = NrmStringToQuark(dataresstr);
			datares->qres = qdatares;
#if DEBUG_PLOTAPP
			fprintf(stderr,"\tdata sym: %s res: %s value: %s",
			       data_sym,dataresstr,value);
			if (datares->is_coord)
				fprintf(stderr,
					" coord: %d\n",datares->coord_ix);
			else 
				fprintf(stderr,"\n");
#endif
		}
	}
	return;
}
	     
static void RecordData
(
	PlotApp		papp,
	NhlString	datares
)
{
	NgGO		go;
	int		i;
	NhlString	data_str;
	NhlString	*data;
	int		data_count;
        _NhlConvertContext context = NULL;
	int 		len;

	go = (NgGO)_NhlGetLayer(papp->go_id);
	if (! go)
		return;

	NhlVAGetValues(papp->app_id,
		       datares,&data_str,
		       NULL);

	if (! data_str)
		return;

	context = StringResToStringArray(data_str,&data_count,&data,NULL);

/*
 * work backwards so that data symbols end up in the same order as they
 * are entered in the plot style res file.
 */
	papp->data_count = data_count;
	for (i = data_count - 1; i >= 0; i--) {
		AppData    appdata;
		char *str,*name,*tcp;
		int  ndims;
		
		str = data[i];
		while (*str && isspace(*str))
			str++;
		name = str;
		while (*str && ! (isspace(*str) || *str == ':'))
			str++;
		*str = '\0';
		str++;
		while (*str && (isspace(*str) || *str == ':'))
			str++;
		ndims = strtol(str,&tcp,10);
#if DEBUG_PLOTAPP
		fprintf(stderr,"name: %s ndims: %d \n",name,ndims);
#endif
		appdata = NhlMalloc(sizeof(AppDataRec));
		appdata->qdataname = NrmStringToQuark(name);
		appdata->ndims = ndims;
		appdata->datares = NULL;
		appdata->next = papp->data;
		appdata->required = False;
		appdata->description = NULL;
		appdata->conform_group = -1;
		papp->data = appdata;
#if 0
		appdata->dlocs = GetAppRefLocs(papp,name);
#endif
		ParseAppDataRes(papp,appdata);
	}
/*
 * Find and mark the conformation groups
 */
	len = strlen(DATACONFORM_RES);
	for (i = 0; papp->qapp_res[i] != NrmNULLQUARK; i++) {
		int group = 0;
		char *res = NrmQuarkToString(papp->qapp_res[i]);
		char *value;
		int bogus_pos;
		ResFunc rfuncs = NULL;
		int count;
		NhlString *dnames;
		int j;
		NhlBoolean error = False;
		
		if (strncmp(res,DATACONFORM_RES,len))
			continue;

		if (strlen(res) > len)
			group = strtol(&res[len],NULL,10);

		NhlVAGetValues(papp->app_id,
			       res,&value,
			       NULL);

		/*
		 * this func returns 0 if okay
		 */
		if (ParseResourceValue(papp,res,value,&bogus_pos,&rfuncs)) {
			FreeResFuncs(rfuncs);
			NhlFree(value);
			continue;
		}
		FreeResFuncs(rfuncs);

		context = StringResToStringArray
			(value,&count,&dnames,context);
		NhlFree(value);

		for (j = 0; j < count; j++) {
			NhlString dname = dnames[j];
			NrmQuark qdname;
			int dlen = strlen(dname);
			AppData    appdata;

			if (! (dname[0] == '$' &&
			       dname[dlen-1] == '$')) {
				error = True;
				break;
			}
			dname[dlen-1] = '\0';
			qdname = NrmStringToQuark(&dname[1]);
			
			for (appdata = papp->data; 
			     appdata; appdata = appdata->next) {
				   if (qdname != appdata->qdataname)
					   continue;
				   appdata->conform_group = group;
				   break;
			}
			if (! appdata) {
				error = True;
				break;
			}
		}
		if (error) {
			NhlString error_str = " Resource %s syntax error;\n\tplot style is : %s\n\tplot style file is: %s/%s.res";
			NhlPError(NhlWARNING,NhlEUNKNOWN,
				  error_str,res,
				  NrmQuarkToString(papp->qstyle_name),
				  NrmQuarkToString(papp->qdir),
				  NrmQuarkToString(papp->qname));
		}
	}

	NhlFree(data_str);
	_NhlFreeConvertContext(context);
	return;
}

static NhlBoolean Loaded
(
	NrmQuark  qdir,
	NrmQuark  qfuncfile
)
{
	FuncFile  ffile;

	for (ffile = FuncFileList; ffile; ffile = ffile->next)
		if (qdir == ffile->qfuncdir && qfuncfile == ffile->qfuncfile)
			return True;

	return False;
}

static NhlBoolean Readable
(
	NrmQuark  qdir,
	NrmQuark  qfuncfile
)
{
        struct stat statbuf;
	NhlString funcfile = NrmQuarkToString(qfuncfile);
	NhlString dir = NrmQuarkToString(qdir);

	/*
	 * include enough space for the load command, which is to follow,
	 * avoiding an extra redundant check
	 */
	if (! UpdateBufSize
	    (strlen(funcfile) + strlen(dir) + 20,&Buffer,&BufSize))
		return False;

	if (funcfile[0] == '/') { /* full path -- ignore the directory */
		sprintf(Buffer,"%s",funcfile);
	}
	else {
		sprintf(Buffer,"%s/%s",dir,funcfile);
	}
	if (stat(Buffer,&statbuf))
		return False;

	if ((statbuf.st_mode & S_IROTH) ||
	    ((getgid() == statbuf.st_gid) && (statbuf.st_mode & S_IRGRP)) ||
	    ((getuid() == statbuf.st_uid) && (statbuf.st_mode & S_IRUSR)))
		return True;

	return False;
}

static NrmQuark *GetFunctionNames
(
	NhlString	dir,
	NhlString	funcfile,
	int		*func_count
)
{
	FILE		*fp;
	char		*cp;
	int		alloced = 0, count = 0;
	NrmQuark	*qfuncs = NULL;
	NhlBoolean	expecting_symbol = False;

	*func_count = 0;

	if (funcfile[0] == '/')
		sprintf(Buffer,"%s",funcfile);
	else {
		sprintf(Buffer,"%s/%s",dir,funcfile);
		fp = fopen(Buffer,"r");
	}
	fp = fopen(Buffer,"r");
	if (! fp) {
		NHLPERROR((NhlFATAL,NhlEUNKNOWN,
			   "error opening Ncl function file %s",Buffer));
		return NULL;
	}	
	while (cp = fgets(Buffer,255,fp)) {
		char *start;

		if (! expecting_symbol) {
			while (isspace(*cp))
				cp++;
			if (! *cp)
				continue;

			if (strncmp(cp,"function",8))
				continue;
			cp += 8;
		}
		while (isspace(*cp))
			cp++;
		if (*cp == '\\' && *(cp+1) == '\n') {
			expecting_symbol = True;
			continue;
		}
		expecting_symbol = False;
		if (! (isalpha(*cp) || *cp == '_')) {
			/* 
			 * This is a syntax error, but we won't say anything
			 * for now.
			 */
			continue;
		}
		start = cp;
		while (isalnum(*cp) || *cp == '_')
			cp++;
		*cp = '\0';
		if (count == alloced) {
			alloced += 10;
			qfuncs = NhlRealloc(qfuncs,alloced * sizeof(NrmQuark));
		}
		qfuncs[count++] = NrmStringToQuark(start);
	}
	*func_count = count;

	return qfuncs;
}
	
	 
static void Load
(
	NgGO	  	go,
	PlotApp		papp,
	NrmQuark  	qdir,
	NrmQuark  	qfuncfile
)
{
	NhlString	funcfile = NrmQuarkToString(qfuncfile);
	NhlString	dir = NrmQuarkToString(qdir);
	FuncFile	ffile;
	NrmQuark	*newfuncs;
	int		i,newfunc_count;

	for (ffile = FuncFileList; ffile; ffile = ffile->next) {
		if (qdir == ffile->qfuncdir && qfuncfile == ffile->qfuncfile) {
			papp->ffiles[papp->ffile_count++] = ffile;
			return;
		}
	}

	newfuncs = GetFunctionNames(dir,funcfile,&newfunc_count);

	if (funcfile[0] == '/') {
		sprintf(Buffer,"load \"%s\"\n",funcfile);
	}
	else {
		sprintf(Buffer,"load \"%s/%s\"\n",dir,funcfile);
	}

	(void)NgNclSubmitLine(go->go.nclstate,Buffer,True);

	ffile = NhlMalloc(sizeof(FuncFileRec));
	if (! ffile) {
		NHLPERROR((NhlFATAL,ENOMEM,NULL));
		return;
	}
	ffile->qfuncdir = qdir;
	ffile->qfuncfile = qfuncfile;
	ffile->qfuncs = newfuncs;
	ffile->func_count = newfunc_count;

	ffile->next = FuncFileList;
	FuncFileList = ffile;

	if (NclFuncs)
		NclFreeDataList(NclFuncs);
	NclFuncs = NclGetProcFuncList();

	for (i = 0; i < ffile->func_count; i++) {
		FuncInfo finfo;
		NhlBoolean found = False;
		for (finfo = FuncInfoList; finfo; finfo = finfo->next) {
			if (finfo->qfunc == ffile->qfuncs[i]) {
				finfo->qplotapp = papp->qname;
				finfo->ffile = ffile;
				finfo->dl = GetNclFuncData
					(NclFuncs,finfo->qfunc);
				found = True;
				break;
			}
		}
		if (found)
			continue;
		finfo = NhlMalloc(sizeof(FuncInfoRec));
		if (!finfo) {
			NHLPERROR((NhlFATAL,ENOMEM,NULL));
			return;
		}
		finfo->qfunc = ffile->qfuncs[i];
		finfo->qplotapp = papp->qname;
		finfo->ffile = ffile;
		finfo->dl = GetNclFuncData(NclFuncs,finfo->qfunc);	
		finfo->next = FuncInfoList;
		FuncInfoList = finfo;
	}
				

	papp->ffiles[papp->ffile_count++] = ffile;

	return;
}
static void RecordAndLoadFunctions
(
	PlotApp		papp,
	NhlString	funcdirs,
	NhlString	funcfiles,
	NhlString	execfunc
)
{
	NgGO		go;
	int		i,j;
	NhlString	func_dir_array;
	NhlString	func_file_array;
	NhlString	*func_files = NULL,*func_dirs = NULL;
	int		func_file_count = 0, func_dir_count = 0;

	_NhlConvertContext context = NULL;

	go = (NgGO)_NhlGetLayer(papp->go_id);
	if (! go)
		return;

	NhlVAGetValues(papp->app_id,
		       funcdirs,&func_dir_array,
		       funcfiles,&func_file_array,
		       NULL);

	/*
	 * If no func files the func dirs are irrelevant
	 */
	if (! func_file_array)
		return;

	context = StringResToStringArray(func_file_array,
					 &func_file_count,&func_files,NULL);
	if (func_dir_array) {
		context = StringResToStringArray
			(func_dir_array,&func_dir_count,&func_dirs,context);
	}
	/*
	 * Eventually we'll also look through directories specified by
	 * the NDV_FUNCTION_FILE_PATH. But for now just use the directory
	 * where the resource file was found. Note that the func file
	 * may be specified as a full path in which case the directory 
	 * is ignored.
	 */

	if (papp->ffile_count) {
		NhlFree(papp->ffiles);
	}
	papp->ffiles = NhlMalloc(func_file_count * sizeof(NrmQuark));
	if (! papp->ffiles) {
		NHLPERROR((NhlFATAL,ENOMEM,NULL));
		return;
	}
/* 
 * This will be incremented as files are encountered.
 */
	papp->ffile_count = 0; 
		
	if (! func_dir_count) {
		for (i = 0; i < func_file_count; i++) {
			NrmQuark qfuncfile = NrmStringToQuark(func_files[i]);
			if (Readable(papp->qdir,qfuncfile))
				Load(go,papp,papp->qdir,qfuncfile);
		}
	}
	else {
		for (i = 0; i < func_file_count; i++) {
			NrmQuark qfuncfile = NrmStringToQuark(func_files[i]);
			for (j = 0; j < func_dir_count; j++) {
				NrmQuark qdir = NrmStringToQuark(func_dirs[j]);
				if (Readable(qdir,qfuncfile)) {
					Load(go,papp,qdir,qfuncfile);
					break;
				}
			}
		}
	}

	if (context)
		_NhlFreeConvertContext(context);
	return;
}

static void RecordObjResRefs
(
	PlotApp	papp,
	AppObjRes res
)
{
	char *sp,*ep;
	int  rlen;

	if (! UpdateBufSize
	    (strlen(res->value),&Buffer,&BufSize))
		return;

	strcpy(Buffer,res->value);
	rlen = strlen(Buffer);

	ep = Buffer;
	while ((sp = strchr(ep,'$')) != NULL) {
		NrmQuark	qref;
		AppObject	appobj;
		AppData		appdata;
		NhlBoolean	found = False;
		RefType		rtype;

		ep = strchr(sp+1,'$');
		if (! ep)
			return;

		if (ep < Buffer + rlen + 1) {

			switch (*(ep+1)) {
			default:
				rtype = _NgREF_REGULAR;
				break;
			case '!':
				rtype = _NgREF_COORD;
				break;
			case '@':
				rtype = _NgREF_ATTR;
				break;
			case '(':
				rtype = _NgREF_SUBSET;
				break;
			}
		}
		*ep = '\0';

		qref = NrmStringToQuark(sp+1);

		/*
		 * Since the refs are stored from back to front, that is
		 * how they will be replaced. This ensures that the offset
		 * value from the front of the string will be correct 
		 * in the substituted string as each substitution is made.
		 */
		
		for (appdata = papp->data; appdata; appdata = appdata->next) {
			if (appdata->qdataname == qref) {
				AppResSymRef symref = 
					NhlMalloc(sizeof(AppResSymRefRec));
				if (! symref) {
					NHLPERROR((NhlFATAL,ENOMEM,NULL));
					return;
				}
				symref->next = res->symrefs;
				res->symrefs = symref;
				symref->sym.d = appdata;
				symref->kind = _NgDATA_REF;
				symref->rtype = rtype;
				symref->offset = sp - Buffer;
				symref->count = ep - sp;
				found = True;
				break;
			}
		}
		if (found) {
			ep++;
			continue;
		}
		for (appobj = papp->objects; appobj; appobj = appobj->next) {
			if (appobj->qbasename == qref) {
				AppResSymRef symref = 
					NhlMalloc(sizeof(AppResSymRefRec));
				if (! symref) {
					NHLPERROR((NhlFATAL,ENOMEM,NULL));
					return;
				}
				symref->next = res->symrefs;
				res->symrefs = symref;
				symref->sym.o = appobj;
				symref->kind = _NgOBJ_REF;
				symref->rtype = rtype;
				symref->offset = sp - Buffer;
				symref->count  = ep - sp;
				break;
			}
		}
	        ep++;
	}
	return;
}


static void RecordDataResRefs
(
	PlotApp	papp,
	AppDataRes res
)
{
	char *sp,*ep;
	int  rlen;

	if (! UpdateBufSize(strlen(res->value),&Buffer,&BufSize))
		return;

	strcpy(Buffer,res->value);
	rlen = strlen(Buffer);

	ep = Buffer;
	while ((sp = strchr(ep,'$')) != NULL) {
		NrmQuark qref;
		AppObject appobj;
		AppData   appdata;
		NhlBoolean   found = False;
		RefType    rtype;
		
		ep = strchr(sp+1,'$');
		if (! sp)
			return;

		if (ep < Buffer + rlen + 1) {
			switch (*(ep+1)) {
			default:
				rtype = _NgREF_REGULAR;
				break;
			case '!':
				rtype = _NgREF_COORD;
				break;
			case '@':
				rtype = _NgREF_ATTR;
				break;
			case '(':
				rtype = _NgREF_SUBSET;
				break;
			}
		}
		*ep = '\0';
		qref = NrmStringToQuark(sp + 1);
		
		for (appdata = papp->data; appdata; appdata = appdata->next) {
			if (appdata->qdataname == qref) {
				AppResSymRef symref = 
					NhlMalloc(sizeof(AppResSymRefRec));
				if (! symref) {
					NHLPERROR((NhlFATAL,ENOMEM,NULL));
					return;
				}
				symref->next = res->symrefs;
				res->symrefs = symref;
				symref->sym.d = appdata;
				symref->kind = _NgDATA_REF;
				symref->rtype = rtype;
				symref->offset = sp - Buffer;
				symref->count = ep - sp;
				found = True;
				break;
			}
		}
		if (found) {
			ep++;
			continue;
		}
		for (appobj = papp->objects; appobj; appobj = appobj->next) {
			if (appobj->qbasename == qref) {
				AppResSymRef symref = 
					NhlMalloc(sizeof(AppResSymRefRec));
				if (! symref) {
					NHLPERROR((NhlFATAL,ENOMEM,NULL));
					return;
				}
				symref->next = res->symrefs;
				res->symrefs = symref;
				symref->sym.o = appobj;
				symref->kind = _NgOBJ_REF;
				symref->rtype = rtype;
				symref->offset = sp - Buffer;
				symref->count = ep - sp;
				break;
			}
		}
		ep++;
	}
	return;
}
				
	       
		
static void RecordObjectAndDataReferences
(
	PlotApp	papp
)
{
	AppObject	appobj;
	AppData		appdata;

	for (appobj = papp->objects; appobj != NULL; appobj = appobj->next) {
		AppObjRes res;
		for (res = appobj->objres; res != NULL; res = res->next) {
			if (res->bogus)
				continue;
			RecordObjResRefs(papp,res);
		}
		
	}
	for (appdata = papp->data; appdata != NULL; appdata = appdata->next) {
		AppDataRes res;
		for (res = appdata->datares; res != NULL; res = res->next) {
			if (res->bogus)
				continue;
			RecordDataResRefs(papp,res);
		}
	}
	return;
}
static void ParseAppResources
(
	PlotApp	papp
)
{
	NhlGenArray	appres;
	NhlString	*res;
	int		i;
	int		obj_ix = -1, data_ix = -1;
	int		funcdir_ix = -1, funcfile_ix = -1, execfunc_ix = -1;
	NhlString 	funcdirs, funcfiles, execfunc;
	
	NhlVAGetValues(papp->app_id,
		       NhlNappResources,&appres,
		       NULL);

	if (! appres || appres->num_dimensions != 1 || 
	    appres->num_elements < 1)
		return;

	res = (NhlString *) appres->data;

	papp->qapp_res = NhlMalloc(sizeof(NrmQuark) *
				  (appres->num_elements + 1));

	for (i = 0; i < appres->num_elements; i++) {
#if DEBUG_PLOTAPP
		fprintf(stderr,"%s\n",res[i]);
#endif
		papp->qapp_res[i] = NrmStringToQuark(res[i]);
		if (papp->qapp_res[i] == QndvObjects)
			obj_ix = i;
		if (papp->qapp_res[i] == QndvData)
			data_ix = i;
		if (papp->qapp_res[i] == QndvFuncDirs)
			funcdir_ix = i;
		if (papp->qapp_res[i] == QndvFuncFiles)
			funcfile_ix = i;
		if (papp->qapp_res[i] == QndvExecFunction)
			execfunc_ix = i;
	}
	papp->qapp_res[i] = NrmNULLQUARK;


	funcdirs = (funcdir_ix >= 0) ? res[funcdir_ix] : NULL;
	funcfiles = (funcdir_ix >= 0) ? res[funcfile_ix] : NULL;
	execfunc = (execfunc_ix >= 0) ? res[execfunc_ix] : NULL;

	RecordAndLoadFunctions(papp,funcdirs,funcfiles,execfunc);

	if (obj_ix >= 0) {
		RecordObjects(papp,res[obj_ix]);
	}
	if (data_ix >= 0) {
		RecordData(papp,res[data_ix]);
	}
	RecordObjectAndDataReferences(papp);

	NhlFreeGenArray(appres);

	return;
}


static int ReorderObjDependencies
(
	NrmQuark  *qobjs,
	int	  obj_count,
	NrmQuark  qbefore,
	NrmQuark  qafter
)
{
	int i,before_ix, after_ix;

	for (i = 0; i < obj_count; i++) {
		if (qobjs[i] == qbefore)
			before_ix = i;
		if (qobjs[i] == qafter)
			after_ix = i;
	}
	if (before_ix > after_ix) {
		NrmQuark qt = qobjs[before_ix];
		for (i = before_ix; i > after_ix; i--) {
			qobjs[i] = qobjs[i-1];
		}
		qobjs[after_ix] = qt;
		return after_ix + 1;
	}
	return -1;
}
static void SetUpObjDependencyList
(
	PlotApp	papp
)
{
	AppObject appobj;
	int obj_count = papp->obj_count;
	int i;

	papp->qobj_deps = NhlMalloc(sizeof(NrmQuark) * (obj_count + 1));
	papp->obj_classes = NhlMalloc(sizeof(NhlClass) * (obj_count + 1));
	
	/* 
	 * First populate the dependency list with the objects;
	 * then move things around based on dependencies
	 */

	for (appobj = papp->objects,i = 0; appobj; appobj = appobj->next) {
		papp->qobj_deps[i++] = appobj->qbasename;
	}
	papp->qobj_deps[obj_count] = NrmNULLQUARK;

	for (i = 0; i < obj_count; i++) {
		for (appobj = papp->objects; appobj; appobj = appobj->next) {
			if (papp->qobj_deps[i] == appobj->qbasename) {
				papp->obj_classes[i] = appobj->class;
				break;
			}
		}
#if DEBUG_PLOTAPP
		fprintf(stderr,"Class %s: %s, ",
		       papp->obj_classes[i]->base_class.class_name,
		       NrmQuarkToString(papp->qobj_deps[i]));
#endif
	}
#if DEBUG_PLOTAPP
	fprintf(stderr,"\n");
#endif

	return;
}
static NhlString
PreProcessPlotStyleFile
(
	const char *priv_dir,
	NhlString dir,
	NhlString pstyle
)
{
        struct stat statbuf;
        FILE *fpin, *fpout;
	char *cp;
	static char priv_pstyle_buf[256];
	int i,pid;

	static char outfilehead[] = "*appResources : (/ \\\n\t";
	
	if (! UpdateBufSize(strlen(dir)+strlen(pstyle)+10,&Buffer,&BufSize))
		return NULL;
	sprintf(Buffer,"%s/%s.res",dir,pstyle);
/*
 * if no res file, just return
 */
	if (stat(Buffer,&statbuf))
		return NULL;

	if (! (fpin = fopen(Buffer,"r"))) {
		NHLPERROR((NhlFATAL,
			   NhlEUNKNOWN,"Error opening resource file: %s",
			   Buffer));
		return NULL;
	}
/*
 * the private plotstyle name is composed of the prefix "_Ng", followed by
 * the plotstyle name, the process id, and finally the ".res" suffix.
 */
	
	pid = getpid();
	sprintf(priv_pstyle_buf,"_Ng%s%d",pstyle,pid);
	if (! UpdateBufSize
	    (strlen(priv_pstyle_buf)+strlen(priv_dir)+10,&Buffer,&BufSize))
		return NULL;
	sprintf(Buffer,"%s/%s.res",priv_dir,priv_pstyle_buf);
	if (! (fpout = fopen(Buffer,"w"))) {
		NHLPERROR((NhlFATAL,
			   NhlEUNKNOWN,"Error opening resource file: %s",
			   Buffer));
		fclose(fpin);
		return NULL;
	}


/*
 * write out the appResources first, 
 * then everthing else
 */
	fputs(outfilehead,fpout);
	fputs(NrmQuarkToString(QAppResList[0]),fpout);
	for (i = 1; QAppResList[i] != NrmNULLQUARK; i++) {
		fputs(" , \\\n\t",fpout);
		fputs(NrmQuarkToString(QAppResList[i]),fpout);
	}
	

	while (cp = fgets(Buffer,255,fpin)) {
		char *acp,*ccp,*scp,*dcp;
		while (isspace(*cp))
			cp++;
		if (*cp == '!')
			continue;
		ccp = strchr(cp,':');
		if (! ccp)
			continue;
		acp = strchr(cp,'@');
		if (! acp)
			continue;
		if (acp > ccp)
			continue;
		*(ccp--) = '\0';
		while (isspace(*ccp))
			*(ccp--) = '\0';
		scp = strchr(cp,'*');
		if (scp && scp < acp)
			cp = scp + 1;
		dcp = strchr(cp,'.');
		if (dcp && dcp < acp)
			cp = dcp + 1;
		fputs(" , \\\n\t",fpout);
		fputs(cp,fpout);
	}
	fputs(" /)\n\n",fpout);

	rewind(fpin);
	while (cp = fgets(Buffer,255,fpin)) {
		fputs(cp,fpout);
	}
	fclose(fpin);
	fclose(fpout);

	return priv_pstyle_buf;
}	
static int CreatePlotApp
(
	int		go_id,
	NrmQuark	qplot_style,
	NrmQuark	qplot_style_dir,
	NhlBoolean	preview,
	NhlString	*priv_style_name
)
{
	NhlErrorTypes	ret = NhlNOERROR;
	char		priv_dirbuf[512];
	NhlString	plotstyledir,plotstyle,priv_plotstyle;
	const char 	*tmpdir;
	NgResData 	app_res_data;
        NhlPointer	appresdata;
	int		app_id;
/*
 * The plot style res file is preprocessed to make all resources specified
 * with the "@" symbol into application resources. All the predefined 
 * application resources are also inserted into the res file at this point.
 * That way the user does not have to worry about these resources, or need
 * to list them in two places. After preprocessing a temporary file is 
 * written into the tmp dir. This is the resfile that the application
 * actually reads. It is deleted as soon as the App object is created.
 */

	if (qplot_style == NrmNULLQUARK) 
		return NhlNULLOBJID;
	plotstyle = NrmQuarkToString(qplot_style);


#if DEBUG_PLOTAPP
	fprintf(stderr,"plot style %s\n",plotstyle);
#endif

	if (qplot_style_dir != NrmNULLQUARK) {
		plotstyledir = NrmQuarkToString(qplot_style_dir);
	}
	else {
		plotstyledir = "./plot_styles";
	}

	tmpdir =  GetNCARGPath("tmp");
	if (! tmpdir) {
		return NhlNULLOBJID;
	}
	priv_plotstyle = PreProcessPlotStyleFile
		(tmpdir,plotstyledir,plotstyle);

	if (! priv_plotstyle) 
		return NhlFATAL;


	if (preview)
		strcpy(priv_dirbuf,tmpdir);
	else 
		sprintf(priv_dirbuf,"\"%s\"",tmpdir);

	app_res_data = NgReallocResData(NULL,1);
	if (! app_res_data)
		return NhlNULLOBJID;

	app_res_data->res_count = 1;
	app_res_data->res[0] = "appUsrDir";
	app_res_data->types[0] = QString;
	app_res_data->values[0] = (NhlPointer) priv_dirbuf;

	if (preview) {
		NgPreviewResProc	resproc;

		resproc = NgPreviewResList;
		appresdata = &app_res_data;
		ret = NgCreatePreviewGraphic
			(go_id,&app_id,priv_plotstyle,priv_plotstyle,
			 NULL,"appClass",1,&resproc,&appresdata);
	}
	else {
		NgSetResProc	resproc;

		resproc = NgAddResList;
		appresdata = app_res_data;
		ret = NgCreateGraphic
			(go_id,&app_id,priv_plotstyle,priv_plotstyle,
			 NULL,"appClass",1,&resproc,&appresdata);
	}

	if (! app_id || ret < NhlWARNING)
		return (int) ret;

	sprintf(priv_dirbuf,"%s/%s.res",tmpdir,priv_plotstyle);
	errno = 0;
	if (unlink(priv_dirbuf) != 0) {
		NHLPERROR((NhlWARNING,errno,
			   "Error unlinking private plotstyle res file %s",
			   priv_dirbuf));
	}

	NgFreeResData(app_res_data);

	*priv_style_name = NhlMalloc(strlen(priv_plotstyle)+1);
	if (! *priv_style_name) {
 		NHLPERROR((NhlFATAL,ENOMEM,NULL));
		return NhlFATAL;
	}
	strcpy(*priv_style_name,priv_plotstyle);

	return app_id;
}

static void DestroyPlotApp
(
	int		go_id,
	NrmQuark	qplot_style,
	int		app_id,
	NhlBoolean	preview
)
{
	if (! qplot_style)
		return;

	if (preview)
		NgDestroyPreviewGraphic(go_id,app_id);
	else
		NgDestroyGraphic(go_id,NrmQuarkToString(qplot_style));

	return;
}

void NgDeletePlotAppRef
(
	NrmQuark	qplotstyle
)
{
	PlotApp	*papp = &PlotAppList;
	PlotApp	dpapp = NULL;

	while (*papp) {
		if ((*papp)->qname == qplotstyle) {
			dpapp = *papp;
			dpapp->ref_count--;
#if DEBUG_PLOTAPP
			fprintf(stderr,
				"delete ref count: %d\n",dpapp->ref_count);
#endif
			if (dpapp->ref_count > 0)
				return;
			*papp = (*papp)->next;
			break;
		}
		papp = &((*papp)->next);
	}
	if (! dpapp) {
		NHLPERROR((NhlFATAL,NhlEUNKNOWN,
			   "No references left to plot style: %s",
			   NrmQuarkToString(qplotstyle)));
		return;
	}

	if (dpapp->preview)
		NgDestroyPreviewGraphic(dpapp->go_id,dpapp->app_id);
	else 
		NgDestroyGraphic(dpapp->go_id,dpapp->priv_style_name);

	if (dpapp->qapp_res)
		NhlFree(dpapp->qapp_res);
 	if (dpapp->qobj_deps)
		NhlFree(dpapp->qobj_deps);
 	if (dpapp->obj_classes)
		NhlFree(dpapp->obj_classes);
 	if (dpapp->priv_style_name)
		NhlFree(dpapp->priv_style_name);

	while (dpapp->objects) {
		AppObject obj = dpapp->objects;
		dpapp->objects = obj->next;
		while (obj->objres) {
			AppObjRes objres = obj->objres;
			obj->objres = objres->next;
			while (objres->symrefs) {
				AppResSymRef symref = objres->symrefs;
				objres->symrefs = symref->next;
				NhlFree(symref);
			}
			FreeResFuncs(objres->rfuncs);
			NhlFree(objres);
		}
		NhlFree(obj);
	}

	while (dpapp->data) {
		AppData data = dpapp->data;
		dpapp->data = data->next;
		while (data->datares) {
			AppDataRes datares = data->datares;
			data->datares = datares->next;
			while (datares->symrefs) {
				AppResSymRef symref = datares->symrefs;
				datares->symrefs = symref->next;
				NhlFree(symref);
			}
			FreeResFuncs(datares->rfuncs);
			NhlFree(datares);
		}
		NhlFree(data);
	}

	NhlFree(dpapp);

	return;
}

int NgNewPlotAppRef
(
	int		go_id,
	NhlString	plot_style,
	NhlString	plot_style_dir,
	NhlString	plot_style_name,
	NhlString	plot_style_class_name,
	NhlBoolean	preview
)
{
	NrmQuark	qplotstyle,qplotstyledir,qstylename;
	PlotApp 	papp = PlotAppList;
	int 		app_id;
	NhlBoolean	found = False;
	NgGO		go = (NgGO)_NhlGetLayer(go_id);
	NhlString	priv_style_name;

	if (! go)
		return (int) NhlNULLOBJID;

/*
 * force preview to False; eventually we may get rid of this parameter.
 * the app object is private, so the user won't be setting any of its
 * resources.
 */
	preview = False;
	qplotstyle = NrmStringToQuark(plot_style);
	qplotstyledir = NrmStringToQuark(plot_style_dir);
	qstylename = NrmStringToQuark(plot_style_name);

	if (QString == NrmNULLQUARK) {
		int qapp_rescount = 0;
		int i;
		QString = NrmStringToQuark(NhlTString);
		QndvFuncDirs = NrmStringToQuark(NhlNndvFuncDirs);
		qapp_rescount++;
		QndvFuncFiles = NrmStringToQuark(NhlNndvFuncFiles);
		qapp_rescount++;
		QndvFunctions = NrmStringToQuark(NhlNndvFunctions);
		qapp_rescount++;
		QndvExecFunction = NrmStringToQuark(NhlNndvExecFunction);
		qapp_rescount++;
		QndvObjects = NrmStringToQuark(NhlNndvObjects);
		qapp_rescount++;
		QndvData = NrmStringToQuark(NhlNndvData);
		qapp_rescount++;
		QpmOverlays = NrmStringToQuark(NhlNpmOverlays);
		qapp_rescount++;
		QmpDataLimitObject = NrmStringToQuark(NhlNmpDataLimitObject);
		qapp_rescount++;
		QndvUpdateFunc = NrmStringToQuark(NhlNndvUpdateFunc);
		qapp_rescount++;
		QAppResList = NhlMalloc(sizeof(NrmQuark)*(qapp_rescount + 1));
		qapp_rescount = 0;
		QAppResList[qapp_rescount++] = QndvFuncDirs;
		QAppResList[qapp_rescount++] = QndvFuncFiles;
		QAppResList[qapp_rescount++] = QndvFunctions;
		QAppResList[qapp_rescount++] = QndvExecFunction;
		QAppResList[qapp_rescount++] = QndvObjects;
		QAppResList[qapp_rescount++] = QndvData;
		QAppResList[qapp_rescount++] = QpmOverlays;
		QAppResList[qapp_rescount++] = QmpDataLimitObject;
		QAppResList[qapp_rescount++] = QndvUpdateFunc;
		QAppResList[qapp_rescount] = NrmNULLQUARK;

		BufSize = BUFINC;
		Buffer = NhlMalloc(BufSize);
		if (! Buffer) {
			NHLPERROR((NhlFATAL,ENOMEM,NULL));
			return (int) NhlFATAL;
		}
		for (i = 0; i < NhlNumber(NclKeywords); i++) {
			QNclKeywords[i] = NrmStringToQuark(NclKeywords[i]);
		}
	}
	while (papp) {
		if (papp->qname == qplotstyle) {
			papp->ref_count++;
#if DEBUG_PLOTAPP
			fprintf(stderr,"add ref count: %d\n",papp->ref_count);
#endif

			if (papp->preview && ! preview) {
				DestroyPlotApp(go_id,qplotstyle,
					       papp->app_id,True);
				found = True;
				break;
			}
			else if (! _NhlGetLayer(papp->app_id)) {
				found = True;
				break;
			}
			return papp->app_id;
		}
		papp = papp->next;
	}
#if DEBUG_PLOTAPP
	fprintf(stderr,"creating plot app: %s\n",NrmQuarkToString(qplotstyle));
#endif

	app_id = CreatePlotApp(go_id,qplotstyle,qplotstyledir,preview,
			       &priv_style_name);
	if (app_id <= NhlNULLOBJID)
		return NhlNULLOBJID;

	if (! found) {
		papp = NhlMalloc(sizeof(PlotAppRec));
		if (! papp) {
			NHLPERROR((NhlFATAL,ENOMEM,NULL));
			return (int) NhlFATAL;
		}
		papp->ref_count = 1;
		papp->next = PlotAppList;
		PlotAppList = papp;
		papp->objects = NULL;
		papp->data = NULL;
		papp->qapp_res = NULL;
		papp->ffiles = NULL;
		papp->ffile_count = 0;
	}

	papp->go_id = go_id;
	papp->app_id = app_id;
	papp->qname = qplotstyle;
	papp->qdir = qplotstyledir;
	papp->preview = preview;
	papp->qstyle_name = qstylename;
	papp->priv_style_name = priv_style_name;
	papp->class_name = plot_style_class_name;
	papp->obj_count = 0;
	papp->data_count = 0;

	ParseAppResources(papp);

	SetUpObjDependencyList(papp);

	return app_id;
}

static NgDataItem DataItemInProfile
(
	NgDataProfile	dprof,
	AppObject	obj,
	AppObjRes	res
	
)
{
	int i;
	NgDataItem ditem;

	for (i = 0; i < dprof->n_dataitems; i++) {
		ditem = dprof->ditems[i];
		if (ditem->resq == res->qres &&
		    ditem->qhlu_name == obj->qbasename)
				
			return ditem;
	}
	return NULL;
}

static void EditDataItem
(
	NgDataItem	ditem,
	AppObject	obj,
	AppObjRes	res
	
)
{
	AppResProfile rprof = res->prof;	

	if (! rprof)
		return;

	if (rprof->qname != NrmNULLQUARK)
		ditem->name = NrmQuarkToString(rprof->qname);
	if (rprof->vis > -1)
		ditem->vis = (NhlBoolean) rprof->vis;
	else
		ditem->vis = True;
	if (rprof->required > -1) 
		ditem->required = (NhlBoolean) rprof->required;
	if (rprof->mindims > -1) 
		ditem->mindims = rprof->mindims;
	if (rprof->maxdims > -1) 
		ditem->maxdims = rprof->maxdims;
	if ((long)rprof->data > -1) 
		ditem->data = rprof->data;
	if (rprof->save_to_compare > -1) 
		ditem->save_to_compare = (NhlBoolean)rprof->save_to_compare;
	if (rprof->init_only > -1) 
		ditem->init_only = (NhlBoolean)rprof->init_only;

	if (ditem->init_only && rprof->vis < 0)
		ditem->vis = False;

	return;

}
static NhlBoolean SyntheticResource
(
	AppObjRes	res
)
{
	int i;

	for (i = 0; i < NhlNumber(QFakeRes); i++) {
		if (*(QFakeRes[i]) == res->qres)
			return True;
	}
	return False;
}

static void MergeObjResDataItems
(
	NgGO		go,
	NgDataProfile	dprof,
	AppObject	obj
	)
{
	AppObjRes	res;
	int		rescount = 0;
	int		update_func_len = strlen(NhlNndvUpdateFunc);
	
	for (res = obj->objres; res; res = res->next) {
		if (res->type == _NgRES_PROFILE)
			continue;
		else if (DataItemInProfile(dprof,obj,res)) {
			continue;
		}
			rescount++;
	}
	if (rescount) {
		int n_dataitems = dprof->n_dataitems + rescount;
		dprof->ditems = NhlRealloc
			(dprof->ditems,n_dataitems * sizeof(NgDataItem));
		if (! dprof->ditems) {
			NHLPERROR((NhlFATAL,ENOMEM,NULL));
			return;
		}
	}

	for (res = obj->objres; res; res = res->next) {
		NgDataItem ditem;
		AppResProfile rprof = res->prof;
		NgDataItemType ditype = _NgCONFIG;
		NhlBoolean set_only = False;
		NhlPointer data = (NhlPointer) -1;
		NrmQuark qres = res->qres;

		if (res->type == _NgRES_PROFILE)
			continue;
		if (res->bogus)
			continue;

		set_only = True;
		if (res->type == _NgRES_UPDATE_FUNC) {
			NhlString resname = NrmQuarkToString(qres);
			int sequence;
			ditype = _NgUPDATEFUNC;

			if (! strcmp(resname,NhlNndvUpdateFunc))
				sequence = 0;
			else {
				sequence = strtol(&resname[update_func_len],
						  NULL,0);
			}
			data = (NhlPointer) sequence;
			if (rprof) {
				rprof->data = data;
			}
		}
		else if (SyntheticResource(res)) {
			ditype = _NgSYNTHETIC;
		}

		if ((ditem = DataItemInProfile(dprof,obj,res))) {
			EditDataItem(ditem,obj,res);
		}
		else if (rprof) {
			ditem = NgNewDataItem
				(rprof->qname ? rprof->qname : qres,
				 qres,obj->qbasename,
				 obj->class,ditype,rprof->mindims,
				 rprof->maxdims,
				 ((long)rprof->data) < 0 ? NULL : rprof->data,
				 rprof->required < 0 ? False : rprof->required,
				 rprof->vis < 0 ? True : rprof->vis,
				 set_only,
				 rprof->save_to_compare < 0 ? 
				 False : rprof->save_to_compare,
				 rprof->init_only < 0 ? 
				 False : rprof->init_only);
			NgAppendDataProfileItem(dprof,ditem,rprof->qrefres);
		}
		else {
			ditem = NgNewDataItem
				(qres,qres,obj->qbasename,
				 obj->class,ditype,0,1,data,
				 False,True,set_only,False,False);
			NgAppendDataProfileItem(dprof,ditem,NrmNULLQUARK);
		}

		ditem->res_info = NhlMalloc(sizeof(NgResInfoRec));
		if (! ditem->res_info) {
			NHLPERROR((NhlFATAL,ENOMEM,NULL));
			return;
		}
		ditem->res_info->rdata = (NhlPointer) res;
		ditem->res_info->valtype = _NgEXPR;
		ditem->res_info->qsym = NrmNULLQUARK;
		ditem->res_info->argcount = 0;
		ditem->res_info->args = NULL;
	}
	return;
}
	
NgDataProfile NgNewPlotAppDataProfile
(
	int		go_id,
	NrmQuark	qplotstyle
)
{
	PlotApp	papp = PlotAppList;
	AppObject	obj;
	NgDataProfile	dprof = NULL;
	NgGO		go = (NgGO) _NhlGetLayer(go_id);
	int		i;

	if (! go)
		return NULL;

	while (papp) {
		if (papp->qname == qplotstyle) {
			break;
		}
		papp = papp->next;
	}
	if (! papp)
		return NULL;

	if (! papp->objects) {
		/*
		 * No objects listed explicitly. But there still has to
		 * be at least one
		 */
			
		if (papp->class_name) {
			return NgNewDataProfile(go,papp->class_name);
		}
		else {
			return NULL;
		}
	}
	if (! strcmp(papp->class_name,NGPLOTCLASS)) {
		dprof = NgNewDataProfile(go,papp->class_name);
	}
	for (obj = papp->objects; obj; obj = obj->next) {
		if (NgHasDataProfile(go,obj->class->base_class.class_name))
			dprof = NgMergeDataProfiles
				(go,dprof,NrmQuarkToString(obj->qbasename),
				 obj->class->base_class.class_name);
		if (! dprof)
			return NULL; 

		MergeObjResDataItems(go,dprof,obj);
	}
	dprof->qpstyle = papp->qname;
	dprof->obj_count = papp->obj_count;
	dprof->qobjects = papp->qobj_deps;
	dprof->obj_classes = papp->obj_classes;

	for (i = 0; i < dprof->n_dataitems; i++) {
		NgDataItem ditem = dprof->ditems[i];
		if (! ditem->res_info)
			ditem->vis = False;
	}

	return dprof;
}
static NhlBoolean PerlMatch
(
	NhlString pattern,
	NhlString match_text
)
{
	char cmd[] = "echo %s | perl  -e 'while (<>){exit 1 if %s; exit 0}'";
	int ret;

	if (! UpdateBufSize
	    (strlen(cmd) + strlen(match_text) +strlen(pattern),
	     &Buffer,&BufSize))
		return False;

	sprintf(Buffer,cmd,match_text,pattern);
	errno = 0;
	ret = system(Buffer);
#if DEBUG_PLOTAPP
	perror(match_text);
	fprintf(stderr,"status %d %d\n",WIFEXITED(ret), WEXITSTATUS(ret));
#endif
	if (WEXITSTATUS(ret) == 1) {
		return True;
	}
	return False;
}

static NhlBoolean MatchPattern
(
	AppData	  appdata,
	int	  dcount,
	NrmQuark  qfile,
	NrmQuark  qvar
)
{
	AppDataRes	datares;
	NhlString	*patterns = NULL;
	int		pat_count = 0;
	_NhlConvertContext context = NULL;
	int i;
	NhlBoolean matched = False;
	DataTable dt = &Data_Table[dcount];
	
	for (datares = appdata->datares; datares; datares = datares->next) {
		if (! datares->is_coord && 
		    strstr(NrmQuarkToString(datares->qres),"Pattern")) {
			context = StringResToStringArray
				(datares->value,
				 &pat_count,&patterns,context);
			break;
		}
	}
	if (! pat_count) {	/* no pattern specified -- match is True */
		matched = True;
	}
	else if (dt->pat_ix > -1 && dt->pat_ix < pat_count) {
		/*
		 * calling perl: this will be replaced with a lib call 
		 */
		if (PerlMatch(patterns[dt->pat_ix],NrmQuarkToString(qvar))) {
				matched = True;
		}
	}
	if (dt->pat_ix > -1)
		dt->pat_ix = dt->pat_ix < pat_count - 1 ? dt->pat_ix + 1 : -1;
	if (context)
		_NhlFreeConvertContext(context);
	return matched ? True : False;
}

static NhlBoolean AlreadyAssigned
(
	PlotApp		papp,
	int		data_ix,
	NrmQuark	qfile,
	NrmQuark	qvar
)
{
	int i;

	for (i = 0; i < papp->data_count; i++) {
		if (i == data_ix)
			continue;
		if (Data_Table[i].qvar == qvar && 
		    Data_Table[i].qfile == qfile)
			return True;
	}

	return False;
}

#define MIN_ELEMENTS 3
static NhlBoolean HasMinElementCount
(
	NgVarData vdata,
	int	  dim_ix
)
{
	if (vdata->set_state <= _NgDEFAULT_SHAPE) {
		if (vdata->size[dim_ix] >= MIN_ELEMENTS)
			return True;
	}
	if (abs((vdata->finish[dim_ix] - vdata->start[dim_ix]) /
		vdata->stride[dim_ix]) + 1 >= MIN_ELEMENTS) {
		return True;
	}
	return False;
}

static NhlBoolean MatchDimensions
(
	AppData	  appdata,
	int	  dcount,
	NgVarData vdata
)
{
	AppDataRes	datares;
	DataTable	dt = &Data_Table[dcount];
	NhlString	patterns[10] = { NULL,NULL,NULL,NULL,NULL,
					 NULL,NULL,NULL,NULL,NULL };
	NhlBoolean	matched[10] = { False, False, False, False, False,
				        False, False, False, False, False };
	int		i,j,ix;
	NclApiVarInfoRec *vinfo;

	vinfo = dt->dl->u.var;

	for (datares = appdata->datares; datares; datares = datares->next) {
		if (datares->is_coord && 
		    strstr(NrmQuarkToString(datares->qres),"Pattern")) {
			if (datares->coord_ix < 0)
				ix = abs(datares->coord_ix) - 1;
			else 
				ix = datares->coord_ix;
			if (ix > 9)
				continue;
			patterns[ix] = datares->value;
		}
	}
	for (i = 0; i < appdata->ndims; i++) {
		if (patterns[i]) {
			for (j = vinfo->n_dims - 1; j >=0; j--) {
				if (! matched[j] && 
				    vinfo->dim_info[j].dim_quark > 
				    NrmNULLQUARK) {
					if (!HasMinElementCount(vdata,j))
						continue;
					if (PerlMatch
					    (patterns[i],NrmQuarkToString
					     (vinfo->dim_info[j].dim_quark))) {
						dt->qdims[i] = 
						  vinfo->dim_info[j].dim_quark;
						matched[j] = True;
						dt->dim_ix[i] = j;
						break;
					}
				}
			}
		}
	}
	for (i = 0; i < appdata->ndims; i++) {
		if (! dt->qdims[i] > NrmNULLQUARK) {
			if (patterns[i])
				return False;
			for (j = vinfo->n_dims - 1; j >=0; j--) {
				if (! matched[j]) {
					if (!HasMinElementCount(vdata,j))
						continue;
					dt->dim_ix[i] = j;
					dt->qdims[i] = 
						vinfo->dim_info[j].dim_quark;
					matched[j] = True;
					break;
				}
			}
		}
	}
	
	return True;
}


static NhlBoolean MatchUnits
(
	AppData	  appdata,
	int	  dcount
)
{
	return True;
}

static NhlBoolean MatchAttributes
(
	AppData	  appdata,
	int	  dcount
)
{
	return True;
}

static NhlBoolean GetInfo
(
	DataTable dt,
	NgVarData vdata
)
{

	if (dt->dl) {
		if (dt->free_dl) {
			NclFreeDataList(dt->dl);
		}
		dt->dl = NULL;
	}
	if (vdata->dl) {
		dt->dl = vdata->dl;
		dt->free_dl = False;
	}
	else if (dt->qfile && dt->qvar) {
		dt->dl = NclGetFileVarInfo(dt->qfile,dt->qvar);
		dt->free_dl = True;
	}
	else if (dt->qvar) {
		dt->dl = NclGetVarInfo(dt->qvar);
		dt->free_dl = True;
	}
	else {
		NHLPERROR((NhlFATAL,NhlEUNKNOWN,"internal error"));
		return False;
	}
	return True;
}
static void ScratchVar
(
	DataTable	dt
)
{
	dt->qfile = NrmNULLQUARK;
	dt->qvar = NrmNULLQUARK;
	if (dt->free_dl) {
		 NclFreeDataList(dt->dl);
		 dt->dl = NULL;
		 dt->free_dl = False;
	}
	return;
}

static NgVarData MatchVarData
(
	PlotApp		papp,
	AppData		appdata,
	int		dcount,
	int		count,
	NgVarData	*vdata
)
{
	int		i;
	DataTable	dt = &Data_Table[dcount];
	int		start = 0, end = count;
	NhlBoolean	explicit_set = False;
	NhlBoolean	never_matched = True;

	if (! (count && vdata))
		return False;

	dt->appdata = appdata;

	if (count == papp->data_count && 
	    vdata[dcount]->set_state != _NgVAR_UNSET) {
		start = dcount;
		end = start + 1;
		explicit_set = True;
	}

	for (i = start; i < end; i++) {
		if (vdata[i]->ndims < appdata->ndims)
			continue;

		if (! explicit_set) {
			if (AlreadyAssigned
			    (papp,dcount,vdata[i]->qfile,vdata[i]->qvar))
				continue;

			if (! MatchPattern
			    (appdata,dcount,vdata[i]->qfile,vdata[i]->qvar)) {
				never_matched = False;
				continue;
			}
		}
		dt->qfile = vdata[i]->qfile;
		dt->qvar = vdata[i]->qvar;
		if (! GetInfo(dt,vdata[i])) {
			ScratchVar(dt);
			continue;
		}
		if (! MatchDimensions(appdata,dcount,vdata[i])) {
			ScratchVar(dt);
			continue;
		}
		if (! MatchUnits(appdata,dcount)) {
			ScratchVar(dt);
			continue;
		}
		if (! MatchAttributes(appdata,dcount)) {
			ScratchVar(dt);
			continue;
		}
		return vdata[i];
	}
	if (never_matched) {
		dt->pat_ix = -1;
	}
	return NULL;
}

static NgVarData MatchVar
(
	PlotApp		papp,
	AppData		appdata,
	int		dcount,
	NrmQuark	*qvars
)
{
	return NULL;
}

static NgVarData MatchVarFromFile
(
	PlotApp		papp,
	AppData		appdata,
	int		dcount,
	NrmQuark	*qfiles
)
{
	return NULL;
}

static NhlBoolean MatchCoordAttr
(
	NrmQuark	qfile,
	NrmQuark	qvar,
	int		qdim,
	char		*buf,
	char		**endp
)
{
        NclApiDataList  *dl;
	NclApiVarInfoRec *vinfo;
	char tbuf[256];
	char *cp;
	int i;

/*
 * The end pointer is already set. It should only be modified if the 
 * attribute match fails and therefore the attribute name needs to
 * be wiped out of the resource value.
 */
 	
	if (qfile > NrmNULLQUARK)
		dl = NclGetFileVarCoordInfo(qfile,qvar,qdim);
	else
		dl = NclGetVarCoordInfo(qvar,qdim);

	strncpy(tbuf,buf,255);
	cp = tbuf;
	if (! (isalpha(*cp) || *cp == '_')) {
		/*
		 * in this situation the attribute name is not valid. 
		 * all that's getting 'wiped' is the '@' symbol. An
		 * ncl syntax error is likely. Should more of the string
		 * be eliminated?
		 */
		*endp = buf; 
		return False;
	}
	else {
		cp++;
		while (isalnum(*cp) || *cp == '_')
			cp++;
		*cp = '\0';
		if (!dl) {
			*endp = buf + (cp - tbuf);
			return False;
		}
		vinfo = dl->u.var;
		for (i = 0; i < vinfo->n_atts; i++) {
			if (! strcmp(tbuf,
				     NrmQuarkToString(vinfo->attnames[i])))
				break;
		}
	}
	if (i == vinfo->n_atts) {
		*endp = buf + (cp - tbuf);
		return False;
	}
	return True;
}

static NhlBoolean WriteCoords
(
	char 		*buf,
	NclApiVarInfoRec *vinfo,
	DataTable	dt,
	NgVarData	vd
)
{
	int i,coord_ix = dt->appdata->ndims - 1;
	char *cp;
		
	if (!(vd && vd->start && vd->finish && vd->stride) ||
	    vd->ndims < vinfo->n_dims)
		return False;
	sprintf(buf,"(");
	for (i = 0; i < vinfo->n_dims; i++) {
		cp = &buf[strlen(buf)];
		if (i == dt->dim_ix[coord_ix]) {
			if (vd->start[i] == 0 &&
			     vd->finish[i] == vinfo->dim_info[i].dim_size - 1 
			     && vd->stride[i] == 1) {
					sprintf(cp,":,");
			}
			else {
				sprintf(cp,"%ld:%ld:%ld,",
					vd->start[i],vd->finish[i],
					vd->stride[i]);
			}
			coord_ix--;
		}
		else { /* one element only is accepted */
			sprintf(cp,"%ld,",vd->start[i]);
		}
	}
	buf[strlen(buf)-1] = ')';
	return True;
}

static NhlBoolean WriteReorderedCoords
(
	char 		*buf,
	NclApiVarInfoRec *vinfo,
	DataTable	dt,
	NgVarData	vd
)
{
	int i,j;
	char *cp;
	int dim_ix;
	NrmQuark qdim;

	if (!(vd && vd->start && vd->finish && vd->stride) ||
	    vd->ndims < vinfo->n_dims)
		return False;
/*
 * this takes two passes through the dimensions:
 * unreferenced dimensions will be the slow ones and have only one element.
 */
		
	sprintf(buf,"(");
	for (i = 0, dim_ix = 0; i < vinfo->n_dims; i++) {
		cp = &buf[strlen(buf)];
		for (j = 0; j < dt->appdata->ndims; j++) {
			if (i == dt->dim_ix[j])
				break;
		}
		if (j < dt->appdata->ndims) {
			/* dim found in the Data Table -worry about it later */
			continue;
		}
		qdim = vinfo->dim_info[i].dim_quark;
		if (qdim <= NrmNULLQUARK) {
			NHLPERROR((NhlFATAL,NhlEUNKNOWN,
		   "Variable %s unnamed dimension: reordering not possible",
				   NrmQuarkToString(dt->qvar)));
			return False;
		}
		 /* one element only is accepted */

		sprintf(cp,"%s | %ld,",NrmQuarkToString(qdim),vd->start[i]);
		dim_ix++;
	}
/*
 * If the vdata subsection has never been set explicitly, then it will be
 * wrong when dimensions are going to be reordered based on name. In this
 * case, we cheat a little, by checking the range of the
 * fast moving dimensions instead of range of the dimension that
 * we are interested in. Sound confusing? It is. If not explicitly set (in
 * the varpage at least), it will have the set_state _NgDEFAULT_SHAPE. 
 */
	for (i = dt->appdata->ndims - 1; i >=0; i--) {
		int ix = dt->dim_ix[i];

		cp = &buf[strlen(buf)];
		qdim = vinfo->dim_info[ix].dim_quark;
		if (qdim <= NrmNULLQUARK) { 
			/* shouldn't be possible here, but check anyway */
			NHLPERROR((NhlFATAL,NhlEUNKNOWN,
		   "Variable %s unnamed dimension: reordering not possible",
				   NrmQuarkToString(dt->qvar)));
			return False;
		}
 		if (vd->start[ix] == 0 &&
		     vd->finish[ix] == vinfo->dim_info[ix].dim_size - 1 &&
		     vd->stride[ix] == 1) {
			sprintf(cp,"%s | :,",NrmQuarkToString(qdim));
		}
		else {
			sprintf(cp,"%s | %ld:%ld:%ld,",NrmQuarkToString(qdim),
				vd->start[ix],vd->finish[ix],vd->stride[ix]);
		}
		dim_ix++;
	}
	buf[strlen(buf)-1] = ')';
	return True;
}

static NhlBoolean ReplaceDataSymRef
(
	PlotApp		papp,
	AppObjRes	res,
	int		index,
	AppResSymRef	sref,
	int		offset,
	NhlString	*buffer,
	int		*bufsize
)
{
	char		tbuf[512];
	DataTable	dt = &Data_Table[index];
	int		coord_ix,n_to_move;
	char		*cp,*sp,*ep;
	NclApiVarInfoRec *vinfo;
	int 		i;
	NrmQuark	qdim;
	NgVarData	vd;
	NhlBoolean	status = False;
	NhlBoolean	is_coord_attr = False;
	int		spos;

	if (! dt->qvar) /* this data is not specified yet */
		return False;

	if (! dt->dl) {
		NHLPERROR((NhlFATAL,NhlEUNKNOWN,
			   "Internal error: no var info"));
		return False;
	}
	if (offset < 0)
		offset = sref->offset;
		
	vinfo = dt->dl->u.var;
	vd = &dt->vd_rec;
	switch (sref->rtype) {
	case _NgREF_ATTR:
		/* first see if the attribute named is actually an
		 * attribute of this var
		 * the attribute starts beyond the char count by 2
		 */
		cp = *buffer + offset + sref->count + 2;
		strncpy(tbuf,cp,512);
		cp = tbuf;
		if (! (isalpha(*cp) || *cp == '_')) {
			i = vinfo->n_atts;
			*cp = '\0';
		}
		else {
			cp++;
			while (isalnum(*cp) || *cp == '_')
				cp++;
			*cp = '\0';
			for (i = 0; i < vinfo->n_atts; i++) {
				if (! strcmp(tbuf,
				     NrmQuarkToString(vinfo->attnames[i])))
					break;
			}
		}
		if (i == vinfo->n_atts) {
			/* replace with empty string */
			spos = offset+sref->count+strlen(tbuf)+2;
			sprintf(tbuf,"\"\"");
		}
		else if (dt->qfile) {
			sprintf(tbuf,"%s->%s",
				NrmQuarkToString(dt->qfile),
				NrmQuarkToString(dt->qvar));
			spos = offset + sref->count + 1;
		}
		else {
			sprintf(tbuf,"%s",
				NrmQuarkToString(dt->qvar));
			spos = offset + sref->count + 1;
		}
		status = True;
		break;
	case _NgREF_COORD:
		/*
		 * the coordinate index is beyond the char count by 2
		 */
		cp = *buffer + offset + sref->count + 2;

		coord_ix = strtol(cp,&sp,10);
		if (! (sp > cp)) {
			NHLPERROR((NhlFATAL,NhlEUNKNOWN,
			"Syntax error in res file coord index specification"));
			return False;
		}
		spos = sp - *buffer;
		/*
		 * the DataTable is stored in fast to slow order
		 */
		if (coord_ix >= 0) {
			coord_ix = vinfo->n_dims - coord_ix - 1;
		}
		else {
			coord_ix = -coord_ix - 1;
		}
		if (coord_ix < 0 || coord_ix > 4) {
			NHLPERROR((NhlFATAL,NhlEUNKNOWN,
			   "Invalid coord index in res file specification"));
			return False;
		}
		qdim = dt->qdims[coord_ix];
		
		/* check for coordinate attribute */
		if (*sp == '@') { 
			status = True;
			if (!(qdim > NrmNULLQUARK && 
			      MatchCoordAttr(dt->qfile,dt->qvar,
					     qdim,sp+1,&sp))) {
				sprintf(tbuf,"\"\"");
				spos = sp - *buffer;
				break;
			}
			is_coord_attr = True;
		}
		if (qdim > NrmNULLQUARK) {
			/* 
			 * This might be just a named dimension or it
			 * might actually be a coord var, so find out.
			 */
			for (i = 0; i < vinfo->n_dims; i++) {
				if (qdim == vinfo->coordnames[i])
					break;
			}
			if (i == vinfo->n_dims)
				qdim = NrmNULLQUARK;
		}
		if (qdim > NrmNULLQUARK) {
			if (dt->qfile) {
				sprintf(tbuf,"%s->%s",
					NrmQuarkToString(dt->qfile),
					NrmQuarkToString(qdim));
			}
			else {
				sprintf(tbuf,"%s&%s",
					NrmQuarkToString(dt->qvar),
					NrmQuarkToString(qdim));
			}
			if (is_coord_attr) 
				;
			else if (vd->start[i] == 0 && 
				 vd->finish[i] == 
				 vinfo->dim_info[i].dim_size - 1 &&
				 vd->stride[i] == 1) {
				sprintf(&tbuf[strlen(tbuf)],"(:)");
			}
			else {
				sprintf(&tbuf[strlen(tbuf)],"(%ld:%ld:%ld)",
					vd->start[i],vd->finish[i],
					vd->stride[i]);
			}
			status = True;
		}
		else {
			tbuf[0] = '\0';
		}
		break;
	case _NgREF_REGULAR:
		if (dt->qfile) {
			sprintf(tbuf,"%s->%s",
				NrmQuarkToString(dt->qfile),
				NrmQuarkToString(dt->qvar));
		}
		else {
			sprintf(tbuf,"%s",
				NrmQuarkToString(dt->qvar));
		}
		if (! dt->reorder) {
 			if (! WriteCoords(&tbuf[strlen(tbuf)],vinfo,dt,vd))
				break;
		}
		else {
			if (! WriteReorderedCoords
			    (&tbuf[strlen(tbuf)],vinfo,dt,vd))
				break;
		}
		spos = offset + sref->count + 1;
		status = True;
		break;
		
	default:
		break;
	}

	if (! UpdateBufSize(strlen(*buffer) + strlen(tbuf)+4,buffer,bufsize))
		return False;

	sp = *buffer + spos;
	ep = *buffer + offset + strlen(tbuf);
	n_to_move = strlen(sp);
	memmove(ep,sp,n_to_move);
	*(ep+n_to_move) = '\0';

	strncpy(*buffer + offset,tbuf,strlen(tbuf));

	return status;
}

static NhlBoolean ReplaceObjSymRef
(
	PlotApp		papp,
	AppObjRes	res,
	AppObject 	appobj,
	AppResSymRef	sref,
	NhlString	plotname,
	int		offset,
	NhlString	*buffer,
	int		*bufsize
)
{
	char		tbuf[512];
	int		i,ix = -1;
	char		*sp,*ep;
	int		n_to_move;

	if (offset < 0)
		offset = sref->offset;
	/* 
	 * Find the array index for this graphic object, in the 
	 * dependency ordered list (which will be the order the 
	 * objects actually get created in)
	 */
	for (i = 0; i < papp->obj_count; i++) {
		if (papp->qobj_deps[i] == appobj->qbasename)
			ix = i;
	}
	if (ix == -1) {
		NHLPERROR((NhlFATAL,NhlEUNKNOWN,"Internal error"));
		return False;
	}
	sprintf(tbuf,"%s_%s",plotname,NrmQuarkToString(papp->qobj_deps[ix]));

	if (! UpdateBufSize(strlen(*buffer) + strlen(tbuf)+4,buffer,bufsize))
		return False;
	sp = *buffer + offset + sref->count + 1;
	ep = *buffer + offset + strlen(tbuf);
	n_to_move = strlen(sp);
	memmove(ep,sp,n_to_move);
	*(ep+n_to_move) = '\0';

	
	strncpy(*buffer + offset,tbuf,strlen(tbuf));

	return True;
}

static NhlBoolean ReplaceSymRef
(
	PlotApp		papp,
	AppObjRes	res,
	AppResSymRef	sref,
	NhlString	plotname,
	int		offset,
	NhlString	*buffer,
	int		*bufsize
)
{
	int  i;
	

	if (sref->kind == _NgDATA_REF) {
		for (i = 0; i < papp->data_count; i++) {
			if (sref->sym.d == Data_Table[i].appdata) {
				return ReplaceDataSymRef
					(papp,res,i,sref,
					 offset,buffer,bufsize);
			}
		}
	}
	else {
		AppObject appobj;
		for (appobj = papp->objects; appobj; appobj = appobj->next) {
			if (sref->sym.o == appobj) {
				return ReplaceObjSymRef
					(papp,res,appobj,sref,plotname,
					 offset,buffer,bufsize);
			}
		}
	}
	
	return False;
}

static void SetFuncInfo
(
	PlotApp		papp,
	ResFunc		rfuncs,
	NgResInfo	rinfo,
	NhlString	plotname,
	NhlString	valbuf
)
{
	AppObjRes res = (AppObjRes) rinfo->rdata;
	ResFunc rf;
	int i;
	NclApiFuncInfoRec *finfo = NULL;
/*
 * Find out if a function in the resource value qualifies as a 
 * SingleFunctionResVal
 */
	for (rf = rfuncs; rf; rf = rf->next) {
		if (SingleFunctionResVal(rf,valbuf))
			break;
	}
	if (! rf)
		return;

	if (rf->finfo && rf->finfo->dl)
		finfo = rf->finfo->dl->u.func;

	if (rinfo->argcount != finfo->nparams) {
		if (rinfo->argcount)
			NgFreeArgInfo(rinfo->args,rinfo->argcount);
		if (! finfo->nparams) {
			rinfo->args = NULL;
		}
		else {
			rinfo->args = NhlMalloc
				(finfo->nparams * sizeof(NgArgInfoRec));
			if (! rinfo->args) {
				NHLPERROR((NhlFATAL,ENOMEM,NULL));
				return;
			}
			for (i = 0; i < finfo->nparams; i++) {
				rinfo->args[i].sval = NULL;
			}
		}
		rinfo->argcount = finfo->nparams;
	}
	
	rinfo->qsym = rf->finfo->qfunc;
	rinfo->valtype = _NgFUNC;

#if DEBUG_PLOTAPP
	fprintf(stderr,"single term func %s\n",NrmQuarkToString(rinfo->qsym));
#endif
	for (i = 0; i < finfo->nparams; i++) {
		int bix = rf->delim_pos[i] + 1;
		int eix = rf->delim_pos[i+1] - 1;
		AppResSymRef sref;
		char *buf = NULL;
		int  bufsize = 0;
		int len,offset;
		NclApiArgTemplate *arg = &finfo->theargs[i];
		char *name = "unknown";
		char *type = "any";
		
		while (isspace(valbuf[bix]))
			bix++;
		while (isspace(valbuf[eix]))
			eix--;
		len = eix - bix + 1;
		if (! UpdateBufSize(len,&buf,&bufsize))
			return;
		strncpy(buf,&valbuf[bix],len);
		buf[len] = '\0';
		if (valbuf == res->value) {
			for (sref = res->symrefs; sref; sref = sref->next) {
				if (sref->offset < bix || 
				    sref->offset + sref->count > eix)
					continue;
				offset = sref->offset - bix;
				ReplaceSymRef(papp,res,sref,plotname,offset,
					      &buf,&bufsize);
			}
		}
		if (rinfo->args[i].sval)
			NhlFree(rinfo->args[i].sval);
		rinfo->args[i].sval = buf;
		rinfo->args[i].qargdatatype = arg->arg_data_type;
		rinfo->args[i].qargname = arg->arg_sym;
/*
 * not using these yet
 */
		rinfo->args[i].valtype = _NgEXPR;
		rinfo->args[i].argcount = 0;
		rinfo->args[i].args = NULL;

#if DEBUG_PLOTAPP
		if (arg->arg_sym > NrmNULLQUARK)
			name = NrmQuarkToString(arg->arg_sym);
		if (arg->arg_data_type > NrmNULLQUARK)
			type = NrmQuarkToString(arg->arg_data_type);

		fprintf(stderr,"\tparam %d name: %s type %s dims %d val: %s\n",
			i+1,name,type,arg->n_dims,buf);
#endif
		
	}
				
	return;
}

static void SubstituteVarSyms
(
	PlotApp		papp,
	AppData		appdata,
	NhlString	plotname,
	NgDataProfile	dprof
)
{
	int i;
	NhlBoolean status;

	for (i = 0; i < dprof->n_dataitems; i++) {
		NgDataItem ditem = dprof->ditems[i];
		NgResInfo rinfo = ditem->res_info;
		AppObjRes res;
		AppResSymRef sref;
		ResFunc rfuncs = NULL;
		ResFunc	rfunc;

/*
 * Eventually we will try to figure out whether user expressions contain
 * references to the plot app objects or data, but for now just leave them
 * alone.
 */		

		if (! (rinfo && rinfo->rdata))
			continue;
		res = (AppObjRes) rinfo->rdata;

		if (res->bogus ||
		    ditem->vdata->set_state == _NgBOGUS_EXPRESSION ||
		    ditem->vdata->set_state == _NgUSER_DISABLED)
			continue;

		if (ditem->vdata->set_state == _NgUSER_EXPRESSION) {
			int bogus, bogus_pos;
			bogus = ParseResourceValue
				(papp,NrmQuarkToString(res->qres),
				 ditem->vdata->expr_val,
				 &bogus_pos,&rfuncs);
			if (bogus) {
				FreeResFuncs(rfuncs);
				continue;
			}
			if (! UpdateBufSize(strlen(ditem->vdata->expr_val),
					    &Buffer,&BufSize))
				return;
			strcpy(Buffer,ditem->vdata->expr_val);
			SetFuncInfo(papp,rfuncs,rinfo,plotname,Buffer);
			FreeResFuncs(rfuncs);
		}
		else {
			SetFuncInfo
				(papp,res->rfuncs,rinfo,plotname,res->value);
			if (! UpdateBufSize(strlen(res->value),
					    &Buffer,&BufSize))
				return;
			strcpy(Buffer,res->value);
			for (sref = res->symrefs; sref; sref = sref->next) {
				status = ReplaceSymRef(papp,res,sref,plotname,
						       -1,&Buffer,&BufSize);
				if (! status)
					break;
			}
			if (status) {
				NgSetExpressionVarData
					(papp->go_id,
					 ditem->vdata,Buffer,_NgNOEVAL,False);
			}
		}
	}
		
	return;
}

static void EvaluateDataProfileVars
(
	PlotApp		papp,
	AppData		appdata,
	NgDataProfile	dprof
)
{
	return;
}

/*
 * the DataTable is a static structure reinitialized everytime a DataProfile
 * instance is evaluated. 
 */
static void InitializeDataTable
(
	int count
)
{
	if (count > DataTableAllocCount) {
		Data_Table = NhlRealloc
			(Data_Table,count * sizeof(DataTableRec));
		if (! Data_Table) {
			NHLPERROR((NhlFATAL,ENOMEM,NULL));
			return;
		}

		DataTableAllocCount = count;
	}
	memset(Data_Table,(char) 0,count * sizeof(DataTableRec));
	return;
}

NhlBoolean NgPlotAppDataUsable
(
	int		go_id,
	NrmQuark	qplotstyle,
	NgVarData	vdata
)
{
	PlotApp	papp = PlotAppList;
	NgGO		go = (NgGO) _NhlGetLayer(go_id);
	AppData		data;
	

	if (! go)
		return NhlFATAL;

	while (papp) {
		if (papp->qname == qplotstyle) {
			break;
		}
		papp = papp->next;
	}
	if (! papp)
		return NhlFATAL;
/*
 * Right now we're just check to see that at least one data reference 
 * is looking for a data var with number of dimensions less than or
 * equal to the number of dimensions in the data var under test.
 * But we also need to check that the var meets pattern and unit and
 * whatever other requirements come up.
 */
	for (data = papp->data; data; data = data->next) {
		/*
		 * if the var has been shaped then its current rank 
		 * must meet dimensionality requirements. Otherwise,
		 * any of its dimensions can be used to meet the requirements.
		 */
		if (vdata->set_state == _NgSHAPED_VAR &&
		    data->ndims <= vdata->rank)
			return True;
		if (data->ndims <= vdata->ndims)
			return True;
	}
	return False;
}

NhlErrorTypes InitializePlotDataRecs
(
	NgPlotData	plotdata,
	NrmQuark	qname,
	NhlString	description,
	NhlBoolean	required,
	int		ndims,
	int		conform_group
)
{

	plotdata->qname = qname;
	plotdata->description = description;
	plotdata->required = required;
	plotdata->ndims = ndims;
	plotdata->vdata = NgNewVarData();
	plotdata->conform_group = conform_group;
	if (! plotdata->vdata)
		return NhlFATAL;

	return NhlNOERROR;
}

void NgFreePlotDataRecs
(
	NgPlotData	plotdata,
	int		count
)
{
	int i;

	for (i = 0; i < count; i++) 
		NgFreeVarData(plotdata[i].vdata);

	NhlFree(plotdata);

	return;
}
					    
NhlErrorTypes NgUpdatePlotAppDataProfile
(
	int		go_id,
	NrmQuark	qplotstyle,
	NhlString	plotname,
	NgDataProfile	dprof
)
{
	PlotApp	papp = PlotAppList;
	NgGO		go = (NgGO) _NhlGetLayer(go_id);

	if (! go)
		return NhlFATAL;

	while (papp) {
		if (papp->qname == qplotstyle) {
			break;
		}
		papp = papp->next;
	}
	if (! papp)
		return NhlFATAL;
	return NhlNOERROR;
}

static NhlBoolean DimReorderRequired
(
	DataTable dt
)
{
	int i;

	for (i = 1; i < dt->appdata->ndims; i++) {
		if (dt->dim_ix[i] > dt->dim_ix[i-1])
			return True;
	}
	return False;
}

static void TransferVarData
(
	DataTable dt,
	NgVarData vdata
)
{
	NclApiVarInfoRec *vinfo = dt->dl->u.var;
	int i,j,coord_ix = dt->appdata->ndims - 1;
	NgVarData vd = &dt->vd_rec;

	dt->reorder = DimReorderRequired(dt);

	NgCopyVarData(vd,vdata);
/*
 * If the vdata has a default shape, ignore the shape set in the vdata
 * and base the shape on the expected dimension names.
 * Otherwise the vdata shape prevails.
 */

	if (vdata->set_state != _NgDEFAULT_SHAPE)
		return;

	if (! dt->reorder) {
		for (i = 0; i < vinfo->n_dims; i++) {
			vd->start[i] = 0;
			vd->stride[i] = 1;
			if (i != dt->dim_ix[coord_ix]) {
				vd->finish[i] = vd->start[i];
				continue;
			}
			vd->finish[i] = vinfo->dim_info[i].dim_size - 1;
			coord_ix--;
		}
		return;
	}
	for (i = 0; i < vinfo->n_dims; i++) {
		vd->start[i] = 0;
		vd->stride[i] = 1;

		for (j = 0; j < dt->appdata->ndims; j++) {
			if (i == dt->dim_ix[j])
				break;
		}
		if (j == dt->appdata->ndims) {
			/* not found */
			vd->finish[i] = vd->start[i];
			continue;
		}
		vd->finish[i] = vinfo->dim_info[i].dim_size - 1;
	}
}

/*
 * This function is designed to set up the data profile given a variety of
 * kinds of input. If NgVarData records are supplied, they are used first to
 * try to match all the data symbols in the plot style. Otherwise, first
 * the single vars are used (the default slice will be taken). Last the
 * file list is examined.
 */

NhlErrorTypes NgSetPlotAppDataVars
(
	int		go_id,
	NrmQuark	qplotstyle,
	NhlString	plotname,
	NgDataProfile	dprof,
	NrmQuark	*qfiles,	/* NULL-terminated list of files */
	NrmQuark	*qvars,		/* NULL-terminated list of vars */
	int		varcount,
	NgVarData	*vardata,
	NrmQuark	qgraphics	/* graphic obj array - not used */
)
{
	PlotApp	papp = PlotAppList;
	NgGO		go = (NgGO) _NhlGetLayer(go_id);
	AppData		data;
	int		dcount;
	int		init_plot_data = False;
	NgVarData	vdata;
	NhlBoolean	done = False;
	

	if (! go)
		return NhlFATAL;

	while (papp) {
		if (papp->qname == qplotstyle) {
			break;
		}
		papp = papp->next;
	}
	if (! papp)
		return NhlFATAL;
	
	InitializeDataTable(papp->data_count);
	if (! dprof->plotdata) {
		dprof->plotdata = 
			NhlMalloc(papp->data_count * sizeof(NgPlotDataRec));
		if (! dprof->plotdata) {
			NHLPERROR((NhlFATAL,ENOMEM,NULL));
			return NhlFATAL;
		}
		dprof->plotdata_count = papp->data_count;
		init_plot_data = True;
	}

/*
 * There is a loop here to pass one pattern to each member of the data table
 * before going onto the next pattern.
 */
	while (! done) {
		dcount = 0;

		done = True;
		for (data = papp->data; data; data = data->next) {
			NgPlotData pdata = &dprof->plotdata[dcount];
			DataTable dt = &Data_Table[dcount];
			NhlBoolean free = False;

			if (init_plot_data)
				InitializePlotDataRecs
					(pdata,data->qdataname,
					 data->description,
					 data->required,data->ndims,
					 data->conform_group);
			vdata = MatchVarData
				(papp,data,dcount,varcount,vardata);
#if 0
			if (! vdata) {
				vdata = MatchVar(papp,data,dcount,qvars);
				free = True;
			}
			if (! vdata) {
				vdata = MatchVarFromFile
					(papp,data,dcount,qfiles);
				free = True;
			}
#endif
		
			if (vdata) {
				TransferVarData(dt,vdata);
				NgCopyVarData(pdata->vdata,&dt->vd_rec);
				if (free)
					NgFreeVarData(vdata);
			}
			else {
				if (dt->pat_ix > -1)
					done = False;
			}
			dcount++;
		}
		init_plot_data = False;
	}
	SubstituteVarSyms(papp,data,plotname,dprof);
#if 0
	EvaluateDataProfileVars(papp,data,dprof);
#endif

	return NhlNOERROR;
}

static NhlErrorTypes HandleOverlayRes
(
	PlotApp		papp,
	NrmQuark	qplot,
	NgDataItem	ditem,
	NhlBoolean	preview
)
{
	NrmQuark		qobj = ditem->qhlu_name;
	_NhlConvertContext	context;
	int 			count;
	NhlString		*objects;
	int			i;
	char			ncl_name[256];
	NgGO			go = (NgGO)_NhlGetLayer(papp->go_id);

	if (preview) {
		/* not handled yet */
		return NhlNOERROR;
	}
	if (! ((ditem->vdata->set_state == _NgEXPRESSION ||
	       ditem->vdata->set_state == _NgUSER_EXPRESSION) &&
	       ditem->vdata->expr_val))
		return NhlNOERROR;

	if (! go)
		return NhlFATAL;

	context = StringResToStringArray
		(ditem->vdata->expr_val,&count,&objects,NULL);
	
	if (! context) {
		NHLPERROR((NhlFATAL,ENOMEM,NULL));
		return NhlFATAL;
	}

	sprintf(ncl_name,"%s_%s",
		NrmQuarkToString(qplot),
		NrmQuarkToString(qobj));

	for (i = 0; i < count; i++) {
		char buf[512];

		sprintf(buf,"overlay(%s,%s)\n",ncl_name,objects[i]);
		(void)NgNclSubmitBlock(go->go.nclstate,buf);
	}
		
	return NhlNOERROR;
}

static NhlErrorTypes HandleDataLimitObjectRes
(
	PlotApp		papp,
	NrmQuark	qplot,
	NgDataItem	ditem,
	NgResData	resdata,
	int		*res_count,
	NhlBoolean	preview
)
{
	int			i;
	NgGO			go = (NgGO)_NhlGetLayer(papp->go_id);
	float			xmin,ymin,xmax,ymax;
	char			buf[32];
	char			*cp;
	NgVarData		vdata = ditem->vdata;
#if 0
	NhlString	res_names[] = {
		"mpLimitMode","mpRelativeCenterLon",
		"mpMinLonF","mpMaxLonF","mpMinLatF","mpMaxLatF" };
#endif
	NhlString	res_names[] = {
		"mpLimitMode",
		"mpMinLonF","mpMaxLonF","mpMinLatF","mpMaxLatF" };
	int hlu_id,count,*id_array;

	if (preview) {
		/* not handled yet */
		return NhlNOERROR;
	}

	if (! go)
		return NhlFATAL;

	if (! ((vdata->set_state == _NgEXPRESSION ||
		vdata->set_state == _NgUSER_EXPRESSION) &&
	       vdata->expr_val))
		return NhlFATAL;

	hlu_id = NgNclGetHluObjId(go->go.nclstate,vdata->expr_val,&count,
				  &id_array);

	if (hlu_id <= NhlNULLOBJID) {
		return NhlFATAL;
	}
	NhlVAGetValues(hlu_id,
		       "trXMinF",&xmin,
		       "trXMaxF",&xmax,
		       "trYMinF",&ymin,
		       "trYMaxF",&ymax,
		       NULL);

	if (*res_count + 6 >= resdata->res_alloced) {
		resdata = NgReallocResData(resdata,*res_count+6);
		if (! resdata)
			return NhlFATAL;
	}
	for (i = 0; i < 5; i++) {
		resdata->res[*res_count] = res_names[i];
		resdata->types[*res_count] = QString;

		switch (i) {
		case 0:
			sprintf(buf,"\"LatLon\"");
			break;
		case 1:
			sprintf(buf,"%f",xmin);
			break;
		case 2:
			sprintf(buf,"%f",xmax);
			break;
		case 3:
			sprintf(buf,"%f",ymin);
			break;
		case 4:
			sprintf(buf,"%f",ymax);
			break;
		}
		cp = NhlMalloc(strlen(buf)+1);
		strcpy(cp,buf);
		resdata->values[*res_count] = cp;
		(*res_count)++;
	}

	return NhlNOERROR;
}

extern NhlErrorTypes NgHandleSyntheticResource
(
	int		go_id,
	NrmQuark	qplotstyle,
	NrmQuark	qplot,
	NgDataProfile	dprof,
	int		obj_ix,
	int		item_ix,
	NgResData	resdata,
	int		*res_count,
	NhlBoolean	preview
)
{
	PlotApp		papp = PlotAppList;
	NgDataItem 	ditem = dprof->ditems[item_ix];
	NrmQuark   	qres = ditem->resq;

	while (papp) {
		if (papp->qname == qplotstyle) {
			break;
		}
		papp = papp->next;
	}
	if (! papp) {
		NHLPERROR((NhlFATAL,NhlEUNKNOWN,
			   "NgHandleSyntheticResource: invalid plot style"));
		return NhlFATAL;
	}

	if (qres == QpmOverlays)
		return HandleOverlayRes(papp,qplot,ditem,preview);
	else if (qres == QmpDataLimitObject)
		return HandleDataLimitObjectRes
			(papp,qplot,ditem,resdata,res_count,preview);
	
	NHLPERROR((NhlFATAL,NhlEUNKNOWN,
		   "NgHandleSyntheticResource: invalid synthetic resource"));

	return NhlFATAL;
}

extern NhlString NgPlotAppName
(
	int		go_id,
	NrmQuark	qplotstyle
)
{
	PlotApp		papp = PlotAppList;

	while (papp) {
		if (papp->qname == qplotstyle) {
			break;
		}
		papp = papp->next;
	}
	if (! papp) {
		NHLPERROR((NhlFATAL,NhlEUNKNOWN,
			   "NgPlotAppName: invalid plot style"));
		return NULL;
	}
	return NrmQuarkToString(papp->qstyle_name);
}
