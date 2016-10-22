" Vim indent file
" Language: Javascript
" Maintainer: Chris Paul ( https://github.com/bounceme )
" URL: https://github.com/pangloss/vim-javascript
" Last Change: October 19, 2016

" Only load this indent file when no other was loaded.
if exists('b:did_indent')
  finish
endif
let b:did_indent = 1

" Now, set up our indentation expression and keys that trigger it.
setlocal indentexpr=GetJavascriptIndent()
setlocal nolisp noautoindent nosmartindent
setlocal indentkeys=0{,0},0),0],:,!^F,o,O,e
setlocal cinoptions+=j1,J1

let b:undo_indent = 'setlocal indentexpr< smartindent< autoindent< indentkeys< cinoptions<'

" Only define the function once.
if exists('*GetJavascriptIndent')
  finish
endif

let s:cpo_save = &cpo
set cpo&vim

" Get shiftwidth value
if exists('*shiftwidth')
  function s:sw()
    return shiftwidth()
  endfunction
else
  function s:sw()
    return &sw
  endfunction
endif

let s:expr_case = '\<\%(\%(case\>\s*\S.\{-}\)\|default\)\s*:\C'
" Regex of syntax group names that are or delimit string or are comments.
let s:syng_strcom = '\%(s\%(tring\|pecial\)\|comment\|regex\|doc\|template\)'

" Expression used to check whether we should skip a match with searchpair().
let s:skip_expr = "synIDattr(synID(line('.'),col('.'),0),'name') =~? '".s:syng_strcom."'"
function s:skip_func(lnum)
  if !s:free || search('`','nW',a:lnum) || search('\*\/','nW',a:lnum)
    let s:free = !eval(s:skip_expr)
    let s:looksyn = s:free ? line('.') : s:looksyn
    return !s:free
  endif
  let s:looksyn = line('.')
  return (strridx(getline('.'),'/',col('.')-1) + 1 || search('[''"\\]','nW',s:looksyn)) && eval(s:skip_expr)
endfunction

if has('reltime')
  function s:GetPair(start,end,flags,skip,time,...)
    return searchpair(a:start,'',a:end,a:flags,a:skip,max([prevnonblank(v:lnum) - 2000,0] + a:000),a:time)
  endfunction
else
  function s:GetPair(start,end,flags,...)
    return searchpair(a:start,'',a:end,a:flags,"line('.') < prevnonblank(v:lnum) - 2000 ? dummy : 0")
  endfunction
endif

function s:Trimline(ln)
  let pline = substitute(getline(a:ln),'\s*$','','')
  let l:max = max([strridx(pline,'//'),strridx(pline,'/*'),0])
  while l:max && synIDattr(synID(a:ln, strlen(pline), 0), 'name') =~? '\%(comment\|doc\)'
    let pline = substitute(strpart(pline, 0, l:max),'\s*$','','')
    let l:max = max([strridx(pline,'//'),strridx(pline,'/*'),0])
  endwhile
  return pline
endfunction

" configurable regexes that define continuation lines, not including (, {, or [.
let s:opfirst = '^' . get(g:,'javascript_opfirst',
      \ '\%([<>,?^%|*&]\|\/[/*]\@!\|\([-.:+]\)\1\@!\|=>\@!\|in\%(stanceof\)\=\>\)')
let s:continuation = get(g:,'javascript_continuation',
      \ '\%([<=,.?/*^%|&:]\|+\@<!+\|-\@<!-\|=\@<!>\|\<in\%(stanceof\)\=\)') . '$'

function s:OneScope(lnum,text)
  return cursor(a:lnum, match(' ' . a:text, '\%(\<else\|\<do\|=>\)$')) + 1 ||
        \ cursor(a:lnum, match(' ' . a:text, ')$')) + 1 &&
        \ s:GetPair('(', ')', 'bW', s:skip_expr, 100) > 0 &&
        \ search('\C\<\%(for\%(\_s\+\%(await\|each\)\)\=\|if\|let\|w\%(hile\|ith\)\)\_s*\%#','bW')
endfunction

function s:iscontOne(i,num,cont)
  let [l:i, l:cont, l:num] = [a:i, a:cont, a:num + !a:num]
  let pind = a:num ? indent(l:num) : -s:W
  let ind = indent(l:i) + (!l:cont * s:W)
  let bL = 0
  while l:i >= l:num && (!l:cont || ind > pind + s:W)
    if indent(l:i) < ind " first line always true for !a:cont, false for !!a:cont
      if s:OneScope(l:i,s:Trimline(l:i))
        if expand('<cword>') ==# 'while' &&
              \ s:GetPair('\C\<do\>','\C\<while\>','bW','line2byte(line(".")) + col(".") <'
              \ . (line2byte(l:num) + b:js_cache[2]) . '||'
              \ . s:skip_expr . '|| !s:IsBlock()',100,l:num) > 0
          return 0
        endif
        let bL += 1
        let [l:cont, l:i] = [0, line('.')]
      elseif !l:cont
        break
      endif
      let ind = indent(l:i)
    endif
    let l:i = s:PrevCodeLine(l:i - 1)
  endwhile
  return bL * s:W
endfunction

