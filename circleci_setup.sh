#!/usr/bin/env bash

[ ! -f "$HOME/.tool-versions" ] && touch $HOME/.tool-versions

# Check for asdf and install in case it doesn't exist
if ! asdf | grep version
  then
    git clone https://github.com/asdf-vm/asdf.git $HOME/.asdf
    echo -e '
      . $HOME/.asdf/asdf.sh' >> ~/.bashrc
    echo -e '
      . $HOME/.asdf/completions/asdf.bash' >> ~/.bashrc
fi

source ~/.bashrc

# Add Erlang and Elixir plugins
asdf plugin-add erlang https://github.com/asdf-vm/asdf-erlang.git
asdf plugin-add elixir https://github.com/asdf-vm/asdf-elixir.git

# Install plugins based on .tool-versions file
asdf install