# Secrets Directory

This directory contains sensitive configuration files that should never be committed to version control.

## Firebase Admin SDK

1. Go to [Firebase Console](https://console.firebase.google.com/)
2. Select your project
3. Go to Project Settings > Service Accounts
4. Click "Generate new private key"
5. Save the downloaded JSON file as `firebase-admin.json` in this directory

## File Structure

```
secrets/
├── firebase-admin.json          # Firebase service account key (REQUIRED)
├── firebase-admin.json.example  # Example template
└── README.md                    # This file
```

## Security Notes

- Never commit actual credential files to version control
- Keep the `firebase-admin.json` file secure and private
- Use appropriate file permissions to restrict access
- Rotate service account keys periodically for security

## Optional: Disable Authentication

If you don't want to use Firebase authentication:

1. Remove or rename `firebase-admin.json`
2. The service will automatically disable authentication
3. All requests will be treated as anonymous users with `farmer` role

This is useful for development and testing environments.