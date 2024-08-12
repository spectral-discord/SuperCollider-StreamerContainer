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

(defun kill-sc-stream ()
   (call-process-shell-command "/config/stream/kill_stream.sh &"))
(add-hook 'kill-emacs-hook #'kill-sc-stream)

;; change the default sclang UDP port
;; prevents conflict with SuperDirt
(setq sclang-udp-port 5500)

;; func for splitting the window and running both sclang & tidal modes
(defun open-both-sclang-tidal ()
   (get-buffer-create "sclang")
   (get-buffer-create "tidal")
   (split-window-right)
   (split-window-below)
   (other-window 2)
   (switch-to-buffer "tidal")
   (split-window-below)
   (tidal-mode)
   (tidal-start-haskell)
   (other-window 1)
   (switch-to-buffer "sclang")
   (sclang-start))


;;;;;;;;;;;;;;;;;; you can edit this stuff

;; hide toolbar
(menu-bar-mode -1)

;; theme
(add-to-list 'custom-theme-load-path "/config")
(load-theme 'catppuccin t)
(setq catppuccin-flavor 'mocha)
(catppuccin-reload)
