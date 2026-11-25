/**
 * Encrypts a JSON payload using AES-256-GCM.
 * @param {Object} payload - The JSON body to encrypt.
 * @param {string} base64Key - The payloadEncryptionKey received during login.
 * @returns {Promise<string>} - Returns "Base64(IV):Base64(Ciphertext)"
 */
export async function encryptPayload(payload, base64Key) {
  if (!base64Key) throw new Error("No session key found");

  // 1. Convert JSON payload to bytes
  const encoder = new TextEncoder();
  const data = encoder.encode(JSON.stringify(payload));

  // 2. Decode the Base64 Session Key to bytes
  const keyBytes = Uint8Array.from(atob(base64Key), (c) => c.charCodeAt(0));

  // 3. Import the key into the Web Crypto API
  const cryptoKey = await window.crypto.subtle.importKey(
    "raw",
    keyBytes,
    { name: "AES-GCM" },
    false,
    ["encrypt"],
  );

  // 4. Generate a random 12-byte Initialization Vector (IV)
  const iv = window.crypto.getRandomValues(new Uint8Array(12));

  // 5. Encrypt the data
  const encryptedBuffer = await window.crypto.subtle.encrypt(
    { name: "AES-GCM", iv: iv },
    cryptoKey,
    data,
  );

  // 6. Convert IV and Ciphertext to Base64
  const base64Iv = btoa(String.fromCharCode(...iv));
  const base64CipherText = btoa(
    String.fromCharCode(...new Uint8Array(encryptedBuffer)),
  );

  // 7. Return in the exact format the backend expects
  return `${base64Iv}:${base64CipherText}`;
}

export async function decryptPayload(encryptedText, base64Key) {
  if (!base64Key) {
    throw new Error("No session key found");
  }

  const [base64Iv, base64CipherText] = encryptedText.split(":");

  const iv = Uint8Array.from(atob(base64Iv), (c) => c.charCodeAt(0));

  const encryptedBytes = Uint8Array.from(atob(base64CipherText), (c) =>
    c.charCodeAt(0),
  );

  const keyBytes = Uint8Array.from(atob(base64Key), (c) => c.charCodeAt(0));

  const cryptoKey = await window.crypto.subtle.importKey(
    "raw",
    keyBytes,
    { name: "AES-GCM" },
    false,
    ["decrypt"],
  );

  const decryptedBuffer = await window.crypto.subtle.decrypt(
    {
      name: "AES-GCM",
      iv,
    },
    cryptoKey,
    encryptedBytes,
  );

  return new TextDecoder().decode(decryptedBuffer);
}
