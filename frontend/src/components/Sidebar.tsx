import React from 'react';
import { NavLink } from 'react-router-dom';
import { 
  HomeIcon, 
  ChartBarIcon, 
  CurrencyDollarIcon,
  Cog6ToothIcon,
  BeakerIcon,
  XMarkIcon 
} from '@heroicons/react/24/outline';
import { useWeb3 } from '../contexts/Web3Context';

interface SidebarProps {
  isOpen: boolean;
  onClose: () => void;
}

const Sidebar: React.FC<SidebarProps> = ({ isOpen, onClose }) => {
  const { mevMetrics, activeAuctions, activePools } = useWeb3();

  const navigation = [
    {
      name: 'Dashboard',
      href: '/dashboard',
      icon: HomeIcon,
      badge: null,
    },
    {
      name: 'MEV Auctions',
      href: '/auction',
      icon: CurrencyDollarIcon,
      badge: activeAuctions.length > 0 ? activeAuctions.length : null,
    },
    {
      name: 'Pool Management',
      href: '/pools',
      icon: BeakerIcon,
      badge: activePools.length > 0 ? activePools.length : null,
    },
    {
      name: 'Analytics',
      href: '/analytics',
      icon: ChartBarIcon,
      badge: null,
    },
    {
      name: 'Settings',
      href: '/settings',
      icon: Cog6ToothIcon,
      badge: null,
    },
  ];

  return (
    <>
      {/* Mobile backdrop */}
      {isOpen && (
        <div 
          className="fixed inset-0 z-40 bg-gray-600 bg-opacity-75 lg:hidden"
          onClick={onClose}
        />
      )}

      {/* Sidebar */}
      <div className={`
        fixed inset-y-0 left-0 z-50 w-64 bg-white dark:bg-gray-800 shadow-lg transform transition-transform duration-300 ease-in-out lg:translate-x-0 lg:static lg:inset-0
        ${isOpen ? 'translate-x-0' : '-translate-x-full'}
      `}>
        <div className="flex flex-col h-full">
          {/* Header */}
          <div className="flex items-center justify-between h-16 px-6 border-b border-gray-200 dark:border-gray-700">
            <div className="flex items-center">
              <div className="h-8 w-8 bg-gradient-to-r from-blue-500 to-purple-600 rounded-lg flex items-center justify-center">
                <span className="text-white font-bold text-sm">M</span>
              </div>
              <span className="ml-3 text-lg font-semibold text-gray-900 dark:text-white">
                MEVShield
              </span>
            </div>
            <button
              className="lg:hidden p-2 rounded-md text-gray-400 hover:text-gray-500 hover:bg-gray-100 dark:hover:bg-gray-700"
              onClick={onClose}
            >
              <XMarkIcon className="h-5 w-5" />
            </button>
          </div>

          {/* Navigation */}
          <nav className="flex-1 px-4 py-6 space-y-2">
            {navigation.map((item) => (
              <NavLink
                key={item.name}
                to={item.href}
                className={({ isActive }) =>
                  `group flex items-center px-3 py-2 text-sm font-medium rounded-md transition-colors duration-200 ${
                    isActive
                      ? 'bg-blue-100 dark:bg-blue-900 text-blue-700 dark:text-blue-200'
                      : 'text-gray-700 dark:text-gray-300 hover:bg-gray-100 dark:hover:bg-gray-700 hover:text-gray-900 dark:hover:text-white'
                  }`
                }
              >
                <item.icon className="mr-3 h-5 w-5 flex-shrink-0" />
                <span className="flex-1">{item.name}</span>
                {item.badge && (
                  <span className="ml-2 inline-flex items-center px-2 py-0.5 rounded-full text-xs font-medium bg-blue-100 dark:bg-blue-900 text-blue-800 dark:text-blue-200">
                    {item.badge}
                  </span>
                )}
              </NavLink>
            ))}
          </nav>

          {/* Stats Summary */}
          <div className="px-4 py-6 border-t border-gray-200 dark:border-gray-700">
            <div className="space-y-4">
              <div className="text-xs text-gray-500 dark:text-gray-400 uppercase tracking-wide font-semibold">
                Quick Stats
              </div>
              
              <div className="space-y-3">
                <div className="flex justify-between">
                  <span className="text-sm text-gray-600 dark:text-gray-400">
                    Total MEV Prevented
                  </span>
                  <span className="text-sm font-medium text-gray-900 dark:text-white">
                    {mevMetrics.totalMEVPrevented.toString().slice(0, 6)}...
                  </span>
                </div>
                
                <div className="flex justify-between">
                  <span className="text-sm text-gray-600 dark:text-gray-400">
                    Active Auctions
                  </span>
                  <span className="text-sm font-medium text-gray-900 dark:text-white">
                    {activeAuctions.length}
                  </span>
                </div>
                
                <div className="flex justify-between">
                  <span className="text-sm text-gray-600 dark:text-gray-400">
                    Total Pools
                  </span>
                  <span className="text-sm font-medium text-gray-900 dark:text-white">
                    {activePools.length}
                  </span>
                </div>
              </div>
            </div>
          </div>
        </div>
      </div>
    </>
  );
};

export default Sidebar;