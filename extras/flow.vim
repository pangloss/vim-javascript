syntax region  jsFlowTypeStatement            start=/type/    end=/=/     oneline skipwhite skipempty nextgroup=jsFlowTypeObject
syntax region  jsFlowDeclareBlock             start=/declare/ end=/[;\n]/ oneline contains=jsFlow,jsFlowDeclareKeyword,jsFlowStorageClass
syntax region  jsFlow                         start=/:/       end=/\%(\%([),=;\n]\|{\%(.*}\)\@!\|\%({.*}\)\@<=\s*{\)\@=\|void\)/ contains=@jsFlowCluster oneline skipwhite skipempty nextgroup=jsFuncBlock
syntax region  jsFlowReturn         contained start=/:/       end=/\%(\S\s*\%({\)\@=\|\n\)/ contains=@jsFlowCluster oneline skipwhite skipempty nextgroup=jsFuncBlock keepend
syntax region  jsFlowTypeObject     contained start=/{/       end=/}/     skipwhite skipempty nextgroup=jsFunctionBlock extend
syntax region  jsFlowObject         contained matchgroup=jsFlowNoise start=/{/       end=/}/     oneline contains=@jsFlowCluster
syntax region  jsFlowArray          contained matchgroup=jsFlowNoise start=/\[/      end=/\]/    oneline contains=@jsFlowCluster
syntax keyword jsFlowDeclareKeyword contained declare
syntax keyword jsFlowType           contained boolean number string null void any mixed JSON array function object Array
syntax match   jsFlowClassProperty  contained /\<[0-9a-zA-Z_$]*\>:\@=/ skipwhite skipempty nextgroup=jsFlow
syntax match   jsFlowNoise          contained /[:;,<>]/
syntax cluster jsFlowCluster        contains=jsFlowType,jsFlowArray,jsFlowObject,jsFlowNoise
syntax keyword jsFlowStorageClass   contained const var let
syntax region  jsFlowParenRegion    contained start=/:\s*(/ end=/)\%(\s*:\)\@=/ oneline contains=@jsFlowCluster skipwhite skipempty nextgroup=jsObjectValue
syntax region  jsFlowClass          contained matchgroup=jsFlowNoise start=/</ end=/>/ oneline contains=@jsFlowCluster skipwhite skipempty nextgroup=jsClassBlock

if version >= 508 || !exists("did_javascript_syn_inits")
  if version < 508
    let did_javascript_syn_inits = 1
    command -nargs=+ HiLink hi link <args>
  else
    command -nargs=+ HiLink hi def link <args>
  endif
  HiLink jsFlow                   PreProc
  HiLink jsFlowReturn             PreProc
  HiLink jsFlowArray              PreProc
  HiLink jsFlowDeclareBlock       PreProc
  HiLink jsFlowObject             PreProc
  HiLink jsFlowParenRegion        PreProc
  HiLink jsFlowClass              PreProc
  HiLink jsFlowClassProperty      jsClassProperty
  HiLink jsFlowType               Type
  HiLink jsFlowDeclareKeyword     Type
  HiLink jsFlowNoise              Noise
  delcommand HiLink
endif
