;;; -*- coding: utf-8-unix -*-
;;;
;;;Part of: Vicare Scheme
;;;Contents: tests for (vicare posix) mmap functions
;;;Date: Tue Jul 17, 2012
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
  (prefix (vicare posix)
	  px.)
  (vicare platform constants)
  (vicare language-extensions syntaxes)
  (vicare checks))

(check-set-mode! 'report-failed)
(check-display "*** testing POSIX library, mmap functions\n")


(parametrise ((check-test-name	'mmap))

;;;On BSD and Darwin systems  only MAP_ANON is defined, MAP_ANONYMOUS is
;;;undefined.

  (check
      (let* ((page-size	(px.sysconf _SC_PAGESIZE))
	     (ptr	(px.mmap #f page-size
				 (fxior PROT_READ PROT_WRITE)
				 (fxior MAP_PRIVATE (or MAP_ANONYMOUS MAP_ANON 0))
				 0 0)))
	(px.munmap ptr page-size)
	(pointer? ptr))
    => #t)

  (check	;msync
      (let* ((page-size	(px.sysconf _SC_PAGESIZE))
	     (ptr	(px.mmap #f page-size
				 (fxior PROT_READ PROT_WRITE)
				 (fxior MAP_PRIVATE (or MAP_ANONYMOUS MAP_ANON 0))
				 0 0)))
	(px.msync ptr page-size 0)
	(px.munmap ptr page-size)
	(pointer? ptr))
    => #t)

  (px.cond-expand
   (px.mremap
    (check	;mremap
	(let* ((page-size	(px.sysconf _SC_PAGESIZE))
	       (ptr		(px.mmap #f page-size
					 (fxior PROT_READ PROT_WRITE)
					 (fxior MAP_PRIVATE (or MAP_ANONYMOUS MAP_ANON 0))
					 0 0))
	       (ptr		(px.mremap ptr page-size (* 2 page-size) (or MREMAP_MAYMOVE 0))))
	  (px.munmap ptr page-size)
	  (pointer? ptr))
      => #t))
   (else (void)))

  (px.cond-expand
   (px.madvise
    (check	;madvise
	(let* ((page-size	(px.sysconf _SC_PAGESIZE))
	       (ptr		(px.mmap #f page-size
					 (fxior PROT_READ PROT_WRITE)
					 (fxior MAP_PRIVATE (or MAP_ANONYMOUS MAP_ANON 0))
					 0 0)))
	  (px.madvise ptr page-size MADV_NORMAL)
	  (px.munmap ptr page-size)
	  (pointer? ptr))
      => #t))
   (else (void)))

  (px.cond-expand
   ((and px.mlock px.munlock (not darwin))
    (check	;mlock, munlock
	(let* ((page-size	(px.sysconf _SC_PAGESIZE))
	       (ptr		(px.mmap #f page-size
					 (fxior PROT_READ PROT_WRITE)
					 (fxior MAP_PRIVATE (or MAP_ANONYMOUS MAP_ANON 0))
					 0 0)))
	  (px.mlock ptr page-size)
	  (px.munlock ptr page-size)
	  (px.munmap ptr page-size)
	  (pointer? ptr))
      => #t))
   (else (void)))

  (px.cond-expand
   ((and px.mlockall px.munlockall (not darwin))
    (check	;mlockall, mulockall
	(begin
	  (px.mlockall MCL_FUTURE)
	  (px.munlockall)
	  #t)
      => #t))
   (else (void)))

  (check	;mprotect
      (let* ((page-size	(px.sysconf _SC_PAGESIZE))
	     (ptr	(px.mmap #f page-size
				 (fxior PROT_READ PROT_WRITE)
				 (fxior MAP_PRIVATE (or MAP_ANONYMOUS MAP_ANON 0))
				 0 0)))
	(px.mprotect ptr page-size PROT_READ)
	(px.munmap ptr page-size)
	(pointer? ptr))
    => #t)

  #t)


;;;; done

(check-report)

;;; end of file
