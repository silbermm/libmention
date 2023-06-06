# Libmention

A [Webmention](https://www.w3.org/TR/webmention/) implementation for Elixir

## Goals
[ ] Ability to [Send](https://www.w3.org/TR/webmention/#sending-webmentions) WebMentions
[ ] Ability to [Receive](https://www.w3.org/TR/webmention/#receiving-webmentions) Webmentions
[ ] Configurable storage, defaulting to `ets`
[ ] Easy local development and management of WebMentions including verification

## Installation

Add `libmention` to your list of dependencies in `mix.exs`:

```elixir
def deps do
  [
    {:libmention, "~> 0.1.0"}
  ]
end
```

## Usage
