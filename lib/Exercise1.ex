defmodule Exercise1 do
  def e1_function(data) do
    response = Enum.reduce data, %{}, fn x, acc ->
      word = String.downcase(x)
      word = String.replace(word, ~r/[!#$%&()*+,.:;<=>?@\^_`{|}~-]/, "")
      v = Map.get(acc, word)
      if v == nil do
        Map.put(acc, word, 1)
      else
        Map.put(acc, word, v+1)
      end
    end
    response
  end

  def e1_split_function(data, workers) do
    list = String.split(data, [" ", "\n", "\t"])
    size = length(list)
    a = div(size,workers)+1
    Enum.chunk_every(list, a)
  end

  def e1_merge_function(map, childs) do
    res = merge(map, childs, %{})
    IO.puts("Función de convergencia")
    IO.inspect(res)
    #IO.inspect(childs)
  end

  def merge(map, [a | children], r) do
    r = Map.merge(r, map[a], fn _k, v1, v2 ->
      v1 + v2
    end)
    merge(map, children, r)
  end

  def merge(_, [], r) do
    r
  end
end
