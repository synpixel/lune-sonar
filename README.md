<div align="center">
	<img src="assets/logo.svg" width="128" alt="Logo"/>
	<h1>Sonar</h1>
	<p>A tool built for <a href="https://github.com/lune-org/lune/">Lune</a> which attempts to find users in a given Roblox place</p>
</div>

## Quick Start

```luau
local sonar = require(...)

local PLACE_ID = 1818 -- Classic: Crossroads
local TARGET_USER_IDS = {
    1, -- @Roblox
    156, -- @builderman
}

local searchResults = sonar.searchForUsers(TARGET_USER_IDS, PLACE_ID)
print(`found {#searchResults} results!`)
```

## API Reference

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

A search result containing server information, returned by `searchForUsers`.

### searchForUsers

```luau
searchForUsers(targetUserIds: { number }, placeId: number) -> { SearchResult }
```

Searches for users in a given place and returns the results.
