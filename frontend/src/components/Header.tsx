import React from 'react';
import { ConnectButton } from '@rainbow-me/rainbowkit';
import { Bars3Icon, SunIcon, MoonIcon } from '@heroicons/react/24/outline';

interface HeaderProps {
  onMenuClick: () => void;
  onThemeToggle: () => void;
  theme: 'light' | 'dark';
}

const Header: React.FC<HeaderProps> = ({ onMenuClick, onThemeToggle, theme }) => {
  return (
    <header className="backdrop-blur-md bg-gray-900/30 border-b border-gray-700/50 shadow-xl">
      <div className="px-4 sm:px-6 lg:px-8">
        <div className="flex justify-between items-center h-16">
          {/* Left side - Menu button and logo */}
          <div className="flex items-center">
            <button
              type="button"
              className="lg:hidden p-2 rounded-xl bg-white/10 backdrop-blur-sm border border-white/20 text-white hover:bg-white/20 focus:outline-none focus:ring-2 focus:ring-blue-400/50 transition-all duration-200"
              onClick={onMenuClick}
            >
              <Bars3Icon className="h-6 w-6" />
            </button>
            
            <div className="flex items-center ml-4 lg:ml-0">
              <div className="flex-shrink-0 flex items-center">
                <div className="h-10 w-10 bg-gradient-to-br from-cyan-400 via-blue-500 to-purple-600 rounded-xl flex items-center justify-center shadow-lg shadow-blue-500/25">
                  <span className="text-white font-bold text-lg">M</span>
                </div>
                <h1 className="ml-3 text-xl font-bold bg-gradient-to-r from-white to-gray-300 bg-clip-text text-transparent">
                  MEVShield Pool
                </h1>
              </div>
            </div>
          </div>

          {/* Center - Network status indicator */}
          <div className="hidden md:flex items-center space-x-4">
            <div className="flex items-center space-x-2 px-4 py-2 rounded-full bg-green-500/20 border border-green-400/30 backdrop-blur-sm">
              <div className="h-2 w-2 bg-green-400 rounded-full animate-pulse shadow-lg shadow-green-400/50"></div>
              <span className="text-sm text-green-200 font-medium">
                Network Active
              </span>
            </div>
          </div>

          {/* Right side - Theme toggle and wallet connection */}
          <div className="flex items-center space-x-4">
            {/* Theme toggle */}
            <button
              type="button"
              className="p-2 rounded-xl bg-white/10 backdrop-blur-sm border border-white/20 text-white hover:bg-white/20 focus:outline-none focus:ring-2 focus:ring-blue-400/50 transition-all duration-200"
              onClick={onThemeToggle}
            >
              {theme === 'dark' ? (
                <SunIcon className="h-5 w-5" />
              ) : (
                <MoonIcon className="h-5 w-5" />
              )}
            </button>

            {/* Wallet connection */}
            <div className="rounded-xl overflow-hidden">
              <ConnectButton 
                accountStatus={{
                  smallScreen: 'avatar',
                  largeScreen: 'full',
                }}
                chainStatus={{
                  smallScreen: 'icon',
                  largeScreen: 'full',
                }}
                showBalance={{
                  smallScreen: false,
                  largeScreen: true,
                }}
              />
            </div>
          </div>
        </div>
      </div>
    </header>
  );
};

export default Header;