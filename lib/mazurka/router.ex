defprotocol Mazurka.Router do
  @doc """
  TODO write the docs
  """

  def resolve(router, affordance, source, conn)

  @doc """
  TODO write the docs
  """

  def resolve_resource(router, module, source, conn)

  @doc """

  """
  def format_params(router, params, source, conn)
end

defimpl Mazurka.Router, for: Atom do
  def resource(nil, affordance, _source, _conn) do
    affordance
  end
  def resolve(router, affordance, source, conn) do
    router.resolve(affordance, source, conn)
  end

  def resolve_resource(nil, module, _source, _conn) do
    module
  end
  def resolve_resource(router, module, source, conn) do
    router.resolve_resource(module, source, conn)
  rescue e in UndefinedFunctionError ->
    case e do
      %{module: ^router, function: :resolve_resource} ->
        module
      _ ->
        reraise e, System.stacktrace
    end
  end

  def format_params(nil, params, _source, _conn) do
    params
  end
  def format_params(router, params, source, conn) do
    router.format_params(params, source, conn)
  rescue e in UndefinedFunctionError ->
    case e do
      %{module: ^router, function: :format_params} ->
        params
      _ ->
        reraise e, System.stacktrace
    end
  end
end
