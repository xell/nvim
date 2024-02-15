syntax case ignore
syntax clear
syntax spell toplevel

syn include @markdown syntax/markdown.vim
syn match markdownContent '^[ ]*-[ ]\zs.*\ze$' contains=@markdown keepend
syn region markdownYaml start='^---$' end='^---' contains=@markdown keepend
" syn region markdown start='^\s*- \zs' keepend end='$' contains=@markdown

" https://github.com/neovim/neovim/blob/master/runtime/syntax/markdown.vim
" https://vi.stackexchange.com/questions/26825/conceal-markdown-links-and-extensions
syn region markdownLink matchgroup=markdownLinkDelimiter start="(" end=")" contains=markdownUrl keepend contained conceal
syn region markdownLinkText matchgroup=markdownLinkTextDelimiter start="!\=\[\%(\%(\_[^][]\|\[\_[^][]*\]\)*]\%( \=[[(]\)\)\@=" end="\]\%( \=[[(]\)\@=" nextgroup=markdownLink,markdownId skipwhite contains=@markdownInline,markdownLineStart concealends
" syn region markdownCode matchgroup=markdownCodeDelimiter start="`" end="`" keepend contains=markdownLineStart
" syn region markdownCode matchgroup=markdownCodeDelimiter start="`` \=" end=" \=``" keepend contains=markdownLineStart

" hi default link markdownCodeDelimiter String
" hi default link markdownCode String
" TODO fold of block will affect the below highlights
" hi default link markdownCodeBlock String

" syn match listMarker '^[ ]*\zs-\ze[ ]' conceal cchar=○
" hi! default link Conceal Title

" syn match markdownListMarkerConceal "\%(\t\| \{0,4\}\)\zs[-*+]\ze\%(\s\+\S\)\@=" conceal cchar=●
" syn match Conceal /^\s*\zs-/ conceal cchar=
" call matchadd('Conceal',"\%(\t\| \{0,4\}\)\zs[-*+]\ze\%(\s\+\S\)\@=",50,-1,{'conceal': '●'})
" call matchadd('Conceal','^\s*\zs-',10,-1,{'conceal': '●'})
call matchadd('Conceal','^\s*\zs-\ze ',10,-1,{'conceal': '○'})
"" call matchadd('Conceal','^\s*\zs-\ze ',10,-1,{'conceal': ''})
" call matchadd('Conceal','^\s*\zs-\ze ',10,-1,{'conceal': ''})
" hi! link Conceal Normal
