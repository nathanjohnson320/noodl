defmodule Mix.Tasks.Stripe.Webhook do
  use Mix.Task

  @shortdoc "Runs the stripe webhook cli"
  def run(_) do
    System.cmd("stripe", ~w(listen --forward-to localhost:4000/stripe/webhook),
      into: IO.stream(:stdio, :line)
    )
  end
end
