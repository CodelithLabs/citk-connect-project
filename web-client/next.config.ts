import type { NextConfig } from "next";

const nextConfig: NextConfig = {
  output: 'export',
  // Required for free hosting (since there is no server to optimize images on the fly)
  images: {
    unoptimized: true,
  },
};

export default nextConfig;