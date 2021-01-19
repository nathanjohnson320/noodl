defmodule NoodlWeb.ReleaseView do
  use NoodlWeb, :view

  def strip_whitespace(str) do
    str |> String.replace(" ", "")
  end

  def price_classes(changeset) do
    case Ecto.Changeset.get_change(changeset, :pricing_type, changeset.data.pricing_type) do
      "free" ->
        "mt-1 form-input block w-full py-2 px-3 border border-gray-300 rounded-md shadow-sm focus:outline-none transition duration-150 ease-in-out sm:text-sm sm:leading-5 opacity-50"

      _ ->
        "mt-1 form-input block w-full py-2 px-3 border border-gray-300 rounded-md shadow-sm focus:outline-none transition duration-150 ease-in-out sm:text-sm sm:leading-5"
    end
  end

  def radio_classes(type, changeset) do
    current_type =
      Ecto.Changeset.get_change(changeset, :pricing_type, changeset.data.pricing_type)

    if current_type == type, do: "border-red-400 bg-red-50 text-red-800", else: ""
  end

  def price_disabled?(changeset) do
    case Ecto.Changeset.get_change(changeset, :pricing_type, changeset.data.pricing_type) do
      "free" -> true
      _ -> false
    end
  end

  def get_purchase_submit_classes(%{submitting: submitting} = assigns) do
    disabled = submit_disabled?(assigns)

    if submitting or disabled do
      "bg-gray-900 py-1 px-1 text-white rounded-full w-24 opacity-50 pointer-events-none"
    else
      "bg-red-500 py-1 px-1 text-white rounded-full w-24"
    end
  end

  def submit_disabled?(%{release_errors: release_errors}) do
    count =
      release_errors
      |> Map.keys()
      |> Enum.count()

    count > 0
  end

  defdelegate cover_photo_url(event), to: NoodlWeb.EventsView
  defdelegate pretty_manage_date(event, date), to: NoodlWeb.EventsView
end
