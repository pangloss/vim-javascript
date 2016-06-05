" Vim syntax file
" Language:     JavaScript
" Maintainer:   vim-javascript community
" URL:          https://github.com/pangloss/vim-javascript

if !exists("main_syntax")
  if version < 600
    syntax clear
  elseif exists("b:current_syntax")
    finish
  endif
  let main_syntax = 'javascript'
endif

if !exists('g:javascript_conceal')
  let g:javascript_conceal = 0
endif

"" dollar sign is permittd anywhere in an identifier
setlocal iskeyword+=$

syntax sync fromstart
" TODO: Figure out what type of casing I need
" syntax case ignore
syntax case match

syntax match   jsNoise           /[:,\;\.]\{1}/
syntax match   jsFuncCall         /\k\+\%(\s*(\)\@=/
syntax match   jsParensError    /\%()\|}\|\]\)/

"" Program Keywords
syntax keyword jsStorageClass   const var let
syntax keyword jsOperator       delete instanceof typeof void new in
syntax match   jsOperator       /[\!\|\&\+\-\<\>\=\%\/\*\~\^]\{1}/
syntax keyword jsBooleanTrue    true
syntax keyword jsBooleanFalse   false
syntax keyword jsModules        import export contained
" TODO: Not sure if jsObjectBlock should be nextgroup here
syntax keyword jsModules        export contained nextgroup=jsObjectBlock skipwhite skipempty
syntax keyword jsModuleWords    from as contained
syntax keyword jsModuleWords    default contained nextgroup=jsObjectBlock skipwhite skipempty
syntax keyword jsOf             of contained
syntax keyword jsArgsObj        arguments

syntax region jsImportContainer      start="^\s\?import \?" end=";\|$" contains=jsModules,jsModuleWords,jsComment,jsString,jsTemplateString,jsNoise,jsBlock
syntax region jsExportContainer      start="^\s\?export \?" end="$" contains=jsModules,jsModuleWords,jsComment,jsTemplateString,jsString,jsRegexpString,jsNumber,jsFloat,jsThis,jsOperator,jsBooleanTrue,jsBooleanFalse,jsNull,jsFunction,jsArrowFunction,jsGlobalObjects,jsExceptions,jsDomErrNo,jsDomNodeConsts,jsHtmlEvents,jsDotNotation,jsBracket,jsParen,jsFuncCall,jsUndefined,jsNan,jsStorageClass,jsPrototype,jsBuiltins,jsNoise,jsArgsObj,jsBlock,jsClassDefinition

"" JavaScript comments
syntax keyword jsCommentTodo    TODO FIXME XXX TBD contained
syntax region  jsComment        start=+\/\/+ end=+$+ keepend contains=jsCommentTodo,@Spell extend
syntax region  jsComment        start=+^\s*\/\/+ skip=+\n\s*\/\/+ end=+$+ keepend contains=jsCommentTodo,@Spell fold
syntax region  jsComment        start="/\*"  end="\*/" contains=jsCommentTodo,jsCvsTag,@Spell fold extend
syntax region  jsEnvComment     start="\%^#!" end="$" display
syntax region  jsCvsTag         start="\$\cid:" end="\$" oneline contained

