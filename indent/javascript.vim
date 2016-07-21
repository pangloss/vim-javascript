" Vim indent file
" Language: Javascript
" Acknowledgement: Based off of vim-ruby maintained by Nikolai Weibull http://vim-ruby.rubyforge.org

" Only load this indent file when no other was loaded.
if exists("b:did_indent")
  finish
endif
let b:did_indent = 1

" Now, set up our indentation expression and keys that trigger it.
setlocal indentexpr=GetJavascriptIndent()
setlocal nolisp
setlocal indentkeys=0{,0},0),0],:,!^F,o,O,e
setlocal cinoptions+=j1,J1,c1

let b:undo_indent = 'setlocal indentexpr< formatexpr< indentkeys< cinoptions<'

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
  endfunc
else
  func s:sw()
    return &sw
  endfunc
endif

let s:line_pre = '^\s*\%(\/\*.*\*\/\s*\)*'
let s:expr_case = s:line_pre . '\%(\%(case\>.*\)\|default\)\s*:\C'
" Regex of syntax group names that are or delimit string or are comments.
let s:syng_strcom = '\%(string\|regex\|special\|doc\|comment\|template\)\c'

" Regex of syntax group names that are strings or documentation.
let s:syng_comment = '\%(comment\|doc\)\c'

" Expression used to check whether we should skip a match with searchpair().
let s:skip_expr = "synIDattr(synID(line('.'),col('.'),1),'name') =~ '".s:syng_strcom."'"

func s:lookForParens(start,end,flags,time)
  try
    return searchpair(a:start,'',a:end,a:flags,
	  \ "line('.') < " . (prevnonblank(v:lnum) - 2000) . " ? dummy :" . s:skip_expr
          \ ,0,a:time)
  catch /E118/
    return searchpair(a:start,'',a:end,a:flags,0,0)
  endtry
endfunc

let s:line_term = '\s*\%(\%(:\@<!\/\/.*\)\=\|\%(\/\*.*\*\/\s*\)*\)$'

" configurable regexes that define continuation lines, not including (, {, or [.
if !exists('g:javascript_opfirst')
  let g:javascript_opfirst = '\%([,:?]\|\([-/.+*]\)\%(\1\|\*\|\/\)\@!\|||\|&&\)'
endif
let g:javascript_opfirst = s:line_pre . g:javascript_opfirst

if !exists('g:javascript_continuation')
  let g:javascript_continuation = '\%([*,.?:]\|+\@<!+\|-\@<!-\|\*\@<!\/\|=\|||\|&&\)'
endif
let g:javascript_continuation .= s:line_term

function s:Onescope(lnum)
  return getline(a:lnum) =~ '\%(\<else\|\<do\|=>\)\C' . s:line_term ||
        \ (cursor(a:lnum, match(getline(a:lnum),')' . s:line_term)) > -1 &&
        \ s:lookForParens('(', ')', 'cbW', 100) > 0 &&
        \ cursor(line('.'),match( ' ' . strpart(getline(line('.')),0,col('.') - 1),
        \ '\<\%(else\|for\%(\s+each\)\=\|if\|let\|while\|with\)\C' . s:line_term)) > -1) &&
        \ (expand("<cword>") =~ 'while\C' ? !s:lookForParens('\<do\>\C', '\<while\>\C','bw',100) : 1)
endfunction

" Auxiliary Functions {{{2
" ======================

" Check if the character at lnum:col is inside a string, comment, or is ascii.
function s:IsInStringOrComment(lnum, col)
  return synIDattr(synID(a:lnum, a:col, 1), 'name') =~ s:syng_strcom
endfunction

" Check if the character at lnum:col is inside a multi-line comment.
function s:IsInComment(lnum, col)
  return synIDattr(synID(a:lnum, a:col, 1), 'name') =~ s:syng_comment
endfunction

" Find line above 'lnum' that isn't empty, in a comment, or in a string.
function s:PrevNonBlankNonString(lnum)
  let lnum = prevnonblank(a:lnum)
  while lnum > 0
    if !s:IsInStringOrComment(lnum, matchend(getline(lnum), '^\s*[^''"]'))
      break
    endif
    let lnum = prevnonblank(lnum - 1)
  endwhile
  return lnum
endfunction

