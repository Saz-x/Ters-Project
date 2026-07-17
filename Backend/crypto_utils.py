import secrets
import pyotp
from cryptography.hazmat.primitives.ciphers.aead import AESGCM

# 1. Standard Banking Card Generator (Luhn Algorithm)
def generate_luhn_card_number(bin_prefix="400000") -> str:
    """
    Generates a valid 16-digit card number that passes the global Luhn algorithm check.
    """
    digits = [int(x) for x in bin_prefix]
    while len(digits) < 15:
        digits.append(secrets.randbelow(10))
        
    checksum = 0
    reverse_digits = digits[::-1]
    for i, digit in enumerate(reverse_digits):
        if i % 2 == 0:
            multiply_result = digit * 2
            checksum += multiply_result if multiply_result < 9 else multiply_result - 9
        else:
            checksum += digit
            
    check_digit = (10 - (checksum % 10)) % 10
    digits.append(check_digit)
    
    return "".join(map(str, digits))

# 2. Cryptographic Dynamic CVV Engine (TOTP - Time-Based One-Time Password)
def generate_dynamic_cvv(secret_key: str, interval_seconds: int = 30) -> str:
    """
    Generates a secure 3-digit CVV token that automatically rotates based on the time window.
    """
    totp = pyotp.TOTP(secret_key, digits=3, interval=interval_seconds)
    return totp.now()

def verify_dynamic_cvv(secret_key: str, user_cvv: str, interval_seconds: int = 30) -> bool:
    """
    Validates the user's submitted dynamic CVV against the current time window.
    """
    totp = pyotp.TOTP(secret_key, digits=3, interval=interval_seconds)
    return totp.verify(user_cvv)

# 3. Data-at-Rest Encryption Protocol (AES-256-GCM)
def generate_system_encryption_key() -> bytes:
    """Generates a cryptographically strong 256-bit encryption key."""
    return AESGCM.generate_key(bit_length=256)

def encrypt_sensitive_data(plain_text: str, key: bytes) -> dict:
    """Encrypts card numbers or sensitive strings using AES-GCM protocol."""
    aesgcm = AESGCM(key)
    nonce = secrets.token_bytes(12)  # Unique initialization vector
    encrypted_bytes = aesgcm.encrypt(nonce, plain_text.encode(), None)
    
    return {
        "encrypted_data": encrypted_bytes.hex(),
        "nonce": nonce.hex()
    }

def decrypt_sensitive_data(encrypted_hex: str, nonce_hex: str, key: bytes) -> str:
    """Decrypts ciphertexts back into readable plain text."""
    aesgcm = AESGCM(key)
    decrypted_bytes = aesgcm.decrypt(bytes.fromhex(nonce_hex), bytes.fromhex(encrypted_hex), None)
    return decrypted_bytes.decode()