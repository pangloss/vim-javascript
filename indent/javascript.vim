" Vim indent file
" Language: Javascript
" Maintainer: vim-javascript community
" URL: https://github.com/pangloss/vim-javascript
" Acknowledgement: Based off of vim-ruby maintained by Nikolai Weibull http://vim-ruby.rubyforge.org
" Last Change: July 30, 2016

" Only load this indent file when no other was loaded.
if exists("b:did_indent")
  finish
endif
let b:did_indent = 1

" Now, set up our indentation expression and keys that trigger it.
setlocal indentexpr=GetJavascriptIndent()
setlocal nolisp
setlocal indentkeys=0{,0},0),0],:,!^F,o,O,e
setlocal cinoptions+=j1,J1

let b:undo_indent = 'setlocal indentexpr< indentkeys< cinoptions<'

" Only define the function once.
if exists("*GetJavascriptIndent")
  finish
endif

let s:cpo_save = &cpo
set cpo&vim

" Get shiftwidth value
if exists('*shiftwidth')
  func s:sw()
    return shiftwidth()
  endfunction
else
  func s:sw()
    return &sw
  endfunction
endif

let s:line_pre = '^\s*\%(\/\*.*\*\/\s*\)*'
let s:expr_case = s:line_pre . '\%(\%(case\>.*\)\|default\)\s*:\C'
" Regex of syntax group names that are or delimit string or are comments.
let s:syng_strcom = '\%(string\|regex\|special\|doc\|comment\|template\)\c'

" Regex of syntax group names that are strings or documentation.
let s:syng_comment = '\%(comment\|doc\)\c'

" Expression used to check whether we should skip a match with searchpair().
let s:skip_expr = "line('.') < (prevnonblank(v:lnum) - 2000) ? dummy : s:IsSyn(line('.'),col('.'),'')"

func s:lookForParens(start,end,flags,time)
  try
    return searchpair(a:start,'',a:end,a:flags,s:skip_expr,0,a:time)
  catch /E118/
    return searchpair(a:start,'',a:end,a:flags,0,0)
  endtry
endfunction

let s:line_term = '\s*\%(\/\*.*\*\/\s*\)*$'

" configurable regexes that define continuation lines, not including (, {, or [.
if !exists('g:javascript_opfirst')
  let g:javascript_opfirst = '\%([<>,:?^%]\|\([-/.+]\)\%(\1\|\*\|\/\)\@!\|\*\/\@!\|=>\@!\||\|&\|in\%(stanceof\)\=\>\)\C'
endif
let g:javascript_opfirst = s:line_pre . g:javascript_opfirst

if !exists('g:javascript_continuation')
  let g:javascript_continuation = '\%([<*,.?:^%]\|+\@<!+\|-\@<!-\|=\@<!>\|\*\@<!\/\|=\||\|&\|\<in\%(stanceof\)\=\)\C'
endif
let g:javascript_continuation .= s:line_term

func s:Onescope(lnum,text,add)
  return a:text =~ '\%(\<else\|\<do\|=>' . (a:add ? '\|\<try\|\<finally' : '' ) . '\)\C' . s:line_term ||
        \ ((a:add && a:text =~ s:line_pre . s:line_term && cursor(s:PrevCodeLine(a:lnum - 1),1) > -1 &&
        \ cursor(line('.'),match(s:Stripline(getline(line('.'))), ')' . s:line_term))>-1) ||
        \ cursor(a:lnum, match(a:text, ')' . s:line_term)) > -1) &&
        \ s:lookForParens('(', ')', 'cbW', 100) > 0 &&
        \ search((a:add ? '\%(function\*\|[A-Za-z_$][0-9A-Za-z_$]*\)\C' :
        \ '\<\%(for\%(\s+each\)\=\|if\|let\|while\|with\)\C') . '\_s*\%#','bW') &&
        \ (a:add || (expand("<cword>") == 'while' ? !s:lookForParens('\<do\>\C', '\<while\>\C','bW',100) : 1))
endfunction

" Auxiliary Functions {{{2

" strip line of comment
func s:StripLine(c)
  return substitute(a:c, '\%(:\@<!\/\/.*\)$', '','')
endfunction

" Check if the character at lnum:col is inside a string, comment, or is ascii.
func s:IsSyn(lnum, col, reg)
  return synIDattr(synID(a:lnum, a:col, 1), 'name') =~? (a:reg != '' ? a:reg : s:syng_strcom)
endfunction

" Find line above 'lnum' that isn't empty, in a comment, or in a string.
func s:PrevCodeLine(lnum)
  let lnum = prevnonblank(a:lnum)
  while lnum > 0
    if !s:IsSyn(lnum, matchend(getline(lnum), '^\s*[^''"]'),'')
      break
    endif
    let lnum = prevnonblank(lnum - 1)
  endwhile
  return lnum > 0 ? lnum : -1
