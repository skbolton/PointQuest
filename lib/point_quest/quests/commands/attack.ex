defmodule PointQuest.Quests.Commands.Attack do
  @moduledoc """
  Command for an adventure to attack for round in a quest.
  """
  use Ecto.Schema
  import Ecto.Changeset
  alias PointQuest.Quests

  require PointQuest.Quests.Telemetry
  require Telemetrex

  @type t :: %__MODULE__{
          quest_id: String.t(),
          adventurer_id: String.t(),
          attack: AttackValue.t()
        }

  defp repo(), do: Application.get_env(:point_quest, PointQuest.Behaviour.Quests.Repo)

  @primary_key false
  embedded_schema do
    field :quest_id, :string
    field :adventurer_id, :string
    field :attack, Quests.AttackValue
  end

  @spec changeset(t(), map()) :: Ecto.Changeset.t(t())
  def changeset(attack, params \\ %{}) do
    attack
    |> cast(params, [:quest_id, :adventurer_id, :attack])
    |> validate_required([:quest_id, :adventurer_id, :attack])
  end

  def new!(params) do
    %__MODULE__{}
    |> changeset(params)
    |> apply_action!(:update)
  end

  def new(params) do
    %__MODULE__{}
    |> changeset(params)
    |> apply_action(:update)
  end

  def execute(%__MODULE__{quest_id: quest_id} = attack_command) do
    Telemetrex.span event: Quests.Telemetry.attack(), context: %{command: attack_command} do
      with {:ok, quest} <- repo().get_quest_by_id(quest_id),
           {:ok, event} <- Quests.Quest.handle(attack_command, quest),
           {:ok, updated_quest} <- repo().write(quest, event) do
        {:ok, updated_quest, event}
      end
    after
      {:ok, %Quests.Quest{} = quest, event} -> %{quest: quest, event: event}
      {:error, reason} -> %{error: true, reason: reason}
    end
  end
end
