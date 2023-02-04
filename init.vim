if exists('g:vscode')
    let g:nvimapp = 1
    " https://github.com/vscode-neovim/vscode-neovim/issues/58
    nnoremap zM :call VSCodeNotify('editor.foldAll')<CR>
    nnoremap zR :call VSCodeNotify('editor.unfoldAll')<CR>
    nnoremap zc :call VSCodeNotify('editor.fold')<CR>
    nnoremap zC :call VSCodeNotify('editor.foldRecursively')<CR>
    nnoremap zo :call VSCodeNotify('editor.unfold')<CR>
    nnoremap zO :call VSCodeNotify('editor.unfoldRecursively')<CR>
    nnoremap za :call VSCodeNotify('editor.toggleFold')<CR>
    nnoremap <Space> :call VSCodeNotify('editor.toggleFold')<CR>
    nnoremap zj :call VSCodeNotify('editor.gotoNextFold')<CR>
    nnoremap zk :call VSCodeNotify('editor.gotoPreviousFold')<CR>
    nnoremap zK :call VSCodeNotify('editor.gotoParentFold')<CR>

    " https://github.com/vscode-neovim/vscode-neovim/issues/259
    "  function! MoveCursor(direction) abort
    "      if(reg_recording() == '' && reg_executing() == '')
    "          return 'g'.a:direction
    "      else
    "          return a:direction
    "      endif
    "  endfunction
    "  nmap <expr> j MoveCursor('j')
    "  nmap <expr> k MoveCursor('k')
    nmap j gj
    nmap k gk
    "  nmap j :call VSCodeCall('cursorMove', { 'to': 'down', 'by': 'wrappedLine', 'value': v:count ? v:count : 1 })<CR>
    "  nmap k :call VSCodeCall('cursorMove', { 'to': 'up', 'by': 'wrappedLine', 'value': v:count ? v:count : 1 })<CR>

    " FIXME
    vnoremap == <Cmd>call VSCodeNotify('editor.action.reindentselectedlines')<CR>

    " TODO
    let s:maximized_flag = 1
    function! ToggleMaximizeEditor()
        if (s:maximized_flag)
            call VSCodeNotify('workbench.action.minimizeOtherEditors')
            let s:maximized_flag = !s:maximized_flag
        else
            call VSCodeNotify('workbench.action.evenEditorWidths')
            let s:maximized_flag = !s:maximized_flag
        endif
    endfunction
    map <C-CR> :call ToggleMaximizeEditor()<CR>

    let s:switch_recently_used_editor = 1
    function SwitchRecentlyUsedEditor() abort
        if (s:switch_recently_used_editor)
            call VSCodeNotify('workbench.action.openPreviousRecentlyUsedEditor')
            let s:switch_recently_used_editor = !s:switch_recently_used_editor
        else
            call VSCodeNotify('workbench.action.openNextRecentlyUsedEditor')
            let s:switch_recently_used_editor = !s:switch_recently_used_editor
        endif
    endfunction
    nnoremap <Backspace> <Cmd>call SwitchRecentlyUsedEditor()<CR>
    nnoremap $ <Cmd>call VSCodeNotify('workbench.action.focusOtherSideEditor')<CR>
    map - <End>
else
    let g:nvimapp = 0
    nnoremap j gj
    nnoremap k gk
    nmap <Backspace> <C-W>p
    set number

    " cursor
    " https://github.com/neovim/neovim/wiki/FAQ#cursor-style-isnt-restored-after-exiting-or-suspending-and-resuming-nvim
    au VimEnter,VimResume * set guicursor=n-v-c:block,i-ci-ve:ver25,r-cr:hor20,o:hor50
			    \,a:blinkwait700-blinkoff400-blinkon250-Cursor/lCursor
			    \,sm:block-blinkwait175-blinkoff150-blinkon175

    au VimLeave,VimSuspend * set guicursor=a:hor20-blinkon0
    map - $
endif

