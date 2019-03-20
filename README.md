# TestchainBackend

## Docker compose

1. Build all images in all repo
2. Use `make dc-up` for run
3. Use `make dc-down` for down with removing of data

Instead of 2 and 3 u can use `docker-compose` cmd in console.

## Deployment service

```elixir
iex(6)> Proxy.Deployment.BaseApi.request("test", "get_info")
{:error,
 %{
   "code" => "notFound",
   "detail" => "Unknown method: get_info",
   "errorList" => []
 }}
iex(7)> Proxy.Deployment.BaseApi.request("test", "GetInfo")
{:ok,
 %{
   "result" => %{
     "steps" => [
       %{
         "defaults" => %{"osmDelay" => "1"},
         "description" => "Step 7 - MS 3 - Crash & Bite",
         "id" => 1,
         "oracles" => [
           %{"contract" => "MEDIANIZER_ETH", "symbol" => "ETH"},
           %{"contract" => "MEDIANIZER_REP", "symbol" => "REP"}
         ],
         "roles" => ["CREATOR", "CDP_OWNER"]
       }
     ],
     "tagHash" => "f1e23cd2aecb42ddb74f29eb7db576f21b1911d9"
   },
   "type" => "ok"
 }}
```

## Local docker-compose env

To start everything in docker on your local machine there is set of make commands.
Everything is wrapped into `docker-compose-dev.yml` file. So you have to have `docker-compose`
installed on your machine.

Commands:

 - `make run-dev` - Will start QA portal in docker images and will set `localhost:3000` - for UI and `localhost:4000` - for WS/Web API
 - `make logs-dev` - Will spam you with logs from system
 - `make stop-dev` - Will stop all services
