" vim:foldmethod=marker
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

    " nmap j gj
    " nmap k gk

    " solution 1
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

    " solution 2
    " nmap j :call VSCodeCall('cursorMove', { 'to': 'down', 'by': 'wrappedLine', 'value': v:count ? v:count : 1 })<CR>
    " nmap k :call VSCodeCall('cursorMove', { 'to': 'up', 'by': 'wrappedLine', 'value': v:count ? v:count : 1 })<CR>

    " solution 3
"     lua <<EOF
"     local function moveCursor(direction)
"         if (vim.fn.reg_recording() == '' and vim.fn.reg_executing() == '') then
"             return ('g' .. direction)
"         else
"             return direction
"         end
"     end
    
"     vim.keymap.set('n', 'k', function()
"         return moveCursor('k')
"     end, { expr = true, remap = true })
"     vim.keymap.set('n', 'j', function()
"         return moveCursor('j')
"     end, { expr = true, remap = true })
" EOF

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

    " inoremap kk <Esc>
    " inoremap <Esc> <Ignore>

    " nnoremap j gj
    " nnoremap k gk
    nmap <Backspace> <C-W>p
    set number

    " cursor
    " https://github.com/neovim/neovim/wiki/FAQ#cursor-style-isnt-restored-after-exiting-or-suspending-and-resuming-nvim
    if !has('gui_running')
	    au VimEnter,VimResume * set guicursor=n-v-c:block,i-ci-ve:ver25,r-cr:hor20,o:hor50
				    \,a:blinkwait700-blinkoff400-blinkon250-Cursor/lCursor
				    \,sm:block-blinkwait175-blinkoff150-blinkon175

	    au VimLeave,VimSuspend * set guicursor=a:hor20-blinkon0
    endif
    map - $
    if system("osascript -e 'tell application \"System Events\" to tell appearance preferences to return dark mode'") =~? 'false'
		colorscheme xell_light_white
    else
		colorscheme xell_dark
	endif
endif

set ignorecase smartcase
set iskeyword+=-
set autochdir
set breakindent
set foldcolumn=2
set tabstop=4
set shiftwidth=4
set concealcursor=nc

set omnifunc=syntaxcomplete#Complete
imap <D-d> <C-x><C-K>

cnoremap <C-j> <Down>
cnoremap <C-k> <Up>

let mapleader = ","

map <C-j> <C-f>
map <C-k> <C-b>

vmap <D-c> "+y
map <D-v> x"+gP
cmap <D-v> <C-R>+
imap <D-v> <C-R><C-O>+

nmap <Leader>ns :let @/=""<CR>
nmap <Leader>nh :set nohlsearch<CR>
nmap <Leader>h :set hlsearch!<CR>
nmap <Leader>s :split<CR>
nmap <Leader>v :vsplit<CR>
nmap <Leader>c <C-W>c
" nmap ` <C-W>w

vmap <D-d> "zy:call <SID>google()<CR>
nmap <D-d> :silent !open "dict://<cword>"<CR>
function s:google()
    let word = @z
    let word = substitute(iconv(word, 'latin1', 'utf-8'),'[^A-Za-z0-9_.~-]','\="%".printf("%02X",char2nr(submatch(0)))','g')
    " let word = system('/usr/local/bin/php -r "echo rawurlencode(' . "'" . word . "'" . ');"')
    " let word = system('`brew --prefix`/bin/php -r "echo rawurlencode(' . "'" . word . "'" . ');"')
    exec 'silent! !open "https://www.google.com/search?q=' . shellescape(word, 1) . '"'
endfunction

nmap <Leader>fN :e /Users/xell/Library/Mobile Documents/iCloud~md~obsidian/Documents/Notes/QuickNote.md<CR>

" https://github.com/junegunn/vim-plug
" https://github.com/junegunn/vim-plug/issues/1218 lua
" https://gitlab.com/sultanahamer/dotfiles/-/blob/master/nvim/lua/plugins.lua?ref_type=heads
call plug#begin()

" easymotion plugins {{{
if exists(1 || 'g:vscode')
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

" https://github.com/xiyaowong/fast-cursor-move.nvim
" remap j k
Plug 'xiyaowong/fast-cursor-move.nvim'

" https://github.com/ixru/nvim-markdown
" no foldlevel support https://github.com/ixru/nvim-markdown/issues/5
Plug 'ixru/nvim-markdown'

" Plug 'vim-scripts/ZoomWin'

