// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "IAddressChecker.sol";

/**
 * @title    Address Checker contract
 * @notice   Gets data from multiple addresses in single function calls.
 *           It can be used to check balances and to check whether there is bytecode
 *           (contract deployed) for multiple addresses. This is useful in order to avoid
 *           issuing a separate call for each address, which is very innefficient.
 * @dev      This contract only contains view functions that doesn't spend gas. However, some RPC
 *           providers put a cap on the amount of gas that the transaction *would* consume to
 *           prevent spamming. As a rough refernece, a try using a free INFURA endpoint succesfully
 *           executes around 75k addresses for getNativeBalances but fails when requesting 100k.
 *           It's advised to split up such big lists to prevent failures.
 */
contract AddressChecker is IAddressChecker {
    /**
     * @notice  Returns an array of the native token balances for array of addresses.
     * @param addresses  Array of addresses to check.
     */
    function nativeBalances(address[] calldata addresses) external view override returns (uint[] memory) {
        uint256 length = addresses.length;

        uint[] memory balances = new uint[](length);

        for (uint i = 0; i < length; ) {
            balances[i] = addresses[i].balance;
            unchecked {
                ++i;
            }
        }
        return balances;
    }

    /**
     * @notice  Returns an array of booleans signaling whether there is bytecode deployed for an array of addresses.
     * @param addresses  Array of addresses to check.
     */
    function contractsDeployed(address[] calldata addresses) external view override returns (bool[] memory) {
        uint256 length = addresses.length;

        bool[] memory hasContractArray = new bool[](length);

        for (uint i = 0; i < length; ) {
            hasContractArray[i] = addresses[i].code.length > 0;
            unchecked {
                ++i;
            }
        }
        return hasContractArray;
    }

    /**
     * @notice  Returns an array of structs with both the native token balance and whether the addresses have bytecode
     *          deployed for for an array of addresses.
     * @param addresses  Array of addresses to check.
     */
    function addressStates(address[] calldata addresses) external view override returns (AddressState[] memory) {
        uint256 length = addresses.length;

        AddressState[] memory addressStateArray = new AddressState[](length);

        for (uint i = 0; i < length; ) {
            addressStateArray[i] = AddressState(addresses[i].balance, addresses[i].code.length > 0);
            unchecked {
                ++i;
            }
        }
        return addressStateArray;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

interface IAddressChecker {
    struct AddressState {
        uint256 balance;
        bool hasContract;
    }

    function nativeBalances(address[] calldata addresses) external view returns (uint[] memory);

    function contractsDeployed(address[] calldata addresses) external view returns (bool[] memory);

    function addressStates(address[] calldata addresses) external view returns (AddressState[] memory);
}