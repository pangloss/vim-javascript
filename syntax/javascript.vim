" Vim syntax file
" Language:     JavaScript
" Maintainer:   Yi Zhao (ZHAOYI) <zzlinux AT hotmail DOT com>
" Last Change By: Marc Harter
" Last Change:  February 18, 2011
" Version:      0.7.9
" Changes:      Updates JSDoc syntax
"
" TODO:
"  - Add the HTML syntax inside the JSDoc

if !exists("main_syntax")
  if version < 600
    syntax clear
  elseif exists("b:current_syntax")
    finish
  endif
  let main_syntax = 'javascript'
endif

"" Drop fold if it is set but VIM doesn't support it.
let b:javascript_fold='true'
if version < 600    " Don't support the old version
  unlet! b:javascript_fold
endif

"" dollar sign is permittd anywhere in an identifier
setlocal iskeyword+=$

syntax sync fromstart

"" JavaScript comments
syntax keyword javaScriptCommentTodo    TODO FIXME XXX TBD contained
syntax region  javaScriptLineComment    start=+\/\/+ end=+$+ keepend contains=javaScriptCommentTodo,@Spell
syntax region  javaScriptEnvComment     start="\%^#!" end="$" display
syntax region  javaScriptLineComment    start=+^\s*\/\/+ skip=+\n\s*\/\/+ end=+$+ keepend contains=javaScriptCommentTodo,@Spell fold
syntax region  javaScriptCvsTag         start="\$\cid:" end="\$" oneline contained
syntax region  javaScriptComment        start="/\*"  end="\*/" contains=javaScriptCommentTodo,javaScriptCvsTag,@Spell fold

"" JSDoc / JSDoc Toolkit
if !exists("javascript_ignore_javaScriptdoc")
  syntax case ignore

  "" syntax coloring for javadoc comments (HTML)
  "syntax include @javaHtml <sfile>:p:h/html.vim
  "unlet b:current_syntax

  syntax region javaScriptDocComment      matchgroup=javaScriptComment start="/\*\*\s*"  end="\*/" contains=javaScriptDocTags,javaScriptCommentTodo,javaScriptCvsTag,@javaScriptHtml,@Spell fold

  " tags containing a param
  syntax match  javaScriptDocTags         contained "@\(augments\|base\|borrows\|class\|constructs\|default\|exception\|exports\|extends\|file\|member\|memberOf\|module\|name\|namespace\|optional\|requires\|title\|throws\|version\)\>" nextgroup=javaScriptDocParam skipwhite
  " tags containing type and param
  syntax match  javaScriptDocTags         contained "@\(argument\|param\|property\)\>" nextgroup=javaScriptDocType skipwhite
  " tags containing type but no param
  syntax match  javaScriptDocTags         contained "@\(type\|return\|returns\)\>" nextgroup=javaScriptDocTypeNoParam skipwhite
  " tags containing references
  syntax match  javaScriptDocTags         contained "@\(lends\|link\|see\)\>" nextgroup=javaScriptDocSeeTag skipwhite
  " other tags (no extra syntax)
  syntax match  javaScriptDocTags         contained "@\(access\|addon\|alias\|author\|beta\|constant\|constructor\|copyright\|deprecated\|description\|event\|example\|exec\|field\|fileOverview\|fileoverview\|function\|global\|ignore\|inner\|license\|overview\|private\|protected\|project\|public\|readonly\|since\|static\)\>"

  syntax region javaScriptDocType         start="{" end="}" oneline contained nextgroup=javaScriptDocParam skipwhite
  syntax match  javaScriptDocType         contained "\%(#\|\"\|\w\|\.\|:\|\/\)\+" nextgroup=javaScriptDocParam skipwhite
  syntax region javaScriptDocTypeNoParam  start="{" end="}" oneline contained
  syntax match  javaScriptDocTypeNoParam  contained "\%(#\|\"\|\w\|\.\|:\|\/\)\+"
  syntax match  javaScriptDocParam        contained "\%(#\|\"\|{\|}\|\w\|\.\|:\|\/\)\+"
  syntax region javaScriptDocSeeTag       contained matchgroup=javaScriptDocSeeTag start="{" end="}" contains=javaScriptDocTags

  syntax case match
