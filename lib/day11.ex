defmodule Aoc23.Day11 do
  def read_data do
    {:ok, content} = File.read("data/day11.txt")

    content
    |> String.split("\n")
    |> Enum.map(&String.to_charlist/1)
    |> Enum.reverse
    |> tl
    |> Enum.reverse
  end

  def read_test_data do
    data = """
    ...#......
    .......#..
    #.........
    ..........
    ......#...
    .#........
    .........#
    ..........
    .......#..
    #...#.....
    """

    data
    |> String.split("\n")
    |> Enum.map(&String.to_charlist/1)
    |> Enum.reverse
    |> tl
    |> Enum.reverse
  end

  def transpose(rows) do
    rows
    |> List.zip
    |> Enum.map(&Tuple.to_list/1)
  end

  def expansion_helper(space, coord, factor), do: expansion_helper(space, coord, 1, factor, [])
  def expansion_helper([], _, _, _, result), do: result
  def expansion_helper([row | rest], coord, out_coord, factor, result) do
    case Enum.all?(row, fn {{_, _}, char} -> char == ?. end) do
      true -> expansion_helper(rest, coord, out_coord + factor, factor, result)
      false ->
        output =
          case coord do
            :x -> Enum.map(row, fn {{_, y}, point} -> {{out_coord, y}, point} end)
            :y -> Enum.map(row, fn {{x, _}, point} -> {{x, out_coord}, point} end)
          end
        expansion_helper(rest, coord, out_coord + 1, factor, [output | result])
    end
  end

  def expansion(space, factor) do
    space
    |> then(fn it -> expansion_helper(it, :x, factor) end)
    |> Enum.reverse
    |> transpose
    |> then(fn it -> expansion_helper(it, :y, factor) end)
    |> Enum.reverse
    |> transpose
  end

  def find_galaxies space do
    for {row, y} <- List.zip([space, Enum.to_list(1..length(space))]), reduce: [] do
      acc ->
        galaxies = for {point, x} <- List.zip([row, Enum.to_list(1..length(row))]), reduce: [] do
            acc ->
              case point do
                ?\# -> [{x,y} | acc]
                _ -> acc
              end
          end
        acc ++ Enum.reverse(galaxies)
    end
  end

  def taxicab_metric({x1,y1}, {x2,y2}) do
    abs(x1-x2)+abs(y1-y2)
  end

  def reduce_galaxies(gals), do: reduce_galaxies(gals, 0)
  def reduce_galaxies([], res), do: res
  def reduce_galaxies([gal | gals], res) do
    total =
      gals
      |> Enum.map(fn g ->
          taxicab_metric(g, gal)
        end)
      |> Enum.sum
    reduce_galaxies(gals, res + total)
  end

  def gal_to_string({x,y}), do: "{" <> to_string(x) <> "," <> to_string(y) <> "}"

  def label_galaxy(galaxy) do
    for {row, y} <- Enum.zip([galaxy, Enum.to_list(1..length(galaxy))]) do
      for {point, x} <- Enum.zip([row, Enum.to_list(1..length(row))]) do
        {{x, y}, point}
      end
    end
  end

  def process_data data do
    data
    |> label_galaxy
    |> then(&(expansion(&1, 1_000_000)))
    |> List.flatten
    |> Enum.filter(fn {_, point} -> point == ?\# end)
    |> Enum.map(fn {point, _} -> point end)
    |> reduce_galaxies
  end
end
