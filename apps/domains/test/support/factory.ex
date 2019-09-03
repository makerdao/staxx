defmodule Staxx.Domains.Factory do
  # without Ecto
  use ExMachina

  def user_factory do
    %{
      name: Faker.Name.name(),
      email: sequence(:email, &"#{&1}#{Faker.Internet.email()}"),
      active: true,
      admin: false,
      preferences: %{}
    }
  end
end
