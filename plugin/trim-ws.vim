if exists('g:loaded_trim_ws')
    finish
endif
let g:loaded_trim_ws = 1

" Remember option and print new value
function! SetTrim(trim, print)
    let b:trim_ws = a:trim

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

" Cycle through trim_ws modes
function! ToggleTrim()
    if !exists('b:trim_ws')
        " Default to 1 so resulting mode will be 2
        let b:trim_ws = 1
    endif

    call SetTrim((b:trim_ws + 1) % 3, 1)
endfunction

" Check if file already has trailing whitespace
function! InitTrimWS()
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

" Remove trailing whitespace
function! DoTrim()
    if !exists('b:trim_ws')
        let b:trim_ws = InitTrimWS()
    endif

    if b:trim_ws == 1
        let l:win = winsaveview()
        %s/\s\+$//ge
        call winrestview(l:win)
    endif
endfunction

" Use git diff --check to look for newly introduced whitespace errors
function! GitTrim()
    if b:trim_ws == 2
        let l:changed = 0
        let l:win = winsaveview()

        for l:line in split(system('git diff --check ' . expand('%:p')), '\n')
            if l:line =~ '[^:]*:\d\+: trailing whitespace.'
                let l:num = split(l:line, ':')[1]
                execute l:num . 's/\s\+$//ge'
                let l:changed = 1
            endif
        endfor

        call winrestview(l:win)

        if l:changed
            write
        endif
    endif
endfunction

nnoremap <leader>tw :call ToggleTrim()<CR>

autocmd BufWritePre * call DoTrim()
autocmd BufWritePost * call GitTrim()
autocmd BufNewFile * call SetTrim(1, 0)
