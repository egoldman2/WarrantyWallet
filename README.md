# WarrantyWallet

An iOS app that scans your receipts with AI and keeps track of all your warranties in one place.

## What is it?

Ever lost a receipt and couldn't remember if your warranty was still valid? WarrantyWallet solves this by:

1. Taking a photo of your receipt
2. Using AI to extract the item details
3. Automatically finding your warranty info
4. Keeping everything organized

All your warranty info in your pocket.

## Features

- 📸 Scan receipts with your camera
- 🤖 AI automatically extracts item info
- 🔍 Finds warranty details automatically
- 📅 Tracks expiration dates
- 🗂️ Organized warranty dashboard
- 🔒 All your data stays on your phone

## How to Use

### Add a Warranty

1. Open app and tap the **+** button
2. Take a photo of your receipt or pick one from your phone
3. App scans the receipt and fills in the details
4. Tap **"Find Policy Online"** to get warranty info
5. Tap **"Save Item"**
6. Done! Warranty is saved

### View Warranties

- **Home screen** - See all warranties with status
- **Tap a warranty** - View full details, conditions, return window
- **Search** - Find warranties by item or store name

### Edit Warranties (not implemented yet)

- Tap **"Edit"** to change warranty period, return window, or conditions
- Tap warranty card to see full policy details

## Installation

### Requirements
- iPhone with iOS 26 or later
- Xcode 16+
- OpenAI API key 4o-mini

### Setup

1. Clone the repo
   ```bash
   git clone https://github.com/egoldman2/WarrantyWallet.git
   ```

2. Get an OpenAI API key
   - Go to https://platform.openai.com/api-keys
   - Create a new key

3. Add your API key
   - Open `Secrets.swift` in the project
   - Replace the empty key with your actual key
   ```swift
   static let openAIAPIKey: String = "your-key-here"
   ```

4. Open in Xcode and run
   ```bash
   open WarrantyWallet.xcodeproj
   ```

## How It Works

### Step 1: Scan Receipt
- Phone camera takes photo
- App uses OCR to read text from the image

### Step 2: Extract Info
- AI looks at the text and finds:
  - Item name
  - Store name
  - Price
  - Purchase date

### Step 3: Find Warranty
- App searches the web for warranty info
- Finds warranty length and conditions
- Finds return policy

### Step 4: Save
- Everything stored on your phone
- Shows up on your home screen

## File Structure

```
WarrantyWallet/
├── Models/
│   └── ReceiptData.swift          # Info from receipt
├── Services/
│   ├── OCRService.swift           # Reads text from images
│   ├── OpenAIService.swift        # Uses AI to extract info
│   └── WarrantyService.swift      # Manages warranties
├── Views/
│   ├── ContentView.swift          # Home screen
│   ├── AddWarrantyItemView.swift  # Add new warranty
│   ├── WarrantyItemDetailView.swift    # View warranty details
│   └── Other views...
├── Utils/
│   ├── Config.swift               # Settings
│   ├── Secrets.swift              # API keys
│   └── Persistence.swift          # Database setup
└── WarrantyWalletApp.swift        # App start
```

## Technology Used

- **SwiftUI** - How the UI looks
- **Core Data** - Saves all your warranties on your phone
- **Vision Framework** - Reads text from photos
- **OpenAI API** - AI that extracts info and searches for warranties

## What Gets Saved

For each warranty, we save:
- Item name, store, price
- Purchase date
- Receipt photo
- Warranty period (in months)
- Return window (in days)
- Warranty conditions
- Return policy info
- Links to warranty policies

## Permissions

The app needs:
- 📷 Camera - to take receipt photos
- 📷 Photos - to pick receipt images from your library

That's it. No other permissions needed.

## Privacy

- Your data stays on your phone only
- No cloud backup
- No account needed
- We don't track your data

## Troubleshooting

**"OpenAI API key not configured"**
- Check that your API key is in `Secrets.swift`
- Make sure it's valid 

**"No text found in image"**
- Take receipt photo in better lighting
- Make sure receipt is straight and clear
- Don't take photo at an angle

**"Warranty not found"**
- Website might not have the info
- You can manually add warranty details
- Try searching on retailer website
