defmodule SortedMapTest do
  use ExUnit.Case
  doctest SortedMap

  test "Enum.to_list/1 returns the a sorted list of the key value tuples" do
    assert Enum.to_list(SortedMap.new(a: 1, b: 2, d: 5, c: 4)) == [a: 1, b: 2, d: 5, c: 4]
  end

  test "Enum.into/2 appends keys at the end" do
    assert Enum.into([c: 3, d: 4], SortedMap.new(a: 1, b: 2)) ==
             SortedMap.new(a: 1, b: 2, c: 3, d: 4)
  end

  test "Enum.into/2 appends overrides keys and does not update their position" do
    assert Enum.into([c: 3, a: 4], SortedMap.new(a: 1, b: 2)) == SortedMap.new(a: 4, b: 2, c: 3)
  end

  test "Enum.concat/2 appends keys to " do
    assert Enum.concat(SortedMap.new(a: 1, b: 2), c: 3, d: 4) == [a: 1, b: 2, c: 3, d: 4]

    assert Enum.concat(SortedMap.new(a: 1, b: 2), SortedMap.new(c: 3, d: 4)) == [
             a: 1,
             b: 2,
             c: 3,
             d: 4
           ]
  end
end
