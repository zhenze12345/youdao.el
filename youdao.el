;;; youdao.el ---

;; Copyright (C) 2012 Free Software Foundation, Inc.
;;
;; Author:  zhenzegu@gmail.com
;; Maintainer:  zhenzegu@gmail.com
;; Created: 27 Dec 2012
;; Version: 0.01
;; Keywords 

;; This program is free software; you can redistribute it and/or modify
;; it under the terms of the GNU General Public License as published by
;; the Free Software Foundation; either version 2, or (at your option)
;; any later version.
;;
;; This program is distributed in the hope that it will be usefuln,
;; but WITHOUT ANY WARRANTY; without even the implied warranty of
;; MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
;; GNU General Public License for more details.
;;
;; You should have received a copy of the GNU General Public License
;; along with this program; if not, write to the Free Software
;; Foundation, Inc., 675 Mass Ave, Cambridge, MA 02139, USA.

;;; Commentary:

;; 一个使用有道API来翻译Emacs上文本的插件

;; 使用前需要到
;; http://http://fanyi.youdao.com/openapi?path=data-mode
;; 去申请一个key

;; 该插件依赖于pos-tip.el
;; http://www.emacswiki.org/emacs/download/pos-tip.el
;; 请事先下载

;; 安装方法
;; ~/.emacs:
;; (require 'youdao)
;; (setf youdao-key-from "xxxxxx") ;; 有道提供的key-from
;; (setf youdao-key "xxxxxx") ;; 有道提供的API key
;; (global-set-key (kbd "C-c C-v") 'youdao-translate-word)

;; 使用方法
;; 不选择文本，翻译光标所在的当前单词
;; 选择文本，翻译选择的句子

;; 有道有时候会乱码，重试一次就正常了

;;; Code:
(eval-when-compile
  (require 'cl)
  (require 'pos-tip))

(defvar youdao-key-from "")

(defvar youdao-key "")

(defvar youdao-doc-type "json")

(defvar youdao-host "fanyi.youdao.com")

(defvar youdao-buffer-name "*youdao*")

(defvar youdao-process-name "youdao")

(defun youdao-get-current-word ()
  "Get the word to translate."
  (save-excursion
    (when (not mark-active)
      (forward-word)
      (backward-word)
      (mark-word))
    (buffer-substring
     (region-beginning)
     (region-end))))

(defun youdao-get-request ()
  "Concat youdao API url."
  (format "GET /openapi.do?keyfrom=%s&key=%s&type=data&doctype=%s&version=1.1&q=%s HTTP/1.1\r\nHost: %s\r\n\r\n"
          youdao-key-from
          youdao-key
          youdao-doc-type
          (url-hexify-string (youdao-get-current-word))
          youdao-host))

(defun youdao-sentinel (proc msg)
  nil)

(defun youdao-cleanup ()
  (let ((proc (get-process youdao-process-name))
        (buffer (get-buffer youdao-buffer-name)))
    (if proc
        (delete-process proc))
    (if buffer
        (kill-buffer buffer))))

(defun youdao-show-tips (msg)
  (when (and (string-match "HTTP/1.1 200 OK" msg)
             (string-match "\"errorCode\":\\([0-9.-]+\\)" msg)
             (string= (substring msg
                                 (match-beginning 1)
                                 (match-end 1))
                      "0"))
    (cond ((string-match "\"explains\":\\[\\(\\(\"\\([^\\{}]\\|\\\"\\)*\",\\)*\"\\([^\\{}]\\|\\\"\\)*\"\\)\\]" msg)
           (let ((result (reduce
                          `(lambda (str1 str2)
                             (concat str1 "\n" str2))
                          (mapcar
                           `(lambda (str)
                              (replace-regexp-in-string "\"" "" str))
                           (split-string
                            (substring msg
                                       (match-beginning 1)
                                       (match-end 1))
                            ",")))))
             (if result
                 (pos-tip-show result))))
          ((string-match "\"translation\":\\[\"\\(\\([^\\{}]\\|\\\"\\)*\\)\"\\]" msg)
           (pos-tip-show (substring msg
                                    (match-beginning 1)
                                    (match-end 1)))))))

(defun youdao-filter (proc msg)
  (set-buffer (get-buffer "*scratch*"))
  (erase-buffer)
  (insert msg)
  (youdao-show-tips msg)
  (youdao-cleanup))

(defun youdao-translate-word ()
  "Translate word from fanyi.youdao.com"
  (interactive)
  (let ((proc (make-network-process
               :name youdao-process-name
               :buffer youdao-buffer-name
               :family 'ipv4
               :host youdao-host
               :service 80
               :sentinel 'youdao-sentinel
               :filter 'youdao-filter)))
    (when proc
      (process-send-string proc (youdao-get-request)))))

(provide 'youdao)
;;; youdao.el ends here
