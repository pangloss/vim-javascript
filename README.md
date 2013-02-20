# vim-javascript

JavaScript bundle for vim, this bundle provides syntax and indent plugins.

> Indentation of javascript in vim is terrible, and this is the very end of it.

## Features

1. very correct indentation for javascript
2. support javascript indentation in html (provided by [lepture](https://github.com/lepture))

## Installation

- Install with [Vundle](https://github.com/gmarik/vundle)

If you are not using vundle, you really should have a try.
Edit your vimrc:

    Bundle "pangloss/vim-javascript"

And install it:

    :so ~/.vimrc
    :BundleInstall


- Install with [pathogen](https://github.com/tpope/vim-pathogen)

If you prefer tpope's pathogen, that's ok. Just clone it:

    cd ~/.vim/bundle
    git clone https://github.com/pangloss/vim-javascript.git

## Configuration

[html indentation](http://www.vim.org/scripts/script.php?script_id=2075)
provided by Andy Wokula is faster. But you need to make some configuration.

Suggested configuration:

```vim
let g:html_indent_inctags = "html,body,head,tbody"
let g:html_indent_script1 = "inc"
let g:html_indent_style1 = "inc"
```

Head over to [vim.org](http://www.vim.org/scripts/script.php?script_id=2075)
for more information.

## Bug report

Report a bug on [GitHub Issues](https://github.com/pangloss/vim-javascript/issues).
