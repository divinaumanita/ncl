%{
#include <stdio.h>
#ifdef IRIX
#include <pfmt.h>
#endif
#include <ncarg/c.h>
#include <ncarg/hlu/hluP.h>
#include <ncarg/hlu/NresDB.h>
#include "defs.h"
#include "NclDataDefs.h"
#include "Symbol.h"
#include "SrcTree.h"
#include "Machine.h"
#include <errno.h>
#include <ctype.h>
#include <sys/types.h>
#include <sys/stat.h>
#if defined(HPUX)
#include <dl.h>
#else
#include <dlfcn.h>
#endif
int scopelevel = 0;
extern int yydebug;
extern char *yytext;
extern FILE *thefptr;
extern FILE *theoptr;
extern int cmd_line;
extern int cur_line_length;
extern int cur_line_number;
extern int last_line_length;
extern char *cur_line_text;
extern int ok_to_start_vsblk;
#define ERROR(x)  NhlPError(NhlFATAL,NhlEUNKNOWN,"%s",(x))
int is_error = 0;
int block_syntax_error = 0;
int ret_urn = 0;
/*
extern int _NclTranslate(
#ifdef NhlNeedProto
void*,   
FILE* 
#endif
);
*/
extern void _NclTransTerminate(
#ifdef NhlNeedProto
void
#endif
);

extern int rec; 
extern FILE* recfp;
extern FILE* yyin;

int loading = 0;
int preloading = 0;
int top_level_line;
char *cur_load_file = NULL;

%}
%union {
	int integer;
	double real;
	char  str[NCL_MAX_STRING];
	struct _NclSymbol *sym;
	void *src_node;
	struct src_node_list *list;
	struct ncl_rcl_list *array;
}

%token	<void> EOLN 
%token  <void> EOFF
%token	<void> RP LP RBC LBC RBK LBK COLON ',' SEMI MARKER LPSLSH SLSHRP DIM_MARKER FSTRING EFSTRING ASTRING CSTRING
%token <integer> INT DIMNUM
%token <real> REAL
%token <str> STRING DIM DIMNAME ATTNAME COORDV FVAR 
%token <sym> INTEGER FLOAT LONG DOUBLE BYTE CHARACTER GRAPHIC STRNG NUMERIC FILETYPE SHORT LOGICAL
%token <sym> UNDEF VAR WHILE DO QUIT  NPROC PIPROC IPROC UNDEFFILEVAR BREAK NOPARENT NCLNULL
%token <sym> BGIN END NFUNC IFUNC FDIM IF THEN VBLKNAME CONTINUE
%token <sym> DFILE KEYFUNC KEYPROC ELSE EXTERNAL RETURN VSBLKGET NEW
%token <sym> OBJVAR OBJTYPE RECORD VSBLKCREATE VSBLKSET LOCAL STOP NCLTRUE NCLFALSE DLIB
%token '='
%token OR
%token XOR
%token AND
%token GT 
%token GE 
%token LT 
%token LE 
%token EQ 
%token NE
%token '<' 
%token '>'
%token '+' 
%token '-'
%token '*' 
%token '#' 
%token '/' 
%token '%'
%token '^'
%token UNOP 
%token NOT
%right '='
%left OR XOR
%left AND
%left GT GE LT LE EQ NE
%left '<' '>'
%left '+' '-'
%left '*' '#' '/' '%'
%left '^'
%left UNOP NOT
%type <array> expr_list
%type <src_node> statement assignment 
%type <src_node> procedure function_def procedure_def fp_block block do conditional
%type <src_node> visblk statement_list
%type <src_node> declaration identifier expr v_parent 
%type <src_node> subscript0 break_cont vcreate
%type <src_node> subscript1 subexpr primary function array error filevarselector coordvarselector attributeselector
%type <list> the_list arg_dec_list subscript_list opt_arg_list 
%type <list> block_statement_list resource_list dim_size_list  
%type <list> arg_list do_stmnt resource vset vget get_resource get_resource_list
%type <sym> datatype pfname vname
%type <sym> func_identifier proc_identifier anysym
%%


statement_list :  statement eoln			{	
								int strt;

/*
								fprintf(stdout,"is_error0 %d\n",is_error);
								fflush(stdout);
*/
								if(($1 != NULL)&&!(is_error||block_syntax_error)) {
									_NclPrintTree($1,thefptr);
									strt = _NclTranslate($1,thefptr);
									_NclTransTerminate();
#ifdef NCLDEBUG
									_NclPrintMachine(strt,-1,theoptr);
#endif
#ifndef PRINTTREEONLY
									_NclExecute(strt);
#endif
									_NclResetNewSymStack();
									_NclFreeTree();
								} else {
									_NclDeleteNewSymStack();
									_NclFreeTree();
									is_error = 0;
									if(block_syntax_error) {
										NhlPError(NhlFATAL,NhlEUNKNOWN,"Syntax Error in block, block not executed");
										block_syntax_error = 0;
									}
								}
							}
	| statement_list statement eoln			{		
								int strt;
/*
								fprintf(stdout,"is_error1 %d\n",is_error);
								fflush(stdout);
*/
								if(($2 != NULL) && !(is_error||block_syntax_error)) {
									_NclPrintTree($2,thefptr);
									strt = _NclTranslate($2,thefptr);
									_NclTransTerminate();
#ifdef NCLDEBUG
									_NclPrintMachine(strt,-1,theoptr);
#endif
#ifndef PRINTTREEONLY
									_NclExecute(strt);
#endif
									_NclResetNewSymStack();
									_NclFreeTree();
								} else {
									_NclDeleteNewSymStack();
									_NclFreeTree();
									is_error = 0;
									if(block_syntax_error) {
										NhlPError(NhlFATAL,NhlEUNKNOWN,"Syntax Error in block, block not executed");
										block_syntax_error = 0;
									}
								}
							}
	| statement_list RECORD STRING eoln		{ 
/*
* These record statments have to occur here so that the record command isn't written out
* by the scanner. The scanner writes each line when an EOLN is scanned.
*/
								recfp = fopen(_NGResolvePath($3),"w"); 
								if(recfp != NULL){ 
									rec =1;
								} else {
									NhlPError(NhlWARNING,errno,"Could not open record file");
									rec = 0;
								}
							}
	| RECORD STRING eoln				{ 
								recfp = fopen(_NGResolvePath($2),"w"); 
								if(recfp != NULL){ 
									rec =1;
								} else {
									NhlPError(NhlWARNING,errno,"Could not open record file");
									rec = 0;
								}
							}
	| EXTERNAL UNDEF STRING	eoln			{
								void (*init_function)(void);
								$2->u.package = NclMalloc(sizeof(NclSharedLibraryInfo));
								fprintf(stdout,"opening: %s\n",_NGResolvePath($3));
#if defined(HPUX)

								$2->u.package->so_handle = shl_load(_NGResolvePath($3),BIND_IMMEDIATE,0L);
#else
								$2->u.package->so_handle = dlopen(_NGResolvePath($3),RTLD_NOW);
#endif
								if($2->u.package->so_handle == NULL) {
#if defined(HPUX)
									NhlPError(NhlWARNING,NhlEUNKNOWN,"An error occurred loading the external file %s, file not loaded\n%s",$3,strerror(errno));
#else
									NhlPError(NhlWARNING,NhlEUNKNOWN,"An error occurred loading the external file %s, file not loaded\n%s",$3,dlerror());
#endif
								} else {
#if defined(HPUX)
									init_function = NULL;
									(void)shl_findsym(&($2->u.package->so_handle), "Init",TYPE_UNDEFINED,(void*)&init_function);
#else
									init_function = dlsym($2->u.package->so_handle, "Init");
#endif
									if(init_function != NULL) {
										_NclResetNewSymStack();
										_NclNewScope();
										_NclChangeSymbolType($2,DLIB);
										(*init_function)();
										$2->u.package->scope = _NclPopScope();
									} else {
										NhlPError(NhlWARNING,NhlEUNKNOWN,"Could not find Init() in external file %s, file not loaded",$3);
										$2->u.package->scope = NULL;
									}
									
	
								}
							}
	| statement_list EXTERNAL UNDEF STRING eoln		{
								void (*init_function)(void);
								$$ = NULL;
								$3->u.package = NclMalloc(sizeof(NclSharedLibraryInfo));
								fprintf(stdout,"opening: %s\n",_NGResolvePath($4));
#if defined(HPUX)
								$3->u.package->so_handle = shl_load(_NGResolvePath($4),BIND_IMMEDIATE,0L);
#else
								$3->u.package->so_handle = dlopen(_NGResolvePath($4),RTLD_NOW);
#endif
								if($3->u.package->so_handle == NULL) {
#if defined(HPUX)
									NhlPError(NhlWARNING,NhlEUNKNOWN,"An error occurred loading the external file %s, file not loaded\n%s",$4,strerror(errno));
#else
									NhlPError(NhlWARNING,NhlEUNKNOWN,"An error occurred loading the external file %s, file not loaded\n%s",$4,dlerror());
#endif
								} else {
#if defined(HPUX)
									init_function = NULL;
									(void)shl_findsym(&($3->u.package->so_handle), "Init",TYPE_UNDEFINED,(void*)&init_function);
#else
									init_function = dlsym($3->u.package->so_handle, "Init");
#endif
									if(init_function != NULL) {
										_NclResetNewSymStack();
										_NclNewScope();
										_NclChangeSymbolType($3,DLIB);
										(*init_function)();
										$3->u.package->scope = _NclPopScope();
									} else {
										NhlPError(NhlWARNING,NhlEUNKNOWN,"Could not find Init() in external file %s, file not loaded",$4);
										$3->u.package->scope = NULL;
									}
								}

							}
