<div align="center">
	<img src="assets/logo.svg" width="128" alt="Logo"/>
	<h1>Sonar</h1>
	<p>A Luau library built for <a href="https://github.com/lune-org/lune/">Lune</a> which attempts to find users in a given Roblox place</p>
</div>

## Quick Start

```luau
local sonar = require(...)

local PLACE_ID = 1818 -- Classic: Crossroads
local TARGET_USER_IDS = {
    1, -- @Roblox
    156, -- @builderman
}

local results = sonar.searchForUsers(TARGET_USER_IDS, PLACE_ID)
print(`found {#results} results!`)
```

## API Reference

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
