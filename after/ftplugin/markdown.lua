local vol = vim.opt_local
vol.shiftwidth = 2
vol.concealcursor = 'nc'
vol.conceallevel = 2
vol.breakindent = true
vol.linebreak = true
vol.formatoptions = 'mBlrocq'
vol.comments:append(':-')
vol.comments:remove('fb:-')

local vks = vim.keymap.set
vks('v', '<Leader>b', [[<ESC>`>a**<ESC>`<i**<ESC>`>ll]], { buffer = true })
vks('v', '<Leader>i', [[<ESC>`>a*<ESC>`<i*<ESC>`>ll]], { buffer = true })
vks('v', '<Leader>t', [[<ESC>`>a}<ESC>`<i{=<ESC>`>ll]], { buffer = true })
vks('v', '<Leader>c', [[<ESC>`>a`<ESC>`<i`<ESC>`>ll]], { buffer = true })
vks('v', '<Leader>h', [[<ESC>`>a==}<ESC>`<i{==<ESC>`>ll]], { buffer = true })

vol.foldmethod = 'expr'
vol.foldexpr = 'v:lua.vim.treesitter.foldexpr()'

vim.cmd[[
let s:textbundle_filename = expand('%:r')

command! -buffer -nargs=0 ExportTextbundle call <SID>export_textbundle()
function! s:export_textbundle()
    " Is it already in a Textbundle?
    if expand('%:p:h:t') =~ '\.textbundle$'
        echohl ErrorMsg | echo "It's already a Textbundle." | echohl None
        return
    endif
    " Is there an assests directory?
    let current_dir = expand('%:p:h')
    if !isdirectory(current_dir . '/assets')
        echohl ErrorMsg | echo "There's no 'assets' directory." | echohl None
        return
    endif
    " CD to current directory to siimplify the following operations
    exec 'cd ' . current_dir
    let textbundle_filename = expand('%:t:r')
    " let textbundle_path = current_dir . '/' . textbundle_filename . '.textbundle'
    " call mkdir(textbundle_path)
    call mkdir(textbundle_filename . '.textbundle')
    echo system('cp -r assets "' . textbundle_filename . '.textbundle/"')
    echo system('cp "' . expand('%:p:t') . '" "' . textbundle_filename . '.textbundle/text.md"')
    let info_json_content = ['{', '"version" : 2,',
                \ '"type": "net.daringfireball.markdown",',
                \ '"transient" : true,',
                \ '"creatorURL" : "file:///Applications/MacVim.app",',
                \ '"creatorIdentifier" : "org.vim",',
                \ '"sourceURL": ""', '}']
    call writefile(info_json_content, 'info.json', )
    echo system('mv info.json "' . textbundle_filename . '.textbundle/"')
    " echohl MoreMsg
    echom textbundle_filename . '.textbundle'
    echom 'was successfully created in'
    echom current_dir
    " echohl None
endfunction
]]
