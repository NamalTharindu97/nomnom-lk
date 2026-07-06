//go:build seed

package main

import (
	"bytes"
	"context"
	"encoding/json"
	"fmt"
	"io"
	"log"
	"os"
	"path/filepath"
	"strings"
	"time"

	"github.com/disintegration/imaging"
	"github.com/google/uuid"
	"github.com/minio/minio-go/v7"
	"github.com/minio/minio-go/v7/pkg/credentials"
	"github.com/nomnom-lk/backend/internal/config"
	"github.com/nomnom-lk/backend/internal/database"
	"github.com/nomnom-lk/backend/internal/models"
	"github.com/nomnom-lk/backend/pkg/hash"
	"gorm.io/gorm"
)

type ownerSeed struct {
	Email string
	Name  string
}

type restaurantSeed struct {
	Name        string
	NameSi      string
	NameTa      string
	Description string
	DescSi      string
	DescTa      string
	Address     string
	Latitude    float64
	Longitude   float64
	CuisineTags []string
	ImageSeed   string
	OwnerEmail  string
}

type offerSeed struct {
	RestaurantIdx int
	Title         string
	TitleSi       string
	TitleTa       string
	Description   string
	DescSi        string
	DescTa        string
	OriginalPrice float64
	OfferPrice    float64
	ImageSeed     string
	DaysValid     int
}

