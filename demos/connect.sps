;;; -*- coding: utf-8-unix -*-
;;;
;;;Part of: Vicare Scheme
;;;Contents: demo program that connects to remote servers
;;;Date: Fri May 10, 2013
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
  (prefix (vicare posix)
	  px.)
  (prefix (vicare posix simple-event-loop)
	  px.)
  (prefix (vicare posix log-files)
	  log.))


;;;; global variables

;;An instance  of record  type "<global-options>" holding  global server
;;options configured from the command line.
;;
(define options
  (make-parameter #f))

;;; --------------------------------------------------------------------

(define-constant VERSION-NUMBER
  "0.1d0")

;;The exit status in case of "bad configuration option value".  It is to
;;be handed to EXIT.
;;
(define-constant BAD-OPTION-EXIT-STATUS 2)


;;;; main function

(module (main)

  (define (main argv)
    ;;We catch the exceptions to exit with an error status.  If we catch
    ;;an exception here: we cannot log a message because we have already
    ;;closed the log file.
    ;;
    ;;Log lines specific  to the raised error should be  output near the
    ;;cause  of the  error, where  we can  better explain  what we  were
    ;;doing.
    ;;
    (guard (E (else (exit 1)))
      ;;Set configuration  parameters; it is useless  to use PARAMETRISE
      ;;here.
      (options
       (guard (E (else
		  (error-message-and-exit 1 "parsing options: ~a" (condition-message E))))
	 (make-<global-options> argv)))
      (log.logging-enabled?	(options.log-file))
      (log.log-pathname		(options.log-file))
      (with-compensations
	(%main.open-logging)
	(%main.log-start-messages)
	(%main.enter-connection-procedure)
	(log.log "exiting CONNECT client"))
      ;;First get out of WITH-COMPENSATIONS, then exit.
      (exit 0)))

  (define (%main.open-logging)
    (guard (E (else
	       (fprintf (current-error-port)
			"connect.sps: error while opening log file: ~a\n"
			(if (condition-message? E)
			    (condition-message E)
			  "unknown error"))))
      (log.setup-compensated-log-file-creation)))

  (define (%main.log-start-messages)
    (let ((pid (px.getpid)))
      (log.log-prefix (format "vicare connect[~a]: " pid))
      (log.log "*** starting CONNECT client, pid=~a" pid)))

  (define (%main.enter-connection-procedure)
    ;;Catch the exceptions here to log the event: exit because of error.
    ;;Then raise again  the exception to run the  compensations and exit
    ;;with error code.
    ;;
    (import CLIENT-CONNECTION-PROCEDURE)
    (log.with-logging-handler
     (condition-message "exiting CONNECT client because of error: ~a")
     (enter-client-connect (options.server-interface)
			   (options.server-port)
			   (options.client-connect-config))))

  #| end of module: MAIN |# )


;;;; type definitions

;;Hold global server options configured from the command line.
;;
(define-record-type <global-options>
  (fields (mutable server-interface)
		;False or a string  representing the server interface to
		;connect to.  When false an error should be raised.
	  (mutable server-port)
		;False or an exact  integer representing the server port
		;to connect to.  When false an error should be raised.
	  (mutable log-file)
		;False or a string representing  the pathname of the log
		;file.   As  special case:  if  the  string is  "-"  log
		;messages should go to stderr.
	  (mutable client-connect-config)
		;ENUM-SET of type CLIENT-CONNECT-CONFIG.
	  (mutable verbosity)
		;An exact integer.  When zero: run the program silently;
		;this is the default.  When  a positive integer: run the
		;program  with  verbose   messages  at  the  appropriate
		;verbosity level.
	  )
  (protocol
   (lambda (maker)
     (lambda (argv)
       (import COMMAND-LINE-ARGS)
       (define-syntax-rule (%err ?template . ?args)
	 (error-message-and-exit BAD-OPTION-EXIT-STATUS ?template . ?args))
       (let ((self (maker #f #;interface #f #;port
			  #f #;log-file (server-loop-config)
			  0 #;verbosity )))
	 (parse-command-line-arguments self argv)

	 ;; validate client interface, more validation later
	 (let ((interface ($<global-options>-server-interface self)))
	   (unless (and (string? interface)
			(not (zero? (string-length interface))))
	     (%err "invalid server interface: \"~a\"" interface)))

	 ;; validate client port
	 (let ((port ($<global-options>-server-port self)))
	   (cond ((not (px.network-port-number? port))
		  (%err "invalid server port: \"~a\"" port))))

	 ;; validate log file
	 (let ((filename ($<global-options>-log-file self)))
	   (cond ((not filename)
		  (void))
		 ((not (string? filename))
		  (%err "internal error selecting log file pathname: ~a" filename))
		 ((string=? "-" filename)
		  ;;Log to the current error port.
		  (void))
		 ((zero? (string-length filename))
		  (%err "selected empty log file pathname"))
		 (else
		  (let ((filename (absolutise-pathname filename)))
		    (when (and (file-exists? filename)
			       (not (and (px.file-is-regular-file? filename)
					 (px.file-writable? filename))))
		      (%err "selected log file pathname not writable" filename))
		    (<global-options>-log-file-set! self filename)))))

	 self)))))

;;; --------------------------------------------------------------------

(define (<global-options>-increment-verbosity! opts)
  (<global-options>-verbosity-set! opts (+ +1 (<global-options>-verbosity opts))))

(define (<global-options>-decrement-verbosity! opts)
  (<global-options>-verbosity-set! opts (+ -1 (<global-options>-verbosity opts))))

;;; --------------------------------------------------------------------

(define (options.server-interface)
  ($<global-options>-server-interface (options)))

(define (options.server-port)
  ($<global-options>-server-port (options)))

(define (options.log-file)
  ;;Return  false if  logging  must  be disabled.   Return  a string  if
  ;;logging must be  enabled; the string represents the  pathname of the
  ;;log file; as special case: if  the string is "-" log messages should
  ;;go to stderr.
  ;;
  ($<global-options>-log-file (options)))

(define (options.verbosity)
  ($<global-options>-verbosity (options)))

(define (options.client-connect-config)
  ($<global-options>-client-connect-config (options)))


;;;; command line arguments parsing

(module COMMAND-LINE-ARGS
  (parse-command-line-arguments)
  (import (srfi :37 args-fold))

  (define (parse-command-line-arguments seed argv)
    (args-fold (cdr argv) program-options
	       unrecognised-option-proc
	       argument-processor
	       seed))

;;; --------------------------------------------------------------------

  (define-constant HELP-SCREEN
    "Usage: echod.sps [vicare options] -- [options]
Options:
   -I IFACE
   --interface IFACE
\tSelect the server interface to connect to.

   -P PORT
   --port PORT
\tSelect the server port to connect to (1...65535)

   --log-file /path/to/log-file
\tSelect the pathname for the log file.  Use \"-\" to log
\ton the error port.  When not given no log file is created.

   --recv-first
\tStart the client and expect the server to send the first
\tmessage.

   -V
   --version
\tPrint version informations and exit.

   --version-only
\tPrint version number only and exit.

   -v
   --verbose
\tPrint verbose messages.

   -h
   --help
\tPrint this help screen and exit.\n")

  (define-constant VERSION-SCREEN
    "Vicare CONNECT ~a\n\
     Copyright (C) 2013 Marco Maggi <marco.maggi-ipsu@poste.it>\n\
     This is free software; see the source for copying conditions.  There is NO\n\
     warranty; not even for MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.\n")

;;; --------------------------------------------------------------------

  (define (interface-option-processor option name operand seed)
    ;;Select the interface to bind to.  We will validate this later.
    ;;
    (<global-options>-server-interface-set! seed operand)
    seed)

  (define (port-option-processor option name operand seed)
    (let ((port (string->number operand)))
      (unless port
	(invalid-option-value name operand))
      (<global-options>-server-port-set! seed port))
    seed)

  (define (log-file-option-processor option name operand seed)
    (<global-options>-log-file-set! seed operand)
    seed)

  (define (recv-first-option-processor option name operand seed)
    (import CLIENT-CONNECTION-PROCEDURE)
    (<global-options>-client-connect-config-set!
     seed (enum-set-union
	   (client-connect-config recv-first)
	   (<global-options>-server-loop-config seed)))
    seed)

;;; --------------------------------------------------------------------
;;; auxiliary options

  (define (verbosity-option-processor option name operand seed)
    (<global-options>-increment-verbosity! seed)
    seed)

  (define (help-option-processor option name operand seed)
    (fprintf (current-error-port) HELP-SCREEN)
    (exit 0))

  (define (version-option-processor option name operand seed)
    (fprintf (current-error-port) VERSION-SCREEN VERSION-NUMBER)
    (exit 0))

  (define (version-only-option-processor option name operand seed)
    (fprintf (current-error-port) "~a\n" VERSION-NUMBER)
    (exit 0))

;;; --------------------------------------------------------------------
;;; options definition

  (define program-options
    ;;List of  options recognised by  this program.  The format  of each
    ;;option specification is:
    ;;
    ;;   names required-arg? optional-arg? option-proc
    ;;
    (list
     (option '(#\I "interface")	#t #f interface-option-processor)
     (option '(#\P "port")	#t #f port-option-processor)
     (option '("log-file")	#t #f log-file-option-processor)
     (option '("recv-first")	#t #f recv-first-option-processor)

     (option '("version-only")	#f #f version-only-option-processor)
     (option '(#\V "version")	#f #f version-option-processor)
     (option '(#\v "verbose")	#f #f verbosity-option-processor)
     (option '(#\h "help")	#f #f help-option-processor)
     ))

;;; --------------------------------------------------------------------
;;; helper functions

  (define (argument-processor operand seed)
    (%err "invalid command line argument: ~a" operand))

  (define (invalid-option-value option value)
    (%err "invalid value for option \"~a\": ~a" option value))

  (define (unrecognised-option-proc option name arg seed)
    (%err "unknown command line option: ~a" name))

  (define-syntax-rule (%err ?template . ?args)
    (error-message-and-exit BAD-OPTION-EXIT-STATUS ?template . ?args))

  #| end of module: COMMAND-LINE-ARGS |#)


;;;; server events loop

(module CLIENT-CONNECTION-PROCEDURE
  (enter-client-connect client-connect-option client-connect-config)

  (define-enumeration client-connect-option
    (recv-first
		;Start  the client  and expect  the server  to send  the
		;first message.
     )
    client-connect-config)

  (define (enter-client-connect interface port options-set)
    ;;To be called  by the main client function.  Connect  to the server
    ;;and enter  the dialogue.  This  function returns when  the process
    ;;must be exited.
    ;;
    ;;Given  a  string INTERFACE  representing  a  network interface  to
    ;;connect to  and a network  PORT number: create the  client socket,
    ;;connect  to the  server, enter  the dialogue.   Return unspecified
    ;;values.
    ;;
    ;;INTERFACE must  be a string  representing the server  interface to
    ;;connect to; for example "localhost".
    ;;
    ;;PORT  must be  an exact  integer representing  the server  port to
    ;;connect to; for example 8081.
    ;;
    ;;OPTIONS-SET must be an  ENUM-SET of type CLIENT-CONNECT-OPTION; it
    ;;is used to configure the client connection.
    ;;
    (import INTERPROCESS-SIGNALS)
    (with-compensations
      (initialise-signal-handlers)
      (log.log "connecting to: ~a:~a" interface port)
      (letrec
	  ((client-port (log.with-logging-handler
			    (condition-message "while creating client socket: ~a")
			  (compensate
			      (px.tcp-connect interface port)
			    (with
			     (close-port client-port))))))

	(if (%config.recv-first? options-set)
	    (sel.readable client-port
			  (lambda ()
			    (proto.start-recv-session port)))
	  (sel.writable client-port
			(lambda ()
			  (proto.start-send-session port))))
	;;We return  from this  form only  when it is  time to  exit the
	;;process.
	(sel.enter)))
    (void))

  (define (%config.recv-first? options-set)
    (enum-set-member? (server-loop-option recv-first) options-set))

  #| end of module: SERVER-EVENTS-LOOP |# )


;;;; CONNECT client

(module CONNECT-CLIENT
  (proto.start-session)
  (import (prefix (vicare net channels) chan.))

  (define (proto.start-recv-session port)
    (log.with-logging-handler
	(condition-message "while starting session: ~a")
      (define connection-id
	(gensym->unique-string (gensym)))
      #f))

  (define (proto.start-send-session port)
    (log.with-logging-handler
	(condition-message "while starting session: ~a")
      (define connection-id
	(gensym->unique-string (gensym)))
      (%log-accepted-connection client-address connection-id)
      (let ((chan (chan.open-input/output-channel server-port)))
	(chan.channel-set-message-terminators! chan '(#ve(ascii "\r\n") #ve(ascii "\n")))
	(chan.channel-recv-begin! chan)
	(%process-incoming-data server-port chan connection-id))))

  (define (%process-incoming-data server-port chan connection-id)
    (define (%reschedule)
      (sel.readable server-port
		    (lambda ()
		      (%process-incoming-data server-port chan connection-id))
		    (time-from-now (make-time 5 0))
		    (lambda ()
		      (log.log "connection ~a expired" connection-id)
		      (%stop-session connection-id server-port chan))))
    (log.with-logging-handler
	(condition-message "while processing incoming data: ~a")
      (cond ((chan.channel-recv-message-portion! chan)
	     => (lambda (dummy)
		  (let* ((data.bv  (chan.channel-recv-end! chan))
			 (data.str (utf8->string data.bv)))
		    (log.log "connection ~a echoing: ~a"
			     connection-id (ascii->string (uri-encode data.bv)))
		    (%send-message chan (list #ve(ascii "echo> ") data.bv))
		    (if (%received-quit? data.bv)
			(%stop-session connection-id server-port chan)
		      (begin
			(chan.channel-recv-begin! chan)
			(%reschedule))))))
	    (else
	     (%reschedule)))))

  (define (%stop-session connection-id server-port chan)
    (log.log "closing connection ~a" connection-id)
    (chan.close-channel chan)
    (net.close-server-port server-port))

  (define (%send-message chan data)
    ;;Send the list  of bytevectors DATA through the  channel; perform a
    ;;full send operation.  Return unspecified values.
    ;;
    (chan.channel-send-begin! chan)
    (for-each-in-order
	(lambda (bv)
	  (chan.channel-send-message-portion! chan bv))
      data)
    (chan.channel-send-end! chan))

  (define (%received-quit? bv)
    ;;We know that the last bytes of BV must represent \n or \r\n.
    ;;
    (let ((bv.len (bytevector-length bv)))
      (cond ((and (fx<= 2 bv.len)
		  (fx=? (char->integer #\return)
			(bytevector-u8-ref bv (fx- bv.len 2)))
		  (fx=? (char->integer #\newline)
			(bytevector-u8-ref bv (fx- bv.len 1))))
	     (bytevector=? bv #ve(ascii "quit\r\n")))
	    ((and (fx<= 1 bv.len)
		  (fx=? (char->integer #\newline)
			(bytevector-u8-ref bv (fx- bv.len 1))))
	     (bytevector=? bv #ve(ascii "quit\n")))
	    (else #f))))

  #| end of module: ECHO-SERVER |# )


;;;; interprocess signal handlers

(module INTERPROCESS-SIGNALS
  (initialise-signal-handlers)

  (define (initialise-signal-handlers)
    (sel.receive-signal SIGTERM %sigterm-handler)
    (sel.receive-signal SIGQUIT %sigquit-handler)
    (sel.receive-signal SIGINT  %sigint-handler)
    (sel.receive-signal SIGTSTP %sigtstp-handler)
    (sel.receive-signal SIGCONT %sigcont-handler)
    (sel.receive-signal SIGUSR1 %sigusr1-handler)
    (sel.receive-signal SIGUSR2 %sigusr2-handler))

  (define (%sigterm-handler)
    (sel.receive-signal SIGTERM %sigterm-handler)
    (log.log "received SIGTERM")
    (sel.leave-asap))

  (define (%sigquit-handler)
    ;;SIGQUIT comes from Ctrl-\.  The documentation of the GNU C Library
    ;;has this to say about SIGQUIT:
    ;;
    ;;   The SIGQUIT  signal  is  similar to  SIGINT,  except that  it's
    ;;  controlled by  a different key and produces a  core dump when it
    ;;  terminates the  process, just like a program  error signal.  You
    ;;  can think of this as a program error condition "detected" by the
    ;;  user.
    ;;
    ;;  Certain kinds of cleanups  are best omitted in handling SIGQUIT.
    ;;  For example,  if the program creates temporary  files, it should
    ;;  handle the other termination  requests by deleting the temporary
    ;;  files.  But it is better for SIGQUIT not to delete them, so that
    ;;  the user can examine them in conjunction with the core dump.
    ;;
    (sel.receive-signal SIGQUIT %sigquit-handler)
    (log.log "received SIGQUIT")
    (sel.leave-asap))

  (define (%sigint-handler)
    ;;SIGINT comes from Ctrl-C.
    (sel.receive-signal SIGINT %sigint-handler)
    (log.log "received SIGINT")
    (sel.leave-asap))

  (define (%sigtstp-handler)
    ;;SIGTSTP  comes from  Ctrl-Z.   We should  put  some process  state
    ;;suspension  finalisation   in  this  handler.   Finally   we  send
    ;;ourselves a SIGSTOP to suspend the process.
    (log.with-logging-handler
	(condition-message "error in SIGTSTP handler: ~a")
      (sel.receive-signal SIGTSTP %sigtstp-handler)
      (log.log "received SIGTSTP")
      (px.kill (px.getpid) SIGSTOP)))

  (define (%sigcont-handler)
    ;;SIGCONT comes from the controlling process and allows us to resume
    ;;the program.  We should put some process state reinitialisation in
    ;;this handler.
    (log.with-logging-handler
	(condition-message "error in SIGCONT handler: ~a")
      (sel.receive-signal SIGCONT %sigcont-handler)
      (log.log "received SIGCONT")))

  (define (%sigusr1-handler)
    ;;SIGUSR1  is  explicitly  sent  by  someone  to  perform  a  custom
    ;;procedure.
    ;;
    (log.with-logging-handler
	(condition-message "error in SIGUSR1 handler: ~a")
      (sel.receive-signal SIGUSR1 %sigusr1-handler)
      (log.log "received SIGUSR1")))

  (define (%sigusr2-handler)
    ;;SIGUSR2  is  explicitly  sent  by  someone  to  perform  a  custom
    ;;procedure.
    ;;
    (log.with-logging-handler
	(condition-message "error in SIGUSR2 handler: ~a")
      (sel.receive-signal SIGUSR2 %sigusr2-handler)
      (log.log "received SIGUSR2")))

  #| end of module: INTERPROCESS-SIGNALS |# )


;;;; printing helpers

(define (debug-print . args)
  ;;This is for debugging purposes.
  ;;
  (pretty-print args (current-error-port)))

(module (verbose-message error-message-and-exit)

  (define (verbose-message requested-level template . args)
    (when (<= (options.verbosity) requested-level)
      (%format-and-print (current-error-port) template args)))

  (define (error-message-and-exit exit-status template . args)
    (%format-and-print (current-error-port) template args)
    (exit exit-status))

;;; --------------------------------------------------------------------

  (define (%format-and-print port template args)
    (fprintf port "vicare echod: ")
    (apply fprintf port template args)
    (newline port)
    (flush-output-port port))

  #| end of module |# )


;;;; helpers

(define (absolutise-pathname pathname)
  (if (char=? #\/ (string-ref pathname 0))
      pathname
    (string-append (px.getcwd) pathname)))


;;;; done

(main (command-line))

;;; end of file
;; Local Variables:
;; eval: (put 'log.with-logging-handler 'scheme-indent-function 1)
;; End:
