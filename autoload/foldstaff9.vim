vim9script
# ========================================================================{{{1
# Plugin:     foldstaff-vim
# LasCahnge:  2022/02/11  v1.02
# License:    MIT License
# Filenames:  %/../../plugin/foldstaff.vim
#             foldstaff.vim
#             foldstaff9.vim
# ========================================================================}}}1

const t_cpo = &cpo | set cpo&vim
# const n = expand("%:t:r")

# OPTIONS: ==============================================================={{{1
var foldstaff = {}
const foldstaff_default = {
    header: {
      format: [
        '%i%t %<%>%{repeat("[", %v)%}%L]',
      ],
      width: '+0',
      modify: [],
      min: 8,
      ellipsis: '~',
    },
    marker: {
      fill: [
        '- ',
        '=', '_', '.',
      ],
      width: 0,
      # bang: 0,
    },
    fold: {
      type: 'auto',
      keyswitch: -1,
      match: [],
    },
  }

# ========================================================================}}}1

const SMB = '\t -@\[-`{-~' # symbol-pattern @\v

# MODULE: ================================================================{{{1
  # ______________________________________________________________________{{{2
  def Is(a: any = 0, b: any = 0): bool
    return (type(a) == type(b)) && (a == b)
  enddef

  # ______________________________________________________________________{{{2
  def Esc(s: string, f: number = 0): string # ('str', [flg=0:pat 1:sub]) = escape_string
    # return escape(s, '$%&()=^~\|@[{+*]}<>?')
    return escape(s, (f != 0 ? '$%&()^|\|@[{+*]}<>?' : '$%&()-=^~\|@[{+*]}<.>?'))
  enddef

  # ______________________________________________________________________{{{2
  def Get(...arg: list<any>): any # (var, '{key/idx...}', [default=0]) = value @deepget()
    if len(arg) < 1 | return 0 | elseif len(arg) == 1 | return arg[0] | endif
    var r = arg[0] | var d = get(arg, 2, 0)
    var k = map(split('' .. arg[1], '\v\s*[\[\]\.]+\s*'), (_, v) => substitute(v, '\v^([''"])(.*)\1$', '\2', ''))

    const _gf = {
      1: (a, b) => ((strlen(a) > b) ? a[str2nr(b)] : 0z00ff),
      2: (a, b) => get(a, b, 0z00ff),
      3: (a, b) => ((len(a) > str2nr(b)) ? a[str2nr(b)] : 0z00ff),
      4: (a, b) => (has_key(a, b) ? a[b] : 0z00ff),
     10: (a, b) => get(a, b, 0z00ff)}

    for c in k
      r = has_key(_gf, type(r)) ? _gf[type(r)](r, c) : 0z00ff
      if Is(r, 0z00ff) | r = d | break | endif
    endfor

    return r
  enddef

  # ______________________________________________________________________{{{2
  def Set(...arg: list<any>): any # ('var', [value]) = var #CAUTION:"s:"
    var [t, v, r, e] = [get(arg, 0, 'g:tmp'), get(arg, 1), null, '']
    t = split(substitute(t, '\v\C^([gtwb]\:)', '\1.', ''), '\v[ \.\[\]''"]+')
    if !exists(t[0]) | return r | endif | r = eval(t[0])
    if len(t) < 2 | r = v | return r | endif

    for i in range(1, len(t) - 2)
      if (type(r) == 3) && (t[i] =~ '\v^\-?\d+$')
        var j = str2nr(t[i])
        if !(len(r) > j) | j = len(add(r, {})) - 1 | endif
        r = r[j]
      else
        if (type(r) != 4) | r = {} | endif
        if !has_key(r, t[i]) | r[t[i]] = {} | endif
        r = r[t[i]]
      endif
    endfor
    if (type(r) == 3) && (t[-1] =~ '\v^\-?\d+$') | t[-1] = min([len(r), str2nr(t[-1])]) | endif

    r[t[-1]] = v
    return r
  enddef

  # ______________________________________________________________________{{{2
  def IsCmt(l: number = line('.')): bool
    return hlID('Comment') == synIDtrans(synID(l, indent(l) + 1, 1))
  enddef

  # ______________________________________________________________________{{{2
  def Winwidth(cid: number = 0): number # ([winID=0]): visible-cols
    var wid = cid
    if wid < 1000 | wid = win_getid(wid) | endif
    if wid < 1000 | wid = win_getid() | endif

    var wo = getwinvar(wid, '&')
    var wn = [wo.foldcolumn, 0, 0]
    var scl = wo.signcolumn
    if  scl =~? 'yes'
      wn[1] = 2
    elseif (scl =~? 'auto' || (scl =~? 'number' && !wo.number))
      if len(sign_getplaced(winbufnr(wid))[0].signs) > 0 | wn[1] = 2 | endif
    endif
    wn[2] = wo.number * max([wo.numberwidth, strlen(line('$', wid))])
    return winwidth(wid) - reduce(wn, (a, b) => a + b)
  enddef

  # ______________________________________________________________________{{{2
  def Replace(...args: list<any>): string
    if args == [] | return '' | endif
    var a = flattennew(args) | var flg = 0
    if (type(a[-1]) == 0)
      flg = (a[-1] != 0) ? 1 : 0 | a = a[0 : -2]
    endif
    var ret = a[0] | a = a[1 : ] | if len(a) < 2 | return ret | endif

    var [reg, p, q] = [[], '', '']
    for i in range(0, len(a) - 1, 2)
      if a[i] =~ '\v\c^\\[os]' | a[i] = a[i][2 : ] | q = '' | else | q = 'g' | endif
      add(reg, [a[i], a[i + 1], q])
    endfor

    while p != ret | p = ret
      for r in reg | ret = substitute(ret, r[0], r[1], r[2]) | endfor
      if flg == 0 | break | endif
    endwhile

    return ret
  enddef

  # ______________________________________________________________________{{{2
  def Strfill(s: string, l: number, p: number = 0): string
    var r = strcharpart(repeat(s, l), 0, l) | var c = strcharlen(r) - 1
    while (l > 0) && (r != '') && (strwidth(r) > l) # support multi-byte char
      r = strcharpart(r, 0, c) | c -= 1
    endwhile
    var pp = repeat(' ', l - strwidth(r))
    return (p == 2 ? pp : '') .. r .. (p == 1 ? pp : '')
  enddef

  # ______________________________________________________________________{{{2
  function Ec(v) # want run echo(eval) in the old-Vim
    return execute('echon '..tr(a:v, "\x06", '%'))
  endfunction