func main() {
	cfg, err := config.Load()
	if err != nil {
		log.Fatalf("Failed to load config: %v", err)
	}

	db := database.NewPostgresDB(&cfg.Database)

	sqlDB, err := db.DB()
	if err != nil {
		log.Fatalf("Failed to get underlying DB: %v", err)
	}
	defer sqlDB.Close()

	fmt.Println("🌱 Seeding database...")

	mc, err := minio.New(cfg.AWS.S3Endpoint, &minio.Options{
		Creds:        credentials.NewStaticV4(cfg.AWS.AccessKeyID, cfg.AWS.SecretAccessKey, ""),
		Secure:       false,
		BucketLookup: minio.BucketLookupAuto,
	})
	if err != nil {
		log.Fatalf("Failed to create MinIO client: %v", err)
	}

	env := "dev"
	bucket := cfg.AWS.S3Bucket

	ctx := context.Background()

	exists, err := mc.BucketExists(ctx, bucket)
	if err != nil {
		log.Fatalf("Failed to check bucket: %v", err)
	}
	if !exists {
		if err := mc.MakeBucket(ctx, bucket, minio.MakeBucketOptions{}); err != nil {
			log.Fatalf("Failed to create bucket: %v", err)
		}
	}

	cleanup(db)

	adminID := createAdmin(db, cfg)
	owners := createOwners(db)
	fmt.Printf("Created admin: %s\n", adminID)
	for email, id := range owners {
		fmt.Printf("Created owner: %s -> %s\n", email, id)
	}

	restaurants := []restaurantSeed{
		{
			Name: "Pizza Hut", NameSi: "පිස්සා හට්", NameTa: "பிஸ்ஸா ஹட்",
			Description: "Delicious pizzas, pasta, and Italian dishes", DescSi: "රසවත් පිස්සා, පැස්ටා, සහ ඉතාලි කෑම", DescTa: "சுவையான பிஸ்ஸா, பாஸ்தா, மற்றும் இத்தாலிய உணவுகள்",
			Address: "55 Galle Road, Colombo 03", Latitude: 6.9020, Longitude: 79.8612,
			CuisineTags: []string{"Pizza", "Italian", "Fast Food"}, ImageSeed: "pizza-hut", OwnerEmail: "owner@nomnom.lk",
		},
		{
			Name: "KFC", NameSi: "කේඑෆ්සී", NameTa: "கேஎப்சி",
			Description: "Fried chicken, burgers, and crispy treats", DescSi: "ෆ්‍රයිඩ් චිකන්, බර්ගර්, සහ හැපෙනසුළු කෑම", DescTa: "வறுத்த கோழி, பர்கர்கள், மற்றும் மிருதுவான தின்பண்டங்கள்",
			Address: "100 Galle Road, Colombo 04", Latitude: 6.8930, Longitude: 79.8560,
			CuisineTags: []string{"Fried Chicken", "Fast Food", "Burgers"}, ImageSeed: "kfc", OwnerEmail: "kfc@nomnom.lk",
		},
		{
			Name: "Bread Talk", NameSi: "බ්‍රෙඩ් ටෝක්", NameTa: "பிரெட் டாக்",
			Description: "Freshly baked breads, cakes, and pastries", DescSi: "නැවුම් බේක් කළ පාන්, කේක්, සහ පේස්ට්‍රි", DescTa: "புதிதாக சுடப்பட்ட ரொட்டிகள், கேக்குகள், மற்றும் பேஸ்ட்ரிகள்",
			Address: "22 Union Place, Colombo 02", Latitude: 6.9180, Longitude: 79.8540,
			CuisineTags: []string{"Bakery", "Cakes", "Pastries"}, ImageSeed: "bread-talk", OwnerEmail: "breadtalk@nomnom.lk",
		},
		{
			Name: "Keells", NameSi: "කීල්ස්", NameTa: "கீல்ஸ்",
			Description: "Quick bites, burgers, and crispy snacks", DescSi: "ඉක්මන් කෑම, බර්ගර්, සහ හැපෙනසුළු ස්නැක්ස්", DescTa: "விரைவு உணவுகள், பர்கர்கள், மற்றும் மிருதுவான தின்பண்டங்கள்",
			Address: "77 Havelock Road, Colombo 05", Latitude: 6.8780, Longitude: 79.8680,
			CuisineTags: []string{"Fast Food", "Burgers", "Snacks"}, ImageSeed: "keells", OwnerEmail: "keells@nomnom.lk",
		},
		{
			Name: "Fab", NameSi: "ෆැබ්", NameTa: "ஃபேப்",
			Description: "Cakes, pastries, and sweet treats", DescSi: "කේක්, පේස්ට්‍රි, සහ පැණි රස කෑම", DescTa: "கேக்குகள், பேஸ்ட்ரிகள், மற்றும் இனிப்பு தின்பண்டங்கள்",
			Address: "45 Nawala Road, Nugegoda", Latitude: 6.8720, Longitude: 79.8920,
			CuisineTags: []string{"Bakery", "Cakes", "Desserts"}, ImageSeed: "fab", OwnerEmail: "fab@nomnom.lk",
		},
		{
			Name: "Popeyes", NameSi: "පොප්අයිස්", NameTa: "பாப்ஐஸ்",
			Description: "Louisiana-style fried chicken and burgers", DescSi: "ලුසියානා විලාසිතාවේ ෆ්‍රයිඩ් චිකන් සහ බර්ගර්", DescTa: "லூசியானா பாணி வறுத்த கோழி மற்றும் பர்கர்கள்",
			Address: "200 Galle Road, Dehiwala", Latitude: 6.8570, Longitude: 79.8640,
			CuisineTags: []string{"Fried Chicken", "Fast Food", "Burgers"}, ImageSeed: "popeyes", OwnerEmail: "popeyes@nomnom.lk",
		},
		{
			Name: "Solo Bowl", NameSi: "සොලෝ බෝල්", NameTa: "சோலோ பௌல்",
			Description: "Rice bowls, noodles, and Asian fusion", DescSi: "බත් බෝල, නූඩ්ල්ස්, සහ ආසියානු ෆියුෂන්", DescTa: "சாதம் பௌல்கள், நூடுல்ஸ், மற்றும் ஆசிய கலப்பு உணவுகள்",
			Address: "33 Horton Place, Colombo 07", Latitude: 6.9120, Longitude: 79.8710,
			CuisineTags: []string{"Rice Bowls", "Asian", "Noodles"}, ImageSeed: "solo-bowl", OwnerEmail: "solobowl@nomnom.lk",
		},
		{
			Name: "Spar", NameSi: "ස්පාර්", NameTa: "ஸ்பார்",
			Description: "Desserts, cakes, and sweet delights", DescSi: "අතුරුපස, කේක්, සහ පැණි රස", DescTa: "இனிப்புகள், கேக்குகள், மற்றும் இனிப்பு விருந்துகள்",
			Address: "15 Station Road, Colombo 10", Latitude: 6.9300, Longitude: 79.8650,
			CuisineTags: []string{"Desserts", "Cakes", "Sweets"}, ImageSeed: "spar", OwnerEmail: "spar@nomnom.lk",
		},
		{
			Name: "Street Burger", NameSi: "ස්ට්‍රීට් බර්ගර්", NameTa: "ஸ்ட்ரீட் பர்கர்",
			Description: "Gourmet burgers, fries, and American comfort food", DescSi: "ගවර්මෙට් බර්ගර්, ෆ්‍රයිස්, සහ ඇමරිකානු සැනසිලි කෑම", DescTa: "கார்மெட் பர்கர்கள், பொரியல்கள், மற்றும் அமெரிக்க இதமான உணவுகள்",
			Address: "88 Galle Road, Bambalapitiya", Latitude: 6.8850, Longitude: 79.8600,
			CuisineTags: []string{"Burgers", "American", "Fast Food"}, ImageSeed: "street-burger", OwnerEmail: "streetburger@nomnom.lk",
		},
		{
			Name: "Subway", NameSi: "සබ්වේ", NameTa: "சப்வே",
			Description: "Fresh submarine sandwiches and salads", DescSi: "නැවුම් සබ්මැරීන් සැන්ඩ්විච් සහ සලාද", DescTa: "புதிய சப்மரைன் சாண்ட்விச்கள் மற்றும் சாலடுகள்",
			Address: "60 Galle Road, Colombo 03", Latitude: 6.9060, Longitude: 79.8580,
			CuisineTags: []string{"Sandwiches", "Healthy", "Fast Food"}, ImageSeed: "subway", OwnerEmail: "subway@nomnom.lk",
		},
		{
			Name: "Taco Bell", NameSi: "ටැකෝ බෙල්", NameTa: "டாகோ பெல்",
			Description: "Mexican-inspired tacos, burritos, and quesadillas", DescSi: "මෙක්සිකානු ආභාසයෙන් ටැකෝ, බුරිටෝ, සහ ක්වෙසාඩිලා", DescTa: "மெக்சிகன் பாணி டாகோஸ், புரிட்டோஸ், மற்றும் குவெசடிலாஸ்",
			Address: "120 Galle Road, Colombo 04", Latitude: 6.8950, Longitude: 79.8550,
			CuisineTags: []string{"Mexican", "Tacos", "Fast Food"}, ImageSeed: "taco-bell", OwnerEmail: "tacbell@nomnom.lk",
		},
	}

	offers := []offerSeed{
		{RestaurantIdx: 0, Title: "Grand Dipper", Description: "Pizza Hut Grand Dipper — loaded with toppings", OriginalPrice: 2500, OfferPrice: 1590, ImageSeed: "pizza-hut-granddipper", DaysValid: 30},
		{RestaurantIdx: 0, Title: "Lunch Deals 2 for 1", Description: "Two lunch pizzas for the price of one at Pizza Hut", OriginalPrice: 3000, OfferPrice: 1500, ImageSeed: "pizza-hut-lunch2", DaysValid: 45},
		{RestaurantIdx: 0, Title: "Lunch Pizza Deals", Description: "Special lunch pizza deals with a complimentary drink", OriginalPrice: 1800, OfferPrice: 1190, ImageSeed: "pizza-hut-lunch-pizza", DaysValid: 30},
		{RestaurantIdx: 0, Title: "Pepperoni Special", Description: "Classic pepperoni pizza at a great price", OriginalPrice: 2200, OfferPrice: 1390, ImageSeed: "pizza1", DaysValid: 21},
		{RestaurantIdx: 0, Title: "Veggie Supreme", Description: "Loaded veggie pizza with fresh garden toppings", OriginalPrice: 2000, OfferPrice: 1290, ImageSeed: "pizza2", DaysValid: 21},
		{RestaurantIdx: 1, Title: "Chicken Bucket 1", Description: "8 pieces of fried chicken with fries and coleslaw", OriginalPrice: 2200, OfferPrice: 1590, ImageSeed: "kfc1", DaysValid: 30},
		{RestaurantIdx: 1, Title: "Chicken Bucket 2", Description: "12 pieces of fried chicken family bucket", OriginalPrice: 3500, OfferPrice: 2490, ImageSeed: "kfc2", DaysValid: 45},
		{RestaurantIdx: 1, Title: "Chicken Bucket 3", Description: "6 pieces of fried chicken with a large drink", OriginalPrice: 1600, OfferPrice: 1190, ImageSeed: "kfc3", DaysValid: 21},
		{RestaurantIdx: 2, Title: "Carrot Cake Offer", Description: "Freshly baked carrot cake with cream cheese frosting", OriginalPrice: 1200, OfferPrice: 750, ImageSeed: "bread-talk-carrot", DaysValid: 14},
		{RestaurantIdx: 3, Title: "Burger Deal", Description: "Classic beef burger with fries and a drink", OriginalPrice: 1100, OfferPrice: 750, ImageSeed: "keels-burgers", DaysValid: 21},
		{RestaurantIdx: 3, Title: "Crispy Combo", Description: "Crispy chicken strips with dip and fries", OriginalPrice: 1300, OfferPrice: 890, ImageSeed: "keels-crispy", DaysValid: 30},
		{RestaurantIdx: 3, Title: "Fish Roll Pack", Description: "6 crispy fish rolls with spicy sauce", OriginalPrice: 800, OfferPrice: 550, ImageSeed: "keels-fish-rolls", DaysValid: 14},
		{RestaurantIdx: 4, Title: "Fab Cake Slice", Description: "Rich chocolate cake slice with cream", OriginalPrice: 600, OfferPrice: 390, ImageSeed: "fab-cake", DaysValid: 14},
		{RestaurantIdx: 4, Title: "Fab Cake 2", Description: "Mixed berry cheesecake slice", OriginalPrice: 750, OfferPrice: 490, ImageSeed: "fab-cake2", DaysValid: 14},
		{RestaurantIdx: 4, Title: "Combo Meal Deal", Description: "Cake slice with coffee or tea", OriginalPrice: 900, OfferPrice: 590, ImageSeed: "fab-combo", DaysValid: 21},
		{RestaurantIdx: 5, Title: "Chicken Burgers", Description: "2 crispy chicken burgers with fries", OriginalPrice: 1800, OfferPrice: 1290, ImageSeed: "popeyes-burgers", DaysValid: 30},
		{RestaurantIdx: 6, Title: "Mongolian Rice Bowl", Description: "Savory Mongolian rice bowl with your choice of protein", OriginalPrice: 1400, OfferPrice: 990, ImageSeed: "solo-bowl-rice", DaysValid: 21},
		{RestaurantIdx: 7, Title: "Strawberry Cheese Cake", Description: "Creamy strawberry cheesecake slice", OriginalPrice: 850, OfferPrice: 550, ImageSeed: "spar-cake", DaysValid: 14},
		{RestaurantIdx: 8, Title: "Burger Trio", Description: "Three gourmet burgers with truffle fries", OriginalPrice: 3200, OfferPrice: 2190, ImageSeed: "street-burger3", DaysValid: 45},
		{RestaurantIdx: 8, Title: "Double Cheeseburger", Description: "Double cheeseburger with bacon and onion rings", OriginalPrice: 1800, OfferPrice: 1290, ImageSeed: "street-burger2", DaysValid: 30},
		{RestaurantIdx: 8, Title: "Classic Burgers", Description: "Classic beef burger combo with fries and a shake", OriginalPrice: 1500, OfferPrice: 990, ImageSeed: "street-burgers", DaysValid: 30},
		{RestaurantIdx: 9, Title: "Submarine Offers", Description: "Footlong sub with your choice of fillings and a drink", OriginalPrice: 1600, OfferPrice: 1100, ImageSeed: "subway-sub", DaysValid: 30},
		{RestaurantIdx: 10, Title: "Taco Deal", Description: "3 tacos with salsa, guacamole, and sour cream", OriginalPrice: 1500, OfferPrice: 990, ImageSeed: "taco-bell-tacos", DaysValid: 21},
	}

	samplesBase := "/Users/namal/dev/MobileApps/NomNom LK/assets/samples"

	sampleFiles := map[string]string{
		"pizza-hut":              filepath.Join(samplesBase, "pizza hut granddipper.jpeg"),
		"pizza-hut-granddipper":  filepath.Join(samplesBase, "pizza hut granddipper.jpeg"),
		"pizza-hut-lunch2":       filepath.Join(samplesBase, "pizza hut lunch deals 2.jpeg"),
		"pizza-hut-lunch-pizza":  filepath.Join(samplesBase, "pizza hut lunch pizza deals.jpeg"),
		"pizza1":                 filepath.Join(samplesBase, "pizza1.jpeg"),
		"pizza2":                 filepath.Join(samplesBase, "pizza2.jpeg"),
		"kfc":                    filepath.Join(samplesBase, "kfc1.jpeg"),
		"kfc1":                   filepath.Join(samplesBase, "kfc1.jpeg"),
		"kfc2":                   filepath.Join(samplesBase, "kfc2.jpeg"),
		"kfc3":                   filepath.Join(samplesBase, "kfc3.jpeg"),
		"bread-talk":             filepath.Join(samplesBase, "bread talk offers carrort cake.jpeg"),
		"bread-talk-carrot":      filepath.Join(samplesBase, "bread talk offers carrort cake.jpeg"),
		"keells":                 filepath.Join(samplesBase, "keels burgers.jpeg"),
		"keels-burgers":          filepath.Join(samplesBase, "keels burgers.jpeg"),
		"keels-crispy":           filepath.Join(samplesBase, "keels crispy combo.jpeg"),
		"keels-fish-rolls":       filepath.Join(samplesBase, "keels fish rolls.jpeg"),
		"fab":                    filepath.Join(samplesBase, "Fab cake.jpeg"),
		"fab-cake":               filepath.Join(samplesBase, "Fab cake.jpeg"),
		"fab-cake2":              filepath.Join(samplesBase, "fab cake2.jpeg"),
		"fab-combo":              filepath.Join(samplesBase, "fab combo meal.jpeg"),
		"popeyes":                filepath.Join(samplesBase, "popeyes burgers.jpeg"),
		"popeyes-burgers":        filepath.Join(samplesBase, "popeyes burgers.jpeg"),
		"solo-bowl":              filepath.Join(samplesBase, "solo bowl mongolien rice.jpeg"),
		"solo-bowl-rice":         filepath.Join(samplesBase, "solo bowl mongolien rice.jpeg"),
		"spar":                   filepath.Join(samplesBase, "spar stowberry cheese cake.jpeg"),
		"spar-cake":              filepath.Join(samplesBase, "spar stowberry cheese cake.jpeg"),
		"street-burger":          filepath.Join(samplesBase, "streat_burger burger3.jpeg"),
		"street-burger3":         filepath.Join(samplesBase, "streat_burger burger3.jpeg"),
		"street-burger2":         filepath.Join(samplesBase, "streeat bregers beger2.jpeg"),
		"street-burgers":         filepath.Join(samplesBase, "streeat bugger buggers.jpeg"),
		"subway":                 filepath.Join(samplesBase, "sub way submarine offers.jpeg"),
		"subway-sub":             filepath.Join(samplesBase, "sub way submarine offers.jpeg"),
		"taco-bell":              filepath.Join(samplesBase, "taco bell tacos.jpeg"),
		"taco-bell-tacos":        filepath.Join(samplesBase, "taco bell tacos.jpeg"),
	}

	uploaded := make(map[string]string)

	for seed, filePath := range sampleFiles {
		uploadedURL, err := uploadToMinIO(ctx, mc, bucket, env, filePath, "images")
		if err != nil {
			fmt.Printf("  ❌ Upload failed for %s: %v\n", seed, err)
			continue
		}
		uploaded[seed] = uploadedURL
		fmt.Printf("  ✅ Uploaded %s -> %s\n", seed, uploadedURL)
	}

	restaurantIDs := make([]uuid.UUID, len(restaurants))
	for i, r := range restaurants {
		coverImage := uploaded[r.ImageSeed]
		if coverImage == "" {
			coverImage = uploaded["pizza-hut"]
		}

		ownerID, ok := owners[r.OwnerEmail]
		if !ok {
			fmt.Printf("  ❌ Owner not found for %s (email: %s)\n", r.Name, r.OwnerEmail)
			continue
		}

		translations := buildTranslations(r.NameSi, r.NameTa, r.DescSi, r.DescTa, "name", "description")

		rest := models.Restaurant{
			Name:        r.Name,
			Description: &r.Description,
			Address:     r.Address,
			Latitude:    &r.Latitude,
			Longitude:   &r.Longitude,
			CuisineTags: r.CuisineTags,
			CoverImage:  &coverImage,
			OwnerID:     &ownerID,
			Status:      models.RestaurantApproved,
			IsFeatured:  i < 4,
			Translations: translations,
		}
		if err := db.Create(&rest).Error; err != nil {
			fmt.Printf("  ❌ Failed to create restaurant %s: %v\n", r.Name, err)
			continue
		}
		restaurantIDs[i] = rest.ID
		fmt.Printf("  ✅ Created restaurant: %s\n", r.Name)
	}

	now := time.Now()
	for _, o := range offers {
		if o.RestaurantIdx >= len(restaurantIDs) {
			continue
		}
		rid := restaurantIDs[o.RestaurantIdx]
		if rid == uuid.Nil {
			continue
		}

		imgURL := uploaded[o.ImageSeed]
		if imgURL == "" {
			imgURL = uploaded[restaurants[o.RestaurantIdx].ImageSeed]
		}
		if imgURL == "" {
			imgURL = uploaded["pizza-hut"]
		}

		var imageURLs models.JSONStringSlice
		if imgURL != "" {
			imageURLs = []string{imgURL}
		}

		translations := buildTranslations(o.TitleSi, o.TitleTa, o.DescSi, o.DescTa, "title", "description")

		startDate := now.Add(-time.Duration(o.DaysValid/2) * 24 * time.Hour)
		endDate := now.Add(time.Duration(o.DaysValid) * 24 * time.Hour)

		ownerID := owners[restaurants[o.RestaurantIdx].OwnerEmail]

		offer := models.Offer{
			RestaurantID:  rid,
			Title:         o.Title,
			Description:   &o.Description,
			OriginalPrice: o.OriginalPrice,
			OfferPrice:    o.OfferPrice,
			ImageURLs:     imageURLs,
			StartDate:     &startDate,
			EndDate:       endDate,
			CreatedBy:     &ownerID,
			Status:        models.OfferApproved,
			Translations:  translations,
		}
		if err := db.Create(&offer).Error; err != nil {
			fmt.Printf("  ❌ Failed to create offer %s: %v\n", o.Title, err)
			continue
		}
		fmt.Printf("  ✅ Created offer: %s\n", o.Title)
	}

	fmt.Println("\n🌱 Seed completed successfully!")
	fmt.Printf("  📍 %d restaurants\n", len(restaurants))
	fmt.Printf("  📍 %d offers\n", len(offers))
	fmt.Printf("  📍 %d images uploaded\n", len(uploaded))
}

