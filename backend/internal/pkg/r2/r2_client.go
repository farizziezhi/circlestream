package r2

import (
	"context"
	"fmt"
	"time"

	"github.com/aws/aws-sdk-go-v2/aws"
	"github.com/aws/aws-sdk-go-v2/config"
	"github.com/aws/aws-sdk-go-v2/credentials"
	"github.com/aws/aws-sdk-go-v2/service/s3"
	appConfig "github.com/farizziezhi/circlestream/backend/internal/config"
)

type R2Client struct {
	s3Client      *s3.Client
	presignClient *s3.PresignClient
	bucketName    string
	publicURL     string
}

// Note: Backblaze B2 bucket CORS must be configured in the Backblaze dashboard to allow PUT requests from any origin.
func NewClient(cfg *appConfig.Config) (*R2Client, error) {
	r2Resolver := aws.EndpointResolverWithOptionsFunc(func(service, region string, options ...interface{}) (aws.Endpoint, error) {
		return aws.Endpoint{
			URL:           cfg.R2Endpoint,
			SigningRegion: "auto",
		}, nil
	})

	awsCfg, err := config.LoadDefaultConfig(context.TODO(),
		config.WithEndpointResolverWithOptions(r2Resolver),
		config.WithCredentialsProvider(credentials.NewStaticCredentialsProvider(
			cfg.R2AccessKey,
			cfg.R2SecretKey,
			"",
		)),
		config.WithRegion("auto"),
	)
	if err != nil {
		return nil, fmt.Errorf("unable to load SDK config, %w", err)
	}

	s3Client := s3.NewFromConfig(awsCfg)
	presignClient := s3.NewPresignClient(s3Client)

	return &R2Client{
		s3Client:      s3Client,
		presignClient: presignClient,
		bucketName:    cfg.R2BucketName,
		publicURL:     cfg.R2PublicURL,
	}, nil
}

func (c *R2Client) GeneratePresignedURL(objectKey, contentType string, expiry time.Duration) (string, error) {
	presignedReq, err := c.presignClient.PresignPutObject(context.TODO(), &s3.PutObjectInput{
		Bucket:      aws.String(c.bucketName),
		Key:         aws.String(objectKey),
		ContentType: aws.String(contentType),
	}, func(opts *s3.PresignOptions) {
		opts.Expires = expiry
	})
	if err != nil {
		return "", err
	}
	return presignedReq.URL, nil
}

func (c *R2Client) BuildPublicURL(objectKey string) string {
	return fmt.Sprintf("%s/%s", c.publicURL, objectKey)
}
