defmodule DateTimeParserTest.Recorder do
  @moduledoc "Record results from tests into a Markdown file"

  use Agent
  @name {:global, :recorder}
  @example_file "EXAMPLES.md"

  def start_link(initial_value \\ []) do
    Agent.start_link(fn -> initial_value end, name: @name)
  end

  def add(input, output, method) do
    Agent.update(@name, fn state ->
      [{input, output, method} | state]
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
    File.write(
      @example_file,
      """
      # Examples

      |**Input**|**Output (ISO 8601)**|**Method**|
      |:--------:|:-------:|:--------:|
      """
    )
  end

  defp write_result({input, output, method}) do
    File.write(
      @example_file,
      "|`#{input}`|`#{DateTimeParserTestMacros.to_iso(output)}`|#{method}|\n",
      [:append]
    )
  end
end
