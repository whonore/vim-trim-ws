function! s:letdef(var, val) abort
  if !exists(a:var)
    execute printf('let %s = %s', a:var, string(a:val))
  endif
endfunction

call s:letdef('g:airline#extensions#trimws#all', 'Trim All')
call s:letdef('g:airline#extensions#trimws#new', 'Trim New')

let s:spc = g:airline_symbols.space

function! airline#extensions#trimws#status() abort
  let l:mode = get(b:, 'trim_ws', 0)
  let l:status =
    \ l:mode == 1 ? g:airline#extensions#trimws#all
    \ : l:mode == 2 ? g:airline#extensions#trimws#new
    \ : ''
  return l:status !=# '' ? s:spc . g:airline_left_sep . s:spc . l:status : ''
endfunction

function! airline#extensions#trimws#apply(...) abort
  call airline#extensions#append_to_section('a', '%{airline#extensions#trimws#status()}')
endfunction

function! airline#extensions#trimws#init(ext) abort
  call airline#parts#define_function('trimws', 'airline#extensions#trimws#status')
  call a:ext.add_statusline_func('airline#extensions#trimws#apply')
endfunction
