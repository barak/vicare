;;; -*- coding: utf-8-unix -*-
;;;
;;;Part of: Vicare
;;;Contents: tests
;;;Date: Tue Oct 18, 2011
;;;
;;;Abstract
;;;
;;;	Tests  from the  file "scheme/tests/hashtables.ss"  file  in the
;;;	original Ikarus distribution.
;;;
;;;Copyright (C) 2006-2010 Abdulaziz Ghuloum <aghuloum@cs.indiana.edu>
;;;Modified by Marco Maggi <marco.maggi-ipsu@poste.it>
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

#!ikarus
(import (vicare)
  (rnrs hashtables)
  (libtest ikarus-test-framework)
  (vicare checks))

(define (run-tests) (test-hashtables))

(define-tests test-hashtables
  [values
   (let ([h (make-eq-hashtable)])
     (hashtable-set! h 'foo 12)
     (hashtable-set! h 'bar 13)
     (or (equal? (hashtable-keys h) '#(foo bar))
	 (equal? (hashtable-keys h) '#(bar foo))))]
  [values
   (let ([h (make-eq-hashtable)])
     (hashtable-set! h 'foo 12)
     (hashtable-set! h 'bar 13)
     (hashtable-clear! h)
     (equal? (hashtable-keys h) '#()))]
  )

(check-display "*** testing hashtables\n")
(run-tests)
(check-display "; *** done\n\n")

;;; end of file
