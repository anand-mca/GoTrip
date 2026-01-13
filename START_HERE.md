# 🚀 GoTrip Backend Setup - Complete Installation Guide

## What You Have Now

Your GoTrip Flutter app now has complete **Supabase backend integration** ready! Here's what's been set up:

### ✅ Infrastructure Created

| Component | Status | Details |
|-----------|--------|---------|
| **Supabase Service** | ✅ Complete | Singleton service for all backend operations |
| **Authentication** | ✅ Ready | Signup/Login/Logout via email |
| **Database Schema** | ✅ Ready | 4 tables: profiles, trips, bookings, favorites |
| **Storage System** | ✅ Ready | 2 buckets: trips (images), avatars |
| **State Management** | ✅ Ready | AuthProvider & TripProvider |
| **Sample Data** | ✅ Included | 5 sample trips included |
| **Documentation** | ✅ Complete | 3 detailed guides |

---

## 🎯 Next Steps (Choose One)

### **OPTION A: Quick Setup (15 minutes)** ⚡
Perfect if you want to get running quickly.
1. Open: `QUICK_START.md`
2. Follow the 6 simple steps
3. Run your app

### **OPTION B: Detailed Setup (30 minutes)** 📚
Perfect if you want to understand everything.
1. Open: `SUPABASE_SETUP.md`
2. Follow detailed step-by-step instructions
3. Review all configurations

### **OPTION C: Just Reference** 📖
Perfect if you just want to understand what's available.
1. Open: `BACKEND_SUMMARY.md`
2. Review architecture and available methods
3. Check the code in `lib/services/supabase_service.dart`

---

## 📋 Setup Checklist

### Pre-Setup (5 min)
- [ ] Read this document
- [ ] Choose setup option above
- [ ] Have a web browser ready

### Supabase Account (5 min)
- [ ] Go to https://supabase.com
- [ ] Create free account
- [ ] Create new project named "gotrip"
- [ ] Wait for project to initialize

### Credentials (2 min)
- [ ] Go to Settings → API in Supabase
- [ ] Copy Project URL
- [ ] Copy Anon Public Key
- [ ] Edit `lib/config/supabase_config.dart`
- [ ] Paste credentials

### Database Setup (3 min)
- [ ] In Supabase, go to SQL Editor
- [ ] Create new query
- [ ] Copy SQL from setup guide
- [ ] Paste and run

### Storage Setup (2 min)
- [ ] Go to Storage tab
- [ ] Create "trips" bucket (public)
- [ ] Create "avatars" bucket (public)

### Final Test (2 min)
- [ ] Run `flutter pub get`
- [ ] Run `flutter run`
- [ ] Test signup/login

**Total Time: ~20 minutes**

---

## 📁 New Files Created

```
GoTrip/
├── QUICK_START.md                          ← START HERE!
├── SUPABASE_SETUP.md                       ← Detailed guide
├── BACKEND_SUMMARY.md                      ← Reference docs
└── gotrip_mobile/lib/
    ├── config/
    │   └── supabase_config.dart           ← ADD YOUR CREDENTIALS HERE
    ├── services/
    │   └── supabase_service.dart          ← Backend service (complete)
    ├── providers/
    │   ├── auth_provider.dart             ← Auth state (complete)
    │   └── trip_provider.dart             ← Trip state (complete)
    └── models/
        ├── trip_model.dart                ← Enhanced with fromJson
        └── user_model.dart                ← Enhanced with fromJson
```

---

## 🔑 Key Credentials You'll Need

From Supabase Dashboard → Settings → API:

```
SUPABASE_URL = https://[YOUR_PROJECT_ID].supabase.co
SUPABASE_ANON_KEY = eyJ... (long key)
```

⚠️ **Important**: 
- Anon key is safe to put in your app
- Service role key should NEVER be in your app
- These enable your app to connect to your database

---

## 💡 How It Works

### Flow Diagram
```
User opens app
    ↓
main.dart initializes Supabase
    ↓
User sees Login Screen
    ↓
User signs up/logs in
    ↓
Credentials sent to Supabase Auth
    ↓
Token received
    ↓
User can access app
    ↓
All data queries use SupabaseService
    ↓
Data stored in PostgreSQL database
    ↓
Images stored in Storage buckets
```

### Data Flow
```
Flutter Screen
    ↓
Provider (AuthProvider/TripProvider)
    ↓
SupabaseService (business logic)
    ↓
Supabase SDK
    ↓
Supabase Backend (Cloud)
    ↓
PostgreSQL Database + Storage
```

---

## 🎓 Using the Service in Your Code

### In Login Screen
```dart
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';

// In button onPressed:
final authProvider = context.read<AuthProvider>();
await authProvider.signIn(email, password);
```

### In Home Screen
```dart
import '../providers/trip_provider.dart';

@override
void initState() {
  super.initState();
  context.read<TripProvider>().fetchAllTrips();
}
```

### Direct Service Usage
```dart
import '../services/supabase_service.dart';

final supabase = SupabaseService();
List<Map> trips = await supabase.getAllTrips();
```

---

