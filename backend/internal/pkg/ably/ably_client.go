package ably

import (
	"context"
	"encoding/json"
	"fmt"

	"github.com/ably/ably-go/ably"
	"github.com/farizziezhi/circlestream/backend/internal/config"
)

type AblyClient struct {
	restClient *ably.REST
}

func NewClient(cfg *config.Config) (*AblyClient, error) {
	restClient, err := ably.NewREST(
		ably.WithKey(cfg.AblyAPIKey),
	)
	if err != nil {
		return nil, err
	}
	return &AblyClient{restClient: restClient}, nil
}

func (c *AblyClient) Publish(channelName, eventType string, data interface{}) error {
	channel := c.restClient.Channels.Get(channelName)

	payloadBytes, err := json.Marshal(map[string]interface{}{
		"type": eventType,
		"data": data,
	})
	if err != nil {
		return err
	}

	return channel.Publish(context.Background(), eventType, string(payloadBytes))
}

func (c *AblyClient) GenerateToken(circleID int64) (string, error) {
	capabilityStr := fmt.Sprintf(`{"circle:%d":["subscribe"]}`, circleID)

	params := &ably.TokenParams{
		TTL:        3600 * 1000, // 1 hour in milliseconds
		Capability: capabilityStr,
	}

	tokenRequest, err := c.restClient.Auth.RequestToken(context.Background(), params)
	if err != nil {
		return "", err
	}

	return tokenRequest.Token, nil
}

