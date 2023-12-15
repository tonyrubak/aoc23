defmodule Aoc23.Day15 do
  def read_data do
    {:ok, content} = File.read("data/day15.txt")

    content
    |> String.splitter(",")
    |> Enum.map(&String.to_charlist/1)
    |> Enum.map(fn list -> Enum.filter(list, fn c -> c != ?\n end) end)
  end

  def read_data2 do
    {:ok, content} = File.read("data/day15.txt")

    content
    |> String.splitter("\n")
    |> Enum.reverse
    |> tl
    |> Enum.reverse
    |> Enum.map(&Aoc23.Day15.Parser.parse/1)
    |> Enum.flat_map(fn {:ok, data, _, _, _, _} -> data end)
  end


  def read_test_data do
    "rn=1,cm-,qp=3,cm=2,qp-,pc=4,ot=9,ab=5,pc-,pc=6,ot=7"
    |> String.splitter(",")
    |> Enum.map(&String.to_charlist/1)
  end

  def read_test_data2 do
    "rn=1,cm-,qp=3,cm=2,qp-,pc=4,ot=9,ab=5,pc-,pc=6,ot=7"
    |> Aoc23.Day15.Parser.parse
    |> then(fn {:ok, data, _, _, _, _} -> data end)
  end

  # List Char -> Int
  # Hashes a list of characters using the following algorithm
  # Initial value: 0
  # Next value = (previous + current) * 17 mod 256
  # Example: rn=1 -> 30
  # Example: cm- -> 253
  def hash(chars) do
   Enum.reduce(chars, 0, fn current, acc ->
      rem((acc + current) * 17, 256)
    end)
  end

  # Map, Operation -> Map
  # Takes an array of boxes and updates the boxes by the given operation
  def process_operation([target, ?=, lens], boxes) do
    location = hash(target)
    box = case Map.fetch(boxes, location) do
      :error -> []
      {:ok, list} -> list
    end
    
    box = case Enum.find_index(box, fn {label, _} -> label == target end) do
      nil -> [{target, lens} | box]
      idx -> List.replace_at(box, idx, {target, lens})
    end

    Map.put(boxes, location, box)
  end
  def process_operation([target, ?-], boxes) do
    location = hash(target)
    box = case Map.fetch(boxes, location) do
      :error -> []
      {:ok, list} -> list
    end

    box = Enum.filter(box, fn {label, _} -> label != target end)
    Map.put(boxes, location, box)
  end

  # List, Int -> Int
  # Takes a box and a box number and returns the total focusing
  # power contained in the box
  def focusing_power(box, box_num) do
    box
    |> Enum.reverse
    |> Enum.with_index
    |> Enum.map(fn {{_, lens}, idx} ->
      (box_num + 1) * (idx + 1) * lens
    end)
    |> Enum.sum
  end

  # Map -> Int
  # Takes a map of boxes and returns the total focusing power
  # of all the boxes the map contains
  def focusing_power(map) do
    map
    |> Map.keys
    |> Enum.map(fn key -> {key, Map.fetch(map, key)} end)
    |> Enum.map(fn {key, {:ok, box}} -> {key, box} end)
    |> Enum.map(fn {key, box} -> focusing_power(box, key) end)
    |> Enum.sum
  end

  def main(data) do
    data
    |> Enum.map(&hash/1)
    |> Enum.sum
  end

  def main2(data) do
    data
    |> Enum.reduce(%{}, &process_operation/2)
    |> focusing_power
  end
end

defmodule Aoc23.Day15.Parser do
  import NimbleParsec

  label = repeat(ascii_char([?a..?z]))
  assign = ascii_char([?=]) |> concat(integer(min: 1))
  remove = ascii_char([?-])
  separator = ascii_char([?,])
  entry = label |> wrap |> concat(choice([assign, remove])) |> wrap

  line = repeat(entry |> concat(optional(ignore(separator))))
  defparsec(:parse, line)
end
