" Global!
" hi! default link Folded NormalFloat

" Redefine texComment without the 'contains=@Spell' argument
syn region texComment start="%" end="$" keepend contains=@NoSpell