set ignorecase smartcase

let mapleader = ","

map <C-j> <C-f>
map <C-k> <C-b>

vmap <D-c> "+y
map <D-v> x"+gP
cmap <D-v> <C-R>+
imap <D-v> <C-R><C-O>+

nmap <Leader>ns :let @/=""<CR>
nmap <Leader>nh :set nohlsearch<CR>
nmap <Leader>h :set hlsearch<CR>
nmap <Leader>s :split<CR>
nmap <Leader>v :vsplit<CR>
nmap <Leader>c <C-W>c
nmap ` <C-W>w

vmap <D-d> "zy:call <SID>google()<CR>
nmap <D-d> :silent !open "dict://<cword>"<CR>
function s:google()
    let word = @z
    let word = system('/usr/local/bin/php -r "echo rawurlencode(' . "'" . word . "'" . ');"')
    exec 'silent! !open "https://www.google.com/search?q=' . shellescape(word, 1) . '"'
endfunction

nmap <Leader>fn :e /Users/xell/Library/Mobile Documents/iCloud~md~obsidian/Documents/Notes/QuickNote.md<CR>

" https://github.com/junegunn/vim-plug
call plug#begin()

" easymotion plugins {{{
if exists('g:vscode')
	" Plug 'asvetliakov/vim-easymotion', {'rtp': 'vscode'}
    Plug 'asvetliakov/vim-easymotion', {'as': 'vsc-easymotion'}
else
    "  https://github.com/vscode-neovim/vscode-neovim/wiki/Plugins#vim-easymotion
    " Plug 'easymotion/vim-easymotion', {'rtp': 'nvim'}
    Plug 'easymotion/vim-easymotion'
endif

" }}}

" https://www.v2ex.com/t/856921
Plug 'zzhirong/vim-easymotion-zh'

" https://github.com/ybian/smartim
Plug 'ybian/smartim'

call plug#end()

let g:smartim_default = 'com.apple.keylayout.ABC'
" let g:smartim_disable = 1
" unlet g:smartim_disable
" autocmd InsertLeave * :silent !/usr/local/bin/im-select com.apple.keylayout.ABC
" autocmd UIEnter * set noimd

let g:EasyMotion_leader_key=";"
let g:EasyMotion_skipfoldedline=0
let g:EasyMotion_space_jump_first=1
let g:EasyMotion_move_highlight = 0
let g:EasyMotion_use_migemo = 1
"  noremap s <Plug>(easymotion-overwin-f2)
" `s` 和 surround 冲突, 比如 ds
"  onoremap z <Plug>(easymotion-f2)
noremap f <Plug>(easymotion-fl)
noremap F <Plug>(easymotion-Fl)
noremap t <Plug>(easymotion-tl)
noremap T <Plug>(easymotion-Tl)
noremap ;. <Plug>(easymotion-repeat)
noremap ;l <Plug>(easymotion-next)
noremap ;h <Plug>(easymotion-prev)
noremap <Leader>/ <Plug>(easymotion-sn)

command! -range=% Num :call NumberOfChars()
function! NumberOfChars() range "{{{
	"count double-byte characters
	redir => numChs
	"silent! execute a:firstline.",".a:lastline."s/[^\\x00-\\xff]/&/gn"
	silent! execute "'<,'>s/[^\\x00-\\xff]/&/gn"
	redir END
	if match(numChs,"E486") > 0
		let numC = 0
	else
		let numC = strpart(numChs, 0, stridx(numChs," "))
	endif

	"count english words
	redir => numEng
	silent! execute "'<,'>s/\\<\\(\\w\\|-\\|'\\)\\+\\>/&/gn"
	redir END
	if match(numEng,"E486") > 0
		let numE = 0
	else
		let numE = strpart(numEng, 0, stridx(numEng," "))
	endif

	"echo to vim
	echo ""
	echo numC . " 个中文字符"
	echo numE . " 个英文词语"
endfunction "}}}
