defmodule Aoc23.Day16 do
  def read_test_data do
    """
    .|...\\....
    |.-.\\.....
    .....|-...
    ........|.
    ..........
    .........\
    ..../.\\\\..
    .-.-/..|..
    .|....-|.\
    ..//.|....
    """
    |> String.splitter("\n")
    |> Enum.map(&String.to_charlist/1)
    |> Enum.map(fn it -> Arrays.new(it) end)
    |> Arrays.new
  end

  # Velocity, Mirror -> Velocity
  # Takes a velocity and reflects it according to the kind of mirror it encounters
  # Example: {1, 0}, ?\/ -> {0, 1}
  # Example: {0, -1}, ?\\ -> {1, 0}
  def reflect({x, y}, mirror) do
    case mirror do
      ?\/ -> {y, x}
      ?\\ -> {-y, -x}
    end
  end

  # Velocity, Splitter -> List Velocity
  # Takes a velocity and splits it according the the kind of splitter it encounters
  # Example: {1, 0}, ?| -> [{0, -1}, {0, 1}]
  # Example: {0, -1}, ?| -> [{0, -1}]
  def split({vx,vy}, splitter) do
    vx_n = abs(vx)
    vy_n = abs(vy)
    case splitter do
      ?| when vx_n > 0 -> [{0, -1}, {0, 1}]
      ?- when vy_n > 0 -> [{-1, 0}, {1, 0}]
      _ -> [{vx, vy}]
    end
  end

  # Char -> Bool
  # Takes a map symbol and determines if the symbol is a mirror
  def is_mirror?(char) do
    case char do
      ?\/ -> true
      ?\\ -> true
      _ -> false
    end
  end

  # Char -> Bool
  # Takes a map symbol and dtermines if the symbol is a splitter
  def is_splitter?(char) do
    case char do
      ?| -> true
      ?- -> true
      _ -> false
    end
  end

  # Particle, Map -> Beam
  # Takes a particle and a map and processes a physics timestep
  def timestep({{x, y}, {vx, vy}}, map) do
    max_y = Arrays.size(map) - 1
    max_x = Arrays.size(map[0]) - 1
    {x, y} = {x + vx, y + vy}
    symbol = cond do
      x < 0 or x > max_x -> nil
      y < 0 or y > max_y -> nil
      true -> map[y][x]
    end
    cond do
      symbol == nil -> []
      is_mirror?(symbol) -> [{{x, y}, reflect({vx, vy}, symbol)}]
      is_splitter?(symbol) -> Enum.map(split({vx, vy}, symbol), fn velocity -> {{x, y}, velocity} end)
      true -> [{{x, y}, {vx, vy}}]
    end
  end

  def progress([], _, energized), do: energized
  def progress(particles, map, energized) do
    result = Enum.flat_map(particles, fn particle -> timestep(particle, map) end)
    energized =
      result
      |> Enum.map(fn {position, _} -> position end)
      |> MapSet.new
      |> MapSet.union(energized)
    progress(result, map, energized)
  end
end
