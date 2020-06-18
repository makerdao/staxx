defmodule Staxx.SnapshotRegistry.JwtAuthToken do
  use Joken.Config

  def encode(metadata) do
    generate_and_sign!(%{meta: metadata})
  end

  def decode(token) do
    verify_and_validate(token)
  end
end
