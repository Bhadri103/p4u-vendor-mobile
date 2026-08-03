# Vendor phone authentication setup

The Android application id is `com.p4u.p4u_vendor`.

The current vendor APK is signed with these certificate fingerprints:

- SHA-1: `E4:84:E2:E8:A3:D7:61:13:79:8A:90:4A:AF:58:6F:8D:0A:2D:F0:C5`
- SHA-256: `64:CE:96:78:6A:98:09:6F:E4:B4:74:77:78:67:34:F0:D1:CE:05:7C:0F:56:6A:1E:74:A1:49:5E:CD:FB:D9:06`

Add both fingerprints to the `com.p4u.p4u_vendor` Android app in Firebase,
download the refreshed `google-services.json`, and replace
`android/app/google-services.json` before producing the final distributed APK.

Phone authentication must also be enabled in Firebase Authentication.