"" JSDoc / JSDoc Toolkit
if !exists("javascript_ignore_javaScriptdoc")
  "" syntax coloring for javadoc comments (HTML)
  syntax region jsComment    matchgroup=jsComment start="/\*\s*"  end="\*/" contains=jsDocTags,jsCommentTodo,jsCvsTag,@jsHtml,@Spell fold

  " tags containing a param
  syntax match  jsDocTags         contained "@\(alias\|api\|augments\|borrows\|class\|constructs\|default\|defaultvalue\|emits\|exception\|exports\|extends\|fires\|kind\|link\|listens\|member\|member[oO]f\|mixes\|module\|name\|namespace\|requires\|template\|throws\|var\|variation\|version\)\>" nextgroup=jsDocParam skipwhite
  " tags containing type and param
  syntax match  jsDocTags         contained "@\(arg\|argument\|cfg\|param\|property\|prop\)\>" nextgroup=jsDocType skipwhite
  " tags containing type but no param
  syntax match  jsDocTags         contained "@\(callback\|define\|enum\|external\|implements\|this\|type\|typedef\|return\|returns\)\>" nextgroup=jsDocTypeNoParam skipwhite
  " tags containing references
  syntax match  jsDocTags         contained "@\(lends\|see\|tutorial\)\>" nextgroup=jsDocSeeTag skipwhite
  " other tags (no extra syntax)
  syntax match  jsDocTags         contained "@\(abstract\|access\|accessor\|author\|classdesc\|constant\|const\|constructor\|copyright\|deprecated\|desc\|description\|dict\|event\|example\|file\|file[oO]verview\|final\|function\|global\|ignore\|inheritDoc\|inner\|instance\|interface\|license\|localdoc\|method\|mixin\|nosideeffects\|override\|overview\|preserve\|private\|protected\|public\|readonly\|since\|static\|struct\|todo\|summary\|undocumented\|virtual\)\>"

  syntax region jsDocType         matchgroup=jsDocTypeBrackets start="{" end="}" oneline contained nextgroup=jsDocParam skipwhite contains=jsDocTypeRecord
  syntax match  jsDocType         contained "\%(#\|\"\|\w\|\.\|:\|\/\)\+" nextgroup=jsDocParam skipwhite
  syntax region jsDocTypeRecord   start=/{/ end=/}/ contained extend contains=jsDocTypeRecord
  syntax region jsDocTypeRecord   start=/\[/ end=/\]/ contained extend contains=jsDocTypeRecord
  syntax region jsDocTypeNoParam  start="{" end="}" oneline contained
  syntax match  jsDocTypeNoParam  contained "\%(#\|\"\|\w\|\.\|:\|\/\)\+"
  syntax match  jsDocParam        contained "\%(#\|\$\|-\|'\|\"\|{.\{-}}\|\w\|\.\|:\|\/\|\[.{-}]\|=\)\+"
  syntax region jsDocSeeTag       contained matchgroup=jsDocSeeTag start="{" end="}" contains=jsDocTags
endif   "" JSDoc end

