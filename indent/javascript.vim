" Vim indent file
" Language: Javascript
" Maintainer: Chris Paul ( https://github.com/bounceme )
" URL: https://github.com/pangloss/vim-javascript
" Last Change: April 25, 2017

" Only load this indent file when no other was loaded.
if exists('b:did_indent')
  finish
endif
let b:did_indent = 1

" indent correctly if inside <script>
" vim/vim@690afe1 for the switch from cindent
let b:html_indent_script1 = 'inc'

" Now, set up our indentation expression and keys that trigger it.
setlocal indentexpr=GetJavascriptIndent()
setlocal autoindent nolisp nosmartindent
setlocal indentkeys+=0],0)
" Testable with something like:
" vim  -eNs "+filetype plugin indent on" "+syntax on" "+set ft=javascript" \
"       "+norm! gg=G" '+%print' '+:q!' testfile.js \
"       | diff -uBZ testfile.js -

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
    return &l:shiftwidth == 0 ? &l:tabstop : &l:shiftwidth
  endfunction
endif

" Performance for forwards search(): start search at pos rather than masking
" matches before pos.
let s:z = has('patch-7.4.984') ? 'z' : ''

" searchpair() wrapper
if has('reltime')
  function s:GetPair(start,end,flags,skip,time,...)
    return searchpair('\m'.a:start,'','\m'.a:end,a:flags,a:skip,max([prevnonblank(v:lnum) - 2000,0] + a:000),a:time)
  endfunction
else
  function s:GetPair(start,end,flags,skip,...)
    return searchpair('\m'.a:start,'','\m'.a:end,a:flags,a:skip,max([prevnonblank(v:lnum) - 1000,get(a:000,1)]))
  endfunction
endif

" Regex of syntax group names that are or delimit string or are comments.
let s:syng_strcom = 'string\|comment\|regex\|special\|doc\|template\%(braces\)\@!'
let s:syng_str = 'string\|template\|special'
let s:syng_com = 'comment\|doc'
" Expression used to check whether we should skip a match with searchpair().
let s:skip_expr = "synIDattr(synID(line('.'),col('.'),0),'name') =~? '".s:syng_strcom."'"

function s:parse_cino(f)
  let pv = matchstr(&cino,'\C.*'.a:f.'\zs-\=\d*\%(\.\d\+\)\=s\=')
  let factor = 1 . repeat(0,strlen(matchstr(pv,'\.\zs\d*')))
  return eval(substitute(join(split(pv,'s',1), '*'.s:W), '^-\=\zs\*\|\.','','g'))
            \ / factor
endfunction

function s:skip_func()
  if getline('.') =~ '\%<'.col('.').'c\/.\{-}\/\|\%>'.col('.').'c[''"]\|\\$'
    return eval(s:skip_expr)
  elseif s:checkIn || search('\m`\|\${\|\*\/','nW'.s:z,s:looksyn)
    let s:checkIn = eval(s:skip_expr)
  endif
  let s:looksyn = line('.')
  return s:checkIn
endfunction

function s:alternatePair(stop)
  let [pos, pat, l:for] = [getpos('.')[1:2], '[][(){};]', 3]
  while search('\m'.pat,'bW',a:stop)
    if s:skip_func() | continue | endif
    let idx = stridx('])};',s:looking_at())
    if idx is 3
      if l:for is 1
        return s:GetPair('{','}','bW','s:skip_func()',2000,a:stop) > 0 || call('cursor',pos)
      endif
      let [pat, l:for] = ['[{}();]', l:for - 1]
    elseif idx + 1
      if s:GetPair(['\[','(','{'][idx], '])}'[idx],'bW','s:skip_func()',2000,a:stop) < 1
        break
      endif
    else
      return
    endif
  endwhile
  call call('cursor',pos)
endfunction

function s:save_pos(f,...)
  let l:pos = getpos('.')[1:2]
  let ret = call(a:f,a:000)
  call call('cursor',l:pos)
  return ret
endfunction

function s:syn_at(l,c)
  return synIDattr(synID(a:l,a:c,0),'name')
