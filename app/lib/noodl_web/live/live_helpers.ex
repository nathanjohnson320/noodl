defmodule NoodlWeb.LiveHelpers do
  require Phoenix.HTML

  import Phoenix.LiveView.Helpers
  import Phoenix.HTML
  import Phoenix.HTML.Form
  import NoodlWeb.Gettext

  @doc """
  Renders a component inside the `NoodlWeb.ModalComponent` component.

  The rendered modal receives a `:return_to` option to properly update
  the URL when the modal is closed.

  ## Examples

      <%= live_modal @socket, NoodlWeb.FooLive.FormComponent,
        id: @foo.id || :new,
        action: @live_action,
        foo: @foo,
        return_to: Routes.foo_index_path(@socket, :index) %>
  """

  alias Noodl.Markdown

  def live_modal(socket, component, opts) do
    path = Keyword.fetch!(opts, :return_to)
    modal_opts = [id: :modal, return_to: path, component: component, opts: opts]
    live_component(socket, NoodlWeb.ModalComponent, modal_opts)
  end

  def render_markdown(text) do
    text |> Markdown.to_html() |> Phoenix.HTML.raw()
  end

  def localized_datetime_select(form, field, opts \\ []) do
    date = Map.get(form.source.changes, field) || Map.get(form.data, field)
    day_of_week = Timex.day_name(Timex.weekday(date))

    builder = fn b ->
      ~e"""
      <div class="my-2 flex items-center">
        <p class="text-sm mr-2">Date (<%= day_of_week %>)</p>
        <%= b.(:month, [class: "form-select", disabled: opts[:disabled]]) %>
        <%= b.(:day, [class: "form-select", disabled: opts[:disabled]]) %>
        <%= b.(:year, [class: "form-select", disabled: opts[:disabled]]) %>
      </div>

      <div class="my-2 flex items-center">
        <p class="text-sm mr-2">Time</p>
        <%= b.(:hour, [class: "form-select", disabled: opts[:disabled]]) %> :
        <%= b.(:minute, [class: "form-select", disabled: opts[:disabled]]) %>
      </div>
      """
    end

    opts =
      opts
      |> Keyword.put(:month,
        options: [
          {gettext("January"), "1"},
          {gettext("February"), "2"},
          {gettext("March"), "3"},
          {gettext("April"), "4"},
          {gettext("May"), "5"},
          {gettext("June"), "6"},
          {gettext("July"), "7"},
          {gettext("August"), "8"},
          {gettext("September"), "9"},
          {gettext("October"), "10"},
          {gettext("November"), "11"},
          {gettext("December"), "12"}
        ]
      )
      |> Keyword.put(:hour,
        options: [
          {gettext("12am"), "0"},
          {gettext("1am"), "1"},
          {gettext("2am"), "2"},
          {gettext("3am"), "3"},
          {gettext("4am"), "4"},
          {gettext("5am"), "5"},
          {gettext("6am"), "6"},
          {gettext("7am"), "7"},
          {gettext("8am"), "8"},
          {gettext("9am"), "9"},
          {gettext("10am"), "10"},
          {gettext("11am"), "11"},
          {gettext("12pm"), "12"},
          {gettext("1pm"), "13"},
          {gettext("2pm"), "14"},
          {gettext("3pm"), "15"},
          {gettext("4pm"), "16"},
          {gettext("5pm"), "17"},
          {gettext("6pm"), "18"},
          {gettext("7pm"), "19"},
          {gettext("8pm"), "20"},
          {gettext("9pm"), "21"},
          {gettext("10pm"), "22"},
          {gettext("11pm"), "23"}
        ]
      )
      |> Keyword.put(:minute,
        options:
          :lists.seq(0, 59, 5)
          |> Enum.map(fn time ->
            {String.pad_leading(to_string(time), 2, ["0"]), to_string(time)}
          end)
      )

    datetime_select(form, field, [builder: builder] ++ opts)
  end
end
