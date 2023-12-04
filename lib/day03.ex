defmodule Aoc23.Day03 do
@doc """
You and the Elf eventually reach a gondola lift station; he says the gondola lift will take you up to the water source, but this is as far as he can bring you. You go inside.

It doesn't take long to find the gondolas, but there seems to be a problem: they're not moving.

"Aaah!"

You turn around to see a slightly-greasy Elf with a wrench and a look of surprise. "Sorry, I wasn't expecting anyone! The gondola lift isn't working right now; it'll still be a while before I can fix it." You offer to help.

The engineer explains that an engine part seems to be missing from the engine, but nobody can figure out which one. If you can add up all the part numbers in the engine schematic, it should be easy to work out which part is missing.

The engine schematic (your puzzle input) consists of a visual representation of the engine. There are lots of numbers and symbols you don't really understand, but apparently any number adjacent to a symbol, even diagonally, is a "part number" and should be included in your sum. (Periods (.) do not count as a symbol.)

Here is an example engine schematic:

467..114..
...*......
..35..633.
......#...
617*......
.....+.58.
..592.....
......755.
...$.*....
.664.598..

In this schematic, two numbers are not part numbers because they are not adjacent to a symbol: 114 (top right) and 58 (middle right). Every other number is adjacent to a symbol and so is a part number; their sum is 4361.

Of course, the actual engine schematic is much larger. What is the sum of all of the part numbers in the engine schematic?
"""
  def read_data do
    {:ok, content} = File.read("data/day3.txt")
    content
  end

  def process_data(data) do
    map =
      data
      |> String.split("\n")
      |> Enum.reverse
      |> tl
      |> Enum.reverse
      |> Enum.map(&Aoc23.Day03Parser.parse/1)
      |> generate_lines
    symbols = find_symbols(map)

    n = Enum.flat_map(symbols, fn {:symbol, %{x: x, y: y}} -> neighbors(map, x, y) end)
    
    n
    |> Enum.map(fn point -> map_lookup(map, point) end)
    |> MapSet.new
    |> Enum.filter(fn item -> is_number?(item) end)
    |> Enum.map(fn {:number, %{val: val}} -> val end)
    |> Enum.sum
  end

  def process_data2(data) do
    map =
      data
      |> String.split("\n")
      |> Enum.reverse
      |> tl
      |> Enum.reverse
      |> Enum.map(&Aoc23.Day03Parser.parse/1)
      |> generate_lines
    poss_gears = find_gears(map)

    poss_gears
    |> Enum.map(fn {:symbol, %{x: x, y: y}} -> neighbors(map, x, y) end)
    |> Enum.map(fn ns -> Enum.map(ns, fn n -> map_lookup(map, n) end) end)
    |> Enum.map(fn ns -> Enum.filter(ns, &is_number?/1) end)
    |> Enum.map(&MapSet.new/1)
    |> Enum.filter(fn ns -> MapSet.size(ns) == 2 end)
    |> Enum.map(&MapSet.to_list/1)
    |> Enum.map(fn [{:number, %{val: l}}, {:number, %{val: r}}] -> l * r end)
    |> Enum.sum
  end

  def is_number?({:number, _}), do: true
  def is_number?(_), do: false

  def map_lookup(map, {x, y}), do: Enum.at(Enum.at(map, y), x)

  def generate_row({:ok, data, "", %{}, _, _ }, y), do: generate_row(data, 0, y, [])
  def generate_row([], _, _, result), do: Enum.reverse result
  def generate_row([elem | rest], x, y, result) do
    case elem do
      {:blank, _} -> generate_row(rest, x + 1, y, [:blank | result])
      {:number, number} ->
        reps = length(Integer.digits(number))
        generate_row(rest, x + reps, y, List.duplicate({:number, %{:x => x, :y => y, :val => number}}, reps) ++ result)
      {:symbol, symbol} -> generate_row(rest, x + 1, y, [{:symbol, %{:symbol => symbol, :x => x, :y => y}} | result])
    end
  end

  def generate_lines(data), do: generate_lines(data, 0, [])
  def generate_lines([], _, result), do: Enum.reverse result
  def generate_lines([row | rest], y, result) do
    generate_lines(rest, y + 1, [generate_row(row, y) | result])
  end

  def is_symbol?(item) do
    case item do
      {:symbol, _} -> true
      _ -> false
    end
  end

  def is_gear?(item) do
    case item do
      {:symbol, %{:symbol => 42}} -> true
      _ -> false
    end
  end

  def find_symbols(map) do
    map
    |> Enum.flat_map(fn row -> Enum.filter(row, fn item -> is_symbol?(item) end) end)
  end

  def find_gears(map) do
    map
    |> Enum.flat_map(fn row -> Enum.filter(row, fn item -> is_gear?(item) end) end)
  end

  def neighbors(map, x, y) do
    rows = length(map)
    cols = length(Enum.at(map, 0))
    nw = if (x - 1) < 0 or (y - 1) < 0 do nil else {x - 1, y - 1} end
    n = if (y - 1) < 0 do nil else {x, y - 1} end
    ne = if (x + 1) >= cols or (y - 1) < 0 do nil else {x + 1, y - 1} end
    w = if (x - 1) < 0 do nil else {x - 1, y} end
    e = if (x + 1) >= cols do nil else {x + 1, y} end
    sw = if (x - 1) < 0 or (y + 1) >= rows do nil else {x - 1, y + 1} end
    s = if (y + 1) >= rows do nil else {x, y + 1} end
    se = if (x + 1) >= cols or (y + 1) >= rows do nil else {x + 1, y + 1} end

    [nw, n, ne, w, e, sw, s, se]
    |> Enum.filter(fn item -> item != nil end)
  end
end




defmodule Aoc23.Day03Parser do
  import NimbleParsec

  blank =
    ignore(string("."))
    |> tag(:blank)

  number =
    integer(min: 1)
    |> unwrap_and_tag(:number)

  symbol =
    utf8_char([])
    |> unwrap_and_tag(:symbol)

  line = repeat(choice([blank,number,symbol]))

  defparsec(:parse, line)
end
