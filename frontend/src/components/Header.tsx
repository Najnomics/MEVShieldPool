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
    <header className="bg-white dark:bg-gray-800 shadow-sm border-b border-gray-200 dark:border-gray-700">
      <div className="px-4 sm:px-6 lg:px-8">
        <div className="flex justify-between items-center h-16">
          {/* Left side - Menu button and logo */}
          <div className="flex items-center">
            <button
              type="button"
              className="lg:hidden p-2 rounded-md text-gray-400 hover:text-gray-500 hover:bg-gray-100 dark:hover:bg-gray-700 focus:outline-none focus:ring-2 focus:ring-inset focus:ring-blue-500"
              onClick={onMenuClick}
            >
              <Bars3Icon className="h-6 w-6" />
            </button>
            
            <div className="flex items-center ml-4 lg:ml-0">
              <div className="flex-shrink-0 flex items-center">
                <div className="h-8 w-8 bg-gradient-to-r from-blue-500 to-purple-600 rounded-lg flex items-center justify-center">
                  <span className="text-white font-bold text-sm">M</span>
                </div>
                <h1 className="ml-3 text-xl font-semibold text-gray-900 dark:text-white">
                  MEVShield Pool
                </h1>
              </div>
            </div>
          </div>

          {/* Center - Network status indicator */}
          <div className="hidden md:flex items-center space-x-4">
            <div className="flex items-center space-x-2">
              <div className="h-2 w-2 bg-green-400 rounded-full animate-pulse"></div>
              <span className="text-sm text-gray-600 dark:text-gray-300">
                Network Active
              </span>
            </div>
          </div>

          {/* Right side - Theme toggle and wallet connection */}
          <div className="flex items-center space-x-4">
            {/* Theme toggle */}
            <button
              type="button"
              className="p-2 rounded-md text-gray-400 hover:text-gray-500 hover:bg-gray-100 dark:hover:bg-gray-700 focus:outline-none focus:ring-2 focus:ring-inset focus:ring-blue-500"
              onClick={onThemeToggle}
            >
              {theme === 'dark' ? (
                <SunIcon className="h-5 w-5" />
              ) : (
                <MoonIcon className="h-5 w-5" />
              )}
            </button>

            {/* Wallet connection */}
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
    </header>
  );
};

export default Header;