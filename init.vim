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
    function! MoveCursor(direction) abort
        if(reg_recording() == '' && reg_executing() == '')
            return 'g'.a:direction
        else
            return a:direction
        endif
    endfunction
    nmap <expr> j MoveCursor('j')
    nmap <expr> k MoveCursor('k')

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
<<<<<<< HEAD
    au VimEnter,VimResume * set guicursor=n-v-c:block,i-ci-ve:ver25,r-cr:hor20,o:hor50
			    \,a:blinkwait700-blinkoff400-blinkon250-Cursor/lCursor
			    \,sm:block-blinkwait175-blinkoff150-blinkon175

    au VimLeave,VimSuspend * set guicursor=a:hor20-blinkon0
=======
    map - $
>>>>>>> 3624d7a (Small fixes.)
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

"  vmap <D-d> "zy:silent! !open "https://www.google.com/search?q="$(php -r "echo rawurlencode('<C-R>z');")<CR>
"  vmap <D-d> "zy:silent! !open "https://www.google.com/search?q="$(php -r "echo rawurlencode('@z');")<CR>
vmap <D-d> "zy:call <SID>google()<CR>
nmap <D-d> :silent !open "dict://<cword>"<CR>
function s:google()
    let word = @z
    let word = system('/usr/local/bin/php -r "echo rawurlencode(' . "'" . word . "'" . ');"')
    exec 'silent! !open "https://www.google.com/search?q=' . shellescape(word, 1) . '"'
endfunction

" https://github.com/ybian/smartim
let g:smartim_default = 'com.apple.keylayout.ABC'
" let g:smartim_disable = 1
" unlet g:smartim_disable
" autocmd InsertLeave * :silent !/usr/local/bin/im-select com.apple.keylayout.ABC
" autocmd UIEnter * set noimd

call plug#begin()
" https://github.com/junegunn/vim-plug
" The default plugin directory will be as follows:
"   - Vim (Linux/macOS): '~/.vim/plugged'
"   - Vim (Windows): '~/vimfiles/plugged'
"   - Neovim (Linux/macOS/Windows): stdpath('data') . '/plugged'
" You can specify a custom plugin directory by passing it as the argument
"   - e.g. `call plug#begin('~/.vim/plugged')`
"   - Avoid using standard Vim directory names like 'plugin'

" Make sure you use single quotes

"  https://github.com/vscode-neovim/vscode-neovim/wiki/Plugins#vim-easymotion
"  https://www.v2ex.com/t/856921
if exists('g:vscode')
	Plug 'asvetliakov/vim-easymotion', {'rtp': 'vscode'}
else
	Plug 'easymotion/vim-easymotion', {'rtp': 'nvim'}
endif
Plug 'zzhirong/vim-easymotion-zh'

" Initialize plugin system
" - Automatically executes `filetype plugin indent on` and `syntax enable`.
call plug#end()
" You can revert the settings after the call like so:
"   filetype indent off   " Disable file-type-specific indentation
"   syntax off            " Disable syntax highlighting

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
