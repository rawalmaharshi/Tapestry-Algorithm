defmodule Proj3.Node do
    use GenServer

    def init(init_state) do
        pid = self();
        # GenServer.cast(pid, :start)
        [nodeInitializationData | _tail] = init_state
        # Initialize this genserver with name, empty routing table and all
        routingTable = Enum.reduce(0..3, %{}, fn currentLevel, acc1 -> 
            slots = Enum.reduce(0..15, %{}, fn x, acc2 -> 
                currentSlot = Helper.currentSlot(x)
                Map.put(acc2, currentSlot, "")
            end)
            Map.put(acc1, currentLevel, slots)
        end)
        currentState = nodeInitializationData
        currentState = Map.merge(currentState, %{routingTable: routingTable})
        currentState = Map.put_new(currentState, :pid, pid)
        
        #This method adds hashname to global list of hashnames that is stored under Tapestry's state
        GenServer.cast(Proj3.Tapestry, {:add_node_name_to_global_list, currentState.hashID, pid})
        # getCurrentState()
        IO.inspect {:ok, currentState}
    end

    # def handle_call({:get_state}, _from, current_state) do
    #     {:reply, current_state, current_state}
    # end

    def handle_call({:updateRoutingTable, currentNodeId, allHashNames}, _from, current_state) do

        newRoutingTable = routingTableFunction(Map.get(current_state, :routingTable), currentNodeId, allHashNames)
        current_state = Map.put(current_state, :routingTable, newRoutingTable)
        {:reply, current_state, current_state}
    end

    def terminate(reason, _current_state) do
        IO.inspect reason
        IO.puts "Exiting GenServer ###########------------#######"
    end

    #Client Side Methods
    @server Proj3.Node
    def start_link(init_arg) do
        GenServer.start_link(@server, init_arg)
    end

    def stop(reason) do
        GenServer.stop(@server, {:terminate, reason})
    end

    def fillRoutingTable(hash_pid_map) do
        IO.puts "In node's routing method"
        {:ok, pid_map} = Map.fetch(hash_pid_map, :hashedMapPID)
        {:ok, allHashNames} = Map.fetch(hash_pid_map, :hashNamesOfAllNodes)
        Enum.map(pid_map, fn {hashName, pid} -> updateRoutingTable(pid, hashName, allHashNames) end)
    end

    #Gets called by the function above
    def updateRoutingTable(pid, currentNodeId, allHashNames) do
        GenServer.call(pid, {:updateRoutingTable, currentNodeId, allHashNames})
    end

    def routingTableFunction(routingTable, hashID, hashNames) do
           t = Enum.reduce(hashNames, routingTable, fn {_,x},acc ->
           level= longest_prefix(hashID,x,0,0)
           q= Enum.reduce(0..level, acc, fn y, acc2->
                temp= String.at(x,y)
                {_, rlevel} = Map.fetch(acc, y)
                x = Map.put(rlevel, temp, x)
                _acc2 = Map.put(acc2,y,x)
            end)
            _acc = q
        end)
        t
    end

    def longest_prefix(currentHashID, hashID, i, count) do
        count = cond do
            String.equivalent?(currentHashID, hashID) ->
                (String.length(currentHashID)) - 1
            (String.at(hashID,i)==String.at(currentHashID, i))->
                longest_prefix(currentHashID, hashID, i + 1, count + 1)
            true ->
                count
        end
        count
    end
end