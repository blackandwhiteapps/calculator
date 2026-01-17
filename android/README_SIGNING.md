# Android App Signing Setup

## Step 1: Generate a Keystore

Run the following command to generate a keystore file:

```bash
cd android
keytool -genkey -v -keystore keystore/calculator-release-key.jks -keyalg RSA -keysize 2048 -validity 10000 -alias calculator
```

You'll be prompted to:
- Enter a keystore password (remember this!)
- Re-enter the password
- Enter your name and organizational details
- Enter a key password (can be same as keystore password)

**Important:** Keep the keystore file and passwords secure. You'll need them to publish updates to your app.

## Step 2: Create key.properties

Copy the example file and fill in your passwords:

```bash
cp key.properties.example key.properties
```

Then edit `key.properties` and replace:
- `YOUR_STORE_PASSWORD` with your keystore password
- `YOUR_KEY_PASSWORD` with your key password

The file should look like:
```
storePassword=your_actual_store_password
keyPassword=your_actual_key_password
keyAlias=calculator
storeFile=keystore/calculator-release-key.jks
```

## Step 3: Create the keystore directory

```bash
cd android
mkdir -p keystore
```

The keystore will be generated directly in this location when you run the keytool command.

## Step 4: Build Release APK

Once configured, you can build a signed release APK:

```bash
flutter build apk --release
```

Or build an App Bundle for Google Play:

```bash
flutter build appbundle --release
```

## Security Notes

- The `key.properties` file and keystore files are already in `.gitignore` and will NOT be committed to git
- Never share your keystore file or passwords publicly
- Keep backups of your keystore in a secure location
- If you lose your keystore, you won't be able to update your app on Google Play

