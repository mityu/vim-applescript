"Plugin Name: applescript filetype plugin
"Author: mityu
"Last Change: 23-Oct-2019.

scriptencoding utf-8

if exists('b:did_ftplugin')
	finish
endif
let b:did_ftplugin=1

let s:cpo_save=&cpo
set cpo&vim

if !exists('*ApplescriptFtpluginUndo')
	func ApplescriptFtpluginUndo()
		setlocal fo< commentstring< comments<
		silent! iunmap <buffer> <Plug>(applescript-line-connecting-CR)
	endfunc
endif
let b:undo_ftplugin = 'call ApplescriptFtpluginUndo()'

inoremap <buffer> <Plug>(applescript-line-connecting-CR) ¬<CR>

setlocal fo-=t fo+=croql
setlocal commentstring=--%s
setlocal comments=sO:*\ -,mxO:*\ \ ,exO:*),s1:(*,mb:*,ex:*),:--

augroup ftplugin-applescript
	au!
augroup END

let s:default_config = {}
let s:default_config.run = {
			\'output': {
			\	'buffer_name': '[AppleScriptRun Output]',
			\	'open_command': 'botright split'
			\	}
			\}
func! s:bufnr(expr) abort "{{{
	if type(a:expr) == type('')
		return bufnr(escape(a:expr,'\/[]^$*.?'))
	else
		return a:expr
	endif
endfunc "}}}
func! s:bufexists(expr) abort "{{{
	return s:bufnr(a:expr) != -1
endfunc "}}}
func! s:bufexists_on_this_tab(expr) abort "{{{
	return s:bufexists(a:expr) && bufwinnr(s:bufnr(a:expr)) != -1
endfunc "}}}
func! s:goto_win(expr) abort "{{{
	execute bufwinnr(s:bufnr(a:expr)) 'wincmd w'
endfunc "}}}
func! s:tempfile() abort "{{{
	return tempname() . '.applescript'
endfunc "}}}

if executable('osascript')
	com! -range=% -buffer AppleScriptRun call s:runAppleScript(<line1>,<line2>)
	au ftplugin-applescript FileType <buffer> if exists(':AppleScriptRun')==2|delc AppleScriptRun|endif

	func! s:runAppleScript(start,end) abort "{{{
		if exists('g:applescript_config') && has_key(g:applescript_config,'run')
			let config = extend(deepcopy(g:applescript_config.run),s:default_config.run,'keep')
		else
			let config = deepcopy(s:default_config.run)
		endif
		let current_bufnr = bufnr('%')
		let script = getline(a:start,a:end)
		let tempfile = s:tempfile()
		let cmd = printf('osascript %s',shellescape(tempfile))

		try
			call writefile(script,tempfile)

			if s:bufexists_on_this_tab(config.output.buffer_name)
				call s:goto_win(config.output.buffer_name)
			else
				execute config.output.open_command config.output.buffer_name
				setlocal buftype=nofile nobuflisted noswapfile noundofile ft=AppleScriptRunOutput
			endif

			let output = system(cmd)
			silent %delete _
			0put =output
		catch
			echohl Error
			echomsg v:exception
			echohl None
			return
		finally
			call delete(tempfile)
			call s:goto_win(current_bufnr)
		endtry
	endfunc "}}}
endif

if executable('osacompile')
	com! -buffer -range=% AppleScriptExport call s:exportAppleScript(<line1>,<line2>)
	au ftplugin-applescript FileType <buffer> if exists(':AppleScriptExport')==2|delc AppleScriptExport|endif

	func! s:ask(msg) abort "{{{
		return input(a:msg . ' (Y[es]/N[o]) ') =~? 'y'
	endfunc "}}}
	func! s:exportAppleScript(start,end) abort "{{{
		let script = getline(a:start,a:end)
		let tempfile = s:tempfile()
		let product_name = ''
		let config = {}
		let config.execute_only = {'flag': 0, 'argv': '-x'}
		let config.stay_open = {'flag': 0, 'argv': '-s'}
		let config.use_startup_screen = {'flag': 0, 'argv': '-u'}

		while product_name ==# ''
			let product_name = input(
						\"Input export file name (*.scpt=script, *.scptd=script bundle, *.app=application bundle)\n>> ",
						\'','dir')
		endwhile
		let config.execute_only.flag = s:ask('Export execute only')
		if product_name =~? '.\+\.app$'
			let config.stay_open.flag = s:ask('Stay-open applet')
			let config.use_startup_screen.flag = s:ask('Use startup screen')
		endif

		if getftype(product_name) !=# ''
			if !s:ask(printf('File "%s" exists. Overwrite?',product_name))
				echo 'Canceled.'
				return
			endif
		endif

		let flags = join(values(map(filter(config,'v:val.flag'),'v:val.argv')),' ')
		let cmd = printf('osacompile -o %s %s %s',product_name,flags,tempfile)

		try
			call writefile(script,tempfile)
			let output = system(cmd)

			if output ==# ''
				echo printf('Export "%s" successfully.',product_name)
			else
				echohl Error
				echomsg '[command]' cmd
				echomsg output
				echohl None
				echomsg '[You can read these message again by executing ":messages"]'
			endif
		catch
			echohl Error
			echomsg v:exception
			echohl None
		finally
			call delete(tempfile)
		endtry
	endfunc "}}}
endif

let &cpo=s:cpo_save
unlet s:cpo_save

" vim: foldmethod=marker
