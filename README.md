# foldstaff-vim

[![REQUIRE: Vim 8.2-later?](https://img.shields.io/static/v1?label=plugin&message=8.2%2B&color=2a2&logo=vim)](https://www.vim.org "REQUIRE: Vim 8.2 later")&nbsp;
[![MIT License](https://img.shields.io/static/v1?label=license&message=MIT&color=28c)](LICENSE "MIT License")&nbsp;
 [![plugin version 0.82](https://img.shields.io/static/v1?label=version&message=0.82&color=e62)](https://github.com/hongkong3/foldstaff-vim/ "plugin version 0.82")&nbsp;

> *This document has been prepared baded on automatic translation.  Please forgive me if there are some strange sentences...*  

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
    And, `fold-marker`,etc. can also uses.  
  - *type = "text"*  
    This is mainly for *Vim-help*.  
    Folding buffer individually, after separating them with horizontal line and blank line.  
    The result looks like **an outline** or **table of contents**.  
  - *type = "match"*  
    Judges and folds each line using a pre-defined matching-patterns.
    
* [**foldstaff-option**](#user-content-foldstaff-option)  
  This is a function for **option setting**, for above utilities.  
  Although it is possible to set global-variable`g:` as in general plugins, this function allows you to check and reflect the values immediately.  

----
## Screenshot

> Default:  
![c1](https://user-images.githubusercontent.com/97036597/152065346-2364bbca-4cee-4a76-8ce9-82b7e626c715.png)

> Custom & Modify:  
![c2](https://user-images.githubusercontent.com/97036597/152065366-4261e10e-9764-4d05-8713-5182a1a20ce9.png)
  
> Funcky:  
![c3](https://user-images.githubusercontent.com/97036597/152065375-d1651cf1-7c46-4f8b-8bb6-6a091001c038.png)

> Vim-Help at **foldstaff-fold** *type="text"*:  
![t1](https://user-images.githubusercontent.com/97036597/152065191-7ceb2a59-72b7-44f2-b51f-a3e244699f2f.png)

----
## Installation
Install using your favorite package managers.

[**Vundle:**](https://github.com/VundleVim/Vundle.vime)
```vim
Plugin 'hongkong3/foldstaff-vim'
```
[**NeoBundle:**](https://github.com/Shougo/neobundle.vim)
```vim
NeoBundle 'hongkong3/foldstaff-vim'
```
[**VimPlug:**](https://github.com/junegunn/vim-plug)
```vim
Plug 'hongkong3/foldstaff-vim'
```
[**Pathgon:**](https://github.com/tpope/vim-pathogen)
```terminal
cd ~/.vim/bundle
git clone https://github.com/hongkong3/foldstaff-vim
```

----
## Usage
For more information on how to use it, please see the help in Vim.  
`:h foldstaff`  
  
### Quick start:
Place this in your *.vimrc*.
```vim
let g:enable_foldstaff = 1
```

<br />

### foldstaff-header
It is used as a callback function for `foldtext` from Vim.  



----
## Option

*...Right now I'm still writing.*

----

*This is no relationship with any real person, organization, or name.*


[ghp]: https://github.com/hongkong3/foldstaff-vim/
