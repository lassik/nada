#! /usr/bin/env gosh

(import (scheme base) (scheme file) (scheme write) (srfi 1) (srfi 170))
(cond-expand
 (gauche (import (only (gauche base) make)
                 (only (file util) create-directory*)
                 (gauche process) (util digest) (rfc sha))))

(define (disp . xs) (for-each display xs) (newline))

(define (sha1-bytevector bytes)
  (let ((sha (make <sha1>)))
    (digest-update! sha bytes)
    (digest-hexify (digest-final! sha))))

(define (read-all-bytes in)
  (let loop ((whole (bytevector)))
    (let ((part (read-bytevector 4096 in)))
      (if (eof-object? part) whole (loop (bytevector-append whole part))))))

(define (sha1-string string) (sha1-bytevector (string->utf8 string)))

(define (sha1-file file)
  (sha1-bytevector (call-with-port (open-binary-input-file file)
                                   read-all-bytes)))

(define (sha1-object x)
  (sha1-string
   (call-with-port (open-output-string)
                   (lambda (out) (write x out) (get-output-string out)))))

(define (build recipe)
  (let* ((src (map (lambda (x) (string-append "src/" x))
                   (cdr (assoc 'src recipe))))
         (dir (string-append "store/"
                             (sha1-string (fold string-append
                                                (sha1-object recipe)
                                                (map sha1-file src)))))
         (dst (cadr (assoc 'dst recipe)))
         (ddd (string-append dir "/" dst))
         (bin (string-append "bin/" dst))
         (cmd (append-map (lambda (x)
                            (case x
                              ((src) src)
                              ((dst) (list ddd))
                              (else (and (string? x) (list x)))))
                          (cdr (assoc 'cmd recipe)))))
    (create-directory* dir)
    (do-process cmd)
    (create-directory* "bin")
    (when (file-exists? bin) (delete-file bin))
    (create-symlink (string-append "../" dir "/" dst) bin)))

(build
 '((dst "mg")
   (src "autoexec.c" "basic.c" "bell.c" "buffer.c" "cinfo.c" "dir.c"
        "display.c" "echo.c" "extend.c" "file.c" "fileio.c" "funmap.c"
        "help.c" "kbd.c" "keymap.c" "line.c" "macro.c" "main.c" "match.c"
        "modes.c" "paragraph.c" "re_search.c" "region.c" "search.c" "spawn.c"
        "tty.c" "ttyio.c" "ttykbd.c" "undo.c" "util.c" "version.c" "window.c"
        "word.c" "yank.c" "cmode.c" "cscope.c" "dired.c" "grep.c" "tags.c"
        "fparseln.c" "fstatat.c" "futimens.c" "getline.c" "reallocarray.c"
        "strlcat.c" "strlcpy.c" "strndup.c" "strtonum.c" "interpreter.c"
        "extensions.c")
   (cmd "cc" "-w" "-g" "-O2" "-lncurses" "-lutil"
        "-DREGEX"
        "-DMSG_NOSIGNAL=SO_NOSIGPIPE"
        "-DLOGIN_NAME_MAX=MAXLOGNAME"
        "-o" dst src)))
