const webpack = require('webpack');

module.exports = function override(config, env) {
  // Ensure resolve.alias exists
  if (!config.resolve) config.resolve = {};
  if (!config.resolve.alias) config.resolve.alias = {};
  
  // Fix for @react-native-async-storage/async-storage in web environment
  config.resolve.alias['@react-native-async-storage/async-storage'] = require.resolve('localforage');
  
  // Fix for openapi-fetch with MetaMask SDK - ensure correct resolution
  config.resolve.alias['openapi-fetch'] = require.resolve('openapi-fetch/dist/index.js');
  
  // Fix process/browser resolution (critical for RainbowKit)
  config.resolve.alias['process/browser'] = require.resolve('process/browser.js');

  // Fix for openapi-fetch with MetaMask SDK
  config.resolve.fallback = {
    ...config.resolve.fallback,
    'stream': require.resolve('stream-browserify'),
    'util': require.resolve('util'),
    'process': require.resolve('process/browser.js'),
  };

  // Add plugins for global polyfills
  config.plugins = [
    ...config.plugins,
    new webpack.ProvidePlugin({
      process: 'process/browser.js',
      Buffer: ['buffer', 'Buffer'],
    }),
  ];

  // Ignore source map warnings for node_modules
  config.ignoreWarnings = [
    /Failed to parse source map/,
  ];

  return config;
};

