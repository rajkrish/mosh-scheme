(define %verbose #f)
(define %disable-acc #t)
(define %loadpath "lib.rnrs:lib.boot:../../../lib")
(load "compat-mosh-run.scm")
(load "runtime.scm")
(load "mosh-utils5.scm")
(load "BOOT1.exp")
(ex:load "lib.boot/mosh.nmosh.ss")
(ex:load "lib.boot/system.nmosh.ss")
(ex:load "build-run.ss")
