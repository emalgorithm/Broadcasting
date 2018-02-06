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
  def run(pl, peers \\ [], app \\ {}) do
    receive do
      {:bind_app, app, peers} -> run(pl, peers, app)
      {:beb_broadcast, msg} ->
        for p <- peers do
          send pl, {:pl_send, msg, p}
        end
        run(pl, peers, app)
      {:pl_deliver, msg} ->
        send app, {:beb_deliver, msg}
        run(pl, peers, app)
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
  def run(beb, app \\ {}, delivered \\ []) do
    receive do
      {:bind_app, app} -> run(beb, app)
      {:rb_broadcast, msg} ->
        send beb, {:beb_broadcast, msg}
        run(beb, app, delivered)
      {:beb_deliver, msg} ->
        if !Enum.member?(delivered, msg) do
          send beb, {:beb_broadcast, msg}
          send app, {:rb_deliver, msg}
          run(beb, app, [msg | delivered])
        else
          run(beb, app, delivered)
        end
    end
  end
end
