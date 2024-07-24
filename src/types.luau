export type Pages<Entry> = {
	toCursor: (Pages<Entry>, cursor: string) -> { Entry },
	nextPage: (Pages<Entry>) -> { Entry },
	previousPage: (Pages<Entry>) -> { Entry },
	isLastPage: (Pages<Entry>) -> { Entry },
	isFirstPage: (Pages<Entry>) -> { Entry },
}

export type Fingerprint = {
	thumbnailUrl: string,
	userId: number?,
	attachUserId: (Fingerprint, userId: number) -> Fingerprint,
	matches: (Fingerprint, otherFingerprint: Fingerprint) -> boolean,
}

export type SearchOptions = {
	serverType: "public" | "private",
	roblosecurity: string,
}

export type PartialSearchOptions = {
	serverType: ("public" | "private")?,
	roblosecurity: string?,
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
