defmodule Staxx.DeploymentScope.UserScopeTest do
  use ExUnit.Case

  alias Staxx.DeploymentScope.UserScope

  test "do map with email" do
    email = Faker.Internet.email()
    id = Faker.String.base64()
    id2 = Faker.String.base64()

    assert [] = UserScope.list_by_email(email)

    :ok = UserScope.map(id, email)
    assert [^id] = UserScope.list_by_email(email)

    # ignore duplicates
    :ok = UserScope.map(id, email)
    assert [^id] = UserScope.list_by_email(email)

    :ok = UserScope.unmap(id, email)
    assert [] = UserScope.list_by_email(email)

    # Ignore absence
    :ok = UserScope.unmap(id, email)
    assert [] = UserScope.list_by_email(email)

    :ok = UserScope.map(id, email)
    assert [^id] = UserScope.list_by_email(email)

    :ok = UserScope.unmap(id, email)
    assert [] = UserScope.list_by_email(email)

    :ok = UserScope.map(id, email)
    assert [^id] = UserScope.list_by_email(email)
    :ok = UserScope.map(id2, email)
    assert [^id, ^id2] = UserScope.list_by_email(email)
  end
end