# SUB: ==================================================================={{{1
# ________________________________________________________________________{{{2
def ShowOpt(opt: dict<any> = foldstaff)
  var gen = foldstaff._ | var flg = has_key(opt, '_')
  var t = repeat(' ', ((&sw != 0) ? &sw : ((&ts != 0) ? &ts : 4)))
  var idt = map(['', '', '', ''], (i, v) => repeat(t, i + 1))

  var msg = ['foldstaff = {']
  for ft in keys(opt) | add(msg, printf('%s[''%s'']: {', idt[0], ft))
    for [fn, fo] in items(gen)
      var gg = (has_key(opt[ft], fn) ? '' : "\x01") | if (flg && (gg != '')) | continue | endif
      add(msg, printf('%s%s%s: {', gg, idt[1], fn))
      for k in keys(fo)
        var [g, ki] = ((gg == '') && has_key(opt[ft][fn], k)) ? ['', opt[ft][fn][k]] : ["\x01", fo[k]]
        if ((g != '') && flg) | continue | endif

        if (type(ki) == 3) && (len(ki) > 1)
          add(msg, printf('%s%s%s: [', gg, idt[2], k))
          for i in ki | add(msg, printf('%s%s%s,', g, idt[3], string(i))) | endfor
          add(msg, printf('%s%s],', gg, idt[2]))
        else
          add(msg, printf('%s%s%s: %s,', g, idt[2], k, string(ki)))
        endif
      endfor | add(msg, printf('%s%s},', gg, idt[1]))
    endfor | add(msg, idt[0] .. '},')
  endfor | add(msg, '}')

  map(msg, (i, v) => substitute(v, "'", "''", 'g'))
  for m in msg
    if m =~ '\v^%x01'
      execute('echoh Comment')
      execute printf('echo ''%s''', m[1 :])
      execute('echoh None')
    else | execute printf('echo ''%s''', m) | endif
  endfor
