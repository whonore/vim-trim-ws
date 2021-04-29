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

" Check if file already has trailing whitespace.
function! s:initmode(check) abort
  " For completion
  function! YesNo(ArgLead, CmdLine, CursorPos)
    return "Yes\nNo\nyes\nno"
  endfunction

  " Ask if want to keep whitespace
  return a:check && search('\s\+$', 'n')
    \ ? input(
      \ 'File has trailing whitespace. Keep it? (y/n): ',
      \ '',
      \ 'custom,YesNo') =~? '^n' ? s:all : s:new
    \ : s:all
endfunction

" Set the current mode.
function! s:setmode(trim, verbose) abort
  let b:trim_ws = a:trim
  doautocmd User TrimWSChanged
  if a:verbose
    echom s:msgs[a:trim]
  endif
endfunction

" Get the current mode or initialize it.
function! s:getmode(check) abort
  if !exists('b:trim_ws')
    call s:setmode(s:initmode(a:check), 0)
  endif
  return b:trim_ws
endfunction

" Cycle through modes.
function! s:cyclemode() abort
  " Default to s:all so resulting mode will be s:new
  let l:trim = s:getmode(0)
  let l:verbose = get(g:, 'trim_ws_verbose', 1)
  call s:setmode((l:trim + 1) % 3, l:verbose)
endfunction

" Remove trailing whitespace from given lines.
function! s:trim(...) abort
  if !&modifiable
    return
  endif

  let l:win = winsaveview()

  let l:lines = a:0 == 0 ? ['%'] : a:000[0]
  for l:line in l:lines
    execute printf('silent keepjumps keeppatterns %ss/\s\+$//ge', l:line)
  endfor

  call winrestview(l:win)
endfunction

" Trim whitespace based on the current mode.
function! s:doTrim() abort
  if s:getmode(1) == s:all
    " Trim all lines.
    call s:trim()
  elseif s:getmode(1) == s:new
    " Use git diff --check to look for newly introduced whitespace errors.
    let l:lines = []
    for l:line in split(system('git diff --check ' . expand('%:p')), '\n')
      try
        let l:lines = add(
          \ l:lines,
          \ matchlist(l:line, '[^:]*:\(\d\+\): trailing whitespace.')[1])
      catch /Vim\%((\a\+)\)\=:E684:/
      endtry
    endfor
    call s:trim(l:lines)
  endif
  silent update
endfunction

command! -bar TrimWSCycle call s:cyclemode()
nnoremap <silent> <leader>tw :TrimWSCycle<CR>

augroup trimws
  autocmd!
  autocmd BufWritePost * call s:doTrim()
  autocmd BufNewFile * call s:setmode(s:all, 0)
  autocmd User TrimWSChanged silent
augroup END
