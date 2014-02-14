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
;;;MERCHANTABILITY  or FITNESS FOR  A PARTICULAR  PURPOSE.  See  the GNU
;;;General Public License for more details.
;;;
;;;You should  have received  a copy of  the GNU General  Public License
;;;along with this program.  If not, see <http://www.gnu.org/licenses/>.


(library (ikarus ratnums)
  (export
    $ratnum->flonum
    $ratnum-positive?		$ratnum-negative?
    $ratnum-non-positive?	$ratnum-non-negative?)
  (import (ikarus)
    (except (ikarus system $ratnums)
	    $ratnum->flonum
	    $ratnum-positive?		$ratnum-negative?
	    $ratnum-non-positive?	$ratnum-non-negative?)
    (ikarus system $flonums))


(module ($ratnum->flonum)

  (define ($ratnum->flonum num)
    (let ((n ($ratnum-n num)) (d ($ratnum-d num)))
      (if (> n 0)
	  (pos n d)
	(- (pos (- n) d)))))

  (define *precision* 53)

  (define (long-div1 n d)
    (let-values (((q r) (quotient+remainder n d)))
      (cond
       ((< (* r 2) d) (inexact q))
       (else (inexact (+ q 1)))
       ;;(else (error #f "invalid" n d q r))
       )))

  (define (long-div2 n d bits)
    (let f ((bits bits) (ac (long-div1 n d)))
      (cond
       ((= bits 0) ac)
       (else (f (- bits 1) (/ ac 2.0))))))

  (define (pos n d)
    (let ((nbits (bitwise-length n))
	  (dbits (bitwise-length d)))
      (let ((diff-bits (- nbits dbits)))
	(if (>= diff-bits *precision*)
	    (long-div1 n d)
	  (let ((extra-bits (- *precision* diff-bits)))
	    (long-div2 (sll n extra-bits) d extra-bits))))))

  ;; (define ($ratnum->flonum x)
  ;;   (define (->flonum n d)
  ;;     (let-values (((q r) (quotient+remainder n d)))
  ;;       (if (= r 0)
  ;;           (inexact q)
  ;;           (if (= q 0)
  ;;               (/ (->flonum d n))
  ;;               (+ q (->flonum r d))))))
  ;;   (let ((n (numerator x)) (d (denominator x)))
  ;;     (let ((b (bitwise-first-bit-set n)))
  ;;       (if (eqv? b 0)
  ;;           (let ((b (bitwise-first-bit-set d)))
  ;;             (if (eqv? b 0)
  ;;                 (->flonum n d)
  ;;                 (/ (->flonum n (bitwise-arithmetic-shift-right d b))
  ;;                    (expt 2.0 b))))
  ;;           (* (->flonum (bitwise-arithmetic-shift-right n b) d)
  ;;              (expt 2.0 b))))))

  ;; (define ($ratnum->flonum x)
  ;;   (let f ((n ($ratnum-n x)) (d ($ratnum-d x)))
  ;;     (let-values (((q r) (quotient+remainder n d)))
  ;;       (if (= q 0)
  ;;           (/ 1.0 (f d n))
  ;;           (if (= r 0)
  ;;               (inexact q)
  ;;               (+ q (f r d)))))))

  ;; (define ($ratnum->flonum num)
  ;;   (define (rat n m)
  ;;     (let-values (((q r) (quotient+remainder n m)))
  ;;        (if (= r 0)
  ;;            (inexact q)
  ;;            (fl+ (inexact q) (fl/ 1.0 (rat  m r))))))
  ;;   (define (pos n d)
  ;;     (cond
  ;;       ((even? n)
  ;;        (* (pos (sra n 1) d) 2.0))
  ;;       ((even? d)
  ;;        (/ (pos n (sra d 1)) 2.0))
  ;;       ((> n d) (rat n d))
  ;;       (else
  ;;        (/ (rat d n)))))
  ;;   (let ((n ($ratnum-n num)) (d ($ratnum-d num)))
  ;;     (if (> n 0)
  ;;         (pos n d)
  ;;         (- (pos (- n) d)))))

  #| end of module |# )


;;;; predicates

(define ($ratnum-positive? Q)
  ;;The denominator of a properly constructed ratnum is always positive;
  ;;the sign of a ratnum is the sign of the numerator.
  ;;
  (positive? ($ratnum-num Q)))

(define ($ratnum-negative? Q)
  ;;The denominator of a properly constructed ratnum is always positive;
  ;;the sign of a ratnum is the sign of the numerator.
  ;;
  (negative? ($ratnum-num Q)))

;;; --------------------------------------------------------------------

(define ($ratnum-non-positive? x)
  ;;The denominator of a ratnum is always strictly positive.
  ;;
  (non-positive? ($ratnum-n x)))

(define ($ratnum-non-negative? x)
  ;;The denominator of a ratnum is always strictly positive.
  ;;
  (non-negative? ($ratnum-n x)))


;;;; done

)

;;; end of file