enddef

# ________________________________________________________________________{{{2
def GetPrm(): dict<any> # header attributes
  var ll = line('$')
  var prm = { # - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -{{{
      s: v:foldstart,
      e: v:foldend,
      l: v:foldend - v:foldstart + 1,
      v: v:foldlevel,
      V: foldlevel(v:foldstart),
      d: v:folddashes,
      D: &diff ? 1 : 0,
      i: repeat(' ', indent(v:foldstart)),
      I: indent(v:foldstart) / shiftwidth(),
      p: 100 * v:foldstart / ll,
      P: printf('%5.1g', 100.0 * v:foldstart / ll),
  } # - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -}}}
  var a = printf('%%%dd', strwidth(string(ll)))
  extend(prm, map({S: '', E: '', L: ''}, (k, v) => printf(a, prm[tolower(k)])))
  [prm.c, prm.C] = split(&cms .. '%s', '\v\%s')[: 1] # comment-string
  [prm.m, prm.M] = split(&fmr .. ',', ',')[: 1] # fold-marker
  return prm
enddef

# ________________________________________________________________________{{{2
def KeySwitch(flg: number = 0): number # ([0:OFF 1:ON -1:toggle])  # witch folding Keys
  var f = flg | var keys = ['za', 'zc', 'zo', '', 'zA', 'zC', 'zO', '']
  if (f < 0) | f = xor(Get(b:, 'foldstaff_fold.switched'), 1) | endif

  for i in range(len(keys))
    if (keys[i] == '') | continue | elseif (f > 0)
      execute(printf('noremap <buffer> %s %s', keys[i], keys[xor(i, 4)]))
    else
      execute(printf('unmap <buffer> %s', keys[i]), 'silent!')
    endif
  endfor
  return flg
enddef

# MAIN: =================================================================={{{1
# ________________________________________________________________________{{{2
export def Option(...arg: list<any>): string # ([{options}], [flg: 1:new 2:show]) = '{options}'
  var opt = get(arg, 0) | var flg = get(arg, 1) | var bad = []

  if and(flg, 1) == 1 || !exists('foldstaff._')
    foldstaff = {'_': deepcopy(foldstaff_default)}
  endif

  if type(opt) != 4 | opt = get(g:, 'foldstaff') | endif # @Setting
  if type(opt) == 4
    for ft in keys(opt) # file-type
      if type(opt[ft]) != 4 || Is(opt[ft], {}) | continue | endif
      for [fn, fo] in items(opt[ft]) # func: header/marker/fold
        if type(fo) != 4 || !has_key(foldstaff_default, fn)
          add(bad, printf('[''%s''].%s', ft, fn)) | continue
        endif
        for k in keys(fo) # func-attributes
          if !has_key(foldstaff_default[fn], k) # spell-miss?
            add(bad, printf('[''%s''].%s.%s', ft, fn, k)) | continue
          elseif type(fo[k]) == 4 | for [i, v] in items(fo[k]) # list-index?
            if i !~ '\v^\-?\d+?' | continue | endif # 部分追加
            var tl = Get(foldstaff, printf('%s.%s.%s', ft, fn, k), [])
            Set(printf('foldstaff.%s.%s.%s', ft, fn, k), tl)
            Set(printf('foldstaff.%s.%s.%s.%s', ft, fn, k, i), v)
          endfor | else
            Set(printf('foldstaff.%s.%s.%s', ft, fn, k), fo[k]) # Added
          endif
        endfor
      endfor
    endfor
  endif

  # ec foldstaff bad
  var ret = {} # make result-DICT
  if (type(opt) != 4) | ret = foldstaff | else
    for ft in keys(opt) | ret[ft] = Get(foldstaff, ft, {}) | endfor
  endif

  if (and(flg, 2) == 2) | call ShowOpt(ret) | endif # show

  if (len(bad) > 0) # too too extra care...
    execute 'echoh ToDo'
    for i in bad
      execute printf('echo "foldstaff: invalid option-key ignored.  >>  %s"', i)
    endfor
    execute 'echoh None'
  endif

  if exists('b:foldstaff_header') | b:foldstaff_header.text = {} | endif
  if (&fdm == 'expr') && (&l:fde == 'foldstaff#fold()') | &l:fde = 'foldstaff#fold()' | endif
  return string(ret)
