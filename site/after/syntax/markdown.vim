" https://github.com/neovim/neovim/blob/master/runtime/syntax/markdown.vim
" https://vi.stackexchange.com/questions/26825/conceal-markdown-links-and-extensions
syn region markdownLink matchgroup=markdownLinkDelimiter start="(" end=")" contains=markdownUrl keepend contained conceal
syn region markdownLinkText matchgroup=markdownLinkTextDelimiter start="!\=\[\%(\%(\_[^][]\|\[\_[^][]*\]\)*]\%( \=[[(]\)\)\@=" end="\]\%( \=[[(]\)\@=" nextgroup=markdownLink,markdownId skipwhite contains=@markdownInline,markdownLineStart concealends
" syn region markdownCode matchgroup=markdownCodeDelimiter start="`" end="`" keepend contains=markdownLineStart
" syn region markdownCode matchgroup=markdownCodeDelimiter start="`` \=" end=" \=``" keepend contains=markdownLineStart

syn match   xTemp      '{=[^=][^}]\{-}}' containedin=ALLBUT,cmHighlight,cmHighlightLeft,cmHighlightRight
syn match   cmHighlight      '{==[^=].\{-}==}' contains=@Spell,cmHighlightLeft,cmHighlightRight
syn match   cmHighlightLeft  '{==' contained conceal
syn match   cmHighlightRight '==}' contained conceal

hi default link xTemp Type
hi default link cmHighlight Type
hi default link markdownCodeDelimiter String
hi default link markdownCode String

syn region markdownIdDeclaration matchgroup=markdownLinkDelimiter start="^ \{0,3\}!\=\[" end="\]:" oneline keepend skipwhite

hi! default link markdownFootnote Underlined
hi! default link markdownIdDeclaration Underlined
hi! default link markdownBold Keyword
hi! default link markdownItalic Special
" TODO fold of block will affect the below highlights
" hi default link markdownCodeBlock String

" syn match markdownListMarkerConceal "\%(\t\| \{0,4\}\)\zs[-*+]\ze\%(\s\+\S\)\@=" conceal cchar=●
" call matchadd('Conceal',"\%(\t\| \{0,4\}\)\zs[-*+]\ze\%(\s\+\S\)\@=",50,-1,{'conceal': '●'})
" call matchadd('Conceal','^\s*\zs-',10,-1,{'conceal': '●'})
"" call matchadd('Conceal','^\s*\zs-\ze ',10,-1,{'conceal': '○'})
" hi! link Conceal Normal
" syntax match Conceal /^\s*\zs-/ conceal cchar=
