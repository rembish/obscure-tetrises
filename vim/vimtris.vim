" vimtris.vim - a falling-block puzzle game written in Vim script.
"
"   vim -Nu NONE -i NONE -es -S vimtris.vim < events > frames
"
" Vim is only the interpreter here: -es is silent Ex mode, so there is no
" screen, no buffer to look at and no terminal handling. In that mode input('')
" reads one line from stdin, so the script reads the seed and then one event
" per line itself (0 tick, 1 left, 2 right, 3 rotate, 4 soft drop, 5 hard drop,
" 9 quit). At end of input Vim simply exits. Each frame goes out with
" writefile(..., '/dev/stdout', 'abS'): 'b' means no newline after the last
"" item, 'a' appends instead of truncating whatever stdout points at, and
" 'S' skips the fsync() that writefile() would otherwise do after every frame.
"
" The UTF-8 box characters are written as raw bytes and pass through untouched
" whatever 'encoding' the locale gives Vim (no :scriptencoding on purpose).
"
" The rules are in ../SPEC.md. This is legacy Vim script (not vim9script).

" ---- tables -------------------------------------------------------------------
" Rotation masks: bit y*4+x is set when the 4x4 box has a cell at (x, y).
let s:masks = [
      \ [240, 17476, 3840, 8738],
      \ [102, 102, 102, 102],
      \ [114, 610, 624, 562],
      \ [54, 1122, 864, 561],
      \ [99, 612, 1584, 306],
      \ [113, 550, 1136, 802],
      \ [116, 1570, 368, 547]]
let s:colours = [51, 226, 135, 46, 196, 33, 208]
let s:points = [0, 40, 100, 300, 1200]

" ---- escape sequences ------------------------------------------------------------
let s:E = "\e"
let s:R = s:E . '[m'

function! s:B(s) abort
  return s:E . '[38;5;60m' . a:s . s:R
endfunction

function! s:D(s) abort
  return s:E . '[38;5;244m' . a:s . s:R
endfunction

" The coloured block for piece p (0..6).
let s:blocks = map(copy(s:colours), {_, c -> s:E . '[38;5;' . c . 'm██' . s:R})
let s:empty = s:E . '[38;5;237m ·' . s:R
let s:cellstr = [s:empty] + s:blocks

" ---- state ---------------------------------------------------------------------
" The board is a flat list of 200 cells, index y*10+x; 0 empty, piece+1 filled.
let s:board = repeat([0], 200)
let s:score = 0
let s:lines = 0
let s:over = 0

" Park-Miller minimal standard generator; returns the next piece number.
function! s:Rand() abort
  let s:seed = s:seed * 16807 % 2147483647
  return s:seed % 7
endfunction

function! s:Level() abort
  return s:lines / 10 + 1
endfunction

" The box offsets [cx, cy] of every piece and rotation, worked out once from
" the masks, because looping over 16 bits on every test is slow in Vim script.
let s:offsets = []
for s:p in range(7)
  call add(s:offsets, [])
  for s:m in s:masks[s:p]
    call add(s:offsets[-1], map(filter(range(16), 'and(s:m, 1 << v:val)'),
          \ '[v:val % 4, v:val / 4]'))
  endfor
endfor

" The board coordinates [x, y] of the cells of the current piece at (x, y, r).
function! s:Cells(x, y, r) abort
  return map(copy(s:offsets[s:cur][a:r]), '[a:x + v:val[0], a:y + v:val[1]]')
endfunction

" Does the current piece fit at (x, y) in rotation r?
function! s:Fits(x, y, r) abort
  for [cx, cy] in s:Cells(a:x, a:y, a:r)
    if cx < 0 || cx >= 10 || cy < 0 || cy >= 20 || s:board[cy * 10 + cx]
      return 0
    endif
  endfor
  return 1
endfunction

function! s:Spawn() abort
  let s:x = 3
  let s:y = 0
  let s:r = 0
  let s:t = 0
  if !s:Fits(s:x, s:y, s:r)
    let s:over = 1
  endif
endfunction

function! s:Lock() abort
  " 1. Write the piece into the board.
  for [cx, cy] in s:Cells(s:x, s:y, s:r)
    let s:board[cy * 10 + cx] = s:cur + 1
  endfor
  " 2. Keep the rows that still have a hole, then pad with empty rows on top.
  let kept = []
  for row in range(20)
    let cells = s:board[row * 10 : row * 10 + 9]
    if index(cells, 0) >= 0
      call extend(kept, cells)
    endif
  endfor
  let n = 20 - len(kept) / 10
  let s:board = repeat([0], n * 10) + kept
  " 3. and 4. Score with the level before the clear, then count the rows.
  let s:score += s:points[n] * s:Level()
  let s:lines += n
  " 5. Next piece.
  let s:cur = s:next
  let s:next = s:Rand()
  call s:Spawn()
endfunction

function! s:StepDown() abort
  if s:Fits(s:x, s:y + 1, s:r)
    let s:y += 1
  else
    call s:Lock()
  endif
