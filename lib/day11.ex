defmodule Aoc23.Day11 do
  @expansion_factor 1_000_000

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

  def is_blank_line(row), do: Enum.all?(row, fn {_, char} -> char == ?. end)

  def transform_line(row, coord, out_coord) do
    case coord do
      :x -> Enum.map(row, fn {{_, y}, point} -> {{out_coord, y}, point} end)
      :y -> Enum.map(row, fn {{x, _}, point} -> {{x, out_coord}, point} end)
    end
  end

  def expansion_helper(space, coord), do: expansion_helper(space, coord, 1, [])
  def expansion_helper([], _, _, result), do: result
  def expansion_helper([row | rest], coord, out_coord, result) do
    if is_blank_line(row) do
      expansion_helper(rest, coord, out_coord + @expansion_factor,  result)
    else
      output = transform_line(row, coord, out_coord)
      expansion_helper(rest, coord, out_coord + 1, [output | result])
    end
  end

  def expansion(space) do
    space
    |> then(fn it -> expansion_helper(it, :x) end)
    |> Enum.reverse
    |> transpose
    |> then(fn it -> expansion_helper(it, :y) end)
    |> Enum.reverse
    |> transpose
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
    |> expansion
    |> List.flatten
    |> Enum.filter(fn {_, point} -> point == ?\# end)
    |> Enum.map(fn {point, _} -> point end)
    |> reduce_galaxies
  end
end
