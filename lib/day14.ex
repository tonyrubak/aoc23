defmodule Aoc23.Day14 do
  use Memoize
  def read_data do
    {:ok, content} = File.read("data/day14.txt")
    
    content
    |> String.splitter("\n")
    |> Enum.reverse
    |> tl
    |> Enum.reverse
    |> Enum.map(&Aoc23.Day14.Parser.parse/1)
    |> Enum.map(fn {:ok, data, _, _, _, _} -> data end)
    |> Enum.map(&Arrays.new/1)
    |> Arrays.new
  end

  def read_test_data do
    """
    O....#....
    O.OO#....#
    .....##...
    OO.#O....O
    .O.....O#.
    O.#..O.#.#
    ..O..#O..O
    .......O..
    #....###..
    #OO..#....
    """
    |> String.splitter("\n")
    |> Enum.reverse
    |> tl
    |> Enum.reverse
    |> Enum.map(&Aoc23.Day14.Parser.parse/1)
    |> Enum.map(fn {:ok, data, _, _, _, _} -> data end)
    |> Enum.map(&Arrays.new/1)
    |> Arrays.new
  end

  def process_data data do
    data |> roll_north |> load
  end

  # List (List Symbol) -> Array (Array Symbol)
  # Turns a list of lists into a 2D array
  def lists_to_array list do
    for row <- list, reduce: Arrays.new() do
      acc -> Arrays.append(acc, Arrays.new(row))
    end
  end

  def transpose(rows) do
    rows
    |> Enum.zip
    |> Enum.map(&Tuple.to_list/1)
    |> Enum.map(&Arrays.new/1)
    |> Arrays.new
  end

  # Array (Array Symbol), Int -> Array (Array Symbol)
  # Moves all round stones as far north as possible
  def roll_north(array) do
    for i <- 1..Arrays.size(array) - 1, reduce: array do
      acc -> roll_north(acc, i)
    end
  end
  def roll_north(array, end_at) do
    for {j, row} <- Enum.with_index(Arrays.slice(array, 1..-end_at), fn elem, idx -> {idx + 1, elem} end), reduce: array do
      acc ->
        should_replace = Enum.map(Enum.with_index(row, fn elem, idx -> {idx, elem} end),
          fn {i, item} -> item == :round and acc[j - 1][i] == :empty end)
        row_above =
          Enum.zip([acc[j - 1], should_replace])
          |> Enum.map(fn {original, replace} -> if replace do :round else original end end)
          |> Arrays.new
        this_row =
          Enum.zip([acc[j], should_replace])
          |> Enum.map(fn {original, replace} -> if replace do :empty else original end end)
          |> Arrays.new
        tmp = put_in(acc[j - 1], row_above)
        put_in(tmp[j], this_row)
    end
  end

  def roll_south(array) do
    array
    |> Enum.reverse
    |> Arrays.new
    |> roll_north
    |> Enum.reverse
    |> Arrays.new
  end

  def roll_west(array) do
    array
    |> transpose
    |> roll_north
    |> transpose
  end

  def roll_east(array) do
    array
    |> transpose
    |> Enum.reverse
    |> Arrays.new
    |> roll_north
    |> Enum.reverse
    |> Arrays.new
    |> transpose
  end

  defmemo cycle(array) do
    array
    |> roll_north
    |> roll_west
    |> roll_south
    |> roll_east
  end

  def find_cycle_start(array) do
    Enum.reduce_while(Stream.iterate(1, &(&1 + 1)), {array, %{}}, fn i, {acc, table} ->
      IO.puts "Iteration: " <> to_string(i)
      if Map.has_key?(table, acc) do
        {:halt, {i, acc}}
      else
        table = Map.put(table, acc, true)
        acc = cycle(acc)
        {:cont, {acc, table}}
      end
    end)
  end

  def find_cycle_length(array) do
    Enum.reduce_while(Stream.iterate(1, &(&1 + 1)), array, fn i, acc ->
      tmp = cycle(acc)
      if tmp == array do
        {:halt, i}
      else
       {:cont, tmp}
      end
    end)
  end

  def process_data2(data, iterations) do
    {start_idx, start_arr } =
      data |> find_cycle_start
    cycle_length = find_cycle_length(start_arr)
    iterations_rem = rem(iterations - start_idx, cycle_length)
    end_arr = for _ <- 1..iterations_rem+1, reduce: start_arr do
      acc -> cycle(acc)
    end
    load(end_arr)
  end


  # Array (Array Symbol) -> Int
  # Calculate the total load of the round rocks
  def load(array) do
    for {j, row} <- Enum.with_index(array, fn elem, idx -> {Arrays.size(array) - idx, elem} end), reduce: 0 do
      acc ->
        row_load =
          row
          |> Enum.filter(fn item -> item == :round end)
          |> Enum.count
          |> then(fn c -> c * j end)
        acc + row_load
    end
  end
end

defmodule Aoc23.Day14.Parser do
  import NimbleParsec

  empty = string(".") |> replace(:empty)
  round = string("O") |> replace(:round)
  square = string("#") |> replace(:square)

  line = repeat(choice([empty, round, square]))

  defparsec(:parse, line)
end
