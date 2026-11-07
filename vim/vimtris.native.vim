" vimtris.native.vim - play vimtris in Vim itself, without the launcher.
"
"   vim -Nu NONE -i NONE -n -S vimtris.native.vim
"   SEED=42 vim -Nu NONE -i NONE -n -S vimtris.native.vim      (a fixed game)
"
" vimtris.sh runs Vim headless and feeds it numbers: bash reads the keys and
" sends a tick every 100 ms. Here Vim does both. It starts full-screen, which
" puts the terminal in raw mode, so getchar(0) returns each key as it is
" pressed, or 0 if there is none; reltime() keeps the time. The game is
" vimtris.vim's, sourced from next to this file: same rules, same frames.
"
" The frames go to /dev/stdout, the terminal, as vimtris.vim writes them, but
" with "\r\n" at the ends of the lines: raw mode also turns off the terminal's
" output processing, and a bare newline only moves the cursor down.
" Vim itself draws nothing meanwhile: it only redraws when a script is done or
" asks for it, and this script runs until the game ends.

let g:vimtris_native = 1
execute 'source' fnameescape(expand('<sfile>:p:h') . '/vimtris.vim')

" The keys of ../SPEC.md: letters, arrows, space and Enter.
let s:keys = {'a': 1, 'A': 1, "\<Left>": 1, 'd': 2, 'D': 2, "\<Right>": 2,
      \ 'w': 3, 'W': 3, "\<Up>": 3, 's': 4, 'S': 4, "\<Down>": 4, "\r": 4,
      \ 'z': 5, 'Z': 5, ' ': 5}

function! s:Out(s) abort
  call writefile([a:s], '/dev/stdout', 'abS')
endfunction

" getchar() gives a Number for a plain key and a String for a special one.
function! s:Key(c) abort
  return type(a:c) == v:t_number ? nr2char(a:c) : a:c
endfunction

function! s:Play() abort
  let seed = str2nr($SEED)
  if seed < 1 || seed > 2147483646
    let seed = (exists('*rand') ? rand() : localtime()) % 2147483646 + 1
  endif
  call s:Out("\e[2J\e[H\e[?25l")      " clear the screen, hide the cursor
  call g:vimtris.start(seed)
  let start = reltime()
  let ticks = 0                       " ticks sent so far
  while !g:vimtris.over()
    let c = getchar(0)
    if c isnot 0
      let k = s:Key(c)
      if k ==? 'q'
        return
      endif
      if has_key(s:keys, k) && g:vimtris.event(s:keys[k])
        call g:vimtris.render()
      endif
      continue                        " read every waiting key before sleeping
    endif
    " A tick every 100 ms. After a long stall (a suspended terminal, say)
    " the clock starts again instead of replaying all the missed ticks.
    let due = float2nr(reltimefloat(reltime(start)) * 10)
    if due - ticks > 10
      let start = reltime()
      let ticks = 0
      let due = 0
    endif
    while ticks < due && !g:vimtris.over()
      let ticks += 1
      if g:vimtris.event(0)
        call g:vimtris.render()
      endif
    endwhile
    sleep 10m
  endwhile
  " Game over: the last frame stays up until a key is pressed, because Vim
  " gives the terminal back as it was when it quits.
  call getchar()
endfunction

try
  call s:Play()
catch /^Vim:Interrupt$/
endtry
call s:Out("\e[?25h\e[m")
qall!