enddef


# ________________________________________________________________________{{{2
export def Header(...arg: list<any>): string
  if !exists('foldstaff') | foldstaff9#option() | endif
  var ft = &ft

  if (type(get(arg, 0, '')) == 0) # for TEST
    v:foldstart = arg[0] | ft = get(arg, 2, &ft)
    v:foldlevel = max([1, str2nr(matchstr(string(get(arg, 1, "1")), '\v\d+'))])
    v:foldend = rand() % (line('$') - v:foldstart) + v:foldstart
  endif

  if !exists('b:foldstaff_header.line') # reserve management
    b:foldstaff_header = {line: line('$')}
    # echom 'set-AU' # mistakes sometimes ???
    au! InsertLeave,TextChanged <buffer> if Get(b:, 'foldstaff_header.line') != line('$') | b:foldstaff_header.line = line('$') | b:foldstaff_header.text = {} | b:foldstaff_header.pat = '' | endif
  endif

  var rp = b:foldstaff_header | var ww = Winwidth()

  if (get(rp, 'width') == ww) && (ft == &ft) # use reserve text!
    var r = Get(rp.text, printf('%d:%d', v:foldstart, v:foldlevel))
    if !Is(r, 0) | return r | endif
  else | rp.width = ww | rp.text = {} | endif

  var opt = deepcopy(foldstaff._.header)
  for [k, v] in items(opt) # read options
    var vv = Get(foldstaff, printf('%s.header.%s', ft, k), v)
    if !Is(vv, []) | opt[k] = vv | endif
  endfor

  var cw = opt.width
  cw = (type(cw) == 0) ? cw : ((&tw > 0 ? &tw : 78) + str2nr(matchstr(cw, '\v\-?\d+')))
  cw = min([ww, cw < 12 ? 78 : cw]) # text-width

  var prm = GetPrm()
  var fmt = opt.format[min([prm.v, len(opt.format)]) - 1]
  var pat = Get(rp, 'pat', '')
  if (pat == '')
    pat = printf('\v\s+(%s)?\s*(%s|%s)\d*\s*(%s)?\s*$', Esc(prm.c), Esc(prm.m), Esc(prm.M), Esc(prm.C))
    rp.pat = pat
  endif

  var txt = '' | var i = prm.s
  while (txt == '') && (0 < i) && (prm.e > i)
    prm.T = i | var a = getline(i) | i = nextnonblank(i + 1)
    a = (a =~ '\v^[' .. SMB .. ']*$') ? '' : a
    txt = trim(a, " \t")
  endwhile
  if (txt == '') | txt = getline(prm.s) | prm.T = prm.s | endif
  if len(opt.modify) > 0 | txt = Replace(txt, flattennew(opt.modify)) | endif
  txt = substitute(txt, '\v\%', "\x06", 'g')

  def HeaderExpr(v: string): string # %{...%} @nested support? - - - - - {{{
    return v =~ '\v\%\{' ?
      '%{' .. substitute(v, '\v\%\{(.{-})$', (vv) => function('HeaderExpr', [vv[1]])(), '') : Ec(v)
      # execute('echon ' .. tr(v, "\x06", '%')) # In Vim9, even `echo` requires spaces... it's too pain X(
  enddef # - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - }}}

  fmt = substitute(fmt, '\v\%\%', "\x06", 'g') # fformatting-header
  fmt = substitute(fmt, printf('\v\C\%%([%s])', join(keys(prm), '')), (v) => prm[v[1]], 'g')
  var a = '' | while (a != fmt) | a = fmt
    fmt = substitute(fmt, '\v\%\{(.{-})\%\}', (v) => HeaderExpr(v[1]), 'g')
  endwhile
  if (fmt !~ '\v\C\%t') | txt = '' | endif

  var fc = matchstr(fmt, '\v\%\>\zs.{-}\ze\%\>') | fc = (fc == '') ? ' '  : fc
  var hw = strwidth(substitute(fmt, '\v\C\%t|\%\<.{-}\%\>', '', 'g'))

  var pw = cw - hw
  if pw < strwidth(txt) # text shotning
    txt = Strfill(txt, max([opt.min, pw - strwidth(opt.ellipsis)])) .. opt.ellipsis
  endif

  pw -= strwidth(txt) # fill-char
  var t = Strfill(fc, pw, 2)

  fmt = substitute(fmt, '\v\C\%t', Esc(txt, 1), '')
  fmt = substitute(fmt, '\v\C\%\<.{-}\%\>', Esc(t, 1), '')
  fmt = substitute(fmt, '\v\C\%t|\%\<.{-}\%\>', '', 'g')
  fmt = strcharpart(substitute(fmt, '\v%x06', '%', 'g') .. repeat(" ", ww), 0, ww + 8)

  if ft == &ft # reserve header-text
    rp.text[printf('%d:%d', prm.s, prm.v)] = fmt
  endif

  return fmt
