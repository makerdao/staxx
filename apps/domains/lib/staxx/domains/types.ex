defmodule Staxx.Domains.Types do
  defmodule StackScope do
    # @type t :: "global" | "organization" | "user" | "sandbox"

    def global, do: "global"

    def organization, do: "organization"

    def user, do: "user"

    def sandbox, do: "sandbox"
  end
end
