# OrbisTertius

> “Nothing is built on stone; All is built on sand, but we must build as if the sand were stone.”

![System Architecture](./overview.png)
## Initiation of Core API Services for Development
Local DynamoDB Service @ localhost:8000
HeimdallrNode API Service @ localhost:5000
Node Debug Inspection Port @ 9229 
WolfSmoke Notification Worker Service 
Node Debug Inspection Port @ 9222

### On aarch64 (x86, x64)

``` bash
docker-compose  -f local-compose.yml up 
```
`
With Inspection

``` bash
docker-compose -f inspect-compose.yml up 
```
`


### On ARM Devices ( M1/ RPI )

``` bash
docker-compose  -f m1-compose.yml up 
```
`
With Inspection

``` bash
docker-compose -f m1-inspect-compose.yml up 
```
`

## Initiation of  Phos Phoenix Service

Start Postgres Services Locally
PGAdmin @ localhost:5050
``` bash
docker-compose -f phos-compose.yml up 
```
`

To start the Phos Service:

    Enter the PhosphorousPhoenix directory
    Install dependencies with mix deps.get
    Create and migrate your database with mix ecto.setup
    Migrate using mix ecto.migrate to update the repository that maps to Postgres data store
    Start Phoenix endpoint with mix phx.server OR iex -S mix phx.server

Testing:

    mix test
