;;; $DOOMDIR/config.el -*- lexical-binding: t; -*-

;; Place your private configuration here! Remember, you do not need to run 'doom
;; sync' after modifying this file!


;; Some functionality uses this to identify you, e.g. GPG configuration, email
;; clients, file templates and snippets.
(setq user-full-name "Ken Wu"
      user-mail-address "kenbwu@amazon.com")

;; Doom exposes five (optional) variables for controlling fonts in Doom. Here
;; are the three important ones:
;;
;; + `doom-font'
;; + `doom-variable-pitch-font'
;; + `doom-big-font' -- used for `doom-big-font-mode'; use this for
;;   presentations or streaming.
;;
;; They all accept either a font-spec, font string ("Input Mono-12"), or xlfd
;; font string. You generally only need these two:
;; (setq doom-font (font-spec :family "monospace" :size 12 :weight 'semi-light)
;;       doom-variable-pitch-font (font-spec :family "sans" :size 13))
(setq doom-font (font-spec :family "monospace" :size 16))
;; There are two ways to load a theme. Both assume the theme is installed and
;; available. You can either set `doom-theme' or manually load a theme with the
;; `load-theme' function. This is the default:
(setq doom-theme 'doom-solarized-dark-high-contrast)

;; If you use `org' and don't want your org files in the default location below,
;; change `org-directory'. It must be set before org loads!
(setq org-directory "~/org/")

;; This determines the style of line numbers in effect. If set to `nil', line
;; numbers are disabled. For relative line numbers, set this to `relative'.
(setq display-line-numbers-type t)

(setq doom-unreal-buffer-functions '(minibufferp))

;; Here are some additional functions/macros that could help you configure Doom:
;;
;; - `load!' for loading external *.el files relative to this one
;; - `use-package!' for configuring packages
;; - `after!' for running code after a package has loaded
;; - `add-load-path!' for adding directories to the `load-path', relative to
;;   this file. Emacs searches the `load-path' when you load packages with
;;   `require' or `use-package'.
;; - `map!' for binding new keys
;;
;; To get information about any of these functions/macros, move the cursor over
;; the highlighted symbol at press 'K' (non-evil users must press 'C-c c k').
;; This will open documentation for it, including demos of how they are used.
;;
;; You can also try 'gd' (or 'C-c c d') to jump to their definition and see how
;; they are implemented.
(setq doom-unreal-buffer-functions '(minibufferp))

(after! vterm
  (setq vterm-max-scrollback 100000))

(map! :after vertico
      :leader "r" #'vertico-repeat)
(map! :leader "g" #'goto-line)
(map! :after project
      :prefix "C-x" "p" #'+popup/other)

(defun file-notify-rm-all-watches ()
  "Remove all existing file notification watches from Emacs."
  (interactive)
  (maphash
   (lambda (key _value)
     (file-notify-rm-watch key))
   file-notify-descriptors))

(use-package! tree-sitter
  :config (global-tree-sitter-mode t))

(use-package! tree-sitter-langs
  :config (add-hook 'tree-sitter-after-on-hook #'tree-sitter-hl-mode))

;; for key combinations not working in terminals
(defun abaw/setup-keys-for-terminal ()
  (dolist (key (list "C-="))
    (define-key input-decode-map (concat "\e[emacs-" key) (kbd key))))

(use-package! faces
  :config (add-hook 'tty-setup-hook #'abaw/setup-keys-for-terminal))

(after! doom-modeline
  (setq doom-modeline-icon nil)
  ;; alternative:
  ;; (advice-remove #'doom-modeline-propertize-icon #'+modeline-disable-icon-in-daemon-a)
  )

;; This use `git ls-files' for listing project files, which contains no
;; untracked files. It's a sane default for me and a lot faster.
(after! projectile
  (undefadvice! doom--only-use-generic-command-a (fn vcs))
  (setq projectile-git-command "git ls-files -z --exclude-standard"))