;
block_statement_list : statement eoln { 	

								
								if(is_error) {
									if(!cmd_line)
										block_syntax_error = 1;
									_NclDeleteNewSymStack();	
									is_error = 0;
									$1 = NULL;
								} else {
									_NclResetNewSymStack();
								}
								if($1 != NULL) {
									$$ = _NclMakeNewListNode();
									$$->next = NULL;
									$$->node = $1;
								} else {
									$$ = NULL;
								}
							}
	| block_statement_list statement eoln {	
/*
* This looping is necessary because ordering needs to be maintained for statement_lists
*/
								NclSrcListNode *step;
								if(is_error) {
									if(!cmd_line)
										block_syntax_error = 1;
									_NclDeleteNewSymStack();	
									is_error = 0;
									$2 = NULL;
								} else {
									_NclResetNewSymStack();
								}
							
								if($1 == NULL) {
									if($2 != NULL) {
										$$ = _NclMakeNewListNode();
										$$->next = NULL;
										$$->node = $2;
									} else if($2 == NULL) {
										$$ = NULL;
									}
								} else if($2 != NULL){
									step = $1;
									while(step->next != NULL) {
										step = step->next;
									}
									step->next = _NclMakeNewListNode();
									step= step->next;
									step->next = NULL;
									step->node = $2;
									$$ = $1;
								} else {
									$$ = $1;
								}
							}
	| block_statement_list RECORD STRING eoln				{ 
								recfp = fopen(_NGResolvePath($3),"w"); 
								if(recfp != NULL){ 
									rec =1;
								} else {
									NhlPError(NhlWARNING,errno,"Could not open record file");
									rec = 0;
								}
								$$ = $1;
							}
	| RECORD STRING eoln				{ 
								recfp = fopen(_NGResolvePath($2),"w"); 
								if(recfp != NULL){ 
									rec =1;
								} else {
									NhlPError(NhlWARNING,errno,"Could not open record file");
									rec = 0;
								}
								$$ = NULL;
							}
	| EXTERNAL UNDEF STRING	eoln			{
								void (*init_function)(void);
								$$ = NULL;
								$2->u.package = NclMalloc(sizeof(NclSharedLibraryInfo));
								fprintf(stdout,"opening: %s\n",_NGResolvePath($3));
#if defined(HPUX)
								$2->u.package->so_handle = shl_load(_NGResolvePath($3),BIND_IMMEDIATE,0L);
#else
								$2->u.package->so_handle = dlopen(_NGResolvePath($3),RTLD_NOW);
#endif
								if($2->u.package->so_handle == NULL) {
#if defined(HPUX)
									NhlPError(NhlWARNING,NhlEUNKNOWN,"An error occurred loading the external file %s, file not loaded\n%s",$3,strerror(errno));
#else
									NhlPError(NhlWARNING,NhlEUNKNOWN,"An error occurred loading the external file %s, file not loaded\n%s",$3,dlerror());
#endif
								} else {
#if defined(HPUX)
									init_function = NULL;
									(void)shl_findsym(&($2->u.package->so_handle), "Init",TYPE_UNDEFINED,(void*)&init_function);
#else
									init_function = dlsym($2->u.package->so_handle, "Init");
#endif
									if(init_function != NULL) {
										_NclResetNewSymStack();
										_NclNewScope();				
										_NclChangeSymbolType($2,DLIB);
										(*init_function)();
										$2->u.package->scope = _NclPopScope();
									} else {
										NhlPError(NhlWARNING,NhlEUNKNOWN,"Could not find Init() in external file %s, file not loaded",$3);
										$2->u.package->scope = NULL;
									}
								}
							}
	| block_statement_list EXTERNAL UNDEF STRING eoln	{

								void (*init_function)(void);
								$$ = NULL;
								$3->u.package = NclMalloc(sizeof(NclSharedLibraryInfo));
								fprintf(stdout,"opening: %s\n",_NGResolvePath($4));
#if defined(HPUX)
								$3->u.package->so_handle = shl_load(_NGResolvePath($4),BIND_IMMEDIATE,0L);
#else
								$3->u.package->so_handle = dlopen(_NGResolvePath($4),RTLD_NOW);
#endif
								if($3->u.package->so_handle == NULL) {
#if defined(HPUX)
									NhlPError(NhlWARNING,NhlEUNKNOWN,"An error occurred loading the external file %s, file not loaded\n%s",$4,strerror(errno));
#else
									NhlPError(NhlWARNING,NhlEUNKNOWN,"An error occurred loading the external file %s, file not loaded\n%s",$4,dlerror());
#endif
								} else {
#if defined(HPUX)
									init_function = NULL;
									(void)shl_findsym(&($3->u.package->so_handle), "Init",TYPE_UNDEFINED,(void*)&init_function);
#else
									init_function = dlsym($3->u.package->so_handle, "Init");
#endif
									if(init_function != NULL) {
										_NclResetNewSymStack();
										_NclNewScope();				
										_NclChangeSymbolType($3,DLIB);
										(*init_function)();
										$3->u.package->scope = _NclPopScope();
									} else {
										NhlPError(NhlWARNING,NhlEUNKNOWN,"Could not find Init() in external file %s, file not loaded",$4);
										$3->u.package->scope = NULL;
									}
								}
							}
;

opt_eoln : 		{ /* do nothing */ }
	| opt_eoln eoln	{ 
				yyerrok;
			}	
;


eoln : EOLN 						{ yyerrok; }
	| EOFF						{ 
								yyerrok;
#ifdef MAKEAPI
								ret_urn = 1;
#endif
							}
;

statement :     					{ $$ = NULL; }
	| 	assignment 				{
								$$ = $1; 
							}
	|	procedure 				{
								$$ = $1;
							}
	|	function_def 				{
								$$ = $1;
							}
	|	procedure_def 				{
								$$ = $1;
							}
	| 	block 					{
								$$ = $1;
							}
	|	do 					{
								$$ = $1;
							}
	| 	conditional				{
								$$ = $1;
							}
	| 	break_cont				{
								$$ = $1;
							}
	|	visblk 					{
								$$ = $1;
							}
	|	RETURN expr 				{
								$$ = _NclMakeReturn($2); 
							}
	|	RETURN 					{
								$$ = _NclMakeReturn(NULL); 
							}
	| 	QUIT 					{ 
#ifndef MAKEAPI
								return(-1);
#else
								$$ = NULL;
#endif

							}
	| 	error 					{ 
								$$ = NULL ; 
								ERROR("error in statement"); 
							}
	| 	STOP RECORD				{
/*
* this goes here so that rec gets set to one before eoln comes from scanner.
*/
								if(rec ==1 ) {
									fclose(recfp);
								} 
								$$ = NULL;
							}
;

break_cont : BREAK  {
				$$ = _NclMakeBreakCont($1);
			}
	| CONTINUE {
				$$ = _NclMakeBreakCont($1);
		}

