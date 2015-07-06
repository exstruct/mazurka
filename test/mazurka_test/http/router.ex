defmodule MazurkaTest.HTTP.Router do
  use Mazurka.Protocol.HTTP.Router
  use Mazurka.Mediatype.Hyperjson.Hyperpath
  use MazurkaTest.Dispatch

  alias MazurkaTest.Resources

  plug :match
  plug :dispatch

  get     "/",                          Resources.Root
  get     "/users",                     Resources.Users.List
  get     "/users/:user",               Resources.Users.Read
  post    "/users/:user",               Resources.Users.Update

  match   _,                            Resources.Errors.NotFound
end