endfunction

" Apply one event; return 1 if a frame should be printed.
function! s:Event(e) abort
  if a:e == 0
    let s:t += 1
    if s:t < max([1, 11 - s:Level()])
      return 0
    endif
    let s:t = 0
    call s:StepDown()
  elseif a:e == 1 || a:e == 2
    let dx = a:e == 1 ? -1 : 1
    if s:Fits(s:x + dx, s:y, s:r)
      let s:x += dx
    endif
  elseif a:e == 3
    let nr = (s:r + 1) % 4
    for dx in [0, -1, 1, -2, 2]
      if s:Fits(s:x + dx, s:y, nr)
        let s:x += dx
        let s:r = nr
        break
      endif
    endfor
  elseif a:e == 4
    call s:StepDown()
  elseif a:e == 5
    while s:Fits(s:x, s:y + 1, s:r)
      let s:y += 1
    endwhile
    call s:Lock()
  else
    return 0
  endif
  return 1
endfunction

" ---- drawing ---------------------------------------------------------------------
let s:title = 'V I M T R I S'
let s:indent = '   '
let s:frame_line = s:B('│') . repeat(' ', 14) . s:B('│')
let s:keys = [['← a', 'move left'], ['→ d', 'move right'], ['↑ w', 'rotate'],
      \ ['↓ s', 'soft drop'], ['␣ z', 'hard drop'], ['  q', 'quit']]

" The side-panel text for board rows 0..19.
function! s:Panel() abort
  let p = repeat([''], 20)
  let p[0] = s:indent . s:B('╭──') . ' ' . s:D('next') . ' ' . s:B('──────╮')
  let p[1] = s:indent . s:frame_line
  let m = s:masks[s:next][0]
  for y in range(4)
    let row = ''
    for x in range(4)
      let row .= and(m, 1 << (y * 4 + x)) ? s:blocks[s:next] : '  '
    endfor
    let p[2 + y] = s:indent . s:B('│') . '   ' . row . '   ' . s:B('│')
  endfor
  let p[6] = s:indent . s:frame_line
  let p[7] = s:indent . s:B('╰' . repeat('─', 14) . '╯')
  let p[9] = s:indent . s:D('score')
  let p[10] = s:indent . s:E . '[1m' . s:score . s:R
  let p[11] = s:indent . s:D('level') . ' ' . s:E . '[1m' . s:Level() . s:R
        \ . '  ' . s:D('lines') . ' ' . s:E . '[1m' . s:lines . s:R
  let p[13] = s:indent . s:D('controls')
  for i in range(6)
    let p[14 + i] = s:indent . s:E . '[1m' . s:keys[i][0] . s:R . '  ' . s:D(s:keys[i][1])
  endfor
  return p
endfunction

function! s:Render() abort
  let grid = copy(s:board)
  if !s:over
    for [cx, cy] in s:Cells(s:x, s:y, s:r)
      let grid[cy * 10 + cx] = s:cur + 1
    endfor
  endif
  let panel = s:Panel()
  let rows = ['  ' . s:E . '[1;38;5;75m' . s:title . s:R,
        \ ' ' . s:B('╔' . repeat('═', 20) . '╗')]
  for y in range(20)
    if s:over && y == 9
      let body = s:E . '[1;7m     GAME  OVER     ' . s:R
    else
      " Cell value 0..7 indexes [empty] + blocks directly.
      let body = join(map(grid[y * 10 : y * 10 + 9], 's:cellstr[v:val]'), '')
    endif
    call add(rows, ' ' . s:B('║') . body . s:B('║') . panel[y])
  endfor
  call add(rows, ' ' . s:B('╚' . repeat('═', 20) . '╝'))
  " Without the 'b' flag writefile() ends every list item with a newline,
  " so each item is one frame line ending with ESC[K.
  let lines = map(rows, {_, l -> l . s:E . '[K'})
  let lines[0] = s:E . '[H' . lines[0]
  call writefile(lines, '/dev/stdout', 'aS')
endfunction

" ---- main loop -------------------------------------------------------------------
function! s:Start(seed) abort
  let s:seed = a:seed
  let s:cur = s:Rand()
  let s:next = s:Rand()
  call s:Spawn()
  call s:Render()
endfunction

" vimtris.native.vim sources this file for the game and reads the keys itself:
" it gets the functions it needs here, and the stdin loop below doesn't run.
if exists('g:vimtris_native')
  let g:vimtris = {'start': function('s:Start'), 'event': function('s:Event'),
        \ 'render': function('s:Render'), 'over': {-> s:over}}
  finish
endif

call s:Start(str2nr(input('')))
while !s:over
  " input() returns '' at a blank line; at end of input Vim exits by itself.
  let s:line = trim(input(''))
  if s:line ==# ''
    continue
  endif
  let s:ev = str2nr(s:line)
  if s:ev == 9
    break
  endif
  if s:Event(s:ev)
    call s:Render()
  endif
endwhile
qall!
