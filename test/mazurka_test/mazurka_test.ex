defmodule MazurkaTest do  
  def start do
    Plug.Adapters.Cowboy.http MazurkaTest.HTTP.Router, nil, [port: 4001]
  end
end
