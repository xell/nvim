" vim:fdm=marker
syntax case ignore
syntax clear
syntax spell toplevel


" {{{
" hi default link markdownCodeDelimiter String
" hi default link markdownCode String
" TODO fold of block will affect the below highlights
" hi default link markdownCodeBlock String

" syn match listMarker '^[ ]*\zs-\ze[ ]' conceal cchar=○
" hi! default link Conceal Title

" syn match markdownListMarkerConceal "\%(\t\| \{0,4\}\)\zs[-*+]\ze\%(\s\+\S\)\@=" conceal cchar=●


let s:circle_symbol = ['○', '', '', '', '', '󰝦']
"exec 'syn match Conceal /^\s*\zs-\ze / conceal cchar=' . ($TERM_PROGRAM ==# 'WezTerm' ? s:circle_symbol[1] : s:circle_symbol[1])
call matchadd('Conceal','^\s*\zs-\ze ', 20, -1, {'conceal': $TERM_PROGRAM ==# 'WezTerm' ? s:circle_symbol[1] : s:circle_symbol[1]})

" hi! link Conceal Normal
" }}}

syn match markdownImageLinkIndicator /\zs!\ze\[.\{-}\]([^ )]\{-}\.\w\+)/
hi default link markdownImageLinkIndicator Label

" Becuase markdown has its own syntax file, but outlinex is brand new
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
hi default link cmHighlight RedrawDebugClear
hi default link pdcStrike Todo
"hi default link pdcStrong @markup.strong
hi default link pdcStrong textBold
"hi default link pdcEmphasis @markup.italic
hi default link pdcEmphasis textItalic
hi default link pdcCode @string
hi default link pdcBlockQuote CursorLine
hi! default link @markup.raw.markdown_inline @string
