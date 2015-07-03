defmodule MazurkaTest.Dispatch do
  use Mazurka.Dispatch
  alias MazurkaTest.Services
  # alias Mazurka.Middleware

  service Foo.bar/0

  service Auth.user_id/0, Services.Auth.user_id(conn) do
    Middleware.Logger.debug("Getting the user_id")
  end

  env :test do
    service Auth
  end

  service Users.get/1, MazurkaTest.Services.Users.get(&1) do
    Middleware.PubSub.subscribe(Users, &1)
    env :prod do
      Middleware.LRU.get(Users, &1)
    end
  end

  service Users.update/2, MazurkaTest.Services.Users.get(&1, &2, env) do
    env :prod do
      Middleware.LRU.delete(Users, &1)
    end
    Middleware.PubSub.publish(Users, &1)
  end

  service Users, MazurkaTest.Services.Users
end