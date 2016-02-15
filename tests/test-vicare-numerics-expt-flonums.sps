;;; -*- coding: utf-8-unix -*-
;;;
;;;Part of: Vicare Scheme
;;;Contents: tests for numerics functions: expt
;;;Date: Thu Dec  6, 2012
;;;
;;;Abstract
;;;
;;;
;;;
;;;Copyright (C) 2012 Marco Maggi <marco.maggi-ipsu@poste.it>
;;;
;;;This program is free software:  you can redistribute it and/or modify
;;;it under the terms of the  GNU General Public License as published by
;;;the Free Software Foundation, either version 3 of the License, or (at
;;;your option) any later version.
;;;
;;;This program is  distributed in the hope that it  will be useful, but
;;;WITHOUT  ANY   WARRANTY;  without   even  the  implied   warranty  of
;;;MERCHANTABILITY or  FITNESS FOR  A PARTICULAR  PURPOSE.  See  the GNU
;;;General Public License for more details.
;;;
;;;You should  have received a  copy of  the GNU General  Public License
;;;along with this program.  If not, see <http://www.gnu.org/licenses/>.
;;;


#!r6rs
(import (vicare)
  (vicare system $ratnums)
  (vicare system $compnums)
  (vicare system $numerics)
  (vicare checks))

(check-set-mode! 'report-failed)
(check-display "*** testing Vicare numerics functions: expt, flonum exponent\n")


;;;; helpers

(define C make-rectangular)
(define R real-part)
(define I imag-part)

(define-syntax make-test
  (syntax-rules ()
    ((_ ?safe-fun ?middle-fun ?unsafe-fun)
     (syntax-rules ()
       ((_ ?op1 ?op2 ?expected-result)
	(begin
	  (check (?safe-fun   ?op1 ?op2)	=> ?expected-result)
	  (check (?middle-fun ?op1 ?op2)	=> ?expected-result)
	  (check (?unsafe-fun ?op1 ?op2)	=> ?expected-result)
	  ))))))

(define-syntax make-flonum-test
  (syntax-rules ()
    ((_ ?safe-fun ?middle-fun ?unsafe-fun)
     (syntax-rules ()
       ((_ ?op1 ?op2 ?expected-result)
	(begin
	  (check (?safe-fun   ?op1 ?op2)	(=> flonum=?) ?expected-result)
	  (check (?middle-fun ?op1 ?op2)	(=> flonum=?) ?expected-result)
	  (check (?unsafe-fun ?op1 ?op2)	(=> flonum=?) ?expected-result)
	  ))))))

(define-syntax make-cflonum-test
  (syntax-rules ()
    ((_ ?safe-fun ?middle-func ?unsafe-fun)
     (syntax-rules ()
       ((_ ?op1 ?op2 ?expected-result)
	(begin
	  (check (?safe-fun   ?op1 ?op2)	(=> cflonum=?) ?expected-result)
	  (check (?middle-fun ?op1 ?op2)	(=> flonum=?) ?expected-result)
	  (check (?unsafe-fun ?op1 ?op2)	(=> cflonum=?) ?expected-result)
	  ))))))

(define-syntax make-compnum-test
  (syntax-rules ()
    ((_ ?safe-fun ?middle-fun ?unsafe-fun)
     (syntax-rules ()
       ((_ ?op1 ?op2 ?expected-result)
	(begin
	  (check (?safe-fun   ?op1 ?op2)	(=> compnum=?) ?expected-result)
	  (check (?middle-fun ?op1 ?op2)	(=> compnum=?) ?expected-result)
	  (check (?unsafe-fun ?op1 ?op2)	(=> compnum=?) ?expected-result)
	  ))))))

(define-syntax make-inexact-test
  (syntax-rules ()
    ((_ ?safe-fun ?middle-fun ?unsafe-fun)
     (syntax-rules ()
       ((_ ?op1 ?op2 ?expected-result)
	(begin
	  (check (?safe-fun   ?op1 ?op2)	(=> inexact=?) ?expected-result)
	  (check (?middle-fun ?op1 ?op2)	(=> inexact=?) ?expected-result)
	  (check (?unsafe-fun ?op1 ?op2)	(=> inexact=?) ?expected-result)
	  ))))))

;;; --------------------------------------------------------------------

(define-syntax catch-implementation-restriction
  (syntax-rules ()
    ((_ ?message . ?body)
     (check
	 (guard (E ((implementation-restriction-violation? E)
		    (condition-message E))
		   (else E))
	   (begin . ?body))
       => ?message))))

;;; --------------------------------------------------------------------

(define (flonum=? x y)
  (cond ((flnan? x)
	 (flnan? y))
	((flzero?/positive x)
	 (flzero?/positive y))
	((flzero?/negative x)
	 (flzero?/negative y))
	((fl=? x y))))

(define (cflonum=? x y)
  (and (flonum=? (real-part x) (real-part y))
       (flonum=? (imag-part x) (imag-part y))))

(define (compnum=? x y)
  (cond ((and (cflonum? x)
	      (cflonum? y))
	 (cflonum=? x y))
	((and (flonum? x)
	      (flonum? y))
	 (flonum=? x y))
	(else
	 (= x y))))

;;; --------------------------------------------------------------------

(define (inexact=? x y)
  (cond ((and (cflonum? x)
	      (cflonum? y))
	 (cflonum-quasi=? x y))
	((and (flonum? x)
	      (flonum? y))
	 (flonum-quasi=? x y))
	((or (compnum? x)
	     (cflonum? x)
	     (compnum? y)
	     (cflonum? y))
	 (complex-quasi=? x y))
	(else
	 (= x y))))

(define (flonum-quasi=? x y)
  (cond ((flnan? x)
	 (flnan? y))
	((infinite? x)
	 (fl=? x y))
	;;Here we cannot consider +0.0 different fro -0.0.
	((flzero? x)
	 (flzero? y))
	(else
	 (fl<? (flabs (fl- x y))
	       1e-5)
	 #;(fl<? (fl/ (flabs (fl- x y))
		    (flabs x))
	       1e-5))))

