defmodule Aoc23.Day05 do
@doc """
You take the boat and find the gardener right where you were told he would be: managing a giant "garden" that looks more to you like a farm.

"A water source? Island Island is the water source!" You point out that Snow Island isn't receiving any water.

"Oh, we had to stop the water because we ran out of sand to filter it with! Can't make snow with dirty water. Don't worry, I'm sure we'll get more sand soon; we only turned off the water a few days... weeks... oh no." His face sinks into a look of horrified realization.

"I've been so busy making sure everyone here has food that I completely forgot to check why we stopped getting more sand! There's a ferry leaving soon that is headed over in that direction - it's much faster than your boat. Could you please go check it out?"

You barely have time to agree to this request when he brings up another. "While you wait for the ferry, maybe you can help us with our food production problem. The latest Island Island Almanac just arrived and we're having trouble making sense of it."

The almanac (your puzzle input) lists all of the seeds that need to be planted. It also lists what type of soil to use with each kind of seed, what type of fertilizer to use with each kind of soil, what type of water to use with each kind of fertilizer, and so on. Every type of seed, soil, fertilizer and so on is identified with a number, but numbers are reused by each category - that is, soil 123 and fertilizer 123 aren't necessarily related to each other.

For example:

seeds: 79 14 55 13

seed-to-soil map:
50 98 2
52 50 48

soil-to-fertilizer map:
0 15 37
37 52 2
39 0 15

fertilizer-to-water map:
49 53 8
0 11 42
42 0 7
57 7 4

water-to-light map:
88 18 7
18 25 70

light-to-temperature map:
45 77 23
81 45 19
68 64 13

temperature-to-humidity map:
0 69 1
1 0 69

humidity-to-location map:
60 56 37
56 93 4

The almanac starts by listing which seeds need to be planted: seeds 79, 14, 55, and 13.

The rest of the almanac contains a list of maps which describe how to convert numbers from a source category into numbers in a destination category. That is, the section that starts with seed-to-soil map: describes how to convert a seed number (the source) to a soil number (the destination). This lets the gardener and his team know which soil to use with which seeds, which water to use with which fertilizer, and so on.

Rather than list every source number and its corresponding destination number one by one, the maps describe entire ranges of numbers that can be converted. Each line within a map contains three numbers: the destination range start, the source range start, and the range length.

Consider again the example seed-to-soil map:

50 98 2
52 50 48

The first line has a destination range start of 50, a source range start of 98, and a range length of 2. This line means that the source range starts at 98 and contains two values: 98 and 99. The destination range is the same length, but it starts at 50, so its two values are 50 and 51. With this information, you know that seed number 98 corresponds to soil number 50 and that seed number 99 corresponds to soil number 51.

The second line means that the source range starts at 50 and contains 48 values: 50, 51, ..., 96, 97. This corresponds to a destination range starting at 52 and also containing 48 values: 52, 53, ..., 98, 99. So, seed number 53 corresponds to soil number 55.

Any source numbers that aren't mapped correspond to the same destination number. So, seed number 10 corresponds to soil number 10.

So, the entire list of seed numbers and their corresponding soil numbers looks like this:

seed  soil
0     0
1     1
...   ...
48    48
49    49
50    52
51    53
...   ...
96    98
97    99
98    50
99    51

With this map, you can look up the soil number required for each initial seed number:

    Seed number 79 corresponds to soil number 81.
    Seed number 14 corresponds to soil number 14.
    Seed number 55 corresponds to soil number 57.
    Seed number 13 corresponds to soil number 13.

The gardener and his team want to get started as soon as possible, so they'd like to know the closest location that needs a seed. Using these maps, find the lowest location number that corresponds to any of the initial seeds. To do this, you'll need to convert each seed number through other categories until you can find its corresponding location number. In this example, the corresponding types are:

    Seed 79, soil 81, fertilizer 81, water 81, light 74, temperature 78, humidity 78, location 82.
    Seed 14, soil 14, fertilizer 53, water 49, light 42, temperature 42, humidity 43, location 43.
    Seed 55, soil 57, fertilizer 57, water 53, light 46, temperature 82, humidity 82, location 86.
    Seed 13, soil 13, fertilizer 52, water 41, light 34, temperature 34, humidity 35, location 35.

So, the lowest location number in this example is 35.

What is the lowest location number that corresponds to any of the initial seed numbers?
"""
  def read_data do
    {:ok, content} = File.read("data/day5.txt")
    content
    |> String.split("\n")
    |> Enum.reverse
    |> tl
    |> Enum.reverse
  end

  def read_test_data do
    {:ok, content} = File.read("data/day5t.txt")
    content
    |> String.split("\n")
    |> Enum.reverse
    |> tl
    |> Enum.reverse
  end

  def process_data(data) do
    {:ok, seeds, _, _, _, _} =
      data
      |> hd
      |> Aoc23.Day05Parser.parseSeeds

    data = tl(tl(data))

    stages = generate_stages(data, [])

    pairs = gen_pairs(seeds)

    # Solution using reverse transforms. Requires stages be lists
    # Enum.reduce_while(Stream.iterate(0, fn n -> n + 1 end), {pairs, stages}, &process_possible_seed/2)

    # Solution using filled stages. Requires stages be arrays
    pairs
    |> Enum.flat_map(fn pair -> progress_seed(pair, stages) end)
    |> Enum.map(fn {k, _} -> k end)
    |> Enum.min
  end

  ### The correct solution
  def progress_seed(seed, stages) do
    for stage <- stages, reduce: [seed] do
      acc -> Enum.flat_map(acc, fn item -> progress_stage(item, stage,[]) end)
    end
  end

  def progress_stage({key, len}, stage, result) do
    {src, dest, stage_len} = lookup(stage, {key, len})
    if (src + stage_len) >= (key + len) do
      [{dest + (key - src), len} | result]
    else
      consumed_len = (src + stage_len) - key
      progress_stage({key + consumed_len, len - consumed_len}, stage, [{dest + (key - src), consumed_len} | result])
    end
  end

  # Binary search to find the correct transform for a key in a stage
  def lookup(stage, seed), do: lookup(stage, seed, 0, Arrays.size(stage) - 1)
  def lookup(stage, {seed_low, seed_len}, l, r) do
    if l > r do
      {seed_low, seed_low, seed_len}
    else
      m = div(l + r, 2)
      {src, _, stage_len} = stage[m]
      cond do
        src + stage_len <= seed_low -> lookup(stage, {seed_low, seed_len}, m + 1, r)
        src > seed_low -> lookup(stage, {seed_low, seed_len}, l, m - 1)
        true -> stage[m]
      end
    end
  end
  ###

  ### Stage generation
  def generate_stages(nil, result), do: Enum.reverse(result)
  def generate_stages(data, result) do
    {stage, remaining} = process_stage(data)
    generate_stages(remaining, [stage | result])
  end

  def gen_pairs(seeds), do: gen_pairs(seeds, [])
  def gen_pairs([], result), do: result
  def gen_pairs([l | [len | rest]], result), do: gen_pairs(rest, [{l, len} | result])

  def fill_stage(stage), do: fill_stage(stage, 0, [])
  def fill_stage([], _, result), do: result
  def fill_stage([{s, d, l} | rest], current, result) do
    if (current < s) do
      fill_stage(rest, s + l, [{s,d,l} | [{current, current, s - current} | result]])
    else
      fill_stage(rest, s + l, [{s,d,l} | result])
    end
  end

  def finalize_stage(stage, data) do
    stage
    |> Enum.sort(fn {s1, _, _}, {s2, _, _} -> s1 <= s2 end)
    |> fill_stage
    |> Enum.reverse
    |> Enum.into(Arrays.new())
    |> then(fn arr -> {arr, data} end)
  end

  def process_stage(data), do: process_stage(tl(data), [])
  def process_stage([], result), do: finalize_stage(result, nil)
  def process_stage([line | rest], result) do
    case line do
      "" -> 
        finalize_stage(result, rest)
      _ ->
        {:ok, parsed_line, _, _, _, _} = Aoc23.Day05Parser.parseMap line
        process_stage(rest, [transform_line(parsed_line) | result])
    end
  end
  
  def transform_line([dest, source, len]), do: {source, dest, len}
  ###

  ### The solution when we try to search for a location that turns into a seed that exists
  ### This works, but is kind of slow (a minute or so runtime)
  def process_possible_seed(location, {seeds, stages}) do
    seed = Enum.reduce(stages, location, &reverse_stage/2)
    if is_seed(seed, seeds) do
      {:halt, location}
    else
      {:cont, {seeds, stages}}
    end
  end

  def is_seed(_, []), do: false
  def is_seed(poss_seed, [{low, len} | rest]) do
    if (poss_seed >= low) and (poss_seed < low + len) do
      true
    else
      is_seed(poss_seed, rest)
    end
  end

  def reverse_stage([], output), do: output
  def reverse_stage([{source, dest, len} | rest], output) do
    if (output >= dest) and (output < dest + len) do
      source + (output - dest)
    else
      reverse_stage(rest, output)
    end
  end
  ###
end

defmodule Aoc23.Day05Parser do
  import NimbleParsec

  whitespace =
    repeat(ignore(string(" ")))

  number =
  whitespace
  |> concat(integer(min: 1))
  |> concat(whitespace)

  seeds =
  ignore(string("seeds:"))
  |> concat(repeat(number))

  map =
    number
    |> concat(number)
    |> concat(number)

  defparsec(:parseSeeds, seeds)
  defparsec(:parseMap, map)
end