conditional : IF expr then block_statement_list END IF				{  $$ = _NclMakeIfThen($2,$4);  }
	| IF expr then block_statement_list ELSE block_statement_list END IF	{  $$ = _NclMakeIfThenElse($2,$4,$6);  }
	| IF expr then statement END IF						{  
											NclSrcListNode *tmp = NULL;	
											if($4 != NULL) {
												tmp = _NclMakeNewListNode();
												tmp->next = NULL;
												tmp->node = $4;
											} 
											$$ = _NclMakeIfThen($2,tmp);  
										}
	| IF expr then statement ELSE block_statement_list END IF	 	{  
											NclSrcListNode *tmp = NULL;
	
											if($4 != NULL) {
                                                                                                tmp = _NclMakeNewListNode();
                                                                                                tmp->next = NULL;
                                                                                                tmp->node = $4;
											} 
											$$ = _NclMakeIfThenElse($2,tmp,$6);  
										}
											

	| IF expr then statement ELSE statement END IF	 	{  
										NclSrcListNode *tmp = NULL ,*tmp1 = NULL ;
										if($4 != NULL) {
                                                                                        tmp = _NclMakeNewListNode();
                                                                                        tmp->next = NULL;
                                                                                        tmp->node = $4;
										}
										if($6 != NULL) {
                                                                                        tmp1 = _NclMakeNewListNode();
                                                                                        tmp1->next = NULL;
                                                                                        tmp1->node = $6;
										}		
										$$ = _NclMakeIfThenElse($2,tmp,tmp1);  
								}
	| IF expr then block_statement_list ELSE statement END IF	 	{  
											NclSrcListNode *tmp = NULL ;
											if($6 != NULL) {
                                                                                        	tmp = _NclMakeNewListNode();
                                                                                        	tmp->next = NULL;
                                                                                        	tmp->node = $6;
	                                                                                } 
											$$ = _NclMakeIfThenElse($2,$4,tmp);  

										}

;

then : 
	| THEN 
;

visblk :   vset		{
				$$ = $1;
			}
	| vget		{
				$$ = $1;
			}
;

v_parent: NOPARENT {
			$$ = NULL;
		   }
	| identifier {
			$$ = $1;
		     }
;


vcreate : VSBLKCREATE expr OBJTYPE v_parent resource_list END VSBLKCREATE	{   
									$$ = _NclMakeVis($2,$3,$4,$5,Ncl_VISBLKCREATE);
								}
	| VSBLKCREATE expr OBJTYPE v_parent resource END VSBLKCREATE 	{   
										NclSrcListNode * tmp = NULL;
										if($5 != NULL) {
						 					tmp = _NclMakeNewListNode();
											tmp->next = NULL;
											tmp->node = $5;
										}
										$$ = _NclMakeVis($2,$3,$4,tmp,Ncl_VISBLKCREATE); 
								}
	| VSBLKCREATE error 					{
										$$ = NULL;
								}
;

vset :  VSBLKSET expr resource END VSBLKSET		{
									NclSrcListNode * tmp = NULL;
									if($3 != NULL) {
						 				tmp = _NclMakeNewListNode();
										tmp->next = NULL;
										tmp->node = $3;
									}
									$$ = _NclMakeSGVis($2,tmp,Ncl_VISBLKSET); 
								}
	| VSBLKSET expr resource_list END VSBLKSET	{
									$$ = _NclMakeSGVis($2,$3,Ncl_VISBLKSET);
								}
	| VSBLKSET error 					{
										$$ = NULL;
								}
;
vget : VSBLKGET expr get_resource END VSBLKGET		{
									NclSrcListNode * tmp = NULL;
									if($3 != NULL) {
						 				tmp = _NclMakeNewListNode();
										tmp->next = NULL;
										tmp->node = $3;
									}
									$$ = _NclMakeSGVis($2,tmp,Ncl_VISBLKGET); 
								}
	| VSBLKGET expr get_resource_list END VSBLKGET  	{
									$$ = _NclMakeSGVis($2,$3,Ncl_VISBLKGET);
								}
	| VSBLKGET error {
										$$ = NULL;
								}
;


get_resource_list : get_resource eoln		{
							if($1 != NULL) {
						 		$$ = _NclMakeNewListNode();
								$$->next = NULL;
								$$->node = $1;
							} else {
								$$ = NULL;
							}
						}
	| get_resource_list get_resource eoln	{
							if($1 == NULL) {
								if($2 != NULL) {
									$$ = _NclMakeNewListNode();
									$$->next = NULL;
								 	$$->node = $2;
								} else {
									$$ = NULL;
								}
							} else if($2 != NULL) {
								$$ = _NclMakeNewListNode();
								$$->next = $1;
								$$->node = $2;
							} else {
								$$ = $1;
								if((is_error)&&(cmd_line)) {
									is_error = 0;
								}
							}
						}
;

get_resource : 					{
							$$ = NULL;
						}
	| STRING COLON identifier		{
							((NclGenericRefNode*)$3)->ref_type = Ncl_WRITEIT;
						 	$$ = _NclMakeGetResource(_NclMakeStringExpr($1),$3);

						}
	| identifier COLON identifier		{
							((NclGenericRefNode*)$3)->ref_type = Ncl_WRITEIT;
						 	$$ = _NclMakeGetResource($1,$3);

						}
/*
	| STRING COLON UNDEF			{
						 	$$ = _NclMakeGetResource($1,$3);
							if(cmd_line)
								if(!VerifyGetResExpr($3)) {
									$$ = NULL;
								}
						}
	| STRING COLON identifier			{
						 	$$ = _NclMakeGetResource($1,$3);
						}
*/
	| error					{	
							$$ = NULL;
						}
;


resource_list : resource eoln			{
							if($1 != NULL) {
						 		$$ = _NclMakeNewListNode();
								$$->next = NULL;
								$$->node = $1;
							} else {
								$$ = NULL;
							}
						}
						
	| resource_list resource eoln		{
							if($1 == NULL) {
								if($2 != NULL) {
									$$ = _NclMakeNewListNode();
									$$->next = NULL;
								 	$$->node = $2;
								} else {
									$$ = NULL;
								}
							} else if($2 != NULL) {
								$$ = _NclMakeNewListNode();
								$$->next = $1;
								$$->node = $2;
							} else {
								$$ = $1;
								if((is_error)&&(cmd_line)) {
/*
									_NclDeleteNewSymStack();		
*/
									is_error = 0;
								}
						
							}
						}	
	| resource_list error eoln		{
							$$ = $1;
							is_error -= 1;
/*
							_NclDeleteNewSymStack();	
*/
						}
;

resource : 					{
							$$ = NULL;
						}
	| STRING COLON expr 			{
						 	$$ = _NclMakeResource(_NclMakeStringExpr($1),$3);
						}
	| identifier COLON expr 		{
						 	$$ = _NclMakeResource($1,$3);
						}
/*
	| STRING COLON RKEY FVAR		{
						 	$$ = NULL;
						}
	| STRING COLON RKEY FVAR LP subscript_list RP	{
					 		$$ = NULL;
						}
	| STRING COLON RKEY COORDV		{	
						 	$$ = NULL;
						}
	| STRING COLON RKEY COORDV LP subscript_list RP  	{
							 	$$ = NULL;
							}
	| STRING COLON RKEY ATTNAME		{
						 	$$ = NULL;
						}
	| STRING COLON RKEY ATTNAME LP subscript_list RP	{
						 		$$ = NULL;
							}
*/
;

do_stmnt : block_statement_list						{
										$$ = $1;
									}
	| statement							{
										NclSrcListNode * tmp = NULL;
										if($1 != NULL ) {
											tmp = _NclMakeNewListNode();
											tmp->next = NULL;
											tmp->node = $1;
										}
										$$ = tmp;
									}
;

do : DO identifier '=' expr ',' expr do_stmnt END DO 			 	{ 
										
										$$ = _NclMakeDoFromTo($2,$4, $6, $7);
									}
	| DO identifier '=' expr ',' expr ',' expr do_stmnt END DO	 { 
										$$ = _NclMakeDoFromToStride($2,$4,$6,$8,$9);
									}
	| DO WHILE expr block_statement_list END DO {   
								$$ = _NclMakeWhile($3,$4);
							}
	| DO WHILE expr statement END DO {   
								NclSrcListNode *tmp = NULL ;
								if($4 != NULL) {
                                                               		tmp = _NclMakeNewListNode();
                                                                       	tmp->next = NULL;
                                                                       	tmp->node = $4;
	                                                        } 
								$$ = _NclMakeWhile($3,tmp);
							}
;

