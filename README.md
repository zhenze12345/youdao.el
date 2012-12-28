youdao.el
=========

一个使用有道API来翻译Emacs上文本的插件

使用前需要到

http://http://fanyi.youdao.com/openapi?path=data-mode

去申请一个key


该插件依赖于pos-tip.el

http://www.emacswiki.org/emacs/download/pos-tip.el

请事先下载


安装方法

~/.emacs:

(require 'youdao)

(setf youdao-key-from "xxxxxx") ;; 有道提供的key-from

(setf youdao-key "xxxxxx") ;; 有道提供的API key

(global-set-key (kbd "C-c C-v") 'youdao-translate-word)


使用方法

不选择文本，翻译光标所在的当前单词

选择文本，翻译选择的句子


有道有时候会乱码，重试一次就正常了
