let s:save_cpo = &cpo
set cpo&vim

let s:V = vital#of('unite-cpan-module')
let s:List = s:V.import('Data.List')
let s:HTTP = s:V.import('Web.HTTP')
let s:JSON = s:V.import('Web.JSON')

let s:metacpan_search_file_endpoint = 'http://api.metacpan.org/v0/file/_search'

function! s:create_modules(fields)
  let l:modules = []
  for l:m in a:fields.module
    let l:ret = {}
    let l:ret.name = l:m.name
    let l:ret.version = get(l:m, 'version', get(a:fields, 'version', ''))
    let l:ret.author = a:fields.author
    let l:ret.abstract = get(a:fields, 'abstract', '')
    let l:ret.path = a:fields.path
    let l:ret.release = a:fields.release
    let l:ret.date = a:fields.date
    call add(l:modules, l:ret)
  endfor
  return l:modules
endfunction

function! s:search_modules(input)
  let l:filters = [
        \ 'status:latest',
        \ 'maturity:released',
        \ '_exists_:module.name',
        \ s:make_query(a:input),
        \ ]
  let l:fields = [
        \ 'module',
        \ 'version',
        \ 'author',
        \ 'abstract',
        \ 'path',
        \ 'release',
        \ 'date',
        \ ]
  let l:params = {
        \ 'q': join(l:filters, ' AND '),
        \ 'fields': join(l:fields, ','),
        \ 'size': s:max_candidates(),
        \ }

  let l:response = s:HTTP.get(s:metacpan_search_file_endpoint, l:params)
  if !l:response.success
    return []
  endif

  let l:decoded = s:Json.decode(l:response.content)
  return s:List.concat(map(l:decoded.hits.hits, 's:create_modules(v:val.fields)'))
endfunction

function! s:max_candidates()
  return get(g:, 'unite_source_cpan_module_max_candidates', 50)
endfunction

function! s:create_candidate(module, args, context)
  let l:abbr = a:module.name
  if !empty(a:module.date)
    let l:abbr .= ' [' . matchstr(a:module.date, '^\d\{4}-\d\{2}-\d\{2}') . ']'
  endif
  if !empty(a:module.author)
    let l:abbr .= ' (' . a:module.author . ')'
  endif
  if !empty(a:module.abstract)
    let l:abbr .=  ' - ' . a:module.abstract
  endif
  return {
        \ 'abbr': l:abbr,
        \ 'word': a:module.name,
        \ 'kind': 'uri',
        \ 'action__path': s:cpan_uri(a:module)
        \ }
endfunction

function! s:make_query(input)
  let l:quoted = map(split(a:input), "'\"' . v:val . '\"'")
  return '(' . join(l:quoted, ' AND ') . ')'
endfunction

function! s:cpan_uri(module)
  return printf('http://search.cpan.org/~%s/%s/%s',
        \ tolower(a:module.author),
        \ a:module.release,
        \ a:module.path
        \ )
endfunction

function! unite#sources#cpan_module#define()
  return s:source
endfunction

let s:source = {
      \ 'name': 'cpan-module',
      \ 'description': 'candidates from cpan modules',
      \ 'default_action': 'start',
      \ 'syntax': 'uniteSource__CpanModule',
      \ 'hooks': {},
      \}

function! s:source.hooks.on_init(args, context)
  let a:context.source__input = a:context.input
  if a:context.source__input == ''
    let a:context.source__input = unite#util#input('please input search words: ')
  endif
endfunction

function! s:source.hooks.on_syntax(args, context)
  syntax match uniteSource__CpanModule_Date /\[\d\{4}-\d\{2}-\d\{2}\]/
        \ contained containedin=uniteSource__CpanModule
  syntax match uniteSource__CpanModule_Author /([-A-Z]*)/
        \ contained containedin=uniteSource__CpanModule
endfunction

function! s:source.gather_candidates(args, context)
  let l:input = a:context.source__input
  call unite#print_source_message('search words: ' . l:input, s:source.name)
  let l:modules = s:search_modules(l:input)
  return map(l:modules, 's:create_candidate(v:val, a:args, a:context)')
endfunction

let &cpo = s:save_cpo
unlet s:save_cpo
