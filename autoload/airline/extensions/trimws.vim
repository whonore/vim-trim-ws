if !exists('g:airline#extensions#trimws#all')
  let g:airline#extensions#trimws#all = 'Trim All'
endif

if !exists('g:airline#extensions#trimws#new')
  let g:airline#extensions#trimws#new = 'Trim New'
endif

let s:spc = g:airline_symbols.space

function! airline#extensions#trimws#status() abort
  return !exists('b:trim_ws') || b:trim_ws == 0 ? ''
          \ : b:trim_ws == 1 ? g:airline#extensions#trimws#all
          \ : g:airline#extensions#trimws#new
endfunction

function! airline#extensions#trimws#apply(...) abort
  let l:status = airline#extensions#trimws#status()
  if !empty(l:status)
    call airline#extensions#append_to_section('a',
          \ s:spc . g:airline_left_sep . s:spc . l:status)
  endif
endfunction

function! airline#extensions#trimws#init(ext) abort
  call airline#parts#define_function('trimws', 'airline#extensions#trimws#status')
  call a:ext.add_statusline_func('airline#extensions#trimws#apply')
endfunction
