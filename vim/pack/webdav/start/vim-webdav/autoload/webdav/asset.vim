" autoload/webdav/asset.vim - Clipboard image upload and asset:// references
"
" The Obsidian plugin obsidian-asset-manager stores note attachments on a
" dedicated WebDAV server and references them as `![](asset://<path>)`. This
" module writes the same files under the same names so both clients dedup
" against each other, and reads the same references back so `gx` can open one.
"
" Naming, hashing and the reference shape are owned by that plugin. The tables
" in doc/webdav.txt name the source files; changing anything here without
" changing it there splits the two clients apart.

" asset-manager slugify(): keeps unicode, strips only path-hostile characters.
" Two deliberate divergences from the original, both harmless for note titles:
" JS slices 48 UTF-16 code units where strcharpart() counts characters (equal
" below U+10000), and JS \s covers every unicode space where Vim's covers
" space and tab.
function! webdav#asset#slugify(text) abort
  let s = trim(a:text)
  let s = substitute(s, '[/\\:*?"<>|#%[\]]\+', ' ', 'g')
  let s = substitute(s, '\s\+', '-', 'g')
  let s = substitute(s, '-\+', '-', 'g')
  let s = substitute(s, '^[-.]\+', '', '')
  let s = substitute(s, '[-.]\+$', '', '')
  let s = strcharpart(s, 0, 48)
  return substitute(s, '-\+$', '', '')
endfunction

" asset-manager noteAssetSlug(): the note's immediate parent folder name and
" its basename, joined by a space. At the vault root it is the basename alone.
function! webdav#asset#note_slug(ctx) abort
  let parent = fnamemodify(substitute(a:ctx.dir, '/\+$', '', ''), ':t')
  let base = fnamemodify(a:ctx.name, ':t:r')
  return empty(parent) ? base : parent . ' ' . base
endfunction

" asset-manager buildAssetPath(): <prefix>/<slug>-<hash8>.<ext>, falling back
" to <prefix>/<hash16>.<ext> when there is no slug. The hash covers the bytes
" that get stored, so re-pasting the same image resolves to the same path.
function! webdav#asset#build_path(pattern, slug, file, ext) abort
  let slug = webdav#asset#slugify(a:slug)
  let hash = strpart(sha256(readblob(a:file)), 0, empty(slug) ? 16 : 8)
  let base = empty(slug) ? hash : slug . '-' . hash
  let dir = webdav#asset#prefix(a:pattern)
  return empty(dir) ? base . '.' . a:ext : dir . '/' . base . '.' . a:ext
endfunction

" Folder under the asset root, strftime-expanded and free of edge slashes.
function! webdav#asset#prefix(pattern) abort
  let dir = strftime(get(a:pattern, 'prefix', '%Y/%m'))
  return substitute(substitute(dir, '^/\+', '', ''), '/\+$', '', '')
endfunction

" asset-manager pathToRef(): the store qualifier appears only for a store that
" is not the default one.
function! webdav#asset#ref(path, store) abort
  let clean = substitute(a:path, '^/\+', '', '')
  return 'asset://' . (empty(a:store) ? '' : a:store . '@') . clean
endfunction

" asset-manager parseRef(): everything before the first '@' names a store.
function! webdav#asset#parse_ref(ref) abort
  let body = substitute(substitute(a:ref, '^asset://', '', ''), '^/\+', '', '')
  let at = stridx(body, '@')
  if at == -1
    return {'store': '', 'path': body}
  endif
  return {'store': strpart(body, 0, at), 'path': strpart(body, at + 1)}
endfunction

function! s:pattern(name) abort
  let patterns = get(g:, 'webdav_asset_patterns', {})
  if empty(patterns)
    echoerr 'Error: g:webdav_asset_patterns not configured'
    return {}
  endif
  if !has_key(patterns, a:name)
    echoerr "Error: Asset pattern '" . a:name . "' not found"
    echo 'Available patterns: ' . join(sort(keys(patterns)), ', ')
    return {}
  endif
  let pattern = patterns[a:name]
  if !has_key(pattern, 'server')
    echoerr "Error: Asset pattern '" . a:name . "' is missing required field (server)"
    return {}
  endif
  return pattern
endfunction

