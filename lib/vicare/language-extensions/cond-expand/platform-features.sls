;;;Copyright 2010 Derick Eddington.  My MIT-style license is in the file
;;;named LICENSE from  the original collection this  file is distributed
;;;with.

#!r6rs
(library (vicare language-extensions cond-expand platform-features)
  (export expand-time-features run-time-features)
  (import (rnrs)
    (only (vicare) host-info)
    (vicare language-extensions cond-expand OS-id-features))
  (define (expand-time-features)
    '(vicare))
  (define (run-time-features)
    ;;Return a list of symbols representing OS features.
    ;;
    (OS-id-features (host-info)
		    '(("linux"		linux posix)
		      ("solaris"	solaris posix)
		      ("darwin"		darwin posix)
		      ("bsd"		bsd)
		      ("freebsd"	freebsd posix)
		      ("openbsd"	openbsd posix)
		      ("cygwin"		cygwin posix) ;; correct?
		      ("gnu"		gnu)))))

;;; end of file
