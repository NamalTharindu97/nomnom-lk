//go:build seed

package main

import (
	"bytes"
	"context"
	"encoding/json"
	"fmt"
	"io"
	"log"
	"net/http"
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
	ownerID := createRestaurantOwner(db, cfg)
	fmt.Printf("Created admin: %s\n", adminID)
	fmt.Printf("Created owner: %s\n", ownerID)

	restaurants := []restaurantSeed{
		{
			Name: "Kottu House", NameSi: "කොත්තු හවුස්", NameTa: "கொத்து ஹவுஸ்",
			Description: "Best kottu roti in Colombo with spicy flavors", DescSi: "කොළඹ හොඳම කොත්තු රොටි කුළුබඩු රසයෙන්", DescTa: "கொழும்பில் சிறந்த கொத்து ரொட்டி காரமான சுவையில்",
			Address: "42 Galle Road, Colombo 03", Latitude: 6.9020, Longitude: 79.8612,
			CuisineTags: []string{"Kottu", "Sri Lankan", "Street Food"}, ImageSeed: "kottu-house",
		},
		{
			Name: "Rice & Curry Paradise", NameSi: "රයිස් ඇන්ඩ් කරී පැරඩයිස්", NameTa: "ரைஸ் அண்ட் கறி பரடைஸ்",
			Description: "Traditional rice and curry with authentic Sri Lankan flavors", DescSi: "සම්ප්‍රදායික බත් සහ ව්‍යංජන සැබෑ ලංකා රසයෙන්", DescTa: "பாரம்பரிய சாதமும் கறியும் உண்மையான இலங்கை சுவையில்",
			Address: "125 Kandy Road, Kadawatha", Latitude: 7.0000, Longitude: 79.9500,
			CuisineTags: []string{"Rice & Curry", "Sri Lankan", "Traditional"}, ImageSeed: "rice-curry",
		},
		{
			Name: "Hoppers Spot", NameSi: "හොප්පර්ස් ස්පොට්", NameTa: "ஹொப்பர்ஸ் ஸ்பாட்",
			Description: "Crispy hoppers and string hoppers with sambol", DescSi: "හැපෙනසුළු ආප්ප සහ ඉඳිආප්ප සම්බෝල සමඟ", DescTa: "மிருதுவான அப்பம் மற்றும் இடியாப்பம் சம்பலுடன்",
			Address: "78 Marine Drive, Colombo 07", Latitude: 6.9120, Longitude: 79.8530,
			CuisineTags: []string{"Hoppers", "Sri Lankan", "Breakfast"}, ImageSeed: "hoppers",
		},
		{
			Name: "Pittu Place", NameSi: "පිට්ටු ප්ලේස්", NameTa: "பிட்டு பிளேஸ்",
			Description: "Authentic pittu with coconut and various curries", DescSi: "පොල් සහ විවිධ ව්‍යංජන සමඟ සැබෑ පිට්ටු", DescTa: "தேங்காய் மற்றும் பல்வேறு கறிகளுடன் உண்மையான பிட்டு",
			Address: "56 Highlevel Road, Nugegoda", Latitude: 6.8670, Longitude: 79.8930,
			CuisineTags: []string{"Pittu", "Sri Lankan", "Traditional"}, ImageSeed: "pittu",
		},
		{
			Name: "Lamprais Lanka", NameSi: "ලම්ප්‍රයිස් ලංකා", NameTa: "லம்ப்ரைஸ் லங்கா",
			Description: "Dutch-Burgher style lamprais with all traditional accompaniments", DescSi: "ලන්දේසි-බර්ගර් විලාසිතාවේ ලම්ප්‍රයිස් සියළු සාම්ප්‍රදායික අනුභව සමඟ", DescTa: "டச்சு-பெர்கர் பாணி லம்ப்ரைஸ் அனைத்து பாரம்பரிய துணை உணவுகளுடன்",
			Address: "23 Dickmans Road, Colombo 05", Latitude: 6.8890, Longitude: 79.8710,
			CuisineTags: []string{"Lamprais", "Burgher", "Fusion"}, ImageSeed: "lamprais",
		},
		{
			Name: "Biryani Bistro", NameSi: "බිරියානි බිස්ට්‍රෝ", NameTa: "பிரியாணி பிஸ்ட்ரோ",
			Description: "Fragrant biryani with tender meat and aromatic rice", DescSi: "ඇරෝමැටික බිරියානි මෘදු මස් හා සුවඳ බත් සමඟ", DescTa: "மணம் மிக்க பிரியாணி மென்மையான இறைச்சி மற்றும் வாசனை சாதத்துடன்",
			Address: "310 Galle Road, Colombo 06", Latitude: 6.8810, Longitude: 79.8590,
			CuisineTags: []string{"Biryani", "Muslim", "Rice"}, ImageSeed: "biryani",
		},
		{
			Name: "String Hopper Hut", NameSi: "ඉඳිආප්ප හට්", NameTa: "இடியாப்ப ஹட்",
			Description: "Soft string hoppers with curry and coconut milk", DescSi: "මෘදු ඉඳිආප්ප ව්‍යංජන හා පොල් කිරි සමඟ", DescTa: "மென்மையான இடியாப்பம் கறி மற்றும் தேங்காய் பாலுடன்",
			Address: "89 Nawala Road, Nugegoda", Latitude: 6.8770, Longitude: 79.8860,
			CuisineTags: []string{"String Hoppers", "Sri Lankan", "Breakfast"}, ImageSeed: "string-hopper",
		},
		{
			Name: "Pol Roti Shop", NameSi: "පොල් රොටි ෂොප්", NameTa: "பொல் ரொட்டி கடை",
			Description: "Coconut roti with spicy sambol and dhal curry", DescSi: "පොල් රොටි කුළු සම්බෝල හා පරිප්පු ව්‍යංජන සමඟ", DescTa: "தேங்காய் ரொட்டி கார சம்பல் மற்றும் பருப்பு கறியுடன்",
			Address: "45 Stanley Road, Jaffna", Latitude: 9.6615, Longitude: 80.0255,
			CuisineTags: []string{"Pol Roti", "Sri Lankan", "Street Food"}, ImageSeed: "pol-roti",
		},
	}

	offers := []offerSeed{
		{RestaurantIdx: 0, Title: "Chicken Kottu Special", TitleSi: "චිකන් කොත්තු ස්පෙශල්", TitleTa: "சிக்கன் கொத்து ஸ்பெஷல்", Description: "Large chicken kottu with extra cheese and a drink", DescSi: "අමතර චීස් හා බීම සමග විශාල චිකන් කොත්තු", DescTa: "கூடுதல் சீஸ் மற்றும் பானத்துடன் பெரிய சிக்கன் கொத்து", OriginalPrice: 1500, OfferPrice: 990, ImageSeed: "chicken-kottu", DaysValid: 30},
		{RestaurantIdx: 0, Title: "Kottu Combo for Two", TitleSi: "දෙදෙනෙකුට කොත්තු කොම්බෝ", TitleTa: "இருவருக்கு கொத்து காம்போ", Description: "Two kottus, two drinks, and an extra side of sambol", DescSi: "කොත්තු දෙකක්, බීම දෙකක්, සහ අමතර සම්බෝල පැත්තක්", DescTa: "இரண்டு கொத்து, இரண்டு பானங்கள், மற்றும் கூடுதல் சம்பல் பக்க உணவு", OriginalPrice: 2800, OfferPrice: 1790, ImageSeed: "kottu-combo", DaysValid: 45},
		{RestaurantIdx: 1, Title: "Family Rice & Curry Bundle", TitleSi: "පවුල් බත් හා ව්‍යංජන බණ්ඩල්", TitleTa: "குடும்ப சாதமும் கறியும் தொகுப்பு", Description: "Rice and curry for 4 with 3 curries, papadum, and dessert", DescSi: "ව්‍යංජන 3ක්, පපඩම්, සහ අතුරුපස සමඟ 4 දෙනෙකුට බත් හා ව්‍යංජන", DescTa: "4 பேருக்கு சாதமும் கறியும் 3 கறிகள், பப்படம், மற்றும் இனிப்புடன்", OriginalPrice: 4500, OfferPrice: 2990, ImageSeed: "family-rice", DaysValid: 60},
		{RestaurantIdx: 1, Title: "Lunch Special Rice", TitleSi: "දිවා භෝජන විශේෂ බත්", TitleTa: "மதிய சிறப்பு சாதம்", Description: "Rice with 2 curries, salad, and a drink", DescSi: "ව්‍යංජන 2ක්, සලාදයක්, සහ බීමක් සමඟ බත්", DescTa: "2 கறிகள், சாலட், மற்றும் பானத்துடன் சாதம்", OriginalPrice: 1200, OfferPrice: 790, ImageSeed: "lunch-rice", DaysValid: 14},
		{RestaurantIdx: 2, Title: "Egg Hoppers 5 Pack", TitleSi: "බිත්තර ආප්ප 5ක පැක්", TitleTa: "முட்டை அப்பம் 5 பொதி", Description: "5 egg hoppers with lunu miris and coconut sambol", DescSi: "ලූනු මිරිස් හා පොල් සම්බෝල සමඟ බිත්තර ආප්ප 5ක්", DescTa: "லுனு மிரிஸ் மற்றும் தேங்காய் சம்பலுடன் 5 முட்டை அப்பம்", OriginalPrice: 800, OfferPrice: 550, ImageSeed: "egg-hoppers", DaysValid: 30},
		{RestaurantIdx: 2, Title: "Hoppers & Curry Breakfast", TitleSi: "ආප්ප හා ව්‍යංජන උදෑසන", TitleTa: "அப்பமும் கறியும் காலை உணவு", Description: "4 plain hoppers with potato curry and seeni sambol", DescSi: "අල ව්‍යංජන හා සීනි සම්බෝල සමඟ සාමාන්‍ය ආප්ප 4ක්", DescTa: "உருளைக்கிழங்கு கறி மற்றும் சீனி சம்பலுடன் 4 சாதாரண அப்பம்", OriginalPrice: 650, OfferPrice: 450, ImageSeed: "hoppers-breakfast", DaysValid: 21},
		{RestaurantIdx: 3, Title: "Pittu Platter", TitleSi: "පිට්ටු තැටිය", TitleTa: "பிட்டு தட்டு", Description: "Mixed pittu with coconut, curry, and seeni sambol", DescSi: "පොල්, ව්‍යංජන, සහ සීනි සම්බෝල සමඟ මිශ්‍ර පිට්ටු", DescTa: "தேங்காய், கறி, மற்றும் சீனி சம்பலுடன் கலவை பிட்டு", OriginalPrice: 900, OfferPrice: 650, ImageSeed: "pittu-platter", DaysValid: 30},
		{RestaurantIdx: 3, Title: "Pittu & Dhal Curry", TitleSi: "පිට්ටු හා පරිප්පු ව්‍යංජන", TitleTa: "பிட்டும் பருப்பு கறியும்", Description: "Coconut pittu with dhal curry and pol sambol", DescSi: "පරිප්පු ව්‍යංජන හා පොල් සම්බෝල සමඟ පොල් පිට්ටු", DescTa: "பருப்பு கறி மற்றும் தேங்காய் சம்பலுடன் தேங்காய் பிட்டு", OriginalPrice: 550, OfferPrice: 390, ImageSeed: "pittu-dhal", DaysValid: 14},
		{RestaurantIdx: 4, Title: "Lamprais Family Pack", TitleSi: "ලම්ප්‍රයිස් පවුල් පැක්", TitleTa: "லம்ப்ரைஸ் குடும்ப பொதி", Description: "Traditional lamprais for 2 with all accompaniments", DescSi: "සියළු අනුභව සමඟ 2 දෙනෙකුට සාම්ප්‍රදායික ලම්ප්‍රයිස්", DescTa: "அனைத்து துணை உணவுகளுடன் 2 பேருக்கு பாரம்பரிய லம்ப்ரைஸ்", OriginalPrice: 3200, OfferPrice: 2200, ImageSeed: "lamprais-family", DaysValid: 45},
		{RestaurantIdx: 4, Title: "Single Lamprais Meal", TitleSi: "තනි ලම්ප්‍රයිස් භෝජනය", TitleTa: "தனி லம்ப்ரைஸ் உணவு", Description: "Classic lamprais with rice, meat, sambol, and frikkadels", DescSi: "බත්, මස්, සම්බෝල, සහ ෆ්‍රිකැඩෙල්ස් සමඟ සම්භාව්‍ය ලම්ප්‍රයිස්", DescTa: "சாதம், இறைச்சி, சம்பல், மற்றும் ஃப்ரிக்கடெல்ஸுடன் கிளாசிக் லம்ப்ரைஸ்", OriginalPrice: 1500, OfferPrice: 1100, ImageSeed: "single-lamprais", DaysValid: 30},
		{RestaurantIdx: 5, Title: "Chicken Biryani Special", TitleSi: "චිකන් බිරියානි ස්පෙශල්", TitleTa: "சிக்கன் பிரியாணி ஸ்பெஷல்", Description: "Fragrant chicken biryani with raita and brinjal pickle", DescSi: "රයිතා හා වම්බටු අච්චාරු සමඟ ඇරෝමැටික චිකන් බිරියානි", DescTa: "ரைத்தா மற்றும் கத்தரிக்காய் ஊறுகாயுடன் மணம் மிக்க சிக்கன் பிரியாணி", OriginalPrice: 1800, OfferPrice: 1250, ImageSeed: "chicken-biryani", DaysValid: 21},
		{RestaurantIdx: 5, Title: "Mutton Biryani Feast", TitleSi: "මටන් බිරියානි මංගල්‍යය", TitleTa: "மட்டன் பிரியாணி விருந்து", Description: "Premium mutton biryani with extra meat, boiled egg, and salad", DescSi: "අමතර මස්, තම්බා බිත්තර, සහ සලාද සමඟ ප්‍රිමියම් මටන් බிரියානි", DescTa: "கூடுதல் இறைச்சி, வேக வைத்த முட்டை, மற்றும் சாலட்டுடன் பிரீமியம் மட்டன் பிரியாணி", OriginalPrice: 2500, OfferPrice: 1800, ImageSeed: "mutton-biryani", DaysValid: 30},
		{RestaurantIdx: 6, Title: "String Hopper & Kiri Hodi", TitleSi: "ඉඳිආප්ප හා කිරිහොදි", TitleTa: "இடியாப்பமும் தேங்காய் பால் கறியும்", Description: "Soft string hoppers with coconut milk curry and sambol", DescSi: "පොල් කිරි ව්‍යංජන හා සම්බෝල සමඟ මෘදු ඉඳිආප්ප", DescTa: "தேங்காய் பால் கறி மற்றும் சம்பலுடன் மென்மையான இடியாப்பம்", OriginalPrice: 600, OfferPrice: 420, ImageSeed: "string-hopper-meal", DaysValid: 14},
		{RestaurantIdx: 6, Title: "String Hopper Breakfast", TitleSi: "ඉඳිආප්ප උදෑසන", TitleTa: "இடியாப்ப காலை உணவு", Description: "8 string hoppers with pol sambol, seeni sambol, and dhal", DescSi: "පොල් සම්බෝල, සීනි සම්බෝල, සහ පරිප්පු සමඟ ඉඳිආප්ප 8ක්", DescTa: "தேங்காய் சம்பல், சீனி சம்பல், மற்றும் பருப்புடன் 8 இடியாப்பம்", OriginalPrice: 500, OfferPrice: 350, ImageSeed: "string-hopper-breakfast", DaysValid: 7},
		{RestaurantIdx: 7, Title: "Pol Roti with Sambol", TitleSi: "පොල් රොටි සම්බෝල සමඟ", TitleTa: "தேங்காய் ரொட்டி சம்பலுடன்", Description: "2 coconut rotis with lunu miris and fresh pol sambol", DescSi: "ලූනු මිරිස් හා නැවුම් පොල් සම්බෝල සමඟ පොල් රොටි 2ක්", DescTa: "லுனு மிரிஸ் மற்றும் புதிய தேங்காய் சம்பலுடன் 2 தேங்காய் ரொட்டி", OriginalPrice: 400, OfferPrice: 250, ImageSeed: "pol-roti-sambol", DaysValid: 14},
		{RestaurantIdx: 7, Title: "Pol Roti & Curry Combo", TitleSi: "පොල් රොටි හා ව්‍යංජන සංයෝගය", TitleTa: "தேங்காய் ரொட்டி மற்றும் கறி காம்போ", Description: "2 pol rotis with dhal curry and seeni sambol", DescSi: "පරිප්පු ව්‍යංජන හා සීනි සම්බෝල සමඟ පොල් රොටි 2ක්", DescTa: "பருப்பு கறி மற்றும் சீனி சம்பலுடன் 2 தேங்காய் ரொட்டி", OriginalPrice: 350, OfferPrice: 220, ImageSeed: "pol-roti-combo", DaysValid: 10},
		{RestaurantIdx: 0, Title: "Cheese Kottu Deluxe", TitleSi: "චීස් කොත්තු ඩීලක්ස්", TitleTa: "சீஸ் கொத்து டீலக்ஸ்", Description: "Cheese kottu with chicken, egg, and spicy sauce", DescSi: "චිකන්, බිත්තර, සහ කුළු සෝස් සමඟ චීස් කොත්තු", DescTa: "சிக்கன், முட்டை, மற்றும் காரமான சாஸுடன் சீஸ் கொத்து", OriginalPrice: 1800, OfferPrice: 1290, ImageSeed: "cheese-kottu", DaysValid: 30},
		{RestaurantIdx: 1, Title: "Seafood Rice & Curry", TitleSi: "මුහුදු ආහාර බත් හා ව්‍යංජන", TitleTa: "கடல் உணவு சாதமும் கறியும்", Description: "Rice with fish ambulance, prawn curry, and crab sambol", DescSi: "මාළු ඇම්බුල් තියල්, ඉස්සෝ ව්‍යංජන, සහ කකුළු සම්බෝල සමඟ බත්", DescTa: "மீன் அம்புல் தியல், இறால் கறி, மற்றும் நண்டு சம்பலுடன் சாதம்", OriginalPrice: 2200, OfferPrice: 1650, ImageSeed: "seafood-rice", DaysValid: 30},
	}

	sourceURLs := map[string]string{
		"kottu-house":             "https://images.unsplash.com/photo-1601050690597-df0568f70950?w=400&h=300&fit=crop",
		"rice-curry":              "https://images.unsplash.com/photo-1512058564366-18510be2db19?w=400&h=300&fit=crop",
		"hoppers":                 "https://images.unsplash.com/photo-1604909052743-94e838911d9a?w=400&h=300&fit=crop",
		"pittu":                   "https://images.unsplash.com/photo-1481931098730-318b6f776db0?w=400&h=300&fit=crop",
		"lamprais":                "https://images.unsplash.com/photo-1504674900247-0877df9cc836?w=400&h=300&fit=crop",
		"biryani":                 "https://images.unsplash.com/photo-1631452180519-c014fe946bc7?w=400&h=300&fit=crop",
		"string-hopper":           "https://images.unsplash.com/photo-1484723091739-30a097e8f929?w=400&h=300&fit=crop",
		"pol-roti":                "https://images.unsplash.com/photo-1506084869-89b14b2b4bf4?w=400&h=300&fit=crop",
		"chicken-kottu":           "https://images.unsplash.com/photo-1601050690597-df0568f70950?w=400&h=300&fit=crop",
		"kottu-combo":             "https://images.unsplash.com/photo-1553621042-f6e147245754?w=400&h=300&fit=crop",
		"family-rice":             "https://images.unsplash.com/photo-1512058564366-18510be2db19?w=400&h=300&fit=crop",
		"lunch-rice":              "https://images.unsplash.com/photo-1490645935967-10de6ba17061?w=400&h=300&fit=crop",
		"egg-hoppers":             "https://images.unsplash.com/photo-1604909052743-94e838911d9a?w=400&h=300&fit=crop",
		"hoppers-breakfast":       "https://images.unsplash.com/photo-1604909052743-94e838911d9a?w=400&h=300&fit=crop",
		"pittu-platter":           "https://images.unsplash.com/photo-1481931098730-318b6f776db0?w=400&h=300&fit=crop",
		"pittu-dhal":              "https://images.unsplash.com/photo-1540189549336-e6e99c3679fe?w=400&h=300&fit=crop",
		"lamprais-family":         "https://images.unsplash.com/photo-1504674900247-0877df9cc836?w=400&h=300&fit=crop",
		"single-lamprais":         "https://images.unsplash.com/photo-1551218805-3034e18d68a3?w=400&h=300&fit=crop",
		"chicken-biryani":         "https://images.unsplash.com/photo-1631452180519-c014fe946bc7?w=400&h=300&fit=crop",
		"mutton-biryani":          "https://images.unsplash.com/photo-1631452180519-c014fe946bc7?w=400&h=300&fit=crop",
		"string-hopper-meal":      "https://images.unsplash.com/photo-1484723091739-30a097e8f929?w=400&h=300&fit=crop",
		"string-hopper-breakfast": "https://images.unsplash.com/photo-1490645935967-10de6ba17061?w=400&h=300&fit=crop",
		"pol-roti-sambol":         "https://images.unsplash.com/photo-1506084869-89b14b2b4bf4?w=400&h=300&fit=crop",
		"pol-roti-combo":          "https://images.unsplash.com/photo-1476124369491-e7addf5dc371?w=400&h=300&fit=crop",
		"cheese-kottu":            "https://images.unsplash.com/photo-1601050690597-df0568f70950?w=400&h=300&fit=crop",
		"seafood-rice":            "https://images.unsplash.com/photo-1512058564366-18510be2db19?w=400&h=300&fit=crop",
	}

	tmpDir, err := os.MkdirTemp("", "nomnom-seed-*")
	if err != nil {
		log.Fatalf("Failed to create temp dir: %v", err)
	}
	defer os.RemoveAll(tmpDir)

	uploaded := make(map[string]string)

	for seed, url := range sourceURLs {
		ext := ".jpg"
		filePath := filepath.Join(tmpDir, seed+ext)

		if err := downloadImage(url, filePath); err != nil {
			fmt.Printf("  ⚠️  Download failed for %s: %v. Using fallback.\n", seed, err)
			fallbackFile := filepath.Join(tmpDir, seed+"-fallback"+ext)
			picsumURL := fmt.Sprintf("https://picsum.photos/seed/%s/400/300", seed)
			if err := downloadImage(picsumURL, fallbackFile); err != nil {
				fmt.Printf("  ❌ Fallback also failed for %s: %v\n", seed, err)
				continue
			}
			filePath = fallbackFile
		}

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
			coverImage = uploaded["kottu-house"]
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

		imageSeed := o.ImageSeed
		imgURL := uploaded[imageSeed]
		if imgURL == "" {
			imgURL = uploaded[restaurants[o.RestaurantIdx].ImageSeed]
		}
		if imgURL == "" {
			imgURL = uploaded["kottu-house"]
		}

		var imageURLs models.JSONStringSlice
		if imgURL != "" {
			imageURLs = []string{imgURL}
		}

		translations := buildTranslations(o.TitleSi, o.TitleTa, o.DescSi, o.DescTa, "title", "description")

		startDate := now.Add(-time.Duration(o.DaysValid/2) * 24 * time.Hour)
		endDate := now.Add(time.Duration(o.DaysValid) * 24 * time.Hour)

		offer := models.Offer{
			RestaurantID:  rid,
			Title:         o.Title,
			Description:   &o.Description,
			OriginalPrice: o.OriginalPrice,
			OfferPrice:    o.OfferPrice,
			ImageURLs:     imageURLs,
			StartDate:     &startDate,
			EndDate:       endDate,
			CreatedBy:     &adminID,
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

func downloadImage(url, filePath string) error {
	client := &http.Client{Timeout: 30 * time.Second}
	resp, err := client.Get(url)
	if err != nil {
		return fmt.Errorf("http get failed: %w", err)
	}
	defer resp.Body.Close()

	if resp.StatusCode != http.StatusOK {
		return fmt.Errorf("unexpected status: %d", resp.StatusCode)
	}

	out, err := os.Create(filePath)
	if err != nil {
		return fmt.Errorf("file create failed: %w", err)
	}
	defer out.Close()

	if _, err := io.Copy(out, resp.Body); err != nil {
		return fmt.Errorf("file write failed: %w", err)
	}
	return nil
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

	admin := models.User{
		Email:        cfg.Admin.Email,
		PasswordHash: hashedPassword,
		Name:         "Admin",
		Role:         models.RoleAdmin,
		IsActive:     true,
	}

	result := db.Where("email = ?", admin.Email).FirstOrCreate(&admin)
	if result.Error != nil {
		log.Fatalf("Failed to create admin user: %v", result.Error)
	}
	fmt.Printf("Admin user: %s (%s)\n", admin.Email, admin.ID.String())
	return admin.ID
}

func createRestaurantOwner(db *gorm.DB, cfg *config.Config) uuid.UUID {
	hashedPassword, err := hash.HashPassword("Owner@123")
	if err != nil {
		log.Fatalf("Failed to hash owner password: %v", err)
	}

	owner := models.User{
		Email:        "owner@nomnom.lk",
		PasswordHash: hashedPassword,
		Name:         "Test Owner",
		Role:         models.RoleRestaurantOwner,
		IsActive:     true,
	}

	result := db.Where("email = ?", owner.Email).FirstOrCreate(&owner)
	if result.Error != nil {
		log.Fatalf("Failed to create owner user: %v", result.Error)
	}
	fmt.Printf("Owner user: %s (%s)\n", owner.Email, owner.ID.String())
	return owner.ID
}
