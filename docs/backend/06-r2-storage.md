# Cloudflare R2 Storage

## CircleStream — Media Storage Specification

---

## 1. Overview

Cloudflare R2 digunakan sebagai object storage untuk semua file gambar. 

**Prinsip utama:**
- File **tidak pernah** melewati server Golang
- Flutter upload langsung ke R2 menggunakan presigned URL
- Backend hanya mengelola presigned URL dan menyimpan metadata URL ke Turso

---

## 2. R2 Bucket Structure

```
bucket: circlestream-media
├── circles/
│   └── {circle_id}/
│       └── posts/
│           ├── {uuid}.jpg          ← full size
│           └── thumb_{uuid}.jpg    ← thumbnail
```

**Contoh:**
```
circles/1/posts/a1b2c3d4-e5f6.jpg
circles/1/posts/thumb_a1b2c3d4-e5f6.jpg
```

---

## 3. Presigned Upload Flow

### Step 1: Flutter request presigned URL

```
POST /media/presign-upload
Authorization: Bearer {access_token}

{
  "circle_id": 1,
  "filename": "photo.jpg",
  "content_type": "image/jpeg",
  "file_size": 2048000
}
```

### Step 2: Backend validasi dan generate URL

Golang handler:
```go
func presignUpload(c *fiber.Ctx) error {
    // 1. Validasi user adalah member circle
    // 2. Validasi content_type (jpg/jpeg/png/webp)
    // 3. Validasi file_size <= 10MB
    // 4. Generate object key
    objectKey := fmt.Sprintf("circles/%d/posts/%s%s", circleID, uuid, ext)
    
    // 5. Generate presigned URL dari R2
    presignClient := s3.NewPresignClient(r2Client)
    presignResult, err := presignClient.PresignPutObject(ctx, &s3.PutObjectInput{
        Bucket:      aws.String(bucketName),
        Key:         aws.String(objectKey),
        ContentType: aws.String(req.ContentType),
    }, func(opts *s3.PresignOptions) {
        opts.Expires = 15 * time.Minute
    })
    
    return c.JSON(fiber.Map{
        "upload_url": presignResult.URL,
        "object_key": objectKey,
        "expires_in": 900,
    })
}
```

### Step 3: Flutter upload langsung ke R2

```dart
final response = await http.put(
  Uri.parse(presignedUrl),
  headers: {
    'Content-Type': 'image/jpeg',
  },
  body: compressedImageBytes,
);

if (response.statusCode == 200) {
  // Upload berhasil, lanjut ke finalize
  await finalizePost(objectKey, thumbnailKey);
}
```

### Step 4: Flutter finalize post

```
POST /media/finalize
Authorization: Bearer {access_token}

{
  "circle_id": 1,
  "object_key": "circles/1/posts/abc123.jpg",
  "thumbnail_key": "circles/1/posts/thumb_abc123.jpg"
}
```

Backend:
1. Verifikasi object_key sesuai circle_id (security check)
2. Build public URL: `https://cdn.circlestream.app/{object_key}`
3. Simpan post ke Turso
4. Publish `post_created` event ke Ably
5. Return post object

---

## 4. R2 Configuration

### Environment Variables (Backend)
```env
R2_ACCOUNT_ID=your_account_id
R2_ACCESS_KEY_ID=your_access_key
R2_SECRET_ACCESS_KEY=your_secret_key
R2_BUCKET_NAME=circlestream-media
R2_PUBLIC_URL=https://cdn.circlestream.app
```

### Golang R2 Client Setup
```go
import (
    "github.com/aws/aws-sdk-go-v2/service/s3"
    "github.com/aws/aws-sdk-go-v2/config"
)

func NewR2Client() *s3.Client {
    r2Resolver := aws.EndpointResolverWithOptionsFunc(func(service, region string, options ...interface{}) (aws.Endpoint, error) {
        return aws.Endpoint{
            URL: fmt.Sprintf("https://%s.r2.cloudflarestorage.com", os.Getenv("R2_ACCOUNT_ID")),
        }, nil
    })
    
    cfg, _ := config.LoadDefaultConfig(context.TODO(),
        config.WithEndpointResolverWithOptions(r2Resolver),
        config.WithCredentialsProvider(credentials.NewStaticCredentialsProvider(
            os.Getenv("R2_ACCESS_KEY_ID"),
            os.Getenv("R2_SECRET_ACCESS_KEY"),
            "",
        )),
        config.WithRegion("auto"),
    )
    
    return s3.NewFromConfig(cfg)
}
```

---

## 5. Image Validation Rules

| Rule | Value |
|---|---|
| Format yang diizinkan | JPG, JPEG, PNG, WEBP |
| Max file size (raw) | 10 MB |
| Target setelah kompresi | ≤ 3 MB |
| Max dimensi (long side) | 2048px |
| Thumbnail target | ≤ 200KB, max 400px |

Validasi dilakukan di **dua tempat**:
1. Flutter: sebelum request presign (client-side)
2. Backend: saat request presign (server-side, wajib)

---

## 6. Flutter Image Compression

```dart
import 'package:flutter_image_compress/flutter_image_compress.dart';

Future<Uint8List> compressImage(File imageFile) async {
  final result = await FlutterImageCompress.compressWithFile(
    imageFile.path,
    minWidth: 1080,
    minHeight: 1080,
    quality: 85,
    format: CompressFormat.jpeg,
  );
  
  // Jika masih > 3MB, compress lebih agresif
  if (result!.length > 3 * 1024 * 1024) {
    return await FlutterImageCompress.compressWithList(
      result,
      quality: 70,
    );
  }
  
  return result;
}

Future<Uint8List> generateThumbnail(File imageFile) async {
  return await FlutterImageCompress.compressWithFile(
    imageFile.path,
    minWidth: 400,
    minHeight: 400,
    quality: 75,
    format: CompressFormat.jpeg,
  );
}
```

---

## 7. Security Notes

- Presigned URL expires dalam 15 menit
- Object key harus dimulai dengan `circles/{circle_id}/` — backend validasi ini
- User tidak bisa upload ke circle yang bukan miliknya
- Bucket bersifat private, akses via public URL hanya untuk read (CDN)
- Jangan expose R2 credentials ke client Flutter
