" Vim indent file
" Language: Javascript
" Maintainer: Chris Paul ( https://github.com/bounceme )
" URL: https://github.com/pangloss/vim-javascript
" Last Change: Octember 31, 2016

" Only load this indent file when no other was loaded.
if exists('b:did_indent')
  finish
endif
let b:did_indent = 1

" Now, set up our indentation expression and keys that trigger it.
setlocal indentexpr=GetJavascriptIndent()
setlocal autoindent nolisp nosmartindent
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

let s:expr_case = '\<\%(\%(case\>\s*[^[:blank:]:].\{-}\)\|default\)\s*:\C'
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
  return (search('\/','nbW',s:looksyn) || search('[''"\\]','nW',s:looksyn)) && eval(s:skip_expr)
endfunction

if has('reltime')
  function s:GetPair(start,end,flags,skip,time,...)
    return searchpair(a:start,'',a:end,a:flags,a:skip,max([prevnonblank(v:lnum) - 2000,0] + a:000),a:time)
  endfunction
else
  function s:GetPair(start,end,flags,skip,...)
    return searchpair(a:start,'',a:end,a:flags,a:skip,max([prevnonblank(v:lnum) - 1000,get(a:000,1)]))
  endfunction
endif

function s:current_char()
  return getline('.')[col('.')-1]
endfunction

function s:token()
  return s:current_char() =~ '\w' ? expand('<cword>') : s:current_char()
endfunction

" NOTE: moves the cursor
function s:previous_token()
  return search('\<\|[^[:alnum:]_$[:space:]]','bW') ? s:token() : ''
endfunction

function s:Trim(ln)
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
      \ '\%([<>,?^%|*/&]\|\([-.:+]\)\1\@!\|=>\@!\|in\%(stanceof\)\=\>\)')
let s:continuation = get(g:,'javascript_continuation',
      \ '\%([<=,.?/*^%|&:]\|+\@<!+\|-\@<!-\|=\@<!>\|\<in\%(stanceof\)\=\)') . '$'

function s:OneScope(lnum,text)
  if cursor(a:lnum, match(' ' . a:text, ')$')) + 1 &&
        \ s:GetPair('(', ')', 'bW', s:skip_expr, 100) > 0
    let token = s:previous_token()
    if index(split('await each'),token) + 1
      return s:previous_token() ==# 'for'
    endif
    return index(split('for if let while with'),token) + 1
  endif
  return cursor(a:lnum, match(' ' . a:text, '\%(\<else\|\<do\|=>\)$\C')) + 1
endfunction

function s:iscontOne(i,num,cont)
  let [l:i, l:cont, l:num] = [a:i, a:cont, a:num + !a:num]
  let pind = a:num ? indent(l:num) + s:W : 0
  let ind = indent(l:i) + (a:cont ? 0 : s:W)
  let bL = 0
  while l:i >= l:num && (!l:cont || ind > pind)
    if indent(l:i) < ind " first line always true for !a:cont, false for !!a:cont
      if s:OneScope(l:i,s:Trim(l:i))
        if s:token() ==# 'while' &&
              \ s:GetPair('\C\<do\>','\C\<while\>','bW','line2byte(line(".")) + col(".") <'
              \ . (line2byte(l:num) + b:js_cache[2]) . '||'
              \ . s:skip_expr . '|| !s:IsBlock()',100,l:num) > 0
          return 0
        endif
        let bL += s:W
        let [l:cont, l:i] = [0, line('.')]
      elseif !l:cont
        break
      endif
    elseif !a:cont
      break
    endif
    let ind = min([ind, indent(l:i)])
    let l:i = s:PrevCodeLine(l:i - 1)
  endwhile
  return bL
endfunction

