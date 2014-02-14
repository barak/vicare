;;; -*- coding: utf-8-unix -*-
;;;
;;;Part of: Vicare Scheme
;;;Contents: tests for stack containers
;;;Date: Wed Sep 25, 2013
;;;
;;;Abstract
;;;
;;;
;;;
;;;Copyright (C) 2013 Marco Maggi <marco.maggi-ipsu@poste.it>
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
  (vicare containers stacks)
  (vicare arguments validation)
  (vicare checks))

(check-set-mode! 'report-failed)
(check-display "*** testing Vicare libraries: stack containers\n")


(parametrise ((check-test-name	'making))

  (check
      (stack? (make-stack))
    => #t)

  (check
      (stack->list (make-stack))
    => '())

  (check
      (stack->list (make-stack 1))
    => '(1))

  (check
      (stack->list (make-stack 1 2 3))
    => '(1 2 3))

  #t)


(parametrise ((check-test-name 'pred))

  (check
      (stack-empty? (make-stack))
    => #t)

  (check
      (stack-empty? (make-stack 1))
    => #f)

  (check
      (stack-empty? (make-stack 1 2 3))
    => #f)

  #t)


(parametrise ((check-test-name		'object))

  (define who 'test)

;;; hash

  (check-for-true
   (integer? (stack-hash (make-stack 1 2 3))))

  (check
      (let ((A (make-stack 1 2 3))
	    (B (make-stack 1 2 3))
	    (T (make-hashtable stack-hash eq?)))
	(hashtable-set! T A 1)
	(hashtable-set! T B 2)
	(list (hashtable-ref T A #f)
	      (hashtable-ref T B #f)))
    => '(1 2))

;;; --------------------------------------------------------------------
;;; properties

  (check
      (let ((S (make-stack 1 2 3)))
	(stack-property-list S))
    => '())

  (check
      (let ((S (make-stack 1 2 3)))
	(stack-putprop S 'ciao 'salut)
	(stack-getprop S 'ciao))
    => 'salut)

  (check
      (let ((S (make-stack 1 2 3)))
	(stack-getprop S 'ciao))
    => #f)

  (check
      (let ((S (make-stack 1 2 3)))
	(stack-putprop S 'ciao 'salut)
	(stack-remprop S 'ciao)
	(stack-getprop S 'ciao))
    => #f)

  (check
      (let ((S (make-stack 1 2 3)))
	(stack-putprop S 'ciao 'salut)
	(stack-putprop S 'hello 'ohayo)
	(list (stack-getprop S 'ciao)
	      (stack-getprop S 'hello)))
    => '(salut ohayo))

;;; --------------------------------------------------------------------
;;; arguments validation

  (check-for-true
   (let ((S (make-stack 1 2 3)))
     (with-arguments-validation (who)
	 ((stack	S))
       #t)))

;;;

  (check-for-procedure-argument-violation
      (let ((S 123))
	(with-arguments-validation (who)
	    ((stack	S))
	  #t))
    => (list who '(123)))

  #f)


(parametrise ((check-test-name 'inspect))

  (check
      (stack-size (make-stack))
    => 0)

  (check
      (stack-size (make-stack 1))
    => 1)

  (check
      (stack-size (make-stack 1 2 3))
    => 3)

;;; --------------------------------------------------------------------

  (check
      (guard (E (else (condition-message E)))
	(stack-top (make-stack)))
    => "stack is empty")

  (check
      (stack-top (make-stack 1))
    => 1)

  (check
      (stack-top (make-stack 1 2 3))
    => 1)

  #t)


(parametrise ((check-test-name 'operations))

  (check
      (let ((q (make-stack)))
	(stack-push! q 1)
	(stack-push! q 2)
	(stack-push! q 3)
	(stack->list q))
    => '(3 2 1))

;;; --------------------------------------------------------------------

  (check
      (guard (E (else (condition-message E)))
	(let ((q (make-stack)))
	  (stack-pop! q)))
    => "stack is empty")

  (check
      (let ((q (make-stack 1 2 3)))
	(stack-pop! q))
    => 1)

  (check
      (let ((q (make-stack 1 2 3)))
	(stack-pop! q)
	(stack-pop! q)
	(stack-pop! q))
    => 3)

  (check
      (let ((q (make-stack 1 2 3)))
	(stack-pop! q)
	(stack-pop! q)
	(stack-pop! q)
	(stack-empty? q))
    => #t)

  #t)


(parametrise ((check-test-name 'conversion))

  (check
      (stack->list (make-stack))
    => '())

  (check
      (stack->list (make-stack 1))
    => '(1))

  (check
      (stack->list (make-stack 1 2 3))
    => '(1 2 3))

;;; --------------------------------------------------------------------

  (check
      (stack->vector (make-stack))
    => '#())

  (check
      (stack->vector (make-stack 1))
    => '#(1))

  (check
      (stack->vector (make-stack 1 2 3))
    => '#(1 2 3))

;;; --------------------------------------------------------------------

  (check
      (stack->list (list->stack '()))
    => '())

  (check
      (stack->list (list->stack '(1)))
    => '(1))

  (check
      (stack->list (list->stack '(1 2 3)))
    => '(1 2 3))

;;; --------------------------------------------------------------------

  (check
      (stack->vector (vector->stack '#()))
    => '#())

  (check
      (stack->vector (vector->stack '#(1)))
    => '#(1))

  (check
      (stack->vector (vector->stack '#(1 2 3)))
    => '#(1 2 3))



  #t)


;;;; done

(check-report)

;;; end of file
