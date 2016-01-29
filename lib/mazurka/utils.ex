defmodule Mazurka.Utils do
  def env do
    cond do
      env = System.get_env("MIX_ENV") ->
        String.to_atom(env)
      true ->
        Mix.env
    end
  end
end
