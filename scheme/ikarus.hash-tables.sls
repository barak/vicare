;;;Ikarus Scheme -- A compiler for R6RS Scheme.
;;;Copyright (C) 2006,2007,2008  Abdulaziz Ghuloum
;;;Mofified by Marco Maggi <marco.maggi-ipsu@poste.it>
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


;;See the paper:
;;
;;  Ghuloum, Dybvig.  "Generation-Friendly Eq Hash Tables".  Proceedings
;;  of the 2007 Workshop on Scheme and Functional Programming.
;;


#!r6rs
(library (ikarus hash-tables)
  (export
    make-eq-hashtable		make-eqv-hashtable
    make-hashtable
    hashtable?			hashtable-mutable?
    hashtable-ref		hashtable-set!
    hashtable-size
    hashtable-delete!		hashtable-clear!
    hashtable-contains?
    hashtable-update!
    hashtable-keys		hashtable-entries
    hashtable-copy
    hashtable-equivalence-function
    hashtable-hash-function
    string-hash			string-ci-hash
    symbol-hash			bytevector-hash
    equal-hash

    ;; unsafe operations
    $string-hash		$string-ci-hash
    $symbol-hash		$bytevector-hash)
  (import
      (ikarus system $pairs)
    (ikarus system $vectors)
    (ikarus system $tcbuckets)
    (ikarus system $fx)
    (except (ikarus)
	    make-eq-hashtable		make-eqv-hashtable
	    make-hashtable
	    hashtable?			hashtable-mutable?
	    hashtable-ref		hashtable-set!
	    hashtable-size
	    hashtable-delete!		hashtable-clear!
	    hashtable-contains?
	    hashtable-update!
	    hashtable-keys		hashtable-entries
	    hashtable-copy
	    hashtable-equivalence-function
	    hashtable-hash-function
	    string-hash			string-ci-hash
	    symbol-hash			bytevector-hash
	    equal-hash)
    ;;This import spec must be the  last, else rebuilding the boot image
    ;;may fail.  (Marco Maggi; Sat Feb  9, 2013)
    (vicare arguments validation))


;;;; arguments validation

(define-argument-validation (initial-capacity who obj)
  (and (or (fixnum? obj)
	   (bignum? obj))
       (>= obj 0))
  (procedure-argument-violation who "invalid initial hashtable capacity" obj))

(define-argument-validation (hasht who obj)
  (hasht? obj)
  (procedure-argument-violation who "expected hash table as argument" obj))

(define-argument-validation (mutable-hasht who obj)
  (hasht-mutable? obj)
  (procedure-argument-violation who "expected mutable hash table as argument" obj))


;;;; data structure

(define-struct hasht
  (vec
   count
   tc
   mutable?
   hashf
   equivf
   hashf0
   ))


;;;; directly from Dybvig's paper

(define (tc-pop tc)
  (let ((x ($car tc)))
    (if (eq? x ($cdr tc))
	#f
      (let ((v ($car x)))
	($set-car! tc ($cdr x))
	($set-car! x #f)
	($set-cdr! x #f)
	v))))

;; assq-like lookup
(define (direct-lookup x b)
  (if (fixnum? b)
      #f
    (if (eq? x ($tcbucket-key b))
	b
      (direct-lookup x ($tcbucket-next b)))))

(define (rehash-lookup h tc x)
  (cond ((tc-pop tc)
	 => (lambda (b)
	      (if (eq? ($tcbucket-next b) #f)
		  (rehash-lookup h tc x)
		(begin
		  (re-add! h b)
		  (if (eq? x ($tcbucket-key b))
		      b
		    (rehash-lookup h tc x))))))
	(else #f)))

(define (get-bucket-index b)
  (let ((next ($tcbucket-next b)))
    (if (fixnum? next)
	next
      (get-bucket-index next))))

(define (replace! lb x y)
  (let ((n ($tcbucket-next lb)))
    (cond ((eq? n x)
	   ($set-tcbucket-next! lb y)
	   (void))
	  (else
	   (replace! n x y)))))

(define (re-add! h b)
  (let ((vec (hasht-vec h))
	(next ($tcbucket-next b)))
    ;; first remove it from its old place
    (let ((idx
	   (if (fixnum? next)
	       next
	     (get-bucket-index next))))
      (let ((fst ($vector-ref vec idx)))
	(cond
	 ((eq? fst b)
	  ($vector-set! vec idx next))
	 (else
	  (replace! fst b next)))))
;;; reset the tcbucket-tconc FIRST
    ($set-tcbucket-tconc! b (hasht-tc h))
;;; then add it to the new place
    (let ((k ($tcbucket-key b)))
      (let ((ih (pointer-value k)))
	(let ((idx ($fxlogand ih ($fx- ($vector-length vec) 1))))
	  (let ((n ($vector-ref vec idx)))
	    ($set-tcbucket-next! b n)
	    ($vector-set! vec idx b)
	    (void)))))))

(define (get-bucket h x)
  (define (get-hashed h x ih)
    (let ((equiv? (hasht-equivf h))
	  (vec (hasht-vec h)))
      (let ((idx (bitwise-and ih ($fx- ($vector-length vec) 1))))
	(let f ((b ($vector-ref vec idx)))
	  (cond ((fixnum? b)
		 #f)
		((equiv? x ($tcbucket-key b))
		 b)
		(else
		 (f ($tcbucket-next b))))))))
  (cond ((hasht-hashf h)
	 => (lambda (hashf)
	      (get-hashed h x (hashf x))))
	((and (eq? eqv? (hasht-equivf h))
	      (number? x))
	 (get-hashed h x (%number-hash x)))
	(else
	 (let ((pv (pointer-value x))
	       (vec (hasht-vec h)))
	   (let ((ih pv))
	     (let ((idx ($fxlogand ih ($fx- ($vector-length vec) 1))))
	       (let ((b ($vector-ref vec idx)))
		 (or (direct-lookup x b)
		     (rehash-lookup h (hasht-tc h) x)))))))))

(define (get-hash h x v)
  (cond ((get-bucket h x)
	 => (lambda (b)
	      ($tcbucket-val b)))
	(else v)))

(define (in-hash? h x)
  (and (get-bucket h x) #t))

(define (del-hash h x)
  (define (unlink! h b)
    (let ((vec (hasht-vec h))
	  (next ($tcbucket-next b)))
      ;; first remove it from its old place
      (let ((idx (if (fixnum? next)
		     next
		   (get-bucket-index next))))
	(let ((fst ($vector-ref vec idx)))
	  (cond ((eq? fst b)
		 ($vector-set! vec idx next))
		(else
		 (replace! fst b next)))))
      ;; set next to be #f, denoting, not in table
      ($set-tcbucket-next! b #f)))
  (cond ((get-bucket h x)
	 => (lambda (b)
	      (unlink! h b)
	      ;; don't forget the count.
	      (set-hasht-count! h (- (hasht-count h) 1))))))

(define (put-hash! h x v)
  (define (put-hashed h x v ih)
    (let ((equiv? (hasht-equivf h))
	  (vec (hasht-vec h)))
      (let ((idx (bitwise-and ih ($fx- ($vector-length vec) 1))))
	(let f ((b ($vector-ref vec idx)))
	  (cond ((fixnum? b)
		 ($vector-set! vec idx (vector x v ($vector-ref vec idx)))
		 (let ((ct (hasht-count h)))
		   (set-hasht-count! h ($fxadd1 ct))
		   (when ($fx> ct ($vector-length vec))
		     (enlarge-table h))))
		((equiv? x ($tcbucket-key b))
		 ($set-tcbucket-val! b v))
		(else
		 (f ($tcbucket-next b))))))))
  (cond ((hasht-hashf h)
	 => (lambda (hashf)
	      (put-hashed h x v (hashf x))))
	((and (eq? eqv? (hasht-equivf h))
	      (number? x))
	 (put-hashed h x v (%number-hash x)))
	(else
	 (let ((pv  (pointer-value x))
	       (vec (hasht-vec h)))
	   (let ((ih pv))
	     (let ((idx ($fxlogand ih ($fx- ($vector-length vec) 1))))
	       (let ((b ($vector-ref vec idx)))
		 (cond ((or (direct-lookup x b) (rehash-lookup h (hasht-tc h) x))
			=> (lambda (b)
			     ($set-tcbucket-val! b v)
			     (void)))
		       (else
			(let ((bucket ($make-tcbucket (hasht-tc h) x v
						      ($vector-ref vec idx))))
			  (if ($fx= (pointer-value x) pv)
			      ($vector-set! vec idx bucket)
			    (let* ((ih  (pointer-value x))
				   (idx ($fxlogand ih ($fx- ($vector-length vec) 1))))
			      ($set-tcbucket-next! bucket ($vector-ref vec idx))
			      ($vector-set! vec idx bucket))))
			(let ((ct (hasht-count h)))
			  (set-hasht-count! h ($fxadd1 ct))
			  (when ($fx> ct ($vector-length vec))
			    (enlarge-table h))))))))))))

(define (update-hash! h x proc default)
  (cond ((get-bucket h x)
	 => (lambda (b)
	      ($set-tcbucket-val! b (proc ($tcbucket-val b)))))
	(else
	 (put-hash! h x (proc default)))))

(define (enlarge-table h)
  (define (enlarge-hashtable h hashf)
    (define (insert-b b vec mask)
      (let* ((x    ($tcbucket-key b))
	     (ih   (hashf x))
	     (idx  (bitwise-and ih mask))
	     (next ($tcbucket-next b)))
	($set-tcbucket-next! b ($vector-ref vec idx))
	($vector-set! vec idx b)
	(unless (fixnum? next)
	  (insert-b next vec mask))))
    (define (move-all vec1 i n vec2 mask)
      (unless ($fx= i n)
	(let ((b ($vector-ref vec1 i)))
	  (unless (fixnum? b)
	    (insert-b b vec2 mask))
	  (move-all vec1 ($fxadd1 i) n vec2 mask))))
    (let* ((vec1 (hasht-vec h))
	   (n1   ($vector-length vec1))
	   (n2   ($fxsll n1 1))
	   (vec2 (make-base-vec n2)))
      (move-all vec1 0 n1 vec2 ($fx- n2 1))
      (set-hasht-vec! h vec2)))
  (cond ((hasht-hashf h)
	 => (lambda (hashf)
	      (enlarge-hashtable h hashf)))
	((eq? eq? (hasht-equivf h))
	 (enlarge-hashtable h (lambda (x)
				(pointer-value x))))
	(else
	 (enlarge-hashtable h (lambda (x)
				(if (number? x)
				    (%number-hash x)
				  (pointer-value x)))))))

(define (init-vec v i n)
  (if ($fx= i n)
      v
    (begin
      ($vector-set! v i i)
      (init-vec v ($fxadd1 i) n))))

(define (make-base-vec n)
  (init-vec (make-vector n) 0 n))

(define (clear-hash! h)
  (let ((v (hasht-vec h)))
    (init-vec v 0 (vector-length v)))
  (unless (hasht-hashf h)
    (set-hasht-tc! h (let ((x (cons #f #f)))
		       (cons x x))))
  (set-hasht-count! h 0))

(define (get-keys h)
  (let ((v (hasht-vec h))
	(n (hasht-count h)))
    (let ((kv (make-vector n)))
      (let f ((i  ($fxsub1 n))
	      (j  ($fxsub1 (vector-length v)))
	      (kv kv)
	      (v  v))
	(cond (($fx= i -1)
	       kv)
	      (else
	       (let ((b ($vector-ref v j)))
		 (if (fixnum? b)
		     (f i ($fxsub1 j) kv v)
		   (f (let f ((i i) (b b) (kv kv))
			($vector-set! kv i ($tcbucket-key b))
			(let ((b ($tcbucket-next b))
			      (i ($fxsub1 i)))
			  (cond
			   ((fixnum? b) i)
			   (else (f i b kv)))))
		      ($fxsub1 j) kv v)))))))))

(define (get-entries h)
  (let ((v (hasht-vec h))
	(n (hasht-count h)))
    (let ((kv (make-vector n))
	  (vv (make-vector n)))
      (let f ((i  ($fxsub1 n))
	      (j  ($fxsub1 (vector-length v)))
	      (kv kv)
	      (vv vv)
	      (v  v))
	(cond (($fx= i -1)
	       (values kv vv))
	      (else
	       (let ((b ($vector-ref v j)))
		 (if (fixnum? b)
		     (f i ($fxsub1 j) kv vv v)
		   (f (let f ((i i) (b b) (kv kv) (vv vv))
			($vector-set! kv i ($tcbucket-key b))
			($vector-set! vv i ($tcbucket-val b))
			(let ((b ($tcbucket-next b))
			      (i ($fxsub1 i)))
			  (cond ((fixnum? b)
				 i)
				(else
				 (f i b kv vv)))))
		      ($fxsub1 j) kv vv v)))))))))

(define (hasht-copy h mutable?)
  (define (dup-hasht h mutable? n)
    (let* ((hashf (hasht-hashf h))
	   (tc (and (not hashf) (let ((x (cons #f #f))) (cons x x)))))
      (make-hasht (make-base-vec n) 0 tc mutable?
		  hashf (hasht-equivf h) (hasht-hashf0 h))))
  (let ((v (hasht-vec h))
	(n (hasht-count h)))
    (let ((r (dup-hasht h mutable? (vector-length v))))
      (let f ((i ($fxsub1 n))
	      (j ($fxsub1 (vector-length v)))
	      (r r)
	      (v v))
	(cond (($fx= i -1)
	       r)
	      (else
	       (let ((b ($vector-ref v j)))
		 (if (fixnum? b)
		     (f i ($fxsub1 j) r v)
		   (f (let f ((i i) (b b) (r r))
			(put-hash! r ($tcbucket-key b) ($tcbucket-val b))
			(let ((b ($tcbucket-next b))
			      (i ($fxsub1 i)))
			  (cond ((fixnum? b)
				 i)
				(else
				 (f i b r)))))
		      ($fxsub1 j) r v)))))))))


;;;; public interface: constructors and predicate

(define (hashtable? x)
  (hasht? x))

(define make-eq-hashtable
  (case-lambda
   (()
    (let* ((x  (cons #f #f))
	   (tc (cons x x)))
      (make-hasht (make-base-vec 32) #;vec 0 #;count tc #;tc
		  #t #;mutable? #f #;hashf eq? #;equivf #f #;hashf0 )))
   ((cap)
    (define who 'make-eq-hashtable)
    (with-arguments-validation (who)
	((initial-capacity	cap))
      (make-eq-hashtable)))))

(define make-eqv-hashtable
  (case-lambda
   (()
    (let* ((x  (cons #f #f))
	   (tc (cons x x)))
      (make-hasht (make-base-vec 32) #;vec 0 #;count tc #;tc
		  #t #;mutable? #f #;hashf eqv? #;equivf #f #;hashf0)))
   ((cap)
    (define who 'make-eqv-hashtable)
    (with-arguments-validation (who)
	((initial-capacity	cap))
      (make-eqv-hashtable)))))

(module (make-hashtable)

  (define make-hashtable
    (case-lambda
     ((hashf equivf)
      (make-hashtable hashf equivf 0))
     ((hashf equivf cap)
      (define who 'make-hashtable)
      (with-arguments-validation (who)
	  ((procedure		hashf)
	   (procedure		equivf)
	   (initial-capacity	cap))
	(make-hasht (make-base-vec 32) #;vec 0 #;count #f #;tc
		    #t #;mutable? (%make-hashfun-wrapper hashf) #;hashf
		    equivf #;equivf hashf #;hashf0)))))

  (define (%make-hashfun-wrapper f)
    (if (or (eq? f symbol-hash)
	    (eq? f string-hash)
	    (eq? f string-ci-hash)
	    (eq? f equal-hash))
	f
      (lambda (k)
	(define who 'hashfunc-wrapper)
	(let ((i (f k)))
	  (with-arguments-validation (who)
	      ((hash-result	i))
	    i)))))

  (define-argument-validation (hash-result who obj)
    (or (fixnum? obj)
	(bignum? obj))
    (procedure-argument-violation who "invalid return value from client hash function" obj))

  #| end of module: make-hashtable |# )

;;; --------------------------------------------------------------------

(module (hashtable-copy)

  (define who 'hashtable-copy)

  (define hashtable-copy
    (case-lambda
     ((table)
      (with-arguments-validation (who)
	  ((hasht	table))
	(if (hasht-mutable? table)
	    (hasht-copy table #f)
	  table)))
     ((table mutable?)
      (with-arguments-validation (who)
	  ((hasht	table))
	(if (or mutable?
		(hasht-mutable? table))
	    (hasht-copy table (and mutable? #t))
	  table)))))

  #| end of module |# )


;;;; public interface: accessors and mutators

(define (hashtable-ref table key default)
  (define who 'hashtable-ref)
  (with-arguments-validation (who)
      ((hasht	table))
    (get-hash table key default)))

(define (hashtable-set! table key val)
  (define who 'hashtable-set!)
  (with-arguments-validation (who)
      ((hasht		table)
       (mutable-hasht	table))
    (put-hash! table key val)))

;;; --------------------------------------------------------------------

(define (hashtable-contains? table key)
  (define who 'hashtable-contains?)
  (with-arguments-validation (who)
      ((hasht	table))
    (in-hash? table key)))

;;; --------------------------------------------------------------------

(define (hashtable-update! table key proc default)
  (define who 'hashtable-update!)
  (with-arguments-validation (who)
      ((hasht		table)
       (mutable-hasht	table)
       (procedure	proc))
    (update-hash! table key proc default)))

(define (hashtable-delete! table key)
  ;;FIXME: should shrink table if number of keys drops below:
  ;;
  ;;(sqrt (vector-length (hasht-vec h)))
  ;;
  ;;(Abdulaziz Ghuloum)
  ;;
  (define who 'hashtable-delete!)
  (with-arguments-validation (who)
      ((hasht		table)
       (mutable-hasht	table))
    (del-hash table key)))

(define (hashtable-clear! table)
  (define who 'hashtable-clear!)
  (with-arguments-validation (who)
      ((hasht		table)
       (mutable-hasht	table))
    (clear-hash! table)))


;;;; public interface: inspection

(define (hashtable-size table)
  (define who 'hashtable-size)
  (with-arguments-validation (who)
      ((hasht	table))
    (hasht-count table)))

(define (hashtable-entries table)
  (define who 'hashtable-entries)
  (with-arguments-validation (who)
      ((hasht	table))
    (get-entries table)))

(define (hashtable-keys table)
  (define who 'hashtable-keys)
  (with-arguments-validation (who)
      ((hasht	table))
    (get-keys table)))

(define (hashtable-mutable? table)
  (define who 'hashtable-mutable?)
  (with-arguments-validation (who)
      ((hasht	table))
    (hasht-mutable? table)))

;;; --------------------------------------------------------------------

(define (hashtable-equivalence-function table)
  (define who 'hashtable-equivalence-function)
  (with-arguments-validation (who)
      ((hasht	table))
    (hasht-equivf table)))

(define (hashtable-hash-function table)
  (define who 'hashtable-equivalence-function)
  (with-arguments-validation (who)
      ((hasht	table))
    (hasht-hashf0 table)))


;;;; hash functions

(define (string-hash s)
  (define who 'string-hash)
  (with-arguments-validation (who)
      ((string	s))
    ($string-hash s)))

(define ($string-hash s)
  (foreign-call "ikrt_string_hash" s))

;;; --------------------------------------------------------------------

(define (string-ci-hash s)
  (define who 'string-ci-hash)
  (with-arguments-validation (who)
      ((string	s))
    ($string-ci-hash s)))

(define ($string-ci-hash s)
  (foreign-call "ikrt_string_hash" (string-foldcase s)))

;;; --------------------------------------------------------------------

(define (symbol-hash s)
  (define who 'symbol-hash)
  (with-arguments-validation (who)
      ((symbol	s))
    ($symbol-hash s)))

(define ($symbol-hash s)
  (foreign-call "ikrt_string_hash" (symbol->string s)))

;;; --------------------------------------------------------------------

(define (bytevector-hash s)
  ;;Defined by Vicare.
  ;;
  (define who 'bytevector-hash)
  (with-arguments-validation (who)
      ((bytevector	s))
    ($bytevector-hash s)))

(define ($bytevector-hash s)
  (foreign-call "ikrt_bytevector_hash" s))

;;; --------------------------------------------------------------------

(define (equal-hash s)
  (string-hash (call-with-string-output-port
		   (lambda (port)
		     (write s port)))))

(define (%number-hash x)
  (cond ((fixnum? x)
	 x)
	((flonum? x)
	 (foreign-call "ikrt_flonum_hash" x))
	((bignum? x)
	 (foreign-call "ikrt_bignum_hash" x))
	((ratnum? x)
	 (fxxor (%number-hash (numerator x))
		(%number-hash (denominator x))))
	(else
	 (fxxor (%number-hash (real-part x))
		(%number-hash (imag-part x))))))


;;;; done

(set-rtd-printer! (type-descriptor hasht)	(lambda (x p wr)
						  (display "#<hashtable>" p)))

)

;;; end of file
