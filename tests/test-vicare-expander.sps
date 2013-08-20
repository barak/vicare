;;; -*- coding: utf-8-unix -*-
;;;
;;;Part of: Vicare
;;;Contents: tests for the expander
;;;Date: Tue Sep 25, 2012
;;;
;;;Abstract
;;;
;;;
;;;
;;;Copyright (C) 2012, 2013 Marco Maggi <marco.maggi-ipsu@poste.it>
;;;
;;;This program is free software:  you can redistribute it and/or modify
;;;it under the terms of the  GNU General Public License as published by
;;;the Free Software Foundation, either version 3 of the License, or (at
;;;your option) any later version.
;;;
;;;This program is  distributed in the hope that it  will be useful, but
;;;WITHOUT  ANY   WARRANTY;  without   even  the  implied   warranty  of
;;;MERCHANTABILITY  or FITNESS FOR  A PARTICULAR  PURPOSE.  See  the GNU
;;;General Public License for more details.
;;;
;;;You should  have received  a copy of  the GNU General  Public License
;;;along with this program.  If not, see <http://www.gnu.org/licenses/>.
;;;


;;;; copyright notice for the XOR macro
;;;
;;;Copyright (c) 2008 Derick Eddington
;;;
;;;Permission is hereby granted, free of charge, to any person obtaining
;;;a  copy of  this  software and  associated  documentation files  (the
;;;"Software"), to  deal in the Software  without restriction, including
;;;without limitation  the rights to use, copy,  modify, merge, publish,
;;;distribute, sublicense,  and/or sell copies  of the Software,  and to
;;;permit persons to whom the Software is furnished to do so, subject to
;;;the following conditions:
;;;
;;;The  above  copyright notice  and  this  permission  notice shall  be
;;;included in all copies or substantial portions of the Software.
;;;
;;;Except  as  contained  in  this  notice, the  name(s)  of  the  above
;;;copyright holders  shall not be  used in advertising or  otherwise to
;;;promote  the sale,  use or  other dealings  in this  Software without
;;;prior written authorization.
;;;
;;;THE  SOFTWARE IS  PROVIDED "AS  IS",  WITHOUT WARRANTY  OF ANY  KIND,
;;;EXPRESS OR  IMPLIED, INCLUDING BUT  NOT LIMITED TO THE  WARRANTIES OF
;;;MERCHANTABILITY,    FITNESS   FOR    A    PARTICULAR   PURPOSE    AND
;;;NONINFRINGEMENT.  IN NO EVENT  SHALL THE AUTHORS OR COPYRIGHT HOLDERS
;;;BE LIABLE  FOR ANY CLAIM, DAMAGES  OR OTHER LIABILITY,  WHETHER IN AN
;;;ACTION OF  CONTRACT, TORT  OR OTHERWISE, ARISING  FROM, OUT OF  OR IN
;;;CONNECTION  WITH THE SOFTWARE  OR THE  USE OR  OTHER DEALINGS  IN THE
;;;SOFTWARE.


#!vicare
(import (vicare)
  (rnrs eval)
  (vicare checks))

