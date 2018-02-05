defmodule System1Test do
  use ExUnit.Case
  doctest System1

  test "greets the world" do
    assert System1.hello() == :world
  end
end
