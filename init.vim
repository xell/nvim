
if exists('g:vscode')
    let g:test = 1
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
else
    let g:test = 0
    nnoremap j gj
    nnoremap k gk
    set number
endif

let mapleader = ","

map - $
map <C-j> <C-f>
map <C-k> <C-b>

nmap <Leader>ns :let @/=""<CR>
nmap <Leader>nh :set nohlsearch<CR>
nmap <Leader>h :set hlsearch<CR>
nmap <Leader>s :split<CR>
nmap <Leader>v :vsplit<CR>
nmap <Leader>c <C-W>c
nmap <Backspace> <C-W>p
nmap ` <C-W>w

" https://github.com/ybian/smartim
let g:smartim_default = 'com.apple.keylayout.ABC'
" let g:smartim_disable = 1
" unlet g:smartim_disable
" autocmd InsertLeave * :silent !/usr/local/bin/im-select com.apple.keylayout.ABC
" autocmd UIEnter * set noimd
