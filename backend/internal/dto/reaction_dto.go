package dto

type AddReactionRequest struct {
	Emoji string `json:"emoji"`
}

type AddReactionResponse struct {
	PostID int64  `json:"post_id"`
	Emoji  string `json:"emoji"`
	Count  int64  `json:"count"`
}

type GetReactionsResponse struct {
	PostID    int64            `json:"post_id"`
	Reactions map[string]int64 `json:"reactions"`
	Total     int64            `json:"total"`
}