## 🗄️ Database Schema

### profiles
Stores user information
- Email, name, bio, avatar
- List of saved/booked trips
- Timestamps

### trips
All available trips
- Title, description, image
- Location, rating, price
- Difficulty, duration, amenities
- Group size, created by user

### bookings
Trip bookings made by users
- User ID, Trip ID
- Status (pending/confirmed/cancelled)
- Booking date, number of people
- Total price, special requests

### favorites
User's favorite trips
- User ID, Trip ID
- Timestamp
- Unique constraint (one per user/trip)

---

## 🔐 Security Features Already Enabled

✅ **Row Level Security (RLS)**
- Users can only see their own data
- Unless data is public (like trips)

✅ **Authentication**
- Email/password validation
- Secure password hashing
- Session tokens

✅ **API Keys**
- Anon key has limited permissions
- Service role key kept secret

---

## 🐛 Troubleshooting Quick Links

| Problem | Solution |
|---------|----------|
| "Initialization error" | Check credentials in supabase_config.dart |
| "Login fails" | Verify user exists in Supabase Auth tab |
| "No trips showing" | Check SQL ran successfully in SQL Editor |
| "Can't upload image" | Verify buckets are public in Storage |
| "Can't see other users' data" | This is correct! RLS is working |

See full troubleshooting in `SUPABASE_SETUP.md`

---

## 📞 Available Methods (SupabaseService)

### Auth Methods
```dart
signUp(email, password, name)
signIn(email, password)
signOut()
getCurrentUser()
authStateChanges()
```

### User Methods
```dart
getUserProfile(userId)
updateUserProfile(userId, updates)
```

### Trip Methods
```dart
getAllTrips()
getTripById(tripId)
searchTrips(query)
```

### Booking Methods
```dart
createBooking(userId, tripId, data)
getUserBookings(userId)
```

### Image Methods
```dart
uploadImage(bucket, file, userId)
listImages(bucket, userId)
deleteImage(bucket, fileName)
```

### Favorite Methods
```dart
addToFavorites(userId, tripId)
removeFromFavorites(userId, tripId)
getUserFavorites(userId)
isFavorite(userId, tripId)
```

See full documentation in `BACKEND_SUMMARY.md`

---

## ✨ What's Included in Free Tier

| Quota | Limit |
|-------|-------|
| Database Storage | 500 MB |
| File Storage | 1 GB |
| API Calls | 50,000/month |
| Bandwidth | 5 GB/month |
| Users | Unlimited |
| Concurrent Users | 5 |

Perfect for MVP and testing!

---

## 🚀 Performance Tips

1. **Use Caching**: Fetch data once and cache locally
2. **Pagination**: Fetch trips in batches for large datasets
3. **Indexing**: Indexes are created for common queries
4. **Image Optimization**: Resize images before uploading
5. **Batch Operations**: Multiple updates at once

---

## 📱 Testing Your Setup

After setup, test these features:

1. **Sign Up**
   - Open app, go to signup
   - Create account
   - Check Supabase Auth → Users panel

2. **Login**
   - Close app
   - Reopen
   - Login with credentials
   - Should see home screen with trips

3. **Browse Trips**
   - See 5 sample trips
   - Check ratings and prices
   - Verify trip details load

4. **Search**
   - Go to Explore
   - Search for location
   - Should return filtered results

5. **Favorites**
   - Click heart on trip card
   - Go to Profile
   - Should show in favorites

6. **Logout**
   - Click logout
   - Should return to login screen

---

## 📚 Learning Resources

- **Supabase Docs**: https://supabase.com/docs
- **PostgreSQL Guide**: https://www.postgresql.org/docs/
- **Flutter Provider**: https://pub.dev/packages/provider
- **REST API**: https://supabase.com/docs/guides/api

---

## ⏭️ Next Steps After Setup

1. ✅ Complete the 15-minute setup above
2. Update screens to use AuthProvider and TripProvider
3. Add image upload to profile/trip creation
4. Implement booking flow
5. Add notifications
6. Deploy to App Store / Play Store

---

## 🎉 Ready?

### Choose Your Path:

**👉 Fast Track**: Open `QUICK_START.md` now!

**📚 Detailed**: Open `SUPABASE_SETUP.md` for full walkthrough

**📖 Reference**: Open `BACKEND_SUMMARY.md` to explore features

---

## ✅ Verification Checklist

Before you start, verify these files exist:

- [ ] `lib/config/supabase_config.dart` - ✅ Created
- [ ] `lib/services/supabase_service.dart` - ✅ Created  
- [ ] `lib/providers/auth_provider.dart` - ✅ Created
- [ ] `lib/providers/trip_provider.dart` - ✅ Created
- [ ] `lib/main.dart` - ✅ Updated
- [ ] `pubspec.yaml` - ✅ Updated with Supabase

All files are created and ready! 🎊

---

**Time to get started: 15-30 minutes** ⏱️

**Difficulty: Easy** 😊

**Support: See SUPABASE_SETUP.md for help** 💡

---

*Last Updated: January 12, 2026*
*GoTrip Backend Integration Complete* ✨
