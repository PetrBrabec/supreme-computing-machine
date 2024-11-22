/**
 * Replaces placeholders in the template with corresponding values from variables.
 * @param {string} template - The template string containing placeholders.
 * @param {Record<string, string>} variables - Object containing key-value pairs for replacement.
 * @returns {string} - The interpolated string.
 */
export function interpolate(template: string, variables: Record<string, string>): string {
  return template.replace(/\${(.*?)}/g, (_, key) => variables[key.trim()] || '');
}
