;;;Ikarus Scheme -- A compiler for R6RS Scheme.
;;;Copyright (C) 2011 Marco Maggi <marco.maggi-ipsu@poste.it>
;;;Copyright (C) 2008,2009  Abdulaziz Ghuloum
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


(library (ikarus.pointers)
  (export
    ;; pointer objects
    pointer?
    null-pointer			pointer-null?
    pointer->integer			integer->pointer
    pointer-diff			pointer-add
    pointer=?				pointer<>?
    pointer<?				pointer>?
    pointer<=?				pointer>=?
    set-pointer-null!

    ;; shared libraries inteface
    dlopen				dlclose
    dlsym				dlerror

    ;; calling functions and callbacks
    make-c-callout-maker		make-c-callout-maker/with-errno
    make-c-callback-maker		free-c-callback
    with-local-storage

    ;; raw memory allocation
    malloc				free
    realloc				calloc
    memcpy				memmove
    memset				memory-copy
    memcmp
    memory->bytevector			bytevector->memory

    ;; C strings
    bytevector->cstring			cstring->bytevector
    string->cstring			cstring->string
    strlen
    strcmp				strncmp
    strdup				strndup
    bytevectors->argv			argv->bytevectors
    strings->argv			argv->strings
    argv-length

    ;; errno interface
    errno

    ;; memory accessors and mutators
    pointer-ref-c-uint8			pointer-ref-c-sint8
    pointer-ref-c-uint16		pointer-ref-c-sint16
    pointer-ref-c-uint32		pointer-ref-c-sint32
    pointer-ref-c-uint64		pointer-ref-c-sint64

    pointer-ref-c-signed-char		pointer-ref-c-unsigned-char
    pointer-ref-c-signed-short		pointer-ref-c-unsigned-short
    pointer-ref-c-signed-int		pointer-ref-c-unsigned-int
    pointer-ref-c-signed-long		pointer-ref-c-unsigned-long
    pointer-ref-c-signed-long-long	pointer-ref-c-unsigned-long-long

    pointer-ref-c-float			pointer-ref-c-double
    pointer-ref-c-pointer

    pointer-set-c-uint8!		pointer-set-c-sint8!
    pointer-set-c-uint16!		pointer-set-c-sint16!
    pointer-set-c-uint32!		pointer-set-c-sint32!
    pointer-set-c-uint64!		pointer-set-c-sint64!

    pointer-set-c-signed-char!		pointer-set-c-unsigned-char!
    pointer-set-c-signed-short!		pointer-set-c-unsigned-short!
    pointer-set-c-signed-int!		pointer-set-c-unsigned-int!
    pointer-set-c-signed-long!		pointer-set-c-unsigned-long!
    pointer-set-c-signed-long-long!	pointer-set-c-unsigned-long-long!

    pointer-set-c-float!		pointer-set-c-double!
    pointer-set-c-pointer!)
  (import (ikarus)
    (only (ikarus system $pointers)
	  $pointer=)
    (vicare syntactic-extensions)
    (prefix (vicare unsafe-operations)
	    unsafe.)
    (prefix (vicare unsafe-capi)
	    capi.)
    (prefix (vicare words)
	    words.)
    (prefix (vicare installation-configuration)
	    config.))


;;;; arguments validation

(define-argument-validation (string who obj)
  (string? obj)
  (assertion-violation who "expected string as argument" obj))

(define-argument-validation (symbol who obj)
  (symbol? obj)
  (assertion-violation who "expected symbol as argument" obj))

(define-argument-validation (list who obj)
  (list? obj)
  (assertion-violation who "expected list as argument" obj))

(define-argument-validation (bytevector who obj)
  (bytevector? obj)
  (assertion-violation who "expected bytevector as argument" obj))

(define-argument-validation (flonum who obj)
  (flonum? obj)
  (assertion-violation who "expected flonum as argument" obj))

(define-argument-validation (pointer who obj)
  (pointer? obj)
  (assertion-violation who "expected pointer as argument" obj))

(define-argument-validation (procedure who obj)
  (procedure? obj)
  (assertion-violation who "expected procedure as argument" obj))

;;; --------------------------------------------------------------------

(define-argument-validation (non-negative-exact-integer who obj)
  (or (and (fixnum? obj) (unsafe.fx<= 0 obj))
      (and (bignum? obj) (<= 0 obj)))
  (assertion-violation who "expected non-negative exact integer as argument" obj))

(define-argument-validation (null/list-of-symbols who obj)
  (or (null? obj) (and (list? obj) (for-all symbol? obj)))
  (assertion-violation who "expected list of symbols as argument" obj))

(define-argument-validation (list-of-bytevectors who obj)
  (and (list? obj) (for-all bytevector? obj))
  (assertion-violation who "expected list of bytevectors as argument" obj))

(define-argument-validation (list-of-strings who obj)
  (and (list? obj) (for-all string? obj))
  (assertion-violation who "expected list of strings as argument" obj))

(define-argument-validation (vector-of-lengths who obj)
  (and (vector? obj)
       (vector-for-all (lambda (obj)
			 (and (fixnum? obj) (unsafe.fx<= 0 obj)))
	 obj))
  (assertion-violation who "expected list of non-negative fixnums as argument" obj))

;;; --------------------------------------------------------------------

(define-argument-validation (pathname who obj)
  (or (bytevector? obj) (string? obj))
  (assertion-violation who "expected string or bytevector as pathname argument" obj))

(define-argument-validation (errno who obj)
  (or (boolean? obj) (and (fixnum? obj) (unsafe.fx<= obj 0)))
  (assertion-violation who "expected boolean or negative fixnum as errno argument" obj))

(define-argument-validation (machine-word who obj)
  (words.machine-word? obj)
  (assertion-violation who
    "expected non-negative exact integer in the range of a machine word as argument" obj))

(define-argument-validation (ptrdiff who obj)
  (words.ptrdiff? obj)
  (assertion-violation who
    "expected exact integer representing pointer difference as argument" obj))

(define-argument-validation (number-of-bytes who obj)
  (and (fixnum? obj) (unsafe.fx<= 0 obj))
  (assertion-violation who "expected non-negative fixnum as number of bytes argument" obj))

(define-argument-validation (number-of-elements who obj)
  (and (fixnum? obj) (unsafe.fx<= 0 obj))
  (assertion-violation who "expected non-negative fixnum as number of elements argument" obj))

(define-argument-validation (byte who obj)
  (or (words.word-u8? obj)
      (words.word-s8? obj))
  (assertion-violation who
    "expected exact integer representing an 8-bit signed or unsigned integer as argument" obj))

(define-argument-validation (pointer-offset who obj)
  (and (fixnum? obj) (unsafe.fx<= 0 obj))
  (assertion-violation who "expected non-negative fixnum as pointer offset argument" obj))

(define-argument-validation (start-index-for-bytevector who idx bv)
  ;;To be used after  START-INDEX validation.  Valid scenarios for start
  ;;indexes:
  ;;
  ;;  |...|word
  ;;  |---|---|---|---|---|---|---|---|---| bytevector
  ;;                      ^start
  ;;
  ;;  |---|---|---|---|---|---|---|---|---| bytevector
  ;;                                  ^start
  ;;
  ;;  |---|---|---|---|---|---|---|---|---| bytevector
  ;;                                      ^start = bv.len
  ;;
  ;;  | empty bytevector
  ;;  ^start = bv.len = 0
  ;;
  ;;the following is an invalid scenario:
  ;;
  ;;  |---|---|---|---|---|---|---|---|---| bytevector
  ;;                                    ^start = bv.len
  ;;
  (let ((bv.len (unsafe.bytevector-length bv)))
    (or (unsafe.fx=  idx bv.len)
	(unsafe.fx<= idx bv.len)))
  (assertion-violation who
    (string-append "start index argument "		(number->string idx)
		   " too big for bytevector length "	(number->string (unsafe.bytevector-length bv)))
    idx))

(define-argument-validation (count-for-bytevector who count bv bv.start)
  (let ((end (unsafe.fx+ bv.start count)))
    (unsafe.fx<= end (unsafe.bytevector-length bv)))
  (assertion-violation who
    (string-append "word count "			(number->string count)
		   " too big for bytevector length "	(number->string (unsafe.bytevector-length bv))
		   " start index "			(number->string bv.start))
    count))

;;; --------------------------------------------------------------------

(define-argument-validation (uint8 who obj)
  (words.word-u8? obj)
  (assertion-violation who
    "expected exact integer representing an 8-bit signed integer as argument" obj))

(define-argument-validation (sint8 who obj)
  (words.word-s8? obj)
  (assertion-violation who
    "expected exact integer representing an 8-bit unsigned integer as argument" obj))

(define-argument-validation (uint16 who obj)
  (words.word-u16? obj)
  (assertion-violation who
    "expected exact integer representing an 16-bit signed integer as argument" obj))

(define-argument-validation (sint16 who obj)
  (words.word-s16? obj)
  (assertion-violation who
    "expected exact integer representing an 16-bit unsigned integer as argument" obj))

(define-argument-validation (uint32 who obj)
  (words.word-u32? obj)
  (assertion-violation who
    "expected exact integer representing an 32-bit signed integer as argument" obj))

(define-argument-validation (sint32 who obj)
  (words.word-s32? obj)
  (assertion-violation who
    "expected exact integer representing an 32-bit unsigned integer as argument" obj))

(define-argument-validation (uint64 who obj)
  (words.word-u64? obj)
  (assertion-violation who
    "expected exact integer representing an 64-bit signed integer as argument" obj))

(define-argument-validation (sint64 who obj)
  (words.word-s64? obj)
  (assertion-violation who
    "expected exact integer representing an 64-bit unsigned integer as argument" obj))

;;; --------------------------------------------------------------------

(define-argument-validation (signed-char who obj)
  (words.signed-char? obj)
  (assertion-violation who
    "expected exact integer representing a C language \"signed char\" as argument" obj))

(define-argument-validation (unsigned-char who obj)
  (words.unsigned-char? obj)
  (assertion-violation who
    "expected exact integer representing a C language \"unsigned char\" as argument" obj))

(define-argument-validation (signed-short who obj)
  (words.signed-short? obj)
  (assertion-violation who
    "expected exact integer representing a C language \"signed short\" as argument" obj))

(define-argument-validation (unsigned-short who obj)
  (words.unsigned-short? obj)
  (assertion-violation who
    "expected exact integer representing a C language \"unsigned short\" as argument" obj))

(define-argument-validation (signed-int who obj)
  (words.signed-int? obj)
  (assertion-violation who
    "expected exact integer representing a C language \"signed int\" as argument" obj))

(define-argument-validation (unsigned-int who obj)
  (words.unsigned-int? obj)
  (assertion-violation who
    "expected exact integer representing a C language \"unsigned int\" as argument" obj))

(define-argument-validation (signed-long who obj)
  (words.signed-long? obj)
  (assertion-violation who
    "expected exact integer representing a C language \"signed long\" as argument" obj))

(define-argument-validation (unsigned-long who obj)
  (words.unsigned-long? obj)
  (assertion-violation who
    "expected exact integer representing a C language \"unsigned long\" as argument" obj))

(define-argument-validation (signed-long-long who obj)
  (words.signed-long-long? obj)
  (assertion-violation who
    "expected exact integer representing a C language \"signed long long\" as argument" obj))

(define-argument-validation (unsigned-long-long who obj)
  (words.unsigned-long-long? obj)
  (assertion-violation who
    "expected exact integer representing a C language \"unsigned long long\" as argument" obj))


;;;; errno interface

(define errno
  (case-lambda
   (()
    (foreign-call "ikrt_last_errno"))
   ((errno)
    (with-arguments-validation (errno)
	((errno  errno))
      (foreign-call "ikrt_set_errno" errno)))))


;;; shared libraries interface

(define (dlerror)
  (let ((p (capi.ffi-dlerror)))
    (and p (latin1->string p))))

(define dlopen
  (case-lambda
   (()
    (capi.ffi-dlopen #f #f #f))
   ((libname)
    (dlopen libname #f #f))
   ((libname lazy? global?)
    (define who 'dlopen)
    (with-arguments-validation (who)
	((pathname  libname))
      (with-pathnames ((libname.bv libname))
	(capi.ffi-dlopen libname.bv lazy? global?))))))

(define (dlclose ptr)
  (define who 'dlclose)
  (with-arguments-validation (who)
      ((pointer  ptr))
    (capi.ffi-dlclose ptr)))

(define (dlsym handle name)
  (define who 'dlsym)
  (with-arguments-validation (who)
      ((pointer  handle)
       (string   name))
    (capi.ffi-dlsym handle (string->latin1 name))))


;;; pointer manipulation procedures

(define NULL-POINTER
  (capi.ffi-fixnum->pointer 0))

(define (pointer? obj)
  ;;FIXME Why  in hell do I have  to keep this function  rather than use
  ;;the  $FIXNUM?   primitive   operation  exported  by  (ikarus  system
  ;;$pointers)? (Marco Maggi; Nov 30, 2011)
  ;;
  (capi.ffi-pointer? obj))

(define (null-pointer)
  NULL-POINTER)

(define (pointer-null? obj)
  (and (pointer? obj) (capi.ffi-pointer-null? obj)))

(define (set-pointer-null! ptr)
  (define who 'set-pointer-null!)
  (with-arguments-validation (who)
      ((pointer ptr))
    (capi.ffi-set-pointer-null! ptr)))

;;; --------------------------------------------------------------------

(define (integer->pointer x)
  (define who 'integer->pointer)
  (with-arguments-validation (who)
      ((machine-word  x))
    (if (fixnum? x)
	(capi.ffi-fixnum->pointer x)
      (capi.ffi-bignum->pointer x))))

(define (pointer->integer x)
  (define who 'pointer->integer)
  (with-arguments-validation (who)
      ((pointer	x))
    (capi.ffi-pointer->integer x)))

;;; --------------------------------------------------------------------

(define (pointer-add ptr delta)
  (define who 'pointer-add)
  (with-arguments-validation (who)
      ((pointer  ptr)
       (ptrdiff  delta))
    (let ((rv (capi.ffi-pointer-add ptr delta)))
      (or rv
	  (assertion-violation who
	    "requested pointer arithmetic operation would cause \
             machine word overflow or underflow"
	    ptr delta)))))

(define (pointer-diff ptr1 ptr2)
  (define who 'pointer-diff)
  (with-arguments-validation (who)
      ((pointer  ptr1)
       (pointer  ptr2))
    ;;Implemented  at the  Scheme level  because converting  pointers to
    ;;Scheme exact  integer objects  is the simplest  and safest  way to
    ;;correctly handle the full range of possible pointer values.
    (- (capi.ffi-pointer->integer ptr1)
       (capi.ffi-pointer->integer ptr2))))

(define (pointer+ ptr off)
  (integer->pointer (+ (pointer->integer ptr) off)))

;;; --------------------------------------------------------------------

(let-syntax ((define-pointer-comparison
	       (syntax-rules ()
		 ((_ ?who ?pred)
		  (define (?who ptr1 ptr2)
		    (define who '?who)
		    (with-arguments-validation (who)
			((pointer ptr1)
			 (pointer ptr2))
		      (?pred ptr1 ptr2)))))))

  (define-pointer-comparison pointer=?		$pointer=)
  (define-pointer-comparison pointer<>?		capi.ffi-pointer-neq)
  (define-pointer-comparison pointer<?		capi.ffi-pointer-lt)
  (define-pointer-comparison pointer>?		capi.ffi-pointer-gt)
  (define-pointer-comparison pointer<=?		capi.ffi-pointer-le)
  (define-pointer-comparison pointer>=?		capi.ffi-pointer-ge))

;;; --------------------------------------------------------------------

(let-syntax ((define-accessor (syntax-rules ()
					((_ ?who ?accessor)
					 (define (?who pointer offset)
					   (define who '?who)
					   (with-arguments-validation (who)
					       ((pointer  pointer)
						(ptrdiff  offset))
					     (?accessor pointer offset)))))))
  (define-accessor pointer-ref-c-uint8		capi.ffi-pointer-ref-c-uint8)
  (define-accessor pointer-ref-c-sint8		capi.ffi-pointer-ref-c-sint8)
  (define-accessor pointer-ref-c-uint16		capi.ffi-pointer-ref-c-uint16)
  (define-accessor pointer-ref-c-sint16		capi.ffi-pointer-ref-c-sint16)
  (define-accessor pointer-ref-c-uint32		capi.ffi-pointer-ref-c-uint32)
  (define-accessor pointer-ref-c-sint32		capi.ffi-pointer-ref-c-sint32)
  (define-accessor pointer-ref-c-uint64		capi.ffi-pointer-ref-c-uint64)
  (define-accessor pointer-ref-c-sint64		capi.ffi-pointer-ref-c-sint64)

  (define-accessor pointer-ref-c-float		capi.ffi-pointer-ref-c-float)
  (define-accessor pointer-ref-c-double		capi.ffi-pointer-ref-c-double)
  (define-accessor pointer-ref-c-pointer	capi.ffi-pointer-ref-c-pointer)

  (define-accessor pointer-ref-c-signed-char	capi.ffi-pointer-ref-c-signed-char)
  (define-accessor pointer-ref-c-signed-short	capi.ffi-pointer-ref-c-signed-short)
  (define-accessor pointer-ref-c-signed-int	capi.ffi-pointer-ref-c-signed-int)
  (define-accessor pointer-ref-c-signed-long	capi.ffi-pointer-ref-c-signed-long)
  (define-accessor pointer-ref-c-signed-long-long capi.ffi-pointer-ref-c-signed-long-long)
  (define-accessor pointer-ref-c-unsigned-char	capi.ffi-pointer-ref-c-unsigned-char)
  (define-accessor pointer-ref-c-unsigned-short	capi.ffi-pointer-ref-c-unsigned-short)
  (define-accessor pointer-ref-c-unsigned-int	capi.ffi-pointer-ref-c-unsigned-int)
  (define-accessor pointer-ref-c-unsigned-long	capi.ffi-pointer-ref-c-unsigned-long)
  (define-accessor pointer-ref-c-unsigned-long-long capi.ffi-pointer-ref-c-unsigned-long-long))

;;; --------------------------------------------------------------------

(let-syntax ((define-mutator (syntax-rules ()
				       ((_ ?who ?mutator ?word-type)
					(define (?who pointer offset value)
					  (define who '?who)
					  (with-arguments-validation (who)
					      ((pointer     pointer)
					       (ptrdiff     offset)
					       (?word-type  value))
					    (?mutator pointer offset value)))))))
  (define-mutator pointer-set-c-uint8!		capi.ffi-pointer-set-c-uint8!	uint8)
  (define-mutator pointer-set-c-sint8!		capi.ffi-pointer-set-c-sint8!	sint8)
  (define-mutator pointer-set-c-uint16!		capi.ffi-pointer-set-c-uint16!	uint16)
  (define-mutator pointer-set-c-sint16!		capi.ffi-pointer-set-c-sint16!	sint16)
  (define-mutator pointer-set-c-uint32!		capi.ffi-pointer-set-c-uint32!	uint32)
  (define-mutator pointer-set-c-sint32!		capi.ffi-pointer-set-c-sint32!	sint32)
  (define-mutator pointer-set-c-uint64!		capi.ffi-pointer-set-c-uint64!	uint64)
  (define-mutator pointer-set-c-sint64!		capi.ffi-pointer-set-c-sint64!	sint64)

  (define-mutator pointer-set-c-float!		capi.ffi-pointer-set-c-float!	flonum)
  (define-mutator pointer-set-c-double!		capi.ffi-pointer-set-c-double!	flonum)
  (define-mutator pointer-set-c-pointer!	capi.ffi-pointer-set-c-pointer!	pointer)

  (define-mutator pointer-set-c-signed-char!	capi.ffi-pointer-set-c-signed-char!	signed-char)
  (define-mutator pointer-set-c-signed-short!	capi.ffi-pointer-set-c-signed-short!	signed-short)
  (define-mutator pointer-set-c-signed-int!	capi.ffi-pointer-set-c-signed-int!	signed-int)
  (define-mutator pointer-set-c-signed-long!	capi.ffi-pointer-set-c-signed-long!	signed-long)
  (define-mutator pointer-set-c-signed-long-long!
    capi.ffi-pointer-set-c-signed-long-long! signed-long-long)

  (define-mutator pointer-set-c-unsigned-char!	capi.ffi-pointer-set-c-unsigned-char!	unsigned-char)
  (define-mutator pointer-set-c-unsigned-short!	capi.ffi-pointer-set-c-unsigned-short!	unsigned-short)
  (define-mutator pointer-set-c-unsigned-int!	capi.ffi-pointer-set-c-unsigned-int!	unsigned-int)
  (define-mutator pointer-set-c-unsigned-long!	capi.ffi-pointer-set-c-unsigned-long!	unsigned-long)
  (define-mutator pointer-set-c-unsigned-long-long!
    capi.ffi-pointer-set-c-unsigned-long-long! unsigned-long-long))


;;; explicit memory management

(define (malloc number-of-bytes)
  (define who 'malloc)
  (with-arguments-validation (who)
      ((number-of-bytes	 number-of-bytes))
    (capi.ffi-malloc number-of-bytes)))

(define (realloc pointer number-of-bytes)
  (define who 'realloc)
  (with-arguments-validation (who)
      ((number-of-bytes	 number-of-bytes))
    ;;Take  care at  the C  level not  to realloc  null pointers  and of
    ;;mutating POINTER to NULL.
    (capi.ffi-realloc pointer number-of-bytes)))

(define (calloc number-of-elements element-size)
  (define who 'calloc)
  (with-arguments-validation (who)
      ((number-of-elements	number-of-elements)
       (number-of-bytes		element-size))
    (capi.ffi-calloc number-of-elements element-size)))

(define (free ptr)
  (define who 'free)
  (with-arguments-validation (who)
      ((pointer	ptr))
    ;;Take care  at the  C level  not to "free()"  null pointers  and of
    ;;mutating PTR to NULL.
    (capi.ffi-free ptr)))

;;; --------------------------------------------------------------------

(define (memory-copy dst dst.start src src.start count)
  (define who 'memory-copy)
  (with-arguments-validation (who)
      ((pointer-offset	dst.start)
       (pointer-offset	src.start))
    (cond ((pointer? dst)
	   (cond ((pointer? src)
		  (capi.ffi-memcpy (pointer-add dst dst.start)
				   (pointer-add src src.start)
				   count))
		 ((bytevector? src)
		  (with-arguments-validation (who)
		      ((start-index-for-bytevector	src.start src)
		       (count-for-bytevector		count src src.start))
		    (foreign-call "ikrt_memcpy_from_bv" (pointer-add dst dst.start) src src.start count)))
		 (else
		  (assertion-violation who "expected pointer or bytevector as source argument" src))))
	  ((bytevector? dst)
	   (with-arguments-validation (who)
	       ((start-index-for-bytevector	dst.start dst)
		(count-for-bytevector		count dst dst.start))
	     (cond ((pointer? src)
		    (foreign-call "ikrt_memcpy_to_bv" dst dst.start (pointer-add src src.start) count))
		   ((bytevector? src)
		    (with-arguments-validation (who)
			((start-index-for-bytevector	src.start src)
			 (count-for-bytevector		count src src.start))
		      (unsafe.bytevector-copy!/count src src.start dst dst.start count)))
		   (else
		    (assertion-violation who "expected pointer or bytevector as source argument" src)))))
	  (else
	   (assertion-violation who "expected pointer or bytevector as destination argument" dst)))))

;;; --------------------------------------------------------------------

(define (memcpy dst src count)
  (define who 'memcpy)
  (with-arguments-validation (who)
      ((pointer		dst)
       (pointer		src)
       (number-of-bytes	count))
    (capi.ffi-memcpy dst src count)))

(define (memmove dst src count)
  (define who 'memmove)
  (with-arguments-validation (who)
      ((pointer		dst)
       (pointer		src)
       (number-of-bytes	count))
    (capi.ffi-memmove dst src count)))

(define (memset ptr byte count)
  (define who 'memset)
  (with-arguments-validation (who)
      ((pointer		ptr)
       (byte		byte)
       (number-of-bytes	count))
    (capi.ffi-memset ptr byte count)))

(define (memcmp ptr1 ptr2 count)
  (define who 'memcp)
  (with-arguments-validation (who)
      ((pointer		ptr1)
       (pointer		ptr2)
       (number-of-bytes	count))
    (capi.ffi-memcmp ptr1 ptr2 count)))

;;; --------------------------------------------------------------------

(define (memory->bytevector pointer length)
  (define who 'memory->bytevector)
  (with-arguments-validation (who)
      ((pointer		pointer)
       (number-of-bytes	length))
    (capi.ffi-memory->bytevector pointer length)))

(define (bytevector->memory bv)
  (define who 'bytevector->memory)
  (with-arguments-validation (who)
      ((bytevector	bv))
    (let ((rv (capi.ffi-bytevector->memory bv)))
      (if rv
	  (values rv (unsafe.bytevector-length bv))
	(values #f #f)))))


;;;; C strings

(define (strlen pointer)
  (define who 'strlen)
  (with-arguments-validation (who)
      ((pointer pointer))
    (capi.ffi-strlen pointer)))

(define (strcmp pointer1 pointer2)
  (define who 'strcmp)
  (with-arguments-validation (who)
      ((pointer pointer1)
       (pointer pointer2))
    (capi.ffi-strcmp pointer1 pointer2)))

(define (strncmp pointer1 pointer2 count)
  (define who 'strncmp)
  (with-arguments-validation (who)
      ((pointer		pointer1)
       (pointer		pointer2)
       (number-of-bytes	count))
    (capi.ffi-strncmp pointer1 pointer2 count)))

(define (strdup pointer)
  (define who 'strdup)
  (with-arguments-validation (who)
      ((pointer pointer))
    (capi.ffi-strdup pointer)))

(define (strndup pointer count)
  (define who 'strndup)
  (with-arguments-validation (who)
      ((pointer		pointer)
       (number-of-bytes	count))
    (capi.ffi-strndup pointer count)))

;;; --------------------------------------------------------------------

(define (bytevector->cstring bv)
  (define who 'bytevector->cstring)
  (with-arguments-validation (who)
      ((bytevector bv))
    (capi.ffi-bytevector->cstring bv)))

(define cstring->bytevector
  (case-lambda
   ((pointer)
    (define who 'cstring->bytevector)
    (with-arguments-validation (who)
	((pointer pointer))
      (capi.ffi-cstring->bytevector pointer (capi.ffi-strlen pointer))))
   ((pointer count)
    (define who 'cstring->bytevector)
    (with-arguments-validation (who)
	((pointer		pointer)
	 (number-of-bytes	count))
      (capi.ffi-cstring->bytevector pointer count)))))

;;; --------------------------------------------------------------------

(define cstring->string
  (case-lambda
   ((pointer)
    (define who 'cstring->string)
    (with-arguments-validation (who)
	((pointer pointer))
      (latin1->string (capi.ffi-cstring->bytevector pointer (capi.ffi-strlen pointer)))))
   ((pointer count)
    (define who 'cstring->string)
    (with-arguments-validation (who)
	((pointer		pointer)
	 (number-of-bytes	count))
      (latin1->string (capi.ffi-cstring->bytevector pointer count))))))

(define (string->cstring str)
  (define who 'string->cstring)
  (with-arguments-validation (who)
      ((string	str))
    (bytevector->cstring (string->latin1 str))))

;;; --------------------------------------------------------------------

(define (bytevectors->argv bvs)
  (define who 'bytevectors->argv)
  (with-arguments-validation (who)
      ((list-of-bytevectors bvs))
    (capi.ffi-bytevectors->argv bvs)))

(define (argv->bytevectors pointer)
  (define who 'argv->bytevectors)
  (with-arguments-validation (who)
      ((pointer pointer))
    (capi.ffi-argv->bytevectors pointer)))

(define (strings->argv strs)
  (define who 'strings->argv)
  (with-arguments-validation (who)
      ((list-of-strings strs))
    (capi.ffi-bytevectors->argv (map string->latin1 strs))))

(define (argv->strings pointer)
  (define who 'argv->strings)
  (with-arguments-validation (who)
      ((pointer pointer))
    (map latin1->string (capi.ffi-argv->bytevectors pointer))))

(define (argv-length pointer)
  (define who 'argv-length)
  (with-arguments-validation (who)
      ((pointer pointer))
    (capi.ffi-argv-length pointer)))


;;;; local storage

(define (with-local-storage lengths proc)
  (define who 'with-local-storage)
  (with-arguments-validation (who)
      ((vector-of-lengths	lengths)
       (procedure		proc))
    (capi.ffi-with-local-storage lengths proc)))


;;;; Libffi: C API

(define-inline (capi.ffi-enabled?)
  (foreign-call "ikrt_has_ffi"))

(define-inline (capi.ffi-prep-cif type-ids)
  (foreign-call "ikrt_ffi_prep_cif" type-ids))

(define-inline (capi.ffi-callout user-data args)
  (foreign-call "ikrt_ffi_call" user-data args))

(define-inline (capi.ffi-prepare-callback cif.proc)
  (foreign-call "ikrt_ffi_prepare_callback" cif.proc))

(define-inline (capi.ffi-free-c-callback c-callback-pointer)
  (foreign-call "ikrt_ffi_release_callback" c-callback-pointer))


;;;; Libffi: native type identifiers

;;The  fixnums identifying  the  types must  be  kept in  sync with  the
;;definition of "type_id_t" in the file "ikarus-ffi.c".
;;
(define-inline-constant TYPE_ID_VOID            0)
(define-inline-constant TYPE_ID_UINT8           1)
(define-inline-constant TYPE_ID_SINT8           2)
(define-inline-constant TYPE_ID_UINT16          3)
(define-inline-constant TYPE_ID_SINT16          4)
(define-inline-constant TYPE_ID_UINT32          5)
(define-inline-constant TYPE_ID_SINT32          6)
(define-inline-constant TYPE_ID_UINT64          7)
(define-inline-constant TYPE_ID_SINT64          8)
(define-inline-constant TYPE_ID_FLOAT           9)
(define-inline-constant TYPE_ID_DOUBLE         10)
(define-inline-constant TYPE_ID_POINTER        11)
(define-inline-constant TYPE_ID_UCHAR          12)
(define-inline-constant TYPE_ID_SCHAR          13)
(define-inline-constant TYPE_ID_USHORT         14)
(define-inline-constant TYPE_ID_SSHORT         15)
(define-inline-constant TYPE_ID_UINT           16)
(define-inline-constant TYPE_ID_SINT           17)
(define-inline-constant TYPE_ID_ULONG          18)
(define-inline-constant TYPE_ID_SLONG          19)
(define-inline-constant TYPE_ID_MAX            20)

(define (%type-symbol->type-id type)
  (case type
    ((uint8_t)			TYPE_ID_UINT8)
    ((int8_t)			TYPE_ID_SINT8)
    ((uint16_t)			TYPE_ID_UINT16)
    ((int16_t)			TYPE_ID_SINT16)
    ((uint32_t)			TYPE_ID_UINT32)
    ((int32_t)			TYPE_ID_SINT32)
    ((uint64_t)			TYPE_ID_UINT64)
    ((int64_t)			TYPE_ID_SINT64)

    ((float)			TYPE_ID_FLOAT)
    ((double)			TYPE_ID_DOUBLE)
    ((pointer)			TYPE_ID_POINTER)
    ((callback)			TYPE_ID_POINTER)

    ((void)			TYPE_ID_VOID)
    ((unsigned-char)		TYPE_ID_UCHAR)
    ((signed-char)		TYPE_ID_SCHAR)
    ((unsigned-short)		TYPE_ID_SSHORT)
    ((signed-short)		TYPE_ID_USHORT)
    ((unsigned-int)		TYPE_ID_UINT)
    ((signed-int)		TYPE_ID_SINT)
    ((unsigned-long)		TYPE_ID_ULONG)
    ((signed-long)		TYPE_ID_SLONG)
    ((unsigned-long-long)	TYPE_ID_UINT64)
    ((signed-long-long)		TYPE_ID_SINT64)

    (else
     (assertion-violation #f "invalid FFI type specifier" type))))

(let-syntax ((define-predicate (syntax-rules ()
				 ((_ ?who ?pred)
				  (define (?who obj) (?pred obj))))))
  (define-predicate %unsigned-char?		words.unsigned-char?)
  (define-predicate %unsigned-short?		words.unsigned-short?)
  (define-predicate %unsigned-int?		words.unsigned-int?)
  (define-predicate %unsigned-long?		words.unsigned-long?)
  (define-predicate %unsigned-long-long?	words.unsigned-long-long?)

  (define-predicate %signed-char?		words.signed-char?)
  (define-predicate %signed-short?		words.signed-short?)
  (define-predicate %signed-int?		words.signed-int?)
  (define-predicate %signed-long?		words.signed-long?)
  (define-predicate %signed-long-long?		words.signed-long-long?)

  (define-predicate %sint8?			words.word-s8?)
  (define-predicate %uint8?			words.word-u8?)
  (define-predicate %sint16?			words.word-s16?)
  (define-predicate %uint16?			words.word-u16?)
  (define-predicate %sint32?			words.word-s32?)
  (define-predicate %uint32?			words.word-u32?)
  (define-predicate %sint64?			words.word-s64?)
  (define-predicate %uint64?			words.word-u64?))

(define (%select-type-predicate type)
  (case type
    ((unsigned-char)		%unsigned-char?)
    ((unsigned-short)		%unsigned-short?)
    ((unsigned-int)		%unsigned-int?)
    ((unsigned-long)		%unsigned-long?)
    ((unsigned-long-long)	%unsigned-long-long?)

    ((signed-char)		%signed-char?)
    ((signed-short)		%signed-short?)
    ((signed-int)		%signed-int?)
    ((signed-long)		%signed-long?)
    ((signed-long-long)		%signed-long-long?)

    ((float)			flonum?)
    ((double)			flonum?)
    ((pointer)			pointer?)
    ((callback)			pointer?)

    ((int8_t)			%sint8?)
    ((uint8_t)			%uint8?)
    ((int16_t)			%sint16?)
    ((uint16_t)			%uint16?)
    ((int32_t)			%sint32?)
    ((uint32_t)			%uint32?)
    ((int64_t)			%sint64?)
    ((uint64_t)			%uint64?)

    (else
     (assertion-violation #f "unknown FFI type specifier" type))))


;;; Libffi: call interfaces

(define (ffi-enabled?)
  (capi.ffi-enabled?))

;;Descriptor for callout and  callback generators associated to the same
;;function signature.  Once allocated,  instances of this type are never
;;released; rather they are cached in CIF-TABLE.
;;
(define-struct cif
  (cif			;Pointer   to  a   malloc-ed  C   language  data
			;structure  of type  "ffi_cif".   Once allocated
			;these structures are never released.
   callout-maker	;False   or  closure.   The   closure  generates
			;callout functions of given signature.
   callout-maker/with-errno
   callback-maker	;False   or  Closure.   The   closure  generates
			;callback functions of given signature
   arg-checkers		;vector of predicates used to validate arguments
   retval-checker	;predicate used to validate return value
   arg-types		;vector of symbols representing arg types
   retval-type		;symbol representing return value type
   ))

;;Maximum for the hash value of  signature vectors.  It is used to avoid
;;overflow of fixnums, allowing unsafe fx operations to be used.
;;
(define H_MAX
  (- (greatest-fixnum) TYPE_ID_MAX))

(define (%signature-hash signature)
  ;;Given a vector  of fixnums representing native types  for the return
  ;;value and  the arguments of a  callout or callback,  return a fixnum
  ;;hash value.
  ;;
  (let loop ((signature signature)
	     (len       (unsafe.vector-length signature))
	     (H		0)
	     (i         0))
    (cond ((unsafe.fx= i len)
	   H)
	  ((unsafe.fx< H_MAX H)
	   (assertion-violation '%signature-hash "FFI signature too big" signature))
	  (else
	   (loop signature len
		 (unsafe.fx+ H (unsafe.vector-ref signature i))
		 (unsafe.fxadd1 i))))))

(define (%unsafe.signature=? vec1 vec2)
  (let ((len1 (unsafe.vector-length vec1)))
    (and (unsafe.fx= len1 (unsafe.vector-length vec2))
	 (let loop ((i 0))
	   (or (unsafe.fx= i len1)
	       (and (unsafe.fx= (unsafe.vector-ref vec1 i)
				(unsafe.vector-ref vec2 i))
		    (loop (unsafe.fxadd1 i))))))))

;;Table of structures of type CIF, used to avoid generating duplicates.
;;
(define CIF-TABLE #f)

(define (%ffi-prep-cif who retval-type arg-types)
  ;;Return an instance of  CIF structure representing the call interface
  ;;for  callouts  and callbacks  of  the  given  signature.  If  a  CIF
  ;;structure for  such function  signature already exists:  retrieve it
  ;;from the hash table; else build a new structure.
  ;;
  ;;RETVAL-TYPE must  be a  symbol representing the  type of  the return
  ;;value.  ARG-TYPES must  be a list of symbols  representing the types
  ;;of the arguments.
  ;;
  (define who '%ffi-prep-cif)
  (with-arguments-validation (who)
      ((list	arg-types))
    (let* ((arg-types	(if (equal? '(void) arg-types) '() arg-types))
	   (signature	(vector-map %type-symbol->type-id
			  (list->vector (cons retval-type arg-types)))))
      (unless CIF-TABLE
	(set! CIF-TABLE (make-hashtable %signature-hash %unsafe.signature=?)))
      (or (hashtable-ref CIF-TABLE signature #f)
          (let* ((cif			(capi.ffi-prep-cif signature))
		 (arg-types		(if (null? arg-types)
					    '#()
					  (list->vector arg-types)))
		 (arg-checkers		(if (null? arg-types)
					    #f
					  (vector-map %select-type-predicate arg-types)))
		 (retval-checker	(if (eq? 'void retval-type)
					    #f
					  (%select-type-predicate retval-type))))
	    (and cif
		 (let ((S (make-cif cif #f #f #f arg-checkers retval-checker arg-types retval-type)))
		   (hashtable-set! CIF-TABLE signature S)
		   S)))
	  (if (ffi-enabled?)
	      (assertion-violation who "failed to initialize C interface" retval-type arg-types)
	    (assertion-violation who "FFI support is not enabled"))))))


;;;; Libffi: callouts

(define (make-c-callout-maker retval-type arg-types)
  ;;Given  the symbol RETVAL-TYPE  representing the  type of  the return
  ;;value and a list of  symbols ARG-TYPES representing the types of the
  ;;arguments: return  a closure to  be used to generate  Scheme callout
  ;;functions from pointers to C functions.
  ;;
  (define who 'make-c-callout-maker)
  (with-arguments-validation (who)
      ((symbol			retval-type)
       (null/list-of-symbols	arg-types))
    (let ((S (%ffi-prep-cif who retval-type arg-types)))
      (or (cif-callout-maker S)
	  (let ((maker (lambda (c-function-pointer)
			 (%callout-maker S c-function-pointer))))
	    (set-cif-callout-maker! S maker)
	    maker)))))

(define (%callout-maker S c-function-pointer)
  ;;Worker  function  for  Scheme  callout maker  functions.   Return  a
  ;;closure to be called to call a foreign function.
  ;;
  ;;S must be an instance of the CIF data structure.  C-FUNCTION-POINTER
  ;;must be a pointer object referencing the foreign function.
  ;;
  (define who '%callout-maker)
  (with-arguments-validation (who)
      ((pointer  c-function-pointer))
    (let ((user-data (cons (cif-cif S) c-function-pointer)))
      (lambda args	;this is the callout function
	(%generic-callout-wrapper user-data S args)))))

(define (%generic-callout-wrapper user-data S args)
  ;;Worker function for the wrapper of the actual foreign function: call
  ;;the foreign  function and return  its return value.   This functions
  ;;exists mostly to validate the input arguments.
  ;;
  ;;USER-DATA must be a pair whose car is a pointer object referencing a
  ;;Libffi's  CIF data  structure  and  whose cdr  is  a pointer  object
  ;;representing the address of  the foreign function to call.
  ;;
  ;;S must be an instance of the CIF data structure.
  ;;
  ;;ARGS is the list of arguments in the call.
  ;;
  (define who '%generic-callout-wrapper)
  (let ((args (list->vector args)))
    (arguments-validation-forms
      (let ((types     (cif-arg-types    S))
	    (checkers  (cif-arg-checkers S)))
	(unless (unsafe.fx= (unsafe.vector-length args)
			    (unsafe.vector-length types))
	  (assertion-violation who "wrong number of arguments" types args))
	(when checkers
	  (vector-for-each (lambda (arg-pred type arg)
			     (unless (arg-pred arg)
			       (assertion-violation who
				 "argument does not match specified type" type arg)))
	    checkers types args))))
    (capi.ffi-callout user-data args)))

;;; --------------------------------------------------------------------

(define (make-c-callout-maker/with-errno retval-type arg-types)
  ;;Given  the symbol RETVAL-TYPE  representing the  type of  the return
  ;;value and a list of  symbols ARG-TYPES representing the types of the
  ;;arguments: return  a closure to  be used to generate  Scheme callout
  ;;functions from pointers to C functions.
  ;;
  (define who 'make-c-callout-maker/with-errno)
  (with-arguments-validation (who)
      ((symbol			retval-type)
       (null/list-of-symbols	arg-types))
    (let ((S (%ffi-prep-cif who retval-type arg-types)))
      (or (cif-callout-maker/with-errno S)
	  (let ((maker (lambda (c-function-pointer)
			 (%callout-maker/with-errno S c-function-pointer))))
	    (set-cif-callout-maker/with-errno! S maker)
	    maker)))))

(define (%callout-maker/with-errno S c-function-pointer)
  ;;Worker  function  for  Scheme  callout maker  functions.   Return  a
  ;;closure to be called to call a foreign function.
  ;;
  ;;S must be an instance of the CIF data structure.  C-FUNCTION-POINTER
  ;;must be a pointer object referencing the foreign function.
  ;;
  (define who '%callout-maker/with-errno)
  (with-arguments-validation (who)
      ((pointer  c-function-pointer))
    (let ((user-data (cons (cif-cif S) c-function-pointer)))
      (lambda args	;this is the callout function
	(let ((rv (%generic-callout-wrapper user-data S args)))
	  (values rv (foreign-call "ikrt_last_errno")))))))


;;;; Libffi: callbacks

(define (make-c-callback-maker retval-type arg-types)
  ;;Given  the symbol RETVAL-TYPE  representing the  type of  the return
  ;;value and a list of  symbols ARG-TYPES representing the types of the
  ;;arguments: return a  closure to be used to  generate Scheme callback
  ;;pointers from Scheme functions.
  ;;
  (define who 'make-c-callback-maker)
  (with-arguments-validation (who)
      ((symbol			retval-type)
       (null/list-of-symbols	arg-types))
    (let ((S (%ffi-prep-cif who retval-type arg-types)))
      (or (cif-callback-maker S)
	  (let ((maker (lambda (proc)
			 (%callback-maker S proc))))
	    (set-cif-callback-maker! S maker)
	    maker)))))

(define (%callback-maker S proc)
  ;;Worker  function  for Scheme  callback  maker  functions.  Return  a
  ;;pointer to callable machine code.
  ;;
  ;;S must be  an instance of the CIF data structure.   PROC must be the
  ;;Scheme function to wrap.
  ;;
  (define who 'callback-generator)
  (with-arguments-validation (who)
      ((procedure  proc))
    (let* ((retval-pred	(cif-retval-checker S))
	   (retval-type (cif-retval-type    S))
	   (proc	(if (or (eq? retval-type 'void)
				(not config.arguments-validation))
			    proc ;no return value to be validated
			  ;;This is a wrapper for a Scheme function that
			  ;;needs validation of the return value.
			  (lambda args
			    (let ((v (apply proc args)))
			      (if (retval-pred v)
				  v
				(assertion-violation 'callback
				  "returned value does not match specified type" retval-type v)))))))
      (or (capi.ffi-prepare-callback (cons (cif-cif S) proc))
	  (assertion-violation who "internal error building FFI callback")))))

(define (free-c-callback c-callback-pointer)
  (define who 'free-c-callback)
  (with-arguments-validation (who)
      ((pointer	c-callback-pointer))
    (or (capi.ffi-free-c-callback c-callback-pointer)
	(assertion-violation who
	  "attempt to release unkwnown callback pointer" c-callback-pointer))))


;;;; done

)

;;; end of file
;; Local Variables:
;; eval: (put 'with-pathnames 'scheme-indent-function 1)
;; eval: (put 'arguments-validation-forms 'scheme-indent-function 0)
;; End:
