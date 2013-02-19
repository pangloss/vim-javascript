# vim-javascript

JavaScript bundle for vim, this bundle provides syntax and indent plugins.

> Indentation of javascript in vim is terrible, and this is the very end of it.

## Maintainer(s) wanted

This project does not get too much love because, frankly I don't use JS all that
much anymore. This project's maintenance isn't much work, but it would be helpful to
everyone if one or two people would evaluate pull requests and merge them if they're
good.  There are also a couple of valid issues that have been filed that would make
lots of people happy if they were addressed.  Plus it might be good if someone updated
the script on vim.org occasionally.  By the way, I'd be happy to put more effort into
helping a new maintainer get going than what I put in actually maintaining the project
myself. If you're interested, please comment on issue #65.

Cheers!
Darrick

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
