defmodule API.HTTPStream do
  def get(url) do
    Stream.resource(
      # start_fun
      fn ->
        HTTPoison.get!(
          url,
          %{},
          stream_to: self(),
          async: :once
        )
      end,
      fn %HTTPoison.AsyncResponse{id: id} = resp ->
        receive do
          %HTTPoison.AsyncStatus{id: ^id, code: _code} ->
            HTTPoison.stream_next(resp)
            {[], resp}

          %HTTPoison.AsyncHeaders{id: ^id, headers: _headers} ->
            HTTPoison.stream_next(resp)
            {[], resp}

          %HTTPoison.AsyncChunk{id: ^id, chunk: chunk} ->
            HTTPoison.stream_next(resp)
            {[chunk], resp}

          %HTTPoison.AsyncEnd{id: ^id} ->
            {:halt, resp}
        end
      end,
      fn %HTTPoison.AsyncResponse{id: id} ->
        :hackney.stop_async(id)
      end
    )
  end
end
