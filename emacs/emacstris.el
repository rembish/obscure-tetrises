;;; emacstris.el --- a falling-block puzzle game for Emacs in batch mode -*- lexical-binding: t -*-

;; Run it headless:
;;
;;   emacs --batch -Q -l emacstris.el
;;
;; stdin:  the seed on the first line, then one event number per line
;;         (0 tick, 1 left, 2 right, 3 rotate, 4 soft drop, 5 hard drop, 9 quit).
;; stdout: one frame of ANSI escapes after every event that changed something.
;;
;; The rules, the random numbers and the exact output bytes are described in
;; ../SPEC.md.  Nothing here touches a buffer, a window or a keymap: in batch
;; mode Emacs is just a Lisp interpreter with a line reader on stdin
;; (`read-from-minibuffer') and a printer on stdout (`princ').

;;; Code:

;; ---------------------------------------------------------------------------
;; Constants
;; ---------------------------------------------------------------------------

(defconst emacstris-title "E M A C S T R I S")

(defconst emacstris-masks
  ;; One vector of four rotations per piece.  Bit y*4+x of a mask is the cell
  ;; at column x, row y of the piece's 4x4 box.
  [[240 17476 3840 8738]                ; I
   [102 102 102 102]                    ; O
   [114 610 624 562]                    ; T
   [54 1122 864 561]                    ; S
   [99 612 1584 306]                    ; Z
   [113 550 1136 802]                   ; J
   [116 1570 368 547]]                  ; L
  "Rotation masks, indexed by piece number then rotation.")

(defconst emacstris-colours [51 226 135 46 196 33 208]
  "256-colour palette index for each piece.")

(defconst emacstris-points [0 40 100 300 1200]
  "Points for clearing 0..4 rows, multiplied by the level.")

(defconst emacstris-width 10)
(defconst emacstris-height 20)

;; ---------------------------------------------------------------------------
;; State.  Everything is a plain global; there is only ever one game.
;; ---------------------------------------------------------------------------

(defvar emacstris-board nil
  "Vector of width*height cells, row-major.  0 = empty, else piece + 1.")
(defvar emacstris-seed 1 "Park-Miller generator state.")
(defvar emacstris-piece 0 "Current piece number.")
(defvar emacstris-next 0 "Next piece number.")
(defvar emacstris-x 3)
(defvar emacstris-y 0)
(defvar emacstris-rot 0)
(defvar emacstris-ticks 0 "Ticks since the piece last fell.")
(defvar emacstris-score 0)
(defvar emacstris-lines 0)
(defvar emacstris-over nil "Non-nil once a new piece could not spawn.")

;; ---------------------------------------------------------------------------
;; Rules
;; ---------------------------------------------------------------------------

(defun emacstris-random ()
  "Advance the Park-Miller generator and return a piece number 0..6.
Emacs fixnums are 62 bits wide, so seed * 16807 never overflows."
  (setq emacstris-seed (% (* emacstris-seed 16807) 2147483647))
  (% emacstris-seed 7))

(defun emacstris-level ()
  (1+ (/ emacstris-lines 10)))

(defun emacstris-cells (piece rot)
  "List of (X . Y) offsets of the cells of PIECE in rotation ROT."
  (let ((mask (aref (aref emacstris-masks piece) rot))
        cells)
    (dotimes (i 16)
      (when (/= 0 (logand (ash mask (- i)) 1))
        (push (cons (% i 4) (/ i 4)) cells)))
    cells))

(defun emacstris-cell (x y)
  "The board cell at column X, row Y (both assumed on the board)."
  (aref emacstris-board (+ (* y emacstris-width) x)))

(defun emacstris-fits (x y rot)
  "Non-nil if the current piece fits with its box at X, Y in rotation ROT."
  (let ((ok t))
    (dolist (c (emacstris-cells emacstris-piece rot) ok)
      (let ((bx (+ x (car c)))
            (by (+ y (cdr c))))
        (unless (and (<= 0 bx) (< bx emacstris-width)
                     (<= 0 by) (< by emacstris-height)
                     (= 0 (emacstris-cell bx by)))
          (setq ok nil))))))

(defun emacstris-spawn ()
  "Put the current piece at the top; the game is over if it does not fit."
  (setq emacstris-x 3 emacstris-y 0 emacstris-rot 0 emacstris-ticks 0)
  (unless (emacstris-fits emacstris-x emacstris-y emacstris-rot)
    (setq emacstris-over t)))

(defun emacstris-clear-rows ()
  "Remove full rows, shifting the rows above down.  Return how many went."
  (let ((dst (1- emacstris-height))
        (w emacstris-width))
    ;; Walk the rows bottom-up, copying each row that is not full to DST.
    (let ((src (1- emacstris-height)))
      (while (>= src 0)
        (let ((full t))
          (dotimes (x w)
            (when (= 0 (emacstris-cell x src)) (setq full nil)))
          (unless full
            (dotimes (x w)
              (aset emacstris-board (+ (* dst w) x) (emacstris-cell x src)))
            (setq dst (1- dst))))
        (setq src (1- src))))
    ;; Whatever is left above DST becomes empty rows.
    (dotimes (i (* (1+ dst) w))
      (aset emacstris-board i 0))
    (1+ dst)))

(defun emacstris-lock ()
  "Write the piece into the board, clear rows, score, and spawn the next one."
  (dolist (c (emacstris-cells emacstris-piece emacstris-rot))
    (aset emacstris-board
          (+ (* (+ emacstris-y (cdr c)) emacstris-width) emacstris-x (car c))
          (1+ emacstris-piece)))
  (let ((n (emacstris-clear-rows)))
    ;; The level used for scoring is the one before these rows count.
    (setq emacstris-score (+ emacstris-score
                             (* (aref emacstris-points n) (emacstris-level))))
    (setq emacstris-lines (+ emacstris-lines n)))
  (setq emacstris-piece emacstris-next
        emacstris-next (emacstris-random))
  (emacstris-spawn))

(defun emacstris-step-down ()
  "Move the piece one row down, or lock it if it cannot move."
  (if (emacstris-fits emacstris-x (1+ emacstris-y) emacstris-rot)
      (setq emacstris-y (1+ emacstris-y))
    (emacstris-lock)))

(defun emacstris-event (e)
  "Apply event E.  Return non-nil if a frame should be printed."
  (pcase e
    (0 (setq emacstris-ticks (1+ emacstris-ticks))
       (when (>= emacstris-ticks (max 1 (- 11 (emacstris-level))))
         (setq emacstris-ticks 0)
         (emacstris-step-down)
         t))
    ((or 1 2)
     (let ((nx (+ emacstris-x (if (= e 1) -1 1))))
       (when (emacstris-fits nx emacstris-y emacstris-rot)
         (setq emacstris-x nx)))
     t)
    (3 (let ((nr (% (1+ emacstris-rot) 4))
             (kicks '(0 -1 1 -2 2)))
         (while kicks
           (if (emacstris-fits (+ emacstris-x (car kicks)) emacstris-y nr)
               (setq emacstris-x (+ emacstris-x (car kicks))
                     emacstris-rot nr
                     kicks nil)
             (setq kicks (cdr kicks)))))
       t)
    (4 (emacstris-step-down) t)
    (5 (while (emacstris-fits emacstris-x (1+ emacstris-y) emacstris-rot)
         (setq emacstris-y (1+ emacstris-y)))
       (emacstris-lock)
       t)
    (_ nil)))

;; ---------------------------------------------------------------------------
;; Output
;; ---------------------------------------------------------------------------

(defun emacstris-border (s) (concat "\e[38;5;60m" s "\e[m"))
(defun emacstris-dim (s) (concat "\e[38;5;244m" s "\e[m"))
(defun emacstris-bold (s) (concat "\e[1m" s "\e[m"))

(defun emacstris-block (piece)
  "A filled cell in the colour of PIECE."
  (format "\e[38;5;%dm██\e[m" (aref emacstris-colours piece)))

(defconst emacstris-keys
  '(("← a" . "move left") ("→ d" . "move right") ("↑ w" . "rotate")
    ("↓ s" . "soft drop") ("␣ z" . "hard drop") ("  q" . "quit"))
  "Side-panel control rows, board rows 14..19.")

(defun emacstris-panel (row)
  "The side-panel text to the right of board ROW."
  (let ((side (emacstris-border "│")))
    (cond
     ((= row 0) (concat "   " (emacstris-border "╭──") " " (emacstris-dim "next")
                        " " (emacstris-border "──────╮")))
     ((memq row '(1 6)) (concat "   " side (make-string 14 ?\s) side))
     ((<= 2 row 5)
      ;; One row of the next piece's box, rotation 0.
      (let ((mask (aref (aref emacstris-masks emacstris-next) 0))
            (cells ""))
        (dotimes (x 4)
          (setq cells
                (concat cells
                        (if (/= 0 (logand (ash mask (- (+ (* (- row 2) 4) x))) 1))
                            (emacstris-block emacstris-next)
                          "  "))))
        (concat "   " side "   " cells "   " side)))
     ((= row 7) (concat "   " (emacstris-border
                               (concat "╰" (make-string 14 ?─) "╯"))))
     ((= row 9) (concat "   " (emacstris-dim "score")))
     ((= row 10) (concat "   " (emacstris-bold (number-to-string emacstris-score))))
     ((= row 11) (concat "   " (emacstris-dim "level") " "
                         (emacstris-bold (number-to-string (emacstris-level)))
                         "  " (emacstris-dim "lines") " "
                         (emacstris-bold (number-to-string emacstris-lines))))
     ((= row 13) (concat "   " (emacstris-dim "controls")))
     ((<= 14 row 19)
      (let ((k (nth (- row 14) emacstris-keys)))
        (concat "   " (emacstris-bold (car k)) "  " (emacstris-dim (cdr k)))))
     (t ""))))

(defun emacstris-frame ()
  "Build the whole frame as one string."
  (let ((grid (copy-sequence emacstris-board))
        (lines nil))
    ;; Draw the falling piece on a copy of the board (not on game over).
    (unless emacstris-over
      (dolist (c (emacstris-cells emacstris-piece emacstris-rot))
        (aset grid (+ (* (+ emacstris-y (cdr c)) emacstris-width) emacstris-x (car c))
              (1+ emacstris-piece))))
    (push (concat "  \e[1;38;5;75m" emacstris-title "\e[m") lines)
    (push (concat " " (emacstris-border (concat "╔" (make-string 20 ?═) "╗"))) lines)
    (dotimes (y emacstris-height)
      (let ((body ""))
        (if (and emacstris-over (= y 9))
            (setq body "\e[1;7m     GAME  OVER     \e[m")
          (dotimes (x emacstris-width)
            (let ((c (aref grid (+ (* y emacstris-width) x))))
              (setq body (concat body (if (= c 0) "\e[38;5;237m ·\e[m"
                                        (emacstris-block (1- c))))))))
        (push (concat " " (emacstris-border "║") body (emacstris-border "║")
                      (emacstris-panel y))
              lines)))
    (push (concat " " (emacstris-border (concat "╚" (make-string 20 ?═) "╝"))) lines)
    (concat "\e[H"
            (mapconcat (lambda (l) (concat l "\e[K\n")) (nreverse lines) ""))))

(defun emacstris-draw ()
  ;; In batch mode `princ' writes to stdout and the bytes reach the pipe
  ;; before the next line is read, so every frame shows up at once.
  (princ (emacstris-frame)))

;; ---------------------------------------------------------------------------
;; Main loop
;; ---------------------------------------------------------------------------

(defun emacstris-read-line ()
  "Read one line from stdin, or nil at end of input.
In batch mode `read-from-minibuffer' reads stdin and signals an error at EOF."
  (condition-case nil
      (read-from-minibuffer "")
    (error nil)))

(defun emacstris-main ()
  (setq emacstris-board (make-vector (* emacstris-width emacstris-height) 0)
        emacstris-seed (string-to-number (or (emacstris-read-line) "1")))
  (setq emacstris-piece (emacstris-random)
        emacstris-next (emacstris-random))
  (emacstris-spawn)
  (emacstris-draw)
  (let (line e)
    (while (and (not emacstris-over)
                (setq line (emacstris-read-line)))
      ;; Blank lines are skipped; `string-to-number' would read them as 0.
      (unless (string-match-p "\\`[ \t]*\\'" line)
        (setq e (string-to-number line))
        (if (= e 9)
            (setq emacstris-over 'quit)     ; stop at once, no frame
          (when (emacstris-event e)
            (emacstris-draw)))))))

(emacstris-main)

;;; emacstris.el ends here
