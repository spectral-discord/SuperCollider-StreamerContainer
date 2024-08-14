;;;;;;;;;;;;;;;;;; probably don't edit this section

(eval-when-compile
  (add-to-list 'load-path "/root/emacs/use-package")
  (require 'use-package))

(require 'package)
(add-to-list 'package-archives '("melpa" . "https://melpa.org/packages/") t)
(package-initialize)

;; SCEL
(add-to-list 'load-path "/usr/local/share/emacs/site-lisp/SuperCollider/")
(require 'sclang)

;; Tidal
(use-package haskell-mode
  :ensure t)
(use-package tidal
  :ensure t)

;; SC help files
(use-package w3m
  :ensure t)

(setq browse-url-browser-function 'w3m-browse-url)
(autoload 'w3m-browse-url "w3m" "Ask a WWW browser to show a URL." t)

(eval-after-load "w3m"
  '(progn
  (define-key w3m-mode-map [left] 'backward-char)
  (define-key w3m-mode-map [right] 'forward-char)
  (define-key w3m-mode-map [up] 'previous-line)
  (define-key w3m-mode-map [down] 'next-line)))

;; start stream on startup
(defun start-sc-stream ()
  (call-process-shell-command "cp -R /config/sclang-includes /usr/local/share/SuperCollider/Extensions")
  (call-process-shell-command "/config/stream/start_stream.sh &"))
(add-hook 'emacs-startup-hook #'start-sc-stream)

;; kill stream services on exit
(defun kill-sc-stream ()
  (call-process-shell-command "/config/stream/kill_stream.sh &"))
(add-hook 'kill-emacs-hook #'kill-sc-stream)

;; change the default sclang UDP port
;; prevents conflict with SuperDirt
(setq sclang-udp-port 5500)

;; initialize windows and start modes
(defun tidal-start ()
  (get-buffer-create "tidal")
  (switch-to-buffer "tidal")
  (tidal-mode)
  (tidal-start-haskell)
  (shrink-window (/ (window-height) 2))
  (other-window -1)
  (insert "-- Tidal Cycles workspace\n\n"))

;; func for splitting the window and running both sclang & tidal modes
(defun open-both-sclang-tidal ()
  (split-window-right)
  (split-window-below)
  (other-window 2)
  (split-window-below)
  (tidal-start)
  (other-window 2)
  (sclang-start)
  (enlarge-window (/ (window-height (next-window)) 2)))

;; func for opening the right mode based on the MODE env variable
(defun start-scsc ()
  (if (string= (getenv "MODE") "both")
    (open-both-sclang-tidal)
    (if (string= (getenv "MODE") "tidal")
      (tidal-start)
      (progn (sclang-start)
        (enlarge-window (/ (window-height (next-window)) 2))))))


;;;;;;;;;;;;;;;;;; you can edit this stuff

;; hide the menu bar
(menu-bar-mode -1)

;; theme
(add-to-list 'custom-theme-load-path "/config")
(load-theme 'catppuccin t)
(setq catppuccin-flavor 'mocha)
(catppuccin-reload)

;; windmove
(when (fboundp 'windmove-default-keybindings)
  (windmove-default-keybindings))