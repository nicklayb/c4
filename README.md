# C4

Connect 4 game with TCP front end

## Installation

### Local deployment

#### Requirements

- `direnv` for local environment configuration

#### Create env file

Create a `../.c4.envrc` file and add at least the following

```
export C4_TCP_SERVER_PORT=6677
```

#### Start server

```bash
iex -S mix

# or 

make dev
```

The server will launch locally with hostname `localhost` and port `6677`.

### Docker deployment

Build the continer

```bash
make docker-build
```

Start the container

```bash
docker run -p 6677:6677 -e C4_TCP_SERVER_PORT=6677 c4:latest
```

## Connect

Using either `nc` or `telnet`, simply connect to ther server's endpoint.

```bash
telnet localhost 6677
```

You should see a "Welcome" message with some indication.

## General usage

When connecting to the server, the first thing you need to do is enter a username. The username will then be shown in the prompt confirming. You can then run `help` to see what you can do.
