;;;Ikarus Scheme -- A compiler for R6RS Scheme.
;;;Copyright (C) 2006,2007,2008  Abdulaziz Ghuloum
;;;Modified by Marco Maggi <marco.maggi-ipsu@poste.it>
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
(library (ikarus control)
  (export
    call/cf		call/cc
    dynamic-wind
    (rename (call/cc call-with-current-continuation))
    exit		exit-hooks)
  (import (except (ikarus)
		  call/cf		call/cc
		  call-with-current-continuation
		  dynamic-wind
		  exit			exit-hooks
		  list-tail)
    (ikarus system $stack)
    (ikarus system $pairs)
    (ikarus system $fx)
    (ikarus.emergency)
    (vicare arguments validation)
    (only (vicare syntactic-extensions)
	  define-inline))


;;;; helpers

(module common-tail
  (%common-tail)

  (define (%common-tail x y)
    ;;This function  is used only  by the function %DO-WIND.   Given two
    ;;lists X and  Y (being lists of winders), which  are known to share
    ;;the  same  tail, return  the  first  pair  of their  common  tail;
    ;;example:
    ;;
    ;;   T = (p q r)
    ;;   X = (a b c d . T)
    ;;   Y = (i l m . T)
    ;;
    ;;return the  list T.   Attempt to  make this  operation as  fast as
    ;;possible.
    ;;
    (let ((lx (%unsafe-len x))
	  (ly (%unsafe-len y)))
      (let ((x (if ($fx> lx ly)
		   (%list-tail x ($fx- lx ly))
		 x))
	    (y (if ($fx> ly lx)
		   (%list-tail y ($fx- ly lx))
		 y)))
	(if (eq? x y)
	    x
	  (%drop-uncommon-heads ($cdr x) ($cdr y))))))

  (define (%list-tail ls n)
    ;;Skip the  first N items  in the list  LS and return  the resulting
    ;;tail.
    ;;
    (if ($fxzero? n)
	ls
      (%list-tail ($cdr ls) ($fxsub1 n))))

  (define (%drop-uncommon-heads x y)
    ;;Given two lists X and Y skip  their heads until the first EQ? pair
    ;;is found; return such pair.
    ;;
    (if (eq? x y)
	x
      (%drop-uncommon-heads ($cdr x) ($cdr y))))

  (module (%unsafe-len)

    (define-inline (%unsafe-len ls)
      (%len ls 0))

    (define (%len ls n)
      ;;Return the length of the list LS.
      ;;
      (if (null? ls)
	  n
	(%len ($cdr ls) ($fxadd1 n))))

    #| end of module: %unsafe-len |# )

  #| end of module: %common-tail |# )


;;;; winders

(module winders-handling
  (%current-winders
   %winders-set!
   %winders-push!
   %winders-pop!
   %winders-eq?)

  (define the-winders
    ;;A list  of pairs  beind the in-guard  and out-guard  functions set
    ;;with DYNAMIC-WIND:
    ;;
    ;;   ((?in-guard . ?out-guard) ...)
    ;;
    ;;In   a   multithreading   context    this   variable   should   be
    ;;thread-specific.
    ;;
    '())

  (define-inline (%current-winders)
    the-winders)

  (define-inline (%winders-set! ?new)
    (set! the-winders ?new))

  (define-inline (%winders-push! ?in ?out)
    (set! the-winders (cons (cons ?in ?out) the-winders)))

  (define-inline (%winders-pop!)
    (set! the-winders ($cdr the-winders)))

  (define-inline (%winders-eq? ?save)
    (eq? ?save the-winders))

  #| end of module: winders-handling |# )


;;;; continuations

(define (%primitive-call/cf func)
  ;;Low level function: call the function FUNC with a description of the
  ;;current  Scheme stack  frame, stored  in a  continuation object,  as
  ;;argument.
  ;;
  #;(emergency-write "enter call/cf")
  (if ($fp-at-base)
      ;;The situation of the Scheme stack is:
      ;;
      ;;          high memory
      ;;   |                      | <-- pcb->frame_base
      ;;   |----------------------|
      ;;   |    return address    | <-- frame pointer register (FPR)
      ;;   |----------------------|
      ;;   |                      |
      ;;          low memory
      ;;
      ;;so there is no continuation to  be saved, because we already are
      ;;at the  base of  the stack;  so we just  call the  function FUNC
      ;;using the current "pcb->next_k"  as continuation object.  Notice
      ;;that "pcb->next_k" is not removed from the PCB structure.
      ;;
      ;;Notice that there  are at least two situations in  which the FPR
      ;;is  at the  base of  the stack;  one is  when the  execution has
      ;;rewind the stack until the base of the current stack segment:
      ;;
      ;;          high memory
      ;;   |                      | <-- pcb->frame_base = end of segment
      ;;   |----------------------|
      ;;   | ik_underflow_handler | <-- frame pointer register (FPR)
      ;;   |----------------------|
      ;;   |                      |
      ;;          low memory
      ;;
      ;;the other is when $SEAL-FRAME-AND-CALL has been used to save the
      ;;current  stack  inside   a  call  to  this   very  function  and
      ;;$CALL-WITH-UNDERFLOW-HANDLER has  prepared the stack  as follows
      ;;before calling the argument function FUNC:
      ;;
      ;;          high memory
      ;;   |                      | <-- end of segment
      ;;   |----------------------|
      ;;   | ik_underflow_handler |
      ;;   |----------------------|
      ;;   |         ...          |
      ;;   |----------------------|
      ;;   |  old return address  | <-- pcb->frame_base
      ;;   |----------------------|
      ;;   | ik_underflow_handler | <-- frame pointer register (FPR)
      ;;   |----------------------|
      ;;   | continuation object  |
      ;;   |----------------------|
      ;;   |                      |
      ;;          low memory
      ;;
      (func ($current-frame))
    ;;The situation of the Scheme stack is:
    ;;
    ;;         high memory
    ;;   |                      | <-- pcb->frame_base
    ;;   |----------------------|
    ;;   | ik_underflow_handler |
    ;;   |----------------------|
    ;;             ...
    ;;   |----------------------|
    ;;   |    return address    | <-- frame pointer register (FPR)
    ;;   |----------------------|
    ;;   |                      |
    ;;          low memory
    ;;
    ;;so we  need to save the  current stack into a  continuation object
    ;;and then call FUNC.
    ($seal-frame-and-call func)))

(define (call/cf func)
  (define who 'call/cf)
  (with-arguments-validation (who)
      ((procedure	func))
    (%primitive-call/cf func)))

(module (call/cc)
  (import winders-handling)

  (define (call/cc func)
    (define who 'call/cc)
    (with-arguments-validation (who)
	((procedure	func))
      (%primitive-call/cc (lambda (kont)
			    (let ((save (%current-winders)))
			      (define-inline (%do-wind-maybe)
				(unless (%winders-eq? save)
				  (%do-wind save)))
			      (func (case-lambda
				     ((v)
				      (%do-wind-maybe)
				      (kont v))
				     (()
				      (%do-wind-maybe)
				      (kont))
				     ((v1 v2 . v*)
				      (%do-wind-maybe)
				      (apply kont v1 v2 v*)))))))))

  (define-inline (%primitive-call/cc ?func)
    (%primitive-call/cf (lambda (frm)
			  ;;FRM  is  a  continuation object  created  by
			  ;;%PRIMITIVE-CALL/CF   and    representing   a
			  ;;snapshot  of the  Scheme  stack right  after
			  ;;entering %PRIMITIVE-CALL/CF.
			  ;;
			  ;;When FRM  arrives here, it has  already been
			  ;;prepended to the list "pcb->next_k".
			  ;;
			  ;;The return value  of $FRAME->CONTINUATION is
			  ;;a  closure  object  which,  when  evaluated,
			  ;;resumes the continuation represented by FRM.
			  (?func ($frame->continuation frm)))))

  (module (%do-wind)

    (define (%do-wind new)
      (import common-tail)
      (let ((tail (%common-tail new (%current-winders))))
	(%unwind* (%current-winders) tail)
	(%rewind* new                tail)))

    (define (%unwind* ls tail)
      ;;The list LS must be the head  of WINDERS, TAIL must be a tail of
      ;;WINDERS.  Run the out-guards from LS, and pop their entry, until
      ;;TAIL is left in WINDERS.
      ;;
      ;;In other words, given LS and TAIL:
      ;;
      ;;   LS   = ((?old-in-guard-N . ?old-out-guard-N)
      ;;           ...
      ;;           (?old-in-guard-1 . ?old-out-guard-1)
      ;;           (?old-in-guard-0 . ?old-out-guard-0)
      ;;           . TAIL)
      ;;   TAIL = ((?in-guard . ?out-guard) ...)
      ;;
      ;;run  the out-guards  from ?OLD-OUT-GUARD-N  to ?OLD-OUT-GUARD-0;
      ;;finally set winders to TAIL.
      ;;
      (unless (eq? ls tail)
	(%winders-set! ($cdr ls))
	(($cdr ($car ls)))
	(%unwind* ($cdr ls) tail)))

    (define (%rewind* ls tail)
      ;;The list LS must be the new head of WINDERS, TAIL must be a tail
      ;;of WINDERS.   Run the in-guards  from LS in reverse  order, from
      ;;TAIL excluded to the top; finally set WINDERS to LS.
      ;;
      ;;In other words, given LS and TAIL:
      ;;
      ;;   LS   = ((?new-in-guard-N . ?new-out-guard-N)
      ;;           ...
      ;;           (?new-in-guard-1 . ?new-out-guard-1)
      ;;           (?new-in-guard-0 . ?new-out-guard-0)
      ;;           . TAIL)
      ;;   TAIL = ((?in-guard . ?out-guard) ...)
      ;;
      ;;run  the  in-guards  from  ?NEW-IN-GUARD-0  to  ?NEW-IN-GUARD-N;
      ;;finally set WINDERS to LS.
      ;;
      (unless (eq? ls tail)
	(%rewind* ($cdr ls) tail)
	(($car ($car ls)))
	(%winders-set! ls)))

    #| end of module: %do-wind |# )

  #| end of module: call/cc |# )


;;;; dynamic wind

(define (dynamic-wind in-guard body out-guard)
  (define who 'dynamic-wind)
  (import winders-handling)
  (with-arguments-validation (who)
      ((procedure	in-guard)
       (procedure	body)
       (procedure	out-guard))
    (in-guard)
    ;;We  do *not*  push  the guards  if an  error  occurs when  running
    ;;IN-GUARD.
    (%winders-push! in-guard out-guard)
    (call-with-values
	body
      (case-lambda
       ((v)
	(%winders-pop!)
	(out-guard)
	v)
       (()
	(%winders-pop!)
	(out-guard)
	(values))
       ((v1 v2 . v*)
	(%winders-pop!)
	(out-guard)
	(apply values v1 v2 v*))))))


;;;; other functions

(define exit
  (case-lambda
   (()
    (exit 0))
   ((status)
    (for-each (lambda (f)
		;;Catch and discard any  exception: exit hooks must take
		;;care of themselves.
		(guard (E (else (void)))
		  (f)))
      (exit-hooks))
    (foreign-call "ikrt_exit" status))))

(define exit-hooks
  (make-parameter '()
    (lambda (obj)
      (assert (and (list? obj)
		   (for-all procedure? obj)))
      obj)))


;;;; done

)

;;; end of file