" Check if line 'lnum' has more opening brackets than closing ones.
function s:LineHasOpeningBrackets(lnum)
  let open_0 = 0
  let open_2 = 0
  let open_4 = 0
  let line = getline(a:lnum)
  let pos = match(line, '[][(){}]', 0)
  while pos != -1
    if !s:IsInStringOrComment(a:lnum, pos + 1)
      let idx = stridx('(){}[]', line[pos])
      if idx % 2 == 0
        let open_{idx} = open_{idx} + 1
      else
        let open_{idx - 1} = open_{idx - 1} - 1
      endif
    endif
    let pos = match(line, '[][(){}]', pos + 1)
  endwhile
  return (open_0 > 0 ? 1 : (open_0 == 0 ? 0 : 2)) . (open_2 > 0 ? 1 : (open_2 == 0 ? 0 : 2)) . (open_4 > 0 ? 1 : (open_4 == 0 ? 0 : 2))
endfunction
" }}}

" GetJavascriptIndent Function
" =========================
function GetJavascriptIndent()
  if !exists('b:js_cache')
    let b:js_cache = [0,0]
  end
  " Get the current line.
  let line = getline(v:lnum)
  " previous nonblank line number
  let prevline = prevnonblank(v:lnum - 1)
  " previous line of code
  let lnum = s:PrevNonBlankNonString(v:lnum - 1)

  " start with strings,comments,etc.{{{2
  if (line !~ '^[''"`]' && synIDattr(synID(v:lnum, 1, 1), 'name') =~? 'string\|template') ||
        \ (line !~ '^\s*[/*]' && synIDattr(synID(v:lnum, 1, 1), 'name') =~? 'comment')
    return -1
  endif
  if line !~ '^\%(\/\*\|\s*\/\/\)' && s:IsInComment(v:lnum, 1)
    return cindent(v:lnum)
  endif
  if line =~ '^\s*$' && getline(prevline) =~ '\%(\%(^\s*\/\/\|\/\*\).*\)\@<!\*\/' &&
        \ s:IsInComment(prevline, 1)
    return indent(prevline) - 1
  endif
  if line =~ '^\s*$' && lnum != prevline
    return indent(prevnonblank(v:lnum))
  endif
  if lnum == 0
    return 0
  endif
  if (line =~ s:expr_case)
    let s:cpo_switch = &cpo
    set cpo+=%
    let ind = cindent(v:lnum)
    let &cpo = s:cpo_switch
    return ind
  endif
  "}}}

  " the containing paren, bracket, curly
  let pcounts = [0]
  if b:js_cache[0] >= lnum  && b:js_cache[0] < v:lnum && b:js_cache[0] &&
        \ (b:js_cache[0] > lnum || map(pcounts,'s:LineHasOpeningBrackets(lnum)')[0] !~ '2')
    let num = pcounts[0] =~ '1' ? lnum : b:js_cache[1]
  else
    call cursor(v:lnum,1)
    let syns = synIDattr(synID(v:lnum, 1, 1), 'name')
    if line[1] =~ '\s'
      if syns != ''
        let pattern = syns =~? 'funcblock' ? ['{','}'] : syns =~? 'jsparen' ? ['(',')'] : syns =~? 'jsbracket'? ['\[','\]'] :
              \ ['(\|{\|\[',')\|}\|\]']
        let num = s:lookForParens(pattern[0],pattern[1],'nbw',2000)
      else
        let num = 0
      end
    else
      let num = s:lookForParens('(\|{\|\[',')\|}\|\]','nbW',2000)
    end
  end
  let b:js_cache = [v:lnum, num]

  " most significant part
  if line =~ s:line_pre . '[])}]'
    return indent(num)
  end
  let switch_offset = 0
  if index(map(synstack(v:lnum, 1), 'synIDattr( v:val, "name")'),'jsSwitchBlock') > -1
    let bnum = search('\<switch\s*(','nbw')
    let switch_offset = bnum < num || bnum == lnum ? 0 : &cino !~ ':' ?  s:sw() :
          \ float2nr(str2float(matchstr(&cino,'.*:\zs[-0-9.]*')) * (match(&cino,'.*:\zs[^,]*s') ? s:sw() : 1))
  endif
  if (line =~ g:javascript_opfirst ||
        \ (getline(lnum) =~ g:javascript_continuation && getline(lnum) !~ s:expr_case) ||
        \ (s:Onescope(lnum) && line !~ s:line_pre . '{')) &&
        \ (num != lnum &&
        \ synIDattr(synID(v:lnum, 1, 1), 'name') !~? 'jsdestructuringblock\|args\|jsbracket\|jsparen\|jsobject')
    return (num > 0 ? indent(num) : -s:sw()) + (s:sw() * 2) + switch_offset
  elseif num > 0
    return indent(num) + s:sw() + switch_offset
  end

endfunction


let &cpo = s:cpo_save
unlet s:cpo_save

" vim: foldmethod=marker:foldlevel=1
