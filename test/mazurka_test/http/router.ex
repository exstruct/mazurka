defmodule MazurkaTest.HTTP.Router do
  use Mazurka.Protocol.HTTP.Router
  use Mazurka.Mediatype.Hyperjson.Hyperpath
  use MazurkaTest.Dispatch

  alias MazurkaTest.Resources

  plug :match
  plug :dispatch

  get     "/",                          Resources.Root
  get     "/users/:user",               Resources.Users

  match   _,                            Resources.Errors.NotFound
end