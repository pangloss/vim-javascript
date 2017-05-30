" Vim indent file
" Language: Javascript
" Maintainer: Chris Paul ( https://github.com/bounceme )
" URL: https://github.com/pangloss/vim-javascript
" Last Change: May 27, 2017

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

" Regex of syntax group names that are or delimit string or are comments.
let b:syng_strcom = get(b:,'syng_strcom','string\|comment\|regex\|special\|doc\|template\%(braces\)\@!')
let b:syng_str = get(b:,'syng_str','string\|template\|special')
" template strings may want to be excluded when editing graphql:
" au! Filetype javascript let b:syng_str = '^\%(.*template\)\@!.*string\|special'
" au! Filetype javascript let b:syng_strcom = '^\%(.*template\)\@!.*string\|comment\|regex\|special\|doc'

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
    return &l:shiftwidth ? &l:shiftwidth : &l:tabstop
  endfunction
endif

" Performance for forwards search(): start search at pos rather than masking
" matches before pos.
let s:z = has('patch-7.4.984') ? 'z' : ''

let s:syng_com = 'comment\|doc'
" Expression used to check whether we should skip a match with searchpair().
let s:skip_expr = "s:syn_at(line('.'),col('.')) =~? b:syng_strcom"

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

function s:syn_at(l,c)
  let pos = join([a:l,a:c],',')
  if has_key(s:synId_cache,pos)
    return s:synId_cache[pos]
  endif
  let s:synId_cache[pos] = synIDattr(synID(a:l,a:c,0),'name')
  return s:synId_cache[pos]
endfunction

function s:parse_cino(f)
  let [cin, divider, n] = [strridx(&cino,a:f), 0, '']
  if cin == -1
    return
  endif
  let [sign, cstr] = &cino[cin+1] == '-' ? [-1, &cino[cin+2:]] : [1, &cino[cin+1:]]
  for c in split(cstr,'\zs')
    if c == '.' && !divider
      let divider = 1
    elseif c ==# 's'
      if n is ''
        let n = s:sw()
      else
        let n = str2nr(n) * s:sw()
      endif
      break
    elseif c =~ '\d'
      let [n, divider] .= [c, 0]
    else
      break
    endif
  endfor
  return sign * str2nr(n) / max([str2nr(divider),1])
endfunction

" Optimized {skip} expr, used only once per GetJavascriptIndent() call
function s:skip_func()
  if s:topCol == 1 || line('.') < s:scriptTag
    return {} " E728, used as limit condition for loops and searchpair()
  endif
  let s:topCol = col('.')
  if getline('.') =~ '\%<'.s:topCol.'c\/.\{-}\/\|\%>'.s:topCol.'c[''"]\|\\$'
    if eval(s:skip_expr)
      let s:topCol = 0
    endif
    return !s:topCol
  elseif s:checkIn || search('\m`\|\${\|\*\/','nW'.s:z,s:looksyn)
    let s:checkIn = eval(s:skip_expr)
    if s:checkIn
      let s:topCol = 0
    endif
  endif
  let s:looksyn = line('.')
  return s:checkIn
endfunction

function s:alternatePair()
  let [l:pos, pat, l:for] = [getpos('.'), '[][(){};]', 2]
  while search('\m'.pat,'bW')
    let tok = s:skip_func() ? '' : s:looking_at()
    if tok is ''
      continue
    elseif tok == ';'
      if !l:for
        if s:GetPair('{','}','bW','s:skip_func()',2000) > 0
          return
        endif
      else
        let [pat, l:for] = ['[{}();]', l:for - 1]
        continue
      endif
    elseif tok =~ '[])}]'
      if s:GetPair(escape(tr(tok,'])}','[({'),'['), tok,'bW','s:skip_func()',2000) > 0
        continue
      endif
    else
      return
    endif
    break
  endwhile
  call setpos('.',l:pos)
endfunction

function s:Nat(...)
  return max(a:000+[0])
endfunction

function s:looking_at()
  return getline('.')[col('.')-1]
endfunction

function s:token()
  return s:looking_at() =~ '\k' ? expand('<cword>') : s:looking_at()
endfunction

function s:previous_token()
  let l:pos = getpos('.')
  if search('\m\k\{1,}\|\S','ebW')
    if (strpart(getline('.'),col('.')-2,2) == '*/' || line('.') != l:pos[1] &&
          \ getline('.')[:col('.')-1] =~ '\/\/') && s:syn_at(line('.'),col('.')) =~? s:syng_com
      while search('\m\S\ze\_s*\/[/*]','bW')
        if s:syn_at(line('.'),col('.')) !~? s:syng_com
          return s:token()
        endif
      endwhile
    else
      return s:token()
    endif
    call setpos('.',l:pos)
  endif
  return ''
