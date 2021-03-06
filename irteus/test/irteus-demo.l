(require :unittest "lib/llib/unittest.l")

(init-unit-test)

(load "irteus/demo/demo.l")
(defmacro do-until-key (&rest forms) (with-gensyms (do-until-key-counter tm) `(progn (setq tm (instance mtimer :init)) (dotimes (do-until-key-counter 10) (warning-message 2 ";; do-until-key ~7,3f ~A/~A~%" (send tm :stop) do-until-key-counter 10) ,@forms))))

(deftest test-full-body-ik
  (full-body-ik))

(deftest test-full-body-ik-use-torso
  (full-body-ik :use-torso nil))

(deftest test-full-body-ik-use-leg
  (full-body-ik :use-leg t))

(deftest test-dual-arm-ik
  (dual-arm-ik))

(deftest test-dual-manip-ik
  (dual-manip-ik))

(deftest test-crank-motion
  (crank-motion))

(deftest test-hand-grasp
  (hand-grasp))

(deftest test-hanoi-arm
  (hanoi-arm))

(deftest test-particle
  (particle))

;; check whether all ik are solved for walking examples
(deftest test-walk-motion-for-sample-robot
  (assert
   (not (some #'null (mapcar #'(lambda (x) (cadr (memq :angle-vector x)))
                             (walk-motion-for-sample-robot))))))

(deftest test-trot-walk-motion-for-sample-robot-go-backward-over
  (assert
   (not (some #'null (mapcar #'(lambda (x) (cadr (memq :angle-vector x)))
                             (trot-walk-motion-for-sample-robot))))))

(deftest test-trot-walk-motion-for-sample-robot
  (assert
   (not (some #'null (mapcar #'(lambda (x) (cadr (memq :angle-vector x)))
                             (trot-walk-motion-for-sample-robot :go-backward-over nil))))))

(deftest test-crawl-walk-motion-for-sample-robot-go-backward-over
  (assert
   (not (some #'null (mapcar #'(lambda (x) (cadr (memq :angle-vector x)))
                             (crawl-walk-motion-for-sample-robot))))))

(deftest test-crawl-walk-motion-for-sample-robot
  (assert
   (not (some #'null (mapcar #'(lambda (x) (cadr (memq :angle-vector x)))
                             (crawl-walk-motion-for-sample-robot :go-backward-over nil))))))

(deftest test-walk-motion-for-robots
  (assert
   (every #'identity
          (mapcar #'(lambda (rs-list) (not (some #'null (mapcar #'(lambda (x) (cadr (memq :angle-vector x))) rs-list))))
                  (walk-motion-for-robots)))))

(run-all-tests)
(exit)
