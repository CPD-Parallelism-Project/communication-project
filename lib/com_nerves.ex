defmodule ComNerves do

  def test do
    data = "head 1 2 3 4 5 6 7 8 9 0 1 2 3 4 5 6 7 8 9 8 7 6 5 4 3 2 2 5 6 8 0 6 4 23 2 3 4 5 6 7 89 0 6 3 1 1 1 1 1 1 Hola hola HOLA HO,la 1 1 1 1 1 1 head"
    configure(5)
    start_cluster(data, &Exercise1.e1_split_function/2, &Exercise1.e1_function/1, &Exercise1.e1_merge_function/2)
    #send_test()
  end

  def configure(group) do
    Node.start(:"com@#group_#{group}")
  end

  def start_cluster(data, fun_split, fun, converge) do
    size = connect_children()
    IO.puts("Nodes number: #{size}")
    parallel_constant = 4

    headNode = start_head(size*parallel_constant, converge)
    childs = Node.list()
      |> Enum.with_index()
      |> Enum.flat_map( fn {node, index} -> Enum.map(0..parallel_constant, fn x -> start_child(node,  "#{index} #{x}", headNode) end) end)
    parallel_workers = length(childs)
    data_splited = fun_split.(data, parallel_workers)

    #Enviar la función junto con dato a cada nodo
    for {value, index} <- Enum.with_index(childs) do
      send(value, {:execute, fun, Enum.at(data_splited, index) , headNode})
    end
    :ok

  end

  def receive_test() do
    receive do
      {:test, origin} -> send(origin, {:ack, "correct"})
    end
  end

  def send_test() do
    connect_children()
    Node.spawn(hd(Node.list()), fn -> Com.receive_test() end)
    |> send({:test, nil})

    receive do
      {:ack, message} -> IO.puts(message)
    end
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

  def start_head(size, converge) do
    #configure_net(0)
    Node.spawn_link(Node.self(), fn -> loop_head(size, %{}, size, converge) end)
  end

  def loop_head(size, rta, workers, converge) do
    map = receive do
      {:end, node, data, index} ->  Map.put(rta, index, data)
      {:execute_head, data, fun, index} -> Map.put(rta, index, fun.(data))
    end
    case size do
      0 -> converge.(map, Map.keys(map))
      _ -> loop_head(size - 1, map, workers, converge)
    end
  end

  def start_child(node, index, headNode) do
    Node.spawn_link(node, fn -> loop_child(index) end )
  end

  def loop_child(index) do
    receive do
      {:execute, fun, data, pidOrigin} -> send(pidOrigin, {:end, Node.self(), fun.(data), index })
    end
  end

  # Conectar los nodos disponibles
  defp connect_children() do
    [
      :"livebook@grupo-1",
      #:"livebook@grupo-0",
      #:"livebook@grupo-0",
      #:"livebook@grupo-0",
      #:"livebook@grupo-0",
    ]
    |> Enum.reduce(0, fn node, acc -> Node.connect(node); acc + 1 end )

  end

end