" https://github.com/sweet-js/sweet.js/wiki/design#give-lookbehind-to-the-reader
function s:IsBlock()
  let l:ln = line('.')
  if search('\S','bW')
    let char = getline('.')[col('.')-1]
    let pchar = getline('.')[col('.')-2]
    let syn = synIDattr(synID(line('.'),col('.')-1,0),'name')
    if pchar . char == '*/' && syn =~? 'comment'
      if !search('\/\*','bW') || !search('\S','bW')
        return 1
      endif
      let char = getline('.')[col('.')-1]
      let pchar = getline('.')[col('.')-2]
      let syn = synIDattr(synID(line('.'),col('.')-1,0),'name')
    endif
    if syn =~? '\%(xml\|jsx\)'
      return char != '{'
    elseif char =~# '\l'
      if line('.') == l:ln && expand('<cword>') ==# 'return'
        return 0
      endif
      return index(split('const let import export yield default delete var void typeof throw new in instanceof')
            \ , expand('<cword>')) < 0
    elseif char == '>'
      return pchar == '=' || syn =~? '^jsflow'
    elseif char == ':'
      return strpart(getline('.'),0,col('.')) =~# s:expr_case . '$'
    else
      return stridx('-=~!<*+,/?^%|&([',char) < 0
    endif
  else
    return 1
  endif
endfunction

" Find line above 'lnum' that isn't empty, in a comment, or in a string.
function s:PrevCodeLine(lnum)
  let l:lnum = prevnonblank(a:lnum)
  while l:lnum
    if synIDattr(synID(l:lnum,matchend(getline(l:lnum), '^\s*[^''"`]'),0),'name') !~? s:syng_strcom
      return l:lnum
    endif
    let l:lnum = prevnonblank(l:lnum - 1)
  endwhile
endfunction

" Check if line 'lnum' has a balanced amount of parentheses.
function s:Balanced(lnum)
  let l:open = 0
  let l:line = getline(a:lnum)
  let pos = match(l:line, '[][(){}]', 0)
  while pos != -1
    if synIDattr(synID(a:lnum,pos + 1,0),'name') !~? s:syng_strcom
      if stridx('[({',l:line[pos]) + 1
        let l:open += 1
      else
        let l:open -= 1
        if l:open < 0
          return 0
        endif
      endif
    endif
    let pos = match(l:line, '[][(){}]', pos + 1)
  endwhile
  return !l:open
endfunction

function GetJavascriptIndent()
  try
    let save_magic = &magic
    set magic
  let b:js_cache = get(b:,'js_cache',[0,0,0])
  " Get the current line.
  let l:line = getline(v:lnum)
  let syns = synIDattr(synID(v:lnum, 1, 0), 'name')

  " start with strings,comments,etc.
  if syns =~? '\%(comment\|doc\)'
    if l:line =~ '^\s*\*'
      return cindent(v:lnum)
    elseif l:line !~ '^\s*\/'
      return -1
    endif
  elseif syns =~? '\%(string\|template\)' && l:line !~ '^[''"]'
    return -1
  endif
  let l:lnum = s:PrevCodeLine(v:lnum - 1)
  if !l:lnum
    return 0
  endif

  let l:line = substitute(l:line,'^\s*\%(\/\*.\{-}\*\/\s*\)*','','')

  if l:line =~# '^' . s:expr_case
    let cpo_switch = &cpo
    set cpo+=%
    let ind = cindent(v:lnum)
    let &cpo = cpo_switch
    return ind
  endif

  " the containing paren, bracket, curly. Many hacks for performance
  call cursor(v:lnum,1)
  let idx = strlen(l:line) ? stridx('])}',l:line[0]) : -1
  if indent(l:lnum)
    let [s:looksyn,s:free] = [v:lnum - 1,1]
    if b:js_cache[0] >= l:lnum && b:js_cache[0] < v:lnum &&
          \ (b:js_cache[0] > l:lnum || idx < 0 && s:Balanced(l:lnum))
      let num = b:js_cache[1]
    elseif idx + 1
      return indent(s:GetPair(['\[','(','{'][idx], '])}'[idx],'bW','s:skip_func(s:looksyn)',2000))
    elseif indent(v:lnum) && syns =~? 'block'
      let num = s:GetPair('{','}','bW','s:skip_func(s:looksyn)',2000)
    else
      let num = s:GetPair('[({[]','[])}]','bW','s:skip_func(s:looksyn)',2000)
    endif
  else
    let num = s:GetPair('[({[]','[])}]','bW',s:skip_expr,200,l:lnum)
  endif

  if idx + 1
    return indent(num)
  endif
  let num = max([num,0])
  let b:js_cache = [v:lnum,num,line('.') == v:lnum && num ? b:js_cache[2] : col('.')]

  call cursor(v:lnum,1)
  if l:line =~# '^while\>' && s:GetPair('\C\<do\>','\C\<while\>','bW',s:skip_expr . '|| !s:IsBlock()',100,num + 1) > 0
    return indent(line('.'))
  endif

  let s:W = s:sw()
  let pline = s:Trimline(l:lnum)
  call cursor(b:js_cache[1],b:js_cache[2])
  let bchar = getline('.')[col('.')-1] == '{'
  let switch_offset = !num || !bchar || !(search(')\_s*\%#','bW') &&
        \ s:GetPair('(', ')', 'bW', s:skip_expr, 100) > 0 && search('\C\<switch\_s*\%#','bW')) ? 0 :
        \ &cino !~ ':' || !has('float') ? s:W :
        \ float2nr(str2float(matchstr(&cino,'.*:\zs[-0-9.]*')) * (&cino =~# '.*:[^,]*s' ? s:W : 1))

  " most significant, find the indent amount
  let isOp = l:line =~# s:opfirst || pline !~# s:expr_case . '$' && pline =~# s:continuation
  let bL = s:iscontOne(l:lnum,num,isOp)
  let bL -= (bL && l:line[0] == '{') * s:W
  if isOp && (!num || bchar && cursor(b:js_cache[1],b:js_cache[2])+1 && s:IsBlock())
    return (num ? indent(num) : -s:W) + (s:W * 2) + switch_offset + bL
  elseif num
    return indent(num) + s:W + switch_offset + bL
  endif
  return bL
  
  finally
    let &magic = save_magic
  endtry
endfunction

let &cpo = s:cpo_save
unlet s:cpo_save
