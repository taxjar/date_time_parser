defmodule DateTimeParserTest.Recorder do
  @moduledoc "Record results from tests into a Markdown file"
  @external_resource "test/fixture/playground_header.md"
  @examples_header File.read!(@external_resource)

  if Version.match?(System.version(), ">= 1.5.0") do
    use Agent
    @name {:global, :recorder}
    @example_file "EXAMPLES.livemd"

    def start_link(initial_value \\ []) do
      Agent.start_link(fn -> initial_value end, name: @name)
    end

    def add(input, output, method, opts) do
      Agent.update(@name, fn state ->
        [{input, output, method, opts} | state]
      end)
    end

    def list do
      Agent.get(@name, fn state ->
        Enum.sort(state)
      end)
    end

    def write_results do
      write_headers()
      Enum.each(list(), &write_result/1)

      :ok
    end

    defp write_headers do
      File.write(@example_file, @examples_header)
    end

    defp write_result({input, output, method, opts}) do
      File.write(
        @example_file,
        "|`#{input}`|`#{DateTimeParserTestMacros.to_iso(output)}`|#{method}|#{format_options(opts)}|\n",
        [:append]
      )
    end

    defp format_options([]), do: " "
    defp format_options(options), do: "`#{inspect(options)}`"
  else
    def start_link(_ \\ []), do: {:ok, nil}
    def add(_, _, _, _), do: :ok
    def list, do: :ok
    def write_results, do: :ok
  end
end
