defmodule Mix.Tasks.Emails do
  use Mix.Task

  @shortdoc "Uses mjml to output email files"

  def run(_) do
    "./lib/noodl_web/templates/**/*.mjml"
    |> Path.wildcard()
    |> Enum.map(fn template ->
      template_path = Path.expand(template)

      try do
        output_path = "#{Path.rootname(template_path)}.eex"

        {_, 0} =
          System.cmd(Path.expand("./assets/node_modules/.bin/mjml"), [
            "-r",
            template_path,
            "-o",
            output_path
          ])

        Mix.Shell.IO.info("Compiled template: #{output_path}")
      rescue
        ErlangError ->
          IO.puts("mjml not installed, run npm install")
      end
    end)
  end
end
