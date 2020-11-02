if exists('g:loaded_trim_ws')
  finish
endif
let g:loaded_trim_ws = 1

let s:off = 0
let s:all = 1
let s:new = 2

let s:msgs = {
  \ s:off: 'Trim WS off, Git Trim off',
  \ s:all: 'Trim WS on',
  \ s:new: 'Trim WS off, Git Trim on'
\}

" Remember option and print new value.
function! s:mode(trim, verbose) abort
  let b:trim_ws = a:trim
  doautocmd User TrimWSChanged

  if a:verbose
    echom s:msgs[a:trim]
  endif
endfunction

" Cycle through trim_ws modes.
function! s:cycle() abort
  " Default to s:all so resulting mode will be s:new
  let l:trim = get(b:, 'trim_ws', s:all)
  let l:verbose = get(g:, 'trim_ws_verbose', 1)
  call s:mode((l:trim + 1) % 3, l:verbose)
endfunction

" Check if file already has trailing whitespace.
function! s:init() abort
  " For completion
  function! YesNo(ArgLead, CmdLine, CursorPos)
    return "Yes\nNo\nyes\nno"
  endfunction

  " Ask if want to keep whitespace
  if search('\s\+$', 'n')
    return input(
      \ 'File has trailing whitespace. Keep it? (y/n): ',
      \ '',
      \ 'custom,YesNo') =~? '^n' ? s:all : s:new
  endif

  return s:all
endfunction

" Remove trailing whitespace.
function! s:trim(...) abort
  if !&modifiable
    return
  endif

  let l:win = winsaveview()

  let l:lines = a:0 == 0 ? ['%'] : a:000[0]
  for l:line in l:lines
    execute printf('keepjumps keeppatterns %ss/\s\+$//ge', l:line)
  endfor

  call winrestview(l:win)
endfunction

" Initialize if needed and trim whitespace.
function! s:doTrim() abort
  if !exists('b:trim_ws')
    let b:trim_ws = s:init()
    doautocmd User TrimWSChanged
  endif

  if b:trim_ws == s:all
    call s:trim()
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

  call s:trim(l:lines)
  update
endfunction

command! -bar TrimWSCycle call s:cycle()
nnoremap <silent> <leader>tw :TrimWSCycle<CR>

augroup trimws
  autocmd!
  autocmd BufWritePre * call s:doTrim()
  autocmd BufWritePost * call s:gitTrim()
  autocmd BufNewFile * call s:mode(1, 0)
  autocmd User TrimWSChanged silent
augroup END
