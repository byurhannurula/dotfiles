#!/usr/bin/env bash

check_bash_version() {
  if ((BASH_VERSINFO[0] < 3)); then
    print_error "Sorry, you need at least bash-3.0 to run this script."
    exit 1
  fi
}

check_internet_connection() {
  if [ ping -q -w1 -c1 google.com ] &>/dev/null; then
    print_error "Please check your internet connection"
    exit 0
  else
    print_success "Internet connection"
  fi
}

ask_for_sudo() {
  # Ask for the administrator password upfront.

  sudo -v &>/dev/null

  # Update existing `sudo` time stamp
  # until this script has finished.
  #
  # https://gist.github.com/cowboy/3118588

  # Keep-alive: update existing `sudo` time stamp until script has finished
  while true; do
    sudo -n true
    sleep 60
    kill -0 "$$" || exit
  done 2>/dev/null &

  print_success "Password cached"
}