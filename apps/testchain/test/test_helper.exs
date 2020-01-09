ExUnit.start()
Faker.start()
{:ok, _pid} = Staxx.Testchain.Test.EventSubscriber.start_link()
