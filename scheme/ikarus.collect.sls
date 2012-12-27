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


(library (ikarus collect)
  (export
    do-overflow			do-overflow-words
    do-vararg-overflow		do-stack-overflow
    collect			collect-key
    post-gc-hooks

    register-to-avoid-collecting
    forget-to-avoid-collecting
    replace-to-avoid-collecting
    retrieve-to-avoid-collecting
    collection-avoidance-list
    purge-collection-avoidance-list)
  (import (except (ikarus)
		  collect		collect-key
		  post-gc-hooks

		  register-to-avoid-collecting
		  forget-to-avoid-collecting
		  replace-to-avoid-collecting
		  retrieve-to-avoid-collecting
		  collection-avoidance-list
		  purge-collection-avoidance-list)
    (ikarus system $fx)
    (ikarus system $arg-list)
    (vicare syntactic-extensions)
    (vicare arguments validation)
    (ikarus.emergency))


(define post-gc-hooks
  (make-parameter '()
    (lambda (ls)
      ;;NULL? check so that we don't  reference LIST? and ANDMAP at this
      ;;stage of booting.
      (if (or (null? ls)
	      (and (list? ls)
		   (andmap procedure? ls)))
          ls
	(assertion-violation 'post-gc-hooks "not a list of procedures" ls)))))

(define (do-post-gc ls n)
  #;(emergency-write "do-post-gc enter")
  (let ((k0 (collect-key)))
    ;;Run the hook functions.
    (parameterize ((post-gc-hooks '()))
      ;;FIXME  As a  temporary work  around for  issue #35:  comment out
      ;;running the  post GC  hooks.  To  be restored  after the  bug is
      ;;fixed.  (Marco Maggi; Nov 1, 2012)
      #;(void)
      (for-each (lambda (x) (x)) ls))
    #;(emergency-write "do-post-gc check for redoing gc")
    (if (eq? k0 (collect-key))
        (let ((was-enough? (foreign-call "ik_collect_check" n)))
          ;;Handlers ran  without GC but  there was not enough  space in
          ;;the nursery for the pending allocation.
          (unless was-enough?
	    #;(emergency-write "do-post-gc again after run without GC")
	    (do-post-gc ls n))
	  #;(emergency-write "do-post-gc leaving"))
      (let ()
	;;Handlers did cause a GC, so, do the handlers again.
	#;(emergency-write "do-post-gc again after run with GC")
	(do-post-gc ls n)))))

(define (do-overflow n)
  (foreign-call "ik_collect" n)
  (let ((ls (post-gc-hooks)))
    (unless (null? ls)
      (do-post-gc ls n))))

(define (do-overflow-words n)
  (let ((n ($fxsll n 2)))
    (foreign-call "ik_collect" n)
    (let ((ls (post-gc-hooks)))
      (unless (null? ls)
	(do-post-gc ls n)))))

(define do-vararg-overflow do-overflow)

(define (collect)
  (do-overflow 4096))

(define (do-stack-overflow)
  ;;FIXME This is unused.  (Marco Maggi; Nov  7, 2012)
  ;;
  (foreign-call "ik_stack_overflow"))

(define (dump-metatable)
  (foreign-call "ik_dump_metatable"))

(define (dump-dirty-vector)
  (foreign-call "ik_dump_dirty_vector"))

(define (collect-key)
  (or ($collect-key)
      (begin
        ($collect-key (gensym))
        (collect-key))))


(define (register-to-avoid-collecting obj)
  (foreign-call "ik_register_to_avoid_collecting" obj))

(define (forget-to-avoid-collecting ptr)
  (define who 'forget-to-avoid-collecting)
  (with-arguments-validation (who)
      ((pointer	ptr))
    (foreign-call "ik_forget_to_avoid_collecting" ptr)))

(define (replace-to-avoid-collecting ptr obj)
  (define who 'replace-to-avoid-collecting)
  (with-arguments-validation (who)
      ((non-null-pointer	ptr))
    (foreign-call "ik_replace_to_avoid_collecting" ptr obj)))

(define (retrieve-to-avoid-collecting ptr)
  (define who 'retrieve-to-avoid-collecting)
  (with-arguments-validation (who)
      ((pointer	ptr))
    (foreign-call "ik_retrieve_to_avoid_collecting" ptr)))

(define (collection-avoidance-list)
  (foreign-call "ik_collection_avoidance_list"))

(define (purge-collection-avoidance-list)
  (foreign-call "ik_purge_collection_avoidance_list"))


;;;; done

)

;;; end of file
