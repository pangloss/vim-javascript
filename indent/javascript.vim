" Vim indent file
" Language: Javascript
" Acknowledgement: Based off of vim-ruby maintained by Nikolai Weibull http://vim-ruby.rubyforge.org

" Only load this indent file when no other was loaded.
if exists("b:did_indent")
  finish
endif
let b:did_indent = 1

setlocal nosmartindent

" Now, set up our indentation expression and keys that trigger it.
setlocal indentexpr=GetJavascriptIndent()
setlocal formatexpr=Fixedgq(v:lnum,v:count)
setlocal indentkeys=0{,0},0),0],0\,:,!^F,o,O,e
setlocal cinoptions+=j1,J1,c1

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

func s:lookForParens(start,end,flags,stop)
  try 
    return searchpair(a:start,'',a:end,a:flags,
	  \ "line('.') < " . (prevnonblank(v:lnum) - 2000) . " ? dummy :"
	  \ . " synIDattr(synID(line('.'), col('.'), 1), 'name')"
	  \ . " =~? '\\(Comment\\|regex\\|String\\|doc\\|special\\|template\\)'"
          \ ,a:stop,2000)
  catch /E118/
    return searchpair(a:start,'',a:end,a:flags,0,a:stop)
  endtry
endfunc

let s:line_term = '\s*\%(\%(:\@<!\/\/.*\)\=\|\%(\/\*.*\*\/\s*\)*\)$'

" Regex that defines continuation lines, not including (, {, or [.
let s:continuation_regex = '\%([*,.?:]\|+\@<!+\|-\@<!-\|\*\@<!\/\|=\|||\|&&\)' . s:line_term

let s:one_line_scope_regex = '\%(\<else\>\|=>\)\C' . s:line_term

function s:Onescope(lnum)
  if getline(a:lnum) =~ s:one_line_scope_regex
    return 1
  end
  call cursor(a:lnum, 1)
  if search('.*\zs\<\%(while\|for\|if\)\>\s*(\C', 'ce', a:lnum) > 0 &&
        \ s:lookForParens('(', ')', 'W', a:lnum) > 0 &&
        \ col('.') == strlen(s:RemoveTrailingComments(getline(a:lnum)))
    return 1
  else
    return 0
  end
endfunction

let s:operator_first = s:line_pre . '\%([,:?]\|\([-/.+*]\)\%(\1\|\*\|\/\)\@!\|||\|&&\)'

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

function s:RemoveTrailingComments(content)
  let single = '\/\/\%(.*\)\s*$'
  let multi = '\/\*\%(.*\)\*\/\s*$'
  return substitute(substitute(substitute(a:content, single, '', ''), multi, '', ''), '\s\+$', '', '')
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
let s:preref = [0,0]
function GetJavascriptIndent()
  " Get the current line.
  let line = getline(v:lnum)
  " previous nonblank line number
  let prevline = prevnonblank(v:lnum - 1)
  " previous line of code
  let lnum = s:PrevNonBlankNonString(v:lnum - 1)

  if line !~ '^[''"`]' && synIDattr(synID(v:lnum, 1, 1), 'name') =~? 'string\|template'
    let s:preref[0] = v:lnum
    return -1
  endif
  if line !~ '^\%(\/\*\|\s*\/\/\)' && s:IsInComment(v:lnum, 1)
    let s:preref[0] = v:lnum
    return cindent(v:lnum)
  endif
  if line =~ '^\s*$' && getline(prevline) =~ '\%(\%(^\s*\/\/\|\/\*\).*\)\@<!\*\/' &&
        \ s:IsInComment(prevline, 1)
    let s:preref[0] = v:lnum
    return indent(prevline) - 1
  endif
  if line =~ '^\s*$' && lnum != prevline
    let s:preref[0] = v:lnum
    return indent(prevnonblank(v:lnum))
  endif
  if lnum == 0
    let s:preref[0] = v:lnum
    return 0
  endif
  if (line =~ s:expr_case)
    let s:cpo_switch = &cpo
    set cpo+=%
    let ind = cindent(v:lnum)
    let &cpo = s:cpo_switch
    let s:preref = [v:lnum, search('\<switch\s*(','nbw')]
    return ind
  endif

  call cursor(v:lnum,1)
  " the containing paren, bracket, curly
  let counts = s:LineHasOpeningBrackets(lnum)