endfunction

" Check if line 'lnum' has more opening brackets than closing ones.
func s:LineHasOpeningBrackets(lnum)
  let open_0 = 0
  let open_2 = 0
  let open_4 = 0
  let line = getline(a:lnum)
  let pos = match(line, '[][(){}]', 0)
  let last = 0
  while pos != -1
    if !s:IsSyn(a:lnum, pos + 1, '')
      let idx = stridx('(){}[]', line[pos])
      if idx % 2 == 0
        let open_{idx} = open_{idx} + 1
        let last = pos
      else
        let open_{idx - 1} = open_{idx - 1} - 1
      endif
    endif
    let pos = match(line, '[][(){}]', pos + 1)
  endwhile
  return [(open_0 > 0 ? 1 : (open_0 == 0 ? 0 : 2)) . (open_2 > 0 ? 1 : (open_2 == 0 ? 0 : 2)) .
        \ (open_4 > 0 ? 1 : (open_4 == 0 ? 0 : 2)), last]
endfunction
" }}}

func GetJavascriptIndent()
  if !exists('b:js_cache')
    let b:js_cache = [0,0,0]
  endif
  " Get the current line.
  let line = getline(v:lnum)
  " previous nonblank line number
  let prevline = prevnonblank(v:lnum - 1)

  " start with strings,comments,etc.{{{2
  if (line !~ '^[''"`]' && s:IsSyn(v:lnum,1,'string\|template')) ||
        \ (line !~ '^\s*[/*]' && s:IsSyn(v:lnum,1,s:syng_comment))
    return -1
  endif
  if line !~ '^\%(\/\*\|\s*\/\/\)' && s:IsSyn(v:lnum,1,s:syng_comment)
    return cindent(v:lnum)
  endif
  let lnum = s:PrevCodeLine(v:lnum - 1)
  let pline = s:StripLine(getline(lnum))
  let line = s:StripLine(line)
  if lnum <= 0
    return 0
  endif

  if (line =~ s:expr_case)
    let cpo_switch = &cpo
    set cpo+=%
    let ind = cindent(v:lnum)
    let &cpo = cpo_switch
    return ind
  endif
  "}}}

  " the containing paren, bracket, curly. Memoize, last lineNr either has the
  " same scope or starts a new one, unless if it closed a scope.
  let pcounts = [0]
  if b:js_cache[0] >= lnum  && b:js_cache[0] <= v:lnum && b:js_cache[0] &&
        \ (b:js_cache[0] > lnum || map(pcounts,'s:LineHasOpeningBrackets(lnum)')[0][0] !~ '2')
    let num = pcounts[0][0] =~ '1' ? lnum : b:js_cache[1]
    if pcounts[0][0] =~'1'
      call cursor(lnum,pcounts[0][1])
    endif
  else
    call cursor(v:lnum,1)
    let syns = synIDattr(synID(v:lnum, 1, 1), 'name')
    if line[0] =~ '\s' && syns != ''
      let pattern = syns =~? 'funcblock' ? ['{','}'] : syns =~? 'jsparen' ? ['(',')'] : syns =~? 'jsbracket'? ['\[','\]'] :
            \ ['(\|{\|\[',')\|}\|\]']
      let num = s:lookForParens(pattern[0],pattern[1],'bW',2000)
    else
      let num = s:lookForParens('(\|{\|\[',')\|}\|\]','bW',2000)
    endif
  endif
  let b:js_cache = [v:lnum,num,line('.') == v:lnum ? b:js_cache[2] : col('.')]

  " most significant part
  if line =~ s:line_pre . '[])}]'
    return indent(num)
  endif
  let inb = num == 0 ? 1 : s:Onescope(num, s:StripLine(strpart(getline(num),0,b:js_cache[2] - 1)),1)
  let switch_offset = (!inb || num == 0) || expand("<cword>") != 'switch' ? 0 : &cino !~ ':' || !has('float') ?  s:sw() :
        \ float2nr(str2float(matchstr(&cino,'.*:\zs[-0-9.]*')) * (match(&cino,'.*:\zs[^,]*s') ? s:sw() : 1))
  if ((line =~ g:javascript_opfirst ||
        \ (pline =~ g:javascript_continuation && pline !~ s:expr_case)) &&
        \ inb) || (s:Onescope(lnum,pline,0) && line !~ s:line_pre . '{')
    return (num > 0 ? indent(num) : -s:sw()) + (s:sw() * 2) + switch_offset
  elseif num > 0
    return indent(num) + s:sw() + switch_offset
  endif

endfunction


let &cpo = s:cpo_save
unlet s:cpo_save
