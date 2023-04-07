defmodule Phos.Repo.Migrations.AddPlatformNotificationTable do
  use Ecto.Migration

  @table_query "SELECT * FROM information_schema.tables WHERE table_schema = 'public' AND table_name IN ('orbs', 'comments')"

  def up do
    # Create a function that broadcasts row changes
    execute("
      CREATE OR REPLACE FUNCTION broadcast_changes()
      RETURNS trigger AS $$
      DECLARE
        current_row RECORD;
      BEGIN
        IF (TG_OP = 'INSERT' OR TG_OP = 'UPDATE') THEN
          current_row := NEW;
        ELSE
          current_row := OLD;
        END IF;
        IF (TG_OP = 'INSERT') THEN
          OLD := NEW;
        END IF;
        IF (TG_OP = 'DELETE') THEN
          NEW := OLD;
        END IF;
      PERFORM pg_notify(
          'table_changes',
          json_build_object(
            'table', TG_TABLE_NAME,
            'type', TG_OP,
            'id', current_row.id,
            'new_row_data', row_to_json(NEW),
            'old_row_data', row_to_json(OLD)
          )::text
        );
      RETURN current_row;
      END;
      $$ LANGUAGE plpgsql;")

    execute("CREATE OR REPLACE FUNCTION create_notify_triggers()
                RETURNS event_trigger
                LANGUAGE plpgsql
                AS $$
                DECLARE
                  r RECORD;
                BEGIN
                  FOR r IN #{@table_query} LOOP
                    RAISE NOTICE 'CREATE FOR: %', r.table_name::text;
                    EXECUTE 'DROP TRIGGER IF EXISTS notify_table_changes_trigger ON ' || r.table_name || ';';
                    EXECUTE 'CREATE TRIGGER notify_table_changes_trigger
                            AFTER INSERT OR UPDATE OR DELETE
                            ON ' || r.table_name || '
                            FOR EACH ROW
                            EXECUTE PROCEDURE broadcast_changes();';
                  END LOOP;
                END;
                $$;")

    execute "CREATE EVENT TRIGGER add_table_broadcast_triggers ON ddl_command_end
              WHEN TAG IN ('CREATE TABLE','CREATE TABLE AS')
              EXECUTE PROCEDURE create_notify_triggers();"
    
    create table(:notification_templates, primary_key: false) do
      add :id, :uuid, primary_key: true
      add :key, :string
      add :body, :string, null: false
      add :title, :string, null: false
      add :subtitle, :string
      add :receiver_name, :boolean, default: false, null: true
      add :sender_name, :boolean, default: false, null: true
      add :event_name, :boolean, default: false, null: true
      add :icon, :string
      add :click_action, :string
    end

    create index(:notification_templates, :key, unique: true)

    create table(:notifications, primary_key: false) do
      add :id, :uuid, primary_key: true
      add :template_id, references(:notification_templates, column: :id, type: :uuid)
      add :active, :boolean, default: true, null: true
      add :success, :boolean, null: true
      add :spec, {:map, :string}
      add :retry_after, :integer, default: 0
      add :retry_attempt, :integer, default: 0
      add :next_execute_at, :naive_datetime, null: true
      add :error_reason, :string
    end
  end

  def down do
    execute "DROP EVENT TRIGGER add_table_broadcast_triggers"
    execute "
      do $$
      declare
        r RECORD;
      begin
        FOR r IN SELECT * FROM information_schema.tables WHERE table_schema = 'public' AND table_name IN ('orbs', 'comments')
        LOOP
          RAISE NOTICE 'DROP TRIGGER FOR: %', r.table_name::text;
          EXECUTE 'DROP TRIGGER IF EXISTS notify_table_changes_trigger ON ' || r.table_name || ';';
        END LOOP;
      end;
      $$"

    drop table(:notifications)
    drop index(:notification_templates, :key, unique: true)
    drop table(:notification_templates)
  end
end
