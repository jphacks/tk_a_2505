export const assetPrefix =
  process.env.USE_BASE_PATH === "true" ? "/tk_a_2505" : "";

export function withAssetPrefix(path: string) {
  return `${assetPrefix}${path}`;
}
