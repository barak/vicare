;;; -*- coding: utf-8-unix -*-
;;;
;;;Part of: Vicare Scheme
;;;Contents: communicating with remote processes
;;;Date: Fri Apr  5, 2013
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
(library (vicare net channels)
  (export
    ;; record type
    channel
    binary-channel
    textual-channel

    ;; initialisation and finalisation
    open-binary-input-channel		open-textual-input-channel
    open-binary-output-channel		open-textual-output-channel
    open-binary-input/output-channel	open-textual-input/output-channel
    close-channel
    channel-abort!

    ;; configuration
    channel-set-maximum-message-size!
    channel-set-expiration-time!
    channel-set-message-terminators!
    channel-set-maximum-message-portion-size!

    ;; getters
    channel-connect-in-port
    channel-connect-ou-port

    ;; predicates and arguments validation
    channel?
    channel.vicare-arguments-validation
    false-or-channel.vicare-arguments-validation

    binary-channel?
    binary-channel.vicare-arguments-validation
    false-or-binary-channel.vicare-arguments-validation

    textual-channel?
    textual-channel.vicare-arguments-validation
    false-or-textual-channel.vicare-arguments-validation

    receiving-channel?		receiving-channel.vicare-arguments-validation
    sending-channel?		sending-channel.vicare-arguments-validation
    inactive-channel?		inactive-channel.vicare-arguments-validation
    input-channel?		input-channel.vicare-arguments-validation
    output-channel?		output-channel.vicare-arguments-validation
    input/output-channel?	input/output-channel.vicare-arguments-validation

    ;; message reception
    channel-recv-begin!		channel-recv-end!
    channel-recv-message-portion!
    channel-recv-full-message

    ;; message sending
    channel-send-begin!		channel-send-end!
    channel-send-message-portion!
    channel-send-full-message

    ;; condition objects
    &channel
    make-channel-condition
    channel-condition?
    condition-channel

    &delivery-timeout-expired
    make-delivery-timeout-expired-condition
    delivery-timeout-expired-condition?

    &maximum-message-size-exceeded
    make-maximum-message-size-exceeded-condition
    maximum-message-size-exceeded-condition?)
  (import (vicare)
    (vicare unsafe operations)
    (vicare arguments validation)
    (vicare language-extensions syntaxes))


;;;; data structures

(define-record-type-extended channel
  (nongenerative vicare:net:channels:channel)
  (fields (immutable connect-in-port)
		;An input  or input/output  binary port used  to receive
		;messages from a remote process.
	  (immutable connect-ou-port)
		;An  output or  input/output  binary port  used to  send
		;messages to a remote process.
	  (mutable action)
		;False or the symbol "recv" or the symbol "send".
	  (mutable expiration-time)
		;A time object representing the  limit of time since the
		;Epoch  to complete  message delivery;  if the  allotted
		;time expires:  sending or  receiving this  message will
		;fail.
	  (mutable message-buffer)
		;Null  or a  list of  bytevectors representing  the data
		;accumulated so far; last input first.
	  (mutable message-size)
		;A non-negative  exact integer representing  the current
		;message size.
	  (mutable maximum-message-size)
		;A non-negative exact integer representing the inclusive
		;maximum  message  size;  if  the size  of  the  message
		;exceeds this value: message delivery will fail.
	  (mutable message-terminators)
		;A non-empty list  of non-empty bytevectors representing
		;possible message terminators.
	  (mutable message-terminated?)
		;A  boolean,  true  if  while receiving  a  message  the
		;terminator has already been read.
	  (mutable maximum-message-portion-size)
		;A positive  fixnum representing  the maximum  number of
		;units (bytes, characters) read at each "message portion
		;receive" operation.
	  )
  (protocol
   (lambda (maker)
     (lambda (in-port ou-port default-terminators max-portion-size)
       (define who 'channel-constructor)
       (define-argument-validation (one-port who in-port ou-port)
	 (or in-port ou-port)
	 (assertion-violation who "both port arguments are false" in-port ou-port))
       (with-arguments-validation (who)
	   ((input-port/false	in-port)
	    (output-port/false	ou-port)
	    (one-port		in-port ou-port))
	 (maker in-port ou-port
		#f #;action #f #;expiration-time
		'() #;message-buffer 0 #;message-size 4096 #;maximum-message-size
		default-terminators #;message-terminators #f #;message-terminated?
		max-portion-size #;maximum-message-portion-size
		))))))

(define-record-type-extended binary-channel
  (nongenerative vicare:net:channels:binary-channel)
  (parent channel)
  (protocol
   (lambda (make-channel)
     (lambda (in-port ou-port)
       (define who 'binary-channel-constructor)
       (with-arguments-validation (who)
	   ((binary-port/false	in-port)
	    (binary-port/false	ou-port))
	 ((make-channel in-port ou-port DEFAULT-BINARY-TERMINATORS 4096)))))))

(define-record-type-extended textual-channel
  (nongenerative vicare:net:channels:textual-channel)
  (parent channel)
  (protocol
   (lambda (make-channel)
     (lambda (in-port ou-port)
       (define who 'textual-channel-constructor)
       (with-arguments-validation (who)
	   ((textual-port/false	in-port)
	    (textual-port/false	ou-port))
	 ((make-channel in-port ou-port DEFAULT-TEXTUAL-TERMINATORS 1024)))))))

(define-constant DEFAULT-BINARY-TERMINATORS
  '(#ve(ascii "\r\n\r\n") #ve(ascii "\r\n")))

(define-constant DEFAULT-TEXTUAL-TERMINATORS
  '("\r\n\r\n" "\r\n"))


;;;; unsafe operations

(define ($channel-message-buffer-push! chan data)
  ($channel-message-buffer-set! chan (cons data ($channel-message-buffer chan)))
  ($channel-message-increment-size! chan (if (binary-channel? chan)
					     ($bytevector-length data)
					   ($string-length data))))

(define ($channel-message-increment-size! chan delta-size)
  ($channel-message-size-set! chan (+ delta-size ($channel-message-size chan))))

(define ($delivery-timeout-expired? chan)
  (cond (($channel-expiration-time chan)
	 => (lambda (expiration-time)
	      (time<=? expiration-time (current-time))))
	(else #f)))

(define ($maximum-size-exceeded? chan)
  (> ($channel-message-size chan)
     ($channel-maximum-message-size chan)))


;;;; initialisation and finalisation

(define (open-binary-input-channel port)
  (define who 'open-binary-input-channel)
  (with-arguments-validation (who)
      ((binary-port	port)
       (input-port	port))
    (make-binary-channel port #f)))

(define (open-binary-output-channel port)
  (define who 'open-binary-output-channel)
  (with-arguments-validation (who)
      ((binary-port	port)
       (output-port	port))
    (make-binary-channel #f port)))

(define open-binary-input/output-channel
  (case-lambda
   ((port)
    (open-binary-input/output-channel port port))
   ((in-port ou-port)
    (define who 'open-binary-input/output-channel)
    (with-arguments-validation (who)
	((binary-port	in-port)
	 (binary-port	ou-port)
	 (input-port	in-port)
	 (output-port	ou-port))
      (make-binary-channel in-port ou-port)))))

;;; --------------------------------------------------------------------

(define (open-textual-input-channel port)
  (define who 'open-textual-input-channel)
  (with-arguments-validation (who)
      ((textual-port	port)
       (input-port	port))
    (make-textual-channel port #f)))

(define (open-textual-output-channel port)
  (define who 'open-textual-output-channel)
  (with-arguments-validation (who)
      ((textual-port	port)
       (output-port	port))
    (make-textual-channel #f port)))

(define open-textual-input/output-channel
  (case-lambda
   ((port)
    (open-textual-input/output-channel port port))
   ((in-port ou-port)
    (define who 'open-textual-input/output-channel)
    (with-arguments-validation (who)
	((textual-port	in-port)
	 (textual-port	ou-port)
	 (input-port	in-port)
	 (output-port	ou-port))
      (make-textual-channel in-port ou-port)))))

;;; --------------------------------------------------------------------

(define (close-channel chan)
  ;;Finalise a  channel closing its connection  port; return unspecified
  ;;values.  A pending message delivery is aborted.
  ;;
  (define who 'close-channel)
  (with-arguments-validation (who)
      ((channel		chan))
    ($close-channel chan)))

(define ($close-channel chan)
  (define (%close port)
    (and port (close-port port)))
  (%close ($channel-connect-in-port chan))
  (%close ($channel-connect-ou-port chan))
  (struct-reset chan)
  (void))

(define (channel-abort! chan)
  ;;Abort  the current  operation  and reset  the  channel to  inactive;
  ;;return unspecified values.
  ;;
  (define who 'channel-abort!)
  (with-arguments-validation (who)
      ((channel		chan))
    ($channel-abort! chan)))

(define ($channel-abort! chan)
  ($channel-action-set!              chan #f)
  ($channel-message-buffer-set!      chan '())
  ($channel-message-size-set!        chan 0)
  ($channel-message-terminated?-set! chan #f)
  (void))

;;;; configuration

(define (channel-set-maximum-message-size! chan maximum-message-size)
  ;;MAXIMUM-MESSAGE-SIZE must  be a positive exact  integer representing
  ;;the inclusive maximum  message size in octets or  characters; if the
  ;;size of the message exceeds this value: message delivery will fail.
  ;;
  (define who 'channel-set-maximum-message-size!)
  (with-arguments-validation (who)
      ((channel			chan)
       (positive-exact-integer	maximum-message-size))
    ($channel-maximum-message-size-set! chan maximum-message-size)
    (void)))

(define (channel-set-expiration-time! chan expiration-time)
  ;;EXPIRATION-TIME  must be  false or  a time  object representing  the
  ;;limit of time  since the Epoch to complete message  delivery; if the
  ;;allotted time expires: message delivery will fail.
  ;;
  (define who 'channel-set-expiration-time!)
  (with-arguments-validation (who)
      ((channel		chan)
       (time/false	expiration-time))
    ($channel-expiration-time-set! chan expiration-time)
    (void)))

(module (channel-set-message-terminators!)

  (define (channel-set-message-terminators! chan terminators)
    ;;TERMINATORS must be  a non-empty list of  non-empty bytevectors or
    ;;strings representing possible message terminators.
    ;;
    (define who 'channel-set-message-terminators!)
    (cond ((binary-channel? chan)
	   (with-arguments-validation (who)
	       ((binary-terminators	terminators))
	     ($channel-message-terminators-set! chan terminators)))
	  ((textual-channel? chan)
	   (with-arguments-validation (who)
	       ((textual-terminators	terminators))
	     ($channel-message-terminators-set! chan terminators)))
	  (else
	   (assertion-violation who
	     "expected textual or binary channel as argument" chan)))
    (void))

  (define-argument-validation (binary-terminators who obj)
    (and (not (null? obj))
	 (list? obj)
	 (for-all (lambda (item)
		    (and (bytevector? item)
			 (not ($fxzero? ($bytevector-length item)))))
	   obj))
    (assertion-violation who
      "expected non-empty list of non-empty bytevectors as argument" obj))

  (define-argument-validation (textual-terminators who obj)
    (and (not (null? obj))
	 (list? obj)
	 (for-all (lambda (item)
		    (and (string? item)
			 (not ($fxzero? ($string-length item)))))
	   obj))
    (assertion-violation who
      "expected non-empty list of non-empty strings as argument" obj))

  #| end of module |# )

(define (channel-set-maximum-message-portion-size! chan max-portion-size)
  ;;MAX-PORTION-SIZE  must   be  a  positive  fixnum   representing  the
  ;;inclusive  maximum size,  in  octets or  characters, requested  when
  ;;receiving message portions.
  ;;
  (define who 'channel-set-maximum-message-portion-size!)
  (with-arguments-validation (who)
      ((channel			chan)
       (positive-fixnum		max-portion-size))
    ($channel-maximum-message-portion-size-set! chan max-portion-size)
    (void)))


;;;; predicates and arguments validation: receiving messages

(define (receiving-channel? chan)
  ;;Return #t  if CHAN  is in  the course of  receiving a  message, else
  ;;return #f.  It is an error if CHAN is not an instance of CHANNEL.
  ;;
  (define who 'receiving-channel?)
  (with-arguments-validation (who)
      ((channel	chan))
    ($receiving-channel? chan)))

(define ($receiving-channel? chan)
  ;;Unsafe function returning #t if CHAN is in the course of receiving a
  ;;message, else return #f.
  ;;
  (eq? 'recv ($channel-action chan)))

;;; --------------------------------------------------------------------

(define-argument-validation (receiving-channel who obj)
  ;;Succeed if OBJ is an instance of  CHANNEL and it is in the course of
  ;;receiving a message.
  ;;
  (and (channel? obj)
       ($receiving-channel? obj))
  (assertion-violation who
    "expected channel in the course of receving a message as argument" obj))

(define-argument-validation (not-receiving-channel who chan)
  ;;Succeed if  CHAN is an  instance of CHANNEL and  it is *not*  in the
  ;;course of receiving a message.
  ;;
  (and (channel? chan)
       (not ($receiving-channel? chan)))
  (assertion-violation who
    "expected channel not in the course of receving a message as argument" chan))


;;;; predicates and arguments validation: sending messages

(define (sending-channel? chan)
  ;;Return #t if CHAN is in the course of sending a message, else return
  ;;#f.  It is an error if CHAN is not an instance of CHANNEL.
  ;;
  (define who 'sending-channel?)
  (with-arguments-validation (who)
      ((channel	chan))
    ($sending-channel? chan)))

(define ($sending-channel? chan)
  ;;Unsafe function returning  #t if CHAN is in the  course of sending a
  ;;message, else return #f.
  ;;
  (eq? 'send ($channel-action chan)))

;;; --------------------------------------------------------------------

(define-argument-validation (sending-channel who obj)
  ;;Succeed if OBJ is an instance of  CHANNEL and it is in the course of
  ;;sending a message.
  ;;
  (and (channel? obj)
       ($sending-channel? obj))
  (assertion-violation who
    "expected channel in the course of sending a message as argument" obj))

(define-argument-validation (not-sending-channel who chan)
  ;;Succeed if  CHAN is an  instance of CHANNEL and  it is *not*  in the
  ;;course of sending a message.
  ;;
  (and (channel? chan)
       (not ($sending-channel? chan)))
  (assertion-violation who
    "expected channel not in the course of sending a message as argument" chan))


;;;; predicates and arguments validation: inactive channel

(define (inactive-channel? chan)
  ;;Return #t if CHAN is neither  in the course of sending nor receiving
  ;;a  message, else  return #f.   It  is an  error  if CHAN  is not  an
  ;;instance of CHANNEL.
  ;;
  (define who 'inactive-channel?)
  (with-arguments-validation (who)
      ((channel	chan))
    ($inactive-channel? chan)))

(define ($inactive-channel? chan)
  ;;Unsafe function  returning #t if  CHAN is  neither in the  course of
  ;;sending nor receiving a message, else return #f.
  ;;
  (not ($channel-action chan)))

;;; --------------------------------------------------------------------

(define-argument-validation (inactive-channel who obj)
  ;;Succeed if OBJ  is an instance of  CHANNEL and it is  neither in the
  ;;course of sending nor receiving a message.
  ;;
  (and (channel? obj)
       ($inactive-channel? obj))
  (assertion-violation who "expected inactive channel as argument" obj))

(define-argument-validation (not-inactive-channel who chan)
  ;;Succeed if CHAN  is an instance of CHANNEL and  it is either sending
  ;;or receiving a message.
  ;;
  (and (channel? chan)
       (not ($inactive-channel? chan)))
  (assertion-violation who "expected inactive channel as argument" chan))


;;;; predicates and arguments validation: input channel

(define (input-channel? chan)
  ;;Return #t if  CHAN is an input or input/output  channel, else return
  ;;#f.  It is an error if CHAN is not an instance of CHANNEL.
  ;;
  (define who 'input-channel?)
  (with-arguments-validation (who)
      ((channel	chan))
    ($input-channel? chan)))

(define ($input-channel? chan)
  ;;Unsafe function  returning #t  if CHAN is  an input  or input/output
  ;;channel, else return #f.
  ;;
  (and ($channel-connect-in-port chan) #t))

;;; --------------------------------------------------------------------

(define-argument-validation (input-channel who obj)
  ;;Succeed if  OBJ is  an instance  of CHANNEL  and it  is an  input or
  ;;input/output channel.
  ;;
  (and (channel? obj)
       ($input-channel? obj))
  (assertion-violation who
    "expected input or input/output channel as argument" obj))


;;;; predicates and arguments validation: output channel

(define (output-channel? chan)
  ;;Return #t if CHAN is an  output or input/output channel, else return
  ;;#f.  It is an error if CHAN is not an instance of CHANNEL.
  ;;
  (define who 'output-channel?)
  (with-arguments-validation (who)
      ((channel	chan))
    ($output-channel? chan)))

(define ($output-channel? chan)
  ;;Unsafe function  returning #t if  CHAN is an output  or input/output
  ;;channel, else return #f.
  ;;
  (and ($channel-connect-ou-port chan) #t))

;;; --------------------------------------------------------------------

(define-argument-validation (output-channel who obj)
  ;;Succeed if  OBJ is  an instance of  CHANNEL and it  is an  output or
  ;;input/output channel.
  ;;
  (and (channel? obj)
       ($output-channel? obj))
  (assertion-violation who
    "expected output or input/output channel as argument" obj))


;;;; predicates and arguments validation: input/output channel

(define (input/output-channel? chan)
  ;;Return #t if CHAN is an input/output channel, else return #f.  It is
  ;;an error if CHAN is not an instance of CHANNEL.
  ;;
  (define who 'input/output-channel?)
  (with-arguments-validation (who)
      ((channel	chan))
    ($input/output-channel? chan)))

(define ($input/output-channel? chan)
  ;;Unsafe function  returning #t  if CHAN  is an  input/output channel,
  ;;else return #f.
  ;;
  (and ($channel-connect-in-port chan)
       ($channel-connect-ou-port chan)
       #t))

;;; --------------------------------------------------------------------

(define-argument-validation (input/output-channel who obj)
  ;;Succeed if OBJ  is an instance of CHANNEL and  it is an input/output
  ;;channel.
  ;;
  (and (channel? obj)
       ($input/output-channel? obj))
  (assertion-violation who "expected input/output channel as argument" obj))


;;;; condition objects and exception raising

(define-condition-type &channel
    &condition
  make-channel-condition
  channel-condition?
  (channel	condition-channel))

(define-condition-type &delivery-timeout-expired
    &error
  make-delivery-timeout-expired-condition
  delivery-timeout-expired-condition?)

(define-condition-type &maximum-message-size-exceeded
    &error
  make-maximum-message-size-exceeded-condition
  maximum-message-size-exceeded-condition?)

;;; --------------------------------------------------------------------

(define (%error-message-delivery-timeout-expired who chan)
  ;;Raise a  non-continuable exception  representing the  error: message
  ;;message delivery  timeout expired.  The raised  condition object has
  ;;components: &who, &message, &channel, &timeout-expired.
  ;;
  (raise
   (condition (make-channel-condition chan)
	      (make-delivery-timeout-expired-condition)
	      (make-who-condition who)
	      (make-message-condition "message reception timeout expired"))))

(define (%error-maximum-message-size-exceeded who chan)
  ;;Raise a  non-continuable exception  representing the  error: maximum
  ;;message size exceeded.  The  raised condition object has components:
  ;;&who, &message, &channel, &maximum-message-size-exceeded.
  ;;
  (raise
   (condition (make-channel-condition chan)
	      (make-maximum-message-size-exceeded-condition)
	      (make-who-condition who)
	      (make-message-condition "message reception timeout expired"))))


;;;; receiving messages

(define (channel-recv-begin! chan)
  ;;Configure a channel to start receiving a message; return unspecified
  ;;values.  CHAN  must be an  input or  input/output channel; it  is an
  ;;error if the channel is not inactive.
  ;;
  (define who 'channel-recv-begin!)
  (with-arguments-validation (who)
      ((inactive-channel	chan)
       (input-channel		chan))
    ($channel-recv-begin! chan)))

(define ($channel-recv-begin! chan)
  ($channel-action-set!              chan 'recv)
  ($channel-message-buffer-set!      chan '())
  ($channel-message-size-set!        chan 0)
  ($channel-message-terminated?-set! chan #f)
  (void))

;;; --------------------------------------------------------------------

(define (channel-recv-end! chan)
  ;;Finish receiving  a message and  return the accumulated octets  in a
  ;;bytevector or chars in  a string.  It is an error  if the channel is
  ;;not in the course of receiving a message.
  ;;
  ;;After this function  is applied to a channel: the  channel itself is
  ;;configured  as  inactive; so  it  is  available to  start  receiving
  ;;another message or to send a message.
  ;;
  (define who 'channel-recv-end!)
  (with-arguments-validation (who)
      ((receiving-channel	chan))
    ($channel-recv-end! chan)))

(define ($channel-recv-end! chan)
  (receive (reverse-buffers total-size)
      ($channel-recv-end!/rbl chan)
    (if (binary-channel? chan)
	($bytevector-reverse-and-concatenate total-size reverse-buffers)
      ($string-reverse-and-concatenate total-size reverse-buffers))))

(define (channel-recv-end!/rbl chan)
  ;;Finish  receiving a  message  and return  the 2  values:  a list  of
  ;;bytevectors or strings representing  the data buffers accumulated in
  ;;reverse order,  an exact integer  representing the total  data size.
  ;;It is an  error if the channel  is not in the course  of receiving a
  ;;message.
  ;;
  ;;After this function  is applied to a channel: the  channel itself is
  ;;configured  as  inactive; so  it  is  available to  start  receiving
  ;;another message or to send a message.
  ;;
  (define who 'channel-recv-end!/rbl)
  (with-arguments-validation (who)
      ((receiving-channel	chan))
    ($channel-recv-end!/rbl chan)))

(define ($channel-recv-end!/rbl chan)
  (begin0
      (values ($channel-message-buffer chan)
	      ($channel-message-size   chan))
    ($channel-action-set!          chan #f)
    ($channel-message-buffer-set!  chan '())
    ($channel-message-size-set!    chan 0)
    ($channel-message-terminated?-set! chan #f)))

;;; --------------------------------------------------------------------

(define (channel-recv-message-portion! chan)
  ;;Receive a portion of input message from the given channel.  It is an
  ;;error if the channel is not in the course of receiving a message.
  ;;
  ;;* Return  true if a configured  message terminator is read  from the
  ;;input port or if the channel already read a terminator in a previous
  ;;operation.   If  a  message  terminator is  received:  set  CHAN  to
  ;;"message terminated" status.
  ;;
  ;;* Return the EOF object if EOF  is read from the input port before a
  ;;message terminator.
  ;;
  ;;* Return false  if neither a message terminator nor  EOF is read; in
  ;;this  case we  need to  call this  function again  later to  receive
  ;;further message portions.
  ;;
  ;;*  If the  message  delivery  timeout is  expired  or expires  while
  ;;receiving data: raise an exception.
  ;;
  ;;* If the accumulated data exceeds the maximum message size: raise an
  ;;exception.
  ;;
  (define who 'channel-recv-message-portion!)
  (cond ((and (binary-channel?     chan)
	      ($receiving-channel? chan))
	 ($channel-recv-binary-message-portion! chan))
	((and (textual-channel?    chan)
	      ($receiving-channel? chan))
	 ($channel-recv-textual-message-portion! chan))
	(else
	 (assertion-violation who
	   "expected net channel in the course of receiving a message as argument" chan))))

;;; --------------------------------------------------------------------

(define (channel-recv-full-message chan)
  (define who 'channel-recv-full-message)
  (with-arguments-validation (who)
      ((inactive-channel	chan)
       (input-channel		chan))
    ($channel-recv-full-message chan)))

(define ($channel-recv-full-message chan)
  ($channel-recv-begin! chan)
  (let next-portion ()
    (let ((rv (if (binary-channel? chan)
		  ($channel-recv-binary-message-portion! chan)
		($channel-recv-textual-message-portion! chan))))
      (cond ((eof-object? rv)
	     rv)
	    ((would-block-object? rv)
	     rv)
	    ((not rv)
	     (next-portion))
	    (else
	     ($channel-recv-end! chan))))))


;;;; receiving messages: binary message portion

(module ($channel-recv-binary-message-portion!)

  (define who 'channel-recv-message-portion!)

  (define ($channel-recv-binary-message-portion! chan)
    ;;Receive a portion of input message  from the given channel.  It is
    ;;an  error if  the channel  is  not in  the course  of receiving  a
    ;;message.
    ;;
    ;;* Return true if a configured  message terminator is read from the
    ;;input  port or  if  the channel  already read  a  terminator in  a
    ;;previous operation.  If a message terminator is received: set CHAN
    ;;to "message terminated" status.
    ;;
    ;;* Return the EOF object if EOF  is read from the input port before
    ;;a message terminator.
    ;;
    ;;* Return false if neither a message terminator nor EOF is read; in
    ;;this case  we need  to call  this function  again later  to receive
    ;;further message portions.
    ;;
    ;;*  If the  message delivery  timeout is  expired or  expires while
    ;;receiving  data:  raise an  exception.
    ;;
    ;;* If the accumulated data  exceeds the maximum message size: raise
    ;;an exception.
    ;;
    (cond
     ;;If the  message is terminated: we  do not care anymore  about the
     ;;timeout.
     (($channel-message-terminated? chan)
      #t)
     ;;If the message  is not terminated and the  timeout expired: raise
     ;;an error.
     (($delivery-timeout-expired? chan)
      (%error-message-delivery-timeout-expired who chan))
     (else
      (let ((bv (get-bytevector-n ($channel-connect-in-port chan)
				  ($channel-maximum-message-portion-size chan))))
	(cond
	 ;;If  the EOF  is found  before reading  a message  terminator:
	 ;;return the EOF object.
	 ((eof-object? bv)
	  bv)
	 ;;If reading causes a would-block  condition with no input data
	 ;;or an empty bytevector is  read: return would block to signal
	 ;;the need to read further message portions.
	 ((or (would-block-object? bv)
	      ($fxzero? ($bytevector-length bv)))
	  #!would-block)
	 ;;If a message portion is read: push it on the internal buffer;
	 ;;check message size and timeout expiration; return true if the
	 ;;message is terminated, false otherwise.
	 (else
	  ($channel-message-buffer-push! chan bv)
	  (cond (($maximum-size-exceeded? chan)
		 (%error-maximum-message-size-exceeded who chan))
		(($delivery-timeout-expired? chan)
		 (%error-message-delivery-timeout-expired who chan))
		((%received-message-terminator? chan)
		 ($channel-message-terminated?-set! chan #t)
		 #t)
		(else #f))))))))

  (module (%received-message-terminator?)

    (define (%received-message-terminator? chan)
      ;;Compare  all  the  message   terminators  with  the  bytevectors
      ;;accumulated in  the buffer of CHAN.   If the tail of  the buffer
      ;;equals one of the terminators: return true, else return false.
      ;;
      (let ((terminators ($channel-message-terminators chan))
	    (buffers     ($channel-message-buffer chan)))
	(find (lambda (terminator)
		($terminated-octets-stream? buffers terminator))
	  terminators)))

    (define ($terminated-octets-stream? reverse-stream terminator)
      ;;Compare a terminator  with the tail of an octets  stream; if the
      ;;stream  is terminated  return #t,  else return  #f.  This  is an
      ;;unsafe  function: it  assumes  the arguments  have been  already
      ;;validated.
      ;;
      ;;TERMINATOR  must  be  a non-empty  bytevector  representing  the
      ;;stream  terminator; the  last octet  in TERMINATOR  is the  last
      ;;octet in a properly terminated stream.
      ;;
      ;;REVERSE-SEQUENCE must be null or a list of non-empty bytevectors
      ;;representing the stream of octects in bytevector-reversed order;
      ;;as  if the  stream of  octets  has been  accumulated (=  CONSed)
      ;;bytevector by bytevector:
      ;;
      ;;* The first  item of REVERSE-SEQUENCE is the  last bytevector in
      ;;  the  stream, the  last item of  REVERSE-SEQUENCE is  the first
      ;;  bytevector in the stream.
      ;;
      ;;*  Every bytevector  in REVERSE-SEQUENCE  represents a  chunk of
      ;;  stream: the  first octet in the bytevector is  the first octet
      ;;  in  the chunk, the  last octet in  the bytevector is  the last
      ;;  octet in the chunk.
      ;;
      (define ($bytevector-last-index bv)
	($fxsub1 ($bytevector-length bv)))
      (let loop ((terminator.idx  ($bytevector-last-index terminator))
		 (buffers         reverse-stream))
	(cond (($fx= -1 terminator.idx)
	       #t)
	      ((null? buffers)
	       #f)
	      ((let* ((buf     ($car buffers))
		      (buf.idx ($bytevector-last-index buf)))
		 ($compare-bytevector-tails terminator terminator.idx buf buf.idx))
	       => (lambda (terminator.idx)
		    (loop ($fxsub1 terminator.idx) ($cdr buffers))))
	      (else #f))))

    (define ($compare-bytevector-tails A A.idx B B.idx)
      ;;Recursive  function.  Compare  the bytevector  A, starting  from
      ;;index A.idx inclusive, to the  bytevector B, starting from index
      ;;B.idx inclusive.  If:
      ;;
      ;;* All the octets are equal  up to (zero? A.idx) included: return
      ;;  0.  An example of this case is a call with arguments:
      ;;
      ;;     A =       #vu8(3 4 5)	A.idx = 2
      ;;     B = #vu8(0 1 2 3 4 5)	B.idx = 5
      ;;
      ;;  another example of this case:
      ;;
      ;;     A = #vu8(0 1 2 3 4 5)	A.idx = 5
      ;;     B = #vu8(0 1 2 3 4 5)	B.idx = 5
      ;;
      ;;* All the octets are equal up to (zero?  B.idx) included: return
      ;;  the value  of A.idx referencing the last compared  octet in A.
      ;;  An example of this case is a call with arguments:
      ;;
      ;;     A = #vu8(0 1 2 3 4 5)	A.idx = 5
      ;;     B =       #vu8(3 4 5)	B.idx = 2
      ;;
      ;;  the returned value is: A.idx == 3.
      ;;
      ;;* Octects  having (positive?  A.idx) and  (positive?  B.idx) are
      ;;  different: return false.
      ;;
      (and ($fx= ($bytevector-u8-ref A A.idx)
		 ($bytevector-u8-ref B B.idx))
	   (cond (($fxzero? A.idx)
		  0)
		 (($fxzero? B.idx)
		  A.idx)
		 (else
		  ($compare-bytevector-tails A ($fxsub1 A.idx)
					     B ($fxsub1 B.idx))))))

    #| end of module: %received-message-terminator? |# )

  #| end of module: channel-recv-message-portion! |# )


;;;; receiving messages: textual message portion

(module ($channel-recv-textual-message-portion!)

  (define who 'channel-recv-message-portion!)

  (define ($channel-recv-textual-message-portion! chan)
    ;;Receive a portion of input message  from the given channel.  It is
    ;;an  error if  the channel  is  not in  the course  of receiving  a
    ;;message.
    ;;
    ;;* Return true if a configured  message terminator is read from the
    ;;input  port or  if  the channel  already read  a  terminator in  a
    ;;previous operation.  If a message terminator is received: set CHAN
    ;;to "message terminated" status.
    ;;
    ;;* Return the EOF object if EOF  is read from the input port before
    ;;a message terminator.
    ;;
    ;;* Return false if neither a message terminator nor EOF is read; in
    ;;this case  we need to  call this  function again later  to receive
    ;;further message portions.
    ;;
    ;;*  If the  message delivery  timeout is  expired or  expires while
    ;;receiving  data:  raise an  exception.
    ;;
    ;;* If the accumulated data  exceeds the maximum message size: raise
    ;;an exception.
    ;;
    (cond
     ;;If the  message is terminated: we  do not care anymore  about the
     ;;timeout.
     (($channel-message-terminated? chan)
      #t)
     ;;If the message  is not terminated and the  timeout expired: raise
     ;;an error.
     (($delivery-timeout-expired? chan)
      (%error-message-delivery-timeout-expired who chan))
     (else
      (let ((str (get-string-n ($channel-connect-in-port chan)
			       ($channel-maximum-message-portion-size chan))))
	(cond
	 ;;If  the EOF  is found  before reading  a message  terminator:
	 ;;return the EOF object.
	 ((eof-object? str)
	  str)
	 ;;If reading causes a would-block  condition with no input data
	 ;;or an empty string is  read: return would-block to signal the
	 ;;need to read further message portions.
	 ((or (would-block-object? str)
	      ($fxzero? ($string-length str)))
	  #!would-block)
	 ;;If a message portion is read: push it on the internal buffer;
	 ;;check message size and timeout expiration; return true if the
	 ;;message is terminated, false otherwise.
	 (else
	  ($channel-message-buffer-push! chan str)
	  (cond (($maximum-size-exceeded? chan)
		 (%error-maximum-message-size-exceeded who chan))
		(($delivery-timeout-expired? chan)
		 (%error-message-delivery-timeout-expired who chan))
		((%received-message-terminator? chan)
		 ($channel-message-terminated?-set! chan #t)
		 #t)
		(else #f))))))))

  (module (%received-message-terminator?)

    (define (%received-message-terminator? chan)
      ;;Compare all the message terminators with the strings accumulated
      ;;in the buffer of CHAN.  If the  tail of the buffer equals one of
      ;;the terminators: return true, else return false.
      ;;
      (let ((terminators ($channel-message-terminators chan))
	    (buffers     ($channel-message-buffer chan)))
	(find (lambda (terminator)
		($terminated-chars-stream? buffers terminator))
	  terminators)))

    (define ($terminated-chars-stream? reverse-stream terminator)
      ;;Compare a terminator  with the tail of an chars  stream; if the
      ;;stream  is terminated  return #t,  else return  #f.  This  is an
      ;;unsafe  function: it  assumes  the arguments  have been  already
      ;;validated.
      ;;
      ;;TERMINATOR must  be a  non-empty string representing  the stream
      ;;terminator; the  last char in TERMINATOR  is the last char  in a
      ;;properly terminated stream.
      ;;
      ;;REVERSE-SEQUENCE must  be null  or a  list of  non-empty strings
      ;;representing the stream of chars in string-reversed order; as if
      ;;the stream  of chars has  been accumulated (= CONSed)  string by
      ;;string:
      ;;
      ;;* The first  item of REVERSE-SEQUENCE is the last  string in the
      ;;   stream,  the  last  item of  REVERSE-SEQUENCE  is  the  first
      ;;  string in the stream.
      ;;
      ;;* Every string in REVERSE-SEQUENCE represents a chunk of stream:
      ;;  the first char  in the string is the first  char in the chunk,
      ;;  the last char in the string is the last char in the chunk.
      ;;
      (define ($string-last-index str)
	($fxsub1 ($string-length str)))
      (let loop ((terminator.idx  ($string-last-index terminator))
		 (buffers         reverse-stream))
	(cond (($fx= -1 terminator.idx)
	       #t)
	      ((null? buffers)
	       #f)
	      ((let* ((buf     ($car buffers))
		      (buf.idx ($string-last-index buf)))
		 ($compare-string-tails terminator terminator.idx buf buf.idx))
	       => (lambda (terminator.idx)
		    (loop ($fxsub1 terminator.idx) ($cdr buffers))))
	      (else #f))))

    (define ($compare-string-tails A A.idx B B.idx)
      ;;Recursive function.   Compare the string A,  starting from index
      ;;A.idx  inclusive, to  the string  B, starting  from index  B.idx
      ;;inclusive.  If:
      ;;
      ;;* All the chars are equal  up to (zero? A.idx) included: return
      ;;  0.  An example of this case is a call with arguments:
      ;;
      ;;     A =    "345"	A.idx = 2
      ;;     B = "012345"	B.idx = 5
      ;;
      ;;  another example of this case:
      ;;
      ;;     A = "012345"	A.idx = 5
      ;;     B = "012345"	B.idx = 5
      ;;
      ;;* All the chars are equal  up to (zero?  B.idx) included: return
      ;;  the  value of A.idx referencing  the last compared char  in A.
      ;;  An example of this case is a call with arguments:
      ;;
      ;;     A = "012345"	A.idx = 5
      ;;     B =    "345"	B.idx = 2
      ;;
      ;;  the returned value is: A.idx == 3.
      ;;
      ;;*  Chars having  (positive?  A.idx)  and (positive?   B.idx) are
      ;;  different: return false.
      ;;
      (and ($fx= ($string-ref A A.idx)
		 ($string-ref B B.idx))
	   (cond (($fxzero? A.idx)
		  0)
		 (($fxzero? B.idx)
		  A.idx)
		 (else
		  ($compare-string-tails A ($fxsub1 A.idx)
					 B ($fxsub1 B.idx))))))

    #| end of module: %received-message-terminator? |# )

  #| end of module: channel-recv-message-portion! |# )


;;;; sending messages

(define (channel-send-begin! chan)
  ;;Configure a channel  to start sending a  message; return unspecified
  ;;values.  CHAN  must be an output  or input/output channel; it  is an
  ;;error if the channel is not inactive.
  ;;
  (define who 'channel-send-begin!)
  (with-arguments-validation (who)
      ((inactive-channel	chan)
       (output-channel		chan))
    ($channel-send-begin! chan)))

(define ($channel-send-begin! chan)
  ($channel-action-set!          chan 'send)
  ($channel-message-buffer-set!  chan '())
  ($channel-message-size-set!    chan 0)
  (void))

;;; --------------------------------------------------------------------

(define (channel-send-end! chan)
  ;;Finish sending a message by flushing the connect port and return the
  ;;total number of octets or chars sent.  It is an error if the channel
  ;;is not in the course of sending a message.
  ;;
  ;;After this function  is applied to a channel: the  channel itself is
  ;;configured  as  inactive; so  it  is  available to  start  receiving
  ;;another message or to send a message.
  ;;
  (define who 'channel-send-end!)
  (with-arguments-validation (who)
      ((sending-channel	chan))
    ($channel-send-end! chan)))

(define ($channel-send-end! chan)
  (begin0
      ($channel-message-size chan)
    (flush-output-port ($channel-connect-ou-port chan))
    ($channel-action-set!          chan #f)
    ($channel-message-buffer-set!  chan '())
    ($channel-message-size-set!    chan 0)))

;;; --------------------------------------------------------------------

(define (channel-send-message-portion! chan portion)
  ;;Send a portion  of output message through the  given channel; return
  ;;unspecified values.   It is an  error if the  channel is not  in the
  ;;course of sending a message.
  ;;
  ;;PORTION must be a bytevector representing the message portion.
  ;;
  ;;This function does not flush the connection port.
  ;;
  (define who 'channel-send-message-portion!)
  (define-argument-validation (portion who obj chan)
    (if (binary-channel? chan)
	(bytevector? obj)
      (string? obj))
    (assertion-violation who "expected appropriate message portion as argument" obj))
  (with-arguments-validation (who)
      ((sending-channel	chan)
       (portion		portion chan))
    ($channel-send-message-portion! chan portion)))

(define ($channel-send-message-portion! chan portion)
  (define who '$channel-send-message-portion!)
  ($channel-message-increment-size! chan (if (binary-channel? chan)
					     ($bytevector-length portion)
					   ($string-length portion)))
  (cond (($delivery-timeout-expired? chan)
	 (%error-message-delivery-timeout-expired who chan))
	(($maximum-size-exceeded? chan)
	 (%error-maximum-message-size-exceeded who chan))
	(else
	 (if (binary-channel? chan)
	     (put-bytevector ($channel-connect-ou-port chan) portion)
	   (put-string ($channel-connect-ou-port chan) portion)))))

;;; --------------------------------------------------------------------

(define (channel-send-full-message chan . message-portions)
  (define who 'channel-send-full-message)
  (with-arguments-validation (who)
      ((inactive-channel	chan)
       (output-channel		chan))
    ($channel-send-full-message chan message-portions)))

(define ($channel-send-full-message chan message-portions)
  ($channel-send-begin! chan)
  (for-each-in-order (lambda (portion)
		       ($channel-send-message-portion! chan portion))
    message-portions)
  ($channel-send-end! chan))


;;;; done

)

;;; end of file
