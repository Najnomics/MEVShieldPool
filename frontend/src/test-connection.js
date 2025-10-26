// Quick test script to check if MetaMask is detected
// Run this in browser console

console.log('Testing MetaMask connection...');

// Check if MetaMask is installed
if (typeof window.ethereum !== 'undefined') {
  console.log('✅ MetaMask detected!');
  console.log('Provider:', window.ethereum);
  
  // Try to connect
  window.ethereum.request({ method: 'eth_requestAccounts' })
    .then(accounts => {
      console.log('✅ Connected! Accounts:', accounts);
    })
    .catch(err => {
      console.error('❌ Connection failed:', err);
    });
} else {
  console.log('❌ MetaMask not detected. Make sure MetaMask is installed.');
}

