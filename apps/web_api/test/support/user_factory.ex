defmodule Staxx.WebApiWeb.UserFactory do
  use ExMachina

  def user_factory do
    %{
      "email" => Faker.Internet.email(),
      "name" => Faker.Person.name()
    }
  end
end
