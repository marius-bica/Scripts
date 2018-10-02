#
# /etc/zshrc is sourced in interactive shells.
#
# $Id: zshrc 6 2005-08-18 22:40:48Z tavy $
#

# {{{ Initialization.

# Set term to 256 colors
TERM=xterm-256color

# Guess the zsh installation directory.
zsh_prefix=${${(M)module_path:#*/lib/zsh*/*}%/lib/zsh*/*}

# Set the function path.
fpath=( ~/.zsh/functions $fpath )

# Autoload zsh modules when they are referenced
zmodload -a zsh/stat stat
zmodload -a zsh/zpty zpty
zmodload -a zsh/zprof zprof
zmodload -ap zsh/mapfile mapfile

# Automatically remove duplicates from these arrays.
typeset -U cdpath fpath

# Autoload some functions
autoload -U colors nslookup zcalc zmv spectrum
autoload -Uz sticky-note

# Ensure ~/.zsh exists
[[ -d ~/.zsh ]] || mkdir -p ~/.zsh

# Running in mc?
[[ -n "$MC_CONTROL_FILE$MC_TMPDIR$MC_SID" || $(whence -s /proc/$PPID/exe) = */mc ]] && _running_mc=yes

# Source executable scripts in /etc/profile.d/*.sh
for i in /etc/profile.d/*.sh(-N.*); source $i

# }}}

# {{{ General shell options

setopt auto_cd \
       auto_continue \
       NO_beep \
       correct \
       extended_glob \
       NO_flow_control \
       NO_hup \
       magic_equal_subst \
       prompt_subst \
       NO_prompt_cr

# History.
setopt hist_find_no_dups \
       hist_save_no_dups \
       hist_ignore_dups \
       hist_ignore_space \
       extended_history \
       share_history
HISTFILE=~/.bash_history
HISTSIZE=2100
SAVEHIST=2000

# hack for running in mc
[[ -n $_running_mc ]] && setopt NO_correct hist_no_functions NO_zle

# }}}

# {{{ Functions

# csh compatibility
setenv() { export $1=$2 }

HELPDIR=$zsh_prefix/share/zsh/$ZSH_VERSION/help
#unalias run-help
autoload -U run-help

# }}}

# {{{ Variables

# PATH-like Variables.
typeset -U path manpath
typeset -xUT LD_LIBRARY_PATH ld_library_path

# Set $PATH, only existing directories.
paths=(/usr/local/{sbin,bin} /opt/*/bin(N) {/usr/{pkg/,X11R6/,},/}{sbin,bin} /usr/games $path)
path=( $HOME/bin ${^paths}(-N/) )
export PATH
unset paths

# Set $INFOPATH.
typeset -xUT INFOPATH infopath
infopath=( /usr{/local,/share,}/info(N) /usr{/local,}/share/xemacs*/*/info(N) $infopath )

# Remote host.
export REMOTEHOST="${SSH_CLIENT%% *}"

# Find mc.
for i in /usr/{local,pkg,}/{share,lib}/mc/bin/mc.sh(N); do
    source $i
    break
done

# Compatibility.
[[ -n $HOSTNAME ]] || export HOSTNAME=$HOST

# Set $EDITOR.
if [[ -z $EDITOR ]]; then
    if (( $+commands[editor] )) then
        EDITOR=editor
    elif (( $+commands[joe] )) then
        EDITOR=joe
    elif (( $+commands[mc] )) then
        EDITOR='mc -e'
    elif (( $+commands[vim] )) then
        EDITOR=vim
    fi
    export EDITOR
    export VISUAL=$EDITOR
fi

# Set $PAGER
if [[ -z $PAGER ]]; then
    if (( $+commands[pager] )) then
        PAGER=pager
    elif (( $+commands[less] )) then
        PAGER=less
    elif (( $+commands[more] )) then
        PAGER=more
    fi
    export PAGER
fi

export LESSOPEN="| /usr/share/source-highlight/src-hilite-lesspipe.sh %s"
export LESSCHARSET=utf-8
export LESS="-MM -F -i -Q -X -R"

if [[ -z $LS_COLORS ]]; then
    if (( $+commands[dircolors] )) then
        eval $(dircolors -b | sed 's/ex=01;32/ex=00;32/g')
    else
        LS_COLORS='no=00:fi=00:di=01;34:ln=01;36:pi=40;33:so=01;35:bd=40;33;01:cd=40;33;01:or=40;31;01:ex=01;32:*.tar=01;31:*.tgz=01;31:*.arj=01;31:*.taz=01;31:*.lzh=01;31:*.zip=01;31:*.z=01;31:*.Z=01;31:*.gz=01;31:*.deb=01;31:*.jpg=01;35:*.gif=01;35:*.bmp=01;35:*.ppm=01;35:*.tga=01;35:*.xbm=01;35:*.xpm=01;35:*.tif=01;35:*.mpg=01;37:*.avi=01;37:*.gl=01;37:*.dl=01;37:'
    fi
    export LS_COLORS
fi

# }}}

# {{{ Aliases

alias mv='nocorrect mv -i'
alias cp='nocorrect cp -i'
alias rm='nocorrect rm -i'
alias mkdir='nocorrect mkdir'
# alias ls='ls -alphF --color=auto'
alias ls='ls --color=auto'
alias lshtr='ls -lhtr'
alias d='ls'
# alias l='ls -lA'
alias lsd='ls -ld *(-/DN)'
alias s='cd ..'
alias p='cd -'
alias free='free -m'
alias gb=gulp build
alias pcp='rsync -ah --progress --no-perms --no-owner --no-group --no-times'

# General aliases.
# alias -g L="|less"
# alias -g H="|head"
# alias -g T="|tail"
# alias -g G="|grep"
# alias -g N="&>/dev/null&"
# alias -g O="2>&1"

# }}}

# {{{ Prompt

prompt_tavy_setup () {
    local c_user c_host c_pwd c_jobs c_err c_prompt
    local c_off c_host_off c_user_off c_prompt_off
    local ps
    integer sl=2

    if [[ -n $_running_mc ]]; then
        NUMCOLORS=2
    else
        NUMCOLORS=$termcap[Co]
    fi

    if [[ $NUMCOLORS -gt 2 ]]; then
        colors                  # get colors
        spectrum
        c_off="%{$reset_color%}"



#       if [[ -n $REMOTEHOST ]]; then
            c_host="%{$FX[bold]$FG[022]%}" c_host_off=$c_off
#       fi
#       if [[ $EUID = 0 ]]; then
            c_user="%{$FX[bold]$FG[160]%}" c_user_off=$c_off
            c_prompt="%{$fg[red]%}" c_prompt_off=$c_off
#       fi
        c_pwd="%{$FX[bold]$FG[069]%}"
        c_jobs="%{$fg_bold[yellow]%}"
        c_err="%{$bg_bold[red]%}"
    fi

    [[ $DISPLAY = :0* ]] && (( sl+=1 ))
    [[ -n $SUDO_UID ]] && (( sl+=1 ))
    [[ -n $_running_mc ]] && (( sl+=1 ))

    if [[ $TERM = (xterm|rxvt)* && -z $_running_mc ]]; then
        ps=$'%{\e[?9l'                  # disable mouse reporting
        ps=$ps$'\e]0;%n@%m:%~\a'        # window title
        ps="${ps}%}"
    fi

    #versioning branch info

    setopt prompt_subst
    autoload -Uz vcs_info
    zstyle ':vcs_info:*' actionformats \
        '%F{5}[%F{2}%b%F{3}|%F{1}%a%F{5}]%f '
    zstyle ':vcs_info:*' formats       \
        '%F{5}[%F{2}%b%F{5}]%f '
    zstyle ':vcs_info:(sv[nk]|bzr):*' branchformat '%b%F{1}:%F{3}%r'

    zstyle ':vcs_info:*' enable git cvs svn

    # or use pre_cmd, see man zshcontrib
    vcs_info_wrapper() {
        vcs_info
        if [ -n "$vcs_info_msg_0_" ]; then
            echo -n "%{$fg[grey]%}${vcs_info_msg_0_}%{$reset_color%}$del"
        fi
        if [ "$(git stash list 2>/dev/null)" != "" ]; then
            echo "%{$fg_bold[blue]%}⦿ %{$reset_color%}";
        fi
    }
    VERINFO=$'$(vcs_info_wrapper)'
    NEWLINE=$'\n'

    hostnamex=`hostname`
    ps="${ps}${c_user}%n${c_user_off}@"                                 # user@
    ps="${ps}${c_host}${hostnamex}${c_host_off}%B:%b"                             # host:
    ps="${ps}${c_pwd}%\$[COLUMNS/2]<...<%~%<<${c_off}"                  # pwd
#    ps="${ps}%(${sl}L. <sh%L>.)"                                        # sh#
    ps="${ps}%(1j. ${c_jobs}[%j]${c_off}.)%(?.. ${c_err}%?${c_off})"    # jobs, err
    PS1="${ps} ${VERINFO}${NEWLINE}%B%(!.#.$)%b${c_prompt_off} "                 # '$' or '#'

    if eval '[[ -o promptsp ]] 2>/dev/null'; then
        setopt prompt_cr prompt_sp
    else
        setopt NO_prompt_cr
        PS1=$'\r%}'$PS1
        if [[ $termcap[xn] = yes ]]; then
            PS1="${(l:$((COLUMNS-1)):::):-}$PS1"
        else
            PS1="${(l:$((COLUMNS-2)):::):-}$PS1"
        fi
        PS1="%B%S%{#%}%s%b%{$PS1"
    fi
}
zstyle :sticky-note theme bg white fg black

prompt_tavy_setup

# }}}

# {{{ Z Line Editor

if [[ -o zle ]]; then

    # {{{ Variables

    # Remove '/' from WORDCHARS
    WORDCHARS=${WORDCHARS:s./.}

    # }}}

    # {{{ Key bindings

    #bindkey -m
    bindkey "\e[2~" yank
    bindkey "\e[3~" delete-char
    bindkey "\e[5~" up-line-or-history
    bindkey "\e[6~" down-line-or-history
    bindkey "\e[1~" beginning-of-line
    bindkey "\e[4~" end-of-line
    bindkey "\e[7~" beginning-of-line
    bindkey "\e[8~" end-of-line
    bindkey "\eOH" beginning-of-line
    bindkey "\eOF" end-of-line
    bindkey "\e[H" beginning-of-line
    bindkey "\e[F" end-of-line
    bindkey '\e[A' history-beginning-search-backward
    bindkey '\e[B' history-beginning-search-forward

    bindkey -e                 # emacs key bindings
    bindkey ' ' magic-space    # also do history expansion on space
    bindkey '^I' complete-word # complete on tab, leave expansion to _expand
    bindkey "\e\e[D" backward-word
    bindkey "\e\e[C" forward-word

    # }}}

    # {{{ Completion

    _cache=~/.zsh/cache/$HOST-$OSTYPE
    [[ -d $_cache ]] || mkdir -p $_cache

    zmodload -i zsh/complist
    autoload -U compinit
    compinit -d $_cache/_compdump

    setopt complete_in_word

    # list of completers to use
    zstyle ':completion:*::::' completer _expand _complete _ignored _correct _approximate

    # allow one error for every three characters typed in approximate completer
    zstyle -e ':completion:*:approximate:*' max-errors \
        'reply=( $(( ($#PREFIX+$#SUFFIX)/3 )) numeric )'

    # insert all expansions for expand completer
    zstyle ':completion:*:expand:*' tag-order all-expansions

    # formatting and messages
    zstyle ':completion:*' verbose yes
    zstyle ':completion:*:descriptions' format '%B-- %d%b'
    zstyle ':completion:*:messages' format '%d'
    zstyle ':completion:*:corrections' format '%B%d (errors: %e)%b'
    #zstyle ':completion:*:warnings' format 'No matches for: %d'
    #zstyle ':completion:*' auto-description 'specify: %d'
    zstyle ':completion:*:default' list-packed yes
    zstyle ':completion:*:default' list-prompt ''
    zstyle ':completion:*' group-name ''

    # match uppercase from lowercase
    zstyle ':completion:*' matcher-list 'm:{a-z}={A-Z}'

    # offer indexes before parameters in subscripts
    zstyle ':completion:*:*:-subscript-:*' tag-order indexes parameters

    # Filename suffixes to ignore during completion (except after rm command)
    zstyle ':completion:*:*:(^rm):*:*files' ignored-patterns '*?\~'
    # Don't complete backup files as executables
    zstyle ':completion:*:complete:-command-::commands' ignored-patterns '*\~'

    # ignore completion functions (until the _ignored completer)
    zstyle ':completion:*:functions' ignored-patterns '_*'

    # Completion caching
    zstyle ':completion::complete:*' use-cache yes
    zstyle ':completion::complete:*' cache-path $_cache

    # OS-specific
    case $OSTYPE:$EUID in
        linux*:0)
            zstyle ':completion:*:processes' command ps -ax -o pid,tty,stat,bsdtime,cmd
            zstyle ':completion:*:processes-names' command ps -ax -ho cmd
            ;;
        linux*:*)
            zstyle ':completion:*:processes' command ps '-u$EUID' -o pid,tty,stat,bsdtime,cmd
            zstyle ':completion:*:processes-names' command ps '-u$EUID' ho cmd
            ;;
        (netbsd*|freebsd*|openbsd*):0)
            zstyle ':completion:*:processes' command ps -ax
            zstyle ':completion:*:processes-names' command ps -ax -c -o command
            ;;
        (netbsd*|freebsd*|openbsd*):*)
            zstyle ':completion:*:processes-names' command ps -c -o command
            ;;
        cygwin*)
            zstyle ':completion:*' preserve-prefix '(?:/|/d/?/|/cygdrive/?/)'
            zstyle ':completion:*:processes' command ps -as
            ;;
    esac

    # coloring
    zstyle ':completion:*:default' list-colors ${(s.:.)LS_COLORS}
    zstyle ':completion:*:processes' list-colors '=(#b) #([0-9]#)*=0=01;31'

    # URLs
    [[ -d ~/.zsh/urls ]] && zstyle ':completion:*:urls' urls ~/.zsh/urls
    #(( $+userdirs[apache] )) && zstyle ':completion:*:urls' local localhost ~apache/html public_html
    #(( $+userdirs[www-data] )) && zstyle ':completion:*:urls' local localhost ~www-data/html public_html

    unset _cache

    # }}}

fi

# }}}

# {{{ Terminal

# Sane terminal
stty sane

# Freeze the terminal settings.
ttyctl -f

# }}}

# {{{ Other

# Watch for login/logout.
if [[ -n $REMOTEHOST ]]; then
    watch=(notme)               # watch for everybody but me
    LOGCHECK=30                 # check for login/logout activity
fi

# Accept talk(1).
(( $+commands[mesg] )) && mesg y

# Mail
MAILCHECK=60
[[ -d ~/Maildir/new ]] && mailpath=( ~/Maildir )

# zftp
for i in ${^module_path}/zsh/zftp*(.N); do
    autoload -U zfinit
    zfinit
    break
done

# }}}

# {{{ OS-dependent initialization

# OS-dependent stuff.
case $OSTYPE in
    freebsd*)
        export CLICOLOR=1
        #export CDROM=/dev/acd0a
        eject () { umount /cdrom &>/dev/null; cdcontrol eject; }
        unalias ls
        alias ls='ls -F'
        ;;
    openbsd*)
        eject () { umount /cdrom &>/dev/null; cdio eject; }
        unalias ls
        alias ls='ls -F'
        ;;
esac

# }}}

# {{{ Final.

# Fixups for MC.
export COLORTERM=
if [[ -n "$_running_mc" ]]; then
    unalias ls
fi

# Clean up.
unset i sourced

# Source host-specific stuff
if [[ -f /etc/zshrc-$HOST ]]; then
    source /etc/zshrc-$HOST
fi

# }}}

# https://github.com/zsh-users/zsh-syntax-highlighting
source ~/.zsh/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh
ZSH_HIGHLIGHT_STYLES[globbing]='fg=yellow'
ZSH_HIGHLIGHT_STYLES[path]='bold'

