/**********************************************************************
  $Header$

  Grammar definition for input files defining an NFA

 *********************************************************************/

/* COPYRIGHT */

%{
#include "n2d.h"

static Block *curblock = NULL; /* Current block being built */
static State *curstate = NULL; /* Current state being worked on */
static State *addtostate = NULL; /* Current state (incl ext) to which transitions are added */
static struct Abbrev *curabbrev = NULL; /* Current definition being worked on */

/* Prefix set by prefix command */
char *prefix = NULL;

State *get_curstate(void) { return curstate; }

%}

%union {
    char *s;
    int i;
    Stringlist *sl;
}


%token STRING STATE TOKENS PREFIX ARROW PIPE BLOCK ENDBLOCK COLON EQUAL SEMICOLON
%token ABBREV DEFINE
%type<s> STRING option
%type<sl> option_seq transition_seq

%%

all : decl_seq ;

decl_seq : /* empty */ | decl_seq decl ;

decl : block_decl | tokens_decl | prefix_decl | abbrev_decl ;

/* Don't invalidate curstate at the end, this is the means of working out the
   starting state of the NFA */
block_decl : block1 block2 { fixup_state_refs(curblock); curblock = NULL; } ;

block1 : BLOCK STRING { curblock = lookup_block($2, CREATE_MUST_NOT_EXIST); addtostate = curstate = NULL; } ;

block2 : instance_decl_seq state_decl_seq ENDBLOCK ;

prefix_decl : PREFIX STRING { prefix = $2; };

tokens_decl : TOKENS token_seq ;

abbrev_decl : ABBREV STRING { curabbrev = create_abbrev($2); }
              EQUAL string_pipe_seq
            ;

token_seq : token_seq token | token ;

string_pipe_seq : string_pipe_seq PIPE STRING { add_tok_to_abbrev(curabbrev, $3); }
                |                      STRING { add_tok_to_abbrev(curabbrev, $1); }
                ;

token : STRING { (void) lookup_token($1, CREATE_MUST_NOT_EXIST); }

instance_decl_seq : /* empty */ | instance_decl_seq instance_decl ;

state_decl_seq : /* empty */ | state_decl_seq state_decl ;

state_decl : STATE STRING { addtostate = curstate = lookup_state(curblock, $2, CREATE_OR_USE_OLD); } sdecl_seq ;

sdecl_seq : /* empty */ | sdecl_seq sdecl ;

sdecl : transition_decl ;

instance_decl : STRING COLON STRING { instantiate_block(curblock, $3 /* master_block_name */, $1 /* instance_name */ ); } ;

transition_decl : transition_seq ARROW STRING { add_transitions(addtostate, $1, $3); 
                                                addtostate = curstate; }
                | transition_seq EQUAL STRING { addtostate = add_transitions_to_internal(curblock, addtostate, $1);
                                                add_exit_value(addtostate, $3);
                                                addtostate = curstate; }
                ;

transition_seq : option_seq { $$ = $1; }
               | transition_seq SEMICOLON option_seq { addtostate = add_transitions_to_internal(curblock, addtostate, $1); $$ = $3; }
               ;

option_seq : option { $$ = add_token(NULL, $1); }
           | option_seq PIPE option { $$ = add_token($1, $3); } ;

option : STRING 
       | /* empty */ { $$ = NULL; }
       ;