func uploadToMinIO(ctx context.Context, mc *minio.Client, bucket, env, filePath, folder string) (string, error) {
	file, err := os.Open(filePath)
	if err != nil {
		return "", fmt.Errorf("file open failed: %w", err)
	}
	defer file.Close()

	data, err := io.ReadAll(file)
	if err != nil {
		return "", fmt.Errorf("file read failed: %w", err)
	}

	ext := strings.ToLower(filepath.Ext(filePath))
	objectKey := fmt.Sprintf("%s/%s/%s.jpg", env, folder, uuid.New().String())

	var uploadData []byte
	var contentType string

	if ext == ".svg" {
		objectKey = fmt.Sprintf("%s/%s/%s.svg", env, folder, uuid.New().String())
		uploadData = data
		contentType = "image/svg+xml"
	} else {
		img, err := imaging.Decode(bytes.NewReader(data))
		if err != nil {
			return "", fmt.Errorf("image decode failed: %w", err)
		}
		cropped := imaging.Fill(img, 1024, 1024, imaging.Center, imaging.Lanczos)
		buf := new(bytes.Buffer)
		if err := imaging.Encode(buf, cropped, imaging.JPEG, imaging.JPEGQuality(85)); err != nil {
			return "", fmt.Errorf("image encode failed: %w", err)
		}
		uploadData = buf.Bytes()
		contentType = "image/jpeg"
	}

	_, err = mc.PutObject(ctx, bucket, objectKey, bytes.NewReader(uploadData), int64(len(uploadData)), minio.PutObjectOptions{
		ContentType: contentType,
	})
	if err != nil {
		return "", fmt.Errorf("minio upload failed: %w", err)
	}

	return fmt.Sprintf("/api/v1/uploads/%s", objectKey), nil
}

