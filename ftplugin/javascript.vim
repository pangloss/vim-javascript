" Vim filetype plugin file
" Language:     JavaScript
" Maintainer:   vim-javascript community
" URL:          https://github.com/pangloss/vim-javascript

setlocal suffixesadd+=.js

if v:version == 703 && exists('&regexpengine') || v:version == 704 && !has('patch2')
  set regexpengine=1
endif
