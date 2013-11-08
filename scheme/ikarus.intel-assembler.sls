;;;Ikarus Scheme -- A compiler for R6RS Scheme.
;;;Copyright (C) 2006,2007,2008  Abdulaziz Ghuloum
;;;Modified by Marco Maggi.
;;;
;;;This program is free software:  you can redistribute it and/or modify
;;;it under  the terms of  the GNU General  Public License version  3 as
;;;published by the Free Software Foundation.
;;;
;;;This program is  distributed in the hope that it  will be useful, but
;;;WITHOUT  ANY   WARRANTY;  without   even  the  implied   warranty  of
;;;MERCHANTABILITY or  FITNESS FOR  A PARTICULAR  PURPOSE.  See  the GNU
;;;General Public License for more details.
;;;
;;;You should  have received a  copy of  the GNU General  Public License
;;;along with this program.  If not, see <http://www.gnu.org/licenses/>.

#!r6rs
(library (ikarus.intel-assembler)
  (export
    assemble-sources
    code-entry-adjustment
    assembler-property-key)
  (import (except (ikarus)
		  fixnum-width
		  greatest-fixnum
		  least-fixnum
		  )
    (except (ikarus.code-objects)
	    procedure-annotation)
    (vicare unsafe operations)
    (vicare arguments validation)
    (prefix (vicare platform words)
	    words.)
    (vicare language-extensions syntaxes))

  (include "ikarus.wordsize.scm")


;;;; Introduction
;;
;;As reference for  i686 instructions we can look at  (URL last verified
;;on Oct 9, 2012):
;;
;;   Intel(R)  Architecture  Software   Developer's  Manual,  Volume  2:
;;   Instruction Set Reference Manual
;;
;;   <http://www.intel.com/design/intarch/manuals/243191.htm>
;;
;;The entry point in the  assembler is the function ASSEMBLE-SOURCES: it
;;compiles  assembly code  into binary  code stored  in a  code objects;
;;every call to ASSEMBLE-SOURCES can generate a list of code objects.
;;
;;Assembly code is  represented by a symbolic expression; we  can take a
;;look  at  the assembly  by  using  "--print-assembly" option  for  the
;;executable "vicare".


;;;; Assembly examples

;;Let's consider the library:
#|
   (library (proof)
     (export alpha)
     (import (vicare))
     (define (alpha)
       123))
|#
;;internally it is converted to something like:
#|
   (letrec ((alpha_0 (lambda () '123)))
     (void))
|#
;;and the associated assembly symbolic  expression for a 32-bit platform
;;is:
#|
   (name (alpha "var/tmp//proof.sls" . 74))
   (label L2)
   (cmpl 0 %eax)
   (jne (label L3))
   (label L4)
   (movl 492 %eax)
   (ret)
   (label L3)
   (jmp (label SL_invalid_args))
   (nop)
|#
;;where we see:
;;
;;**The label "L2" is the entry  point.
;;
;;**The  number of  required  arguments  is zero,  the  number of  given
;;  arguments is already stored in %EAX: if more than zero arguments are
;;  present, jump to "L3".
;;
;;**The fixnum 123 is encoded as raw exact integer:
;;
;;    492 = 123 * 4 = 123 << 2
;;
;;  such raw integer is loaded in %EAX.
;;
;;**The return value is computed and ready: return to the caller.
;;
;;**If the  wrong number of arguments  was given: jump to  the far label
;;  "SL_invalid_args".
;;


;;;; helpers

(define (fold func init ls)
  (if (null? ls)
      init
    (func ($car ls) (fold func init ($cdr ls)))))

(define-syntax with-args
  ;;Expect ?X to be an expression evaluating to a list of 2 values; bind
  ;;these values  to ?A0 and  ?A1 then evaluate  the ?BODY forms  in the
  ;;region of the bindings.
  ;;
  (syntax-rules (lambda)
    ((_ ?x (lambda (?a0 ?a1) ?body0 . ?body))
     (let ((t ?x))
       (if (pair? t)
           (let ((t ($cdr t)))
             (if (pair? t)
                 (let ((?a0 ($car t))
		       (t   ($cdr t)))
                   (if (pair? t)
		       (let ((?a1 ($car t)))
			 (if (null? ($cdr t))
			     (let ()
			       ?body0 . ?body)
			   (die 'with-args "too many args")))
		     (die 'with-args "too few args")))
	       (die 'with-args "too few args")))
	 (die 'with-args "too few args"))))))

(define-syntax byte
  ;;Expect  ?X to  be  an  expression evaluating  to  an exact  integer;
  ;;extract and return the 8 least significant bits from the integer.
  ;;
  (syntax-rules ()
    ((_ ?x)
     (let ((t ?x))
       (if (or (fixnum? t)
	       (bignum? t))
           (bitwise-and t 255)
	 (error 'byte "invalid" t '(byte ?x)))))))

(define-syntax define-entry-predicate
  (syntax-rules ()
    ((_ ?who ?symbol)
     (define (?who x)
       (and (pair? x)
	    (eq? ($car x) '?symbol))))))


;;;; constants

(define-constant const.wordsize-bitmask
  ;;On 32-bit platforms: this  is an exact integer of 32  bits set to 1.
  ;;On 64-bit platforms: this is an exact integer of 64 bits set to 1.
  ;;
  (- (expt 2 (* wordsize 8)) 1))

;;; --------------------------------------------------------------------

(define *cogen*
  (gensym "*cogen*"))

(define (assembler-property-key)
  *cogen*)

(define register-mapping
;;;   reg  cls  idx  REX.R
  '((%eax   32    0  #f)
    (%ecx   32    1  #f)
    (%edx   32    2  #f)
    (%ebx   32    3  #f)
    (%esp   32    4  #f)
    (%ebp   32    5  #f)
    (%esi   32    6  #f)
    (%edi   32    7  #f)
    (%r8    32    0  #t)
    (%r9    32    1  #t)
    (%r10   32    2  #t)
    (%r11   32    3  #t)
    (%r12   32    4  #t)
    (%r13   32    5  #t)
    (%r14   32    6  #t)
    (%r15   32    7  #t)
    (%al     8    0  #f)
    (%cl     8    1  #f)
    (%dl     8    2  #f)
    (%bl     8    3  #f)
    (%ah     8    4  #f)
    (%ch     8    5  #f)
    (%dh     8    6  #f)
    (%bh     8    7  #f)
    (/0      0    0  #f)
    (/1      0    1  #f)
    (/2      0    2  #f)
    (/3      0    3  #f)
    (/4      0    4  #f)
    (/5      0    5  #f)
    (/6      0    6  #f)
    (/7      0    7  #f)
    (xmm0  xmm    0  #f)
    (xmm1  xmm    1  #f)
    (xmm2  xmm    2  #f)
    (xmm3  xmm    3  #f)
    (xmm4  xmm    4  #f)
    (xmm5  xmm    5  #f)
    (xmm6  xmm    6  #f)
    (xmm7  xmm    7  #f)
    (%r8l    8    0  #t)
    (%r9l    8    1  #t)
    (%r10l   8    2  #t)
    (%r11l   8    3  #t)
    (%r12l   8    4  #t)
    (%r13l   8    5  #t)
    (%r14l   8    6  #t)
    (%r15l   8    7  #t)
    ))


;;;; arguments validation


(module stuff
  (register-index
   reg8?		reg32?
   xmmreg?		reg?
   reg-requires-REX?
   word			reloc-word
   reloc-word+		byte?
   mem?			small-disp?
   CODE			CODE+r
   ModRM		IMM32
   IMM			IMM8
   imm?			foreign?
   imm8?		label?
   label-address?	label-name
   immediate-int?
   obj?			obj+?
   CODErri		CODErr
   RegReg		IMM*2
   SIB			imm32?)

  (define-argument-validation (immediate-int who obj)
    (immediate-int? obj)
    (procedure-argument-violation who "expected immediate integer as argument" obj))


  (define (register-index x)
    (cond ((assq x register-mapping)
	   => caddr)
	  (else
	   (die 'register-index "not a register" x))))

  (let-syntax ((define-register-mapping-predicate
		 (syntax-rules ()
		   ((_ ?who ?val)
		    (define (?who x)
		      (cond ((assq x register-mapping)
			     => (lambda (x)
				  (eqv? ($cadr x) ?val)))
			    (else #f)))))))
    (define-register-mapping-predicate reg8?   8)
    (define-register-mapping-predicate reg32?  32)
    (define-register-mapping-predicate xmmreg? 'xmm))

  (define-inline (reg? x)
    (assq x register-mapping))

  (define (reg-requires-REX? x)
    (cond ((assq x register-mapping)
	   => cadddr)
	  (else
	   (error 'reg-required-REX? "not a reg" x))))

  (define-inline (word x)
    (cons 'word x))

  (define-inline (reloc-word x)
    (cons 'reloc-word x))

  (define-inline (reloc-word+ x d)
    (cons* 'reloc-word+ x d))

  (define (byte? x)
    (and (fixnum? x)
	 ($fx>= x -128)
	 ($fx<= x +127)))

  (define-entry-predicate mem? disp)

  (define (small-disp? x)
    (and (mem? x)
	 (byte? ($cadr x))))

  (define (CODE n ac)
    (cons (byte n) ac))

  (define (CODE+r n r ac)
    (cons (byte ($fxlogor n (register-index r)))
	  ac))

  (define (ModRM mod reg r/m ac)
    (cons (byte ($fxlogor (register-index r/m)
			  ($fxlogor ($fxsll (register-index reg) 3)
				    ($fxsll mod 6))))
	  (if (and (not ($fx= mod 3)) (eq? r/m '%esp))
	      (cons (byte #x24) ac)
	    ac)))

  (define (IMM32 n ac)
    (boot.case-word-size
     ((32)
      (IMM n ac))
     ((64)
      (cond ((imm32? n)
	     ;;Prepend  to the  accumulator AC  a 32-bit  immediate value,
	     ;;least significant byte first.
	     ;;
	     ;;  #xDDCCBBAA -> `(#xAA #xBB #xCC #xDD . ,ac)
	     ;;
	     ;;SRA = shift right arithmetic.
	     (cons* (byte n)
		    (byte (sra n 8))
		    (byte (sra n 16))
		    (byte (sra n 24))
		    ac))
	    ((label? n)
	     (let ((LN (label-name n)))
	       `((,(if (local-label? LN) 'local-relative 'relative) . ,LN)
		 . ,ac)))
	    (else
	     (die 'IMM32 "invalid" n))))))
  ;;The following  is the original Ikarus's  IMM32 implementation.  (Marco
  ;;Maggi; Oct 8, 2012)
  ;;
  ;; (define (IMM32 n ac)
  ;;   (cond (($fx= wordsize 4)
  ;; 	 (IMM n ac))
  ;; 	((imm32? n)
  ;; 	 (cons* (byte n)
  ;; 		(byte (sra n 8))
  ;; 		(byte (sra n 16))
  ;; 		(byte (sra n 24))
  ;; 		ac))
  ;; 	((label? n)
  ;; 	 (cond ((local-label? (label-name n))
  ;; 		(cons `(local-relative . ,(label-name n))
  ;; 		      ac))
  ;; 	       (else
  ;; 		(cons `(relative       . ,(label-name n))
  ;; 		      ac))))
  ;; 	(else
  ;; 	 (die 'IMM32 "invalid" n))))

  (define (IMM n ac)
    (cond ((immediate-int? n)
	   ;;Prepend  to the  accumulator  AC an  immediate integer  value
	   ;;least significant bytes first.
	   ;;
	   ;;  #xDDCCBBAA -> `(#xAA #xBB #xCC #xDD . ,ac)
	   ;;
	   (boot.case-word-size
	    ((32)
	     (cons* (byte n)
		    (byte (sra n 8))
		    (byte (sra n 16))
		    (byte (sra n 24))
		    ac))
	    ((64)
	     (cons* (byte n)
		    (byte (sra n 8))
		    (byte (sra n 16))
		    (byte (sra n 24))
		    (byte (sra n 32))
		    (byte (sra n 40))
		    (byte (sra n 48))
		    (byte (sra n 56))
		    ac))))
	  ((obj? n)
	   (let ((v ($cadr n)))
	     (cons (if (immediate? v)
		       (word v)
		     (reloc-word v))
		   ac)))
	  ((obj+? n)
	   (let ((v ($cadr  n))
		 (d ($caddr n)))
	     (cons (reloc-word+ v d) ac)))
	  ((label-address? n)
	   (cons `(label-addr	. ,(label-name n))
		 ac))
	  ((foreign? n)
	   (cons `(foreign-label	. ,(label-name n))
		 ac))
	  ((label? n)
	   (let ((LN (label-name n)))
	     `((,(if (local-label? LN) 'local-relative 'relative) . ,LN)
	       . ,ac)))
	  (else
	   (die 'IMM "invalid" n))))

  (define (IMM8 n ac)
    ;;Prepend  to the  accumulator AC  a fixnum  representing the  byte N,
    ;;which is an immediate 8-bit value.
    ;;
    (define who 'IMM8)
    (with-arguments-validation (who)
	((immediate-int	n))
      (cons (byte n) ac)))

  (define (imm? x)
    (or (immediate-int?	x)
	(obj?		x)
	(obj+?		x)
	(label-address?	x)
	(foreign?		x)
	(label?		x)))

  (define-entry-predicate foreign? foreign-label)

  (define-inline (imm8? x)
    (byte? x))

  (define-entry-predicate label? label)
  (define-entry-predicate label-address? label-address)

  (define-inline (label-name x)
    ($cadr x))

  (define-inline (immediate-int? ?x)
    (let ((X ?x))
      (or (fixnum? X)
	  (bignum? X))))

  (define-entry-predicate obj?	obj)
  (define-entry-predicate obj+?	obj+)

  (define (CODErri c d s i ac)
    ;;Generate code for register+register+immediate operations?
    ;;
    (cond ((imm8? i)
	   (CODE c (ModRM 1 d s (IMM8 i ac))))
	  ((imm? i)
	   (CODE c (ModRM 2 d s (IMM i ac))))
	  (else
	   (die 'CODErri "invalid i" i))))

  (define (CODErr c r1 r2 ac)
    ;;Generate code for register+register operations?
    ;;
    (CODE c (ModRM 3 r1 r2 ac)))

  (define (RegReg r1 r2 r3 ac)
    (cond ((eq? r3 '%esp)
	   (die 'assembler "BUG: invalid src %esp"))
	  ((eq? r1 '%ebp)
	   (die 'assembler "BUG: invalid src %ebp"))
	  (else
	   (cons* (byte ($fxlogor 4                   ($fxsll (register-index r1) 3)))
		  (byte ($fxlogor (register-index r2) ($fxsll (register-index r3) 3)))
		  ac))))

  (define (IMM*2 i1 i2 ac)
    (cond ((and (immediate-int? i1)
		(obj? i2))
	   (let ((d i1)
		 (v ($cadr i2)))
	     (cons (reloc-word+ v d) ac)))
	  ((and (immediate-int? i2)
		(obj? i1))
	   (IMM*2 i2 i1 ac))
	  ((and (immediate-int? i1)
		(immediate-int? i2))
	   (IMM (bitwise-and (+ i1 i2) const.wordsize-bitmask)
		ac))
	  (else
	   (die 'assemble "invalid IMM*2" i1 i2))))

  (define (SIB s i b ac)
    (cons (byte ($fxlogor (register-index b)
			  ($fxlogor ($fxsll (register-index i) 3)
				    ($fxsll s 6))))
	  ac))

  (define (imm32? x)
    (boot.case-word-size
     ((32)
      (imm? x))
     ((64)
      (and (immediate-int? x)
	   (<= (words.least-s32) x (words.greatest-s32))))))

  #| end of module |# )


(module (convert-instructions local-label?)
  (module (label-name)
    (import stuff))

  ;;List  of symbols  representing  local labels.
  (define local-labels
    (make-parameter '()))

  (define (local-label? x)
    ;;FIXME Would  this be significantly  faster with an  EQ? hashtable?
    ;;Or is the number of local labels usually small?  (Marco Maggi; Oct
    ;;9, 2012)
    ;;
    (and (memq x (local-labels)) #t))

  (define (convert-instructions ls)
    (parametrise ((local-labels (%uncover-local-labels ls)))
      (fold %convert-single-sexp '() ls)))

  (define who 'convert-instruction)

  (define (%convert-single-sexp assembly-sexp accum)
    ;;Convert  ASSEMBLY-SEXP into  a sequence  of fixnums  (representing
    ;;octets) and sexps prepended to  the accumulator list ACCUM; return
    ;;the new accumulator list.
    ;;
    ;;The items  prepended to ACCUM can  be fixnums or entries  like the
    ;;following:
    ;;
    ;;	(label . ?symbol)
    ;;  (label-addr . ?symbol)
    ;;  (current-frame-offset)
    ;;
    (define key
      ($car assembly-sexp))
    (cond ((getprop key *cogen*)
	   ;;Convert an assembly instruction specification.
	   ;;
	   => (lambda (prop)
		(let ((n    ($car prop))
		      (proc ($cdr prop))
		      (args ($cdr assembly-sexp)))
		  (define-inline (%with-checked-args ?nargs ?body-form)
		    (if ($fx= (length args) ?nargs)
			?body-form
		      (%error-incorrect-args assembly-sexp n)))
		  (case-fixnums n
		    ((2)
		     (%with-checked-args 2
		       (proc assembly-sexp accum ($car args) ($cadr args))))
		    ((1)
		     (%with-checked-args 1
		       (proc assembly-sexp accum ($car args))))
		    ((0)
		     (%with-checked-args 0
		       (proc assembly-sexp accum)))
		    (else
		     (%with-checked-args n
		       (apply proc assembly-sexp accum args)))))))
	  ((eq? key 'seq)
	   ;;Process a SEQ sexp.  A SEQ sexp has the format:
	   ;;
	   ;;   (seq . ?asm-sexps)
	   ;;
	   ;;where   ?ASM-SEXPS  is   a   list   of  assembly   symbolic
	   ;;expressions.
	   ;;
	   (fold %convert-single-sexp accum ($cdr assembly-sexp)))
	  ((eq? key 'pad)
	   ;;Process a PAD sexp.  Convert the assembly code and return a
	   ;;new accumulator list padded with a prefix of zeros.
	   ;;
	   (let* ((n              ($cadr assembly-sexp))
		  (asm-sexps      ($cddr assembly-sexp))
		  (new-accum.tail (fold %convert-single-sexp accum asm-sexps))
		  (prefix.len     (compute-code-size (%find-prefix accum new-accum.tail))))
	     (append (make-list (- n prefix.len) 0)
		     new-accum.tail)))
	  (else
	   (assertion-violation who "unknown instruction" assembly-sexp))))

  (define (%find-prefix old-accum new-accum)
    ;;Expect NEW-ACCUM to be a list having OLD-ACCUM as tail:
    ;;
    ;;   new-accum = (item0 item ... . old-accum)
    ;;
    ;;visit the prefix of NEW-ACCUM holding the new ITEMs and filter out
    ;;the ITEMs being BOTTOM-CODE entries; return the resulting list.
    ;;
    (let loop ((ls new-accum))
      (if (eq? ls old-accum)
	  '()
	(let ((asm-sexp ($car ls)))
	  (if (bottom-code? asm-sexp)
	      ;;Skip BOTTOM-CODE sexp.
	      (loop ($cdr ls))
	    (cons asm-sexp (loop ($cdr ls))))))))

  (define-entry-predicate bottom-code? bottom-code)

  (define (%error-incorrect-args assembly-sexp expected-nargs)
    (assertion-violation who
      (string-append
       "wrong number of arguments in assembly symbolic expression, expected "
       (number->string expected-nargs))
      assembly-sexp))

  (define-inline (%uncover-local-labels accum)
    ;;Expect ACCUM to be a list of assembly sexps; visit ACCUM, entering
    ;;PAD and SEQ entries recursively, and build a list of symbols being
    ;;the names of the LABEL entries.  Return the list of LABEL names.
    ;;
    (%%uncover-local-labels '() accum))

  (define (%%uncover-local-labels names accum)
    (define-inline (%next ?names)
      (%%uncover-local-labels ?names ($cdr accum)))
    (if (null? accum)
	names
      (let ((entry ($car accum)))
	(if (pair? entry)
	    (case-symbols ($car entry)
	      ((label)
	       (%next (cons (label-name entry) names)))
	      ((seq pad)
	       (%next (%%uncover-local-labels names ($cdr entry))))
	      (else
	       (%next names)))
	  (%next names)))))

  ;;The following is the original Ikarus' version.  (Marco Maggi; Oct 9,
  ;;2012)
  ;;
  ;; (define (uncover-local-labels accum)
  ;;   (define locals '())
  ;;   (define (find x)
  ;;     (when (pair? x)
  ;; 	(case ($car x)
  ;; 	  ((label)
  ;; 	   (set! locals (cons (label-name x) locals)))
  ;; 	  ((seq pad)
  ;; 	   (for-each find ($cdr x))))))
  ;;   (for-each find accum)
  ;;   locals)

  #| end of module |# )


;;Notice that this  module exports nothing; this is  because its purpose
;;is to put properties in the  property lists of the symbols (ret, cltd,
;;movl, ...) of the assembly operations:
;;
;;   ret
;;   cltd
;;   movl src dst
;;   mov32 src dst
;;   movb src dst
;;   addl src dst
;;   subl src dst
;;   sall src dst
;;   shrl src dst
;;   sarl src dst
;;   andl src dst
;;   orl src dst
;;   xorl src dst
;;   leal src dst
;;   cmpl src dst
;;   imull src dst
;;   idivl dst
;;   pushl dst
;;   popl dst
;;   notl dst
;;   bswap dst
;;   negl dst
;;   jmp dst
;;   call dst
;;   movsd src dst
;;   cvtsi2sd src dst
;;   cvtsd2ss src dst
;;   cvtss2sd src dst
;;   movss src dst
;;   addsd src dst
;;   subsd src dst
;;   mulsd src dst
;;   divsd src dst
;;   ucomisd src dst
;;   ja dst
;;   jae dst
;;   jb dst
;;   jbe dst
;;   jg dst
;;   jge dst
;;   jl dst
;;   jle dst
;;   je dst
;;   jna dst
;;   jnae dst
;;   jnb dst
;;   jnbe dst
;;   jng dst
;;   jnge dst
;;   jnl dst
;;   jnle dst
;;   jne dst
;;   jo dst
;;   jp dst
;;   jnp dst
;;
;;and  additionally  to  the   symbols  (byte,  byte-vector,  int,  ...)
;;representing the following datums:
;;
;;   byte x
;;   byte-vector x
;;   int a
;;   label L
;;   label-address L
;;   current-frame-offset
;;   nop ac
;;
(module ()
  (import stuff)

  (define who 'assembler)

;;; --------------------------------------------------------------------

  (define (REX.R bits ac)
    (if ($fx= wordsize 4)
	(error who "BUG: REX.R invalid in 32-bit mode")
      (cons ($fxlogor #b01001000 bits) ac)))

  (define (REX+r r ac)
    (cond (($fx= wordsize 4)
	   ac)
	  ((reg-requires-REX? r)
	   (REX.R #b001 ac))
	  (else
	   (REX.R #b000 ac))))

  (define (REX+RM r rm ac)
    (define who 'REX+RM)
    (define (C n ac)
      ac)
    ;;(printf "CASE ~s\n" n)
    ;;(let f ((ac ac) (i 30))
    ;;  (unless (or (null? ac) (= i 0))
    ;;    (if (number? (car ac))
    ;;        (printf " #x~x" (car ac))
    ;;        (printf " ~s" (car ac)))
    ;;    (f (cdr ac) (- i 1))))
    ;;(newline)
    ;;ac)
    (cond (($fx= wordsize 4)
	   ac)
	  ((mem? rm)
	   (if (reg-requires-REX? r)
	       (with-args rm
		 (lambda (a0 a1)
		   (cond ((and (imm?   a0)
			       (reg32? a1))
			  (if (reg-requires-REX? a1)
			      (REX.R #b101 ac)
			    (REX.R #b100 ac)))

			 ((and (imm?   a1)
			       (reg32? a0))
			  (if (reg-requires-REX? a0)
			      (REX.R #b101 ac)
			    (REX.R #b100 ac)))

			 ((and (reg32? a0)
			       (reg32? a1))
			  (cond ((reg-requires-REX? a0)
				 (if (reg-requires-REX? a1)
				     (REX.R #b111 ac)
				   (REX.R #b110 ac)))
				((reg-requires-REX? a1)
				 (REX.R #b101 ac))
				(else
				 (REX.R #b100 ac))))

			 ((and (imm? a0)
			       (imm? a1))
			  (error 'REC+RM "not here 4")
			  #;(error who "unhandledb" a1))

			 (else
			  (die who "unhandled" a0 a1)))))
	     (with-args rm
	       (lambda (a0 a1)
		 (cond ((and (imm?   a0)
			     (reg32? a1))
			(if (reg-requires-REX? a1)
			    (REX.R #b001 ac)
			  (REX.R 0 ac)))

		       ((and (imm?   a1)
			     (reg32? a0))
			(if (reg-requires-REX? a0)
			    (REX.R #b001 ac)
			  (REX.R 0 ac)))

		       ((and (reg32? a0)
			     (reg32? a1))
			(cond ((reg-requires-REX? a0)
			       (if (reg-requires-REX? a1)
				   (error who "unhandled x1" a0 a1)
				 (REX.R #b010 ac)))
			      ((reg-requires-REX? a1)
			       (error who "unhandled x3" a0 a1))
			      (else
			       (REX.R 0 ac))))

		       ((and (imm? a0)
			     (imm? a1))
			;;(error 'REC+RM "not here 8")
			(REX.R 0 ac))

		       (else
			(die who "unhandled" a0 a1)))))))
	  ((reg? rm)
	   (let* ((bits 0)
		  (bits (if (reg-requires-REX? r)
			    ($fxlogor bits #b100)
			  bits))
		  (bits (if (reg-requires-REX? rm)
			    ($fxlogor bits #b001)
			  bits)))
	     (REX.R bits ac)))
	  (else
	   (die who "unhandled" rm))))

  (define (C c ac)
    (if ($fx= 4 wordsize)
	(CODE c ac)
      (REX.R 0 (CODE c ac))))

  ;;Commented out because it is not used (Marco Maggi; Oct 25, 2011).
  ;;
  ;; (define trace-ac
  ;;   (let ((cache '()))
  ;;     (lambda (ac1 what ac2)
  ;;       (when (assembler-output)
  ;;         (let ((diff (let f ((ls ac2))
  ;; 		      (cond ((eq? ls ac1)
  ;; 			     '())
  ;; 			    (else
  ;; 			     (cons (car ls) (f (cdr ls))))))))
  ;;           (unless (member diff cache)
  ;;             (set! cache (cons diff cache))
  ;;             (printf "~s => ~s\n" what diff))))
  ;;       ac2)))

  (define (CR c r ac)
    (REX+r r (CODE+r c r ac)))

  (define (CR* c r rm ac)
    (REX+RM r rm (CODE c (RM r rm ac))))

  (define (CR*-no-rex c r rm ac)
    (CODE c (RM r rm ac)))

  (define (CCR* c0 c1 r rm ac)
    ;;(CODE c0 (CODE c1 (RM r rm ac))))
    (REX+RM r rm (CODE c0 (CODE c1 (RM r rm ac)))))

  (define (CCR c0 c1 r ac)
    ;;(CODE c0 (CODE+r c1 r ac)))
    (REX+r r (CODE c0 (CODE+r c1 r ac))))

  (define (CCCR* c0 c1 c2 r rm ac)
    ;;(CODE c0 (CODE c1 (CODE c2 (RM r rm ac)))))
    (REX+RM r rm (CODE c0 (CODE c1 (CODE c2 (RM r rm ac))))))

  (define (CCI32 c0 c1 i32 ac)
    (CODE c0 (CODE c1 (IMM32 i32 ac))))

  (define (RM /d dst ac)
    (define who 'RM)
    (cond ((mem? dst)
	   (with-args dst
	     (lambda (a0 a1)
	       (cond ((and (imm8?  a0)
			   (reg32? a1))
		      (ModRM 1 /d a1 (IMM8 a0 ac)))
		     ((and (imm?   a0)
			   (reg32? a1))
		      (ModRM 2 /d a1 (IMM32 a0 ac)))
		     ((and (imm8?  a1)
			   (reg32? a0))
		      (ModRM 1 /d a0 (IMM8 a1 ac)))
		     ((and (imm?   a1)
			   (reg32? a0))
		      (ModRM 2 /d a0 (IMM32 a1 ac)))
		     ((and (reg32? a0)
			   (reg32? a1))
		      (RegReg /d a0 a1 ac))
		     ((and (imm? a0)
			   (imm? a1))
		      (ModRM 0 /d '/5 (IMM*2 a0 a1 ac)))
		     (else
		      (die who "unhandled" a0 a1))))))
	  ((reg? dst)
	   (ModRM 3 /d dst ac))
	  (else
	   (die who "unhandled" dst))))

  ;;Commented out because unused.  (Marco Maggi; Oct 4, 2012)
  ;;
  ;; (define (dotrace instr orig ls)
  ;;   (printf "TRACE: ~s ~s\n" instr
  ;; 	    (let f ((ls ls))
  ;; 	      (if (eq? ls orig)
  ;; 		  '()
  ;; 		(cons (car ls) (f (cdr ls))))))
  ;;   ls)

  (define (jmp-pc-relative code0 code1 dst ac)
    (boot.case-word-size
     ((32)
      (error 'intel-assembler "no pc-relative jumps in 32-bit mode"))
     ((64)
      (let ((G (gensym)))
	(CODE code0
	      (CODE code1 (cons* `(local-relative . ,G)
				 `(bottom-code (label . ,G)
					       (label-addr . ,(label-name dst)))
				 ac)))))))

;;; --------------------------------------------------------------------

  (let-syntax ((add-instruction
		   (syntax-rules ()
		     ((add-instruction (?name ?instr ?ac ?args ...)
			?body0 ?body ...)
		      (putprop '?name *cogen*
			       (cons (length '(?args ...))
				     (lambda (?instr ?ac ?args ...)
				       ?body0 ?body ...)))))))
    (define-syntax add-instructions
      (syntax-rules ()
	((add-instructions ?instr ?accumulator
	   ((?name* ?arg** ...) ?body* ?body** ...)
	   ...)
	 (begin
	   (add-instruction (?name* ?instr ?accumulator ?arg** ...)
	     ?body* ?body** ...)
	   ...)))))

;;; --------------------------------------------------------------------
;;; end of module definitions

  ;;Store a function  in the properties list of symbols  being the names
  ;;of assembly instructions.
  ;;
  (add-instructions instr ac
    ((ret)
     (CODE #xC3 ac))
    ((cltd)
     (C #x99 ac))
    ((movl src dst)
     (cond ((and (imm? src)
		 (reg? dst))
	    (CR #xB8 dst (IMM src ac)))
	   ((and (imm? src)
		 (mem? dst))
	    (CR* #xC7 '/0 dst (IMM32 src ac)))
	   ((and (reg? src)
		 (reg? dst))
	    (CR* #x89 src dst ac))
	   ((and (reg? src)
		 (mem? dst))
	    (CR* #x89 src dst ac))
	   ((and (mem? src)
		 (reg? dst))
	    (CR* #x8B dst src ac))
	   (else
	    (die who "invalid" instr))))
    ((mov32 src dst)
;;; FIXME
     (cond ((and (imm? src)
		 (reg? dst))
	    (error 'mov32 "here1")
	    (CR #xB8 dst (IMM32 src ac)))
	   ((and (imm? src)
		 (mem? dst))
	    (CR*-no-rex #xC7 '/0 dst (IMM32 src ac)))
	   ((and (reg? src)
		 (reg? dst))
	    (error 'mov32 "here3")
	    (CR* #x89 src dst ac))
	   ((and (reg? src)
		 (mem? dst))
	    (CR*-no-rex #x89 src dst ac))
	   ((and (mem? src)
		 (reg? dst))
	    (if ($fx= wordsize 4)
		(CR* #x8B dst src ac)
	      (CR*-no-rex #x8B dst src ac)))
	   (else
	    (die who "invalid" instr))))
    ((movb src dst)
     (cond ((and (imm8? src)
		 (mem?  dst))
	    (CR* #xC6 '/0 dst (IMM8 src ac)))
	   ((and (reg8? src)
		 (mem?  dst))
	    (CR* #x88 src dst ac))
	   ((and (mem?  src)
		 (reg8? dst))
	    (CR* #x8A dst src ac))
	   (else
	    (die who "invalid" instr))))
    ((addl src dst)
     (cond ((and (imm8? src)
		 (reg?  dst))
	    (CR*  #x83 '/0 dst (IMM8 src ac)))
	   ((and (imm32? src)
		 (eq? dst '%eax))
	    (C #x05 (IMM32 src ac)))
	   ((and (imm32? src)
		 (reg?   dst))
	    (CR*  #x81 '/0 dst (IMM32 src ac)))
	   ((and (reg? src)
		 (reg? dst))
	    (CR*  #x01 src dst ac))
	   ((and (mem? src)
		 (reg? dst))
	    (CR*  #x03 dst src ac))
	   ((and (imm32? src)
		 (mem?   dst))
	    (CR*  #x81 '/0 dst (IMM32 src ac)))
	   ((and (reg? src)
		 (mem? dst))
	    (CR*  #x01 src dst ac))
	   (else
	    (die who "invalid" instr))))
    ((subl src dst)
     (cond ((and (imm8? src)
		 (reg?  dst))
	    (CR*  #x83 '/5 dst (IMM8 src ac)))
	   ((and (imm32? src)
		 (eq? dst '%eax))
	    (C #x2D (IMM32 src ac)))
	   ((and (imm32? src)
		 (reg?   dst))
	    (CR*  #x81 '/5 dst (IMM32 src ac)))
	   ((and (reg? src)
		 (reg? dst))
	    (CR*  #x29 src dst ac))
	   ((and (mem? src)
		 (reg? dst))
	    (CR*  #x2B dst src ac))
	   ((and (imm32? src)
		 (mem?   dst))
	    (CR*  #x81 '/5 dst (IMM32 src ac)))
	   ((and (reg? src)
		 (mem? dst))
	    (CR*  #x29 src dst ac))
	   (else
	    (die who "invalid" instr))))
    ((sall src dst)
     (cond ((and (eqv? 1 src)
		 (reg? dst))
	    (CR* #xD1 '/4 dst ac))
	   ((and (imm8? src)
		 (reg? dst))
	    (CR* #xC1 '/4 dst (IMM8 src ac)))
	   ((and (imm8? src)
		 (mem?  dst))
	    (CR* #xC1 '/4 dst (IMM8 src ac)))
	   ((and (eq? src '%cl)
		 (reg? dst))
	    (CR* #xD3 '/4 dst ac))
	   ((and (eq? src '%cl)
		 (mem? dst))
	    (CR* #xD3 '/4 dst ac))
	   (else
	    (die who "invalid" instr))))
    ((shrl src dst)
     (cond ((and (eqv? 1 src)
		 (reg? dst))
	    (CR* #xD1 '/5 dst ac))
	   ((and (imm8? src)
		 (reg? dst))
	    (CR* #xC1 '/5 dst (IMM8 src ac)))
	   ((and (eq? src '%cl)
		 (reg? dst))
	    (CR* #xD3 '/5 dst ac))
	   ((and (imm8? src)
		 (mem?  dst))
	    (CR* #xC1 '/5 dst (IMM8 src ac)))
	   ((and (eq? src '%cl)
		 (mem? dst))
	    (CR* #xD3 '/5 dst ac))
	   (else
	    (die who "invalid" instr))))
    ((sarl src dst)
     (cond ((and (eqv? 1 src)
		 (reg? dst))
	    (CR* #xD1 '/7 dst ac))
	   ((and (imm8? src)
		 (reg?  dst))
	    (CR* #xC1 '/7 dst (IMM8 src ac)))
	   ((and (imm8? src)
		 (mem?  dst))
	    (CR* #xC1 '/7 dst (IMM8 src ac)))
	   ((and (eq? src '%cl)
		 (reg? dst))
	    (CR* #xD3 '/7 dst ac))
	   ((and (eq? src '%cl)
		 (mem? dst))
	    (CR* #xD3 '/7 dst ac))
	   (else
	    (die who "invalid" instr))))
    ((andl src dst)
     (cond ((and (imm32? src)
		 (mem?   dst))
	    (CR*  #x81 '/4 dst (IMM32 src ac)))
	   ((and (imm8? src)
		 (reg?  dst))
	    (CR*  #x83 '/4 dst (IMM8 src ac)))
	   ((and (imm32? src)
		 (eq? dst '%eax))
	    (C #x25 (IMM32 src ac)))
	   ((and (imm32? src)
		 (reg?   dst))
	    (CR*  #x81 '/4 dst (IMM32 src ac)))
	   ((and (reg? src)
		 (reg? dst))
	    (CR*  #x21 src dst ac))
	   ((and (reg? src)
		 (mem? dst))
	    (CR*  #x21 src dst ac))
	   ((and (mem? src)
		 (reg? dst))
	    (CR*  #x23 dst src ac))
	   (else
	    (die who "invalid" instr))))
    ((orl src dst)
     (cond ((and (imm32? src)
		 (mem?   dst))
	    (CR*  #x81 '/1 dst (IMM32 src ac)))
	   ((and (reg? src)
		 (mem? dst))
	    (CR*  #x09 src dst ac))
	   ((and (imm8? src)
		 (reg?  dst))
	    (CR*  #x83 '/1 dst (IMM8 src ac)))
	   ((and (imm32? src)
		 (eq? dst '%eax))
	    (C #x0D (IMM32 src ac)))
	   ((and (imm32? src)
		 (reg?   dst))
	    (CR*  #x81 '/1 dst (IMM32 src ac)))
	   ((and (reg? src)
		 (reg? dst))
	    (CR*  #x09 src dst ac))
	   ((and (mem? src)
		 (reg? dst))
	    (CR*  #x0B dst src ac))
	   (else
	    (die who "invalid" instr))))
    ((xorl src dst)
     (cond ((and (imm8? src)
		 (reg?  dst))
	    (CR*  #x83 '/6 dst (IMM8 src ac)))
	   ((and (imm8? src)
		 (mem?  dst))
	    (CR*  #x83 '/6 dst (IMM8 src ac)))
	   ((and (imm32? src)
		 (eq? dst '%eax))
	    (C #x35 (IMM32 src ac)))
	   ((and (reg? src)
		 (reg? dst))
	    (CR*  #x31 src dst ac))
	   ((and (mem? src)
		 (reg? dst))
	    (CR*  #x33 dst src ac))
	   ((and (reg? src)
		 (mem? dst))
	    (CR*  #x31 src dst ac))
	   (else
	    (die who "invalid" instr))))
    ((leal src dst)
     (cond ((and (mem? src)
		 (reg? dst))
	    (CR* #x8D dst src ac))
	   (else
	    (die who "invalid" instr))))
    ((cmpl src dst)
     (cond ((and (imm8? src)
		 (reg?  dst))
	    (CR*  #x83 '/7 dst (IMM8 src ac)))
	   ((and (imm32? src)
		 (eq? dst '%eax))
	    (C #x3D (IMM32 src ac)))
	   ((and (imm32? src)
		 (reg?   dst))
	    (CR*  #x81 '/7 dst (IMM32 src ac)))
	   ((and (reg? src)
		 (reg? dst))
	    (CR*  #x39 src dst ac))
	   ((and (mem? src)
		 (reg? dst))
	    (CR*  #x3B dst src ac))
	   ((and (imm8? src)
		 (mem?  dst))
	    (CR*  #x83 '/7 dst (IMM8 src ac)))
	   ((and (imm32? src)
		 (mem?   dst))
	    (CR*  #x81 '/7 dst (IMM32 src ac)))
	   (else
	    (die who "invalid" instr))))
    ((imull src dst)
     (cond ((and (imm8? src)
		 (reg?  dst))
	    (CR*  #x6B dst dst (IMM8 src ac)))
	   ((and (imm32? src)
		 (reg?   dst))
	    (CR*  #x69 dst dst (IMM32 src ac)))
	   ((and (reg? src)
		 (reg? dst))
	    (CCR* #x0F #xAF dst src ac))
	   ((and (mem? src)
		 (reg? dst))
	    (CCR* #x0F #xAF dst src ac))
	   (else
	    (die who "invalid" instr))))
    ((idivl dst)
     (cond ((reg? dst)
	    (CR* #xF7 '/7 dst ac))
	   ((mem? dst)
	    (CR* #xF7 '/7 dst ac))
	   (else
	    (die who "invalid" instr))))
    ((pushl dst)
     (cond ((imm8? dst)
	    (CODE #x6A (IMM8 dst ac)))
	   ((imm32? dst)
	    (CODE #x68 (IMM32 dst ac)))
	   ((reg? dst)
	    (CR   #x50 dst ac))
	   ((mem? dst)
	    (CR*  #xFF '/6 dst ac))
	   (else
	    (die who "invalid" instr))))
    ((popl dst)
     (cond ((reg? dst)
	    (CR  #x58 dst ac))
	   ((mem? dst)
	    (CR* #x8F '/0 dst ac))
	   (else
	    (die who "invalid" instr))))
    ((notl dst)
     (cond((reg? dst)
	   (CR* #xF7 '/2 dst ac))
	  ((mem? dst)
	   (CR* #xF7 '/7 dst ac))
	  (else
	   (die who "invalid" instr))))
    ((bswap dst)
     (cond ((reg? dst)
	    (CCR #x0F #xC8 dst ac))
	   (else
	    (die who "invalid" instr))))
    ((negl dst)
     (cond ((reg? dst)
	    (CR* #xF7 '/3 dst ac))
	   (else
	    (die who "invalid" instr))))
    ((jmp dst)
     (cond ((and (label? dst)
		 (local-label? (label-name dst)))
	    (CODE #xE9 (cons `(local-relative . ,(label-name dst))
			     ac)))
	   ((imm? dst)
	    (boot.case-word-size
	     ((32)
	      (CODE #xE9 (IMM32 dst ac)))
	     ((64)
	      (jmp-pc-relative #xFF #x25 dst ac))))
	   ((mem? dst)
	    (CR*  #xFF '/4 dst ac))
	   (else
	    (die who "invalid jmp target" dst))))
    ((call dst)
     (cond ((and (label? dst)
		 (local-label? (label-name dst)))
	    (CODE #xE8 (cons `(local-relative . ,(label-name dst))
			     ac)))
	   ((imm? dst)
	    (boot.case-word-size
	     ((32)
	      (CODE #xE8 (IMM32 dst ac)))
	     ((64)
	      (jmp-pc-relative #xFF #x15 dst ac))))
	   ((mem? dst)
	    (CR* #xFF '/2 dst ac))
	   ((reg? dst)
	    (CR* #xFF '/2 dst ac))
	   (else
	    (die who "invalid jmp target" dst))))
    ((movsd src dst)
     (cond ((and (xmmreg? dst)
		 (mem?    src))
	    (CCCR* #xF2 #x0F #x10 dst src ac))
	   ((and (xmmreg? src)
		 (mem? dst))
	    (CCCR* #xF2 #x0F #x11 src dst ac))
	   (else
	    (die who "invalid" instr))))
    ((cvtsi2sd src dst)
     (cond ((and (xmmreg? dst)
		 (reg? src))
	    (CCCR* #xF2 #x0F #x2A src dst ac))
	   ((and (xmmreg? dst)
		 (mem? src))
	    (CCCR* #xF2 #x0F #x2A dst src ac))
	   (else
	    (die who "invalid" instr))))
    ((cvtsd2ss src dst)
     (cond ((and (xmmreg? dst)
		 (xmmreg? src))
	    (CCCR* #xF2 #x0F #x5A src dst ac))
	   (else
	    (die who "invalid" instr))))
    ((cvtss2sd src dst)
     (cond ((and (xmmreg? dst)
		 (xmmreg? src))
	    (CCCR* #xF3 #x0F #x5A src dst ac))
	   (else
	    (die who "invalid" instr))))
    ((movss src dst)
     (cond ((and (xmmreg? dst)
		 (mem?    src))
	    (CCCR* #xF3 #x0F #x10 dst src ac))
	   ((and (xmmreg? src)
		 (mem?    dst))
	    (CCCR* #xF3 #x0F #x11 src dst ac))
	   (else
	    (die who "invalid" instr))))
    ((addsd src dst)
     (cond ((and (xmmreg? dst)
		 (mem?    src))
	    (CCCR* #xF2 #x0F #x58 dst src ac))
	   (else
	    (die who "invalid" instr))))
    ((subsd src dst)
     (cond ((and (xmmreg? dst)
		 (mem?    src))
	    (CCCR* #xF2 #x0F #x5C dst src ac))
	   (else
	    (die who "invalid" instr))))
    ((mulsd src dst)
     (cond ((and (xmmreg? dst)
		 (mem?    src))
	    (CCCR* #xF2 #x0F #x59 dst src ac))
	   (else
	    (die who "invalid" instr))))
    ((divsd src dst)
     (cond ((and (xmmreg? dst)
		 (mem?    src))
	    (CCCR* #xF2 #x0F #x5E dst src ac))
	   (else
	    (die who "invalid" instr))))
    ((ucomisd src dst)
     (cond ((and (xmmreg? dst)
		 (mem?    src))
	    (CCCR* #x66 #x0F #x2E dst src ac))
	   (else
	    (die who "invalid" instr))))
    ((ja dst)     (CCI32 #x0F #x87 dst ac))
    ((jae dst)    (CCI32 #x0F #x83 dst ac))
    ((jb dst)     (CCI32 #x0F #x82 dst ac))
    ((jbe dst)    (CCI32 #x0F #x86 dst ac))
    ((jg dst)     (CCI32 #x0F #x8F dst ac))
    ((jge dst)    (CCI32 #x0F #x8D dst ac))
    ((jl dst)     (CCI32 #x0F #x8C dst ac))
    ((jle dst)    (CCI32 #x0F #x8E dst ac))
    ((je dst)     (CCI32 #x0F #x84 dst ac))
    ((jna dst)    (CCI32 #x0F #x86 dst ac))
    ((jnae dst)   (CCI32 #x0F #x82 dst ac))
    ((jnb dst)    (CCI32 #x0F #x83 dst ac))
    ((jnbe dst)   (CCI32 #x0F #x87 dst ac))
    ((jng dst)    (CCI32 #x0F #x8E dst ac))
    ((jnge dst)   (CCI32 #x0F #x8C dst ac))
    ((jnl dst)    (CCI32 #x0F #x8D dst ac))
    ((jnle dst)   (CCI32 #x0F #x8F dst ac))
    ((jne dst)    (CCI32 #x0F #x85 dst ac))
    ((jo dst)     (CCI32 #x0F #x80 dst ac))
    ((jp dst)     (CCI32 #x0F #x8A dst ac))
    ((jnp dst)    (CCI32 #x0F #x8B dst ac))
    ((byte x)
     (if (byte? x)
	 (cons (byte x) ac)
       (die who "not a byte" x)))
    ((byte-vector x)
     (append (map (lambda (x)
		    (byte x))
	       (vector->list x))
	     ac))
    ((int a)
     (IMM a ac))
    ((label L)
     (if (symbol? L)
	 (cons (cons 'label L) ac)
       (die who "label is not a symbol" L)))
    ((label-address L)
     (if (symbol? L)
	 (cons (cons 'label-addr L) ac)
       (die who "label-address is not a symbol" L)))
    ((current-frame-offset)
     (cons '(current-frame-offset) ac))
    ((nop)
     ac))

  #| end of module |# )


(define (compute-code-size octets-and-labels)
  ;;Given a list holding octets-as-fixnums  and label sexps: compute and
  ;;return the number  of bytes needed to hold  the corresponding binary
  ;;code.  Such  number of bytes  will be the  minimum size of  the data
  ;;area in a code object.
  ;;
  (define who 'compute-code-size)
  (fold (lambda (x size)
	  (if (fixnum? x)
	      ($fxadd1 size)
	    (case-symbols ($car x)
	      ((byte)
	       ($fxadd1 size))
	      ((relative local-relative)
	       ($fxadd4 size))
	      ((label)
	       size)
	      ((word reloc-word reloc-word+ label-addr
		     current-frame-offset foreign-label)
	       ($fx+ size wordsize))
	      ((bottom-code)
	       ($fx+ size (compute-code-size ($cdr x))))
	      (else
	       (error who "unknown instr" x)))))
	0
	octets-and-labels))


(module (store-binary-code-in-code-objects)

  (define (store-binary-code-in-code-objects x ls)
    ;;Loop  over the  list of  entries LS,  filling the  data area  of X
    ;;accordingly.  X is a code object.
    ;;
    ;;LS is a  list of fixnums and lists; the  fixnums being binary code
    ;;octects to  be stored in  the code  object's data area,  the lists
    ;;representing entries for the relocation vector.
    ;;
    ;;Return a list representing data to build a relocation vector.
    ;;
    (define (loop ls idx reloc bot*)
      ;;IDX is  the index  of the  next byte  to be  filled in  the code
      ;;object's data area.  It is
      ;;
      ;;BOT* is initially  empty and is filled with  subentries from the
      ;;entries in LS having key BOTTOM-CODE; such entries are processed
      ;;ater LS has been consumed.
      ;;
      (cond ((null? ls)
	     (if (null? bot*)
		 reloc
	       (loop ($car bot*) idx reloc ($cdr bot*))))
	    (else
	     (let ((a ($car ls)))
	       (if (fixnum? a)
		   (begin
		     ;;Store a byte of binary code in the data area.
		     ($code-set! x idx a)
		     (loop ($cdr ls) ($fxadd1 idx) reloc bot*))
		 (case ($car a)
		   ((byte)
		    ;;Store a byte of binary code in the data area.
		    ($code-set! x idx ($cdr a))
		    (loop ($cdr ls) ($fxadd1 idx) reloc bot*))
		   ((relative local-relative)
		    ;;Add an entry to the relocation list; leave 4 bytes
		    ;;of room in the data area.
		    (loop ($cdr ls) ($fx+ idx 4) (cons (cons idx a) reloc) bot*))
		   ((reloc-word reloc-word+ label-addr foreign-label)
		    ;;Add an entry to the  relocation list; leave a word
		    ;;of room in the data area.
		    (loop ($cdr ls) ($fx+ idx wordsize) (cons (cons idx a) reloc) bot*))
		   ((word)
		    ;;Store a machine word in the data area.
		    (%set-code-word! x idx ($cdr a))
		    (loop ($cdr ls) ($fx+ idx wordsize) reloc bot*))
		   ((current-frame-offset)
		    ;;Store a machine word in  the data area holding the
		    ;;current offset in the data area.
		    (%set-code-word! x idx idx) ;;; FIXME 64bit
		    (loop ($cdr ls) ($fx+ idx wordsize) reloc bot*))
		   ((label)
		    ;;Store informations  about the current  location in
		    ;;the code object in the symbol ($cdr a).
		    (%set-label-loc! ($cdr a) (list x idx))
		    (loop ($cdr ls) idx reloc bot*))
		   ((bottom-code)
		    ;;Push this  entry in  BOT* to  be processed  at the
		    ;;end.
		    (loop ($cdr ls) idx reloc (cons ($cdr a) bot*)))
		   (else
		    (die 'store-binary-code-in-code-objects "unknown instr" a))))))))
    (loop ls 0 '() '()))

  (define (%set-code-word! code idx x)
    ;;Store a machine  word, whose value is  X, in the data  area of the
    ;;code object CODE at index IDX.
    ;;
    (define who '%set-code-word!)
    (with-arguments-validation (who)
	((fixnum	x))
      (if ($fx= wordsize 4)
	  (begin
	    ($code-set! code ($fx+ idx 0) ($fxsll ($fxlogand x #x3F) 2))
	    ($code-set! code ($fx+ idx 1) ($fxlogand ($fxsra x 6) #xFF))
	    ($code-set! code ($fx+ idx 2) ($fxlogand ($fxsra x 14) #xFF))
	    ($code-set! code ($fx+ idx 3) ($fxlogand ($fxsra x 22) #xFF)))
	(begin
	  ($code-set! code ($fx+ idx 0) ($fxsll ($fxlogand x #x1F) 3))
	  ($code-set! code ($fx+ idx 1) ($fxlogand ($fxsra x 5) #xFF))
	  ($code-set! code ($fx+ idx 2) ($fxlogand ($fxsra x 13) #xFF))
	  ($code-set! code ($fx+ idx 3) ($fxlogand ($fxsra x 21) #xFF))
	  ($code-set! code ($fx+ idx 4) ($fxlogand ($fxsra x 29) #xFF))
	  ($code-set! code ($fx+ idx 5) ($fxlogand ($fxsra x 37) #xFF))
	  ($code-set! code ($fx+ idx 6) ($fxlogand ($fxsra x 45) #xFF))
	  ($code-set! code ($fx+ idx 7) ($fxlogand ($fxsra x 53) #xFF))))))

  (define (%set-label-loc! x loc)
    (if (getprop x '*label-loc*)
	(error '%set-label-loc! "label is already defined" x)
      (putprop x '*label-loc* loc)))

  #| end of module |# )


(module (make-reloc-vector-record-filler code-entry-adjustment)

  (define who 'make-reloc-vector-record-filler)

  (define (make-reloc-vector-record-filler thunk?-label code vec)
    ;;Return  a closure  to be  used to  add records  to the  relocation
    ;;vector VEC associated to the code object CODE.
    ;;
    (define reloc-idx 0)
    (lambda (r)
      (define val
	(let ((v ($cddr r)))
	  (cond ((thunk?-label v)
		 => (lambda (label)
		      (let ((p (%label-loc label)))
			(cond (($fx= (length p) 2)
			       (let ((code ($car  p))
				     (idx  ($cadr p)))
				 (unless ($fxzero? idx)
				   (%error "cannot create a thunk pointing" idx))
				 (let ((thunk (code->thunk code)))
				   ($set-cdr! ($cdr p) (list thunk))
				   thunk)))
			      (else
			       ($caddr p))))))
		(else v))))
      (define-syntax key
	(identifier-syntax ($cadr r)))
      (case-symbols key
	((reloc-word)
	 ;;Add a record of type "vanilla object".
	 (let ((off ($car r))) ;Offset into the data area of the code object.
	   (%store-first-word! vec reloc-idx IK_RELOC_RECORD_VANILLA_OBJECT_TAG off)
	   ($vector-set! vec ($fxadd1 reloc-idx) val)
	   ($fxincr! reloc-idx 2)))
	((foreign-label)
	 ;;Add a record of type "foreign address".
	 (let ((off  ($car r)) ;Offset into the data area of the code object.
	       (name (%foreign-string->bytevector val)))
	   (%store-first-word! vec reloc-idx IK_RELOC_RECORD_FOREIGN_ADDRESS_TAG off)
	   ($vector-set! vec ($fxadd1 reloc-idx) name)
	   ($fxincr! reloc-idx 2)))
	((reloc-word+)
	 ;;Add a record of type "displaced object".
	 (let ((off  ($car r)) ;Offset into the data area of the code object.
	       (obj  ($car val))
	       (disp ($cdr val)))
	   (%store-first-word! vec reloc-idx IK_RELOC_RECORD_DISPLACED_OBJECT_TAG off)
	   ($vector-set! vec ($fxadd1 reloc-idx) disp)
	   ($vector-set! vec ($fxadd2 reloc-idx) obj)
	   ($fxincr! reloc-idx 3)))
	((label-addr)
	 ;;Add a record of type "displaced object".
	 (let* ((off  ($car r))	;Offset into the data area of the code object.
		(loc  (%label-loc val))
		(obj  ($car  loc))
		(disp ($cadr loc)))
	   (%store-first-word! vec reloc-idx IK_RELOC_RECORD_DISPLACED_OBJECT_TAG off)
	   ($vector-set! vec ($fxadd1 reloc-idx) ($fx+ disp (code-entry-adjustment)))
	   ($vector-set! vec ($fxadd2 reloc-idx) obj))
	 ($fxincr! reloc-idx 3))
	((local-relative)
	 ;;This entry requires the address of a label in the binary code
	 ;;of this very  code object.  There is no need  to add a record
	 ;;to the relocation vector, we  just store in the code object's
	 ;;data area  the relative offset  of the label with  respect to
	 ;;the current position in data area itself.
	 ;;
	 ;;  meta data     L  data area
	 ;; |---------|----+-------------|---|---|--------| code object
	 ;;                ^               ^ |
	 ;;                |               | |
	 ;;                |         ------  |
	 ;;                |        |        |
	 ;;                |.................| relative offset of L
	 ;;
	 ;;           |....| disp        |...| 4
	 ;;           |..................| off
	 ;;
	 ;;Notice that local  labels are specified with  a 32-bit offset
	 ;;on all the platforms.
	 ;;
	 (let* ((off  ($car r))	;Offset into the data area of the code object.
		(loc  (%label-loc val))
		(obj  ($car  loc))
		(disp ($cadr loc)))
	   (unless (eq? obj code)
	     (%error "source code object and target code object of \
                      a local relative jump are not the same"))
	   (let ((rel ($fx- disp ($fxadd4 off))))
	     ($code-set! code          off  ($fxlogand         rel     #xFF))
	     ($code-set! code ($fxadd1 off) ($fxlogand ($fxsra rel 8)  #xFF))
	     ($code-set! code ($fxadd2 off) ($fxlogand ($fxsra rel 16) #xFF))
	     ($code-set! code ($fxadd3 off) ($fxlogand ($fxsra rel 24) #xFF)))))
	((relative)
	 ;;Add a record of type "jump label".
	 (let* ((off  ($car r))	;Offset into the data area of the code object.
		(loc  (%label-loc val))
		(obj  ($car  loc))
		(disp ($cadr loc)))
	   (unless (and (code? obj) (fixnum? disp))
	     (%error "invalid relative jump obj/disp" obj disp))
	   (%store-first-word! vec reloc-idx IK_RELOC_RECORD_JUMP_LABEL_TAG off)
	   ($vector-set! vec ($fxadd1 reloc-idx) ($fx+ disp (code-entry-adjustment)))
	   ($vector-set! vec ($fxadd2 reloc-idx) obj))
	 ($fxincr! reloc-idx 3))
	(else
	 (%error "invalid entry key while filling relocation vector" key)))
      ))

  (define code-entry-adjustment
    (let ((v #f))
      (case-lambda
       (()
	(or v (die 'code-entry-adjustment "uninitialized")))
       ((x)
	(set! v x)))))

  (define %foreign-string->bytevector
    ;;Convert  the  string  X  to  a  UTF-8  bytevector.   To  speed  up
    ;;operations: keep a cache of conversions in MEMOIZED as association
    ;;list.
    ;;
    (let ((memoized (make-hashtable string-hash string=?)))
      (lambda (str)
	(with-arguments-validation (who)
	    ((string	str))
	  (or (hashtable-ref memoized str #f)
	      (let ((bv (string->utf8 str)))
		(hashtable-set! memoized str bv)
		bv))))))

  (define-inline (%error message . irritants)
    (apply error who message irritants))

  (define-syntax %store-first-word!
    (syntax-rules (IK_RELOC_RECORD_VANILLA_OBJECT_TAG)
      ((_ ?vec ?reloc-idx IK_RELOC_RECORD_VANILLA_OBJECT_TAG ?binary-code.offset)
       ($vector-set! ?vec ?reloc-idx                ($fxsll ?binary-code.offset 2)))
      ((_ ?vec ?reloc-idx ?tag ?binary-code.offset)
       ($vector-set! ?vec ?reloc-idx ($fxlogor ?tag ($fxsll ?binary-code.offset 2))))
      ))

  (define (%label-loc x)
    (or (getprop x '*label-loc*)
	(error 'compile "undefined label" x)))

  ;;Commented out because unused.  (Marco Maggi; Oct 9, 2012)
  ;;
  ;; (define-inline (unset-label-loc! x)
  ;;   (remprop x '*label-loc*))

  (define-inline-constant IK_RELOC_RECORD_VANILLA_OBJECT_TAG	0)
  (define-inline-constant IK_RELOC_RECORD_FOREIGN_ADDRESS_TAG	1)
  (define-inline-constant IK_RELOC_RECORD_DISPLACED_OBJECT_TAG	2)
  (define-inline-constant IK_RELOC_RECORD_JUMP_LABEL_TAG	3)

  #| end of module |# )


(module (assemble-sources)

  (define (assemble-sources thunk?-label ls*)
    ;;This is the entry point in the assembler.
    ;;
    ;;Return a list of code objects.
    ;;
    (let ((num-of-freevars* (map car       ls*))
	  (code-name*       (map code-name ls*))
	  (assembly-sexps*  (map code-list ls*)))
      (let* ((octets-and-labels* (map convert-instructions  assembly-sexps*))
	     (octets-and-labels* (map %optimize-local-jumps octets-and-labels*)))
	(let ((code-size*  (map compute-code-size   octets-and-labels*))
	      (reloc-size* (map %compute-reloc-size octets-and-labels*)))
	  (let ((code-objects* (map make-code   code-size* num-of-freevars*))
		(reloc-vector* (map make-vector reloc-size*)))
	    (let ((reloc** (map store-binary-code-in-code-objects
			     code-objects* octets-and-labels*)))
	      (for-each
		  (lambda (code-object reloc-vector reloc*)
		    (for-each
			(make-reloc-vector-record-filler thunk?-label code-object reloc-vector)
		      reloc*))
		code-objects* reloc-vector* reloc**)
	      ;;This causes the relocation vector to be processed for each
	      ;;code object.
	      (for-each set-code-reloc-vector! code-objects* reloc-vector*)
	      (for-each (lambda (code name)
			  (when name
			    (set-code-annotation! code name)))
		code-objects* code-name*)
	      code-objects*))))))

  (define-entry-predicate name? name)

  (define (code-list ls)
    (if (name? ($cadr ls))
	($cddr ls)
      ($cdr ls)))

  (define (code-name ls)
    (let ((a ($cadr ls)))
      (if (name? a)
	  ($cadr a)
	#f)))

  (define (%optimize-local-jumps octets-and-labels)
    ;;Scan OCTETS-AND-LABELS  and collect  the LABEL entries,  which are
    ;;"local"; then scan again OCTETS-AND-LABELS and mutate the RELATIVE
    ;;entries referencing local labels to be LOCAL-RELATIVE entries.
    ;;
    ;;Notice  that   this  function  does   NOT  modify  the   spine  of
    ;;OCTETS-AND-LABELS in any way; it  just mutates some of the entry's
    ;;CARs.
    ;;
    (let ((locals '())
	  (G      (gensym)))
      (define (%mark-labels-with-property x)
	(when (pair? x)
	  (case-symbols ($car x)
	    ((label)
	     (putprop ($cdr x) G 'local)
	     (set! locals (cons ($cdr x) locals)))
	    ((bottom-code)
	     (for-each %mark-labels-with-property ($cdr x))))))
      (define (%relative->local-relative x)
	(when (pair? x)
	  (case-symbols ($car x)
	    ((relative)
	     (when (eq? (getprop ($cdr x) G) 'local)
	       ($set-car! x 'local-relative)))
	    ((bottom-code)
	     (for-each %relative->local-relative ($cdr x))))))
      (for-each %mark-labels-with-property octets-and-labels)
      (for-each %relative->local-relative  octets-and-labels)
      ;;Clean up the property lists of label symbols.
      (for-each (lambda (x)
		  (remprop x G))
	locals)
      octets-and-labels))

  (define (%compute-reloc-size octets-and-labels)
    ;;Compute the length  of the relocation vector needed  to relocate a
    ;;code object holding the binary code in OCTETS-AND-LABELS.
    ;;
    (define who '%compute-reloc-size)
    (fold (lambda (x ac)
	    (if (fixnum? x)
		ac
	      (case-symbols ($car x)
		((word byte label current-frame-offset local-relative)
		 ac)
		((reloc-word foreign-label)
		 ($fx+ ac 2))
		((relative reloc-word+ label-addr)
		 ($fx+ ac 3))
		((bottom-code)
		 ($fx+ ac (%compute-reloc-size ($cdr x))))
		(else
		 (assertion-violation who "unknown instr" x)))))
	  0
	  octets-and-labels))

  #| end of module |# )


;;;; done

)

;;; end of file
;; Local Variables:
;; eval: (put 'add-instructions 'scheme-indent-function 2)
;; eval: (put 'add-instruction 'scheme-indent-function 1)
;; eval: (put 'with-args 'scheme-indent-function 1)
;; eval: (put '%with-checked-args 'scheme-indent-function 1)
;; End:
