import React, { useState } from 'react';
import { useWeb3 } from '../contexts/Web3Context';
import { 
  Cog6ToothIcon, 
  ShieldCheckIcon, 
  BellIcon,
  EyeIcon,
  KeyIcon,
  GlobeAltIcon
} from '@heroicons/react/24/outline';

const Settings: React.FC = () => {
  const { isConnected } = useWeb3();
  
  const [notifications, setNotifications] = useState({
    auctionUpdates: true,
    poolUpdates: true,
    mevAlerts: true,
    systemUpdates: false,
  });

  const [privacy, setPrivacy] = useState({
    encryptBids: true,
    hideBidAmounts: false,
    anonymousMode: false,
  });

  const [preferences, setPreferences] = useState({
    autoRefresh: true,
    refreshInterval: 30,
    defaultGasPrice: 'medium',
    slippageTolerance: 0.5,
  });

  if (!isConnected) {
    return (
      <div className="min-h-96 flex items-center justify-center">
        <div className="text-center backdrop-blur-xl bg-gradient-to-br from-gray-800/40 to-gray-900/40 border border-gray-700/30 rounded-2xl p-8 shadow-2xl">
          <Cog6ToothIcon className="mx-auto h-16 w-16 text-gray-400 mb-4" />
          <h3 className="text-xl font-bold text-white mb-2">
            Connect Wallet
          </h3>
          <p className="text-gray-300">
            Connect your wallet to access settings.
          </p>
        </div>
      </div>
    );
  }

  return (
    <div className="space-y-8">
      {/* Header */}
      <div className="backdrop-blur-sm bg-gradient-to-r from-gray-800/30 to-gray-900/30 border border-gray-700/30 rounded-2xl p-6 shadow-xl">
        <h1 className="text-3xl font-bold bg-gradient-to-r from-orange-300 via-yellow-300 to-amber-300 bg-clip-text text-transparent">
          Settings
        </h1>
        <p className="mt-2 text-gray-300 font-medium">
          Configure your MEVShield Pool preferences and security settings
        </p>
      </div>

      <div className="grid grid-cols-1 lg:grid-cols-2 gap-8">
        {/* Notification Settings */}
        <div className="backdrop-blur-xl bg-gradient-to-br from-blue-800/40 to-cyan-900/40 border border-blue-700/30 rounded-2xl shadow-2xl shadow-blue-500/10">
          <div className="p-6">
            <div className="flex items-center justify-between mb-6">
              <h3 className="text-xl font-bold bg-gradient-to-r from-blue-300 to-cyan-300 bg-clip-text text-transparent">
                Notifications
              </h3>
              <div className="p-3 rounded-xl bg-blue-500/20 border border-blue-400/30 backdrop-blur-sm">
                <BellIcon className="h-6 w-6 text-blue-300" />
              </div>
            </div>

            <div className="space-y-4">
              {Object.entries(notifications).map(([key, value]) => (
                <div key={key} className="flex items-center justify-between p-4 bg-white/5 backdrop-blur-sm border border-white/10 rounded-xl">
                  <div>
                    <h4 className="text-white font-medium">
                      {key.replace(/([A-Z])/g, ' $1').replace(/^./, str => str.toUpperCase())}
                    </h4>
                    <p className="text-gray-400 text-sm">
                      {key === 'auctionUpdates' && 'Get notified about auction status changes'}
                      {key === 'poolUpdates' && 'Receive updates about your pool performance'}
                      {key === 'mevAlerts' && 'Alert when MEV opportunities are detected'}
                      {key === 'systemUpdates' && 'Important system and security updates'}
                    </p>
                  </div>
                  <label className="relative inline-flex items-center cursor-pointer">
                    <input
                      type="checkbox"
                      checked={value}
                      onChange={(e) => setNotifications(prev => ({
                        ...prev,
                        [key]: e.target.checked
                      }))}
                      className="sr-only peer"
                    />
                    <div className="w-11 h-6 bg-gray-700 peer-focus:outline-none peer-focus:ring-4 peer-focus:ring-blue-300/25 rounded-full peer peer-checked:after:translate-x-full peer-checked:after:border-white after:content-[''] after:absolute after:top-[2px] after:left-[2px] after:bg-white after:rounded-full after:h-5 after:w-5 after:transition-all peer-checked:bg-blue-600"></div>
                  </label>
                </div>
              ))}
            </div>
          </div>
        </div>

        {/* Privacy Settings */}
        <div className="backdrop-blur-xl bg-gradient-to-br from-purple-800/40 to-violet-900/40 border border-purple-700/30 rounded-2xl shadow-2xl shadow-purple-500/10">
          <div className="p-6">
            <div className="flex items-center justify-between mb-6">
              <h3 className="text-xl font-bold bg-gradient-to-r from-purple-300 to-violet-300 bg-clip-text text-transparent">
                Privacy & Security
              </h3>
              <div className="p-3 rounded-xl bg-purple-500/20 border border-purple-400/30 backdrop-blur-sm">
                <ShieldCheckIcon className="h-6 w-6 text-purple-300" />
              </div>
            <div className="space-y-4">
              {Object.entries(privacy).map(([key, value]) => (
                <div key={key} className="flex items-center justify-between p-4 bg-white/5 backdrop-blur-sm border border-white/10 rounded-xl">
                  <div>
                    <h4 className="text-white font-medium">
                      {key.replace(/([A-Z])/g, ' $1').replace(/^./, str => str.toUpperCase())}
                    </h4>
                    <p className="text-gray-400 text-sm">
                      {key === 'encryptBids' && 'Use Lit Protocol to encrypt all bid submissions'}
                      {key === 'hideBidAmounts' && 'Hide your bid amounts from the interface'}
                      {key === 'anonymousMode' && 'Enable anonymous participation in auctions'}
                    </p>
                  </div>
                  <label className="relative inline-flex items-center cursor-pointer">
                    <input
                      type="checkbox"
                      checked={value}
                      onChange={(e) => setPrivacy(prev => ({
                        ...prev,
                        [key]: e.target.checked
                      }))}
                      className="sr-only peer"
                    />
                    <div className="w-11 h-6 bg-gray-700 peer-focus:outline-none peer-focus:ring-4 peer-focus:ring-purple-300/25 rounded-full peer peer-checked:after:translate-x-full peer-checked:after:border-white after:content-[''] after:absolute after:top-[2px] after:left-[2px] after:bg-white after:rounded-full after:h-5 after:w-5 after:transition-all peer-checked:bg-purple-600"></div>
                  </label>
                </div>
              ))}
            </div>
          </div>
        </div>
      </div>

      {/* Advanced Preferences */}
      <div className="backdrop-blur-xl bg-gradient-to-br from-orange-800/40 to-amber-900/40 border border-orange-700/30 rounded-2xl shadow-2xl shadow-orange-500/10">
        <div className="p-6">
          <div className="flex items-center justify-between mb-6">
            <h3 className="text-xl font-bold bg-gradient-to-r from-orange-300 to-amber-300 bg-clip-text text-transparent">
              Advanced Preferences
            </h3>
            <div className="p-3 rounded-xl bg-orange-500/20 border border-orange-400/30 backdrop-blur-sm">
              <Cog6ToothIcon className="h-6 w-6 text-orange-300" />
            </div>
          </div>

          <div className="grid grid-cols-1 md:grid-cols-2 gap-6">
            <div className="space-y-4">
              <label className="block text-sm font-bold text-orange-200">
                Refresh Interval (seconds)
              </label>
              <select
                value={preferences.refreshInterval}
                onChange={(e) => setPreferences(prev => ({
                  ...prev,
                  refreshInterval: parseInt(e.target.value)
                }))}
                className="w-full px-4 py-3 bg-white/10 backdrop-blur-sm border border-white/20 rounded-xl text-white focus:outline-none focus:ring-2 focus:ring-orange-400/50 focus:border-orange-400/50 transition-all duration-200"
              >
                <option value={15} className="bg-gray-800">15 seconds</option>
                <option value={30} className="bg-gray-800">30 seconds</option>
                <option value={60} className="bg-gray-800">1 minute</option>
                <option value={300} className="bg-gray-800">5 minutes</option>
              </select>
            </div>

            <div className="space-y-4">
              <label className="block text-sm font-bold text-orange-200">
                Slippage Tolerance
              </label>
              <select
                value={preferences.slippageTolerance}
                onChange={(e) => setPreferences(prev => ({
                  ...prev,
                  slippageTolerance: parseFloat(e.target.value)
                }))}
                className="w-full px-4 py-3 bg-white/10 backdrop-blur-sm border border-white/20 rounded-xl text-white focus:outline-none focus:ring-2 focus:ring-orange-400/50 focus:border-orange-400/50 transition-all duration-200"
              >
                <option value={0.1} className="bg-gray-800">0.1%</option>
                <option value={0.5} className="bg-gray-800">0.5%</option>
                <option value={1.0} className="bg-gray-800">1.0%</option>
                <option value={2.0} className="bg-gray-800">2.0%</option>
              </select>
            </div>
          </div>
        </div>
      </div>
    </div>
  );
};

export default Settings;