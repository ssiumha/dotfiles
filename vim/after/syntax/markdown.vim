" Rainbow column highlighting + border conceal for markdown tables (MacVim only)
if !has('gui_macvim') | finish | endif

setlocal conceallevel=2 concealcursor=nc

" Rainbow palette (jellybeans-friendly)
let s:colors = ['#e06c75', '#98c379', '#61afef', '#c678dd', '#e5c07b', '#56b6c2']
for s:i in range(len(s:colors))
  execute printf('highlight mkdTblRainbow%d guifg=%s', s:i, s:colors[s:i])
endfor

" Pipe → │ (dimmed)
syntax match mkdTblPipe /|/ contained conceal cchar=│
highlight mkdTblPipe guifg=#555555

" Separator line: ─ for dashes, dim
syntax match mkdTblDash /-/ contained conceal cchar=─
highlight link mkdTblDash mkdTblPipe
syntax match mkdTblColon /:/ contained conceal cchar=·
highlight link mkdTblColon mkdTblPipe

" Column cells (up to 8 columns, cycling 6 colors)
for s:i in range(8)
  let s:skip = repeat('[^|]*|', s:i)
  execute printf('syntax match mkdTblCell%d /^|%s\zs[^|]\+/ contained', s:i, s:skip)
  execute printf('highlight link mkdTblCell%d mkdTblRainbow%d', s:i, s:i % len(s:colors))
endfor

" Data row (defined first → lower priority)
syntax match mkdTblDataRow /^|.\+|$/ transparent
      \ contains=mkdTblPipe,mkdTblCell0,mkdTblCell1,mkdTblCell2,mkdTblCell3,mkdTblCell4,mkdTblCell5,mkdTblCell6,mkdTblCell7

" Separator line (defined last → wins over data row on separator lines)
syntax match mkdTblSepLine /^|\([: -]*|\)\+$/ contains=mkdTblPipe,mkdTblDash,mkdTblColon
