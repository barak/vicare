;;;
;;;Part of: Vicare Scheme
;;;Contents: tags implementation
;;;Date: Fri May 18, 2012
;;;
;;;Abstract
;;;
;;;	This library implements the syntaxes defining classes and labels
;;;	for  "object-oriented perfumed  programming" (OOPP).   With this
;;;	library  Scheme does  not  really become  an  OOP language;  the
;;;	coding style  resulting from using these features  is similar to
;;;	using "void  *" pointers in the  C language and  casting them to
;;;	some structure pointer type when needed.
;;;
;;;Copyright (C) 2012-2014 Marco Maggi <marco.maggi-ipsu@poste.it>
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


#!vicare
(library (nausicaa language oopp (0 4))
  (options visit-upon-loading)
  (export
    define-label		define-class		define-mixin
    make-from-fields		is-a?
    slot-set!			slot-ref
    tag-unique-identifiers

    define/tags			define-values/tags
    lambda/tags
    case-lambda/tags		case-define/tags
    with-tags			begin/tags
    let/tags			let*/tags
    letrec/tags			letrec*/tags
    let-values/tags		let*-values/tags
    receive/tags		receive-and-return/tags
    do/tags			do*/tags
    tag-case
    set!/tags
    with-label-shadowing
    with-tagged-arguments-validation

    <top> <top>? <top>-unique-identifiers
    <procedure>

    ;; conditions
    &tagged-binding-violation
    make-tagged-binding-violation
    tagged-binding-violation?

    ;; auxiliary syntaxes
    => brace
    (deprefix (aux.parent		aux.nongenerative	aux.abstract
	       aux.sealed		aux.opaque		aux.predicate
	       aux.fields		aux.virtual-fields
	       aux.mutable		aux.immutable		aux.method
	       aux.method-syntax	aux.methods		aux.protocol
	       aux.public-protocol	aux.super-protocol	aux.maker
	       aux.finaliser		aux.getter		aux.setter
	       aux.shadows		aux.satisfies		aux.mixins
	       aux.<>			aux.<-)
	      aux.))
  (import (vicare (0 4))
    (for (prefix (vicare expander object-type-specs)
		 typ.)
      expand)
    (prefix (only (vicare expander tags)
		  <top>)
	    typ.)
    (nausicaa language oopp auxiliary-syntaxes (0 4))
    (nausicaa language oopp conditions (0 4))
    (for (prefix (nausicaa language oopp oopp-syntax-helpers (0 4))
    		 syntax-help.)
    	 expand)
    (for (prefix (nausicaa language oopp definition-parser-helpers (0 4))
		 parser-help.)
	 expand)
    (for (prefix (only (nausicaa language oopp configuration (0 4))
		       validate-tagged-values?)
		 config.)
	 expand)
    (prefix (only (nausicaa language auxiliary-syntaxes (0 4))
		  <>			<-
		  parent		nongenerative
		  sealed		opaque
		  predicate		abstract
		  fields		virtual-fields
		  mutable		immutable
		  method		method-syntax		methods
		  protocol		public-protocol		super-protocol
		  getter		setter
		  shadows		satisfies
		  mixins		maker			finaliser)
	    aux.)
    (vicare unsafe operations))


(define-record-type (<top>-record-type make-<top> <top>?)
  ;;This is the super class of all the classes and labels.
  ;;
  ;;This type has  fields, but their use is restricted  to this library;
  ;;their existence must be hidden  from the subclasses of "<top>".  For
  ;;this reason we cannot use the  default protocol defined by this form
  ;;to build instances  of "<top>"; rather we  use the "<top>-super-rcd"
  ;;defined below which defines default values for the fields.
  ;;
  (nongenerative nausicaa:builtin:<top>)
  (fields (mutable unique-identifiers <top>-unique-identifiers <top>-unique-identifiers-set!)
		;List  of  UIDs identifying  the  subclass  to which  an
		;instance  belongs.   This  field is  used  to  speed-up
		;dispatching  of  multimethods:  we accept  the  greater
		;memory  usage  to  allow  some more  speed  in  generic
		;functions.
	  ))

(define <top>-super-rcd
  ;;We need a  constructor for "<top>", to be  used as super-constructor
  ;;by   subclasses    of   "<top>",   that   initialises    the   field
  ;;UNIQUE-IDENTIFIERS, hiding it from the subclass's constructors.
  ;;
  (make-record-constructor-descriptor
   (record-type-descriptor <top>-record-type) #f
   (lambda (make-instance)
     (lambda ()
       (make-instance '())))))

(define (<top>-predicate obj)
  ;;This  function is  used as  predicate for  "<top>" in  place of  the
  ;;predefined  "<top>?".   By  convention:   all  the  objects  in  the
  ;;(nausicaa) language are instances of "<top>".
  ;;
  #t)

(define-syntax <top>
  (let ()
    (typ.set-identifier-object-type-spec! #'<top>
      (typ.make-object-type-spec #'<top> #'typ.<top> #'<top>-predicate))
    (lambda (stx)
      ;;Tag syntax for "<top>", all the operations involving this tag go
      ;;through this syntax.  This tag is  the supertag of all the class
      ;;and label tags.
      ;;
      ;;In all the branches:
      ;;
      ;;* ?EXPR  must be an  expression to  be evaluated only  once; its
      ;;result must be an instance of  the subtag type.  ?EXPR can be an
      ;;identifier  but  also  the  application of  an  accessor  to  an
      ;;instance.
      ;;
      ;;*  ?VAR must  be the  identifier  bound to  the instance  syntax
      ;;dispatcher.
      ;;
      (case-define synner
	((message)
	 (syntax-violation '<top> message stx #f))
	((message subform)
	 (syntax-violation '<top> message stx subform)))
      (syntax-case stx ( ;;
			:flat-oopp-syntax
			:define :make :make-from-fields :is-a?
			:dispatch :mutator :getter :setter
			:insert-parent-clause define-record-type
			:insert-constructor-fields lambda
			:super-constructor-descriptor :assert-type-and-return
			:assert-procedure-argument :assert-expression-return-value
			:append-unique-id :list-of-unique-ids
			:predicate-function :accessor-function :mutator-function
			aux.<>)

	;;This is special for "<top>":
	;;
	((_ #:oopp-syntax (??expr ??arg ...))
	 (synner "undefined OOPP syntax"))

	;;This is special for "<top>":
	;;
	((_ :flat-oopp-syntax ??expr)
	 #'??expr)
	((_ :flat-oopp-syntax ??expr ??arg ...)
	 #'(??expr ??arg ...))

	((_ :define ?var ?expr)
	 (identifier? #'?var)
	 #'(define ?var ?expr))

	((_ :define ?var)
	 (identifier? #'?var)
	 #'(define ?var))

	((_ :make . ?args)
	 (synner "invalid maker call syntax for <top> tag"))

	((_ :make-from-fields . ?args)
	 (synner "invalid :make-from-fields call syntax for <top> tag"))

	;;Every  object  is of  type  "<top>"  by  definition.  We  have  to
	;;evaluate the given expression for its side effects.
	((_ :is-a? aux.<>)
	 #'<top>-predicate)
	((_ :is-a? ?expr)
	 #'(begin
	     ?expr
	     #t))

	;;If a  "<top>" value receives  a dispatch  request: what do  we do?
	;;Raise an error because "<top>" has no members.
	((_ :dispatch (?expr . ?args))
	 (synner "invalid tag member"))

	((_ :mutator ?expr ?field-name ?value)
	 (synner "invalid tag-syntax field-mutator request"))

	((_ :getter (?expr . ?args))
	 (synner "invalid tag-syntax getter request"))

	((_ :setter (?expr . ?args))
	 (synner "invalid tag-syntax setter request"))

	;;Given an R6RS record type definition: insert an appropriate PARENT
	;;clause so that the type is derived from "<top>-record-type".
	((_ :insert-parent-clause (define-record-type ?name . ?clauses))
	 #'(define-record-type ?name (parent <top>-record-type) . ?clauses))

	;;For common  tags: this rule should  insert the field names  in the
	;;appropriate  position  in  the  definition of  a  custom  protocol
	;;function.   But this  is the  "<top>" tag  which keeps  hidden its
	;;fields, so just return the input expression.
	((_ :insert-constructor-fields (lambda (make-parent-1)
					 (lambda (V ...)
					   ((make-parent-2 W ...) Z ...))))
	 #'(lambda (make-parent-1)
	     (lambda (V ...)
	       ((make-parent-2 W ...) Z ...))))

	((_ :super-constructor-descriptor)
	 #'<top>-super-rcd)

	;;This is  used for values  validation by tagged variables;  it must
	;;work like the  R6RS ASSERT syntax.  By convention:  all the values
	;;are of type "<top>", so we just evaluate the expression and return
	;;its value.
	((_ :assert-type-and-return ?expr)
	 #'?expr)
	((_ :assert-procedure-argument ?expr)
	 #'(void))
	((_ :assert-expression-return-value ?expr)
	 #'?expr)

	((_ :append-unique-id (?id ...))
	 #'(quote (?id ... nausicaa:builtin:<top>)))

	((_ :list-of-unique-ids)
	 ;;This is the list of UIDs for the type "<top>".
	 #'(quote (nausicaa:builtin:<top>)))

	((_ :predicate-function)
	 #'<top>-predicate)

	;;The tag "<top>" has no accessible fields.
	((_ :accessor-function ?field-name)
	 (identifier? #'?field-name)
	 (synner "invalid tag-syntax field accessor function request" #'?field-name))

	;;The tag "<top>" has no accessible fields.
	((_ :mutator-function ?field-name)
	 (identifier? #'?field-name)
	 (synner "invalid tag-syntax field mutator function request" #'?field-name))

	(_
	 (syntax-help.tag-public-syntax-transformer stx #f #'set!/tags synner))))))


;;;; procedure label

(define <procedure>-list-of-uids
  ;;We really want a binding for this list.
  ;;
  (<top> :append-unique-id (nausicaa:builtin:<procedure>)))

(define-syntax <procedure>
  (let ()
    (typ.set-identifier-object-type-spec! #'<procedure>
      (typ.make-object-type-spec #'<procedure> #'<top> #'procedure?))
    (lambda (stx)
      (case-define synner
	((message)
	 (syntax-violation '<procedure> message stx #f))
	((message subform)
	 (syntax-violation '<procedure> message stx subform)))
      (define (%the-setter-and-getter . args)
	(synner "invalid OOPP syntax"))
      (syntax-case stx ( ;;
			:make :dispatch :mutator :append-unique-id
			:accessor-function :mutator-function
			:process-shadowed-identifier)

	;;This clause is special for "<procedure>".
	((_ #:nested-oopp-syntax ?expr)
	 #'?expr)

	((_ :dispatch (?expr ?id . ?args))
	 (synner "invalid OOPP syntax"))

	((_ :mutator ?expr ?field-name ?value)
	 (synner "invalid OOPP syntax"))

	((_ :make ?expr)
	 #'?expt)

	((_ :append-unique-id (?id ...))
	 #'(<top> :append-unique-id (?id ... nausicaa:builtin:<procedure>)))

	((_ :accessor-function ?field-name)
	 (synner "invalid OOPP syntax"))

	((_ :mutator-function ?field-name)
	 (synner "invalid OOPP syntax"))

	((_ :process-shadowed-identifier ?body0 ?body ...)
	 (synner "invalid OOPP syntax"))

	(_
	 (syntax-help.tag-private-common-syntax-transformer
	  stx #f #'values #'procedure? #'<procedure>-list-of-uids
	  %the-setter-and-getter %the-setter-and-getter
	  (lambda ()
	    (syntax-help.tag-public-syntax-transformer stx #f #'set!/tags synner))))))))


(define-syntax* (define-label stx)
  ;;Define a new label type.  After  all the processing: expand to a set
  ;;of syntax definitions and  miscellaneous bindings for predicates and
  ;;constructors.
  ;;
  (lambda (ctv-retriever)
    (define spec   (parser-help.parse-label-definition stx #'<top> #'lambda/tags ctv-retriever synner))
    (define tag-id (parser-help.<parsed-spec>-name-id spec))
    (with-syntax
	((THE-TAG			tag-id)
	 (THE-PARENT			(parser-help.<parsed-spec>-parent-id spec))
	 (THE-PUBLIC-CONSTRUCTOR	(parser-help.<parsed-spec>-public-constructor-id spec))
	 (THE-PUBLIC-PREDICATE		(parser-help.<parsed-spec>-public-predicate-id   spec))
	 (THE-PRIVATE-PREDICATE		(parser-help.<parsed-spec>-private-predicate-id  spec))
	 (THE-LIST-OF-UIDS		(parser-help.<parsed-spec>-list-of-uids-id       spec))
	 (NONGENERATIVE-UID		(parser-help.<parsed-spec>-nongenerative-uid     spec))

	 (((IMMUTABLE-FIELD IMMUTABLE-ACCESSOR IMMUTABLE-TAG) ...)
	  (parser-help.<parsed-spec>-immutable-fields-data spec))

	 (((MUTABLE-FIELD MUTABLE-ACCESSOR MUTABLE-MUTATOR MUTABLE-TAG) ...)
	  (parser-help.<parsed-spec>-mutable-fields-data spec))

	 (((METHOD-NAME METHOD-RV-TAG METHOD-IMPLEMENTATION) ...)
	  (parser-help.<parsed-spec>-methods-table spec))

	 (SHADOWED-IDENTIFIER
	  (parser-help.<parsed-spec>-shadowed-identifier spec))

	 ((DEFINITION ...)
	  (parser-help.<parsed-spec>-definitions spec))

	 (ACCESSOR-TRANSFORMER
	  (syntax-help.make-accessor-transformer spec))

	 (MUTATOR-TRANSFORMER
	  (syntax-help.make-mutator-transformer  spec))

	 (MAKER-TRANSFORMER
	  (parser-help.<parsed-spec>-maker-transformer spec))

	 ((SATISFACTION ...)
	  (parser-help.<parsed-spec>-satisfactions spec))
	 (SATISFACTION-CLAUSES
	  (parser-help.<label-spec>-satisfaction-clauses spec)))
      (with-syntax
	  ((THE-PUBLIC-PROTOCOL-EXPR
	    ;;Labels  have  no   record-type  descriptor,  so,  strictly
	    ;;speaking, we do  not need to follow  the same construction
	    ;;protocol   of   R6RS   records;   but   uniformity   makes
	    ;;understanding easier, so  the label construction protocols
	    ;;are similar to those of proper records.
	    (or (parser-help.<parsed-spec>-public-protocol spec)
		(parser-help.<parsed-spec>-common-protocol spec)
		#'(lambda ()
		    (lambda args
		      (assertion-violation 'THE-TAG
			"no constructor defined for label" 'THE-TAG args)))))

	   (PREDICATE-EXPR
	    ;;The  predicate  expression  must evaluate  to  a  function
	    ;;predicate for instances of this  tag.  We must check first
	    ;;the parent  tag's predicate,  then the predicate  for this
	    ;;label; the "<top>" tag has no predicate.
	    ;;
	    ;;NOTE Remember  that the  PREDICATE clause can  also select
	    ;;the binding of a syntax; we  have no way to distinguish if
	    ;;THE-PRIVATE-PREDICATE is  a syntax's keyword  or something
	    ;;else,  so we  always have  to create  a function  here, we
	    ;;cannot  just return  THE-PRIVATE-PREDICATE when  it is  an
	    ;;identifier.
	    (let ((has-priv-id? (syntax->datum #'THE-PRIVATE-PREDICATE)))
	      (cond ((free-identifier=? #'THE-PARENT #'<top>)
		     ;;The parent is "<top>": we just use for this tag's
		     ;;predicate, if any was selected.
		     (if has-priv-id?
			 #'(lambda (obj)
			     (THE-PRIVATE-PREDICATE obj))
		       #'(lambda (obj) #t)))
		    (has-priv-id?
		     ;;The parent is not "<top>" and this tag definition
		     ;;selects a predicate: apply the parent's predicate
		     ;;first, than this tag's one.
		     #'(lambda (obj)
			 (and (THE-PARENT :is-a? obj)
			      (THE-PRIVATE-PREDICATE obj))))
		    (else
		     ;;The parent is not "<top>" and this tag definition
		     ;;does  not  select  a predicate:  just  apply  the
		     ;;parent's predicate.
		     #'(lambda (obj)
			 (THE-PARENT :is-a? obj))))))

	   (GETTER-TRANSFORMER
	    ;;If no getter syntax is defined for this label: use the one
	    ;;of  the parent.   The getter  of "<top>"  raises a  syntax
	    ;;violation error.
	    (or (parser-help.<parsed-spec>-getter spec)
		#'(lambda (stx unused-tag)
		    #`(THE-PARENT :getter #,stx))))

	   (SETTER-TRANSFORMER
	    ;;If no setter syntax is defined for this label: use the one
	    ;;of  the parent.   The setter  of "<top>"  raises a  syntax
	    ;;violation error.
	    (or (parser-help.<parsed-spec>-setter spec)
		#'(lambda (stx unused-tag)
		    #`(THE-PARENT :setter #,stx)))))

	#'(begin

	    (define THE-PUBLIC-CONSTRUCTOR
	      (THE-PUBLIC-PROTOCOL-EXPR))

	    (define THE-PUBLIC-PREDICATE PREDICATE-EXPR)

	    (define THE-LIST-OF-UIDS
	      (THE-PARENT :append-unique-id (NONGENERATIVE-UID)))

	    (define-syntax THE-TAG
	      ;;Tag  syntax, all  the operations  involving this  tag go
	      ;;through this syntax.  For all the patterns:
	      ;;
	      ;;*  ??EXPR must  be an  expression to  be evaluated  only
	      ;;once; its  result must be  an instance of the  tag type.
	      ;;??EXPR can be an identifier  but also the application of
	      ;;an accessor to an instance.
	      ;;
	      ;;* ??VAR  must be  the identifier  bound to  the instance
	      ;;syntax dispatcher.
	      ;;
	      (let ((%the-getter	(lambda (stx)
					  (GETTER-TRANSFORMER stx #'THE-TAG)))
		    (%the-setter	(lambda (stx)
					  (SETTER-TRANSFORMER stx #'THE-TAG)))
		    (%the-accessor	ACCESSOR-TRANSFORMER)
		    (%the-mutator	MUTATOR-TRANSFORMER)
		    (%the-maker		MAKER-TRANSFORMER))
		(let ()
		  (define (%constructor-maker input-form.stx)
		    #f)
		  (define (%accessor-maker field.sym input-form.stx)
		    #f)
		  (define (%mutator-maker field.sym input-form.stx)
		    #f)
		  (define (%getter-maker keys.stx input-form.stx)
		    #f)
		  (define (%setter-maker keys.stx input-form.stx)
		    #f)
		  (define %caster-maker #f)
		  (define (%dispatcher method-sym arg*.stx input-form-stx)
		    #f)
		  (define type-spec
		    (typ.make-object-type-spec #'THE-TAG #'THE-PARENT #'THE-PUBLIC-PREDICATE
					       %constructor-maker
					       %accessor-maker %mutator-maker
					       %getter-maker %setter-maker
					       %caster-maker %dispatcher))
		  (typ.set-identifier-object-type-spec! #'THE-TAG type-spec))

		(lambda (stx)
		  (define (synner message subform)
		    (syntax-violation 'THE-TAG message stx subform))
		  (syntax-case stx ( ;;
				    :dispatch :mutator :append-unique-id
				    :accessor-function :mutator-function
				    :process-shadowed-identifier
				    aux.<>)

		    ;;Try to  match the tagged-variable use  to a method
		    ;;call  for  the  tag;  if no  method  name  matches
		    ;;??MEMBER-ID,  try to  match  a field  name; if  no
		    ;;field name matches ??MEMBER-ID, hand everything to
		    ;;the parent tag.
		    ((_ :dispatch (??expr ??member-id . ??args))
		     (identifier? #'??member-id)
		     (case (syntax->datum #'??member-id)
		       ((METHOD-NAME)
			(syntax-help.process-method-application #'METHOD-RV-TAG #'(METHOD-IMPLEMENTATION ??expr . ??args)))
		       ...
		       (else
			(%the-accessor stx #'??expr #'??member-id #'??args synner))))

		    ;;Invoke the mutator syntax transformer.  The syntax
		    ;;use:
		    ;;
		    ;;   (set!/tags (?var ?field-name) ?new-val)
		    ;;
		    ;;is expanded to:
		    ;;
		    ;;   (?var :mutator ?field-name ?new-val)
		    ;;
		    ;;and then to:
		    ;;
		    ;;   (THE-TAG :mutator SRC-VAR ?field-name ?new-val)
		    ;;
		    ;;where  SRC-VAR  is  the identifier  bound  to  the
		    ;;actual  instance.   Then,  depending on  the  ?ARG
		    ;;forms, the  mutator can expand to:  a simple field
		    ;;mutator  invocation,  or  to  a  subfield  mutator
		    ;;invocation, or to a submethod invocation.
		    ;;
		    ((_ :mutator ??expr ??field-name ??new-value)
		     (if (identifier? #'?field-name)
			 (%the-mutator stx #'??expr #'??field-name #'??new-value)
		       (synner "expected identifier as field name for mutator" #'??field-name)))

		    ((_ :append-unique-id (??id (... ...)))
		     #'(THE-PARENT :append-unique-id (??id (... ...) NONGENERATIVE-UID)))

		    ((_ :accessor-function ??field-name)
		     (if (identifier? #'??field-name)
			 (case (syntax->datum #'??field-name)
			   ((IMMUTABLE-FIELD)	#'(lambda (obj) (IMMUTABLE-ACCESSOR obj)))
			   ...
			   ((MUTABLE-FIELD)	#'(lambda (obj) (MUTABLE-ACCESSOR   obj)))
			   ...
			   (else
			    #'(THE-PARENT :accessor-function ??field-name)))
		       (synner "expected identifier as field name for accessor function" #'??field-name)))

		    ((_ :mutator-function ??field-name)
		     (if (identifier? #'??field-name)
			 (case (syntax->datum #'??field-name)
			   ((MUTABLE-FIELD)
			    #'(lambda (obj val) (MUTABLE-MUTATOR obj val)))
			   ...
			   ((IMMUTABLE-FIELD)
			    (synner "request of mutator function for immutable field" #'IMMUTABLE-FIELD))
			   ...
			   (else
			    #'(THE-PARENT :mutator-function ??field-name)))
		       (synner "expected identifier as field name for mutator function" #'??field-name)))

		    ;;Replace  all the  occurrences of  ??SRC-ID in  the
		    ;;??BODY forms  with the identifier selected  by the
		    ;;SHADOWS  clause.  This  allows a  label tag  to be
		    ;;used to handle some other entity type.
		    ;;
		    ;;Notice that we really substitute ??SRC-ID from the
		    ;;input form rather than THE-TAG.
		    ;;
		    ;;SHADOWED-IDENTIFIER has #f as datum if no shadowed
		    ;;identifier was specified in the label definition.
		    ;;
		    ((??src-id :process-shadowed-identifier ??body0 ??body (... ...))
		     (syntax-help.process-shadowed-identifier #'??src-id #'SHADOWED-IDENTIFIER
							      #'(begin ??body0 ??body (... ...))))

		    (_
		     (syntax-help.tag-private-common-syntax-transformer
		      stx #f #'THE-PUBLIC-CONSTRUCTOR #'THE-PUBLIC-PREDICATE #'THE-LIST-OF-UIDS
		      %the-getter %the-setter
		      (lambda ()
			(syntax-help.tag-public-syntax-transformer stx %the-maker #'set!/tags synner))))))
		))

	    DEFINITION ...
	    (module () (SATISFACTION . SATISFACTION-CLAUSES) ...)
	    ;;NOTE  Just  in  case  putting  the  satisfactions  into  a
	    ;;module's body  turns out not to  be right, we can  use the
	    ;;following  definition instead.   What's important  is that
	    ;;the  whole  sequence  of  forms  resulting  from  a  label
	    ;;definition expansion is a sequence of definitions.  (Marco
	    ;;Maggi; Tue Jul 16, 2013)
	    ;;
	    ;; (define dummy-for-satisfactions
	    ;;   (let ()
	    ;;     (SATISFACTION . SATISFACTION-CLAUSES) ...
	    ;;     #f))

	    )))))


(define-syntax* (define-class stx)
  ;;Define a new class type.  After  all the processing: expand to a set
  ;;of syntax definitions and  miscellaneous bindings for predicates and
  ;;constructors.
  ;;
  (lambda (ctv-retriever)
    (define spec	(parser-help.parse-class-definition stx #'<top> #'lambda/tags ctv-retriever synner))
    (define tag-id	(parser-help.<parsed-spec>-name-id spec))
    (define abstract?	(parser-help.<parsed-spec>-abstract? spec))
    (with-syntax
	((THE-TAG				tag-id)
	 (THE-RECORD-TYPE			(parser-help.<class-spec>-record-type-id spec))
	 (THE-PREDICATE				(parser-help.<parsed-spec>-public-predicate-id spec))
	 (THE-PARENT				(parser-help.<parsed-spec>-parent-id spec))
	 (THE-DEFAULT-PROTOCOL			(parser-help.<class-spec>-default-protocol-id spec))
	 (THE-FROM-FIELDS-CONSTRUCTOR		(parser-help.<class-spec>-from-fields-constructor-id spec))
	 (THE-PUBLIC-CONSTRUCTOR		(parser-help.<parsed-spec>-public-constructor-id spec))
	 (THE-LIST-OF-UIDS			(parser-help.<parsed-spec>-list-of-uids-id spec))
	 (NONGENERATIVE-UID			(parser-help.<parsed-spec>-nongenerative-uid spec))
	 (ABSTRACT?				abstract?)
	 (SEALED?				(parser-help.<parsed-spec>-sealed? spec))
	 (OPAQUE?				(parser-help.<parsed-spec>-opaque? spec))

	 (((CONCRETE-FIELD-SPEC ...) ...)	(parser-help.<parsed-spec>-concrete-fields-data spec))
	 ((CONCRETE-FIELD-NAME ...)		(parser-help.<parsed-spec>-concrete-fields-names spec))

	 (((IMMUTABLE-FIELD IMMUTABLE-ACCESSOR IMMUTABLE-TAG) ...)
	  (parser-help.<parsed-spec>-immutable-fields-data spec))

	 (((MUTABLE-FIELD MUTABLE-ACCESSOR MUTABLE-MUTATOR MUTABLE-TAG) ...)
	  (parser-help.<parsed-spec>-mutable-fields-data spec))

	 (((METHOD-NAME METHOD-RV-TAG METHOD-IMPLEMENTATION) ...)
	  (parser-help.<parsed-spec>-methods-table spec))

	 ((DEFINITION ...)
	  (parser-help.<parsed-spec>-definitions spec))

	 (ACCESSOR-TRANSFORMER
	  (syntax-help.make-accessor-transformer spec))

	 (MUTATOR-TRANSFORMER
	  (syntax-help.make-mutator-transformer  spec))

	 (MAKER-TRANSFORMER
	  (parser-help.<parsed-spec>-maker-transformer spec))

	 (FINALISER-EXPRESSION
	  (parser-help.<parsed-spec>-finaliser-expression spec))

	 ((SATISFACTION ...)
	  (parser-help.<parsed-spec>-satisfactions spec))
	 (SATISFACTION-CLAUSES
	  (parser-help.<class-spec>-satisfaction-clauses spec))

	 (WRONG-TYPE-ERROR-MESSAGE
	  (string-append "invalid expression result, expected value of type "
			 (symbol->string (syntax->datum tag-id)))))
      (define (%compose-parent-rcd-with-proto proto)
	#`(make-record-constructor-descriptor (record-type-descriptor THE-RECORD-TYPE)
					      (THE-PARENT :super-constructor-descriptor)
					      #,proto))
      (with-syntax
	  ((THE-COMMON-CONSTRUCTOR-EXPR
	    ;;The common protocol is the default  one to be used when no
	    ;;specialised  protocols  are  defined by  the  DEFINE-CLASS
	    ;;clauses.  Abstract classes cannot have a common protocol.
	    ;;
	    ;;If the  class is concrete  and no protocol is  defined, we
	    ;;use the appropriately built  default protocol; R6RS states
	    ;;that  when the  parent's RCD  has a  custom protocol,  the
	    ;;derived RCD must have a custom protocol too.
	    (%compose-parent-rcd-with-proto (cond (abstract?
						   #'(lambda (make-superclass)
						       (lambda args
							 (assertion-violation 'THE-TAG
							   "attempt to instantiate abstract class"))))
						  ((parser-help.<parsed-spec>-common-protocol spec))
						  (else
						   #'THE-DEFAULT-PROTOCOL))))

	   (THE-PUBLIC-CONSTRUCTOR-EXPR
	    ;;The public  protocol is to  be used  by the maker  of this
	    ;;class type;  when not defined,  it defaults to  the common
	    ;;protocol; abstract classes cannot have a public protocol.
	    ;;
	    ;;If the  class is concrete  and no protocol is  defined, we
	    ;;use the appropriately built  default protocol; R6RS states
	    ;;that  when the  parent's RCD  has a  custom protocol,  the
	    ;;derived RCD must have a custom protocol too.
	    (let ((proto (parser-help.<parsed-spec>-public-protocol spec)))
	      (if (or abstract? (not proto))
		  #'the-common-constructor-descriptor
		(%compose-parent-rcd-with-proto proto))))

	   (THE-SUPER-CONSTRUCTOR-EXPR
	    ;;The  super protocol  is to  be used  when instantiating  a
	    ;;subclass of  this class  type; when  not defined,  and the
	    ;;class  is concrete,  it defaults  to the  common protocol.
	    ;;Abstract classes can have a super protocol.
	    ;;
	    ;;If the  class is concrete  and no protocol is  defined, we
	    ;;use the appropriately built  default protocol; R6RS states
	    ;;that  when the  parent's RCD  has a  custom protocol,  the
	    ;;derived RCD must have a custom protocol too.
	    (let ((proto (parser-help.<parsed-spec>-super-protocol spec)))
	      (cond (abstract?
		     (%compose-parent-rcd-with-proto (or proto #'THE-DEFAULT-PROTOCOL)))
		    (proto
		     (%compose-parent-rcd-with-proto proto))
		    (else
		     #'the-common-constructor-descriptor))))

	   (GETTER-TRANSFORMER
	    ;;If no getter syntax is defined for this label: use the one
	    ;;of  the parent.   The getter  of "<top>"  raises a  syntax
	    ;;violation error.
	    (or (parser-help.<parsed-spec>-getter spec)
		#'(lambda (stx unused-tag)
		    #`(THE-PARENT :getter #,stx))))

	   (SETTER-TRANSFORMER
	    ;;If no setter syntax is defined for this label: use the one
	    ;;of  the parent.   The setter  of "<top>"  raises a  syntax
	    ;;violation error.
	    (or (parser-help.<parsed-spec>-setter spec)
		#'(lambda (stx unused-tag)
		    #`(THE-PARENT :setter #,stx)))))

	#'(begin

	    (THE-PARENT :insert-parent-clause
	      (define-record-type (THE-RECORD-TYPE the-automatic-constructor THE-PREDICATE)
		(nongenerative NONGENERATIVE-UID)
		(sealed SEALED?)
		(opaque OPAQUE?)
		(fields (CONCRETE-FIELD-SPEC ...)
			...)))

	    (define (THE-FROM-FIELDS-CONSTRUCTOR . args)
	      (apply the-automatic-constructor
		     ;;This is the value of the hidden field in "<top>".
		     (THE-TAG :list-of-unique-ids)
		     args))

	    (define THE-DEFAULT-PROTOCOL
	      (THE-PARENT :insert-constructor-fields
		(lambda (make-parent)
		  (lambda (CONCRETE-FIELD-NAME ...)
		    ((make-parent) CONCRETE-FIELD-NAME ...)))))

	    (module ()
	      (cond (FINALISER-EXPRESSION
		     => (lambda (finaliser)
			  (record-destructor-set! (record-type-descriptor THE-RECORD-TYPE)
						  finaliser)))))

	    (define THE-LIST-OF-UIDS
	      (THE-PARENT :append-unique-id (NONGENERATIVE-UID)))

	    ;;*NOTE*  (Marco Maggi;  Thu  May 17,  2012)  Once a  record
	    ;;constructor  descriptor (RCD)  has been  built: everything
	    ;;needed to  build a  record constructor function  is known;
	    ;;applying RECORD-CONSTRUCTOR to the RCD can return the same
	    ;;constructor function,  memoised in an internal  field.  It
	    ;;is  not  clear  if,  according  to  R6RS,  every  call  to
	    ;;RECORD-CONSTRUCTOR causes all the protocol functions to be
	    ;;called a new time.
	    ;;
	    ;;This   is   the   business  of   the   underlying   Scheme
	    ;;implementation,   so,   here,    we   shamelessly   invoke
	    ;;RECORD-CONSTRUCTOR  multiple times  even  though we  known
	    ;;that all the RCDs may be the same (the common RCD).

	    (define the-common-constructor-descriptor THE-COMMON-CONSTRUCTOR-EXPR)
	    ;;This  is commented  out  because unused  at present.   The
	    ;;common   constructor  descriptor   is   used  when   other
	    ;;constructor descriptors are not customised, but the common
	    ;;constructor function does not need to be defined.
	    ;;
	    ;; (define THE-COMMON-CONSTRUCTOR
	    ;;   (record-constructor the-common-constructor-descriptor))

	    (define the-public-constructor-descriptor THE-PUBLIC-CONSTRUCTOR-EXPR)
	    (define THE-PUBLIC-CONSTRUCTOR
	      (let ((constructor (record-constructor the-public-constructor-descriptor)))
		(lambda args
		  (receive-and-return (instance)
		      (apply constructor args)
		    ($record-type-field-set! <top>-record-type unique-identifiers
					     instance (THE-TAG :list-of-unique-ids))))))

	    (define the-super-constructor-descriptor THE-SUPER-CONSTRUCTOR-EXPR)
	    ;;This  is commented  out  because unused  at present.   The
	    ;;super   constructor  descriptor   is   used  by   subclass
	    ;;constructors to  build instances of type  THE-TAG, but the
	    ;;super constructor function does not need to be defined.
	    ;;
	    ;; (define the-super-constructor
	    ;;   (record-constructor the-super-constructor-descriptor))

	    (define-syntax THE-TAG
	      ;;Tag  syntax, all  the operations  involving this  tag go
	      ;;through  this  syntax.   The  only  reason  this  syntax
	      ;;dispatches to sub-syntaxes it to keep the code readable.
	      ;;
	      ;;??EXPR must be an expression  to be evaluated only once;
	      ;;its result must be an  instance of the tag type.  ??EXPR
	      ;;can  be an  identifier but  also the  application of  an
	      ;;accessor to an instance.
	      ;;
	      ;;??VAR  must  be the  identifier  bound  to the  instance
	      ;;syntax dispatcher.
	      ;;
	      (let ((%the-getter	(lambda (stx)
					  (GETTER-TRANSFORMER stx #'THE-TAG)))
		    (%the-setter	(lambda (stx)
					  (SETTER-TRANSFORMER stx #'THE-TAG)))
		    (%the-accessor	ACCESSOR-TRANSFORMER)
		    (%the-mutator	MUTATOR-TRANSFORMER)
		    (%the-maker		MAKER-TRANSFORMER))

		(let ()
		  (define (%constructor-maker input-form.stx)
		    #f)
		  (define (%accessor-maker field.sym input-form.stx)
		    #f)
		  (define (%mutator-maker field.sym input-form.stx)
		    #f)
		  (define (%getter-maker keys.stx input-form.stx)
		    #f)
		  (define (%setter-maker keys.stx input-form.stx)
		    #f)
		  (define %caster-maker #f)
		  (define (%dispatcher method-sym arg*.stx input-form-stx)
		    #f)
		  (define type-spec
		    (typ.make-object-type-spec #'THE-TAG #'THE-PARENT #'THE-PREDICATE
					       %constructor-maker
					       %accessor-maker %mutator-maker
					       %getter-maker %setter-maker
					       %caster-maker %dispatcher))
		  (typ.set-identifier-object-type-spec! #'THE-TAG type-spec))

		(lambda (stx)
		  (define (synner message subform)
		    (syntax-violation 'THE-TAG message stx subform))

		  (syntax-case stx ( ;;
				    :make-from-fields
				    :dispatch :mutator
				    :insert-parent-clause define-record-type
				    :insert-constructor-fields
				    :super-constructor-descriptor lambda
				    :append-unique-id
				    :accessor-function :mutator-function
				    aux.<>)

		    ;;Given an  R6RS record  type definition:  insert an
		    ;;appropriate  PARENT clause  so  that  the type  is
		    ;;derived  from this  tag's  record  type.  This  is
		    ;;needed because only the  tag identifier is part of
		    ;;the public interface, but  we still need to define
		    ;;record types derived from this one.
		    ((_ :insert-parent-clause (define-record-type ??name . ??clauses))
		     #'(define-record-type ??name (parent THE-RECORD-TYPE) . ??clauses))

		    ;;Insert the field names in the appropriate position
		    ;;in the  definition of a custom  protocol function.
		    ;;This  is used  by  subclasses to  build their  own
		    ;;default protocol  which does  not need to  set the
		    ;;fields in "<top>".
		    ((_ :insert-constructor-fields
			(lambda (make-parent1)
			  (lambda (V (... ...))
			    ((make-parent2 W (... ...)) Z (... ...)))))
		     #'(THE-PARENT :insert-constructor-fields
			 (lambda (make-parent1)
			   (lambda (CONCRETE-FIELD-NAME ... V (... ...))
			     ((make-parent2 CONCRETE-FIELD-NAME ... W (... ...)) Z (... ...))))))

		    ((_ :super-constructor-descriptor)
		     #'the-super-constructor-descriptor)

		    ;;Try to  match the tagged-variable use  to a method
		    ;;call  for  the  tag;  if no  method  name  matches
		    ;;??MEMBER-ID,  try to  match  a field  name; if  no
		    ;;field name matches ??MEMBER-ID, hand everything to
		    ;;the parent tag.
		    ((_ :dispatch (??expr ??member-id . ??args))
		     (identifier? #'??member-id)
		     (case (syntax->datum #'??member-id)
		       ((METHOD-NAME)
			(syntax-help.process-method-application #'METHOD-RV-TAG #'(METHOD-IMPLEMENTATION ??expr . ??args)))
		       ...
		       (else
			(%the-accessor stx #'??expr #'??member-id #'??args synner))))

		    ;;Invoke the mutator syntax transformer.  The syntax
		    ;;use:
		    ;;
		    ;;   (set!/tags (?var ?field-name) ?new-val)
		    ;;
		    ;;is expanded to:
		    ;;
		    ;;   (?var :mutator ?field-name ?new-val)
		    ;;
		    ;;and then to:
		    ;;
		    ;;   (THE-TAG :mutator SRC-VAR ?field-name ?new-val)
		    ;;
		    ;;where  SRC-VAR  is  the identifier  bound  to  the
		    ;;actual  instance.   Then,  depending on  the  ?ARG
		    ;;forms, the  mutator can expand to:  a simple field
		    ;;mutator  invocation,  or  to  a  subfield  mutator
		    ;;invocation, or to a submethod invocation.
		    ;;
		    ((_ :mutator ??expr ??field-name ??new-value)
		     (if (identifier? #'?field-name)
			 (%the-mutator stx #'??expr #'??field-name #'??new-value)
		       (synner "expected identifier as field name for mutator" #'??field-name)))

		    ((_ :make-from-fields . ??args)
		     #'(THE-FROM-FIELDS-CONSTRUCTOR . ??args))

		    ((_ :append-unique-id (??id (... ...)))
		     #'(THE-PARENT :append-unique-id (??id (... ...) NONGENERATIVE-UID)))

		    ((_ :accessor-function ??field-name)
		     (if (identifier? #'??field-name)
			 (case (syntax->datum #'??field-name)
			   ((IMMUTABLE-FIELD)	#'(lambda (obj) (IMMUTABLE-ACCESSOR obj)))
			   ...
			   ((MUTABLE-FIELD)	#'(lambda (obj) (MUTABLE-ACCESSOR   obj)))
			   ...
			   (else
			    #'(THE-PARENT :accessor-function ??field-name)))
		       (synner "expected identifier as field name for accessor function" #'??field-name)))

		    ((_ :mutator-function ??field-name)
		     (if (identifier? #'??field-name)
			 (case (syntax->datum #'??field-name)
			   ((MUTABLE-FIELD)
			    #'(lambda (obj val) (MUTABLE-MUTATOR obj val)))
			   ...
			   ((IMMUTABLE-FIELD)
			    (synner "request of mutator function for immutable field" #'IMMUTABLE-FIELD))
			   ...
			   (else
			    #'(THE-PARENT :mutator-function ??field-name)))
		       (synner "expected identifier as field name for mutator function" #'??field-name)))

		    (_
		     (syntax-help.tag-private-common-syntax-transformer
		      stx ABSTRACT? #'THE-PUBLIC-CONSTRUCTOR #'THE-PREDICATE #'THE-LIST-OF-UIDS
		      %the-getter %the-setter
		      (lambda ()
			(syntax-help.tag-public-syntax-transformer stx %the-maker #'set!/tags synner))))))
		))

	    DEFINITION ...

	    (module () (SATISFACTION . SATISFACTION-CLAUSES) ...)
	    ;;NOTE  Just  in  case  putting  the  satisfactions  into  a
	    ;;module's body  turns out not to  be right, we can  use the
	    ;;following  definition instead.   What's important  is that
	    ;;the  whole  sequence  of  forms  resulting  from  a  class
	    ;;definition expansion is a sequence of definitions.  (Marco
	    ;;Maggi; Tue Jul 16, 2013)
	    ;;
	    ;; (define dummy-for-satisfactions
	    ;;   (let ()
	    ;;     (SATISFACTION . SATISFACTION-CLAUSES) ...
	    ;;     #f))

	    )))))


;;;; mixins
;;
;;Mixins are collections of clauses that  can be added to a label, class
;;or other mixin definition.  For example:
;;
;;  (define-mixin <alpha>
;;    (fields d e f))
;;
;;  (define-class <beta>
;;    (fields a b c)
;;    (mixins <alpha>))
;;
;;is equivalent to:
;;
;;  (define-class <beta>
;;    (fields a b c)
;;    (fields d e f))
;;
;;and so equivalent to:
;;
;;  (define-class <beta>
;;    (fields a b c d e f))
;;
;;mixin clauses are added to the end of the enclosing entity definition.
;;
(define-syntax* (define-mixin stx)
  (lambda (ctv-retriever)
    (receive (mixin-name-id mixin-ctv)
	(parser-help.parse-mixin-definition stx #'<top> #'lambda/tags ctv-retriever synner)
      #`(define-syntax #,mixin-name-id
	  (make-compile-time-value (quote #,mixin-ctv))))))


;;;; companion syntaxes

(define-syntax* (make-from-fields stx)
  (syntax-case stx ()
    ((_ ?tag . ?args)
     (identifier? #'?tag)
     #'(?tag :make-from-fields . ?args))
    (_
     (synner "invalid syntax in use of from-fields maker call"))))

(define-syntax* (tag-unique-identifiers stx)
  (syntax-case stx ()
    ((_ ?tag)
     (identifier? #'?tag)
     #'(?tag :list-of-unique-ids))
    (_
     (synner "invalid syntax in use of tag list of UIDs"))))

(define-syntax* (with-label-shadowing stx)
  (syntax-case stx (:process-shadowed-identifier)
    ((_ () ?body0 ?body ...)
     #'(begin ?body0 ?body ...))
    ((_ (?label0 ?label ...) ?body0 ?body ...)
     (all-identifiers? #'(?label0 ?label ...))
     #'(?label0 :process-shadowed-identifier
		(with-label-shadowing (?label ...)
		  ?body0 ?body ...)))
    (_
     (synner "invalid syntax in request for labels shadowing"))))


(define-syntax* (set!/tags stx)
  (syntax-case stx ()

    ;;Main syntax to invoke the setter  for the tag of ?VAR; it supports
    ;;multiple sets of keys for nested setter invocations.  For example:
    ;;
    ;;   (define {V <vector>} '#(1 2 3))
    ;;   (set!/tags (V [1]) #\B)
    ;;   (V [1]) => #\B
    ;;
    ((_ (?var (?key0 ...) (?key ...) ...) ?new-value)
     (identifier? #'?var)
     #'(?var :setter ((?key0 ...) (?key ...) ...) ?new-value))

    ;;Alternative syntax  to invoke the setter  for the tag of  ?VAR; it
    ;;supports multiple sets of keys for nested setter invocations.  For
    ;;example:
    ;;
    ;;   (define {V <vector>} '#(1 2 3))
    ;;   (set!/tags V[1] #\B)
    ;;   (V [1]) => #\B
    ;;
    ((_ ?var (?key0 ...) (?key ...) ... ?new-value)
     (identifier? #'?var)
     #'(?var :setter ((?key0 ...) (?key ...) ...) ?new-value))

    ;;Syntax to invoke  the getter of a value  resulting from evaluating
    ;;?EXPR.  For example:
    ;;
    ;;   (define-class <alpha>
    ;;     (fields (mutable {vec <vector>})))
    ;;   (define {A <alpha>} (<alpha> (#(1 2 3))))
    ;;   (set!/tags ((A V) [1]) #\B)
    ;;   ((A V) [1]) => #\B
    ;;
    ((_ (?expr (?key0 ...) (?key ...) ...) ?new-value)
     (not (identifier? #'?expr))
     #'(?expr :setter ((?key0 ...) (?key ...) ...) ?new-value))
    ((_ ?expr (?key0 ...) (?key ...) ... ?new-value)
     (not (identifier? #'?expr))
     #'(?expr :setter ((?key0 ...) (?key ...) ...) ?new-value))

    ;;Syntax to invoke a field mutator.
    ;;
    ((_ (?var ?field-name) ?new-value)
     (and (identifier? #'?var)
	  (identifier? #'?field-name))
     #'(?var :mutator ?field-name ?new-value))

    ;;Syntax to invoke the field mutator  for the tagged return value of
    ;;an expression.
    ;;
    ((_ (?expr ?field-name) ?new-value)
     (and (not (identifier? #'?expr))
	  (identifier? #'?field-name))
     #'(?expr :mutator ?field-name ?new-value))

    ;;Syntax to mutate a binding with R6RS's SET!.
    ((_ ?var ?new-value)
     (identifier? #'?var)
     #'(set! ?var ?new-value))
    ))


(define-syntax* (with-tagged-arguments-validation stx)
  ;;Transform:
  ;;
  ;;  (with-tagged-arguments-validation (who)
  ;;      ((<fixnum>  X)
  ;;       (<integer> Y))
  ;;    (do-this)
  ;;    (do-that))
  ;;
  ;;into:
  ;;
  ;;  (begin
  ;;    (<fixnum> :assert-procedure-argument X)
  ;;    (begin
  ;;      (<integer> :assert-procedure-argument Y)
  ;;      (let ()
  ;;        (do-this)
  ;;        (do-that))))
  ;;
  ;;As a special case:
  ;;
  ;;  (with-tagged-arguments-validation (who)
  ;;      ((<top>  X))
  ;;    (do-this)
  ;;    (do-that))
  ;;
  ;;expands to:
  ;;
  ;;  (let ()
  ;;    (do-this)
  ;;    (do-that))
  ;;
  (define (main stx)
    (syntax-case stx ()
      ((_ (?who) ((?validator ?arg) ...) . ?body)
       (identifier? #'?who)
       (let* ((body		#'(let () . ?body))
	      (output-form	(%build-output-form #'?who
						    #'(?validator ...)
						    (syntax->list #'(?arg ...))
						    body)))
	 (if config.validate-tagged-values?
	     output-form
	   body)))
      (_
       (%synner "invalid input form" #f))))

  (define (%build-output-form who validators args body)
    (syntax-case validators (<top>)
      (()
       body)

      ;;Accept "<top>" as special validator meaning "always valid".
      ((<top> . ?other-validators)
       (%build-output-form who #'?other-validators (cdr args) body))

      ((?validator . ?other-validators)
       (identifier? #'?validator)
       (%generate-validation-form who #'?validator (car args) #'?other-validators (cdr args) body))

      ((?validator . ?others)
       (%synner "invalid argument-validator selector" #'?validator))))

  (define (%generate-validation-form who validator-id arg-id other-validators-stx args body)
    #`(begin
	(#,validator-id :assert-procedure-argument #,arg-id)
	#,(%build-output-form who other-validators-stx args body)))

  (define (%synner msg subform)
    (syntax-violation 'with-tagged-arguments-validation msg stx subform))

  (main stx))


;;;; tagged return value

(define-syntax* (begin/tags stx)
  (syntax-case stx (aux.<-)
    ((_ (aux.<- ?tag) ?body0 ?body ...)
     (identifier? #'?tag)
     (if config.validate-tagged-values?
	 #'(let ((retval (begin ?body0 ?body ...)))
	     (?tag :assert-expression-return-value retval))
       #'(begin ?body0 ?body ...)))

    ((_ (aux.<- ?tag0 ?tag ...) ?body0 ?body ...)
     (all-identifiers? #'(?tag0 ?tag ...))
     (if config.validate-tagged-values?
	 (with-syntax
	     (((RETVAL ...) (generate-temporaries #'(?tag ...))))
	   #'(receive (retval0 RETVAL ...)
		 (begin ?body0 ?body ...)
	       (values (?tag0 :assert-expression-return-value retval0)
		       (?tag  :assert-expression-return-value RETVAL)
		       ...)))
       #'(begin ?body0 ?body ...)))

    ((_ (aux.<-) ?body0 ?body ...)
     #'(begin ?body0 ?body ...))

    ((_ ?body0 ?body ...)
     #'(begin ?body0 ?body ...))
    ))


;;;; convenience syntaxes with tags: LAMBDA, CASE-LAMBDA

(define-syntax* (lambda/tags stx)
  (syntax-case stx (brace)

    ;;Thunk definition.
    ;;
    ((_ () ?body0 ?body ...)
     #'(lambda () ?body0 ?body ...))

    ;;Function with tagged return values.
    ((_ ((brace ?who ?rv-tag0 ?rv-tag ...) . ?formals) ?body0 ?body ...)
     (and (all-identifiers? #'(?who ?rv-tag0 ?rv-tag ...))
	  (free-identifier=? #'?who #'_))
     #'(lambda/tags ?formals (begin/tags (aux.<- ?rv-tag0 ?rv-tag ...) ?body0 ?body ...)))

    ;;Function with untagged args argument.
    ;;
    ((_ ?args ?body0 ?body ...)
     (identifier? #'?args)
     #'(lambda ?args ?body0 ?body ...))

    ;;Function with tagged args argument.
    ;;
    ((_ (brace ?args-id ?tag-id) ?body0 ?body ...)
     (and (identifier? #'?args-id)
	  (identifier? #'?tag-id))
     (with-syntax ((((FORMAL) VALIDATIONS (SYNTAX-BINDING ...))
		    (syntax-help.parse-formals-bindings #'((brace ?args-id ?tag-id)) #'<top> synner)))
       #`(lambda FORMAL
	   (fluid-let-syntax ((__who__ (identifier-syntax 'lambda/tags)))
	     (with-tagged-arguments-validation (__who__)
		 VALIDATIONS
	       (let-syntax (SYNTAX-BINDING ...)
		 ?body0 ?body ...))))))

    ;;Mandatory arguments and tagged rest argument.
    ;;
    ((_ (?var0 ?var ... . (brace ?rest-id ?tag-id)) ?body0 ?body ...)
     (and (identifier? #'?rest-id)
	  (identifier? #'?tag-id))
     (with-syntax (((FORMALS VALIDATIONS (SYNTAX-BINDING ...))
		    (syntax-help.parse-formals-bindings #'(?var0 ?var ... . (brace ?rest-id ?tag-id)) #'<top> synner)))
       #`(lambda FORMALS
	   (fluid-let-syntax ((__who__ (identifier-syntax 'lambda/tags)))
	     (with-tagged-arguments-validation (__who__)
		 VALIDATIONS
	       (let-syntax (SYNTAX-BINDING ...)
		 ?body0 ?body ...))))))

    ;;Mandatory arguments and untagged rest argument.
    ;;
    ((_ (?var0 ?var ... . ?args) ?body0 ?body ...)
     (identifier? #'?args)
     (with-syntax (((FORMALS VALIDATIONS (SYNTAX-BINDING ...))
		    (syntax-help.parse-formals-bindings #'(?var0 ?var ... . ?args) #'<top> synner)))
       #`(lambda FORMALS
	   (fluid-let-syntax ((__who__ (identifier-syntax 'lambda/tags)))
	     (with-tagged-arguments-validation (__who__)
		 VALIDATIONS
	       (let-syntax (SYNTAX-BINDING ...)
		 ?body0 ?body ...))))))

    ;;Mandatory arguments and no rest argument.
    ;;
    ((_ (?var0 ?var ...) ?body0 ?body ...)
     (with-syntax (((FORMALS VALIDATIONS (SYNTAX-BINDING ...))
		    (syntax-help.parse-formals-bindings #'(?var0 ?var ...) #'<top> synner)))
       #`(lambda FORMALS
	   (fluid-let-syntax ((__who__ (identifier-syntax 'lambda/tags)))
	     (with-tagged-arguments-validation (__who__)
		 VALIDATIONS
	       (let-syntax (SYNTAX-BINDING ...)
		 ?body0 ?body ...))))))

    (_
     (synner "syntax error in LAMBDA/TAGS"))))

(define-syntax* (case-lambda/tags stx)
  (define (%process-clause clause-stx)
    (syntax-case clause-stx (brace)
      ;;Clause with tagged return values.
      ((((brace ?who ?rv-tag0 ?rv-tag ...) . ?formals) ?body0 ?body ...)
       (and (all-identifiers? #'(?who ?rv-tag0 ?rv-tag ...))
	    (free-identifier=? #'?who #'_))
       (%process-clause #'(?formals
			   (begin/tags (aux.<- ?rv-tag0 ?rv-tag ...) ?body0 ?body ...))))
      ;;Clause with UNtagged return values.
      ((?formals ?body0 ?body ...)
       (with-syntax (((FORMALS VALIDATIONS (SYNTAX-BINDING ...))
		      (syntax-help.parse-formals-bindings #'?formals #'<top> synner)))
	 #'(FORMALS
	    (define who 'case-lambda/tags)
	    (with-tagged-arguments-validation (who)
		VALIDATIONS
	      (let-syntax (SYNTAX-BINDING ...)
		?body0 ?body ...)))))
      (_
       (synner "invalid clause syntax" clause-stx))))
  (syntax-case stx ()
    ((_)
     #'(case-lambda))

    ((_ ?clause ...)
     (cons #'case-lambda
	   (map %process-clause (syntax->list #'(?clause ...)))))

    (_
     (synner "invalid syntax in case-lambda definition"))))


;;;; convenience syntaxes with tags: DEFINE, DEFINE-VALUES, CASE-DEFINE

(define-syntax* (define/tags stx)
  (syntax-case stx (brace)

    ;;Untagged, uninitialised variable.
    ;;
    ((_ ?who)
     (identifier? #'?who)
     #'(define ?who))

    ;;Tagged, uninitialised variable.
    ;;
    ((_ (brace ?who ?tag))
     (and (identifier? #'?who)
	  (identifier? #'?tag))
     #'(?tag ?who))

    ;;Untagged, initialised variable.
    ;;
    ((_ ?who ?expr)
     (identifier? #'?who)
     #'(define ?who ?expr))

    ;;Tagged, initialised variable.
    ;;
    ((_ (brace ?who ?tag) ?expr)
     (and (identifier? #'?who)
	  (identifier? #'?tag))
     #'(?tag ?who ?expr))

    ;;Function definition with tagged single return value through tagged
    ;;who.
    ;;
    ((_ ((brace ?who ?rv-tag) . ?formals) ?body0 ?body ...)
     (all-identifiers? #'(?who ?rv-tag))
     (with-syntax
	 ((FUN (identifier-prefix "the-" #'?who)))
       #'(module (?who)
	   (define FUN
	     (lambda/tags ((brace _ ?rv-tag) . ?formals)
	       (fluid-let-syntax
		   ((__who__ (identifier-syntax (quote ?who))))
		 ?body0 ?body ...)))
	   (define-syntax* (?who stx)
	     (syntax-case stx ()
	       (?id
		(identifier? #'?id)
		#'FUN)
	       ((_ ?arg (... ...))
		#'(?rv-tag #:nested-oopp-syntax (FUN ?arg (... ...))))
	       ))
	   #| end of module |# )))

    ;;Function  definition with  tagged multiple  return values  through
    ;;tagged who.
    ;;
    ((_ ((brace ?who ?rv-tag0 ?rv-tag ...) . ?formals) ?body0 ?body ...)
     (all-identifiers? #'(?who ?rv-tag0 ?rv-tag ...))
     #'(define ?who
	 (lambda/tags ((brace _ ?rv-tag0 ?rv-tag ...) . ?formals)
	   (fluid-let-syntax
	       ((__who__ (identifier-syntax (quote ?who))))
	     ?body0 ?body ...))))

    ;;Function definition.
    ;;
    ((_ (?who . ?formals) ?body0 ?body ...)
     (identifier? #'?who)
     #'(define ?who
	 (lambda/tags ?formals
	   (fluid-let-syntax
	       ((__who__ (identifier-syntax (quote ?who))))
	     ?body0 ?body ...))))

    (_
     (synner "syntax error in DEFINE/TAGS"))))

(define-syntax* (define-values/tags stx)
  (define who 'define-values/tags)

  (define (%main stx)
    (syntax-case stx ()
      ((_ (?var ... ?var0) ?form ... ?form0)
       (let ((vars-stx #'(?var ... ?var0)))
	 (with-syntax
	     (((VAR ... VAR0) (%process-vars vars-stx (lambda (id tag) #`(brace #,id #,tag))))
	      ((ID  ... ID0)  (%process-vars vars-stx (lambda (id tag) id)))
	      ((TMP ...)      (generate-temporaries #'(?var ...))))
	   #'(begin
	       (define (return-multiple-values)
		 ?form ... ?form0)
	       (define/tags VAR)
	       ...
	       (define/tags VAR0
		 (call-with-values
		     return-multiple-values
		   (lambda (TMP ... TMP0)
		     (set! ID TMP)
		     ...
		     TMP0)))))))))

  (define (%process-vars vars-stx maker)
    (syntax-case vars-stx (brace)
      (() '())
      ((?id ?var ...)
       (identifier? #'?id)
       (cons (maker #'?id #'<top>) (%process-vars #'(?var ...) maker)))
      (((brace ?id ?tag) ?var ...)
       (and (identifier? #'?id)
	    (identifier? #'?tag))
       (cons (maker #'?id #'?tag) (%process-vars #'(?var ...) maker)))
      ((?var0 ?var ...)
       (syntax-violation who "invalid binding definition syntax" stx #'?var0))))

  (%main stx))

(define-syntax* (case-define/tags stx)
  (syntax-case stx ()
    ((_ ?who (?formals ?body0 ?body ...) ...)
     (identifier? #'?who)
     #'(define ?who
	 (fluid-let-syntax
	     ((__who__ (identifier-syntax (quote ?who))))
	   (case-lambda/tags
	     (?formals ?body0 ?body ...) ...))))
    ))


;;;; convenience syntaxes with tags: LET and similar

(define-syntax* (with-tags stx)
  (syntax-case stx ()
    ((_ (?var ...) ?body0 ?body ...)
     (with-syntax
	 ((((VAR ...) (TAG ...) (SYNTAX-BINDING ...))
	   (syntax-help.parse-with-tags-bindings #'(?var ...) synner)))
       #`(let-syntax (SYNTAX-BINDING ...) ?body0 ?body ...)))
    (_
     (synner "syntax error"))))

(define-syntax* (let/tags stx)
  (syntax-case stx ()
    ;; no bindings
    ((_ () ?body0 ?body ...)
     #'(let () ?body0 ?body ...))

    ;; common LET with possibly tagged bindings
    ((_ ((?var ?init) ...) ?body0 ?body ...)
     (with-syntax
	 ((((VAR ...) (TAG ...) (SYNTAX-BINDING ...))
	   (syntax-help.parse-let-bindings #'(?var ...) #'<top> synner)))
       #`(let ((VAR (TAG :assert-type-and-return ?init)) ...)
	   (let-syntax (SYNTAX-BINDING ...) ?body0 ?body ...))))

    ;; named let, no bindings
    ((_ ?name () ?body0 ?body ...)
     (identifier? #'?name)
     #'(let ?name () ?body0 ?body ...))

    ;; named let, with possibly tagged bindings
    ((_ ?name ((?var ?init) ...) ?body0 ?body ...)
     (identifier? #'?name)
     (with-syntax
	 ((((VAR ...) (TAG ...) (SYNTAX-BINDING ...))
	   (syntax-help.parse-let-bindings #'(?var ...) #'<top> synner)))
       #`(let ?name ((VAR (TAG :assert-type-and-return ?init)) ...)
	   (let-syntax (SYNTAX-BINDING ...) ?body0 ?body ...))))

    (_
     (synner "syntax error"))))

(define-syntax* (let*/tags stx)
  (syntax-case stx ()
    ((_ () ?body0 ?body ...)
     #'(let () ?body0 ?body ...))

    ((_ ((?var0 ?init0) (?var ?init) ...) ?body0 ?body ...)
     #`(let/tags ((?var0 ?init0))
	 (let*/tags ((?var ?init) ...)
	   ?body0 ?body ...)))

    (_
     (syntax-violation 'let*/tags "syntax error in let*/tags input form" stx #f))))

(define-syntax* (letrec/tags stx)
  (syntax-case stx ()
    ((_ () ?body0 ?body ...)
     #'(let () ?body0 ?body ...))

    ((_ ((?var ?init) ...) ?body0 ?body ...)
     (with-syntax
	 (((TMP ...)
	   (generate-temporaries #'(?var ...)))
	  (((VAR ...) (TAG ...) (SYNTAX-BINDING ...))
	   (syntax-help.parse-let-bindings #'(?var ...) #'<top> synner)))
       #`(let ((VAR #f) ...)
	   (let-syntax (SYNTAX-BINDING ...)
	     ;;Do not enforce the order of evaluation of ?INIT.
	     (let ((TMP (TAG :assert-type-and-return ?init)) ...)
	       (set! VAR TMP) ...
	       (let () ?body0 ?body ...))))))

    (_
     (syntax-violation 'letrec/tags "syntax error in letrec/tags input form" stx #f))))

(define-syntax* (letrec*/tags stx)
  (syntax-case stx ()
    ((_ () ?body0 ?body ...)
     #'(let () ?body0 ?body ...))

    ((_ ((?var ?init) ...) ?body0 ?body ...)
     (with-syntax
	 ((((VAR ...) (TAG ...) (SYNTAX-BINDING ...))
	   (syntax-help.parse-let-bindings #'(?var ...) #'<top> synner)))
       #`(let ((VAR #f) ...)
	   (let-syntax (SYNTAX-BINDING ...)
	     ;;do enforce the order of evaluation of ?INIT
	     (set! VAR (TAG :assert-type-and-return ?init))
	     ...
	     (let () ?body0 ?body ...)))))

    (_
     (syntax-violation 'letrec*/tags "syntax error in letrec*/tags input form" stx #f))))


;;;; convenience syntaxes with tags: LET-VALUES and similar

(define-syntax* receive/tags
  (syntax-rules ()
    ((_ ?formals ?expression ?body0 ?body ...)
     (call-with-values
	 (lambda () ?expression)
       (lambda/tags ?formals ?body0 ?body ...)))))

(define-syntax* (receive-and-return/tags stx)
  (syntax-case stx ()
    ((_ ?vars ?inits ?body0 ?body ...)
     (with-syntax
	 ((((VARS) (BINDING ...))
	   (syntax-help.parse-let-values-bindings #'(?vars) #'<top> synner)))
       (if (identifier? #'VARS)
	   #`(let-values ((VARS ?inits))
	       (let-syntax (BINDING ...) ?body0 ?body ... (apply values VARS)))
	 #`(let-values ((VARS ?inits))
	     (let-syntax (BINDING ...) ?body0 ?body ... (values . VARS))))))
    ))

(define-syntax* (let-values/tags stx)
  (syntax-case stx ()
    ((_ () ?body0 ?body ...)
     #'(let () ?body0 ?body ...))

    ((_ ((?vars ?inits) ...) ?body0 ?body ...)
     (with-syntax
	 ((((VARS ...) (BINDING ...))
	   (syntax-help.parse-let-values-bindings #'(?vars ...) #'<top> synner)))
       #`(let-values ((VARS ?inits) ...)
	   (let-syntax (BINDING ...) ?body0 ?body ...))))

    ((_ ?bindings ?body0 ?body ...)
     (synner "syntax error in bindings" #'?bindings))
    (_
     (synner "syntax error"))))

(define-syntax* (let*-values/tags stx)
  (syntax-case stx ()
    ((_ () ?body0 ?body ...)
     #'(let () ?body0 ?body ...))

    ((_ ((?vars0 ?inits0) (?vars ?inits) ...) ?body0 ?body ...)
     #`(let-values/tags ((?vars0 ?inits0))
	 (let*-values/tags ((?vars ?inits) ...)
	   ?body0 ?body ...)))

    ((_ ?bindings ?body0 ?body ...)
     (synner "syntax error in bindings" #'?bindings))
    (_
     (synner "syntax error"))))


;;;; convenience syntaxes with tags: DO and similar

(define-syntax* do/tags
  (syntax-rules ()
    ((_ ((?var ?init ?step ...) ...)
	(?test ?expr ...)
	?form ...)
     (let-syntax ((the-expr (syntax-rules ()
			      ((_)
			       (values))
			      ((_ ??expr0 ??expr (... ...))
			       (begin ??expr0 ??expr (... ...)))))
		  (the-step (syntax-rules ()
			      ((_ ??var)
			       ??var)
			      ((_ ??var ??step)
			       ??step)
			      ((_ ??var ??step0 ??step (... ...))
			       (syntax-violation 'do/tags
				 "invalid step specification"
				 '(??step0 ??step (... ...)))))))
       (let/tags loop ((?var ?init) ...)
		 (if ?test
		     (the-expr ?expr ...)
		   (begin
		     ?form ...
		     (loop (the-step ?var ?step ...) ...))))))))

(define-syntax* (do*/tags stx)
  (define (%parse-var stx)
    (syntax-case stx (brace)
      (?id
       (identifier? #'?id)
       #'?id)
      ((brace ?id ?tag)
       (all-identifiers? #'(?id ?tag))
       #'?id)
      (_
       (synner "invalid binding declaration"))))
  (syntax-case stx ()
    ((_ ((?var ?init ?step ...) ...)
	(?test ?expr ...)
	?form ...)
     (with-syntax (((ID ...) (map %parse-var (syntax->list #'(?var ...)))))
       #'(let-syntax ((the-expr (syntax-rules ()
				  ((_)
				   (values))
				  ((_ ??expr0 ??expr (... ...))
				   (begin ??expr0 ??expr (... ...)))))
		      (the-step (syntax-rules ()
				  ((_ ??var)
				   ??var)
				  ((_ ??var ??step)
				   ??step)
				  ((_ ??var ??step0 ??step (... ...))
				   (syntax-violation 'do/tags
				     "invalid step specification"
				     '(??step0 ??step (... ...)))))))
	   (let*/tags ((?var ?init) ...)
	     (let/tags loop ((?var ID) ...)
		       (if ?test
			   (the-expr ?expr ...)
			 (begin
			   ?form ...
			   (loop (the-step ID ?step ...) ...))))))
       ))))


;;;; other syntaxes

(define-syntax tag-case
  (syntax-rules (else)
    ((_ ?expr
	((?tag0 ?tag ...)
	 ?tag-body0 ?tag-body ...)
	...
	(else
	 ?else-body0 ?else-body ...))
     (let ((E ?expr))
       (cond ((or (?tag0 :is-a? E)
		  (?tag :is-a? E)
		  ...)
	      ?tag-body0 ?tag-body ...)
	     ...
	     (else
	      ?else-body0 ?else-body ...))))
    ((_ ?expr
	((?tag0 ?tag ...)
	 ?tag-body0 ?tag-body ...)
	...)
     (let ((tag ?expr))
       (cond ((or (?tag0 :is-a? E)
		  (?tag :is-a? E)
		  ...)
	      ?tag-body0 ?tag-body ...)
	     ...)))
    ))


;;;; done

)

;;; end of file
;; Local Variables:
;; eval: (put 'rnrs.define-syntax* 'scheme-indent-function 1)
;; eval: (put 'aux.method-syntax 'scheme-indent-function 1)
;; eval: (put 'aux.method 'scheme-indent-function 1)
;; eval: (put 'THE-PARENT 'scheme-indent-function 1)
;; eval: (put 'receive-and-return/tags 'scheme-indent-function 2)
;; eval: (put 'typ.set-identifier-object-type-spec! 'scheme-indent-function 1)
;; End:
