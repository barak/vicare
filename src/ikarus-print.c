/*
 * Ikarus Scheme -- A compiler for R6RS Scheme.
 * Copyright (C) 2006,2007,2008  Abdulaziz Ghuloum
 * Modified by Marco Maggi <marco.maggi-ipsu@poste.it>
 *
 * This program is free software:  you can redistribute it and/or modify
 * it under  the terms of  the GNU General  Public License version  3 as
 * published by the Free Software Foundation.
 *
 * This program is  distributed in the hope that it  will be useful, but
 * WITHOUT  ANY   WARRANTY;  without   even  the  implied   warranty  of
 * MERCHANTABILITY  or FITNESS FOR  A PARTICULAR  PURPOSE.  See  the GNU
 * General Public License for more details.
 *
 * You should  have received  a copy of  the GNU General  Public License
 * along with this program.  If not, see <http://www.gnu.org/licenses/>.
 */


/** --------------------------------------------------------------------
 ** Headers.
 ** ----------------------------------------------------------------- */

#include "internals.h"

static void print_object (FILE* fh, ikptr x, int nested_level);

const static char* char_string[128] = {
  "#\\nul","#\\soh","#\\stx","#\\etx","#\\eot","#\\enq","#\\ack","#\\bel",
  "#\\bs", "#\\tab","#\\newline", "#\\vt", "#\\ff", "#\\return", "#\\so",
  "#\\si",
  "#\\dle","#\\dc1","#\\dc2","#\\dc3","#\\dc4","#\\nak","#\\syn","#\\etb",
  "#\\can","#\\em", "#\\sub","#\\esc","#\\fs", "#\\gs", "#\\rs", "#\\us",
  "#\\space","#\\!","#\\\"","#\\#","#\\$","#\\%","#\\&","#\\'",
  "#\\(","#\\)","#\\*","#\\+","#\\,","#\\-","#\\.","#\\/",
  "#\\0","#\\1","#\\2","#\\3","#\\4","#\\5","#\\6","#\\7",
  "#\\8","#\\9","#\\:","#\\;","#\\<","#\\=","#\\>","#\\?",
  "#\\@","#\\A","#\\B","#\\C","#\\D","#\\E","#\\F","#\\G",
  "#\\H","#\\I","#\\J","#\\K","#\\L","#\\M","#\\N","#\\O",
  "#\\P","#\\Q","#\\R","#\\S","#\\T","#\\U","#\\V","#\\W",
  "#\\X","#\\Y","#\\Z","#\\[","#\\\\","#\\]","#\\^","#\\_",
  "#\\`","#\\a","#\\b","#\\c","#\\d","#\\e","#\\f","#\\g",
  "#\\h","#\\i","#\\j","#\\k","#\\l","#\\m","#\\n","#\\o",
  "#\\p","#\\q","#\\r","#\\s","#\\t","#\\u","#\\v","#\\w",
  "#\\x","#\\y","#\\z","#\\{","#\\|","#\\}","#\\~","#\\del"};


/** --------------------------------------------------------------------
 ** Utilities.
 ** ----------------------------------------------------------------- */

void
ik_fprint (FILE* fh, ikptr x)
{
  print_object(fh, x, 0);
}
void
ik_print (ikptr x)
{
  print_object(stderr, x, 0);
  fprintf(stderr, "\n");
}
void
ik_print_no_newline (ikptr x)
{
  print_object(stderr, x, 0);
}

ikptr
ikrt_print_emergency (ikptr s_bv, ikpcb *pcb)
{
  fprintf(stderr, "\nemergency!!! %s\n\n", IK_BYTEVECTOR_DATA_CHARP(s_bv));
  return IK_VOID;
}

ikptr
ikrt_scheme_print (ikptr x, ikpcb * pcb)
/* This can be called from Scheme. */
{
  print_object(stderr, x, 0);
  fprintf(stderr, "\n");
  return IK_VOID;
}


static void
print_indentation (FILE* fh, int nested_level)
{
  if (nested_level) {
    fprintf(fh, "\t");
  }
  for (; nested_level; --nested_level)
    fprintf(fh, "   ");
}
static void
print_object (FILE* fh, ikptr x, int nested_level)
{
#define PRINT_OBJECT(F,X)	print_object((F),(X),1+nested_level)
#define PRINT_INDENTATION()	print_indentation(fh, 1+nested_level)
  if (IK_IS_FIXNUM(x)) {
    fprintf(fh, "fixnum=%ld", IK_UNFIX(x));
  }
  else if (x == IK_FALSE_OBJECT) {
    fprintf(fh, "bool=#f");
  }
  else if (x == IK_TRUE_OBJECT) {
    fprintf(fh, "bool=#t");
  }
  else if (x == IK_NULL_OBJECT) {
    fprintf(fh, "null=()");
  }
  else if (IK_IS_CHAR(x)) {
    unsigned long i = ((long)x) >> char_shift;
    if (i < 128)
      fprintf(fh, "char=%s", char_string[i]);
    else
      fprintf(fh, "char=#\\x%lx", i);
  }
  else if (IK_IS_CODE(x)) {
    fprintf(fh, "code={x=0x%016lx, annotation=", x);
    PRINT_OBJECT(fh, IK_REF(x, off_code_annotation));
    fprintf(fh, "}");
  }
  else if (IK_IS_CONTINUATION(x)) {
    ikcont *	kont = IK_CONTINUATION_STRUCT(x);
    fprintf(fh, "continuation={x=0x%016lx, top=0x%016lx, size=%ld, next=0x%016lx}",
	    x, kont->top, kont->size, kont->next);
  }
  else if (IK_IS_SYSTEM_CONTINUATION(x)) {
    ikcont *	kont = IK_CONTINUATION_STRUCT(x);
    fprintf(fh,
	    "system-continuation={x=0x%016lx, top=0x%016lx, size=%ld (unused), next=0x%016lx}",
	    x, kont->top, kont->size, kont->next);
  }
  else if (IK_TAGOF(x) == vector_tag) {
    ikptr first_word = IK_REF(x, off_vector_length);
    if (IK_IS_FIXNUM(first_word)) {
      ikptr len = first_word;
      if (len == 0) {
        fprintf(fh, "vector=#()");
      } else {
        fprintf(fh, "vector=#(");
        ikptr data = x + off_vector_data;
        PRINT_OBJECT(fh, IK_REF(data, 0));
        ikptr i = (ikptr)wordsize;
        while (i<len) {
          fprintf(fh, " ");
          PRINT_OBJECT(fh, IK_REF(data,i));
          i += wordsize;
        }
        fprintf(fh, ")");
      }
    } else if (first_word == symbol_tag) {
      ikptr str   = IK_REF(x, off_symbol_record_string);
      ikptr fxlen = IK_REF(str, off_string_length);
      int   len   = IK_UNFIX(fxlen);
      int * data  = (int*)(str + off_string_data);
      int   i;
      fprintf(fh, "symbol=");
      for (i=0; i<len; i++) {
        char c = (data[i]) >> char_shift;
        fprintf(fh, "%c", c);
      }
    } else if (IK_TAGOF(first_word) == rtd_tag) {
      ikptr	s_rtd		 = IK_REF(x, off_record_rtd);;
      ikptr	number_of_fields = IK_UNFIX(IK_REF(s_rtd, off_rtd_length));
      int	i;
      if (s_rtd == ik_the_pcb()->base_rtd) {
	fprintf(fh, "#[rtd: ");
      } else {
	fprintf(fh, "#[struct nfields=%ld rtd=", number_of_fields);
	PRINT_OBJECT(fh, IK_REF(s_rtd, off_rtd_name));
	fprintf(fh, ": ");
      }
      for (i=0; i<number_of_fields; ++i) {
	if (i) fprintf(fh, ", ");
	PRINT_OBJECT(fh, IK_FIELD(x, i));
      }
      fprintf(fh, "]");
    } else
      fprintf(fh, "#<unknown first_word=%p>", (void*)first_word);
  }
  else if (IK_IS_CLOSURE(x)) {
    long	freec = IK_CLOSURE_NUMBER_OF_FREE_VARS(x);
    long	i;
    fprintf(fh, "#<closure num_of_free_vars=%ld,\n",
	    freec);
    for (i=0; i<freec; ++i) {
      PRINT_INDENTATION();
      fprintf(fh, "free[%ld]=", i);
      PRINT_OBJECT(fh, IK_CLOSURE_FREE_VAR(x, i));
      fprintf(fh, "\n");
    }
    PRINT_INDENTATION();
    PRINT_OBJECT(fh, IK_CLOSURE_CODE_OBJECT(x));
    fprintf(fh, ">");
  }
  else if (IK_IS_PAIR(x)) {
    fprintf(fh, "pair=(");
    print_object(fh, IK_CAR(x), 0);
    fprintf(fh, " . ");
    PRINT_OBJECT(fh, IK_CDR(x));
    fprintf(fh, ")");
  }
  else if (IK_TAGOF(x) == string_tag) {
    ikptr fxlen = IK_REF(x, off_string_length);
    int   len   = IK_UNFIX(fxlen);
    int * data  = (int*)(x + off_string_data);
    int   i;
    fprintf(fh, "string=\"");
    for(i=0; i<len; i++) {
      char c = (data[i]) >> char_shift;
      if ((c == '\\') || (c == '"')) {
        fprintf(fh, "\\");
      }
      fprintf(fh, "%c", c);
    }
    fprintf(fh, "\"");
  }
  else if (IK_TAGOF(x) == bytevector_tag) {
    ikptr          fxlen = IK_REF(x, off_bytevector_length);
    int            len   = IK_UNFIX(fxlen);
    unsigned char* data  = (unsigned char*)(x + off_bytevector_data);
    fprintf(fh, "bytevector=#vu8(");
    int i;
    for(i=0; i<(len-1); i++) {
      fprintf(fh, "%d ", data[i]);
    }
    if (i < len) {
      fprintf(fh, "%d", data[i]);
    }
    fprintf(fh, ")");
  }
  else if (IK_FORWARD_PTR == x) {
    fprintf(fh, "#<forward-ptr>");
  }
  else if (IK_EOF_OBJECT == x) {
    fprintf(fh, "#<eof>");
  }
  else if (IK_VOID_OBJECT == x) {
    fprintf(fh, "#<void>");
  }
  else if (IK_UNBOUND_OBJECT == x) {
    fprintf(fh, "#<unbound-object>");
  }
  else if (IK_BWP_OBJECT == x) {
    fprintf(fh, "#<bwp-object>");
  }
  else {
    fprintf(fh, "#<unknown 0x%016lx>", x);
  }
}

void
ik_print_stack_frame (FILE * fh, ikptr top)
{
  ikptr		single_value_rp	= IK_REF(top, 0);
  ikptr		framesize	= IK_CALLTABLE_FRAMESIZE(single_value_rp);
  ikptr		args_size;
  ikptr		argc;
  ikptr		s_code;
  int		i;
  if (framesize) {
    args_size	= framesize - wordsize;
  } else {
    framesize	= IK_REF(top, wordsize);
    args_size	= framesize - wordsize - wordsize;
  }
  argc		= args_size / wordsize;
  s_code	= ik_stack_frame_top_to_code_object(top);
  fprintf(fh, "\tcall frame: top=0x%016lx, framesize=%ld, args count=%ld\n",
	  top, framesize, argc);
  fprintf(fh, "\tcode object: ");
  ik_fprint(fh, s_code);
  for (i=0; i<argc; ++i) {
    fprintf(fh, "\n\targ %d=", i);
    ik_fprint(fh, IK_REF(top, wordsize + i * wordsize));
  }
  fprintf(fh, "\n");
}

void
ik_print_stack_frame_code_objects (FILE * fh, int max_num_of_frames, ikpcb * pcb)
/* Visit  the current  Scheme  stack  printing to  FH  the code  objects
   referenced  by the  stack  frames.  At  most visit  MAX_NUM_OF_FRAMES
   frames (to avoid printing too much output). */
{
  int		i;
  ikptr		top = pcb->frame_pointer;
  ikptr		end = pcb->frame_base - wordsize;
  for (i=0; (i <= max_num_of_frames) && (top < end); ++i) {
    ikptr	single_value_rp	= IK_REF(top, 0);
    ikptr	framesize	= IK_CALLTABLE_FRAMESIZE(single_value_rp);
    if (0 == framesize) {
      framesize = IK_REF(top, wordsize);
    }
    fprintf(fh, "stack code object %d: ", i);
    ik_fprint(fh, ik_stack_frame_top_to_code_object(top));
    fprintf(fh, "\n");
    top += framesize;
  }
}

/* end of file*/