enddef


# ________________________________________________________________________{{{2
export def Marker(flg: number = 0, lv: number = v:count): number # ([flg: 0:{ 1:}], [lv=v:count])  # for KeyMap
  if &fdm == 'manual' | execute('normal zf') | return -1 | endif
  if !exists('foldstaff') | foldstaff#option() | endif # standup option

  var ml = [line('v'), line('.')] | ml = (ml[1] < ml[0]) ? [ml[1], ml[0]] : ml
  const cms = split(&cms .. '%s', '\v\s*\%s\s*')[: 1]
  const fmr = split(&fmr .. ',', '\v\s*\,\s*')[: 1]

  var opt = deepcopy(foldstaff._.marker)
  for [k, v] in items(opt) | opt[k] = Get(foldstaff, printf('%s.mrker.%s', &ft, k), v) | endfor
  var mw = !Is(opt.width, 0) ? opt.width : Get(foldstaff, &ft .. 'header.width', Get(foldstaff, '_.header.width'))
  mw = (type(mw) == 0 && mw > 3) ? mw : ((&tw > 0) ? (&tw + str2nr(matchstr(string(mw), '\v\-?\d+'))) : 78)

  var fc = (len(opt.fill) > 0) ? opt.fill[min([lv, len(opt.fill) - 1])] : ' '
  var chl = hlID('Comment')

  var b = Esc(join(map(copy(opt.fill), (_, v) => substitute(v, ' ', '', 'g')), ''))
  var a = map(extend(copy(cms), copy(fmr)), (_, v) => Esc(v))
  var pat = [
    printf('\v\C\s*%s%%([ \t%s]*%%(%s|%s)\d*)+(.{-}%s.{-})$', a[0], b, a[2], a[3], a[1]),
    printf('\v\C^(.{-}%s.{-})([ \t%s]{-}%%(%s|%s)\d*\s*)+(.{-}%s.{-})$', a[0], b, a[2], a[3], a[1]),
    printf('\v^(.*\S)\s*(\S*%s.{-})$', a[1]),
  ]

  def Insmrk(ln: number, fl: bool = false): string # (lnum, flg) - - - - - -{{{
    var al = fl ? prevnonblank(ln) : nextnonblank(ln) | var row = []

    if ln != al # blank-line
      row = [printf('%s%s', ((abs(al - ln) == 1) ? repeat(" ", indent(al)) : ''), cms[0]), cms[1]]
    else # comment is check by syntax
      var [c, lc] = [col([ln, '$']), -1] | var s = getline(ln)
      while c > 0
        if chl == synIDtrans(synID(ln, c, 1)) && (lc < 0 || lc > c) | lc = c | endif | c -= 1
      endwhile
      if lc > 0 && match(s, pat[2], lc) >= 0 # has coments
        row = matchlist(strpart(s, lc), pat[2])[1 :]
        row[0] = strpart(s, 0, lc) .. row[0]
      else # no comment
        row = [substitute(s, '\v\s*$', ' ' .. cms[0], ''), cms[1]]
      endif
    endif

    var mrk = fmr[fl ? 1 : 0] .. (lv > 0 ? lv : '')
    row = [row[0] .. ' ', ((row[1] != '') ? (' ' .. row[1]) : '')]
    var ff = Strfill(fc, mw - strwidth(join(row, '') .. mrk), 2)

    return row[0] .. ff .. mrk .. row[1]
  enddef # - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - }}}

  var rm = [&ro, &ma]
  if (get(opt, 'bang') != 0) | [&ro, &ma] = [false, true] | endif

  var f = reduce(map(range(4), (_, i) => stridx(getline(ml[i / 2]), fmr[i % 2]) + 1), (d, e) => d + e) > 0
  if f | for l in range(ml[0], ml[1]) # remove markers
    setline(l, Replace(getline(l), pat[0], '', pat[1], '\1\3'))
  endfor | endif

  if (!f || lv > 0) # place marker
    setline(ml[0], Insmrk(ml[0], ((flg != 0) && (ml[0] == ml[1]))))
    if (ml[0] != ml[1]) | setline(ml[1], Insmrk(ml[1], true)) | endif
  endif

  if (get(opt, 'bang') != 0) | [&ro, &ma] = rm | endif
  execute("normal! \<C-\>\<C-n>") # exit Visual-Mode
  return 0