func buildTranslations(si, ta, descSi, descTa, nameField, descField string) *json.RawMessage {
	translations := make(map[string]map[string]string)
	if si != "" {
		translations[nameField] = map[string]string{"si": si}
	}
	if ta != "" {
		if m, ok := translations[nameField]; ok {
			m["ta"] = ta
		} else {
			translations[nameField] = map[string]string{"ta": ta}
		}
	}
	if descSi != "" {
		translations[descField] = map[string]string{"si": descSi}
	}
	if descTa != "" {
		if m, ok := translations[descField]; ok {
			m["ta"] = descTa
		} else {
			translations[descField] = map[string]string{"ta": descTa}
		}
	}
	if len(translations) == 0 {
		return nil
	}
	data, _ := json.Marshal(translations)
	raw := json.RawMessage(data)
	return &raw
}

func cleanup(db *gorm.DB) {
	fmt.Println("Cleaning existing seed data...")
	db.Exec("DELETE FROM favorites")
	db.Exec("DELETE FROM notifications")
	db.Exec("DELETE FROM device_tokens")
	db.Exec("DELETE FROM offers")
	db.Exec("DELETE FROM restaurants")
	db.Exec("DELETE FROM refresh_tokens")
	db.Exec("DELETE FROM users WHERE role != 'admin'")
}

