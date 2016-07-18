syntax region  jsFlowDefinition     contained                        start=/:/    end=/\%(\s*[,=;)\n]\)\@=/ contains=@jsFlowCluster containedin=jsParen
syntax region  jsFlowArray          contained matchgroup=jsFlowNoise start=/\[/   end=/\]/        contains=@jsFlowCluster
syntax region  jsFlowObject         contained matchgroup=jsFlowNoise start=/{/    end=/}/         contains=@jsFlowCluster
syntax region  jsFlowParens         contained matchgroup=jsFlowNoise start=/(/    end=/)/         contains=@jsFlowCluster
syntax match   jsFlowNoise          contained /[:;,<>]/
syntax keyword jsFlowType           contained boolean number string null void any mixed JSON array function object array bool class
syntax keyword jsFlowTypeof         contained typeof skipempty skipempty nextgroup=jsFlowTypeCustom,jsFlowType
syntax match   jsFlowTypeCustom     contained /\k*/ skipwhite skipempty nextgroup=jsFlowGroup
syntax region  jsFlowGroup          contained matchgroup=jsFlowNoise start=/</ end=/>/ contains=@jsFlowCluster
syntax region  jsFlowArrow          contained matchgroup=jsFlowNoise start=/(/       end=/)\s*=>/     oneline contains=@jsFlowCluster
syntax match   jsFlowMaybe          contained /?/

syntax match   jsFlowReturn         contained /:\s*/ contains=jsFlowNoise skipwhite skipempty nextgroup=@jsFlowReturnCluster
syntax region  jsFlowReturnObject   contained matchgroup=jsFlowNoise start=/{/    end=/}/  contains=@jsFlowCluster skipwhite skipempty nextgroup=jsFuncBlock
syntax region  jsFlowReturnArray    contained matchgroup=jsFlowNoise start=/\[/   end=/\]/ contains=@jsFlowCluster skipwhite skipempty nextgroup=jsFuncBlock
syntax region  jsFlowReturnParens   contained matchgroup=jsFlowNoise start=/(/   end=/)/   contains=@jsFlowCluster skipwhite skipempty nextgroup=jsFuncBlock
syntax match   jsFlowReturnKeyword  contained /\k\+/ contains=jsFlowType,jsFlowTypeCustom skipwhite skipempty nextgroup=jsFlowReturnGroup,jsFuncBlock
syntax region  jsFlowReturnGroup    contained matchgroup=jsFlowNoise start=/</ end=/>/ contains=@jsFlowCluster skipwhite skipempty nextgroup=jsFuncBlock

syntax region  jsFlowFunctionGroup  contained matchgroup=jsFlowNoise start=/</ end=/>/ contains=@jsFlowCluster skipwhite skipempty nextgroup=jsFuncArgs
syntax region  jsFlowClassGroup     contained matchgroup=jsFlowNoise start=/</ end=/>/ contains=@jsFlowCluster skipwhite skipempty nextgroup=jsClassBlock

syntax region  jsFlowTypeStatement                                   start=/type/    end=/=\@=/ contains=jsFlowTypeOperator oneline skipwhite skipempty nextgroup=jsFlowTypeValue keepend
syntax region  jsFlowTypeValue      contained                        start=/=/       end=/[;\n]/ contains=@jsExpression
syntax match   jsFlowTypeOperator   contained /=/
syntax keyword jsFlowTypeKeyword    contained type

syntax keyword jsFlowDeclare                  declare skipwhite skipempty nextgroup=jsFlowTypeStatement,jsClassDefinition,jsStorageClass,jsFlowModule,jsFlowInterface
syntax match   jsFlowClassProperty  contained /\<[0-9a-zA-Z_$]*\>:\@=/ skipwhite skipempty nextgroup=jsFlowDefinition containedin=jsClassBlock

syntax region  jsFlowModule         contained start=/module/ end=/{\@=/ skipempty skipempty nextgroup=jsFlowDeclareBlock contains=jsString
syntax region  jsFlowInterface      contained start=/interface/ end=/{\@=/ skipempty skipempty nextgroup=jsFlowInterfaceBlock contains=@jsFlowCluster
syntax region  jsFlowDeclareBlock   contained matchgroup=jsFlowNoise start=/{/ end=/}/ contains=jsFlowDeclare,jsFlowNoise

syntax region jsFlowInterfaceBlock  contained matchgroup=jsFlowNoise start=/{/ end=/}/ contains=jsObjectKey,jsObjectKeyString,jsObjectKeyComputed,jsObjectSeparator,jsObjectFuncName,jsObjectMethodType,jsGenerator,jsComment,jsObjectStringKey,jsSpreadExpression,jsFlowNoise keepend

syntax cluster jsFlowReturnCluster            contains=jsFlowNoise,jsFlowReturnObject,jsFlowReturnArray,jsFlowReturnKeyword,jsFlowReturnGroup
syntax cluster jsFlowCluster                  contains=jsFlowArray,jsFlowObject,jsFlowNoise,jsFlowTypeof,jsFlowType,jsFlowGroup,jsFlowArrow,jsFlowMaybe,jsFlowParens

if version >= 508 || !exists("did_javascript_syn_inits")
  if version < 508
    let did_javascript_syn_inits = 1
    command -nargs=+ HiLink hi link <args>
  else
    command -nargs=+ HiLink hi def link <args>
  endif
  HiLink jsFlowDefinition         PreProc
  HiLink jsFlowType               Type
  HiLink jsFlowTypeCustom         PreProc
  HiLink jsFlowTypeof             PreProc
  HiLink jsFlowArray              PreProc
  HiLink jsFlowObject             PreProc
  HiLink jsFlowParens             PreProc
  HiLink jsFlowGroup              PreProc
  HiLink jsFlowReturn             PreProc
  HiLink jsFlowReturnObject       jsFlowReturn
  HiLink jsFlowReturnArray        jsFlowArray
  HiLink jsFlowReturnParens       jsFlowParens
  HiLink jsFlowReturnGroup        jsFlowGroup
  HiLink jsFlowFunctionGroup      PreProc
  HiLink jsFlowClassGroup         PreProc
  HiLink jsFlowArrow              PreProc
  HiLink jsFlowTypeStatement      PreProc
  HiLink jsFlowTypeKeyword        PreProc
  HiLink jsFlowTypeOperator       PreProc
  HiLink jsFlowMaybe              PreProc
  HiLink jsFlowClassProperty      jsClassProperty
  HiLink jsFlowDeclare            PreProc
  HiLink jsFlowModule             PreProc
  HiLink jsFlowInterface          PreProc
  HiLink jsFlowNoise              Noise
  delcommand HiLink
endif
