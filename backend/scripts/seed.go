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
	Name           string
	NameSi         string
	NameTa         string
	Description    string
	DescSi         string
	DescTa         string
	Address        string
	Latitude       float64
	Longitude      float64
	CuisineTags    []string
	ImageSeed      string
	OwnerEmail     string
	InstagramURL   string
	FacebookURL    string
	WebsiteURL     string
	OrderPlatforms []string
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

	mc, err := minio.New(cfg.R2.Endpoint, &minio.Options{
		Creds:        credentials.NewStaticV4(cfg.R2.AccessKeyID, cfg.R2.SecretAccessKey, ""),
		Secure:       cfg.R2.Secure,
		BucketLookup: minio.BucketLookupAuto,
	})
	if err != nil {
		log.Fatalf("Failed to create MinIO client: %v", err)
	}

	env := cfg.R2.Prefix
	if env == "" {
		env = "dev"
	}
	bucket := cfg.R2.Bucket

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

	fmt.Printf("Env prefix: %s | Bucket: %s | Secure: %v\n", env, bucket, cfg.R2.Secure)

	owners := createOwners(db)
	fmt.Println("Owners ready")
	for email, id := range owners {
		fmt.Printf("Created owner: %s -> %s\n", email, id)
	}

	restaurants := []restaurantSeed{
		{
			Name: "Pizza Hut", NameSi: "පිස්සා හට්", NameTa: "பிஸ்ஸா ஹட்",
			Description: "Delicious pizzas, pasta, and Italian dishes", DescSi: "රසවත් පිස්සා, පැස්ටා, සහ ඉතාලි කෑම", DescTa: "சுவையான பிஸ்ஸா, பாஸ்தா, மற்றும் இத்தாலிய உணவுகள்",
			Address: "55 Galle Road, Colombo 03", Latitude: 6.9020, Longitude: 79.8612,
			CuisineTags: []string{"Pizza", "Italian", "Fast Food"}, ImageSeed: "pizza-hut", OwnerEmail: "owner@nomnom.lk",
			InstagramURL: "https://www.instagram.com/pizzahut_srilanka/",
			FacebookURL:  "https://www.facebook.com/PizzaHutSriLanka/",
			WebsiteURL:   "https://www.pizzahut.lk/",
			OrderPlatforms: []string{"uber_eats", "pickme"},
		},
		{
			Name: "KFC", NameSi: "කේඑෆ්සී", NameTa: "கேஎப்சி",
			Description: "Fried chicken, burgers, and crispy treats", DescSi: "ෆ්‍රයිඩ් චිකන්, බර්ගර්, සහ හැපෙනසුළු කෑම", DescTa: "வறுத்த கோழி, பர்கர்கள், மற்றும் மிருதுவான தின்பண்டங்கள்",
			Address: "100 Galle Road, Colombo 04", Latitude: 6.8930, Longitude: 79.8560,
			CuisineTags: []string{"Fried Chicken", "Fast Food", "Burgers"}, ImageSeed: "kfc", OwnerEmail: "kfc@nomnom.lk",
			InstagramURL: "https://www.instagram.com/kfc_srilanka/",
			FacebookURL:  "https://www.facebook.com/KFCSriLanka/",
			WebsiteURL:   "https://www.kfc.lk/",
			OrderPlatforms: []string{"pickme", "uber_eats"},
		},
		{
			Name: "Bread Talk", NameSi: "බ්‍රෙඩ් ටෝක්", NameTa: "பிரெட் டாக்",
			Description: "Freshly baked breads, cakes, and pastries", DescSi: "නැවුම් බේක් කළ පාන්, කේක්, සහ පේස්ට්‍රි", DescTa: "புதிதாக சுடப்பட்ட ரொட்டிகள், கேக்குகள், மற்றும் பேஸ்ட்ரிகள்",
			Address: "22 Union Place, Colombo 02", Latitude: 6.9180, Longitude: 79.8540,
			CuisineTags: []string{"Bakery", "Cakes", "Pastries"}, ImageSeed: "bread-talk", OwnerEmail: "breadtalk@nomnom.lk",
			InstagramURL: "https://www.instagram.com/breadtalk_srilanka/",
			FacebookURL: "https://www.facebook.com/BreadTalkSriLanka/",
			WebsiteURL: "https://www.breadtalk.lk/",
		},
		{
			Name: "Keells", NameSi: "කීල්ස්", NameTa: "கீல்ஸ்",
			Description: "Quick bites, burgers, and crispy snacks", DescSi: "ඉක්මන් කෑම, බර්ගර්, සහ හැපෙනසුළු ස්නැක්ස්", DescTa: "விரைவு உணவுகள், பர்கர்கள், மற்றும் மிருதுவான தின்பண்டங்கள்",
			Address: "77 Havelock Road, Colombo 05", Latitude: 6.8780, Longitude: 79.8680,
			CuisineTags: []string{"Fast Food", "Burgers", "Snacks"}, ImageSeed: "keells", OwnerEmail: "keells@nomnom.lk",
			InstagramURL: "https://www.instagram.com/keells_srilanka/",
			FacebookURL: "https://www.facebook.com/KeellsSriLanka/",
			WebsiteURL: "https://www.keells.lk/",
		},
		{
			Name: "Fab", NameSi: "ෆැබ්", NameTa: "ஃபேப்",
			Description: "Cakes, pastries, and sweet treats", DescSi: "කේක්, පේස්ට්‍රි, සහ පැණි රස කෑම", DescTa: "கேக்குகள், பேஸ்ட்ரிகள், மற்றும் இனிப்பு தின்பண்டங்கள்",
			Address: "45 Nawala Road, Nugegoda", Latitude: 6.8720, Longitude: 79.8920,
			CuisineTags: []string{"Bakery", "Cakes", "Desserts"}, ImageSeed: "fab", OwnerEmail: "fab@nomnom.lk",
			InstagramURL: "https://www.instagram.com/fab_srilanka/",
			FacebookURL: "https://www.facebook.com/FabSriLanka/",
		},
		{
			Name: "Popeyes", NameSi: "පොප්අයිස්", NameTa: "பாப்ஐஸ்",
			Description: "Louisiana-style fried chicken and burgers", DescSi: "ලුසියානා විලාසිතාවේ ෆ්‍රයිඩ් චිකන් සහ බර්ගර්", DescTa: "லூசியானா பாணி வறுத்த கோழி மற்றும் பர்கர்கள்",
			Address: "200 Galle Road, Dehiwala", Latitude: 6.8570, Longitude: 79.8640,
			CuisineTags: []string{"Fried Chicken", "Fast Food", "Burgers"}, ImageSeed: "popeyes", OwnerEmail: "popeyes@nomnom.lk",
			InstagramURL: "https://www.instagram.com/popeyes_srilanka/",
			FacebookURL:  "https://www.facebook.com/PopeyesSriLanka/",
			WebsiteURL:   "https://www.popeyes.lk/",
			OrderPlatforms: []string{"uber_eats"},
		},
		{
			Name: "Solo Bowl", NameSi: "සොලෝ බෝල්", NameTa: "சோலோ பௌல்",
			Description: "Rice bowls, noodles, and Asian fusion", DescSi: "බත් බෝල, නූඩ්ල්ස්, සහ ආසියානු ෆියුෂන්", DescTa: "சாதம் பௌல்கள், நூடுல்ஸ், மற்றும் ஆசிய கலப்பு உணவுகள்",
			Address: "33 Horton Place, Colombo 07", Latitude: 6.9120, Longitude: 79.8710,
			CuisineTags: []string{"Rice Bowls", "Asian", "Noodles"}, ImageSeed: "solo-bowl", OwnerEmail: "solobowl@nomnom.lk",
			InstagramURL: "https://www.instagram.com/solobowl_lk/",
			FacebookURL: "https://www.facebook.com/SoloBowlLK/",
		},
		{
			Name: "Spar", NameSi: "ස්පාර්", NameTa: "ஸ்பார்",
			Description: "Desserts, cakes, and sweet delights", DescSi: "අතුරුපස, කේක්, සහ පැණි රස", DescTa: "இனிப்புகள், கேக்குகள், மற்றும் இனிப்பு விருந்துகள்",
			Address: "15 Station Road, Colombo 10", Latitude: 6.9300, Longitude: 79.8650,
			CuisineTags: []string{"Desserts", "Cakes", "Sweets"}, ImageSeed: "spar", OwnerEmail: "spar@nomnom.lk",
			FacebookURL: "https://www.facebook.com/SparSriLanka/",
		},
		{
			Name: "Street Burger", NameSi: "ස්ට්‍රීට් බර්ගර්", NameTa: "ஸ்ட்ரீட் பர்கர்",
			Description: "Gourmet burgers, fries, and American comfort food", DescSi: "ගවර්මෙට් බර්ගර්, ෆ්‍රයිස්, සහ ඇමරිකානු සැනසිලි කෑම", DescTa: "கார்மெட் பர்கர்கள், பொரியல்கள், மற்றும் அமெரிக்க இதமான உணவுகள்",
			Address: "88 Galle Road, Bambalapitiya", Latitude: 6.8850, Longitude: 79.8600,
			CuisineTags: []string{"Burgers", "American", "Fast Food"}, ImageSeed: "street-burger", OwnerEmail: "streetburger@nomnom.lk",
			InstagramURL: "https://www.instagram.com/streetburgerlk/",
			FacebookURL:  "https://www.facebook.com/StreetBurgerLK/",
			OrderPlatforms: []string{"pickme"},
		},
		{
			Name: "Subway", NameSi: "සබ්වේ", NameTa: "சப்வே",
			Description: "Fresh submarine sandwiches and salads", DescSi: "නැවුම් සබ්මැරීන් සැන්ඩ්විච් සහ සලාද", DescTa: "புதிய சப்மரைன் சாண்ட்விச்கள் மற்றும் சாலடுகள்",
			Address: "60 Galle Road, Colombo 03", Latitude: 6.9060, Longitude: 79.8580,
			CuisineTags: []string{"Sandwiches", "Healthy", "Fast Food"}, ImageSeed: "subway", OwnerEmail: "subway@nomnom.lk",
			InstagramURL: "https://www.instagram.com/subway_srilanka/",
			FacebookURL: "https://www.facebook.com/SubwaySriLanka/",
			WebsiteURL: "https://www.subway.lk/",
		},
		{
			Name: "Taco Bell", NameSi: "ටැකෝ බෙල්", NameTa: "டாகோ பெல்",
			Description: "Mexican-inspired tacos, burritos, and quesadillas", DescSi: "මෙක්සිකානු ආභාසයෙන් ටැකෝ, බුරිටෝ, සහ ක්වෙසාඩිලා", DescTa: "மெக்சிகன் பாணி டாகோஸ், புரிட்டோஸ், மற்றும் குவெசடிலாஸ்",
			Address: "120 Galle Road, Colombo 04", Latitude: 6.8950, Longitude: 79.8550,
			CuisineTags: []string{"Mexican", "Tacos", "Fast Food"}, ImageSeed: "taco-bell", OwnerEmail: "tacbell@nomnom.lk",
			InstagramURL: "https://www.instagram.com/tacobell_srilanka/",
			FacebookURL:  "https://www.facebook.com/TacoBellSriLanka/",
			OrderPlatforms: []string{"uber_eats"},
		},
	}

	offers := []offerSeed{
		{RestaurantIdx: 0, Title: "Grand Dipper", TitleSi: "ග්‍රෑන්ඩ් ඩිපර්", TitleTa: "கிராண்ட் டிப்பர்", Description: "Pizza Hut Grand Dipper — loaded with toppings", DescSi: "පීසා හට් ග්‍රෑන්ඩ් ඩිපර් — ටොපිං වලින් පිරුණු", DescTa: "பீஸ்ஸா ஹட் கிராண்ட் டிப்பர் — மேல்பாகங்களால் நிரப்பப்பட்டது", OriginalPrice: 2500, OfferPrice: 1590, ImageSeed: "pizza-hut-granddipper", DaysValid: 30},
		{RestaurantIdx: 0, Title: "Lunch Deals 2 for 1", TitleSi: "දිවා ආහාර ගනුදෙනු 2ක් 1ක මිලට", TitleTa: "மதிய உணவு ஒப்பந்தங்கள் 2 க்கு 1", Description: "Two lunch pizzas for the price of one at Pizza Hut", DescSi: "පීසා හට් හි දිවා ආහාර පීසා දෙකක් එකක මිලට", DescTa: "பீஸ்ஸா ஹட்டில் இரண்டு மதிய உணவு பீஸ்ஸாக்கள் ஒன்றின் விலையில்", OriginalPrice: 3000, OfferPrice: 1500, ImageSeed: "pizza-hut-lunch2", DaysValid: 45},
		{RestaurantIdx: 0, Title: "Lunch Pizza Deals", TitleSi: "දිවා ආහාර පීසා ගනුදෙනු", TitleTa: "மதிய உணவு பீஸ்ஸா ஒப்பந்தங்கள்", Description: "Special lunch pizza deals with a complimentary drink", DescSi: "නොමිලේ පානයක් සමඟ විශේෂ දිවා ආහාර පීසා ගනුදෙනු", DescTa: "இலவச பானத்துடன் சிறப்பு மதிய உணவு பீஸ்ஸா ஒப்பந்தங்கள்", OriginalPrice: 1800, OfferPrice: 1190, ImageSeed: "pizza-hut-lunch-pizza", DaysValid: 30},
		{RestaurantIdx: 0, Title: "Pepperoni Special", TitleSi: "පෙපරෝනි විශේෂ", TitleTa: "பெப்பரோனி ஸ்பெஷல்", Description: "Classic pepperoni pizza at a great price", DescSi: "සම්භාව්‍ය පෙපරෝනි පීසා විශිෂ්ට මිලකට", DescTa: "கிளாசிக் பெப்பரோனி பீஸ்ஸா சிறந்த விலையில்", OriginalPrice: 2200, OfferPrice: 1390, ImageSeed: "pizza1", DaysValid: 21},
		{RestaurantIdx: 0, Title: "Veggie Supreme", TitleSi: "වෙජී සුප්‍රීම්", TitleTa: "வேஜி சுப்ரீம்", Description: "Loaded veggie pizza with fresh garden toppings", DescSi: "නැවුම් එළවළු ටොපිං සහිත පීසා", DescTa: "புதிய காய்கறி மேல்பாகங்களுடன் ஏற்றப்பட்ட பீஸ்ஸா", OriginalPrice: 2000, OfferPrice: 1290, ImageSeed: "pizza2", DaysValid: 21},
		{RestaurantIdx: 1, Title: "8pc Chicken Bucket", TitleSi: "කුකුල් මස් කෑලි 8ක බාල්දිය", TitleTa: "8 துண்டு கோழி வாளி", Description: "8 pieces of fried chicken with fries and coleslaw", DescSi: "ප්‍රංශ ෆ්‍රයිස් සහ කොල්ස්ලෝ සමඟ බැදපු කුකුල් මස් කෑලි 8ක්", DescTa: "பொரியல் மற்றும் கோல்ஸ்லாவுடன் 8 துண்டுகள் வறுத்த கோழி", OriginalPrice: 2200, OfferPrice: 1590, ImageSeed: "kfc1", DaysValid: 30},
		{RestaurantIdx: 1, Title: "Family Chicken Bucket", TitleSi: "පවුලේ කුකුල් මස් බාල්දිය", TitleTa: "குடும்ப கோழி வாளி", Description: "12 pieces of fried chicken family bucket", DescSi: "බැදපු කුකුල් මස් කෑලි 12ක පවුල් බාල්දිය", DescTa: "12 துண்டுகள் வறுத்த கோழி குடும்ப வாளி", OriginalPrice: 3500, OfferPrice: 2490, ImageSeed: "kfc2", DaysValid: 45},
		{RestaurantIdx: 1, Title: "Chicken Bucket with Drink", TitleSi: "පානයක් සමඟ කුකුල් මස් බාල්දිය", TitleTa: "பானத்துடன் கோழி வாளி", Description: "6 pieces of fried chicken with a large drink", DescSi: "විශාල පානයක් සමඟ බැදපු කුකුල් මස් කෑලි 6ක්", DescTa: "ஒரு பெரிய பானத்துடன் 6 துண்டுகள் வறுத்த கோழி", OriginalPrice: 1600, OfferPrice: 1190, ImageSeed: "kfc3", DaysValid: 21},
		{RestaurantIdx: 2, Title: "Carrot Cake Offer", TitleSi: "කැරට් කේක් ගනුදෙනුව", TitleTa: "கேரட் கேக் சலுகை", Description: "Freshly baked carrot cake with cream cheese frosting", DescSi: "චීස් ක්‍රීම් අයිසිං සමඟ නැවුම්ව පුලුස්සන ලද කැරට් කේක්", DescTa: "கிரீம் சீஸ் ஐசிங்குடன் புதிதாக சுடப்பட்ட கேரட் கேக்", OriginalPrice: 1200, OfferPrice: 750, ImageSeed: "bread-talk-carrot", DaysValid: 14},
		{RestaurantIdx: 3, Title: "Burger Deal", TitleSi: "බර්ගර් ගනුදෙනුව", TitleTa: "பர்கர் சலுகை", Description: "Classic beef burger with fries and a drink", DescSi: "ප්‍රංශ ෆ්‍රයිස් සහ පානයක් සමඟ සම්භාව්‍ය හරක් මස් බර්ගර්", DescTa: "பொரியல் மற்றும் பானத்துடன் கிளாசிக் மாட்டிறைச்சி பர்கர்", OriginalPrice: 1100, OfferPrice: 750, ImageSeed: "keels-burgers", DaysValid: 21},
		{RestaurantIdx: 3, Title: "Crispy Combo", TitleSi: "ක්‍රිස්පි කොම්බෝ", TitleTa: "கிரிஸ்பி காம்போ", Description: "Crispy chicken strips with dip and fries", DescSi: "ඩිප් සහ ෆ්‍රයිස් සමඟ ක්‍රිස්පි චිකන් ස්ට්‍රිප්ස්", DescTa: "நனைத்து சாப்பிடும் சாஸ் மற்றும் பொரியலுடன் மிருதுவான சிக்கன் ஸ்ட்ரிப்ஸ்", OriginalPrice: 1300, OfferPrice: 890, ImageSeed: "keels-crispy", DaysValid: 30},
		{RestaurantIdx: 3, Title: "Fish Roll Pack", TitleSi: "මාළු රෝල් පැක් එක", TitleTa: "மீன் ரோல் பேக்", Description: "6 crispy fish rolls with spicy sauce", DescSi: "කුළුබඩු සහිත සෝස් සමඟ ක්‍රිස්පි මාළු රෝල් 6ක්", DescTa: "காரமான சாஸுடன் 6 மிருதுவான மீன் ரோல்கள்", OriginalPrice: 800, OfferPrice: 550, ImageSeed: "keels-fish-rolls", DaysValid: 14},
		{RestaurantIdx: 4, Title: "Chocolate Cake Slice", TitleSi: "චොකලට් කේක් කෑල්ල", TitleTa: "சாக்லேட் கேக் துண்டு", Description: "Rich chocolate cake slice with cream", DescSi: "ක්‍රීම් සමඟ පොහොසත් චොකලට් කේක් කෑල්ල", DescTa: "கிரீமுடன் ரிச் சாக்லேட் கேக் துண்டு", OriginalPrice: 600, OfferPrice: 390, ImageSeed: "fab-cake", DaysValid: 14},
		{RestaurantIdx: 4, Title: "Berry Cheesecake", TitleSi: "බෙරී චීස්කේක්", TitleTa: "பெர்ரி சீஸ்கேக்", Description: "Mixed berry cheesecake slice", DescSi: "මිශ්‍ර බෙරී චීස්කේක් කෑල්ල", DescTa: "கலப்பு பெர்ரி சீஸ்கேக் துண்டு", OriginalPrice: 750, OfferPrice: 490, ImageSeed: "fab-cake2", DaysValid: 14},
		{RestaurantIdx: 4, Title: "Combo Meal Deal", TitleSi: "කොම්බෝ ආහාර ගනුදෙනුව", TitleTa: "காம்போ உணவு சலுகை", Description: "Cake slice with coffee or tea", DescSi: "කෝපි හෝ තේ සමඟ කේක් කෑල්ලක්", DescTa: "காபி அல்லது தேநீருடன் கேக் துண்டு", OriginalPrice: 900, OfferPrice: 590, ImageSeed: "fab-combo", DaysValid: 21},
		{RestaurantIdx: 5, Title: "Chicken Burgers", TitleSi: "චිකන් බර්ගර්", TitleTa: "சிக்கன் பர்கர்கள்", Description: "2 crispy chicken burgers with fries", DescSi: "ප්‍රංශ ෆ්‍රයිස් සමඟ ක්‍රිස්පි චිකන් බර්ගර් 2ක්", DescTa: "பொரியலுடன் 2 மிருதுவான சிக்கன் பர்கர்கள்", OriginalPrice: 1800, OfferPrice: 1290, ImageSeed: "popeyes-burgers", DaysValid: 30},
		{RestaurantIdx: 6, Title: "Mongolian Rice Bowl", TitleSi: "මොංගෝලියානු රයිස් බවුල්", TitleTa: "மங்கோலியன் ரைஸ் பவுல்", Description: "Savory Mongolian rice bowl with your choice of protein", DescSi: "ඔබ කැමති ප්‍රෝටීන් සමඟ රසවත් මොංගෝලියානු රයිස් බවුල්", DescTa: "உங்கள் விருப்ப புரதத்துடன் சுவையான மங்கோலியன் ரைஸ் பவுல்", OriginalPrice: 1400, OfferPrice: 990, ImageSeed: "solo-bowl-rice", DaysValid: 21},
		{RestaurantIdx: 7, Title: "Strawberry Cheese Cake", TitleSi: "ස්ට්‍රෝබෙරි චීස්කේක්", TitleTa: "ஸ்ட்ராபெர்ரி சீஸ்கேக்", Description: "Creamy strawberry cheesecake slice", DescSi: "ක්‍රීමි ස්ට්‍රෝබෙරි චීස්කේක් කෑල්ල", DescTa: "கிரீமி ஸ்ட்ராபெர்ரி சீஸ்கேக் துண்டு", OriginalPrice: 850, OfferPrice: 550, ImageSeed: "spar-cake", DaysValid: 14},
		{RestaurantIdx: 8, Title: "Burger Trio", TitleSi: "බර්ගර් ත්‍රිත්වය", TitleTa: "பர்கர் மூன்று", Description: "Three gourmet burgers with truffle fries", DescSi: "ට්‍රෆල් ෆ්‍රයිස් සමඟ ප්‍රීමියම් බර්ගර් තුනක්", DescTa: "ட்ரஃபிள் பொரியலுடன் மூன்று கெளர்மெட் பர்கர்கள்", OriginalPrice: 3200, OfferPrice: 2190, ImageSeed: "street-burger3", DaysValid: 45},
		{RestaurantIdx: 8, Title: "Double Cheeseburger", TitleSi: "ඩබල් චීස්බර්ගර්", TitleTa: "இரட்டை சீஸ்பர்கர்", Description: "Double cheeseburger with bacon and onion rings", DescSi: "බේකන් සහ ළූණු මුදු සමඟ ඩබල් චීස්බර්ගර්", DescTa: "பேக்கன் மற்றும் வெங்காய மோதிரங்களுடன் இரட்டை சீஸ்பர்கர்", OriginalPrice: 1800, OfferPrice: 1290, ImageSeed: "street-burger2", DaysValid: 30},
		{RestaurantIdx: 8, Title: "Classic Burger Combo", TitleSi: "සම්භාව්‍ය බර්ගර් කොම්බෝ", TitleTa: "கிளாசிக் பர்கர் காம்போ", Description: "Classic beef burger combo with fries and a shake", DescSi: "ප්‍රංශ ෆ්‍රයිස් සහ මිල්ක්ෂේක් එකක් සමඟ සම්භාව්‍ය හරක් මස් බර්ගර්", DescTa: "பொரியல் மற்றும் மில்க்ஷேக்குடன் கிளாசிக் மாட்டிறைச்சி பர்கர்", OriginalPrice: 1500, OfferPrice: 990, ImageSeed: "street-burgers", DaysValid: 30},
		{RestaurantIdx: 9, Title: "Submarine Offer", TitleSi: "සබ්මැරීන් ගනුදෙනුව", TitleTa: "சப்மரைன் சலுகை", Description: "Footlong sub with your choice of fillings and a drink", DescSi: "ඔබ කැමති පිරවුම් සහ පානයක් සමඟ අඩි දිග සබ් එකක්", DescTa: "உங்கள் விருப்ப நிரப்புதல்கள் மற்றும் பானத்துடன் ஃபுட்லாங் சப்", OriginalPrice: 1600, OfferPrice: 1100, ImageSeed: "subway-sub", DaysValid: 30},
		{RestaurantIdx: 10, Title: "Taco Deal", TitleSi: "ටැකෝ ගනුදෙනුව", TitleTa: "டாகோ சலுகை", Description: "3 tacos with salsa, guacamole, and sour cream", DescSi: "සල්සා, ග්වාකමෝල් සහ ඇඹුල් ක්‍රීම් සමඟ ටැකෝ 3ක්", DescTa: "சல்சா, குவாக்கமோல் மற்றும் புளிப்பு கிரீமுடன் 3 டாகோக்கள்", OriginalPrice: 1500, OfferPrice: 990, ImageSeed: "taco-bell-tacos", DaysValid: 21},
	}

	samplesBase := "../assets/samples"

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

		slug := strings.ToLower(strings.ReplaceAll(r.Name, " ", "-"))

		var rest models.Restaurant
		result := db.Where("slug = ?", slug).First(&rest)
		if result.Error == nil {
			fmt.Printf("  ℹ️  Restaurant exists: %s (id: %s)\n", r.Name, rest.ID)
			restaurantIDs[i] = rest.ID
			continue
		}

		rest = models.Restaurant{
			Name:           r.Name,
			Slug:           slug,
			Description:    &r.Description,
			Address:        r.Address,
			Latitude:       &r.Latitude,
			Longitude:      &r.Longitude,
			CuisineTags:    r.CuisineTags,
			CoverImage:     &coverImage,
			OwnerID:        &ownerID,
			Status:         models.RestaurantApproved,
			IsFeatured:     i < 4,
			Translations:   translations,
			OrderPlatforms: r.OrderPlatforms,
		}
		if r.InstagramURL != "" {
			rest.InstagramURL = &r.InstagramURL
		}
		if r.FacebookURL != "" {
			rest.FacebookURL = &r.FacebookURL
		}
		if r.WebsiteURL != "" {
			rest.WebsiteURL = &r.WebsiteURL
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

		var existing models.Offer
		result := db.Where("restaurant_id = ? AND title = ?", rid, o.Title).First(&existing)
		if result.Error == nil {
			fmt.Printf("  ℹ️  Offer exists: %s\n", o.Title)
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
