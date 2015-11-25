Python Abhängigkeiten:
======================

pip install rope
pip install flake8
pip install importmagic
pip install autopep8
pip install yapf

* scratch * -> M-x eval-buffer
(require 'package)
(add-to-list 'package-archives
             '("elpy" . "https://jorgenschaefer.github.io/packages/"))
(add-to-list 'package-archives
              '("melpa" . "http://melpa.milkbox.net/packages/") t)
emacs:
M-x package-refresh-contents
M-x package-install RET elpy RET
M-x package-install RET js2-mode RET
M-x package-install RET ac-js2 RET
M-x package-install RET auto-complete RET
M-x package-install RET iedit RET

.emacs.d/ < befüllen
