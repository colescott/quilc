;;;; logical-matrix-sanity-tests.lisp
;;;;
;;;; Author: appleby

(in-package #:cl-quil-tests)

;;; The purpose of these tests are to act as a basic sanity-check for
;;; PARSED-PROGRAM-TO-LOGICAL-MATRIX.  Specifically these test were motivated by a bug in the way
;;; gate modifiers were parsed, resulting in incorrect logical matrices being generated when the
;;; FORKED and CONTROLLED modifiers were combined for certain choices of gate and gate
;;; parameters. In addition, other tests in the test suite will compare the output of P-P-T-L-M for
;;; both a compiled and uncompiled version of a given PARSED-PROGRAM and check to see if they are
;;; OPERATOR=, but this assumes that P-P-T-L-M on the uncompiled PARSED-PROGRAM is a valid
;;; reference. The below tests are therefore meant to provide an early warning in case P-P-T-L-M is
;;; misbehaving.

(deftest test-logical-matrix-sanity ()
  "Test that PARSED-PROGRAM-TO-LOGICAL-MATRIX produces the expected matrix for a handful of simple programs."
  (mapc (lambda (testcase)
          (let* ((input (first testcase))
                 (entries (second testcase))
                 (n (length entries))
                 (p (if (stringp input) (quil:parse-quil input) input))
                 (actual (quil::parsed-program-to-logical-matrix p))
                 (expected (quil::from-list (a:flatten entries) (list n n)))
                 (compiled (quil::matrix-rescale
                            (quil::parsed-program-to-logical-matrix
                             (quil:compiler-hook p (quil::build-nq-linear-chip
                                                    (quil:qubits-needed p))))
                            expected)))
            ;; FIASCO:IS always evaluates it's format arguments, even if the test assertion
            ;; succeeds.  Formatting via MATRIX-MISMATCH-FMT will only compute the MATRIX-MISMATCH
            ;; when/if the associated test assertion actually fails.
            (is (quil::matrix-equality actual expected)
                "Checking input: ~S~%~/cl-quil-tests::matrix-mismatch-fmt/"
                input
                (list actual expected))
            (is (quil::operator= compiled expected)
                "Checking compiled input: ~S~%~/cl-quil-tests::matrix-mismatch-fmt/"
                input
                (list compiled expected))))
        ;; Bind some values that show up as matrix entries in the testscases below, to make pattern
        ;; matching on them easier. Scroll down to the RY-gate tests to see where a,..,h are used.
        (let* ((i+ #C(0.0 1.0))
               (i- #C(0.0 -1.0))
               (pi/6 (/ quil::pi 6))
               (a+ (cos pi/6))
               (b+ (sin pi/6))
               (b- (- b+))
               (pi/12 (/ quil::pi 12))
               (c+ (cos pi/12))
               (d+ (sin pi/12))
               (d- (- d+))
               (pi/16 (/ quil::pi 16))
               (e+ (cos pi/16))
               (f+ (sin pi/16))
               (f- (- f+))
               (pi/20 (/ quil::pi 20))
               (g+ (cos pi/20))
               (h+ (sin pi/20))
               (h- (- h+)))
          `(;; Some simple matrices with elements from {0, 1, -1, i, -i}.
            ("I 0"
             ((1.0  0.0)
              (0.0  1.0)))
            ("X 0"
             ((0.0  1.0)
              (1.0  0.0)))
            ("Y 0"
             ((0.0  ,i-)
              (,i+  0.0)))
            ("Z 0"
             ((1.0  0.0)
              (0.0 -1.0)))
            (,(with-output-to-quil
                "X 0"
                "X 0")
             ((1.0  0.0)
              (0.0  1.0)))
            (,(with-output-to-quil
                "I 0"
                "I 1")
             ((1.0  0.0  0.0  0.0)
              (0.0  1.0  0.0  0.0)
              (0.0  0.0  1.0  0.0)
              (0.0  0.0  0.0  1.0)))
            ("CNOT 0 1"
             ((1.0  0.0  0.0  0.0)
              (0.0  0.0  0.0  1.0)
              (0.0  0.0  1.0  0.0)
              (0.0  1.0  0.0  0.0)))
            ("CNOT 1 0"
             ((1.0  0.0  0.0  0.0)
              (0.0  1.0  0.0  0.0)
              (0.0  0.0  0.0  1.0)
              (0.0  0.0  1.0  0.0)))
            (,(with-output-to-quil
                "X 0"
                "CNOT 0 1")
             ((0.0  1.0  0.0  0.0)
              (0.0  0.0  1.0  0.0)
              (0.0  0.0  0.0  1.0)
              (1.0  0.0  0.0  0.0)))
            (,(with-output-to-quil
                "X 0"
                "CNOT 1 0")
             ((0.0  1.0  0.0  0.0)
              (1.0  0.0  0.0  0.0)
              (0.0  0.0  1.0  0.0)
              (0.0  0.0  0.0  1.0)))
            ("PHASE(pi/2) 0"
             ((1.0  0.0)
              (0.0  ,i+)))
            ("PHASE(-pi/2) 0"
             ((1.0  0.0)
              (0.0  ,i-)))
            (;; Same as above
             "DAGGER PHASE(pi/2) 0"
             ((1.0  0.0)
              (0.0  ,i-)))
            (;; Same as PHASE(pi/2) 0
             "DAGGER DAGGER PHASE(pi/2) 0"
             ((1.0  0.0)
              (0.0  ,i+)))
            (;; Should be the same as CNOT 0 1, above
             "CONTROLLED X 0 1"
             ((1.0  0.0  0.0  0.0)
              (0.0  0.0  0.0  1.0)
              (0.0  0.0  1.0  0.0)
              (0.0  1.0  0.0  0.0)))
            (;; Should be the same as CNOT 1 0, above
             "CONTROLLED X 1 0"
             ((1.0  0.0  0.0  0.0)
              (0.0  1.0  0.0  0.0)
              (0.0  0.0  0.0  1.0)
              (0.0  0.0  1.0  0.0)))
            (;; Test CONTROLLED on non-permutation gate
             "CONTROLLED Y 0 1"
             ((1.0  0.0  0.0  0.0)
              (0.0  0.0  0.0  ,i-)
              (0.0  0.0  1.0  0.0)
              (0.0  ,i+  0.0  0.0)))
            ("CONTROLLED Y 1 0"
             ((1.0  0.0  0.0  0.0)
              (0.0  1.0  0.0  0.0)
              (0.0  0.0  0.0  ,i-)
              (0.0  0.0  ,i+  0.0)))
            ("CONTROLLED DAGGER PHASE(pi/2) 1 0"
             ((1.0  0.0  0.0  0.0)
              (0.0  1.0  0.0  0.0)
              (0.0  0.0  1.0  0.0)
              (0.0  0.0  0.0  ,i-)))
            (;; Same as above
             "DAGGER CONTROLLED PHASE(pi/2) 1 0"
             ((1.0  0.0  0.0  0.0)
              (0.0  1.0  0.0  0.0)
              (0.0  0.0  1.0  0.0)
              (0.0  0.0  0.0  ,i-)))
            ("FORKED Y 0 1"
             ((0.0  0.0  ,i-  0.0)
              (0.0  0.0  0.0  ,i-)
              (,i+  0.0  0.0  0.0)
              (0.0  ,i+  0.0  0.0)))
            ("FORKED Y 1 0"
             ((0.0  ,i-  0.0  0.0)
              (,i+  0.0  0.0  0.0)
              (0.0  0.0  0.0  ,i-)
              (0.0  0.0  ,i+  0.0)))
            ("FORKED PHASE(pi, pi/2) 1 0"
             ((1.0  0.0  0.0  0.0)
              (0.0 -1.0  0.0  0.0)
              (0.0  0.0  1.0  0.0)
              (0.0  0.0  0.0  ,i+)))
            ("FORKED PHASE(pi/2, pi) 1 0"
             ((1.0  0.0  0.0  0.0)
              (0.0  ,i+  0.0  0.0)
              (0.0  0.0  1.0  0.0)
              (0.0  0.0  0.0 -1.0)))
            ("CONTROLLED FORKED Y 2 1 0"
             ;;000  001  010  011  100  101  110  111
             ((1.0  0.0  0.0  0.0  0.0  0.0  0.0  0.0)   ; 000
              (0.0  1.0  0.0  0.0  0.0  0.0  0.0  0.0)   ; 001
              (0.0  0.0  1.0  0.0  0.0  0.0  0.0  0.0)   ; 010
              (0.0  0.0  0.0  1.0  0.0  0.0  0.0  0.0)   ; 011
              (0.0  0.0  0.0  0.0  0.0  ,i-  0.0  0.0)   ; 100
              (0.0  0.0  0.0  0.0  ,i+  0.0  0.0  0.0)   ; 101
              (0.0  0.0  0.0  0.0  0.0  0.0  0.0  ,i-)   ; 110
              (0.0  0.0  0.0  0.0  0.0  0.0  ,i+  0.0))) ; 111
            (;; Same as above
             "FORKED CONTROLLED Y 1 2 0"
             ;;000  001  010  011  100  101  110  111
             ((1.0  0.0  0.0  0.0  0.0  0.0  0.0  0.0)   ; 000
              (0.0  1.0  0.0  0.0  0.0  0.0  0.0  0.0)   ; 001
              (0.0  0.0  1.0  0.0  0.0  0.0  0.0  0.0)   ; 010
              (0.0  0.0  0.0  1.0  0.0  0.0  0.0  0.0)   ; 011
              (0.0  0.0  0.0  0.0  0.0  ,i-  0.0  0.0)   ; 100
              (0.0  0.0  0.0  0.0  ,i+  0.0  0.0  0.0)   ; 101
              (0.0  0.0  0.0  0.0  0.0  0.0  0.0  ,i-)   ; 110
              (0.0  0.0  0.0  0.0  0.0  0.0  ,i+  0.0))) ; 111
            ("FORKED CONTROLLED Y 2 1 0"
             ;;000  001  010  011  100  101  110  111
             ((1.0  0.0  0.0  0.0  0.0  0.0  0.0  0.0)   ; 000
              (0.0  1.0  0.0  0.0  0.0  0.0  0.0  0.0)   ; 001
              (0.0  0.0  0.0  ,i-  0.0  0.0  0.0  0.0)   ; 010
              (0.0  0.0  ,i+  0.0  0.0  0.0  0.0  0.0)   ; 011
              (0.0  0.0  0.0  0.0  1.0  0.0  0.0  0.0)   ; 100
              (0.0  0.0  0.0  0.0  0.0  1.0  0.0  0.0)   ; 101
              (0.0  0.0  0.0  0.0  0.0  0.0  0.0  ,i-)   ; 110
              (0.0  0.0  0.0  0.0  0.0  0.0  ,i+  0.0))) ; 111
            (;; Same as previous
             "CONTROLLED FORKED Y 1 2 0"
             ;;000  001  010  011  100  101  110  111
             ((1.0  0.0  0.0  0.0  0.0  0.0  0.0  0.0)   ; 000
              (0.0  1.0  0.0  0.0  0.0  0.0  0.0  0.0)   ; 001
              (0.0  0.0  0.0  ,i-  0.0  0.0  0.0  0.0)   ; 010
              (0.0  0.0  ,i+  0.0  0.0  0.0  0.0  0.0)   ; 011
              (0.0  0.0  0.0  0.0  1.0  0.0  0.0  0.0)   ; 100
              (0.0  0.0  0.0  0.0  0.0  1.0  0.0  0.0)   ; 101
              (0.0  0.0  0.0  0.0  0.0  0.0  0.0  ,i-)   ; 110
              (0.0  0.0  0.0  0.0  0.0  0.0  ,i+  0.0))) ; 111
            ("CONTROLLED FORKED DAGGER PHASE(pi, pi/2) 2 1 0"
             ;;000  001  010  011  100  101  110  111
             ((1.0  0.0  0.0  0.0  0.0  0.0  0.0  0.0)   ; 000
              (0.0  1.0  0.0  0.0  0.0  0.0  0.0  0.0)   ; 001
              (0.0  0.0  1.0  0.0  0.0  0.0  0.0  0.0)   ; 010
              (0.0  0.0  0.0  1.0  0.0  0.0  0.0  0.0)   ; 011
              (0.0  0.0  0.0  0.0  1.0  0.0  0.0  0.0)   ; 100
              (0.0  0.0  0.0  0.0  0.0 -1.0  0.0  0.0)   ; 101
              (0.0  0.0  0.0  0.0  0.0  0.0  1.0  0.0)   ; 110
              (0.0  0.0  0.0  0.0  0.0  0.0  0.0  ,i-))) ; 111
            (;; Same as previous
             "CONTROLLED DAGGER FORKED PHASE(pi, pi/2) 2 1 0"
             ;;000  001  010  011  100  101  110  111
             ((1.0  0.0  0.0  0.0  0.0  0.0  0.0  0.0)   ; 000
              (0.0  1.0  0.0  0.0  0.0  0.0  0.0  0.0)   ; 001
              (0.0  0.0  1.0  0.0  0.0  0.0  0.0  0.0)   ; 010
              (0.0  0.0  0.0  1.0  0.0  0.0  0.0  0.0)   ; 011
              (0.0  0.0  0.0  0.0  1.0  0.0  0.0  0.0)   ; 100
              (0.0  0.0  0.0  0.0  0.0 -1.0  0.0  0.0)   ; 101
              (0.0  0.0  0.0  0.0  0.0  0.0  1.0  0.0)   ; 110
              (0.0  0.0  0.0  0.0  0.0  0.0  0.0  ,i-))) ; 111
            (;; Same as previous
             "DAGGER CONTROLLED FORKED PHASE(pi, pi/2) 2 1 0"
             ;;000  001  010  011  100  101  110  111
             ((1.0  0.0  0.0  0.0  0.0  0.0  0.0  0.0)   ; 000
              (0.0  1.0  0.0  0.0  0.0  0.0  0.0  0.0)   ; 001
              (0.0  0.0  1.0  0.0  0.0  0.0  0.0  0.0)   ; 010
              (0.0  0.0  0.0  1.0  0.0  0.0  0.0  0.0)   ; 011
              (0.0  0.0  0.0  0.0  1.0  0.0  0.0  0.0)   ; 100
              (0.0  0.0  0.0  0.0  0.0 -1.0  0.0  0.0)   ; 101
              (0.0  0.0  0.0  0.0  0.0  0.0  1.0  0.0)   ; 110
              (0.0  0.0  0.0  0.0  0.0  0.0  0.0  ,i-))) ; 111
            ("FORKED CONTROLLED DAGGER PHASE(pi, pi/2) 2 1 0"
             ;;000  001  010  011  100  101  110  111
             ((1.0  0.0  0.0  0.0  0.0  0.0  0.0  0.0)   ; 000
              (0.0  1.0  0.0  0.0  0.0  0.0  0.0  0.0)   ; 001
              (0.0  0.0  1.0  0.0  0.0  0.0  0.0  0.0)   ; 010
              (0.0  0.0  0.0 -1.0  0.0  0.0  0.0  0.0)   ; 011
              (0.0  0.0  0.0  0.0  1.0  0.0  0.0  0.0)   ; 100
              (0.0  0.0  0.0  0.0  0.0  1.0  0.0  0.0)   ; 101
              (0.0  0.0  0.0  0.0  0.0  0.0  1.0  0.0)   ; 110
              (0.0  0.0  0.0  0.0  0.0  0.0  0.0  ,i-))) ; 111

            ;; Test matrices with entries from {0, 1} U RY(z) for z in {pi/3,pi/6,pi/8,pi/10}. This
            ;; combination of RY gate + theta values was chosen because it produces a 2x2 matrix
            ;; where 3 of the 4 values are distinct, and hence easier to verify they wind up in the
            ;; expected places in the output of PARSED-PROGRAM-TO-LOGICAL-MATRIX.
            ("RY(pi/3) 0"
             ((,a+  ,b-)
              (,b+  ,a+)))
            ("RY(pi/6) 0"
             ((,c+  ,d-)
              (,d+  ,c+)))
            ("RY(pi/8) 0"
             ((,e+  ,f-)
              (,f+  ,e+)))
            ("RY(pi/10) 0"
             ((,g+  ,h-)
              (,h+  ,g+)))
            (;; Test permuting qubit args
             "FORKED CONTROLLED RY(pi/3, pi/6) 0 1 2"
             ;;000  001  010  011  100  101  110  111
             ((1.0  0.0  0.0  0.0  0.0  0.0  0.0  0.0)   ; 000
              (0.0  1.0  0.0  0.0  0.0  0.0  0.0  0.0)   ; 001
              (0.0  0.0  ,a+  0.0  0.0  0.0  ,b-  0.0)   ; 010
              (0.0  0.0  0.0  ,c+  0.0  0.0  0.0  ,d-)   ; 011
              (0.0  0.0  0.0  0.0  1.0  0.0  0.0  0.0)   ; 100
              (0.0  0.0  0.0  0.0  0.0  1.0  0.0  0.0)   ; 101
              (0.0  0.0  ,b+  0.0  0.0  0.0  ,a+  0.0)   ; 110
              (0.0  0.0  0.0  ,d+  0.0  0.0  0.0  ,c+))) ; 111
            ("FORKED CONTROLLED RY(pi/3, pi/6) 1 0 2"
             ;;000  001  010  011  100  101  110  111
             ((1.0  0.0  0.0  0.0  0.0  0.0  0.0  0.0)   ; 000
              (0.0  ,a+  0.0  0.0  0.0  ,b-  0.0  0.0)   ; 001
              (0.0  0.0  1.0  0.0  0.0  0.0  0.0  0.0)   ; 010
              (0.0  0.0  0.0  ,c+  0.0  0.0  0.0  ,d-)   ; 011
              (0.0  0.0  0.0  0.0  1.0  0.0  0.0  0.0)   ; 100
              (0.0  ,b+  0.0  0.0  0.0  ,a+  0.0  0.0)   ; 101
              (0.0  0.0  0.0  0.0  0.0  0.0  1.0  0.0)   ; 110
              (0.0  0.0  0.0  ,d+  0.0  0.0  0.0  ,c+))) ; 111
            ("FORKED CONTROLLED RY(pi/3, pi/6) 2 0 1"
             ;;000  001  010  011  100  101  110  111
             ((1.0  0.0  0.0  0.0  0.0  0.0  0.0  0.0)   ; 000
              (0.0  ,a+  0.0  ,b-  0.0  0.0  0.0  0.0)   ; 001
              (0.0  0.0  1.0  0.0  0.0  0.0  0.0  0.0)   ; 010
              (0.0  ,b+  0.0  ,a+  0.0  0.0  0.0  0.0)   ; 011
              (0.0  0.0  0.0  0.0  1.0  0.0  0.0  0.0)   ; 100
              (0.0  0.0  0.0  0.0  0.0  ,c+  0.0  ,d-)   ; 101
              (0.0  0.0  0.0  0.0  0.0  0.0  1.0  0.0)   ; 110
              (0.0  0.0  0.0  0.0  0.0  ,d+  0.0  ,c+))) ; 111
            ("FORKED CONTROLLED RY(pi/3, pi/6) 0 2 1"
             ;;000  001  010  011  100  101  110  111
             ((1.0  0.0  0.0  0.0  0.0  0.0  0.0  0.0)   ; 000
              (0.0  1.0  0.0  0.0  0.0  0.0  0.0  0.0)   ; 001
              (0.0  0.0  1.0  0.0  0.0  0.0  0.0  0.0)   ; 010
              (0.0  0.0  0.0  1.0  0.0  0.0  0.0  0.0)   ; 011
              (0.0  0.0  0.0  0.0  ,a+  0.0  ,b-  0.0)   ; 100
              (0.0  0.0  0.0  0.0  0.0  ,c+  0.0  ,d-)   ; 101
              (0.0  0.0  0.0  0.0  ,b+  0.0  ,a+  0.0)   ; 110
              (0.0  0.0  0.0  0.0  0.0  ,d+  0.0  ,c+))) ; 111
            ("FORKED CONTROLLED RY(pi/3, pi/6) 1 2 0"
             ;;000  001  010  011  100  101  110  111
             ((1.0  0.0  0.0  0.0  0.0  0.0  0.0  0.0)   ; 000
              (0.0  1.0  0.0  0.0  0.0  0.0  0.0  0.0)   ; 001
              (0.0  0.0  1.0  0.0  0.0  0.0  0.0  0.0)   ; 010
              (0.0  0.0  0.0  1.0  0.0  0.0  0.0  0.0)   ; 011
              (0.0  0.0  0.0  0.0  ,a+  ,b-  0.0  0.0)   ; 100
              (0.0  0.0  0.0  0.0  ,b+  ,a+  0.0  0.0)   ; 101
              (0.0  0.0  0.0  0.0  0.0  0.0  ,c+  ,d-)   ; 110
              (0.0  0.0  0.0  0.0  0.0  0.0  ,d+  ,c+))) ; 111
            ("FORKED CONTROLLED RY(pi/3, pi/6) 2 1 0"
             ;;000  001  010  011  100  101  110  111
             ((1.0  0.0  0.0  0.0  0.0  0.0  0.0  0.0)   ; 000
              (0.0  1.0  0.0  0.0  0.0  0.0  0.0  0.0)   ; 001
              (0.0  0.0  ,a+  ,b-  0.0  0.0  0.0  0.0)   ; 010
              (0.0  0.0  ,b+  ,a+  0.0  0.0  0.0  0.0)   ; 011
              (0.0  0.0  0.0  0.0  1.0  0.0  0.0  0.0)   ; 100
              (0.0  0.0  0.0  0.0  0.0  1.0  0.0  0.0)   ; 101
              (0.0  0.0  0.0  0.0  0.0  0.0  ,c+  ,d-)   ; 110
              (0.0  0.0  0.0  0.0  0.0  0.0  ,d+  ,c+))) ; 111
            ("FORKED FORKED RY(pi/3, pi/6, pi/8, pi/10) 2 1 0"
             ;;000  001  010  011  100  101  110  111
             ((,a+  ,b-  0.0  0.0  0.0  0.0  0.0  0.0)   ; 000
              (,b+  ,a+  0.0  0.0  0.0  0.0  0.0  0.0)   ; 001
              (0.0  0.0  ,c+  ,d-  0.0  0.0  0.0  0.0)   ; 010
              (0.0  0.0  ,d+  ,c+  0.0  0.0  0.0  0.0)   ; 011
              (0.0  0.0  0.0  0.0  ,e+  ,f-  0.0  0.0)   ; 100
              (0.0  0.0  0.0  0.0  ,f+  ,e+  0.0  0.0)   ; 101
              (0.0  0.0  0.0  0.0  0.0  0.0  ,g+  ,h-)   ; 110
              (0.0  0.0  0.0  0.0  0.0  0.0  ,h+  ,g+))) ; 111
            ("FORKED FORKED RY(pi/3, pi/6, pi/8, pi/10) 1 2 0"
             ;;000  001  010  011  100  101  110  111
             ((,a+  ,b-  0.0  0.0  0.0  0.0  0.0  0.0)   ; 000
              (,b+  ,a+  0.0  0.0  0.0  0.0  0.0  0.0)   ; 001
              (0.0  0.0  ,e+  ,f-  0.0  0.0  0.0  0.0)   ; 010
              (0.0  0.0  ,f+  ,e+  0.0  0.0  0.0  0.0)   ; 011
              (0.0  0.0  0.0  0.0  ,c+  ,d-  0.0  0.0)   ; 100
              (0.0  0.0  0.0  0.0  ,d+  ,c+  0.0  0.0)   ; 101
              (0.0  0.0  0.0  0.0  0.0  0.0  ,g+  ,h-)   ; 110
              (0.0  0.0  0.0  0.0  0.0  0.0  ,h+  ,g+))) ; 111
            ("FORKED FORKED RY(pi/3, pi/6, pi/8, pi/10) 0 1 2"
             ;;000  001  010  011  100  101  110  111
             ((,a+  0.0  0.0  0.0  ,b-  0.0  0.0  0.0)   ; 000
              (0.0  ,e+  0.0  0.0  0.0  ,f-  0.0  0.0)   ; 001
              (0.0  0.0  ,c+  0.0  0.0  0.0  ,d-  0.0)   ; 010
              (0.0  0.0  0.0  ,g+  0.0  0.0  0.0  ,h-)   ; 011
              (,b+  0.0  0.0  0.0  ,a+  0.0  0.0  0.0)   ; 100
              (0.0  ,f+  0.0  0.0  0.0  ,e+  0.0  0.0)   ; 101
              (0.0  0.0  ,d+  0.0  0.0  0.0  ,c+  0.0)   ; 110
              (0.0  0.0  0.0  ,h+  0.0  0.0  0.0  ,g+))) ; 111
            ("FORKED FORKED RY(pi/3, pi/6, pi/8, pi/10) 0 2 1"
             ;;000  001  010  011  100  101  110  111
             ((,a+  0.0  ,b-  0.0  0.0  0.0  0.0  0.0)   ; 000
              (0.0  ,e+  0.0  ,f-  0.0  0.0  0.0  0.0)   ; 001
              (,b+  0.0  ,a+  0.0  0.0  0.0  0.0  0.0)   ; 010
              (0.0  ,f+  0.0  ,e+  0.0  0.0  0.0  0.0)   ; 011
              (0.0  0.0  0.0  0.0  ,c+  0.0  ,d-  0.0)   ; 100
              (0.0  0.0  0.0  0.0  0.0  ,g+  0.0  ,h-)   ; 101
              (0.0  0.0  0.0  0.0  ,d+  0.0  ,c+  0.0)   ; 110
              (0.0  0.0  0.0  0.0  0.0  ,h+  0.0  ,g+))) ; 111
            ("CONTROLLED CONTROLLED RY(pi/3) 2 1 0"
             ;;000  001  010  011  100  101  110  111
             ((1.0  0.0  0.0  0.0  0.0  0.0  0.0  0.0)   ; 000
              (0.0  1.0  0.0  0.0  0.0  0.0  0.0  0.0)   ; 001
              (0.0  0.0  1.0  0.0  0.0  0.0  0.0  0.0)   ; 010
              (0.0  0.0  0.0  1.0  0.0  0.0  0.0  0.0)   ; 011
              (0.0  0.0  0.0  0.0  1.0  0.0  0.0  0.0)   ; 100
              (0.0  0.0  0.0  0.0  0.0  1.0  0.0  0.0)   ; 101
              (0.0  0.0  0.0  0.0  0.0  0.0  ,a+  ,b-)   ; 110
              (0.0  0.0  0.0  0.0  0.0  0.0  ,b+  ,a+))) ; 111
            (;; Same as above
             "CONTROLLED CONTROLLED RY(pi/3) 1 2 0"
             ;;000  001  010  011  100  101  110  111
             ((1.0  0.0  0.0  0.0  0.0  0.0  0.0  0.0)   ; 000
              (0.0  1.0  0.0  0.0  0.0  0.0  0.0  0.0)   ; 001
              (0.0  0.0  1.0  0.0  0.0  0.0  0.0  0.0)   ; 010
              (0.0  0.0  0.0  1.0  0.0  0.0  0.0  0.0)   ; 011
              (0.0  0.0  0.0  0.0  1.0  0.0  0.0  0.0)   ; 100
              (0.0  0.0  0.0  0.0  0.0  1.0  0.0  0.0)   ; 101
              (0.0  0.0  0.0  0.0  0.0  0.0  ,a+  ,b-)   ; 110
              (0.0  0.0  0.0  0.0  0.0  0.0  ,b+  ,a+))) ; 111
            ("CONTROLLED CONTROLLED RY(pi/3) 0 1 2"
             ;;000  001  010  011  100  101  110  111
             ((1.0  0.0  0.0  0.0  0.0  0.0  0.0  0.0)   ; 000
              (0.0  1.0  0.0  0.0  0.0  0.0  0.0  0.0)   ; 001
              (0.0  0.0  1.0  0.0  0.0  0.0  0.0  0.0)   ; 010
              (0.0  0.0  0.0  ,a+  0.0  0.0  0.0  ,b-)   ; 011
              (0.0  0.0  0.0  0.0  1.0  0.0  0.0  0.0)   ; 100
              (0.0  0.0  0.0  0.0  0.0  1.0  0.0  0.0)   ; 101
              (0.0  0.0  0.0  0.0  0.0  0.0  1.0  0.0)   ; 110
              (0.0  0.0  0.0  ,b+  0.0  0.0  0.0  ,a+))) ; 111
            ("CONTROLLED CONTROLLED RY(pi/3) 0 2 1"
             ;;000  001  010  011  100  101  110  111
             ((1.0  0.0  0.0  0.0  0.0  0.0  0.0  0.0)   ; 000
              (0.0  1.0  0.0  0.0  0.0  0.0  0.0  0.0)   ; 001
              (0.0  0.0  1.0  0.0  0.0  0.0  0.0  0.0)   ; 010
              (0.0  0.0  0.0  1.0  0.0  0.0  0.0  0.0)   ; 011
              (0.0  0.0  0.0  0.0  1.0  0.0  0.0  0.0)   ; 100
              (0.0  0.0  0.0  0.0  0.0  ,a+  0.0  ,b-)   ; 101
              (0.0  0.0  0.0  0.0  0.0  0.0  1.0  0.0)   ; 110
              (0.0  0.0  0.0  0.0  0.0  ,b+  0.0  ,a+))) ; 111
            ))))