func createAdmin(db *gorm.DB, cfg *config.Config) uuid.UUID {
	hashedPassword, err := hash.HashPassword(cfg.Admin.Password)
	if err != nil {
		log.Fatalf("Failed to hash admin password: %v", err)
	}

	now := time.Now()
	admin := models.User{
		Email:           cfg.Admin.Email,
		PasswordHash:    hashedPassword,
		Name:            "Admin",
		Role:            models.RoleAdmin,
		IsActive:        true,
		EmailVerifiedAt: &now,
	}

	result := db.Where("email = ?", admin.Email).FirstOrCreate(&admin)
	if result.Error != nil {
		log.Fatalf("Failed to create admin user: %v", result.Error)
	}
	fmt.Printf("Admin user: %s (%s)\n", admin.Email, admin.ID.String())
	return admin.ID
}

func createOwners(db *gorm.DB) map[string]uuid.UUID {
	ownerSeeds := []ownerSeed{
		{Email: "owner@nomnom.lk", Name: "Pizza Hut Owner"},
		{Email: "kfc@nomnom.lk", Name: "KFC Owner"},
		{Email: "breadtalk@nomnom.lk", Name: "Bread Talk Owner"},
		{Email: "keells@nomnom.lk", Name: "Keells Owner"},
		{Email: "fab@nomnom.lk", Name: "Fab Owner"},
		{Email: "popeyes@nomnom.lk", Name: "Popeyes Owner"},
		{Email: "solobowl@nomnom.lk", Name: "Solo Bowl Owner"},
		{Email: "spar@nomnom.lk", Name: "Spar Owner"},
		{Email: "streetburger@nomnom.lk", Name: "Street Burger Owner"},
		{Email: "subway@nomnom.lk", Name: "Subway Owner"},
		{Email: "tacbell@nomnom.lk", Name: "Taco Bell Owner"},
	}

	hashedPassword, err := hash.HashPassword("Owner@123")
	if err != nil {
		log.Fatalf("Failed to hash owner password: %v", err)
	}

	now := time.Now()
	owners := make(map[string]uuid.UUID, len(ownerSeeds))

	for _, s := range ownerSeeds {
		owner := models.User{
			Email:           s.Email,
			PasswordHash:    hashedPassword,
			Name:            s.Name,
			Role:            models.RoleRestaurantOwner,
			IsActive:        true,
			EmailVerifiedAt: &now,
		}
		result := db.Where("email = ?", owner.Email).FirstOrCreate(&owner)
		if result.Error != nil {
			log.Fatalf("Failed to create owner %s: %v", s.Email, result.Error)
		}
		owners[s.Email] = owner.ID
	}

	return owners
}
