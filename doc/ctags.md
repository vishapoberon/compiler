## Code navigation with ctags

[`ctags`](https://github.com/universal-ctags/ctags) is a tool that creates an index file for names (symbols) in various programming langauges, which helps code comprehension by giving information to text editors to search, locate, and interactively suggest names. Particularly for Oberon, the `oberon.ctags` file, located in the project root, contains definitions for Oberon modules and procedures (but not receiver procedures). 

Below you can find installation instructions and usage examples for `ctags`, in particular, using the universal tags implementation (not tested with other implementations), with `vim` (you can find or add guides for your text editor), with examples that deal with Oberon source code. 

## Install universal tags

#### Use your package manager

`pacman -S ctags` (arch linux)  
`apt install universal-ctags` (debian, ubuntu)  
`brew install universal-ctags` (macOS)  
...

#### Compile from source 

`git clone https://github.com/universal-ctags/ctags.git`  
follow [build instructions](https://github.com/universal-ctags/ctags/blob/master/README.md#how-to-build-and-install)  

## Using ctags with vim and Oberon

the following instructions are for POSIX systems, but can be easily adapted to other systems

#### Configuration

First, generate tags in project root  
`make tags`

When you add or change names in source files, you have to regenerate the `tags` file. That can be done by running `make tags` again. Optionally, use a `vim` plugin such as [vim-gutentags](https://github.com/ludovicchabant/vim-gutentags) to automate this process. Install it (or skip this step):

`git clone https://github.com/ludovicchabant/vim-gutentags ~/.vim/plugin/`  

or wherever your vim global plugin directory is specified in `:h plugin`. 

Add this to your `~/.vimrc`
```
" search upwards for tags file until home directory
set tags=./tags;~
" qualified name metadata for plugin
let g:gutentags_ctags_extra_args = ['--extras=+q']
```

To use `oberon.ctags` with a plugin or for Oberon language detection outside its directory:   
`cp oberon.ctags ~/.config/ctags/`  
or  
`cp oberon.ctags $XDG_CONFIG_HOME/ctags/`  

#### Usage examples

tags documentation is in vim
`:h tags`

some examples:
```
vim -t "Compiler"
vim -t "OPS.Get"
vim -c ":ts Platform.Read"
vim -c ":ta BrowserCmd.ShowDef"
```

Inside vim when you have cursor on the first letter `M` of `Module.Procedure`, do this to jump to procedure definition:  
`v 3e <C-]>`    *(visually select the fully qualified name)*  
module definition:  
`<C-]>`  
To come back:  
`<C-o>`

Putting cursor on `P` of `Module.Procedure` is not guaranteed to resolve correctly to the correct module, so choose the fully qualified name. This is a [known limitation](https://docs.ctags.io/en/latest/man/ctags-faq.7.html#how-do-i-jump-to-the-tag-i-want-instead-of-the-wrong-one-by-the-same-name) of `ctags` (any suggestions for handling this better are welcome).

To address this, you can visually select as in the above examples, or resolve ambiguities interactively:  
`g <C-]>`  
`:ts Write`  
`:ts Platform.Write`  
or make vim see the qualified name as a complete keyword:  
`iskeyword+=.`  
in `.vimrc`  
`autocmd FileType oberon,modula2 setlocal iskeyword+=.`  

**TODO**  
There is some auto-completion, but it doesn't work well. One idea is to define a custom `omnifunc` that suggests only exported symbols (`*`) from a file (module scope is file), so that when you type `OPS.` and press `<C-P>` you can have useful suggestions (similar to `showdef`).

