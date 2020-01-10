ExUnit.after_suite(fn _ ->
  Application.put_env(:docker, :adapter, Staxx.Docker.Adapter.Mock)
end)

ExUnit.start()
Faker.start()
{:ok, _pid} = Staxx.Testchain.Test.EventSubscriber.start_link()
