" autoload the local .vimrc file you need to have
" https://github.com/MarcWeber/vim-addon-local-vimrc
" plugin installed

" clean and reload the plugin files in the current buffer
nnoremap <silent> <Leader>r :
  \ if expand('%:e') ==# 'js' <BAR>
  \   syn clear <BAR>
  \   unlet! b:did_indent <BAR>
  \   unlet! b:current_syntax <BAR>
  \   source ftdetect/javascript.vim <BAR>
  \   source syntax/javascript.vim <BAR>
  \   source indent/javascript.vim <BAR>
  \ endif <CR>


" tells you just what syntax highlighting groups the item under the cursor actually is
nnoremap <silent> <Leader>h :echo
      \ "hi<" . synIDattr(synID(line("."),col("."),1),"name") . "> " .
      \ "trans<" . synIDattr(synID(line("."),col("."),0),"name") . "> " .
      \ "lo<" . synIDattr(synIDtrans(synID(line("."),col("."),1)),"name") . ">"<CR>

" tells you more information about the highlighting group of the item under cursor
source .hilinks.vim
nnoremap <silent> <Leader>t :HLT!<CR>
