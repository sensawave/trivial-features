;;;; -*- Mode: lisp; indent-tabs-mode: nil -*-
;;;
;;; tests.lisp --- trivial-features tests.
;;;
;;; Copyright (C) 2007, Luis Oliveira  <loliveira@common-lisp.net>
;;;
;;; Permission is hereby granted, free of charge, to any person
;;; obtaining a copy of this software and associated documentation
;;; files (the "Software"), to deal in the Software without
;;; restriction, including without limitation the rights to use, copy,
;;; modify, merge, publish, distribute, sublicense, and/or sell copies
;;; of the Software, and to permit persons to whom the Software is
;;; furnished to do so, subject to the following conditions:
;;;
;;; The above copyright notice and this permission notice shall be
;;; included in all copies or substantial portions of the Software.
;;;
;;; THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND,
;;; EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF
;;; MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND
;;; NONINFRINGEMENT.  IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT
;;; HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY,
;;; WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
;;; OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER
;;; DEALINGS IN THE SOFTWARE.

(in-package #:trivial-features-tests)

;;;; Support Code

;;; Hmm, why not just use CL-POSIX?

(defcfun ("uname" %uname) :int
  (buf :pointer))

;;; Get system identification.
(defun uname ()
  (with-foreign-object (buf 'utsname)
    (when (= (%uname buf) -1)
      (error "uname() returned -1"))
    (macrolet ((utsname-slot (name)
                 `(foreign-string-to-lisp
                   (foreign-slot-pointer buf 'utsname ',name))))
      (values (utsname-slot sysname)
              ;; (utsname-slot nodename)
              ;; (utsname-slot release)
              ;; (utsname-slot version)
              (utsname-slot machine)))))

(defun mutually-exclusive-p (features)
  (= 1 (loop for feature in features when (featurep feature) count 1)))

;;;; Tests

(deftest endianness.1
    (with-foreign-object (p :uint16)
      (setf (mem-ref p :uint16) #xfeff)
      (ecase (mem-ref p :uint8)
        (#xfe (featurep :big-endian))
        (#xff (featurep :little-endian))))
  t)

(defparameter *bsds* '(:darwin :netbsd :openbsd :freebsd))
(defparameter *unices* (list* :linux *bsds*))

(deftest os.1
    (featurep (trivial-features::keywordify
               (trivial-features::canonicalize-symbol-name-case (uname))))
  t)

(deftest os.2
    (if (featurep :bsd)
        (mutually-exclusive-p *bsds*)
        (featurep `(:not (:or ,@*bsds*))))
  t)

(deftest os.3
    (if (featurep `(:or ,@*unices*))
        (featurep :unix)
        t)
  t)

(deftest os.4
    (if (featurep :windows)
        (not (featurep :unix))
        t)
  t)

(deftest cpu.1
    (mutually-exclusive-p '(:ppc :ppc64 :x86 :x86-64 :alpha :mips))
  t)
