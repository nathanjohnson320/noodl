defmodule NoodlWeb.AccountsView do
  use NoodlWeb, :view

  alias NoodlWeb.Router.Helpers, as: Routes

  def profile_photo_url(%{profile_photo: photo} = user) do
    Noodl.Uploaders.ProfilePhoto.url({photo, user}, :thumb)
  end

  def get_active_class(%{view: view}, page) do
    if view == page,
      do:
        "group flex items-center px-3 py-2 text-sm leading-5 font-medium text-gray-900 rounded-md bg-gray-200 hover:text-gray-900 focus:outline-none focus:bg-gray-300 transition ease-in-out duration-150 mb-1",
      else:
        "group flex items-center px-3 py-2 text-sm leading-5 font-medium text-gray-600 rounded-md hover:text-gray-900 hover:bg-gray-50 focus:outline-none focus:text-gray-900 focus:bg-gray-200 transition ease-in-out duration-150 mb-1"
  end

  def get_active_icon_class(%{view: view}, page) do
    if view == page,
      do:
        "flex-shrink-0 -ml-1 mr-3 h-6 w-6 text-gray-500 group-hover:text-gray-500 group-focus:text-gray-600 transition ease-in-out duration-150",
      else:
        "flex-shrink-0 -ml-1 mr-3 h-6 w-6 text-gray-400 group-focus:text-gray-500 transition ease-in-out duration-150"
  end

  def gravatar_url(user, size \\ 80) do
    sanitized_email = user.email |> String.trim() |> String.downcase()
    hash = :crypto.hash(:md5, sanitized_email) |> Base.encode16(case: :lower)

    "https://www.gravatar.com/avatar/#{hash}?#{URI.encode_query(%{"d" => "mp", "s" => size})}"
  end

  def user_since(%{inserted_at: inserted_at}) do
    Timex.from_now(inserted_at)
  end
end
