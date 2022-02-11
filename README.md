# [<img src="https://user-images.githubusercontent.com/97036597/152203062-8592a88b-9d65-4a02-b283-a9e08fc86026.svg"  style="height:1em;" alt="papier-mache logo" />foldstaff-vim]()

<!-- It is indeed impossible to embed a plain SVG. If I could, I'd be able to do animations and stuff... -->
<!-- Style is also useful for IMG.  can I use SVG without worry? -->

[![REQUIRE: Vim 8.2-later?](https://img.shields.io/static/v1?label=plugin&message=8.2%2B&color=2a2&logo=vim)](https://www.vim.org "REQUIRE: Vim 8.2 later")&nbsp;
[![MIT License](https://img.shields.io/static/v1?label=license&message=MIT&color=28c)](LICENSE "MIT License")&nbsp;
[![plugin version 1.02](https://img.shields.io/static/v1?label=version&message=1.02&color=e62)](https://github.com/hongkong3/foldstaff-vim/ "plugin version 1.02")&nbsp;
🍔🍙

> *This document has been prepared baded on automatic translation.  
> Please forgive me if there are some strange sentences...*  

<br>

This plugin is utilities for *Folding* at **Vim editor**.   
The settings for each utility, can be switched for each `filetype`.  


### [foldstaff-vim][ghp] provides the bellow utilities:  

* [**foldstaff-header**](#user-content-foldstaff-header)  
  For *foldtext*.  Generates the display Text of closed Folding.  
  You can freely edit the content to be displayed using *formatting-text* as like the `statusline`.  
  And you can set the *formatting-text* for each `filetype` and each `foldlevel`.  
  You can also specify the length of the display Text.  

* [**foldstaff-marker**](#user-content-foldstaff-marker)  
  Set the `fold-marker`, with right-side aligned.  
  That is almot all there is to it.   

* [**foldstaff-fold**](#user-content-foldstaff-fold)  
  Folding method for *foldexpr*, when the `fold-expr`.  
  This has some folding types:<br>
  - *type = "code"*  
    This is for Code or Script buffer.  
    This is similar to `fold-indent`, but folding into the previous paret level line. ~~(like as VS-Code)~~  
    And, `fold-marker`, etc. can also uses.  
  - *type = "text"*  
    This is mainly for *Vim-help*.  
    Folding buffer individually, after separating them with horizontal line and blank line.  
    The result looks like **an outline** or **table of contents**.  
  - *type = "match"*  
    Judges and folds each line using a pre-defined matching-patterns.

* [**foldstaff-option**](#user-content-foldstaff-option)  
  This is a function for **option setting**, for above utilities.  
  Although it is possible to set global-variable`g:` as in general plugins, this function allows you to check and reflect the values immediately.  

<br />

----
## Screenshot

> Default:  
![c1](https://user-images.githubusercontent.com/97036597/152065346-2364bbca-4cee-4a76-8ce9-82b7e626c715.png)

> Modify:  
![c2](https://user-images.githubusercontent.com/97036597/152065366-4261e10e-9764-4d05-8713-5182a1a20ce9.png)

> Funcky:  
![c3](https://user-images.githubusercontent.com/97036597/152065375-d1651cf1-7c46-4f8b-8bb6-6a091001c038.png)

> Vim-Help at **foldstaff-fold** *type="text"*:  
![t1](https://user-images.githubusercontent.com/97036597/152065191-7ceb2a59-72b7-44f2-b51f-a3e244699f2f.png)

----
## Installation
Install using your favorite package manager.

- [**Vundle:**](https://github.com/VundleVim/Vundle.vime)  
  ```vim
  Plugin 'hongkong3/foldstaff-vim'
  ```
- [**NeoBundle:**](https://github.com/Shougo/neobundle.vim)  
  ```vim
  NeoBundle 'hongkong3/foldstaff-vim'
  ```
- [**VimPlug:**](https://github.com/junegunn/vim-plug)  
  ```vim
  Plug 'hongkong3/foldstaff-vim'
  ```
- [**Pathgon:**](https://github.com/tpope/vim-pathogen)  
  ```shell
  cd ~/.view/bundle
  git clone https://github.com/hongkong3/foldstaff-vim
  ```

----

## Usage
For more information on how to use it, please see the help in Vim.  
`:h foldstaff`  
  
### Quick start:
Place this in your *.vimrc*: 
```vim
let g:enable_foldstaff = 1
```
This will allow you to use all the utilities.  
(also, add *foldstaff["help"]* settings)  

<br />

The following is an introduction of how to use and set up each of them individually.  

<br />

### [Vim9-version]
If you write the following in **vimrc**, it will run in the *Vim9-script* version.  
```vim
let g:foldstaff_enable_vim9 = 1
```

<br />

**Note:** *Some functions may not work due to changes in **Vim9-script** specifications.*  
*(Confirmed to work: gVim 8.2.4324)*


- - - - - - - - - - - - - - - - - - - - - - - -

### foldstaff-header:

**Setup:**
```vim
:set foldtext=foldstaff#header()
```

This is used as a callback function for *foldtext* from **Vim**.  
In usage, it is more important to edit the *formatting-text*.  

<details><summary><strong>caution: not realtime update</strong></summary>

When changes to the base-text, will not realtime reflected in the folded-text.  
It will be updated by...  
* number of buffer-lines changed  
* window resized (window-columns changed)  
* execute `:FoldstaffOption` on current buffer  

</details>

<br />

The text on the line with first non-symbolic character from *foldstart*, will be used as the **base-text**.  
(This means, that lines with only symbols as separators will be ignored)  

<details><summary><strong>about: base-text</strong></summary>

As an example, here is the case of folding with <em>fold-marker</em>.

* *before fold*  
  ```py
    # define _______________________________________________{{{2  #A
    X_RANGE = 10 #(+-)x_range.

    # ______________________________________________________{{{2  #B
    rgb_val = []
    data_range = np.linspace(-(X_RANGE),X_RANGE,(X_RANGE*4)+1)
  ```
* *after folded*  
  ```py
    # define _____________________________________________~+[ 3]  #A
    rgb_val = []                                           +[ 6]  #B
  ```
In the case of **#A** the text of the foldstart line will be used as is.  
In case **#B**, foldstart line is only a symbol and a marker, so it is ignored and the text of the next line is used.  

<br />

By the way, there is no need to place the marker on a separate line to avoid displaying symbols like **#B**.  
* Removing symbols uses `:FoldstaffOption python.modify`, etc.  
* Use other folding methods  


etc.  Please use the way that best suits your writing style.

</details>

<br />


### foldstaff-header-format
The *formatting-text* is used for generated the *folded-text*.  
You can set for each `filetype` and each `foldlevel`.  

Specify the *formatting-text* for each `foldlevel` as a string in a LIST variable.  
If the number of *formatting-text* is less than the `foldlevel`, the last item will be used.  
```vim
" I'm leaving a lot out.
header.format = [
  '# %t %<=%> %p%%(%l)',                    " #Lv1
  '## %t %<-%> %p%%(%l)',                   " #Lv2
  '%{repeat("#", %v)%} %t %<.%>%p%%(%l)',   " #Lv3, ...
]
```

Even if there is only one *formatting-text*, as in the default, the `foldlevel` can be represented by including an expression.  
```vim
header.format = ['%i%t %<%>%{repeat("+", %v)%}[%L]']
```

<br />

Items that can be used within the *formatting-text* include the following:  

| item | contents |
| :-: | --- |
| `%%` | a single percent sign `%` |
| `%t` | **base-text**<br />It will also be modified by `header.modify` |
|`%<` ... `%>`| fill the margin by repeat string, from between this|
|`%{` ... `%}`| evalute expression between this, and replace to result|
| `%s` , `%S` | line number of *foldstart*, and with padding |
| `%e` , `%E` | line number of *foldend*, and with padding |
| `%l` , `%L` | number of line in folded, and with padding |
| `%p` <br/> `%P`|percentage of foldstart line in buffer [0 .. 100]<br />percentage of foldstart line in buffer ["&nbsp;&nbsp;0.0" .. "100.0"]|
| `%v` | current closed foldlevel (start 1) |
| `%V` | max foldlevel |
| `%i` | indent of foldstart line [space] |
| `%I` | indent-level (indent() / shiftwidth()) |
| `%T` | line number where the **base-text** |
| `%d` | *folddashes* ["-"] |
| `%D` | `&diff` [0 / 1] |

You can also call user-functions as evaluation expressions, so I think you can do most things.

<br />

- - - - - - - - - - - - - - - - - - - - - - - -

### foldstaff-marker:
This is set the *fold-marker*. This function is designed to be used setting to *key-mapping*.

**Setup:**
```vim
:map zf <Plug>(foldstaff-marker)
:map zF <Plug>(foldstaff-endmarker)
```
`zf` and `zF` are just examples.  Feel free to set the actual **keys** as you wish.  
Two *key-mappings* are provided, for the `{{{`**start-marker**  and  `}}}`**end-marker**.  

<br />

At runtime, it works as follows:  
- When executed in Normal-Mode, *fold-marker* will be placed by the behind of cursor line.  
  - if *fold-marker* already been placed, then remove it.  
```vim
  " - - - - - - - - - - - - - - - - - - - - - - - - - - -{{{
```

- When executed with <em title="for example, an input like &#34;1zf&#34; or &#34;2zF&#34;.">&lt;count&gt;</em>[^fmr], place *fold-marker* for it **foldlevel**.
  - if *fold-marker* already been placed, then replace marker of new **foldlevel**. 
```vim
  " ===================================================={{{2
```

- When execute in Visual-Mode(multiline selected), will be placed **start-marker** on first-line, and **end-marker** on last-line.  
```vim
  for i in range(10) " - - - - - - - - - - - - - - - - - {{{
    echo i
  endfor " - - - - - - - - - - - - - - - - - - - - - - - }}}
```

<br />

Also, you can possible to set the character of fill at margin, for each **foldlevel**.  
There is unlimit characters, so you can do something like this.  
```vim
  " ( T T)/(^ ^ )`( - -)c(>_< )9_( T T)/(^ ^ )`( - -)c(>_{{{
```

[^fmr]: for example, an input like "1zf" or "2zF".

- - - - - - - - - - - - - - - - - - - - - - - -

### foldstaff-fold:
This function is for *foldexpr*.   
This function performs folding according to the contents of the buffers.  

<br />

**Setup:**  
```vim
:set foldmethod=expr foldexpr=foldstaff#fold()
```

This completes the configuration, but the settings will often be overwritten...  
It may be more constructive to execute the following **Ex-Command** as needed.  

<br />

**Command:**  
```vim
:FoldstaffFold
:FoldstaffFold {type}
```

{type} cna be **code**, **text**, **match**, or **auto**.  
If {type} is omitted, then **auto** will be used.  
When **auto** is used, it will switch to **code** or **text** depending on the buffer contents.  

If **match** is specified, it cannot be executed unless `:FoldstaffOption fold.match = [...]` is set beforehand.  

- - - - - - - - - - - - - - - - - - - - - - - -

### foldstaff-option:
This is a dedicated function for setting options for this plugin.  
A function version is also available, but I think it is easier to use the command.  

<br />

**Command:**  
```vim
:FoldstaffOption
:FoldstaffOption {filetype}.{method}.{key} = {value}
:FoldstaffOption {filetype}.{method}.{key}[index] = {value}
```
When executed with no argument, if `g:foldstaff` exists, it will read the setting.  

If arguments are specified, it will change the setting to that value.  
The only part of the argument that is required is the `{key} = {value}` part.  
Arguments *{filetype}* and *{method}* can be omitted.  

For the about to be specified for *{filetype}*, *{method}* and *{key}*, please check [**Option**](#user-content-option) described below.  

<br />

After execution, it will display the changed *option-vriable*, and update [foldstaff-header](#user-content-foldstaff-header) and [foldstaff-fold](#user-content-foldstaff-fold).  
It also acquires the changed *option-variable* in register `h` as a string. (type `"hp` to paste it)  

- - - - - - - - - - - - - - - - - - - - - - - -

## Option  
The option values in this plugin are managed by a DICT variable.  
The contents of this variable are as follows:  
```vim
    " #line-continuation '\' omitted.
    [g:]foldstaff = {
        "_" = #{                            " filetype [basic]
            header = #{                     " @ foldstaff-header
                format = [                  "   formatting text(s)
                    '%i%t %<%>%{repeat("[", %v)%}%L]',
                ],
                width = '+0',               "   max-length of folded text
                min = 8,                    "   min-length of base-text
                ellipsis = '~',             "   symbols when base-text omitted
                modify = [],                "   substitution-list to base-text
            },
            marker = #{                     " @ foldstaff-marker
                fill = [                    "   padding strings list
                    '- ',                   "     for non-level
                    '=', '_', '.',          "     for each foldlevel
                ],
                width = 0,                  "   length of fold marker
            },
            fold = #{                       " @ foldstaff-fold
                type = 'auto',              "   fold-type: [code/text/match/auto]
                keyswitch = -1,             "   za zo zc key-maps switch flag
                match = [],                 "   for fold-type:'match' (default is empty)
            },
        },
    " # The same settings as above can be added for each filetypes.
        "vim" = {
            ...
        },
        "help" = {
            ...
        }, ...
    }
```

<br />

See `:h foldstaff-option-detail` for details of each setting value.  

----

*This "foldstaff" is no relationship with any real person, organization, or name.*  


[ghp]: https://github.com/hongkong3/foldstaff-vim/
