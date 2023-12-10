
defmodule Aoc23.Day10 do
  def read_data file do
    {:ok, content} = File.read(file)

    content
    |> String.split("\n")
    |> Enum.reverse
    |> tl
    |> Enum.reverse
    |> Enum.map(&Aoc23.Day10Parser.parse/1)
    |> Enum.map(fn {:ok, line, _, _, _, _} ->
      line
      |> Enum.map(fn direction -> [direction, :exterior] end)
      |> Enum.into(Arrays.new())
    end)
    |> Enum.map(fn line -> Enum.into(line, Arrays.new()) end)
    |> Enum.into(Arrays.new())
  end

  def print_map(map) do
    for {row, y} <- Enum.zip([map, 0..Arrays.size(map) - 1]) do
      str = row
      |> Enum.map(&loc_to_string/1)
      |> Enum.reverse
      |> Enum.reduce(&<>/2)

      IO.puts(str)
    end
  end

  def loc_to_string([dir, int]) do
    case int do
      :pipe -> dir_to_string(dir)
      :interior -> "I"
      :exterior -> dir_to_string(dir)
    end
  end

  def dir_to_string(dir) do
    case dir do
      :ns -> "|"
      :ew -> "-"
      :ne -> "L"
      :nw -> "J"
      :sw -> "7"
      :se -> "F"
      :blank -> "."
      :start -> "S"
    end
  end

  def find_start_point map do
    Enum.reduce_while(map, 0, fn row, acc ->
      case Enum.find_index(row, fn [loc, _] -> loc == :start end) do
        nil -> {:cont, acc + 1}
        n -> {:halt, {n, acc}}
      end
    end)
  end

  def count(map, mode) do
    for row <- map, reduce: 0 do
      acc ->
        in_row = row
        |> Enum.filter(fn [_, int] -> int == mode end)
        |> Enum.count
        acc + in_row
    end
  end

  def neighbors(map, {x,y}) do
    max_y = Arrays.size(map)
    max_x = Arrays.size(map[y])
    n = cond do
      y - 1 < 0 -> nil
      true -> map[y - 1][x]
    end
    s = cond do
      y + 1 >= max_y -> nil
      true -> map[y + 1][x]
    end
    w = cond do
      x - 1 < 0 -> nil
      true -> map[y][x - 1]
    end
    e = cond do
      x + 1 >= max_x -> nil
      true -> map[y][x + 1]
    end

    [n,s,w,e]
    |> Enum.filter(fn item -> item != nil end)
    |> Enum.map(fn [_, val] -> val end)
  end

  def check_neighbors(map, mode) do
    update_map = for {row, y} <- Enum.zip([map, 0..Arrays.size(map) - 1]) do
      update_row = for {[dir, int], x} <- Enum.zip([row, 0..Arrays.size(row) - 1]) do
        cond do
          int == :pipe -> [dir, int]
          Enum.any?(neighbors(map, {x,y}), fn val -> val == mode end) -> [dir, mode]
          true -> [dir, int]
        end
      end
      Arrays.new(update_row)
    end
    Arrays.new(update_map)
  end

  def propagate(map, mode) do
    n = count(map, mode)
    new_map = check_neighbors(map, mode)
    new_n = count(new_map, mode)
    if n == new_n do
      new_map
    else
      propagate(new_map, mode)
    end
  end

  def mark(map, {x,y}, from) do
    max_y = Arrays.size(map)
    max_x = Arrays.size(map[y])

    {mx, my} =
      case from do
        :n -> {x + 1, y}
        :s -> {x - 1, y}
        :e -> {x, y + 1}
        :w -> {x, y - 1}
      end

    map =
      cond do
      my < 0 -> map
      my > max_y - 1 -> map
      mx < 0 -> map
      mx > max_x - 1 -> map
      true -> update_in(map[my][mx], fn [dir, int] ->
        case int do
          :exterior -> [dir, :interior]
          _ -> [dir, int]
        end
      end)
    end
  end

  def traverse_and_mark(map, {x,y}, from) do
    map = mark(map, {x,y}, from)
    map = update_in(map[y][x], fn [dir, _] -> [dir, :pipe] end)

    [current, _] = map[y][x]

    case current do
      :start ->
        {next, to} = {{24, 77}, :n}
        map = mark(map, next, to)
        map
      _ ->
        {next, to} = traverse_helper(map, {x, y}, from)
        map = mark(map, next, to)
        traverse_and_mark(map, next, to)
    end
  end

  def traverse(map, {x1,y1}, from1, {x2,y2}, from2, steps) do
    {next1, to1} = traverse_helper(map, {x1, y1}, from1)
    {next2, to2} = traverse_helper(map, {x2, y2}, from2)

    cond do
      x1 == x2 and y1 == y2 -> steps
      true -> traverse(map, next1, to1, next2, to2, steps + 1)
    end
  end

  def traverse_helper(map, {x, y}, from) do
    [point, _] = map[y][x]
    case {from, point} do
      {:n, :ns} -> {{x, y + 1}, :n}
      {:n, :ne} -> {{x + 1, y}, :w}
      {:n, :nw} -> {{x - 1, y}, :e}
      {:s, :ns} -> {{x, y - 1}, :s}
      {:s, :se} -> {{x + 1, y}, :w}
      {:s, :sw} -> {{x - 1, y}, :e}
      {:e, :ew} -> {{x - 1, y}, :e}
      {:e, :ne} -> {{x, y - 1}, :s}
      {:e, :se} -> {{x, y + 1}, :n}
      {:w, :ew} -> {{x + 1, y}, :w}
      {:w, :nw} -> {{x, y - 1}, :s}
      {:w, :sw} -> {{x, y + 1}, :n}
      end
  end
end

defmodule Aoc23.Day10Parser do
  import NimbleParsec

  vertical = ascii_char([?|]) |> replace(:ns)
  horizontal = ascii_char([?-]) |> replace(:ew)
  ne = ascii_char([?L]) |> replace(:ne)
  nw = ascii_char([?J]) |> replace(:nw)
  sw = ascii_char([?7]) |> replace(:sw)
  se = ascii_char([?F]) |> replace(:se)
  blank = ascii_char([?.]) |> replace(:blank)
  start = ascii_char([?S]) |> replace(:start)

  line =
    choice([vertical, horizontal, ne, nw, sw, se, blank, start])
    |> repeat

  defparsec(:parse, line)
end