endfunction

function s:__previous_token()
  let l:pos = getpos('.')
  let ret = s:previous_token()
  call setpos('.',l:pos)
  return ret
endfunction

function s:expr_col()
  let [bal, l:pos] = [0, getpos('.')]
  while bal < 1 && search('\m[{}?:;]','bW',s:scriptTag)
    let tok = eval(s:skip_expr) ? '' : s:looking_at()
    if tok is ''
      continue
    elseif tok == ':'
      if getpos('.')[1:2] == [l:pos[1],l:pos[2]-1]
        let bal = 1
      else
        let bal -= strpart(getline('.'),col('.')-2,3) !~ '::'
      endif
    elseif tok == '?'
      let bal += 1
    elseif tok == '{' && !s:IsBlock()
      let bal = 1
    elseif tok != '}' || s:GetPair('{','}','bW',s:skip_expr,200) < 1
      break
    endif
  endwhile
  call setpos('.',l:pos)
  return s:Nat(bal)
endfunction

" configurable regexes that define continuation lines, not including (, {, or [.
let s:opfirst = '^' . get(g:,'javascript_opfirst',
      \ '\C\%([<>=,?^%|*/&]\|\([-.:+]\)\1\@!\|!=\|in\%(stanceof\)\=\>\)')
let s:continuation = get(g:,'javascript_continuation',
      \ '\C\%([<=,.~!?/*^%|&:]\|+\@<!+\|-\@<!-\|=\@<!>\|\<\%(typeof\|new\|delete\|void\|in\|instanceof\|await\)\)') . '$'

