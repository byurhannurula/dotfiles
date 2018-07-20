# Add Homebrew `/usr/local/bin` and User `~/bin` to the `$PATH`
PATH=$HOME/bin:$PATH
PATH=/usr/local/bin:$PATH
PATH=/usr/local/share/npm/bin:$PATH
export PATH

export MONGO_PATH=/usr/local/mongodb
export PATH=$PATH:$MONGO_PATH/bin

# Load the shell dotfiles, and then some:
# * ~/.path can be used to extend `$PATH`.
# * ~/.extra can be used for other settings you don’t want to commit.
for file in ~/.{path,bash_prompt,exports,aliases,functions,extra}; do
  [ -r "$file" ] && source "$file"
done
unset file

# Code launcher
code () { VSCODE_CWD="$PWD" open -n -b "com.microsoft.VSCode" --args $* ;}
