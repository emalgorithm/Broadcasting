defmodule PerfectLink do
  def run(app \\ {}, links \\ []) do
    receive do
      {:bind_links, links} -> run(app, links)
      {:bind_app, app} -> run(app, links)
      {:pl_send, msg, dest} ->
        send Enum.at(links, dest), msg
        run(app, links)
      msg ->
        send app, {:pl_deliver, msg}
        run(app, links)
    end
  end
end

defmodule BEB do
  def run(peers, pl, app \\ {}) do
    receive do
      {:bind_app, app} -> run(peers, pl, app)
      {:beb_broadcast, msg} ->
        for p <- peers do
          send pl, {:pl_send, msg, p}
        end
        run(peers, pl, app)
      {:pl_deliver, msg} ->
        send app, {:beb_deliver, msg}
        run(peers, pl, app)
    end
  end
end

defmodule LossyLink do
  def run(id, reliability, app \\ {}, links \\ []) do
    receive do
      {:bind_links, links} -> run(id, reliability, app, links)
      {:bind_app, app} -> run(id, reliability, app, links)
      {:pl_send, msg, dest} ->
        if Enum.random(1..100) <= reliability do
          send Enum.at(links, dest), msg
        end
        run(id, reliability, app, links)
      msg ->
        send app, {:pl_deliver, msg}
        run(id, reliability, app, links)
    end
  end
end
