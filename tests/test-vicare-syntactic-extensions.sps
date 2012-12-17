;;; -*- coding: utf-8-unix -*-
;;;
;;;Part of: Vicare Scheme
;;;Contents: tests for (vicare syntactic-extensions)
;;;Date: Thu Sep 13, 2012
;;;
;;;Abstract
;;;
;;;
;;;Copyright (c) 2010, 2012 Marco Maggi <marco.maggi-ipsu@poste.it>
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


(import (vicare)
  (vicare syntactic-extensions)
  (vicare checks))

(check-set-mode! 'report-failed)
(check-display "*** testing Vicare syntactic extensions library\n")


(parametrise ((check-test-name	'case-integers))

  (check
      (case-integers 123
	((123)	#t)
	((456)	#f))
    => #t)

  (check
      (case-integers 456
	((123)	#t)
	((456)	#f))
    => #f)

  (check
      (case-integers 789
	((123)	#t)
	((456)	#f))
    => (void))

;;; --------------------------------------------------------------------

  (check
      (case-integers 123
	((123)	1)
	((456)	2)
	(else	3))
    => 1)

  (check
      (case-integers 456
	((123)	1)
	((456)	2)
	(else   3))
    => 2)

  (check
      (case-integers 789
	((123)	1)
	((456)	2)
	(else	3))
    => 3)

;;; --------------------------------------------------------------------

  (check
      (case-integers 1
	((1 2 3)	#t)
	((4)		#f))
    => #t)

  (check
      (case-integers 2
	((1 2 3)	#t)
	((4)		#f))
    => #t)

  (check
      (case-integers 3
	((1 2 3)	#t)
	((4)		#f))
    => #t)

  (check
      (case-integers 4
	((1 2 3)	#t)
	((4)		#f))
    => #f)

  (check
      (case-integers 5
	((1 2 3)	#t)
	((4)		#f))
    => (void))

;;; --------------------------------------------------------------------

  (check
      (case-integers 1
	((1 2 3)	#t)
	((4)		#f)
	(else		0))
    => #t)

  (check
      (case-integers 2
	((1 2 3)	#t)
	((4)		#f)
	(else		0))
    => #t)

  (check
      (case-integers 3
	((1 2 3)	#t)
	((4)		#f)
	(else		0))
    => #t)

  (check
      (case-integers 4
	((1 2 3)	#t)
	((4)		#f)
	(else		0))
    => #f)

  (check
      (case-integers 5
	((1 2 3)	#t)
	((4)		#f)
	(else		0))
    => 0)

  #f)


(parametrise ((check-test-name	'case-fixnums))

  (check
      (case-fixnums 123
	((123)	#t)
	((456)	#f))
    => #t)

  (check
      (case-fixnums 456
	((123)	#t)
	((456)	#f))
    => #f)

  (check
      (case-fixnums 789
	((123)	#t)
	((456)	#f))
    => (void))

;;; --------------------------------------------------------------------

  (check
      (case-fixnums 123
	((123)	1)
	((456)	2)
	(else	3))
    => 1)

  (check
      (case-fixnums 456
	((123)	1)
	((456)	2)
	(else   3))
    => 2)

  (check
      (case-fixnums 789
	((123)	1)
	((456)	2)
	(else	3))
    => 3)

;;; --------------------------------------------------------------------

  (check
      (case-fixnums 1
	((1 2 3)	#t)
	((4)		#f))
    => #t)

  (check
      (case-fixnums 2
	((1 2 3)	#t)
	((4)		#f))
    => #t)

  (check
      (case-fixnums 3
	((1 2 3)	#t)
	((4)		#f))
    => #t)

  (check
      (case-fixnums 4
	((1 2 3)	#t)
	((4)		#f))
    => #f)

  (check
      (case-fixnums 5
	((1 2 3)	#t)
	((4)		#f))
    => (void))

;;; --------------------------------------------------------------------

  (check
      (case-fixnums 1
	((1 2 3)	#t)
	((4)		#f)
	(else		0))
    => #t)

  (check
      (case-fixnums 2
	((1 2 3)	#t)
	((4)		#f)
	(else		0))
    => #t)

  (check
      (case-fixnums 3
	((1 2 3)	#t)
	((4)		#f)
	(else		0))
    => #t)

  (check
      (case-fixnums 4
	((1 2 3)	#t)
	((4)		#f)
	(else		0))
    => #f)

  (check
      (case-fixnums 5
	((1 2 3)	#t)
	((4)		#f)
	(else		0))
    => 0)

  #f)


;;;; done

(check-report)

;;; end of file
