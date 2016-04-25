# vim-javascript v1.0.0

JavaScript bundle for vim, this bundle provides syntax highlighting and
improved indentation.


## Installation

### Install with [Vundle](https://github.com/gmarik/vundle)

Add to vimrc:

    Plugin 'pangloss/vim-javascript'

And install it:

    :so ~/.vimrc
    :PluginInstall

### Install with [vim-plug](https://github.com/junegunn/vim-plug)

Add to vimrc:

    Plug 'pangloss/vim-javascript'

And install it:

    :so ~/.vimrc
    :PlugInstall

### Install with [pathogen](https://github.com/tpope/vim-pathogen)

      cd ~/.vim/bundle
      git clone https://github.com/pangloss/vim-javascript.git


## Configuration Variables

The following variables control certain syntax highlighting features. You can
add them to your `.vimrc` to enable/disable their features.

```
let g:javascript_enable_domhtmlcss = 1
```

Enables HTML/CSS syntax highlighting in your JavaScript file.

Default Value: 0

-----------------

```
let g:javascript_ignore_javaScriptdoc = 1
```

Disables JSDoc syntax highlighting

Default Value: 0

-----------------

```
set foldmethod=syntax
```

Enables code folding based on our syntax file.

Please note this can have a dramatic effect on performance and because it is a
global vim option, we do not set it ourselves.


## Concealing Characters

You can customize concealing characters by defining one or more of the following
variables:

    let g:javascript_conceal_function       = "ƒ"
    let g:javascript_conceal_null           = "ø"
    let g:javascript_conceal_this           = "@"
    let g:javascript_conceal_return         = "⇚"
    let g:javascript_conceal_undefined      = "¿"
    let g:javascript_conceal_NaN            = "ℕ"
    let g:javascript_conceal_prototype      = "¶"
    let g:javascript_conceal_static         = "•"
    let g:javascript_conceal_super          = "Ω"
    let g:javascript_conceal_arrow_function = "⇒"


## Contributing

This project uses the [git
flow](http://nvie.com/posts/a-successful-git-branching-model/) model for
development. There's [a handy git module for git
flow](//github.com/nvie/gitflow). If you'd like to be added as a contributor,
the price of admission is 1 pull request. Please follow the general code style
guides (read the code) and in your pull request explain the reason for the
proposed change and how it is valuable.


## Bug Reports

Report a bug on [GitHub Issues](https://github.com/pangloss/vim-javascript/issues).


## A Quick Note on Regexes

Vim 7.4 with patches LESS than 1-7 exhibits a bug that broke how we handle
javascript regexes. Please update to a newer version or run the following
commands to fix:

```
:set regexpengine=1
:syntax enable
```


## License

Distributed under the same terms as Vim itself. See `:help license`.
