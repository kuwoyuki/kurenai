defmodule KurenaiTest do
  use ExUnit.Case
  doctest Kurenai

  test "greets the world" do
    assert Kurenai.hello() == :world
  end
end
