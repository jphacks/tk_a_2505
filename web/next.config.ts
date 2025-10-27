import type { NextConfig } from "next";
import createNextIntlPlugin from "next-intl/plugin";

const withNextIntl = createNextIntlPlugin("./i18n/request.ts");

const useBasePath = process.env.USE_BASE_PATH === "true";

const nextConfig: NextConfig = {
  output: "export",
  basePath: useBasePath ? "/tk_a_2505" : "",
  assetPrefix: useBasePath ? "/tk_a_2505" : "",
  trailingSlash: true,
  images: {
    unoptimized: true,
  },
};

export default withNextIntl(nextConfig);
