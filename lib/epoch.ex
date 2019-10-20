defmodule DateTimeParser.Epoch do
  @moduledoc false

  @token_key :unix_epoch

  import DateTimeParser.Formatters, only: [format: 1]

  def parse(%{"seconds" => raw_seconds, "subseconds" => raw_subseconds}) do
    with {seconds, _} <- Integer.parse(raw_seconds) do
      parsed_epoch =
        case(Integer.parse(raw_subseconds)) do
          :error ->
            {seconds, nil}

          {subseconds, _} ->
            {seconds, subseconds}
        end

      {:ok, [{@token_key, parsed_epoch}], nil, nil, nil, nil}
    end
  end

  def from_tokens(tokens) do
    {seconds, subseconds} = tokens[@token_key]

    with {:ok, datetime} <- DateTime.from_unix(seconds) do
      case subseconds do
        nil ->
          {:ok, datetime}

        subseconds ->
          truncated_subsecond =
            subseconds
            |> Integer.digits()
            |> Enum.take(6)
            |> Integer.undigits()

          {:ok, %{datetime | microsecond: format({:microsecond, truncated_subsecond})}}
      end
    end
  end
end
