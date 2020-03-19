defmodule MmoGameWeb.LayoutView do
  use MmoGameWeb, :view

  @doc """
  Declaratively builds up a classname from a map of `optional`
  strings and a `required` string. This is essentially a port
  of the popular JavaScript package.

  ## Examples

      iex> optional = %{"alert-dismissible" => true}
      ...> required = "alert alert-success"
      ...> ServiceManagementWeb.LayoutView.classnames(optional, required)
      "alert alert-success alert-dismissible"

  """
  # @spec classnames(%{required(String.t()) => boolean()}, String.t()) :: String.t()
  def classnames(classes) when is_list(classes) do
    classes
    |> Enum.filter(&(&1 not in ["", nil]))
    |> Enum.join(" ")
  end

  def classnames(optional, required \\ "") do
    optional =
      optional
      |> Enum.filter(&match?({_, true}, &1))
      |> Enum.map(&elem(&1, 0))
      |> Enum.join(" ")

    (required <> " " <> optional) |> String.trim()
  end
end
