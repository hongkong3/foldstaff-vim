vim9script
# ========================================================================{{{1
# Plugin:     foldstaff-vim
# LasCahnge:  2022/01/28  v0.5
# License:    MIT license
# Filenames:  %/../../plugin/foldstaff.vim
#             foldstaff.vim
#             foldstaff9.vim
# ========================================================================}}}1

const s:t_cpo = &cpo | set cpo&vim
const s:n = expand("%:t:r")

# OPTIONS: ==============================================================={{{1
# final s:foldstaff_default = {}

# s:foldstaff_default.header = {}
# s:foldstaff_default.header.format = ['%i%t %<%>%{repeat("[", %v)%}%L]']
# s:foldstaff_default.header.width = '+0'
# s:foldstaff_default.header.modify = []
# s:foldstaff_default.header.min = 8
# s:foldstaff_default.header.ellipsis = '~'

# s:foldstaff_default.marker = {}
# s:foldstaff_default.marker.fill = ['- ', '=', '-', '= ', '- ', '. ']
# s:foldstaff_default.marker.width = 0

# s:foldstaff_default.fold = {}
# s:foldstaff_default.fold.type = 'auto'
# s:foldstaff_default.fold.match = []
# s:foldstaff_default.fold.keyswitch = -1
const s:foldstaff_default = {
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
    },
    fold: {
      type: 'auto',
      keyswitch: -1,
      match: [],
    },
  }

# running variables: -----------------------------------------------------{{{2
# b:foldstaff_header = {
#   width:  {current-width},      # FLG1
#   line:   {max-line},           # FLG2
#   text:   {                     # reserve header-texts
#     'start:lv': 'text',
#      ...... ,
#   },
#   pat:    {sub-pattern},
# }
#
# b:foldstaff_fold = {
#   type:   {fold-type},          # type checked
#   expr:   {params},
#   switched: 0 / 1,              # FLG key-switch
#     fmr:    {pat},               # pattern of fold-marker @CODE
# }
# ========================================================================}}}1

const s:SMB = '\t -@\[-`{-~' # symbol-pattern @\v

# MODULE: ================================================================{{{1
  # ----------------------------------------------------------------------{{{2
  def s:is(a: any = 0, b: any = 0): bool
    return (type(a) == type(b)) && (a == b)
  enddef

  # ----------------------------------------------------------------------{{{2
  def s:esc(s: string, f: number = 0): string # f[0:pat 1:sub]
    # return escape(s, '$%&()=^~\|@[{+*]}<>?')
    return escape(s, (f != 0 ? '$%&()^|\|@[{+*]}<>?' : '$%&()-=^~\|@[{+*]}<.>?'))
  enddef

  # ----------------------------------------------------------------------{{{2
  def s:is_cmt(l: number = line('.')): bool
    return hlID('Comment') == synIDtrans(synID(l, indent(l) + 1, 1))    
  enddef

  # ----------------------------------------------------------------------{{{2
  def s:winwidth(cid: number = 0): number # visible-cols
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


# MAIN: =================================================================={{{1


# ========================================================================}}}1
  def g:Test9()
    var l:t = copy(s:foldstaff_default)
    FL l:t
  enddef

&cpo = s:t_cpo # | unlet! s:t_cpo
# vim:set ft=vim fenc=utf-8 cms=#\ %s norl:                   Author: HongKong
