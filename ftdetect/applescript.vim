"Plugin Name: AppleScript
"Author: mityu
"Last Change: 04-Mar-2017.

let s:cpo_save=&cpo
set cpo&vim

au BufNewFile,BufRead *.scpt setf applescript
au BufNewFile,BufRead *.applescript setf applescript

let &cpo=s:cpo_save
unlet s:cpo_save

" vim: foldmethod=marker
