defmodule Aoc23.Day07 do
  def read_data do
    {:ok, content} = File.read("data/day7.txt")
    content
    |> String.split("\n")
    |> Enum.reverse
    |> tl
    |> Enum.reverse
    |> Enum.map(&parse_line/1)
  end

  def process_data(data) do
    data
    |> Enum.sort(&hand_comparator/2)
    |> Enum.reverse
    # |> Enum.map(fn {h, _} -> {h, score_hand2(h)} end)
    |> hands_reducer
  end

  def examine_data(data) do
    data
    |> Enum.filter(fn {hand, _} -> not is_five_of_kind(hand) end)
    |> Enum.filter(fn {hand, _} -> not is_four_of_kind(hand) end)
    |> Enum.filter(fn {hand, _} -> not is_full_house(hand) end)
    |> Enum.filter(fn {hand, _} -> is_three_of_kind(hand) end)
    |> Enum.sort(&hand_comparator/2)
  end

  def parse_line(line) do
    {:ok, data, _, _, _, _} = Aoc23.Day07Parser.parse(line)
    [bid | rest] = Enum.reverse(data)
    {Enum.reverse(rest), bid}
  end

  def read_test_data do
    [{[3,2,10,3,13],765},
     {[10,5,5,0,5], 684},
     {[13,13,6,7,7], 28},
     {[13,10,0,0,10], 220},
     {[12,12,12,0,14], 483}]
  end

  def score_hand(hand) do
    s = MapSet.new(hand)
    case MapSet.size(s) do
      1 -> 7
      2 ->
        c = Enum.at(hand, 0)
        case length(Enum.filter(hand, fn card -> card == c end)) do
          4 -> 6
          1 -> 6
          _ -> 5
        end
      3 ->
        case Enum.max(Map.values(Enum.frequencies(hand))) do
          3 -> 4
          2 -> 3
        end
      4 -> 2
      5 -> 1
    end
  end

  def hands_reducer(hands) do
    for {{_, bid}, i} <- Enum.zip([hands, 1..(length(hands))]), reduce: 0 do
      acc -> acc + bid * i
    end
  end

  def compare_helper({c1, c2}, _) do
    cond do
      c1 > c2 -> {:halt, true}
      c1 < c2 -> {:halt, false}
      true -> {:cont, true}
    end
  end

  def hand_comparator({h1, _}, {h2, _}) do
    cond do
      score_hand2(h1) > score_hand2(h2) -> true
      score_hand2(h1) < score_hand2(h2) -> false
      true -> Enum.reduce_while(Enum.zip([h1, h2]), true, &compare_helper/2)
    end  
  end

  ### Part 2
  def score_hand2(hand) do
    cond do
      is_five_of_kind(hand) -> 7
      is_four_of_kind(hand) -> 6
      is_full_house(hand) -> 5
      is_three_of_kind(hand) -> 4
      is_two_pair(hand) -> 3
      is_pair(hand) -> 2
      true -> 1
    end
  end

  def is_five_of_kind(hand) do
    freq =  Enum.frequencies(hand)
    num_j =
      case Map.get(freq, 0) do
        nil -> 0
        i -> i
      end
    freqs = Map.values(Map.drop(freq,[0]))
    num_j == 5 or Enum.max(freqs) + num_j == 5
  end

  def is_four_of_kind(hand) do
    freq =  Enum.frequencies(hand)
    num_j =
      case Map.get(freq, 0) do
        nil -> 0
        i -> i
      end
    freqs = Map.values(Map.drop(freq,[0]))
    num_j != 5 and Enum.max(freqs) + num_j == 4
  end

  def is_full_house(hand) do
    freq =  Enum.frequencies(hand)
    num_j =
      case Map.get(freq, 0) do
        nil -> 0
        i -> i
      end
    hand
    |> MapSet.new()
    |> MapSet.size()
    |> then(fn size -> (size == 2) or (size == 3 and num_j == 1) end)
  end

  def is_three_of_kind(hand) do
    freq = Enum.frequencies(hand)
    num_j =
      case Map.get(freq, 0) do
        nil -> 0
        i -> i
      end
    freqs = Map.values(Map.drop(freq,[0]))
    Enum.max(freqs) + num_j == 3
  end

  def is_two_pair(hand) do
    hand
    |> MapSet.new()
    |> MapSet.size()
    |> then(fn size -> size == 3 end)
  end    

  def is_pair(hand) do
    freq =  Enum.frequencies(hand)
    num_j =
      case Map.get(freq, 0) do
        nil -> 0
        i -> i
      end
    freqs = Map.values(Map.drop(freq,[0]))
    Enum.max(freqs) + num_j == 2
  end

end

defmodule Aoc23.Day07Parser do
  import NimbleParsec

  whitespace = repeat(ignore(string(" ")))

  two =
    ascii_char([?2])
    |> replace(2)

  three =
    ascii_char([?3])
    |> replace(3)

  four =
    ascii_char([?4])
    |> replace(4)

  five =
    ascii_char([?5])
    |> replace(5)

  six =
    ascii_char([?6])
    |> replace(6)

  seven =
    ascii_char([?7])
    |> replace(7)

  eight =
    ascii_char([?8])
    |> replace(8)

  nine =
    ascii_char([?9])
    |> replace(9)

  ten =
    ascii_char([?T])
    |> replace(10)

  j =
    ascii_char([?J])
    |> replace(0)

  q =
    ascii_char([?Q])
    |> replace(12)

  k =
    ascii_char([?K])
    |> replace(13)

  a =
    ascii_char([?A])
    |> replace(14)

  number =
  whitespace
  |> concat(integer(min: 1))
  |> concat(whitespace)

  card = choice([two, three, four, five, six, seven, eight, nine, ten, j, q, k, a])

  hand = repeat(card)

  line = hand |> concat(number)

  defparsec(:parse, line)
end
