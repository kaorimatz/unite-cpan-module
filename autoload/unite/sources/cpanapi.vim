let s:save_cpo = &cpo
set cpo&vim

let s:V = vital#of('unite-cpanapi')
let s:Http = s:V.import('Web.Http')
let s:Json = s:V.import('Web.Json')

let s:cpanapi_search_module_uri = 'http://api.metacpan.org/v0/file/_search'

function! s:search_modules(input)
  let l:filters = [
        \ 'status:latest',
        \ 'maturity:released',
        \ '_exists_:module.name',
        \ s:make_query(a:input),
        \ ]
  let l:fields = [
        \ 'id',
        \ 'documentation',
        \ 'distribution',
        \ 'version',
        \ 'author',
        \ 'abstract',
        \ 'path',
        \ 'release',
        \ ]
  let l:params = {
        \ 'q': join(l:filters, ' AND '),
        \ 'fields': join(l:fields, ','),
        \ 'size': s:max_candidates(),
        \ }

  let l:response = s:Http.get(s:cpanapi_search_module_uri, l:params)
  if !l:response.success
    return []
  endif

  let l:decoded = s:Json.decode(l:response.content)
  return map(l:decoded.hits.hits, 'v:val.fields')
endfunction

function! s:max_candidates()
  return get(g:, 'unite_source_cpanapi_max_candidates', 100)
endfunction

function! s:create_candidate(module, args, context)
  let l:module_name = a:module.documentation
  let l:abstract = get(a:module, 'abstract', '')
  let l:abbr = l:module_name . (!empty(l:abstract) ? ' - ' . l:abstract : '')
  return {
        \ 'abbr': l:abbr,
        \ 'word': l:module_name,
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

function! unite#sources#cpanapi#define()
  return s:source
endfunction

let s:source = {
      \ 'name': 'cpanapi',
      \ 'description': 'candidates from cpan modules',
      \ 'default_action': 'start',
      \ 'hooks': {},
      \}

function! s:source.hooks.on_init(args, context)
  let a:context.source__input = a:context.input
  if a:context.source__input == ''
    let a:context.source__input = unite#util#input('please input search words: ')
  endif
endfunction

function! s:source.gather_candidates(args, context)
  let l:input = a:context.source__input
  call unite#print_source_message('search words: ' . l:input, s:source.name)
  let l:modules = s:search_modules(l:input)
  return map(l:modules, 's:create_candidate(v:val, a:args, a:context)')
endfunction

let &cpo = s:save_cpo
unlet s:save_cpo
