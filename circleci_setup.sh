#!/usr/bin/env bash

[ ! -f ".tool-versions" ] && touch .tool-versions

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

echo "Installing erlang asdf plugin"
if [ $(asdf plugin-list | grep -c "erlang") -eq 0 ];
  then
    asdf plugin-add erlang
    asdf install erlang 22.1
fi

echo "Installing elixir asdf plugin"
if [ $(asdf plugin-list | grep -c "elixir") -eq 0 ];
  then
    asdf plugin-add elixir
    asdf install elixir 1.9.3
fi

# Install plugins based on .tool-versions file
asdf install