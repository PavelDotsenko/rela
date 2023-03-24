defmodule Rela do
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
            @repo.insert_all("r_#{table}", [
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
                r.contractor == ^contractor
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
