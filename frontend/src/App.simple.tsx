import React, { useState } from 'react';
import { BrowserRouter as Router, Routes, Route, Navigate } from 'react-router-dom';
import './styles/globals.css';

const App: React.FC = () => {
  const [sidebarOpen, setSidebarOpen] = useState(false);

  return (
    <Router>
      <div className="min-h-screen bg-gradient-to-br from-gray-900 via-slate-900 to-black">
        <div className="min-h-screen bg-gradient-to-tr from-blue-900/10 via-purple-900/5 to-cyan-900/10">
          {/* Header */}
          <header className="backdrop-blur-md bg-gray-900/30 border-b border-gray-700/50 shadow-xl">
            <div className="px-4 sm:px-6 lg:px-8">
              <div className="flex justify-between items-center h-16">
                <div className="flex items-center">
                  <button
                    type="button"
                    className="lg:hidden p-2 rounded-xl bg-white/10 backdrop-blur-sm border border-white/20 text-white hover:bg-white/20 transition-all duration-200"
                    onClick={() => setSidebarOpen(!sidebarOpen)}
                  >
                    ☰
                  </button>
                  
                  <div className="flex items-center ml-4 lg:ml-0">
                    <div className="h-10 w-10 bg-gradient-to-br from-cyan-400 via-blue-500 to-purple-600 rounded-xl flex items-center justify-center shadow-lg shadow-blue-500/25">
                      <span className="text-white font-bold text-lg">M</span>
                    </div>
                    <h1 className="ml-3 text-xl font-bold bg-gradient-to-r from-white to-gray-300 bg-clip-text text-transparent">
                      MEVShield Pool
                    </h1>
                  </div>
                </div>

                <div className="hidden md:flex items-center space-x-4">
                  <div className="flex items-center space-x-2 px-4 py-2 rounded-full bg-green-500/20 border border-green-400/30 backdrop-blur-sm">
                    <div className="h-2 w-2 bg-green-400 rounded-full animate-pulse shadow-lg shadow-green-400/50"></div>
                    <span className="text-sm text-green-200 font-medium">Demo Mode</span>
                  </div>
                </div>

                <div className="flex items-center space-x-4">
                  <button className="px-4 py-2 bg-gradient-to-r from-blue-500 to-purple-600 rounded-xl text-white font-medium hover:from-blue-600 hover:to-purple-700 transition-all duration-200">
                    Connect Wallet
                  </button>
                </div>
              </div>
            </div>
          </header>

          <div className="flex">
            {/* Sidebar */}
            <div className={`fixed inset-y-0 left-0 z-50 w-64 bg-gray-900/60 backdrop-blur-xl border-r border-gray-700/50 shadow-2xl transform transition-transform duration-300 ease-in-out lg:translate-x-0 lg:static lg:inset-0 ${sidebarOpen ? 'translate-x-0' : '-translate-x-full'}`}>
              <div className="flex flex-col h-full">
                <div className="flex items-center justify-between h-16 px-6 border-b border-gray-700/50">
                  <div className="flex items-center">
                    <div className="h-8 w-8 bg-gradient-to-br from-cyan-400 via-blue-500 to-purple-600 rounded-xl flex items-center justify-center shadow-lg shadow-blue-500/25">
                      <span className="text-white font-bold text-sm">M</span>
                    </div>
                    <span className="ml-3 text-lg font-bold bg-gradient-to-r from-white to-gray-300 bg-clip-text text-transparent">
                      MEVShield
                    </span>
                  </div>
                </div>

                <nav className="flex-1 px-4 py-6 space-y-2">
                  <a href="/dashboard" className="group flex items-center px-4 py-3 text-sm font-medium rounded-xl bg-gradient-to-r from-blue-500/20 to-purple-500/20 border border-blue-400/30 backdrop-blur-sm text-blue-200 shadow-lg shadow-blue-500/10">
                    <span className="mr-3">📊</span>
                    <span className="flex-1">Dashboard</span>
                  </a>
                  <a href="/auction" className="group flex items-center px-4 py-3 text-sm font-medium rounded-xl text-gray-300 hover:bg-white/10 hover:border hover:border-white/20 hover:backdrop-blur-sm hover:text-white transition-all duration-300">
                    <span className="mr-3">💰</span>
                    <span className="flex-1">MEV Auctions</span>
                  </a>
                  <a href="/pools" className="group flex items-center px-4 py-3 text-sm font-medium rounded-xl text-gray-300 hover:bg-white/10 hover:border hover:border-white/20 hover:backdrop-blur-sm hover:text-white transition-all duration-300">
                    <span className="mr-3">🧪</span>
                    <span className="flex-1">Pool Management</span>
                  </a>
                  <a href="/analytics" className="group flex items-center px-4 py-3 text-sm font-medium rounded-xl text-gray-300 hover:bg-white/10 hover:border hover:border-white/20 hover:backdrop-blur-sm hover:text-white transition-all duration-300">
                    <span className="mr-3">📈</span>
                    <span className="flex-1">Analytics</span>
                  </a>
                  <a href="/settings" className="group flex items-center px-4 py-3 text-sm font-medium rounded-xl text-gray-300 hover:bg-white/10 hover:border hover:border-white/20 hover:backdrop-blur-sm hover:text-white transition-all duration-300">
                    <span className="mr-3">⚙️</span>
                    <span className="flex-1">Settings</span>
                  </a>
                </nav>
              </div>
            </div>

            {/* Main Content */}
            <main className={`flex-1 transition-all duration-300 ${sidebarOpen ? 'ml-64' : 'ml-0'} lg:ml-64 min-h-screen`}>
              <div className="px-6 py-8 sm:px-8 lg:px-12">
                <Routes>
                  <Route path="/" element={<Navigate to="/dashboard" replace />} />
                  <Route path="/dashboard" element={<DashboardPage />} />
                  <Route path="/auction" element={<div className="text-white">Auction Interface</div>} />
                  <Route path="/analytics" element={<div className="text-white">Analytics Page</div>} />
                  <Route path="/pools" element={<div className="text-white">Pool Management</div>} />
                  <Route path="/settings" element={<div className="text-white">Settings</div>} />
                </Routes>
              </div>
            </main>
          </div>
        </div>
      </div>
    </Router>
  );
};

