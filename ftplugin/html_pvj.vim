if exists("b:did_ftplugin")
    finish
endif
let b:did_ftplugin = 1

"" dollar sign is permitted anywhere in an identifier
if &filetype == "html"
    setlocal iskeyword+=$
endif
