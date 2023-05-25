defmodule Rela do
  @moduledoc """
  # EN

  This module will help you setup non-traditional relational databases that keep track of every connection between multiple tables.

  Startup guide:

  1. Install this module as a dependency in your mix and run `mix deps.get`
  2. Create your own database schema modules
  3. Create a separate Rela module in your app lib folder
  4. With the help of `use` add this Rela app to your Rela module with opts that have this structure:
      use Rela, %{
          relations: [
              %{actor: `One of your schema modules`, contractor: `One of your schema modules`, arity: :one_to_one},
              %{actor: `One of your schema modules`, contractor: `One of your schema modules`, arity: :one_to_many},
              %{actor: `One of your schema modules`, contractor: `One of your schema modules`, arity: :many_to_many},
              ...
          ],
          repo: `Your Repo module here`
      }
  5. In your Application, after starting your Repo, you should call `Name of your Rela module`.check_r_tables(), which will create `r_`-tables
  6. If you were using the old version of Rela, you should call `Name of your Rela module`.update_from_previous_version\1
     with a key map that contains previously used aliases and the table names they represented, similar to this:
      update_from_previous_version(%{
          "`alias used in relation_types`" => "`table name that used the alias`",
          ...
      })
  7. After all of that, you should be able to use the remaining functions to manipulate the `r_`-tables


  # RU

  Этот модуль поможет вам создавать нетрадиционные реляционные базы данных которые следят за всеми связями между множеств таблиц.

  Быстрый старт:

  1. Установите этот модуль как зависимость в вашем mix и запустите `mix deps.get`
  2. Создайте модули схем для своей базы данных
  3. Создайте отдельный Rela модуль в своей папке lib
  4. С помощью `use` добавьте это Rela приложение к своему Rela модулю с опциями, похожими на эту структуру:
      use Rela, %{
          relations: [
              %{actor: `Один из ваших модулей схемы`, contractor: `Один из ваших модулей схемы`, arity: :one_to_one},
              %{actor: `Один из ваших модулей схемы`, contractor: `Один из ваших модулей схемы`, arity: :one_to_many},
              %{actor: `Один из ваших модулей схемы`, contractor: `Один из ваших модулей схемы`, arity: :many_to_many},
              ...
          ],
          repo: `Ваш Repo модуль`
      }
  5. В вашем Application, после запуска репозитория, необходимо вызвать `Имя вашего модуля Rela`.check_r_tables(), что создаст `r_`-таблицы
  6. Если вы использовали старую версию Rela, необходимо вызвать `Имя вашего модуля Rela`.update_from_previous_version\1
     с ключевой картой в которой находятся прежде используемые псевдонимы и таблицы, которые они представляли, похожую на эту:
      update_from_previous_version(%{
          "`псевдоним с relation_types`" => "`имя таблицы, использующую этот псевдоним`",
          ...
      })
  7. После всего этого, вы можете проверять оставшиеся функции для манипуляции `r_`-таблиц
  """
  @moduledoc since: "1.0.0"
  use Ecto.Schema

  schema "" do
    field(:actor_id, :integer)
    field(:contractor_id, :integer)
    field(:contractor, :string)
    field(:created_at, :naive_datetime)
    field(:is_deleted, :boolean)
  end

  defmacro __using__(opts) do
    quote bind_quoted: [opts: opts] do
      import Ecto.Query
      @sql Ecto.Adapters.SQL
      @chng Ecto.Changeset
      @repo opts[:repo]
      @conns Enum.reduce(opts[:relations], %{}, fn
               %{arity: :one_to_one, actor: actor, contractor: contractor}, acc ->
                 Map.merge(acc, %{{actor, contractor} => :one, {contractor, actor} => :one})

               %{arity: :one_to_many, actor: actor, contractor: contractor}, acc ->
                 Map.merge(acc, %{{actor, contractor} => :many, {contractor, actor} => :one})

               %{arity: :many_to_many, actor: actor, contractor: contractor}, acc ->
                 Map.merge(acc, %{{actor, contractor} => :many, {contractor, actor} => :many})

               _ = type, _ ->
                 throw({:error, "INCORRECT TYPE FORMAT", type})
             end)

      def exists_relation?(left, right) do
        exists_relation(left, right)
        |> case do
          {:ok, _} -> true
          {:error, _} -> false
        end
      end

      @doc """
        Check if the two items are related

        Use this function to check if a relation exists between item `left` and item `right`

        Проверка связи между `left` и `right`

        ## Examples / Примеры

            iex> Rela.exists_relation(%LeftItem{id: 1}, %RightItem{id: 4})
            {:ok, "relation between left_items and right_items exists"}

      """
      def exists_relation(left, right)

      def exists_relation(left, _right) when not is_struct(left),
      do: {:error, "left item is not a struct"}

      def exists_relation(_left, right) when not is_struct(right),
        do: {:error, "right item is not a struct"}

      def exists_relation(
            %{__meta__: %{source: left_table}, id: left_id},
            %{__meta__: %{source: right_table}, __struct__: right_struct, id: right_id}
          )
          when not is_nil(left_id) and not is_nil(right_id) do
        with true <- exists(left_table, left_id, right_id, right_table),
             true <- exists(right_table, right_id, left_id, left_table) do
          {:ok, "relation between #{left_table} and #{right_table} exists"}
        else
          false -> {:error, "relations between #{left_table} and #{right_table} not found"}
        end
      end

      def exists_relation(left, _right) do
        message = if is_nil(left[:id]), do: "left", else: "right"

        {:error, "#{message} item has no id"}
      end

      def get_contractors!(left, right) do
        get_contractors(left, right)
        |> case do
          {:ok, answer} -> answer
          {:error, _} -> []
        end
      end

      @doc """
        Get related items

        Use this function to get the items under the module passed to `right` that is related to the `left` item

        Получение предметов модуля `right`, связанных с предметом `left`

        ## Examples / Примеры

            iex> Rela.get_contractors(%LeftItem{id: 1}, RightItem)
            {:ok, [%RightItem{id: 4, name: "RIGHT"}, %{id: 5, name: "RIGHTOO"}]}

      """
      def get_contractors(left, right)

      def get_contractors(left, _right) when not is_struct(left),
       do: {:error, "left item is not a struct"}

      def get_contractors(left, right) when not is_struct(right),
        do: get_contractors(left, right.__struct__)

      def get_contractors(
            %{__meta__: %{source: left_table}, id: left_id},
            %{__meta__: %{source: right_table}, __struct__: right_struct}
          )
          when not is_nil(left_id) do
        with [_ | _] = right <- get(left_table, left_id, right_table),
             contractors <-
               Enum.map(
                 right,
                 fn a ->
                   Enum.at(
                     @repo.all(from(r in right_struct, where: r.id == ^a.contractor_id)),
                     0
                   )
                 end
               ) do
          {:ok, contractors}
        else
          [] -> {:error, "relations between #{left_table} and #{right_table} not found"}
        end
      end

      def get_contractors(left, _right), do: {:error, "left item has no id"}

      def get_contractor!(left, right) do
        get_contractor(left, right)
        |> case do
          {:ok, answer} -> answer
          {:error, _} -> nil
        end
      end

      @doc """
        Get related item

        Use this function to get the item under the module passed to `right` that is related to the `left` item

        Получение одного предмета с модулем `right`, связанного с предметом `left`

        ## Examples / Примеры

            iex> Rela.get_contractor(%LeftItem{id: 1}, RightItem)
            {:ok, %RightItem{id: 4, name: "RIGHT"}}

      """
      def get_contractor(left, right)

      def get_contractor(left, _right) when not is_struct(left),
        do: {:error, "left item is not a struct"}

      def get_contractor(left, right) when not is_struct(right),
        do: get_contractor(left, right.__struct__)

      def get_contractor(
            %{__meta__: %{source: left_table}, __struct__: left_struct, id: left_id},
            %{__meta__: %{source: right_table}, __struct__: right_struct}
          )
          when not is_nil(left_id) do
        with [%{contractor_id: right_id} | _] <- get(left_table, left_id, right_table),
             [contractor | _] <- @repo.all(from(r in right_struct, where: r.id == ^right_id)) do
          {:ok, contractor}
        else
          [] -> {:error, "relation between #{left_table} and #{right_table} not found"}
        end
      end

      def get_contractor(left, right), do: {:error, "left item has no id"}

      @doc """
        Delete a relation

        Use this function to delete a relation between the `left` and `right` items

        This function doesn't actually delete the relation from the DB, but hides it

        Удаление (скрытие) связи между предметами `left` и `right`

        ## Examples / Примеры

            iex> Rela.delete_rela(%LeftItem{id: 1}, %RightItem{id: 4})
            {:ok, "relation between left_items and right_items deleted"}

      """
      def delete_rela(left, right)

      def delete_rela(left, _right) when not is_struct(left),
        do: {:error, "left item is not a struct"}

      def delete_rela(_left, right) when not is_struct(right),
        do: {:error, "right item is not a struct"}

      def delete_rela(
            %{__meta__: %{source: left_table}, __struct__: left_struct, id: left_id},
            %{__meta__: %{source: right_table}, __struct__: right_struct, id: right_id}
          )
          when not is_nil(left_id) and not is_nil(right_id) do
        with [left | _] <- get(left_table, left_id, right_id, right_table),
             [right | _] <- get(right_table, right_id, left_id, left_table),
             _ <- delete(left),
             _ <- delete(right) do
          {:ok, "relation between #{left_table} and #{right_table} deleted"}
        else
          [] -> {:error, "relation between #{left_table} and #{right_table} not found"}
        end
      end

      def delete_rela(left, _right) do
        if is_nil(left[:id]) do
          {:error, "left item has no id"}
        else
          {:error, "right item has no id"}
        end
      end

      @doc """
        Create a relation

        Use this function to create a relation between the `left` and `right` items

        Создание связи между прдеметом `left` и `right`

        ## Examples / Примеры

            iex> Rela.create(%LeftItem{id: 1}, %RightItem{id: 4})
            {:ok, "relation between left_items and right_items created"}

      """
      def create(left, right)

      def create(left, _right) when not is_struct(left),
        do: {:error, "left item is not a struct"}

      def create(_left, right) when not is_struct(right),
        do: {:error, "right item is not a struct"}

      def create(
            %{__meta__: %{source: left_table}, __struct__: left_struct, id: left_id},
            %{__meta__: %{source: right_table}, __struct__: right_struct, id: right_id}
          )
          when not is_nil(left_id) and not is_nil(right_id) do
        with relation_arity when not is_tuple(relation_arity) <-
               Map.get(
                 @conns,
                 {left_struct, right_struct},
                 {:error,
                  "relation between tables #{left_table} and #{right_table} doesn't exist"}
               ),
             [] <-
               if(relation_arity == :one,
                 do: get(left_table, left_id, right_table),
                 else: []
               ),
             {1, _} <- insert(left_table, left_id, right_id, right_table),
             {1, _} <- insert(right_table, right_id, left_id, left_table) do
          {:ok, "relation between #{left_table} and #{right_table} created"}
        else
          [_ | _] -> {:error, "new relation violates arity agreements"}
          any -> any
        end
      end

      def create(left, _right) do
        if is_nil(left[:id]) do
          {:error, "left item has no id"}
        else
          {:error, "right item has no id"}
        end
      end

      def get_conns(), do: @conns

      def check_r_tables() do
        Enum.map(@conns, fn {{actor, _}, _} -> actor.__struct__.__meta__.source end)
        |> Enum.uniq()
        |> Enum.each(
          &@sql.query(
            @repo,
            "CREATE TABLE IF NOT EXISTS r_#{&1} (id serial PRIMARY KEY, actor_id INT NOT NULL, contractor_id INT NOT NULL, contractor VARCHAR(50) NOT NULL, created_at TIMESTAMP NOT NULL DEFAULT NOW(), is_deleted BOOLEAN NOT NULL DEFAULT false, FOREIGN KEY (actor_id) REFERENCES #{&1} (id))"
          )
        )
      end

      defp get(table, actor_id, contractor) do
        @repo.all(
          from(r in {"r_#{table}", Rela},
            where: r.actor_id == ^actor_id and r.contractor == ^contractor and not r.is_deleted,
            select: r
          )
        )
      end

      defp get(table, actor_id, contractor_id, contractor) do
        @repo.all(
          from(r in {"r_#{table}", Rela},
            where:
              r.actor_id == ^actor_id and r.contractor == ^contractor and
                r.contractor_id == ^contractor_id and not r.is_deleted,
            select: r
          )
        )
      end

      defp insert(table, actor_id, contractor_id, contractor, first_time? \\ true) do
        try do
        if not exists(table, actor_id, contractor_id, contractor) do
            @repo.insert_all({"r_#{table}", Rela}, [
            %{actor_id: actor_id, contractor_id: contractor_id, contractor: contractor}
          ])
        else
          {:error, "relation between #{table} and #{contractor} already exists"}
          end
        rescue
          any ->
            IO.inspect(any)
            check_r_tables()

            if(first_time?,
              do: insert(table, actor_id, contractor_id, contractor, false),
              else: {:error, "something went wrong when inserting relation: #{any}"}
            )
        end
      end

      defp exists(table, actor_id, contractor_id, contractor) do
        @repo.exists?(
          from(r in {"r_#{table}", Rela},
            where:
              r.actor_id == ^actor_id and r.contractor_id == ^contractor_id and
                r.contractor == ^contractor and not r.is_deleted
          )
        )
      end

      defp delete(rela) do
        rela
        |> @chng.change(is_deleted: true)
        |> @repo.update()
      end
    end
  end
end
