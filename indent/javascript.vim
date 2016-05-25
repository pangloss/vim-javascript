" Vim indent file
" Language: Javascript
" Acknowledgement: Based off of vim-ruby maintained by Nikolai Weibull http://vim-ruby.rubyforge.org

" 0. Initialization {{{1
" =================

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
setlocal cinoptions+=j1,J1

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

" 1. Variables {{{1
" ============

let s:line_pre = '^\s*\%(\/\*.*\*\/\s*\)*'
let s:js_keywords = s:line_pre . '\%(break\|catch\|const\|continue\|debugger\|delete\|do\|else\|finally\|for\|function\|if\|in\|instanceof\|let\|new\|return\|switch\|this\|throw\|try\|typeof\|var\|void\|while\|with\)\>\C'
let s:expr_case = s:line_pre . '\%(case\s\+[^\:]*\|default\)\s*:\s*\C'
" Regex of syntax group names that are or delimit string or are comments.
let s:syng_strcom = '\%(string\|regex\|comment\|template\)\c'

" Regex of syntax group names that are strings.
let s:syng_string = 'regex\c'

" Regex of syntax group names that are strings or documentation.
let s:syng_multiline = '\%(comment\|doc\)\c'

" Regex of syntax group names that are line comment.
let s:syng_linecom = 'linecomment\c'

" Expression used to check whether we should skip a match with searchpair().
let s:skip_expr = "synIDattr(synID(line('.'),col('.'),1),'name') =~ '".s:syng_strcom."'"

let s:line_term = '\s*\%(\%(\/\/.*\)\=\|\%(\/\*.*\*\/\s*\)*\)$'

" Regex that defines continuation lines, not including (, {, or [.
let s:continuation_regex = '\%([*.?:]\|+\@<!+\|-\@<!-\|\*\@<!\/\|=\|||\|&&\)' . s:line_term

let s:one_line_scope_regex = '\%(\<else\>\|=>\)\C' . s:line_term

function s:Onescope(lnum)
  if getline(a:lnum) =~ s:one_line_scope_regex
    return 1
  end
  let mypos = col('.')
  call cursor(a:lnum, 1)
  if search('\<\%(while\|for\|if\)\>\s*(\C', 'ce', a:lnum) > 0 && searchpair('(', '', ')', 'W', s:skip_expr, a:lnum) > 0 && col('.') == strlen(s:RemoveTrailingComments(getline(a:lnum)))
    call cursor(a:lnum, mypos)
    return 1
  else
    call cursor(a:lnum, mypos)
    return 0
  end
endfunction

" Regex that defines blocks.
let s:block_regex = '[{([]' . s:line_term

let s:operator_first = s:line_pre . '\%([.:?]\|\([-/+*]\)\%(\1\|\*\|\/\)\@!\|||\|&&\)'

let s:var_stmt = s:line_pre . '\%(const\|let\|var\)\s\+\C'

let s:comma_first = s:line_pre . ','
let s:comma_last = ',' . s:line_term

" 2. Auxiliary Functions {{{1
" ======================

" Check if the character at lnum:col is inside a string, comment, or is ascii.
function s:IsInStringOrComment(lnum, col)
  return synIDattr(synID(a:lnum, a:col, 1), 'name') =~ s:syng_strcom
endfunction

" Check if the character at lnum:col is inside a string.
function s:IsInString(lnum, col)
  return synIDattr(synID(a:lnum, a:col, 1), 'name') =~ s:syng_string
endfunction

" Check if the character at lnum:col is inside a multi-line comment.
function s:IsInMultilineComment(lnum, col)
  return !s:IsLineComment(a:lnum, a:col) && synIDattr(synID(a:lnum, a:col, 1), 'name') =~ s:syng_multiline
endfunction

" Check if the character at lnum:col is a line comment.
function s:IsLineComment(lnum, col)
  return synIDattr(synID(a:lnum, a:col, 1), 'name') =~ s:syng_linecom
endfunction

" Find line above 'lnum' that isn't empty, in a comment, or in a string.
function s:PrevNonBlankNonString(lnum)
  let in_block = 0
  let lnum = prevnonblank(a:lnum)
  while lnum > 0
    " Go in and out of blocks comments as necessary.
    " If the line isn't empty (with opt. comment) or in a string, end search.
    let line = getline(lnum)
    if s:IsInMultilineComment(lnum, matchend(line, '^\s*/\*') - 1) && line !~ s:line_pre . '$'
      if in_block
        let in_block = 0
      else
        break
      endif
    elseif !in_block && s:IsInMultilineComment(lnum, match(line, '\*/\s*$') + 1) && line !~ s:line_pre . '$'
      let in_block = 1
    elseif !in_block && line !~ s:line_pre . '\%(//\).*$' && !(s:IsInStringOrComment(lnum, 1) && s:IsInStringOrComment(lnum, strlen(line)))
      break
    endif
    let lnum = prevnonblank(lnum - 1)
  endwhile
  return lnum
