scriptencoding utf-8
" ========================================================================{{{1
" Plugin:     foldstaff
" LasCahnge:  2022/02/09  v1.00
" License:    MIT license
" Filenames:  %/../../plugin/foldstaff.vim
"             foldstaff.vim
"             foldstaff9.vim
" ________________________________________________________________________{{{2
" ========================================================================}}}1

let s:t_cpo = &cpo | set cpo&vim
let s:n = expand('<sfile>:t:r')

" OPTION: ================================================================{{{1
let s:{s:n}_default = {}

let s:{s:n}_default.header = {}
let s:{s:n}_default.header.format = ['%i%t %<%>%{repeat("+", %v)%}[%L]']
let s:{s:n}_default.header.width = '+0'
let s:{s:n}_default.header.modify = []
let s:{s:n}_default.header.min = 8
let s:{s:n}_default.header.ellipsis = '~'

let s:{s:n}_default.marker = {}
let s:{s:n}_default.marker.fill = ['- ', '=', '_', '.']
let s:{s:n}_default.marker.width = 0
" forced placing to 'readonly' and 'nomodifiable'
" let s:{s:n}_default.marker.bang = 0

let s:{s:n}_default.fold = {}
let s:{s:n}_default.fold.type = 'auto'
let s:{s:n}_default.fold.keyswitch = -1
let s:{s:n}_default.fold.match = []

" running variables: _____________________________________________________{{{2
" b:{s:n}_header = {
"   width:  {current-width},      # FLG1
"   line:   {max-line},           # FLG2
"   text:   {                     # reserve header-texts
"     'start:lv': 'text',
"      ...... ,
"   },
"   pat:    {sub-pattern},
" }
"
" b:{s:n}_fold = {
"   type:   {fold-type},          # type checked
"   expr:   {params},
"   switched: 0 / 1,              # FLG key-switch
"     fmr:    {pat},               # pattern of fold-marker @CODE
" }
"
" ========================================================================}}}1

let s:SMB = '\t -@\[-`{-~' " symbol-pattern @\v

