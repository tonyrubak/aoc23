defmodule Aoc23.Day12 do
  def read_data do
    {:ok, content} = File.read("data/day12.txt")

    content
    |> String.splitter("\n")
    |> Enum.reverse
    |> tl
    |> Enum.reverse
  end

  def read_test_data do
    """
    ???.### 1,1,3
    .??..??...?##. 1,1,3
    ?#?#?#?#?#?#?#? 1,3,1,6
    ????.#...#... 4,1,1
    ????.######..#####. 1,6,5
    ?###???????? 3,2,1
    """
    |> String.splitter("\n")
    |> Enum.reverse
    |> tl
    |> Enum.reverse
  end

  def process_data rows do
    rows
    |> Enum.map(&Aoc23.Day12.Row.from_string/1)
    |> Enum.map(&Aoc23.Day12.Row.unfold/1)
    |> Enum.map(&Aoc23.Day12.Row.count_possibilities/1)
    |> Enum.sum
  end  
end

defmodule Aoc23.Day12.Row do
  use Memoize
  defstruct line: [], broken: []
  defmemo count_possibilities(%{line: line, broken: broken}) do
    count_possibilities(%Aoc23.Day12.Row{line: Enum.reverse(line), broken: Enum.reverse(broken)}, 0)
  end
  defmemo count_possibilities(
        %{line: line, broken: broken} = row,
        working
      ) do
    cond do
      broken == [] and Enum.any?(line, fn it -> it == :broken end) ->
        0
      broken == [] ->
        1
      hd(broken) == working ->
        case line do
          [:broken | _] ->
            0
          [:unknown | _] ->
            count_possibilities(%{line: [:operational | tl(line)], broken: broken}, working) + count_possibilities(%{line: [:broken | tl(line)], broken: broken}, working)
          _ ->
            count_possibilities(%{line: line, broken: tl(broken)}, 0)
        end
      line == [] ->
        0
      hd(line) == :unknown ->
        count_possibilities(%{row | line: [:operational | tl(line)]}, working) + count_possibilities(%{row | line: [:broken | tl(line)]}, working)
      hd(line) == :broken -> count_possibilities(%{line: tl(line), broken: broken}, working + 1)
      hd(line) == :operational and working != 0 ->
        0
      hd(line) == :operational -> count_possibilities(%{line: tl(line), broken: broken}, 0)
    end
  end

  def from_string(str) do
    {:ok, [line, broken], _, _, _, _} = Aoc23.Day12.Parser.parse(str)
    %{:line => line, :broken => broken}
  end

  def row_to_string(%{line: line}) do
    Enum.map(line, fn it ->
      case it do
        :broken -> ?\#
        :unknown -> ??
        :operational -> ?.
      end
    end) |> to_string
  end

  def unfold(%{line: line, broken: broken}) do
    line =
      line
      |> List.duplicate(5)
      |> Enum.intersperse(:unknown)
      |> List.flatten

    broken =
      broken
      |> List.duplicate(5)
      |> List.flatten

    %{:line => line, :broken => broken}
  end
end

defmodule Aoc23.Day12.Parser do
  import NimbleParsec

  unknown = ascii_char([??]) |> replace(:unknown)
  operational = ascii_char([?.]) |> replace(:operational)
  broken = ascii_char([?\#]) |> replace(:broken)

  status = repeat(choice([unknown, operational, broken])) |> wrap

  number = integer(min: 1) |> ignore(optional(ascii_char([?,])))
  counts = repeat(number) |> wrap

  line =
    status
    |> concat(ignore(string(" ")))
    |> concat(counts)

  defparsec(:parse, line)
end
