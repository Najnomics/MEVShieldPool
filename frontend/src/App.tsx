import React, { useState, useEffect } from 'react';
import { BrowserRouter as Router, Routes, Route, Navigate } from 'react-router-dom';
import { QueryClient, QueryClientProvider } from '@tanstack/react-query';
import { WagmiConfig } from 'wagmi';
import { RainbowKitProvider, getDefaultWallets, connectorsForWallets } from '@rainbow-me/rainbowkit';
import { configureChains, createConfig, mainnet, polygon, arbitrum, optimism } from 'wagmi';
import { alchemyProvider } from 'wagmi/providers/alchemy';
import { publicProvider } from 'wagmi/providers/public';
import { ToastContainer } from 'react-toastify';

// Components
import Header from './components/Header';
import Sidebar from './components/Sidebar';
import Dashboard from './pages/Dashboard';
import AuctionInterface from './pages/AuctionInterface';
import AnalyticsPage from './pages/AnalyticsPage';
import PoolManagement from './pages/PoolManagement';
import Settings from './pages/Settings';
import LoadingSpinner from './components/LoadingSpinner';

// Hooks and Context
import { Web3Provider } from './contexts/Web3Context';
import { useTheme } from './hooks/useTheme';

// Styles
import '@rainbow-me/rainbowkit/styles.css';
import 'react-toastify/dist/ReactToastify.css';
import './styles/globals.css';

// Configure chains for multi-chain support
const { chains, publicClient, webSocketPublicClient } = configureChains(
  [mainnet, polygon, arbitrum, optimism],
  [
    alchemyProvider({ apiKey: process.env.REACT_APP_ALCHEMY_API_KEY! }),
    publicProvider(),
  ]
);

// Configure wallet connectors
const { wallets } = getDefaultWallets({
  appName: 'MEVShield Pool',
  projectId: process.env.REACT_APP_WALLET_CONNECT_PROJECT_ID!,
  chains,
});

const connectors = connectorsForWallets([
  ...wallets,
]);

// Create wagmi config
const wagmiConfig = createConfig({
  autoConnect: true,
  connectors,
  publicClient,
  webSocketPublicClient,
});

// Create React Query client
const queryClient = new QueryClient({
  defaultOptions: {
    queries: {
      staleTime: 60000, // 1 minute
      refetchOnWindowFocus: false,
    },
  },
});

const App: React.FC = () => {
  const [sidebarOpen, setSidebarOpen] = useState(false);
  const [isLoading, setIsLoading] = useState(true);
  const { theme, toggleTheme } = useTheme();

  useEffect(() => {
    // Initialize application
    const initializeApp = async () => {
      try {
        // Load any necessary data
        await new Promise(resolve => setTimeout(resolve, 1000)); // Simulate loading
        setIsLoading(false);
      } catch (error) {
        console.error('Failed to initialize app:', error);
        setIsLoading(false);
      }
    };

    initializeApp();
  }, []);

  if (isLoading) {
    return (
      <div className="min-h-screen bg-gray-900 flex items-center justify-center">
        <LoadingSpinner size="large" />
      </div>
    );
  }

  return (
    <QueryClientProvider client={queryClient}>
      <WagmiConfig config={wagmiConfig}>
        <RainbowKitProvider 
          chains={chains}
          theme="dark"
        >
          <Web3Provider>
            <Router>
              <div className="min-h-screen bg-gradient-to-br from-gray-900 via-slate-900 to-black">
                <div className="min-h-screen bg-gradient-to-tr from-blue-900/10 via-purple-900/5 to-cyan-900/10">
                  {/* Header */}
                  <Header 
                    onMenuClick={() => setSidebarOpen(!sidebarOpen)}
                    onThemeToggle={toggleTheme}
                    theme={theme}
                  />

                  <div className="flex">
                    {/* Sidebar */}
                    <Sidebar 
                      isOpen={sidebarOpen}
                      onClose={() => setSidebarOpen(false)}
                    />

                    {/* Main Content */}
                    <main className={`flex-1 transition-all duration-300 ${
                      sidebarOpen ? 'ml-64' : 'ml-0'
                    } lg:ml-64 min-h-screen`}>
                      <div className="px-6 py-8 sm:px-8 lg:px-12">
                        <Routes>
                          <Route path="/" element={<Navigate to="/dashboard" replace />} />
                          <Route path="/dashboard" element={<Dashboard />} />
                          <Route path="/auction" element={<AuctionInterface />} />
                          <Route path="/analytics" element={<AnalyticsPage />} />
                          <Route path="/pools" element={<PoolManagement />} />
                          <Route path="/settings" element={<Settings />} />
                        </Routes>
                      </div>
                    </main>
                  </div>

                  {/* Toast notifications */}
                  <ToastContainer
                    position="top-right"
                    autoClose={5000}
                    hideProgressBar={false}
                    newestOnTop={false}
                    closeOnClick
                    rtl={false}
                    pauseOnFocusLoss
                    draggable
                    pauseOnHover
                    theme={theme}
                  />
                </div>
              </div>
            </Router>
          </Web3Provider>
        </RainbowKitProvider>
      </WagmiConfig>
    </QueryClientProvider>
  );
};

export default App;