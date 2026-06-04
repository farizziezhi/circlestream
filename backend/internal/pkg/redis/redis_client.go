package redis

import (
	"context"
	"crypto/tls"
	"fmt"
	"strconv"

	"github.com/farizziezhi/circlestream/backend/internal/config"
	"github.com/redis/go-redis/v9"
)

var Presets = []string{"❤️", "😂", "😮", "🔥", "👏", "😢", "🤩", "💀"}

type RedisClient struct {
	rdb *redis.Client
}

func NewClient(cfg *config.Config) *RedisClient {
	rdb := redis.NewClient(&redis.Options{
		Addr:      cfg.RedisAddr,
		Password:  cfg.RedisPassword,
		TLSConfig: &tls.Config{},
	})
	return &RedisClient{rdb: rdb}
}

func (c *RedisClient) IncrReaction(ctx context.Context, postID int64, emoji string) (int64, error) {
	key := fmt.Sprintf("reaction:count:%d:%s", postID, emoji)
	return c.rdb.Incr(ctx, key).Result()
}

func (c *RedisClient) GetReactionCounts(ctx context.Context, postID int64) (map[string]int64, error) {
	pipe := c.rdb.Pipeline()
	cmds := make([]*redis.StringCmd, len(Presets))
	for i, emoji := range Presets {
		key := fmt.Sprintf("reaction:count:%d:%s", postID, emoji)
		cmds[i] = pipe.Get(ctx, key)
	}

	_, _ = pipe.Exec(ctx)

	counts := make(map[string]int64)
	for i, emoji := range Presets {
		valStr, err := cmds[i].Result()
		if err == nil {
			val, parseErr := strconv.ParseInt(valStr, 10, 64)
			if parseErr == nil && val > 0 {
				counts[emoji] = val
			}
		}
	}
	return counts, nil
}

func (c *RedisClient) GetReactionCountsBatch(ctx context.Context, postIDs []int64) (map[int64]map[string]int64, error) {
	if len(postIDs) == 0 {
		return make(map[int64]map[string]int64), nil
	}

	pipe := c.rdb.Pipeline()
	type cmdRef struct {
		postID int64
		emoji  string
		cmd    *redis.StringCmd
	}
	var refs []cmdRef

	for _, postID := range postIDs {
		for _, emoji := range Presets {
			key := fmt.Sprintf("reaction:count:%d:%s", postID, emoji)
			cmd := pipe.Get(ctx, key)
			refs = append(refs, cmdRef{
				postID: postID,
				emoji:  emoji,
				cmd:    cmd,
			})
		}
	}

	_, _ = pipe.Exec(ctx)

	result := make(map[int64]map[string]int64)
	for _, postID := range postIDs {
		result[postID] = make(map[string]int64)
	}

	for _, ref := range refs {
		valStr, err := ref.cmd.Result()
		if err == nil {
			val, parseErr := strconv.ParseInt(valStr, 10, 64)
			if parseErr == nil && val > 0 {
				result[ref.postID][ref.emoji] = val
			}
		}
	}

	return result, nil
}

func (c *RedisClient) DeletePostReactions(ctx context.Context, postID int64) error {
	keys := make([]string, len(Presets))
	for i, emoji := range Presets {
		keys[i] = fmt.Sprintf("reaction:count:%d:%s", postID, emoji)
	}
	return c.rdb.Del(ctx, keys...).Err()
}

func (c *RedisClient) Ping(ctx context.Context) error {
	return c.rdb.Ping(ctx).Err()
}
