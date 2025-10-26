const webpack = require('webpack');

module.exports = function override(config, env) {
  // Fix for @react-native-async-storage/async-storage in web environment
  config.resolve.alias = {
    ...config.resolve.alias,
    '@react-native-async-storage/async-storage': require.resolve('localforage'),
  };

  // Ignore source map warnings for node_modules
  config.ignoreWarnings = [
    /Failed to parse source map/,
  ];

  return config;
};

