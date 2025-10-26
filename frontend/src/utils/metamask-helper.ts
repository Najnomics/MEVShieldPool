// Check if MetaMask is installed (specifically MetaMask, not other wallets)
export const isMetaMaskInstalled = () => {
  if (typeof window.ethereum === 'undefined') {
    return false;
  }
  
  // Check if it's specifically MetaMask (not Uniswap or other wallets)
  const ethereum = window.ethereum as any;
  return (
    ethereum.isMetaMask === true ||
    (ethereum.providers && ethereum.providers.find((p: any) => p.isMetaMask === true))
  );
};

// Get MetaMask provider specifically
const getMetaMaskProvider = () => {
  if (typeof window.ethereum === 'undefined') {
    return null;
  }

  const ethereum = window.ethereum as any;
  
  // If isMetaMask is true, it's MetaMask
  if (ethereum.isMetaMask === true) {
    return ethereum;
  }
  
  // If providers array exists, find MetaMask
  if (ethereum.providers) {
    const metaMaskProvider = ethereum.providers.find((p: any) => p.isMetaMask === true);
    if (metaMaskProvider) {
      return metaMaskProvider;
    }
  }
  
  // Fallback: if only one provider, use it (might be MetaMask in some browsers)
  if (!ethereum.providers) {
    return ethereum;
  }
  
  return null;
};

// Helper function to manually trigger MetaMask connection
export const connectMetaMaskManually = async () => {
  const provider = getMetaMaskProvider();
  
  if (!provider) {
    throw new Error('MetaMask is not installed or not detected');
  }

  try {
    // Request account access specifically from MetaMask
    const accounts = await provider.request({
      method: 'eth_requestAccounts',
    });
    
    return accounts;
  } catch (error: any) {
    if (error.code === 4001) {
      throw new Error('User rejected the connection request');
    }
    throw error;
  }
};

// Get current MetaMask account
export const getMetaMaskAccount = async () => {
  if (!isMetaMaskInstalled()) {
    return null;
  }

  try {
    const accounts = await window.ethereum.request({
      method: 'eth_accounts',
    });
    return accounts.length > 0 ? accounts[0] : null;
  } catch (error) {
    console.error('Error getting MetaMask account:', error);
    return null;
  }
};