" https://github.com/sweet-js/sweet.js/wiki/design#give-lookbehind-to-the-reader
function s:IsBlock(...)
  let l:ln = get(a:000,0,line('.'))
  if search('\S','bW')
    let char = s:token()
    let syn = synIDattr(synID(line('.'),col('.')-(char == '{'),0),'name')
    if syn =~? '\%(xml\|jsx\)'
      return char != '{'
    elseif syn =~? 'comment'
      return search('\/[/*]','bW') && s:IsBlock(l:ln)
    elseif char == '>'
      return getline('.')[col('.')-2] == '=' || syn =~? '^jsflow'
    elseif char == ':'
      return cursor(0,match(' ' . strpart(getline('.'),0,col('.')),'.*\zs' . s:expr_case . '$')) + 1 &&
            \ (expand('<cword>') !=# 'default' || s:previous_token() !~ '[,{]')
    endif
    return index(split('return const let import export yield default delete var void typeof throw new in instanceof'
          \ . ' - = ~ ! < * + , / ? ^ % | & ( ['), char) < (0 + (line('.') != l:ln))
  endif
  return 1
endfunction

" Find line above 'lnum' that isn't empty, in a comment, or in a string.
function s:PrevCodeLine(lnum)
  let l:lnum = prevnonblank(a:lnum)
  while l:lnum
    let syn = synIDattr(synID(l:lnum,matchend(getline(l:lnum), '^\s*[^''"`]'),0),'name')
    if syn =~? 'html'
      return
    elseif syn !~? s:syng_strcom
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
      let l:open += match(' ' . l:line[pos],'[[({]')
      if l:open < 0
        return 0
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

  let l:line = substitute(substitute(l:line,'^\s*\%(\/\*.\{-}\*\/\s*\)*','',''),'^\/[/*].*','','')

  " the containing paren, bracket, curly. Many hacks for performance
  call cursor(v:lnum,1)
  let idx = strlen(l:line) ? stridx('])}',l:line[0]) : -1
  if indent(l:lnum)
    let [s:looksyn,s:free] = [v:lnum - 1,1]
    if b:js_cache[0] >= l:lnum && b:js_cache[0] < v:lnum &&
          \ (b:js_cache[0] > l:lnum || s:Balanced(l:lnum))
      call call('cursor',b:js_cache[1:])
    elseif idx + 1
      call s:GetPair(['\[','(','{'][idx], '])}'[idx],'bW','s:skip_func(s:looksyn)',2000)
    elseif indent(v:lnum) && syns =~? 'block'
      call s:GetPair('{','}','bW','s:skip_func(s:looksyn)',2000)
    else
      call s:GetPair('[({[]','[])}]','bW','s:skip_func(s:looksyn)',2000)
    endif
  else
    call s:GetPair('[({[]','[])}]','bW',s:skip_expr,200,l:lnum)
  endif

  if idx + 1
    if idx == 2 && search('\S','bW',line('.')) && s:current_char() == ')'
      call s:GetPair('(',')','bW',s:skip_expr,200)
    endif
    return indent(line('.'))
  endif

  let b:js_cache = [v:lnum] + (line('.') == v:lnum ? [0,0] : [line('.'),col('.')])
  let num = b:js_cache[1]

  let [s:W, pline, isOp, stmt, bL, switch_offset] = [s:sw(), s:Trim(l:lnum),0,0,0,0]
  if num 
    if s:current_char() == '{'
      if search(')\_s*\%#','bW')
        let stmt = 1
        if s:GetPair('(', ')', 'bW', s:skip_expr, 100) > 0 && s:previous_token() ==# 'switch'
          let switch_offset = &cino !~ ':' || !has('float') ? s:W :
                \ float2nr(str2float(matchstr(&cino,'.*:\zs[-0-9.]*')) * (&cino =~# '.*:[^,]*s' ? s:W : 1))
          if l:line =~# '^' . s:expr_case
            return indent(num) + switch_offset
          endif
          let stmt = pline !~# s:expr_case . '$'
        endif
      elseif s:IsBlock()
        let stmt = 1
      endif
    endif
  else
    let stmt = 1
  endif

  if stmt
    call cursor(v:lnum,1)
    if l:line =~# '^while\>' && s:GetPair('\C\<do\>','\C\<while\>','bW',s:skip_expr . '|| !s:IsBlock()',100,num + 1) > 0
      return indent(line('.'))
    endif
    let isOp = l:line =~# s:opfirst || pline =~# s:continuation
    let bL = s:iscontOne(l:lnum,num,isOp)
    let bL -= (bL && l:line[0] == '{') * s:W
  endif

  " main return
  if isOp
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
