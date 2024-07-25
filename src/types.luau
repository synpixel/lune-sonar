export type Pages<Entry> = {
	toCursor: (Pages<Entry>, cursor: string) -> { Entry },
	nextPage: (Pages<Entry>) -> { Entry },
	previousPage: (Pages<Entry>) -> { Entry },
	isLastPage: (Pages<Entry>) -> { Entry },
	isFirstPage: (Pages<Entry>) -> { Entry },
}

export type Fingerprint = string | { string | number }

export type SearchOptions = {
	serverType: "public" | "private",
}

export type PartialSearchOptions = {
	serverType: ("public" | "private")?,
}

export type SearchResult = {
	serverId: string,
	serverPing: number,
	serverFps: number,
	activePlayers: number,
	maxPlayers: number,
	userIds: { number },
}

return nil
