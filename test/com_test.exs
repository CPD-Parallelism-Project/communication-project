defmodule ComTest do
  use ExUnit.Case
  doctest Com

  test "greets the world" do
    assert Com.hello() == :world
  end
end
