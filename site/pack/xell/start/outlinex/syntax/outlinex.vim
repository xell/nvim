" vim:fdm=marker
syntax case ignore
syntax clear
syntax spell toplevel

" syn include @markdown syntax/markdown.vim
" syn match markdownContent '^[ ]*-[ ]\zs.*\ze$' contains=@markdown keepend
" syn region markdownYaml start='^---$' end='^---' contains=@markdown keepend
" syn region markdown start='^\s*- \zs' keepend end='$' contains=@markdown

" https://github.com/neovim/neovim/blob/master/runtime/syntax/markdown.vim
" https://vi.stackexchange.com/questions/26825/conceal-markdown-links-and-extensions
syn region markdownLink matchgroup=markdownLinkDelimiter start="(" end=")" contains=markdownUrl keepend contained conceal
syn region markdownLinkText matchgroup=markdownLinkTextDelimiter start="!\=\[\%(\%(\_[^][]\|\[\_[^][]*\]\)*]\%( \=[[(]\)\)\@=" end="\]\%( \=[[(]\)\@=" nextgroup=markdownLink,markdownId skipwhite contains=@markdownInline,markdownLineStart concealends
" syn region markdownCode matchgroup=markdownCodeDelimiter start="`" end="`" keepend contains=markdownLineStart
" syn region markdownCode matchgroup=markdownCodeDelimiter start="`` \=" end=" \=``" keepend contains=markdownLineStart

" {{{
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
" }}}

syn match markdownImageLinkIndicator /\zs!\ze\[.\{-}\]([^ )]\{-}\.\w\+)/
hi default link markdownImageLinkIndicator Label

" CriticMarkup
syn match   pdcTempPPP      '{=[^=][^}]\{-}}' containedin=ALLBUT,cmHighlight,cmHighlightLeft,cmHighlightRight
syn match   cmHighlight      '{==[^=].\{-}==}' contains=@Spell,cmHighlightLeft,cmHighlightRight
syn match   cmHighlightLeft  '{==' contained conceal
syn match   cmHighlightRight '==}' contained conceal
" ~~strike~~
syn match   pdcStrike       '\~\~[^\~ ]\([^\~]\|\~ \)*\~\~' contains=@Spell,pdcStrikeFix
syn match   pdcStrikeFix    '\~' contained conceal
" **strong**
syn match   pdcStrong       '\*\*[^* ].\{-}\*\*' contains=@Spell,pdcStrongFix
" *emp*
syn match   pdcEmphasis     '\*[^* ].\{-}\*' contains=@Spell,pdcStrongFix
syn match   pdcStrongFix    '\*' contained conceal
" Inline codes
syn region pdcCode start=/`\S/ end=/`\|^\s*$/ oneline
syn region pdcCode start=/``[^`]*/ end=/``\|^\s*$/ oneline
" Quotes
syn match pdcBlockQuote '^\s*- \zs>.*$'
" yaml
" syn region pandocYAMLHeader start=/\%(\%^\|\_^\s*\n\)\@<=\_^-\{3}\ze\n.\+/ end=/^\([-.]\)\1\{2}$/ keepend contains=@YAML containedin=TOP

hi default link pdcTempPPP Type
hi default link cmHighlight Type
hi default link pdcStrike Todo
hi default link pdcStrong Keyword
hi default link pdcEmphasis Special
hi default link pdcCode String
hi default link pdcBlockQuote CursorLine
