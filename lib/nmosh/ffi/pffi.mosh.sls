(library (nmosh ffi pffi)
         (export make-pffi-ref pffi-c-function)
         (import (rnrs)
                 (srfi :48)
                 (nmosh global-flags)
                 (mosh ffi))

(define pffi-feature-set 
  (let ((f (get-global-flag '%get-pffi-feature-set)))
    (if f (f) '())))

(define pffi-mark '*pffi-reference*)

(define (make-pffi-ref slot)
  `(,pffi-mark ,slot))

(define (pffi-slot obj)
  (and (pffi? obj) (cadr obj)))

(define (pffi? x) 
  (and (pair? x) (eq? pffi-mark (car x))))

(define (pffi-lookup lib func)
  (let ((plib (assoc (pffi-slot lib) pffi-feature-set)))
    (let ((pfn (assoc func (cdr plib))))
      (cdr pfn))))

(define-syntax pffi-c-function
  (syntax-rules ()
    ((_ lib ret func arg ...)
     (cond
       ((pffi? lib)
        (pointer->c-function (pffi-lookup lib 'func) 'ret 'func '(arg ...)))
       (else
         (make-c-function lib 'ret 'func '(arg ...)))))))
)
