defmodule Com do

  def test do
    data = "head"
    start_cluster(data, &test_function/1)
  end

  def start_cluster(data, fun) do
    #size = connect_children()
    #Partir la información para iniciar los procesos con información distribuida
    #data = String.split(data, " ")

    #Node.list()
    childs = Enum.map(1..3, fn item -> start_child(_,item) end)
    headNode = start_head( 3, childs)
    #Enviar la función junto con dato a cada nodo
    send(headNode, {:execute_head, data, fun})
    childs |> Enum.each(fn pid -> send(pid, {:execute, fun, "node", headNode}) end )
    :ok
  end

  def configure_net(ip) do
    VintageNet.configure("eth0", %{
      type: VintageNetEthernet,
      ipv4: %{
        method: :static,
        address: "192.168.1.#{ip+1}",
        prefix_length: 24,
        gateway: "192.168.1.1",
        nameservers: ["1.1.1.1"]
      }
    })
  end

  def start_head( size, childs) do
    #configure_net(0)
    spawn(__MODULE__, :loop_head, [size, %{}, childs])
  end


  def start_child(node,item) do
    #configure_net(item)
    spawn(fn -> loop_child() end)
  end

  def loop_child do
    receive do
      {:execute, fun, data, pidOrigin} -> send(pidOrigin, {:end, self(), fun.(data) })
    end
  end

  def loop_head(size, rta, childs) do
    map = receive do
      {:end, node, data} ->  Map.put(rta, node, data)
      {:execute_head, data, fun} -> Map.put(rta, self(), fun.(data))
    end
    case size do
      0 -> converge(map,childs++[self()])
      _ -> loop_head(size - 1, map, childs)
    end

  end

  defp converge(map, childs) do
    IO.puts("Función de convergencia")
    IO.inspect(map)
    IO.inspect(childs)
  end

  # Conectar los nodos disponibles
  defp connect_children do
    Enum.each(1..3, Node.spawn(Node.self(), :loop_child, []))
    size = 0
    Node.list() |> Enum.each(fn node -> Node.connect(node); size + 1 end)
    IO.puts("Nodes number: #{size}")
    size
  end

  def test_function(data) do
    random_time()
    "Resolved data from #{data}"
  end

  def random_time do
    :timer.sleep(Enum.random(1..10) * 300)
    Node.list() |> Enum.reduce(0, fn node, acc -> acc + 1 end)
  end

end

defmodule Tasks do
  def task_1 (data) do
    "Task 1 from #{data}"
  end

  def task_2 (data) do
    "Task 2 from #{data}"
  end



end
