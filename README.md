# DispatchEx

Compile time dispatch for patterns.

Similar to Elixirs `Protocol` but uses pattern matching on the value.


## Installation

If [available in Hex](https://hex.pm/docs/publish), the package can be installed
by adding `dispatchex` to your list of dependencies in `mix.exs`:

```elixir
def project do
  [
    # ...
    compilers: Mix.compilers() ++ [:dispatch]
  ]

def deps do
  [
    # ...
    {:dispatchex, "~> 0.1.0"}
  ]
end
```


Documentation can be generated with [ExDoc](https://github.com/elixir-lang/ex_doc)
and published on [HexDocs](https://hexdocs.pm). Once published, the docs can
be found at <https://hexdocs.pm/dispatchex>.

## Live Reload & Phoenix

To add support for live reload compilation add to `reloadable_compilers` in `config/dev.exs`.

```
config :phxapp_web, PhxApp.Endpoint,
  reloadable_compilers: [:gettext, :phoenix, :elixir, :dispatch],
```


## Simple Usage

```elixir
defmodule Castable do
  use DispatchEx, :protocol

  @callback cast(term()) :: {:ok, term()} | {:error, atom()}

  # Add optional fallback clause,
  def cast(_), do: {:error, :fallback}
end

defmodule WrappedNumber do
  use DispatchEx, for: Castable

  def cast(%{"type" => "number", "value" => v}), do: {:ok, {:integer, v}}
end

defmodule WrappedString do
  use DispatchEx, for: Castable

  def cast(%{"type" => "string", "value" => v}), do: {:ok, {:string, v}}
end

{:ok, {:string, "abc"}} = Castable.cast(%{"type" => "string", "value" => "abc"})
{:ok, {:integer, 123}} = Castable.cast(%{"type" => "number", "value" => 123})
{:error, :fallback} = Castable.cast(%{})
```