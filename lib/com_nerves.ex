defmodule Com do

  def test do
    data = "head"
    #start_cluster(data, &test_function/1)
    send_test()
  end

  def start_cluster(data, fun) do
    size = connect_children()
    IO.puts("Nodes number: #{size}")
    #Partir la información para iniciar los procesos con información distribuida
    #data = String.split(data, " ")

    childs = Node.list() |> Enum.with_index() |> Enum.map( fn {node, index} -> start_child(node, index) end)
    IO.puts("childs")
    IO.inspect(childs)
    headNode = start_head(size)
    #Enviar la función junto con dato a cada nodo
    send(headNode, {:execute_head, data, fun, size})
    childs |> Enum.each(fn pid -> send(pid, {:execute, fun, "node", headNode}) end )
    :ok
  end

  def receive_test() do
    receive do
      {:test, origin} -> send(origin, {:ack, "correct"})
    end
  end

  def send_test() do
    connect_children()
    # Crea un proceso local dentro del nodo para recibir el mensaje
    pidOrigin = Node.spawn(Node.self(), fn ->
      receive do
        {:ack, message} -> IO.puts(message)
      end
    end )
    # Crea
    # hd(Node.list())
    Node.spawn(hd(Node.list()), fn -> Com.receive_test() end)
    |> send({:test, pidOrigin})
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

  def start_head( size) do
    #configure_net(0)
    Node.spawn_link(Node.self(), fn -> loop_head(size, %{}) end)
  end


  def start_child(node, index) do
    #configure_net(item)
    Node.spawn_link(node, fn -> loop_child(index) end )
  end

  def loop_child(index) do
    receive do
      {:execute, fun, data, pidOrigin} -> send(pidOrigin, {:end, Node.self(), fun.(data), index })
    end
  end

  def loop_head(size, rta) do
    map = receive do
      {:end, node, data, index} ->  Map.put(rta, node, %{data: data, index: index})
      {:execute_head, data, fun, index} -> Map.put(rta, self(), %{data: fun.(data), index: index})
    end
    case size do
      0 -> converge(map)
      _ -> loop_head(size - 1, map)
    end

  end

  defp converge(map) do
    IO.puts("Función de convergencia")
    IO.inspect(map)
  end

  # Conectar los nodos disponibles
  defp connect_children() do
    Node.list() |> Enum.reduce(0, fn node, acc -> Node.connect(node); acc + 1 end )
  end

  def test_function(data) do
    random_time()
    "Resolved data from #{data}"
  end

  def random_time do
    :timer.sleep(Enum.random(1..10) * 300)
  end

end

defmodule Tasks do
  def task_1 (data) do
    #Codigo de la primera tarea
    "Task 1 from #{data}"
  end

  def task_2 (data) do
    #Codigo de la segunda tarea
    "Task 2 from #{data}"
  end



end

Com.test()
