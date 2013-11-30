# unite-cpan-module

![screenshot](http://gyazo.com/ff810020aa98b5c700ff529c76df37bb.png)

## Dependencies

- [unite.vim](https://github.com/Shougo/unite.vim)

## Install

Get the source code.

    git clone https://github.com/kaorimatz/unite-cpan-module

Copy `unite-cpan-module` to your `runtimepath` directory.

## Usage

    :Unite cpan-module

The plugin will ask you to input keywords for searching CPAN modules.

    please input search words: JSON

You can select a module from the candidates.
The plugin opens the URI for the selected module at search.cpan.org by default.

## Settings

### Variables

- `g:unite_source_cpan_module_max_candidates`
    - The maximum number of candidates

Example:

    let g:unite_source_cpan_module_max_candidates = 15

### Highlight Groups

- `uniteSource__CpanModule_Author`
    - PAUSE ID of the author
- `uniteSource__CpanModule_Date`
    - Release date

Example:

    autocmd ColorScheme * highlight uniteSource__CpanModule_Author ctermfg=Red
    autocmd ColorScheme * highlight uniteSource__CpanModule_Date ctermfg=Green

## Thanks

- [MetaCPAN](https://metacpan.org/)
    - This plugin searches CPAN modules using API provided by MetaCPAN
