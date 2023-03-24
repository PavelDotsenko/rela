# Rela

# EN Startup guide: 

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

# RU Быстрый старт

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
