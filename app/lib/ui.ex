defmodule UI do
  @moduledoc """
  Place to put all the tailwind ui components styles
  """

  @color Application.get_env(:noodl, :theme, "red")

  def button(type \\ :primary, size \\ :base) do
    sizes =
      case size do
        :xs ->
          %{px: 2.5, py: 1.5, lead: 4, text: "text-xs", rounded: "rounded"}

        :sm ->
          %{px: 3, py: 2, lead: 4, text: "text-sm", rounded: "rounded-md"}

        :base ->
          %{px: 4, py: 2, lead: 5, text: "text-sm", rounded: "rounded-md"}

        :lg ->
          %{px: 4, py: 2, lead: 6, text: "text-base", rounded: "rounded-md"}

        :xl ->
          %{px: 6, py: 3, lead: 6, text: "text-base", rounded: "rounded-md"}
      end

    color =
      case type do
        :primary ->
          "text-white bg-#{@color}-600 hover:bg-#{@color}-500 focus:outline-none focus:border-#{
            @color
          }-700 focus:shadow-outline-#{@color} active:bg-#{@color}-700"

        :secondary ->
          "text-#{@color}-700 bg-#{@color}-100 hover:bg-#{@color}-50 focus:outline-none focus:border-#{
            @color
          }-300 focus:shadow-outline-#{@color} active:bg-#{@color}-200"

        _ ->
          ""
      end

    "inline-flex items-center px-#{sizes.px} py-#{sizes.py} border border-transparent #{
      sizes.text
    } leading-#{sizes.lead} font-medium #{sizes.rounded} #{color} transition ease-in-out duration-150"
  end
end