endfunction

" Find line above 'lnum' that started the continuation 'lnum' may be part of.
function s:GetMSL(lnum, in_one_line_scope)
  " Start on the line we're at and use its indent.
  let msl = a:lnum
  let lnum = s:PrevNonBlankNonString(a:lnum - 1)
  while lnum > 0
    " If we have a continuation line, or we're in a string, use line as MSL.
    " Otherwise, terminate search as we have found our MSL already.
    let line = getline(lnum)
    let col = match(line, s:continuation_regex) + 1
    let line2 = getline(msl)
    let col2 = matchend(line2, ')')
    if (col > 0 && !s:IsInStringOrComment(lnum, col) && !s:Match(lnum, s:expr_case)) || s:IsInString(lnum, strlen(line))
      let msl = lnum

    " if there are more closing brackets, continue from the line which has the matching opening bracket
    elseif col2 > 0 && !s:IsInStringOrComment(msl, col2) && s:LineHasOpeningBrackets(msl)[0] == '2' && !a:in_one_line_scope
      call cursor(msl, 1)
      if searchpair('(', '', ')', 'bW', s:skip_expr) > 0
        let lnum = line('.')
        let msl = lnum
      endif

    else

      " Don't use lines that are part of a one line scope as msl unless the
      " flag in_one_line_scope is set to 1
      "
      if a:in_one_line_scope
        break
      end
      let msl_one_line = s:Onescope(lnum)
      if msl_one_line == 0
        break
      endif
    end
    let lnum = s:PrevNonBlankNonString(lnum - 1)
  endwhile
  return msl
endfunction

function s:RemoveTrailingComments(content)
  let single = '\/\/\%(.*\)\s*$'
  let multi = '\/\*\%(.*\)\*\/\s*$'
  return substitute(substitute(substitute(a:content, single, '', ''), multi, '', ''), '\s\+$', '', '')
endfunction

" Find if the string is inside var statement (but not the first string)
function s:InMultiVarStatement(lnum, cont, prev)
  let lnum = s:PrevNonBlankNonString(a:lnum - 1)

  "  let type = synIDattr(synID(lnum, indent(lnum) + 1, 0), 'name')

  " loop through previous expressions to find a var statement
  while lnum > 0 && (s:Match(lnum, s:comma_last) || (a:cont && getline(lnum) =~ s:line_pre . '}') || (a:prev && s:Match(a:prev, s:comma_last)))
    " if the line is a js keyword
    if a:cont
      call cursor(lnum,1)
      if searchpair('{', '', '}', 'bW', s:skip_expr) > 0
        let lnum = line('.')
      end
    end
    if s:Match(lnum, s:js_keywords)
      " check if the line is a var stmt
      " if the line has a comma first or comma last then we can assume that we
      " are in a multiple var statement
      if s:Match(lnum, s:var_stmt) && s:Match(lnum, s:comma_last)
        return lnum
      endif

      " other js keywords, not a var
      if !s:Match(lnum, s:comma_last)
        return 0
      end
    endif
    let lnum = s:PrevNonBlankNonString(lnum - 1)
  endwhile

  " beginning of program, not a var
  return 0
endfunction

" Find line above with beginning of the var statement or returns 0 if it's not"{{{2
" this statement
" function s:GetVarIndent(lnum)
"   let lvar = s:InMultiVarStatement(a:lnum, 0,0)
"   let prev_lnum = s:PrevNonBlankNonString(a:lnum - 1)

"   if lvar
"     let line = s:RemoveTrailingComments(getline(prev_lnum))

"     " if the previous line doesn't end in a comma, return to regular indent
"     if (line !~ s:comma_last)
"       return indent(prev_lnum) - s:sw()
"     else
"       return indent(lvar) + s:sw()
"     endif
"   endif

"   return -1
" endfunction"}}}


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

function s:Match(lnum, regex)
  let col = match(getline(a:lnum), a:regex) + 1
  return col > 0 && !s:IsInStringOrComment(a:lnum, col) ? col : 0
endfunction

function s:IndentWithContinuation(lnum, ind, width)
  " Set up variables to use and search for MSL to the previous line.
  let p_lnum = a:lnum
  let lnum = s:GetMSL(a:lnum, 1)
  let line = getline(lnum)

  " If the previous line wasn't a MSL and is continuation return its indent.
  " TODO: the || s:IsInString() thing worries me a bit.
  if p_lnum != lnum
    if s:Match(p_lnum,s:continuation_regex)||s:IsInString(p_lnum,strlen(line))
      return a:ind
    endif
  endif

  " Set up more variables now that we know we aren't continuation bound.
  let msl_ind = indent(lnum)

  " If the previous line ended with [*+/.-=], start a continuation that
  " indents an extra level.
  if s:Match(lnum, s:continuation_regex)
    if lnum == p_lnum
      return msl_ind + a:width
    else
      return msl_ind
    end
  elseif s:InMultiVarStatement(p_lnum, 0, s:PrevNonBlankNonString(p_lnum - 1))
    return indent(p_lnum) - s:sw()
  endif

  return a:ind
