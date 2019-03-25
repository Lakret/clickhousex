defmodule Clickhousex.Helpers do
  @moduledoc false

  defmodule BindQueryParamsError do
    @moduledoc false

    defexception [:message, :query, :params]
  end

  @doc false
  def bind_query_params(query, []), do: query

  def bind_query_params(query, params) do
    query_parts = String.split(query, "?")

    case length(query_parts) do
      1 ->
        case length(params) do
          0 ->
            query

          _ ->
            raise BindQueryParamsError,
              message: "Extra params: the query doesn't contain '?'",
              query: query,
              params: params
        end

      len ->
        if len - 1 != length(params) do
          raise BindQueryParamsError,
            message:
              "The number of parameters does not correspond to the number of question marks",
            query: query,
            params: params
        end

        param_for_query(query_parts, params)
    end
  end

  @doc false
  defp param_for_query(query_parts, params) when length(params) == 0 do
    Enum.join(query_parts, "")
  end

  defp param_for_query([query_head | query_tail], [params_head | params_tail]) do
    query_head <> param_as_string(params_head) <> param_for_query(query_tail, params_tail)
  end

  @doc false
  defp param_as_string(param) when is_list(param) do
    param
    |> Enum.map(fn p -> param_as_string(p) end)
    |> Enum.join(",")
  end

  defp param_as_string(param) when is_integer(param) do
    Integer.to_string(param)
  end

  defp param_as_string(param) when is_boolean(param) do
    to_string(param)
  end

  defp param_as_string(param) when is_float(param) do
    to_string(param)
  end

  defp param_as_string(param) when is_float(param) do
    to_string(param)
  end

  defp param_as_string({date_tuple = {_year, _month, _day}, {hour, minute, second, msecond}}) do
    case NaiveDateTime.from_erl({date_tuple, {hour, minute, second}}, {msecond, 3}) do
      {:ok, ndt} ->
        "'#{NaiveDateTime.to_iso8601(ndt)}'"

      {:error} ->
        {:error, %Clickhousex.Error{message: :wrong_date_time}}
    end
  end

  defp param_as_string(date = {_year, _month, _day}) do
    case Date.from_erl(date) do
      {:ok, date} ->
        "'#{Date.to_string(date)}'"

      {:error} ->
        {:error, %Clickhousex.Error{message: :wrong_date}}
    end
  end

  defp param_as_string(param) do
    "'" <> param <> "'"
  end
end
