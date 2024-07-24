# Sonar

Sonar is a tool built for [Lune](https://github.com/lune-org/lune) which attempts to find given users in a given place.

## Quick Start

```luau
local sonar = require(...)

local TARGET_USER_IDS = { 1 } -- @Roblox
local PLACE_ID = 1818 -- Classic: Crossroads

local searchResults = sonar.searchForUsers(TARGET_USER_IDS, PLACE_ID)
print(`found {#searchResults} results!`)
```

## API

### SearchResult

```luau
{
    serverId: string,
    serverPing: number,
    serverFps: number,
    activePlayers: number,
    maxPlayers: number,
    userIds: { number },
}
```

### searchForUsers

```luau
searchForUsers(targetUserIds: { number }, placeId: number) -> { SearchResult }
```