" Strings, Templates, Numbers
syntax region  jsString           start=+"+  skip=+\\\("\|$\)+  end=+"\|$+  contains=jsSpecial,@htmlPreproc,@Spell
syntax region  jsString           start=+'+  skip=+\\\('\|$\)+  end=+'\|$+  contains=jsSpecial,@htmlPreproc,@Spell
syntax region  jsTemplateString   start=+`+  skip=+\\\(`\|$\)+  end=+`+     contains=jsTemplateVar,jsSpecial,@htmlPreproc
syntax region  jsTaggedTemplate   start=/\k\+\%([\n\s]\+\)\?`/ end=+`+ contains=jsTemplateString keepend
syntax match   jsNumber           /\<-\=\d\+\(L\|[eE][+-]\=\d\+\)\=\>\|\<0[xX]\x\+\>/
syntax keyword jsNumber           Infinity
syntax match   jsFloat            /\<-\=\%(\d\+\.\d\+\|\d\+\.\|\.\d\+\)\%([eE][+-]\=\d\+\)\=\>/

" Regular Expressions
syntax match   jsSpecial          "\v\\%(0|\\x\x\{2\}\|\\u\x\{4\}\|\c[A-Z]|.)" contained
syntax region  jsTemplateVar      matchgroup=jsTemplateBraces start=+${+ end=+}+ contained contains=@jsExpression
syntax region  jsRegexpCharClass  start=+\[+ skip=+\\.+ end=+\]+ contained
syntax match   jsRegexpBoundary   "\v%(\<@![\^$]|\\[bB])" contained
syntax match   jsRegexpBackRef    "\v\\[1-9][0-9]*" contained
syntax match   jsRegexpQuantifier "\v\\@<!%([?*+]|\{\d+%(,|,\d+)?})\??" contained
syntax match   jsRegexpOr         "\v\<@!\|" contained
syntax match   jsRegexpMod        "\v\(@<=\?[:=!>]" contained
syntax cluster jsRegexpSpecial    contains=jsSpecial,jsRegexpBoundary,jsRegexpBackRef,jsRegexpQuantifier,jsRegexpOr,jsRegexpMod
syntax region  jsRegexpGroup      start="\\\@<!(" skip="\\.\|\[\(\\.\|[^]]\)*\]" end="\\\@<!)" contained contains=jsRegexpCharClass,@jsRegexpSpecial keepend
if v:version > 703 || v:version == 603 && has("patch1088")
  syntax region  jsRegexpString     start=+\%(\%(\%(return\|case\)\s\+\)\@50<=\|\%(\%([)\]"']\|\d\|\w\)\s*\)\@50<!\)/\(\*\|/\)\@!+ skip=+\\.\|\[\%(\\.\|[^]]\)*\]+ end=+/[gimy]\{,4}+ contains=jsRegexpCharClass,jsRegexpGroup,@jsRegexpSpecial,@htmlPreproc oneline keepend
else
  syntax region  jsRegexpString     start=+\%(\%(\%(return\|case\)\s\+\)\@<=\|\%(\%([)\]"']\|\d\|\w\)\s*\)\@<!\)/\(\*\|/\)\@!+ skip=+\\.\|\[\%(\\.\|[^]]\)*\]+ end=+/[gimy]\{,4}+ contains=jsRegexpCharClass,jsRegexpGroup,@jsRegexpSpecial,@htmlPreproc oneline keepend
endif

syntax match   jsObjectKey        /\<[a-zA-Z_$][0-9a-zA-Z_$]*\>\(\s*:\)\@=/ contains=jsFunctionKey contained
syntax match   jsFunctionKey      /\<[a-zA-Z_$][0-9a-zA-Z_$]*\>\(\s*:\s*function\s*\)\@=/ contained
" TODO: Put this in jsClassBlock only
syntax match   jsDecorator        "@" display contains=jsDecoratorFunction nextgroup=jsDecoratorFunction skipwhite
syntax match   jsDecoratorFunction "[a-zA-Z_][a-zA-Z0-9_.]*" display contained nextgroup=jsFunc skipwhite

exe 'syntax keyword jsNull      null      '.(exists('g:javascript_conceal_null')        ? 'conceal cchar='.g:javascript_conceal_null        : '')
exe 'syntax keyword jsReturn    return    '.(exists('g:javascript_conceal_return')      ? 'conceal cchar='.g:javascript_conceal_return      : '')
exe 'syntax keyword jsUndefined undefined '.(exists('g:javascript_conceal_undefined')   ? 'conceal cchar='.g:javascript_conceal_undefined   : '')
exe 'syntax keyword jsNan       NaN       '.(exists('g:javascript_conceal_NaN')         ? 'conceal cchar='.g:javascript_conceal_NaN         : '')
exe 'syntax keyword jsPrototype prototype '.(exists('g:javascript_conceal_prototype')   ? 'conceal cchar='.g:javascript_conceal_prototype   : '')
exe 'syntax keyword jsThis      this      '.(exists('g:javascript_conceal_this')        ? 'conceal cchar='.g:javascript_conceal_this        : '')
exe 'syntax keyword jsStatic    static    '.(exists('g:javascript_conceal_static')      ? 'conceal cchar='.g:javascript_conceal_static      : '')
exe 'syntax keyword jsSuper     super     '.(exists('g:javascript_conceal_super')       ? 'conceal cchar='.g:javascript_conceal_super       : '')

" Statement Keywords
syntax keyword jsStatement      break continue with yield
" TODO: Create special block regions for these 2 lines
syntax keyword jsConditional    if else switch
syntax keyword jsRepeat         do while for
" TODO: Contain these in Switch block only
syntax keyword jsLabel          case default
" TODO: Create try/catch blocks
syntax keyword jsException      try catch throw finally
syntax keyword jsAsyncKeyword   async await

" Keywords
syntax keyword jsGlobalObjects  Array Boolean Date Function Iterator Number Object Symbol Map WeakMap Set RegExp String Proxy Promise Buffer ParallelArray ArrayBuffer DataView Float32Array Float64Array Int16Array Int32Array Int8Array Uint16Array Uint32Array Uint8Array Uint8ClampedArray JSON Math console document window Intl Collator DateTimeFormat NumberFormat
syntax keyword jsExceptions     Error EvalError InternalError RangeError ReferenceError StopIteration SyntaxError TypeError URIError
syntax keyword jsBuiltins       decodeURI decodeURIComponent encodeURI encodeURIComponent eval isFinite isNaN parseFloat parseInt uneval
syntax keyword jsFutureKeys     abstract enum int short boolean interface byte long char final native synchronized float package throws goto private transient debugger implements protected volatile double public

"" DOM2 Objects
syntax keyword jsGlobalObjects  DOMImplementation DocumentFragment Document Node NodeList NamedNodeMap CharacterData Attr Element Text Comment CDATASection DocumentType Notation Entity EntityReference ProcessingInstruction
syntax keyword jsExceptions     DOMException

"" DOM2 CONSTANT
syntax keyword jsDomErrNo       INDEX_SIZE_ERR DOMSTRING_SIZE_ERR HIERARCHY_REQUEST_ERR WRONG_DOCUMENT_ERR INVALID_CHARACTER_ERR NO_DATA_ALLOWED_ERR NO_MODIFICATION_ALLOWED_ERR NOT_FOUND_ERR NOT_SUPPORTED_ERR INUSE_ATTRIBUTE_ERR INVALID_STATE_ERR SYNTAX_ERR INVALID_MODIFICATION_ERR NAMESPACE_ERR INVALID_ACCESS_ERR
syntax keyword jsDomNodeConsts  ELEMENT_NODE ATTRIBUTE_NODE TEXT_NODE CDATA_SECTION_NODE ENTITY_REFERENCE_NODE ENTITY_NODE PROCESSING_INSTRUCTION_NODE COMMENT_NODE DOCUMENT_NODE DOCUMENT_TYPE_NODE DOCUMENT_FRAGMENT_NODE NOTATION_NODE

"" HTML events and internal variables
syntax keyword jsHtmlEvents     onblur onclick oncontextmenu ondblclick onfocus onkeydown onkeypress onkeyup onmousedown onmousemove onmouseout onmouseover onmouseup onresize

"" Code blocks
" TODO: This should really only be for arrays... figure out the array scope better
syntax region  jsBracket     matchgroup=jsBrackets     start="\[" end="\]" contains=@jsAll,jsParensError,jsBracket,jsParen,jsBlock,@htmlPreproc fold
" TODO: This is a region to create jsParensErrors. We'll need to create special contained regions for if/else/switch statements
syntax region  jsParen       matchgroup=jsParens       start="("  end=")"  contains=@jsAll,jsOf,jsParensError,jsParen,jsBracket,jsBlock,@htmlPreproc fold extend
syntax region  jsClassBlock  matchgroup=jsClassBraces  start="{"  end="}"  contains=jsFuncName,jsClassMethodDefinitions,jsOperator,jsArrowFunction,jsArrowFuncArgs,jsComment,jsGenerator contained fold
syntax region  jsFuncBlock   matchgroup=jsFuncBraces   start="{"  end="}"  contains=@jsAll,jsParensError,jsParen,jsBracket,jsBlock,@htmlPreproc,jsClassDefinition fold extend
" TODO: jsBlock should be made ONLY for switch/if/else statements
syntax region  jsBlock       matchgroup=jsBraces       start="{"  end="}"  contains=@jsAll,jsParensError,jsParen,jsBracket,jsBlock,jsObjectKey,@htmlPreproc,jsClassDefinition,jsObjectBlock extend
" TODO: Should NOT include jsAll - should onyl accept aspects for keys, using nextgroup for everything else
syntax region  jsObjectBlock matchgroup=jsObjectBraces      start="\%()[\r\n\t ]*\)\@<!{"  end="}"  contains=@jsAll,jsObjectKey,jsParensError,jsParen,jsNoise extend
syntax region  jsTernaryIf   matchgroup=jsTernaryIfOperator start=+?+  end=+:+  contains=@jsExpression,jsTernaryIf

syntax match   jsGenerator       contained /\*/ nextgroup=jsFuncName,jsFuncArgs skipwhite skipempty
syntax match   jsFuncName        contained /\<[a-zA-Z_$][0-9a-zA-Z_$]*/ nextgroup=jsFuncArgs skipwhite skipempty
" These versions of jsFuncName is for use in object declarations with no key -
" TODO: May not need this at all actually
syntax match   jsFuncName        contained /\%(^[\r\n\t ]*\)\@<=[*\r\n\t ]*[a-zA-Z_$][0-9a-zA-Z_$]*[\r\n\t ]*(\@=/ nextgroup=jsFuncArgs skipwhite skipempty containedin=jsObjectBlock contains=jsGenerator
syntax match   jsFuncName        contained /\%(,[\r\n\t ]*\)\@<=[*\r\n\t ]*[a-zA-Z_$][0-9a-zA-Z_$]*[\r\n\t ]*(\@=/ nextgroup=jsFuncArgs skipwhite skipempty containedin=jsObjectBlock contains=jsGenerator
syntax match   jsFuncArgDestructuring contained /\({\|}\|=\|:\|\[\|\]\)/ extend
syntax region  jsFuncArgs        contained matchgroup=jsFuncParens start='(' end=')' contains=jsFuncArgCommas,jsFuncArgRest,jsComment,jsString,jsNumber,jsFuncArgDestructuring,jsArrowFunction,jsParen,jsArrowFuncArgs nextgroup=jsFuncBlock keepend skipwhite skipempty
syntax match   jsFuncArgCommas   contained ','
syntax match   jsFuncArgRest     contained /\%(\.\.\.[a-zA-Z_$][0-9a-zA-Z_$]*\))/ contains=jsFuncArgRestDots
syntax match   jsFuncArgRestDots contained /\.\.\./

" Matches a single keyword argument with no parens
syntax match   jsArrowFuncArgs  /\k\+\s*\%(=>\)\@=/ skipwhite contains=jsFuncArgs nextgroup=jsArrowFunction extend
" Matches a series of arguments surrounded in parens
syntax match   jsArrowFuncArgs  /([^()]*)\s*\(=>\)\@=/ skipempty skipwhite contains=jsFuncArgs nextgroup=jsArrowFunction extend

exe 'syntax match jsFunction /\<function\>/ nextgroup=jsGenerator,jsFuncName,jsFuncArgs skipwhite '.(exists('g:javascript_conceal_function') ? 'conceal cchar='.g:javascript_conceal_function : '')
exe 'syntax match jsArrowFunction /=>/ skipwhite nextgroup=jsFuncBlock contains=jsFuncBraces '.(exists('g:javascript_conceal_arrow_function') ? 'conceal cchar='.g:javascript_conceal_arrow_function : '')

syntax keyword jsClassKeywords extends class contained
syntax match   jsClassNoise /\./ contained
syntax match   jsClassMethodDefinitions /\%(get\|set\|static\)\%( \k\+\)\@=/ contained nextgroup=jsFuncName skipwhite skipempty
syntax match   jsClassDefinition /\<class\>\%( [a-zA-Z_$][0-9a-zA-Z_$ \n.]*\)*/  contains=jsClassKeywords,jsClassNoise nextgroup=jsClassBlock skipwhite skipempty

" TODO: Look to optimize this, so it can be properly used in nextgroup= stuff
syntax cluster jsExpression  contains=jsComment,jsTaggedTemplate,jsTemplateString,jsString,jsRegexpString,jsNumber,jsFloat,jsThis,jsStatic,jsSuper,jsOperator,jsBooleanTrue,jsBooleanFalse,jsNull,jsFunction,jsArrowFunction,jsGlobalObjects,jsExceptions,jsFutureKeys,jsDomErrNo,jsDomNodeConsts,jsHtmlEvents,jsDotNotation,jsBracket,jsParen,jsObjectBlock,jsBlock,jsFuncCall,jsUndefined,jsNan,jsStorageClass,jsPrototype,jsBuiltins,jsNoise,jsCommonJS,jsImportContainer,jsExportContainer,jsArgsObj,jsDecorator,jsAsyncKeyword,jsClassDefinition,jsArrowFunction,jsArrowFuncArgs
" TODO: This may actually need to be optimized
syntax cluster jsAll         contains=@jsExpression,jsLabel,jsConditional,jsRepeat,jsReturn,jsStatement,jsTernaryIf,jsException

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
  HiLink jsFuncArgRest          Special
  HiLink jsComment              Comment
  HiLink jsEnvComment           PreProc
  HiLink jsCommentTodo          Todo
  HiLink jsCvsTag               Function
  HiLink jsDocTags              Special
  HiLink jsDocSeeTag            Function
  HiLink jsDocType              Type
  HiLink jsDocTypeBrackets      jsDocType
  HiLink jsDocTypeRecord        jsDocType
  HiLink jsDocTypeNoParam       Type
  HiLink jsDocParam             Label
  HiLink jsString               String
  HiLink jsTemplateString       String
  HiLink jsTaggedTemplate       StorageClass
  HiLink jsTernaryIfOperator    Conditional
  HiLink jsRegexpString         String
  HiLink jsRegexpBoundary       SpecialChar
  HiLink jsRegexpQuantifier     SpecialChar
  HiLink jsRegexpOr             Conditional
  HiLink jsRegexpMod            SpecialChar
  HiLink jsRegexpBackRef        SpecialChar
  HiLink jsRegexpGroup          jsRegexpString
  HiLink jsRegexpCharClass      Character
  HiLink jsCharacter            Character
  HiLink jsPrototype            Special
  HiLink jsConditional          Conditional
  HiLink jsBranch               Conditional
  HiLink jsLabel                Label
  HiLink jsReturn               Statement
  HiLink jsRepeat               Repeat
  HiLink jsStatement            Statement
  HiLink jsException            Exception
  HiLink jsAsyncKeyword         Keyword
  HiLink jsArrowFunction        Type
  HiLink jsFunction             Type
  HiLink jsGenerator            jsFunction
  HiLink jsArrowFuncArgs        jsFuncArgs
  HiLink jsFuncName             Function
  HiLink jsArgsObj              Special
  HiLink jsError                Error
  HiLink jsParensError          Error
  HiLink jsOperator             Operator
  HiLink jsOf                   Operator
  HiLink jsStorageClass         StorageClass
  HiLink jsClassKeywords        Structure
  HiLink jsThis                 Special
  HiLink jsStatic               Special
  HiLink jsSuper                Special
  HiLink jsNan                  Number
  HiLink jsNull                 Type
  HiLink jsUndefined            Type
  HiLink jsNumber               Number
  HiLink jsFloat                Float
  HiLink jsBooleanTrue          Boolean
  HiLink jsBooleanFalse         Boolean
  HiLink jsNoise                Noise
  HiLink jsBrackets             Noise
  HiLink jsParens               Noise
  HiLink jsBraces               Noise
  HiLink jsFuncBraces           Noise
  HiLink jsFuncParens           Noise
  HiLink jsClassBraces          Noise
  HiLink jsClassNoise           Noise
  HiLink jsObjectBraces         Noise
  HiLink jsSpecial              Special
  HiLink jsTemplateVar          Special
  HiLink jsTemplateBraces       jsBraces
  HiLink jsGlobalObjects        Special
  HiLink jsExceptions           Special
  HiLink jsFutureKeys           Special
  HiLink jsBuiltins             Special
  HiLink jsModules              Include
  HiLink jsModuleWords          Include
  HiLink jsDecorator            Special
  HiLink jsFuncArgRestDots      Noise
  HiLink jsFuncArgDestructuring Noise

  HiLink jsDomErrNo             Constant
  HiLink jsDomNodeConsts        Constant
  HiLink jsDomElemAttrs         Label
  HiLink jsDomElemFuncs         PreProc

  HiLink jsHtmlEvents           Special
  HiLink jsHtmlElemAttrs        Label
  HiLink jsHtmlElemFuncs        PreProc

  HiLink jsCssStyles            Label

  HiLink jsClassMethodDefinitions Type

  delcommand HiLink
endif

" Define the htmlJavaScript for HTML syntax html.vim
syntax cluster  htmlJavaScript       contains=@jsAll,jsBracket,jsParen,jsBlock
syntax cluster  javaScriptExpression contains=@jsAll,jsBracket,jsParen,jsBlock,@htmlPreproc

" Vim's default html.vim highlights all javascript as 'Special'
hi! def link javaScript              NONE

let b:current_syntax = "javascript"
if main_syntax == 'javascript'
  unlet main_syntax
endif
