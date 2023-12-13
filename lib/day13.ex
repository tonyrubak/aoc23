defmodule Aoc23.Day13 do
  @row_multiplier 100
  
  # Each pattern will be represented by a list of lists of characters
  def read_data do
    {:ok, content} = File.read("data/day13.txt")

    content
    |> String.splitter("\n")
    |> Enum.reverse
    |> tl
    |> Enum.reverse
    |> Enum.map(&String.to_charlist/1)
    |> lists_to_patterns
  end

  def read_test_data do
    """
    #.##..##.
    ..#.##.#.
    ##......#
    ##......#
    ..#.##.#.
    ..##..##.
    #.#.##.#.

    #...##..#
    #....#..#
    ..##..###
    #####.##.
    #####.##.
    ..##..###
    #....#..#
    """
    |> String.splitter("\n")
    |> Enum.reverse
    |> tl
    |> Enum.reverse
    |> Enum.map(&String.to_charlist/1)
    |> lists_to_patterns
  end

  def lists_to_patterns(lists), do: lists_to_patterns(lists, [], [])
  def lists_to_patterns([], working, results), do: Enum.reverse([Enum.reverse(working) | results])
  def lists_to_patterns([head | rest], working, results) do
    case head do
      [] -> lists_to_patterns(rest, [], [Enum.reverse(working) | results])
      _ -> lists_to_patterns(rest, [head | working], results)
    end
  end

  def transpose(rows) do
    rows
    |> List.zip
    |> Enum.map(&Tuple.to_list/1)
  end

  # List (List Char) -> Boolean
  # Determines if a given list of lists is reflective across a line
  # between two rows.
  # To determine vertical reflectivity first transpose the lists.
  def is_reflective?([]), do: true
  def is_reflective?([_]), do: false
  def is_reflective?(pattern) do
    case {hd(pattern), hd(Enum.reverse(pattern))} do
      {x, x} ->
        new_pattern =
          pattern
          |> Enum.reverse
          |> tl
          |> Enum.reverse
          |> tl
        is_reflective?(new_pattern)
      _ -> false
    end
  end

  # List (List Char), Keyword -> Integer
  # Determines the number of lines above a horizontal line of relection.
  def reflect(pattern, remove_from), do: reflect(pattern, remove_from, 0)
  def reflect([], _, _), do: -1
  def reflect(pattern, remove_from, n) do
    case {is_reflective?(pattern), remove_from} do
      {true, :top} -> n + div(length(pattern), 2)
      {true, :end} -> div(length(pattern), 2)
      {false, :top} -> reflect(tl(pattern), :top, n + 1)
      {false, :end} ->
        pattern
        |> Enum.reverse
        |> tl
        |> Enum.reverse
        |> then(fn p -> reflect(p, :end, n) end)
    end
  end

  # List (List (List Char)) -> Integer
  # Gets the reflections for each pattern and adds them up according to the formula
  # We assume that there is only one valid reflection for each pattern
  def count_reflections(patterns) do
    patterns
    |> Enum.map(&get_reflections/1)
    |> Enum.flat_map(fn p -> Enum.filter(p, fn i -> i > 0 end) end)
    |> Enum.sum
  end

  # List (List Char), List Integer -> Integer
  # Gets the reflections for each pattern and compares them to the reflections
  # in the original pattern. Keeps only reflections that were not in the original
  # pattern and adds them up according to the formula
  # We assume that there is only one valid reflection for each pattern
  def count_reflections1(p, old_reflections) do
    get_reflections(p)
    |> Enum.zip_with(old_reflections, fn l, r ->
      if l != r do
        l
      else
        0
      end
    end)
    |> Enum.filter(fn i -> i > 0 end)
    |> Enum.sum
  end

  # List (List Char) -> List Integer
  # Generates the reflection list for the given pattern
  def get_reflections(p) do
    [reflect(p, :top) * 100, reflect(p, :end) * 100, reflect(transpose(p), :top), reflect(transpose(p), :end)]
  end

  # Char -> Char
  # Changes a . to a # or vice-versa
  def fix_smudge(c) do
    case c do
      ?. -> ?\#
      ?\# -> ?.
    end
  end

  # List (List Char), Integer, Integer -> List (List Char)
  # Fixes a smudge in the mirror at the given point
  def fix_mirror(mirror, x, y) do
    mirror
    |> List.update_at(y, fn row -> List.update_at(row, x, &fix_smudge/1) end)
  end

  def find_alternate_reflection(pattern), do: find_alternate_reflection(pattern, get_reflections(pattern), 0, 0)
  def find_alternate_reflection(pattern, old_count, x, y) do
    reflections =
      pattern
      |> then(fn p -> fix_mirror(p, x, y) end)
      |> then(fn p -> count_reflections1(p, old_count) end)
    row_length = length(Enum.at(pattern, 0))
    cond do
      reflections > 0 -> reflections
      x == row_length -> find_alternate_reflection(pattern, old_count, 0, y + 1)
      y == length(pattern) -> :error
      true -> find_alternate_reflection(pattern, old_count, x + 1, y)
    end
  end
end
