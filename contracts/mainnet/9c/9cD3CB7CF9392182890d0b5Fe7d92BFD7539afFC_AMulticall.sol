// SPDX-License-Identifier: GPL-2.0-or-later

// solhint-disable-next-line
pragma solidity 0.8.17;

import "./interfaces/IAMulticall.sol";

/// @title AMulticall - Allows sending mulple transactions to the pool.
/// @notice As per https://github.com/Uniswap/swap-router-contracts/blob/main/contracts/base/MulticallExtended.sol
contract AMulticall is IAMulticall {
    modifier checkDeadline(uint256 deadline) {
        require(_blockTimestamp() <= deadline, 'AMULTICALL_DEADLINE_PAST_ERROR');
        _;
    }

    modifier checkPreviousBlockhash(bytes32 previousBlockhash) {
        require(blockhash(block.number - 1) == previousBlockhash, 'AMULTICALL_BLOCKHASH_ERROR');
        _;
    }

    /// @inheritdoc IAMulticall
    function multicall(bytes[] calldata data) public override returns (bytes[] memory results) {
        results = new bytes[](data.length);
        for (uint256 i = 0; i < data.length; i++) {
            (bool success, bytes memory result) = address(this).delegatecall(data[i]);

            if (!success) {
                // Next 5 lines from https://ethereum.stackexchange.com/a/83577
                if (result.length < 68) revert();
                assembly {
                    result := add(result, 0x04)
                }
                revert(abi.decode(result, (string)));
            }

            results[i] = result;
        }
    }

    /// @inheritdoc IAMulticall
    function multicall(uint256 deadline, bytes[] calldata data)
        external
        payable
        override
        checkDeadline(deadline)
        returns (bytes[] memory)
    {
        return multicall(data);
    }

    /// @inheritdoc IAMulticall
    function multicall(bytes32 previousBlockhash, bytes[] calldata data)
        external
        payable
        override
        checkPreviousBlockhash(previousBlockhash)
        returns (bytes[] memory)
    {
        return multicall(data);
    }

    /// @dev Method that exists purely to be overridden for tests
    /// @return The current block timestamp
    function _blockTimestamp() internal view virtual returns (uint256) {
        return block.timestamp;
    }
}

// SPDX-License-Identifier: GPL-2.0-or-later

pragma solidity >=0.8.0 <0.9.0;

/// @notice As per https://github.com/Uniswap/swap-router-contracts/blob/main/contracts/interfaces/IMulticallExtended.sol
interface IAMulticall {
    /// @notice Enables calling multiple methods in a single call to the contract
    /// @param data Array of encoded calls.
    /// @return results Array of call responses.
    function multicall(bytes[] calldata data) external returns (bytes[] memory results);

    /// @notice Call multiple functions in the current contract and return the data from all of them if they all succeed
    /// @dev The `msg.value` should not be trusted for any method callable from multicall.
    /// @param deadline The time by which this function must be called before failing
    /// @param data The encoded function data for each of the calls to make to this contract
    /// @return results The results from each of the calls passed in via data
    function multicall(uint256 deadline, bytes[] calldata data) external payable returns (bytes[] memory results);

    /// @notice Call multiple functions in the current contract and return the data from all of them if they all succeed
    /// @dev The `msg.value` should not be trusted for any method callable from multicall.
    /// @param previousBlockhash The expected parent blockHash
    /// @param data The encoded function data for each of the calls to make to this contract
    /// @return results The results from each of the calls passed in via data
    function multicall(bytes32 previousBlockhash, bytes[] calldata data)
        external
        payable
        returns (bytes[] memory results);
}