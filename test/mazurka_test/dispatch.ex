defmodule MazurkaTest.Dispatch do
  use Mazurka.Dispatch
  alias MazurkaTest.Services
  # alias Mazurka.Middleware

  service Posts, Services.Posts

  service Auth.user_id/0, Services.Auth.user_id(conn) do
    Middleware.Logger.debug("Getting the user_id")
  end

  env :test do
    service Auth
  end

  service Users.list/0, Services.Users.list(env)

  service Users.get/1, Services.Users.get(&1, env) do
    Middleware.PubSub.subscribe(Users, &1)
    env :prod do
      Middleware.LRU.get(Users, &1)
    end
  end

  service Users.update/2, Services.Users.update(&1, &2, env) do
    env :prod do
      Middleware.LRU.delete(Users, &1)
    end
    Middleware.PubSub.publish(Users, &1)
  end

  service Users, Services.Users

  defp exec(DynamicPartials, fun, args, _, _, _, _) do
    props = args |> List.flatten |> Enum.into(%{})
    fun = fun |> Kernel.to_string |> Kernel.<>("_partial") |> String.to_atom

    {:partial, {MazurkaTest.Partials.Dynamic, fun, props}}
  end
end
