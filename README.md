# Magic Elixir Macro

The Elixir macro found in `sorry.exs` allows you to call functions without specifying the arguments (as long as the name matches a local variable).

## Example
```elixir
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
  end

  defp put_user_id(object, user_id) do
    Map.put(object, :user_id, user_id)
  end

  defp put_another(object, arg) do
    Map.put(object, :arg, arg)
  end
end
```

The code above turns `my_func/0` into
```
  def my_func() do
    user_id = :foo
    password = %{plaintext: "lol ok"}
    object = new_arg

    object = put_user_id(object, user_id)
    arg = :bar

    object = put_another(object, arg)
  end
```

# Disclaimer

I am not responsible if you actually use this. Please don't use this, it was a fun exercise in writing macros.
