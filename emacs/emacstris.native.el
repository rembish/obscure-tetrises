;;; emacstris.native.el --- play emacstris in Emacs itself, without the launcher -*- lexical-binding: t -*-

;;   emacs -Q -nw -l emacstris.native.el
;;   SEED=42 emacs -Q -nw -l emacstris.native.el      (a fixed game)
;;
;; emacstris.sh runs Emacs in batch mode and feeds it numbers: bash reads the
;; keys and sends a tick every 100 ms.  Here Emacs does both.  In a terminal
;; frame (-nw) the terminal is in raw mode, so `read-event' with a timeout
;; returns each key as it is pressed, or nil when there is none, and
;; `float-time' keeps the time.  The game is emacstris.el's, loaded from next
;; to this file: same rules, same frames.
;;
;; The frames go to the terminal with `send-string-to-terminal', past Emacs's
;; own display, which `inhibit-redisplay' keeps from drawing over them.

;;; Code:

(defvar emacstris-native t
  "Tells emacstris.el not to run its stdin loop.")
(load (expand-file-name "emacstris.el" (file-name-directory load-file-name)) nil t)

;; In batch mode emacstris.el prints to stdout; here it goes to the terminal.
;; Raw mode also turns off the terminal's output processing, so a bare newline
;; only moves the cursor down: every line ends in "\r\n".
(defun emacstris-draw ()
  (send-string-to-terminal (string-replace "\n" "\r\n" (emacstris-frame))))

(defun emacstris-native-key ()
  "The next key as a character or an arrow symbol, or nil if none is waiting.
`read-event' sees the bytes the terminal sends, so ESC [ D (or ESC O D) is
decoded here into `left', and so on."
  (let ((e (read-event nil nil 0.01)))
    (if (not (eq e ?\e))
        e
      (let ((e2 (read-event nil nil 0.01)))
        (if (memq e2 '(?\[ ?O))
            (pcase (read-event nil nil 0.01)
              (?A 'up) (?B 'down) (?C 'right) (?D 'left))
          e2)))))

(defun emacstris-native-event (key)
  "The event number for KEY, as in ../SPEC.md, or nil."
  (pcase key
    ((or ?a ?A 'left) 1)
    ((or ?d ?D 'right) 2)
    ((or ?w ?W 'up) 3)
    ((or ?s ?S 'down ?\r ?\n) 4)
    ((or ?z ?Z ?\s) 5)))

(defun emacstris-native-play ()
  (let ((seed (string-to-number (or (getenv "SEED") "")))
        (start (float-time))
        (ticks 0)                       ; ticks sent so far
        key due)
    (unless (<= 1 seed 2147483646)
      (setq seed (1+ (random 2147483646))))
    (send-string-to-terminal "\e[2J\e[H\e[?25l") ; clear, hide the cursor
    (emacstris-start seed)
    (catch 'quit
      (while (not emacstris-over)
        (setq key (emacstris-native-key))
        (cond
         ((memq key '(?q ?Q)) (throw 'quit nil))
         (key (let ((e (emacstris-native-event key)))
                (when (and e (emacstris-event e))
                  (emacstris-draw)))))
        ;; A tick every 100 ms.  After a long stall the clock starts again
        ;; instead of replaying all the missed ticks.
        (setq due (floor (* 10 (- (float-time) start))))
        (when (> (- due ticks) 10)
          (setq start (float-time) ticks 0 due 0))
        (while (and (< ticks due) (not emacstris-over))
          (setq ticks (1+ ticks))
          (when (emacstris-event 0)
            (emacstris-draw))))
      ;; Game over: the last frame stays up until a key is pressed, because
      ;; Emacs gives the terminal back as it was when it exits.
      (while (not (read-event nil nil 0.1))))))

(let ((inhibit-redisplay t))
  (condition-case nil
      (emacstris-native-play)
    (quit nil))                         ; C-g
  (send-string-to-terminal "\e[?25h\e[m")
  (kill-emacs 0))

;;; emacstris.native.el ends here