endif   "" JSDoc end

syntax case match

"" Syntax in the JavaScript code
syntax match   javaScriptSpecial        "\\\d\d\d\|\\x\x\{2\}\|\\u\x\{4\}\|\\."
syntax region  javaScriptStringD        start=+"+  skip=+\\\\\|\\$"+  end=+"+  contains=javaScriptSpecial,@htmlPreproc
syntax region  javaScriptStringS        start=+'+  skip=+\\\\\|\\$'+  end=+'+  contains=javaScriptSpecial,@htmlPreproc
syntax region  javaScriptRegexpCharClass start=+\[+ end=+\]+ contained
syntax region  javaScriptRegexpString   start=+\(\(\(return\|case\)\s\+\)\@<=\|\(\([)\]"']\|\d\|\w\)\s*\)\@<!\)/\(\*\|/\)\@!+ skip=+\\\\\|\\/+ end=+/[gimy]\{,4}+ contains=javaScriptSpecial,javaScriptRegexpCharClass,@htmlPreproc oneline
syntax match   javaScriptNumber         /\<-\=\d\+L\=\>\|\<0[xX]\x\+\>/
syntax match   javaScriptFloat          /\<-\=\%(\d\+\.\d\+\|\d\+\.\|\.\d\+\)\%([eE][+-]\=\d\+\)\=\>/
syntax match   javaScriptLabel          /\<\w\+\(\s*:\)\@=/

"" JavaScript Prototype
syntax keyword javaScriptPrototype      prototype

"" Program Keywords
syntax keyword javaScriptSource         import export
syntax keyword javaScriptType           const undefined var void yield 
syntax keyword javaScriptOperator       delete new in instanceof let typeof
syntax keyword javaScriptBoolean        true false
syntax keyword javaScriptNull           null
syntax keyword javaScriptThis           this

"" Statement Keywords
syntax keyword javaScriptConditional    if else
syntax keyword javaScriptRepeat         do while for
syntax keyword javaScriptBranch         break continue switch case default return
syntax keyword javaScriptStatement      try catch throw with finally

syntax keyword javaScriptGlobalObjects  Array Boolean Date Function Infinity JavaArray JavaClass JavaObject JavaPackage Math Number NaN Object Packages RegExp String Undefined java netscape sun

syntax keyword javaScriptExceptions     Error EvalError RangeError ReferenceError SyntaxError TypeError URIError

syntax keyword javaScriptFutureKeys     abstract enum int short boolean export interface static byte extends long super char final native synchronized class float package throws goto private transient debugger implements protected volatile double import public

"" DOM/HTML/CSS specified things

  " DOM2 Objects
  syntax keyword javaScriptGlobalObjects  DOMImplementation DocumentFragment Document Node NodeList NamedNodeMap CharacterData Attr Element Text Comment CDATASection DocumentType Notation Entity EntityReference ProcessingInstruction
  syntax keyword javaScriptExceptions     DOMException

  " DOM2 CONSTANT
  syntax keyword javaScriptDomErrNo       INDEX_SIZE_ERR DOMSTRING_SIZE_ERR HIERARCHY_REQUEST_ERR WRONG_DOCUMENT_ERR INVALID_CHARACTER_ERR NO_DATA_ALLOWED_ERR NO_MODIFICATION_ALLOWED_ERR NOT_FOUND_ERR NOT_SUPPORTED_ERR INUSE_ATTRIBUTE_ERR INVALID_STATE_ERR SYNTAX_ERR INVALID_MODIFICATION_ERR NAMESPACE_ERR INVALID_ACCESS_ERR
  syntax keyword javaScriptDomNodeConsts  ELEMENT_NODE ATTRIBUTE_NODE TEXT_NODE CDATA_SECTION_NODE ENTITY_REFERENCE_NODE ENTITY_NODE PROCESSING_INSTRUCTION_NODE COMMENT_NODE DOCUMENT_NODE DOCUMENT_TYPE_NODE DOCUMENT_FRAGMENT_NODE NOTATION_NODE

  " HTML events and internal variables
  syntax case ignore
  syntax keyword javaScriptHtmlEvents     onblur onclick oncontextmenu ondblclick onfocus onkeydown onkeypress onkeyup onmousedown onmousemove onmouseout onmouseover onmouseup onresize
  syntax case match

" Follow stuff should be highligh within a special context
" While it can't be handled with context depended with Regex based highlight
" So, turn it off by default
if exists("javascript_enable_domhtmlcss")

    " DOM2 things
    syntax match javaScriptDomElemAttrs     contained /\%(nodeName\|nodeValue\|nodeType\|parentNode\|childNodes\|firstChild\|lastChild\|previousSibling\|nextSibling\|attributes\|ownerDocument\|namespaceURI\|prefix\|localName\|tagName\)\>/
    syntax match javaScriptDomElemFuncs     contained /\%(insertBefore\|replaceChild\|removeChild\|appendChild\|hasChildNodes\|cloneNode\|normalize\|isSupported\|hasAttributes\|getAttribute\|setAttribute\|removeAttribute\|getAttributeNode\|setAttributeNode\|removeAttributeNode\|getElementsByTagName\|getAttributeNS\|setAttributeNS\|removeAttributeNS\|getAttributeNodeNS\|setAttributeNodeNS\|getElementsByTagNameNS\|hasAttribute\|hasAttributeNS\)\>/ nextgroup=javaScriptParen skipwhite
    " HTML things
    syntax match javaScriptHtmlElemAttrs    contained /\%(className\|clientHeight\|clientLeft\|clientTop\|clientWidth\|dir\|id\|innerHTML\|lang\|length\|offsetHeight\|offsetLeft\|offsetParent\|offsetTop\|offsetWidth\|scrollHeight\|scrollLeft\|scrollTop\|scrollWidth\|style\|tabIndex\|title\)\>/
    syntax match javaScriptHtmlElemFuncs    contained /\%(blur\|click\|focus\|scrollIntoView\|addEventListener\|dispatchEvent\|removeEventListener\|item\)\>/ nextgroup=javaScriptParen skipwhite

    " CSS Styles in JavaScript
    syntax keyword javaScriptCssStyles      contained color font fontFamily fontSize fontSizeAdjust fontStretch fontStyle fontVariant fontWeight letterSpacing lineBreak lineHeight quotes rubyAlign rubyOverhang rubyPosition
    syntax keyword javaScriptCssStyles      contained textAlign textAlignLast textAutospace textDecoration textIndent textJustify textJustifyTrim textKashidaSpace textOverflowW6 textShadow textTransform textUnderlinePosition
    syntax keyword javaScriptCssStyles      contained unicodeBidi whiteSpace wordBreak wordSpacing wordWrap writingMode
    syntax keyword javaScriptCssStyles      contained bottom height left position right top width zIndex
    syntax keyword javaScriptCssStyles      contained border borderBottom borderLeft borderRight borderTop borderBottomColor borderLeftColor borderTopColor borderBottomStyle borderLeftStyle borderRightStyle borderTopStyle borderBottomWidth borderLeftWidth borderRightWidth borderTopWidth borderColor borderStyle borderWidth borderCollapse borderSpacing captionSide emptyCells tableLayout
    syntax keyword javaScriptCssStyles      contained margin marginBottom marginLeft marginRight marginTop outline outlineColor outlineStyle outlineWidth padding paddingBottom paddingLeft paddingRight paddingTop
    syntax keyword javaScriptCssStyles      contained listStyle listStyleImage listStylePosition listStyleType
    syntax keyword javaScriptCssStyles      contained background backgroundAttachment backgroundColor backgroundImage gackgroundPosition backgroundPositionX backgroundPositionY backgroundRepeat
    syntax keyword javaScriptCssStyles      contained clear clip clipBottom clipLeft clipRight clipTop content counterIncrement counterReset cssFloat cursor direction display filter layoutGrid layoutGridChar layoutGridLine layoutGridMode layoutGridType
    syntax keyword javaScriptCssStyles      contained marks maxHeight maxWidth minHeight minWidth opacity MozOpacity overflow overflowX overflowY verticalAlign visibility zoom cssText
    syntax keyword javaScriptCssStyles      contained scrollbar3dLightColor scrollbarArrowColor scrollbarBaseColor scrollbarDarkShadowColor scrollbarFaceColor scrollbarHighlightColor scrollbarShadowColor scrollbarTrackColor

    " Highlight ways
    syntax match javaScriptDotNotation      "\." nextgroup=javaScriptPrototype,javaScriptDomElemAttrs,javaScriptDomElemFuncs,javaScriptHtmlElemAttrs,javaScriptHtmlElemFuncs
    syntax match javaScriptDotNotation      "\.style\." nextgroup=javaScriptCssStyles

endif "DOM/HTML/CSS

"" end DOM/HTML/CSS specified things


"" Code blocks
" there is a name collision with javaScriptExpression in html.vim, hence the use of the '2' here
syntax cluster javaScriptExpression2 contains=javaScriptComment,javaScriptLineComment,javaScriptDocComment,javaScriptStringD,javaScriptStringS,javaScriptRegexpString,javaScriptNumber,javaScriptFloat,javaScriptSource,javaScriptThis,javaScriptType,javaScriptOperator,javaScriptBoolean,javaScriptNull,javaScriptFunction,javaScriptGlobalObjects,javaScriptExceptions,javaScriptFutureKeys,javaScriptDomErrNo,javaScriptDomNodeConsts,javaScriptHtmlEvents,javaScriptDotNotation,javaScriptBracket,javaScriptParen,javaScriptBlock,javaScriptParenError
syntax cluster javaScriptAll       contains=@javaScriptExpression2,javaScriptLabel,javaScriptConditional,javaScriptRepeat,javaScriptBranch,javaScriptStatement,javaScriptTernaryIf
syntax region  javaScriptBracket   matchgroup=javaScriptBracket transparent start="\[" end="\]" contains=@javaScriptAll,javaScriptParensErrB,javaScriptParensErrC,javaScriptBracket,javaScriptParen,javaScriptBlock,@htmlPreproc
syntax region  javaScriptParen     matchgroup=javaScriptParen   transparent start="("  end=")"  contains=@javaScriptAll,javaScriptParensErrA,javaScriptParensErrC,javaScriptParen,javaScriptBracket,javaScriptBlock,@htmlPreproc
syntax region  javaScriptBlock     matchgroup=javaScriptBlock   transparent start="{"  end="}"  contains=@javaScriptAll,javaScriptParensErrA,javaScriptParensErrB,javaScriptParen,javaScriptBracket,javaScriptBlock,@htmlPreproc 
syntax region  javaScriptTernaryIf matchgroup=javaScriptTernaryIfOperator start=+?+  end=+:+  contains=@javaScriptExpression2

"" catch errors caused by wrong parenthesis
syntax match   javaScriptParensError    ")\|}\|\]"
syntax match   javaScriptParensErrA     contained "\]"
syntax match   javaScriptParensErrB     contained ")"
syntax match   javaScriptParensErrC     contained "}"

if main_syntax == "javascript"
  syntax sync clear
  syntax sync ccomment javaScriptComment minlines=200
  syntax sync match javaScriptHighlight grouphere javaScriptBlock /{/
endif

"" Fold control
if exists("b:javascript_fold")
    syntax match   javaScriptFunction       /\<function\>/ nextgroup=javaScriptFuncName skipwhite
    syntax match   javaScriptOpAssign       /=\@<!=/ nextgroup=javaScriptFuncBlock skipwhite skipempty
    syntax region  javaScriptFuncName       contained matchgroup=javaScriptFuncName start=/\%(\$\|\w\)*\s*(/ end=/)/ contains=javaScriptLineComment,javaScriptComment nextgroup=javaScriptFuncBlock skipwhite skipempty
    syntax region  javaScriptFuncBlock      contained matchgroup=javaScriptFuncBlock start="{" end="}" contains=@javaScriptAll,javaScriptParensErrA,javaScriptParensErrB,javaScriptParen,javaScriptBracket,javaScriptBlock fold
else
    syntax keyword javaScriptFunction       function
endif

" Define the default highlighting.
" For version 5.7 and earlier: only when not done already
" For version 5.8 and later: only when an item doesn't have highlighting yet
if version >= 508 || !exists("did_javascript_syn_inits")
  if version < 508
    let did_javascript_syn_inits = 1
    command -nargs=+ HiLink hi link <args>
  else
    command -nargs=+ HiLink hi def link <args>
  endif
  HiLink javaScriptComment              Comment
  HiLink javaScriptLineComment          Comment
  HiLink javaScriptEnvComment           PreProc
  HiLink javaScriptDocComment           Comment
  HiLink javaScriptCommentTodo          Todo
  HiLink javaScriptCvsTag               Function
  HiLink javaScriptDocTags              Special
  HiLink javaScriptDocSeeTag            Function
  HiLink javaScriptDocType              Type
  HiLink javaScriptDocTypeNoParam       Type
  HiLink javaScriptDocParam             Label
  HiLink javaScriptStringS              String
  HiLink javaScriptStringD              String
  HiLink javaScriptTernaryIfOperator    Conditional
  HiLink javaScriptRegexpString         String
  HiLink javaScriptRegexpCharClass      Character
  HiLink javaScriptCharacter            Character
  HiLink javaScriptPrototype            Type
  HiLink javaScriptConditional          Conditional
  HiLink javaScriptBranch               Conditional
  HiLink javaScriptRepeat               Repeat
  HiLink javaScriptStatement            Statement
  HiLink javaScriptFunction             Function
  HiLink javaScriptError                Error
  HiLink javaScriptParensError          Error
  HiLink javaScriptParensErrA           Error
  HiLink javaScriptParensErrB           Error
  HiLink javaScriptParensErrC           Error
  HiLink javaScriptOperator             Operator
  HiLink javaScriptType                 Type
  HiLink javaScriptThis                 Type
  HiLink javaScriptNull                 Type
  HiLink javaScriptNumber               Number
  HiLink javaScriptFloat                Number
  HiLink javaScriptBoolean              Boolean
  HiLink javaScriptLabel                Label
  HiLink javaScriptSpecial              Special
  HiLink javaScriptSource               Special
  HiLink javaScriptGlobalObjects        Special
  HiLink javaScriptExceptions           Special

  HiLink javaScriptDomErrNo             Constant
  HiLink javaScriptDomNodeConsts        Constant
  HiLink javaScriptDomElemAttrs         Label
  HiLink javaScriptDomElemFuncs         PreProc

  HiLink javaScriptHtmlEvents           Special
  HiLink javaScriptHtmlElemAttrs        Label
  HiLink javaScriptHtmlElemFuncs        PreProc

  HiLink javaScriptCssStyles            Label

  delcommand HiLink
endif

" Define the htmlJavaScript for HTML syntax html.vim
"syntax clear htmlJavaScript
"syntax clear javaScriptExpression
syntax cluster  htmlJavaScript contains=@javaScriptAll,javaScriptBracket,javaScriptParen,javaScriptBlock,javaScriptParenError
syntax cluster  javaScriptExpression contains=@javaScriptAll,javaScriptBracket,javaScriptParen,javaScriptBlock,javaScriptParenError,@htmlPreproc
" Vim's default html.vim highlights all javascript as 'Special'
hi! def link javaScript NONE

let b:current_syntax = "javascript"
if main_syntax == 'javascript'
  unlet main_syntax
endif

" vim: ts=4