function s:continues(ln,con)
  let tok = matchstr(a:con[-15:],s:continuation)
  if tok isnot ''
    call cursor(a:ln,strlen(a:con))
    if tok =~ '[/>]'
      return s:syn_at(a:ln,col('.')) !~? (tok == '>' ? 'jsflow\|^html' : 'regex')
    elseif tok =~ '\l'
      return s:previous_token() != '.'
    elseif tok == ':'
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
  let l:n = prevnonblank(a:lnum)
  while l:n
    if getline(l:n) =~ '^\s*\/[/*]'
      if (stridx(getline(l:n),'`') != -1 || getline(l:n-1)[-1:] == '\') &&
            \ s:syn_at(l:n,1) =~? b:syng_str
        break
      endif
      let l:n = prevnonblank(l:n-1)
    elseif stridx(getline(l:n), '*/') != -1 && s:syn_at(l:n,1) =~? s:syng_com
      for l:n in range(l:n-1, s:Nat(l:n-(&cino =~ '\*' ? s:parse_cino('*') : 70)-1), -1)
        if stridx(getline(l:n),'/*') != -1
          break
        endif
      endfor
    else
      break
    endif
  endwhile
  return l:n
endfunction

" Check if line 'lnum' has a balanced amount of parentheses.
function s:Balanced(lnum)
  let l:open = 0
  let l:line = getline(a:lnum)
  let pos = match(l:line, '[][(){}]', 0)
  while pos != -1
    if s:syn_at(a:lnum,pos + 1) !~? b:syng_strcom
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

function s:OneScope(lnum)
  let pline = s:Trim(a:lnum)
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
  return pline[-2:] == '=>' || index(split(kw),s:token()) != -1 &&
        \ s:__previous_token() != '.' && !s:doWhile()
endfunction

function s:doWhile()
  if expand('<cword>') ==# 'while'
    let l:pos = searchpos('\m\<','cbW')
    while search('\m\C[{}]\|\<\%(do\|while\)\>','bW')
      if !eval(s:skip_expr)
        if (s:looking_at() == '}' && s:GetPair('{','}','bW',s:skip_expr,200) > 0 ?
              \ s:previous_token() : s:token()) ==# 'do' && s:IsBlock()
          return 1
        endif
        break
      endif
    endwhile
    call setpos('.',l:pos)
  endif
endfunction

" returns braceless levels started by 'i' and above lines * &sw. 'num' is the
" lineNr which encloses the entire context, 'cont' if whether line 'i' + 1 is
" a continued expression, which could have started in a braceless context
function s:iscontOne(i,num,cont)
  let [l:i, l:num, bL] = [a:i, a:num + !a:num, 0]
  let pind = a:num ? indent(l:num) + s:sw() : 0
  let ind = indent(l:i) + (a:cont ? 0 : s:sw())
  while l:i >= l:num && (ind > pind || l:i == l:num)
    if indent(l:i) < ind && s:OneScope(l:i)
      let bL += s:sw()
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
function s:IsBlock()
  let l:n = line('.')
  let tok = s:previous_token()
  if match(s:stack,'\cxml\|jsx') != -1 && s:syn_at(line('.'),col('.')-1) =~? 'xml\|jsx'
    return tok != '{'
  elseif tok =~ '\k'
    if tok ==# 'type'
      return s:__previous_token() !~# '^\%(im\|ex\)port$'
    endif
    return index(split('return const let import export extends yield default delete var await void typeof throw case new of in instanceof')
          \ ,tok) < (line('.') != l:n) || s:__previous_token() == '.'
  elseif tok == '>'
    return getline('.')[col('.')-2] == '=' || s:syn_at(line('.'),col('.')) =~? 'jsflow\|^html'
  elseif tok == '*'
    return s:__previous_token() == ':'
  elseif tok == ':'
    return !s:expr_col()
  elseif tok == '/'
    return s:syn_at(line('.'),col('.')) =~? 'regex'
  endif
  return tok !~ '[=~!<,.?^%|&([]' &&
        \ (tok !~ '[-+]' || l:n != line('.') && getline('.')[col('.')-2] == tok)
endfunction

function GetJavascriptIndent()
  let b:js_cache = get(b:,'js_cache',[0,0,0])
  let s:synId_cache = {}
  " Get the current line.
  let l:line = getline(v:lnum)
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
  elseif syns =~? b:syng_str
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
  let [ s:scriptTag, idx ] = [ get(get(b:,'hi_indent',{}),'blocklnr'),
        \ index([']',')','}'],l:line[0]) ]
  if b:js_cache[0] >= l:lnum && b:js_cache[0] < v:lnum &&
        \ (b:js_cache[0] > l:lnum || s:Balanced(l:lnum))
    call call('cursor',b:js_cache[2] ? b:js_cache[1:] : [v:lnum,1])
  else
    call cursor(v:lnum,1)
    let [s:looksyn, s:checkIn, s:topCol] = [v:lnum - 1, 0, 0]
    if idx != -1
      call s:GetPair(['\[','(','{'][idx],'])}'[idx],'bW','s:skip_func()',2000)
    elseif getline(v:lnum) !~ '^\S' && syns =~? 'block'
      call s:GetPair('{','}','bW','s:skip_func()',2000)
    else
      call s:alternatePair()
    endif
  endif

  let b:js_cache = [v:lnum] + (line('.') == v:lnum ? [s:scriptTag,0] : getpos('.')[1:2])
  let num = b:js_cache[1]

  let [numInd, isOp, bL, l:switch_offset] = [s:Nat(indent(num)),0,0,0]
  if !b:js_cache[2] || s:looking_at() == '{' && s:IsBlock()
    let [ilnum, pline] = [line('.'), s:Trim(l:lnum)]
    if b:js_cache[2] && s:looking_at() == ')' && s:GetPair('(',')','bW',s:skip_expr,100) > 0
      if ilnum == num
        let [num, numInd] = [line('.'), indent('.')]
      endif
      if idx == -1 && s:previous_token() ==# 'switch' && s:previous_token() != '.'
        let l:switch_offset = &cino !~ ':' ? s:sw() : s:parse_cino(':')
        if pline[-1:] != '.' && l:line =~# '^\%(default\|case\)\>'
          return s:Nat(numInd + l:switch_offset)
        elseif &cino =~ '='
          let l:case_offset = s:parse_cino('=')
        endif
      endif
    endif
    if idx == -1 && pline[-1:] !~ '[{;]'
      let isOp = (l:line =~# s:opfirst || s:continues(l:lnum,pline)) * s:sw()
      let bL = s:iscontOne(l:lnum,b:js_cache[1],isOp)
      let bL -= (bL && l:line[0] == '{') * s:sw()
    endif
  elseif idx == -1 && getline(b:js_cache[1])[b:js_cache[2]-1] == '(' && &cino =~ '('
    let pval = s:parse_cino('(')
    return !pval || !search('\m\S','nbW',num) && !s:parse_cino('U') ?
          \ (s:parse_cino('w') ? 0 : -!!search('\m\S','W'.s:z,num)) + virtcol('.') :
          \ s:Nat(numInd + pval + s:GetPair('(',')','nbrmW',s:skip_expr,100,num) * s:sw())
  endif

  " main return
  if l:line =~ '^[])}]\|^|}'
    return numInd
  elseif num
    return s:Nat(numInd + get(l:,'case_offset',s:sw()) + l:switch_offset + bL + isOp)
  endif
  return bL + isOp
endfunction

let &cpo = s:cpo_save
unlet s:cpo_save
