# libmention

<!-- MDOC !-->

A [Webmention](https://www.w3.org/TR/webmention/) implementation for Elixir

## Goals
* [ ] [Send](https://www.w3.org/TR/webmention/#sending-webmentions) WebMentions (in progress)
* [ ] [Receive](https://www.w3.org/TR/webmention/#receiving-webmentions) Webmentions
* [ ] Configurable storage, defaulting to `ets`
* [ ] Easy local development and management of WebMentions including:
  * [ ] Accept
  * [ ] Decline
  * [ ] Verify
  * [ ] Block

## Usage
All aspects of the library can be used piecemeal or used a more automated system.

### Sending
When using piecemeal, the functions worth exploring are in `Libmention.Outgoing`:
* `Libmention.Outgoing.parse/1` is used to parse an html document for all unique links. The idea here is to pass in the body of your post/note/comment and determine which urls may need to have a webmention sent.
* `Libmention.Outgoing.discover/2` takes a link, sends a discovery and determine if webmention is supported at that specific link,
* `Libmention.Outgoing.send/4` sends that webmention

When using as more automated system, add the `Libmention.Supervisor` to your supervision try and configure it for sending.
```elixir
config = [
  outgoing: [

  ]
]
children = [
  ...,
  {Libmention.Supervisor, config}
]
```
Then to send for a page,

```elixir
Libmention.Supervisor.send(html)
```

### Receiving

<!-- MDOC !-->

## Installation

Add `libmention` to your list of dependencies in `mix.exs`:

```elixir
def deps do
  [
    {:libmention, "~> 0.1.0"}
  ]
end
```
