; mysql.ss - DBD (Database Driver) for MySQL
;
;   Copyright (c) 2009  Higepon(Taro Minowa)  <higepon@users.sourceforge.jp>
;
;   Redistribution and use in source and binary forms, with or without
;   modification, are permitted provided that the following conditions
;   are met:
;
;   1. Redistributions of source code must retain the above copyright
;      notice, this list of conditions and the following disclaimer.
;
;   2. Redistributions in binary form must reproduce the above copyright
;      notice, this list of conditions and the following disclaimer in the
;      documentation and/or other materials provided with the distribution.
;
;   THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS
;   "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT
;   LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR
;   A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT
;   OWNER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL,
;   SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED
;   TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR
;   PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF
;   LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING
;   NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS
;   SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
;
;  $Id: dbi.ss 621 2008-11-09 06:22:47Z higepon $

(library (mosh dbd mysql)
  (export <dbd-mysql>)
  (import
   (mosh mysql)
   (clos user)
   (clos core)
   (only (mosh) format)
   (only (mosh ffi) pointer-null? pointer->integer string->utf8z)
   (only (rnrs) define quote let unless when assertion-violation zero?
                guard cond else => lambda values string->number raise
                let-values and = display reverse cons vector-set! current-error-port unquote
                vector-ref make-vector vector-length + let* equal? string->utf8
                make-hashtable string-hash hashtable-set! hashtable-ref quasiquote
                string-downcase)
   (mosh dbi))

(define-class <dbd-mysql> (<dbd>))
(define-class <mysql-connection> (<connection>) mysql)
(define-class <mysql-result> (<result>) mysql lst getter)

(define (vector-for-each-with-index proc v)
  (let ([len (vector-length v)])
    (let loop ([i 0])
      (cond
       [(= i len) v]
       [else
        (proc (vector-ref v i) i)
        (loop (+ i 1))]))))

(define (make-getter mysql result)
  (let* ([field-count (mysql-field-count mysql)]
         [ht (make-hashtable string-hash equal?)])
    (let loop ([i 0])
      (cond
       [(= field-count i) '()]
       [else
        ;; ignore case
        (hashtable-set! ht (string-downcase (mysql-field-name (mysql-fetch-field-direct result i))) i)
        (loop (+ i 1))]))
    (lambda (row name)
      (let ([index (hashtable-ref ht (string-downcase name) #f)])
        (unless index
          (assertion-violation 'dbi-getter "unknown column" name))
      (vector-ref row index)))))

(define-method initialize ((m <mysql-connection>) init-args)
  (initialize-direct-slots m <mysql-connection> init-args))

(define-method initialize ((m <mysql-result>) init-args)
  (initialize-direct-slots m <mysql-result> init-args))

(define-method dbi-result->list ((res <mysql-result>))
  (slot-ref res 'lst))

(define-method dbi-close ((conn <mysql-connection>))
  (mysql-close (slot-ref conn 'mysql)))

(define-method dbi-getter ((res <mysql-result>))
  (slot-ref res 'getter))

(define-method dbd-execute ((conn <mysql-connection>) sql)
  (let ([mysql (slot-ref conn 'mysql)])
    ;; we assume mysql-server accepts utf8
    (unless (zero? (mysql-query mysql (string->utf8z sql))) ;; null terminated c char*.
      (raise (make-dbi-error 'mysql-query sql (mysql-error mysql) (mysql-sqlstate mysql))))
    (let ([result (mysql-store-result mysql)])
      (cond
       ;; insert, update, create table
       [(pointer-null? result)
        (make <mysql-result>
          'mysql mysql
          'lst '()
          'getter (lambda a `(insert-id . ,(pointer->integer (mysql-insert-id mysql)))))]
       ;; select
       [else
        (let loop ([row (mysql-fetch-row result)]
                   [ret '()])
          (cond
           [(pointer-null? row)
            (let ([getter (make-getter mysql result)])
              (mysql-free-result result)
              (make <mysql-result>
                'mysql mysql
                'lst (reverse ret)
                'getter getter))]
           [else
            (let ([v (make-vector (mysql-field-count mysql))])
              (vector-for-each-with-index
               (lambda (val index)
                 (vector-set! v index (mysql-row-ref result row index)))
               v)
              (loop (mysql-fetch-row result) (cons v ret)))]))]))))

(define-method dbd-connect ((dbd <dbd-mysql>) user password options)
  (define (parse-options options)
    (cond
     [(#/([^:]+):([^:]+):(\d+)/ options) =>
      (lambda (m)
        (values (m 1) (m 2) (string->number (m 3))))]
     [else
      (values #f #f #f)]))
  (let ([mysql (guard (c (#t #f)) (mysql-init))])
    (unless mysql
      (assertion-violation 'mysql-init "mysql-init failed"))
    (let-values ([(db host port) (parse-options options)])
      (cond
       [(and db host port)
        (when (pointer-null? (mysql-real-connect mysql host user password db port NULL 0))
          (assertion-violation 'dbd-connect "mysql connection failed" (mysql-error mysql)))
        (make <mysql-connection> 'mysql mysql)]
       [else
        (assertion-violation 'dbd-connect "invalid options in dsn" options)]))))

)
