if exists('g:loaded_trim_ws')
  finish
endif
let g:loaded_trim_ws = 1

let g:trim_ws_print = 1

" Try to refresh airline plugin.
function! s:refresh_airline()
  try
    call airline#update_statusline()
  catch
  endtry
endfunction

" Remember option and print new value.
function! s:setTrim(trim, print)
  let b:trim_ws = a:trim
  call s:refresh_airline()

  if a:print
    if a:trim == 0
      echom 'Trim WS off, Git Trim off'
    elseif a:trim == 1
      echom 'Trim WS on'
    elseif a:trim == 2
      echom 'Trim WS off, Git Trim on'
    endif
  endif
endfunction

" Cycle through trim_ws modes.
function! s:cycleTrim()
  if !exists('b:trim_ws')
    " Default to 1 so resulting mode will be 2
    let b:trim_ws = 1
  endif

  call s:setTrim((b:trim_ws + 1) % 3, g:trim_ws_print)
endfunction

" Check if file already has trailing whitespace.
function! s:initTrimWS()
  " For completion
  function! YesNo(ArgLead, CmdLine, CursorPos)
    return "Yes\nNo\nyes\nno"
  endfunction

  " Ask if want to keep whitespace
  if search('\s\+$', 'n')
    if input('File has trailing whitespace. Keep it? (y/n): ',
            \'',
            \'custom,YesNo') =~? '^n'
      return 1
    else
      return 2
    endif
  endif

  return 1
endfunction

" Remove trailing whitespace.
function! s:trimLines(...)
  let l:win = winsaveview()

  let l:lines = a:0 == 0 ? ['%'] : a:000[0]
  for l:line in l:lines
    execute l:line . 's/\s\+$//ge'
  endfor

  call winrestview(l:win)
endfunction

" Initialize if needed and trim whitespace.
function! s:doTrim()
  if !exists('b:trim_ws')
    let b:trim_ws = s:initTrimWS()
    call s:refresh_airline()
  endif

  if b:trim_ws == 1
    call s:trimLines()
  endif
endfunction

" Use git diff --check to look for newly introduced whitespace errors.
function! s:gitTrim()
  if b:trim_ws != 2
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

command! TrimWSCycle call s:cycleTrim()
nnoremap <leader>tw :TrimWSCycle<CR>

augroup trimws
  autocmd!
  autocmd BufWritePre * call s:doTrim()
  autocmd BufWritePost * call s:gitTrim()
  autocmd BufNewFile * call s:setTrim(1, 0)
augroup END