block : BGIN block_statement_list END	{ $$ = _NclMakeBlock($2); }
	| BGIN statement END	{ 
					NclSrcListNode *tmp = NULL ;
					if($2 != NULL) {
                                       		tmp = _NclMakeNewListNode();
                                        	tmp->next = NULL;
                                               	tmp->node = $2;
	                                } 
					$$ = _NclMakeBlock(tmp); 
				}
;
fp_block : BGIN block_statement_list END	{ $$ = _NclMakeBlock($2); }
	| BGIN statement END	{ 
					NclSrcListNode *tmp = NULL ;
					if($2 != NULL) {
                                       		tmp = _NclMakeNewListNode();
                                        	tmp->next = NULL;
                                               	tmp->node = $2;
	                                } 
					$$ = _NclMakeBlock(tmp); 
				}
;

procedure : IPROC opt_arg_list    {
					NclSrcListNode *step;
					int count = 0;
					
					step = $2;
					while(step != NULL) {
						count++;
						step = step->next;
					}
					if(count != $1->u.procfunc->nargs) {
						is_error += 1;
						NhlPError(NhlFATAL,NhlEUNKNOWN,"syntax error: procedure %s expects %d arguments, got %d",$1->name,$1->u.procfunc->nargs,count);
						$$ = NULL;
					} else {
						$$ = _NclMakeProcCall($1,$2,Ncl_INTRINSICPROCCALL); 
					}
				}
	| PIPROC opt_arg_list    {
					NclSrcListNode *step;
					int count = 0;
				
					step = $2;
					while(step != NULL) {
						count++;
						step = step->next;
					}
					if(count != $1->u.procfunc->nargs) {
						is_error += 1;
						NhlPError(NhlFATAL,NhlEUNKNOWN,"syntax error: procedure %s expects %d arguments, got %d",$1->name,$1->u.procfunc->nargs,count);
						$$ = NULL;
					} else {
						$$ = _NclMakeProcCall($1,$2,Ncl_INTRINSICPROCCALL); 
					}
				}
	| NPROC opt_arg_list	{ 
					NclSrcListNode *step;
					int count = 0;
				
					step = $2;
					while(step != NULL) {
						count++;
						step = step->next;
					}
					if(count != $1->u.procfunc->nargs) {
						is_error += 1;
						NhlPError(NhlFATAL,NhlEUNKNOWN,"syntax error: procedure %s expects %d arguments, got %d",$1->name,$1->u.procfunc->nargs,count);
						$$ = NULL;
					} else {
						$$ = _NclMakeProcCall($1,$2,Ncl_PROCCALL); 
					}
				}
	| PIPROC 		{ 
					if($1->u.procfunc->nargs != 0) {
						is_error += 1;
						NhlPError(NhlFATAL,NhlEUNKNOWN,"syntax error: procedure %s expects %d arguments, got %d",$1->name,$1->u.procfunc->nargs,0);
						$$ = NULL;
					} else {
						$$ = _NclMakeProcCall($1,NULL,Ncl_INTRINSICPROCCALL); 
					}
				}
	| IPROC 		{ 
					if($1->u.procfunc->nargs != 0) {
						is_error += 1;
						NhlPError(NhlFATAL,NhlEUNKNOWN,"syntax error: procedure %s expects %d arguments, got %d",$1->name,$1->u.procfunc->nargs,0);
						$$ = NULL;
					} else {
						$$ = _NclMakeProcCall($1,NULL,Ncl_INTRINSICPROCCALL); 
					}
				}
	| NPROC 		{ 
						if($1->u.procfunc->nargs != 0) {
							is_error += 1;
							NhlPError(NhlFATAL,NhlEUNKNOWN,"syntax error: procedure %s expects %d arguments, got %d",$1->name,$1->u.procfunc->nargs,0);
							$$ = NULL;
						} else {
							$$ = _NclMakeProcCall($1,NULL,Ncl_PROCCALL); 
						}
				}
	| DLIB COLON COLON anysym	{
					NclSymbol *s;
					if($1->u.package != NULL) {
						s = _NclLookUpInScope($1->u.package->scope,$4->name);
						if(s == NULL) {
							is_error += 1;
							NhlPError(NhlFATAL,NhlEUNKNOWN,"syntax error: procedure %s is not defined in package %s\n",$4->name,$1->name);
							$$ = NULL;
						} else if(s->type == IPROC){
							if(s->u.procfunc->nargs != 0) {
								is_error += 1;
								NhlPError(NhlFATAL,NhlEUNKNOWN,"syntax error: procedure %s expects %d arguments, got %d",s->name,s->u.procfunc->nargs,0);
								$$ = NULL;
							} else {
								$$ = _NclMakeProcCall(s,NULL,Ncl_INTRINSICPROCCALL); 
							}
						} else {
							NhlPError(NhlFATAL,NhlEUNKNOWN,"syntax error: %s is not a procedure in package %s\n",$4->name,$1->name);
							$$ = NULL;
						}
					} else {
						$$ = NULL;
					}
				}
	| DLIB COLON COLON anysym opt_arg_list {
					NclSrcListNode *step;
					int count = 0;
					
					NclSymbol *s;
					if($1->u.package != NULL) {
						s = _NclLookUpInScope($1->u.package->scope,$4->name);
						if(s == NULL) {
							is_error += 1;
							NhlPError(NhlFATAL,NhlEUNKNOWN,"syntax error: procedure %s is not defined in package %s\n",$4->name,$1->name);
							$$ = NULL;
						} else if(s->type == IPROC){
							step = $5;
							while(step != NULL) {
								count++;
								step = step->next;
							}
							if(count != s->u.procfunc->nargs) {
								is_error += 1;
								NhlPError(NhlFATAL,NhlEUNKNOWN,"syntax error: procedure %s expects %d arguments, got %d",s->name,s->u.procfunc->nargs,count);
								$$ = NULL;
							} else {
								$$ = _NclMakeProcCall(s,$5,Ncl_INTRINSICPROCCALL); 
							}
                                                } else {
                                                        NhlPError(NhlFATAL,NhlEUNKNOWN,"syntax error: %s is not a procedure in package %s\n",$4->name,$1->name);
                                                        $$ = NULL;
                                                }

					} else {
						$$ = NULL;
					}
				}
/*---------------------------------------------ERROR HANDLING BELOW THIS LINE-----------------------------------------------------*/
/*
	| identifier opt_arg_list	{ ERROR("syntax error: <identifier> IS NOT A PROCEDURE"); }
*/
	| IFUNC opt_arg_list	{ $$ = NULL;  ERROR("syntax error: <identifier> IS A FUNCTION NOT A PROCEDURE"); }
	| NFUNC opt_arg_list	{ $$ = NULL; ERROR("syntax error: <identifier> IS A FUNCTION NOT A PROCEDURE"); }
/*
	| UNDEF LP arg_list RP	{ $$ = NULL; NhlPError(NhlFATAL,NhlEUNKNOWN,"syntax error: %s IS A FUNCTION NOT A PROCEDURE",$1->name); }
*/

;

opt_arg_list : LP arg_list RP			{ $$ = $2;    }
	| LP RP					{ $$ = NULL;    }
;

arg_list: expr					{ 
						/* Code to check type of expression, iff its and identifier then stamp it with
							the Ncl_PARAMIT tag so the translator can add extra code */
							if(!is_error) {
								if(((NclGenericNode*)$1)->kind == Ncl_IDNEXPR) {
									((NclGenericRefNode*)((NclIdnExpr*)$1)->idn_ref_node)->ref_type =
										Ncl_PARAMIT;
								}
								$$ = _NclMakeNewListNode();
								$$->next = NULL;
								$$->node = $1;
							} else {
								$$ = NULL;
							}
						}
	| arg_list ',' expr  			{
							NclSrcListNode * step;
						/* 
						* ordering is important because arguments eventually must be pushed on stack in
						* appropriate order 
						*/
							if(!is_error) {
								step = $1;
								while(step->next != NULL) {
									step = step->next;
								}
							/* Code to check type of expression, iff its and identifier then stamp it with
								the Ncl_PARAMIT tag so the translator can add extra code */
								if(((NclGenericNode*)$3)->kind == Ncl_IDNEXPR) {
									((NclGenericRefNode*)((NclIdnExpr*)$3)->idn_ref_node)->ref_type =
										Ncl_PARAMIT;
								}
								step->next = _NclMakeNewListNode();
								step->next->next = NULL;
								step->next->node = $3;
							} 
							$$ = $1;
							
						}
