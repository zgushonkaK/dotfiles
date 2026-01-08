(require 'package)
;; (require 'corfu) ;;for some reason without that have problem: "symbols value as variable is void: corfu-map"
(add-to-list 'package-archives '("melpa" . "https://melpa.org/packages/"))
(add-to-list 'package-archives '("gnu" . "https://elpa.gnu.org/packages/"))
(package-initialize)
(load-theme 'zenburn t)
(global-display-line-numbers-mode 1)
(tool-bar-mode -1)
(scroll-bar-mode 0)
(setq dired-kill-when-opening t)

;; Добавить недостающие пути к PATH
(setenv "PATH" (concat 
                "/home/vsveolod-fedora/.local/bin" ":"
                "/usr/local/go/bin" ":"
                "/home/vsveolod-fedora/go/bin" ":"
                (getenv "PATH")))

;;; Environment - добавление каталогов в exec-path
(dolist (dir '("/usr/local/bin"
               "~/.local/bin"
               "~/.cargo/bin"
               "~/.ghcup/bin"
               "~/.pyenv/bin"
               "~/go/bin"
               "~/.nodenv/shims"
	       "/home/vsveolod-fedora/.local/bin"
	       "/usr/local/go/bin"
	       "/home/vsveolod-fedora/go/bin"))
  (let ((full-path (expand-file-name dir)))
    (when (file-directory-p full-path)
      (add-to-list 'exec-path full-path))))

(use-package eglot
  :ensure t
  :defer t
  :hook ((python-mode . eglot-ensure)
         (go-mode . eglot-ensure)
	 (c-mode . eglot-ensure)
	 (c++-mode . eglot-ensure))
  :config
  (add-to-list 'eglot-server-programs
               `(python-mode
                 . ,(eglot-alternatives '(("pyright-langserver" "--stdio")
                                          "jedi-language-server"
                                          "/home/vsveolod-fedora/.local/bin/pylsp")))) ;;think how emacs could see python env (this already in path but uhmm)
  (add-to-list 'eglot-server-programs
	       '(c-mode . ("clangd" "--background-index")))
  (add-to-list 'eglot-server-programs
	       '(c++-mode . ("clangd" "--background-index")))
  (add-to-list 'eglot-server-programs
               '(go-mode . ("gopls"))))

(use-package markdown-mode
  :ensure t
  :mode (("\\.md\\'" . markdown-mode)
         ("\\.markdown\\'" . markdown-mode)
         ("README\\.md\\'" . markdown-mode))
  :hook ((markdown-mode . visual-line-mode)
         (markdown-mode . flyspell-mode))
  :custom
  (markdown-command "pandoc")
  (markdown-fontify-code-blocks-natively t)
  (markdown-hide-urls t)
  :bind (:map markdown-mode-map
         ("C-c C-c p" . markdown-preview-mode)
         ("C-c C-c e" . markdown-export)))

;; Предпросмотр в реальном времени
(use-package markdown-preview-mode
  :ensure t
  :commands markdown-preview-mode)

;; Таблицы содержания
(use-package markdown-toc
  :ensure t
  :commands markdown-toc-generate-toc)

;;(use-package pyenv-mode
;;  :ensure t
;;  :init
;;  (add-to-list 'exec-path "~/.pyenv/shims")
;;  (setenv "WORKON_HOME" "~/.pyenv/versions/")
;;  :config
;;  (pyenv-mode))

(use-package pyconf
  :ensure t)

(defalias 'workon 'pyvenv-workon)

(use-package python-black
  :ensure t
  :demand t
  :after python
  :hook ((python-mode . python-black-on-save-mode)))

(use-package cc-mode
  :ensure nil ; уже встроен
  :hook ((c-mode . (lambda ()
                     (setq c-basic-offset 4
                           tab-width 4
                           indent-tabs-mode nil)))
         (c++-mode . (lambda ()
                       (setq c-basic-offset 4
                             tab-width 4
                             indent-tabs-mode nil)))))

(use-package cmake-mode
  :ensure t
  :mode (("CMakeLists\\.txt\\'" . cmake-mode)
         ("\\.cmake\\'" . cmake-mode)))

(defun go-run-this-file ()
  "go run"
  (interactive)
  (compile (format "go run %s" (buffer-file-name))))

(defun go-compile ()
  "go compile"
  (interactive)
  (compile "go build -v && go test -v && go vet"))

(defun go-compile-debug ()
  "go compile with necessary flags to debug with gdb"
  (interactive)
  (compile "go build -gcflags=all=\"-N -l\""))

(use-package go-mode
  :ensure t
  :bind (("C-c C-k" . go-run-this-file)
         ("C-c C-c" . go-compile)
         ("C-c C-d" . go-compile-debug))
  :hook ((before-save . eglot-format-buffer)))


(use-package project-tab-groups
  :ensure
  :config
  (project-tab-groups-mode 1))

;; (global-set-key (kbd "C-<next>") 'tab-next)
;; (global-set-key (kbd "C-<prior>") 'tab-previous)

;; (use-package consult
;;     :ensure t
;;     :demand t
;;     :bind (("C-s" . consult-line)
;;            ("C-M-l" . consult-imenu)
;;            ("C-x b" . consult-buffer)
;;            ("C-x C-b" . consult-bookmark)
;;            ("C-M-s" . consult-ripgrep)
;;            :map minibuffer-local-map
;;            ("C-r" . consult-history)))

(use-package corfu
  :ensure t
  ;; Optional customizations
  :hook
  (prog-mode . (lambda () (setq-local corfu-auto t)))
  :init
  (global-corfu-mode))

(setq corfu-auto t
      corfu-auto-delay 0.2)

(use-package centaur-tabs
  :ensure t
  :demand
  :config
  (centaur-tabs-mode t)
  :bind
  ("C-<prior>" . centaur-tabs-backward)
  ("C-<next>" . centaur-tabs-forward))

(setq centaur-tabs-style "bar")
(setq centaur-tabs-height 32)
(setq centaur-tabs-icon-type 'nerd-icons)
(setq centaur-tabs-set-icons t)
(setq centaur-tabs-set-bar 'over)
(setq centaur-tabs-set-modified-marker t)

(setq neo-theme (if (display-graphic-p) 'nerd-icons))

(when (fboundp 'windmove-default-keybindings)
  (windmove-default-keybindings))

;; Move backup files to ~/.emacs.d/backups
(setq backup-directory-alist
      `(("." . ,(expand-file-name "~/.emacs.d/backups"))))

;; Create backup directory if it doesn't exist
(unless (file-exists-p (expand-file-name "~/.emacs.d/backups"))
  (make-directory (expand-file-name "~/.emacs.d/backups") t))

;; Move auto-save files to ~/.emacs.d/auto-save/
(setq auto-save-file-name-transforms
      `((".*" ,(expand-file-name "~/.emacs.d/auto-save/") t)))

;; Create auto-save directory if it doesn't exist
(unless (file-exists-p (expand-file-name "~/.emacs.d/auto-save/"))
  (make-directory (expand-file-name "~/.emacs.d/auto-save/") t))

;; Auto-save every 300 keystrokes and 30 seconds
(setq auto-save-interval 300)
(setq auto-save-timeout 30)

;; Auto-save on focus lost
(add-hook 'focus-out-hook 'do-auto-save)

(use-package deadgrep
  :ensure t
  :bind ("C-c s" . deadgrep))
