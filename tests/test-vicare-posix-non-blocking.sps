;;; -*- coding: utf-8-unix -*-
;;;
;;;Part of: Vicare Scheme
;;;Contents: tests for file descriptors in non-blocking mode
;;;Date: Sun May 12, 2013
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


#!vicare
(import (vicare)
  (prefix (vicare posix) px.)
  (vicare checks))

(check-set-mode! 'report-failed)
(check-display "*** testing Vicare: POSIX file descriptor in non-blocking mode\n")


;;;; helpers

(define (make-pipe)
  (receive (in ou)
      (px.pipe)
    (push-compensation (px.close in))
    (push-compensation (px.close ou))
    (px.fd-set-non-blocking-mode! in)
    (px.fd-set-non-blocking-mode! ou)
    (values in ou)))

(define (make-binary-ports)
  (receive (in ou)
      (make-pipe)
    (let ((inp (make-binary-file-descriptor-input-port*  in "in"))
	  (oup (make-binary-file-descriptor-output-port* ou "ou")))
      (values inp oup))))

(define (make-textual-ports)
  (receive (in ou)
      (make-pipe)
    (let ((inp (make-textual-file-descriptor-input-port*  in "in" (native-transcoder)))
	  (oup (make-textual-file-descriptor-output-port* ou "ou" (native-transcoder))))
      (values inp oup))))

(define-constant CJK-COMPATIBILITY-IDEOGRAPH-2F9D1-UTF-8
  '#vu8(#xF0 #xAF #xA7 #x91))


(parametrise ((check-test-name	'fd-setting-mode))

  (define (make-pipe)
    (receive (in ou)
	(px.pipe)
      (push-compensation (px.close in))
      (push-compensation (px.close ou))
      (values in ou)))

  (check	;testing
      (with-compensations
	(receive (in ou)
	    (make-pipe)
	  (px.fd-in-non-blocking-mode? in)))
    => #f)

  (check	;setting, testing
      (with-compensations
	(receive (in ou)
	    (make-pipe)
	  (px.fd-set-non-blocking-mode! in)
	  (px.fd-in-non-blocking-mode? in)))
    => #t)

  (check	;setting, unsetting, testing
      (with-compensations
	(receive (in ou)
	    (make-pipe)
	  (px.fd-set-non-blocking-mode! in)
	  (px.fd-unset-non-blocking-mode! in)
	  (px.fd-in-non-blocking-mode? in)))
    => #f)

  (check	;unsetting, testing
      (with-compensations
	(receive (in ou)
	    (make-pipe)
	  (px.fd-unset-non-blocking-mode! in)
	  (px.fd-in-non-blocking-mode? in)))
    => #f)

;;; --------------------------------------------------------------------

  (check	;with cloexec setting, testing
      (with-compensations
	(receive (in ou)
	    (make-pipe)
	  (px.fd-set-non-blocking-mode! in)
	  (px.fd-set-close-on-exec-mode! in)
	  (list (px.fd-in-non-blocking-mode? in)
		(px.fd-in-close-on-exec-mode? in))))
    => '(#t #t))

  (check	;with cloexec setting, testing
      (with-compensations
	(receive (in ou)
	    (make-pipe)
	  (px.fd-set-non-blocking-mode! in)
	  (px.fd-set-close-on-exec-mode! in)
	  (px.fd-unset-close-on-exec-mode! in)
	  (list (px.fd-in-non-blocking-mode? in)
		(px.fd-in-close-on-exec-mode? in))))
    => '(#t #f))

  (check 	;with cloexec setting, testing
      (with-compensations
	(receive (in ou)
	    (make-pipe)
	  (px.fd-set-non-blocking-mode! in)
	  (px.fd-set-close-on-exec-mode! in)
	  (px.fd-unset-non-blocking-mode! in)
	  (list (px.fd-in-non-blocking-mode? in)
		(px.fd-in-close-on-exec-mode? in))))
    => '(#f #t))
  #t)


(parametrise ((check-test-name	'port-setting-mode))

  (check	;testing
      (with-compensations
	(receive (in ou)
	    (px.pipe)
	  (push-compensation (px.close in))
	  (push-compensation (px.close ou))
	  (let ((inp (make-binary-file-descriptor-input-port*  in "in")))
	    (port-in-non-blocking-mode? inp))))
    => #f)

  (check	;setting, testing
      (with-compensations
	(receive (in ou)
	    (px.pipe)
	  (push-compensation (px.close in))
	  (push-compensation (px.close ou))
	  (let ((inp (make-binary-file-descriptor-input-port*  in "in")))
	    (port-set-non-blocking-mode! inp)
	    (port-in-non-blocking-mode? inp))))
    => #t)

  (check	;setting, unsetting, testing
      (with-compensations
	(receive (in ou)
	    (px.pipe)
	  (push-compensation (px.close in))
	  (push-compensation (px.close ou))
	  (let ((inp (make-binary-file-descriptor-input-port*  in "in")))
	    (port-set-non-blocking-mode! inp)
	    (port-unset-non-blocking-mode! inp)
	    (port-in-non-blocking-mode? inp))))
    => #f)

  (check	;unsetting, testing
      (with-compensations
	(receive (in ou)
	    (px.pipe)
	  (push-compensation (px.close in))
	  (push-compensation (px.close ou))
	  (let ((inp (make-binary-file-descriptor-input-port*  in "in")))
	    (port-unset-non-blocking-mode! inp)
	    (port-in-non-blocking-mode? inp))))
    => #f)

  #t)


(parametrise ((check-test-name	'fd))

  ;;Reading from file descriptors with available bytes
  (check
      (with-compensations
	(receive (in ou)
	    (make-pipe)
	  (let ((P (make-textual-file-descriptor-input-port* in "in" (native-transcoder))))
	    (px.write ou '#ve(ascii "ciao"))
	    (receive-and-return (bv)
		(make-bytevector 4)
	      (px.read in bv)))))
    => '#ve(ascii "ciao"))

;;; --------------------------------------------------------------------

  ;;Reading file descriptor without available bytes causes EAGAIN.
  (check
      (with-compensations
	(receive (in ou)
	    (make-pipe)
	  (guard (E ((i/o-eagain-error? E)
		     #t)
		    (else E))
	    (px.read in (make-bytevector 4)))))
    => #t)

  #t)


(parametrise ((check-test-name	'port-binary))

  ;;Reading from binary ports with available bytes: GET-U8.
  (check
      (with-compensations
	(receive (in ou)
	    (make-pipe)
	  (let ((P (make-binary-file-descriptor-input-port* in "in")))
	    (px.write ou '#ve(ascii "ciao"))
	    (get-u8 P))))
    => (char->integer #\c))

  ;;Reading from binary ports with available bytes: LOOKAHEAD-U8.
  (check
      (with-compensations
	(receive (in ou)
	    (make-pipe)
	  (let ((P (make-binary-file-descriptor-input-port* in "in")))
	    (px.write ou '#ve(ascii "ciao"))
	    (lookahead-u8 P))))
    => (char->integer #\c))

  ;;Reading from binary ports with available bytes: LOOKAHEAD-TWO-U8.
  (check
      (with-compensations
	(receive (in ou)
	    (make-pipe)
	  (let ((P (make-binary-file-descriptor-input-port* in "in")))
	    (px.write ou '#ve(ascii "ciao"))
	    (receive (a b)
		(lookahead-two-u8 P)
	      (list a b)))))
    => (list (char->integer #\c) (char->integer #\i)))

  ;;Reading from  binary ports  with available  bytes: GET-BYTEVECTOR-N.
  ;;Ask exactly as available.
  (check
      (with-compensations
	(receive (in ou)
	    (make-pipe)
	  (let ((P (make-binary-file-descriptor-input-port* in "in")))
	    (px.write ou '#ve(ascii "ciao"))
	    (get-bytevector-n P 4))))
    => '#ve(ascii "ciao"))

  ;;Reading from  binary ports  with available  bytes: GET-BYTEVECTOR-N.
  ;;Ask more than available.
  (check
      (with-compensations
	(receive (in ou)
	    (make-pipe)
	  (let ((P (make-binary-file-descriptor-input-port* in "in")))
	    (px.write ou '#ve(ascii "ciao"))
	    (get-bytevector-n P 20))))
    => '#ve(ascii "ciao"))

  ;;Reading from  binary ports with available  bytes: GET-BYTEVECTOR-N!.
  ;;Ask exactly as available.
  (check
      (with-compensations
	(receive (in ou)
	    (make-pipe)
	  (let ((P  (make-binary-file-descriptor-input-port* in "in")))
	    (px.write ou '#ve(ascii "ciao"))
	    (let* ((bv (make-bytevector 4))
		   (rv (get-bytevector-n! P bv 0 4)))
	      (list rv bv)))))
    => '(4 #ve(ascii "ciao")))

  ;;Reading from  binary ports with available  bytes: GET-BYTEVECTOR-N!.
  ;;Ask more than available.
  (check
      (with-compensations
	(receive (in ou)
	    (make-pipe)
	  (let ((P (make-binary-file-descriptor-input-port* in "in")))
	    (px.write ou '#ve(ascii "ciao"))
	    (let* ((bv (make-bytevector 10 0))
		   (rv (get-bytevector-n! P bv 0 10)))
	      (list rv bv)))))
    => `(4 #vu8(99 105 97 111 0 0 0 0 0 0)))

  ;;Reading from binary  ports with available bytes and EOF  at the end:
  ;;GET-BYTEVECTOR-ALL.
  (check
      (with-compensations
	(receive (in ou)
	    (make-pipe)
	  (let ((P (make-binary-file-descriptor-input-port* in "in")))
	    (px.write ou '#ve(ascii "ciao"))
	    (px.close ou)
	    (get-bytevector-all P))))
    => '#ve(ascii "ciao"))

  ;;Reading from binary ports with available bytes: GET-BYTEVECTOR-SOME.
  (check
      (with-compensations
	(receive (in ou)
	    (make-pipe)
	  (let ((P (make-binary-file-descriptor-input-port* in "in")))
	    (px.write ou '#ve(ascii "ciao"))
	    (get-bytevector-some P))))
    => '#ve(ascii "ciao"))

;;; --------------------------------------------------------------------
;;; EAGAIN from empty binary ports

  ;;Reading binary port without available bytes causes EAGAIN: GET-U8.
  (check
      (with-compensations
  	(receive (in ou)
  	    (make-binary-ports)
	  (get-u8 in)))
    => (would-block-object))

  ;;Reading  binary   port  without   available  bytes   causes  EAGAIN:
  ;;LOOKAHEAD-U8.
  (check
      (with-compensations
  	(receive (in ou)
  	    (make-binary-ports)
	  (lookahead-u8 in)))
    => (would-block-object))

  ;;Reading  binary   port  without   available  bytes   causes  EAGAIN:
  ;;LOOKAHEAD-TWO-U8.
  (check
      (with-compensations
	(receive (in ou)
	    (make-binary-ports)
	  (receive (a b)
	      (lookahead-two-u8 in)
	    (list a b))))
    => (list (would-block-object) (would-block-object)))

  ;;Reading binary port  with not enough available  bytes causes EAGAIN:
  ;;LOOKAHEAD-TWO-U8.
  (check
      (with-compensations
	(receive (in ou)
	    (make-pipe)
	  (let ((P (make-binary-file-descriptor-input-port* in "in")))
	    (px.write ou '#vu8(99))
	    (receive (a b)
		(lookahead-two-u8 P)
	      (list a b)))))
    => `(99 ,(would-block-object)))

  ;;Reading binary port without  available bytes with GET-BYTEVECTOR-ALL
  ;;will block forever.
  ;;
  ;; (check
  ;;     (with-compensations
  ;; 	(receive (in ou)
  ;; 	    (make-binary-ports)
  ;; 	  (get-bytevector-all in)))
  ;;   => (would-block-object))

  ;;Reading  binary   port  without   available  bytes   causes  EAGAIN:
  ;;GET-BYTEVECTOR-N.
  (check
      (with-compensations
  	(receive (in ou)
  	    (make-binary-ports)
	  (get-bytevector-n in 1)))
    => (would-block-object))

  ;;Reading  binary   port  without   available  bytes   causes  EAGAIN:
  ;;GET-BYTEVECTOR-N!.
  (check
      (with-compensations
  	(receive (in ou)
  	    (make-binary-ports)
	  (let* ((bv (make-bytevector 1 0))
		 (rv (get-bytevector-n! in bv 0 1)))
	    (list rv bv))))
    => `(,(would-block-object) #vu8(0)))

  ;;Reading  binary   port  without   available  bytes   causes  EAGAIN:
  ;;GET-BYTEVECTOR-SOME.
  (check
      (with-compensations
  	(receive (in ou)
  	    (make-binary-ports)
	  (get-bytevector-some in)))
    => (would-block-object))

  #t)


(parametrise ((check-test-name	'port-textual))

  ;;Reading from textual port with available characters: GET-CHAR.
  (check
      (with-compensations
	(receive (in ou)
	    (make-pipe)
	  (let ((P (make-textual-file-descriptor-input-port* in "in" (native-transcoder))))
	    (px.write ou '#ve(ascii "c"))
	    (px.close ou)
	    (get-char P))))
    => #\c)

  ;;Reading from textual port with available characters: LOOKAHEAD-CHAR.
  (check
      (with-compensations
	(receive (in ou)
	    (make-pipe)
	  (let ((P (make-textual-file-descriptor-input-port* in "in" (native-transcoder))))
	    (px.write ou '#ve(ascii "c"))
	    (px.close ou)
	    (lookahead-char P))))
    => #\c)

  ;;Reading from textual port with available characters: PEEK-CHAR.
  (check
      (with-compensations
	(receive (in ou)
	    (make-pipe)
	  (let ((P (make-textual-file-descriptor-input-port* in "in" (native-transcoder))))
	    (px.write ou '#ve(ascii "c"))
	    (px.close ou)
	    (peek-char P))))
    => #\c)

  ;;Reading    from   textual    port    with   available    characters:
  ;;GET-STRING-SOME.
  (check
      (with-compensations
	(receive (in ou)
	    (make-pipe)
	  (let ((P (make-textual-file-descriptor-input-port* in "in" (native-transcoder))))
	    (px.write ou '#ve(ascii "ciao"))
	    (get-string-some P))))
    => "ciao")

  ;;Reading from  textual port with available  characters: GET-STRING-N.
  ;;Require available.
  (check
      (with-compensations
	(receive (in ou)
	    (make-pipe)
	  (let ((P (make-textual-file-descriptor-input-port* in "in" (native-transcoder))))
	    (px.write ou '#ve(ascii "ciao"))
	    (get-string-n P 4))))
    => "ciao")

  ;;Reading from  textual port with available  characters: GET-STRING-N.
  ;;Require more than available.
  (check
      (with-compensations
	(receive (in ou)
	    (make-pipe)
	  (let ((P (make-textual-file-descriptor-input-port* in "in" (native-transcoder))))
	    (px.write ou '#ve(ascii "ciao"))
	    (get-string-n P 10))))
    => "ciao")

  ;;Reading from  textual port with available  characters: GET-STRING-N!.
  ;;Require available.
  (check
      (with-compensations
	(receive (in ou)
	    (make-pipe)
	  (let ((P (make-textual-file-descriptor-input-port* in "in" (native-transcoder))))
	    (px.write ou '#ve(ascii "ciao"))
	    (let* ((str (make-string 4 #\0))
		   (rv  (get-string-n! P str 0 4)))
	      (list rv str)))))
    => '(4 "ciao"))

  ;;Reading from  textual port with available  characters: GET-STRING-N.
  ;;Require more than available.
  (check
      (with-compensations
	(receive (in ou)
	    (make-pipe)
	  (let ((P (make-textual-file-descriptor-input-port* in "in" (native-transcoder))))
	    (px.write ou '#ve(ascii "ciao"))
	    (let* ((str (make-string 10 #\0))
		   (rv  (get-string-n! P str 0 10)))
	      (list rv str)))))
    => '(4 "ciao000000"))

  ;;Reading from textual  port with available characters and  EOF at the
  ;;end: GET-STRING-ALL.
  (check
      (with-compensations
	(receive (in ou)
	    (make-pipe)
	  (let ((P (make-textual-file-descriptor-input-port* in "in" (native-transcoder))))
	    (px.write ou '#ve(ascii "ciao"))
	    (px.close ou)
	    (get-string-all P))))
    => "ciao")

;;; --------------------------------------------------------------------
;;; reading textual ports with full Unicode character available

  ;;Reading  textual   port  with  full  Unicode   character  available:
  ;;GET-STRING-SOME.
  (check
      (with-compensations
	(receive (in ou)
	    (make-pipe)
	  (let ((P (make-textual-file-descriptor-input-port* in "in" (native-transcoder))))
	    (px.write ou CJK-COMPATIBILITY-IDEOGRAPH-2F9D1-UTF-8)
	    (get-string-some P))))
    => (utf8->string CJK-COMPATIBILITY-IDEOGRAPH-2F9D1-UTF-8))

;;; --------------------------------------------------------------------
;;; EAGAIN from empty textual ports

  ;;Reading  textual   port  without  available  bytes   causes  EAGAIN:
  ;;GET-CHAR.
  (check
      (with-compensations
	(receive (in ou)
	    (make-textual-ports)
	  (get-char in)))
    => (would-block-object))

  ;;Reading  textual   port  without  available  bytes   causes  EAGAIN:
  ;;LOOKAHEAD-CHAR.
  (check
      (with-compensations
	(receive (in ou)
	    (make-textual-ports)
	  (lookahead-char in)))
    => (would-block-object))

  ;;Reading  textual   port  without  available  bytes   causes  EAGAIN:
  ;;PEEK-CHAR.
  (check
      (with-compensations
	(receive (in ou)
	    (make-textual-ports)
	  (peek-char in)))
    => (would-block-object))

  ;;Reading textual port without available byte with GET-STRING-ALL will
  ;;block forever.
  ;;
  ;; (check
  ;;     (with-compensations
  ;; 	(receive (in ou)
  ;; 	    (make-textual-ports)
  ;; 	  (get-string-all in)))
  ;;   => "")

  ;;Reading  textual   port  without  available  bytes   causes  EAGAIN:
  ;;GET-STRING-N.
  (check
      (with-compensations
	(receive (in ou)
	    (make-textual-ports)
	  (get-string-n in 1)))
    => (would-block-object))

  ;;Reading  textual   port  without  available  bytes   causes  EAGAIN:
  ;;GET-STRING-N!.
  (check
      (with-compensations
	(receive (in ou)
	    (make-textual-ports)
	  (let* ((str (make-string 1 #\0))
		 (rv  (get-string-n! in str 0 1)))
	    (list rv str))))
    => (list (would-block-object) "0"))

  ;;Reading  textual   port  without  available  bytes   causes  EAGAIN:
  ;;GET-STRING-SOME.
  (check
      (with-compensations
	(receive (in ou)
	    (make-textual-ports)
	  (get-string-some in)))
    => (would-block-object))

;;; --------------------------------------------------------------------
;;; EAGAIN from textual ports with partial characters

  ;;Reading textual port with partial character available causes EAGAIN:
  ;;GET-STRING-SOME.
  (check
      (with-compensations
	(receive (in ou)
	    (make-pipe)
	  (let ((P (make-textual-file-descriptor-input-port* in "in" (native-transcoder))))
	    ;;Write  a  partial  Unicode   charin  UTF-8  encoding:  CJK
	    ;;COMPATIBILITY IDEOGRAPH 2F9D1.
	    (px.write ou '#vu8(#xF0 #xAF #xA7))
	    (get-string-some P))))
    => (would-block-object))

  #t)


;;;; done

(check-report)

;;; end of file