enddef


# ________________________________________________________________________{{{2
export def Fold(...arg: list<any>): any # (['type'/lnum])
  if !exists('foldstaff') | foldstaff9#Option() | endif # standup option
  if !exists('b:foldstaff_fold') | b:foldstaff_fold = {} | endif

  def FoldCheck(): string # code? / text? # - - - - - - - - - - - - - - - - - {{{
    if &ft =~? '^help$' | return 'text' | endif
    var b = line('$')
    var l = extend(range(b / 2 + 1, b), range(1, b / 2))
    var [a, c, d] = [0, [10, 0], 0] | b = 0
    for i in l
      if (max(c) > 200) | break | elseif i < d | continue | endif
      d = nextnonblank(i)
      if d > i | if d > (i + 1) | c[1] += 2 | endif | continue | endif

      a = indent(i) / shiftwidth()
      if abs(a - b) == 1 | c[0] += 3 | endif
      b = a

      var s = getline(i)
      if s !~ '\v[!-+:-?\[-`{-~]'
        c[1] += strwidth(s) / 8
      elseif s =~ '\v^\s*[\}\]]|[\{\[\)\;]\s*$|^\s*(\#{2,})\s+\S'
        c[0] += 2
      elseif s =~ '\v^\s*([\#\=\-\*\+])(\s*\1){7,}\s*$'
        c[1] += 20
      endif
    endfor
    ec c
    var ret = ['code', 'text'][index(c, max(c))]
    return ret
  enddef # - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - }}}

  # - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -{{{
  def FoldCode(qrg: list<any>): any # ([lnum]) = foldexpr-result
    var cl = get(qrg, 0, v:lnum)
    if (type(cl) != 0) || (cl == 0) | cl = v:lnum | endif
    var ep = get(b:foldstaff_fold, 'expr', [0])
    var fmr = get(b:foldstaff_fold, 'fmr')

    # - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -{{{
    def FoldCodeMark(ln: number, lv: number): any # (lnum, foldLv) = foldLv
      var [s, v] = [getline(ln), lv]
      if !IsCmt(ln) && (s =~ fmr[2]) # markdown: ### header
        v = '>' .. strlen(matchstr(s, fmr[2]))
      elseif (s =~ fmr[0]) # Vim: marker
        var b = matchlist(s, fmr[0])
        v = ((b[1] == fmr[1]) ? '>' : '<') .. ((b[2] != '') ? b[2] : ((b[1] == fmr[1]) ? v + 1 : v))
      elseif (s =~ '\v\c\#%(e%[nd]|\/)?re?g%[io]n>') # [end]region
        v = (s =~ '\v\c\#\%(e%[nd]|\/)re?g%[io]n>') ? ('<' .. (v - 1)) : ('>' .. (v + 1))
      endif
      if !Is(v, lv) | ep[1] = (v[0] == '<') ? (str2nr(v[1]) - 1) : str2nr(v[1]) | endif
      return v
    enddef # - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - }}}
    # - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -{{{
    def FoldCodeFoldLevel(ln: number, mv: number = 0): number # (lnum, [move = +1]) = foldLv
      return foldlevel((mv < 0) ? prevnonblank(ln - 1) : nextnonblank(ln + mv))
    enddef # - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - }}}
    # - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -{{{
    def FoldCodeIndentLevel(ln: number, mv: number = 0): number # (lnum, [move= +1]) = indentLv
      return indent((mv < 0) ? prevnonblank(ln - 1) : nextnonblank(ln + mv)) / shiftwidth()
    enddef # - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - }}}
    # - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -{{{
    def FoldCodeRestoreLevel(ln: number): number # (lnum) = resume foldLv?
      var mk = FoldCodeMark(ln - 1, FoldCodeFoldLevel(ln - 2))
      if (type(mk) == 1) && (mk =~ '\v\<\d+') | return str2nr(mk[1 :]) - 1 | endif
      var [pf, pi] = [FoldCodeFoldLevel(ln, -1), FoldCodeIndentLevel(ln, -1) - FoldCodeIndentLevel(ln, 0)]
      return (pi > 0) ? max([0, pf - pi]) : pf
    enddef # - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - }}}

    if (ep[0] != cl) # next-line, foldLv, idxLv, skipRow, blockFlg
      ep = [0, FoldCodeRestoreLevel(cl), FoldCodeIndentLevel(cl), 0, 0]
      b:foldstaff_fold.expr = ep
    endif

    if Is(fmr, 0) # regexp-pattern
      var a = split(&fmr .. ',', ',')[: 1]
      var b = map(copy(a), (_, v) => Esc(v))
      fmr = [
        printf('\v^.*(%s|%s)(\d*)', b[0], b[1]), a[0],
        '\v^\s*\zs(\#+)\ze\s*[^ \t\#\-\=]',
        '\v^\s*\|.{-}\|.{-}\|\s*$']
      b:foldstaff_fold.fmr = fmr
    endif

    var pp = ep[1] | ep[0] = cl + 1
    if cl <= ep[3] | return pp | endif # @skip

    var nl = nextnonblank(cl) # blank-row
    if nl > cl | ep[3] = nl - 1 | return pp | endif

    var mk = FoldCodeMark(cl, pp) # @markers
    if !Is(mk, pp) | return mk | endif

    var ni = max([0, FoldCodeIndentLevel(cl, 1)])
    if ni != ep[2] | ep[1 : 2] = [max([0, ep[1] + ni - ep[2]]), ni] | endif
    return (ep[1] > pp) ? '>' .. ep[1] : pp
  enddef # - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - }}}
  # - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -{{{
  def FoldText(qrg: list<any>): any # ([lnum]) = foldexpr-result
    var cl = get(qrg, 0, v:lnum)
    if (type(cl) != 0) || (cl == 0) | cl = v:lnum | endif

    # - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -{{{
    def FoldTextRestoreString(ln: number): string # (lnum) = 'character of row-state'
      var r = getline(ln)
      return (r =~ '\v^\s*[\<\>]?$') ? ' ' :
        (r =~ '\v^\s*([\=\#\/])\s*(\1\s*){7,}$') ? '=' :
        (r =~ '\v^\s*([-\+\*])\s*(\1\s*){7,}$') ? '-' :
        (r =~ '\v^\S?[^\t -/:-@[-`{-~]+') ? 'a' : 'b'
    enddef # - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - }}}

    var ep = get(b:foldstaff_fold, 'expr', [0])
    if (ep[0] != cl)
      ep = [cl, foldlevel(cl - 1) '']
      for i in range(cl - 1, cl + 1) | ep[2] ..= FoldTextRestoreString(i) | endfor
      b:foldstaff_fold.expr = ep
    endif
    ep[0] += 1 | ep[2] ..= FoldTextRestoreString(cl + 2) | var [p, s] = ep[1 : 2]

    s = Replace(s,
      ['\v [123a]\=', ' 1b'],
      ['\v [23a]\-', ' 2b'],
      ['\v([\~\-]\s?)\S', '\1b'],
      ['\v2.\-', '2bb'],
      ['\v  [3a]', 'b3b'],
    )
    ep[2] = s[1 :]

    p = (s =~ '\v^.[\=\-]') ? 0 :
      ((s =~ '\v^..[1-9\=\-]') && (p > 0)) ? '<1' :
      (s =~ '\v^.\d') ? '>' .. s[1] :
      (s =~ '\v^\=') ? '>1' :
      (s =~ '\v^\-') ? '>2' :
      (s =~ '\v^.\{') ? 'a1' :
      (s =~ '\v^.\}') ? 'a1' : p

    if (type(p) == 1) | ep[1] = ((p[0] == '<') ? str2nr(p[1]) - 1 : str2nr(p[1])) | endif
    return p
  enddef # - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - }}}
  # - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -{{{
  def FoldMatch(qrg: list<any>): any # ([lnum]) = foldexpr-result
    var cl = get(qrg, 0, v:lnum)
    if (type(cl) != 0) || (cl == 0) | cl = v:lnum | endif
    var pat = Get(foldstaff, &ft .. '.fold.match', Get(foldstaff, '_.fold.match', []))
    var pv: any # Don't just assume the type, and throw an error!! 'any'! 'any'!!
    if (len(pat) == 0)
      if !Is(Get(b:, 'foldstaff_fold.expr'), 'Q')
        echoh ToDo
        echom "foldstaff#fold(\"match\"): No have match pattern..."
        echoh NONE
      endif
      b:foldstaff_fold.expr = 'Q' | pv = -1
    else | pv = '=' | for p in pat
      var el = len(p) - 1 | var sl = cl - (el / 2) | var h = 0
      for i in range(el)
        if p[i + 1] == '' | continue | endif
        if (getline(sl + i) !~# p[i + 1]) | h += 1 | break | endif
      endfor
      ec el sl h
      if (h == 0) | pv = p[0] | break | endif
    endfor | endif
    return pv
  enddef # - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - }}}

  var type = get(b:foldstaff_fold, 'type', '')
  var at = get(arg, 0) | at = type(at) != 1 ? '' :
    at =~ '\v\c<a%[uto]>' ? 'auto' :
    at =~ '\v\c<c%[ode]>' ? 'code' :
    at =~ '\v\c<t%[ext]>' ? 'text' :
    at =~ '\v\c<m%[atch]>' ? 'match' : ''

  if ((at != '') || (type == '')) # set fold-type
    type = (at != '') ? at : Get(foldstaff, &ft .. '.fold.type', Get(foldstaff, '_.fold.type', 'auto'))
    if type == 'auto' | type = FoldCheck() | endif
    if exists('b:foldstaff_fold.switched')
      unlet! b:foldstaff_fold.switched
    endif
    if exists('b:foldstaff_fold.expr')
      unlet! b:foldstaff_fold.expr
    endif
    b:foldstaff_fold.type = type
    if at != '' | &l:fdm = 'expr' | &l:fde = 'foldstaff#fold()' | return 1 | endif
  endif

  if Is(get(b:foldstaff_fold, 'switched', -1), -1) # key-switch
    var a = Get(foldstaff, &ft .. '.fold.keyswitch', Get(foldstaff, '_.fold.keyswitch', 0))
    if (a < 0) | a = (type == 'text') ? 1 : 0 | endif
    b:foldstaff_fold.switched = KeySwitch(a)
  endif

  return (type == 'code') ? FoldCode(arg) :
    (type == 'text') ? FoldText(arg) :
    (type == 'match') ? FoldMatch(arg) : '-1'
enddef


# ========================================================================}}}1
if !exists('foldstaff._.') | foldstaff9#Option() | endif # plugin-initialize

&cpo = t_cpo # | unlet! t_cpo
# vim:set ft=vim fenc=utf-8 cms=#\ %s norl:                   Author: HongKong
