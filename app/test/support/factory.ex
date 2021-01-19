defmodule Noodl.Factory do
  use ExMachina.Ecto, repo: Noodl.Repo

  alias Noodl.Accounts.User
  alias Noodl.Messages.Message
  alias Noodl.Events.{Event, Proposal, Recording, Session}
  alias Noodl.Ticketing.{Release, Ticket}

  def user_factory do
    %User{
      firstname: "Jane",
      lastname: "Smith",
      email: sequence(:email, &"email-#{&1}@example.com")
    }
  end

  def event_factory do
    %Event{
      name: sequence(:title, &"Elixir Conf #{&1}"),
      slug: sequence(:title, &"elixir-conf-#{&1}"),
      description: "A conference",
      start_datetime: DateTime.utc_now(),
      end_datetime: DateTime.utc_now(),
      is_recurring: false,
      language: "english",
      timezone: "America/New_York",
      is_public: false
    }
  end

  def proposal_factory do
    %Proposal{
      audience: "some audience",
      description: "some description",
      notes: "some notes",
      tags: [],
      title: "some title",
      topic: "some topic"
    }
  end

  def release_factory do
    %Release{
      default_quantity: 42,
      description: "some description",
      end_at: ~N[2010-04-17 14:00:00],
      max_tickets_per_person: 42,
      price: 42,
      pricing_type: "some pricing_type",
      quantity: 42,
      start_at: ~N[2010-04-17 14:00:00],
      title: "some title"
    }
  end

  def ticket_factory do
    release = insert(:release)

    %Ticket{
      code: "some code",
      charge_id: nil,
      expires_at: ~N[2010-04-17 14:00:00],
      name: "some name",
      paid: true,
      release_id: release.id,
      event_id: release.event_id,
      user_id: release.user_id
    }
  end

  def session_factory do
    event = insert(:event)

    %Session{
      audience: "some audience",
      end_datetime: ~N[2010-04-17 14:00:00],
      live_stream_id: "some live_stream_id",
      name: "some name",
      slug: "some-name",
      start_datetime: ~N[2010-04-17 14:00:00],
      topic: "some topic",
      event_id: event.id,
      host: insert(:user)
    }
  end

  def recording_factory do
    %Recording{
      external_id: "12389",
      resource_id: "12345",
      status: nil
    }
  end

  def message_factory do
    user = insert(:user)

    %Message{
      user_id: user.id,
      content: "some content"
    }
  end
end
