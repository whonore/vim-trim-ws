if exists('g:loaded_trim_ws')
  finish
endif
let g:loaded_trim_ws = 1

let s:off = 0
let s:all = 1
let s:new = 2

" Try to refresh airline plugin.
augroup trim_ws
  autocmd!
  autocmd User TrimWSChanged silent! AirlineRefresh
augroup END

" Remember option and print new value.
function! s:setTrim(trim, verbose) abort
  let b:trim_ws = a:trim
  doautocmd User TrimWSChanged

  if a:verbose
    if a:trim == s:off
      echom 'Trim WS off, Git Trim off'
    elseif a:trim == s:all
      echom 'Trim WS on'
    elseif a:trim == s:new
      echom 'Trim WS off, Git Trim on'
    endif
  endif
endfunction

" Cycle through trim_ws modes.
function! s:cycleTrim() abort
  " Default to s:all so resulting mode will be s:new
  let l:trim = get(b:, 'trim_ws', s:all)
  let l:verbose = get(g:, 'trim_ws_verbose', 1)
  call s:setTrim((l:trim + 1) % 3, l:verbose)
endfunction

" Check if file already has trailing whitespace.
function! s:initTrimWS() abort
  " For completion
  function! YesNo(ArgLead, CmdLine, CursorPos)
    return "Yes\nNo\nyes\nno"
  endfunction

  " Ask if want to keep whitespace
  if search('\s\+$', 'n')
    if input('File has trailing whitespace. Keep it? (y/n): ',
            \'',
            \'custom,YesNo') =~? '^n'
      return s:all
    else
      return s:new
    endif
  endif

  return s:all
endfunction

" Remove trailing whitespace.
function! s:trimLines(...) abort
  if !&modifiable
    return
  endif

  let l:win = winsaveview()

  let l:lines = a:0 == 0 ? ['%'] : a:000[0]
  for l:line in l:lines
    execute l:line . 's/\s\+$//ge'
  endfor

  call winrestview(l:win)
endfunction

" Initialize if needed and trim whitespace.
function! s:doTrim() abort
  if !exists('b:trim_ws')
    let b:trim_ws = s:initTrimWS()
    doautocmd User TrimWSChanged
  endif

  if b:trim_ws == s:all
    call s:trimLines()
  endif
endfunction

" Use git diff --check to look for newly introduced whitespace errors.
function! s:gitTrim() abort
  if b:trim_ws != s:new
    return
  endif

  let l:lines = []
  for l:line in split(system('git diff --check ' . expand('%:p')), '\n')
    if l:line =~# '[^:]*:\d\+: trailing whitespace.'
      let l:lines = add(l:lines, split(l:line, ':')[1])
    endif
  endfor

  call s:trimLines(l:lines)
  update
endfunction

command! -bar TrimWSCycle call s:cycleTrim()
nnoremap <silent> <leader>tw :TrimWSCycle<CR>

augroup trimws
  autocmd!
  autocmd BufWritePre * call s:doTrim()
  autocmd BufWritePost * call s:gitTrim()
  autocmd BufNewFile * call s:setTrim(1, 0)
augroup END
