defmodule Noodl.Markdown do
  @moduledoc """
  Transform earmark into standard classes

  # Elixir from here
  https://elixirforum.com/t/earmark-add-my-own-class-names-to-the-default-set-of-markdown-tags/30520
  # Tailwind styles from here
  https://github.com/iandinwoodie/github-markdown-tailwindcss/blob/master/markdown.css
  """

  @css_style %{
    "img" => {"class", ""},
    "li" => {"class", ""},
    "p" => {"class", "my-4"},
    "h1" => {"class", "leading-tight border-b text-4xl font-semibold mb-4 mt-6 pb-2"},
    "h2" => {"class", "leading-tight border-b text-2xl font-semibold mb-4 mt-6 pb-2"},
    "h3" => {"class", "leading-snug text-lg font-semibold mb-4 mt-6"},
    "h4" => {"class", "leading-none text-base font-semibold mb-4 mt-6"},
    "h5" => {"class", "leading-tight text-sm font-semibold mb-4 mt-6"},
    "h6" => {"class", "leading-tight text-sm font-semibold text-gray-600 mb-4 mt-6"},
    "ul" => {"class", "text-base pl-8 list-disc"},
    "ol" => {"class", "text-base pl-8 list-decimal"},
    "a" => {"class", "text-blue-600 font-semibold"},
    "blockquote" => {"class", "text-base border-l-4 border-gray-300 pl-4 pr-4 text-gray-600"},
    "strong" => {"class", "font-semibold"},
    "code" => {"class", "font-mono text-sm inline bg-gray-200 rounded px-1 py-05"},
    "pre" => {"class", "bg-gray-100 rounded p-4"},
    "table" => {"class", "text-base border-gray-600"},
    "th" => {"class", "border py-1 px-3"},
    "td" => {"class", "border py-1 px-3"}
  }

  def to_html(markdown) do
    case EarmarkParser.as_ast(markdown) do
      {:ok, tree, []} ->
        Enum.map(tree, fn item ->
          item
          |> parse()
          |> Earmark.Transform.transform()
        end)

      _ ->
        markdown
    end
  end

  def parse({"p", attributes, child_nodes, %{}}) do
    first_child = List.first(child_nodes)

    case first_child do
      {"img", img_attr, img_child_nodes} ->
        parse({"img", img_attr ++ attributes, img_child_nodes, %{}})

      tag when is_binary(tag) ->
        {"p", [Map.get(@css_style, "p") | attributes], child_nodes, %{}}

      tag ->
        parse(tag)
    end
  end

  def parse({tag, attributes, child_nodes, %{}}) do
    {tag, [Map.get(@css_style, tag) | attributes] ++ get_additional(tag),
     Enum.map(child_nodes, &parse/1), %{}}
  end

  def parse(content) when is_binary(content) do
    {"p", [], [content], %{}}
  end

  defp get_additional("a"), do: [{"rel", "noopener noreferrer nofollow"}, {"target", "_blank"}]
  defp get_additional(_), do: []
end
