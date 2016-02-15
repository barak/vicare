;;; -*- coding: utf-8-unix -*-
;;;
;;;Part of: Vicare Scheme
;;;Contents: tests for URI objects
;;;Date: Fri Nov  8, 2013
;;;
;;;Abstract
;;;
;;;
;;;
;;;Copyright (C) 2013, 2014 Marco Maggi <marco.maggi-ipsu@poste.it>
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


#!vicare
(import (nausicaa (0 4))
  (prefix (nausicaa uri) uri.)
  (prefix (nausicaa parser-tools uri) uri.)
  (nausicaa parser-tools uri utilities)
  (vicare checks))

(check-set-mode! 'report-failed)
(check-display "*** testing Nausicaa libraries: URI objects\n")


;;;; helpers

(define (mkport obj)
  (cond ((string? obj)
	 (open-bytevector-input-port (string->ascii obj)))
	((bytevector? obj)
	 (open-bytevector-input-port obj))
	(else
	 (assertion-violation __who__ "expecting string or bytevector" obj))))

(define (string->host-object {str <string>})
  (let ((port (open-bytevector-input-port (string->ascii str))))
    (receive (host.type host.ascii host.data)
	(uri.parse-host port)
      (uri.make-host-object host.type host.ascii host.data))))

(define (percent-encoded->host-object {bv <percent-encoded-bytevector>})
  (let ((port (open-bytevector-input-port bv)))
    (receive (host.type host.ascii host.data)
	(uri.parse-host port)
      (uri.make-host-object host.type host.ascii host.data))))


(parametrise ((check-test-name	'scheme))

  (check	;constructor
      (let ()
	(uri.<scheme> O (<> ('#ve(ascii "http"))))
        (O bytevector))
    => '#ve(ascii "http:"))

  (check
      (let (({O uri.<scheme>} '#ve(ascii "http")))
        (O bytevector))
    => '#ve(ascii "http:"))

  (check
      (let (({O uri.<scheme>} '#ve(ascii "http")))
        (O string))
    => "http:")

  (check
      (let (({O uri.<scheme>} '#ve(ascii "http")))
	(receive (port getter)
	    (open-bytevector-output-port)
	  (O put-bytevector port)
	  (getter)))
    => '#ve(ascii "http:"))

  (check-for-true
   (let (({O uri.<scheme>} '#ve(ascii "http")))
     (fixnum? (O hash))))

;;; --------------------------------------------------------------------

  (check	;empty "scheme" is invalid
      (try
	  (let (({O uri.<scheme>} '#vu8()))
	    #f)
	(catch E
	  ((&tagged-binding-violation)
	   #t)
	  (else E)))
    => #t)

  #t)


(parametrise ((check-test-name	'userinfo))

  (check	;constructor
      (let ()
	(uri.<userinfo> O (<> ('#ve(ascii "marco"))))
        (O bytevector))
    => '#ve(ascii "marco@"))

  (check
      (let (({O uri.<userinfo>} '#vu8()))
        (O bytevector))
    => '#ve(ascii "@"))

  (check
      (let (({O uri.<userinfo>} '#vu8()))
        (O string))
    => "@")

  (check
      (let (({O uri.<userinfo>} '#ve(ascii "marco")))
        (O bytevector))
    => '#ve(ascii "marco@"))

  (check
      (let (({O uri.<userinfo>} '#ve(ascii "marco")))
        (O string))
    => "marco@")

  (check
      (let (({O uri.<userinfo>} '#ve(ascii "ci%3Fa%3Do")))
        (O bytevector))
    => '#ve(ascii "ci%3Fa%3Do@"))

  (check
      (let (({O uri.<userinfo>} '#ve(ascii "ci%3Fa%3Do")))
        (O percent-decoded))
    => '#ve(ascii "ci?a=o"))

  (check
      (let (({O uri.<userinfo>} '#ve(ascii "marco")))
	(receive (port getter)
	    (open-bytevector-output-port)
	  (O put-bytevector port)
	  (getter)))
    => '#ve(ascii "marco@"))

  (check-for-true
   (let (({O uri.<userinfo>} '#ve(ascii "marco")))
     (fixnum? (O hash))))

;;; --------------------------------------------------------------------

  (check
      (try
	  (let (({O uri.<userinfo>} '#vu8(0)))
	    #f)
	(catch E
	  ((&tagged-binding-violation)
	   #t)
	  (else E)))
    => #t)

  #t)


(parametrise ((check-test-name	'host/registered-name))

  (check	;empty host is fine
      (let (({O uri.<host>} (string->host-object "")))
	(O string))
    => "")

  (check	;member of <ip-address>
      (let (({O uri.<host>} (string->host-object "github.io")))
	(O string))
    => "github.io")

  (check	;member of <ip-address>
      (let (({O uri.<host>} (string->host-object "ci%3Fa%3Do")))
	(O string))
    => "ci%3Fa%3Do")

  (check	;member of <ip-address>
      (let (({O uri.<host>} (string->host-object "ci%3Fa%3Do")))
	(O bytevector))
    => '#ve(ascii "ci%3Fa%3Do"))

  (check	;member of <bytevector> through <ip-address>
      (let (({O uri.<host>} (string->host-object "ci%3Fa%3Do")))
        (percent-decode (O bytevector)))
    => '#ve(ascii "ci?a=o"))

  (check	;member of <host>
      (let (({O uri.<host>} (string->host-object "ci%3Fa%3Do")))
        (O bytevector))
    => '#ve(ascii "ci%3Fa%3Do"))

  (check	;member of <host>
      (let (({O uri.<host>} (string->host-object "ci%3Fa%3Do")))
	(receive (port getter)
	    (open-bytevector-output-port)
	  (O put-bytevector port)
	  (getter)))
    => '#ve(ascii "ci%3Fa%3Do"))

  #t)


(parametrise ((check-test-name	'host/ipv4-address))

  (check	;member of <ip-address>
      (let (({O uri.<host>} (string->host-object "1.2.3.4")))
	(O string))
    => "1.2.3.4")

  (check	;member of <ip-address>
      (let (({O uri.<host>} (string->host-object "1.2.3.4")))
	(O bytevector))
    => '#ve(ascii "1.2.3.4"))

  (check	;member of <bytevector> through <ip-address>
      (let (({O uri.<host>} (string->host-object "1.2.3.4")))
	(percent-decode (O bytevector)))
    => '#ve(ascii "1.2.3.4"))

  (check	;member of <host>
      (let (({O uri.<host>} (string->host-object "1.2.3.4")))
        (O bytevector))
    => '#ve(ascii "1.2.3.4"))

  (check	;member of <host>
      (let (({O uri.<host>} (string->host-object "1.2.3.4")))
	(receive (port getter)
	    (open-bytevector-output-port)
	  (O put-bytevector port)
	  (getter)))
    => '#ve(ascii "1.2.3.4"))

  #t)


(parametrise ((check-test-name	'host/ipv6-address))

  (check	;member of <ip-address>
      (let (({O uri.<host>} (string->host-object "[1:2:3:4:5:6:7:8]")))
	(O string))
    => "[1:2:3:4:5:6:7:8]")

  (check	;member of <ip-address>
      (let (({O uri.<host>} (string->host-object "[1:2:3:4:5:6:7:8]")))
	(O bytevector))
    => '#ve(ascii "[1:2:3:4:5:6:7:8]"))

  (check	;member of <host>
      (let (({O uri.<host>} (string->host-object "[1:2:3:4:5:6:7:8]")))
	(receive (port getter)
	    (open-bytevector-output-port)
	  (O put-bytevector port)
	  (getter)))
    => '#ve(ascii "[1:2:3:4:5:6:7:8]"))

  #t)


(parametrise ((check-test-name	'host/ipvfuture))

  (check	;member of <ip-address>
      (let (({O uri.<host>} (string->host-object "[v9.ciao]")))
	(O string))
    => "[v9.ciao]")

  (check	;member of <ip-address>
      (let (({O uri.<host>} (string->host-object "[v9.ciao]")))
	(O bytevector))
    => '#ve(ascii "[v9.ciao]"))

  (check	;member of <host>
      (let (({O uri.<host>} (string->host-object "[v9.ciao]")))
	(receive (port getter)
	    (open-bytevector-output-port)
	  (O put-bytevector port)
	  (getter)))
    => '#ve(ascii "[v9.ciao]"))

  #t)


(parametrise ((check-test-name	'port-number))

  (check	;constructor
      (let ()
	(uri.<port-number> O (<> (8080)))
        (O bytevector))
    => '#ve(ascii ":8080"))

  (check
      (let (({O uri.<port-number>} 0))
        (O bytevector))
    => '#ve(ascii ":0"))

  (check
      (let (({O uri.<port-number>} 0))
        (O string))
    => ":0")

  (check
      (let (({O uri.<port-number>} 8080))
        (O bytevector))
    => '#ve(ascii ":8080"))

  (check
      (let (({O uri.<port-number>} 8080))
        (O string))
    => ":8080")

  (check
      (let (({O uri.<port-number>} 8080))
	(receive (port getter)
	    (open-bytevector-output-port)
	  (O put-bytevector port)
	  (getter)))
    => '#ve(ascii ":8080"))

;;; --------------------------------------------------------------------

  (check
      (try
	  (let (({O uri.<port-number>} "ciao"))
	    #f)
	(catch E
	  ((&tagged-binding-violation)
	   #t)
	  (else E)))
    => #t)

  #t)


(parametrise ((check-test-name	'segment))

  (check	;constructor
      (let ()
	(uri.<segment> O (<> ('#ve(ascii "image"))))
        O)
    => '#ve(ascii "image"))

  (check
      (let (({O uri.<segment>} '#ve(ascii "image")))
        (O bytevector))
    => '#ve(ascii "image"))

  (check
      (let (({O uri.<segment>} '#ve(ascii "image")))
        (O string))
    => "image")

  (check
      (let (({O uri.<segment>} '#ve(ascii "image")))
	(receive (port getter)
	    (open-bytevector-output-port)
	  (O put-bytevector port)
	  (getter)))
    => '#ve(ascii "image"))

;;; --------------------------------------------------------------------

  (check	;empty segments are invalid
      (try
	  (let (({O uri.<segment>} '#vu8()))
	    #f)
	(catch E
	  ((&tagged-binding-violation)
	   #t)
	  (else E)))
    => #t)

  (check	;invalid pct-encoded sequence
      (try
	  (let (({O uri.<segment>} "ciao%Z"))
	    #f)
	(catch E
	  ((&tagged-binding-violation)
	   #t)
	  (else E)))
    => #t)

  #t)


(parametrise ((check-test-name	'list-of-segments))

  (define-constant ELL
    '( ;;
      #ve(ascii "home")
      #ve(ascii "marco")
      #ve(ascii "src")
      #ve(ascii "devel")))

;;; --------------------------------------------------------------------

  (check	;constructor
      (let ()
	(uri.<list-of-segments> O (<> (ELL)))
        O)
    => ELL)

  (check
      (let (({O uri.<list-of-segments>} ELL))
        (O bytevector))
    => '#ve(ascii "home/marco/src/devel"))

  (check
      (let (({O uri.<list-of-segments>} ELL))
        (O string))
    => "home/marco/src/devel")

  (check
      (let (({O uri.<list-of-segments>} ELL))
	(receive (port getter)
	    (open-bytevector-output-port)
	  (O put-bytevector port)
	  (getter)))
    => '#ve(ascii "home/marco/src/devel"))

;;; --------------------------------------------------------------------
;;; empty list

  (check	;constructor
      (let ()
	(uri.<list-of-segments> O (<> ('())))
        O)
    => '())

  (check
      (let (({O uri.<list-of-segments>} '()))
        (O bytevector))
    => '#vu8())

  (check
      (let (({O uri.<list-of-segments>} '()))
        (O string))
    => "")

  (check
      (let (({O uri.<list-of-segments>} '()))
	(receive (port getter)
	    (open-bytevector-output-port)
	  (O put-bytevector port)
	  (getter)))
    => '#vu8())

;;; --------------------------------------------------------------------

  (check	;invalid pct-encoded sequence
      (try
	  (let (({O uri.<list-of-segments>} '(#ve(ascii "ciao%Z"))))
	    #f)
	(catch E
	  ((&tagged-binding-violation)
	   #t)
	  (else E)))
    => #t)

  #t)


(parametrise ((check-test-name	'path-empty))

  (check	;constructor
      (let ()
	(uri.<path> O (uri.<path-empty> ()))
        ((uri.<path-empty> #:predicate) O))
    => #t)

  (check
      (let (({O uri.<path>} (uri.<path-empty> ())))
        (O bytevector))
    => '#vu8())

  (check
      (let (({O uri.<path>} (uri.<path-empty> ())))
        (O string))
    => "")

  (check
      (let (({O uri.<path>} (uri.<path-empty> ())))
	(receive (port getter)
	    (open-bytevector-output-port)
	  (O put-bytevector port)
	  (getter)))
    => '#vu8())

  (check
      (let (({O uri.<path>} (uri.<path-empty> ())))
        (O type))
    => 'path-empty)

  #t)


(parametrise ((check-test-name	'path-abempty))

  (define-constant ELL
    '( ;;
      #ve(ascii "home")
      #ve(ascii "marco")
      #ve(ascii "src")
      #ve(ascii "devel")))

;;; --------------------------------------------------------------------

  (check	;constructor
      (let ()
	(uri.<path> O (uri.<path-abempty> (ELL)))
        ((uri.<path-abempty> #:predicate) O))
    => #t)

  (check
      (let (({O uri.<path>} (uri.<path-abempty> (ELL))))
        (O bytevector))
    => '#ve(ascii "/home/marco/src/devel"))

  (check
      (let (({O uri.<path>} (uri.<path-abempty> (ELL))))
        (O string))
    => "/home/marco/src/devel")

  (check
      (let (({O uri.<path>} (uri.<path-abempty> (ELL))))
	(receive (port getter)
	    (open-bytevector-output-port)
	  (O put-bytevector port)
	  (getter)))
    => '#ve(ascii "/home/marco/src/devel"))

  (check
      (let (({O uri.<path>} (uri.<path-abempty> (ELL))))
        (O type))
    => 'path-abempty)

;;; --------------------------------------------------------------------
;;; empty list

  (check	;constructor
      (let ()
	(uri.<path> O (uri.<path-abempty> ('())))
        ((uri.<path-abempty> #:predicate) O))
    => #t)

  (check
      (let (({O uri.<path>} (uri.<path-abempty> ('()))))
        (O bytevector))
    => '#ve(ascii "/"))

  (check
      (let (({O uri.<path>} (uri.<path-abempty> ('()))))
        (O string))
    => "/")

  (check
      (let (({O uri.<path>} (uri.<path-abempty> ('()))))
	(receive (port getter)
	    (open-bytevector-output-port)
	  (O put-bytevector port)
	  (getter)))
    => '#ve(ascii "/"))

;;; --------------------------------------------------------------------

  (check	;invalid pct-encoded sequence
      (try
	  (uri.<path-abempty> ('(#ve(ascii "ciao%Z"))))
	(catch E
	  ((&procedure-argument-violation)
	   #t)
	  (else E)))
    => #t)

  #t)


(parametrise ((check-test-name	'path-absolute))

  (define-constant ELL
    '( ;;
      #ve(ascii "home")
      #ve(ascii "marco")
      #ve(ascii "src")
      #ve(ascii "devel")))

;;; --------------------------------------------------------------------

  (check	;constructor
      (let ()
	(uri.<path> O (uri.<path-absolute> (ELL)))
        ((uri.<path-absolute> #:predicate) O))
    => #t)

  (check
      (let (({O uri.<path>} (uri.<path-absolute> (ELL))))
        (O bytevector))
    => '#ve(ascii "/home/marco/src/devel"))

  (check
      (let (({O uri.<path>} (uri.<path-absolute> (ELL))))
        (O string))
    => "/home/marco/src/devel")

  (check
      (let (({O uri.<path>} (uri.<path-absolute> (ELL))))
	(receive (port getter)
	    (open-bytevector-output-port)
	  (O put-bytevector port)
	  (getter)))
    => '#ve(ascii "/home/marco/src/devel"))

  (check
      (let (({O uri.<path>} (uri.<path-absolute> (ELL))))
        (O type))
    => 'path-absolute)

;;; --------------------------------------------------------------------
;;; empty list

  (check	;constructor
      (let ()
	(uri.<path> O (uri.<path-absolute> ('())))
        ((uri.<path-absolute> #:predicate) O))
    => #t)

  (check
      (let (({O uri.<path>} (uri.<path-absolute> ('()))))
        (O bytevector))
    => '#ve(ascii "/"))

  (check
      (let (({O uri.<path>} (uri.<path-absolute> ('()))))
        (O string))
    => "/")

  (check
      (let (({O uri.<path>} (uri.<path-absolute> ('()))))
	(receive (port getter)
	    (open-bytevector-output-port)
	  (O put-bytevector port)
	  (getter)))
    => '#ve(ascii "/"))

;;; --------------------------------------------------------------------

  (check	;invalid pct-encoded sequence
      (try
	  (uri.<path-absolute> ('(#ve(ascii "ciao%Z"))))
	(catch E
	  ((&procedure-argument-violation)
	   #t)
	  (else E)))
    => #t)

  #t)


(parametrise ((check-test-name	'path-rootless))

  (define-constant ELL
    '( ;;
      #ve(ascii "home")
      #ve(ascii "marco")
      #ve(ascii "src")
      #ve(ascii "devel")))

;;; --------------------------------------------------------------------

  (check	;constructor
      (let ()
	(uri.<path> O (uri.<path-rootless> (ELL)))
        ((uri.<path-rootless> #:predicate) O))
    => #t)

  (check
      (let (({O uri.<path>} (uri.<path-rootless> (ELL))))
        (O bytevector))
    => '#ve(ascii "home/marco/src/devel"))

  (check
      (let (({O uri.<path>} (uri.<path-rootless> (ELL))))
        (O string))
    => "home/marco/src/devel")

  (check
      (let (({O uri.<path>} (uri.<path-rootless> (ELL))))
	(receive (port getter)
	    (open-bytevector-output-port)
	  (O put-bytevector port)
	  (getter)))
    => '#ve(ascii "home/marco/src/devel"))

  (check
      (let (({O uri.<path>} (uri.<path-rootless> (ELL))))
        (O type))
    => 'path-rootless)

;;; --------------------------------------------------------------------

  (check	;empty list is invalid
      (try
	  (uri.<path-rootless> ('()))
	(catch E
	  ((&procedure-argument-violation)
	   #t)
	  (else E)))
    => #t)

  (check	;invalid pct-encoded sequence
      (try
	  (uri.<path-rootless> ('(#ve(ascii "ciao%Z"))))
	(catch E
	  ((&procedure-argument-violation)
	   #t)
	  (else E)))
    => #t)

  #t)


(parametrise ((check-test-name	'path-noscheme))

  (define-constant ELL
    '( ;;
      #ve(ascii "home")
      #ve(ascii "marco")
      #ve(ascii "src")
      #ve(ascii "devel")))

;;; --------------------------------------------------------------------

  (check	;constructor
      (let ()
	(uri.<path> O (uri.<path-noscheme> (ELL)))
        ((uri.<path-noscheme> #:predicate) O))
    => #t)

  (check
      (let (({O uri.<path>} (uri.<path-noscheme> (ELL))))
        (O bytevector))
    => '#ve(ascii "home/marco/src/devel"))

  (check
      (let (({O uri.<path>} (uri.<path-noscheme> (ELL))))
        (O string))
    => "home/marco/src/devel")

  (check
      (let (({O uri.<path>} (uri.<path-noscheme> (ELL))))
	(receive (port getter)
	    (open-bytevector-output-port)
	  (O put-bytevector port)
	  (getter)))
    => '#ve(ascii "home/marco/src/devel"))

  (check
      (let (({O uri.<path>} (uri.<path-noscheme> (ELL))))
        (O type))
    => 'path-noscheme)

;;; --------------------------------------------------------------------

  (check	;empty list is invalid
      (try
	  (uri.<path-noscheme> ('()))
	(catch E
	  ((&procedure-argument-violation)
	   #t)
	  (else E)))
    => #t)

  (check	;invalid pct-encoded sequence
      (try
	  (uri.<path-noscheme> ('(#ve(ascii "ciao%Z"))))
	(catch E
	  ((&procedure-argument-violation)
	   #t)
	  (else E)))
    => #t)

  #t)


(parametrise ((check-test-name	'make-path))

  (define-constant ELL
    '( ;;
      #ve(ascii "home")
      #ve(ascii "marco")
      #ve(ascii "src")
      #ve(ascii "devel")))

;;; --------------------------------------------------------------------

  (check
      (let (({O uri.<path>} (uri.make-path-object 'path-empty '())))
        (O bytevector))
    => '#vu8())

;;; --------------------------------------------------------------------

  (check
      (let (({O uri.<path>} (uri.make-path-object 'path-abempty ELL)))
        (O bytevector))
    => '#ve(ascii "/home/marco/src/devel"))

  (check
      (let (({O uri.<path>} (uri.make-path-object 'path-abempty '())))
        (O bytevector))
    => '#ve(ascii "/"))

;;; --------------------------------------------------------------------

  (check
      (let (({O uri.<path>} (uri.make-path-object 'path-absolute ELL)))
        (O bytevector))
    => '#ve(ascii "/home/marco/src/devel"))

;;; --------------------------------------------------------------------

  (check
      (let (({O uri.<path>} (uri.make-path-object 'path-rootless ELL)))
        (O bytevector))
    => '#ve(ascii "home/marco/src/devel"))

;;; --------------------------------------------------------------------

  (check
      (let (({O uri.<path>} (uri.make-path-object 'path-noscheme ELL)))
        (O bytevector))
    => '#ve(ascii "home/marco/src/devel"))

  #t)


(parametrise ((check-test-name	'query))

  (check	;constructor
      (let ()
	(uri.<query> O (<> ('#ve(ascii "image"))))
        (O bytevector))
    => '#ve(ascii "?image"))

  (check
      (let (({O uri.<query>} '#vu8()))
        (O bytevector))
    => '#ve(ascii "?"))

  (check
      (let (({O uri.<query>} '#vu8()))
        (O string))
    => "?")

  (check
      (let (({O uri.<query>} '#ve(ascii "image")))
        (O bytevector))
    => '#ve(ascii "?image"))

  (check
      (let (({O uri.<query>} '#ve(ascii "image")))
        (O string))
    => "?image")

  (check
      (let (({O uri.<query>} '#ve(ascii "image")))
	(receive (port getter)
	    (open-bytevector-output-port)
	  (O put-bytevector port)
	  (getter)))
    => '#ve(ascii "?image"))

;;; --------------------------------------------------------------------

  (check
      (try
	  (let (({O uri.<query>} "ciao%Z"))
	    #f)
	(catch E
	  ((&tagged-binding-violation)
	   #t)
	  (else E)))
    => #t)

  #t)


(parametrise ((check-test-name	'fragment))

  (check	;constructor
      (let ()
	(uri.<fragment> O (<> ('#ve(ascii "image"))))
        (O bytevector))
    => '#ve(ascii "#image"))

  (check
      (let (({O uri.<fragment>} '#vu8()))
        (O bytevector))
    => '#ve(ascii "#"))

  (check
      (let (({O uri.<fragment>} '#vu8()))
        (O string))
    => "#")

  (check
      (let (({O uri.<fragment>} '#ve(ascii "image")))
        (O bytevector))
    => '#ve(ascii "#image"))

  (check
      (let (({O uri.<fragment>} '#ve(ascii "image")))
        (O string))
    => "#image")

  (check
      (let (({O uri.<fragment>} '#ve(ascii "image")))
	(receive (port getter)
	    (open-bytevector-output-port)
	  (O put-bytevector port)
	  (getter)))
    => '#ve(ascii "#image"))

;;; --------------------------------------------------------------------

  (check
      (try
	  (let (({O uri.<fragment>} "ciao%Z"))
	    #f)
	(catch E
	  ((&tagged-binding-violation)
	   #t)
	  (else E)))
    => #t)

  #t)


(parametrise ((check-test-name	'uri))

  (define-syntax doit
    (syntax-rules ()
      ((_ ?string)
       (doit ?string ?string))
      ((_ ?input-string ?expected-string)
       (check
	   (let (({o uri.<uri>} (string->uri ?input-string)))
	     (values (o string) (o bytevector)))
	 => ?expected-string (string->ascii ?expected-string)))
      ))

;;; --------------------------------------------------------------------

  ;; (let (({O uri.<uri>} (string->uri "http:///?")))
  ;;   (debug-print (O path) (O has-query?) (ascii->string (O query))
  ;; 		 (O string)))

  (doit "http://www.spiffy.org/the/path/name?question%3Danswer#anchor-point")

  (doit "ci:ao/")

  (doit "ci:ao/a///" "ci:ao/a/")
  (doit "ci:ao/ciao")
  (doit "ci:ao/ciao/hello/salut")
  (doit "http://"			"http:///")
  (doit "http://?query"			"http:///?query")
  (doit "http://#fragment"		"http:///#fragment")
  (doit "http:///")
  (doit "http:///?query" )
  (doit "http:///ciao" )
  (doit "http://ciao.com:8080"		 "http://ciao.com:8080/")
  (doit "http://ciao.com:8080/")
  (doit "http://ciao.com/a/b/c")

;;; with authority, the path is "path-abempty"

  (doit "http://"			"http:///")
  (doit "http://?query"			"http:///?query")
  (doit "http://#fragment"		"http:///#fragment")
  (doit "http:///?query")
  (doit "http:///#fragment")
  (doit "http:///?")
  (doit "http:///#")
  (doit "http:///ciao")
  (doit "http://ciao.com:8080"		 "http://ciao.com:8080/")
  (doit "http://ciao.com:8080/")
  (doit "http://ciao.com/a/b/c")

;;; no authority, empty path

  (doit "http:"			"http:")
  (doit "http:?query"		"http:?query")
  (doit "http:#fragment"	"http:#fragment")

;;; no authority, absolute path

  (doit "http:/")
  (doit "http:/ciao")
  (doit "http:/ciao/hello/salut")

;;; no authority, relative path rootless

  (doit "http:./"			"http:")
  (doit "http:./a///"			"http:a/")
  (doit "http:./ciao"			"http:ciao")
  (doit "http:./ciao/hello/salut"	"http:ciao/hello/salut")

  (doit "http:../"			"http:")
  (doit "http:../a///"			"http:a/")
  (doit "http:../ciao"			"http:ciao")
  (doit "http:../ciao/hello/salut"	"http:ciao/hello/salut")

  (doit "http:a/..//"			"http:")
  (doit "http:a/.././."			"http:")
  (doit "http:ciao/.."			"http:")
  (doit "http:ciao/../hello/salut"	"http:hello/salut")

;;; IPv4address

  (doit "http://1.2.3.4/a/b/c")
  (doit "http://10.20.30.40/a/b/c")

;;; IPv6address

  (doit "http://[1:2:3:4:5:6:7:8]/a/b/c")
  (doit "http://[a:b:c:d:e:f:a:b]/a/b/c"	"http://[A:B:C:D:E:F:A:B]/a/b/c")
  (doit "http://[1:2:3:4::172.30.67.254]/a/b/c"	"http://[1:2:3:4:0:0:AC1E:43FE]/a/b/c")

;;; ipvfuture

  (doit "http://[v4.12345]/a/b/c")
  (doit "http://[vF.12345]/a/b/c")

;;; --------------------------------------------------------------------

  (check
      (let (({o uri.<uri>} (string->uri "http://1.2.3.4/a/b/c")))
	(ascii->string (o hier-part)))
    => "//1.2.3.4")

  (check
      (let (({o uri.<uri>} (string->uri "http:///a/b/c")))
	(ascii->string (o hier-part)))
    => "//")

;;; --------------------------------------------------------------------

  (check
      (let (({o uri.<uri>} (string->uri "http://1.2.3.4/a/b/c")))
	(ascii->string (o authority)))
    => "1.2.3.4")

  (check
      (let (({o uri.<uri>} (string->uri "http:///a/b/c")))
	(ascii->string (o authority)))
    => "")

  #t)


(parametrise ((check-test-name	'class-relative-ref))

  (define-syntax doit
    (syntax-rules ()
      ((_ ?string)
       (doit ?string ?string))
      ((_ ?input-string ?expected-string)
       (check
	   (let (({o uri.<relative-ref>} (string->relative-ref ?input-string)))
	     (values (o string) (o bytevector)))
	 => ?expected-string (string->ascii ?expected-string)))
      ))

;;; --------------------------------------------------------------------

;;; with authority

  (doit "//"			"///")
  (doit "//?query"		"///?query")
  (doit "//#fragment"		"///#fragment")
  (doit "///"			"///")
  (doit "///?query")
  (doit "///#fragment")
  (doit "///ciao")
  (doit "//ciao.com"		"//ciao.com/")
  (doit "//ciao.com:8080"	"//ciao.com:8080/")
  (doit "//marco@ciao.com:8080"	"//marco@ciao.com:8080/")
  (doit "//ciao.com:8080/")
  (doit "//ciao.com:8080/a")
  (doit "//ciao.com/a/b/c")
  (doit "//ciao.com:8080/a/b/c")

;;; no authority, emtpy path

  (doit ""			"")
  (doit "?query"		"?query")
  (doit "#fragment"		"#fragment")

;;; no authority, absolute path

  (doit "/")
  (doit "/a///"			"/a/")
  (doit "/ciao")
  (doit "/ciao/hello/salut")

;;; no authority, relative path rootless

  (doit "./"				"")
  (doit "./a///"			"a/")
  (doit "./ciao"			"ciao")
  (doit "./ciao/hello/salut"		"ciao/hello/salut")

;;; IPv4address

  (doit "//1.2.3.4/a/b/c")
  (doit "//10.20.30.40/a/b/c")

;;; IPv6address

  (doit "//[1:2:3:4:5:6:7:8]/a/b/c")
  (doit "//[a:b:c:d:e:f:a:b]/a/b/c"		 "//[A:B:C:D:E:F:A:B]/a/b/c")
  (doit "//[1:2:3:4::172.30.67.254]/a/b/c"	"//[1:2:3:4:0:0:AC1E:43FE]/a/b/c")

;;; ipvfuture

  (doit "//[v4.12345]/a/b/c")
  (doit "//[vF.12345]/a/b/c")

;;; --------------------------------------------------------------------

  (check
      (let (({o uri.<relative-ref>} (string->relative-ref "//1.2.3.4/a/b/c")))
	(ascii->string (o relative-part)))
    => "//1.2.3.4")

  (check
      (let (({o uri.<relative-ref>} (string->relative-ref "///a/b/c")))
	(ascii->string (o relative-part)))
    => "//")

;;; --------------------------------------------------------------------

  (check
      (let (({o uri.<relative-ref>} (string->relative-ref "//1.2.3.4/a/b/c")))
	(ascii->string (o authority)))
    => "1.2.3.4")

  (check
      (let (({o uri.<relative-ref>} (string->relative-ref "///a/b/c")))
	(ascii->string (o authority)))
    => "")

  #t)


;;;; done

(check-report)

;;; end of file
