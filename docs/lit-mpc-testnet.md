## Lit MPC Testnet Integration (MPC-only)

This guide outlines how to integrate Lit Protocol (MPC-only) with MEVShield on testnet. FHE is deferred; we only use MPC for encrypted bid submission and optional threshold decryption simulation.

### What You Need

- Lit Node Client v7 (off-chain) for encryption and access-control construction
- Your wallet configured to sign Lit auth messages
- MEVShield contracts deployed on Sepolia (see `testnet-sepolia.md`)

### Off-Chain Encryption Flow (Example)

Pseudo-code for building encrypted bid payloads with Lit JS SDK:

```js
import { LitNodeClient } from '@lit-protocol/lit-node-client';

const client = new LitNodeClient({ litNetwork: 'manzano' });
await client.connect();

// Build access control conditions (mirror on-chain validation intent)
const conditions = [
  {
    contractAddress: '0x0000000000000000000000000000000000000000',
    standardContractType: '',
    chain: 'ethereum',
    method: 'eth_getBalance',
    parameters: ["$USER_ADDRESS", "latest"],
    returnValueTest: { comparator: ">=", value: (0.1e18).toString() },
  },
];

// Encrypt the 64-bit bid amount (e.g., in wei)
const bidAmount = BigInt(1e18);
const { encryptedData, symmetricKey } = await client.encrypt(
  new TextEncoder().encode(bidAmount.toString())
);

// Store or share `encryptedData` and session metadata with your dApp
```

On-chain, submit the encrypted bid via `LitEncryptionHook.encryptBid` or the integrated hook call. The on-chain path persists the payload and key hash for later decryption.

### On-Chain Calls

- `LitEncryptionHook.encryptBid(poolId, amount, accessConditions)` — wraps the bid as an encrypted payload recorded per pool.
- `LitEncryptionHook.decryptWinningBids(poolId, bids, signatures)` — simplified threshold decryption path for winners (simulation only).

Notes:
- MPC threshold validation is enforced via `LitProtocolLib.validateMPCParams`.
- FHE is explicitly deferred; MPC-only flows are supported.

### Operational Notes

- Ensure your access conditions reflect realistic constraints (min balance, time window).
- For production, implement an off-chain coordinator to assemble threshold signatures and handle retries.


