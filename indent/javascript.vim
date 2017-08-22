" Vim indent file
" Language: Javascript
" Maintainer: Chris Paul ( https://github.com/bounceme )
" URL: https://github.com/pangloss/vim-javascript
" Last Change: August 12, 2017

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
let s:skip_expr = "s:SynAt(line('.'),col('.')) =~? b:syng_strcom"

" searchpair() wrapper
if has('reltime')
  function s:GetPair(start,end,flags,skip,time,...)
    return searchpair('\m'.(a:start == '[' ? '\[' : a:start),'','\m'.a:end,
          \ a:flags,a:skip,max([prevnonblank(v:lnum) - 2000,0] + a:000),a:time)
  endfunction
else
  function s:GetPair(start,end,flags,skip,...)
    return searchpair('\m'.(a:start == '[' ? '\[' : a:start),'','\m'.a:end,
          \ a:flags,a:skip,max([prevnonblank(v:lnum) - 1000,0,get(a:000,1)]))
  endfunction
endif

function s:SynAt(l,c)
  let byte = line2byte(a:l) + a:c - 1
  let pos = index(s:synid_cache[0], byte)
  if pos == -1
    let s:synid_cache[:] += [[byte], [synIDattr(synID(a:l, a:c, 0), 'name')]]
  endif
  return s:synid_cache[1][pos]
endfunction

function s:ParseCino(f)
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

" Optimized {skip} expr, only callable from the search loop which
" GetJavascriptIndent does to find the containing [[{(] (relies on s:vars)
function s:SkipFunc()
  if s:top_col == 1
    throw 'out of bounds'
  endif
  let s:top_col = 0
  if s:check_in
    if eval(s:skip_expr)
      return 1
    endif
    let s:check_in = 0
  elseif getline('.') =~ '\%<'.col('.').'c\/.\{-}\/\|\%>'.col('.').'c[''"]\|\\$'
    if eval(s:skip_expr)
      let s:looksyn = line('.')
      return 1
    endif
  elseif search('\m`\|\${\|\*\/','nW'.s:z,s:looksyn) && eval(s:skip_expr)
    let s:check_in = 1
    return 1
  endif
  let [s:looksyn, s:top_col] = getpos('.')[1:2]
endfunction

function s:AlternatePair()
  let [pat, l:for] = ['[][(){};]', 2]
  while s:SearchLoop('\m'.pat,'bW',s:script_tag,'s:SkipFunc()')
    if s:LookingAt() == ';'
      if !l:for
        if s:GetPair('{','}','bW','s:SkipFunc()',2000,s:script_tag)
          return
        endif
        break
      else
        let [pat, l:for] = ['[{}();]', l:for - 1]
      endif
    else
      let idx = stridx('])}',s:LookingAt())
      if idx == -1
        return
      elseif !s:GetPair('[({'[idx],'])}'[idx],'bW','s:SkipFunc()',2000,s:script_tag)
        break
      endif
    endif
  endwhile
  throw 'out of bounds'
endfunction

function s:Nat(int)
  return a:int * (a:int > 0)
endfunction

function s:LookingAt()
  return getline('.')[col('.')-1]
endfunction

function s:Token()
  return s:LookingAt() =~ '\k' ? expand('<cword>') : s:LookingAt()
endfunction

function s:PreviousToken()
  let l:pos = getpos('.')
  if search('\m\k\{1,}\|\S','ebW')
    if (strpart(getline('.'),col('.')-2,2) == '*/' || line('.') != l:pos[1] &&
          \ getline('.')[:col('.')-1] =~ '\/\/') && s:SynAt(line('.'),col('.')) =~? s:syng_com
      if s:SearchLoop('\m\S\ze\_s*\/[/*]','bW',"s:SynAt(line('.'),col('.')) =~? s:syng_com")
        return s:Token()
      endif
      call setpos('.',l:pos)
    else
      return s:Token()
    endif
  endif
  return ''
endfunction

function s:Pure(f,...)
  let l:pos = getpos('.')
  let ret = call(a:f,a:000)
  call setpos('.',l:pos)
  return ret
endfunction

function s:SearchLoop(...)
  let l:pos = getpos('.')
  while call('search',a:000[:-2]) " search flags [^nc]
    if !eval(a:000[-1])
      return line('.')
    endif
  endwhile
  call setpos('.',l:pos)
