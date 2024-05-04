// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

/// @notice Encode/decode _account
contract EncodeDecodeAccount {
    struct Result {
        uint256 chainId;
        address user;
    }

    /// @notice Get the account in bytes32 from given chainId and user address
    function encode(uint256 chainId, address user) external pure returns (bytes32) {
        return keccak256(abi.encode(chainId, user));
    }

    /// @notice Get the chain ID and user address from given bytes32 account notation
    function decode(bytes memory account) external pure returns (uint256, address) {
        (uint256 chainId, address user) = abi.decode(account, (uint256, address));
        return (chainId, user);
    }
}