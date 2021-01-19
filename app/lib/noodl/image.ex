defmodule Noodl.Image do
  @moduledoc ~S"""
  Decode an image into waffle compatible contents
  """

  use Waffle.Ecto.Schema

  def decode("data:image/png;base64," <> raw), do: raw |> reformat("png")

  def decode("data:image/gif;base64," <> raw), do: raw |> reformat("gif")

  def decode("data:image/jpg;base64," <> raw), do: raw |> reformat("jpg")

  def decode("data:image/jpeg;base64," <> raw), do: raw |> reformat("jpeg")

  def decode(_), do: {:error, :unsupported}

  def reformat(raw, type) do
    case Base.decode64(raw) do
      {:ok, data} ->
        {:ok,
         %{
           filename: "image.#{type}",
           binary: data
         }}

      _ ->
        {:error, :invalid}
    end
  end

  def add_to_changeset(changeset, field, data_field, attrs) do
    with true <- not is_nil(attrs[field]),
         true <- attrs[field] != "",
         {:ok, data} <- decode(attrs[field]) do
      attrs = Map.put(attrs, data_field |> to_string(), data)
      changeset |> cast_attachments(attrs, [data_field])
    else
      false ->
        changeset

      {:error, :invalid} ->
        changeset |> Ecto.Changeset.add_error(data_field, "Invalid image")

      _ ->
        changeset
    end
  end

  def add_file(changeset, field, path, %{
        client_name: name,
        client_type: content_type
      }) do
    ext = Path.extname(name)

    changeset
    |> cast_attachments(
      %{
        field => %Plug.Upload{
          content_type: content_type,
          filename: "image.#{ext}",
          path: path
        }
      },
      [field]
    )
  end

  def all_ok?([], model), do: {:ok, model}

  def all_ok?(files, model) do
    ok =
      Enum.all?(files, fn
        {:ok, _} -> true
        _ -> false
      end)

    if ok, do: {:ok, model}, else: :error
  end
end
