# color vars
eval yellow='$FG[003]'
eval white='$FG[250]'
eval gray='$FG[238]'
eval blue='$FG[032]'
eval red='$FG[001]'

# primary prompt
PROMPT='${blue}%n@%m:%~$(git_prompt_info) %{$reset_color%}$ '

# git settings
ZSH_THEME_GIT_PROMPT_PREFIX=" ${white}on ${gray}git:"
ZSH_THEME_GIT_PROMPT_CLEAN=""
ZSH_THEME_GIT_PROMPT_DIRTY=" ${red}*%{$reset_color%}"
ZSH_THEME_GIT_PROMPT_SUFFIX="${gray}%{$reset_color%}"
