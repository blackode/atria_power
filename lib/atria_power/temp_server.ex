defmodule AtriaPower.TempServer do
  use GenServer

  # Client API Calls
  def start_link(_args) do
    GenServer.start_link(__MODULE__, %{status: "disabled"}, name: __MODULE__)
  end

  def enable() do
    GenServer.call(__MODULE__, :enable)
  end

  def disable() do
    GenServer.call(__MODULE__, :disable)
  end

  # Server API Calls
  def init(state) do
    {:ok, state}
  end

  def handle_call(:enable, _from, state) do
    # Schedule packet to be sent at some point
    schedule_packet()
    {:reply, {:ok, "enabled"}, %{state | status: "enabled"}}
  end

  def handle_call(:disable, _form, state) do
    {:reply, {:ok, "disabled"}, %{state | status: "disabled"}}
  end

  def handle_info(:send_packet, state) do
    timestamp = DateTime.utc_now() |> DateTime.to_unix()
    reading = AtriaPower.RandomTemparature.generate()
    packet = %{timestamp: timestamp, reading: reading, sensor_type: "temp_sensor"}

    process_packet(packet)

    if state.status == "enabled" do
      schedule_packet()
    end

    {:noreply, state}
  end

  # Private Functions
  defp schedule_packet() do
    Process.send_after(self(), :send_packet, 5000)
  end

  defp process_packet(packet) do
    url = "http://localhost:4000/data_packets"
    request_data = Jason.encode!(packet)
    headers = [ContentType: "application/json"]

    case HTTPoison.request(
           :post,
           url,
           request_data,
           headers,
           []
         ) do
      {:ok, response} ->
        IO.inspect(response, label: "The response")
    end
  end
end