endfunction

function s:looking_at()
  return getline('.')[col('.')-1]
endfunction

function s:token()
  return s:looking_at() =~ '\k' ? expand('<cword>') : s:looking_at()
endfunction

function s:previous_token()
  let l:pos = getpos('.')[1:2]
  if search('\m\k\{1,}\|\S','ebW')
    if (strpart(getline('.'),col('.')-2,2) == '*/' || line('.') != l:pos[0] &&
          \ getline('.')[:col('.')-1] =~ '\/\/') && s:syn_at(line('.'),col('.')) =~? s:syng_com
      while search('\m\S\ze\_s*\/[/*]','bW')
        if s:syn_at(line('.'),col('.')) !~? s:syng_com
          return s:token()
        endif
      endwhile
    else
      return s:token()
    endif
  endif
  call call('cursor',l:pos)
  return ''
endfunction

function s:expr_col()
  if getline('.')[col('.')-2] == ':'
    return 1
  endif
  let bal = 0
  while bal < 1 && search('\m[{}?:;]','bW',s:scriptTag)
    if eval(s:skip_expr) | continue | endif
    " switch (looking_at())
    exe {   '}': "if s:GetPair('{','}','bW',s:skip_expr,200) < 1 | return | endif",
          \ ';': "return",
          \ '{': "return getpos('.')[1:2] != b:js_cache[1:] && !s:IsBlock()",
          \ ':': "let bal -= strpart(getline('.'),col('.')-2,3) !~ '::'",
          \ '?': "let bal += 1" }[s:looking_at()]
  endwhile
  return max([bal,0])
endfunction

" configurable regexes that define continuation lines, not including (, {, or [.
let s:opfirst = '^' . get(g:,'javascript_opfirst',
      \ '\C\%([<>=,?^%|*/&]\|\([-.:+]\)\1\@!\|!=\|in\%(stanceof\)\=\>\)')
let s:continuation = get(g:,'javascript_continuation',
      \ '\C\%([-+<>=,.~!?/*^%|&:]\|\<\%(typeof\|new\|delete\|void\|in\|instanceof\|await\)\)') . '$'

function s:continues(ln,con)
  if !cursor(a:ln, match(' '.a:con,s:continuation))
    let teol = s:looking_at()
    if teol == '/'
      return s:syn_at(line('.'),col('.')) !~? 'regex'
    elseif teol == '>'
      return getline('.')[col('.')-2] != '=' && s:syn_at(line('.'),col('.')) !~? 'jsflow\|^html'
    elseif teol =~ '[-+]'
      return getline('.')[col('.')-2] != teol
    elseif teol =~ '\l'
      return s:previous_token() != '.'
    elseif teol == ':'
      return s:expr_col()
    endif
    return 1
  endif
endfunction

function s:Trim(ln)
  let pline = substitute(getline(a:ln),'\s*$','','')
  let l:max = max([strridx(pline,'//'), strridx(pline,'/*')])
  while l:max != -1 && s:syn_at(a:ln, strlen(pline)) =~? s:syng_com
    let pline = pline[: l:max]
    let l:max = max([strridx(pline,'//'), strridx(pline,'/*')])
    let pline = substitute(pline[:-2],'\s*$','','')
  endwhile
  return pline
endfunction