;
func_identifier: KEYFUNC UNDEF { _NclNewScope(); $$ = $2; }
/*
	| KEYFUNC pfname { NhlPError(NhlFATAL,NhlEUNKNOWN,"Function identifier is defined");_NclNewScope(); $$ = NULL; }
	| KEYFUNC VAR { NhlPError(NhlFATAL,NhlEUNKNOWN,"Function identifier is defined");_NclNewScope(); $$ = NULL; }
*/
;

local_list: vname {
			/* have to make sure that items in the local list are not added twice !! */
			int lv = _NclGetCurrentScopeLevel();

			if($1->level != lv) {
				_NclAddSym($1->name,UNDEF);
			}
		}
	| pfname {
			int lv = _NclGetCurrentScopeLevel();
			if($1->level != lv) {
				_NclAddSym($1->name,UNDEF);
			}
		}
	| local_list opt_eoln ',' opt_eoln vname {
			int lv = _NclGetCurrentScopeLevel();
			if($5->level != lv) {
				_NclAddSym($5->name,UNDEF);
			}
			}
	| local_list opt_eoln ',' opt_eoln pfname {
			int lv = _NclGetCurrentScopeLevel();
			if($5->level != lv) {
				_NclAddSym($5->name,UNDEF);
			}
			}
;
function_def :  func_identifier  LP arg_dec_list  RP opt_eoln {_NclChangeSymbolType($1,NFUNC);_NclAddProcFuncInfoToSym($1,$3); } fp_block		
								{  
									NclScopeRec *tmp;

									if(is_error||((!cmd_line)&&block_syntax_error)) {
										_NclDeleteNewSymStack();
										tmp = _NclPopScope();	
										$$ = NULL;
										is_error += 1;	
										$1->type = UNDEF;
									}else {
										tmp = _NclPopScope();	
										$$ = _NclMakeNFunctionDef($1,$3,$7,tmp);  
									}
								}
	|  func_identifier  LP arg_dec_list  RP opt_eoln LOCAL opt_eoln local_list opt_eoln {_NclChangeSymbolType($1,NFUNC); _NclAddProcFuncInfoToSym($1,$3); } fp_block
								{  
									NclScopeRec *tmp;

									if(is_error||(!cmd_line&&block_syntax_error)) {
										_NclDeleteNewSymStack();
										tmp = _NclPopScope();	
										$$ = NULL;
										is_error += 1;
										$1->type = UNDEF;
									}else {
										tmp = _NclPopScope();	
										$$ = _NclMakeNFunctionDef($1,$3,$11,tmp);  
									}
								}
/*---------------------------------------------ERROR HANDLING BELOW THIS LINE-----------------------------------------------------*/
	| func_identifier error {
			is_error += 1;
			NhlPError(NhlFATAL,NhlEUNKNOWN,"syntax error: Possibly expecting a 'begin' or 'local'");
/*
* Need to call this before new scope is poped so symbols can be found and freed
*/
			_NclDeleteNewSymStack();
/*
* Need to call function to free scope
*/
			(void)_NclPopScope();
			$1->type = UNDEF;
	}
	| KEYFUNC error {
		is_error += 1;
		 NhlPError(NhlFATAL,NhlEUNKNOWN,"Function identifier is defined");
		$$ = NULL;
	}
/*
	| EXTERNAL func_identifier LP arg_dec_list RP opt_eoln local_arg_dec_list eoln error {
						ERROR("syntax error: EXPECTING A 'begin'");
	}
*/
;

arg_dec_list : 			{ $$ = NULL; }
	| opt_eoln the_list { $$ = $2; }
; 

the_list: declaration opt_eoln			{	
							$$ = _NclMakeNewListNode();
							$$->next = NULL;
							$$->node = $1;
						}
	| declaration opt_eoln ',' opt_eoln the_list 	{ 
						/* once again ordering not important as long as it is consistent with function 
							and procedure ordering of argument lists */
							$$ = _NclMakeNewListNode();
							$$->next = $5;
							$$->node = $1;
							  
						}
;

declaration : vname { 
					NclSymbol *s;
					int lv = _NclGetCurrentScopeLevel();

					if(($1->type != UNDEF)||($1->level != lv)) {
						s = _NclAddSym($1->name,UNDEF);
					} else {
						s = $1;
					}
					$$ = _NclMakeLocalVarDec(s,NULL,NULL); 
				}
	| vname COLON datatype { 
					NclSymbol *s;
					int lv = _NclGetCurrentScopeLevel();

					if(($1->type != UNDEF)||($1->level != lv)) {
						s = _NclAddSym($1->name,UNDEF);
					} else {
						s = $1;
					}
					$$ = _NclMakeLocalVarDec(s,NULL,$3); 
				}
	| vname dim_size_list { 
						NclSymbol *s;
						int lv = _NclGetCurrentScopeLevel();
						if(($1->type != UNDEF)||($1->level != lv)) {
							s = _NclAddSym($1->name,UNDEF);
						} else {
							s = $1;
						}

						$$ = _NclMakeLocalVarDec(s,$2,NULL); 
					}
	| vname dim_size_list COLON datatype { 
						NclSymbol *s;
						int lv = _NclGetCurrentScopeLevel();
						if(($1->type != UNDEF)||($1->level != lv)) {
							s = _NclAddSym($1->name,UNDEF);
						} else {
							s = $1;
						}

						$$ = _NclMakeLocalVarDec(s,$2,$4); 
					}
	| pfname { 
				/* Need to intercept defined names and add them to current scope */
					NclSymbol *s;

					s = _NclAddSym($1->name,UNDEF);
					$$ = _NclMakeLocalVarDec(s,NULL,NULL); 
				}
	| pfname COLON datatype { 
					NclSymbol *s;

					s= _NclAddSym($1->name,UNDEF);
					$$ = _NclMakeLocalVarDec(s,NULL,$3); 
				}
	| pfname dim_size_list { 
					NclSymbol *s;

					s = _NclAddSym($1->name,UNDEF);
					$$ = _NclMakeLocalVarDec(s,$2,NULL); 
				}
	| pfname dim_size_list COLON datatype { 
					NclSymbol *s;

					s = _NclAddSym($1->name,UNDEF);
					$$ = _NclMakeLocalVarDec(s,$2,$4); 
				}
;

pfname : IFUNC		{
				$$ = $1;
			}
	| PIPROC	{
				$$ = $1;
			}
	| NFUNC		{		
				$$ = $1;
			}
	| NPROC		{
				$$ = $1;
			}
;

datatype : FLOAT	{ $$ = $1; }
	| LONG		{ $$ = $1; }
	| INTEGER	{ $$ = $1; }
	| SHORT		{ $$ = $1; }
	| DOUBLE	{ $$ = $1; }
	| CHARACTER	{ $$ = $1; }
	| BYTE		{ $$ = $1; }
	| FILETYPE	{ $$ = $1; }
	| NUMERIC	{ $$ = $1; }
	| GRAPHIC 	{ $$ = $1; }
	| STRNG	 	{ $$ = $1; }
	| LOGICAL 	{ $$ = $1; }
;

dim_size_list : LBK INT RBK		{ 
					/* Dimension size list must be in order */
						$$ = _NclMakeNewListNode();
						$$->next = NULL;
						$$->node = _NclMakeDimSizeNode($2);
						 
					}
	| LBK '*' RBK 			{
						$$ = _NclMakeNewListNode();
						$$->next = NULL;
						$$->node = _NclMakeDimSizeNode(-1);
						 
					}
	| dim_size_list LBK INT RBK 	{   	
						NclSrcListNode *step;
						
						step = $1;
						while(step->next != NULL) 
							step = step->next;
						step->next = _NclMakeNewListNode();
						step->next->next = NULL;
						step->next->node = _NclMakeDimSizeNode($3);
						
					}
	| dim_size_list LBK '*' RBK 	{   
						NclSrcListNode *step;
                                                
                                                step = $1;
                                                while(step->next != NULL) 
                                                        step = step->next;
                                                step->next = _NclMakeNewListNode();
                                                step->next->next = NULL;
                                                step->next->node = _NclMakeDimSizeNode(-1);
						
					}
;

