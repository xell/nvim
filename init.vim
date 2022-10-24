if exists('g:vscode')
    let g:nvimapp = 1
    " https://github.com/vscode-neovim/vscode-neovim/issues/259
    " nmap j gj
    " nmap k gk
    " https://github.com/vscode-neovim/vscode-neovim/issues/58
    nmap zM :call VSCodeNotify('editor.foldAll')<CR>
    nmap zR :call VSCodeNotify('editor.unfoldAll')<CR>
    nmap zc :call VSCodeNotify('editor.fold')<CR>
    nmap zC :call VSCodeNotify('editor.foldRecursively')<CR>
    nmap zo :call VSCodeNotify('editor.unfold')<CR>
    nmap zO :call VSCodeNotify('editor.unfoldRecursively')<CR>
    nmap za :call VSCodeNotify('editor.toggleFold')<CR>
    nmap <Space> :call VSCodeNotify('editor.toggleFold')<CR>
    nmap zj :call VSCodeNotify('editor.gotoNextFold')<CR>
    nmap zk :call VSCodeNotify('editor.gotoPreviousFold')<CR>
    nmap zK :call VSCodeNotify('editor.gotoParentFold')<CR>

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
else
    let g:nvimapp = 0
    nnoremap j gj
    nnoremap k gk
    nmap <Backspace> <C-W>p
    set number
endif

let mapleader = ","

map - $
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

vmap <D-d> "zy:silent! !open "https://www.google.com/search?q="$(php -r "echo rawurlencode('<C-R>z');")<CR>
map <D-d> :silent !open "dict://<cword>"<CR>

" https://github.com/ybian/smartim
let g:smartim_default = 'com.apple.keylayout.ABC'
" let g:smartim_disable = 1
" unlet g:smartim_disable
" autocmd InsertLeave * :silent !/usr/local/bin/im-select com.apple.keylayout.ABC
" autocmd UIEnter * set noimd