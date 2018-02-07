defmodule Test.Mazurka.Resource do
  use Test.Mazurka.Case

  block("""
  # Tutorial

  In this tutorial we'll be using a helper module that sets our mediatype.
  """)

  defmodule MyApp.Resource do
    defmacro __using__(_) do
      quote do
        use Mazurka
        use Mazurka.Hyper.JSON
        use Mazurka.Hyper.Msgpack
      end
    end
  end

  describe "Getting started" do
    block("""
    Start by creating a module. Use our resource module `MyApp.Resource` at the top of the module. In this example, we'll create a `User` resource.
    """)

    defmodule User do
      use MyApp.Resource

      map do
        field :name do
          constant do
            "Joe"
          end
        end
      end
    end

    test """
    hyper+json request

    Now let's test that it responds to our request
    """ do
      conn = Plug.Test.conn(:get, "/")
      opts = User.init([])
      conn = User.call(conn, opts)

      %{status: 200, resp_body: resp_body} = conn
      %{"name" => "Joe"} = Poison.decode!(resp_body)
    end

    test """
    hyper+msgpack request

    We can also pass an `Accept` header and request Msgpack
    """ do
      conn =
        Plug.Test.conn(:get, "/")
        |> Plug.Conn.put_req_header("accept", "application/msgpack")

      opts = User.init([])
      conn = User.call(conn, opts)

      %{status: 200, resp_body: resp_body} = conn
      %{"name" => "Joe"} = Msgpax.unpack!(resp_body)
    end

    block """
    You've now created your first resource! You've been introduced to three new keywords in this basic example:

    ### `map/1`
    ### `field/2`
    ### `constant/1`
    """
  end

  describe "Dynamic data" do
    block """
    In the last section, we learned how to create a simple static resource. This time we'll make the data dynamic.
    Let's start by creating a new `User` module. Instead of using the `constant/1` keyword, we'll be using `resolve/1`.
    """

    defmodule User do
      use MyApp.Resource

      map do
        field :name do
          constant do
            "Joe"
          end
        end

        field :age do
          resolve do
            :rand.uniform(50) + 20
          end
        end
      end
    end

    test """
    hyper+json request

    We should now get a random age back each time we request our `User` resource.
    """ do
      conn = Plug.Test.conn(:get, "/")
      opts = User.init([])
      conn = User.call(conn, opts)

      %{status: 200, resp_body: resp_body} = conn
      %{"name" => "Joe", "age" => age} = Poison.decode!(resp_body)
      true = age >= 20 && is_integer(age)
    end

    test """
    hyper+msgpack request

    Let's make sure our Msgpack request works as well.
    """ do
      conn =
        Plug.Test.conn(:get, "/")
        |> Plug.Conn.put_req_header("accept", "application/msgpack")

      opts = User.init([])
      conn = User.call(conn, opts)

      %{status: 200, resp_body: resp_body} = conn
      %{"name" => "Joe", "age" => age} = Msgpax.unpack!(resp_body)
      true = age >= 20 && is_integer(age)
    end

    block """
    ### `resolve/1`
    """
  end

  describe "Reading data from `conn`" do
    block """
    Now let's try pulling data from the `Plug.Conn` struct to change the way our `User` responds.
    """

    defmodule User do
      use MyApp.Resource

      map do
        field :name do
          resolve %{assigns: %{name: name}} = conn do
            {name, conn}
          end
        end

        field :email do
          resolve %{assigns: %{name: name}, host: host} = conn do
            "www." <> domain = host
            {"#{String.downcase(name)}@#{domain}", conn}
          end
        end
      end
    end

    test """
    hyper+json request

    We can now pass a `name` in the `assigns` field.
    """ do
      conn = Plug.Test.conn(:get, "/")
        |> Plug.Conn.assign(:name, "Robert")
      opts = User.init([])
      conn = User.call(conn, opts)

      %{status: 200, resp_body: resp_body} = conn
      %{"name" => "Robert", "email" => "robert@example.com"} = Poison.decode!(resp_body)
    end

    test """
    hyper+msgpack request

    Let's make another request with a different name just to make sure.
    """ do
      conn = Plug.Test.conn(:get, "/")
        |> Plug.Conn.put_req_header("accept", "application/msgpack")
        |> Plug.Conn.assign(:name, "Mike")
      opts = User.init([])
      conn = User.call(conn, opts)

      %{status: 200, resp_body: resp_body} = conn
      %{"name" => "Mike", "email" => "mike@example.com"} = Msgpax.unpack!(resp_body)
    end
  end

  describe "Conditional requests" do
    block """
    Usually we want to restrict requests to authenticated clients. We can accomplish
    that functionality with `condition/2`.
    """

    defmodule User do
      use MyApp.Resource

      @doc """
      Client must be authenticated
      """
      condition %{assigns: assigns} do
        assigns[:authenticated_user]
      end

      map do
        field :name do
          resolve %{assigns: %{name: name}} = conn do
            {name, conn}
          end
        end

        field :email do
          @doc """
          The authenticated user must be the same
          """
          condition %{assigns: %{name: name} = assigns} do
            assigns[:authenticated_user] == name
          end

          resolve %{assigns: %{name: name}, host: host} = conn do
            "www." <> domain = host
            {"#{String.downcase(name)}@#{domain}", conn}
          end
        end
      end
    end

    test """
    hyper+json unauthenticated request

    Now we can verify that the request fails without passing the correct `conn`.
    """ do
      conn = Plug.Test.conn(:get, "/")
        |> Plug.Conn.assign(:name, "Robert")
      opts = User.init([])
      try do
        User.call(conn, opts)
      rescue
        e in Mazurka.ConditionError ->
          "Client must be authenticated" = e.message
      end
    end

    test """
    hyper+msgpack authenticated request

    Let's make sure that authenticated requests go through as well.
    """ do
      conn = Plug.Test.conn(:get, "/")
        |> Plug.Conn.put_req_header("accept", "application/msgpack")
        |> Plug.Conn.assign(:name, "Joe")
        |> Plug.Conn.assign(:authenticated_user, "Robert")
      opts = User.init([])
      conn = User.call(conn, opts)

      %{status: 200, resp_body: resp_body} = conn
      %{"name" => "Joe"} = body = Msgpax.unpack!(resp_body)
      false = Map.has_key?(body, "email")
    end

    test """
    hyper+json authenticated request with email

    We can also check that the email field shows up when the users match.
    """ do
      conn = Plug.Test.conn(:get, "/")
        |> Plug.Conn.put_req_header("accept", "application/msgpack")
        |> Plug.Conn.assign(:name, "Robert")
        |> Plug.Conn.assign(:authenticated_user, "Robert")
      opts = User.init([])
      conn = User.call(conn, opts)

      %{status: 200, resp_body: resp_body} = conn
      %{"name" => "Robert", "email" => "robert@example.com"} = Msgpax.unpack!(resp_body)
    end
  end
end
