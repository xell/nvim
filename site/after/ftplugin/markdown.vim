setlocal tabstop=2
setlocal shiftwidth=2
setlocal concealcursor=nc
setlocal conceallevel=2
setlocal breakindent
setlocal linebreak

let b:coc_suggest_disable = 1

setlocal foldtext=MKDFoldtext()

function MKDFoldtext() abort
    let fs = v:foldstart
    let line = getline(fs)
    let line = strpart(line, 0, 50)
    " ⊙ ● ✪ ⊕ ⌾
    let line = substitute(line, '^\s*-', '●', '')
    let line = repeat(' ', indent(fs)) . line
    return line
endfunction