endfunction

function s:ExprCol()
  if getline('.')[col('.')-2] == ':'
    return 1
  endif
  let [bal, l:pos] = [0, getpos('.')]
  while s:SearchLoop('\m[{}?:]','bW',s:script_tag,s:skip_expr)
    if s:LookingAt() == ':'
      let bal -= strpart(getline('.'),col('.')-2,3) !~ '::'
    elseif s:LookingAt() == '?'
      let bal += 1
      if bal == 1
        break
      endif
    elseif s:LookingAt() == '{'
      let bal = !s:IsBlock()
      break
    elseif !s:GetPair('{','}','bW',s:skip_expr,200)
      break
    endif
  endwhile
  call setpos('.',l:pos)
  return s:Nat(bal)
endfunction

" configurable regexes that define continuation lines, not including (, {, or [.
let s:opfirst = '^' . get(g:,'javascript_opfirst',
      \ '\C\%([<>=,.?^%|/&]\|\([-:+]\)\1\@!\|\*\+\|!=\|in\%(stanceof\)\=\>\)')
let s:continuation = get(g:,'javascript_continuation',
      \ '\C\%([<=,.~!?/*^%|&:]\|+\@<!+\|-\@<!-\|=\@<!>\|\<\%(typeof\|new\|delete\|void\|in\|instanceof\|await\)\)') . '$'

function s:Continues(ln,con)
  let tok = matchstr(a:con[-15:],s:continuation)
  if tok =~ '[a-z:]'
    call cursor(a:ln, len(a:con))
    return tok == ':' ? s:ExprCol() : s:PreviousToken() != '.'
  elseif tok !~ '[/>]'
    return tok isnot ''
  endif
  return s:SynAt(a:ln, len(a:con)) !~? (tok == '>' ? 'jsflow\|^html' : 'regex')
endfunction

function s:Trim(ln)
  let divi = split(getline(a:ln),'\s\+$\|\S\zs\ze\s*\/[/*]')
  while len(divi) > 1 && s:SynAt(a:ln, len(join(divi,''))) =~? s:syng_com
    call remove(divi,-1)
  endwhile
  return join(divi,'')
endfunction

