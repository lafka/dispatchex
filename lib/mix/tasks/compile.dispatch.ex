defmodule Mix.Tasks.Compile.Dispatch do
  use Mix.Task.Compiler

  @moduledoc ~S"""
  Consolidate protocols dispatch

  This does NOT use the elixir defprotocol functionality but instead
  builds a dispatch table based soly on pattern matching. The purpose beeing
  a more flexible dispatch built at compile time.

  Loads all the project files and their dependencies before scanning for the
  `Dispatch` behaviour. The modules implementing the protocol is parsed
  for their AST which the compiler merges with the original source file.
  The result is a single consolidated file with all the function clauses
  for the dispatch. The imlementing beam file may be discarded as it is
  not used.
  """

  @impl true
  def run(_args) do
    config = Mix.Project.config()

    Mix.Task.run("compile")

    ast =
      config
      |> implementations()
      |> consolidate()

    # The list of defs is present, the module should be redefined
    # by removing all of the callback functions defined in behaviour
    # and then injecting the defs.

    Enum.each(ast, fn {proto, defs} ->
      source = "#{proto.module_info(:compile)[:source]}"

      output =
        case :code.which(proto) do
          [] ->
            # File is not compiled yet;
            beam_path(Mix.Project.compile_path(config), proto)

          file ->
            # File is compiled, overwrite it
            "#{file}"
        end

      {:ok, ast} = Code.string_to_quoted(File.read!(source))
      {:defmodule, env, [aliases, [do: {:__block__, [], items}]]} = ast
      callbacks = proto.behaviour_info(:callbacks)

      {implemented, others} =
        Enum.split_with(items, fn
          {:def, _, [{fun, _, args} | _]} ->
            Enum.member?(callbacks, {fun, length(args)})

          _ ->
            false
        end)

      newmodule = others ++ defs ++ implemented

      amended = {:defmodule, env, [aliases, [do: {:__block__, [], newmodule}]]}

      IO.puts Macro.to_string(amended)

      # Attempt to remove the code to avoid warning,
      _ = :code.purge(proto)
      _ = :code.delete(proto)

      [{_, buf}] = Code.compile_quoted(amended, source)

      File.write!(output, buf)
    end)
  end

  defp consolidate(protocols) do
    Enum.map(protocols, fn {protocol, impls} ->
      defs =
        Enum.flat_map(impls, fn impl ->
          List.flatten(Keyword.get_values(impl.__info__(:attributes), :__impl__))
        end)
      {protocol, defs}
    end)
  end

  defp implementations(config) do
    apps =
      for app <- deps(config) do
        # this may fail for uncompiled applications in a umbrella project, in which
        # case it can be ignored since :dispatch compiler will re-run later if required.
        _ = Application.ensure_loaded(app)
        app
      end

    :ok = ensure_all_files_loaded(apps)

    for protocol <- dispatchable(config), into: %{} do
      {protocol, get_protocol_implementations(config, protocol)}
    end
  end

  defp dispatchable(_config) do
    Enum.flat_map(:code.all_loaded(), fn {module, _} ->
      cond do
        not function_exported?(module, :module_info, 1) ->
          []

        [] != List.flatten(Keyword.get_values(module.module_info(:attributes), :dispatch)) ->
          [module]

        true ->
          []
      end
    end)
  end

  defp beam_path(compile_path, module) do
    Path.join(compile_path, Atom.to_string(module) <> ".beam")
  end

  defp ensure_all_files_loaded([]), do: :ok

  defp ensure_all_files_loaded([app | rest]) do
    case :code.lib_dir(app) do
      [_ | _] = dir ->
        for file <- Path.wildcard("#{dir}/ebin/*.beam") do
          case String.to_atom(Path.basename(file, ".beam")) do
            __MODULE__ ->
              :ok

            module ->
              :code.purge(module)
              :code.delete(module)
              {:module, _} = :code.load_abs('#{Path.rootname(file)}')
          end
        end

      {:error, _} ->
        :ok
    end

    ensure_all_files_loaded(rest)
  end

  defp get_protocol_implementations(_config, protocol) do
    Enum.flat_map(:code.all_loaded(), fn {module, _} ->
      cond do
        not function_exported?(module, :module_info, 1) ->
          []

        protocol in List.flatten(Keyword.get_values(module.module_info(:attributes), :behaviour)) ->
          [module]

        true ->
          []
      end
    end)
  end

  defp deps(config) do
    deps = for %{scm: scm} = dep <- Mix.Dep.cached(), not scm.fetchable?, do: dep.app
    Enum.uniq([config[:app] | deps])
  end
end
