# vim-javascript

JavaScript bundle for vim, this bundle provides syntax highlighting and
improved indentation.


## Installation

### Install with [pathogen](https://github.com/tpope/vim-pathogen)

      git clone https://github.com/pangloss/vim-javascript.git ~/.vim/bundle/vim-javascript

alternatively, use a package manager like [vim-plug](https://github.com/junegunn/vim-plug)


### Install with [vundle](https://github.com/VundleVim/Vundle.vim)

Add the plugin to your plugin list inside ~/.vimrc right after you load your Vundle plugin and before `call vundle#end()`:

```
Plugin 'pangloss/vim-javascript'
```

Now install by either running from:
* The terminal: `vim +PluginInstall +qall`
* Inside VIM: :PluginInstall


## Configuration Variables

The following variables control certain syntax highlighting plugins. You can
add them to your `.vimrc` to enable their features.

-----------------

```
let g:javascript_plugin_jsdoc = 1
```

Enables syntax highlighting for [JSDocs](http://usejsdoc.org/).

Default Value: 0

-----------------

```
let g:javascript_plugin_ngdoc = 1
```

Enables some additional syntax highlighting for NGDocs. Requires JSDoc plugin
to be enabled as well.

Default Value: 0

-----------------

```
let g:javascript_plugin_flow = 1
```

Enables syntax highlighting for [Flow](https://flowtype.org/).

Default Value: 0

-----------------

```
set foldmethod=syntax
```

Enables code folding based on our syntax file.

Please note this can have a dramatic effect on performance and because it is a
global vim option, we do not set it ourselves.


## Concealing Characters

You can customize concealing characters, if your font provides the glyph you want, by defining one or more of the following
variables:

    let g:javascript_conceal_function             = "ƒ"
    let g:javascript_conceal_null                 = "ø"
    let g:javascript_conceal_this                 = "@"
    let g:javascript_conceal_return               = "⇚"
    let g:javascript_conceal_undefined            = "¿"
    let g:javascript_conceal_NaN                  = "ℕ"
    let g:javascript_conceal_prototype            = "¶"
    let g:javascript_conceal_static               = "•"
    let g:javascript_conceal_super                = "Ω"
    let g:javascript_conceal_arrow_function       = "⇒"
    let g:javascript_conceal_noarg_arrow_function = "🞅"
    let g:javascript_conceal_underscore_arrow_function = "🞅"


You can enable concealing within VIM with:

    set conceallevel=1

OR if you wish to toggle concealing you may wish to bind a command such as the following which will map `<LEADER>l` (leader is usually the `\` key) to toggling conceal mode:

    map <leader>l :exec &conceallevel ? "set conceallevel=0" : "set conceallevel=1"<CR>


## Indentation Specific

* `:h cino-:`
* `:h cino-=`
* `:h cino-star`
* `:h cino-(`
* `:h cino-w`
* `:h cino-W`
* `:h cino-U`
* `:h cino-m`
* `:h cino-M`
* `:h 'indentkeys'`

## Contributing

Please follow the general code style
guides (read the code) and in your pull request explain the reason for the
proposed change and how it is valuable. All p.r.'s will be reviewed by a
maintainer(s) then, hopefully, merged.

Thank you!


## License

Distributed under the same terms as Vim itself. See `:help license`.