" Find line above 'lnum' that isn't empty or in a comment
function s:PrevCodeLine(lnum)
  let [l:multi, l:n, l:pos] = [0, prevnonblank(a:lnum), getpos('.')]
  while l:n
    if getline(l:n) =~ '^\s*\/[/*]' && (getline(l:n) !~ '`' &&
          \ getline(l:n-1)[-1:] != '\' || s:SynAt(l:n,1) !~? b:syng_str)
      let l:n = prevnonblank(l:n-1)
      continue
    elseif l:multi || getline(l:n) =~ '\*\/'
      call cursor(l:n,1)
      if search('\m\/\*\|\(\*\/\)','bWp') == 1 && s:SynAt(l:n,1) =~? s:syng_com
        let [l:multi, l:n] = [1, line('.')]
        continue
      endif
    endif
    break
  endwhile
  call setpos('.',l:pos)
  return l:n
endfunction

" Check if line 'lnum' has a balanced amount of parentheses.
function s:Balanced(lnum)
  let [l:open, l:line] = [0, getline(a:lnum)]
  let pos = match(l:line, '[][(){}]')
  while pos != -1
    if s:SynAt(a:lnum,pos + 1) !~? b:syng_strcom
      let l:open += match(' ' . l:line[pos],'[[({]')
      if l:open < 0
        return
      endif
    endif
    let pos = match(l:line, l:open ?
          \ matchstr(['[][]','[()]','[{}]'],l:line[pos]) :
          \ '[][(){}]', pos + 1)
  endwhile
  return !l:open
endfunction

function s:OneScope(lnum)
  call cursor(a:lnum, len(s:Trim(a:lnum)))
  if s:LookingAt() == ')' && s:GetPair('(', ')', 'bW', s:skip_expr, 100)
    let tok = s:PreviousToken()
    return (tok =~# '^\%(for\|if\|let\|while\|with\)$' ||
          \ tok =~# '^await$\|^each$' && s:PreviousToken() ==# 'for') &&
          \ s:Pure('s:PreviousToken') != '.' && !(tok == 'while' && s:DoWhile())
  elseif s:Token() =~# '^else$\|^do$'
    return s:Pure('s:PreviousToken') != '.'
  endif
  return strpart(getline('.'),col('.')-2,2) == '=>'
endfunction

function s:DoWhile()
  let cpos = searchpos('\m\<','cbW')
  if s:SearchLoop('\m\C[{}]\|\<\%(do\|while\)\>','bW',s:skip_expr)
    if s:{s:LookingAt() == '}' && s:GetPair('{','}','bW',s:skip_expr,200) ?
          \ 'Previous' : ''}Token() ==# 'do' && s:IsBlock()
      return 1
    endif
    call call('cursor',cpos)
  endif
endfunction

" returns braceless levels started by 'i' and above lines * &sw. 'num' is the
" lineNr which encloses the entire context, 'cont' if whether line 'i' + 1 is
" a continued expression, which could have started in a braceless context
function s:IsContOne(i,num,cont)
  let [l:i, l:num, b_l] = [a:i, a:num + !a:num, 0]
  let pind = a:num ? indent(a:num) + s:sw() : 0
  let ind = indent(a:i) + (a:cont ? 0 : s:sw())
  while l:i > l:num && ind > pind || l:i == l:num
    if indent(l:i) < ind && s:OneScope(l:i)
      let b_l += 1
      let l:i = line('.')
    elseif !a:cont || b_l || ind < indent(a:i)
      break
    endif
    let ind = min([ind, indent(l:i)])
    let l:i = s:PrevCodeLine(l:i - 1)
  endwhile
  return b_l
endfunction

function s:Class()
  return (s:Token() ==# 'class' || s:PreviousToken() =~# '^class$\|^extends$') &&
        \ s:PreviousToken() != '.'
endfunction

function s:IsSwitch()
  return s:PreviousToken() !~ '[.*]' &&
        \ (!s:GetPair('{','}','cbW',s:skip_expr,100) || s:IsBlock() && !s:Class())
endfunction

" https://github.com/sweet-js/sweet.js/wiki/design#give-lookbehind-to-the-reader
function s:IsBlock()
  let l:n = line('.')
  let tok = s:PreviousToken()
  if match(s:stack,'\cxml\|jsx') != -1 && s:SynAt(line('.'),col('.')-1) =~? 'xml\|jsx'
    return tok != '{'
  elseif tok =~ '\k'
    if tok ==# 'type'
      return s:Pure('eval',"s:PreviousToken() !~# '^\\%(im\\|ex\\)port$' || s:PreviousToken() == '.'")
    endif
    return index(split('return const let import export extends yield default delete var await void typeof throw case new of in instanceof')
          \ ,tok) < (line('.') != l:n) || s:Pure('s:PreviousToken') == '.'
  elseif tok == '>'
    return getline('.')[col('.')-2] == '=' || s:SynAt(line('.'),col('.')) =~? 'jsflow\|^html'
  elseif tok == '*'
    return s:Pure('s:PreviousToken') == ':'
  elseif tok == ':'
    return !s:ExprCol()
  elseif tok == '/'
    return s:SynAt(line('.'),col('.')) =~? 'regex'
  elseif tok !~ '[=~!<,.?^%|&([]'
    return tok !~ '[-+]' || l:n != line('.') && getline('.')[col('.')-2] == tok
  endif
endfunction

function GetJavascriptIndent()
  let [b:js_cache, s:synid_cache, l:line, s:stack] = [
        \ get(b:,'js_cache',[0,0,0]),
        \ [[],[]],
        \ getline(v:lnum),
        \ map(synstack(v:lnum,1),"synIDattr(v:val,'name')"),
        \ ]
  " use synstack as it validates syn state and works in an empty line
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
  let l:line_raw = l:line
  if l:line[:1] == '/*'
    let l:line = substitute(l:line,'^\%(\/\*.\{-}\*\/\s*\)*','','')
  endif
  if l:line =~ '^\/[/*]'
    let l:line = ''
  endif

  " the containing paren, bracket, or curly. Many hacks for performance
  let [ s:script_tag, idx ] = [ get(get(b:,'hi_indent',{}),'blocklnr'),
        \ index([']',')','}'],l:line[0]) ]
  if b:js_cache[0] > l:lnum && b:js_cache[0] < v:lnum ||
        \ b:js_cache[0] == l:lnum && s:Balanced(l:lnum)
    call call('cursor',b:js_cache[2] ? b:js_cache[1:] : [v:lnum,1])
  else
    call cursor(v:lnum,1)
    let [s:looksyn, s:check_in, s:top_col] = [v:lnum - 1, 0, 0]
    try
      if idx != -1
        call s:GetPair('[({'[idx],'])}'[idx],'bW','s:SkipFunc()',2000,s:script_tag)
      elseif getline(v:lnum) !~ '^\S' && syns =~? 'block'
        call s:GetPair('{','}','bW','s:SkipFunc()',2000,s:script_tag)
      else
        call s:AlternatePair()
      endif
    catch
      call cursor(v:lnum,1)
    endtry
  endif

  let b:js_cache = [v:lnum] + (line('.') == v:lnum ? [s:script_tag,0] : getpos('.')[1:2])
  let num = b:js_cache[1]

  let [num_ind, is_op, b_l, l:switch_offset] = [s:Nat(indent(num)),0,0,0]
  if !b:js_cache[2] || s:LookingAt() == '{' && s:IsBlock()
    let [ilnum, pline] = [line('.'), s:Trim(l:lnum)]
    if b:js_cache[2] && s:LookingAt() == ')' && s:GetPair('(',')','bW',s:skip_expr,100)
      if ilnum == num
        let [num, num_ind] = [line('.'), indent('.')]
      endif
      if idx == -1 && s:PreviousToken() ==# 'switch' && s:IsSwitch()
        let l:switch_offset = &cino !~ ':' ? s:sw() : s:ParseCino(':')
        if pline[-1:] != '.' && l:line =~# '^\%(default\|case\)\>'
          return s:Nat(num_ind + l:switch_offset)
        elseif &cino =~ '='
          let l:case_offset = s:ParseCino('=')
        endif
      endif
    endif
    if idx == -1 && pline[-1:] !~ '[{;]'
      let sol = matchstr(l:line,s:opfirst)
      if sol is '' || sol == '/' && s:SynAt(v:lnum,
            \ 1 + len(getline(v:lnum)) - len(l:line)) =~? 'regex'
        if s:Continues(l:lnum,pline)
          let is_op = s:sw()
        endif
      elseif b:js_cache[2] && sol =~# '^\%(in\%(stanceof\)\=\|\*\)$'
        call call('cursor',b:js_cache[1:])
        if s:PreviousToken() =~ '\k' && s:Class()
          return num_ind + s:sw()
        endif
        let is_op = s:sw()
      else
        let is_op = s:sw()
      endif
      let b_l = s:Nat(s:IsContOne(l:lnum,b:js_cache[1],is_op) -
            \ (!is_op && l:line =~ '^{')) * s:sw()
    endif
  elseif idx == -1 && getline(b:js_cache[1])[b:js_cache[2]-1] == '(' && &cino =~ '(' &&
        \ (search('\m\S','nbW',num) || s:ParseCino('U'))
    let pval = s:ParseCino('(')
    if !pval
      let [Wval, vcol] = [s:ParseCino('W'), virtcol('.')]
      if search('\m\S','W',num)
        return s:ParseCino('w') ? vcol : virtcol('.')-1
      endif
      return Wval ? s:Nat(num_ind + Wval) : vcol
    endif
    return s:Nat(num_ind + pval + s:GetPair('(',')','nbrmW',s:skip_expr,100,num) * s:sw())
  endif

  " main return
  if l:line =~ '^[])}]\|^|}'
    if l:line_raw[0] == ')' && getline(b:js_cache[1])[b:js_cache[2]-1] == '('
      if s:ParseCino('M')
        return indent(l:lnum)
      elseif &cino =~# 'm' && !s:ParseCino('m')
        return virtcol('.') - 1
      endif
    endif
    return num_ind
  elseif num
    return s:Nat(num_ind + get(l:,'case_offset',s:sw()) + l:switch_offset + b_l + is_op)
  endif
  return b_l + is_op
endfunction

let &cpo = s:cpo_save
unlet s:cpo_save
