scriptencoding utf-8
" ========================================================================{{{1
" Plugin:     foldstaff
" LastChange: 2022/02/11  v1.02
" License:    MIT license
" Filenames:  foldstaff.vim
"             %/../../autoload/foldstaff.vim
"             %/../../autoload/foldstaff9.vim
" ========================================================================}}}1

let s:n = expand('<sfile>:t:r')

if get(g:, 'loaded_'..s:n)>=0.1 || !has('folding')
  finish
endif
let g:loaded_{s:n} = 0.1
let s:t_cpo = &cpo | set cpo&vim
let s:v9 = exists(':vim9') && (get(g:, s:n..'_enable_vim9')>=1)


" Example of Use: --------------------------------------------------------{{{2
  if get(g:, 'enable_'..s:n)>0 " # quick start
    " # fold-text
    set foldtext=foldstaff#header()

    " # option exsample
    let g:foldstaff = {
      \   'help': #{
      \     header: #{
      \       format: [
      \         '%{repeat("  ", %V-1)..["", "+ ", "- ", "  "][min([3, %V-1])]%}%t %<%{"-."[%V>1]%} %>(%l)',
      \       ],
      \       modify: [
      \         ['\v\S\zs%(\s*([\*\|])\S.{-}\S\1)+$|\s*\~$', ''],
      \       ],
      \     },
      \     fold: #{
      \       type: "text",
      \     },
      \   },
      \ }

    " # option-check (& Yank now value)
    " let @* = foldstaff#option(0, 2)

    " # fold-method (expr)
    set foldmethod=expr foldexpr=foldstaff#fold()

    " # fold-marker (key map)
    map zf <Plug>(foldstaff-marker)
    map zF <Plug>(foldstaff-endmarker)

    " # other folding options
    " set foldcolumn=0
    " set foldlevel=0
    " set foldlevelstart=0
    " set foldminlines=1
    " set foldopen="block,hor,mark,percent,quickfix,search,tag,undo"
    " set foldclose=""
    " set foldnestmax=20
    " set foldmarker="{{{,}}}"

    " hi Folded
    " hi FoldColumn

    " # autocmd: keep & restore view(include folding state).
    augroup RestoreView
      autocmd!
      au BufReadPost * if (expand('%')!='' && &bt!~?'nofile') | silent loadview | endif |
        \ au BufWritePost <buffer> if (expand('%')!='' && &bt!~?'nofile') | silent mkview! | endif
    augroup END
    " set viewoptions viewdir  " # related options
  endif


" FUNCTION: =============================================================={{{1
fu! {s:n}#option(...)
  return function(s:n..(s:v9 ? '9#Option' : '#_option'), a:000)()
endfu

fu! {s:n}#header(...)
  return function(s:n..(s:v9 ? '9#Header' :'#_header'), a:000)()
endfu

fu! {s:n}#fold(...)
  return function(s:n..(s:v9 ? '9#Fold' : '#_fold'), a:000)()
endfu

fu! {s:n}#marker(...)
  return function(s:n..(s:v9 ? '9#Marker' : '#_marker'), a:000)()
endfu

fu! {s:n}#refresh() abort
  return {s:n}#option()
endfu

" - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -{{{
fu! s:_msg(...) abort " ('msg', ['highlight']) -> color-message
  let [m, c] = [a:000, '']
  if len(m)>1 | let [c, m] = [m[-1], m[:-2]] | endif
  for i in range(len(m))
    if m[i]=~'\n' | m[i] = split(m[i], '\v\s*\n\s*') |  endif
  endfor
  let m = flatten(m)

  if c!='' | call execute('echoh '..c) | endif
  for i in m
    execute printf('echom ''%s''', substitute(i, "'", "''", 'g'))
  endfor
  echoh None
endfu
" - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -}}}

fu! s:_fold_cmd(...) " call by Command
  return function(s:n..'#fold', [get(a:, 1, 'auto')])()
endfu

" - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -{{{
fu! s:_option_cmd(...) " can be omitted Attribute
  let v = ''..get(a:, 1, '')
  if v=~'\v^\s*$' " check only
    let @h = {s:n}#option(0,2) | return 0
  elseif v!~'\v\w+.{-}\=\s*\S' " has EQUAL?
    call s:_msg(printf('%s#option: arguments wrang.', s:n),
      \ 'REQUIRE: filetype.method.attribute = value', 'ToDo')
    return -1
  endif

  let [v, r] = matchlist(trim(v), '\v^\s*(.{-})\s*\=\s*(.*)\s*$')[1:2]
  let v = filter(split(v, '\v[\t -/:-@\[-`{-~]+'), {_,v-> v!=''})
  if v[-1]=~'\v^\d+$' | let [n, v] = [v[-1]-0, v[:-2]] | else | let n = '' | endif
  try | call execute('let r = '..r, 'silent!') | endtry

  let p = [printf('\v\c\.%s>|<%s\.', v[-1], v[-1]), 'None']
  if len(v)>1 | let p[1] = printf('\v\c<%s\.%s>', v[-2], v[-1]) | endif

  let [j, h] = [match(s:_kns, p[0]), match(s:_kns, p[1])]
  if j<0 " nohit key-names
    call s:_msg(printf('%s#option: arguments wrang.', s:n), 'spell-bad?  '..a:1, 'ToDo')
    return -1
  elseif h<0 " key only
    let v = v[:-2] | let h = j
  else " func & key
    let v = v[:-3]
  endif
  let p = extend([(len(v)>0 && v[0]!='') ? v[0] : '_'], split(s:_kns[h], '\.'))

  if index([-1, 0, 2, 5, 7], h)>0 | if type(n)==0
    let v = printf("{ '%s':{'%s':{'%s':#{%d:%s}}\}}", p[0], p[1], p[2], n, string(r))
  else | let r = type(r)!=3 ? [r] : r
    let v = printf("{'%s':{'%s':{'%s':%s}}\}", p[0], p[1], p[2], string(r))
  endif | else
    let v = printf("{'%s':{'%s':{'%s':%s}}\}", p[0], p[1], p[2], string(r)) 
  endif
  call execute('let v='..v)

  let @h = {s:n}#option(v, 2)
endfu
  let s:_kns = [
    \ 'header.format', 'header.width', 'header.modify', 'header.min', 'header.ellipsis',
    \ 'marker.fill', 'marker.width', 'fold.type', 'fold.match', 'fold.keyswitch']

" - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -}}}

" COMMAND: ==============================================================={{{1
com! -nargs=* -complete=filetype FoldstaffHeader
  \ let @h = foldstaff#header(line('.'), <f-args>) |
  \ call <SID>_msg(@h, 'Folded')

com! -complete=customlist,<SID>_fold_typeList -nargs=? FoldstaffFold
  \ call <SID>_fold_cmd(<f-args>)

  fu! s:_fold_typeList(...)
    return ['auto', 'code', 'text', 'match']
  endfu

com! -complete=filetype -nargs=* FoldstaffOption call <SID>_option_cmd(<q-args>)

com! -nargs=* FoldstaffRefresh call {s:n}#option()

" KEY-MAP: ==============================================================={{{1
if s:v9
  noremap <silent><nowait> <Plug>(foldstaff-marker) <Cmd>call foldstaff9#Marker(0)<CR>
  noremap <silent><nowait> <Plug>(foldstaff-endmarker) <Cmd>call foldstaff9#Marker(1)<CR>
else
  noremap <silent><nowait> <Plug>(foldstaff-marker) <Cmd>call foldstaff#_marker(0)<CR>
  noremap <silent><nowait> <Plug>(foldstaff-endmarker) <Cmd>call foldstaff#_marker(1)<CR>
endif

" ========================================================================}}}1

let &cpo = s:t_cpo | unlet! s:t_cpo
" vim:set ft=vim fenc=utf-8 norl:                             Author: HongKong
