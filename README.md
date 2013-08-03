# vim-javascript

JavaScript bundle for vim, this bundle provides syntax and indent plugins.

## Installation

- Install with [Vundle](https://github.com/gmarik/vundle)

Add to vimrc:

    Bundle "pangloss/vim-javascript"

And install it:

    :so ~/.vimrc
    :BundleInstall

- Install with [pathogen](https://github.com/tpope/vim-pathogen)

    cd ~/.vim/bundle
    git clone https://github.com/pangloss/vim-javascript.git

## Configuration

The following variables control certain syntax highlighting features. You can
add them to your `.vimrc` to enable/disable their features.

#### javascript_enable_domhtmlcss

Enables HTML/CSS syntax highlighting in your JavaScript file.

Default Value: 0

#### b:javascript_fold

Enables JavaScript code folding.

Default Value: 1

#### g:javascript_conceal

Enables concealing characters. For example, `function` is replaced with `ƒ`

Default Value: 0

#### javascript_ignore_javaScriptdoc

Disables JSDoc syntax highlighting

Default Value: 0

## Contributing

If you'd like to be added as a contributor the price of admission is 1 pull request.
Please follow the general code style guides (read the code) and in your pull request explain
the reason for the proposed change and how it is valuable.

## Bug report

Report a bug on [GitHub Issues](https://github.com/pangloss/vim-javascript/issues).
