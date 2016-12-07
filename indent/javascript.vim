" Vim indent file
" Language: Javascript
" Maintainer: Chris Paul ( https://github.com/bounceme )
" URL: https://github.com/pangloss/vim-javascript
" Last Change: December 7, 2016

" Only load this indent file when no other was loaded.
if exists('b:did_indent')
  finish
endif
let b:did_indent = 1

" Now, set up our indentation expression and keys that trigger it.
setlocal indentexpr=GetJavascriptIndent()
setlocal autoindent nolisp nosmartindent
setlocal indentkeys+=0],0)

let b:undo_indent = 'setlocal indentexpr< smartindent< autoindent< indentkeys<'

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

let s:case_stmt = '\<\%(case\>\s*[^ \t:].*\|default\s*\):\C'

" Regex of syntax group names that are or delimit string or are comments.
let s:syng_strcom = 'string\|comment\|regex\|special\|doc\|template'
let s:syng_str = 'string\|template'
let s:syng_com = 'comment\|doc'
" Expression used to check whether we should skip a match with searchpair().
let s:skip_expr = "synIDattr(synID(line('.'),col('.'),0),'name') =~? '".s:syng_strcom."'"

function s:skip_func()
  if !s:free || search('`\|\*\/','nW',s:looksyn)
    let s:free = !eval(s:skip_expr)
    let s:looksyn = s:free ? line('.') : s:looksyn
    return !s:free
  endif
  let s:looksyn = line('.')
  return (search('\/','nbW',s:looksyn) || search('[''"\\]','nW',s:looksyn)) && eval(s:skip_expr)
endfunction

function s:alternatePair(stop)
  while search('[][(){}]','bW',a:stop)
    if !s:skip_func()
      let idx = stridx('])}',s:looking_at())
      if idx + 1
        if !s:GetPair(['\[','(','{'][idx], '])}'[idx],'bW','s:skip_func()',2000,a:stop)
          break
        endif
      else
        return
      endif
    endif
  endwhile
  call cursor(v:lnum,1)
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

function s:looking_at()
  return getline('.')[col('.')-1]
endfunction

function s:token()
  return s:looking_at() =~ '\k' ? expand('<cword>') : s:looking_at()
endfunction

" NOTE: moves the cursor
function s:previous_token()
  let l:ln = line('.')
  return search('.\>\|[^[:alnum:][:space:]_$]','bW') ?
        \ (s:looking_at() == '/' || line('.') != l:ln && getline('.') =~ '\/\/') &&
        \ synIDattr(synID(line('.'),col('.'),0),'name') =~? s:syng_com ?
        \ search('\_[^/]\zs\/[/*]','bW') ? s:previous_token() : ''
        \ : s:token()
        \ : ''
endfunction

" configurable regexes that define continuation lines, not including (, {, or [.
let s:opfirst = '^' . get(g:,'javascript_opfirst',
      \ '\%([<>=,?^%|*/&]\|\([-.:+]\)\1\@!\|!=\|in\%(stanceof\)\=\>\)')
let s:continuation = get(g:,'javascript_continuation',
      \ '\%([<=,.~!?/*^%|&:]\|+\@<!+\|-\@<!-\|=\@<!>\|\%(\.\s*\)\@<!\<\%(typeof\|delete\|void\|in\|instanceof\)\)') . '$'

" get the line of code stripped of comments. if called with two args, leave
" cursor at the last non-comment char.
function s:Trim(ln,...)
  let pline = substitute(getline(a:ln),'\s*$','','')
  let l:max = max([match(pline,'.*[^/]\zs\/[/*]'),0])
  while l:max && synIDattr(synID(a:ln, strlen(pline), 0), 'name') =~? s:syng_com
    let pline = substitute(strpart(pline, 0, l:max),'\s*$','','')
    let l:max = max([match(pline,'.*[^/]\zs\/[/*]'),0])
  endwhile
  return !a:0 || cursor(a:ln,strlen(pline)) ? pline : pline
endfunction

function s:OneScope(lnum)
  let pline = s:Trim(a:lnum,1)
  if pline[-1:] == ')' && s:GetPair('(', ')', 'bW', s:skip_expr, 100) > 0
    let token = s:previous_token()
    if index(split('await each'),token) + 1
      return s:previous_token() ==# 'for'
    endif
    return index(split('for if let while with'),token) + 1
  endif
  return pline =~# '\%(\%(\.\s*\)\@<!\<\%(else\|do\)\|=>\)$'
endfunction

