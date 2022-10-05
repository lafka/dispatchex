defmodule DispatchEx do
  @moduledoc """

  Sets up a module for a protocol dispatch or a concrete implementation.

  ## Example

  ```
  defmodule PolymorphicCommand do
    use Dispatch, :protocol
    @callback cast(term()) :: {:ok, term()} | {:error, reason :: term()}

    # this becoms the default implementation
    def cast(_), do: raise ArgumentError, "unable to cast command description"
  end

  defmodule ReadCommand do
    use Dispatch, for: PolymorphicCommand
    def cast(%{type: read, key: k}), do: {:read, k}
  end

  defmodule WriteCommand do
    use Dispatch, for: PolymorphicCommand
    def cast(%{type: :write, key: k, value: v}), do: {:write, k, v}
  end

  {:read, 1} = PolymorphicCommand.cast(%{type: :read, key: 1})
  {:write, 1, :x} = PolymorphicCommand.cast(%{type: :write, key: 1, value: :x})
  ````
  """

  # Esnure Mix task is available
  require Mix.Tasks.Compile.Dispatch

  defmacro __using__(:protocol) do
    quote do
      Module.register_attribute(__MODULE__, :dispatch, persist: true)
      @dispatch __MODULE__
    end
  end

  defmacro __using__(for: proto) do
    proto = Macro.expand(proto, __CALLER__)

    quote do
      @moduledoc """
      Concrete implementation of #{unquote(proto)} protocol
      """
      @behaviour unquote(proto)

      Module.register_attribute(__MODULE__, :__impl__, persist: true, accumulate: true)

      require unquote(__MODULE__)

      import unquote(__MODULE__)
      import Kernel, except: [def: 1, def: 2]
    end
  end

  defmacro def(call, expr \\ nil) do
    call = Macro.expand(call, __CALLER__)
    resolved = Macro.expand(expr, __CALLER__)
    escaped = Macro.escape({:def, [], [call, resolved]}, prune_metadata: true)

    quote location: :keep do
      @__impl__ unquote(escaped)
      Kernel.def(unquote(call), unquote(expr))
    end
  end
end
