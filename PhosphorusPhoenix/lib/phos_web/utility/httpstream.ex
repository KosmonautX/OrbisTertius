defmodule PhosWeb.Util.HTTPStream do

  def get(url,emit_end\\false) do

    Stream.resource(
      fn -> HTTPoison.get!(url,%{}, [stream_to: self(), async: :once])end,

      # next_fun (multi caluses)
      fn
        %HTTPoison.AsyncResponse{}=resp ->
          handle_async_resp(resp,emit_end)

        #last accumulator when emitting :end
        {:end, resp}->
          {:halt, resp}
      end,

      fn %HTTPoison.AsyncResponse{id: id} ->
        IO.puts("END_Function")
        :hackney.stop_async(id)
      end
    )
  end

  defp handle_async_resp(%HTTPoison.AsyncResponse{id: id}=resp,emit_end) do
    receive do
      %HTTPoison.AsyncStatus{id: ^id, code: code}->
        IO.inspect(code, label: "STATUS: ")
        HTTPoison.stream_next(resp)
        {[], resp}
      %HTTPoison.AsyncHeaders{id: ^id, headers: headers}->
        IO.inspect(headers, label: "HEADERS: ")
        HTTPoison.stream_next(resp)
        {[], resp}
      %HTTPoison.AsyncChunk{id: ^id, chunk: chunk}->
        HTTPoison.stream_next(resp)
        # :erlang.garbage_collect()
        {[chunk], resp}
      %HTTPoison.AsyncEnd{id: ^id}->
        if emit_end do
          {[:end], {:end, resp}}
        else
          {:halt, resp}
        end
    after
      5_000 -> raise "receive timeout"
    end
  end

end