" Find line above 'lnum' that isn't empty or in a comment
function s:PrevCodeLine(lnum)
  let [l:pos, l:n] = [getpos('.')[1:2], prevnonblank(a:lnum)]
  while l:n
    if getline(l:n) =~ '^\s*\/[/*]'
      if (stridx(getline(l:n),'`') > 0 || getline(l:n-1)[-1:] == '\') &&
            \ s:syn_at(l:n,1) =~? s:syng_str
        break
      endif
      let l:n = prevnonblank(l:n-1)
    elseif stridx(getline(l:n), '*/') + 1 && s:syn_at(l:n,1) =~? s:syng_com
      call cursor(l:n,1)
      keepjumps norm! [*
      let l:n = search('\m\S','nbW')
    else
      break
    endif
  endwhile
  call call('cursor',l:pos)
  return l:n
endfunction

" Check if line 'lnum' has a balanced amount of parentheses.
function s:Balanced(lnum)
  let l:open = 0
  let l:line = getline(a:lnum)
  let pos = match(l:line, '[][(){}]', 0)
  while pos != -1
    if s:syn_at(a:lnum,pos + 1) !~? s:syng_strcom
      let l:open += match(' ' . l:line[pos],'[[({]')
      if l:open < 0
        return
      endif
    endif
    let pos = match(l:line, (l:open ?
          \ '['.matchstr(['][','()','{}'],l:line[pos]).']' :
          \ '[][(){}]'), pos + 1)
  endwhile
  return !l:open
endfunction

function s:OneScope(lnum,...)
  let pline = a:0 ? a:1 : s:Trim(a:lnum)
  call cursor(a:lnum,strlen(pline))
  let kw = 'else do'
  if pline[-1:] == ')' && s:GetPair('(', ')', 'bW', s:skip_expr, 100) > 0
    if s:previous_token() =~# '^\%(await\|each\)$'
      call s:previous_token()
      let kw = 'for'
    else
      let kw = 'for if let while with'
    endif
  endif
  return pline[-2:] == '=>' || index(split(kw),s:token()) + 1 &&
        \ s:save_pos('s:previous_token') != '.' && !s:save_pos('s:doWhile')
endfunction

function s:doWhile()
  if expand('<cword>') ==# 'while'
    call search('\m\<','cbW')
    let bal = 0
    while bal < 1 && search('\m\C[{}]\|\<\%(do\|while\)\>','bW')
      if eval(s:skip_expr) | continue | endif
      " switch (looking_at())
      exe {    '}': "if s:GetPair('{','}','bW',s:skip_expr,200) < 1 | return | endif",
            \  '{': "return",
            \  'd': "let bal += s:save_pos('s:IsBlock',1)",
            \  'w': "let bal -= s:save_pos('s:previous_token') != '.'" }[s:looking_at()]
    endwhile
    return max([bal,0])
  endif
endfunction

" returns braceless levels started by 'i' and above lines * &sw. 'num' is the
" lineNr which encloses the entire context, 'cont' if whether line 'i' + 1 is
" a continued expression, which could have started in a braceless context
function s:iscontOne(i,num,cont,cached)
  let [l:i, l:num, bL] = [a:i, a:num + !a:num, 0]
  let pind = a:num ? indent(l:num) + s:W : 0
  let ind = indent(l:i) + (a:cont ? 0 : s:W)
  while l:i >= l:num && (ind > pind || l:i == l:num)
    if indent(l:i) < ind &&
          \ call('s:OneScope',[l:i] + (l:i == a:i ? [a:cached] : []))
      let bL += s:W
      let l:i = line('.')
    elseif !a:cont || bL || ind < indent(a:i)
      break
    endif
    let ind = min([ind, indent(l:i)])
    let l:i = s:PrevCodeLine(l:i - 1)
  endwhile
  return bL
endfunction

" https://github.com/sweet-js/sweet.js/wiki/design#give-lookbehind-to-the-reader
function s:IsBlock(...)
  if a:0 || s:looking_at() == '{'
    let l:n = line('.')
    let char = s:previous_token()
    if match(s:stack,'\cxml\|jsx') + 1 && s:syn_at(line('.'),col('.')-1) =~? 'xml\|jsx'
      return char != '{'
    elseif char =~ '\k'
      if char ==# 'type'
        return s:save_pos('s:previous_token') !~# '^\%(im\|ex\)port$'
      endif
      return index(split('return const let import export extends yield default delete var await void typeof throw case new of in instanceof')
            \ ,char) < (line('.') != l:n) || s:save_pos('s:previous_token') == '.'
    elseif char == '>'
      return getline('.')[col('.')-2] == '=' || s:syn_at(line('.'),col('.')) =~? 'jsflow\|^html'
    elseif char == '*'
      return s:save_pos('s:previous_token') == ':'
    elseif char == ':'
      return !s:save_pos('s:expr_col')
    elseif char == '/'
      return s:syn_at(line('.'),col('.')) =~? 'regex'
    endif
    return char !~ '[=~!<,.?^%|&([]' &&
          \ (char !~ '[-+]' || l:n != line('.') && getline('.')[col('.')-2] == char)
  endif
endfunction

function GetJavascriptIndent()
  let b:js_cache = get(b:,'js_cache',[0,0,0])
  " Get the current line.
  call cursor(v:lnum,1)
  let l:line = getline('.')
  " use synstack as it validates syn state and works in an empty line
  let s:stack = map(synstack(v:lnum,1),"synIDattr(v:val,'name')")
  let syns = get(s:stack,-1,'')

  " start with strings,comments,etc.
  if syns =~? s:syng_com
    if l:line =~ '^\s*\*'
      return cindent(v:lnum)
    elseif l:line !~ '^\s*\/[/*]'
      return -1
    endif
  elseif syns =~? s:syng_str
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
  let s:scriptTag = get(get(b:,'hi_indent',{}),'blocklnr')
  let idx = index([']',')','}'],l:line[0])
  if b:js_cache[0] >= l:lnum && b:js_cache[0] < v:lnum &&
        \ (b:js_cache[0] > l:lnum || s:Balanced(l:lnum))
    if b:js_cache[2]
      call call('cursor',b:js_cache[1:])
    endif
  else
    let [s:looksyn, s:checkIn, top] = [v:lnum - 1, 0, max([s:scriptTag,
          \ (!indent(l:lnum) && s:syn_at(l:lnum,1) !~? s:syng_str) * l:lnum])]
    if idx + 1
      call s:GetPair(['\[','(','{'][idx],'])}'[idx],'bW','s:skip_func()',2000,top)
    elseif getline(v:lnum) !~ '^\S' && syns =~? 'block'
      call s:GetPair('{','}','bW','s:skip_func()',2000,top)
    else
      call s:alternatePair(top)
    endif
  endif

  let b:js_cache = [v:lnum] + (line('.') == v:lnum ? [s:scriptTag,0] : getpos('.')[1:2])
  let num = b:js_cache[1]

  let [s:W, isOp, bL, switch_offset] = [s:sw(),0,0,0]
  if !b:js_cache[2] || s:IsBlock()
    let ilnum = line('.')
    let pline = s:Trim(l:lnum)
    if b:js_cache[2] && s:looking_at() == ')' && s:GetPair('(',')','bW',s:skip_expr,100) > 0
      let num = ilnum == num ? line('.') : num
      if idx < 0 && s:previous_token() ==# 'switch' && s:previous_token() != '.'
        let switch_offset = &cino !~ ':' ? s:W : max([-indent(num),s:parse_cino(':')])
        if pline[-1:] != '.' && l:line =~# '^\%(default\|case\)\>'
          return indent(num) + switch_offset
        endif
      endif
    endif
    if idx < 0 && pline[-1:] !~ '[{;]'
      let isOp = (l:line =~# s:opfirst || s:continues(l:lnum,pline)) * s:W
      let bL = s:iscontOne(l:lnum,b:js_cache[1],isOp,pline)
      let bL -= (bL && l:line[0] == '{') * s:W
    endif
  elseif idx < 0 && getline(b:js_cache[1])[b:js_cache[2]-1] == '(' && &cino =~ '('
    let pval = s:parse_cino('(')
    return !pval || !search('\m\S','nbW',num) && !s:parse_cino('U') ?
          \ (s:parse_cino('w') ? 0 : -!!search('\m\S','W'.s:z,num)) + virtcol('.') :
          \ max([indent('.') + pval + s:GetPair('(',')','nbrmW',s:skip_expr,100,num) * s:W,0])
  endif

  " main return
  if l:line =~ '^[])}]\|^|}'
    return max([indent(num),0])
  elseif num
    return indent(num) + s:W + switch_offset + bL + isOp
  endif
  return bL + isOp
endfunction

let &cpo = s:cpo_save
unlet s:cpo_save
