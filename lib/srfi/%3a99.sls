;;;Copyright 2008-2010 Derick Eddington.  My MIT-style license is in the
;;;file named  LICENSE.srfi from  the original  collection this  file is
;;;distributed with.

#!r6rs
(library (srfi :99)
  (export
    define-record-type
    make-rtd
    record-rtd
    record?
    rtd-accessor
    rtd-all-field-names
    rtd-constructor
    rtd-field-mutable?
    rtd-field-names
    rtd-mutator
    rtd-name
    rtd-parent
    rtd-predicate
    rtd?)
  (import (srfi :99 records)))

;;; end of file
