#!/usr/bin/env bash

[ ! -f ".tool-versions" ] && echo "file .tool-versions was not found" &&
        exit 1

# Check for asdf and install in case it doesn't exist
if ! asdf | grep version
  then
    git clone https://github.com/asdf-vm/asdf.git $HOME/.asdf
    echo -e '\n. $HOME/.asdf/asdf.sh' >> ~/.bashrc
    echo -e '\n. $HOME/.asdf/completions/asdf.bash' >> ~/.bashrc

    echo 'source ~/.asdf-vm/asdf.sh' >> $BASH_ENV
    source $BASH_ENV
fi

# Add Erlang and Elixir plugins
asdf plugin-add erlang https://github.com/asdf-vm/asdf-erlang.git
asdf plugin-add elixir https://github.com/asdf-vm/asdf-elixir.git

# Install plugins based on .tool-versions file
asdf install