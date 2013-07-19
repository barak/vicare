;;; -*- coding: utf-8-unix -*-
;;;
;;;Part of: Vicare Scheme
;;;Contents: tests for numerics functions: gcd
;;;Date: Fri Nov 30, 2012
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
;;;MERCHANTABILITY or  FITNESS FOR  A PARTICULAR  PURPOSE.  See  the GNU
;;;General Public License for more details.
;;;
;;;You should  have received a  copy of  the GNU General  Public License
;;;along with this program.  If not, see <http://www.gnu.org/licenses/>.
;;;


#!r6rs
(import (vicare)
  (numerics helpers)
  (ikarus system $ratnums)
  (ikarus system $compnums)
  (ikarus system $numerics)
  (vicare checks))

(check-set-mode! 'report-failed)
(check-display "*** testing Vicare numerics functions: gcd, greatest common divisor\n")



;;Only integer flonums for this operation.
(define IFL1		+0.0)
(define IFL2		-0.0)
(define IFL3		+1.0)
(define IFL4		-1.0)
(define IFL5		+2.0)
(define IFL6		-2.0)


(parametrise ((check-test-name	'fixnums))

  (let-syntax ((test (make-test gcd $gcd-fixnum-fixnum)))
    (test 0 1 1)
    (test 0 -1 1)
    (test FX1 FX1 1)
    (test FX2 FX1 1)
    (test FX3 FX1 1)
    (test FX4 FX1 1)
    (test FX1 FX2 1)
    (test FX2 FX2 1)
    (test FX3 FX2 1)
    (test FX4 FX2 1)
    (test FX1 FX3 1)
    (test FX2 FX3 1)
    (test FX3 FX3 536870911)
    (test FX4 FX3 1)
    (test FX1 FX4 1)
    (test FX2 FX4 1)
    (test FX3 FX4 1)
    (test FX4 FX4 536870912)
    #f)

  (let-syntax ((test (make-test gcd #;$gcd-fixnum-bignum)))
    (test FX1 BN1 1)
    (test FX2 BN1 1)
    (test FX3 BN1 1)
    (test FX4 BN1 536870912)
    (test FX1 BN2 1)
    (test FX2 BN2 1)
    (test FX3 BN2 1)
    (test FX4 BN2 1)
    (test FX1 BN3 1)
    (test FX2 BN3 1)
    (test FX3 BN3 1)
    (test FX4 BN3 1)
    (test FX1 BN4 1)
    (test FX2 BN4 1)
    (test FX3 BN4 1)
    (test FX4 BN4 4)
    #f)

  (let-syntax ((test (make-flonum-test gcd $gcd-fixnum-flonum)))
    (test FX1 IFL1 1.0)
    (test FX2 IFL1 1.0)
    (test FX3 IFL1 536870911.0)
    (test FX4 IFL1 536870912.0)
    (test FX1 IFL2 1.0)
    (test FX2 IFL2 1.0)
    (test FX3 IFL2 536870911.0)
    (test FX4 IFL2 536870912.0)
    (test FX1 IFL3 1.0)
    (test FX2 IFL3 1.0)
    (test FX3 IFL3 1.0)
    (test FX4 IFL3 1.0)
    (test FX1 IFL4 1.0)
    (test FX2 IFL4 1.0)
    (test FX3 IFL4 1.0)
    (test FX4 IFL4 1.0)
    (test FX1 IFL5 1.0)
    (test FX2 IFL5 1.0)
    (test FX3 IFL5 1.0)
    (test FX4 IFL5 2.0)
    (test FX1 IFL6 1.0)
    (test FX2 IFL6 1.0)
    (test FX3 IFL6 1.0)
    (test FX4 IFL6 2.0)
    #f)

  (let-syntax ((test (make-test gcd $gcd-fixnum-bignum)))
    (test FX1 VBN1 1)
    (test FX2 VBN1 1)
    (test FX3 VBN1 1)
    (test FX4 VBN1 536870912)
    (test FX1 VBN2 1)
    (test FX2 VBN2 1)
    (test FX3 VBN2 1)
    (test FX4 VBN2 1)
    (test FX1 VBN3 1)
    (test FX2 VBN3 1)
    (test FX3 VBN3 1)
    (test FX4 VBN3 1)
    (test FX1 VBN4 1)
    (test FX2 VBN4 1)
    (test FX3 VBN4 1)
    (test FX4 VBN4 4)
    #f)

  #t)


(parametrise ((check-test-name	'bignums))

  (let-syntax ((test (make-test gcd #;$gcd-bignum-fixnum)))
    (test BN1 FX1 1)
    (test BN2 FX1 1)
    (test BN3 FX1 1)
    (test BN4 FX1 1)
    (test BN1 FX2 1)
    (test BN2 FX2 1)
    (test BN3 FX2 1)
    (test BN4 FX2 1)
    (test BN1 FX3 1)
    (test BN2 FX3 1)
    (test BN3 FX3 1)
    (test BN4 FX3 1)
    (test BN1 FX4 536870912)
    (test BN2 FX4 1)
    (test BN3 FX4 1)
    (test BN4 FX4 4)
    #f)

  (let-syntax ((test (make-test gcd #;$gcd-bignum-bignum)))
    (test BN1 BN1 536870912)
    (test BN2 BN1 1)
    (test BN3 BN1 1)
    (test BN4 BN1 4)
    (test BN1 BN2 1)
    (test BN2 BN2 536871011)
    (test BN3 BN2 1)
    (test BN4 BN2 1)
    (test BN1 BN3 1)
    (test BN2 BN3 1)
    (test BN3 BN3 536870913)
    (test BN4 BN3 3)
    (test BN1 BN4 4)
    (test BN2 BN4 1)
    (test BN3 BN4 3)
    (test BN4 BN4 536871012)
    #f)

  (let-syntax ((test (make-inexact-test gcd #;$gcd-bignum-flonum)))
    (test BN1 IFL1 536870912.0)
    (test BN2 IFL1 536871011.0)
    (test BN3 IFL1 536870913.0)
    (test BN4 IFL1 536871012.0)
    (test BN1 IFL2 536870912.0)
    (test BN2 IFL2 536871011.0)
    (test BN3 IFL2 536870913.0)
    (test BN4 IFL2 536871012.0)
    (test BN1 IFL3 1.0)
    (test BN2 IFL3 1.0)
    (test BN3 IFL3 1.0)
    (test BN4 IFL3 1.0)
    (test BN1 IFL4 1.0)
    (test BN2 IFL4 1.0)
    (test BN3 IFL4 1.0)
    (test BN4 IFL4 1.0)
    (test BN1 IFL5 2.0)
    (test BN2 IFL5 1.0)
    (test BN3 IFL5 1.0)
    (test BN4 IFL5 2.0)
    (test BN1 IFL6 2.0)
    (test BN2 IFL6 1.0)
    (test BN3 IFL6 1.0)
    (test BN4 IFL6 2.0)
    #f)

;;; --------------------------------------------------------------------

  (let-syntax ((test (make-test gcd $gcd-bignum-fixnum)))
    (test VBN1 FX1 1)
    (test VBN2 FX1 1)
    (test VBN3 FX1 1)
    (test VBN4 FX1 1)
    (test VBN1 FX2 1)
    (test VBN2 FX2 1)
    (test VBN3 FX2 1)
    (test VBN4 FX2 1)
    (test VBN1 FX3 1)
    (test VBN2 FX3 1)
    (test VBN3 FX3 1)
    (test VBN4 FX3 1)
    (test VBN1 FX4 536870912)
    (test VBN2 FX4 1)
    (test VBN3 FX4 1)
    (test VBN4 FX4 4)
    #f)

  (let-syntax ((test (make-test gcd $gcd-bignum-bignum)))
    (test VBN1 VBN1 1152921504606846976)
    (test VBN2 VBN1 1)
    (test VBN3 VBN1 1)
    (test VBN4 VBN1 4)
    (test VBN1 VBN2 1)
    (test VBN2 VBN2 1152921504606847075)
    (test VBN3 VBN2 1)
    (test VBN4 VBN2 1)
    (test VBN1 VBN3 1)
    (test VBN2 VBN3 1)
    (test VBN3 VBN3 1152921504606846977)
    (test VBN4 VBN3 1)
    (test VBN1 VBN4 4)
    (test VBN2 VBN4 1)
    (test VBN3 VBN4 1)
    (test VBN4 VBN4 1152921504606847076)
    #f)

  (let-syntax ((test (make-inexact-test gcd $gcd-bignum-flonum)))
    (test VBN1 IFL1 1.152921504606847e+18)
    (test VBN2 IFL1 1.152921504606847e+18)
    (test VBN3 IFL1 1.152921504606847e+18)
    (test VBN4 IFL1 1.152921504606847e+18)
    (test VBN1 IFL2 1.152921504606847e+18)
    (test VBN2 IFL2 1.152921504606847e+18)
    (test VBN3 IFL2 1.152921504606847e+18)
    (test VBN4 IFL2 1.152921504606847e+18)
    (test VBN1 IFL3 1.0)
    (test VBN2 IFL3 1.0)
    (test VBN3 IFL3 1.0)
    (test VBN4 IFL3 1.0)
    (test VBN1 IFL4 1.0)
    (test VBN2 IFL4 1.0)
    (test VBN3 IFL4 1.0)
    (test VBN4 IFL4 1.0)
    (test VBN1 IFL5 2.0)
    (test VBN2 IFL5 1.0)
    (test VBN3 IFL5 1.0)
    (test VBN4 IFL5 2.0)
    (test VBN1 IFL6 2.0)
    (test VBN2 IFL6 1.0)
    (test VBN3 IFL6 1.0)
    (test VBN4 IFL6 2.0)
    #f)

  #t)


(parametrise ((check-test-name	'flonums))

  (let-syntax ((test (make-inexact-test gcd $gcd-flonum-fixnum)))
    (test IFL1 FX1 1.0)
    (test IFL2 FX1 1.0)
    (test IFL3 FX1 1.0)
    (test IFL4 FX1 1.0)
    (test IFL5 FX1 1.0)
    (test IFL6 FX1 1.0)
    (test IFL1 FX2 1.0)
    (test IFL2 FX2 1.0)
    (test IFL3 FX2 1.0)
    (test IFL4 FX2 1.0)
    (test IFL5 FX2 1.0)
    (test IFL6 FX2 1.0)
    (test IFL1 FX3 536870911.0)
    (test IFL2 FX3 536870911.0)
    (test IFL3 FX3 1.0)
    (test IFL4 FX3 1.0)
    (test IFL5 FX3 1.0)
    (test IFL6 FX3 1.0)
    (test IFL1 FX4 536870912.0)
    (test IFL2 FX4 536870912.0)
    (test IFL3 FX4 1.0)
    (test IFL4 FX4 1.0)
    (test IFL5 FX4 2.0)
    (test IFL6 FX4 2.0)
    #f)

  (let-syntax ((test (make-inexact-test gcd #;$gcd-flonum-bignum)))
    (test IFL1 BN1 536870912.0)
    (test IFL2 BN1 536870912.0)
    (test IFL3 BN1 1.0)
    (test IFL4 BN1 1.0)
    (test IFL5 BN1 2.0)
    (test IFL6 BN1 2.0)
    (test IFL1 BN2 536871011.0)
    (test IFL2 BN2 536871011.0)
    (test IFL3 BN2 1.0)
    (test IFL4 BN2 1.0)
    (test IFL5 BN2 1.0)
    (test IFL6 BN2 1.0)
    (test IFL1 BN3 536870913.0)
    (test IFL2 BN3 536870913.0)
    (test IFL3 BN3 1.0)
    (test IFL4 BN3 1.0)
    (test IFL5 BN3 1.0)
    (test IFL6 BN3 1.0)
    (test IFL1 BN4 536871012.0)
    (test IFL2 BN4 536871012.0)
    (test IFL3 BN4 1.0)
    (test IFL4 BN4 1.0)
    (test IFL5 BN4 2.0)
    (test IFL6 BN4 2.0)
    #f)

  (let-syntax ((test (make-flonum-test gcd $gcd-flonum-flonum)))
    (test 25.0 10.0 5.0)
    (test 10.0 25.0 5.0)
    (test IFL1 IFL1 0.0)
    (test IFL2 IFL1 0.0)
    (test IFL3 IFL1 1.0)
    (test IFL4 IFL1 1.0)
    (test IFL5 IFL1 2.0)
    (test IFL6 IFL1 2.0)
    (test IFL1 IFL2 0.0)
    (test IFL2 IFL2 0.0)
    (test IFL3 IFL2 1.0)
    (test IFL4 IFL2 1.0)
    (test IFL5 IFL2 2.0)
    (test IFL6 IFL2 2.0)
    (test IFL1 IFL3 1.0)
    (test IFL2 IFL3 1.0)
    (test IFL3 IFL3 1.0)
    (test IFL4 IFL3 1.0)
    (test IFL5 IFL3 1.0)
    (test IFL6 IFL3 1.0)
    (test IFL1 IFL4 1.0)
    (test IFL2 IFL4 1.0)
    (test IFL3 IFL4 1.0)
    (test IFL4 IFL4 1.0)
    (test IFL5 IFL4 1.0)
    (test IFL6 IFL4 1.0)
    (test IFL1 IFL5 2.0)
    (test IFL2 IFL5 2.0)
    (test IFL3 IFL5 1.0)
    (test IFL4 IFL5 1.0)
    (test IFL5 IFL5 2.0)
    (test IFL6 IFL5 2.0)
    (test IFL1 IFL6 2.0)
    (test IFL2 IFL6 2.0)
    (test IFL3 IFL6 1.0)
    (test IFL4 IFL6 1.0)
    (test IFL5 IFL6 2.0)
    (test IFL6 IFL6 2.0)
    #f)

  (let-syntax ((test (make-inexact-test gcd $gcd-flonum-bignum)))
    (test IFL1 VBN1 1.152921504606847e+18)
    (test IFL2 VBN1 1.152921504606847e+18)
    (test IFL3 VBN1 1.0)
    (test IFL4 VBN1 1.0)
    (test IFL5 VBN1 2.0)
    (test IFL6 VBN1 2.0)
    (test IFL1 VBN2 1.152921504606847e+18)
    (test IFL2 VBN2 1.152921504606847e+18)
    (test IFL3 VBN2 1.0)
    (test IFL4 VBN2 1.0)
    (test IFL5 VBN2 1.0)
    (test IFL6 VBN2 1.0)
    (test IFL1 VBN3 1.152921504606847e+18)
    (test IFL2 VBN3 1.152921504606847e+18)
    (test IFL3 VBN3 1.0)
    (test IFL4 VBN3 1.0)
    (test IFL5 VBN3 1.0)
    (test IFL6 VBN3 1.0)
    (test IFL1 VBN4 1.152921504606847e+18)
    (test IFL2 VBN4 1.152921504606847e+18)
    (test IFL3 VBN4 1.0)
    (test IFL4 VBN4 1.0)
    (test IFL5 VBN4 2.0)
    (test IFL6 VBN4 2.0)
    #f)

  #t)


;;;; done

(check-report)

;;; end of file