function! s:grab(dest) abort
  let cmd = get(g:, 'webdav_asset_clipboard_cmd', 'pngpaste %s')
  let cmd = substitute(cmd, '%s', escape(shellescape(a:dest), '\&~'), 'g')
  call webdav#core#debug_log('DEBUG ASSET: clipboard cmd = ' . cmd)
  call system(cmd)
  return v:shell_error == 0 && filereadable(a:dest) && getfsize(a:dest) > 0
endfunction

" Encode to webp, shrinking only images wider than max_width. -size is a second
" pass rather than the first because it aims *at* the target and would raise the
" quality of an already-small image to reach it.
function! s:to_webp(src, pattern) abort
  if !executable('cwebp')
    return ''
  endif

  let dest = tempname() . '.webp'
  let base = printf('cwebp -quiet -resize_mode down_only -resize %d 0 ',
        \ get(a:pattern, 'max_width', 2048))
  let tail = ' ' . shellescape(a:src) . ' -o ' . shellescape(dest)

  call system(base . printf('-q %d', get(a:pattern, 'quality', 82)) . tail)
  if v:shell_error != 0 || !filereadable(dest)
    return ''
  endif

  let target = get(a:pattern, 'target_bytes', 512000)
  if target > 0 && getfsize(dest) > target
    call system(base . printf('-size %d', target) . tail)
    if v:shell_error != 0 || !filereadable(dest)
      return ''
    endif
  endif

  return dest
endfunction

" asset-manager collectionChain(): MKCOL every ancestor from the top down, so a
" root that does not exist yet is created on the first write. An existing
" collection answers 405, which is success here.
function! webdav#asset#mkcol_p(dir, server_info) abort
  let cur = ''
  for seg in filter(split(a:dir, '/'), '!empty(v:val)')
    let cur .= '/' . seg
    let cmd = webdav#http#build_request('MKCOL', cur . '/', a:server_info)
    if empty(cmd)
      return 0
    endif

    let result = webdav#http#execute(cmd)
    if !result.success
      echoerr 'Error creating collection: HTTP request failed'
      echoerr result.response
      return 0
    endif

    let code = webdav#core#extract_http_code(result.response)
    if code != 405 && code != 301 && (code < 200 || code >= 300)
      echoerr 'Error creating collection ' . cur . ': HTTP ' . code
      return 0
    endif
  endfor
  return 1
endfunction

function! s:put(path, file, server_info) abort
  let cmd = webdav#http#build_request('PUT', a:path, a:server_info, a:file, '', '')
  if empty(cmd)
    return 0
  endif

  let result = webdav#http#execute(cmd)
  if !result.success
    echoerr 'Error uploading asset: HTTP request failed'
    echoerr result.response
    return 0
  endif

  let code = webdav#core#extract_http_code(result.response)
  if code < 200 || code >= 300
    echoerr 'Error uploading asset: HTTP ' . code
    return 0
  endif
  return 1
endfunction

" Put text at the cursor column and leave the cursor after it, so a repeated
" paste in insert mode keeps going forward.
function! s:insert(text) abort
  let col = col('.') - 1
  let line = getline('.')
  call setline('.', strpart(line, 0, col) . a:text . strpart(line, col))
  call cursor(line('.'), col + len(a:text) + 1)
endfunction

