<div align="center">
	<img src="assets/logo.svg" width="128" alt="Logo"/>
	<h1>Sonar</h1>
	<p>A Luau library built for Lune which attempts to find users in a given Roblox place</p>
</div>

**Disclaimer:** This is purely a proof of concept, it was made as an experiment with Roblox's thumbnail URL caching. This wasn't made with the goal of breaking Roblox TOS.

## How it works

The [Thumbnails API](https://thumbnails.roblox.com/docs/index.html) has a `/v1/batch` endpoint which "returns a list of thumbnails with varying types and sizes".

Here's how a standard request body looks like:

```json
[
  {
    "requestId": "foo",
    "targetId": 1,
    "type": "AvatarHeadshot",
    "size": "150x150",
    "format": "webp"
  }
]
```

This should give us back a headshot of `@Roblox`'s avatar, because `targetId` in this case is set to a user ID.

And it does!

```json
{
  "data": [
    {
      "requestId": "foo",
      "targetId": 1,
      "imageUrl": "https://tr.rbxcdn.com/30DAY-AvatarHeadshot-310966282D3529E36976BF6B07B1DC90-Png/150/150/AvatarHeadshot/Webp/noFilter",
      ...
    }
  ]
}
```

Now we've got a valid image URL for `@Roblox`'s profile picture. But this is not the only thing you can do with this.

If you take a quick look at `imageUrl`, you can notice a hexadecimal string in the middle: `310966282D3529E36976BF6B07B1DC90`. We'll call these **"thumbnail tokens"**.

Another place where user thumbnails are used is in the server list for Roblox places. You can work with these using the [Games API](https://games.roblox.com/docs/index.html?urls.primaryName=Games%20Api%20v1), specifically the `/v1/games/{placeId}/servers/{serverType}` endpoint.

This endpoint allows you to iterate through the servers of any place with its ID. Let's take a look at one of the entries in a response.

```json
{
  "id": "xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx",
  "playerTokens": [
    "199FBB623957CE5E4F7838A203402349",
    "F83F5E9A514950E291F0C2B12BF6EA22",
    "E2DA836A8B63706CAA462BAB6ADFB6FF",
    "583E65B5DF74D76E5A6AF841623368E3",
    "208FAFE28DC51537BA79540D697762F8"
  ],
  ...
}
```

It contains a `playerTokens` field. You can pass one of those to the Thumbnails API using the `token` field in a request. Let's put one of those `playerToken`s in there.

```json
[
  {
    "requestId": "baz",
    "token": "199FBB623957CE5E4F7838A203402349",
    "type": "AvatarHeadshot",
    "size": "150x150",
    "format": "webp"
  }
]
```

This should give us a response similar to the previous one, which means we can extract a thumbnail token from the response here as well.

The trick with these thumbnail tokens is that **they're cached based on the user, size, format, etc...**, this means that as long as we pass the same parameters _(size, format, etc...)_ to both thumbnail requests, we _will_ get the same `imageUrl`, no matter if we used a user ID or a `playerToken`.

`lune-sonar` abstracts these thumbnail tokens behind an interface called a **"fingerprint"**. You can associate user IDs to these fingerprints.

The library's lookup function takes a list of user IDs along with a place ID. It starts by collecting thumbnails from the user IDs and turning them into fingerprints. It proceeds by iterating through the place's servers all the while collecting thumbnails from `playerTokens` and turning them into fingerprints.

It can then compare fingerprints made from the `playerToken`s with the fingerprints it made from the list of user IDs, and keep track of the results.

## API

### PartialSearchOptions

```luau
type PartialSearchOptions = {
    -- default: public
    serverType: ("public" | "private")?,
}
```

Options to configure the searching process, used by `searchForUsers`.

### SearchResult

```luau
type SearchResult = {
    serverId: string,
    serverPing: number,
    serverFps: number,
    activePlayers: number,
    maxPlayers: number,
    userIds: { number },
}
```

Search result containing server information, returned by `searchForUsers`.

### searchForUsers

```luau
function searchForUsers(
    userIds: { number },
    placeId: number,
    partialSearchOptions: PartialSearchOptions?
) -> { SearchResult }
```

Searches for users in a given place and returns the results.
