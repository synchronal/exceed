defmodule Test.SimpleCase do
  @moduledoc """
  The simplest test case template.
  """

  use ExUnit.CaseTemplate

  using do
    quote do
      import Moar.Assertions
      import Moar.Sugar
      import Test.SimpleCase
    end
  end

  def tmpdir do
    dir = Path.join([System.tmp_dir!(), "elixir_exceed", Moar.Random.string(4, :base32)])
    File.mkdir_p!(dir)
    on_exit(fn -> File.rm_rf!(dir) end)
    dir
  end

  def make_tmpdir(_context), do: [tmpdir: tmpdir()]
end
