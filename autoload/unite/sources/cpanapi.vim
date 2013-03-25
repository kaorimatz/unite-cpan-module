let s:save_cpo = &cpo
set cpo&vim

let s:V = vital#of('unite-cpanapi')
let s:Http = s:V.import('Web.Http')
let s:Json = s:V.import('Web.Json')

let s:cpanapi_release_search_uri = 'http://api.metacpan.org/v0/release/_search'

function! s:search_modules(input)
  let l:params = {
        \ 'q': join(['status:latest', s:make_query(a:input)], ' AND '),
        \ 'fields': join(['id', 'distribution', 'version', 'author', 'abstract'], ','),
        \ 'size': s:max_candidates(),
        \ }

  let l:response = s:Http.get(s:cpanapi_release_search_uri, l:params)
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
  let l:dist = substitute(a:module.distribution, '-', '::', 'g')
  let l:abstract = get(a:module, 'abstract', '')
  let l:abbr = l:dist . (!empty(l:abstract) ? ' - ' . l:abstract : '')
  return {
        \ 'abbr': l:abbr,
        \ 'word': l:dist,
        \ 'action__module_name': l:dist,
        \ }
endfunction

function! s:make_query(input)
  let l:quoted = map(split(a:input), "'\"' . v:val . '\"'")
  return '(' . join(l:quoted, ' AND ') . ')'
endfunction

function! unite#sources#cpanapi#define()
  return s:source
endfunction

let s:source = {
      \ 'name' : 'cpanapi',
      \ 'description' : 'candidates from cpan modules',
      \ 'default_action' : 'insert',
      \ 'hooks' : {},
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
