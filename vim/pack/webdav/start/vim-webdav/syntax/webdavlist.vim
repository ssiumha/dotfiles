" Vim syntax file
" Language: WebDAV Directory Listing
" Maintainer: vim-webdav
" Last Change: 2025

if exists("b:current_syntax")
  finish
endif

" Header comments (lines starting with ")
syntax match webdavComment '^".*$'

" Action items (special commands)
syntax match webdavAction '^+New$\|^+Folder$'

" Parent directory
syntax match webdavParent '^\.\./\?$'

" Directories (lines ending with /)
syntax match webdavDirectory '^[^"[:space:]].*/$'

" Files (everything else that's not a comment)
syntax match webdavFile '^[^"[:space:]][^/]*$'

" Link syntax groups to standard highlighting
highlight default link webdavComment Comment
highlight default link webdavParent Special
highlight default link webdavDirectory Directory
highlight default link webdavAction Title
highlight default link webdavFile Normal

let b:current_syntax = "webdavlist"
