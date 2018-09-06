# A module that will turn functions annotated with `@replace :true` into
# functions with an additonal argument and then add arguments to zero arity
# function calls for functions that require arguments.
defmodule Magic do
  defmacro __using__(_env) do
    quote do
      Module.register_attribute(__MODULE__, :replace_register, accumulate: true)
      Module.register_attribute(__MODULE__, :all_register, accumulate: true)
      @on_definition Magic
      @before_compile Magic
    end
  end

  defmacro __before_compile__(env) do
    replace_funcs = Module.get_attribute(env.module, :replace_register)
    all_funcs = Module.get_attribute(env.module, :all_register)
    Module.put_attribute(env.module, :replace_ran, true)

    for {name, body, args, module, tuple} <- replace_funcs do
      new_body =
        Macro.prewalk(body, fn
          x = {funcname, context, []} ->
            function_head =
              Enum.find_value(all_funcs, fn
                {^funcname, _, theargs, ^module, _ftup} ->
                  {funcname, context, theargs}

                _ ->
                  nil
              end)

            function_head || x

          x ->
            x
        end)

      :elixir_def.take_definition(module, tuple)

      quote do
        def unquote(name)(unquote_splicing(args)), unquote(new_body)
      end
    end
  end

  def __on_definition__(env, _kind, name, args, _guards, body) do
    if Module.get_attribute(env.module, :replace_ran) != true do
      replace? = Module.get_attribute(env.module, :replace)
      Module.put_attribute(env.module, :replace, false)
      tuple = {name, length(args)}
      new_args = args ++ [Macro.var(:new_arg, nil)]

      if replace? do
        Module.put_attribute(
          env.module,
          :replace_register,
          {name, body, new_args, env.module, tuple}
        )
      end

      Module.put_attribute(env.module, :all_register, {name, body, args, env.module, tuple})
    end
  end
end

defmodule Thing do
  use Magic

  @replace true
  def my_func() do
    user_id = :foo
    password = %{plaintext: "lol ok"}
    object = new_arg

    object = put_user_id()
    arg = :bar

    object = put_another()
    dangerous_function()
  end

  defp put_user_id(object, user_id) do
    Map.put(object, :user_id, user_id)
  end

  defp put_another(object, arg) do
    Map.put(object, :arg, arg)
  end

  defp dangerous_function(password, object) do
    # TODO: don't deploy to prod
    Map.put(object, :password, password)
  end
end

IO.inspect(Thing.my_func(%{}))
