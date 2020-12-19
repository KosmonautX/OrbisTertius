# OrbisTertius
Dockerised Development &amp; Deployment Environment

## Init

- run docker service
- `docker-compose up`


## Inspecting Node

- run docker service
-docker-compose  -f inspect-compose.yml OR docker-compose run -p 5000:5000 -p 9229:9229 heimdallr /bin/sh
- tag preferred breakpoint with debugger;
- node --inspect-brk=0.0.0.0 .
  - c till breakpoint if comfortable with repl and CLI debug tools
  - OR under chrome://inspect/#devices DEVtools for Node
  

3 services 

DynamoDB Layer @ localhost:8000/shell


Node IO Layer @ localhost:5000


Node Debug @ localhost:9229


Flask Precompute Layer [^1] @ localhost:3000




[^1]: Integrating...