" Upload the clipboard image and reference it at the cursor.
function! webdav#asset#paste(...) abort
  let name = (a:0 > 0 && !empty(trim(a:1))) ? trim(a:1) : 'default'
  let pattern = s:pattern(name)
  if empty(pattern)
    return
  endif

  let ctx = webdav#buffer#context()
  if empty(ctx) || ctx.kind !=# 'file'
    echo 'Not a WebDAV document buffer'
    return
  endif

  let server_info = webdav#server#get_info(pattern.server)
  if empty(server_info)
    return
  endif

  let grabbed = tempname() . '.png'
  let converted = ''
  try
    if !s:grab(grabbed)
      echohl WarningMsg
      echo 'No image on the clipboard'
      echohl None
      return
    endif

    let converted = s:to_webp(grabbed, pattern)
    let upload = empty(converted) ? grabbed : converted
    let ext = empty(converted) ? 'png' : 'webp'
    if empty(converted)
      echohl WarningMsg
      echo 'cwebp unavailable or failed - uploading the original'
      echohl None
    endif

    let path = webdav#asset#build_path(
          \ pattern, webdav#asset#note_slug(ctx), upload, ext)

    " An existing path means identical bytes, so the upload is already done.
    if webdav#http#file_exists('/' . path, server_info) != 1
      if !webdav#asset#mkcol_p(webdav#asset#prefix(pattern), server_info)
        return
      endif
      echo 'Uploading ' . path . ' ...'
      if !s:put('/' . path, upload, server_info)
        return
      endif
      call webdav#cache#invalidate(pattern.server, server_info, '/' . path)
    endif

    call s:insert('![](' . webdav#asset#ref(path, get(pattern, 'store', '')) . ')')
    echo 'Asset: ' . path
  finally
    call delete(grabbed)
    if !empty(converted)
      call delete(converted)
    endif
  endtry
endfunction

" Paste, or upload the clipboard image when there is nothing to paste.
"
" A terminal never hands Cmd-V to vim: it pastes the clipboard's text as key
" input, and an image has no text, so nothing arrives. What does arrive is p,
" and with clipboard=unnamed(plus) an image leaves the register empty, so p
" would be a no-op. Spend it on the upload instead. Reading the register costs
" nothing, unlike asking the OS what the clipboard holds.
function! webdav#asset#put(key) abort
  if empty(getreg(v:register))
    call webdav#asset#paste()
    return
  endif
  execute 'normal! "' . v:register . v:count1 . a:key
endfunction

" The asset:// reference the cursor sits on, in either the markdown embed/link
" form that asset-manager renders or a bare mention.
function! webdav#asset#ref_at_cursor() abort
  let line = getline('.')
  let col = col('.') - 1

  " Mirrors assetRefRegex(): only the embed/link form counts as a reference.
  let start = 0
  while 1
    let m = matchstrpos(line, '!\=\[[^]]*\](asset://[^)[:space:]]\+)', start)
    if m[1] < 0
      break
    endif
    if col >= m[1] && col < m[2]
      return matchstr(m[0], 'asset://[^)[:space:]]\+')
    endif
    let start = m[2]
  endwhile

  let m = matchstrpos(line, 'asset://[^)[:space:]]\+', 0)
  while m[1] >= 0
    if col >= m[1] && col < m[2]
      return m[0]
    endif
    let m = matchstrpos(line, 'asset://[^)[:space:]]\+', m[2])
  endwhile

  return ''
endfunction

" A store qualifier names either a pattern's 'store' value or a pattern itself;
" no qualifier means the default store, which is the 'default' pattern.
function! s:pattern_for_store(store) abort
  if empty(a:store)
    return s:pattern('default')
  endif

  for name in sort(keys(get(g:, 'webdav_asset_patterns', {})))
    if get(g:webdav_asset_patterns[name], 'store', '') ==# a:store
      return s:pattern(name)
    endif
  endfor

  return s:pattern(a:store)
endfunction

" Everything needed to fetch what a reference points at: the URL, the server
" for its credentials, and the file name. Empty when the store has no pattern.
function! s:resolve(ref) abort
  let parsed = webdav#asset#parse_ref(a:ref)
  let pattern = s:pattern_for_store(parsed.store)
  if empty(pattern)
    return {}
  endif

  let server_info = webdav#server#get_info(pattern.server)
  if empty(server_info)
    return {}
  endif

  return {'url': server_info.url . webdav#core#url_encode('/' . parsed.path),
        \ 'server_info': server_info,
        \ 'name': fnamemodify(parsed.path, ':t')}
endfunction

" Resolve an asset:// reference to the URL that serves it.
function! webdav#asset#url(ref) abort
  let resolved = s:resolve(a:ref)
  return empty(resolved) ? '' : resolved.url
endfunction

let s:plugin_root = fnamemodify(resolve(expand('<sfile>:p')), ':h:h:h')

" Rendering is the slow part (a fetch plus two subprocesses), and a reference
" always points at the same bytes, so a rendered picture never goes stale.
let s:preview_cache = {}

" A glance closes on whatever the reader presses next, so the key is swallowed
" rather than acted on.
function! s:preview_filter(id, key) abort
  call popup_close(a:id)
  return 1
endfunction

" The six levels of the xterm colour cube, which are not evenly spaced.
let s:CUBE = [0, 95, 135, 175, 215, 255]

function! s:cube_hex(index) abort
  return printf('#%02x%02x%02x',
        \ s:CUBE[a:index / 36], s:CUBE[(a:index / 6) % 6], s:CUBE[a:index % 6])
endfunction

" One highlight group per colour pair the picture actually uses. A screenshot
" at this size needs a few hundred, and the names are derived from the colours
" so a second picture reuses whatever it shares with the first.
function! s:pair_type(fg, bg) abort
  let name = printf('WebdavAssetC%d_%d', a:fg, a:bg)
  if empty(prop_type_get(name))
    execute printf('highlight %s ctermfg=%d ctermbg=%d guifg=%s guibg=%s',
          \ name, a:fg + 16, a:bg + 16, s:cube_hex(a:fg), s:cube_hex(a:bg))
    call prop_type_add(name, {'highlight': name})
  endif
  return name
endfunction

" Turn "top,bottom" cube indices into popup lines of upper half blocks, each
" cell coloured by a text property. The block paints its top half in the
" foreground and its bottom half in the background, so one cell shows two
" pixels.
function! s:color_lines(rows) abort
  let block = "▀"
  let width = strlen(block)
  let out = []

  for row in a:rows
    let cells = split(row)
    let props = []
    let col = 1
    for cell in cells
      let pair = split(cell, ',')
      call add(props, {'col': col, 'length': width,
            \ 'type': s:pair_type(str2nr(pair[0]), str2nr(pair[1]))})
      let col += width
    endfor
    call add(out, {'text': repeat(block, len(cells)), 'props': props})
  endfor

  return out
endfunction

" Show the asset:// reference under the cursor as block text in a popup. It is
" a glance, not a viewer: any key or a cursor move closes it, and gx opens the
" real file. A popup draws text, so the image arrives as five shades of block.
function! webdav#asset#preview() abort
  let ref = webdav#asset#ref_at_cursor()
  if empty(ref)
    echo 'No asset:// reference under cursor'
    return
  endif

  if !has('popupwin')
    echoerr 'Error: this vim has no popup support'
    return
  endif
  if !executable('magick')
    echoerr 'Error: magick (ImageMagick) is not installed'
    return
  endif

  " asset-manager's IMAGE_EXT (src/asset/kind.ts). A PDF would need ghostscript
  " and is what gx is for.
  let ext = tolower(fnamemodify(webdav#asset#parse_ref(ref).path, ':e'))
  if index(['png', 'jpg', 'jpeg', 'gif', 'webp', 'svg', 'avif', 'bmp'], ext) < 0
    echo 'Not an image: ' . ext . ' (gx opens it)'
    return
  endif

  let resolved = s:resolve(ref)
  if empty(resolved)
    return
  endif

  let width = get(g:, 'webdav_asset_preview_width', 48)
  let style = get(g:, 'webdav_asset_preview_style', 'color')
  let key = ref . ':' . width . ':' . style
  if !has_key(s:preview_cache, key)
    let auth = empty(resolved.server_info.user) ? ''
          \ : '-u ' . shellescape(resolved.server_info.user . ':' . resolved.server_info.pass)
    let cmd = printf('%s %s %d %s %s',
          \ shellescape(s:plugin_root . '/scripts/img-preview.sh'),
          \ shellescape(resolved.url), width, shellescape(auth), shellescape(style))

    echo 'Rendering ' . resolved.name . ' ...'
    let lines = systemlist(cmd)
    if v:shell_error != 0 || empty(lines)
      echoerr 'Error rendering ' . resolved.name
      return
    endif
    let s:preview_cache[key] = style ==# 'color' ? s:color_lines(lines) : lines
  endif

  call popup_atcursor(s:preview_cache[key], {
        \ 'title': ' ' . resolved.name . ' ',
        \ 'border': [],
        \ 'padding': [0, 1, 0, 1],
        \ 'moved': 'any',
        \ 'filter': function('s:preview_filter'),
        \ 'mapping': 0,
        \ })
endfunction

" Open the asset:// reference under the cursor in the system browser. The URL
" carries no credentials, so a server behind Basic auth prompts there.
function! webdav#asset#open() abort
  let ref = webdav#asset#ref_at_cursor()
  if empty(ref)
    echo 'No asset:// reference under cursor'
    return
  endif

  let url = webdav#asset#url(ref)
  if empty(url)
    return
  endif

  let opener = executable('open') ? 'open' : (executable('xdg-open') ? 'xdg-open' : '')
  if empty(opener)
    echoerr 'Error: no opener found (open, xdg-open)'
    return
  endif

  call system(opener . ' ' . shellescape(url))
  if v:shell_error != 0
    echoerr 'Error opening ' . url
    return
  endif
  echo 'Opened: ' . url
endfunction
