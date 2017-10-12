defmodule Serial do
	def init() do
		Process.flag(:trap_exit, true)
		port = Port.open({:spawn, "priv_dir/serial"}, [{:packet, 2}])
	end

	def open(p, device, speed) do
		Port.command(p, [1, device])
	end
end