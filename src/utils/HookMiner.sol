// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

/**
 * @title HookMiner
 * @dev Utility contract for mining valid hook addresses in Uniswap V4
 * @notice Helps generate hooks with specific permissions and address patterns
 * @author MEVShield Pool Team
 */
library HookMiner {
    /**
     * @dev Hook permission flags as defined in Uniswap V4
     */
    uint160 constant FLAG_BEFORE_INITIALIZE = 0x1 << 159;
    uint160 constant FLAG_AFTER_INITIALIZE = 0x1 << 158;
    uint160 constant FLAG_BEFORE_SWAP = 0x1 << 157;
    uint160 constant FLAG_AFTER_SWAP = 0x1 << 156;
    uint160 constant FLAG_BEFORE_MODIFY_POSITION = 0x1 << 155;
    uint160 constant FLAG_AFTER_MODIFY_POSITION = 0x1 << 154;
    uint160 constant FLAG_BEFORE_DONATE = 0x1 << 153;
    uint160 constant FLAG_AFTER_DONATE = 0x1 << 152;
    uint160 constant FLAG_BEFORE_SWAP_RETURNS_DELTA = 0x1 << 151;
    uint160 constant FLAG_AFTER_SWAP_RETURNS_DELTA = 0x1 << 150;
    uint160 constant FLAG_AFTER_MODIFY_POSITION_RETURNS_DELTA = 0x1 << 149;
    uint160 constant FLAG_AFTER_DONATE_RETURNS_DELTA = 0x1 << 148;

    /**
     * @dev Structure containing hook mining parameters
     */
    struct MiningParams {
        address deployer;
        uint256 salt;
        bytes initCode;
        uint160 targetFlags;
        uint256 maxIterations;
    }

    /**
     * @dev Result of hook address mining
     */
    struct MiningResult {
        address hookAddress;
        uint256 finalSalt;
        bool found;
        uint256 iterations;
    }

    /**
     * @dev Mines a valid hook address with specified permissions
     * @param params Mining parameters including deployer, initCode, and target flags
     * @return result Mining result with found address and metadata
     */
    function mineHookAddress(MiningParams memory params) 
        internal 
        pure 
        returns (MiningResult memory result) 
    {
        result.found = false;
        result.iterations = 0;
        
        for (uint256 i = 0; i < params.maxIterations; i++) {
            uint256 currentSalt = params.salt + i;
            address predictedAddress = computeCreate2Address(
                params.deployer,
                currentSalt,
                params.initCode
            );
            
            result.iterations = i + 1;
            
            if (hasValidFlags(predictedAddress, params.targetFlags)) {
                result.hookAddress = predictedAddress;
                result.finalSalt = currentSalt;
                result.found = true;
                break;
            }
        }
        
        return result;
    }

    /**
     * @dev Computes CREATE2 address for hook deployment
     * @param deployer Address of the deployer
     * @param salt Salt value for CREATE2
     * @param initCodeHash Hash of the initialization code
     * @return predictedAddress The predicted address
     */
    function computeCreate2Address(
        address deployer,
        uint256 salt,
        bytes memory initCode
    ) internal pure returns (address predictedAddress) {
        bytes32 initCodeHash = keccak256(initCode);
        predictedAddress = address(uint160(uint256(keccak256(abi.encodePacked(
            bytes1(0xff),
            deployer,
            salt,
            initCodeHash
        )))));
    }

    /**
     * @dev Checks if an address has the required hook permission flags
     * @param hookAddress The hook address to check
     * @param requiredFlags The required permission flags
     * @return hasFlags True if the address has all required flags
     */
    function hasValidFlags(address hookAddress, uint160 requiredFlags) 
        internal 
        pure 
        returns (bool hasFlags) 
    {
        uint160 addressFlags = uint160(hookAddress);
        return (addressFlags & requiredFlags) == requiredFlags;
    }

    /**
     * @dev Gets the hook permissions for MEV auction functionality
     * @return flags Combined flags for beforeSwap, afterSwap, and beforeInitialize
     */
    function getMEVAuctionFlags() internal pure returns (uint160 flags) {
        return FLAG_BEFORE_INITIALIZE | FLAG_BEFORE_SWAP | FLAG_AFTER_SWAP;
    }

    /**
     * @dev Gets all available hook permission flags
     * @return flags All possible hook permission flags combined
     */
    function getAllFlags() internal pure returns (uint160 flags) {
        return FLAG_BEFORE_INITIALIZE | 
               FLAG_AFTER_INITIALIZE |
               FLAG_BEFORE_SWAP |
               FLAG_AFTER_SWAP |
               FLAG_BEFORE_MODIFY_POSITION |
               FLAG_AFTER_MODIFY_POSITION |
               FLAG_BEFORE_DONATE |
               FLAG_AFTER_DONATE |
               FLAG_BEFORE_SWAP_RETURNS_DELTA |
               FLAG_AFTER_SWAP_RETURNS_DELTA |
               FLAG_AFTER_MODIFY_POSITION_RETURNS_DELTA |
               FLAG_AFTER_DONATE_RETURNS_DELTA;
    }
}
}