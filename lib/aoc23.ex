defmodule Aoc23 do
  @moduledoc """
  Documentation for `Aoc23`.
  """

  @doc """
  Hello world.

  ## Examples

      iex> Aoc23.hello()
      :world

  """
  def hello do
    :world
  end
end


defmodule Aoc23.Day1 do
@doc """
Something is wrong with global snow production, and you've been selected to take a look. The Elves have even given you a map; on it, they've used stars to mark the top fifty locations that are likely to be having problems.

You've been doing this long enough to know that to restore snow operations, you need to check all fifty stars by December 25th.

Collect stars by solving puzzles. Two puzzles will be made available on each day in the Advent calendar; the second puzzle is unlocked when you complete the first. Each puzzle grants one star. Good luck!

You try to ask why they can't just use a weather machine ("not powerful enough") and where they're even sending you ("the sky") and why your map looks mostly blank ("you sure ask a lot of questions") and hang on did you just say the sky ("of course, where do you think snow comes from") when you realize that the Elves are already loading you into a trebuchet ("please hold still, we need to strap you in").

As they're making the final adjustments, they discover that their calibration document (your puzzle input) has been amended by a very young Elf who was apparently just excited to show off her art skills. Consequently, the Elves are having trouble reading the values on the document.

The newly-improved calibration document consists of lines of text; each line originally contained a specific calibration value that the Elves now need to recover. On each line, the calibration value can be found by combining the first digit and the last digit (in that order) to form a single two-digit number.
"""

  def read_data do
    {:ok, content} = File.read("data/day1.txt")
    content
  end

  def process_line(line) do
    nums =
    line
    |> String.to_charlist()
    |> Enum.filter(fn char -> char >= 0x30 end)
    |> Enum.filter(fn char -> char <= 0x39 end)
    last = Kernel.length(nums) - 1
    digits = [Enum.at(nums, 0), Enum.at(nums, last)]
    num_str = List.to_string(digits)
    {result, ""} = Integer.parse(num_str)
    result
  end

  def process_data(data) do
    data
    |> String.split("\n")
    |> Enum.reverse()
    |> tl()
    |> Enum.reverse()
    |> Enum.map(&process_line/1)
    |> Enum.sum()
  end

  def process_data2(data) do
    data =
      data
      |> String.split("\n")
      |> Enum.reverse()
      |> tl()
      |> Enum.reverse()
      |> Enum.map(&process_data_helper/1)
      |> Enum.sum()
  end

  def process_data_helper(line) do
    scanner = %{:str => line, :collector => %{:first => nil, :last => nil}}
    parse(scanner)
  end

  def add_symbol(collector, symbol) do
    if collector.first == nil do
      %{collector | first: symbol, last: symbol}
    else
      %{collector | last: symbol}
    end
  end

  def get_result(%{first: first, last: last}), do: 10 * first + last
  
  def check_word(str, word, len) do
    str
    |> String.slice(1, len)
    |> String.starts_with?(word)
  end

  def parse(scanner = %{:str => "", collector: collector}), do: get_result(collector)
  def parse(scanner = %{str: str, collector: collector}) do
    len = String.length(str)
    collector =
      case String.first(str) do
        "e" ->
          if check_word(str, "ight", 4) do
            add_symbol(collector, 8)
          else
            collector
          end
        "f" ->
          cond do
            check_word(str, "ive", 3) ->
              add_symbol(collector, 5)
            check_word(str, "our", 3) ->
              add_symbol(collector, 4)
            true ->
              collector
          end
        "n" ->
          if check_word(str, "ine", 3) do
            add_symbol(collector, 9)
          else
            collector
          end
        "o" ->
          if check_word(str, "ne", 2) do
            add_symbol(collector, 1)
          else
            collector
          end
        "s" ->
          cond do
            check_word(str, "even", 4) ->
              add_symbol(collector, 7)
            check_word(str, "ix", 2) ->
              add_symbol(collector, 6)
            true->
              collector
          end
        "t" ->
          cond do
            check_word(str, "hree", 4) ->
              add_symbol(collector, 3)
            check_word(str, "wo", 2) ->
              add_symbol(collector, 2)
            true ->
              collector
          end
        _ ->
          case Integer.parse(String.first(str)) do
            {digit, ""} -> add_symbol(collector, digit)
            :error -> collector
          end
      end
    next_str = String.slice(str, 1, len - 1)
    parse(%{scanner | str: next_str, collector: collector})
  end
end