(check-set-mode! 'report-failed)
(check-display "*** testing Vicare expander\n")


(parametrise ((check-test-name	'syntax-objects))

  (define-syntax (check-it stx)
    (syntax-case stx ()
      ((_ ?pattern ?syntax (_ . ?input) ?output)
       (let ((out #'(check
			(let ()
			  (define-syntax doit
			    (lambda (stx)
			      (syntax-case stx ()
				(?pattern ?syntax))))
			  (doit . ?input))
		      => ?output)))
	 #;(check-pretty-print (syntax->datum out))
	 out))))

;;; --------------------------------------------------------------------
;;; lists and pattern variables

  (check-it
      (_ ())
    (syntax 123)
    (_ ())
    123)

  (check-it
      (_ ?val)
    (syntax ?val)
    (_ 123)
    123)

  (check-it
      (_ ?a ?b ?c)
    (syntax (quote (?a ?b ?c)))
    (_ 1 2 3)
    '(1 2 3))

  (check-it
      (_ ?a ?b ?c)
    (syntax (list ?a ?b ?c))
    (_ 1 2 3)
    '(1 2 3))

  (check-it
      (_ (((?a ?b ?c))))
    (syntax (quote (?a ?b ?c)))
    (_ (((1 2 3))))
    '(1 2 3))

;;; --------------------------------------------------------------------
;;; improper lists and pattern variables

  (check-it
      (_ (?a ?b . ?c))
    (syntax (quote (?a ?b ?c)))
    (_ (1 2 . 3))
    '(1 2 3))

;;; --------------------------------------------------------------------
;;; pairs and pattern variables

  (check-it
      (_ (?a . ?b))
    (syntax (quote (?a ?b)))
    (_ (1 . 2))
    '(1 2))

  (check-it
      (_ ((?a . ?b) ?c))
    (syntax (quote (?a ?b ?c)))
    (_ ((1 . 2) 3))
    '(1 2 3))

;;; --------------------------------------------------------------------
;;; vectors and pattern variables

  (check-it
      (_ #())
    (syntax 123)
    (_ #())
    123)

  (check-it
      (_ #(?a ?b ?c))
    (syntax (quote (?a ?b ?c)))
    (_ #(1 2 3))
    '(1 2 3))

  (check-it
      (_ #(#(#(?a ?b ?c))))
    (syntax (quote (?a ?b ?c)))
    (_ #(#(#(1 2 3))))
    '(1 2 3))

;;; --------------------------------------------------------------------
;;; lists and ellipses

  (check-it
      (_ ?a ...)
    (syntax (quote (?a ...)))
    (_ 1 2 3)
    '(1 2 3))

  (check-it
      (_ ?a ?b ...)
    (syntax (quote (?a ?b ...)))
    (_ 1 2 3)
    '(1 2 3))

  (check-it
      (_ (?a ...) ...)
    (syntax (quote ((?a ...) ...)))
    (_ (1 2 3) (4 5 6) (7 8 9))
    '((1 2 3) (4 5 6) (7 8 9)))

  (check-it
      (_ (?a ?b ...) ...)
    (syntax (quote ((?a ?b ...) ...)))
    (_ (1 2 3) (4 5 6) (7 8 9))
    '((1 2 3) (4 5 6) (7 8 9)))

  (check-it
      (_ ?a ... ?b)
    (syntax (quote ((?a ...) ?b)))
    (_ 1 2 3)
    '((1 2) 3))

;;; --------------------------------------------------------------------
;;; vectors and ellipses

  (check-it
      (_ #(?a ...))
    (syntax (quote (?a ...)))
    (_ #(1 2 3))
    '(1 2 3))

  (check-it
      (_ #(?a ?b ...))
    (syntax (quote (?a ?b ...)))
    (_ #(1 2 3))
    '(1 2 3))

  (check-it
      (_ #(?a ...) ...)
    (syntax (quote ((?a ...) ...)))
    (_ #(1 2 3) #(4 5 6) #(7 8 9))
    '((1 2 3) (4 5 6) (7 8 9)))

  (check-it
      (_ #(?a ?b ...) ...)
    (syntax (quote ((?a ?b ...) ...)))
    (_ #(1 2 3) #(4 5 6) #(7 8 9))
    '((1 2 3) (4 5 6) (7 8 9)))

  (check-it
      (_ #(?a ... ?b))
    (syntax (quote ((?a ...) ?b)))
    (_ #(1 2 3))
    '((1 2) 3))

  (check-it
      (_ #(?a ... (?b ...)))
    (syntax (quote ((?a ...) ?b ...)))
    (_ #(1 2 (3 4)))
    '((1 2) 3 4))

  #t)


(parametrise ((check-test-name	'import))

  (check	;import separately a named module and a library, library
		;first
      (let ()
	(module ciao
	  (hello salut)
	  (define (hello) 'hello)
	  (define (salut) 'salut))
	(import (vicare language-extensions syntaxes))
	(import ciao)
	(list (hello) (salut)))
    => '(hello salut))

  (check	;import separately a named  module and a library, module
		;first
      (let ()
	(module ciao
	  (hello salut)
	  (define (hello) 'hello)
	  (define (salut) 'salut))
	(import ciao)
	(import (vicare language-extensions syntaxes))
	(list (hello) (salut)))
    => '(hello salut))

  (check	;import both a named module and a library, library first
      (let ()
	(module ciao
	  (hello salut)
	  (define (hello) 'hello)
	  (define (salut) 'salut))
	(import (vicare language-extensions syntaxes)
	  ciao)
	(list (hello) (salut)))
    => '(hello salut))

  (check	;import both a named module and a library, module first
      (let ()
	(module ciao
	  (hello salut)
	  (define (hello) 'hello)
	  (define (salut) 'salut))
	(import ciao
	  (vicare language-extensions syntaxes))
	(list (hello) (salut)))
    => '(hello salut))

  #;(check	;import a named module with some name mangling
      (let ()
	(module ciao
	  (hello salut)
	  (define (hello) 'hello)
	  (define (salut) 'salut))
	(import (prefix ciao ciao.))
	(list (ciao.hello) (ciao.salut)))
    => '(hello salut))

  #t)


(parametrise ((check-test-name	'export))

  (check
      (let ()
	(module (green)
	  (define (green) 'green)
	  (define (yellow) 'yellow)
	  (export yellow))
	(list (green) (yellow)))
    => '(green yellow))

  #t)


(parametrise ((check-test-name	'deprefix))

  (check
      (eval '(str.length "ciao")
	    (environment
	     '(prefix
	       (deprefix (only (rnrs)
			       string-length
			       string-append)
			 string-)
	       str.)))
    => 4)

  #t)


(parametrise ((check-test-name	'test-define-integrable))

  (define-syntax define-integrable
    ;;Posted  by "leppie"  on the  Ikarus mailing  list; subject  "Macro
    ;;Challenge of Last Year [Difficulty: *****]", 20 Oct 2009.
    ;;
    (lambda (x)
      (define (make-residual-name name)
	(datum->syntax name
		       (string->symbol
			(string-append "residual-"
				       (symbol->string (syntax->datum name))))))
      (syntax-case x (lambda)
        ((_ (?name . ?formals) ?form1 ?form2 ...)
	 (identifier? #'?name)
	 #'(define-integrable ?name (lambda ?formals ?form1 ?form2 ...)))

        ((_ ?name (lambda ?formals ?form1 ?form2 ...))
         (identifier? #'?name)
         (with-syntax ((XNAME (make-residual-name #'?name)))
           #'(begin
               (define-fluid-syntax ?name
                 (lambda (x)
                   (syntax-case x ()
                     (_
		      (identifier? x)
		      #'XNAME)

                     ((_ arg (... ...))
                      #'((fluid-let-syntax
			     ((?name (identifier-syntax XNAME)))
                           (lambda ?formals ?form1 ?form2 ...))
                         arg (... ...))))))

               (define XNAME
                 (fluid-let-syntax ((?name (identifier-syntax XNAME)))
                   (lambda ?formals ?form1 ?form2 ...))))))
	)))

;;; --------------------------------------------------------------------

  (check
      (let ()
	(define-integrable (fact n)
	  (let ((residual-fact (lambda (x)
				 (error 'fact "captured residual-fact"))))
	    (if (< n 2)
		1
	      (* n (fact (- n 1))))))
	(fact 5))
    => 120)

  (check
      (let ()
	(define-integrable (f x) (+ x 1))
	(eq? f f))
    => #t)

  (check
      (let ()
	(define-integrable (even? n) (or (zero? n) (odd? (- n 1))))
	(define-integrable (odd? n) (not (even? n)))
	(even? 5))
    => #f)

  #t)


(parametrise ((check-test-name	'define-values))

  (check
      (let ()
	(define-values (a)
	  1)
	a)
    => 1)

  (check
      (with-result
       (let ()
	 (define-values (a)
	   (add-result 2)
	   1)
	 a))
    => '(1 (2)))

  (check
      (let ()
  	(define-values (a b c)
  	  #t
  	  (values 1 2 3))
  	(list a b c))
    => '(1 2 3))

  (check
      (let ((a 2))
  	(define-values (a)
  	  (values 1))
  	a)
    => 1)

  #t)


(parametrise ((check-test-name	'define-constant-values))

  (check
      (let ()
	(define-constant-values (a b c)
	  #t
	  (values 1 2 3))
	(list a b c))
    => '(1 2 3))

  (check
      (let ()
	(define-constant-values (a)
	  #t
	  (values 1))
	a)
    => 1)

  (check
      (let ()
	(define-constant-values (a)
	  #t
	  1)
	a)
    => 1)

  #t)


(parametrise ((check-test-name	'receive))

  (check
      (receive (a b c)
	  (values 1 2 3)
	(list a b c))
    => '(1 2 3))

  (check
      (receive (a)
	  1
	a)
    => 1)

  #t)


(parametrise ((check-test-name	'receive-and-return))

  (check
      (receive (a b c)
	  (receive-and-return (a b c)
	      (values 1 2 3)
	    (vector a b c))
	(list a b c))
    => '(1 2 3))

  (check
      (with-result
       (receive (a)
	   (receive-and-return (a)
	       1
	     (add-result a))
	 a))
    => '(1 (1)))

  (check
      (with-result
       (receive-and-return ()
	   (values)
	 (add-result 1))
       #t)
    => '(#t (1)))

  #t)


(parametrise ((check-test-name	'begin0))

  (check
      (begin0
       1)
    => 1)

  (check
      (call-with-values
	  (lambda ()
	    (begin0
	     (values 1 2 3)))
	list)
    => '(1 2 3))

  (check
      (with-result
       (begin0
	1
	(add-result 2)
	(add-result 3)))
    => '(1 (2 3)))

  (check
      (with-result
       (call-with-values
	   (lambda ()
	     (begin0
	      (values 1 10)
	      (add-result 2)
	      (add-result 3)))
	 list))
    => '((1 10) (2 3)))


  #t)


(parametrise ((check-test-name	'define-inline))

  (check
      (let ()
	(define-inline (ciao a b)
	  (+ a b))
	(ciao 1 2))
    => 3)

  (check
      (let ()
	(define-inline (ciao)
	  (+ 1 2))
	(ciao))
    => 3)

  (check
      (let ()
	(define-inline (ciao . rest)
	  (apply + rest))
	(ciao 1 2))
    => 3)

  (check
      (let ()
	(define-inline (ciao a . rest)
	  (apply + a rest))
	(ciao 1 2))
    => 3)

  #t)


(parametrise ((check-test-name	'define-constant))

  (check
      (let ()
	(define-constant a 123)
	a)
    => 123)

  #t)


(parametrise ((check-test-name	'define-inline-constant))

  (check
      (let ()
	(define-inline-constant a (+ 1 2 3))
	a)
    => 6)

  #t)


(parametrise ((check-test-name	'define-integrable))

  (check
      (let ()
	(define-integrable (fact n)
	  (if (< n 2)
	      1
	    (* n (fact (- n 1)))))
	(fact 5))
    => 120)

  (check
      (let ()
	(define-integrable (f x) (+ x 1))
	(eq? f f))
    => #t)

  (check
      (let ()
	(define-integrable (even? n) (or (zero? n) (odd? (- n 1))))
	(define-integrable (odd? n) (not (even? n)))
	(even? 5))
    => #f)

  (check
      (let ()
	(define-integrable (incr x)
	  (+ x 1))
	(map incr '(10 20 30)))
    => '(11 21 31))

  #t)


(parametrise ((check-test-name	'define-syntax-rule))

  (check
      (let ()
	(define-syntax-rule (ciao a b)
	  (+ a b))
	(ciao 1 2))
    => 3)

  (check
      (let ()
	(define-syntax-rule (ciao)
	  (+ 1 2))
	(ciao))
    => 3)

  (check
      (let ()
	(define-syntax-rule (ciao . ?rest)
	  (+ . ?rest))
	(ciao 1 2))
    => 3)

  (check
      (let ()
	(define-syntax-rule (ciao a . ?rest)
	  (+ a . ?rest))
	(ciao 1 2))
    => 3)

  #t)


(parametrise ((check-test-name	'test-while))

  (define-fluid-syntax continue
    (lambda (stx)
      (syntax-error 'continue "syntax \"continue\" out of any loop")))

  (define-fluid-syntax break
    (lambda (stx)
      (syntax-error 'continue "syntax \"break\" out of any loop")))

  (define-syntax while
    (syntax-rules ()
      ((_ ?test ?body ...)
       (call/cc
	   (lambda (escape)
	     (let loop ()
	       (fluid-let-syntax ((break    (syntax-rules ()
					      ((_ . ?args)
					       (escape . ?args))))
				  (continue (lambda (stx) #'(loop))))
		 (if ?test
		     (begin
		       ?body ...
		       (loop))
		   (escape)))))))
      ))

;;; --------------------------------------------------------------------

  (check
      (with-result
       (let ((i 5))
	 (while (positive? i)
	   (add-result i)
	   (set! i (+ -1 i)))
	 i))
    => '(0 (5 4 3 2 1)))

  (check
      (with-result
       (let ((i 0))
	 (while (positive? i)
	   (add-result i)
	   (set! i (+ -1 i)))
	 i))
    => '(0 ()))

  (check
      (with-result	;continue
       (let ((i 5))
	 (while (positive? i)
	   (add-result i)
	   (set! i (+ -1 i))
	   (continue)
	   (add-result "post"))
	 i))
    => '(0 (5 4 3 2 1)))

  (check
      (with-result	;break
       (let ((i 5))
	 (while (positive? i)
	   (add-result i)
	   (set! i (+ -1 i))
	   (break)
	   (add-result "post"))
	 i))
    => '(4 (5)))

  (check		;break with single value
      (with-result
       (let ((i 5))
	 (while (positive? i)
	   (add-result i)
	   (set! i (+ -1 i))
	   (break 'ciao)
	   (add-result "post"))))
    => '(ciao (5)))

  (check		;break with multiple values
      (with-result
       (let ((i 5))
	 (receive (a b)
	     (while (positive? i)
	       (add-result i)
	       (set! i (+ -1 i))
	       (break 'ciao 'hello)
	       (add-result "post"))
	   (list a b))))
    => '((ciao hello) (5)))

  #t)


(parametrise ((check-test-name	'while))

  (check
      (with-result
       (let ((i 5))
	 (while (positive? i)
	   (add-result i)
	   (set! i (+ -1 i)))
	 i))
    => '(0 (5 4 3 2 1)))

  (check
      (with-result
       (let ((i 0))
	 (while (positive? i)
	   (add-result i)
	   (set! i (+ -1 i)))
	 i))
    => '(0 ()))

  (check
      (with-result	;continue
       (let ((i 5))
	 (while (positive? i)
	   (add-result i)
	   (set! i (+ -1 i))
	   (continue)
	   (add-result "post"))
	 i))
    => '(0 (5 4 3 2 1)))

  (check
      (with-result	;break
       (let ((i 5))
	 (while (positive? i)
	   (add-result i)
	   (set! i (+ -1 i))
	   (break)
	   (add-result "post"))
	 i))
    => '(4 (5)))

  (check		;break with single value
      (with-result
       (let ((i 5))
	 (while (positive? i)
	   (add-result i)
	   (set! i (+ -1 i))
	   (break 'ciao)
	   (add-result "post"))))
    => '(ciao (5)))

  (check		;break with multiple values
      (with-result
       (let ((i 5))
	 (receive (a b)
	     (while (positive? i)
	       (add-result i)
	       (set! i (+ -1 i))
	       (break 'ciao 'hello)
	       (add-result "post"))
	   (list a b))))
    => '((ciao hello) (5)))

  #t)


(parametrise ((check-test-name	'test-until))

  (define-fluid-syntax continue
    (lambda (stx)
      (syntax-error 'continue "syntax \"continue\" out of any loop")))

  (define-fluid-syntax break
    (lambda (stx)
      (syntax-error 'break "syntax \"break\" out of any loop")))

  (define-syntax until
    (syntax-rules ()
      ((_ ?test ?body ...)
       (call/cc
	   (lambda (escape)
	     (let loop ()
	       (fluid-let-syntax ((break    (syntax-rules ()
					      ((_ . ?args)
					       (escape . ?args))))
				  (continue (lambda (stx) #'(loop))))
		 (if ?test
		     (escape)
		   (begin
		     ?body ...
		     (loop))))))))
      ))

;;; --------------------------------------------------------------------

  (check
      (with-result
       (let ((i 5))
	 (until (zero? i)
	   (add-result i)
	   (set! i (+ -1 i)))
	 i))
    => '(0 (5 4 3 2 1)))

  (check
      (with-result
       (let ((i 0))
	 (until (zero? i)
	   (add-result i)
	   (set! i (+ -1 i)))
	 i))
    => '(0 ()))

  (check	;continue
      (with-result
       (let ((i 5))
	 (until (zero? i)
	   (add-result i)
	   (set! i (+ -1 i))
	   (continue)
	   (add-result "post"))
	 i))
    => '(0 (5 4 3 2 1)))

  (check	;break with no values
      (with-result
       (let ((i 5))
	 (until (zero? i)
	   (add-result i)
	   (set! i (+ -1 i))
	   (break)
	   (add-result "post"))
	 i))
    => '(4 (5)))

  (check	;break with single value
      (with-result
       (let ((i 5))
	 (until (zero? i)
	   (add-result i)
	   (set! i (+ -1 i))
	   (break 'ciao)
	   (add-result "post"))))
    => '(ciao (5)))

  (check	;break with multiple values
      (with-result
       (let ((i 5))
	 (receive (a b)
	     (until (zero? i)
	       (add-result i)
	       (set! i (+ -1 i))
	       (break 'ciao 'hello)
	       (add-result "post"))
	   (list a b))))
    => '((ciao hello) (5)))

  #t)


(parametrise ((check-test-name	'until))

  (check
      (with-result
       (let ((i 5))
	 (until (zero? i)
	   (add-result i)
	   (set! i (+ -1 i)))
	 i))
    => '(0 (5 4 3 2 1)))

  (check
      (with-result
       (let ((i 0))
	 (until (zero? i)
	   (add-result i)
	   (set! i (+ -1 i)))
	 i))
    => '(0 ()))

  (check	;continue
      (with-result
       (let ((i 5))
	 (until (zero? i)
	   (add-result i)
	   (set! i (+ -1 i))
	   (continue)
	   (add-result "post"))
	 i))
    => '(0 (5 4 3 2 1)))

  (check	;break with no values
      (with-result
       (let ((i 5))
	 (until (zero? i)
	   (add-result i)
	   (set! i (+ -1 i))
	   (break)
	   (add-result "post"))
	 i))
    => '(4 (5)))

  (check	;break with single value
      (with-result
       (let ((i 5))
	 (until (zero? i)
	   (add-result i)
	   (set! i (+ -1 i))
	   (break 'ciao)
	   (add-result "post"))))
    => '(ciao (5)))

  (check	;break with multiple values
      (with-result
       (let ((i 5))
	 (receive (a b)
	     (until (zero? i)
	       (add-result i)
	       (set! i (+ -1 i))
	       (break 'ciao 'hello)
	       (add-result "post"))
	   (list a b))))
    => '((ciao hello) (5)))

  #t)


(parametrise ((check-test-name	'test-for))

  (define-fluid-syntax continue
    (lambda (stx)
      (syntax-error 'continue "syntax \"continue\" out of any loop")))

  (define-fluid-syntax break
    (lambda (stx)
      (syntax-error 'break "syntax \"break\" out of any loop")))

  (define-syntax for
    (syntax-rules ()
      ((_ (?init ?test ?incr) ?body ...)
       (call/cc
	   (lambda (escape)
	     ?init
	     (let loop ()
	       (fluid-let-syntax ((break    (syntax-rules ()
					      ((_ . ?args)
					       (escape . ?args))))
				  (continue (lambda (stx) #'(loop))))
		 (if ?test
		     (begin
		       ?body ... ?incr
		       (loop))
		   (escape)))))))
      ))

;;; --------------------------------------------------------------------

  (check	;test true
      (with-result
       (for ((define i 5) (positive? i) (set! i (+ -1 i)))
	 (add-result i))
       #t)
    => '(#t (5 4 3 2 1)))

  (check	;test immediately false
      (with-result
       (for ((define i 0) (positive? i) (set! i (+ -1 i)))
	 (add-result i))
       #t)
    => '(#t ()))

  (check	;continue
      (with-result
       (for ((define i 5) (positive? i) (set! i (+ -1 i)))
	 (add-result i)
	 (set! i (+ -1 i))
	 (continue)
	 (add-result "post"))
       #t)
    => '(#t (5 4 3 2 1)))

  (check	;break with no values
      (with-result
       (for ((define i 5) (positive? i) (set! i (+ -1 i)))
	 (add-result i)
	 (break)
	 (add-result "post"))
       #t)
    => '(#t (5)))

  (check	;break with single value
      (with-result
       (for ((define i 5) (positive? i) (set! i (+ -1 i)))
	 (add-result i)
	 (break 'ciao)
	 (add-result "post")))
    => '(ciao (5)))

  (check	;break with multiple values
      (with-result
       (receive (a b)
	   (for ((define i 5) (positive? i) (set! i (+ -1 i)))
	     (add-result i)
	     (break 'ciao 'hello)
	     (add-result "post"))
	 (list a b)))
    => '((ciao hello) (5)))

  (check	;multiple bindings
      (with-result
       (for ((begin
	       (define i 5)
	       (define j 10))
	     (positive? i)
	     (begin
	       (set! i (+ -1 i))
	       (set! j (+ -1 j))))
	 (add-result i)
	 (add-result j))
       #t)
    => '(#t (5 10 4 9 3 8 2 7 1 6)))

  (check	;no bindings
      (with-result
       (let ((i #f))
	 (for ((set! i 5) (positive? i) (set! i (+ -1 i)))
	   (add-result i))
	 i))
    => '(0 (5 4 3 2 1)))

  #t)


(parametrise ((check-test-name	'for))

  (check	;test true
      (with-result
       (for ((define i 5) (positive? i) (set! i (+ -1 i)))
	 (add-result i))
       #t)
    => '(#t (5 4 3 2 1)))

  (check	;test immediately false
      (with-result
       (for ((define i 0) (positive? i) (set! i (+ -1 i)))
	 (add-result i))
       #t)
    => '(#t ()))

  (check	;continue
      (with-result
       (for ((define i 5) (positive? i) (set! i (+ -1 i)))
	 (add-result i)
	 (set! i (+ -1 i))
	 (continue)
	 (add-result "post"))
       #t)
    => '(#t (5 4 3 2 1)))

  (check	;break with no values
      (with-result
       (for ((define i 5) (positive? i) (set! i (+ -1 i)))
	 (add-result i)
	 (break)
	 (add-result "post"))
       #t)
    => '(#t (5)))

  (check	;break with single value
      (with-result
       (for ((define i 5) (positive? i) (set! i (+ -1 i)))
	 (add-result i)
	 (break 'ciao)
	 (add-result "post")))
    => '(ciao (5)))

  (check	;break with multiple values
      (with-result
       (receive (a b)
	   (for ((define i 5) (positive? i) (set! i (+ -1 i)))
	     (add-result i)
	     (break 'ciao 'hello)
	     (add-result "post"))
	 (list a b)))
    => '((ciao hello) (5)))

  (check	;multiple bindings
      (with-result
       (for ((begin
	       (define i 5)
	       (define j 10))
	     (positive? i)
	     (begin
	       (set! i (+ -1 i))
	       (set! j (+ -1 j))))
	 (add-result i)
	 (add-result j))
       #t)
    => '(#t (5 10 4 9 3 8 2 7 1 6)))

  (check	;no bindings
      (with-result
       (let ((i #f))
	 (for ((set! i 5) (positive? i) (set! i (+ -1 i)))
	   (add-result i))
	 i))
    => '(0 (5 4 3 2 1)))

  #t)


(parametrise ((check-test-name	'return))

  (define-syntax define-returnable
    (syntax-rules ()
      ((_ (?name . ?formals) ?body0 ?body ...)
       (define (?name . ?formals)
	 (call/cc
	     (lambda (escape)
	       (fluid-let-syntax ((return (syntax-rules ()
					    ((_ . ?args)
					     (escape . ?args)))))
		 ?body0 ?body ...)))))
      ))

  (define-syntax lambda-returnable
    (syntax-rules ()
      ((_ ?formals ?body0 ?body ...)
       (lambda ?formals
	 (call/cc
	     (lambda (escape)
	       (fluid-let-syntax ((return (syntax-rules ()
					    ((_ . ?args)
					     (escape . ?args)))))
		 ?body0 ?body ...)))))
      ))

  (define-syntax begin-returnable
    (syntax-rules ()
      ((_ ?body0 ?body ...)
       (call/cc
	   (lambda (escape)
	     (fluid-let-syntax ((return (syntax-rules ()
					  ((_ . ?args)
					   (escape . ?args)))))
	       ?body0 ?body ...))))
      ))

;;; --------------------------------------------------------------------
;;; define-returnable

  (check	;no return, no arguments
      (with-result
       (let ()
	 (define-returnable (ciao)
	   (add-result 'in)
	   (add-result 'out)
	   1)
	 (ciao)))
    => '(1 (in out)))

  (check	;no return, arguments
      (with-result
       (let ()
	 (define-returnable (ciao a b)
	   (add-result 'in)
	   (add-result 'out)
	   (list a b))
	 (ciao 1 2)))
    => '((1 2) (in out)))

  (check	;return no values
      (with-result
       (let ()
	 (define-returnable (ciao)
	   (add-result 'in)
	   (return)
	   (add-result 'out)
	   1)
	 (ciao)
	 #t))
    => '(#t (in)))

  (check	;return single value
      (with-result
       (let ()
	 (define-returnable (ciao)
	   (add-result 'in)
	   (return 2)
	   (add-result 'out)
	   1)
	 (ciao)))
    => '(2 (in)))

  (check	;return multiple values
      (with-result
       (let ()
	 (define-returnable (ciao)
	   (add-result 'in)
	   (return 2 3 4)
	   (add-result 'out)
	   (values 1 2 3))
	 (receive (a b c)
	     (ciao)
	   (list a b c))))
    => '((2 3 4) (in)))

;;; --------------------------------------------------------------------
;;; lambda-returnable

  (check	;no return, no arguments
      (with-result
       (let ()
	 (define ciao
	   (lambda-returnable ()
	     (add-result 'in)
	     (add-result 'out)
	     1))
	 (ciao)))
    => '(1 (in out)))

  (check	;no return, arguments
      (with-result
       (let ()
	 (define ciao
	   (lambda-returnable (a b)
	     (add-result 'in)
	     (add-result 'out)
	     (list a b)))
	 (ciao 1 2)))
    => '((1 2) (in out)))

  (check	;return no values
      (with-result
       (let ()
	 (define ciao
	   (lambda-returnable ()
	     (add-result 'in)
	     (return)
	     (add-result 'out)
	     1))
	 (ciao)
	 #t))
    => '(#t (in)))

  (check	;return single value
      (with-result
       (let ()
	 (define ciao
	   (lambda-returnable ()
	     (add-result 'in)
	     (return 2)
	     (add-result 'out)
	     1))
	 (ciao)))
    => '(2 (in)))

  (check	;return multiple values
      (with-result
       (let ()
	 (define ciao
	   (lambda-returnable ()
	     (add-result 'in)
	     (return 2 3 4)
	     (add-result 'out)
	     (values 1 2 3)))
	 (receive (a b c)
	     (ciao)
	   (list a b c))))
    => '((2 3 4) (in)))

;;; --------------------------------------------------------------------
;;; begin-returnable

  (check	;no return, no arguments
      (with-result
       (begin-returnable
	(add-result 'in)
	(add-result 'out)
	1))
    => '(1 (in out)))

  (check	;no return, arguments
      (with-result
       (begin-returnable
	(add-result 'in)
	(add-result 'out)
	(list 1 2)))
    => '((1 2) (in out)))

  (check	;return no values
      (with-result
       (begin-returnable
	(add-result 'in)
	(return)
	(add-result 'out)
	1)
       #t)
    => '(#t (in)))

  (check	;return single value
      (with-result
       (begin-returnable
	(add-result 'in)
	(return 2)
	(add-result 'out)
	1))
    => '(2 (in)))

  (check	;return multiple values
      (with-result
       (receive (a b c)
	   (begin-returnable
	    (add-result 'in)
	    (return 2 3 4)
	    (add-result 'out)
	    (values 1 2 3))
	 (list a b c)))
    => '((2 3 4) (in)))

  #f)


(parametrise ((check-test-name	'define-returnable))

  (check	;no return, no arguments
      (with-result
       (let ()
	 (define-returnable (ciao)
	   (add-result 'in)
	   (add-result 'out)
	   1)
	 (ciao)))
    => '(1 (in out)))

  (check	;no return, arguments
      (with-result
       (let ()
	 (define-returnable (ciao a b)
	   (add-result 'in)
	   (add-result 'out)
	   (list a b))
	 (ciao 1 2)))
    => '((1 2) (in out)))

  (check	;return no values
      (with-result
       (let ()
	 (define-returnable (ciao)
	   (add-result 'in)
	   (return)
	   (add-result 'out)
	   1)
	 (ciao)
	 #t))
    => '(#t (in)))

  (check	;return single value
      (with-result
       (let ()
	 (define-returnable (ciao)
	   (add-result 'in)
	   (return 2)
	   (add-result 'out)
	   1)
	 (ciao)))
    => '(2 (in)))

  (check	;return multiple values
      (with-result
       (let ()
	 (define-returnable (ciao)
	   (add-result 'in)
	   (return 2 3 4)
	   (add-result 'out)
	   (values 1 2 3))
	 (receive (a b c)
	     (ciao)
	   (list a b c))))
    => '((2 3 4) (in)))

  #f)


(parametrise ((check-test-name	'lambda-returnable))

  (check	;no return, no arguments
      (with-result
       (let ()
	 (define ciao
	   (lambda-returnable ()
	     (add-result 'in)
	     (add-result 'out)
	     1))
	 (ciao)))
    => '(1 (in out)))

  (check	;no return, arguments
      (with-result
       (let ()
	 (define ciao
	   (lambda-returnable (a b)
	     (add-result 'in)
	     (add-result 'out)
	     (list a b)))
	 (ciao 1 2)))
    => '((1 2) (in out)))

  (check	;return no values
      (with-result
       (let ()
	 (define ciao
	   (lambda-returnable ()
	     (add-result 'in)
	     (return)
	     (add-result 'out)
	     1))
	 (ciao)
	 #t))
    => '(#t (in)))

  (check	;return single value
      (with-result
       (let ()
	 (define ciao
	   (lambda-returnable ()
	     (add-result 'in)
	     (return 2)
	     (add-result 'out)
	     1))
	 (ciao)))
    => '(2 (in)))

  (check	;return multiple values
      (with-result
       (let ()
	 (define ciao
	   (lambda-returnable ()
	     (add-result 'in)
	     (return 2 3 4)
	     (add-result 'out)
	     (values 1 2 3)))
	 (receive (a b c)
	     (ciao)
	   (list a b c))))
    => '((2 3 4) (in)))

  #f)


(parametrise ((check-test-name	'begin-returnable))

  (check	;no return, no arguments
      (with-result
       (begin-returnable
	(add-result 'in)
	(add-result 'out)
	1))
    => '(1 (in out)))

  (check	;no return, arguments
      (with-result
       (begin-returnable
	(add-result 'in)
	(add-result 'out)
	(list 1 2)))
    => '((1 2) (in out)))

  (check	;return no values
      (with-result
       (begin-returnable
	(add-result 'in)
	(return)
	(add-result 'out)
	1)
       #t)
    => '(#t (in)))

  (check	;return single value
      (with-result
       (begin-returnable
	(add-result 'in)
	(return 2)
	(add-result 'out)
	1))
    => '(2 (in)))

  (check	;return multiple values
      (with-result
       (receive (a b c)
	   (begin-returnable
	    (add-result 'in)
	    (return 2 3 4)
	    (add-result 'out)
	    (values 1 2 3))
	 (list a b c)))
    => '((2 3 4) (in)))

  #t)


(parametrise ((check-test-name	'test-unwind-protect))

  (define-syntax unwind-protect
    ;;Not a general UNWIND-PROTECT for Scheme,  but fine where we do not
    ;;make the  body return  continuations to the  caller and  then come
    ;;back again and again, calling CLEANUP multiple times.
    ;;
    (syntax-rules ()
      ((_ ?body ?cleanup0 ?cleanup ...)
       (let ((cleanup (lambda () ?cleanup0 ?cleanup ...)))
	 (with-exception-handler
	     (lambda (E)
	       (cleanup)
	       (raise E))
	   (lambda ()
	     (begin0
		 ?body
	       (cleanup))))))))

;;; --------------------------------------------------------------------

  (check
      (with-result
       (unwind-protect
	   (begin
	     (add-result 'in)
	     1)
	 (add-result 'out)))
    => '(1 (in out)))

  (check
      (with-result
       (unwind-protect
	   (begin
	     (add-result 'in)
	     1)
	 (add-result 'out1)
	 (add-result 'out2)))
    => '(1 (in out1 out2)))

  (check	;multiple return values
      (with-result
       (receive (a b)
	   (unwind-protect
	       (begin
		 (add-result 'in)
		 (values 1 2))
	     (add-result 'out1)
	     (add-result 'out2))
	 (list a b)))
    => '((1 2) (in out1 out2)))

  (check	;zero return values
      (with-result
       (unwind-protect
  	   (begin
  	     (add-result 'in)
  	     (values))
  	 (add-result 'out1)
  	 (add-result 'out2))
       #t)
    => `(#t (in out1 out2)))

  (check	;exception in body
      (with-result
       (guard (E (else #t))
	 (unwind-protect
	     (begin
	       (add-result 'in)
	       (error #f "fail!!!")
	       (add-result 'after)
	       1)
	   (add-result 'out))))
    => '(#t (in out)))

  #t)


(parametrise ((check-test-name	'unwind-protect))

  (check
      (with-result
       (unwind-protect
	   (begin
	     (add-result 'in)
	     1)
	 (add-result 'out)))
    => '(1 (in out)))

  (check
      (with-result
       (unwind-protect
	   (begin
	     (add-result 'in)
	     1)
	 (add-result 'out1)
	 (add-result 'out2)))
    => '(1 (in out1 out2)))

  (check	;multiple return values
      (with-result
       (receive (a b)
	   (unwind-protect
	       (begin
		 (add-result 'in)
		 (values 1 2))
	     (add-result 'out1)
	     (add-result 'out2))
	 (list a b)))
    => '((1 2) (in out1 out2)))

  (check	;zero return values
      (with-result
       (unwind-protect
  	   (begin
  	     (add-result 'in)
  	     (values))
  	 (add-result 'out1)
  	 (add-result 'out2))
       #t)
    => `(#t (in out1 out2)))

  (check	;exception in body
      (with-result
       (guard (E (else #t))
	 (unwind-protect
	     (begin
	       (add-result 'in)
	       (error #f "fail!!!")
	       (add-result 'after)
	       1)
	   (add-result 'out))))
    => '(#t (in out)))

  #t)


(parametrise ((check-test-name	'define-auxiliary-syntaxes))

  (define-auxiliary-syntaxes)
  (define-auxiliary-syntaxes ciao)
  (define-auxiliary-syntaxes blu red)

  (define-syntax doit
    (syntax-rules (blu red)
      ((_ (blu ?blu) (red ?red))
       (list ?blu ?red))))

;;; --------------------------------------------------------------------

  (check
      (doit (blu 1) (red 2))
    => '(1 2))

  #t)


(parametrise ((check-test-name	'test-xor))

  (define-syntax xor
    (syntax-rules ()
      ((_ expr ...)
       (xor-aux #F expr ...))))

  (define-syntax xor-aux
    (syntax-rules ()
      ((_ r)
       r)
      ((_ r expr)
       (let ((x expr))
	 (if r
	     (and (not x) r)
	   x)))
      ((_ r expr0 expr ...)
       (let ((x expr0))
	 (and (or (not r) (not x))
	      (let ((n (or r x)))
		(xor-aux n expr ...)))))))

;;; --------------------------------------------------------------------

  (check (xor) => #f)
  (check (xor (number? 1)) => #T)
  (check (xor (null? 1)) => #f)
  (check (xor (string->symbol "foo")) => 'foo)
  (check (xor (string? "a") (symbol? 1)) => #T)
  (check (xor (string? 1) (symbol? 'a)) => #T)
  (check (xor (string? 1) (symbol? 2)) => #f)
  (check (xor (pair? '(a)) (list? '(b))) => #f)
  (check (xor (- 42) (not 42)) => -42)
  (check (xor (null? 1) (/ 42)) => 1/42)
  (check (xor (integer? 1.2) (positive? -2) (exact? 3)) => #T)
  (check (xor (integer? 1.2) (positive? 2) (exact? 3.4)) => #T)
  (check (xor (integer? 1) (positive? -2) (exact? 3.4)) => #T)
  (check (xor (integer? 1.2) (positive? -2) (exact? 3.4)) => #f)
  (check (xor (integer? 1.2) (positive? 2) (exact? 3)) => #f)
  (check (xor (integer? 1) (positive? -2) (exact? 3)) => #f)
  (check (xor (integer? 1) (positive? 2) (exact? 3.4)) => #f)
  (check (xor (integer? 1) (positive? 2) (exact? 3)) => #f)
  (check (xor "foo" (not 'foo) (eq? 'a 'b)) => "foo")
  (check (xor (not 'foo) (+ 1 2) (eq? 'a 'b)) => 3)
  (check (xor (not 'foo) (eq? 'a 'b) (- 1 2)) => -1)
  (let ((x '()))
    (check (xor (begin (set! x (cons 'a x)) #f)
		(begin (set! x (cons 'b x)) #f)
		(begin (set! x (cons 'c x)) #f)
		(begin (set! x (cons 'd x)) #f))
      => #f)
    (check x => '(d c b a)))
  (let ((x '()))
    (check (xor (begin (set! x (cons 'a x)) 'R)
		(begin (set! x (cons 'b x)) #f)
		(begin (set! x (cons 'c x)) #f)
		(begin (set! x (cons 'd x)) #f))
      => 'R)
    (check x => '(d c b a)))
  (let ((x '()))
    (check (xor (begin (set! x (cons 'a x)) #T)
		(begin (set! x (cons 'b x)) #f)
		(begin (set! x (cons 'c x)) #T)
		(begin (set! x (cons 'd x)) #f))
      => #f)
    (check x => '(c b a)))
  (let-syntax ((macro
		   (let ((count 0))
		     (lambda (stx)
		       (syntax-case stx ()
			 ((_) (begin (set! count (+ 1 count)) #''foo))
			 ((_ _) count))))))
    (check (xor #f (macro) #f) => 'foo)
    (check (macro 'count) => 1))

  #t)


(parametrise ((check-test-name	'xor))

  (check (xor) => #f)
  (check (xor (number? 1)) => #T)
  (check (xor (null? 1)) => #f)
  (check (xor (string->symbol "foo")) => 'foo)
  (check (xor (string? "a") (symbol? 1)) => #T)
  (check (xor (string? 1) (symbol? 'a)) => #T)
  (check (xor (string? 1) (symbol? 2)) => #f)
  (check (xor (pair? '(a)) (list? '(b))) => #f)
  (check (xor (- 42) (not 42)) => -42)
  (check (xor (null? 1) (/ 42)) => 1/42)
  (check (xor (integer? 1.2) (positive? -2) (exact? 3)) => #T)
  (check (xor (integer? 1.2) (positive? 2) (exact? 3.4)) => #T)
  (check (xor (integer? 1) (positive? -2) (exact? 3.4)) => #T)
  (check (xor (integer? 1.2) (positive? -2) (exact? 3.4)) => #f)
  (check (xor (integer? 1.2) (positive? 2) (exact? 3)) => #f)
  (check (xor (integer? 1) (positive? -2) (exact? 3)) => #f)
  (check (xor (integer? 1) (positive? 2) (exact? 3.4)) => #f)
  (check (xor (integer? 1) (positive? 2) (exact? 3)) => #f)
  (check (xor "foo" (not 'foo) (eq? 'a 'b)) => "foo")
  (check (xor (not 'foo) (+ 1 2) (eq? 'a 'b)) => 3)
  (check (xor (not 'foo) (eq? 'a 'b) (- 1 2)) => -1)
  (let ((x '()))
    (check (xor (begin (set! x (cons 'a x)) #f)
		(begin (set! x (cons 'b x)) #f)
		(begin (set! x (cons 'c x)) #f)
		(begin (set! x (cons 'd x)) #f))
      => #f)
    (check x => '(d c b a)))
  (let ((x '()))
    (check (xor (begin (set! x (cons 'a x)) 'R)
		(begin (set! x (cons 'b x)) #f)
		(begin (set! x (cons 'c x)) #f)
		(begin (set! x (cons 'd x)) #f))
      => 'R)
    (check x => '(d c b a)))
  (let ((x '()))
    (check (xor (begin (set! x (cons 'a x)) #T)
		(begin (set! x (cons 'b x)) #f)
		(begin (set! x (cons 'c x)) #T)
		(begin (set! x (cons 'd x)) #f))
      => #f)
    (check x => '(c b a)))
  (let-syntax ((macro
		   (let ((count 0))
		     (lambda (stx)
		       (syntax-case stx ()
			 ((_) (begin (set! count (+ 1 count)) #''foo))
			 ((_ _) count))))))
    (check (xor #f (macro) #f) => 'foo)
    (check (macro 'count) => 1))

  #t)


(parametrise ((check-test-name	'extended-define-syntax))

  (define-syntax (doit stx)
    (syntax-case stx ()
      ((_ a b)
       #'(list a b))))

  (check
      (doit 1 2)
    => '(1 2))

  #t)


(parametrise ((check-test-name	'endianness))

  (check (endianness little)		=> 'little)
  (check (endianness big)		=> 'big)
  (check (endianness network)		=> 'big)
  (check (endianness native)		=> (native-endianness))

  #t)


;; (parametrise ((check-test-name	'syntax-transpose))

;;   (define id #f)
;;   (define ciao 1)

;;   (check
;;       (let ((id 3))
;; 	(define-syntax doit
;; 	  (lambda (stx)
;; 	    (syntax-case stx ()
;; 	      ((_ ?id)
;; 	       (begin
;; 		 (check-pretty-print #'id)
;; 		 (check-pretty-print #'?id)
;; 		 (syntax-transpose #'ciao #'id #'?id))))))
;; 	(doit id))
;;     => #f)

;;   #t)


;;;; done

(check-report)

;;; end of file