proc_identifier: KEYPROC UNDEF { _NclNewScope(); $$ = $2; }
;
procedure_def : proc_identifier LP arg_dec_list RP opt_eoln LOCAL opt_eoln local_list opt_eoln {_NclChangeSymbolType($1,NPROC);_NclAddProcFuncInfoToSym($1,$3); } fp_block   {
								NclScopeRec *tmp;
								if(is_error||((!cmd_line)&&block_syntax_error)) {
									_NclDeleteNewSymStack();
                                                                	tmp = _NclPopScope();
									$$ = NULL;
									is_error +=1;
									$1->type = UNDEF;
								} else {
									tmp = _NclPopScope();	
									$$ = _NclMakeProcDef($1,$3,$11,tmp);
								}
							
							}
	| proc_identifier LP arg_dec_list RP opt_eoln {_NclChangeSymbolType($1,NPROC);_NclAddProcFuncInfoToSym($1,$3); } fp_block   {
								NclScopeRec *tmp;

								if(is_error||((!cmd_line)&&block_syntax_error)) {
									_NclDeleteNewSymStack();
                                                                	tmp = _NclPopScope();
									$$ = NULL;
									is_error +=1;
									$1->type = UNDEF;
								} else {
									tmp = _NclPopScope();	
									$$ = _NclMakeProcDef($1,$3,$7,tmp);
								}
									
							}
	| proc_identifier error {
			is_error += 1;
/*
* Need to call this before new scope is poped so symbols can be found and freed
*/
			_NclDeleteNewSymStack();
/*
* Need to call function to free scope
*/
			(void)_NclPopScope();
			$1->type = UNDEF;
			$$ = NULL;
	}
;

assignment :  identifier '=' expr		{
						((NclGenericRefNode*)$1)->ref_type = Ncl_WRITEIT;
						$$ = _NclMakeAssignment($1,$3);
						  
					}
	| identifier  error {
						NhlPError(NhlFATAL,NhlEUNKNOWN,"syntax error: possibly an undefined procedure");
						$$ = NULL;
					}
	| identifier '='  error		{
						$$ = NULL;
					}
/*
	| identifier '=' vcreate	{
						$$ = NULL;
					}
*/
;

filevarselector : FVAR {
			$$ = _NclMakeIdnExpr(_NclMakeStringExpr($1));
		}
	| FSTRING primary EFSTRING {
		_NclValOnly($2);
		$$ = $2;
	}
coordvarselector : COORDV{
			$$ = _NclMakeIdnExpr(_NclMakeStringExpr($1));
	}
	| CSTRING primary EFSTRING {
		_NclValOnly($2);
		$$ = $2;
	}
attributeselector : ATTNAME{
			$$ = _NclMakeIdnExpr(_NclMakeStringExpr($1));
	}
	| ASTRING primary EFSTRING {
		_NclValOnly($2);
		$$ = $2;
	}

identifier : vname {
			$$ = _NclMakeVarRef($1,NULL);
		  }
	| vname filevarselector {
						$$ = _NclMakeFileVarRef($1,$2,NULL,Ncl_FILEVAR);
					}
	| vname filevarselector MARKER		{
						$$ = _NclMakeFileVarRef($1,$2,NULL,Ncl_FILEVAR);
					}
	| vname filevarselector LP subscript_list RP MARKER {
				
						$$ = _NclMakeFileVarRef($1,$2,$4,Ncl_FILEVAR);
					}
	| vname filevarselector LP subscript_list RP	{	
				
						$$ = _NclMakeFileVarRef($1,$2,$4,Ncl_FILEVAR);
					}
	| vname filevarselector DIM_MARKER primary	{
						_NclValOnly($4);
						$$ = _NclMakeFileVarDimRef($1,$2,$4);		
					}
        | vname filevarselector attributeselector {
						$$ = _NclMakeFileVarAttRef($1,$2,$3,NULL);
					}
        | vname filevarselector attributeselector LP subscript_list RP	{
						$$ = _NclMakeFileVarAttRef($1,$2,$3,$5);
					}
	| vname filevarselector coordvarselector			{
						$$ = _NclMakeFileVarCoordRef($1,$2,$3,NULL);
					}
	| vname filevarselector coordvarselector attributeselector{
						$$ = _NclMakeFileVarCoordAttRef($1,$2,$3,$4,NULL);
					}
	| vname filevarselector coordvarselector attributeselector LP subscript_list RP {
						$$ = _NclMakeFileVarCoordAttRef($1,$2,$3,$4,$6);
					}
	| vname filevarselector coordvarselector LP subscript_list RP{
						$$ = _NclMakeFileVarCoordRef($1,$2,$3,$5);
					}
	| vname DIM_MARKER primary  {
						_NclValOnly($3);
						$$ = _NclMakeVarDimRef($1,$3);		
					}
        | vname attributeselector {
						$$ = _NclMakeVarAttRef($1,$2,NULL);
					}
        | vname attributeselector LP subscript_list RP	{
						$$ = _NclMakeVarAttRef($1,$2,$4);
					}
	| vname MARKER			{
						$$ = _NclMakeVarRef($1,NULL);
					}
	| vname LP subscript_list RP MARKER     {
						$$ = _NclMakeVarRef($1,$3);
					}
        | vname LP subscript_list RP {
						$$ = _NclMakeVarRef($1,$3);
					}
	| vname coordvarselector{
						$$ = _NclMakeVarCoordRef($1,$2,NULL);
					}
	| vname coordvarselector LP subscript_list RP{
						$$ = _NclMakeVarCoordRef($1,$2,$4);
					}
	| vname coordvarselector attributeselector		{
						$$ = _NclMakeVarCoordAttRef($1,$2,$3,NULL);
					}
	| vname coordvarselector attributeselector LP subscript_list RP {
						$$ = _NclMakeVarCoordAttRef($1,$2,$3,$5);
					}
	| vname LP RP error 			{
					NhlPError(NhlFATAL,NhlEUNKNOWN,"syntax error: possibly an undefined procedure");
					$$ = NULL;
	}
;

vname : OBJVAR		{
				$$ = $1;
			}
	| OBJTYPE	{
				$$ = $1;
			}
	| VAR		{
				$$ = $1;
			}
	| UNDEF		{
				$$ = $1;
			}
	| DFILE		{
				$$ = $1;
			}
;
subscript_list :  subscript0 	{
					/* ordering of subscripts must be preserved */
						$$ = _NclMakeNewListNode();
						$$->next = NULL;
						$$->node = $1;
					}
	| LBC subscript1 RBC 		{
					/* ordering of subscripts must be preserved */
                                                $$ = _NclMakeNewListNode();
                                                $$->next = NULL;
                                                $$->node = $2;
					}
	| subscript_list ',' subscript0 {
						NclSrcListNode *step;
                                                
                                                step = $1;
                                                while(step->next != NULL) 
                                                        step = step->next;
                                                step->next = _NclMakeNewListNode();
                                                step->next->next = NULL;
                                                step->next->node = $3;
						
					}
	| subscript_list ',' LBC subscript1 RBC {
						NclSrcListNode *step;
                                         
                                                step = $1;
                                                while(step->next != NULL)
                                                        step = step->next;
                                                step->next = _NclMakeNewListNode();
                                                step->next->next = NULL;
                                                step->next->node = $4;
                                                
					}
;

subscript0:  subexpr 			{  
						$$ = _NclMakeIntSubscript($1,NULL);
						 
					}
	|  DIM subexpr			{ 
						$$ = _NclMakeIntSubscript($2,_NclMakeStringExpr($1));
						  
					}
	|  EFSTRING primary EFSTRING "|" subexpr {
						_NclValOnly($2);
						$$ = _NclMakeIntSubscript($5,$2);
					}
;

subscript1:  subexpr	 		{  
						$$ = _NclMakeCoordSubscript($1,NULL);
						 
					}
	|  DIM subexpr			{ 
						$$ = _NclMakeCoordSubscript($2,_NclMakeStringExpr($1));
						  
					}
	|  EFSTRING primary EFSTRING "|" subexpr {
						_NclValOnly($2);
						$$ = _NclMakeCoordSubscript($5,$2);
					}

;

subexpr: expr				{
						_NclValOnly($1);
						$$ = _NclMakeSingleIndex($1);
					}
	|  COLON 			{
						$$ = _NclMakeRangeIndex(NULL,NULL,NULL);
					}
	| expr COLON expr		{
						_NclValOnly($1);
						_NclValOnly($3);
						$$ = _NclMakeRangeIndex($1,$3,NULL);
					}
	| COLON expr			{
						_NclValOnly($2);
						$$ = _NclMakeRangeIndex(NULL,$2,NULL);
					}
	| expr COLON 			{
						_NclValOnly($1);
						$$ = _NclMakeRangeIndex($1,NULL,NULL);
					}
	| expr COLON expr COLON 	{
						_NclValOnly($1);
						_NclValOnly($3);
						$$ = _NclMakeRangeIndex($1,$3,NULL);
					}
	| COLON expr COLON 		{
						_NclValOnly($2);
						$$ = _NclMakeRangeIndex(NULL,$2,NULL);
					}
	| expr COLON COLON		{
						_NclValOnly($1);
						$$ = _NclMakeRangeIndex($1,NULL,NULL);
					} 
	| expr COLON expr COLON expr	{				
						_NclValOnly($1);
						_NclValOnly($3);
						_NclValOnly($5);
						$$ = _NclMakeRangeIndex($1,$3,$5);
					}
	| expr COLON COLON expr		{				
						_NclValOnly($1);
						_NclValOnly($4);
						$$ = _NclMakeRangeIndex($1,NULL,$4);
					}
	| COLON expr COLON expr		{				
						_NclValOnly($2);
						_NclValOnly($4);
						$$ = _NclMakeRangeIndex(NULL,$2,$4);
					}
	| COLON COLON 			{				
						$$ = _NclMakeRangeIndex(NULL,NULL,NULL);
					}
	| COLON COLON expr		{				
						_NclValOnly($3);
						$$ = _NclMakeRangeIndex(NULL,NULL,$3);
					}
	| '*'				{
						$$ = _NclMakeWildCardIndex();
					}
;
expr :  primary				{
						$$ = $1;
					}
	| '-' expr %prec UNOP		{
						_NclValOnly($2);
						$$ = _NclMakeUnaryExpr($2,Ncl_NEGEXPR);
					}
	| NOT expr %prec UNOP		{
						_NclValOnly($2);
						$$ = _NclMakeUnaryExpr($2,Ncl_NOTEXPR);
					}
	| expr '%' expr			{
						_NclValOnly($1);
						_NclValOnly($3);
						$$ = _NclMakeExpr($1,$3,Ncl_MODEXPR);
					}
	| expr OR expr 			{
						_NclValOnly($1);
						_NclValOnly($3);
						$$ = _NclMakeExpr($1,$3,Ncl_OREXPR);
					} 
	| expr AND expr			{			
						_NclValOnly($1);
						_NclValOnly($3);
						$$ = _NclMakeExpr($1,$3,Ncl_ANDEXPR);
					}
	| expr XOR expr			{
						_NclValOnly($1);
						_NclValOnly($3);
						$$ = _NclMakeExpr($1,$3,Ncl_XOREXPR);
					}
	| expr '<' expr			{
						_NclValOnly($1);
						_NclValOnly($3);
						$$ = _NclMakeExpr($1,$3,Ncl_LTSELECTEXPR);
					}
	| expr '>' expr			{
						_NclValOnly($1);
						_NclValOnly($3);
						$$ = _NclMakeExpr($1,$3,Ncl_GTSELECTEXPR);
					}
	| expr '+' expr			{
						_NclValOnly($1);
						_NclValOnly($3);
						$$ = _NclMakeExpr($1,$3,Ncl_PLUSEXPR);
					}
	| expr '-' expr			{
						_NclValOnly($1);
						_NclValOnly($3);
						$$ = _NclMakeExpr($1,$3,Ncl_MINUSEXPR);
					}
	| expr '*' expr			{
						_NclValOnly($1);
						_NclValOnly($3);
						$$ = _NclMakeExpr($1,$3,Ncl_MULEXPR);
					}
	| expr '#' expr			{
						_NclValOnly($1);
						_NclValOnly($3);
						$$ = _NclMakeExpr($1,$3,Ncl_MATMULEXPR);
					}
	| expr '/' expr			{
						_NclValOnly($1);
						_NclValOnly($3);
						$$ = _NclMakeExpr($1,$3,Ncl_DIVEXPR);
					}
	| expr '^' expr			{
						_NclValOnly($1);
						_NclValOnly($3);
						$$ = _NclMakeExpr($1,$3,Ncl_EXPEXPR);
					}
	| expr LE  expr			{
						_NclValOnly($1);
						_NclValOnly($3);
						$$ = _NclMakeExpr($1,$3,Ncl_LEEXPR);
					}
	| expr GE expr			{
						_NclValOnly($1);
						_NclValOnly($3);
						$$ = _NclMakeExpr($1,$3,Ncl_GEEXPR);
					}
	| expr GT expr			{
						_NclValOnly($1);
						_NclValOnly($3);
						$$ = _NclMakeExpr($1,$3,Ncl_GTEXPR);
					}
	| expr LT expr			{
						_NclValOnly($1);
						_NclValOnly($3);
						$$ = _NclMakeExpr($1,$3,Ncl_LTEXPR);
					}
	| expr EQ expr			{
						_NclValOnly($1);
						_NclValOnly($3);
						$$ = _NclMakeExpr($1,$3,Ncl_EQEXPR);
					}
	| expr NE expr			{
						_NclValOnly($1);
						_NclValOnly($3);
						$$ = _NclMakeExpr($1,$3,Ncl_NEEXPR);
					}
;

anysym : INTEGER {
		$$ = $1;
	}
	| FLOAT {
		$$ = $1;
	}
	| LONG {
		$$ = $1;
	}
	| DOUBLE {
		$$ = $1;
	}
	| BYTE {
		$$ = $1;
	}
	| CHARACTER {
		$$ = $1;
	}
	| GRAPHIC {
		$$ = $1;
	}
	| STRNG {
		$$ = $1;
	}
	| NUMERIC {
		$$ = $1;
	}
	| FILETYPE {
		$$ = $1;
	}
	| SHORT {
		$$ = $1;
	}
	| LOGICAL {
		$$ = $1;
	}
	| UNDEF {
		$$ = $1;
	}
	| VAR {
		$$ = $1;
	}
	| WHILE {
		$$ = $1;
	}
	| DO {
		$$ = $1;
	}
	| QUIT  {
		$$ = $1;
	}
	| NPROC {
		$$ = $1;
	}
	| PIPROC {
		$$ = $1;
	}
	| IPROC {
		$$ = $1;
	}
	| UNDEFFILEVAR {
		$$ = $1;
	}
	| BREAK {
		$$ = $1;
	}
	| NOPARENT {
		$$ = $1;
	}
	| BGIN {
		$$ = $1;
	}
	| END {
		$$ = $1;
	}
	| NFUNC {
		$$ = $1;
	}
	| IFUNC {
		$$ = $1;
	}
	| FDIM {
		$$ = $1;
	}
	| IF {
		$$ = $1;
	}
	| THEN {
		$$ = $1;
	}
	| VBLKNAME {
		$$ = $1;
	}
	| CONTINUE {
		$$ = $1;
	}
	| DFILE {
		$$ = $1;
	}
	| KEYFUNC {
		$$ = $1;
	}
	| KEYPROC {
		$$ = $1;
	}
	| ELSE {
		$$ = $1;
	}
	| EXTERNAL {
		$$ = $1;
	}
	| RETURN {
		$$ = $1;
	}
	| VSBLKGET {
		$$ = $1;
	}
	| NEW {
		$$ = $1;
	}
	| OBJVAR {
		$$ = $1;
	}
	| OBJTYPE {
		$$ = $1;
	}
	| RECORD {
		$$ = $1;
	}
	| VSBLKCREATE {
		$$ = $1;
	}
	| VSBLKSET {
		$$ = $1;
	}
	| LOCAL {
		$$ = $1;
	}
	| STOP {
		$$ = $1;
	}
	| NCLTRUE {
		$$ = $1;
	}
	| NCLFALSE {
		$$ = $1;
	}
	| DLIB {
		$$ = $1;
	}
;

primary : REAL				{
/*
* Note all of the structures created below the primary rule are special! They
* contain the ref_type field which is used to determine if the item
* is a parameter to a function or a procedure. The LP expr RP is an
* exception
*/
						$$ = _NclMakeIdnExpr(_NclMakeRealExpr($1,yytext));
					}
	| INT				{
						$$ = _NclMakeIdnExpr(_NclMakeIntExpr($1,yytext));
					}
	| NCLTRUE				{
						$$ = _NclMakeIdnExpr(_NclMakeLogicalExpr(1,yytext));
					}
	| NCLFALSE 			{
						$$ = _NclMakeIdnExpr(_NclMakeLogicalExpr(0,yytext));
					}
	| STRING			{
						$$ = _NclMakeIdnExpr(_NclMakeStringExpr($1));
					}
	| function			{	
						$$ = _NclMakeIdnExpr($1);
					}
	| identifier			{
						$$ = _NclMakeIdnExpr($1);
					}
	| array 		 	{
						$$ = _NclMakeIdnExpr($1);
					}
	| vcreate			{
						$$ = $1;
					}
	| LP expr RP			{ 
						$$ = $2;
					}
	| NEW LP expr ',' datatype ',' expr RP	{
						_NclValOnly($3);
						_NclValOnly($7);
						$$ = _NclMakeNewOp($3,$5,$7);
					}
	| NEW LP expr ',' datatype RP	{
						_NclValOnly($3);
						$$ = _NclMakeNewOp($3,$5,NULL);
					}
	| NCLNULL			{
						$$ = _NclMakeNULLNode();
					}