function s:iscontOne(i,num,cont)
  let [l:i, l:cont, l:num] = [a:i, a:cont, a:num + !a:num]
  let pind = a:num ? indent(l:num) + s:W : 0
  let ind = indent(l:i) + (a:cont ? 0 : s:W)
  let bL = 0
  while l:i >= l:num && (!l:cont || ind > pind)
    if indent(l:i) < ind " first line always true for !a:cont, false for !!a:cont
      if s:OneScope(l:i)
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
function s:IsBlock()
  let l:ln = line('.')
  let char = s:previous_token()
  let syn = char =~ '[{>/]' ? synIDattr(synID(line('.'),col('.')-(char == '{'),0),'name') : ''
  if syn =~? 'xml\|jsx'
    return char != '{'
  elseif char =~ '\k'
    return index(split('return const let import export yield default delete var void typeof throw new in instanceof')
          \ ,char) < (0 + (line('.') != l:ln)) || s:previous_token() == '.'
  elseif char == '>'
    return getline('.')[col('.')-2] == '=' || syn =~? '^jsflow'
  elseif char == ':'
    return !cursor(0,match(' ' . strpart(getline('.'),0,col('.')),'.*\zs' . s:case_stmt . '$')) &&
          \ (expand('<cword>') !=# 'default' || s:previous_token() !~ '[{,.]')
  endif
  return syn =~? 'regex' || char !~ '[-=~!<*+,/?^%|&([]'
endfunction

" Find line above 'lnum' that isn't empty or in a comment
function s:PrevCodeLine(lnum)
  let l:n = prevnonblank(a:lnum)
  while getline(l:n) =~ '^\s*\/[/*]' || synIDattr(synID(l:n,1,0),'name') =~?
        \ s:syng_com
    let l:n = prevnonblank(l:n-1)
  endwhile
  return l:n
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
        return
      endif
    endif
    let pos = match(l:line, '[][(){}]', pos + 1)
  endwhile
  return !l:open
endfunction

function GetJavascriptIndent()
  let b:js_cache = get(b:,'js_cache',[0,0,0])
  " Get the current line.
  let l:line = getline(v:lnum)
  let syns = synIDattr(synID(v:lnum, 1, 0), 'name')

  " start with strings,comments,etc.
  if syns =~? s:syng_com
    if l:line =~ '^\s*\*'
      return cindent(v:lnum)
    elseif l:line !~ '^\s*\/[/*]'
      return -1
    endif
  elseif syns =~? s:syng_str && l:line !~ '^[''"]'
    if b:js_cache[0] == v:lnum - 1 && s:Balanced(v:lnum-1)
      let b:js_cache[0] = v:lnum
    endif
    return -1
  endif
  let l:lnum = s:PrevCodeLine(v:lnum - 1)
  if !l:lnum
    return
  endif

  let l:line = substitute(l:line,'^\s*','','')
  if l:line[:1] == '/*'
    let l:line = substitute(l:line,'^\%(\/\*.\{-}\*\/\s*\)*','','')
  endif
  if l:line =~ '^\/[/*]'
    let l:line = ''
  endif

  " the containing paren, bracket, or curly. Many hacks for performance
  call cursor(v:lnum,1)
  let idx = strlen(l:line) ? stridx('])}',l:line[0]) : -1
  if b:js_cache[0] >= l:lnum && b:js_cache[0] < v:lnum &&
        \ (b:js_cache[0] > l:lnum || s:Balanced(l:lnum))
    call call('cursor',b:js_cache[1:])
  else
    let [s:looksyn, s:free, top] = [v:lnum - 1, 1, (!indent(l:lnum) &&
          \ synIDattr(synID(l:lnum,1,0),'name') !~? s:syng_str) * l:lnum]
    if idx + 1
      call s:GetPair(['\[','(','{'][idx], '])}'[idx],'bW','s:skip_func()',2000,top)
    elseif indent(v:lnum) && syns =~? 'block'
      call s:GetPair('{','}','bW','s:skip_func()',2000,top)
    else
      call s:alternatePair(top)
    endif
  endif

  if idx + 1
    if idx == 2 && search('\S','bW',line('.')) && s:looking_at() == ')'
      call s:GetPair('(',')','bW',s:skip_expr,200)
    endif
    return indent('.')
  endif

  let b:js_cache = [v:lnum] + (line('.') == v:lnum ? [0,0] : getpos('.')[1:2])
  let num = b:js_cache[1]

  let [s:W, isOp, bL, switch_offset] = [s:sw(),0,0,0]
  if !num || s:looking_at() == '{' && s:IsBlock()
    let pline = s:Trim(l:lnum)
    if num && s:looking_at() == ')' && s:GetPair('(', ')', 'bW', s:skip_expr, 100) > 0
      let num = line('.')
      if s:previous_token() ==# 'switch'
        let switch_offset = &cino !~ ':' || !has('float') ? s:W :
              \ float2nr(str2float(matchstr(&cino,'.*:\zs[-0-9.]*')) * (&cino =~# '\%(.*:\)\@>[^,]*s' ? s:W : 1))
        if pline[-1:] != '.' && l:line =~# '^' . s:case_stmt
          return indent(num) + switch_offset
        elseif pline =~# s:case_stmt . '$'
          return indent(l:lnum) + s:W
        endif
      endif
    endif
    if pline[-1:] !~ '[{;]'
      let isOp = l:line =~# s:opfirst || pline =~# s:continuation &&
            \ synIDattr(synID(l:lnum,match(' ' . pline,'\/$'),0),'name') !~? 'regex'
      let bL = s:iscontOne(l:lnum,num,isOp)
      let bL -= (bL && l:line[0] == '{') * s:W
    endif
  endif

  " main return
  if isOp
    return (num ? indent(num) : -s:W) + (s:W * 2) + switch_offset + bL
  elseif num
    return indent(num) + s:W + switch_offset + bL
  endif
  return bL
endfunction

let &cpo = s:cpo_save
unlet s:cpo_save