(define (cflonum-quasi=? x y)
  (and (flonum-quasi=? (real-part x) (real-part y))
       (flonum-quasi=? (imag-part x) (imag-part y))))

(define (complex-quasi=? x y)
  (let ((x.rep (real-part x))
	(x.imp (imag-part x))
	(y.rep (real-part y))
	(y.imp (imag-part y)))
    (and (inexact=? x.rep y.rep)
	 (inexact=? x.imp y.imp))))


;;;; constants

(define SMALLEST-POSITIVE-BIGNUM	(-    (least-fixnum)))
(define SMALLEST-NEGATIVE-BIGNUM	(+ -1 (least-fixnum)))

(define BN1	(+ +1  SMALLEST-POSITIVE-BIGNUM))
(define BN2	(+ +10 SMALLEST-POSITIVE-BIGNUM))
(define BN3	(+ -1  SMALLEST-NEGATIVE-BIGNUM))
(define BN4	(+ -10 SMALLEST-NEGATIVE-BIGNUM))


(parametrise ((check-test-name	'fixnum-base))

  (define-syntax test
    (make-inexact-test expt $expt-number-flonum $expt-fixnum-flonum))

  (test 0	+0.0	+1.0)
  (test +1	+0.0	+1.0)
  (test -1	+0.0	+1.0+0.0i)

  (test 0	-0.0	1.0)
  (test +1	-0.0	+1.0)
  (test -1	-0.0	+1.0+0.0i)

  (test 0	+1.0	+0.0)
  (test +1	+1.0	+1.0)
  (test -1	+1.0	-1.0+0.0i)

  (test 0	-1.0	+inf.0)
  (test +1	-1.0	+1.0)
  (test -1	-1.0	-1.0+0.0i)

  (test +10	2.0	100.0)
  (test -10	2.0	100.0+0.0i)

  (test +10	3.0	1000.0)
  (test -10	3.0	-1000.0+0.0i)

  (test +10	-2.0	1e-2)
  (test -10	-2.0	1e-2+0.0i)

  (test +10	-3.0	+1e-3)
  (test -10	-3.0	-1e-3+0.0i)

  #t)


(parametrise ((check-test-name	'bignum-base))

  (define-syntax test
    (make-inexact-test expt $expt-number-flonum $expt-bignum-flonum))

  (test BN1	+0.0	+1.0)
  (test BN2	+0.0	+1.0)
  (test BN3	+0.0	+1.0+0.0i)
  (test BN4	+0.0	+1.0+0.0i)

  (test BN1	-0.0	+1.0)
  (test BN2	-0.0	+1.0)
  (test BN3	-0.0	+1.0+0.0i)
  (test BN4	-0.0	+1.0+0.0i)

  (test BN1	+1.0	(inexact BN1))
  (test BN2	+1.0	(inexact BN2))
  (test BN3	+1.0	(+ 0.0i (inexact BN3)))
  (test BN4	+1.0	(+ 0.0i (inexact BN4)))

  ;;The test comparison function is not good for these.
  (test BN1	-1.0	(inexact (/ BN1)))
  (test BN2	-1.0	(inexact (/ BN2)))
  (test BN3	-1.0	(+ 0.0i (inexact (/ BN3))))
  (test BN4	-1.0	(+ 0.0i (inexact (/ BN4))))

  #t)


(parametrise ((check-test-name	'ratnum-base))

  (define-syntax test
    (make-inexact-test expt $expt-number-flonum $expt-ratnum-flonum))

  (test +1/2	+0.0	+1.0)
  (test -1/2	+0.0	+1.0+0.0i)

  (test +1/2	-0.0	+1.0)
  (test -1/2	-0.0	+1.0+0.0i)

  (test +1/2	+1.0	(inexact +1/2))
  (test -1/2	+1.0	(+ +0.0i (inexact -1/2)))

  (test +1/2	-1.0	(inexact (/ +1/2)))
  (test -1/2	-1.0	(+ +0.0i (inexact (/ -1/2))))

  (test +1/2	+2.0	(inexact +1/4))
  (test -1/2	+2.0	(+ +0.0i (inexact +1/4)))

  (test +1/2	-2.0	(inexact (/ +1/4)))
  (test -1/2	-2.0	(+ +0.0i (inexact (/ +1/4))))

  (test +1/2	+3.0	(inexact +1/8))
  (test -1/2	+3.0	(+ +0.0i (inexact -1/8)))

  (test +1/2	-3.0	(inexact (/ +1/8)))
  (test -1/2	-3.0	(+ +0.0i (inexact (/ -1/8))))

  #t)


(parametrise ((check-test-name	'flonum-base))

  (define-syntax test
    (make-inexact-test expt $expt-number-flonum $expt-flonum-flonum))

  (test	+0.0		+0.0	+1.0)
  (test	-0.0		+0.0	+1.0)
  (test	+1.0		+0.0	+1.0)
  (test	-1.0		+0.0	+1.0)
  (test	+nan.0		+0.0	+nan.0)
  (test	+inf.0		+0.0	+nan.0)
  (test	-inf.0		+0.0	+nan.0+nan.0i)
  (test +2.0		+0.0	+1.0)
  (test -2.0		+0.0	+1.0)

  (test	+0.0		-0.0	+1.0)
  (test	-0.0		-0.0	+1.0)
  (test	+1.0		-0.0	+1.0)
  (test	-1.0		-0.0	+1.0)
  (test	+nan.0		-0.0	+nan.0)
  (test	+inf.0		-0.0	+nan.0)
  (test	-inf.0		-0.0	+nan.0+nan.0i)
  (test +2.0		-0.0	+1.0)
  (test -2.0		-0.0	+1.0)

  (test	+0.0		+1.0	+0.0)
  (test	-0.0		+1.0	-0.0)
  (test	+1.0		+1.0	+1.0+0.0i)
  (test	-1.0		+1.0	-1.0+0.0i)
  (test	+nan.0		+1.0	+nan.0)
  (test	+inf.0		+1.0	+inf.0+0.0i)
  (test	-inf.0		+1.0	-inf.0)
  (test +2.0		+1.0	+2.0)
  (test -2.0		+1.0	-2.0)

  (test	+0.0		-1.0	+inf.0)
  (test	-0.0		-1.0	-inf.0)
  (test	+1.0		-1.0	+1.0)
  (test	-1.0		-1.0	-1.0+0.0i)
  (test	+nan.0		-1.0	+nan.0)
  (test	+inf.0		-1.0	+0.0)
  (test	-inf.0		-1.0	+0.0+0.0i)
  (test +2.0		-1.0	+0.5)
  (test -2.0		-1.0	-0.5+0.0i)

  (test	+0.0		+2.0	+0.0)
  (test	-0.0		+2.0	-0.0)
  (test	+1.0		+2.0	+1.0+0.0i)
  (test	-1.0		+2.0	+1.0+0.0i)
  (test	+nan.0		+2.0	+nan.0)
  (test	+inf.0		+2.0	+inf.0+0.0i)
  (test	-inf.0		+2.0	+inf.0-inf.0i)
  (test +2.0		+2.0	+4.0)
  (test -2.0		+2.0	+4.0+0.0i)

  (test	+0.0		-2.0	+inf.0)
  (test	-0.0		-2.0	-inf.0)
  (test	+1.0		-2.0	+1.0+0.0i)
  (test	-1.0		-2.0	+1.0+0.0i)
  (test	+nan.0		-2.0	+nan.0)
  (test	+inf.0		-2.0	+0.0)
  (test	-inf.0		-2.0	-0.0)
  (test +2.0		-2.0	+0.25)
  (test -2.0		-2.0	+0.25+0.0i)

  (test	+0.0		+3.0	+0.0)
  (test	-0.0		+3.0	-0.0)
  (test	+1.0		+3.0	+1.0+0.0i)
  (test	-1.0		+3.0	-1.0+0.0i)
  (test	+nan.0		+3.0	+nan.0)
  (test	+inf.0		+3.0	+inf.0+0.0i)
  (test	-inf.0		+3.0	-inf.0+inf.0i)
  (test +2.0		+3.0	+8.0)
  (test -2.0		+3.0	-8.0+0.0i)

  (test	+0.0		-3.0	+inf.0)
  (test	-0.0		-3.0	-inf.0)
  (test	+1.0		-3.0	+1.0+0.0i)
  (test	-1.0		-3.0	-1.0+0.0i)
  (test	+nan.0		-3.0	+nan.0)
  (test	+inf.0		-3.0	+0.0)
  (test	-inf.0		-3.0	-0.0)
  (test +2.0		-3.0	+0.125)
  (test -2.0		-3.0	-0.125+0.0i)

  (test	+0.0		+inf.0	+0.0)
  (test	-0.0		+inf.0	-0.0)
  (test	+1.0		+inf.0	+nan.0)
  (test	-1.0		+inf.0	-nan.0+nan.0i)
  (test	+nan.0		+inf.0	+nan.0)
  (test	+inf.0		+inf.0	+inf.0+0.0i)
  (test	-inf.0		+inf.0	+nan.0+nan.0i)
  (test +2.0		+inf.0	+inf.0)
  (test -2.0		+inf.0	-nan.0+nan.0i)

  (test	+0.0		-inf.0	+inf.0)
  (test	-0.0		-inf.0	-inf.0)
  (test	+1.0		-inf.0	+nan.0)
  (test	-1.0		-inf.0	+nan.0+nan.0i)
  (test	+nan.0		-inf.0	+nan.0)
  (test	+inf.0		-inf.0	+0.0)
  (test	-inf.0		-inf.0	-nan.0+nan.0i)
  (test +2.0		-inf.0	+0.0)
  (test -2.0		-inf.0	-nan.0+nan.0i)

  (test	+0.0		+nan.0	+nan.0)
  (test	-0.0		+nan.0	+nan.0)
  (test	+1.0		+nan.0	+nan.0)
  (test	-1.0		+nan.0	+nan.0)
  (test	+nan.0		+nan.0	+nan.0)
  (test	+inf.0		+nan.0	+nan.0)
  (test	-inf.0		+nan.0	+nan.0)
  (test +2.0		+nan.0	+nan.0)
  (test -2.0		+nan.0	-nan.0)

  #t)


(parametrise ((check-test-name	'cflonum-base))

  (define-syntax test
    (make-inexact-test expt $expt-number-flonum $expt-cflonum-flonum))

  (test	+0.0+0.0i	+0.0	+1.0+0.0i)
  (test	-0.0+0.0i	+0.0	+1.0+0.0i)
  (test	+0.0-0.0i	+0.0	+1.0+0.0i)
  (test	-0.0-0.0i	+0.0	+1.0+0.0i)
  (test	+nan.0+2.0i	+0.0	+nan.0+nan.0i)
  (test	+1.0+nan.0i	+0.0	+nan.0+nan.0i)
  (test	+nan.0+nan.0i	+0.0	+nan.0+nan.0i)
  (test	+inf.0+2.0i	+0.0	+nan.0+nan.0i)
  (test	+1.0+inf.0i	+0.0	+nan.0+nan.0i)
  (test	+inf.0+inf.0i	+0.0	+nan.0+nan.0i)
  (test	-inf.0+2.0i	+0.0	+nan.0+nan.0i)
  (test	+1.0-inf.0i	+0.0	+nan.0+nan.0i)
  (test	-inf.0-inf.0i	+0.0	+nan.0+nan.0i)
  (test	+1.0+2.0i	+0.0	+1.0+0.0i)

  (test	+0.0+0.0i	-0.0	+1.0+0.0i)
  (test	-0.0+0.0i	-0.0	+1.0+0.0i)
  (test	+0.0-0.0i	-0.0	+1.0+0.0i)
  (test	-0.0-0.0i	-0.0	+1.0+0.0i)
  (test	+nan.0+2.0i	-0.0	+nan.0+nan.0i)
  (test	+1.0+nan.0i	-0.0	+nan.0+nan.0i)
  (test	+nan.0+nan.0i	-0.0	+nan.0+nan.0i)
  (test	+inf.0+2.0i	-0.0	+nan.0+nan.0i)
  (test	+1.0+inf.0i	-0.0	+nan.0+nan.0i)
  (test	+inf.0+inf.0i	-0.0	+nan.0+nan.0i)
  (test	-inf.0+2.0i	-0.0	+nan.0+nan.0i)
  (test	+1.0-inf.0i	-0.0	+nan.0+nan.0i)
  (test	-inf.0-inf.0i	-0.0	+nan.0+nan.0i)
  (test	+1.0+2.0i	-0.0	+1.0+0.0i)

  (test	+0.0+0.0i	+1.0	+0.0+0.0i)
  (test	-0.0+0.0i	+1.0	-0.0+0.0i)
  (test	+0.0-0.0i	+1.0	+0.0-0.0i)
  (test	-0.0-0.0i	+1.0	-0.0-0.0i)
  (test	+nan.0+2.0i	+1.0	+nan.0+2.0i)
  (test	+1.0+nan.0i	+1.0	+1.0+nan.0i)
  (test	+nan.0+nan.0i	+1.0	+nan.0+nan.0i)
  (test	+inf.0+2.0i	+1.0	+inf.0+2.0i)
  (test	+1.0+inf.0i	+1.0	+1.0+inf.0i)
  (test	+inf.0+inf.0i	+1.0	+inf.0+inf.0i)
  (test	-inf.0+2.0i	+1.0	-inf.0+2.0i)
  (test	+1.0-inf.0i	+1.0	+1.0-inf.0i)
  (test	-inf.0-inf.0i	+1.0	-inf.0-inf.0i)
  (test	+1.0+2.0i	+1.0	+1.0+2.0i)

  (test	+0.0+0.0i	-1.0	+inf.0+nan.0i)
  (test	-0.0+0.0i	-1.0	-inf.0-inf.0i)
  (test	+0.0-0.0i	-1.0	+inf.0+nan.0i)
  (test	-0.0-0.0i	-1.0	-inf.0+inf.0i)
  (test	+nan.0+2.0i	-1.0	+nan.0+nan.0i)
  (test	+1.0+nan.0i	-1.0	+nan.0+nan.0i)
  (test	+nan.0+nan.0i	-1.0	+nan.0+nan.0i)
  (test	+inf.0+2.0i	-1.0	0.0-0.0i)
  (test	+1.0+inf.0i	-1.0	+0.0-0.0i)
  (test	+inf.0+inf.0i	-1.0	+0.0-0.0i)
  (test	-inf.0+2.0i	-1.0	-0.0-0.0i)
  (test	+1.0-inf.0i	-1.0	+0.0+0.0i)
  (test	-inf.0-inf.0i	-1.0	-0.0+0.0i)
  (test	+1.0+2.0i	-1.0	+0.2-0.4i)

  (test	+0.0+0.0i	+2.0	+0.0+0.0i)
  (test	-0.0+0.0i	+2.0	-0.0+0.0i)
  (test	+0.0-0.0i	+2.0	+0.0-0.0i)
  (test	-0.0-0.0i	+2.0	-0.0-0.0i)
  (test	+nan.0+2.0i	+2.0	+nan.0+nan.0i)
  (test	+1.0+nan.0i	+2.0	+nan.0+nan.0i)
  (test	+nan.0+nan.0i	+2.0	+nan.0+nan.0i)
  (test	+inf.0+2.0i	+2.0	+inf.0+nan.0i)
  (test	+1.0+inf.0i	+2.0	-inf.0+inf.0i)
  (test	+inf.0+inf.0i	+2.0	+inf.0+inf.0i)
  (test	-inf.0+2.0i	+2.0	+inf.0-inf.0i)
  (test	+1.0-inf.0i	+2.0	-inf.0-inf.0i)
  (test	-inf.0-inf.0i	+2.0	-inf.0+inf.0i)
  (test	+1.0+2.0i	+2.0	-3.0+4.0i)

  (test	+0.0+0.0i	-2.0	+inf.0+nan.0i)
  (test	-0.0+0.0i	-2.0	+inf.0+inf.0i)
  (test	+0.0-0.0i	-2.0	+inf.0+nan.0i)
  (test	-0.0-0.0i	-2.0	+inf.0-inf.0i)
  (test	+nan.0+2.0i	-2.0	+nan.0+nan.0i)
  (test	+1.0+nan.0i	-2.0	+nan.0+nan.0i)
  (test	+nan.0+nan.0i	-2.0	+nan.0+nan.0i)
  (test	+inf.0+2.0i	-2.0	0.0-0.0i)
  (test	+1.0+inf.0i	-2.0	+0.0-0.0i)
  (test	+inf.0+inf.0i	-2.0	+0.0-0.0i)
  (test	-inf.0+2.0i	-2.0	-0.0-0.0i)
  (test	+1.0-inf.0i	-2.0	+0.0+0.0i)
  (test	-inf.0-inf.0i	-2.0	-0.0+0.0i)
  (test	+1.0+2.0i	-2.0	-0.12-0.16i)

  (test	+0.0+0.0i	+3.0	+0.0+0.0i)
  (test	-0.0+0.0i	+3.0	-0.0+0.0i)
  (test	+0.0-0.0i	+3.0	+0.0-0.0i)
  (test	-0.0-0.0i	+3.0	-0.0-0.0i)
  (test	+nan.0+2.0i	+3.0	+nan.0+nan.0i)
  (test	+1.0+nan.0i	+3.0	+nan.0+nan.0i)
  (test	+nan.0+nan.0i	+3.0	+nan.0+nan.0i)
  (test	+inf.0+2.0i	+3.0	+inf.0+nan.0i)
  (test	+1.0+inf.0i	+3.0	-inf.0-inf.0i)
  (test	+inf.0+inf.0i	+3.0	-inf.0+inf.0i)
  (test	-inf.0+2.0i	+3.0	-inf.0+inf.0i)
  (test	+1.0-inf.0i	+3.0	-inf.0+inf.0i)
  (test	-inf.0-inf.0i	+3.0	+inf.0-inf.0i)
  (test	+1.0+2.0i	+3.0	-11.0-2.0i)

  (test	+0.0+0.0i	-3.0	+inf.0+nan.0i)
  (test	-0.0+0.0i	-3.0	-inf.0-inf.0i)
  (test	+0.0-0.0i	-3.0	+inf.0+nan.0i)
  (test	-0.0-0.0i	-3.0	-inf.0+inf.0i)
  (test	+nan.0+2.0i	-3.0	+nan.0+nan.0i)
  (test	+1.0+nan.0i	-3.0	+nan.0+nan.0i)
  (test	+nan.0+nan.0i	-3.0	+nan.0+nan.0i)
  (test	+inf.0+2.0i	-3.0	0.0-0.0i)
  (test	+1.0+inf.0i	-3.0	+0.0-0.0i)
  (test	+inf.0+inf.0i	-3.0	+0.0-0.0i)
  (test	-inf.0+2.0i	-3.0	-0.0-0.0i)
  (test	+1.0-inf.0i	-3.0	+0.0+0.0i)
  (test	-inf.0-inf.0i	-3.0	-0.0+0.0i)
  (test	+1.0+2.0i	-3.0	-0.088+0.016i)

  (test	+0.0+0.0i	+inf.0	+0.0+0.0i)
  (test	-0.0+0.0i	+inf.0	-0.0+0.0i)
  (test	+0.0-0.0i	+inf.0	+0.0-0.0i)
  (test	-0.0-0.0i	+inf.0	-0.0-0.0i)
  (test	+nan.0+2.0i	+inf.0	+nan.0+nan.0i)
  (test	+1.0+nan.0i	+inf.0	+nan.0+nan.0i)
  (test	+nan.0+nan.0i	+inf.0	+nan.0+nan.0i)
  (test	+inf.0+2.0i	+inf.0	+nan.0+nan.0i)
  (test	+1.0+inf.0i	+inf.0	+nan.0+nan.0i)
  (test	+inf.0+inf.0i	+inf.0	+nan.0+nan.0i)
  (test	-inf.0+2.0i	+inf.0	+nan.0+nan.0i)
  (test	+1.0-inf.0i	+inf.0	+nan.0+nan.0i)
  (test	-inf.0-inf.0i	+inf.0	+nan.0+nan.0i)
  (test	+1.0+2.0i	+inf.0	+nan.0+nan.0i)

  (test	+0.0+0.0i	-inf.0	+nan.0+nan.0i)
  (test	-0.0+0.0i	-inf.0	+nan.0+nan.0i)
  (test	+0.0-0.0i	-inf.0	+nan.0+nan.0i)
  (test	-0.0-0.0i	-inf.0	+nan.0+nan.0i)
  (test	+nan.0+2.0i	-inf.0	+nan.0+nan.0i)
  (test	+1.0+nan.0i	-inf.0	+nan.0+nan.0i)
  (test	+nan.0+nan.0i	-inf.0	+nan.0+nan.0i)
  (test	+inf.0+2.0i	-inf.0	+nan.0+nan.0i)
  (test	+1.0+inf.0i	-inf.0	+nan.0+nan.0i)
  (test	+inf.0+inf.0i	-inf.0	+nan.0+nan.0i)
  (test	-inf.0+2.0i	-inf.0	+nan.0+nan.0i)
  (test	+1.0-inf.0i	-inf.0	+nan.0+nan.0i)
  (test	-inf.0-inf.0i	-inf.0	+nan.0+nan.0i)
  (test	+1.0+2.0i	-inf.0	+nan.0+nan.0i)

  (test	+0.0+0.0i	+nan.0	+nan.0+nan.0i)
  (test	-0.0+0.0i	+nan.0	+nan.0+nan.0i)
  (test	+0.0-0.0i	+nan.0	+nan.0+nan.0i)
  (test	-0.0-0.0i	+nan.0	+nan.0+nan.0i)
  (test	+nan.0+2.0i	+nan.0	+nan.0+nan.0i)
  (test	+1.0+nan.0i	+nan.0	+nan.0+nan.0i)
  (test	+nan.0+nan.0i	+nan.0	+nan.0+nan.0i)
  (test	+inf.0+2.0i	+nan.0	+nan.0+nan.0i)
  (test	+1.0+inf.0i	+nan.0	+nan.0+nan.0i)
  (test	+inf.0+inf.0i	+nan.0	+nan.0+nan.0i)
  (test	-inf.0+2.0i	+nan.0	+nan.0+nan.0i)
  (test	+1.0-inf.0i	+nan.0	+nan.0+nan.0i)
  (test	-inf.0-inf.0i	+nan.0	+nan.0+nan.0i)
  (test	+1.0+2.0i	+nan.0	+nan.0+nan.0i)

  #t)


(parametrise ((check-test-name	'compnum-base))

  (define-syntax test
    (make-inexact-test expt $expt-number-flonum $expt-compnum-flonum))

  (test	+1.0+2i		+1.2	0.6299893381068001+2.549855239259246i)

  #t)


;;;; done

(check-report)

;;; end of file
