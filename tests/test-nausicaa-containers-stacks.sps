;;;
;;;Part of: Vicare Scheme
;;;Contents: tests for stacks
;;;Date: Wed Oct 14, 2009
;;;
;;;Abstract
;;;
;;;
;;;
;;;Copyright (c) 2009, 2010, 2013, 2014 Marco Maggi <marco.maggi-ipsu@poste.it>
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


#!vicare
(import (nausicaa)
  (nausicaa containers stacks)
  (vicare arguments validation)
  (vicare checks))

(check-set-mode! 'report-failed)
(check-display "*** testing Nausicaa libraries: stack containers\n")


(parametrise ((check-test-name 'making))

  (check
      (let ((q (<stack> ())))
	(is-a? q <stack>))
    => #t)

  (check
      (let ((q (<stack> (1))))
	(is-a? q <stack>))
    => #t)

  (check
      (let ((q (<stack> (1 2 3))))
	(is-a? q <stack>))
    => #t)

  #t)


(parametrise ((check-test-name		'object))

  (define who 'test)

;;; hash

  (check-for-true
   (let (({S <stack>} (<stack> (1 2 3))))
     (integer? (S hash))))

  (check
      (let (({A <stack>}     (<stack> (1 2 3)))
	    ({B <stack>}     (<stack> (1 2 3)))
	    ({T <hashtable>} (make-hashtable (lambda ({S <stack>})
					       (S hash))
					     eq?)))
	(set! T[A] 1)
	(set! T[B] 2)
	(list (T[A])
	      (T[B])))
    => '(1 2))

;;; --------------------------------------------------------------------
;;; properties

  (check
      (let (({S <stack>} (<stack> (1 2 3))))
	(S property-list))
    => '())

  (check
      (let (({S <stack>} (<stack> (1 2 3))))
	(S putprop 'ciao 'salut)
	(S getprop 'ciao))
    => 'salut)

  (check
      (let (({S <stack>} (<stack> (1 2 3))))
	(S getprop 'ciao))
    => #f)

  (check
      (let (({S <stack>} (<stack> (1 2 3))))
	(S putprop 'ciao 'salut)
	(S remprop 'ciao)
	(S getprop 'ciao))
    => #f)

  (check
      (let (({S <stack>} (<stack> (1 2 3))))
	(S putprop 'ciao 'salut)
	(S putprop 'hello 'ohayo)
	(list (S getprop 'ciao)
	      (S getprop 'hello)))
    => '(salut ohayo))

;;; --------------------------------------------------------------------
;;; arguments validation

  (check-for-true
   (let ((S (<stack> (1 2 3))))
     (with-arguments-validation (who)
	 ((<stack>	S))
       #t)))

;;;

  (check-for-procedure-argument-violation
      (let ((S 123))
	(with-arguments-validation (who)
	    ((<stack>	S))
	  #t))
    => (list who '(123)))

  #f)


(parametrise ((check-test-name 'pred))

  (check
      (let (({S <stack>} (<stack> ())))
	(S empty?))
    => #t)

  (check
      (let (({S <stack>} (<stack> (1))))
	(S empty?))
    => #f)

  (check
      (let (({S <stack>} (<stack> (1 2 3))))
	(S empty?))
    => #f)

;;; --------------------------------------------------------------------

  (check
      (let (({S <stack>} (<stack> ())))
	(S not-empty?))
    => #f)

  (check
      (let (({S <stack>} (<stack> (1))))
	(S not-empty?))
    => #t)

  (check
      (let (({S <stack>} (<stack> (1 2 3))))
	(S not-empty?))
    => #t)

  #t)


(parametrise ((check-test-name 'inspect))

  (check
      (let (({S <stack>} (<stack> ())))
	(S size))
    => 0)

  (check
      (let (({S <stack>} (<stack> (1))))
	(S size))
    => 1)

  (check
      (let (({S <stack>} (<stack> (1 2 3))))
	(S size))
    => 3)

;;; --------------------------------------------------------------------

  (check
      (guard (E (else (condition-message E)))
	(let (({S <stack>} (<stack> ())))
	  (S top)))
    => "stack is empty")

  (check
      (let (({S <stack>} (<stack> (1))))
	(S top))
    => 1)

  (check
      (let (({S <stack>} (<stack> (1 2 3))))
	(S top))
    => 1)

  #t)


(parametrise ((check-test-name 'operations))

  (check
      (let (({q <stack>} (<stack> ())))
	(q push! 1)
	(q push! 2)
	(q push! 3)
	(q list))
    => '(3 2 1))

  (check
      (let (({q <stack>} (<stack> (1 2 3))))
	(q pop!)
	(q pop!)
	(q pop!))
    => 3)

  #t)


(parametrise ((check-test-name 'conversion))

  (check
      (let (({S <stack>} (<stack> ())))
	(S list))
    => '())

  (check
      (let (({S <stack>} (<stack> (1))))
	(S list))
    => '(1))

  (check
      (let (({S <stack>} (<stack> (1 2 3))))
	(S list))
    => '(1 2 3))

;;; --------------------------------------------------------------------

  (check
      (let (({S <stack>} (list->stack '())))
	(S list))
    => '())

  (check
      (let (({S <stack>} (list->stack '(1))))
	(S list))
    => '(1))

  (check
      (let (({S <stack>} (list->stack '(1 2 3))))
	(S list))
    => '(1 2 3))

;;; --------------------------------------------------------------------

  (check
      (let (({S <stack>} (<stack> ())))
	(S vector))
    => '#())

  (check
      (let (({S <stack>} (<stack> (1))))
	(S vector))
    => '#(1))

  (check
      (let (({S <stack>} (<stack> (1 2 3))))
	(S vector))
    => '#(1 2 3))

;;; --------------------------------------------------------------------

  (check
      (let (({S <stack>} (vector->stack '#())))
	(S vector))
    => '#())

  (check
      (let (({S <stack>} (vector->stack '#(1))))
	(S vector))
    => '#(1))

  (check
      (let (({S <stack>} (vector->stack '#(1 2 3))))
	(S vector))
    => '#(1 2 3))

  #t)


;;;; done

(check-report)

;;; end of file
