defmodule Aoc23.Day04 do
  def read_data do
    {:ok, content} = File.read("data/day4.txt")
    content
    |> String.split("\n")
    |> Enum.reverse
    |> tl
    |> Enum.reverse
  end

  def process_data(data) do
    data
    |> Enum.map(&Aoc23.Day04Parser.parse/1)
    |> Enum.map(&score_card/1)
    |> Enum.sum
  end

  def score_card({:ok, [_, {:winning, winning}, {:ours, ours}], _, _, _, _}) do
    MapSet.intersection(MapSet.new(winning), MapSet.new(ours))
    |> MapSet.size
    |> then(fn count -> count - 1 end)
    |> then(fn adj_count -> if adj_count >= 0 do 2 ** adj_count else 0 end end)
  end

  def process_data2(data) do
    cards =
      data
      |> Enum.map(&Aoc23.Day04Parser.parse/1)

    num_cards = length(cards)

    cards_won_cards = for {card, n} <- Enum.zip(cards, 1..num_cards), reduce: [] do
      acc -> [{n, score_card2(card, n)} | acc]
    end
    
    card_winnings =
      cards_won_cards
      |> Enum.map(fn card -> only_existing_cards(card, num_cards) end)
      |> Enum.into(%{})

    reduce_cards(Enum.to_list(1..num_cards), card_winnings)
    |> Map.values
    |> Enum.sum
  end

  def reduce_cards(cards, winning), do: reduce_cards(cards, winning, %{})
  def reduce_cards([], _, result), do: result
  def reduce_cards([card | rest], winning, result) do
    {result, copies} = case Map.get(result, card) do
      nil -> {Map.put(result, card, 1), 1}
      n -> {result, n}
    end

    won = case Map.get(winning, card) do
      nil -> []
      list -> list
    end

    new_result = for won_card <- won, reduce: result do
      acc -> Map.update(acc, won_card, 1 + copies, fn val -> val + copies end)
    end
    reduce_cards(rest, winning, new_result)
  end

  def only_existing_cards({card, winnings}, max_card) do
    winnings = Enum.filter(winnings, fn n -> n <= max_card end)
    {card, winnings}
  end

  def score_card2({:ok, [_, {:winning, winning}, {:ours, ours}], _, _, _, _}, i) do
    MapSet.intersection(MapSet.new(winning), MapSet.new(ours))
    |> MapSet.size
    |> then(fn n -> if n > 0 do Enum.to_list((i+1)..(i+n)) else [] end end)
  end
end




defmodule Aoc23.Day04Parser do
  import NimbleParsec

  separator =
    ignore(string("|"))
    |> replace(:sep)

  whitespace = repeat(string(" "))

  winning_numbers = 
    repeat(concat(integer(min: 1), ignore(whitespace)))
    |> tag(:winning)

  our_numbers = 
    repeat(concat(integer(min: 1), ignore(whitespace)))
    |> tag(:ours)

  card =
    ignore(string("Card"))
    |> concat(ignore(whitespace))
    |> concat(unwrap_and_tag(integer(min: 1), :id))
    |> concat(ignore(string(":")))
    |> concat(ignore(whitespace))
    |> concat(winning_numbers)
    |> concat(ignore(separator))
    |> concat(ignore(whitespace))
    |> concat(our_numbers)
  
  defparsec(:parse, card)
end
