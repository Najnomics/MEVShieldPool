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
          className="fixed inset-0 z-40 bg-black/50 backdrop-blur-sm lg:hidden"
          onClick={onClose}
        />
      )}

      {/* Sidebar */}
      <div className={`
        fixed inset-y-0 left-0 z-50 w-64 bg-gray-900/60 backdrop-blur-xl border-r border-gray-700/50 shadow-2xl transform transition-transform duration-300 ease-in-out lg:translate-x-0 lg:static lg:inset-0
        ${isOpen ? 'translate-x-0' : '-translate-x-full'}
      `}>
        <div className="flex flex-col h-full">
          {/* Header */}
          <div className="flex items-center justify-between h-16 px-6 border-b border-gray-700/50">
            <div className="flex items-center">
              <div className="h-8 w-8 bg-gradient-to-br from-cyan-400 via-blue-500 to-purple-600 rounded-xl flex items-center justify-center shadow-lg shadow-blue-500/25">
                <span className="text-white font-bold text-sm">M</span>
              </div>
              <span className="ml-3 text-lg font-bold bg-gradient-to-r from-white to-gray-300 bg-clip-text text-transparent">
                MEVShield
              </span>
            </div>
            <button
              className="lg:hidden p-2 rounded-xl bg-white/10 backdrop-blur-sm border border-white/20 text-white hover:bg-white/20 transition-all duration-200"
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
                  `group flex items-center px-4 py-3 text-sm font-medium rounded-xl transition-all duration-300 ${
                    isActive
                      ? 'bg-gradient-to-r from-blue-500/20 to-purple-500/20 border border-blue-400/30 backdrop-blur-sm text-blue-200 shadow-lg shadow-blue-500/10'
                      : 'text-gray-300 hover:bg-white/10 hover:border hover:border-white/20 hover:backdrop-blur-sm hover:text-white'
                  }`
                }
              >
                <item.icon className="mr-3 h-5 w-5 flex-shrink-0" />
                <span className="flex-1">{item.name}</span>
                {item.badge && (
                  <span className="ml-2 inline-flex items-center px-2 py-1 rounded-full text-xs font-bold bg-gradient-to-r from-cyan-400/20 to-blue-500/20 border border-cyan-400/30 backdrop-blur-sm text-cyan-200 shadow-lg shadow-cyan-500/10">
                    {item.badge}
                  </span>
                )}
              </NavLink>
            ))}
          </nav>

          {/* Stats Summary */}
          <div className="px-4 py-6 border-t border-gray-700/50">
            <div className="bg-gradient-to-br from-gray-800/50 to-gray-900/50 backdrop-blur-sm border border-gray-700/30 rounded-2xl p-4 shadow-xl">
              <div className="text-xs text-cyan-300 uppercase tracking-wide font-bold mb-4">
                Quick Stats
              </div>
              
              <div className="space-y-3">
                <div className="flex justify-between items-center p-2 rounded-lg bg-white/5 backdrop-blur-sm border border-white/10">
                  <span className="text-sm text-gray-300">
                    Total MEV Prevented
                  </span>
                  <span className="text-sm font-bold text-white">
                    {mevMetrics.totalMEVPrevented.toString().slice(0, 6)}...
                  </span>
                </div>
                
                <div className="flex justify-between items-center p-2 rounded-lg bg-white/5 backdrop-blur-sm border border-white/10">
                  <span className="text-sm text-gray-300">
                    Active Auctions
                  </span>
                  <span className="text-sm font-bold text-cyan-300">
                    {activeAuctions.length}
                  </span>
                </div>
                
                <div className="flex justify-between items-center p-2 rounded-lg bg-white/5 backdrop-blur-sm border border-white/10">
                  <span className="text-sm text-gray-300">
                    Total Pools
                  </span>
                  <span className="text-sm font-bold text-purple-300">
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