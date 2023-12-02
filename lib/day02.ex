defmodule Aoc23.Day02 do
  def read_data do
    {:ok, content} = File.read("data/day2.txt")
    content
  end

  def process_data(data) do
    data
    |> String.split("\n")
    |> Enum.reverse
    |> tl
    |> Enum.reverse
    |> Enum.map(&Aoc23.Day02Parser.parse/1)
    |> Enum.map(fn line -> elem(line,1) end)
    |> Enum.map(&process_line/1)
    |> Enum.sum
  end

  def process_line(line) do
    id = elem(Enum.at(line, 0), 1)
    maxes = Enum.reduce(tl(line), %{:blue => 0, :green => 0, :red => 0}, &reduce_sample/2)
    case maxes do
      %{blue: blue, green: green, red: red} when red <= 12 and green <= 13 and blue <= 14 -> id
      _ -> 0
    end
  end

  def process_data2(data) do
    data
    |> String.split("\n")
    |> Enum.reverse
    |> tl
    |> Enum.reverse
    |> Enum.map(&Aoc23.Day02Parser.parse/1)
    |> Enum.map(fn line -> elem(line,1) end)
    |> Enum.map(&process_line2/1)
    |> Enum.sum
  end

  def process_line2(line) do
    id = elem(Enum.at(line, 0), 1)
    maxes = Enum.reduce(tl(line), %{:blue => 0, :green => 0, :red => 0}, &reduce_sample/2)
    maxes.blue * maxes.red * maxes.green
  end

  def reduce_sample({:sample, new_sample}, %{blue: old_blue, red: old_red, green: old_green}) do
    blue =
      case Keyword.fetch(new_sample, :blue) do
        {:ok, n} -> n
        :error -> 0
      end
    red =
      case Keyword.fetch(new_sample, :red) do
        {:ok, n} -> n
        :error -> 0
      end
    green =
      case Keyword.fetch(new_sample, :green) do
        {:ok, n} -> n
        :error -> 0
      end
    %{:blue => max(old_blue, blue), :red => max(old_red, red), :green => max(old_green, green)}
  end
end

defmodule Aoc23.Day02Parser do
  import NimbleParsec

  game_id =
    ignore(string("Game "))
    |> integer(min: 1)
    |> ignore(string(": "))
    |> unwrap_and_tag(:id)

  blue =
    integer(min: 1)
    |> ignore(string(" blue"))
    |> ignore(optional(string(",")))
    |> unwrap_and_tag(:blue)

  red =
    integer(min: 1)
    |> ignore(string(" red"))
    |> ignore(optional(string(",")))
    |> unwrap_and_tag(:red)

  green =
    integer(min: 1)
    |> ignore(string(" green"))
    |> ignore(optional(string(",")))
    |> unwrap_and_tag(:green)

  sample =
    choice([blue, red, green])
    |> concat(optional(concat(ignore(string(" ")), choice([blue, red, green]))))
    |> concat(optional(concat(ignore(string(" ")), choice([blue, red, green]))))
    |> optional(ignore(string("; ")))
    |> tag(:sample)

  game =
    game_id
    |> repeat(sample)


  defparsec(:parse, game)
end
