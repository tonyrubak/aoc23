defmodule Aoc23.Day08 do
@doc """
You're still riding a camel across Desert Island when you spot a sandstorm quickly approaching. When you turn to warn the Elf, she disappears before your eyes! To be fair, she had just finished warning you about ghosts a few minutes ago.

One of the camel's pouches is labeled "maps" - sure enough, it's full of documents (your puzzle input) about how to navigate the desert. At least, you're pretty sure that's what they are; one of the documents contains a list of left/right instructions, and the rest of the documents seem to describe some kind of network of labeled nodes.

It seems like you're meant to use the left/right instructions to navigate the network. Perhaps if you have the camel follow the same instructions, you can escape the haunted wasteland!

After examining the maps for a bit, two nodes stick out: AAA and ZZZ. You feel like AAA is where you are now, and you have to follow the left/right instructions until you reach ZZZ.

This format defines each node of the network individually. For example:

RL

AAA = (BBB, CCC)
BBB = (DDD, EEE)
CCC = (ZZZ, GGG)
DDD = (DDD, DDD)
EEE = (EEE, EEE)
GGG = (GGG, GGG)
ZZZ = (ZZZ, ZZZ)

Starting with AAA, you need to look up the next element based on the next left/right instruction in your input. In this example, start with AAA and go right (R) by choosing the right element of AAA, CCC. Then, L means to choose the left element of CCC, ZZZ. By following the left/right instructions, you reach ZZZ in 2 steps.

Of course, you might not find ZZZ right away. If you run out of left/right instructions, repeat the whole sequence of instructions as necessary: RL really means RLRLRLRLRLRLRLRL... and so on. For example, here is a situation that takes 6 steps to reach ZZZ:

LLR

AAA = (BBB, BBB)
BBB = (AAA, ZZZ)
ZZZ = (ZZZ, ZZZ)

Starting at AAA, follow the left/right instructions. How many steps are required to reach ZZZ?
"""

  def read_data do
    {:ok, content} = File.read("data/day8.txt")
    data =
      content
      |> String.split("\n")
      |> Enum.reverse
      |> tl
      |> Enum.reverse

    {:ok, instructions, _, _, _, _} = Aoc23.Day08Parser.parseInstructions(hd(data))

    map = for line <- tl(tl(data)), reduce: %{} do
      acc ->
        {:ok, contents, _, _, _, _} = Aoc23.Day08Parser.parseLine(line)
        [source, left, right] = contents
        Map.merge(acc, %{source => {left, right}})
    end

    {instructions, map}
  end

  def read_test_data do
    {:ok, content} = File.read("data/day8t.txt")
    data =
      content
      |> String.split("\n")
      |> Enum.reverse
      |> tl
      |> Enum.reverse

    {:ok, instructions, _, _, _, _} = Aoc23.Day08Parser.parseInstructions(hd(data))

    map = for line <- tl(tl(data)), reduce: %{} do
      acc ->
        {:ok, contents, _, _, _, _} = Aoc23.Day08Parser.parseLine(line)
        [source, left, right] = contents
        Map.merge(acc, %{source => {left, right}})
    end

    {instructions, map}
  end

  def traverse2(data) do
    {instructions, map} = data
    starting_points = Enum.filter(Map.keys(map), fn place -> String.ends_with?(place, "A") end)

    instruction_list = Stream.cycle(instructions)    

    Enum.reduce_while(instruction_list, {starting_points, 0}, fn instruction, acc ->
      {current, step} = acc

      nexts = Enum.map(current,
        fn place ->
          if String.ends_with?(place, "Z") do
            IO.puts "Node: " <> place <> " at time " <> to_string(step)
          end
          {left, right} = Map.get(map, place)
          case instruction do
            :right -> right
            :left -> left
          end
        end)
      
      if Enum.all?(nexts, fn place -> String.ends_with?(place, "Z") end) do
        {:halt, {nexts, step + 1}}
      else
        {:cont, {nexts, step + 1}}
      end
    end)
  end

  def traverse({instruction_list, map}) do
    instruction_list = Stream.cycle(instruction_list)

    Enum.reduce_while(instruction_list, {"AAA", 0} , fn instruction, acc ->
      {current, step} = acc
      {left, right} = Map.get(map, current)
      next = case instruction do
               :right -> right
               :left -> left
             end
      if next == "ZZZ" do
        {:halt, {next, step + 1}}
      else
        {:cont, {next, step + 1}}
      end
    end)
  end
end

defmodule Aoc23.Day08Parser do
  import NimbleParsec

  whitespace = repeat(ignore(string(" ")))

  separator = ignore(whitespace |> concat(string("=")) |> concat(whitespace))

  r = ascii_char([?R]) |> replace(:right)
  l = ascii_char([?L]) |> replace(:left)

  instruction_line = repeat(choice([r,l]))

  map_key = ascii_string([?1..?Z], 3)

  line =
    map_key
    |> concat(whitespace)
    |> concat(separator)
    |> concat(ignore(string("(")))
    |> concat(map_key)
    |> concat(ignore(string(", ")))
    |> concat(map_key)
    |> concat(ignore(string(")")))

  defparsec(:parseLine, line)
  defparsec(:parseInstructions, instruction_line)
end
