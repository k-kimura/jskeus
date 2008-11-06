;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;
;;; $Id$
;;;
;;; Copyright (c) 1987- JSK, The University of Tokyo.  All Rights Reserved.
;;;
;;; This software is a collisoin of EusLisp code for robot applications,
;;; which has been developed by the JSK Laboratory for the IRT project.
;;; For more information on EusLisp and it's application to the robotics,
;;; please refer to the following papers.
;;;
;;; Toshihiro Matsui
;;; Multithread object-oriented language euslisp for parallel and
;;;  asynchronous programming in robotics
;;; Workshop on Concurrent Object-based Systems,
;;;  IEEE 6th Symposium on Parallel and Distributed Processing, 1994
;;;
;;; Permission to use this software for educational, research
;;; and non-profit purposes, without fee, and without a written
;;; agreement is hereby granted to all researchers working on
;;; the IRT project at the University of Tokyo, provided that the
;;; above copyright notice remains intact.  
;;;

(require :irtglrgb)

(in-package "GL")
(import '(read-jpeg-file) (find-package "USER"))

(let (glu-lib)
#+:cygwin
  (progn
    (setq glu-lib ( load-foreign "/usr/X11R6/bin/cygGLU-1.dll")))
#+:linux 
  (progn
    (setq glu-lib
	  (cond ((probe-file "/usr/lib/libGLU.so")
		 (load-foreign "/usr/lib/libGLU.so"))
		((probe-file "/usr/X11R6/lib/libGLU.so")
		 (load-foreign "/usr/X11R6/lib/libGLU.so"))
		(t (warn ";; libGLU.so not found")))))
  (defforeign gluTessBeginPolygon glu-lib "gluTessBeginPolygon" () :integer)
  (defforeign gluTessEndPolygon glu-lib "gluTessEndPolygon" () :integer)
  (defforeign gluTessBeginContour glu-lib "gluTessBeginContour" () :integer)
  (defforeign gluTessEndContour glu-lib "gluTessEndContour" () :integer)
  )

(unless (assoc :color-org (send glviewsurface :methods))
  (rplaca (assoc :color (send glviewsurface :methods)) :color-org))
(defmethod glviewsurface
  (:color 
   (&optional color-vector)
   (if color-vector (send self :color-org color-vector)
     (let ((v (float-vector 0 0 0 0)))
       (glgetfloatv GL_CURRENT_COLOR v)
       (subseq v 0 3))))
  (:line-width 
   (&optional x)
   (if x (glLineWidth (float x))
     (let ((tmp (float-vector 0)))
       (glGetFloatv GL_LINE_WIDTH tmp)
       (elt tmp 0))
     ))
  (:point-size 
   (&optional x)
   (if x (glPointSize (float x))
     (let ((tmp (float-vector 0)))
       (glGetFloatv GL_POINT_SIZE tmp)
       (elt tmp 0))
     ))
  (:3d-point (pos &key (depth-test t) (lighting t)) ;; redefined
	     (if depth-test (glDisable GL_DEPTH_TEST))
	     (if lighting (glDisable GL_LIGHTING))
	     (glBegin GL_POINTS)
	     (glVertex3fv pos)
	     (glEnd)
	     (if depth-test (glEnable GL_DEPTH_TEST))
	     (if lighting (glEnable GL_LIGHTING)))
  (:3d-line (start end &key (depth-test t) (lighting t)) ;; redefined
	    (if depth-test (glDisable GL_DEPTH_TEST))
	    (if lighting (glDisable GL_LIGHTING))
	    (glBegin GL_LINE_STRIP)
	    (glVertex3fv start)
	    (glVertex3fv end)
	    (glEnd)
	    (if depth-test (glEnable GL_DEPTH_TEST))
	    (if lighting (glEnable GL_LIGHTING)))
  (:3d-lines (points &key (depth-test t) (lighting t))
	     (if depth-test (glDisable GL_DEPTH_TEST))
	     (if lighting (glDisable GL_LIGHTING))
	     (glBegin GL_LINE_STRIP)
	     (dolist (p points) (glVertex3fv p))
	     (glEnd)
	     (if depth-test (glEnable GL_DEPTH_TEST))
	     (if lighting (glEnable GL_LIGHTING)))
  ;;
  (:makecurrent () (gl::glxMakeCurrent x::*display* x::drawable glcon))
  (:redraw (&rest args) )
  (:flush 
   ()
   (send self :makecurrent)
   (send self :glflush)
   (send-super :flush)
   )
  )

(defun draw-globjects (vwr draw-things &key (clear t) (flush t))
  (let (pcolor)
    (resetperspective (send vwr :viewing) (send vwr :viewsurface))
    (if clear (send vwr :viewsurface :clear))
    ;;(apply #'geo::draw things)
    (setq pcolor (send vwr :viewsurface :color))
    ;; draw origin
    (glDisable GL_LIGHTING)
    (glBegin GL_LINES)
    (glColor3fv #f(1 0 0)) (glVertex3fv #f(0 0 0)) (glVertex3fv #f(100 0 0))
    (glColor3fv #f(0 1 0)) (glVertex3fv #f(0 0 0)) (glVertex3fv #f(0 100 0))
    (glColor3fv #f(0 0 1)) (glVertex3fv #f(0 0 0)) (glVertex3fv #f(0 0 100))
    (glEnd GL_LINES)
    (glEnable GL_LIGHTING)
    (glDisable GL_BLEND)
    (send vwr :viewsurface :color pcolor)
      
    (dolist (abody draw-things)
      ;; draw body
      (cond
       ((find-method abody :draw)
	(send abody :draw vwr))
       ((derivedp abody faceset)
	(draw-glbody vwr abody))
       ((find-method abody :draw-on)
	(send abody :draw-on :viewer vwr))
       (t (warn "Unknown body to draw ~A~%" abody)))
       )
    (if flush (send vwr :viewsurface :flush))
    ))

;;
;; re-definition
;;  
(defun draw-glbody (vwr abody)
  (let* (glcon
	 (lis (cdr (assq glcon (get abody :GL-DISPLAYLIST-ID))))
	 (col (get abody :face-color)))
    (unless col (setq col (float-vector 0.5 0.5 0.5)))
    (unless (vectorp col)
      ;;(warn "draw-body: body ~A face-color ~A~%" abody col)
      (setq col (find-color col))
      (setf (get abody :face-color) col))
    (cond
     (lis
      (let ((mat (send (send abody :worldcoords) :4x4)))
	(glPushMatrix)
	(glMultMatrixf (array-entity (transpose mat *temp-matrix*)))
	(glCallList lis)
	(glPopMatrix)))
     (t
      (let ((newlis (glGenLists 1))
	    (transp (and (= (length col) 4) (< (elt col 3) 1.0)))
	    p2)
	(glNewList newlis gl_compile)
	(when transp
	  (glEnable GL_BLEND)
	  (glBlendFunc GL_SRC_ALPHA GL_ONE_MINUS_SRC_ALPHA))
	(glMaterialfv GL_FRONT_AND_BACK GL_AMBIENT_AND_DIFFUSE col)
	(dolist (aface (send abody :faces))
	  (cond
	   ;; normal face
	   ((and (send aface :convexp) (not (send aface :holes)))
	    (let ((texture-img (get aface :GL-TEXTUREIMAGE))
		  (texture-coords (get aface :GL-TEXTURECOORDS)))
	      (when texture-img
		(glTexImage2D 
		 GL_TEXTURE_2D
		 0 (/ (send texture-img :depth) 8)
		 (send texture-img :width) (send texture-img :height)
		 0 GL_RGB GL_UNSIGNED_BYTE (send texture-img :entity))
		(glTexEnvi GL_TEXTURE_ENV GL_TEXTURE_ENV_MODE GL_DECAL)
		(glEnable GL_TEXTURE_2D))
	      (glBegin GL_POLYGON)
	      (glNormal3fv (send aface :normal))
	      (dolist (p (cdr (send aface :vertices)))
		(if (and texture-coords
			 (setq p2 (gethash p texture-coords)))
		    (glTexCoord2fv p2))
		(glVertex3fv (send abody :inverse-transform-vector p)))
	      (glEnd)
	      (when texture-img
		(glDisable GL_TEXTURE_2D))
	      ))
	   ;; holed face
	   (t
	    (let ((holes (send aface :holes)) l-tessinfo)
	      (setq l-tessinfo
		(mapcar #'(lambda (p)
			    (setq p (send abody :inverse-transform-vector p))
			    (alloctessinfo p 0 nil 0 nil))
			(cdr (send aface :vertices))))
	      (gluTessBeginPolygon *tess-obj* 0)
	      (gluTessBeginContour *tess-obj*)
	      (glNormal3fv (send aface :normal))
	      (mapc #'(lambda (i) (gluTessVertex *tess-obj* i i)) l-tessinfo)
	      (gluTessEndContour *tess-obj*)
	      (gluTessBeginContour *tess-obj*)
	      ;; holes
	      (when holes
		(dolist (hole holes)
		  (let ((h-l-tessinfo
			 (mapcar #'(lambda (p)
				     (setq p (send abody :inverse-transform-vector p))
				     (alloctessinfo p 0 nil 0 nil))
				 (send hole :vertices))))
		    (gluNextContour *tess-obj* GLU_INTERIOR)
		    (mapc #'(lambda (i) (gluTessVertex *tess-obj* i i)) h-l-tessinfo)
		    (nconc l-tessinfo h-l-tessinfo) ;hook it, to deallocated later.
		    )))
	      (gluTessEndContour *tess-obj*)
	      (gluTessEndPolygon *tess-obj*)
	      (mapc #'unix:free l-tessinfo) ;deallocate
	      )))
	  )
	;;
	(when transp
	  (glDisable GL_BLEND))
	(glEndList)
	(setf (get abody :GL-DISPLAYLIST-ID)
	      (cons (cons glcon newlis) (get abody :GL-DISPLAYLIST-ID)))
	(draw-glbody vwr abody)
	)))
    ))

(defun find-color (color)
  (let (v c)
    (setq v
      (cond
       ((null color) nil)
       ((derivedp color colormaterial) (send color :diffuse))
       ((symbolp color)
	(setq c (find-if #'(lambda (o) (eq (send o :name) color))
			 *face-colors*))
	(when c (send c :diffuse)))
       (t color)))
    (unless v (setq v (float-vector 0.5 0.5 0.5)))
    v))

(defun transparent (abody param)
  (let (fc dif)
    (when (setq fc (get abody :face-color))
      (unless (vectorp fc)
	(warn "transparent: body ~A param ~A face-color ~A~%" abody param fc)
	(setq fc (find-color fc)))
      (if (= (length fc) 3)
	  (setq fc
	    (concatenate float-vector fc #f(0))))
      (setf (elt fc 3) param)
      (setf (get abody :face-color) fc)
      (setf (get abody :GL-DISPLAYLIST-ID) nil)
      fc)))

(defmethod polygon
  (:draw-on
   (&key ((:viewer vwer) *viewer*)
         flush (width 1) (color #f(1 1 1)))
   (let ((pwidth (send vwer :viewsurface :line-width))
         (pcolor (send vwer :viewsurface :color))
	 (v (float-vector 0 0 0)))
     (send vwer :viewsurface :line-width width)
     (send vwer :viewsurface :color color)
     (send vwer :viewsurface :3d-lines (send self :vertices))
     (send vwer :viewsurface :line-width pwidth)
     (send vwer :viewsurface :color pcolor)
     (if flush (send vwer :viewsurface :flush))
     ))
  )

(defmethod line
  (:draw-on
   (&key ((:viewer vwer) *viewer*)
         flush (width 1) (color #f(1 1 1)))
   (let ((pwidth (send vwer :viewsurface :line-width))
         (pcolor (send vwer :viewsurface :color))
	 (v (float-vector 0 0 0)))
     (send vwer :viewsurface :line-width width)
     (send vwer :viewsurface :color color)
     (send vwer :viewsurface :3d-line pvert nvert)
     (send vwer :viewsurface :line-width pwidth)
     (send vwer :viewsurface :color pcolor)
     (if flush (send vwer :viewsurface :flush))
     ))
  )

(defmethod faceset
  (:set-color
   (color)
   (setf (get self :GL-DISPLAYLIST-ID) nil)
   (setf (get self :face-color) (gl::find-color color)))
  (:draw-on
   (&key ((:viewer vwer) *viewer*)
         flush (width 1) (color #f(1 1 1)))
   (let ((pwidth (send vwer :viewsurface :line-width))
         (pcolor (send vwer :viewsurface :color)))
     (send vwer :viewsurface :line-width width)
     (send vwer :viewsurface :color color)
     (dolist (f (send self :faces))
       (send vwer :viewsurface :3d-lines (send f :vertices)))
     (send vwer :viewsurface :line-width pwidth)
     (send vwer :viewsurface :color pcolor)
     (if flush (send vwer :viewsurface :flush))
     ))
  ;;
  (:paste-texture-to-face
   (aface &key file)
   (let (img ow oh od tw th)
     (cond 
      ((probe-file file)
       (setq img (read-jpeg-file file)))
      (t (warn ";; Could not find file ~A~%" file)
	 (return-from :paste-texture-to-face nil)))
     (setq ow (send img :width) oh (send img :height)
	   od (/ (send img :depth) 8)
	   tw (ash 1 (ceiling (log ow 2)))
	   th (ash 1 (ceiling (log oh 2))))
     (when (not (= od 3)) (error "not supported depth"))
     (when (not (and (= ow tw) (= oh th)))
       ;; rescale to boundary
       (let ((b (make-string (* tw th od))))
	 (gluScaleImage GL_RGB ow oh GL_UNSIGNED_BYTE (send img :entity)
			    tw th GL_UNSIGNED_BYTE b)
	 (setq img (instance img:color-image24 :init tw th b))))
     (setf (get aface :gl-textureimage) img)
     (setf (get aface :gl-texturecoords) (make-hash-table :test #'equal))
     ;;
     (let ((tmp-coords
	    (list (float-vector 0 0) (float-vector 0 1)
		  (float-vector 1 1) (float-vector 1 0))))
       (dolist (p (cdr (send aface :vertices)))
	 (setf (gethash p (get aface :gl-texturecoords))
	       (pop tmp-coords))))
     ))
  )

(defmethod coordinates
  (:vertices () (list (send self :worldpos)))
  (:draw-on
   (&key ((:viewer vwer) user::*viewer*)
	 flush (width (get self :width)) (color (get self :color))
	 (size (get self :size)))
   (let ((pwidth (send vwer :viewsurface :line-width))
         (pcolor (send vwer :viewsurface :color))
	 (v (float-vector 0 0 0)) v2)
     (if (null width) (setq width 1))
     (if (null color) (setq color #f(1 1 1)))
     (if (null size) (setq size 50))
     (setq v2 (float-vector (* 0.3 size) 0 (* 0.7 size)))
     (send vwer :viewsurface :line-width width)
     (send vwer :viewsurface :color color)
     (dotimes (i 3)
       (setf (elt v i) size)
       (send vwer :viewsurface :3d-line
	     (send self :worldpos)
	     (send self :transform-vector v))
       (setf (elt v i) 0))
     (setf (elt v 2) size)
     (send vwer :viewsurface :3d-line
	   (send self :transform-vector v)
	   (send self :transform-vector v2))
     (setf (elt v2 1) (elt v2 0)  (elt v2 0) 0)
     (send vwer :viewsurface :3d-line
	   (send self :transform-vector v)
	   (send self :transform-vector v2))
     (send vwer :viewsurface :line-width pwidth)
     (send vwer :viewsurface :color pcolor)
     (if flush (send vwer :viewsurface :flush))
     ))
  )

(defmethod geo::float-vector
  (:vertices () (list self))
  (:draw-on
   (&key ((:viewer vwer) *viewer*)
         flush (width 1) (color #f(1 1 1)) (size 50))
   (let ((pwidth (send vwer :viewsurface :line-width))
         (pcolor (send vwer :viewsurface :color))
	 (v (float-vector 0 0 0)))
     (send vwer :viewsurface :line-width width)
     (send vwer :viewsurface :color color)
     (dotimes (i 3)
       (setf (elt v i) size)
       (send vwer :viewsurface :3d-line self (v+ self v))
       (setf (elt v i) 0))
     (send vwer :viewsurface :line-width pwidth)
     (send vwer :viewsurface :color pcolor)
     (if flush (send vwer :viewsurface :flush))
     ))
  )

(provide :irtgl "$Id$")

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;
;;; $Id$
;;;
;;; $Log$
;;; Revision 1.3  2008-11-06 17:19:47  k-okada
;;; fix to work with jskrbeusgl
;;;
;;; Revision 1.2  2008/09/22 06:02:10  k-okada
;;; fix to work with jskeusgl
;;;
;;; Revision 1.1  2008/09/18 18:11:01  k-okada
;;; add irteus
;;;
;;;