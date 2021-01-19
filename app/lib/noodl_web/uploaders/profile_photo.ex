defmodule Noodl.Uploaders.ProfilePhoto do
  use Waffle.Definition

  use Waffle.Ecto.Definition

  alias NoodlWeb.Router.Helpers, as: Routes
  alias NoodlWeb.Endpoint

  @versions [:original, :thumb]

  # Whitelist file extensions
  def validate({file, _}) do
    ~w(.jpg .jpeg .gif .png) |> Enum.member?(Path.extname(file.file_name))
  end

  # Define a thumbnail transformation:
  def transform(:thumb, {%{file_name: file_name}, _user}) do
    type =
      file_name
      |> Path.extname()
      |> String.trim_leading(".")

    # Make it 64px tall preserve aspect ratio, png, strip, limit the disk so people don't ddos
    {:convert, "-strip -resize 150x150^ -format png -limit area 10MB -limit disk 100MB", type}
  end

  # Storage path in s3
  def storage_dir(_version, {_file, user}) do
    "uploads/users/#{user.id}"
  end

  # URL to use when there is none
  def default_url(_version, _scope) do
    Routes.static_path(Endpoint, "/images/default_user.png")
  end

  # Set the mime type for cloudfront
  def s3_object_headers(_version, {file, _scope}) do
    [content_type: MIME.from_path(file.file_name)]
  end
end