" Plug 'vimpostor/vim-lumen'

" https://github.com/neoclide/coc.nvim
" https://github.com/neoclide/coc-sources
" https://github.com/neoclide/coc.nvim/issues/1629
" in more general sense, https://github.com/neoclide/coc-lists can used to
" replaced telescope
Plug 'neoclide/coc.nvim', {'branch': 'release'}

" https://github.com/nvim-telescope/telescope.nvim
Plug 'nvim-lua/plenary.nvim'
Plug 'nvim-telescope/telescope.nvim'

" https://github.com/chentoast/marks.nvim
" https://www.reddit.com/r/neovim/comments/q7bgwo/marksnvim_a_plugin_for_viewing_and_interacting/
Plug 'chentoast/marks.nvim'

call plug#end()

imap <Plug> <Plug>Markdown_NewLineBelow
" imap <S-Tab> <Plug>Markdown_DeindentListItem

" https://linovox.com/install-and-use-telescope-in-neovim/
" lua require'telescope'.setup {defaults = {path_display={"truncate", "smart"}}}
lua require'telescope'.setup {defaults = {path_display={"truncate"}}}

nnoremap <D-S-f> <cmd>Telescope live_grep<cr>
nnoremap <D-p> <cmd>Telescope find_files follow=true<cr>
nnoremap <leader>ff <cmd>Telescope oldfiles<cr>
nnoremap <leader>fb <cmd>Telescope buffers<cr>
nnoremap <leader>fh <cmd>Telescope help_tags<cr>
nnoremap <leader>ft <cmd>Telescope tags<cr>
nnoremap <leader>fc <cmd>Telescope commands<cr>
nnoremap <leader>fC <cmd>Telescope commands_history<cr>
nnoremap <leader>fm <cmd>Telescope marks<cr>
nnoremap <leader>fr <cmd>Telescope registers<cr>
" https://github.com/nvim-telescope/telescope.nvim/issues/394
nnoremap <leader>fv <cmd>Telescope find_files follow=true search_dirs=~/.local/share/nvim<cr>
let g:xell_notes_root = fnameescape(glob('~/Library/Mobile\ Documents/iCloud~md~obsidian/Documents/Notes'))
nnoremap <leader>fn :Telescope find_files search_dirs=<C-R>=g:xell_notes_root<CR><cr>
nnoremap <leader>fl :Telescope current_buffer_fuzzy_find<cr>
nnoremap <leader>fR :Telescope resume<cr>

" nmap <Leader>fl :BLines<CR>
" nmap <Leader>fL :Lines<CR>
" nmap <Leader>fw :Windows<CR>

" marks
lua <<EOF
require'marks'.setup {
  -- whether to map keybinds or not. default true
  default_mappings = true,
  -- which builtin marks to show. default {}
  builtin_marks = { ".", "<", ">", "^" },
  -- whether movements cycle back to the beginning/end of buffer. default true
  cyclic = true,
  -- whether the shada file is updated after modifying uppercase marks. default false
  force_write_shada = false,
  -- how often (in ms) to redraw signs/recompute mark positions. 
  -- higher values will have better performance but may cause visual lag, 
  -- while lower values may cause performance penalties. default 150.
  refresh_interval = 250,
  -- sign priorities for each type of mark - builtin marks, uppercase marks, lowercase
  -- marks, and bookmarks.
  -- can be either a table with all/none of the keys, or a single number, in which case
  -- the priority applies to all marks.
  -- default 10.
  sign_priority = { lower=10, upper=15, builtin=8, bookmark=20 },
  -- disables mark tracking for specific filetypes. default {}
  excluded_filetypes = {},
  -- disables mark tracking for specific buftypes. default {}
  excluded_buftypes = {},
  -- marks.nvim allows you to configure up to 10 bookmark groups, each with its own
  -- sign/virttext. Bookmarks can be used to group together positions and quickly move
  -- across multiple buffers. default sign is '!@#$%^&*()' (from 0 to 9), and
  -- default virt_text is "".
  bookmark_0 = {
    sign = "⚑",
    virt_text = "hello world",
    -- explicitly prompt for a virtual line annotation when setting a bookmark from this group.
    -- defaults to false.
    annotate = false,
  },
  mappings = {}
}
EOF

nmap <C-Enter> :WinFullScreen<CR>

let g:coc_start_at_startup = 1