;
function:  IFUNC opt_arg_list		{
						NclSrcListNode *step;
						int count = 0;
					
						step = $2;
						while(step != NULL) {
							count++;
							step = step->next;
						}
						if(count != $1->u.procfunc->nargs) {
							is_error += 1;
							NhlPError(NhlFATAL,NhlEUNKNOWN,"syntax error: function %s expects %d arguments, got %d",$1->name,$1->u.procfunc->nargs,count);
							$$ = NULL;
						} else {
							$$ = _NclMakeFuncCall($1,$2,Ncl_INTRINSICFUNCCALL);
						}
					}
	| NFUNC opt_arg_list		{
						NclSrcListNode *step;
						int count = 0;
					
						step = $2;
						while(step != NULL) {
							count++;
							step = step->next;
						}
						if(count != $1->u.procfunc->nargs) {
							is_error += 1;
							NhlPError(NhlFATAL,NhlEUNKNOWN,"syntax error: function %s expects %d arguments, got %d",$1->name,$1->u.procfunc->nargs,count);
							$$ = NULL;
						} else {
							$$ = _NclMakeFuncCall($1,$2,Ncl_FUNCCALL);
						}
					}
	| IFUNC 				{
						if($1->u.procfunc->nargs != 0) {
							is_error += 1;
							NhlPError(NhlFATAL,NhlEUNKNOWN,"syntax error: function %s expects %d arguments, got %d",$1->name,$1->u.procfunc->nargs,0);
							$$ = NULL;
						} else {
							$$ = _NclMakeFuncCall($1,NULL,Ncl_INTRINSICFUNCCALL);
						}
					}
	| NFUNC 			{
						if($1->u.procfunc->nargs != 0) {
							is_error += 1;
							NhlPError(NhlFATAL,NhlEUNKNOWN,"syntax error: function %s expects %d arguments, got %d",$1->name,$1->u.procfunc->nargs,0);
							$$ = NULL;
						} else {
							$$ = _NclMakeFuncCall($1,NULL,Ncl_FUNCCALL);
						}
					}
	| DLIB COLON COLON anysym		{
						NclSymbol *s;
						if($1->u.package != NULL) {
							s = _NclLookUpInScope($1->u.package->scope,$4->name);
							if(s == NULL) {
								is_error += 1;
								NhlPError(NhlFATAL,NhlEUNKNOWN,"syntax error: procedure %s is not defined in package %s\n",$4->name,$1->name);
								$$ = NULL;
							} else if(s->type == IFUNC){
								if(s->u.procfunc->nargs != 0) {
									is_error += 1;
									NhlPError(NhlFATAL,NhlEUNKNOWN,"syntax error: function %s expects %d arguments, got %d",s->name,s->u.procfunc->nargs,0);
									$$ = NULL;
								} else {
									$$ = _NclMakeFuncCall(s,NULL,Ncl_INTRINSICFUNCCALL); 
								}
							} else {
								NhlPError(NhlFATAL,NhlEUNKNOWN,"syntax error: %s is not a function in package %s\n",$4->name,$1->name);
								$$ = NULL;
							}
						} else {
							$$ = NULL;
						}
					}			
	| DLIB COLON COLON anysym opt_arg_list	{
						NclSrcListNode *step;
						int count = 0;
						
						NclSymbol *s;
						if($1->u.package != NULL) {
							s = _NclLookUpInScope($1->u.package->scope,$4->name);
							if(s == NULL) {
								is_error += 1;
								NhlPError(NhlFATAL,NhlEUNKNOWN,"syntax error: procedure %s is not defined in package %s\n",$4->name,$1->name);
								$$ = NULL;
							} else if(s->type == IFUNC){
								step = $5;
								while(step != NULL) {
									count++;
									step = step->next;
								}
								if(count != s->u.procfunc->nargs) {
									is_error += 1;
									NhlPError(NhlFATAL,NhlEUNKNOWN,"syntax error: function %s expects %d arguments, got %d",s->name,s->u.procfunc->nargs,count);
									$$ = NULL;
								} else {
									$$ = _NclMakeFuncCall(s,$5,Ncl_INTRINSICFUNCCALL); 
								}
                                                	} else {
                                                        	NhlPError(NhlFATAL,NhlEUNKNOWN,"syntax error: %s is not a function in package %s\n",$4->name,$1->name);
                                                        	$$ = NULL;
                                                	}
	
						} else {
							$$ = NULL;
						}
					}
;
array : LPSLSH expr_list SLSHRP	 { 
							$$ = _NclMakeArrayNode($2);
							 
					}

;
expr_list :  expr				{	
							$$ = _NclMakeRowList();
							$$->list = _NclMakeNewListNode();
							$$->list->next = NULL;
							$$->list->node = $1;
							$$->currentitem= NULL; 
							$$->nelem = 1;
						}
	| expr_list ',' expr   		{ 
						/* pushed on backwards so they can be popped of in correct order*/
							if($1 == NULL) {
								$$ = _NclMakeRowList();
								$$->nelem = 1;
								$$->list = _NclMakeNewListNode();
								$$->list->next = NULL;
								$$->list->node = $1;
								$$->currentitem= NULL; 
								$$->nelem = 1;
							} else {
								NclSrcListNode *tmp;

								tmp = _NclMakeNewListNode();
								tmp->next = $1->list;
								tmp->node = $3;
								$1->list = tmp;
								$1->nelem++;
								$$ = $1;
							}
						}
;
%%
yyerror
#if __STDC__
(char *s)
#else 
(s)
	char *s;
#endif
{
	extern int is_error;
	int i,len;
	char error_buffer[1024];
	

	is_error += 1;

	if(is_error < NCL_MAX_ERROR) {
		if(yytext[0] == '\n') {
			sprintf(error_buffer,"%s\n",cur_line_text);
			len = strlen(error_buffer);
			for(i=0; i<last_line_length-1;i++) sprintf(&(error_buffer[len+i]),"-");
			sprintf(&(error_buffer[len+last_line_length-1]),"^\n");
			if(loading > 0) {
				NhlPError(NhlFATAL,NhlEUNKNOWN,"%s: line %d in file %s before or near \\n \n%s\n",s,cur_line_number + 1,cur_load_file,error_buffer);
			} else if(cmd_line){
				NhlPError(NhlFATAL,NhlEUNKNOWN,"%s: line %d before or near \\n \n%s\n",s,cur_line_number,error_buffer);
			} else {
				NhlPError(NhlFATAL,NhlEUNKNOWN,"%s: line %d before or near \\n \n%s\n",s,cur_line_number+1,error_buffer);
			} 
		} else {
			sprintf((char*)&(error_buffer[0]),"%s\n",cur_line_text);
			len = strlen(error_buffer);
			for(i=0; i<cur_line_length-1;i++) sprintf(&(error_buffer[len+i]),"-");
			sprintf(&(error_buffer[len+cur_line_length-1]),"^\n");
			if(loading > 0) {
				NhlPError(NhlFATAL,NhlEUNKNOWN,"%s: line %d in file %s before or near %s \n%s\n",s,cur_line_number,cur_load_file,yytext,error_buffer);
			} else if(cmd_line){
				NhlPError(NhlFATAL,NhlEUNKNOWN,"%s: line %d before or near %s \n%s\n",s,cur_line_number,yytext,error_buffer);
			} else {
				NhlPError(NhlFATAL,NhlEUNKNOWN,"%s: line %d before or near %s \n%s\n",s,cur_line_number+1,yytext,error_buffer);
			}
		}
	} else if((is_error == NCL_MAX_ERROR)&&(cmd_line != 2)) {
			NhlPError(NhlFATAL,NhlEUNKNOWN,"Maximum number of errors exceeded, terminating");
			exit(0);
	} else {
/*
* GUI STUFF
*/
	}
	return(0);
}
