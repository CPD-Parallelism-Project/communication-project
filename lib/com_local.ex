defmodule ComLocal do

  def start_cluster(data, fun_split, fun_resolve, converge) do
    #size = connect_children()
    #Partir la información para iniciar los procesos con información distribuida
    #data = String.split(data, " ")

    #Node.list()
    childs = Enum.map(1..3, fn _ -> start_child() end)
    headNode = start_head( 3, childs, converge)
    data_splited = fun_split.(data, 4)
    #Enviar la función junto con dato a cada nodo
    send(headNode, {:execute_head, Enum.at(data_splited, 3), fun_resolve})
    for {value, index} <- Enum.with_index(childs) do
      send(value, {:execute, fun_resolve, Enum.at(data_splited,index) , headNode})
    end
    :ok
  end

  def start_head( size, childs, converge) do
    spawn(__MODULE__, :loop_head, [size, %{}, childs, converge])
  end


  def start_child() do
    spawn(fn -> loop_child() end)
  end

  def loop_child do
    receive do
      {:execute, fun, data, pidOrigin} -> send(pidOrigin, {:end, self(), fun.(data) })
    end
  end

  def loop_head(size, rta, childs, converge) do
    map = receive do
      {:end, node, data} ->  Map.put(rta, node, data)
      {:execute_head, data, fun} -> Map.put(rta, self(), fun.(data))
    end
    case size do
      0 -> converge.(map,childs++[self()])
      _ -> loop_head(size - 1, map, childs, converge)
    end

  end
end
