defmodule WebApiWeb.SuccessView do
  use WebApiWeb, :view

  def render("200.json", %{data: data}) do
    %{status: 0, errors: [], message: "", data: data}
  end

  def render("200.json", %{message: message}) do
    %{status: 0, errors: [], message: message, data: %{}}
  end
end
