# Clubhouse Links — Cloud Mac Deployment Guide
## MacStadium / MacInCloud → App Store

---

## Prerequisites (do these before connecting to cloud Mac)

1. **Apple Developer Account** — $99/year at developer.apple.com
2. **App Store Connect** — Create your app listing at appstoreconnect.apple.com
   - App Name: Clubhouse Links
   - Bundle ID: com.clubhouselinks.resident
   - SKU: clubhouselinks-resident-001
3. **App-Specific Password** — Generate at appleid.apple.com → Security → App-Specific Passwords
4. **Your Team ID** — Found at developer.apple.com/account under Membership Details

---

## Step 1 — Provision Your Cloud Mac

### MacStadium
- Go to macstadium.com → sign up for an on-demand or dedicated Mac
- Choose macOS Ventura or Sonoma with Xcode 15 pre-installed
- Connect via their web VNC or SSH:
  ```
  ssh user@your-instance.macstadium.com
  ```

### MacInCloud
- Go to macincloud.com → choose a "Build" plan (cheapest for CI use)
- Connect via SSH from their dashboard
- Xcode is pre-installed; confirm with: `xcodebuild -version`

---

## Step 2 — Upload the Project

From your local machine, copy this entire folder to the cloud Mac:

```bash
scp -r ./ClubhouseResident user@your-cloud-mac-ip:~/ClubhouseResident
```

Or use the cloud Mac's built-in file transfer panel if connecting via VNC/remote desktop.

---

## Step 3 — Install Signing Certificate on the Cloud Mac

On the cloud Mac:

1. Open Keychain Access (if using VNC) or use the CLI:
   ```bash
   # Export your cert from your local Mac first:
   # Keychain Access → My Certificates → right-click → Export as .p12
   
   # Then on cloud Mac, import it:
   security import ~/YourCert.p12 -k ~/Library/Keychains/login.keychain-db -P "your-p12-password" -T /usr/bin/codesign
   ```

2. Verify the cert is visible:
   ```bash
   security find-identity -v -p codesigning
   # Should show: "Apple Distribution: Your Name (XXXXXXXXXX)"
   ```

---

## Step 4 — Configure the Project

Open these files and replace placeholder values:

| File | Key | Replace With |
|------|-----|-------------|
| `project.yml` | `DEVELOPMENT_TEAM` | Your 10-char Team ID |
| `project.yml` | `PRODUCT_BUNDLE_IDENTIFIER` | com.clubhouselinks.resident |
| `scripts/ExportOptions.plist` | `teamID` | Your 10-char Team ID |

---

## Step 5 — Run Setup

```bash
cd ~/ClubhouseResident
chmod +x scripts/*.sh
bash scripts/setup.sh
```

This will:
- Verify Xcode is installed
- Install Homebrew + XcodeGen
- Generate the `.xcodeproj` file from `project.yml`
- Confirm your signing certificate is present

---

## Step 6 — Build & Archive

```bash
bash scripts/build.sh
```

Output will be at: `./build/export/ClubhouseResident.ipa`

If you see signing errors, run:
```bash
xcodebuild -project ClubhouseResident.xcodeproj \
  -scheme ClubhouseResident \
  -showBuildSettings | grep DEVELOPMENT_TEAM
```

---

## Step 7 — Upload to App Store Connect

```bash
export APP_APPLE_ID="you@email.com"
export APP_PASSWORD="xxxx-xxxx-xxxx-xxxx"   # App-Specific Password
bash scripts/upload.sh
```

Then go to appstoreconnect.apple.com:
- Your build will appear under TestFlight within ~15 minutes
- Submit for App Review once you add screenshots + description

---

## App Store Listing Copy

**Name:** Clubhouse Links

**Subtitle:** Resident Portal for HOA Communities

**Description:**
Clubhouse Links is your all-in-one HOA resident portal. Stay connected with your community through real-time event updates, submit service and maintenance requests directly from your phone, and reach your community team in one tap.

Features:
- Community announcements and event calendar
- One-tap maintenance and service request submission
- Direct contact line to your community management team
- Built for Country Place and surrounding Plano neighborhoods

**Keywords:** HOA, resident portal, community, neighborhood, Plano, property management, events, maintenance

**Category:** Lifestyle

**Age Rating:** 4+

---

## Troubleshooting

**"No signing certificate found"**
→ Re-import your .p12 cert and run `security find-identity -v -p codesigning`

**"Bundle ID not found"**
→ Register com.clubhouselinks.resident at developer.apple.com/account/resources/identifiers

**"xcpretty: command not found"**
→ `gem install xcpretty` — or remove `| xcpretty` from build.sh

**"altool is deprecated" warning**
→ Safe to ignore for now; Apple is migrating to `notarytool` but altool still works for App Store uploads
