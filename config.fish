### Export
set fish_greeting # Supresses fish's intro message
set EDITOR "vim" #set Editor to vim
set VISUAL "vim"
set HISTCONTROL "ignoreboth" #remove duplicate commands in history

function ex
     if [ -f $argv ]
         switch $argv[1]
            case "*.tar.bz2"
                tar xjf $argv[1];;
             case "*.tar.gz"    
                tar xzf $argv[1];;
             case "*.bz2"      
                bunzip2 $argv[1];;
             case "*.rar"       
                rar x $argv[1];;
            case "*.rar"       
                rar x $argv[1];;
            case "*.gz"       
                gunzip $argv[1];;
            case "*.tar"       
                tar xf $argv[1];;
            case "*.tar"
                tar xjf $argv[1];;
            case "*.tbz2"
                tar xzf $argv[1];;
            case "*.zip"
                 unzip $argv[1];;
            case "*.Z"
                  uncompress $argv[1];;
            case "*.zip"
                 unzip $argv[1];;
            case "*.7z"
                 7z x $argv[1];;
            case "*"
             echo "'$argv[1]' cannot be extracted via ex()" ;;  
        
         end
     else
         echo "'$1' is not a valid file"
    end
end


# navigation function to go n directories up
function up
  	set -l d ""
  	set -l limit $argv[1]
    echo $limit
 	 # Default to limit of 1
  	if [ -z "$limit" ] || [ "$limit" -le 0 ]
    		set  limit 1
	end

  	for i in (seq 0 $limit)
    		set d  "../$d"
  	end

    echo $d

  	# perform cd. Show error if cd fails
  	if ! cd "$d"
    		echo "Couldn't go up $limit dirs.";
  	end
end

### ALIASES ###

# Changing "ls" to "exa"
alias ls='exa -al  --color=always --group-directories-first' # my preferred listing
alias la='exa -a --color=always --group-directories-first'  # all files and dirs
alias ll='exa -l --color=always --group-directories-first'  # long format
alias lt='exa -aT --color=always --group-directories-first' # tree listing
alias l.='exa -a | egrep "^\."'

# pacman and yay
alias pacsyu='sudo pacman -Syu'                  # update only standard pkgs
alias pacsyyu='sudo pacman -Syyu'                # Refresh pkglist & update standard pkgs
alias yaysua='yay -Sua --noconfirm'              # update only AUR pkgs (yay)
alias yaysyu='yay -Syu --noconfirm'              # update standard pkgs and AUR pkgs (yay)
alias unlock='sudo rm /var/lib/pacman/db.lck'    # remove pacman lock
alias cleanup='sudo pacman -Rns $(pacman -Qtdq)' # remove orphaned packages


# confirm before overwriting something
alias cp="cp -i"
alias mv='mv -i'
alias rm='rm -i'


# Colorize grep output (good for log files)
alias grep='grep --color=auto'

# git
alias addup='git add -u'
alias addall='git add .'
alias branch='git branch'
alias checkout='git checkout'
alias clone='git clone'
alias commit='git commit -m'
alias fetch='git fetch'
alias pull='git pull origin'
alias push='git push origin'
alias stat='git status'  # 'status' is protected name so using 'stat' instead
alias tag='git tag'
alias newtag='git tag -a'

# get error messages from journalctl
alias jctl="journalctl -p 3 -xb"

neofetch
starship init fish | source


