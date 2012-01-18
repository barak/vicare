;;;Ikarus Scheme -- A compiler for R6RS Scheme.
;;;Copyright (C) 2011, 2012 Marco Maggi <marco.maggi-ipsu@poste.it>
;;;Copyright (C) 2006,2007,2008  Abdulaziz Ghuloum
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


(library (ikarus.posix)
  (export
    ;; errno and h_errno codes handling
    errno->string			h_errno->string
    strerror				h_strerror

    ;; interprocess singnal codes handling
    interprocess-signal->string

    ;; system environment variables
    getenv				setenv
    unsetenv
    environ				environ-table
    environ->table			table->environ

    ;; process identifier
    getpid				getppid

    ;; executing processes
    fork				system
    execv				execve
    execl				execle
    execvp				execlp

    ;; process exit status
    waitpid				wait
    WIFEXITED				WEXITSTATUS
    WIFSIGNALED				WTERMSIG
    WCOREDUMP				WIFSTOPPED
    WSTOPSIG

    ;; interprocess signals
    raise-signal			kill
    pause

    ;; file system inspection
    stat				lstat
    fstat
    make-struct-stat			struct-stat?
    struct-stat-st_mode			struct-stat-st_ino
    struct-stat-st_dev			struct-stat-st_nlink
    struct-stat-st_uid			struct-stat-st_gid
    struct-stat-st_size
    struct-stat-st_atime		struct-stat-st_atime_usec
    struct-stat-st_mtime		struct-stat-st_mtime_usec
    struct-stat-st_ctime		struct-stat-st_ctime_usec
    struct-stat-st_blocks		struct-stat-st_blksize

    file-is-directory?			file-is-char-device?
    file-is-block-device?		file-is-regular-file?
    file-is-symbolic-link?		file-is-socket?
    file-is-fifo?			file-is-message-queue?
    file-is-semaphore?			file-is-shared-memory?

    access				file-readable?
    file-writable?			file-executable?
    file-atime				file-ctime
    file-mtime
    file-size				file-exists?

    S_ISDIR				S_ISCHR
    S_ISBLK				S_ISREG
    S_ISLNK				S_ISSOCK
    S_ISFIFO

    ;; file system muators
    chown				fchown
    chmod				fchmod
    umask				getumask
    utime				utimes
    lutimes				futimes

    ;; hard and symbolic links
    link				symlink
    readlink				readlink/string
    realpath				realpath/string
    delete-file				unlink
    posix-remove			rename

    ;; file system directories
    mkdir				mkdir/parents
    rmdir
    getcwd				getcwd/string
    chdir				fchdir
    opendir				fdopendir
    readdir				readdir/string
    closedir				rewinddir
    telldir				seekdir

    make-directory-stream		directory-stream?
    directory-stream-pathname		directory-stream-pointer
    directory-stream-fd			directory-stream-closed?

    split-file-name

    ;; file descriptors
    open				close
    posix-read				pread
    posix-write				pwrite
    lseek
    readv				writev
    select				select-fd
    fcntl				ioctl
    dup					dup2
    pipe				mkfifo

    ;; sockets
    make-sockaddr_un
    sockaddr_un.pathname		sockaddr_un.pathname/string
    make-sockaddr_in			make-sockaddr_in6
    sockaddr_in.in_addr			sockaddr_in6.in6_addr
    sockaddr_in.in_port			sockaddr_in6.in6_port
    in6addr_loopback			in6addr_any
    inet-aton				inet-ntoa
    inet-pton				inet-ntop
    inet-ntoa/string			inet-ntop/string
    gethostbyname			gethostbyname2
    gethostbyaddr			host-entries
    getaddrinfo				gai-strerror
    getprotobyname			getprotobynumber
    getservbyname			getservbyport
    protocol-entries			service-entries
    socket				shutdown
    socketpair
    connect				listen
    accept				bind
    getpeername				getsockname
    send				recv
    sendto				recvfrom
    setsockopt				getsockopt
    setsockopt/int			getsockopt/int
    setsockopt/size_t			getsockopt/size_t
    setsockopt/linger			getsockopt/linger
    getnetbyname			getnetbyaddr
    network-entries

    make-struct-hostent			struct-hostent?
    struct-hostent-h_name		struct-hostent-h_aliases
    struct-hostent-h_addrtype		struct-hostent-h_length
    struct-hostent-h_addr_list		struct-hostent-h_addr

    make-struct-addrinfo		struct-addrinfo?
    struct-addrinfo-ai_flags		struct-addrinfo-ai_family
    struct-addrinfo-ai_socktype		struct-addrinfo-ai_protocol
    struct-addrinfo-ai_addrlen		struct-addrinfo-ai_addr
    struct-addrinfo-ai_canonname

    make-struct-protoent		struct-protoent?
    struct-protoent-p_name		struct-protoent-p_aliases
    struct-protoent-p_proto

    make-struct-servent			struct-servent?
    struct-servent-s_name		struct-servent-s_aliases
    struct-servent-s_port		struct-servent-s_proto

    make-struct-netent			struct-netent?
    struct-netent-n_name		struct-netent-n_aliases
    struct-netent-n_addrtype		struct-netent-n_net

    ;; users and groups
    getuid				getgid
    geteuid				getegid
    getgroups
    seteuid				setuid
    setegid				setgid
    setreuid				setregid
    getlogin				getlogin/string
    getpwuid				getpwnam
    getgrgid				getgrnam
    user-entries			group-entries

    make-struct-passwd			struct-passwd?
    struct-passwd-pw_name		struct-passwd-pw_passwd
    struct-passwd-pw_uid		struct-passwd-pw_gid
    struct-passwd-pw_gecos		struct-passwd-pw_dir
    struct-passwd-pw_shell

    make-struct-group			struct-group?
    struct-group-gr_name		struct-group-gr_gid
    struct-group-gr_mem

    ;; job control
    ctermid				ctermid/string
    setsid				getsid
    getpgrp				setpgid
    tcgetpgrp				tcsetpgrp
    tcgetsid

    ;; date and time functions
    clock				times
    posix-time				gettimeofday
    localtime				gmtime
    timelocal				timegm
    strftime				strftime/string
    nanosleep

    make-struct-timeval			struct-timeval?
    struct-timeval-tv_sec		struct-timeval-tv_usec

    make-struct-timespec		struct-timespec?
    struct-timespec-tv_sec		struct-timespec-tv_nsec

    make-struct-tms			struct-tms?
    struct-tms-tms_utime		struct-tms-tms_stime
    struct-tms-tms_cutime		struct-tms-tms_cstime

    make-struct-tm			struct-tm?
    struct-tm-tm_sec			struct-tm-tm_min
    struct-tm-tm_hour			struct-tm-tm_mday
    struct-tm-tm_mon			struct-tm-tm_year
    struct-tm-tm_wday			struct-tm-tm_yday
    struct-tm-tm_isdst			struct-tm-tm_gmtoff
    struct-tm-tm_zone

    ;; miscellaneous functions
    file-descriptor?)
  (import (except (ikarus)
		  ;; errno and h_errno codes handling
		  errno->string			h_errno->string
		  strerror			h_strerror

		  ;; interprocess singnal codes handling
		  interprocess-signal->string

		  ;; system environment variables
		  getenv			setenv
		  unsetenv
		  environ			environ-table
		  environ->table		table->environ

		  ;; process identifier
		  getpid			getppid

		  ;; executing processes
		  fork				system
		  execv				execve
		  execl				execle
		  execvp			execlp

		  ;; process exit status
		  waitpid			wait
		  WIFEXITED			WEXITSTATUS
		  WIFSIGNALED			WTERMSIG
		  WCOREDUMP			WIFSTOPPED
		  WSTOPSIG

		  ;; interprocess signals
		  raise-signal			kill
		  pause

		  ;; file system inspection
		  stat				lstat
		  fstat
		  make-struct-stat		struct-stat?
		  struct-stat-st_mode		struct-stat-st_ino
		  struct-stat-st_dev		struct-stat-st_nlink
		  struct-stat-st_uid		struct-stat-st_gid
		  struct-stat-st_size
		  struct-stat-st_atime		struct-stat-st_atime_usec
		  struct-stat-st_mtime		struct-stat-st_mtime_usec
		  struct-stat-st_ctime		struct-stat-st_ctime_usec
		  struct-stat-st_blocks		struct-stat-st_blksize

		  file-is-directory?		file-is-char-device?
		  file-is-block-device?		file-is-regular-file?
		  file-is-symbolic-link?	file-is-socket?
		  file-is-fifo?			file-is-message-queue?
		  file-is-semaphore?		file-is-shared-memory?
		  access			file-readable?
		  file-writable?		file-executable?
		  file-ctime			file-mtime
		  file-atime
		  file-size			file-exists?

		  S_ISDIR			S_ISCHR
		  S_ISBLK			S_ISREG
		  S_ISLNK			S_ISSOCK
		  S_ISFIFO

		  ;; file system muators
		  chown				fchown
		  chmod				fchmod
		  umask				getumask
		  utime				utimes
		  lutimes			futimes

		  ;; hard and symbolic links
		  link				symlink
		  readlink			readlink/string
		  realpath			realpath/string
		  delete-file			unlink
		  posix-remove			rename

		  ;; file system directories
		  mkdir				mkdir/parents
		  rmdir
		  getcwd			getcwd/string
		  chdir				fchdir
		  opendir			fdopendir
		  readdir			readdir/string
		  closedir			rewinddir
		  telldir			seekdir

		  make-directory-stream		directory-stream?
		  directory-stream-pathname	directory-stream-pointer
		  directory-stream-fd		directory-stream-closed?

		  split-file-name

		  ;; file descriptors
		  open				close
		  posix-read			pread
		  posix-write			pwrite
		  lseek
		  readv				writev
		  select			select-fd
		  fcntl				ioctl
		  dup				dup2
		  pipe				mkfifo

		  ;; sockets
		  make-sockaddr_un
		  sockaddr_un.pathname		sockaddr_un.pathname/string
		  make-sockaddr_in		make-sockaddr_in6
		  sockaddr_in.in_addr		sockaddr_in6.in6_addr
		  sockaddr_in.in_port		sockaddr_in6.in6_port
		  in6addr_loopback		in6addr_any
		  inet-aton			inet-ntoa
		  inet-pton			inet-ntop
		  inet-ntoa/string		inet-ntop/string
		  gethostbyname			gethostbyname2
		  gethostbyaddr			host-entries
		  getaddrinfo			gai-strerror
		  getprotobyname		getprotobynumber
		  getservbyname			getservbyport
		  protocol-entries		service-entries
		  socket			shutdown
		  socketpair
		  connect			listen
		  accept			bind
		  getpeername			getsockname
		  send				recv
		  sendto			recvfrom
		  setsockopt			getsockopt
		  setsockopt/int		getsockopt/int
		  setsockopt/size_t		getsockopt/size_t
		  setsockopt/linger		getsockopt/linger
		  getnetbyname			getnetbyaddr
		  network-entries

		  make-struct-hostent		struct-hostent?
		  struct-hostent-h_name		struct-hostent-h_aliases
		  struct-hostent-h_addrtype	struct-hostent-h_length
		  struct-hostent-h_addr_list	struct-hostent-h_addr

		  make-struct-addrinfo		struct-addrinfo?
		  struct-addrinfo-ai_flags	struct-addrinfo-ai_family
		  struct-addrinfo-ai_socktype	struct-addrinfo-ai_protocol
		  struct-addrinfo-ai_addrlen	struct-addrinfo-ai_addr
		  struct-addrinfo-ai_canonname

		  make-struct-protoent		struct-protoent?
		  struct-protoent-p_name	struct-protoent-p_aliases
		  struct-protoent-p_proto

		  make-struct-servent		struct-servent?
		  struct-servent-s_name		struct-servent-s_aliases
		  struct-servent-s_port		struct-servent-s_proto

		  make-struct-netent		struct-netent?
		  struct-netent-n_name		struct-netent-n_aliases
		  struct-netent-n_addrtype	struct-netent-n_net

		  ;; users and groups
		  getuid			getgid
		  geteuid			getegid
		  getgroups
		  seteuid			setuid
		  setegid			setgid
		  setreuid			setregid
		  getlogin			getlogin/string
		  getpwuid			getpwnam
		  getgrgid			getgrnam
		  user-entries			group-entries

		  make-struct-passwd		struct-passwd?
		  struct-passwd-pw_name		struct-passwd-pw_passwd
		  struct-passwd-pw_uid		struct-passwd-pw_gid
		  struct-passwd-pw_gecos	struct-passwd-pw_dir
		  struct-passwd-pw_shell

		  make-struct-group		struct-group?
		  struct-group-gr_name		struct-group-gr_gid
		  struct-group-gr_mem

		  ;; job control
		  ctermid			ctermid/string
		  setsid			getsid
		  getpgrp			setpgid
		  tcgetpgrp			tcsetpgrp
		  tcgetsid

		  ;; date and time functions
		  clock				times
		  posix-time			gettimeofday
		  localtime			gmtime
		  timelocal			timegm
		  strftime			strftime/string
		  nanosleep

		  make-struct-timeval		struct-timeval?
		  struct-timeval-tv_sec		struct-timeval-tv_usec

		  make-struct-timespec		struct-timespec?
		  struct-timespec-tv_sec	struct-timespec-tv_nsec

		  make-struct-tms		struct-tms?
		  struct-tms-tms_utime		struct-tms-tms_stime
		  struct-tms-tms_cutime		struct-tms-tms_cstime

		  make-struct-tm		struct-tm?
		  struct-tm-tm_sec		struct-tm-tm_min
		  struct-tm-tm_hour		struct-tm-tm_mday
		  struct-tm-tm_mon		struct-tm-tm_year
		  struct-tm-tm_wday		struct-tm-tm_yday
		  struct-tm-tm_isdst		struct-tm-tm_gmtoff
		  struct-tm-tm_zone

		  ;; miscellaneous functions
		  file-descriptor?)
    (rename (only (ikarus system $pointers)
		  $pointer?)
	    ($pointer? pointer?))
    (vicare syntactic-extensions)
    (vicare platform-constants)
    (prefix (vicare unsafe-capi)
	    capi.)
    (prefix (vicare unsafe-operations)
	    unsafe.)
    (vicare words))


;;;; helpers

(define-inline (%file-descriptor? obj)
  ;;Do  what  is  possible   to  recognised  fixnums  representing  file
  ;;descriptors.
  ;;
  (and (fixnum? obj)
       (unsafe.fx>= obj 0)
       (unsafe.fx<  obj FD_SETSIZE)))

(define-inline (%platform-int? obj)
  (and (or (fixnum? obj) (bignum? obj))
       (<= INT_MIN obj INT_MAX)))

(define-inline (%platform-size_t? obj)
  (and (or (fixnum? obj) (bignum? obj))
       (<= 0 obj SIZE_T_MAX)))


;;;; arguments validation

(define-argument-validation (procedure who obj)
  (procedure? obj)
  (assertion-violation who "expected procedure as argument" obj))

(define-argument-validation (boolean who obj)
  (boolean? obj)
  (assertion-violation who "expected boolean as argument" obj))

(define-argument-validation (fixnum who obj)
  (fixnum? obj)
  (assertion-violation who "expected fixnum as argument" obj))

(define-argument-validation (string who obj)
  (string? obj)
  (assertion-violation who "expected string as argument" obj))

(define-argument-validation (bytevector who obj)
  (bytevector? obj)
  (assertion-violation who "expected bytevector as argument" obj))

;;; --------------------------------------------------------------------

(define-argument-validation (fixnum/false who obj)
  (or (not obj) (fixnum? obj))
  (assertion-violation who "expected false or fixnum as argument" obj))

(define-argument-validation (boolean/fixnum who obj)
  (or (fixnum? obj) (boolean? obj))
  (assertion-violation who "expected boolean or fixnum as argument" obj))

(define-argument-validation (fixnum/pointer/false who obj)
  (or (not obj) (fixnum? obj) (pointer? obj))
  (assertion-violation who "expected false, fixnum or pointer as argument" obj))

(define-argument-validation (exact-integer who obj)
  (or (fixnum? obj) (bignum? obj))
  (assertion-violation who "expected exact integer as argument" obj))

(define-argument-validation (list-of-strings who obj)
  (and (list? obj) (for-all string? obj))
  (assertion-violation who "expected list of strings as argument" obj))

(define-argument-validation (list-of-bytevectors who obj)
  (and (list? obj) (for-all bytevector? obj))
  (assertion-violation who "expected list of bytevectors as argument" obj))

(define-argument-validation (string/bytevector who obj)
  (or (string? obj) (bytevector? obj))
  (assertion-violation who "expected string or bytevector as argument" obj))

(define-argument-validation (string/bytevector/false who obj)
  (or (not obj) (string? obj) (bytevector? obj))
  (assertion-violation who "expected false, string or bytevector as argument" obj))

;;; --------------------------------------------------------------------

(define-argument-validation (pid who obj)
  (fixnum? obj)
  (assertion-violation who "expected fixnum pid as argument" obj))

(define-argument-validation (gid who obj)
  (fixnum? obj)
  (assertion-violation who "expected fixnum gid as argument" obj))

(define-argument-validation (file-descriptor who obj)
  (%file-descriptor? obj)
  (assertion-violation who "expected fixnum file descriptor as argument" obj))

(define-argument-validation (signal who obj)
  (fixnum? obj)
  (assertion-violation who "expected fixnum signal code as argument" obj))

(define-argument-validation (pathname who obj)
  (or (bytevector? obj) (string? obj))
  (assertion-violation who "expected string or bytevector as pathname argument" obj))

(define-argument-validation (struct-stat who obj)
  (struct-stat? obj)
  (assertion-violation who "expected struct stat instance as argument" obj))

(define-argument-validation (secs who obj)
  (word-u32? obj)
  (assertion-violation who
    "expected exact integer in the range [0, 2^32-1] as seconds count argument" obj))

(define-argument-validation (nsecs who obj)
  (and (word-u32? obj)
       (<= 0 obj 999999999))
;;;              987654321
  (assertion-violation who
    "expected exact integer in the range [0, 999999999] as nanoseconds count argument" obj))

(define-argument-validation (secfx who obj)
  (and (fixnum? obj) (unsafe.fx<= 0 obj))
  (assertion-violation who "expected non-negative fixnum as seconds count argument" obj))

(define-argument-validation (usecfx who obj)
  (and (fixnum? obj)
       (unsafe.fx>= obj 0)
       (unsafe.fx<= obj 999999))
  (assertion-violation who "expected non-negative fixnum as nanoseconds count argument" obj))

(define-argument-validation (directory-stream who obj)
  (directory-stream? obj)
  (assertion-violation who "expected directory stream as argument" obj))

(define-argument-validation (open-directory-stream who obj)
  (not (directory-stream-closed? obj))
  (assertion-violation who "expected open directory stream as argument" obj))

(define-argument-validation (dirpos who obj)
  (and (or (fixnum? obj) (bignum? obj))
       (<= 0 obj))
  (assertion-violation who
    "expected non-negative exact integer as directory stream position argument" obj))

(define-argument-validation (offset who obj)
  (and (or (fixnum? obj) (bignum? obj))
       (<= 0 obj))
  (assertion-violation who
    "expected non-negative exact integer as offset argument" obj))

(define-argument-validation (false/fd who obj)
  (or (not obj) (%file-descriptor? obj))
  (assertion-violation who "expected false or file descriptor as argument" obj))

(define-argument-validation (list-of-fds who obj)
  (and (list? obj)
       (for-all (lambda (fd)
		  (%file-descriptor? fd))
	 obj))
  (assertion-violation who "expected list of file descriptors as argument" obj))

(define-argument-validation (af-inet who obj)
  (and (fixnum? obj)
       (or (unsafe.fx= obj AF_INET)
	   (unsafe.fx= obj AF_INET6)))
  (assertion-violation who "expected a fixnum among AF_INET and AF_INET6 as argument" obj))

(define-argument-validation (addrinfo/false who obj)
  (or (not obj) (struct-addrinfo? obj))
  (assertion-violation who "expected an instance of struct-addrinfo as argument" obj))

(define-argument-validation (netaddr who obj)
  (or (fixnum? obj) (bignum? obj)
      (and (bytevector? obj)
	   (= 4 (bytevector-length obj))))
  (assertion-violation who
    "expected exact integer or 32-bit bytevector as network address argument" obj))

(define-argument-validation (platform-int/boolean who obj)
  (or (boolean? obj) (%platform-int? obj))
  (assertion-violation who
    "expected exact integer in platform's \"int\" range as argument" obj))

(define-argument-validation (platform-size_t who obj)
  (%platform-size_t? obj)
  (assertion-violation who
    "expected exact integer in platform's \"size_t\" range as argument" obj))

(define-argument-validation (struct-tm who obj)
  (struct-tm? obj)
  (assertion-violation who "expected instance of struct-tm as argument" obj))


;;;; errors handling

(define (strerror errno)
  (define who 'strerror)
  (with-arguments-validation (who)
      ((boolean/fixnum  errno))
    (if errno
	(if (boolean? errno)
	    "unknown errno code (#t)"
	  (let ((msg (capi.posix-strerror errno)))
	    (if msg
		(string-append (errno->string errno) ": " (utf8->string msg))
	      (string-append "unknown errno code " (number->string (- errno))))))
      "no error")))

(define (raise-errno-error who errno . irritants)
  (raise (condition
	  (make-error)
	  (make-errno-condition errno)
	  (make-who-condition who)
	  (make-message-condition (strerror errno))
	  (make-irritants-condition irritants))))

(define (raise-errno-error/filename who errno filename . irritants)
  (raise (condition
	  (make-error)
	  (make-errno-condition errno)
	  (make-who-condition who)
	  (make-message-condition (strerror errno))
	  (make-i/o-filename-error filename)
	  (make-irritants-condition irritants))))

(define (raise-h_errno-error who h_errno . irritants)
  (raise (condition
	  (make-error)
	  (make-h_errno-condition h_errno)
	  (make-who-condition who)
	  (make-message-condition (h_strerror h_errno))
	  (make-irritants-condition irritants))))

(define (raise-posix-error who message . irritants)
  (raise (condition
	  (make-error)
	  (make-who-condition who)
	  (make-message-condition message)
	  (make-irritants-condition irritants))))


;;;; errno handling

(define (errno->string negated-errno-code)
  ;;Convert   an   errno   code    as   represented   by   the   (vicare
  ;;platform-constants)  library into  a string  representing  the errno
  ;;code symbol.
  ;;
  (define who 'errno->string)
  (with-arguments-validation (who)
      ((fixnum negated-errno-code))
    (let ((errno-code (unsafe.fx- 0 negated-errno-code)))
      (and (unsafe.fx> errno-code 0)
	   (unsafe.fx< errno-code (vector-length ERRNO-VECTOR))
	   (vector-ref ERRNO-VECTOR errno-code)))))

(let-syntax
    ((make-errno-vector
      (lambda (stx)
	(define (%mk-vector)
	  (let* ((max	(fold-left (lambda (max pair)
				     (let ((code (cdr pair)))
				       (cond ((not code)
					      max)
					     ((< max (fx- code))
					      (fx- code))
					     (else
					      max))))
			  0 errno-alist))
		 (vec.len	(fx+ 1 max))
		 ;;All the unused positions are set to #f.
		 (vec	(make-vector vec.len #f)))
	    (for-each (lambda (pair)
			(when (cdr pair)
			  (vector-set! vec (fx- (cdr pair)) (car pair))))
	      errno-alist)
	    vec))
	(define errno-alist
	  `(("E2BIG"		. ,E2BIG)
	    ("EACCES"		. ,EACCES)
	    ("EADDRINUSE"	. ,EADDRINUSE)
	    ("EADDRNOTAVAIL"	. ,EADDRNOTAVAIL)
	    ("EADV"		. ,EADV)
	    ("EAFNOSUPPORT"	. ,EAFNOSUPPORT)
	    ("EAGAIN"		. ,EAGAIN)
	    ("EALREADY"		. ,EALREADY)
	    ("EBADE"		. ,EBADE)
	    ("EBADF"		. ,EBADF)
	    ("EBADFD"		. ,EBADFD)
	    ("EBADMSG"		. ,EBADMSG)
	    ("EBADR"		. ,EBADR)
	    ("EBADRQC"		. ,EBADRQC)
	    ("EBADSLT"		. ,EBADSLT)
	    ("EBFONT"		. ,EBFONT)
	    ("EBUSY"		. ,EBUSY)
	    ("ECANCELED"	. ,ECANCELED)
	    ("ECHILD"		. ,ECHILD)
	    ("ECHRNG"		. ,ECHRNG)
	    ("ECOMM"		. ,ECOMM)
	    ("ECONNABORTED"	. ,ECONNABORTED)
	    ("ECONNREFUSED"	. ,ECONNREFUSED)
	    ("ECONNRESET"	. ,ECONNRESET)
	    ("EDEADLK"		. ,EDEADLK)
	    ("EDEADLOCK"	. ,EDEADLOCK)
	    ("EDESTADDRREQ"	. ,EDESTADDRREQ)
	    ("EDOM"		. ,EDOM)
	    ("EDOTDOT"		. ,EDOTDOT)
	    ("EDQUOT"		. ,EDQUOT)
	    ("EEXIST"		. ,EEXIST)
	    ("EFAULT"		. ,EFAULT)
	    ("EFBIG"		. ,EFBIG)
	    ("EHOSTDOWN"	. ,EHOSTDOWN)
	    ("EHOSTUNREACH"	. ,EHOSTUNREACH)
	    ("EIDRM"		. ,EIDRM)
	    ("EILSEQ"		. ,EILSEQ)
	    ("EINPROGRESS"	. ,EINPROGRESS)
	    ("EINTR"		. ,EINTR)
	    ("EINVAL"		. ,EINVAL)
	    ("EIO"		. ,EIO)
	    ("EISCONN"		. ,EISCONN)
	    ("EISDIR"		. ,EISDIR)
	    ("EISNAM"		. ,EISNAM)
	    ("EKEYEXPIRED"	. ,EKEYEXPIRED)
	    ("EKEYREJECTED"	. ,EKEYREJECTED)
	    ("EKEYREVOKED"	. ,EKEYREVOKED)
	    ("EL2HLT"		. ,EL2HLT)
	    ("EL2NSYNC"		. ,EL2NSYNC)
	    ("EL3HLT"		. ,EL3HLT)
	    ("EL3RST"		. ,EL3RST)
	    ("ELIBACC"		. ,ELIBACC)
	    ("ELIBBAD"		. ,ELIBBAD)
	    ("ELIBEXEC"		. ,ELIBEXEC)
	    ("ELIBMAX"		. ,ELIBMAX)
	    ("ELIBSCN"		. ,ELIBSCN)
	    ("ELNRNG"		. ,ELNRNG)
	    ("ELOOP"		. ,ELOOP)
	    ("EMEDIUMTYPE"	. ,EMEDIUMTYPE)
	    ("EMFILE"		. ,EMFILE)
	    ("EMLINK"		. ,EMLINK)
	    ("EMSGSIZE"		. ,EMSGSIZE)
	    ("EMULTIHOP"	. ,EMULTIHOP)
	    ("ENAMETOOLONG"	. ,ENAMETOOLONG)
	    ("ENAVAIL"		. ,ENAVAIL)
	    ("ENETDOWN"		. ,ENETDOWN)
	    ("ENETRESET"	. ,ENETRESET)
	    ("ENETUNREACH"	. ,ENETUNREACH)
	    ("ENFILE"		. ,ENFILE)
	    ("ENOANO"		. ,ENOANO)
	    ("ENOBUFS"		. ,ENOBUFS)
	    ("ENOCSI"		. ,ENOCSI)
	    ("ENODATA"		. ,ENODATA)
	    ("ENODEV"		. ,ENODEV)
	    ("ENOENT"		. ,ENOENT)
	    ("ENOEXEC"		. ,ENOEXEC)
	    ("ENOKEY"		. ,ENOKEY)
	    ("ENOLCK"		. ,ENOLCK)
	    ("ENOLINK"		. ,ENOLINK)
	    ("ENOMEDIUM"	. ,ENOMEDIUM)
	    ("ENOMEM"		. ,ENOMEM)
	    ("ENOMSG"		. ,ENOMSG)
	    ("ENONET"		. ,ENONET)
	    ("ENOPKG"		. ,ENOPKG)
	    ("ENOPROTOOPT"	. ,ENOPROTOOPT)
	    ("ENOSPC"		. ,ENOSPC)
	    ("ENOSR"		. ,ENOSR)
	    ("ENOSTR"		. ,ENOSTR)
	    ("ENOSYS"		. ,ENOSYS)
	    ("ENOTBLK"		. ,ENOTBLK)
	    ("ENOTCONN"		. ,ENOTCONN)
	    ("ENOTDIR"		. ,ENOTDIR)
	    ("ENOTEMPTY"	. ,ENOTEMPTY)
	    ("ENOTNAM"		. ,ENOTNAM)
	    ("ENOTRECOVERABLE"	. ,ENOTRECOVERABLE)
	    ("ENOTSOCK"		. ,ENOTSOCK)
	    ("ENOTTY"		. ,ENOTTY)
	    ("ENOTUNIQ"		. ,ENOTUNIQ)
	    ("ENXIO"		. ,ENXIO)
	    ("EOPNOTSUPP"	. ,EOPNOTSUPP)
	    ("EOVERFLOW"	. ,EOVERFLOW)
	    ("EOWNERDEAD"	. ,EOWNERDEAD)
	    ("EPERM"		. ,EPERM)
	    ("EPFNOSUPPORT"	. ,EPFNOSUPPORT)
	    ("EPIPE"		. ,EPIPE)
	    ("EPROTO"		. ,EPROTO)
	    ("EPROTONOSUPPORT"	. ,EPROTONOSUPPORT)
	    ("EPROTOTYPE"	. ,EPROTOTYPE)
	    ("ERANGE"		. ,ERANGE)
	    ("EREMCHG"		. ,EREMCHG)
	    ("EREMOTE"		. ,EREMOTE)
	    ("EREMOTEIO"	. ,EREMOTEIO)
	    ("ERESTART"		. ,ERESTART)
	    ("EROFS"		. ,EROFS)
	    ("ESHUTDOWN"	. ,ESHUTDOWN)
	    ("ESOCKTNOSUPPORT"	. ,ESOCKTNOSUPPORT)
	    ("ESPIPE"		. ,ESPIPE)
	    ("ESRCH"		. ,ESRCH)
	    ("ESRMNT"		. ,ESRMNT)
	    ("ESTALE"		. ,ESTALE)
	    ("ESTRPIPE"		. ,ESTRPIPE)
	    ("ETIME"		. ,ETIME)
	    ("ETIMEDOUT"	. ,ETIMEDOUT)
	    ("ETOOMANYREFS"	. ,ETOOMANYREFS)
	    ("ETXTBSY"		. ,ETXTBSY)
	    ("EUCLEAN"		. ,EUCLEAN)
	    ("EUNATCH"		. ,EUNATCH)
	    ("EUSERS"		. ,EUSERS)
	    ("EWOULDBLOCK"	. ,EWOULDBLOCK)
	    ("EXDEV"		. ,EXDEV)
	    ("EXFULL"		. ,EXFULL)))
	(syntax-case stx ()
	  ((?ctx)
	   #`(quote #,(datum->syntax #'?ctx (%mk-vector))))))))

  (define ERRNO-VECTOR (make-errno-vector)))


;;;; h_errno handling

(define (h_errno->string negated-h_errno-code)
  ;;Convert   an   h_errno   code   as  represented   by   the   (vicare
  ;;platform-constants) library  into a string  representing the h_errno
  ;;code symbol.
  ;;
  (define who 'h_errno->string)
  (with-arguments-validation (who)
      ((fixnum negated-h_errno-code))
    (let ((h_errno-code (unsafe.fx- 0 negated-h_errno-code)))
      (and (unsafe.fx> h_errno-code 0)
	   (unsafe.fx< h_errno-code (vector-length H_ERRNO-VECTOR))
	   (vector-ref H_ERRNO-VECTOR h_errno-code)))))

(let-syntax
    ((make-h_errno-vector
      (lambda (stx)
	(define (%mk-vector)
	  (let* ((max	(fold-left (lambda (max pair)
				     (let ((code (cdr pair)))
				       (cond ((not code)
					      max)
					     ((< max (fx- code))
					      (fx- code))
					     (else
					      max))))
			  0 h_errno-alist))
		 (vec.len	(fx+ 1 max))
		 ;;All the unused positions are set to #f.
		 (vec	(make-vector vec.len #f)))
	    (for-each (lambda (pair)
			(when (cdr pair)
			  (vector-set! vec (fx- (cdr pair)) (car pair))))
	      h_errno-alist)
	    vec))
	(define h_errno-alist
	  `(("HOST_NOT_FOUND"		. ,HOST_NOT_FOUND)
	    ("TRY_AGAIN"		. ,TRY_AGAIN)
	    ("NO_RECOVERY"		. ,NO_RECOVERY)
	    ("NO_ADDRESS"		. ,NO_ADDRESS)))
	(syntax-case stx ()
	  ((?ctx)
	   #`(quote #,(datum->syntax #'?ctx (%mk-vector))))))))

  (define H_ERRNO-VECTOR (make-h_errno-vector)))

(define (h_strerror h_errno)
  (define who 'h_strerror)
  (with-arguments-validation (who)
      ((fixnum  h_errno))
    (let ((msg (case-h_errno h_errno
		 ((HOST_NOT_FOUND)	"no such host is known in the database")
		 ((TRY_AGAIN)		"the server could not be contacted")
		 ((NO_RECOVERY)		"non-recoverable error")
		 ((NO_ADDRESS)		"host entry exists but without Internet address")
		 (else			#f))))
      (if msg
	  (string-append (h_errno->string h_errno) ": " msg)
	(string-append "unknown h_errno code " (number->string (- h_errno)))))))


;;;; interprocess singnal codes handling

(define (interprocess-signal->string interprocess-signal-code)
  ;;Convert an  interprocess signal code  as represented by  the (vicare
  ;;interprocess-signals)  library   into  a  string   representing  the
  ;;interprocess signal symbol.
  ;;
  (define who 'interprocess-signal->string)
  (with-arguments-validation (who)
      ((fixnum  interprocess-signal-code))
    (and (unsafe.fx> interprocess-signal-code 0)
	 (unsafe.fx< interprocess-signal-code (vector-length INTERPROCESS-SIGNAL-VECTOR))
	 (vector-ref INTERPROCESS-SIGNAL-VECTOR interprocess-signal-code))))

(let-syntax
    ((make-interprocess-signal-vector
      (lambda (stx)
	(define (%mk-vector)
	  (let* ((max	(fold-left (lambda (max pair)
				     (let ((code (cdr pair)))
				       (cond ((not code)	max)
					     ((< max code)	code)
					     (else		max))))
			  0 interprocess-signal-alist))
		 (vec.len	(fx+ 1 max))
		 ;;All the unused positions are set to #f.
		 (vec	(make-vector vec.len #f)))
	    (for-each (lambda (pair)
			(when (cdr pair)
			  (vector-set! vec (cdr pair) (car pair))))
	      interprocess-signal-alist)
	    vec))
	(define interprocess-signal-alist
	  `(("SIGFPE"		. ,SIGFPE)
	    ("SIGILL"		. ,SIGILL)
	    ("SIGSEGV"		. ,SIGSEGV)
	    ("SIGBUS"		. ,SIGBUS)
	    ("SIGABRT"		. ,SIGABRT)
	    ("SIGIOT"		. ,SIGIOT)
	    ("SIGTRAP"		. ,SIGTRAP)
	    ("SIGEMT"		. ,SIGEMT)
	    ("SIGSYS"		. ,SIGSYS)
	    ("SIGTERM"		. ,SIGTERM)
	    ("SIGINT"		. ,SIGINT)
	    ("SIGQUIT"		. ,SIGQUIT)
	    ("SIGKILL"		. ,SIGKILL)
	    ("SIGHUP"		. ,SIGHUP)
	    ("SIGALRM"		. ,SIGALRM)
	    ("SIGVRALRM"	. ,SIGVRALRM)
	    ("SIGPROF"		. ,SIGPROF)
	    ("SIGIO"		. ,SIGIO)
	    ("SIGURG"		. ,SIGURG)
	    ("SIGPOLL"		. ,SIGPOLL)
	    ("SIGCHLD"		. ,SIGCHLD)
	    ("SIGCLD"		. ,SIGCLD)
	    ("SIGCONT"		. ,SIGCONT)
	    ("SIGSTOP"		. ,SIGSTOP)
	    ("SIGTSTP"		. ,SIGTSTP)
	    ("SIGTTIN"		. ,SIGTTIN)
	    ("SIGTTOU"		. ,SIGTTOU)
	    ("SIGPIPE"		. ,SIGPIPE)
	    ("SIGLOST"		. ,SIGLOST)
	    ("SIGXCPU"		. ,SIGXCPU)
	    ("SIGXSFZ"		. ,SIGXSFZ)
	    ("SIGUSR1"		. ,SIGUSR1)
	    ("SIGUSR2"		. ,SIGUSR2)
	    ("SIGWINCH"		. ,SIGWINCH)
	    ("SIGINFO"		. ,SIGINFO)))
	(syntax-case stx ()
	  ((?ctx)
	   #`(quote #,(datum->syntax #'?ctx (%mk-vector))))))))
  (define INTERPROCESS-SIGNAL-VECTOR (make-interprocess-signal-vector)))


;;;; operating system environment variables

(define (getenv key)
  (define who 'getenv)
  (with-arguments-validation (who)
      ((string  key))
    (let ((rv (capi.posix-getenv (string->utf8 key))))
      (and rv (utf8->string rv)))))

(define setenv
  (case-lambda
   ((key val)
    (setenv key val #t))
   ((key val overwrite)
    (define who 'setenv)
    (with-arguments-validation (who)
	((string  key)
	 (string  val))
      (unless (capi.posix-setenv (string->utf8 key)
				 (string->utf8 val)
				 overwrite)
	(error who "cannot setenv" key val overwrite))))))

(define (unsetenv key)
  (define who 'unsetenv)
  (with-arguments-validation (who)
      ((string  key))
    (capi.posix-unsetenv (string->utf8 key))))

(define (%find-index-of-= str idx str.len)
  ;;Scan STR starint at index IDX  and up to STR.LEN for the position of
  ;;the character #\=.  Return the index or STR.LEN.
  ;;
  (cond ((unsafe.fx= idx str.len)
	 idx)
	((unsafe.char= #\= (unsafe.string-ref str idx))
	 idx)
	(else
	 (%find-index-of-= str (unsafe.fxadd1 idx) str.len))))

(define (environ)
  (map (lambda (bv)
	 (let* ((str     (utf8->string bv))
		(str.len (unsafe.string-length str))
		(idx     (%find-index-of-= str 0 str.len)))
	   (cons (substring str 0 idx)
		 (if (unsafe.fx< (unsafe.fxadd1 idx) str.len)
		     (substring str (unsafe.fxadd1 idx) str.len)
		   ""))))
    (capi.posix-environ)))

(define (environ-table)
  (environ->table (environ)))

(define (environ->table environ)
  (begin0-let ((table (make-hashtable string-hash string=?)))
    (for-each (lambda (pair)
		(hashtable-set! table (unsafe.car pair) (unsafe.cdr pair)))
      environ)))

(define (table->environ table)
  (let-values (((names values) (hashtable-entries table)))
    (let ((len     (unsafe.vector-length names))
	  (environ '()))
      (let loop ((i       0)
		 (environ '()))
	(if (unsafe.fx= i len)
	    environ
	  (loop (unsafe.fxadd1 i)
		(cons (cons (unsafe.vector-ref names  i)
			    (unsafe.vector-ref values i))
		      environ)))))))


;;;; process identifiers

(define (getpid)
  (capi.posix-getpid))

(define (getppid)
  (capi.posix-getppid))


;;;; executing and forking processes

(define (system x)
  (define who 'system)
  (with-arguments-validation (who)
      ((string  x))
    (let ((rv (capi.posix-system (string->utf8 x))))
      (if (unsafe.fx< rv 0)
	  (raise-errno-error who rv x)
	rv))))

(define fork
  (case-lambda
   (()
    (define who 'fork)
    (let ((rv (capi.posix-fork)))
      (if (unsafe.fx<= 0 rv)
	  rv
	(raise-errno-error who rv))))
   ((parent-proc child-proc)
    (define who 'fork)
    (with-arguments-validation (who)
	((procedure  parent-proc)
	 (procedure  child-proc))
      (let ((rv (capi.posix-fork)))
	(cond ((unsafe.fxzero? rv)
	       (child-proc))
	      ((unsafe.fx< rv 0)
	       (raise-errno-error who rv))
	      (else
	       (parent-proc rv))))))))

(define (execl filename . argv)
  (execv filename argv))

(define (execv filename argv)
  (define who 'execv)
  (with-arguments-validation (who)
      ((pathname	filename)
       (list-of-strings	argv))
    (with-pathnames ((filename.bv filename))
      (let ((rv (capi.posix-execv filename.bv (map string->utf8 argv))))
	(if (unsafe.fx< rv 0)
	    (raise-errno-error who rv filename argv)
	  rv)))))

(define (execle filename argv . env)
  (execve filename argv env))

(define (execve filename argv env)
  (define who 'execve)
  (with-arguments-validation (who)
      ((pathname	filename)
       (list-of-strings	argv)
       (list-of-strings	env))
    (with-pathnames ((filename.bv filename))
      (let ((rv (capi.posix-execve filename.bv
				   (map string->utf8 argv)
				   (map string->utf8 env))))
	(if (unsafe.fx< rv 0)
	    (raise-errno-error who rv filename argv env)
	  rv)))))

(define (execlp filename . argv)
  (execvp filename argv))

(define (execvp filename argv)
  (define who 'execvp)
  (with-arguments-validation (who)
      ((pathname	filename)
       (list-of-strings	argv))
    (with-pathnames ((filename.bv filename))
      (let ((rv (capi.posix-execvp filename.bv (map string->utf8 argv))))
	(if (unsafe.fx< rv 0)
	    (raise-errno-error who rv filename argv)
	  rv)))))


;;;; process termination status

(define (waitpid pid options)
  (define who 'waitpid)
  (with-arguments-validation (who)
      ((pid	pid)
       (fixnum	options))
    (let ((rv (capi.posix-waitpid pid options)))
      (if (unsafe.fx< rv 0)
	  (raise-errno-error who rv pid options)
	rv))))

(define (wait)
  (define who 'wait)
  (let ((rv (capi.posix-wait)))
    (if (unsafe.fx< rv 0)
	(raise-errno-error who rv)
      rv)))

(let-syntax
    ((define-termination-status (syntax-rules ()
				  ((_ ?who ?primitive)
				   (define (?who status)
				     (define who '?who)
				     (with-arguments-validation (who)
					 ((fixnum  status))
				       (?primitive status)))))))
  (define-termination-status WIFEXITED		capi.posix-WIFEXITED)
  (define-termination-status WEXITSTATUS	capi.posix-WEXITSTATUS)
  (define-termination-status WIFSIGNALED	capi.posix-WIFSIGNALED)
  (define-termination-status WTERMSIG		capi.posix-WTERMSIG)
  (define-termination-status WCOREDUMP		capi.posix-WCOREDUMP)
  (define-termination-status WIFSTOPPED		capi.posix-WIFSTOPPED)
  (define-termination-status WSTOPSIG		capi.posix-WSTOPSIG))


;;;; interprocess signal handling

(define (raise-signal signum)
  (define who 'raise-signal)
  (with-arguments-validation (who)
      ((signal	signum))
    (let ((rv (capi.posix-raise signum)))
      (when (unsafe.fx< rv 0)
	(raise-errno-error who rv signum (interprocess-signal->string signum))))))

(define (kill pid signum)
  (define who 'kill)
  (with-arguments-validation (who)
      ((pid	pid)
       (signal	signum))
    (let ((rv (capi.posix-kill pid signum)))
      (when (unsafe.fx< rv 0)
	(raise-errno-error who rv signum (interprocess-signal->string signum))))))

(define (pause)
  (capi.posix-pause))


;;;; file system inspection

(define-struct struct-stat
  ;;The  order of  the fields  must match  the order  in the  C function
  ;;"fill_stat_struct()".
  ;;
  (st_mode st_ino st_dev st_nlink
	   st_uid st_gid st_size
	   st_atime st_atime_usec
	   st_mtime st_mtime_usec
	   st_ctime st_ctime_usec
	   st_blocks st_blksize))

(define (%struct-stat-printer S port sub-printer)
  (define-inline (%display thing)
    (display thing port))
  (%display "#[struct-stat")
  (%display " st_mode=#o")	(%display (number->string (struct-stat-st_mode S) 8))
  (%display " st_ino=")		(%display (struct-stat-st_ino S))
  (%display " st_dev=")		(%display (struct-stat-st_dev S))
  (%display " st_nlink=")	(%display (struct-stat-st_nlink S))
  (%display " st_uid=")		(%display (struct-stat-st_uid S))
  (%display " st_gid=")		(%display (struct-stat-st_gid S))
  (%display " st_size=")	(%display (struct-stat-st_size S))
  (%display " st_atime=")	(%display (struct-stat-st_atime S))
  (%display " st_atime_usec=")	(%display (struct-stat-st_atime_usec S))
  (%display " st_mtime=")	(%display (struct-stat-st_mtime S))
  (%display " st_mtime_usec=")	(%display (struct-stat-st_mtime_usec S))
  (%display " st_ctime=")	(%display (struct-stat-st_ctime S))
  (%display " st_ctime_usec=")	(%display (struct-stat-st_ctime_usec S))
  (%display " st_blocks=")	(%display (struct-stat-st_blocks S))
  (%display " st_blksize=")	(%display (struct-stat-st_blksize S))
  (%display "]"))

(define-inline (%make-stat)
  (make-struct-stat #f #f #f #f #f
		    #f #f #f #f #f
		    #f #f #f #f #f))

(define (stat pathname)
  (define who 'stat)
  (with-arguments-validation (who)
      ((pathname  pathname))
    (with-pathnames ((pathname.bv pathname))
      (let* ((S  (%make-stat))
	     (rv (capi.posix-stat pathname.bv S)))
	(if (unsafe.fx< rv 0)
	    (raise-errno-error/filename who rv pathname)
	  S)))))

(define (lstat pathname)
  (define who 'stat)
  (with-arguments-validation (who)
      ((pathname  pathname))
    (with-pathnames ((pathname.bv pathname))
      (let* ((S  (%make-stat))
	     (rv (capi.posix-lstat pathname.bv S)))
	(if (unsafe.fx< rv 0)
	    (raise-errno-error/filename who rv pathname)
	  S)))))

(define (fstat fd)
  (define who 'stat)
  (with-arguments-validation (who)
      ((file-descriptor  fd))
    (let* ((S  (%make-stat))
	   (rv (capi.posix-lstat fd S)))
      (if (unsafe.fx< rv 0)
	  (raise-errno-error who rv fd)
	S))))

;;; --------------------------------------------------------------------

(let-syntax
    ((define-file-is (syntax-rules ()
		       ((_ ?who ?func)
			(define (?who pathname follow-symlinks?)
			  (define who '?who)
			  (with-arguments-validation (who)
			      ((pathname  pathname))
			    (with-pathnames ((pathname.bv pathname))
			      (let ((rv (?func pathname.bv follow-symlinks?)))
				(if (boolean? rv)
				    rv
				  (raise-errno-error/filename who rv pathname))))))
			))))
  (define-file-is file-is-directory?		capi.posix-file-is-directory?)
  (define-file-is file-is-char-device?		capi.posix-file-is-char-device?)
  (define-file-is file-is-block-device?		capi.posix-file-is-block-device?)
  (define-file-is file-is-regular-file?		capi.posix-file-is-regular-file?)
  (define-file-is file-is-symbolic-link?	capi.posix-file-is-symbolic-link?)
  (define-file-is file-is-socket?		capi.posix-file-is-socket?)
  (define-file-is file-is-fifo?			capi.posix-file-is-fifo?)
  (define-file-is file-is-message-queue?	capi.posix-file-is-message-queue?)
  (define-file-is file-is-semaphore?		capi.posix-file-is-semaphore?)
  (define-file-is file-is-shared-memory?	capi.posix-file-is-shared-memory?))

(let-syntax
    ((define-file-is (syntax-rules ()
		       ((_ ?who ?flag)
			(define (?who mode)
			  (with-arguments-validation (?who)
			      ((fixnum  mode))
			    (unsafe.fx= ?flag (unsafe.fxand ?flag mode))))
			))))
  (define-file-is S_ISDIR	S_IFDIR)
  (define-file-is S_ISCHR	S_IFCHR)
  (define-file-is S_ISBLK	S_IFBLK)
  (define-file-is S_ISREG	S_IFREG)
  (define-file-is S_ISLNK	S_IFLNK)
  (define-file-is S_ISSOCK	S_IFSOCK)
  (define-file-is S_ISFIFO	S_IFIFO))

;;; --------------------------------------------------------------------

(define (file-exists? pathname)
  ;;Defined by R6RS.
  ;;
  (define who 'file-exists?)
  (with-arguments-validation (who)
      ((pathname  pathname))
    (with-pathnames ((pathname.bv pathname))
      (let ((rv (capi.posix-file-exists? pathname.bv)))
	(if (boolean? rv)
	    rv
	  (raise-errno-error/filename who rv pathname))))))

(define (access pathname how)
  (define who 'access)
  (with-arguments-validation (who)
      ((pathname  pathname)
       (fixnum	  how))
    (with-pathnames ((pathname.bv pathname))
      (let ((rv (capi.posix-access pathname.bv how)))
	(if (boolean? rv)
	    rv
	  (raise-errno-error/filename who rv pathname how))))))

;;; --------------------------------------------------------------------

(define (file-readable? pathname)
  (access pathname R_OK))

(define (file-writable? pathname)
  (access pathname W_OK))

(define (file-executable? pathname)
  (access pathname X_OK))

;;; --------------------------------------------------------------------

(define (file-size pathname)
  (define who 'file-size)
  (with-arguments-validation (who)
      ((pathname pathname))
    (with-pathnames ((pathname.bv pathname))
      (let ((v (capi.posix-file-size pathname.bv)))
	(if (>= v 0)
	    v
	  (raise-errno-error/filename who v pathname))))))

;;; --------------------------------------------------------------------

(let-syntax
    ((define-file-time (syntax-rules ()
			 ((_ ?who ?func)
			  (define (?who pathname)
			    (define who '?who)
			    (with-arguments-validation (who)
				((pathname  pathname))
			      (with-pathnames ((pathname.bv  pathname))
				;;All the  elements of this  vector must
				;;be initialised here!!!
				(let* ((timespec (make-vector 2))
				       (rv       (?func pathname.bv timespec)))
				  (if (unsafe.fxzero? rv)
				      (+ (* #e1e9 (unsafe.vector-ref timespec 0))
					 (unsafe.vector-ref timespec 1))
				    (raise-errno-error/filename who rv pathname))))))
			  ))))
  (define-file-time file-atime	capi.posix-file-atime)
  (define-file-time file-mtime	capi.posix-file-mtime)
  (define-file-time file-ctime	capi.posix-file-ctime))


;;;; file system attributes mutators

(define (chown pathname owner group)
  (define who 'chown)
  (with-arguments-validation (who)
      ((pathname  pathname)
       (pid       owner)
       (gid	  group))
    (with-pathnames ((pathname.bv pathname))
      (let ((rv (capi.posix-chown pathname.bv owner group)))
	(if (unsafe.fxzero? rv)
	    rv
	  (raise-errno-error/filename who rv pathname owner group))))))

(define (fchown fd owner group)
  (define who 'fchown)
  (with-arguments-validation (who)
      ((file-descriptor	fd)
       (pid		owner)
       (gid		group))
    (let ((rv (capi.posix-fchown fd owner group)))
      (if (unsafe.fxzero? rv)
	  rv
	(raise-errno-error who rv fd owner group)))))

;;; --------------------------------------------------------------------

(define (chmod pathname mode)
  (define who 'chmod)
  (with-arguments-validation (who)
      ((pathname  pathname)
       (fixnum    mode))
    (with-pathnames ((pathname.bv pathname))
      (let ((rv (capi.posix-chmod pathname.bv mode)))
	(if (unsafe.fxzero? rv)
	    rv
	  (raise-errno-error/filename who rv pathname mode))))))

(define (fchmod fd mode)
  (define who 'fchmod)
  (with-arguments-validation (who)
      ((file-descriptor fd)
       (fixnum		mode))
    (let ((rv (capi.posix-fchmod fd mode)))
      (if (unsafe.fxzero? rv)
	  rv
	(raise-errno-error who rv fd mode)))))

;;; --------------------------------------------------------------------

(define (umask mask)
  (define who 'umask)
  (with-arguments-validation (who)
      ((fixnum  mask))
    (capi.posix-umask mask)))

(define (getumask)
  (capi.posix-getumask))

;;; --------------------------------------------------------------------

(define (utime pathname atime mtime)
  (define who 'utime)
  (with-arguments-validation (who)
      ((pathname  pathname)
       (secfx     atime)
       (secfx     mtime))
    (with-pathnames ((pathname.bv pathname))
      (let ((rv (capi.posix-utime pathname.bv atime mtime)))
	(if (unsafe.fxzero? rv)
	    rv
	  (raise-errno-error/filename who rv pathname atime mtime))))))

(define (utimes pathname atime.sec atime.usec mtime.sec mtime.usec)
  (define who 'utimes)
  (with-arguments-validation (who)
      ((pathname  pathname)
       (secfx     atime.sec)
       (usecfx    atime.usec)
       (secfx     mtime.sec)
       (usecfx    mtime.usec))
    (with-pathnames ((pathname.bv pathname))
      (let ((rv (capi.posix-utimes pathname.bv atime.sec atime.usec mtime.sec mtime.usec)))
	(if (unsafe.fxzero? rv)
	    rv
	  (raise-errno-error/filename who rv pathname atime.sec atime.usec mtime.sec mtime.usec))))))

(define (lutimes pathname atime.sec atime.usec mtime.sec mtime.usec)
  (define who 'lutimes)
  (with-arguments-validation (who)
      ((pathname  pathname)
       (secfx     atime.sec)
       (usecfx    atime.usec)
       (secfx     mtime.sec)
       (usecfx    mtime.usec))
    (with-pathnames ((pathname.bv pathname))
      (let ((rv (capi.posix-lutimes pathname.bv atime.sec atime.usec mtime.sec mtime.usec)))
	(if (unsafe.fxzero? rv)
	    rv
	  (raise-errno-error/filename who rv pathname atime.sec atime.usec mtime.sec mtime.usec))))))

(define (futimes fd atime.sec atime.usec mtime.sec mtime.usec)
  (define who 'futimes)
  (with-arguments-validation (who)
      ((file-descriptor  fd)
       (secfx     atime.sec)
       (usecfx    atime.usec)
       (secfx     mtime.sec)
       (usecfx    mtime.usec))
    (let ((rv (capi.posix-futimes fd atime.sec atime.usec mtime.sec mtime.usec)))
      (if (unsafe.fxzero? rv)
	  rv
	(raise-errno-error who rv fd atime.sec atime.usec mtime.sec mtime.usec)))))


;;;; hard and symbolic links

(define (link old-pathname new-pathname)
  (define who 'link)
  (with-arguments-validation (who)
      ((pathname  old-pathname)
       (pathname  new-pathname))
    (with-pathnames ((old-pathname.bv old-pathname)
		     (new-pathname.bv new-pathname))
      (let ((rv (capi.posix-link old-pathname.bv new-pathname.bv)))
	(if (unsafe.fxzero? rv)
	    rv
	  (raise-errno-error/filename who rv old-pathname new-pathname))))))

(define (symlink file-pathname link-pathname)
  (define who 'symlink)
  (with-arguments-validation (who)
      ((pathname  file-pathname)
       (pathname  link-pathname))
    (with-pathnames ((file-pathname.bv file-pathname)
		     (link-pathname.bv link-pathname))
      (let ((rv (capi.posix-symlink file-pathname.bv link-pathname.bv)))
	(if (unsafe.fxzero? rv)
	    rv
	  (raise-errno-error/filename who rv file-pathname link-pathname))))))

(define (readlink link-pathname)
  (define who 'readlink)
  (with-arguments-validation (who)
      ((pathname  link-pathname))
    (with-pathnames ((link-pathname.bv link-pathname))
      (let ((rv (capi.posix-readlink link-pathname.bv)))
	(if (bytevector? rv)
	    rv
	  (raise-errno-error/filename who rv link-pathname))))))

(define (readlink/string link-pathname)
  ((filename->string-func) (readlink link-pathname)))

(define (realpath pathname)
  (define who 'realpath)
  (with-arguments-validation (who)
      ((pathname  pathname))
    (with-pathnames ((pathname.bv pathname))
      (let ((rv (capi.posix-realpath pathname.bv)))
	(if (bytevector? rv)
	    rv
	  (raise-errno-error/filename who rv pathname))))))

(define (realpath/string pathname)
  ((filename->string-func) (realpath pathname)))

;;; --------------------------------------------------------------------

(define unlink delete-file)

(define (delete-file pathname)
  ;;Defined by R6RS.
  ;;
  (define who 'delete-file)
  (with-arguments-validation (who)
      ((pathname pathname))
    (with-pathnames ((pathname.bv pathname))
      (let ((rv (capi.posix-unlink pathname.bv)))
	(unless (unsafe.fxzero? rv)
	  (raise-errno-error/filename who rv pathname))))))

(define (posix-remove pathname)
  (define who 'posix-remove)
  (with-arguments-validation (who)
      ((pathname pathname))
    (with-pathnames ((pathname.bv pathname))
      (let ((rv (capi.posix-remove pathname.bv)))
	(unless (unsafe.fxzero? rv)
	  (raise-errno-error/filename who rv pathname))))))

(define (rename old-pathname new-pathname)
  (define who 'rename)
  (with-arguments-validation (who)
      ((pathname  old-pathname)
       (pathname  new-pathname))
    (with-pathnames ((old-pathname.bv old-pathname)
		     (new-pathname.bv new-pathname))
      (let ((rv (capi.posix-rename old-pathname.bv new-pathname.bv)))
	(unless (unsafe.fxzero? rv)
	  (raise-errno-error/filename who rv old-pathname new-pathname))))))


;;;; file system directories

(define (mkdir pathname mode)
  (define who 'mkdir)
  (with-arguments-validation (who)
      ((pathname  pathname)
       (fixnum	  mode))
    (with-pathnames ((pathname.bv pathname))
      (let ((rv (capi.posix-mkdir pathname.bv mode)))
	(unless (unsafe.fxzero? rv)
	  (raise-errno-error/filename who rv pathname mode))))))

(define (mkdir/parents pathname mode)
  (define who 'mkdir/parents)
  (with-arguments-validation (who)
      ((pathname  pathname)
       (fixnum	  mode))
    (let next-component ((pathname pathname))
      (if (file-exists? pathname)
	  (unless (file-is-directory? pathname #f)
	    (error who "path component is not a directory" pathname))
	(let-values (((base suffix) (split-file-name pathname)))
	  (unless (unsafe.fxzero? (unsafe.string-length base))
	    (next-component base))
	  (unless (unsafe.fxzero? (unsafe.string-length suffix))
	    (mkdir pathname mode)))))))

(define (rmdir pathname)
  (define who 'rmdir)
  (with-arguments-validation (who)
      ((pathname  pathname))
    (with-pathnames ((pathname.bv pathname))
      (let ((rv (capi.posix-rmdir pathname.bv)))
	(unless (unsafe.fxzero? rv)
	  (raise-errno-error/filename who rv pathname))))))

(define (getcwd)
  (define who 'getcwd)
  (let ((rv (capi.posix-getcwd)))
    (if (bytevector? rv)
	rv
      (raise-errno-error who rv))))

(define (getcwd/string)
  (define who 'getcwd)
  (let ((rv (capi.posix-getcwd)))
    (if (bytevector? rv)
	((filename->string-func) rv)
      (raise-errno-error who rv))))

(define (chdir pathname)
  (define who 'chdir)
  (with-arguments-validation (who)
      ((pathname  pathname))
    (with-pathnames ((pathname.bv pathname))
      (let ((rv (capi.posix-chdir pathname.bv)))
	(unless (unsafe.fxzero? rv)
	  (raise-errno-error/filename who rv pathname))))))

(define (fchdir fd)
  (define who 'fchdir)
  (with-arguments-validation (who)
      ((file-descriptor  fd))
    (let ((rv (capi.posix-fchdir fd)))
      (unless (unsafe.fxzero? rv)
	(raise-errno-error who rv fd)))))

;;; --------------------------------------------------------------------

(define (split-file-name str)
  (define who 'split-file-name)
  (define path-sep #\/)
  (define (find-last c str)
    (let f ((i (string-length str)))
      (if (fx=? i 0)
	  #f
	(let ((i (fx- i 1)))
	  (if (char=? (string-ref str i) c)
	      i
	    (f i))))))
  (with-arguments-validation (who)
      ((string  str))
    (cond ((find-last path-sep str)
	   => (lambda (i)
		(values
		 (substring str 0 i)
		 (let ((i (fx+ i 1)))
		   (substring str i (string-length str) )))))
	  (else
	   (values "" str)))))


;;;; inspecting file system directories

(define-struct directory-stream
  (pathname pointer fd closed?))

(define (%directory-stream-printer struct port sub-printer)
  (display "#[directory-stream" port)
  (display " pathname=\"" port) (display (directory-stream-pathname struct) port)
  (display "\"" port)
  (display " pointer="    port) (display (directory-stream-pointer  struct) port)
  (display " fd="         port) (display (directory-stream-fd       struct) port)
  (display " closed?="    port) (display (directory-stream-closed?  struct) port)
  (display "]" port))

(define directory-stream-guardian
  (let ((G (make-guardian)))
    (define (close-garbage-collected-directory-streams)
      (let ((stream (G)))
	(when stream
	  (unless (directory-stream-closed? stream)
	    (set-directory-stream-closed?! stream #t)
	    (capi.posix-closedir (directory-stream-pointer stream)))
	  (close-garbage-collected-directory-streams))))
    (post-gc-hooks (cons close-garbage-collected-directory-streams (post-gc-hooks)))
    G))

(define (opendir pathname)
  (define who 'opendir)
  (with-arguments-validation (who)
      ((pathname  pathname))
    (with-pathnames ((pathname.bv pathname))
      (let ((rv (capi.posix-opendir pathname.bv)))
	(if (fixnum? rv)
	    (raise-errno-error/filename who rv pathname)
	  (begin0-let ((stream (make-directory-stream pathname rv #f #f)))
	    (directory-stream-guardian stream)))))))

(define (fdopendir fd)
  (define who 'fdopendir)
  (with-arguments-validation (who)
      ((file-descriptor  fd))
    (let ((rv (capi.posix-fdopendir fd)))
      (if (fixnum? rv)
	  (raise-errno-error who rv fd)
	(begin0-let ((stream (make-directory-stream #f rv fd #f)))
	  (directory-stream-guardian stream))))))

(define (readdir stream)
  (define who 'readdir)
  (with-arguments-validation (who)
      ((directory-stream       stream)
       (open-directory-stream  stream))
    (let ((rv (capi.posix-readdir (directory-stream-pointer stream))))
      (cond ((fixnum? rv)
	     (set-directory-stream-closed?! stream #t)
	     (raise-errno-error who rv stream))
	    ((not rv)
	     (set-directory-stream-closed?! stream #t)
	     #f)
	    (else rv)))))

(define (readdir/string stream)
  (let ((rv (readdir stream)))
    (and rv ((filename->string-func) rv))))

(define (closedir stream)
  (define who 'closedir)
  (with-arguments-validation (who)
      ((directory-stream stream))
    (unless (directory-stream-closed? stream)
      (set-directory-stream-closed?! stream #t)
      (let ((rv (capi.posix-closedir (directory-stream-pointer stream))))
	(unless (unsafe.fxzero? rv)
	  (raise-errno-error who rv stream))))))

;;; --------------------------------------------------------------------

(define (rewinddir stream)
  (define who 'rewinddir)
  (with-arguments-validation (who)
      ((directory-stream       stream)
       (open-directory-stream  stream))
    (capi.posix-rewinddir (directory-stream-pointer stream))))

(define (telldir stream)
  (define who 'telldir)
  (with-arguments-validation (who)
      ((directory-stream       stream)
       (open-directory-stream  stream))
    (capi.posix-telldir (directory-stream-pointer stream))))

(define (seekdir stream pos)
  (define who 'rewinddir)
  (with-arguments-validation (who)
      ((directory-stream	stream)
       (open-directory-stream	stream)
       (dirpos			pos))
    (capi.posix-seekdir (directory-stream-pointer stream) pos)))


;;;; file descriptors

(define (open pathname flags mode)
  (define who 'open)
  (with-arguments-validation (who)
      ((pathname  pathname)
       (fixnum    flags)
       (fixnum    mode))
    (with-pathnames ((pathname.bv pathname))
      (let ((rv (capi.posix-open pathname.bv flags mode)))
	(if (unsafe.fx<= 0 rv)
	    rv
	  (raise-errno-error/filename who rv pathname flags mode))))))

(define (close fd)
  (define who 'close)
  (with-arguments-validation (who)
      ((file-descriptor  fd))
    (let ((rv (capi.posix-close fd)))
      (unless (unsafe.fxzero? rv)
	(raise-errno-error who rv fd)))))

(define posix-read
  (case-lambda
   ((fd buffer)
    (posix-read fd buffer #f))
   ((fd buffer size)
    (define who 'posix-read)
    (with-arguments-validation (who)
	((file-descriptor  fd)
	 (bytevector	 buffer)
	 (fixnum/false	 size))
      (let ((rv (capi.posix-read fd buffer size)))
	(if (unsafe.fx<= 0 rv)
	    rv
	  (raise-errno-error who rv fd)))))))

(define (pread fd buffer size off)
  (define who 'pread)
  (with-arguments-validation (who)
      ((file-descriptor  fd)
       (bytevector	 buffer)
       (fixnum/false	 size)
       (offset		 off))
    (let ((rv (capi.posix-pread fd buffer size off)))
      (if (unsafe.fx<= 0 rv)
	  rv
	(raise-errno-error who rv fd)))))

(define posix-write
  (case-lambda
   ((fd buffer)
    (posix-write fd buffer #f))
   ((fd buffer size)
    (define who 'posix-write)
    (with-arguments-validation (who)
	((file-descriptor  fd)
	 (bytevector	 buffer)
	 (fixnum/false	 size))
      (let ((rv (capi.posix-write fd buffer size)))
	(if (unsafe.fx<= 0 rv)
	    rv
	  (raise-errno-error who rv fd)))))))

(define (pwrite fd buffer size off)
  (define who 'pwrite)
  (with-arguments-validation (who)
      ((file-descriptor  fd)
       (bytevector	 buffer)
       (fixnum/false	 size)
       (offset		 off))
    (let ((rv (capi.posix-pwrite fd buffer size off)))
      (if (unsafe.fx<= 0 rv)
	  rv
	(raise-errno-error who rv fd)))))

(define (lseek fd off whence)
  (define who 'lseek)
  (with-arguments-validation (who)
      ((file-descriptor  fd)
       (offset		 off)
       (fixnum		 whence))
    (let ((rv (capi.posix-lseek fd off whence)))
      (if (negative? rv)
	  (raise-errno-error who rv fd off whence)
	rv))))

;;; --------------------------------------------------------------------

(define (readv fd buffers)
  (define who 'readv)
  (with-arguments-validation (who)
      ((file-descriptor		fd)
       (list-of-bytevectors	buffers))
    (let ((rv (capi.posix-readv fd buffers)))
      (if (negative? rv)
	  (raise-errno-error who rv fd buffers)
	rv))))

(define (writev fd buffers)
  (define who 'writev)
  (with-arguments-validation (who)
      ((file-descriptor		fd)
       (list-of-bytevectors	buffers))
    (let ((rv (capi.posix-writev fd buffers)))
      (if (negative? rv)
	  (raise-errno-error who rv fd buffers)
	rv))))

;;; --------------------------------------------------------------------

(define (select nfds read-fds write-fds except-fds sec usec)
  (define who 'select)
  (with-arguments-validation (who)
      ((false/fd	nfds)
       (list-of-fds	read-fds)
       (list-of-fds	write-fds)
       (list-of-fds	except-fds)
       (secfx		sec)
       (usecfx		usec))
    (let ((rv (capi.posix-select nfds read-fds write-fds except-fds sec usec)))
      (if (fixnum? rv)
	  (if (unsafe.fxzero? rv)
	      (values '() '() '()) ;timeout expired
	    (raise-errno-error who rv nfds read-fds write-fds except-fds sec usec))
	;; success, extract lists of ready fds
	(values (unsafe.vector-ref rv 0)
		(unsafe.vector-ref rv 1)
		(unsafe.vector-ref rv 2))))))

(define (select-fd fd sec usec)
  (define who 'select-fd)
  (with-arguments-validation (who)
      ((file-descriptor	fd)
       (secfx		sec)
       (usecfx		usec))
    (let ((rv (capi.posix-select-fd fd sec usec)))
      (if (fixnum? rv)
	  (if (unsafe.fxzero? rv)
	      (values #f #f #f) ;timeout expired
	    (raise-errno-error who rv fd sec usec))
	;; success, extract the statuses
	(values (unsafe.vector-ref rv 0)
		(unsafe.vector-ref rv 1)
		(unsafe.vector-ref rv 2))))))

;;; --------------------------------------------------------------------

(define fcntl
  (case-lambda
   ((fd command)
    (fcntl fd command #f))
   ((fd command arg)
    (define who 'fcntl)
    (with-arguments-validation (who)
	((file-descriptor	fd)
	 (fixnum		command)
	 (fixnum/pointer/false	arg))
      (let ((rv (capi.posix-fcntl fd command arg)))
	(if (unsafe.fx<= 0 rv)
	    rv
	  (raise-errno-error who rv fd command arg)))))))

(define ioctl
  (case-lambda
   ((fd command)
    (ioctl fd command #f))
   ((fd command arg)
    (define who 'ioctl)
    (with-arguments-validation (who)
	((file-descriptor	fd)
	 (fixnum		command)
	 (fixnum/pointer/false	arg))
      (let ((rv (capi.posix-ioctl fd command arg)))
	(if (unsafe.fx<= 0 rv)
	    rv
	  (raise-errno-error who rv fd command arg)))))))

;;; --------------------------------------------------------------------

(define (dup fd)
  (define who 'dup)
  (with-arguments-validation (who)
      ((file-descriptor  fd))
    (let ((rv (capi.posix-dup fd)))
      (if (unsafe.fx<= 0 rv)
	  rv
	(raise-errno-error who rv fd)))))

(define (dup2 old new)
  (define who 'dup2)
  (with-arguments-validation (who)
      ((file-descriptor  old)
       (file-descriptor  new))
    (let ((rv (capi.posix-dup2 old new)))
      (unless (unsafe.fxzero? rv)
	(raise-errno-error who rv old new)))))

;;; --------------------------------------------------------------------

(define (pipe)
  (define who 'pipe)
  (let ((rv (capi.posix-pipe)))
    (if (pair? rv)
	(values (unsafe.car rv) (unsafe.cdr rv))
      (raise-errno-error who rv))))

(define (mkfifo pathname mode)
  (define who 'pipe)
  (with-arguments-validation (who)
      ((pathname  pathname)
       (fixnum    mode))
    (with-pathnames ((pathname.bv pathname))
      (let ((rv (capi.posix-mkfifo pathname.bv mode)))
	(unless (unsafe.fxzero? rv)
	  (raise-errno-error/filename who rv pathname mode))))))


;;;; sockets

(define (make-sockaddr_un pathname)
  (define who 'make-sockaddr_un)
  (with-arguments-validation (who)
      ((pathname	pathname))
    (with-pathnames ((pathname.bv pathname))
      (capi.posix-make-sockaddr_un pathname.bv))))

(define (sockaddr_un.pathname addr)
  (define who 'sockaddr_un.pathname)
  (with-arguments-validation (who)
      ((bytevector	addr))
    (let ((rv (capi.posix-sockaddr_un.pathname addr)))
      (if (bytevector? rv)
	  rv
	(error who "expected bytevector holding \"struct sockaddr_un\" as argument" addr)))))

(define (sockaddr_un.pathname/string addr)
  ((filename->string-func) (sockaddr_un.pathname addr)))

;;; --------------------------------------------------------------------

(define (make-sockaddr_in addr port)
  (define who 'make-sockaddr_in)
  (with-arguments-validation (who)
      ((bytevector	addr)
       (fixnum		port))
    (capi.posix-make-sockaddr_in addr port)))

(define (sockaddr_in.in_addr sockaddr)
  (define who 'sockaddr_in.in_addr)
  (with-arguments-validation (who)
      ((bytevector	sockaddr))
    (let ((rv (capi.posix-sockaddr_in.in_addr sockaddr)))
      (if (bytevector? rv)
	  rv
	(error who "expected bytevector holding \"struct sockaddr_in\" as argument" sockaddr)))))

(define (sockaddr_in.in_port sockaddr)
  (define who 'sockaddr_in.in_port)
  (with-arguments-validation (who)
      ((bytevector	sockaddr))
    (let ((rv (capi.posix-sockaddr_in.in_port sockaddr)))
      (if (fixnum? rv)
	  rv
	(error who "expected bytevector holding \"struct sockaddr_in\" as argument" sockaddr)))))

;;; --------------------------------------------------------------------

(define (make-sockaddr_in6 addr port)
  (define who 'make-sockaddr_in6)
  (with-arguments-validation (who)
      ((bytevector	addr)
       (fixnum		port))
    (capi.posix-make-sockaddr_in6 addr port)))

(define (sockaddr_in6.in6_addr sockaddr)
  (define who 'sockaddr_in6.in6_addr)
  (with-arguments-validation (who)
      ((bytevector	sockaddr))
    (let ((rv (capi.posix-sockaddr_in6.in6_addr sockaddr)))
      (if (bytevector? rv)
	  rv
	(error who "expected bytevector holding \"struct sockaddr_in6\" as argument" sockaddr)))))

(define (sockaddr_in6.in6_port sockaddr)
  (define who 'sockaddr_in6.in6_port)
  (with-arguments-validation (who)
      ((bytevector	sockaddr))
    (let ((rv (capi.posix-sockaddr_in6.in6_port sockaddr)))
      (if (fixnum? rv)
	  rv
	(error who "expected bytevector holding \"struct sockaddr_in6\" as argument" sockaddr)))))

;;; --------------------------------------------------------------------

(define (in6addr_loopback)
  (capi.posix-in6addr_loopback))

(define (in6addr_any)
  (capi.posix-in6addr_any))

;;; --------------------------------------------------------------------

(define (inet-aton dotted-quad)
  (define who 'inet-aton)
  (with-arguments-validation (who)
      ((string/bytevector  dotted-quad))
    (let ((rv (capi.posix-inet_aton (if (string? dotted-quad)
					(string->utf8 dotted-quad)
				      dotted-quad))))
      (if (bytevector? rv)
	  rv
	(error who
	  "expected string or bytevector holding an ASCII dotted quad as argument"
	  dotted-quad)))))

(define (inet-ntoa addr)
  (define who 'inet-ntoa)
  (with-arguments-validation (who)
      ((bytevector  addr))
    (capi.posix-inet_ntoa addr)))

(define (inet-ntoa/string addr)
  (utf8->string (inet-ntoa addr)))

;;; --------------------------------------------------------------------

(define (inet-pton af presentation)
  (define who 'inet-pton)
  (with-arguments-validation (who)
      ((af-inet		   af)
       (string/bytevector  presentation))
    (let ((rv (capi.posix-inet_pton af (if (string? presentation)
					   (string->utf8 presentation)
					 presentation))))
      (if (bytevector? rv)
	  rv
	(error who "invalid arguments" af presentation)))))

(define (inet-ntop af addr)
  (define who 'inet-ptoa)
  (with-arguments-validation (who)
      ((af-inet	    af)
       (bytevector  addr))
    (let ((rv (capi.posix-inet_ntop af addr)))
      (if (bytevector? rv)
	  rv
	(error who "invalid arguments" af addr)))))

(define (inet-ntop/string af addr)
  (utf8->string (inet-ntop af addr)))

;;; --------------------------------------------------------------------

(define-struct struct-hostent
  (h_name	;0, bytevector, official host name
   h_aliases	;1, list of bytevectors, host name aliases
   h_addrtype	;2, fixnum, AF_INET or AF_INET6
   h_length	;3, length of address bytevector
   h_addr_list	;4, list of bytevectors holding "struct in_addr" or "struct in6_addr"
   h_addr	;5, bytevector, first in the list of host addresses
   ))

(define (%struct-hostent-printer S port sub-printer)
  (define-inline (%display thing)
    (display thing port))
  (%display "#[\"struct-hostent\"")

  (%display " h_name=\"")
  (%display (utf8->string (struct-hostent-h_name S)))
  (%display "\"")

  (%display " h_aliases=")
  (%display (map utf8->string (struct-hostent-h_aliases S)))

  (%display " h_addrtype=")
  (%display (if (unsafe.fx= AF_INET (struct-hostent-h_addrtype S))
		"AF_INET" "AF_INET6"))

  (%display " h_length=")
  (%display (struct-hostent-h_length S))

  (%display " h_addr_list=")
  (%display (struct-hostent-h_addr_list S))

  (%display " h_addr=")
  (%display (struct-hostent-h_addr S))

  (%display "]"))

;;; --------------------------------------------------------------------

(define (gethostbyname hostname)
  (define who 'gethostbyname)
  (with-arguments-validation (who)
      ((string/bytevector  hostname))
    (let ((rv (capi.posix-gethostbyname (type-descriptor struct-hostent)
					(if (bytevector? hostname)
					    hostname
					  (string->utf8 hostname)))))
      (if (fixnum? rv)
	  (raise-h_errno-error who rv hostname)
	(begin
	  (set-struct-hostent-h_addr_list! rv (reverse (struct-hostent-h_addr_list rv)))
	  rv)))))

(define (gethostbyname2 hostname addrtype)
  (define who 'gethostbyname2)
  (with-arguments-validation (who)
      ((string/bytevector  hostname)
       (af-inet		   addrtype))
    (let ((rv (capi.posix-gethostbyname2 (type-descriptor struct-hostent)
					 (if (bytevector? hostname)
					     hostname
					   (string->utf8 hostname))
					 addrtype)))
      (if (fixnum? rv)
	  (raise-h_errno-error who rv hostname addrtype)
	(begin
	  (set-struct-hostent-h_addr_list! rv (reverse (struct-hostent-h_addr_list rv)))
	  rv)))))

(define (gethostbyaddr addr)
  (define who 'gethostbyaddr)
  (with-arguments-validation (who)
      ((bytevector  addr))
    (let ((rv (capi.posix-gethostbyaddr (type-descriptor struct-hostent) addr)))
      (if (fixnum? rv)
	  (raise-h_errno-error who rv addr)
	(begin
	  (set-struct-hostent-h_addr_list! rv (reverse (struct-hostent-h_addr_list rv)))
	  rv)))))

(define (host-entries)
  (capi.posix-host-entries (type-descriptor struct-hostent)))

;;; --------------------------------------------------------------------

(define-struct struct-addrinfo
  (ai_flags		;0, fixnum
   ai_family		;1, fixnum
   ai_socktype		;2, fixnum
   ai_protocol		;3, fixnum
   ai_addrlen		;4, fixnum
   ai_addr		;5, bytevector
   ai_canonname))	;6, false or bytevector

(define (%struct-addrinfo-printer S port sub-printer)
  (define-inline (%display thing)
    (display thing port))
  (%display "#[\"struct-addrinfo\"")
  (%display " ai_flags=")	(%display (struct-addrinfo-ai_flags	S))
  (%display " ai_family=")
  (%display (let ((N (struct-addrinfo-ai_family S)))
	      (cond ((unsafe.fx= N AF_INET)	"AF_INET")
		    ((unsafe.fx= N AF_INET6)	"AF_INET6")
		    ((unsafe.fx= N AF_UNSPEC)	"AF_UNSPEC")
		    (else			N))))
  (%display " ai_socktype=")
  (%display (let ((N (struct-addrinfo-ai_socktype S)))
	      (cond ((unsafe.fx= N SOCK_STREAM)		"SOCK_STREAM")
		    ((unsafe.fx= N SOCK_DGRAM)		"SOCK_DGRAM")
		    ((unsafe.fx= N SOCK_RAW)		"SOCK_RAW")
		    ((unsafe.fx= N SOCK_RDM)		"SOCK_RDM")
		    ((unsafe.fx= N SOCK_SEQPACKET)	"SOCK_SEQPACKET")
		    ((unsafe.fx= N SOCK_DCCP)		"SOCK_DCCP")
		    (else				N))))
  (%display " ai_protocol=")	(%display (struct-addrinfo-ai_protocol	S))
  (%display " ai_addrlen=")	(%display (struct-addrinfo-ai_addrlen	S))
  (%display " ai_addr=")	(%display (struct-addrinfo-ai_addr	S))
  (%display " ai_canonname=")	(let ((name (struct-addrinfo-ai_canonname S)))
				  (if name
				      (begin
					(%display "\"")
					(%display (latin1->string name))
					(%display "\""))
				    (%display #f)))
  (%display "]"))

(define (getaddrinfo node service hints)
  (define who 'getaddrinfo)
  (with-arguments-validation (who)
      ((string/bytevector/false	node)
       (string/bytevector/false	service)
       (addrinfo/false		hints))
    (with-bytevectors/or-false ((node.bv	node)
				(service.bv	service))
      (let ((rv (capi.posix-getaddrinfo (type-descriptor struct-addrinfo)
					node.bv service.bv hints)))
	(if (fixnum? rv)
	    (raise
	     (condition (make-who-condition who)
			(make-message-condition (gai-strerror rv))
			(make-irritants-condition (list node service hints))))
	  rv)))))

(define (gai-strerror code)
  (define who 'gai-strerror)
  (with-arguments-validation (who)
      ((fixnum   code))
    (latin1->string (capi.posix-gai_strerror code))))

;;; --------------------------------------------------------------------

(define-struct struct-protoent
  (p_name p_aliases p_proto))

(define (%struct-protoent-printer S port sub-printer)
  (define-inline (%display thing)
    (display thing port))
  (%display "#[\"struct-protoent\"")
  (%display " p_name=\"")
  (%display (latin1->string (struct-protoent-p_name S)))
  (%display "\"")
  (%display " p_aliases=")
  (%display (map latin1->string (struct-protoent-p_aliases S)))
  (%display " p_proto=")
  (%display (struct-protoent-p_proto S))
  (%display "]"))

(define (getprotobyname name)
  (define who 'getprotobyname)
  (with-arguments-validation (who)
      ((string/bytevector	name))
    (with-bytevectors ((name.bv name))
      (let ((rv (capi.posix-getprotobyname (type-descriptor struct-protoent) name.bv)))
	(if (not rv)
	    (error who "unknown network protocol" name)
	  rv)))))

(define (getprotobynumber number)
  (define who 'getprotobynumber)
  (with-arguments-validation (who)
      ((fixnum	number))
    (let ((rv (capi.posix-getprotobynumber (type-descriptor struct-protoent) number)))
      (if (not rv)
	  (error who "unknown network protocol" number)
	rv))))

(define (protocol-entries)
  (capi.posix-protocol-entries (type-descriptor struct-protoent)))

;;; --------------------------------------------------------------------

(define-struct struct-servent
  (s_name s_aliases s_port s_proto))

(define (%struct-servent-printer S port sub-printer)
  (define-inline (%display thing)
    (display thing port))
  (%display "#[\"struct-servent\"")
  (%display " s_name=\"")
  (%display (latin1->string (struct-servent-s_name S)))
  (%display "\"")
  (%display " s_aliases=")
  (%display (map latin1->string (struct-servent-s_aliases S)))
  (%display " s_port=")
  (%display (struct-servent-s_port S))
  (%display " s_proto=")
  (%display (latin1->string (struct-servent-s_proto S)))
  (%display "]"))

(define servent-rtd
  (type-descriptor struct-servent))

(define (getservbyname name protocol)
  (define who 'getservbyname)
  (with-arguments-validation (who)
      ((string/bytevector	name)
       (string/bytevector	protocol))
    (with-bytevectors ((name.bv		name)
		       (protocol.bv	protocol))
      (let ((rv (capi.posix-getservbyname servent-rtd name.bv protocol.bv)))
	(if (not rv)
	    (error who "unknown network service" name protocol)
	  rv)))))

(define (getservbyport port protocol)
  (define who 'getservbyport)
  (with-arguments-validation (who)
      ((fixnum			port)
       (string/bytevector	protocol))
    (with-bytevectors ((protocol.bv protocol))
      (let ((rv (capi.posix-getservbyport servent-rtd port protocol.bv)))
	(if (not rv)
	    (error who "unknown network service" port protocol)
	  rv)))))

(define (service-entries)
  (capi.posix-service-entries servent-rtd))

;;; --------------------------------------------------------------------

(define-struct struct-netent
  (n_name n_aliases n_addrtype n_net))

(define (%struct-netent-printer S port sub-printer)
  (define-inline (%display thing)
    (display thing port))
  (%display "#[\"struct-netent\"")
  (%display " n_name=\"")
  (%display (latin1->string (struct-netent-n_name S)))
  (%display "\"")
  (%display " n_aliases=")
  (%display (map latin1->string (struct-netent-n_aliases S)))
  (%display " n_addrtype=")
  (%display (let ((type (struct-netent-n_addrtype S)))
	      (cond ((unsafe.fx= type AF_INET)
		     "AF_INET")
		    ((unsafe.fx= type AF_INET6)
		     "AF_INET6")
		    (else type))))
  (%display " n_net=")
  (%display (struct-netent-n_net S))
  (%display "]"))

(define netent-rtd
  (type-descriptor struct-netent))

(define (%netaddr->bytevector S)
  (let ((net (make-bytevector 4)))
    (bytevector-u32-set! net 0 (struct-netent-n_net S) (endianness big))
    (set-struct-netent-n_net! S net)
    S))

(define (getnetbyname name)
  (define who 'getnetbyname)
  (with-arguments-validation (who)
      ((string/bytevector  name))
    (with-bytevectors ((name.bv  name))
      (let ((rv (capi.posix-getnetbyname netent-rtd name.bv)))
	(if (not rv)
	    (error who "unknown network" name)
	  (%netaddr->bytevector rv))))))

(define (getnetbyaddr net type)
  (define who 'getnetbyaddr)
  (with-arguments-validation (who)
      ((netaddr  net)
       (fixnum   type))
    (let* ((net	(if (bytevector? net)
		    (bytevector-u32-ref net 0 (endianness big))
		  net))
	   (rv	(capi.posix-getnetbyaddr netent-rtd net type)))
      (if (not rv)
	  (error who "unknown network" net type)
	(%netaddr->bytevector rv)))))

(define (network-entries)
  (map %netaddr->bytevector (capi.posix-network-entries netent-rtd)))

;;; --------------------------------------------------------------------

(define (socket namespace style protocol)
  (define who 'socket)
  (with-arguments-validation (who)
      ((fixnum	namespace)
       (fixnum	style)
       (fixnum	protocol))
    (let ((rv (capi.posix-socket namespace style protocol)))
      (if (unsafe.fx<= 0 rv)
	  rv
	(raise-errno-error who rv namespace style protocol)))))

(define (shutdown sock how)
  (define who 'shutdown)
  (with-arguments-validation (who)
      ((file-descriptor	sock)
       (fixnum		how))
    (let ((rv (capi.posix-shutdown sock how)))
      (unless (unsafe.fxzero? rv)
	(raise-errno-error who rv sock how)))))

(define (socketpair namespace style protocol)
  (define who 'socketpair)
  (with-arguments-validation (who)
      ((fixnum	namespace)
       (fixnum	style)
       (fixnum	protocol))
    (let ((rv (capi.posix-socketpair namespace style protocol)))
      (if (pair? rv)
	  (values (unsafe.car rv) (unsafe.cdr rv))
	(raise-errno-error who rv namespace style protocol)))))

;;; --------------------------------------------------------------------

(define (connect sock sockaddr)
  (define who 'connect)
  (with-arguments-validation (who)
      ((file-descriptor	sock)
       (bytevector	sockaddr))
    (let ((rv (capi.posix-connect sock sockaddr)))
      (unless (unsafe.fxzero? rv)
	(raise-errno-error who rv sock sockaddr)))))

(define (listen sock max-pending-conns)
  (define who 'listen)
  (with-arguments-validation (who)
      ((file-descriptor	sock)
       (fixnum		max-pending-conns))
    (let ((rv (capi.posix-listen sock max-pending-conns)))
      (unless (unsafe.fxzero? rv)
	(raise-errno-error who rv sock max-pending-conns)))))

(define (accept sock)
  (define who 'accept)
  (with-arguments-validation (who)
      ((file-descriptor	sock))
    (let ((rv (capi.posix-accept sock)))
      (cond ((pair? rv)
	     (values (unsafe.car rv) (unsafe.cdr rv)))
	    ((unsafe.fx= rv EWOULDBLOCK)
	     (values #f #f))
	    (else
	     (raise-errno-error who rv sock))))))

(define (bind sock sockaddr)
  (define who 'bind)
  (with-arguments-validation (who)
      ((file-descriptor	sock)
       (bytevector	sockaddr))
    (let ((rv (capi.posix-bind sock sockaddr)))
      (unless (unsafe.fxzero? rv)
	(raise-errno-error who rv sock sockaddr)))))

;;; --------------------------------------------------------------------

(define (getpeername sock)
  (define who 'getpeername)
  (with-arguments-validation (who)
      ((file-descriptor	sock))
    (let ((rv (capi.posix-getpeername sock)))
      (if (bytevector? rv)
	  rv
	(raise-errno-error who rv sock)))))

(define (getsockname sock)
  (define who 'getsockname)
  (with-arguments-validation (who)
      ((file-descriptor	sock))
    (let ((rv (capi.posix-getsockname sock)))
      (if (bytevector? rv)
	  rv
	(raise-errno-error who rv sock)))))

;;; --------------------------------------------------------------------

(define (send sock buffer size flags)
  (define who 'send)
  (with-arguments-validation (who)
      ((file-descriptor	sock)
       (bytevector	buffer)
       (fixnum/false	size)
       (fixnum		flags))
    (let ((rv (capi.posix-send sock buffer size flags)))
      (if (unsafe.fx<= 0 rv)
	  rv
	(raise-errno-error who rv sock buffer size flags)))))

(define (recv sock buffer size flags)
  (define who 'recv)
  (with-arguments-validation (who)
      ((file-descriptor	sock)
       (bytevector	buffer)
       (fixnum/false	size)
       (fixnum		flags))
    (let ((rv (capi.posix-recv sock buffer size flags)))
      (if (unsafe.fx<= 0 rv)
	  rv
	(raise-errno-error who rv sock buffer size flags)))))

;;; --------------------------------------------------------------------

(define (sendto sock buffer size flags addr)
  (define who 'sendto)
  (with-arguments-validation (who)
      ((file-descriptor	sock)
       (bytevector	buffer)
       (fixnum/false	size)
       (fixnum		flags)
       (bytevector	addr))
    (let ((rv (capi.posix-sendto sock buffer size flags addr)))
      (if (unsafe.fx<= 0 rv)
	  rv
	(raise-errno-error who rv sock buffer size flags addr)))))

(define (recvfrom sock buffer size flags)
  (define who 'recvfrom)
  (with-arguments-validation (who)
      ((file-descriptor	sock)
       (bytevector	buffer)
       (fixnum/false	size)
       (fixnum		flags))
    (let ((rv (capi.posix-recvfrom sock buffer size flags)))
      (if (pair? rv)
	  (values (unsafe.car rv) (unsafe.cdr rv))
	(raise-errno-error who rv sock buffer size flags)))))

;;; --------------------------------------------------------------------

(define (getsockopt sock level option optval)
  (define who 'getsockopt)
  (with-arguments-validation (who)
      ((file-descriptor	sock)
       (fixnum		level)
       (fixnum		option)
       (bytevector	optval))
    (let ((rv (capi.posix-getsockopt sock level option optval)))
      (unless (unsafe.fxzero? rv)
	(raise-errno-error who rv sock level option optval)))))

(define (getsockopt/int sock level option)
  (define who 'getsockopt/int)
  (with-arguments-validation (who)
      ((file-descriptor	sock)
       (fixnum		level)
       (fixnum		option))
    (let ((rv (capi.posix-getsockopt/int sock level option)))
      (if (pair? rv)
	  (unsafe.car rv)
	(raise-errno-error who rv sock level option)))))

(define (getsockopt/size_t sock level option)
  (define who 'getsockopt/size_t)
  (with-arguments-validation (who)
      ((file-descriptor	sock)
       (fixnum		level)
       (fixnum		option))
    (let ((rv (capi.posix-getsockopt/size_t sock level option)))
      (if (pair? rv)
	  (unsafe.car rv)
	(raise-errno-error who rv sock level option)))))

;;; --------------------------------------------------------------------

(define (setsockopt sock level option optval)
  (define who 'setsockopt)
  (with-arguments-validation (who)
      ((file-descriptor	sock)
       (fixnum		level)
       (fixnum		option)
       (bytevector	optval))
    (let ((rv (capi.posix-setsockopt sock level option optval)))
      (unless (unsafe.fxzero? rv)
	(raise-errno-error who rv sock level option optval)))))

(define (setsockopt/int sock level option optval)
  (define who 'setsockopt/int)
  (with-arguments-validation (who)
      ((file-descriptor		sock)
       (fixnum			level)
       (fixnum			option)
       (platform-int/boolean	optval))
    (let ((rv (capi.posix-setsockopt/int sock level option optval)))
      (unless (unsafe.fxzero? rv)
	(raise-errno-error who rv sock level option optval)))))

(define (setsockopt/size_t sock level option optval)
  (define who 'setsockopt/size_t)
  (with-arguments-validation (who)
      ((file-descriptor	sock)
       (fixnum		level)
       (fixnum		option)
       (platform-size_t	optval))
    (let ((rv (capi.posix-setsockopt/size_t sock level option optval)))
      (unless (unsafe.fxzero? rv)
	(raise-errno-error who rv sock level option optval)))))

;;; --------------------------------------------------------------------

(define (setsockopt/linger sock onoff linger)
  (define who 'setsockopt/linger)
  (with-arguments-validation (who)
      ((file-descriptor		sock)
       (boolean			onoff)
       (fixnum			linger))
    (let ((rv (capi.posix-setsockopt/linger sock onoff linger)))
      (unless (unsafe.fxzero? rv)
	(raise-errno-error who rv sock onoff linger)))))

(define (getsockopt/linger sock)
  (define who 'getsockopt/linger)
  (with-arguments-validation (who)
      ((file-descriptor  sock))
    (let ((rv (capi.posix-getsockopt/linger sock)))
      (if (pair? rv)
	  (values (unsafe.car rv) (unsafe.cdr rv))
	(raise-errno-error who rv sock)))))


;;;; users and groups

(define (getuid)
  (capi.posix-getuid))

(define (getgid)
  (capi.posix-getgid))

(define (geteuid)
  (capi.posix-geteuid))

(define (getegid)
  (capi.posix-getegid))

(define (getgroups)
  (let ((rv (capi.posix-getgroups)))
    (if (pair? rv)
	rv
      (raise-errno-error 'getgroups rv))))

;;; --------------------------------------------------------------------

(define (seteuid uid)
  (define who 'seteuid)
  (with-arguments-validation (who)
      ((fixnum	uid))
    (let ((rv (capi.posix-seteuid uid)))
      (unless (unsafe.fxzero? rv)
	(raise-errno-error who rv uid)))))

(define (setuid uid)
  (define who 'setuid)
  (with-arguments-validation (who)
      ((fixnum	uid))
    (let ((rv (capi.posix-setuid uid)))
      (unless (unsafe.fxzero? rv)
	(raise-errno-error who rv uid)))))

(define (setreuid real-uid effective-uid)
  (define who 'setreuid)
  (with-arguments-validation (who)
      ((fixnum	real-uid)
       (fixnum	effective-uid))
    (let ((rv (capi.posix-setreuid real-uid effective-uid)))
      (unless (unsafe.fxzero? rv)
	(raise-errno-error who rv real-uid effective-uid)))))

;;; --------------------------------------------------------------------

(define (setegid gid)
  (define who 'setegid)
  (with-arguments-validation (who)
      ((fixnum	gid))
    (let ((rv (capi.posix-setegid gid)))
      (unless (unsafe.fxzero? rv)
	(raise-errno-error who rv gid)))))

(define (setgid gid)
  (define who 'setgid)
  (with-arguments-validation (who)
      ((fixnum	gid))
    (let ((rv (capi.posix-setgid gid)))
      (unless (unsafe.fxzero? rv)
	(raise-errno-error who rv gid)))))

(define (setregid real-gid effective-gid)
  (define who 'setregid)
  (with-arguments-validation (who)
      ((fixnum	real-gid)
       (fixnum	effective-gid))
    (let ((rv (capi.posix-setregid real-gid effective-gid)))
      (unless (unsafe.fxzero? rv)
	(raise-errno-error who rv real-gid effective-gid)))))

;;; --------------------------------------------------------------------

(define (getlogin)
  (capi.posix-getlogin))

(define (getlogin/string)
  (let ((rv (capi.posix-getlogin)))
    (and rv (latin1->string rv))))

;;; --------------------------------------------------------------------

(define-struct struct-passwd
  (pw_name	;0, bytevector, user login name
   pw_passwd	;1, bytevector, encrypted password
   pw_uid	;2, fixnum, user ID
   pw_gid	;3, fixnum, group ID
   pw_gecos	;4, bytevector, user data
   pw_dir	;5, bytevector, user's home directory
   pw_shell	;6, bytevector, user's default shell
   ))

(define (%struct-passwd-printer S port sub-printer)
  (define-inline (%display thing)
    (display thing port))
  (%display "#[\"struct-passwd\"")
  (%display " pw_name=\"")	(%display (latin1->string (struct-passwd-pw_name S)))  (%display "\"")
  (%display " pw_passwd=\"")	(%display (latin1->string (struct-passwd-pw_passwd S))) (%display "\"")
  (%display " pw_uid=")		(%display (struct-passwd-pw_uid S))
  (%display " pw_gid=")		(%display (struct-passwd-pw_gid S))
  (%display " pw_gecos=\"")	(%display (latin1->string (struct-passwd-pw_gecos S))) (%display "\"")
  (%display " pw_dir=\"")	(%display (latin1->string (struct-passwd-pw_dir S)))   (%display "\"")
  (%display " pw_shell=\"")	(%display (latin1->string (struct-passwd-pw_shell S))) (%display "\"")
  (%display "]"))

(define passwd-rtd
  (type-descriptor struct-passwd))

(define (getpwuid uid)
  (define who 'getpwuid)
  (with-arguments-validation (who)
      ((fixnum	uid))
    (capi.posix-getpwuid passwd-rtd uid)))

(define (getpwnam name)
  (define who 'getpwnam)
  (with-arguments-validation (who)
      ((string/bytevector  name))
    (with-bytevectors ((name.bv name))
      (capi.posix-getpwnam passwd-rtd name.bv))))

(define (user-entries)
  (capi.posix-user-entries passwd-rtd))

;;; --------------------------------------------------------------------

(define-struct struct-group
  (gr_name	;0, bytevector, group name
   gr_gid	;1, fixnum, group ID
   gr_mem	;2, list of bytevectors, user names
   ))

(define (%struct-group-printer S port sub-printer)
  (define-inline (%display thing)
    (display thing port))
  (%display "#[\"struct-group\"")
  (%display " gr_name=\"")	(%display (latin1->string (struct-group-gr_name S)))  (%display "\"")
  (%display " gr_gid=")		(%display (struct-group-gr_gid S))
  (%display " gr_mem=")
  (%display (map latin1->string (struct-group-gr_mem S)))
  (%display "]"))

(define group-rtd
  (type-descriptor struct-group))

(define (getgrgid gid)
  (define who 'getgrgid)
  (with-arguments-validation (who)
      ((fixnum	gid))
    (capi.posix-getgrgid group-rtd gid)))

(define (getgrnam name)
  (define who 'getgrnam)
  (with-arguments-validation (who)
      ((string/bytevector  name))
    (with-bytevectors ((name.bv name))
      (capi.posix-getgrnam group-rtd name.bv))))

(define (group-entries)
  (capi.posix-group-entries group-rtd))


;;;; job control

(define (ctermid)
  (capi.posix-ctermid))

(define (ctermid/string)
  (latin1->string (capi.posix-ctermid)))

;;; --------------------------------------------------------------------

(define (setsid)
  (define who 'setsid)
  (let ((rv (capi.posix-setsid)))
    (if (unsafe.fx<= 0 rv)
	rv
      (raise-errno-error who rv))))

(define (getsid pid)
  (define who 'getsid)
  (with-arguments-validation (who)
      ((fixnum  pid))
    (let ((rv (capi.posix-getsid pid)))
      (if (unsafe.fx<= 0 rv)
	  rv
	(raise-errno-error who rv pid)))))

(define (getpgrp)
  (define who 'getpgrp)
  (let ((rv (capi.posix-getpgrp)))
    (if (unsafe.fx<= 0 rv)
	rv
      (raise-errno-error who rv))))

(define (setpgid pid pgid)
  (define who 'setpgid)
  (with-arguments-validation (who)
      ((fixnum  pid)
       (fixnum  pgid))
    (let ((rv (capi.posix-setpgid pid pgid)))
      (if (unsafe.fx<= 0 rv)
	  rv
	(raise-errno-error who rv pid pgid)))))

;;; --------------------------------------------------------------------

(define (tcgetpgrp fd)
  (define who 'tcgetpgrp)
  (with-arguments-validation (who)
      ((file-descriptor	fd))
    (let ((rv (capi.posix-tcgetpgrp fd)))
      (if (unsafe.fx<= 0 rv)
	  rv
	(raise-errno-error who rv fd)))))

(define (tcsetpgrp fd pgid)
  (define who 'tcsetpgrp)
  (with-arguments-validation (who)
      ((file-descriptor	fd)
       (fixnum		pgid))
    (let ((rv (capi.posix-tcsetpgrp fd pgid)))
      (unless (unsafe.fx<= 0 rv)
	(raise-errno-error who rv fd pgid)))))

(define (tcgetsid fd)
  (define who 'tcgetsid)
  (with-arguments-validation (who)
      ((file-descriptor	fd))
    (let ((rv (capi.posix-tcgetsid fd)))
      (if (unsafe.fx<= 0 rv)
	  rv
	(raise-errno-error who rv fd)))))


;;;; time functions

(define-struct struct-timeval
  (tv_sec tv_usec))

(define (%struct-timeval-printer S port sub-printer)
  (define-inline (%display thing)
    (display thing port))
  (%display "#[\"struct-timeval\"")
  (%display " tv_sec=")		(%display (struct-timeval-tv_sec  S))
  (%display " tv_usec=")	(%display (struct-timeval-tv_usec S))
  (%display "]"))

;;; --------------------------------------------------------------------

(define-struct struct-timespec
  (tv_sec tv_nsec))

(define (%struct-timespec-printer S port sub-printer)
  (define-inline (%display thing)
    (display thing port))
  (%display "#[\"struct-timespec\"")
  (%display " tv_sec=")		(%display (struct-timespec-tv_sec  S))
  (%display " tv_nsec=")	(%display (struct-timespec-tv_nsec S))
  (%display "]"))

;;; --------------------------------------------------------------------

(define-struct struct-tms
  (tms_utime	;0, exact integer
   tms_stime	;1, exact integer
   tms_cutime	;2, exact integer
   tms_cstime	;3, exact integer
   ))

(define tms-rtd
  (type-descriptor struct-tms))

(define (%struct-tms-printer S port sub-printer)
  (define-inline (%display thing)
    (display thing port))
  (%display "#[\"struct-tms\"")
  (%display " tms_utime=")	(%display (struct-tms-tms_utime  S))
  (%display " tms_stime=")	(%display (struct-tms-tms_stime  S))
  (%display " tms_cutime=")	(%display (struct-tms-tms_cutime S))
  (%display " tms_cstime=")	(%display (struct-tms-tms_cstime S))
  (%display "]"))

;;; --------------------------------------------------------------------

(define-struct struct-tm
  (tm_sec	;0, exact integer
   tm_min	;1, exact integer
   tm_hour	;2, exact integer
   tm_mday	;3, exact integer
   tm_mon	;4, exact integer
   tm_year	;5, exact integer
   tm_wday	;6, exact integer
   tm_yday	;7, exact integer
   tm_isdst	;8, boolean
   tm_gmtoff	;9, exact integer
   tm_zone	;10, bytevector
   ))

(define (%struct-tm-printer S port sub-printer)
  (define-inline (%display thing)
    (display thing port))
  (%display "#[\"struct-tm\"")
  (%display " tm_sec=")		(%display (struct-tm-tm_sec    S))
  (%display " tm_min=")		(%display (struct-tm-tm_min    S))
  (%display " tm_hour=")	(%display (struct-tm-tm_hour   S))
  (%display " tm_mday=")	(%display (struct-tm-tm_mday   S))
  (%display " tm_mon=")		(%display (struct-tm-tm_mon    S))
  (%display " (normalised=")	(%display (+ 1 (struct-tm-tm_mon    S))) (%display ")")
  (%display " tm_year=")	(%display (struct-tm-tm_year   S))
  (%display " (normalised=")	(%display (+ 1900 (struct-tm-tm_year S))) (%display ")")
  (%display " tm_wday=")	(%display (struct-tm-tm_wday   S))
  (%display " tm_yday=")	(%display (struct-tm-tm_yday   S))
  (%display " tm_isdst=")	(%display (struct-tm-tm_isdst  S))
  (%display " tm_gmtoff=")	(%display (struct-tm-tm_gmtoff S))
  (%display " tm_zone=")	(%display (latin1->string (struct-tm-tm_zone S)))
  (%display "]"))

;;; --------------------------------------------------------------------

(define (clock)
  (exact (capi.posix-clock)))

(define (times)
  (let ((S (capi.posix-times tms-rtd)))
    (set-struct-tms-tms_utime!  S (exact (struct-tms-tms_utime  S)))
    (set-struct-tms-tms_stime!  S (exact (struct-tms-tms_stime  S)))
    (set-struct-tms-tms_cutime! S (exact (struct-tms-tms_cutime S)))
    (set-struct-tms-tms_cstime! S (exact (struct-tms-tms_cstime S)))
    S))

;;; --------------------------------------------------------------------

(define (posix-time)
  (exact (capi.posix-time)))

(define (gettimeofday)
  (define who 'gettimeofday)
  (let ((rv (capi.posix-gettimeofday (type-descriptor struct-timeval))))
    (if (struct-timeval? rv)
	rv
      (raise-errno-error who rv))))

;;; --------------------------------------------------------------------

(define (localtime time)
  (define who 'localtime)
  (with-arguments-validation (who)
      ((exact-integer	time))
    (let ((rv (capi.posix-localtime (type-descriptor struct-tm) time)))
      (or rv
	  (raise-posix-error who "invalid time specification" time)))))

(define (gmtime time)
  (define who 'gmtime)
  (with-arguments-validation (who)
      ((exact-integer	time))
    (let ((rv (capi.posix-gmtime (type-descriptor struct-tm) time)))
      (or rv
	  (raise-posix-error who "invalid time specification" time)))))

(define (timelocal tm)
  (define who 'timelocal)
  (with-arguments-validation (who)
      ((struct-tm  tm))
    (let ((rv (capi.posix-timelocal tm)))
      (if rv
	  (exact rv)
	(raise-posix-error who "invalid broken time specification" tm)))))

(define (timegm tm)
  (define who 'timegm)
  (with-arguments-validation (who)
      ((struct-tm  tm))
    (let ((rv (capi.posix-timegm tm)))
      (if rv
	  (exact rv)
	(raise-posix-error who "invalid broken time specification" tm)))))

(define (strftime template tm)
  (define who 'strftime)
  (with-arguments-validation (who)
      ((string/bytevector  template)
       (struct-tm          tm))
    (with-bytevectors ((template.bv template))
      (let ((rv (capi.posix-strftime template.bv tm)))
	(or rv
	    (raise-posix-error who "invalid time conversion request" template tm))))))

(define (strftime/string template tm)
  (let ((rv (strftime template tm)))
    (and rv (latin1->string rv))))

;;; --------------------------------------------------------------------

(define (nanosleep secs nsecs)
  (define who 'nanosleep)
  (with-arguments-validation (who)
      ((secs	secs)
       (nsecs	nsecs))
    (let ((rv (capi.posix-nanosleep secs nsecs)))
      (if (pair? rv)
	  (values (car rv) (cdr rv))
	(raise-errno-error who rv secs nsecs)))))


;;;; miscellaneous functions

(define (file-descriptor? obj)
  (%file-descriptor? obj))


;;;; done

(set-rtd-printer! (type-descriptor struct-stat)		%struct-stat-printer)
(set-rtd-printer! (type-descriptor directory-stream)	%directory-stream-printer)
(set-rtd-printer! (type-descriptor struct-hostent)	%struct-hostent-printer)
(set-rtd-printer! (type-descriptor struct-addrinfo)	%struct-addrinfo-printer)
(set-rtd-printer! (type-descriptor struct-protoent)	%struct-protoent-printer)
(set-rtd-printer! (type-descriptor struct-servent)	%struct-servent-printer)
(set-rtd-printer! (type-descriptor struct-netent)	%struct-netent-printer)
(set-rtd-printer! (type-descriptor struct-passwd)	%struct-passwd-printer)
(set-rtd-printer! (type-descriptor struct-group)	%struct-group-printer)
(set-rtd-printer! (type-descriptor struct-timeval)	%struct-timeval-printer)
(set-rtd-printer! (type-descriptor struct-timespec)	%struct-timespec-printer)
(set-rtd-printer! (type-descriptor struct-tms)		%struct-tms-printer)
(set-rtd-printer! (type-descriptor struct-tm)		%struct-tm-printer)

)

;;; end of file
;; Local Variables:
;; eval: (put 'with-pathnames 'scheme-indent-function 1)
;; eval: (put 'with-bytevectors 'scheme-indent-function 1)
;; eval: (put 'with-bytevectors/or-false 'scheme-indent-function 1)
;; End:
