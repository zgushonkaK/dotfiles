(require 'package)
(require 'corfu) ;;for some reason without that have problem: "symbols value as variable is void: corfu-map"
(add-to-list 'package-archives '("melpa" . "https://melpa.org/packages/"))
(add-to-list 'package-archives '("gnu" . "https://elpa.gnu.org/packages/"))
(package-initialize)
(load-theme 'zenburn t)
(global-display-line-numbers-mode 1)
(tool-bar-mode -1)
(scroll-bar-mode 0)
(setq use-company nil) ;;t - for company mode

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

(unless use-company
  (use-package corfu
    :after orderless
    ;; Optional customizations
    :custom
    (corfu-cycle t)                ;; Enable cycling for `corfu-next/previous'
    (corfu-auto t)                 ;; Enable auto completion
    (corfu-separator ?\s)          ;; Orderless field separator
    (corfu-quit-at-boundary nil)   ;; Never quit at completion boundary
    (corfu-quit-no-match nil)      ;; Never quit, even if there is no match
    (corfu-preview-current nil)    ;; Disable current candidate preview
    ;; (corfu-preselect-first nil)    ;; Disable candidate preselection
    ;; (corfu-on-exact-match nil)     ;; Configure handling of exact matches
    ;; (corfu-echo-documentation nil) ;; Disable documentation in the echo area
    (corfu-scroll-margin 5)        ;; Use scroll margin
    ;; Enable Corfu only for certain modes.
    :hook ((prog-mode . corfu-mode)
           (shell-mode . corfu-mode)
           (eshell-mode . corfu-mode))
    ;; Recommended: Enable Corfu globally.
    ;; This is recommended since Dabbrev can be used globally (M-/).
    ;; See also `corfu-excluded-modes'.
    :init
    (global-corfu-mode) ; This does not play well in eshell if you run a repl
    (setq corfu-auto t))
    :config
    (define-key corfu-map (kbd "M-p") #'corfu-popupinfo-scroll-down) ;; corfu-next
    (define-key corfu-map (kbd "M-n") #'corfu-popupinfo-scroll-up))  ;; corfu-previous

(when use-company
  (use-package company
    :ensure t
    :hook ((prog-mode . company-mode))
    :bind (:map company-active-map
                ("<return>" . nil)
                ("RET" . nil)
                ("C-<return>" . company-complete-selection)
                ([tab] . company-complete-selection)
                ("TAB" . company-complete-selection)))
  (use-package company-box
    :ensure t
    :hook (company-mode . company-box-mode)))