endfunction

function s:InOneLineScope(lnum)
  let msl = s:GetMSL(a:lnum, 1)
  if msl > 0 && s:Onescope(msl)
    return msl
  endif
  return 0
endfunction

function s:ExitingOneLineScope(lnum)
  let msl = s:GetMSL(a:lnum, 1)
  if msl > 0
    " if the current line is in a one line scope ..
    if s:Onescope(msl)
      return 0
    else
      let prev_msl = s:GetMSL(msl - 1, 1)
      if s:Onescope(prev_msl)
        return prev_msl
      endif
    endif
  endif
  return 0
endfunction

" 3. GetJavascriptIndent Function {{{1
" =========================

function GetJavascriptIndent()
  " 3.1. Setup {{{1
  " ----------
  " Set up variables for restoring position in file.  Could use v:lnum here.
  let vcol = col('.')

  " 3.2. Work on the current line {{{1
  " -----------------------------

  let ind = -1
  " Get the current line.
  let line = getline(v:lnum)
  " previous nonblank line number
  let prevline = prevnonblank(v:lnum - 1)
  
  " to not change multiline string values 
  if synIDattr(synID(v:lnum, 1, 1), 'name') =~? 'string\|template' && line !~ s:line_pre . '[''"`]'
    return indent(v:lnum)
  endif

  " If we are in a multi-line comment, cindent does the right thing.
  if s:IsInMultilineComment(v:lnum, 1) && !s:IsLineComment(v:lnum, 1) &&
    \ s:IsInMultilineComment(v:lnum, match(line, '\s*$')) && line !~ '^\/\*'
    return cindent(v:lnum)
  endif
  
  " single opening bracket will assume you want a c style of indenting
  if s:Match(v:lnum, s:line_pre . '{' . s:line_term)
    return cindent(v:lnum)
  endif

  " cindent each line which has a switch label
  if (line =~ s:expr_case)
    return cindent(v:lnum)
  endif

  " the part first where we deal with comma first
  if line =~ s:comma_first
    let counts = s:LineHasOpeningBrackets(prevline)
    if (s:Match(prevline, s:var_stmt) || counts[0] == '1' || counts[1] == '1' || counts[2] == '1')
      return indent(prevline) + s:sw()
    end
  end
  " If we got a closing bracket on an empty line, find its match and indent
  " according to it.  For parentheses we indent to its column - 1, for the
  " others we indent to the containing line's MSL's level.  Return -1 if fail.
  let col = matchend(line, s:line_pre . '[],})]')
  if col > 0 && !s:IsInStringOrComment(v:lnum, col)
    call cursor(v:lnum, col)

    let lvar = s:InMultiVarStatement(v:lnum, 0, 0) || line =~ s:comma_first
    if lvar || line =~ s:comma_first

      " check for comma first
      if (line[col - 1] =~ ',')
        " if the previous line ends in comma or semicolon don't indent
        if (getline(prevline) =~ '[;,]' . s:line_term)
          return indent(s:GetMSL(line('.'), 0))
        " get previous line indent, if it's comma first return prevline indent
        elseif s:Match(prevline, s:comma_first)
          return indent(prevline)
        " otherwise we indent 1 level
        else
          return indent(lvar) + s:sw()
        endif
      endif
    endif


    let bs = strpart('(){}[]', stridx(')}]', line[col - 1]) * 2, 2)
    if searchpair(escape(bs[0], '\['), '', bs[1], 'bW', s:skip_expr) > 0
      let ind = s:InMultiVarStatement(line('.'), 0, 0) ? indent(line('.')) : indent(s:GetMSL(line('.'), 0))
    endif
    return ind
  endif

  " If the line is comma first, dedent 1 level
  if s:Match(prevline, s:comma_first)
    return indent(prevline) - s:sw()
  end

  " If line starts with an operator...
  if (line =~ s:operator_first)
    if (s:Match(prevline, s:operator_first))
      " and so does previous line, don't indent
      return indent(prevline)
    end
    let counts = s:LineHasOpeningBrackets(prevline)
    if counts[0] == '2'
      call cursor(prevline, 1)
      " Search for the opening tag
      let mnum = searchpair('(', '', ')', 'bW', s:skip_expr)
      if mnum > 0 && s:Match(mnum, s:operator_first)
        return indent(mnum)
      end
    elseif counts[0] != '1' && counts[1] != '1' && counts[2] != '1'
      " otherwise, indent 1 level
      return indent(prevline) + s:sw()
    end
    " If previous line starts with an operator...
  elseif (s:Match(prevline, s:operator_first) && getline(prevline) !~ s:comma_last && getline(prevline) !~ '};\=' . s:line_term) || getline(prevline) =~ ');\=' . s:line_term
    let counts = s:LineHasOpeningBrackets(prevline)
    if counts[0] == '2' && !s:Match(prevline, s:operator_first)
      call cursor(prevline, 1)
      " Search for the opening tag
      let mnum = searchpair('(', '', ')', 'bW', s:skip_expr)
      if mnum > 0 && s:Match(mnum, s:operator_first)
        return indent(mnum) - s:sw()
      end
    elseif s:Match(prevline, s:operator_first)
      if counts[0] == '2' && counts[1] == '1'
        call cursor(prevline, 1)
        " Search for the opening tag
        let mnum = searchpair('(', '', ')', 'bW', s:skip_expr)
        if mnum > 0 && !s:Match(mnum, s:operator_first)
          return indent(mnum) + s:sw()
        end
      elseif counts[0] != '1' && counts[1] != '1' && counts[2] != '1'
        return indent(prevline) - s:sw()
      end
    end
  end

  " 3.3. Work on the previous line. {{{1
  " -------------------------------

  " If the line is empty and the previous nonblank line was a multi-line
  " comment, use that comment's indent. Deduct one char to account for the
  " space in ' */'.
  if line =~ '^\s*$' && s:IsInMultilineComment(prevline, 1)
    return indent(prevline) - 1
  endif

  " Find a non-blank, non-multi-line string line above the current line.
  let lnum = s:PrevNonBlankNonString(v:lnum - 1)

  " If the line is empty and inside a string, use the previous line.
  if line =~ '^\s*$' && lnum != prevline
    return indent(prevnonblank(v:lnum))
  endif

  " At the start of the file use zero indent.
  if lnum == 0
    return 0
  endif


  " If the previous line ended with a block opening, add a level of indent.
  if s:Match(lnum, s:block_regex)
    return s:InMultiVarStatement(lnum, 0, 0) ? indent(lnum) + s:sw() : indent(s:GetMSL(lnum, 0)) + s:sw()
  endif

  " Set up variables for current line.
  let line = getline(lnum)
  let ind = indent(lnum)
  " If the previous line contained an opening bracket, and we are still in it,
  " add indent depending on the bracket type.
  if s:Match(lnum, '[[({})\]]')
    let counts = s:LineHasOpeningBrackets(lnum)
    if counts[0] == '2'
      call cursor(lnum, 1)
      " Search for the opening tag
      if searchpair('(', '', ')', 'bW', s:skip_expr) > 0
        return indent(s:GetMSL(line('.'), 0)) 
      end
    elseif counts[1] == '2' && !s:Match(lnum, s:line_pre . '}')
      call cursor(lnum, 1)
      " Search for the opening tag
      if searchpair('{', '', '}', 'bW', s:skip_expr) > 0
        return indent(s:GetMSL(line('.'), 0)) 
      end
    elseif counts[2] == '2' && !s:Match(lnum, s:line_pre . ']')
      call cursor(lnum, 1)
      " Search for the opening tag
      if searchpair('\[', '', '\]', 'bW', s:skip_expr) > 0
        return indent(s:GetMSL(line('.'), 0)) 
      end
    elseif counts[1] == '1' || counts[2] == '1' || counts[0] == '1' || s:Onescope(lnum)
      return ind + s:sw()
    else
      call cursor(v:lnum, vcol)
    end
  end

  " 3.4. Work on the MSL line. {{{1
  " --------------------------
  if s:Match(lnum, s:comma_last) && !s:Match(lnum,  s:continuation_regex)
    return s:Match(lnum, s:var_stmt) ? indent(lnum) + s:sw() : indent(lnum)

  elseif s:Match(s:PrevNonBlankNonString(lnum - 1), s:comma_last)
    if !s:Match(lnum, s:comma_last) && s:InMultiVarStatement(lnum,1,0)
      return indent(lnum) - s:sw()
    end
  end
  let ind_con = ind
  let ind = s:IndentWithContinuation(lnum, ind_con, s:sw())

  " }}}2
  "
  "
  let ols = s:InOneLineScope(lnum)
  if ols > 0
    let ind = ind + s:sw()
  else
    let ols = s:ExitingOneLineScope(lnum)
    while ols > 0 && ind > 0
      let ind = ind - s:sw()
      let ols = s:InOneLineScope(ols - 1)
    endwhile
  endif

  return ind
endfunction

" }}}1

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
    if s:IsLineComment(a:lnum, l:first_char) || s:IsInMultilineComment(a:lnum, l:first_char)
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
