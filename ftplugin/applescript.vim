"Plugin Name: applescript filetype plugin
"Author: mityu
"Last Change: 02-May-2017.

if exists('b:did_ftplugin')
	finish
endif
let b:did_ftplugin=1

let s:cpo_save=&cpo
set cpo&vim

inoremap <buffer> <S-CR> ¬<CR>
inoremap <buffer> \<CR> ¬<CR>

setlocal fo-=t fo+=croql
setlocal commentstring=--%s
setlocal comments=sO:*\ -,mO:*\ \ ,exO:*),s1:(*,mb:*,ex:*),:--

augroup ftplugin-applescript
	au!
augroup END

func! s:formatCode(line1,line2)
	return substitute(shellescape(join(getline(a:line1,a:line2),"\n")),'\\\n',"\n",'g')
endfunc

if executable('osascript')
	com! -range=% -buffer AppleScriptRun call s:runApplescript(<line1>,<line2>)
	au ftplugin-applescript FileType <buffer> if exists(':AppleScriptRun')==2|delc AppleScriptRun|endif

	func! s:runApplescript(line1,line2)
		let l:bufnr_save=bufnr('%')
		let l:output=system('osascript -e ' . s:formatCode(a:line1,a:line2))
		let l:bufname='[AppleScriptRun Output]'
		try
			if bufwinnr('^' . l:bufname . '$')!=-1
				exec bufwinnr('^' . l:bufname . '$') . 'wincmd w'
			else
				exec 'botright split ' . l:bufname
				setlocal buftype=nofile nobuflisted noswapfile ft=AppleScriptRunOutput
			endif
			silent %delete _
			0put =l:output
		finally
			exec bufwinnr(l:bufnr_save) . 'wincmd w'
		endtry
	endfunc
endif

if executable('osacompile')
	com! -buffer -range=% AppleScriptExport call s:exportApplescript(<line1>,<line2>)
	au ftplugin-applescript FileType <buffer> if exists(':AppleScriptExport')==2|delc AppleScriptExport|endif

	func! s:exportApplescript(line1,line2)
		let l:product_name=input('Input export file name (*.scpt=script, *.scptd=script bundle, *.app=application bundle)' . "\n" . '-> ','','dir')
		let l:flag_execute_only=input('Export execute only (Y[es]/N[o]) ')=~'^[yY]'
		let l:flag_stay_open=0
		let l:flag_use_startup_screen=0
		if l:product_name=~'.*\.app$'
			let l:flag_stay_open=input('Stay-open applet (Y[es]/N[o]) ')=~'^[yY]'
			let l:flag_use_startup_screen=input('Use startup screen (Y[es]/N[o]) ')=~'^[yY]'
		endif

		if getftype(l:product_name)!=''
			echo printf('File "%s" exists. overwrite? [y/n]',l:product_name)
			if nr2char(getchar())!=?'y'
				echo 'Canceled export.'
				return
			endif
		endif

		let l:output=system(
				\printf('osacompile -e %s -o %s %s %s %s',
					\s:formatCode(a:line1,a:line2),
					\l:product_name,
					\l:flag_execute_only? '-x': '',
					\l:flag_stay_open? '-s': '',
					\l:flag_use_startup_screen? '-u': ''
				\))

		if empty(l:output) | echo 'Export ' . l:product_name . ' successfully.' | return | endif
		echomsg l:output
		echomsg '[This message can be read by ":messages"]'
	endfunc
endif

let &cpo=s:cpo_save
unlet s:cpo_save

" vim: foldmethod=marker