" https://linuxhandbook.com/vim-auto-complete/
inoremap <silent><expr> <TAB>
      \ coc#pum#visible() ? coc#pum#next(1) :
      \ CheckBackspace() ? "\<Tab>" :
      \ coc#refresh()
inoremap <expr><S-TAB> coc#pum#visible() ? coc#pum#prev(1) : "\<C-h>"
inoremap <silent><expr> <CR> coc#pum#visible() ? coc#pum#confirm(): "\<C-g>u\<CR>\<c-r>=coc#on_enter()\<CR>"
inoremap <silent><expr> <c-@> coc#refresh()
" :h coc#float#has_scroll()
nnoremap <silent><nowait><expr> <C-j> coc#float#has_scroll() ? coc#float#scroll(1) : "\<C-f>"
nnoremap <silent><nowait><expr> <C-k> coc#float#has_scroll() ? coc#float#scroll(0) : "\<C-b>"
" hover
" refer to keybinds in https://github.com/VonHeikemen/lsp-zero.nvim?tab=readme-ov-file#keybindings


set dictionary=/usr/share/dict/words
set complete+=k
set infercase

" au User LumenLight colorscheme xell_light_white
" au User LumenDark colorscheme xell_dark

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

" noremap s <Plug>(easymotion-overwin-f2)
" s 和 surround 冲突, 比如 ds
" onoremap z <Plug>(easymotion-f2)
noremap f <Plug>(easymotion-fl)
noremap F <Plug>(easymotion-Fl)
noremap t <Plug>(easymotion-tl)
noremap T <Plug>(easymotion-Tl)
noremap ;. <Plug>(easymotion-repeat)
noremap ;l <Plug>(easymotion-next)
noremap ;h <Plug>(easymotion-prev)
" noremap <Leader>/ <Plug>(easymotion-sn)
noremap <Leader>/ <Plug>(easymotion-s)

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

let g:urlpattern = '[[:alpha:]-]\+:\/\/[^ "' . "'>\\])]\\+"
let g:webbrowser = ''
" let g:webserver_host = 'http://localhost:80/~xell'
let g:webserver_host = 'http://localhost/~xell'
let g:webserver_dir = glob('~/Sites')
let g:tabpattern = '\(\[[^\^]\{-}\]\([:\[]\)\@!\(([^ ]\{-}\%(\s"[^"]\{-}"\)\?)\)\?\)\|' . g:urlpattern
let g:browser_open_rules = {'t2t': 'GetOutputHTML', 'md': 'GetOutputHTML', 'mkd': 'GetOutputHTML', 'markdown': 'GetOutputHTML', 'rst': 'GetOutputHTML', 'mdindex': 'GetOutputHTML'}

nnoremap <D-M-CR> <Cmd>call <SID>open()<CR>
nmap <expr> <C-y> xelltoolkit#get_copy(<SID>get_link())
nnoremap gn :call xelltoolkit#goto_next_word(g:tabpattern)<CR>
nnoremap gN :call xelltoolkit#goto_pre_word(g:tabpattern)<CR>

nmap <Leader>O :OpenInBrowser<CR>
" FIXME it's used to open the corresonding html of the current markdown. 
command! -bang -nargs=? OpenInBrowser call OpenInBrowser(<bang>1, '<args>')
command! -nargs=0 OpenInDefaultPrg call xelltoolkit#run('', expand("%:p"))

function! s:open()
    call OpenInBrowser(1,s:get_link())
endfunction

function! s:get_link()
	let linktext = xelltoolkit#get_word_at_cursor(g:tabpattern)

	if linktext == ''
		echohl WarningMsg | echomsg 'Wrong URI!' | echohl None
		return ''
	elseif linktext !~ '^\['   " http or file
		return linktext
	elseif linktext =~ '\]('   " [linktext](http title)
		return matchstr(linktext, '\](\(\zs[^ ]\{-}\ze\%(\s"[^"]\{-}"\)\?\))', 0)
	endif

	" [linktext][id] or [linktext][] or [linktext]
	if linktext =~ '\]\[' && linktext !~ '\[\]'
		let id = matchstr(linktext, '\]\[\zs[^]]\+\ze\]', 0)
	else
		let id = matchstr(linktext, '^\[\zs[^]]\+\ze\]', 0)
	endif
	return matchstr(getline(searchpos('^[ ]\{0,3}\[' . id . '\]:\s', 'n')[0]), '\]:\s\zs[^ ]\+\ze')
endfunction

