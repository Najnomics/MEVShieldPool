# Manual Etherscan Verification Steps

## MEVAuctionHook Verification

Since automated verification is experiencing TLS issues, follow these manual steps:

### Step 1: Visit Contract on Etherscan

Go to: https://sepolia.etherscan.io/address/0x44369EA8F59Ed1Df48f8eA14aB1a42Cc07f86aC0

### Step 2: Click "Verify and Publish"

1. Click the **"Contract"** tab
2. Click **"Verify and Publish"** button

### Step 3: Fill in Contract Details

Select the following options:

- **Compiler Type**: `Solidity (Single file)`
- **Compiler Version**: `v0.8.26+commit.8a97fa7a` (or latest 0.8.26)
- **License**: `MIT License (MIT)`
- **Optimization**: `Yes`
- **Runs**: `200`
- **EVM Version**: `paris`
- **Via IR**: `Yes` (Important: check this box!)

### Step 4: Upload Source Code

Copy the entire contents of `src/hooks/MEVAuctionHook.sol` and paste it into the source code field.

**Note**: You may need to include imported files. Etherscan will prompt you if any imports are missing.

### Step 5: Constructor Arguments

Use this constructor argument (ABI-encoded):

```
0x00000000000000000000000089169deae6c7e07a12de45b6198d4022e14527cc0000000000000000000000005ebd47dc03f512afa54ab323b79060792ae56ea70000000000000000000000003d0f3eb4bd1263a02bf70b2a6bcead21e7e654d2
```

### Step 6: Submit

Click **"Verify and Publish"** and wait for Etherscan to process (usually 30-60 seconds).

### Step 7: Verify Success

Once verified, you'll see:
- ✅ Green checkmark on the contract tab
- 📄 Full source code visible
- 🔧 "Read Contract" and "Write Contract" tabs available

## Constructor Arguments Breakdown

The constructor takes 3 addresses:

1. **PoolManager**: `0x89169DeAE6C7E07A12De45B6198D4022e14527cC`
2. **LitEncryption**: `0x5eBD47dc03f512Afa54aB323B79060792aE56Ea7`
3. **PythPriceOracle**: `0x3d0f3EB4Bd1263a02BF70b2a6BcEaD21E7E654d2`

These are ABI-encoded in the constructor arguments field.

## Troubleshooting

### "Unable to generate contract creation input"
- Ensure all imports are included
- Check compiler version matches (0.8.26)
- Verify Via-IR is enabled if your contract uses it

### "Constructor arguments mismatch"
- Double-check the constructor arguments above
- Ensure address order matches: PoolManager, LitEncryption, PythPriceOracle

### "Contract source code does not match"
- Ensure `via_ir = true` is enabled in compiler settings
- Check optimization runs match (200)
- Verify EVM version is correct (paris for Cancun)

## Alternative: Flatten Source Code

If Etherscan complains about imports, flatten the contract first:

```bash
forge flatten src/hooks/MEVAuctionHook.sol > MEVAuctionHook_flat.sol
```

Then upload the flattened file as a single source code block.

## Post-Verification

Once verified, your contract will be at:
https://sepolia.etherscan.io/address/0x44369EA8F59Ed1Df48f8eA14aB1a42Cc07f86aC0#code

You can then:
- View full source code
- Interact with the contract via Etherscan UI
- Share the verified contract URL