const DashboardPage: React.FC = () => {
  return (
    <div className="space-y-8">
      {/* Header */}
      <div className="backdrop-blur-sm bg-gradient-to-r from-gray-800/30 to-gray-900/30 border border-gray-700/30 rounded-2xl p-6 shadow-xl">
        <h1 className="text-3xl font-bold bg-gradient-to-r from-white via-cyan-200 to-blue-300 bg-clip-text text-transparent">
          MEV Dashboard
        </h1>
        <p className="mt-2 text-gray-300 font-medium">
          Real-time MEV protection and auction analytics with advanced glassmorphism design
        </p>
      </div>

      {/* Stats Grid */}
      <div className="grid grid-cols-1 gap-6 sm:grid-cols-2 lg:grid-cols-4">
        {[
          { name: 'Total MEV Prevented', value: '1,234.56', unit: 'ETH', color: 'from-emerald-500/20 to-green-500/20', border: 'border-emerald-400/30' },
          { name: 'Active Auctions', value: '12', unit: 'auctions', color: 'from-cyan-500/20 to-blue-500/20', border: 'border-cyan-400/30' },
          { name: 'Active Pools', value: '8', unit: 'pools', color: 'from-purple-500/20 to-violet-500/20', border: 'border-purple-400/30' },
          { name: 'Avg Response Time', value: '12', unit: 'ms', color: 'from-orange-500/20 to-amber-500/20', border: 'border-orange-400/30' },
        ].map((stat) => (
          <div
            key={stat.name}
            className={`backdrop-blur-xl bg-gradient-to-br ${stat.color} border ${stat.border} rounded-2xl overflow-hidden shadow-2xl hover:shadow-3xl hover:scale-105 transition-all duration-300`}
          >
            <div className="p-6">
              <div className="flex items-center justify-between">
                <div className="flex-shrink-0">
                  <div className="p-4 rounded-2xl bg-white/10 backdrop-blur-sm border border-white/20 shadow-lg">
                    <div className="h-8 w-8 bg-white/20 rounded-lg"></div>
                  </div>
                </div>
                <div className="text-right">
                  <div className="text-3xl font-bold text-white">
                    {stat.value}
                  </div>
                  <div className="text-sm font-medium text-cyan-300">
                    {stat.unit}
                  </div>
                </div>
              </div>
              <div className="mt-4">
                <p className="text-sm font-medium text-gray-300 truncate">
                  {stat.name}
                </p>
              </div>
            </div>
          </div>
        ))}
      </div>

      {/* Activity Panels */}
      <div className="grid grid-cols-1 lg:grid-cols-2 gap-8">
        <div className="backdrop-blur-xl bg-gradient-to-br from-cyan-800/40 to-blue-900/40 border border-cyan-700/30 rounded-2xl shadow-2xl shadow-cyan-500/10">
          <div className="p-6">
            <h3 className="text-xl font-bold bg-gradient-to-r from-cyan-300 to-blue-300 bg-clip-text text-transparent mb-6">
              Active Auctions
            </h3>
            <div className="text-center py-8">
              <div className="text-gray-400 font-medium">
                No active auctions at the moment
              </div>
            </div>
          </div>
        </div>

        <div className="backdrop-blur-xl bg-gradient-to-br from-purple-800/40 to-violet-900/40 border border-purple-700/30 rounded-2xl shadow-2xl shadow-purple-500/10">
          <div className="p-6">
            <h3 className="text-xl font-bold bg-gradient-to-r from-purple-300 to-violet-300 bg-clip-text text-transparent mb-6">
              Top Performing Pools
            </h3>
            <div className="text-center py-8">
              <div className="text-gray-400 font-medium">
                No pool data available
              </div>
            </div>
          </div>
        </div>
      </div>
    </div>
  );
};

export default App;