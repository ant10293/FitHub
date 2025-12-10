"""
Generate unique affiliate links.

This script creates unique affiliate links in Firebase Firestore.
Each link is stored in the 'affiliateLinks' collection with:
- linkToken: unique token for the link
- createdAt: timestamp
- claimed: boolean flag (starts as False)
- claimedBy: userId who claimed it (set when link is claimed)
- claimedAt: timestamp when claimed (set when link is claimed)

IMPORTANT: The userId is NOT known at link generation time.
The userId is only stored when a user claims the link by installing
and opening the app.
"""

import argparse
import os
import secrets
import string
from pathlib import Path
from typing import Optional

try:
    from dotenv import load_dotenv
    # Try to load .env from payout_analytics directory (where it's typically stored)
    # Also try current directory and parent directories
    env_loaded = False
    for env_path in [
        Path(__file__).parent.parent / "payout_analytics" / ".env",
        Path(__file__).parent / ".env",
        Path.cwd() / ".env",
    ]:
        if env_path.exists():
            load_dotenv(env_path)
            env_loaded = True
            break
    if not env_loaded:
        load_dotenv()  # Try default locations
except ImportError:
    pass  # dotenv is optional

try:
    import firebase_admin
    from firebase_admin import credentials, firestore
except ImportError:
    print("Error: firebase-admin package not found.")
    print("Install it with: pip install firebase-admin")
    exit(1)


def generate_unique_token(length: int = 32) -> str:
    """Generate a cryptographically secure random token."""
    alphabet = string.ascii_letters + string.digits
    return ''.join(secrets.choice(alphabet) for _ in range(length))


def check_token_exists(db: firestore.Client, token: str) -> bool:
    """Check if a token already exists in the affiliateLinks collection."""
    try:
        # Query for documents with this linkToken
        # Use filter keyword argument to avoid deprecation warning
        from google.cloud.firestore_v1.base_query import FieldFilter
        query = db.collection('affiliateLinks').where(
            filter=FieldFilter('linkToken', '==', token)
        ).limit(1)
        docs = list(query.stream())
        return len(docs) > 0
    except Exception as e:
        print(f"Error checking token existence: {e}")
        return True  # Assume exists on error to be safe


def generate_unique_link_token(db: firestore.Client, max_attempts: int = 10) -> str:
    """Generate a unique link token that doesn't exist in the database."""
    for attempt in range(max_attempts):
        token = generate_unique_token()
        if not check_token_exists(db, token):
            return token
        print(f"Token collision detected (attempt {attempt + 1}/{max_attempts}), generating new token...")

    raise Exception(f"Failed to generate unique token after {max_attempts} attempts")


def create_affiliate_link(db: firestore.Client, base_url: Optional[str] = None) -> dict:
    """
    Create a unique affiliate link.

    Note: The userId is NOT known at link generation time. It will be stored
    when the link is claimed by a user.

    Args:
        db: Firestore client
        base_url: Optional base URL for the link (defaults to Firebase hosting URL)

    Returns:
        Dictionary with linkToken and fullUrl
    """
    # Generate unique token
    link_token = generate_unique_link_token(db)

    # Create document in affiliateLinks collection
    # userId will be set later when the link is claimed
    link_data = {
        'linkToken': link_token,
        'createdAt': firestore.SERVER_TIMESTAMP,
        'claimed': False,
        'claimedBy': None,  # Will be set when link is claimed
        'claimedAt': None,  # Will be set when link is claimed
    }

    # Use linkToken as document ID for easy lookup
    doc_ref = db.collection('affiliateLinks').document(link_token)
    doc_ref.set(link_data)

    # Generate full URL
    if base_url:
        full_url = f"{base_url}/affiliate/{link_token}"
    else:
        full_url = f"https://fithubv1-d3c91.web.app/affiliate/{link_token}"

    print(f"✅ Created affiliate link")
    print(f"   Token: {link_token}")
    print(f"   URL: {full_url}")

    return {
        'linkToken': link_token,
        'fullUrl': full_url,
        'alreadyExists': False,
        'documentId': link_token
    }


def main():
    parser = argparse.ArgumentParser(
        description='Generate unique affiliate links',
        formatter_class=argparse.RawDescriptionHelpFormatter,
        epilog="""
Examples:
  # Generate a new affiliate link (requires GOOGLE_APPLICATION_CREDENTIALS env var)
  export GOOGLE_APPLICATION_CREDENTIALS="/path/to/service-account.json"
  ./run_generate_affiliate_link.sh

  # Generate link with custom base URL
  ./run_generate_affiliate_link.sh --base-url https://example.com

  # Use --service-account parameter instead of env var
  ./run_generate_affiliate_link.sh --service-account /path/to/service-account.json
        """
    )

    parser.add_argument(
        '--base-url',
        default=None,
        help='Base URL for the affiliate link (defaults to Firebase hosting URL)'
    )

    parser.add_argument(
        '--service-account',
        default=None,
        help='Path to Firebase service account JSON file (or set GOOGLE_APPLICATION_CREDENTIALS env var)'
    )

    args = parser.parse_args()

    # Determine service account path
    service_account_path = None
    if args.service_account:
        service_account_path = Path(args.service_account).expanduser().resolve()
        if not service_account_path.exists():
            print(f"❌ Error: Service account file not found: {service_account_path}")
            exit(1)
    else:
        # Check environment variable (may be loaded from .env file)
        env_cred_path = os.getenv("GOOGLE_APPLICATION_CREDENTIALS")
        if env_cred_path:
            service_account_path = Path(env_cred_path).expanduser().resolve()
            if not service_account_path.exists():
                print(f"❌ Error: Service account file from GOOGLE_APPLICATION_CREDENTIALS not found: {service_account_path}")
                exit(1)

    if not service_account_path:
        print("❌ Error: Firebase service account credentials required")
        print("\nPlease provide credentials using one of these methods:")
        print("  1. Create a .env file in tools/payout_analytics/ with:")
        print("     GOOGLE_APPLICATION_CREDENTIALS=/path/to/service-account.json")
        print("  2. Set GOOGLE_APPLICATION_CREDENTIALS environment variable:")
        print("     export GOOGLE_APPLICATION_CREDENTIALS=/path/to/service-account.json")
        print("  3. Use --service-account parameter:")
        print("     ./tools/run_generate_affiliate_link.sh --service-account /path/to/service-account.json")
        exit(1)

    # Initialize Firebase Admin
    try:
        # Check if already initialized
        firebase_admin.get_app()
        print("✅ Firebase Admin already initialized")
    except ValueError:
        # Not initialized, initialize it with service account
        cred = credentials.Certificate(str(service_account_path))
        firebase_admin.initialize_app(cred)
        print(f"✅ Initialized Firebase Admin with service account: {service_account_path}")

    # Get Firestore client
    try:
        db = firestore.client()
    except Exception as e:
        print(f"❌ Error getting Firestore client: {e}")
        print("   Make sure your service account has Firestore permissions")
        exit(1)

    # Create affiliate link
    try:
        result = create_affiliate_link(db, args.base_url)

        print("\n" + "="*60)
        print("AFFILIATE LINK GENERATED")
        print("="*60)
        print(f"Link Token: {result['linkToken']}")
        print(f"Full URL: {result['fullUrl']}")
        print("\nNote: This link will be claimed by a user when they install")
        print("      and open the app. The userId will be stored at that time.")
        print("="*60)

    except Exception as e:
        print(f"❌ Error creating affiliate link: {e}")
        exit(1)


if __name__ == '__main__':
    main()
