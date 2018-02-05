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
  def run(reliability, app \\ {}, links \\ []) do
    receive do
      {:bind_links, links} -> run(reliability, app, links)
      {:bind_app, app} -> run(reliability, app, links)
      {:pl_send, msg, dest} ->
        if Enum.random(1..100) <= reliability do
          send Enum.at(links, dest), msg
        end
        run(reliability, app, links)
      msg ->
        send app, {:pl_deliver, msg}
        run(reliability, app, links)
    end
  end
end

defmodule RB do
  def run(peers, beb, app \\ {}, delivered \\ []) do
    receive do
      {:bind_app, app} -> run(peers, beb, app)
      {:rb_broadcast, msg} ->
        send beb, {:beb_broadcast, msg}
        run(peers, beb, app, delivered)
      {:beb_deliver, msg} ->
        if !Enum.member?(delivered, msg) do
          send beb, {:beb_broadcast, msg}
          send app, {:rb_deliver, msg}
          run(peers, beb, app, [msg | delivered])
        else
          run(peers, beb, app, delivered)
        end
    end
  end
end