" MODULE: ================================================================{{{1
  " ______________________________________________________________________{{{2
  fu! s:is(...) abort " (A, B)  =  equal?
    return (type(a:1)==type(a:2)) && (a:1==a:2)
  endfu

  " ----------------------------------------------------------------------{{{2
  fu! s:esc(...) abort " ('str', [0:pat 1:sub])  =  '\v:escaped'
    " return escape(a:1, '$%&()=^~\|@[{+*]}<>?')
    return escape(a:1, (get(a:, 2)!=0 ? '$%&()^|\|@[{+*]}<>?' :'$%&()-=^~\|@[{+*]}<.>?'))
  endfu

  " ______________________________________________________________________{{{2
  fu! s:get(...) abort " (var, '{key/idx...}', [default=0])  =  value @deepget()
    if a:0<1 | return 0 | elseif a:0==1 | return a:1 | endif
    let [r, d] = [a:1, get(a:, 3, 0)]
    let k = map(split(''..a:2, '\v\s*[\[\]\.]+\s*'), {_,v-> substitute(v, '\v^([\''\"])(.*)\1$', '\2', '')})

    for c in k
      let r = has_key(s:_get_fnc, type(r)) ? s:_get_fnc[type(r)](r, c) : 0z00ff
      if s:is(r, 0z00ff) | let r = d | break | endif
    endfor
    return r
  endfu

  let s:_get_fnc = #{
    \   1: {a,b-> strlen(a)>b ? a[b] : 0z00ff},
    \   2: {a,b-> get(a, b, 0z00ff)},
    \   3: {a,b-> len(a)>b ? a[b] : 0z00ff},
    \   4: {a,b-> has_key(a, b) ? a[b] : 0z00ff},
    \  10: {a,b-> get(a, b, 0z00ff)},
    \ }

  " ______________________________________________________________________{{{2
  fu! s:set(...) abort " ('var-name', [value])  =  var  # CAUTION`s:`
    let tgt = get(a:, 1, 'g:tmp') | let val = get(a:, 2, 0z00ff)
    if tgt=~#'\v^[gtwbs]:'
      let r = [g:, t:, w:, b:, s:][stridx('gtwbs', tgt[0])] | let tgt = tgt[2:]
    else | let r = g: | endif

    let tgt = map(split(tgt, '\v\s*[\[\]\.]+\s*'), {_,v-> substitute(v, '\v^(["''])(.{-})\1$', '\2', '')})
    for i in range(len(tgt)-1)
      let a = (type(r)==3 && tgt[i]!~'\v^\-?\d+$') ? 0z00ff : s:get(r, tgt[i], 0z00ff)
      if s:is(a, 0z00ff)
        if (type(r)==3 && tgt[i]=~'\v^\-?\d+$')
          let tgt[i] = len(r) | call add(r, {tgt[i+1]:{}})
        elseif tgt[i]=~'^0$'
          let r[tgt[i]] = [tgt[i+1]]
        else
          let r[tgt[i]] = {tgt[i+1]:{}}
        endif
      endif
      let r = r[tgt[i]]
    endfor

    if (type(r)==3 && tgt[-1]=~'\v^\-?\d+$')
      let i = tgt[-1]-0
      if i<len(r) && i>=-len(r) | let r[i] = val | else
        let tgt[-1] = len(r) | call add(r, val)
      endif
    else | let r[tgt[-1]] = val | endif

    return r[tgt[-1]]
  endfu

  " ______________________________________________________________________{{{2
  fu! s:is_cmt(...) abort " ([lnum='.'])  =  comment-row?
    let l = get(a:, 1, line('.'))
    return hlID('Comment')==synIDtrans(synID(l, indent(l)+1, 1))
  endfu

  " ______________________________________________________________________{{{2
  fu! s:winwidth(...) abort " ([winID=0])  =  displayed-col-count
    let wid = get(a:, 1, 0)
    if wid<1000 | let wid = win_getid(wid) | endif
    if wid<1000 | let wid = win_getid() | endif

    let wo = getwinvar(wid, '&')
    let wn = [wo.foldcolumn, 0, 0] | let scl = wo.signcolumn
    if  scl=~?'yes' | let wn[1] = 2
    elseif (scl=~?'auto' || (scl=~?'number' && !wo.number))
      if len(sign_getplaced(winbufnr(wid))[0].signs)>0 | let wn[1] = 2 | endif
    endif
    let wn[2] = wo.number * max([wo.numberwidth, strlen(line('$', wid))+1])
    return winwidth(wid) - reduce(wn, {a,b-> a+b})
  endfu

  " ______________________________________________________________________{{{2
  fu! s:replace(...) abort " ('str', ['pat', {sub}]... ,[repeat=0])  =  'replaced'
    let tgt = get(a:, 1, '') | let one = 0 | let arg = a:000[1:]

    if type(arg[-1])==0 | let one = (a[-1]==0) | let arg = arg[:-2] | endif
    let reg = [] | let arg = flatten(arg) | let p = ''

    for i in range(0, len(arg)-1, 2)
      if arg[i]=~?'\v^\\[so]'
        let arg[i] = arg[i][2:]
        let q = ''
      else | let q = 'g' | endif
      call add(reg, [arg[i], arg[i+1], q])
    endfor

    while p!=tgt | let p = tgt
      for a in reg | let tgt = substitute(tgt, a[0], a[1], a[2]) | endfor
      if one | break | endif
    endwhile

    return tgt
  endfu


" SUB: ==================================================================={{{1
" ________________________________________________________________________{{{2
fu! s:show_opt(...) abort " ({options})
  let opt = get(a:, 1, s:{s:n})
  let gen = s:{s:n}._ | let flg = has_key(opt, '_')
  let idt = repeat(' ', (&sw ? &sw : (&ts ? &ts : 4)))
  let idt = map(range(4), {v-> repeat(idt, v+1)})

  let msg = [printf('%s: {', s:n)]

  " ......................................................................{{{3
  fu! s:_attr(v) " (val) = 'string'
    return type(a:v)==1 ? printf('''%s''', a:v) : a:v
  endfu
  " ......................................................................}}}3

  for ft in keys(opt)
    call add(msg, printf('%s[''%s'']: {', idt[0], ft))
    for [fn, fo] in items(gen)
      let gg = has_key(opt[ft], fn) ? 0 : 1
      " FL gg opt[ft]
      if (gg>0 && flg) | continue | endif
      call add(msg, printf('%s%s%s: {', (gg ? "\x01" : ''), idt[1], fn))
      for k in keys(fo)
        if gg==0 && has_key(opt[ft][fn], k)
          let g = 0 | let ki = opt[ft][fn][k]
        else
          let g = 1 | let ki = fo[k]
        endif

        if (g && flg) | continue | endif
        if type(ki)==3 && len(ki)>1
          call add(msg, printf('%s%s%s: [', (gg>0 ? "\x01" : ''), idt[2], k))
          for i in ki
            call add(msg, printf('%s%s%s,', (g ? "\x01" : ''), idt[3], s:_attr(i)))
          endfor
          call add(msg, (gg>0 ? "\x01" : '')..idt[2]..'],')
        else
          call add(msg, printf('%s%s%s: %s,', (g ? "\x01" : ''), idt[2], k, s:_attr(ki)))
        endif
      endfor
      call add(msg, (gg>0 ? "\x01" : '')..idt[1]..'},')
    endfor
    call add(msg, idt[0]..'},')
  endfor
  call add(msg, '}')

  for m in msg
    if m=~'\v^(%x01|%x02)'
      execute 'echoh '..(m[0]=="\x01" ? 'Comment': 'Statement')
      execute printf('echo ''%s''', substitute(m[1:], '''', '''''', 'g'))
      execute 'echoh None'
    else
      execute printf('echo ''%s''', substitute(m, '''', '''''', 'g'))
    endif
  endfor
endfu


" ________________________________________________________________________{{{2
fu! s:get_param() abort " attributes for header-text
  let ll = line('$')
  let prm = #{
    \   s: v:foldstart,  e: v:foldend,  l: v:foldend-v:foldstart+1,
    \   v: v:foldlevel,  V: foldlevel(v:foldstart),  d: v:folddashes,  D: &diff,
    \   i: repeat(' ', indent(v:foldstart)),  I: indent(v:foldstart)/shiftwidth(),
    \   p: 100*v:foldstart/ll, P: printf('%5.1g', 100.0*v:foldstart/ll),
    \ }
  let a = printf('%%%dd', strwidth(''..ll)) " with-paddings
  call extend(prm, map(#{S:0,E:0,L:0}, {k-> printf(a, prm[tolower(k)])}))
  let [prm.c, prm.C] = split(&cms..'%s', '\v\%s')[:1] " comment
  let [prm.m, prm.M] = split(&fmr..',', ',')[:1] " fold-marker
  return prm
endfu


" ________________________________________________________________________{{{2
fu! s:key_switch(...) abort " ([0:OFF 1:ON -1:toggle])  # Switch folding Keys
  let f = get(a:, 1)
  let km = ['za', 'zc', 'zo', '', 'zA', 'zC', 'zO', '']
  if f<0 | let f = xor(s:get(b:, s:n..'_fold.switched')!=0, 1) | endif

  if f>0 | for i in range(len(km))
    if km[i]=='' | continue | endif
    execute printf('noremap <buffer> %s %s', km[i], km[xor(i, 4)])
  endfor | else | for k in km
    if k=='' | continue | endif
    silent! execute 'unmap <buffer> '..k
  endfor | endif
  return f
endfu


" MAIN: =================================================================={{{1
" ________________________________________________________________________{{{2
fu! {s:n}#_option(...) abort " ([{options}], [flg: 1:new 2:show])  =  {options}
  let opt = get(a:, 1) | let flg = get(a:, 2)
  let def = s:{s:n}_default | let bad = []

  if and(flg, 1)==1 || !exists(printf('s:%s._', s:n)) " new(initialize)
    let s:{s:n} = {} | let s:{s:n}['_'] = deepcopy(def)
  endif

  if type(opt)!=4 | let opt = get(g:, s:n) | endif " @Setting
  if type(opt)==4 | for ft in keys(opt) " file-type
    if type(opt[ft])!=4 || s:is(opt[ft], {}) | continue | endif
    for [fn, fo] in items(opt[ft]) " func: header/marker/fold
      if type(fo)!=4 || !has_key(def, fn) " spell-miss?
        call add(bad, printf('[''%s''].%s', ft, fn)) | continue
      endif
      for k in keys(fo) " func-attributes
        if !has_key(def[fn], k) " spell-miss?
          call add(bad, printf('[''%s''].%s.%s', ft, fn, k)) | continue
        elseif type(fo[k])==4 | for [i, v] in items(fo[k]) " list-index
          if i!~'\v^\-?\d+$' | continue | endif
          let tl = s:get(s:{s:n}, printf('%s.%s.%s', ft, fn, k), [])
          call s:set(printf('s:%s.%s.%s.%s', s:n, ft, fn, k), tl)
          call s:set(printf('s:%s.%s.%s.%s.%s', s:n, ft, fn, k, i), v)
        endfor | else
          call s:set(printf('s:%s.%s.%s.%s', s:n, ft, fn, k), fo[k])
        endif
      endfor
    endfor
  endfor | endif

  if type(opt)!=4 | let ret = s:{s:n} | else
    let ret = {} " make result-DICT
    for ft in keys(opt) | let ret[ft] = s:get(s:{s:n}, ft, {}) | endfor
  endif

  if and(flg, 2)==2 | call s:show_opt(ret) | endif " show-options

  if len(bad)>0 " too too extra care...
    execute 'echoh ToDo'
    for i in bad
      execute printf('echo "%s: invalid option-key ignored.  >>  %s"', s:n, i)
    endfor
    execute 'echoh None'
  endif

  if exists(printf('b:%s_header', s:n)) | let b:{s:n}_header.text = {} | endif
  if &fdm=='expr' && &l:fde==s:n..'#fold()' | let &l:fde = s:n..'#fold()' | endif
  return string(ret)
endfu


" ________________________________________________________________________{{{2

fu! {s:n}#_header(...) abort " ([lnum], [lv])  @foldtext()
  if !exists('s:'..s:n) | call {s:n}#_option() | endif " just to sure
  " if type(get(a:, 1, ''))==0 | let v:foldstart = a:1 | endif " for TEST
  " if type(get(a:, 2, ''))==0 | let v:foldlevel = a:2 | endif
  if type(get(a:, 1, ''))==0 " for TEST
    let v:foldstart = a:1 | let ft = get(a:, 3, &ft)
    let a = get(a:, 2)-0 | let v:foldlevel = a<1 ? 1 : a
    let v:foldend = rand()%(line('$')-v:foldstart)+v:foldstart
  else | let ft = &ft | endif

  if !exists(printf('b:%s_header', s:n))
    let b:{s:n}_header = {} " reserve management
    let b:{s:n}_header.line = line('$')
    au! InsertLeave,TextChanged <buffer>
      \ if s:get(b:, s:n..'_header.line')!=line('$') |
      \   let b:{s:n}_header.line = line('$') |
      \   let b:{s:n}_header.text = {} |
      \   let b:{s:n}_header.pat = '' | endif
  endif
  let rp = b:{s:n}_header | let ww = s:winwidth()

  if get(rp, 'width')==ww && ft==&ft " use reserve data!
    let a = s:get(rp, printf('text.%d:%d', v:foldstart, v:foldlevel))
    if !s:is(a, 0) | return a | endif
  else | let rp.width = ww | let rp.text = {} | endif

  let opt = deepcopy(s:{s:n}._.header) " read options
  for [k, v] in items(opt)
    let vv = s:get(s:{s:n}, printf('%s.header.%s', ft, k), v)
    if !s:is(vv, []) | let opt[k] = vv | endif
  endfor

  let cw = s:get(s:{s:n}, ft..'.header.width', s:get(s:{s:n}, '_.header.width'))
  let cw = type(cw)==1 ? ((&tw>0 ? &tw : 78) + substitute(cw, '\v^\++', '', '')) : cw-0
  let cw = min([cw<12 ? 78 : cw, ww]) " current-width

  let prm = s:get_param()
  let fmt = opt.format[min([prm.v, len(opt.format)])-1] " text-fromat each fold-lv
  let pat = s:get(rp, 'pat', '')
  if pat=='' | let a = map([prm.c, prm.m, prm.M, prm.C], {_,v-> s:esc(v)})
    " let pat = printf('\v\s+(%s)?[%s]*(%s|%s)\d*\s*(%s)?\s*$', a[0], s:SMB, a[1], a[2], a[3])
    let pat = printf('\v\s+(%s)?\s*(%s|%s)\d*\s*(%s)?\s*$', a[0], a[1], a[2], a[3])
    let rp.pat = pat
  endif

  let txt = '' | let i = prm.s
  while txt=='' && 0<i && prm.e>i
    let prm.T = i | let a = getline(i) | let i = nextnonblank(i+1)
    " let a = (a=~'\v^['..s:SMB..']*$') ? '' : substitute(a, pat, '', 'g')
    let a = (a=~'\v^['..s:SMB..']*$') ? '' : a " not to modify it best?
    let txt = trim(a, " \t")
  endwhile
  if txt==''
    " let txt = substitute(getline(prm.s), pat, '', 'g' )
    let txt = getline(prm.s)
    let prm.T = prm.s
  endif
  if len(opt.modify) | let txt = s:replace(txt, flattennew(opt.modify)) | endif
  let txt = substitute(txt, '\v\%', "\x06", 'g')

  " ......................................................................{{{
  fu! s:_header_expr(v) " %{ ... %}  @nested support?
    let v = a:v[1] | return v=~'\v\%\{'
      \ ? '%{'..substitute(v, '\v\%\{(.{-})$', funcref('s:_header_expr'), '')
      \ : execute('echon '..tr(v, "\x06", '%'))
  endfu
  " ......................................................................}}}

  let fmt = substitute(fmt, '\v\%\%', "\x06", 'g') " formating-header
  let fmt = substitute(fmt, printf('\v\C\%%([%s])', join(keys(prm), '')), {v-> prm[v[1]]}, 'g')
  let a = '' | while a!=fmt | let a = fmt
    let fmt = substitute(fmt, '\v\%\{(.{-})\%\}', funcref('s:_header_expr'), 'g')
  endwhile

  if fmt!~'\v\C\%t' | let txt = '' | endif " adjust-width
  let fc = matchstr(fmt, '\v\%\<\zs.{-}\ze\%\>')
  let hw = strwidth(substitute(fmt, '\v\C\%t|\%\<.{-}\%\>', '', 'g'))
  let fc = fc=='' ? ' ' : fc | let pw = cw - hw

  if pw<strwidth(txt) " text shotning
    let t = txt | let a = pw-strwidth(opt.ellipsis) | let tw = strchars(t)-1
    while strwidth(t)>opt.min && strwidth(t)>a " multi-byte support?
      let t = strcharpart(t, 0, tw) | let tw-= 1
    endwhile
    let txt = t..opt.ellipsis
  endif

  let pw-= strwidth(txt) " fill-char
  let t = strcharpart(repeat(fc, pw), 0, pw) | let tw = pw-1
  while strwidth(t)>pw " multi-byte support?
    let t = strcharpart(t, 0, tw) | let tw-= 1
  endwhile
  let t = repeat(' ', pw-strwidth(t))..t " fill-space

  let fmt = substitute(fmt, '\v\C\%t', s:esc(txt, 1), '')
  let fmt = substitute(fmt, '\v\%\<.{-}\%\>', s:esc(t, 1), '')
  let fmt = substitute(fmt, '\v\C\%t|\%\<.{-}\%\>', '', 'g')
  let fmt = strcharpart(substitute(fmt, '\v%x06', '%', 'g')..repeat(" ", ww), 0, ww+8)

  if ft==&ft " reserve header-text
    let rp.text[printf('%d:%d', prm.s, prm.v)] = fmt
  endif
  return fmt
endfu


" ________________________________________________________________________{{{2
fu! {s:n}#_marker(...) abort " ([flg: 0:{ 1:}], [lv=v:count])  @keymaps
  if &fdm=='manual' | return execute('normal! zf') | endif
  if !exists('s:'..s:n) | call {s:n}#_option() | endif " stand up option

  let [flg, lv] = [get(a:, 1)!=0, get(a:, 2, v:count)]
  let ml = [line('v'), line('.')] | let ml = ml[1]<ml[0] ? [ml[1], ml[0]] : ml
  let cms = split(&cms..'%s', '\v\s*\%s\s*')[:1]
  let fmr = split(&fmr..',', '\v\s*\,\s*')[:1]

  let opt = copy(s:{s:n}._.marker) " width
  for [k, v] in items(opt) | let opt[k] = s:get(s:{s:n}, printf('%s.marker.%s', &ft, k), v) | endfor
  let mw = !s:is(opt.width, 0) ? opt.width : s:get(s:{s:n}, &ft..'.header.width', s:get(s:{s:n}, '_.header.width'))
  let mw = (type(mw)==0 && mw>3) ? mw : (&tw>0 ? (&tw + (matchstr(''..mw, '\v\-?\d+')-0)) : 78)
  let fc = len(opt.fill)>0 ? opt.fill[min([lv, len(opt.fill)-1])] : ' '
  let chl = hlID('Comment')

  let pat = s:esc(join(map(copy(opt.fill), {_,v-> substitute(v, ' ', '', 'g')}), ''))
  let a = map(extend(copy(cms), copy(fmr)), {_,v-> s:esc(v)}) " match-pattern
  let pat = [
    \   printf('\v\C\s*%s%%([ \t%s]*%%(%s|%s)\d*)+\s*%s\s*$', a[0], pat, a[2], a[3], a[1]),
    \   printf('\v\C^(.{-}%s.{-})([ \t%s]{-}%%(%s|%s)\d*\s*)+(.{-}%s.{-})$', a[0], pat, a[2], a[3], a[1]),
    \   printf('\v^(.*\S)\s*(\S*%s.{-})$', a[1]),
    \   printf('\v\C^(.*%s.*)\s*(%s.{-})$', a[0], a[1]),
    \ ] " .3 no used


  fu! s:_insmrk(...) closure " (lnum, flg) ...............................{{{3
    let f = get(a:, 2)!=0 | let s = getline(a:1)
    let al = f ? prevnonblank(a:1) : nextnonblank(a:1)
    " @OLD - -  - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -{{{
    " if al!=a:1 " blank
    "   let row = [printf('%s%s', (abs(al-a:1)==1 ? repeat(' ', indent(al)) : ''), cms[0]), cms[1]]
    " elseif s=~pat[2] " comment
    "   let row = matchlist(s, pat[2])[1:]
    " else " normal
    "   let row = [substitute(s, '\v\s*$', ' '..cms[0], ''), cms[1]]
    " endif " - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -}}}
    if al!=a:1 " blank-line
      let row = [printf('%s%s', (abs(al-a:1)==1 ? repeat(" ", indent(al)) : ''), cms[0]), cms[1]]
    else " comment is check by syntax ...parsing be too pain X(
      let [c, lc] = [col([a:1, '$']), -1]
      while c>0
        if chl==synIDtrans(synID(a:1, c, 1)) && (lc<0 || lc>c) | let lc = c | endif
        let c-= 1
      endwhile
      if lc>0 && match(s, pat[2], lc)>=0 " has comments
        let row = matchlist(strpart(s, lc), pat[2])[1:]
        let row[0] = strpart(s, 0, lc)..row[0]
      else " no comment
        let row = [substitute(s, '\v\s*$', ' '..cms[0], ''), cms[1]]
      endif
    endif

    let mrk = fmr[f]..(lv>0 ? lv : '') " string-fill
    let row = [row[0]..' ', (row[1]!='' ? ' '..row[1] : '')]
    let len = mw-strwidth(join(row, '')..mrk)
    let ff = strcharpart(repeat(fc, len), 0, len) | let fl = strcharlen(ff)-1
    while len>0 && ff!='' && strwidth(ff)>len " for multi-byte char
      let ff = strcharpart(ff, 0, fl) | let fl-= 1
    endwhile

    return row[0]..repeat(' ', len-strwidth(ff))..ff..mrk..row[1]
  endfu " ................................................................}}}3


  let frm = [&ro, &ma] | if get(opt, 'bang') | let [&ro, &ma] = [0, 1] | endif

  let ff = reduce(map(range(4), {i-> stridx(getline(ml[i/2]), fmr[i%2])>=0}), {a,b-> a+b})>0
  if ff | for l in range(ml[0], ml[1]) " remove marker
    call setline(l, s:replace(getline(l), pat[0], '', pat[1], '\1\3'))
  endfor | endif

  if (!ff || lv) " place the marker
    call setline(ml[0], s:_insmrk(ml[0], (flg && ml[0]==ml[1])))
    if ml[0]!=ml[1] | call setline(ml[1], s:_insmrk(ml[1], 1)) | endif
  endif
  if get(opt, 'bang') | let [&ro, &ma] = frm | endif

  call execute("normal! \<C-\>\<C-n>") " -> Normal (exit Visual-Mode)
endfu


" ________________________________________________________________________{{{2
fu! {s:n}#_fold(...) abort " (['type'/lnum])  @fold_expr
  if !exists('s:'..s:n) | call {s:n}#_option() | endif " just to sure
  if !exists('b:'..s:n..'_fold') | let b:{s:n}_fold = {} | endif

  " - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -{{{
  fu! s:_check() " = code? / text?
    if &ft=~?'^help$' | return 'text' | endif
    let a = line('$') | let l = extend(range(a/2+1, a), range(1, a/2))
    let [a, b, c] = [0, 0, [10, 0]] | let j = 0
    for i in l
      if max(c)>200 | break | elseif i<j | continue | endif
      let j = nextnonblank(i)
      if j>i | if j>(i+1) | let c[1]+= 2 | endif | continue | endif

      let a = indent(i)/shiftwidth()
      if abs(a-b)==1 | let c[0]+= 3 | endif
      let b = a

      let s = getline(i)
      if s!~'\v[!-+:-?\[-`{-~]'
        let c[1]+= strwidth(s)/8
      elseif s=~'\v^\s*[\}\]]|[\{\[\)\;]\s*$|^\s*(\#{2,})\s+\S'
        let c[0]+= 2
      elseif s=~'\v^\s*([\#\=\-\*\+])(\s*\1){7,}\s*$'
        let c[1]+= 20
      endif
    endfor
    let ret = ['code', 'text'][index(c, max(c))]

    return ret
  endfu
  " - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -}}}

  let type = get(b:{s:n}_fold, 'type', '') | let a = get(a:, 1)
  let a = type(a)!=1 ? '' :
    \ a=~'\v\c<a%[uto]>' ? 'auto' :
    \ a=~'\v\c<c%[ode]>' ? 'code' :
    \ a=~'\v\c<t%[ext]>' ? 'text' :
    \ a=~'\v\c<m%[atch]>' ? 'match' : ''

  if (a!='' || type=='') " set fold-type
    let type = a!='' ? a : s:get(s:{s:n}, &ft..'.fold.type', s:get(s:{s:n}, '_.fold.type', 'auto'))
    if type=='auto' | let type = s:_check() | endif
    if exists('b:'..s:n..'_fold.switched') | unlet! b:{s:n}_fold.switched | endif
    unlet! b:{s:n}_fold.expr
    let b:{s:n}_fold.type = type " v re-folding
    if a!='' | let &l:fdm = 'expr' | let &l:fde = 'foldstaff#fold()' | return 1 | endif
  endif

  if s:is(get(b:{s:n}_fold, 'switched', -1), -1) " key-switch
    let a = s:get(s:{s:n}, &ft..'.fold.keyswitch', s:get(s:{s:n}, '_.fold.keyswitch', 0))
    if a<0 | let a = type=='text' | endif
    let b:{s:n}_fold.switched = s:key_switch(a)
  endif

  return type=='code' ? function('s:fold_code', a:000)() :
    \ type=='text' ? function('s:fold_text', a:000)() :
    \ type=='match' ? function('s:fold_match', a:000)() : -1
endfu

  " ......................................................................{{{3
  fu! s:fold_code(...) abort " ([lnum])  =  fold-expr result
    " at the last, simple is better, it seems...

    " - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -{{{
    fu! s:_mk(...) closure " (lnum, foldLv) = foldLv as Marker
      let s = getline(a:1) | let v = get(a:, 2)
      if !s:is_cmt(a:1) && s=~fmr[2] " markdown: ### header
        let v = '>'..strlen(matchstr(s, fmr[2]))
      elseif s=~fmr[0] " Vim: marker
        let b = matchlist(s, fmr[0])
        let v = '<>'[b[1]==fmr[1]]..(b[2]!='' ? b[2] : (b[1]==fmr[1] ? v+1 : v))
      " elseif s=~'\v^\s*([\~\`])\1{2,}|([\~\`])\2{2,}\s*$'
      "   let ep[4] = xor(ep[4], 1) " md: code-block -> at markers will enough?
      "   let v = and(ep[4], 1) ? '>'..(v+1) : '<'..v
      elseif s=~'\v\c\#%(e%[nd]|\/)?re?g%[io]n>' " #[end]region
        let v = s=~'\v\c\#%(e%[nd]|\/)re?g%[io]n>' ? '<'..(v-1) : '>'..(v+1)
      endif

      if !s:is(v, a:2) | let ep[1] = v[1]-(v[0]=='<') | endif
      return v
    endfu " - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -}}}
    " - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -{{{
    fu! s:_fv(...) " (lnum, [move= +1]) = foldLv
      let a = get(a:, 2)-0
      return foldlevel(a<0 ? prevnonblank(a:1-1) : nextnonblank(a:1+(a>0 ? 1 : 0)))
    endfu " - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -}}}
    " - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -{{{
    fu! s:_iv(...) " (lnum, [move= +1]) = indentLv
      let a = get(a:, 2)-0
      return indent(a<0 ? prevnonblank(a:1-1) : nextnonblank(a:1+(a>0 ? 1 : 0)))/shiftwidth()
    endfu " - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -}}}
    fu! s:_rv(...) " (lnum) = resume foldLv? - - - - - - - - - - - - - - - {{{
      let mk = s:_mk(a:1-1, s:_fv(a:1-2)) " # check end-marker
      if mk=~'\v\<\d+' | return mk[1:]-1 | endif
      let pf = s:_fv(a:1, -1)
      let pi = s:_iv(a:1, -1)-s:_iv(nextnonblank(a:1))
      return pi>0 ? max([0, pf-pi]) : pf
    endfu " - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -}}}


    let cl = get(a:, 1, v:lnum)-0 | if cl==0 | let cl = v:lnum | endif
    let ep = get(b:{s:n}_fold, 'expr', [0])
    let fmr = get(b:{s:n}_fold, 'fmr')
    if ep[0]!=cl " next-line, foldLv, idxLv, skip-row, block-flg
      let ep = [0, s:_rv(cl), s:_iv(cl), 0, 0]
      let b:{s:n}_fold.expr = ep
    endif
    if s:is(fmr, 0) " regexp-pattern
      let a = split(&fmr..',', ',')[:1] | let b = map(copy(a), {_,v-> s:esc(v)})
      let fmr = [
        \ printf('\v^.*(%s|%s)(\d*)', b[0], b[1]), a[0],
        \ '\v^\s*\zs(\#+)\ze\s+[^ \t\#\-\=]',
        \ '\v^\s*\|.{-}\|.{-}\|\s*$']
      let b:{s:n}_fold.fmr = fmr
    endif
    let pp = ep[1] | let ep[0] = cl+1

    if cl<=ep[3] | return pp | endif " @skip
    let nl = nextnonblank(cl) " blank-row
    if nl>cl | let ep[3] = nl-1 | return pp | endif

    let mk = s:_mk(cl, pp) " @ マーカー判定
    if !s:is(mk, pp) | return mk | endif

    let ni = max([0, s:_iv(cl, 1)])
    if ni!=ep[2] | let ep[1:2] = [max([0, ep[1]+ni-ep[2]]), ni] | endif
    return ep[1]>pp ? '>'..ep[1] : pp
  endfu

  " ......................................................................{{{3
  fu! s:fold_text(...) abort " ([lnum])  =  fold-expr result

    " - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -{{{
    fu! s:_rs(...) closure " (lnum)  =  'character of row-state'
      let r = getline(a:1)
      return r=~'\v^\s*[\<\>]?$' ? ' ' :
        \   r=~'\v^\s*([\=\#\/])\s*(\1\s*){7,}$' ? '=' :
        \   r=~'\v^\s*([-\+\*])\s*(\1\s*){7,}$' ? '-' :
        \   r=~'\v^\S?[^\t -/:-@[-`{-~]+' ? 'a' : 'b'
        " \   r=~'\v^\s*\}{3,}' ? '}' : r=~'\v\{{3,}\s*$' ? '{' :
    endfu " - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -}}}

    let cl = get(a:, 1, v:lnum)-0 | if cl==0 | let cl = v:lnum | endif
    let ep = get(b:{s:n}_fold, 'expr', [0])
    if ep[0]!=cl " next-line, foldLv, 'row-states[l-1..l+2]'
      let ep = [cl, foldlevel(cl-1), '']
      for i in range(cl-1, cl+1) | let ep[2]..= s:_rs(i) | endfor
      let b:{s:n}_fold.expr = ep
    endif
    let ep[0]+= 1 | let ep[2]..= s:_rs(cl+2) | let [p, s] = ep[1:2]

    let s = s:replace(s,
      \   ['\v [123a]\=', ' 1b'],
      \   ['\v [23a]\-', ' 2b'],
      \   ['\v([\~\-]\s?)\S', '\1b'],
      \   ['\v2.\-', '2bb'],
      \   ['\v  [3a]', 'b3b'],
      \ )
    let ep[2] = s[1:]

    if s=~'\v^.[\=\-]'
      let p = 0
    elseif s=~'\v^..[1-9\=\-]' && p>0
      let p = '<1'
    elseif s=~'\v^.\d'
      let p = '>'..s[1]
    elseif s=~'\v^\='
      let p = '>1'
    elseif s=~'\v^\-'
      let p = '>2'
    elseif s=~'\v^.\{'
      let p = 'a1'
    elseif s=~'\v^.\}'
      let p = 's1'
    endif

    if type(p)==1 | let ep[1] = p[1]-(p[0]=='<' ? 1 : 0) | endif
    return p
  endfu

  " ......................................................................{{{3
  fu! s:fold_match(...) abort " ([lnum])  =  fold-expr result
    let pat = s:get(s:{s:n}, &ft..'.fold.match', s:get(s:{s:n}, '_.fold.match', []))
    if len(pat)<1
      if !s:is(s:get(b:, 'foldstaff_fold.expr'), 'Q')
        echoh Todo
        execute printf('echom "%s#fold(\"match\"): No have match pattern..."', s:n)
        echoh NONE
      endif
      let b:foldstaff_fold.expr = 'Q' | return -1
    endif

    let cl = get(a:, 1, v:lnum)-0 | if cl==0 | let cl = v:lnum | endif
    let pv = '='
    for p in pat
      let el = len(p)-1 | let sl = cl-el/2 | let h = el
      for i in range(el)
        if p[i+1]=='' | let h-= 1 | continue | endif
        if getline(sl+i)=~#p[i+1] | let h-= 1 | else |  break | endif
      endfor
      if h==0 | let pv = p[0] | break | endif
    endfor
    return pv
  endfu
" ========================================================================}}}1
if !exists(printf('s:%s._', s:n)) | call {s:n}#_option() | endif " initialize

let &cpo = s:t_cpo | unlet s:t_cpo
" vim:set ft=vim fenc=utf-8 norl:                             Author: HongKong
