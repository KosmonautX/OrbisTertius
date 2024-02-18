# OrbisTertius

> “Nothing is built on stone; All is built on sand, but we must build as if the sand were stone.”

![System Architecture](./overview.png)


## Initialization of Services

Start Postgres Services Locally
PGAdmin @ localhost:5050
``` bash
docker-compose -f phos-compose.yml up 
```
### Configuration
    Init the dotenv file with your own config.
    
    Core Services:
     *  PostgreSQL:
     
        PGUSER=postgres
        PGPASSWORD=root
        PGDATABASE=app
        PGPORT=5432
        
    *  MinIO/S3 type Object Storage Service:
     
        AWS_ACCESS_KEY=
        AWS_SECRET_ACCESS_KEY=
        
        defaults to localhost configs
        
     * JWT Bearer Token Authorization Service:
     
       SECRET_TUNNEL=
       
     * Admin Database
     
       ADMIN_TUNNEL=
       
    Support Services:
    * Telegram Bot
    * Google/Apple/Firebase OAuth
    * Firebase Notification 
    * Mailer defaults to localhost dev mailbox behaviour on dev
    * Notion Database Sync for Admin Services
    * Partitioned Cache powered by ETS
       
### To start the Phos Service:

    Enter the PhosphorousPhoenix directory
    Install dependencies with mix deps.get
    Create and migrate your database with mix ecto.setup
    Migrate using mix ecto.migrate to update the repository that maps to Postgres data store
    Start Phoenix endpoint with mix phx.server OR iex -S mix phx.server
    
### Running UI Components Storybook

```
mix dev.storybook
mix assets.deploy
iex -S mix phx.server
```
goto /storybook

`

Testing:

    mix test
