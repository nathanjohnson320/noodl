defmodule Noodl.Uploaders.CoverPhoto do
  use Waffle.Definition
  use Waffle.Ecto.Definition

  alias NoodlWeb.Router.Helpers, as: Routes
  alias NoodlWeb.Endpoint

  @versions [:original, :thumb]

  # Whitelist file extensions:
  def validate({file, _}) do
    ~w(.jpg .jpeg .gif .png) |> Enum.member?(Path.extname(file.file_name))
  end

  # Define a thumbnail transformation:
  def transform(:thumb, {%{file_name: file_name}, _experiance}) do
    type =
      file_name
      |> Path.extname()
      |> String.trim_leading(".")

    {:convert, "-strip -resize 1600x1200^ -format png -limit area 30MB -limit disk 200MB", type}
  end

  # Override the storage directory:
  def storage_dir(_version, {_file, event}) do
    "uploads/events/#{event.slug}"
  end

  # Provide a default URL if there hasn't been a file uploaded
  def default_url(_version, _scope) do
    Routes.static_path(Endpoint, "/images/conference_default.jpg")
  end

  # Specify custom headers for s3 objects
  def s3_object_headers(_version, {file, _scope}) do
    [content_type: MIME.from_path(file.file_name)]
  end
end
