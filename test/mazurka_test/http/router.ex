defmodule MazurkaTest.HTTP.Router do
  use Mazurka.Protocol.HTTP.Router
  use Mazurka.Mediatype.Hyperjson.Hyperpath
  use MazurkaTest.Dispatch, [
    link_transform: :link_transform
  ]

  alias MazurkaTest.Resources

  plug :match
  plug :dispatch

  get     "/",                              Resources.Root

  get     "/posts/:post",                   Resources.Posts.Read

  get     "/parameterized/one",             {Resources.Parameterized, "one"}
  get     "/parameterized/two",             {Resources.Parameterized, "two"}

  get     "/users",                         Resources.Users.List
  get     "/users/:user",                   Resources.Users.Read
  post    "/users/:user",                   Resources.Users.Update

  get     "/junk/access-protocol/:key",     Resources.AccessProtocol
  get     "/junk/multiple",                 Resources.Multiple
  get     "/junk/modules",                  Resources.Modules
  get     "/junk/partials/:name",           Resources.Partials
  get     "/junk/private-macro",            Resources.PrivateMacro
  get     "/junk/helper-macro",             Resources.HelperMacro
  get     "/junk/case/:number",             Resources.Case
  get     "/junk/validation/:key",          Resources.Validation
  get     "/junk/transition_to_binary",     Resources.TransitionToBinary
  get     "/junk/query",                    Resources.QueryParam
  get     "/junk/query/link",               Resources.QueryParamLink

  match   _,                                Resources.Errors.NotFound

  def link_transform(link, _conn) do
    link
  end
end
