#!/bin/bash

###############################################################################
# Check for required functions file
###############################################################################

if [ -e twirl ]; then
	cd "$(dirname "${BASH_SOURCE[0]}")" \
		&& . "helpers"
else
	printf "\n ⚠️  ./helpers not found\n"
	exit 1
fi

###############################################################################
# CHECK: Bash version
###############################################################################

check_bash_version

###############################################################################
# CHECK: Internet
###############################################################################
echo "Checking internet connection…"
check_internet_connection


###############################################################################
# PROMPT: Password
###############################################################################
echo "Caching password…"
ask_for_sudo


###############################################################################
# INSTALL: Dependencies
###############################################################################
echo "Installing Dependencies…"


# -----------------------------------------------------------------------------
# Bash-it
# -----------------------------------------------------------------------------
if [ -d "$HOME/.bash_it" ]; then
	print_success_muted "Bash-it already installed. Skipping."
else
	step "Installing Bash-it…"
	git clone --depth=1 https://github.com/Bash-it/bash-it.git ~/.bash_it
	~/.bash_it/install.sh --silent --no-modify-config
	print_success "Bash-it installed!"
fi

# -----------------------------------------------------------------------------
# NVM
# -----------------------------------------------------------------------------
if [ -x nvm ]; then
	step "Installing NVM…"
	curl -o- https://raw.githubusercontent.com/creationix/nvm/v0.33.11/install.sh | bash
	print_success "NVM installed!"
	step "Installing latest Node…"
	nvm install node
	nvm use node
	nvm run node --version
	nodev=$(node -v)
	print_success "Using Node $nodev!"
else
	print_success_muted "NVM/Node already installed. Skipping."
fi


# -----------------------------------------------------------------------------
# Customizing Shell
# -----------------------------------------------------------------------------
echo 'Customizing Shell...'
echo 'Installing dependencies...'

# Install zsh
apt install zsh

# change default terminal
chsh -s /usr/bin/zsh root

# show current shell 
echo $SHELL

# install oh-my-zsh
sh -c "$(curl -fsSL https://raw.github.com/ohmyzsh/ohmyzsh/master/tools/install.sh)"

echo 'Configuring config files...'
# Copy custom settings

# config
cp ~/dotfiles/.zshrc ~/.zshrc

# custom theme
cp ~/dotfiles/zsh-shell/byurhanbeyzat.zsh-theme ~/oh-my-zsh/custom/themes/

# second theme
git clone https://github.com/bhilburn/powerlevel9k.git ~/.oh-my-zsh/custom/themes/powerlevel9k

# Install plugins
git clone https://github.com/zsh-users/zsh-autosuggestions ${ZSH_CUSTOM:-~/.oh-my-zsh/custom}/plugins/zsh-autosuggestions
git clone https://github.com/zsh-users/zsh-completions ${ZSH_CUSTOM:=~/.oh-my-zsh/custom}/plugins/zsh-completions
git clone https://github.com/zsh-users/zsh-history-substring-search ${ZSH_CUSTOM:-~/.oh-my-zsh/custom}/plugins/zsh-history-substring-search
git clone https://github.com/zsh-users/zsh-syntax-highlighting.git ${ZSH_CUSTOM:-~/.oh-my-zsh/custom}/plugins/zsh-syntax-highlighting

source ~/.zshrc

echo 'Ready to GO! 🚀'