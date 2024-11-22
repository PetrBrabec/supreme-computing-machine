/**
 * Parses a .env file and returns an object with key-value pairs.
 * @param {string} filePath - Path to the .env file.
 * @returns {Record<string, string>} - Object containing environment variables as key-value pairs.
 */
export function parseEnvFile(envContent: string): Record<string, string> {
  return envContent.split('\n').reduce<Record<string, string>>((acc, line) => {
    const trimmedLine = line.trim();
    // Ignore empty lines and comments
    if (!trimmedLine || trimmedLine.startsWith('#')) {
      return acc;
    }
    const [key, ...valueParts] = trimmedLine.split('=');
    const value = valueParts.join('=').trim().replace(/^['"]|['"]$/g, '');
    acc[key.trim()] = value;
    return acc;
  }, {});
}