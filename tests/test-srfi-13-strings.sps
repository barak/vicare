;;;
;;;Part of: Vicare Scheme
;;;Contents: test for general SRFI 13
;;;Date: Sat Dec 22, 2012
;;;
;;;Abstract
;;;
;;;
;;;
;;;Copyright (c) 2012 Marco Maggi <marco.maggi-ipsu@poste.it>
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


#!r6rs
(import (vicare)
  (prefix (srfi :13) srfi.)
  (srfi :14)
  (vicare checks))

(check-set-mode! 'report-failed)
(check-display "*** testing SRFI libraries: SRFI 13, strings\n")


(parametrise ((check-test-name 'predicates))

  (check
      (srfi.string-null? "ciao")
    => #f)

  (check
      (srfi.string-null? "")
    => #t)

;;; --------------------------------------------------------------------
;;; string-every with wrong argument

  (check
      (guard (exc ((assertion-violation? exc)
		   (condition-who exc)))
	(srfi.string-every 123 "abc" 0 2))
    => 'string-every)

;;; --------------------------------------------------------------------
;;; string-every with characters

  (check
      (let ((str "aaaa"))
	(srfi.string-every #\a str))
    => #t)

  (check
      (let* ((str "aaaa")
	     (beg 0)
	     (end (string-length str)))
	(srfi.string-every #\a str beg end))
    => #t)

  (check
      (let* ((str "aaaab")
	     (beg 0)
	     (end (string-length str)))
	(srfi.string-every #\a str beg end))
    => #f)

  (check
      (let* ((str "aabaa")
	     (beg 0)
	     (end (string-length str)))
	(srfi.string-every #\a str beg end))
    => #f)

;;; --------------------------------------------------------------------
;;; string-every with char-sets

  (check
      (let* ((str "aaaa")
  	     (beg 0)
  	     (end (string-length str)))
  	(srfi.string-every (char-set #\a) str beg end))
    => #t)

  (check
      (let* ((str "aaaab")
  	     (beg 0)
  	     (end (string-length str)))
  	(srfi.string-every (char-set #\a) str beg end))
    => #f)

  (check
      (let* ((str "aabaa")
  	     (beg 0)
  	     (end (string-length str)))
  	(srfi.string-every (char-set #\a) str beg end))
    => #f)

;;; --------------------------------------------------------------------
;;; string-every with predicates

  (check
      (let* ((str "aaaa")
	     (beg 0)
	     (end (string-length str)))
	(srfi.string-every char-alphabetic? str beg end))
    => #t)

  (check
      (let* ((str "aaaa2")
	     (beg 0)
	     (end (string-length str)))
	(srfi.string-every char-alphabetic? str beg end))
    => #f)

  (check
      (let* ((str "aa2aa")
	     (beg 0)
	     (end (string-length str)))
	(srfi.string-every char-alphabetic? str beg end))
    => #f)

;;; --------------------------------------------------------------------
;;; string-any with wrong argument

  (check
      (guard (exc ((assertion-violation? exc)
		   (condition-who exc)))
	(srfi.string-any 123 "abc" 0 2))
    => 'string-any)

;;; --------------------------------------------------------------------
;;; string-any with characters

  (check
      (let* ((str "ddadd")
	     (beg 0)
	     (end (string-length str)))
	(srfi.string-any #\a str beg end))
    => #t)

  (check
      (let* ((str "dddda")
	     (beg 0)
	     (end (string-length str)))
	(srfi.string-any #\a str beg end))
    => #t)

  (check
      (let* ((str "ddd")
	     (beg 0)
	     (end (string-length str)))
	(srfi.string-any #\a str beg end))
    => #f)

;;; --------------------------------------------------------------------
;;; string-any with char-sets

  (check
      (let* ((str "dddaddd")
  	     (beg 0)
  	     (end (string-length str)))
  	(srfi.string-any (char-set #\a) str beg end))
    => #t)

  (check
      (let* ((str "ddda")
  	     (beg 0)
  	     (end (string-length str)))
  	(srfi.string-any (char-set #\a) str beg end))
    => #t)

  (check
      (let* ((str "dddd")
  	     (beg 0)
  	     (end (string-length str)))
  	(srfi.string-any (char-set #\a) str beg end))
    => #f)

;;; --------------------------------------------------------------------
;;; string-any with predicates

  (check
      (let* ((str "11a11")
	     (beg 0)
	     (end (string-length str)))
	(srfi.string-any char-alphabetic? str beg end))
    => #t)

  (check
      (let* ((str "11111a")
	     (beg 0)
	     (end (string-length str)))
	(srfi.string-any char-alphabetic? str beg end))
    => #t)

  (check
      (let* ((str "1111")
	     (beg 0)
	     (end (string-length str)))
	(srfi.string-any char-alphabetic? str beg end))
    => #f)

  #f)


(parametrise ((check-test-name	'constructors))

  (check
      (let ((S (srfi.make-string 4)))
	(and (string? S)
	     (= 4 (string-length S))))
    => #t)

  (check
      (srfi.make-string 4 #\a)
    => "aaaa")

;;; --------------------------------------------------------------------

  (check
      (srfi.string)
    => "")

  (check
      (srfi.string #\a)
    => "a")

  (check
      (srfi.string #\a #\a #\a #\a)
    => "aaaa")

;;; --------------------------------------------------------------------

  (check
      (srfi.string-tabulate (lambda (idx) (integer->char (+ 65 idx))) 4)
    => "ABCD")

  (check
      (srfi.string-tabulate integer->char 0)
    => "")

  #f)


(parametrise ((check-test-name 'lists))

  (check
      (let* ((str (string-copy "abcd"))
	     (beg 0)
	     (end (string-length str)))
	(srfi.string->list str beg end))
    => '(#\a #\b #\c #\d))

  (check
      (let* ((str (string-copy ""))
	     (beg 0)
	     (end (string-length str)))
	(srfi.string->list str beg end))
    => '())

;;; --------------------------------------------------------------------

  (check
      (srfi.list->string '(#\a #\b #\c #\d))
    => "abcd")

  (check
      (srfi.list->string '())
    => "")

;;; --------------------------------------------------------------------

  (check
      (srfi.reverse-list->string '(#\a #\b #\c #\d))
    => "dcba")

  (check
      (srfi.reverse-list->string '())
    => "")

;;; --------------------------------------------------------------------

  (check
      (srfi.string-join '("c" "i" "a" "o") "," 'infix)
    => "c,i,a,o")

  (check
      (srfi.string-join '("c" "i" "a" "o") "," 'strict-infix)
    => "c,i,a,o")

  (check
      (srfi.string-join '("c" "i" "a" "o") "," 'suffix)
    => "c,i,a,o,")

  (check
      (srfi.string-join '("c" "i" "a" "o") "," 'prefix)
    => ",c,i,a,o")

;;; --------------------------------------------------------------------

  (check
      (srfi.string-join '() "," 'infix)
    => "")

  (check
      (guard (exc ((assertion-violation? exc)
		   #t))
	(srfi.string-join '() "," 'strict-infix))
    => #t)

  (check
      (srfi.string-join '() "," 'suffix)
    => "")

  (check
      (srfi.string-join '() "," 'prefix)
    => "")

;;; --------------------------------------------------------------------

  (check
      (srfi.string-join '("c") "," 'infix)
    => "c")

  (check
      (srfi.string-join '("c") "," 'strict-infix)
    => "c")

  (check
      (srfi.string-join '("c") "," 'suffix)
    => "c,")

  (check
      (srfi.string-join '("c") "," 'prefix)
    => ",c")

;;; --------------------------------------------------------------------

  (check
      (srfi.string-join '("c" "i" "a" "o"))
    => "c i a o")

  (check
      (srfi.string-join '("c" "i" "a" "o") "" 'infix)
    => "ciao")

  (check
      (srfi.string-join '("c" "i" "a" "o") "" 'strict-infix)
    => "ciao")

  (check
      (srfi.string-join '("c" "i" "a" "o") "" 'suffix)
    => "ciao")

  (check
      (srfi.string-join '("c" "i" "a" "o") "" 'prefix)
    => "ciao")

;;; --------------------------------------------------------------------

  (check
      (srfi.string-join '("c" "i" "a" "o") ",;;" 'infix)
    => "c,;;i,;;a,;;o")

  (check
      (srfi.string-join '("c" "i" "a" "o") ",;;" 'strict-infix)
    => "c,;;i,;;a,;;o")

  (check
      (srfi.string-join '("c" "i" "a" "o") ",;;" 'suffix)
    => "c,;;i,;;a,;;o,;;")

  (check
      (srfi.string-join '("c" "i" "a" "o") ",;;" 'prefix)
    => ",;;c,;;i,;;a,;;o")

  #f)


(parametrise ((check-test-name 'selecting))

  (check
      (srfi.string-length "")
    => 0)

  (check
      (srfi.string-length "a")
    => 1)

  (check
      (srfi.string-length "abc")
    => 3)

;;; --------------------------------------------------------------------

  (check
      (srfi.string-ref "a" 0)
    => #\a)

  (check
      (srfi.string-ref "abc" 2)
    => #\c)

;;; --------------------------------------------------------------------

  (check
      (srfi.string-copy "")
    => "")

  (check
      (srfi.string-copy "a")
    => "a")

  (check
      (srfi.string-copy "abc")
    => "abc")

  (check
      (srfi.string-copy "" 0 0)
    => "")

  (check
      (srfi.string-copy "abc" 0)
    => "abc")

  (check
      (srfi.string-copy "abc" 1)
    => "bc")

  (check
      (srfi.string-copy "abc" 2)
    => "c")

  (check
      (srfi.string-copy "abc" 0 2)
    => "ab")

  (check
      (srfi.string-copy "abc" 1 2)
    => "b")

  (check
      (srfi.string-copy "abc" 0 1)
    => "a")

;;; --------------------------------------------------------------------

  (check
      (srfi.substring/shared "" 0)
    => "")

  (check
      (srfi.substring/shared "abc" 0)
    => "abc")

  (check
      (srfi.substring/shared "abc" 1)
    => "bc")

  (check
      (srfi.substring/shared "abc" 2)
    => "c")

  (check
      (srfi.substring/shared "abc" 0 2)
    => "ab")

  (check
      (srfi.substring/shared "abc" 1 2)
    => "b")

  (check
      (srfi.substring/shared "abc" 0 1)
    => "a")

;;; --------------------------------------------------------------------

  (check
      (let* ((str1 "abcd")
	     (beg1 0)
	     (str2 (string-copy "12")))
	(srfi.string-copy! str2 0 str1 beg1 (+ 2 beg1))
	str2)
    => "ab")

  (check
      (let* ((str1 "abcd")
	     (beg1 0)
	     (str2 ""))
	(srfi.string-copy! str2 0 str1 beg1 beg1)
	str2)
    => "")

  (check
      (guard (exc ((assertion-violation? exc)
		   #t))
	(let* ((str1 "abcd") (beg1 0) (str2 (string-copy "12")))
	  (srfi.string-copy! str2 3 str1 beg1 (+ 2 beg1))
	  str2))
    => #t)

  (check
      (let ((str1 "abcd")
	    (str2 (string-copy "1234")))
	(srfi.string-copy! str2 0 str1)
	str2)
    => "abcd")

  (check
      (let ((str1 "ab")
	    (str2 (string-copy "1234")))
	(srfi.string-copy! str2 2 str1)
	str2)
    => "12ab")

  (check
      (let ((str1 "")
	    (str2 (string-copy "1234")))
	(srfi.string-copy! str2 4 str1)
	str2)
    => "1234")

;;; --------------------------------------------------------------------
;;; string-take

  (check
      (srfi.string-take "" 0)
    => "")

  (check
      (srfi.string-take "a" 1)
    => "a")

  (check
      (srfi.string-take "abc" 1)
    => "a")

  (check
      (srfi.string-take "abcd" 2)
    => "ab")

  (check
      (srfi.string-take "abcd" 4)
    => "abcd")

;;; --------------------------------------------------------------------
;;; string-take-right

  (check
      (srfi.string-take-right "" 0)
    => "")

  (check
      (srfi.string-take-right "a" 1)
    => "a")

  (check
      (srfi.string-take-right "abc" 1)
    => "c")

  (check
      (srfi.string-take-right "abcd" 2)
    => "cd")

  (check
      (srfi.string-take-right "abcd" 4)
    => "abcd")

;;; --------------------------------------------------------------------
;;; string-drop

  (check
      (srfi.string-drop "" 0)
    => "")

  (check
      (srfi.string-drop "abc" 0)
    => "abc")

  (check
      (srfi.string-drop "a" 1)
    => "")

  (check
      (srfi.string-drop "abc" 1)
    => "bc")

  (check
      (srfi.string-drop "abcd" 2)
    => "cd")

  (check
      (srfi.string-drop "abcd" 4)
    => "")

;;; --------------------------------------------------------------------
;;; string-drop-right

  (check
      (srfi.string-drop-right "" 0)
    => "")

  (check
      (srfi.string-drop-right "abc" 0)
    => "abc")

  (check
      (srfi.string-drop-right "a" 1)
    => "")

  (check
      (srfi.string-drop-right "abc" 1)
    => "ab")

  (check
      (srfi.string-drop-right "abcd" 2)
    => "ab")

  (check
      (srfi.string-drop "abcd" 4)
    => "")

;;; --------------------------------------------------------------------
;;; string-pad

  (check (srfi.string-pad "ciao" 4)		=> "ciao")
  (check (srfi.string-pad "ciao" 5)		=> " ciao")
  (check (srfi.string-pad "ciao" 6)		=> "  ciao")

  (check (srfi.string-pad "ciao" 4 #\,)		=> "ciao")
  (check (srfi.string-pad "ciao" 5 #\,)		=> ",ciao")
  (check (srfi.string-pad "ciao" 6 #\,)		=> ",,ciao")

  (check (srfi.string-pad "ciao" 3)		=> "iao")
  (check (srfi.string-pad "ciao" 2)		=> "ao")
  (check (srfi.string-pad "ciao" 1)		=> "o")
  (check (srfi.string-pad "ciao" 0)		=> "")

  (check (srfi.string-pad "ciao" 3 #\,)		=> "iao")
  (check (srfi.string-pad "ciao" 2 #\,)		=> "ao")
  (check (srfi.string-pad "ciao" 1 #\,)		=> "o")
  (check (srfi.string-pad "ciao" 0 #\,)		=> "")

  (check (srfi.string-pad "ciao" 4 #\, 0)	=> "ciao")
  (check (srfi.string-pad "ciao" 4 #\, 1)	=> ",iao")
  (check (srfi.string-pad "ciao" 4 #\, 2)	=> ",,ao")
  (check (srfi.string-pad "ciao" 4 #\, 3)	=> ",,,o")
  (check (srfi.string-pad "ciao" 4 #\, 4)	=> ",,,,")

  (check (srfi.string-pad "ciao" 6 #\, 0)	=> ",,ciao")
  (check (srfi.string-pad "ciao" 6 #\, 1)	=> ",,,iao")
  (check (srfi.string-pad "ciao" 6 #\, 2)	=> ",,,,ao")
  (check (srfi.string-pad "ciao" 6 #\, 3)	=> ",,,,,o")
  (check (srfi.string-pad "ciao" 6 #\, 4)	=> ",,,,,,")

  (check (srfi.string-pad "ciao" 4 #\, 0 4)	=> "ciao")
  (check (srfi.string-pad "ciao" 4 #\, 0 3)	=> ",cia")
  (check (srfi.string-pad "ciao" 4 #\, 0 2)	=> ",,ci")
  (check (srfi.string-pad "ciao" 4 #\, 0 1)	=> ",,,c")
  (check (srfi.string-pad "ciao" 4 #\, 0 0)	=> ",,,,")
  (check (srfi.string-pad "ciao" 4 #\, 1 3)	=> ",,ia")
  (check (srfi.string-pad "ciao" 4 #\, 2 2)	=> ",,,,")

  (check (srfi.string-pad "ciao" 6 #\, 0 4)	=> ",,ciao")
  (check (srfi.string-pad "ciao" 6 #\, 0 3)	=> ",,,cia")
  (check (srfi.string-pad "ciao" 6 #\, 0 2)	=> ",,,,ci")
  (check (srfi.string-pad "ciao" 6 #\, 0 1)	=> ",,,,,c")
  (check (srfi.string-pad "ciao" 6 #\, 0 0)	=> ",,,,,,")
  (check (srfi.string-pad "ciao" 6 #\, 1 3)	=> ",,,,ia")
  (check (srfi.string-pad "ciao" 6 #\, 2 2)	=> ",,,,,,")

;;; --------------------------------------------------------------------
;;; string-pad-right

  (check (srfi.string-pad-right "ciao" 4)		=> "ciao")
  (check (srfi.string-pad-right "ciao" 5)		=> "ciao ")
  (check (srfi.string-pad-right "ciao" 6)		=> "ciao  ")

  (check (srfi.string-pad-right "ciao" 4 #\,)		=> "ciao")
  (check (srfi.string-pad-right "ciao" 5 #\,)		=> "ciao,")
  (check (srfi.string-pad-right "ciao" 6 #\,)		=> "ciao,,")

  (check (srfi.string-pad-right "ciao" 3)		=> "cia")
  (check (srfi.string-pad-right "ciao" 2)		=> "ci")
  (check (srfi.string-pad-right "ciao" 1)		=> "c")
  (check (srfi.string-pad-right "ciao" 0)		=> "")

  (check (srfi.string-pad-right "ciao" 3 #\,)		=> "cia")
  (check (srfi.string-pad-right "ciao" 2 #\,)		=> "ci")
  (check (srfi.string-pad-right "ciao" 1 #\,)		=> "c")
  (check (srfi.string-pad-right "ciao" 0 #\,)		=> "")

  (check (srfi.string-pad-right "ciao" 4 #\, 0)		=> "ciao")
  (check (srfi.string-pad-right "ciao" 4 #\, 1)		=> "iao,")
  (check (srfi.string-pad-right "ciao" 4 #\, 2)		=> "ao,,")
  (check (srfi.string-pad-right "ciao" 4 #\, 3)		=> "o,,,")
  (check (srfi.string-pad-right "ciao" 4 #\, 4)		=> ",,,,")

  (check (srfi.string-pad-right "ciao" 6 #\, 0)		=> "ciao,,")
  (check (srfi.string-pad-right "ciao" 6 #\, 1)		=> "iao,,,")
  (check (srfi.string-pad-right "ciao" 6 #\, 2)		=> "ao,,,,")
  (check (srfi.string-pad-right "ciao" 6 #\, 3)		=> "o,,,,,")
  (check (srfi.string-pad-right "ciao" 6 #\, 4)		=> ",,,,,,")

  (check (srfi.string-pad-right "ciao" 4 #\, 0 4)	=> "ciao")
  (check (srfi.string-pad-right "ciao" 4 #\, 0 3)	=> "cia,")
  (check (srfi.string-pad-right "ciao" 4 #\, 0 2)	=> "ci,,")
  (check (srfi.string-pad-right "ciao" 4 #\, 0 1)	=> "c,,,")
  (check (srfi.string-pad-right "ciao" 4 #\, 0 0)	=> ",,,,")
  (check (srfi.string-pad-right "ciao" 4 #\, 1 3)	=> "ia,,")
  (check (srfi.string-pad-right "ciao" 4 #\, 2 2)	=> ",,,,")

  (check (srfi.string-pad-right "ciao" 6 #\, 0 4)	=> "ciao,,")
  (check (srfi.string-pad-right "ciao" 6 #\, 0 3)	=> "cia,,,")
  (check (srfi.string-pad-right "ciao" 6 #\, 0 2)	=> "ci,,,,")
  (check (srfi.string-pad-right "ciao" 6 #\, 0 1)	=> "c,,,,,")
  (check (srfi.string-pad-right "ciao" 6 #\, 0 0)	=> ",,,,,,")
  (check (srfi.string-pad-right "ciao" 6 #\, 1 3)	=> "ia,,,,")
  (check (srfi.string-pad-right "ciao" 6 #\, 2 2)	=> ",,,,,,")

;;; --------------------------------------------------------------------
;;; string-trim

  (check (srfi.string-trim "  abcd")			=> "abcd")

  (check (srfi.string-trim "aaabcd" #\a)		=> "bcd")
  (check (srfi.string-trim "aaaaad" #\a)		=> "d")
  (check (srfi.string-trim "aaaaaa" #\a)		=> "")

  (check (srfi.string-trim "aaabcd" (char-set #\a))	=> "bcd")
  (check (srfi.string-trim "aaaaad" (char-set #\a))	=> "d")
  (check (srfi.string-trim "aaaaaa" (char-set #\a))	=> "")

  (check (srfi.string-trim "AAAbcd" char-upper-case?)	=> "bcd")
  (check (srfi.string-trim "AAAAAd" char-upper-case?)	=> "d")
  (check (srfi.string-trim "AAAAAA" char-upper-case?)	=> "")

  (check (srfi.string-trim "0aabcd" #\a 1)		=> "bcd")
  (check (srfi.string-trim "00aaad" #\a 2)		=> "d")
  (check (srfi.string-trim "000aaa" #\a 3)		=> "")

;;; --------------------------------------------------------------------
;;; string-trim-right

  (check (srfi.string-trim-right "abcd  ")		=> "abcd")

  (check (srfi.string-trim-right "abcddd" #\d)		=> "abc")
  (check (srfi.string-trim-right "abdddd" #\d)		=> "ab")
  (check (srfi.string-trim-right "addddd" #\d)		=> "a")
  (check (srfi.string-trim-right "dddddd" #\d)		=> "")

  (check (srfi.string-trim-right "abcddd" (char-set #\d))	=> "abc")
  (check (srfi.string-trim-right "abdddd" (char-set #\d))	=> "ab")
  (check (srfi.string-trim-right "addddd" (char-set #\d))	=> "a")
  (check (srfi.string-trim-right "dddddd" (char-set #\d))	=> "")

  (check (srfi.string-trim-right "abcDDD" char-upper-case?)	=> "abc")
  (check (srfi.string-trim-right "abDDDD" char-upper-case?)	=> "ab")
  (check (srfi.string-trim-right "aDDDDD" char-upper-case?)	=> "a")
  (check (srfi.string-trim-right "DDDDDD" char-upper-case?)	=> "")

  (check (srfi.string-trim-right "abcddd" #\d 0)		=> "abc")
  (check (srfi.string-trim-right "abcddd" #\d 1)		=> "bc")
  (check (srfi.string-trim-right "abcddd" #\d 2)		=> "c")
  (check (srfi.string-trim-right "abcddd" #\d 3)		=> "")

  (check (srfi.string-trim-right "abcddD" #\d 0 5)		=> "abc")
  (check (srfi.string-trim-right "abcdDD" #\d 1 4)		=> "bc")
  (check (srfi.string-trim-right "abcDDD" #\d 2 3)		=> "c")
  (check (srfi.string-trim-right "abcDDD" #\d 2 2)		=> "")

;;; --------------------------------------------------------------------
;;; string-trim-both

  (check (srfi.string-trim-both "  abcd  ")			=> "abcd")

  (check (srfi.string-trim-both ",,abcd,," #\,)			=> "abcd")

  (check (srfi.string-trim-both ",,abcd,," (char-set #\,))	=> "abcd")

  (check (srfi.string-trim-both "UUabcdUU" char-upper-case?)	=> "abcd")

  #f)


(parametrise ((check-test-name 'modification))

  (check
      (let ((str (string-copy "abcd")))
	(srfi.string-set! str 0 #\A)
	str)
    => "Abcd")

  (check
      (let ((str (string-copy "abcd")))
	(srfi.string-set! str 3 #\D)
	str)
    => "abcD")

;;; --------------------------------------------------------------------

  (check
      (let ((str (string-copy "abcd")))
	(srfi.string-fill! #\B str)
	str)
    => "BBBB")

  (check
      (let ((str (string-copy "abcd")))
	(srfi.string-fill! #\B str 0 4)
	str)
    => "BBBB")

  (check
      (let ((str (string-copy "abcd")))
	(srfi.string-fill! #\B str 1 4)
	str)
    => "aBBB")

  (check
      (let ((str (string-copy "abcd")))
	(srfi.string-fill! #\B str 2 4)
	str)
    => "abBB")

  (check
      (let ((str (string-copy "abcd")))
	(srfi.string-fill! #\B str 3 4)
	str)
    => "abcB")

  (check
      (let ((str (string-copy "abcd")))
	(srfi.string-fill! #\B str 4 4)
	str)
    => "abcd")

  (check
      (let ((str (string-copy "abcd")))
	(srfi.string-fill! #\B str 0 3)
	str)
    => "BBBd")

  (check
      (let ((str (string-copy "abcd")))
	(srfi.string-fill! #\B str 0 2)
	str)
    => "BBcd")

  (check
      (let ((str (string-copy "abcd")))
	(srfi.string-fill! #\B str 2 2)
	str)
    => "abcd")

  (check
      (let ((str (string-copy "abcd")))
	(srfi.string-fill! #\B str 2 3)
	str)
    => "abBd")

  #f)


(parametrise ((check-test-name 'comparison-lexicographic-case-sensitive))

  (check
      (let* ((str1 "abcdefg") (beg1 0) (end1 (string-length str1))
	     (str2 "abcd123") (beg2 0) (end2 (string-length str2)))
	(srfi.string-compare str1 str2 values values values beg1 end1 beg2 end2))
    => 4)

  (check
      (let* ((str1 "abcdef") (beg1 0) (end1 (string-length str1))
	     (str2 "abcd123") (beg2 0) (end2 (string-length str2)))
	(srfi.string-compare str1 str2 values values values beg1 end1 beg2 end2))
    => 4)

  (check
      (let* ((str1 "efg") (beg1 0) (end1 (string-length str1))
	     (str2 "123") (beg2 0) (end2 (string-length str2)))
	(srfi.string-compare str1 str2 values values values beg1 end1 beg2 end2))
    => 0)

  (check
      (let* ((str1 "") (beg1 0) (end1 (string-length str1))
	     (str2 "abcd") (beg2 0) (end2 (string-length str2)))
	(srfi.string-compare str1 str2 values values values beg1 end1 beg2 end2))
    => 0)

  (check
      (let* ((str1 "abcd") (beg1 0) (end1 (string-length str1))
	     (str2 "") (beg2 0) (end2 (string-length str2)))
	(srfi.string-compare str1 str2 values values values beg1 end1 beg2 end2))
    => 0)

  (check
      (let* ((str1 "abcdA") (beg1 0) (end1 (string-length str1))
	     (str2 "abcdA") (beg2 0) (end2 (string-length str2)))
	(srfi.string-compare str1 str2
			     (lambda (idx) 'less) (lambda (idx) 'equal) (lambda (idx) 'greater)
			     beg1 end1 beg2 end2))
    => 'equal)

  (check
      (let* ((str1 "abcdA") (beg1 0) (end1 (string-length str1))
	     (str2 "abcdB") (beg2 0) (end2 (string-length str2)))
	(srfi.string-compare str1 str2
			     (lambda (idx) 'less) (lambda (idx) 'equal) (lambda (idx) 'greater)
			     beg1 end1 beg2 end2))
    => 'less)

  (check
      (let* ((str1 "abcdB") (beg1 0) (end1 (string-length str1))
	     (str2 "abcdA") (beg2 0) (end2 (string-length str2)))
	(srfi.string-compare str1 str2
			     (lambda (idx) 'less) (lambda (idx) 'equal) (lambda (idx) 'greater)
			     beg1 end1 beg2 end2))
    => 'greater)

;;; --------------------------------------------------------------------

  (check-for-true
   (let* ((str "abcd")
	  (beg1 0) (end1 (string-length str))
	  (beg2 0) (end2 (string-length str)))
     (srfi.string= str str beg1 end1 beg2 end2)))

  (check-for-true
   (let* ((str1 "12abcd") (beg1 2) (end1 (string-length str1))
	  (str2 "abcd") (beg2 0) (end2 (string-length str2)))
     (srfi.string= str1 str2 beg1 end1 beg2 end2)))

  (check-for-false
   (let* ((str1 "abc") (beg1 0) (end1 (string-length str1))
	  (str2 "abcd") (beg2 0) (end2 (string-length str2)))
     (srfi.string= str1 str2 beg1 end1 beg2 end2)))

  (check-for-false
   (let* ((str1 "abcd") (beg1 0) (end1 (string-length str1))
	  (str2 "abc") (beg2 0) (end2 (string-length str2)))
     (srfi.string= str1 str2 beg1 end1 beg2 end2)))

  (check-for-false
   (let* ((str1 "ABcd") (beg1 0) (end1 (string-length str1))
	  (str2 "abcd") (beg2 0) (end2 (string-length str2)))
     (srfi.string= str1 str2 beg1 end1 beg2 end2)))

  (check-for-false
   (let* ((str1 "abcd") (beg1 0) (end1 (string-length str1))
	  (str2 "a2cd") (beg2 0) (end2 (string-length str2)))
     (srfi.string= str1 str2 beg1 end1 beg2 end2)))

;;; --------------------------------------------------------------------

  (check-for-false
   (let* ((str1 "abcd") (beg1 0) (end1 (string-length str1))
	  (str2 "abcd") (beg2 0) (end2 (string-length str2)))
     (srfi.string<> str1 str2 beg1 end1 beg2 end2)))

  (check-for-true
   (let* ((str1 "abc") (beg1 0) (end1 (string-length str1))
	  (str2 "abcd") (beg2 0) (end2 (string-length str2)))
     (srfi.string<> str1 str2 beg1 end1 beg2 end2)))

  (check-for-true
   (let* ((str1 "abcd") (beg1 0) (end1 (string-length str1))
	  (str2 "abc") (beg2 0) (end2 (string-length str2)))
     (srfi.string<> str1 str2 beg1 end1 beg2 end2)))

  (check-for-true
   (let* ((str1 "ABcd") (beg1 0) (end1 (string-length str1))
	  (str2 "abcd") (beg2 0) (end2 (string-length str2)))
     (srfi.string<> str1 str2 beg1 end1 beg2 end2)))

  (check-for-true
   (let* ((str1 "abcd") (beg1 0) (end1 (string-length str1))
	  (str2 "a2cd") (beg2 0) (end2 (string-length str2)))
     (srfi.string<> str1 str2 beg1 end1 beg2 end2)))

;;; --------------------------------------------------------------------

  ;;STR1 is less than STR2:
  ;;
  ;;* If the character at the  mismatch index from STR1 is less than the
  ;;  character at the mismatch index from STR2.
  ;;
  ;;* The strings are equal up to the end of STR1 and STR2 is longer.

  (check-for-false
   (let* ((str1 "abcd") (beg1 0) (end1 (string-length str1))
	  (str2 "abcd") (beg2 0) (end2 (string-length str2)))
     (srfi.string< str1 str2 beg1 end1 beg2 end2)))

  (check-for-true
   (let* ((str1 "abc")  (beg1 0) (end1 (string-length str1))
	  (str2 "abcd") (beg2 0) (end2 (string-length str2)))
     (srfi.string< str1 str2 beg1 end1 beg2 end2)))

  (check-for-false
   (let* ((str1 "abcd") (beg1 0) (end1 (string-length str1))
	  (str2 "abc") (beg2 0) (end2 (string-length str2)))
     (srfi.string< str1 str2 beg1 end1 beg2 end2)))

  (check-for-true
   (let* ((str1 "ABcd") (beg1 0) (end1 (string-length str1))
	  (str2 "abcd") (beg2 0) (end2 (string-length str2)))
     (srfi.string< str1 str2 beg1 end1 beg2 end2)))

  (check-for-true
   (let* ((str1 "ABCD") (beg1 0) (end1 (string-length str1))
	  (str2 "abcd") (beg2 0) (end2 (string-length str2)))
     (srfi.string< str1 str2 beg1 end1 beg2 end2)))

  (check-for-false
   (let* ((str1 "ABCD") (beg1 0) (end1 (string-length str1))
	  (str2 "A2CD") (beg2 0) (end2 (string-length str2)))
     (srfi.string< str1 str2 beg1 end1 beg2 end2)))

;;; --------------------------------------------------------------------

  ;;STR1 is less than, or equal to, STR2:
  ;;
  ;;* If the strings are equal.
  ;;
  ;;* If the character at the  mismatch index from STR1 is less than the
  ;;  character at the mismatch index from STR2.
  ;;
  ;;* The strings are equal up to the end of STR1 and STR2 is longer.

  (check-for-true
   (let* ((str1 "abcd") (beg1 0) (end1 (string-length str1))
	  (str2 "abcd") (beg2 0) (end2 (string-length str2)))
     (srfi.string<= str1 str2 beg1 end1 beg2 end2)))

  (check-for-true
   (let* ((str1 "abc") (beg1 0) (end1 (string-length str1))
	  (str2 "abcd") (beg2 0) (end2 (string-length str2)))
     (srfi.string<= str1 str2 beg1 end1 beg2 end2)))

  (check-for-false
   (let* ((str1 "abcd") (beg1 0) (end1 (string-length str1))
	  (str2 "abc")  (beg2 0) (end2 (string-length str2)))
     (srfi.string<= str1 str2 beg1 end1 beg2 end2)))

  (check-for-true
   (let* ((str1 "ABcd") (beg1 0) (end1 (string-length str1))
	  (str2 "abcd") (beg2 0) (end2 (string-length str2)))
     (srfi.string<= str1 str2 beg1 end1 beg2 end2)))

  (check-for-false
   (let* ((str1 "abcd") (beg1 0) (end1 (string-length str1))
	  (str2 "a2cd") (beg2 0) (end2 (string-length str2)))
     (srfi.string<= str1 str2 beg1 end1 beg2 end2)))

;;; --------------------------------------------------------------------

  ;;STR1 is greater than STR2:
  ;;
  ;;* If the  character at the mismatch index from  STR1 is greater than
  ;;  the character at the mismatch index from STR2.
  ;;
  ;;* The strings are equal up to the end of STR2 and STR1 is longer.

  (check-for-false
   (let* ((str1 "abcd") (beg1 0) (end1 (string-length str1))
	  (str2 "abcd") (beg2 0) (end2 (string-length str2)))
     (srfi.string> str1 str2 beg1 end1 beg2 end2)))

  (check-for-true
   (let* ((str1 "abcd") (beg1 0) (end1 (string-length str1))
	  (str2 "abc") (beg2 0) (end2 (string-length str2)))
     (srfi.string> str1 str2 beg1 end1 beg2 end2)))

  (check-for-false
   (let* ((str1 "abc") (beg1 0) (end1 (string-length str1))
	  (str2 "abcd") (beg2 0) (end2 (string-length str2)))
     (srfi.string> str1 str2 beg1 end1 beg2 end2)))

  (check-for-true
   (let* ((str1 "abcd") (beg1 0) (end1 (string-length str1))
	  (str2 "ABcd") (beg2 0) (end2 (string-length str2)))
     (srfi.string> str1 str2 beg1 end1 beg2 end2)))

  (check-for-false
   (let* ((str1 "a2cd") (beg1 0) (end1 (string-length str1))
	  (str2 "abcd") (beg2 0) (end2 (string-length str2)))
     (srfi.string> str1 str2 beg1 end1 beg2 end2)))

;;; --------------------------------------------------------------------

  ;;STR1 is greater than, or equal to, STR2:
  ;;
  ;;* If the strings are equal.
  ;;
  ;;* If the  character at the mismatch index from  STR1 is greater than
  ;;  the character at the mismatch index from STR2.
  ;;
  ;;* The strings are equal up to the end of STR2 and STR1 is longer.

  (check-for-true
   (let* ((str1 "abcd") (beg1 0) (end1 (string-length str1))
	  (str2 "abcd") (beg2 0) (end2 (string-length str2)))
     (srfi.string>= str1 str2 beg1 end1 beg2 end2)))

  (check-for-true
   (let* ((str1 "abcd") (beg1 0) (end1 (string-length str1))
	  (str2 "abc") (beg2 0) (end2 (string-length str2)))
     (srfi.string>= str1 str2 beg1 end1 beg2 end2)))

  (check-for-false
   (let* ((str1 "abc") (beg1 0) (end1 (string-length str1))
	  (str2 "abcd") (beg2 0) (end2 (string-length str2)))
     (srfi.string>= str1 str2 beg1 end1 beg2 end2)))

  (check-for-true
   (let* ((str1 "abcd") (beg1 0) (end1 (string-length str1))
	  (str2 "ABcd") (beg2 0) (end2 (string-length str2)))
     (srfi.string>= str1 str2 beg1 end1 beg2 end2)))

  (check-for-true
   (let* ((str1 "abcd") (beg1 0) (end1 (string-length str1))
	  (str2 "ABCD") (beg2 0) (end2 (string-length str2)))
     (srfi.string>= str1 str2 beg1 end1 beg2 end2)))

  (check-for-false
   (let* ((str1 "a2cd") (beg1 0) (end1 (string-length str1))
	  (str2 "abcd") (beg2 0) (end2 (string-length str2)))
     (srfi.string>= str1 str2 beg1 end1 beg2 end2)))

  #t)


(parametrise ((check-test-name 'comparison-lexicographic-case-insensitive))

  (check
      (let* ((str1 "aBcdefg") (beg1 0) (end1 (string-length str1))
	     (str2 "abcd123") (beg2 0) (end2 (string-length str2)))
	(srfi.string-compare-ci str1 str2 values values values beg1 end1 beg2 end2))
    => 4)

  (check
      (let* ((str1 "efg") (beg1 0) (end1 (string-length str1))
	     (str2 "123") (beg2 0) (end2 (string-length str2)))
	(srfi.string-compare-ci str1 str2 values values values beg1 end1 beg2 end2))
    => 0)

  (check
      (let* ((str1 "") (beg1 0) (end1 (string-length str1))
	     (str2 "abcd") (beg2 0) (end2 (string-length str2)))
	(srfi.string-compare-ci str1 str2 values values values beg1 end1 beg2 end2))
    => 0)

  (check
      (let* ((str1 "abcd") (beg1 0) (end1 (string-length str1))
	     (str2 "") (beg2 0) (end2 (string-length str2)))
	(srfi.string-compare-ci str1 str2 values values values beg1 end1 beg2 end2))
    => 0)

  (check
      (let* ((str1 "abcdA") (beg1 0) (end1 (string-length str1))
	     (str2 "abcda") (beg2 0) (end2 (string-length str2)))
	(srfi.string-compare-ci str1 str2
				(lambda (idx) 'less) (lambda (idx) 'equal) (lambda (idx) 'greater)
				beg1 end1 beg2 end2))
    => 'equal)

  (check
      (let* ((str1 "abcdA") (beg1 0) (end1 (string-length str1))
	     (str2 "abcdb") (beg2 0) (end2 (string-length str2)))
	(srfi.string-compare-ci str1 str2
				(lambda (idx) 'less) (lambda (idx) 'equal) (lambda (idx) 'greater)
				beg1 end1 beg2 end2))
    => 'less)

  (check
      (let* ((str1 "abcdb") (beg1 0) (end1 (string-length str1))
	     (str2 "abcdA") (beg2 0) (end2 (string-length str2)))
	(srfi.string-compare-ci str1 str2
				(lambda (idx) 'less) (lambda (idx) 'equal) (lambda (idx) 'greater)
				beg1 end1 beg2 end2))
    => 'greater)

;;; --------------------------------------------------------------------

  (check-for-true
   (let* ((str "abcd")
	  (beg1 0) (end1 (string-length str))
	  (beg2 0) (end2 (string-length str)))
     (srfi.string-ci= str str beg1 end1 beg2 end2)))

  (check-for-true
   (let* ((str1 "12abcd") (beg1 2) (end1 (string-length str1))
	  (str2 "abcd") (beg2 0) (end2 (string-length str2)))
     (srfi.string-ci= str1 str2 beg1 end1 beg2 end2)))

  (check-for-false
   (let* ((str1 "abc") (beg1 0) (end1 (string-length str1))
	  (str2 "abcd") (beg2 0) (end2 (string-length str2)))
     (srfi.string-ci= str1 str2 beg1 end1 beg2 end2)))

  (check-for-false
   (let* ((str1 "abcd") (beg1 0) (end1 (string-length str1))
	  (str2 "abc") (beg2 0) (end2 (string-length str2)))
     (srfi.string-ci= str1 str2 beg1 end1 beg2 end2)))

  (check-for-true
   (let* ((str1 "ABcd") (beg1 0) (end1 (string-length str1))
	  (str2 "abcd") (beg2 0) (end2 (string-length str2)))
     (srfi.string-ci= str1 str2 beg1 end1 beg2 end2)))

  (check-for-false
   (let* ((str1 "abcd") (beg1 0) (end1 (string-length str1))
	  (str2 "a2cd") (beg2 0) (end2 (string-length str2)))
     (srfi.string-ci= str1 str2 beg1 end1 beg2 end2)))

;;; --------------------------------------------------------------------

  (check-for-false
   (let* ((str1 "abcd") (beg1 0) (end1 (string-length str1))
	  (str2 "abcd") (beg2 0) (end2 (string-length str2)))
     (srfi.string-ci<> str1 str2 beg1 end1 beg2 end2)))

  (check-for-true
   (let* ((str1 "abc") (beg1 0) (end1 (string-length str1))
	  (str2 "abcd") (beg2 0) (end2 (string-length str2)))
     (srfi.string-ci<> str1 str2 beg1 end1 beg2 end2)))

  (check-for-true
   (let* ((str1 "abcd") (beg1 0) (end1 (string-length str1))
	  (str2 "abc") (beg2 0) (end2 (string-length str2)))
     (srfi.string-ci<> str1 str2 beg1 end1 beg2 end2)))

  (check-for-false
   (let* ((str1 "ABcd") (beg1 0) (end1 (string-length str1))
	  (str2 "abcd") (beg2 0) (end2 (string-length str2)))
     (srfi.string-ci<> str1 str2 beg1 end1 beg2 end2)))

  (check-for-true
   (let* ((str1 "abcd") (beg1 0) (end1 (string-length str1))
	  (str2 "a2cd") (beg2 0) (end2 (string-length str2)))
     (srfi.string-ci<> str1 str2 beg1 end1 beg2 end2)))

;;; --------------------------------------------------------------------

  (check-for-false
   (let* ((str1 "abcd") (beg1 0) (end1 (string-length str1))
	  (str2 "abcd") (beg2 0) (end2 (string-length str2)))
     (srfi.string-ci< str1 str2 beg1 end1 beg2 end2)))

  (check-for-true
   (let* ((str1 "abc") (beg1 0) (end1 (string-length str1))
	  (str2 "abcd") (beg2 0) (end2 (string-length str2)))
     (srfi.string-ci< str1 str2 beg1 end1 beg2 end2)))

  (check-for-false
   (let* ((str1 "abcd") (beg1 0) (end1 (string-length str1))
	  (str2 "abc") (beg2 0) (end2 (string-length str2)))
     (srfi.string-ci< str1 str2 beg1 end1 beg2 end2)))

  (check-for-false
   (let* ((str1 "ABcd") (beg1 0) (end1 (string-length str1))
	  (str2 "abcd") (beg2 0) (end2 (string-length str2)))
     (srfi.string-ci< str1 str2 beg1 end1 beg2 end2)))

  (check-for-false
   (let* ((str1 "abcd") (beg1 0) (end1 (string-length str1))
	  (str2 "a2cd") (beg2 0) (end2 (string-length str2)))
     (srfi.string-ci< str1 str2 beg1 end1 beg2 end2)))

;;; --------------------------------------------------------------------

  (check-for-true
   (let* ((str1 "abcd") (beg1 0) (end1 (string-length str1))
	  (str2 "abcd") (beg2 0) (end2 (string-length str2)))
     (srfi.string-ci<= str1 str2 beg1 end1 beg2 end2)))

  (check-for-true
   (let* ((str1 "abc") (beg1 0) (end1 (string-length str1))
	  (str2 "abcd") (beg2 0) (end2 (string-length str2)))
     (srfi.string-ci<= str1 str2 beg1 end1 beg2 end2)))

  (check-for-false
   (let* ((str1 "abcd") (beg1 0) (end1 (string-length str1))
	  (str2 "abc") (beg2 0) (end2 (string-length str2)))
     (srfi.string-ci<= str1 str2 beg1 end1 beg2 end2)))

  (check-for-true
   (let* ((str1 "ABcd") (beg1 0) (end1 (string-length str1))
	  (str2 "abcd") (beg2 0) (end2 (string-length str2)))
     (srfi.string-ci<= str1 str2 beg1 end1 beg2 end2)))

  (check-for-false
   (let* ((str1 "abcd") (beg1 0) (end1 (string-length str1))
	  (str2 "a2cd") (beg2 0) (end2 (string-length str2)))
     (srfi.string-ci<= str1 str2 beg1 end1 beg2 end2)))

;;; --------------------------------------------------------------------

  (check-for-false
   (let* ((str1 "abcd") (beg1 0) (end1 (string-length str1))
	  (str2 "abcd") (beg2 0) (end2 (string-length str2)))
     (srfi.string-ci> str1 str2 beg1 end1 beg2 end2)))

  (check-for-true
   (let* ((str1 "abcd") (beg1 0) (end1 (string-length str1))
	  (str2 "abc") (beg2 0) (end2 (string-length str2)))
     (srfi.string-ci> str1 str2 beg1 end1 beg2 end2)))

  (check-for-false
   (let* ((str1 "abc") (beg1 0) (end1 (string-length str1))
	  (str2 "abcd") (beg2 0) (end2 (string-length str2)))
     (srfi.string-ci> str1 str2 beg1 end1 beg2 end2)))

  (check-for-false
   (let* ((str1 "abcd") (beg1 0) (end1 (string-length str1))
	  (str2 "ABcd") (beg2 0) (end2 (string-length str2)))
     (srfi.string-ci> str1 str2 beg1 end1 beg2 end2)))

  (check-for-false
   (let* ((str1 "a2cd") (beg1 0) (end1 (string-length str1))
	  (str2 "abcd") (beg2 0) (end2 (string-length str2)))
     (srfi.string-ci> str1 str2 beg1 end1 beg2 end2)))

;;; --------------------------------------------------------------------

  (check-for-true
   (let* ((str1 "abcd") (beg1 0) (end1 (string-length str1))
	  (str2 "abcd") (beg2 0) (end2 (string-length str2)))
     (srfi.string-ci>= str1 str2 beg1 end1 beg2 end2)))

  (check-for-true
   (let* ((str1 "abcd") (beg1 0) (end1 (string-length str1))
	  (str2 "abc") (beg2 0) (end2 (string-length str2)))
     (srfi.string-ci>= str1 str2 beg1 end1 beg2 end2)))

  (check-for-false
   (let* ((str1 "abc") (beg1 0) (end1 (string-length str1))
	  (str2 "abcd") (beg2 0) (end2 (string-length str2)))
     (srfi.string-ci>= str1 str2 beg1 end1 beg2 end2)))

  (check-for-true
   (let* ((str1 "abcd") (beg1 0) (end1 (string-length str1))
	  (str2 "ABcd") (beg2 0) (end2 (string-length str2)))
     (srfi.string-ci>= str1 str2 beg1 end1 beg2 end2)))

  (check-for-false
   (let* ((str1 "a2cd") (beg1 0) (end1 (string-length str1))
	  (str2 "abcd") (beg2 0) (end2 (string-length str2)))
     (srfi.string-ci>= str1 str2 beg1 end1 beg2 end2)))

  #t)


(parametrise ((check-test-name	'hash))

  (check
      (fixnum? (srfi.string-hash "ciao"))
    => #t)

  (check
      (fx<? (srfi.string-hash "ciao" 10) 10)
    => #t)

  (check
      (fixnum? (srfi.string-hash "ciao" 10 0))
    => #t)

  (check
      (fixnum? (srfi.string-hash "ciao" 10 0 4))
    => #t)

  (check
      (fixnum? (srfi.string-hash "ciao" 10 2 3))
    => #t)

  (check
      (fixnum? (srfi.string-hash "ciao" 10 2 2))
    => #t)

  #t)


(parametrise ((check-test-name 'prefix))

  (check
      (let* ((str1 "abcdefg") (beg1 0) (end1 (string-length str1))
	     (str2 "abcd123") (beg2 0) (end2 (string-length str2)))
	(srfi.string-prefix-length str1 str2 beg1 end1 beg2 end2))
    => 4)

  (check
      (let* ((str1 "aBcdefg") (beg1 0) (end1 (string-length str1))
	     (str2 "abcd123") (beg2 0) (end2 (string-length str2)))
	(srfi.string-prefix-length str1 str2 beg1 end1 beg2 end2))
    => 1)

  (check
      (let* ((str1 "efg") (beg1 0) (end1 (string-length str1))
	     (str2 "123") (beg2 0) (end2 (string-length str2)))
	(srfi.string-prefix-length str1 str2 beg1 end1 beg2 end2))
    => 0)

  (check
      (let* ((str1 "a") (beg1 0) (end1 (string-length str1))
	     (str2 "a") (beg2 0) (end2 (string-length str2)))
	(srfi.string-prefix-length str1 str2 beg1 end1 beg2 end2))
    => 1)

  (check
      (let* ((str1 "1") (beg1 0) (end1 (string-length str1))
	     (str2 "2") (beg2 0) (end2 (string-length str2)))
	(srfi.string-prefix-length str1 str2 beg1 end1 beg2 end2))
    => 0)

  (check
      (let* ((str1 "") (beg1 0) (end1 (string-length str1))
	     (str2 "abcd123") (beg2 0) (end2 (string-length str2)))
	(srfi.string-prefix-length str1 str2 beg1 end1 beg2 end2))
    => 0)

  (check
      (let* ((str1 "abcdefg") (beg1 0) (end1 (string-length str1))
	     (str2 "") (beg2 0) (end2 (string-length str2)))
	(srfi.string-prefix-length str1 str2 beg1 end1 beg2 end2))
    => 0)

;;; --------------------------------------------------------------------

  (check
      (let* ((str1 "efgabcd") (beg1 0) (end1 (string-length str1))
	     (str2 "123abcd") (beg2 0) (end2 (string-length str2)))
	(srfi.string-suffix-length str1 str2 beg1 end1 beg2 end2))
    => 4)

  (check
      (let* ((str1 "efgabcd") (beg1 0) (end1 (string-length str1))
	     (str2 "123abCd") (beg2 0) (end2 (string-length str2)))
	(srfi.string-suffix-length str1 str2 beg1 end1 beg2 end2))
    => 1)

  (check
      (let* ((str1 "efg") (beg1 0) (end1 (string-length str1))
	     (str2 "123") (beg2 0) (end2 (string-length str2)))
	(srfi.string-suffix-length str1 str2 beg1 end1 beg2 end2))
    => 0)

  (check
      (let* ((str1 "a") (beg1 0) (end1 (string-length str1))
	     (str2 "a") (beg2 0) (end2 (string-length str2)))
	(srfi.string-suffix-length str1 str2 beg1 end1 beg2 end2))
    => 1)

  (check
      (let* ((str1 "1") (beg1 0) (end1 (string-length str1))
	     (str2 "2") (beg2 0) (end2 (string-length str2)))
	(srfi.string-suffix-length str1 str2 beg1 end1 beg2 end2))
    => 0)

  (check
      (let* ((str1 "") (beg1 0) (end1 (string-length str1))
	     (str2 "abcd123") (beg2 0) (end2 (string-length str2)))
	(srfi.string-suffix-length str1 str2 beg1 end1 beg2 end2))
    => 0)

  (check
      (let* ((str1 "abcdefg") (beg1 0) (end1 (string-length str1))
	     (str2 "") (beg2 0) (end2 (string-length str2)))
	(srfi.string-suffix-length str1 str2 beg1 end1 beg2 end2))
    => 0)

;;; --------------------------------------------------------------------

  (check
      (let* ((str1 "aBcdefg") (beg1 0) (end1 (string-length str1))
	     (str2 "aBcd123") (beg2 0) (end2 (string-length str2)))
	(srfi.string-prefix-length-ci str1 str2 beg1 end1 beg2 end2))
    => 4)

  (check
      (let* ((str1 "aBcdefg") (beg1 0) (end1 (string-length str1))
	     (str2 "abcd123") (beg2 0) (end2 (string-length str2)))
	(srfi.string-prefix-length-ci str1 str2 beg1 end1 beg2 end2))
    => 4)

  (check
      (let* ((str1 "efg") (beg1 0) (end1 (string-length str1))
	     (str2 "123") (beg2 0) (end2 (string-length str2)))
	(srfi.string-prefix-length-ci str1 str2 beg1 end1 beg2 end2))
    => 0)

  (check
      (let* ((str1 "a") (beg1 0) (end1 (string-length str1))
	     (str2 "a") (beg2 0) (end2 (string-length str2)))
	(srfi.string-prefix-length-ci str1 str2 beg1 end1 beg2 end2))
    => 1)

  (check
      (let* ((str1 "1") (beg1 0) (end1 (string-length str1))
	     (str2 "2") (beg2 0) (end2 (string-length str2)))
	(srfi.string-prefix-length-ci str1 str2 beg1 end1 beg2 end2))
    => 0)

  (check
      (let* ((str1 "") (beg1 0) (end1 (string-length str1))
	     (str2 "abcd123") (beg2 0) (end2 (string-length str2)))
	(srfi.string-prefix-length-ci str1 str2 beg1 end1 beg2 end2))
    => 0)

  (check
      (let* ((str1 "abcdefg") (beg1 0) (end1 (string-length str1))
	     (str2 "") (beg2 0) (end2 (string-length str2)))
	(srfi.string-prefix-length-ci str1 str2 beg1 end1 beg2 end2))
    => 0)

;;; --------------------------------------------------------------------

  (check
      (let* ((str1 "efgabCd") (beg1 0) (end1 (string-length str1))
	     (str2 "123abCd") (beg2 0) (end2 (string-length str2)))
	(srfi.string-suffix-length-ci str1 str2 beg1 end1 beg2 end2))
    => 4)

  (check
      (let* ((str1 "efgabCd") (beg1 0) (end1 (string-length str1))
	     (str2 "123abcd") (beg2 0) (end2 (string-length str2)))
	(srfi.string-suffix-length-ci str1 str2 beg1 end1 beg2 end2))
    => 4)

  (check
      (let* ((str1 "efg") (beg1 0) (end1 (string-length str1))
	     (str2 "123") (beg2 0) (end2 (string-length str2)))
	(srfi.string-suffix-length-ci str1 str2 beg1 end1 beg2 end2))
    => 0)

  (check
      (let* ((str1 "a") (beg1 0) (end1 (string-length str1))
	     (str2 "a") (beg2 0) (end2 (string-length str2)))
	(srfi.string-suffix-length-ci str1 str2 beg1 end1 beg2 end2))
    => 1)

  (check
      (let* ((str1 "1") (beg1 0) (end1 (string-length str1))
	     (str2 "2") (beg2 0) (end2 (string-length str2)))
	(srfi.string-suffix-length-ci str1 str2 beg1 end1 beg2 end2))
    => 0)

  (check
      (let* ((str1 "") (beg1 0) (end1 (string-length str1))
	     (str2 "abcd123") (beg2 0) (end2 (string-length str2)))
	(srfi.string-suffix-length-ci str1 str2 beg1 end1 beg2 end2))
    => 0)

  (check
      (let* ((str1 "abcdefg") (beg1 0) (end1 (string-length str1))
	     (str2 "") (beg2 0) (end2 (string-length str2)))
	(srfi.string-suffix-length-ci str1 str2 beg1 end1 beg2 end2))
    => 0)

;;; --------------------------------------------------------------------

  (check
      (let* ((str1 "abcd") (beg1 0) (end1 (string-length str1))
	     (str2 "abcd123") (beg2 0) (end2 (string-length str2)))
	(srfi.string-prefix? str1 str2 beg1 end1 beg2 end2))
    => #t)

  (check
      (let* ((str1 "abcd") (beg1 0) (end1 (string-length str1))
	     (str2 "aBcd123") (beg2 0) (end2 (string-length str2)))
	(srfi.string-prefix? str1 str2 beg1 end1 beg2 end2))
    => #f)

  (check
      (let* ((str1 "efg") (beg1 0) (end1 (string-length str1))
	     (str2 "123") (beg2 0) (end2 (string-length str2)))
	(srfi.string-prefix? str1 str2 beg1 end1 beg2 end2))
    => #f)

  (check
      (let* ((str1 "") (beg1 0) (end1 (string-length str1))
	     (str2 "123") (beg2 0) (end2 (string-length str2)))
	(srfi.string-prefix? str1 str2 beg1 end1 beg2 end2))
    => #t)

  (check
      (let* ((str1 "efg") (beg1 0) (end1 (string-length str1))
	     (str2 "") (beg2 0) (end2 (string-length str2)))
	(srfi.string-prefix? str1 str2 beg1 end1 beg2 end2))
    => #f)

  (check
      (let* ((str1 "") (beg1 0) (end1 (string-length str1))
	     (str2 "") (beg2 0) (end2 (string-length str2)))
	(srfi.string-prefix? str1 str2 beg1 end1 beg2 end2))
    => #t)

;;; --------------------------------------------------------------------

  (check
      (let* ((str1 "aBcd") (beg1 0) (end1 (string-length str1))
	     (str2 "aBcd123") (beg2 0) (end2 (string-length str2)))
	(srfi.string-prefix-ci? str1 str2 beg1 end1 beg2 end2))
    => #t)

  (check
      (let* ((str1 "abcd") (beg1 0) (end1 (string-length str1))
	     (str2 "aBcd123") (beg2 0) (end2 (string-length str2)))
	(srfi.string-prefix-ci? str1 str2 beg1 end1 beg2 end2))
    => #t)

  (check
      (let* ((str1 "efg") (beg1 0) (end1 (string-length str1))
	     (str2 "123") (beg2 0) (end2 (string-length str2)))
	(srfi.string-prefix-ci? str1 str2 beg1 end1 beg2 end2))
    => #f)

  (check
      (let* ((str1 "") (beg1 0) (end1 (string-length str1))
	     (str2 "123") (beg2 0) (end2 (string-length str2)))
	(srfi.string-prefix-ci? str1 str2 beg1 end1 beg2 end2))
    => #t)

  (check
      (let* ((str1 "efg") (beg1 0) (end1 (string-length str1))
	     (str2 "") (beg2 0) (end2 (string-length str2)))
	(srfi.string-prefix-ci? str1 str2 beg1 end1 beg2 end2))
    => #f)

  (check
      (let* ((str1 "") (beg1 0) (end1 (string-length str1))
	     (str2 "") (beg2 0) (end2 (string-length str2)))
	(srfi.string-prefix-ci? str1 str2 beg1 end1 beg2 end2))
    => #t)

;;; --------------------------------------------------------------------

  (check
      (let* ((str1 "abcd") (beg1 0) (end1 (string-length str1))
	     (str2 "123abcd") (beg2 0) (end2 (string-length str2)))
	(srfi.string-suffix? str1 str2 beg1 end1 beg2 end2))
    => #t)

  (check
      (let* ((str1 "abcd") (beg1 0) (end1 (string-length str1))
	     (str2 "123aBcd") (beg2 0) (end2 (string-length str2)))
	(srfi.string-suffix? str1 str2 beg1 end1 beg2 end2))
    => #f)

  (check
      (let* ((str1 "efg") (beg1 0) (end1 (string-length str1))
	     (str2 "123") (beg2 0) (end2 (string-length str2)))
	(srfi.string-suffix? str1 str2 beg1 end1 beg2 end2))
    => #f)

  (check
      (let* ((str1 "") (beg1 0) (end1 (string-length str1))
	     (str2 "123") (beg2 0) (end2 (string-length str2)))
	(srfi.string-suffix? str1 str2 beg1 end1 beg2 end2))
    => #t)

  (check
      (let* ((str1 "efg") (beg1 0) (end1 (string-length str1))
	     (str2 "") (beg2 0) (end2 (string-length str2)))
	(srfi.string-suffix? str1 str2 beg1 end1 beg2 end2))
    => #f)

  (check
      (let* ((str1 "") (beg1 0) (end1 (string-length str1))
	     (str2 "") (beg2 0) (end2 (string-length str2)))
	(srfi.string-suffix? str1 str2 beg1 end1 beg2 end2))
    => #t)

;;; --------------------------------------------------------------------

  (check
      (let* ((str1 "aBcd") (beg1 0) (end1 (string-length str1))
	     (str2 "123aBcd") (beg2 0) (end2 (string-length str2)))
	(srfi.string-suffix-ci? str1 str2 beg1 end1 beg2 end2))
    => #t)

  (check
      (let* ((str1 "abcd") (beg1 0) (end1 (string-length str1))
	     (str2 "123aBcd") (beg2 0) (end2 (string-length str2)))
	(srfi.string-suffix-ci? str1 str2 beg1 end1 beg2 end2))
    => #t)

  (check
      (let* ((str1 "efg") (beg1 0) (end1 (string-length str1))
	     (str2 "123") (beg2 0) (end2 (string-length str2)))
	(srfi.string-suffix-ci? str1 str2 beg1 end1 beg2 end2))
    => #f)

  (check
      (let* ((str1 "") (beg1 0) (end1 (string-length str1))
	     (str2 "123") (beg2 0) (end2 (string-length str2)))
	(srfi.string-suffix-ci? str1 str2 beg1 end1 beg2 end2))
    => #t)

  (check
      (let* ((str1 "efg") (beg1 0) (end1 (string-length str1))
	     (str2 "") (beg2 0) (end2 (string-length str2)))
	(srfi.string-suffix-ci? str1 str2 beg1 end1 beg2 end2))
    => #f)

  (check
      (let* ((str1 "") (beg1 0) (end1 (string-length str1))
	     (str2 "") (beg2 0) (end2 (string-length str2)))
	(srfi.string-suffix-ci? str1 str2 beg1 end1 beg2 end2))
    => #t)

  #f)


(parametrise ((check-test-name 'searching))

  (check
      (let* ((str "abcd") (beg 0) (end (string-length str)))
	(srfi.string-index str #\b beg end))
    => 1)

  (check
      (let* ((str "abcd") (end (string-length str)))
	(srfi.string-index str #\b 1 end))
    => 1)

  (check
      (let* ((str "abcd") (beg 0) (end (string-length str)))
	(srfi.string-index str #\1 beg end))
    => #f)

  (check
      (let* ((str "") (beg 0) (end (string-length str)))
	(srfi.string-index str #\1 beg end))
    => #f)

;;; --------------------------------------------------------------------

  (check
      (let* ((str "abcd") (beg 0) (end (string-length str)))
  	(srfi.string-index str (char-set #\b #\B) beg end))
    => 1)

  (check
      (let* ((str "abcd") (end (string-length str)))
  	(srfi.string-index str (char-set #\b #\B) 1 end))
    => 1)

  (check
      (let* ((str "abcd") (beg 0) (end (string-length str)))
  	(srfi.string-index str (char-set #\0 #\1) beg end))
    => #f)

  (check
      (let* ((str "") (beg 0) (end (string-length str)))
  	(srfi.string-index str (char-set #\0 #\1) beg end))
    => #f)

;;; --------------------------------------------------------------------

  (check
      (let* ((str "aBcd") (beg 0) (end (string-length str)))
	(srfi.string-index str char-upper-case? beg end))
    => 1)

  (check
      (let* ((str "aBcd") (end (string-length str)))
	(srfi.string-index str char-upper-case? 1 end))
    => 1)

  (check
      (let* ((str "abcd") (beg 0) (end (string-length str)))
	(srfi.string-index str char-upper-case? beg end))
    => #f)

  (check
      (let* ((str "") (beg 0) (end (string-length str)))
	(srfi.string-index str char-upper-case? beg end))
    => #f)

;;; --------------------------------------------------------------------

  (check
      (let* ((str "abcd") (beg 0) (end (string-length str)))
	(srfi.string-index-right str #\b beg end))
    => 1)

  (check
      (let* ((str "abcd") (end (string-length str)))
	(srfi.string-index-right str #\b 1 end))
    => 1)

  (check
      (let* ((str "abcd") (beg 0) (end (string-length str)))
	(srfi.string-index-right str #\1 beg end))
    => #f)

  (check
      (let* ((str "") (beg 0) (end (string-length str)))
	(srfi.string-index-right str #\1 beg end))
    => #f)

;;; --------------------------------------------------------------------

  (check
      (let* ((str "abcd") (beg 0) (end (string-length str)))
  	(srfi.string-index-right str (char-set #\b #\B) beg end))
    => 1)

  (check
      (let* ((str "abcd") (end (string-length str)))
  	(srfi.string-index-right str (char-set #\b #\B) 1 end))
    => 1)

  (check
      (let* ((str "abcd") (beg 0) (end (string-length str)))
  	(srfi.string-index-right str (char-set #\0 #\1) beg end))
    => #f)

  (check
      (let* ((str "") (beg 0) (end (string-length str)))
  	(srfi.string-index-right str (char-set #\0 #\1) beg end))
    => #f)

;;; --------------------------------------------------------------------

  (check
      (let* ((str "aBcd") (beg 0) (end (string-length str)))
	(srfi.string-index-right str char-upper-case? beg end))
    => 1)

  (check
      (let* ((str "aBcd") (end (string-length str)))
	(srfi.string-index-right str char-upper-case? 1 end))
    => 1)

  (check
      (let* ((str "abcd") (beg 0) (end (string-length str)))
	(srfi.string-index-right str char-upper-case? beg end))
    => #f)

  (check
      (let* ((str "") (beg 0) (end (string-length str)))
	(srfi.string-index-right str char-upper-case? beg end))
    => #f)

;;; --------------------------------------------------------------------

  (check
      (let* ((str "bacd") (beg 0) (end (string-length str)))
	(srfi.string-skip str #\b beg end))
    => 1)

  (check
      (let* ((str "bacd") (end (string-length str)))
	(srfi.string-skip str #\b 1 end))
    => 1)

  (check
      (let* ((str "1111") (beg 0) (end (string-length str)))
	(srfi.string-skip str #\1 beg end))
    => #f)

  (check
      (let* ((str "") (beg 0) (end (string-length str)))
	(srfi.string-skip str #\1 beg end))
    => #f)

;;; --------------------------------------------------------------------

  (check
      (let* ((str "bacd") (beg 0) (end (string-length str)))
  	(srfi.string-skip str (char-set #\b #\B) beg end))
    => 1)

  (check
      (let* ((str "bacd") (end (string-length str)))
  	(srfi.string-skip str (char-set #\b #\B) 1 end))
    => 1)

  (check
      (let* ((str "1010") (beg 0) (end (string-length str)))
  	(srfi.string-skip str (char-set #\0 #\1) beg end))
    => #f)

  (check
      (let* ((str "") (beg 0) (end (string-length str)))
  	(srfi.string-skip str (char-set #\0 #\1) beg end))
    => #f)

;;; --------------------------------------------------------------------

  (check
      (let* ((str "Bacd") (beg 0) (end (string-length str)))
	(srfi.string-skip str char-upper-case? beg end))
    => 1)

  (check
      (let* ((str "Bacd") (end (string-length str)))
	(srfi.string-skip str char-upper-case? 1 end))
    => 1)

  (check
      (let* ((str "ABCD") (beg 0) (end (string-length str)))
	(srfi.string-skip str char-upper-case? beg end))
    => #f)

  (check
      (let* ((str "") (beg 0) (end (string-length str)))
	(srfi.string-skip str char-upper-case? beg end))
    => #f)

;;; --------------------------------------------------------------------

  (check
      (let* ((str "acdb") (beg 0) (end (string-length str)))
	(srfi.string-skip-right str #\b beg end))
    => 2)

  (check
      (let* ((str "acdb") (end (string-length str)))
	(srfi.string-skip-right str #\b 1 end))
    => 2)

  (check
      (let* ((str "1111") (beg 0) (end (string-length str)))
	(srfi.string-skip-right str #\1 beg end))
    => #f)

  (check
      (let* ((str "") (beg 0) (end (string-length str)))
	(srfi.string-skip-right str #\1 beg end))
    => #f)

;;; --------------------------------------------------------------------

  (check
      (let* ((str "acdb") (beg 0) (end (string-length str)))
  	(srfi.string-skip-right str (char-set #\b #\B) beg end))
    => 2)

  (check
      (let* ((str "acdb") (end (string-length str)))
  	(srfi.string-skip-right str (char-set #\b #\B) 1 end))
    => 2)

  (check
      (let* ((str "0101") (beg 0) (end (string-length str)))
  	(srfi.string-skip-right str (char-set #\0 #\1) beg end))
    => #f)

  (check
      (let* ((str "") (beg 0) (end (string-length str)))
  	(srfi.string-skip-right str (char-set #\0 #\1) beg end))
    => #f)

;;; --------------------------------------------------------------------

  (check
      (let* ((str "acdB") (beg 0) (end (string-length str)))
	(srfi.string-skip-right str char-upper-case? beg end))
    => 2)

  (check
      (let* ((str "acdB") (end (string-length str)))
	(srfi.string-skip-right str char-upper-case? 1 end))
    => 2)

  (check
      (let* ((str "ABCD") (beg 0) (end (string-length str)))
	(srfi.string-skip-right str char-upper-case? beg end))
    => #f)

  (check
      (let* ((str "") (beg 0) (end (string-length str)))
	(srfi.string-skip-right str char-upper-case? beg end))
    => #f)

;;; --------------------------------------------------------------------

  (check
      (let* ((str "abcbd") (beg 0) (end (string-length str)))
	(srfi.string-count str #\b beg end))
    => 2)

  (check
      (let* ((str "abcd") (end (string-length str)))
	(srfi.string-count str #\b 1 end))
    => 1)

  (check
      (let* ((str "abcd") (beg 0) (end (string-length str)))
	(srfi.string-count str #\1 beg end))
    => 0)

  (check
      (let* ((str "") (beg 0) (end (string-length str)))
	(srfi.string-count str #\1 beg end))
    => 0)

;;; --------------------------------------------------------------------

  (check
      (let* ((str "abcBd") (beg 0) (end (string-length str)))
  	(srfi.string-count str (char-set #\b #\B) beg end))
    => 2)

  (check
      (let* ((str "abcd") (end (string-length str)))
  	(srfi.string-count str (char-set #\b #\B) 1 end))
    => 1)

  (check
      (let* ((str "abcd") (beg 0) (end (string-length str)))
  	(srfi.string-count str (char-set #\0 #\1) beg end))
    => 0)

  (check
      (let* ((str "") (beg 0) (end (string-length str)))
  	(srfi.string-count str (char-set #\0 #\1) beg end))
    => 0)

;;; --------------------------------------------------------------------

  (check
      (let* ((str "aBcAd") (beg 0) (end (string-length str)))
	(srfi.string-count str char-upper-case? beg end))
    => 2)

  (check
      (let* ((str "aBcd") (end (string-length str)))
	(srfi.string-count str char-upper-case? 1 end))
    => 1)

  (check
      (let* ((str "abcd") (beg 0) (end (string-length str)))
	(srfi.string-count str char-upper-case? beg end))
    => 0)

  (check
      (let* ((str "") (beg 0) (end (string-length str)))
	(srfi.string-count str char-upper-case? beg end))
    => 0)

;;; --------------------------------------------------------------------

  (check
      (let* ((str1 "ciao hello salut") (beg1 0) (end1 (string-length str1))
	     (str2 "hello") (beg2 0) (end2 (string-length str2)))
	(srfi.string-contains str1 str2 beg1 end1 beg2 end2))
    => 5)

  (check
      (let* ((str1 "ciao hello salut") (beg1 0) (end1 (string-length str1))
	     (str2 "hola") (beg2 0) (end2 (string-length str2)))
	(srfi.string-contains str1 str2 beg1 end1 beg2 end2))
    => #f)

  (check
      (let* ((str1 "ciao hello salut") (beg1 0) (end1 (string-length str1))
	     (str2 "") (beg2 0) (end2 (string-length str2)))
	(srfi.string-contains str1 str2 beg1 end1 beg2 end2))
    => 0)

  (check
      (let* ((str1 "") (beg1 0) (end1 (string-length str1))
	     (str2 "hello") (beg2 0) (end2 (string-length str2)))
	(srfi.string-contains str1 str2 beg1 end1 beg2 end2))
    => #f)

;;; --------------------------------------------------------------------

  (check
      (let* ((str1 "ciAO HELLO saLUT") (beg1 0) (end1 (string-length str1))
	     (str2 "hello") (beg2 0) (end2 (string-length str2)))
	(srfi.string-contains-ci str1 str2 beg1 end1 beg2 end2))
    => 5)

  (check
      (let* ((str1 "ciao hello salut") (beg1 0) (end1 (string-length str1))
	     (str2 "HOLA") (beg2 0) (end2 (string-length str2)))
	(srfi.string-contains-ci str1 str2 beg1 end1 beg2 end2))
    => #f)

  (check
      (let* ((str1 "ciao hello salut") (beg1 0) (end1 (string-length str1))
	     (str2 "") (beg2 0) (end2 (string-length str2)))
	(srfi.string-contains-ci str1 str2 beg1 end1 beg2 end2))
    => 0)

  (check
      (let* ((str1 "") (beg1 0) (end1 (string-length str1))
	     (str2 "hello") (beg2 0) (end2 (string-length str2)))
	(srfi.string-contains-ci str1 str2 beg1 end1 beg2 end2))
    => #f)

  #t)


(parametrise ((check-test-name 'case))

  (check (srfi.string-upcase "abcd")		=> "ABCD")
  (check (srfi.string-upcase "aBcD")		=> "ABCD")
  (check (srfi.string-upcase "1234")		=> "1234")

  (check (srfi.string-downcase "ABCD")		=> "abcd")
  (check (srfi.string-downcase "aBcD")		=> "abcd")
  (check (srfi.string-downcase "1234")		=> "1234")

  (check (srfi.string-upcase! (string-copy "abcd"))	=> "ABCD")
  (check (srfi.string-upcase! (string-copy "aBcD"))	=> "ABCD")
  (check (srfi.string-upcase! (string-copy "1234"))	=> "1234")

  (check (srfi.string-downcase! (string-copy "ABCD"))	=> "abcd")
  (check (srfi.string-downcase! (string-copy "aBcD"))	=> "abcd")
  (check (srfi.string-downcase! (string-copy "1234"))	=> "1234")

;;; --------------------------------------------------------------------

  (check
      (let* ((str (string-copy "abcd")) (beg 0) (end (string-length str)))
	(srfi.string-titlecase! str beg end)
	str)
    => "Abcd")

  (check
      (let* ((str (string-copy "123abcd")) (beg 0) (end (string-length str)))
	(srfi.string-titlecase! str beg end)
	str)
    => "123Abcd")

  (check
      (let* ((str (string-copy "---abcd")) (beg 0) (end (string-length str)))
	(srfi.string-titlecase! str beg end)
	str)
    => "---Abcd")

  (check
      (let* ((str (string-copy "abcd efgh")) (beg 0) (end (string-length str)))
	(srfi.string-titlecase! str beg end)
	str)
    => "Abcd Efgh")

  #f)


(parametrise ((check-test-name 'reverse))

  (check
      (let* ((str (string-copy "abcd")) (beg 0) (end (string-length str)))
	(srfi.string-reverse str beg end))
    => "dcba")

  (check
      (let* ((str (string-copy "")) (beg 0) (end (string-length str)))
	(srfi.string-reverse str beg end))
    => "")

;;; --------------------------------------------------------------------

  (check
      (let* ((str (string-copy "abcd")) (beg 0) (end (string-length str)))
	(srfi.string-reverse! str beg end)
	str)
    => "dcba")

  (check
      (let* ((str (string-copy "")) (beg 0) (end (string-length str)))
	(srfi.string-reverse! str beg end)
	str)
    => "")

  #f)

(parametrise ((check-test-name 'concatenate))

  (check
      (srfi.string-concatenate '("ciao" " " "hello" " " "salut"))
    => "ciao hello salut")

  (check
      (srfi.string-concatenate '())
    => "")

;;; --------------------------------------------------------------------

  (check
      (srfi.string-concatenate-reverse '("ciao" " " "hello" " " "salut") " hola" (string-length " hola"))
    => "salut hello ciao hola")

  (check
      (srfi.string-concatenate-reverse '("ciao" " " "hello" " " "salut") " hola" 3)
    => "salut hello ciao ho")

  (check
      (srfi.string-concatenate-reverse '() "" 0)
    => "")

  #f)


(parametrise ((check-test-name 'mapping))

  (check (srfi.string-map char-upcase "")		=> "")
  (check (srfi.string-map char-upcase "a")		=> "A")
  (check (srfi.string-map char-upcase "abcd")		=> "ABCD")

  (check (srfi.string-map char-upcase "abcd" 0)		=> "ABCD")
  (check (srfi.string-map char-upcase "abcd" 4)		=> "")
  (check (srfi.string-map char-upcase "abcd" 1)		=> "BCD")
  (check (srfi.string-map char-upcase "abcd" 2)		=> "CD")
  (check (srfi.string-map char-upcase "abcd" 3)		=> "D")

  (check (srfi.string-map char-upcase "abcd" 0 0)	=> "")
  (check (srfi.string-map char-upcase "abcd" 4 4)	=> "")

;;; --------------------------------------------------------------------

  (let-syntax
      ((doit (syntax-rules ()
	       ((_ ?input ?output)
		(check
		    (let ((str (string-copy ?input)))
		      (srfi.string-map! char-upcase str)
		      str)
		  => ?output))
	       ((_ ?input ?start ?end ?output)
		(check
		    (let ((str (string-copy ?input)))
		      (srfi.string-map! char-upcase str ?start ?end)
		      str)
		  => ?output))
	       )))

    (doit ""		"")
    (doit "ciao"	"CIAO")

    (doit "" 0 0	"")
    (doit "ciao" 0 4	"CIAO")
    (doit "ciao" 2 3	"ciAo")

    #f)

;;; --------------------------------------------------------------------

  (let-syntax
      ((doit (syntax-rules ()
	       ((_ ?input ?output)
		(check
		    (with-result
		     (srfi.string-for-each add-result ?input))
		  => '(?input ?output)))
	       ((_ ?input ?start ?end ?output)
		(check
		    (with-result
		     (srfi.string-for-each add-result ?input ?start ?end))
		  => '(?input ?output)))
	       )))

    (doit "abcd"		(#\a #\b #\c #\d))
    (doit "abcd" 0 4		(#\a #\b #\c #\d))
    (doit "abcd" 1 4		(#\b #\c #\d))
    (doit "abcd" 2 4		(#\c #\d))
    (doit "abcd" 3 4		(#\d))
    (doit "abcd" 4 4		())
    #f)

;;; --------------------------------------------------------------------

  (let-syntax
      ((doit (syntax-rules ()
	       ((_ ?input ?output)
		(check
		    (with-result
		     (srfi.string-for-each-index add-result ?input))
		  => '(?input ?output)))
	       ((_ ?input ?start ?end ?output)
		(check
		    (with-result
		     (srfi.string-for-each-index add-result ?input ?start ?end))
		  => '(?input ?output)))
	       )))

    (doit "abcd"		(0 1 2 3))
    (doit "abcd" 0 4		(0 1 2 3))
    (doit "abcd" 1 4		(1 2 3))
    (doit "abcd" 2 4		(2 3))
    (doit "abcd" 3 4		(3))
    (doit "abcd" 4 4		())
    #f)

  #t)


(parametrise ((check-test-name 'folding))

  (check
      (let* ((str "abcd")
	     (beg 0)
	     (end (string-length str)))
	(srfi.string-fold cons '() str beg end))
    => '(#\d #\c #\b #\a))

  (check
      (let* ((str "")
	     (beg 0)
	     (end (string-length str)))
	(srfi.string-fold cons '() str beg end))
    => '())

;;; --------------------------------------------------------------------

  (check
      (let* ((str "abcd")
	     (beg 0)
	     (end (string-length str)))
	(srfi.string-fold-right cons '() str beg end))
    => '(#\a #\b #\c #\d))

  (check
      (let* ((str "")
	     (beg 0)
	     (end (string-length str)))
	(srfi.string-fold-right cons '() str beg end))
    => '())

;;; --------------------------------------------------------------------

  (check
      (srfi.string-unfold null? car cdr '(#\a #\b #\c #\d))
    => "abcd")

  (check
      (srfi.string-unfold null? car cdr '())
    => "")

;;; --------------------------------------------------------------------

  (check
      (srfi.string-unfold-right null? car cdr '(#\a #\b #\c #\d))
    => "dcba")

  (check
      (srfi.string-unfold-right null? car cdr '())
    => "")

  #f)


(parametrise ((check-test-name 'replicating))

  (check
      (let* ((str "ciao ") (beg 0) (end (string-length str)))
	(srfi.xsubstring str 0 5 beg end))
    => "ciao ")

  (check
      (let* ((str "ciao ") (beg 0) (end (string-length str)))
	(srfi.xsubstring str 0 9 beg end))
    => "ciao ciao")

  (check
      (let* ((str "ciao ") (beg 0) (end (string-length str)))
	(srfi.xsubstring str -5 5 beg end))
    => "ciao ciao ")

  (check
      (let* ((str "ciao ") (beg 0) (end (string-length str)))
	(srfi.xsubstring str 2 4 beg end))
    => "ao")

  (check
      (let* ((str "ciao ") (beg 0) (end (string-length str)))
	(srfi.xsubstring str -3 7 beg end))
    => "ao ciao ci")

  (check
      (guard (exc ((assertion-violation? exc) #t))
	(let ((str "ciao "))
	  (srfi.xsubstring str -3 7 3 3)))
    => #t)

  (check
      (guard (exc ((assertion-violation? exc)
		   #t))
	(let* ((str "") (beg 0) (end (string-length str)))
	  (srfi.xsubstring str 0 5 beg end)))
    => #t)

;;; --------------------------------------------------------------------

  (check
      (let* ((src.str	"ciao ")
  	     (dst.str	(string-copy "01234"))
	     (dst.beg	0)
	     (from	0)
	     (to	5))
  	(srfi.string-xcopy! dst.str dst.beg src.str from to)
  	dst.str)
    => "ciao ")

  (check
      (let* ((src.str	"ciao ")
  	     (dst.str	(string-copy "012345678"))
	     (dst.start	0)
	     (from	0)
	     (to	9))
  	(srfi.string-xcopy! dst.str dst.start src.str from to)
  	dst.str)
    => "ciao ciao")

  (check
      (let* ((src.str	"ciao ")
  	     (dst.str	(string-copy "0123456789"))
	     (dst.start	0)
	     (from	-5)
	     (to	+5))
  	(srfi.string-xcopy! dst.str dst.start src.str from to)
  	dst.str)
    => "ciao ciao ")

  (check
      (let* ((src.str	"ciao ")
  	     (dst.str	(string-copy "01"))
	     (dst.start	0)
	     (from	2)
	     (to	4))
  	(srfi.string-xcopy! dst.str dst.start src.str from to)
  	dst.str)
    => "ao")

  (check
      (let* ((src.str	"ciao ")
  	     (dst.str	(string-copy "0123456789"))
	     (dst.start	0)
	     (from	-3)
	     (to	+7))
  	(srfi.string-xcopy! dst.str dst.start src.str from to)
  	dst.str)
    => "ao ciao ci")

  (check
      (guard (exc ((assertion-violation? exc)
  		   (condition-message exc)))
  	(let* ((str "")
	       (beg 0)
	       (end (string-length str))
	       (result (string-copy "")))
  	  (srfi.string-xcopy! result 0 str 0 5 beg end)))
    => "cannot replicate empty (sub)string")

  #f)


(parametrise ((check-test-name 'replace))

  (check
      (let* ((str1 "abcd") (beg1 0) (end1 (string-length str1))
	     (str2 "1234") (beg2 0) (end2 (string-length str2)))
	(srfi.string-replace str1 str2 beg1 end1 beg2 end2))
    => "1234")

  (check
      (let* ((str1 "abcd") (beg1 0) (end1 (string-length str1))
	     (str2 "1234") (beg2 0) (end2 (string-length str2)))
	(srfi.string-replace str1 str2 2 2 beg2 end2))
    => "ab1234cd")

  (check
      (let* ((str1 "abcd") (beg1 0) (end1 (string-length str1))
	     (str2 "") (beg2 0) (end2 (string-length str2)))
	(srfi.string-replace str1 str2 2 2 beg2 end2))
    => "abcd")

  (check
      (let* ((str1 "abcd") (beg1 0) (end1 (string-length str1))
	     (str2 "1234") (beg2 0) (end2 (string-length str2)))
	(srfi.string-replace str1 str2 1 3 beg2 end2))
    => "a1234d")

  (check
      (let* ((str1 "abcd") (beg1 0) (end1 (string-length str1))
	     (str2 "1234") (beg2 0) (end2 (string-length str2)))
	(srfi.string-replace str1 str2 0 3 beg2 end2))
    => "1234d")

  (check
      (let* ((str1 "abcd") (beg1 0) (end1 (string-length str1))
	     (str2 "1234") (beg2 0) (end2 (string-length str2)))
	(srfi.string-replace str1 str2 1 4 beg2 end2))
    => "a1234")

  #t)


(parametrise ((check-test-name 'tokenize))

  (check
      (let* ((str "ciao hello salut") (beg 0) (end (string-length str)))
	(srfi.string-tokenize str (char-set #\a #\c #\e #\i #\h #\l #\o #\s #\t #\u)
			      beg end))
    => '("ciao" "hello" "salut"))

  (check
      (let* ((str "") (beg 0) (end (string-length str)))
	(srfi.string-tokenize str (char-set #\a #\c #\e #\i #\h #\l #\o #\s #\t #\u)
			      beg end))
    => '())

  (check
      (let* ((str "ciao hello salut") (beg 0) (end (string-length str)))
	(srfi.string-tokenize str (char-set) beg end))
    => '())

  #f)


(parametrise ((check-test-name 'filtering))

  (check
      (let* ((str "abcbd") (beg 0) (end (string-length str)))
	(srfi.string-delete #\b str beg end))
    => "acd")

  (check
      (let* ((str "abcbd") (beg 0) (end (string-length str)))
	(srfi.string-delete #\0 str beg end))
    => "abcbd")

  (check
      (let* ((str "") (beg 0) (end (string-length str)))
	(srfi.string-delete #\b str beg end))
    => "")

;;; --------------------------------------------------------------------

  (check
      (let* ((str "abcbd") (beg 0) (end (string-length str)))
	(srfi.string-delete (char-set #\b #\B) str beg end))
    => "acd")

  (check
      (let* ((str "abcbd") (beg 0) (end (string-length str)))
	(srfi.string-delete (char-set #\0 #\1) str beg end))
    => "abcbd")

  (check
      (let* ((str "") (beg 0) (end (string-length str)))
	(srfi.string-delete (char-set #\b #\B) str beg end))
    => "")

;;; --------------------------------------------------------------------

  (check
      (let* ((str "aBcBd") (beg 0) (end (string-length str)))
	(srfi.string-delete char-upper-case? str beg end))
    => "acd")

  (check
      (let* ((str "abcbd") (beg 0) (end (string-length str)))
	(srfi.string-delete char-upper-case? str beg end))
    => "abcbd")

  (check
      (let* ((str "") (beg 0) (end (string-length str)))
	(srfi.string-delete char-upper-case? str beg end))
    => "")

;;; --------------------------------------------------------------------

  (check
      (let* ((str "abcbd") (beg 0) (end (string-length str)))
	(srfi.string-filter #\b str beg end))
    => "bb")

  (check
      (let* ((str "abcbd") (beg 0) (end (string-length str)))
	(srfi.string-filter #\0 str beg end))
    => "")

  (check
      (let* ((str "") (beg 0) (end (string-length str)))
	(srfi.string-filter #\b str beg end))
    => "")

;;; --------------------------------------------------------------------

  (check
      (let* ((str "abcbd") (beg 0) (end (string-length str)))
	(srfi.string-filter (char-set #\b #\B) str beg end))
    => "bb")

  (check
      (let* ((str "abcbd") (beg 0) (end (string-length str)))
	(srfi.string-filter (char-set #\0 #\1) str beg end))
    => "")

  (check
      (let* ((str "") (beg 0) (end (string-length str)))
	(srfi.string-filter (char-set #\b #\B) str beg end))
    => "")

;;; --------------------------------------------------------------------

  (check
      (let* ((str "aBcBd") (beg 0) (end (string-length str)))
	(srfi.string-filter char-upper-case? str beg end))
    => "BB")

  (check
      (let* ((str "abcbd") (beg 0) (end (string-length str)))
	(srfi.string-filter char-upper-case? str beg end))
    => "")

  (check
      (let* ((str "") (beg 0) (end (string-length str)))
	(srfi.string-filter char-upper-case? str beg end))
    => "")

  #t)


;;;; done

(check-report)

;;; end of file