if s:preref[0] >= lnum  && s:preref[0] < v:lnum && s:preref[0] && (counts !~ '2' || s:preref[0] > lnum)
    let num = counts =~ '1' ? lnum : s:preref[1]
    let s:preref = [v:lnum, num]
  else
    let syns = synIDattr(synID(v:lnum, 1, 1), 'name')
    if line[1] =~ '\s' && syns != ''
      let pattern = syns =~? 'funcblock' ? ['{','}'] : syns =~? 'jsparen' ? ['(',')'] : syns =~? 'jsbracket'? ['\[','\]'] : ['\%(^.*:\@<!\/\/.*\)\@<!\%((\|{\|\[\)','\%(^.*:\@<!\/\/.*\)\@<!\%()\|}\|\]\)']
      let num = s:lookForParens(pattern[0],pattern[1],'nbw',0)
      let s:preref = [v:lnum, num]
    elseif syns == '' && line[1] =~ '\s'
      let num = 0
      let s:preref = [v:lnum, num]
    else
      let num = s:lookForParens(
            \ '\%(^.*:\@<!\/\/.*\)\@<!\%((\|{\|\[\)',
            \ '\%(^.*:\@<!\/\/.*\)\@<!\%()\|}\|\]\)',
            \ 'nbW', 0)
      let s:preref = [v:lnum, num]
    end
  end

  if line =~ s:line_pre . '[])}]'
    return indent(num)
  end
  let switch_offset = 0
  if synIDattr(synID(v:lnum, 1, 1), 'name') =~? 'switch'

    let num = search('\<switch\s*(','nbw')
    let switch_offset = &cino !~ ':' ?  s:sw() :
          \ (strlen(matchstr(getline(search(s:expr_case,'nbw')),'^\s*')) - strlen(matchstr(getline(num),'^\s*')))
    let s:preref[1] = num
  endif
  if (line =~ s:operator_first ||
        \ (getline(lnum) =~ s:continuation_regex && getline(lnum) !~ s:expr_case) ||
        \ (s:Onescope(lnum) && line !~ s:line_pre . '{')) &&
        \ (num != lnum &&
        \ synIDattr(synID(v:lnum, 1, 1), 'name') !~? 'jsdestructuringblock\|args\|jsbracket\|jsparen\|jsobject')
    " TODO: remove those syntax checks
    return (num > 0 ? indent(num) : -s:sw()) + (s:sw() * 2) + switch_offset
  elseif num > 0
    return indent(num) + s:sw() + switch_offset
  end

endfunction


let &cpo = s:cpo_save
unlet s:cpo_save
" gq{{{2
function! Fixedgq(lnum, count)
  let l:tw = &tw ? &tw : 80;

  let l:count = a:count
  let l:first_char = indent(a:lnum) + 1

  if mode() == 'i' " gq was not pressed, but tw was set
    return 1
  endif

  " This gq is only meant to do code with strings, not comments
  if s:IsInComment(a:lnum, l:first_char)
    return 1
  endif

  if len(getline(a:lnum)) < l:tw && l:count == 1 " No need for gq
    return 1
  endif

  " Put all the lines on one line and do normal spliting after that
  if l:count > 1
    while l:count > 1
      let l:count -= 1
      normal J
    endwhile
  endif

  let l:winview = winsaveview()

  call cursor(a:lnum, l:tw + 1)
  let orig_breakpoint = searchpairpos(' ', '', '\.', 'bcW', '', a:lnum)
  call cursor(a:lnum, l:tw + 1)
  let breakpoint = searchpairpos(' ', '', '\.', 'bcW', s:skip_expr, a:lnum)

  " No need for special treatment, normal gq handles edgecases better
  if breakpoint[1] == orig_breakpoint[1]
    call winrestview(l:winview)
    return 1
  endif

  " Try breaking after string
  if breakpoint[1] <= indent(a:lnum)
    call cursor(a:lnum, l:tw + 1)
    let breakpoint = searchpairpos('\.', '', ' ', 'cW', s:skip_expr, a:lnum)
  endif


  if breakpoint[1] != 0
    call feedkeys("r\<CR>")
  else
    let l:count = l:count - 1
  endif

  " run gq on new lines
  if l:count == 1
    call feedkeys("gqq")
  endif

  return 0
endfunction
"}}}
" vim: foldmethod=marker:foldlevel=1
