// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.20;

import {BaseGuard, Guard} from "@safe-contracts/base/GuardManager.sol";
import {Enum} from "@safe-contracts/common/Enum.sol";
import "@openzeppelin-contracts/interfaces/IERC165.sol";
import {TokenAuthorizer} from "@src/TokenAuthorizer.sol";

/*

@dev This is a guard for the Uniswap V3 / AAVE V3 vault. It allows vault owners to submit the following transactions:
- outbound ERC20 transfers
- Uniswap V3 collects **
- Uniswap V3 burns **
- Uniswap V3 decrease liquidity **
- AAVE V3 withdraw **

** These transactions are a failsafe in-case the trading module becomes bricked. They should not be used under normal circumstances.

*/
contract VaultGuard is TokenAuthorizer, IERC165, BaseGuard {
    error NoFunctionSelectorFound(bytes data);
    error FunctionCallNotAuthorized(bytes4 selector);

    bytes4 public constant GUARD_INTERFACE_ID = 0xe6d7a83a;
    bytes4 internal constant ERC20_TRANSFER_SELECTOR = bytes4(keccak256("transfer(address,uint256)"));
    bytes4 internal constant UNISWAP_V3_COLLECT_SELECTOR =
        bytes4(keccak256("collect((uint256,address,uint128,uint128))"));
    bytes4 internal constant UNISWAP_V3_BURN_SELECTOR = bytes4(keccak256("burn(uint256)"));
    bytes4 internal constant UNISWAP_V3_DECREASE_LIQUIDITY =
        bytes4(keccak256("decreaseLiquidity((uint256,uint128,uint256,uint256,uint256))"));
    bytes4 internal constant AAVE_V3_WITHDRAW_SELECTOR = bytes4(keccak256("withdraw(address,uint256,address)"));

    address public immutable uniswapV3PositionManager;
    address public immutable aaveV3Pool;

    constructor(address _uniswapV3PositionManager, address _aaveV3Pool, address[] memory _authorizedTokens)
        TokenAuthorizer(_authorizedTokens)
    {
        uniswapV3PositionManager = _uniswapV3PositionManager;
        aaveV3Pool = _aaveV3Pool;
    }

    function checkTransaction(
        address to,
        uint256,
        bytes memory data,
        Enum.Operation operation,
        uint256,
        uint256,
        uint256,
        address,
        address payable,
        bytes memory,
        address
    ) external view override {
        // Disallow transactions that use delegate call
        require(operation == Enum.Operation.Call, "DAMM: 'delegatecall' not allowed");

        bytes4 functionSelector = _getFunctionSelector(data);

        if (to == uniswapV3PositionManager) {
            if (
                functionSelector != UNISWAP_V3_COLLECT_SELECTOR && functionSelector != UNISWAP_V3_BURN_SELECTOR
                    && functionSelector != UNISWAP_V3_DECREASE_LIQUIDITY
            ) {
                revert FunctionCallNotAuthorized(functionSelector);
            }
        } else if (to == aaveV3Pool) {
            if (functionSelector != AAVE_V3_WITHDRAW_SELECTOR) revert FunctionCallNotAuthorized(functionSelector);
        } else if (functionSelector != ERC20_TRANSFER_SELECTOR) {
            revert FunctionCallNotAuthorized(functionSelector);
        }
    }

    function checkAfterExecution(bytes32 txHash, bool success) external override {}

    function supportsInterface(bytes4 interfaceId) external view virtual override(IERC165, BaseGuard) returns (bool) {
        return interfaceId == GUARD_INTERFACE_ID || interfaceId == type(Guard).interfaceId // 0xe6d7a83a
            || interfaceId == type(IERC165).interfaceId // 0x01ffc9a7
            || interfaceId == type(TokenAuthorizer).interfaceId;
    }

    function _getFunctionSelector(bytes memory data) internal pure returns (bytes4 selector) {
        if (data.length < 4) {
            revert NoFunctionSelectorFound(data);
        }

        assembly {
            selector := mload(add(data, 32))
        }
    }
}

// SPDX-License-Identifier: LGPL-3.0-only
pragma solidity >=0.7.0 <0.9.0;

import "../common/Enum.sol";
import "../common/SelfAuthorized.sol";
import "../interfaces/IERC165.sol";

interface Guard is IERC165 {
    function checkTransaction(
        address to,
        uint256 value,
        bytes memory data,
        Enum.Operation operation,
        uint256 safeTxGas,
        uint256 baseGas,
        uint256 gasPrice,
        address gasToken,
        address payable refundReceiver,
        bytes memory signatures,
        address msgSender
    ) external;

    function checkAfterExecution(bytes32 txHash, bool success) external;
}

abstract contract BaseGuard is Guard {
    function supportsInterface(bytes4 interfaceId) external view virtual override returns (bool) {
        return
            interfaceId == type(Guard).interfaceId || // 0xe6d7a83a
            interfaceId == type(IERC165).interfaceId; // 0x01ffc9a7
    }
}

/**
 * @title Guard Manager - A contract managing transaction guards which perform pre and post-checks on Safe transactions.
 * @author Richard Meissner - @rmeissner
 */
abstract contract GuardManager is SelfAuthorized {
    event ChangedGuard(address indexed guard);

    // keccak256("guard_manager.guard.address")
    bytes32 internal constant GUARD_STORAGE_SLOT = 0x4a204f620c8c5ccdca3fd54d003badd85ba500436a431f0cbda4f558c93c34c8;

    /**
     * @dev Set a guard that checks transactions before execution
     *      This can only be done via a Safe transaction.
     *      ⚠️ IMPORTANT: Since a guard has full power to block Safe transaction execution,
     *        a broken guard can cause a denial of service for the Safe. Make sure to carefully
     *        audit the guard code and design recovery mechanisms.
     * @notice Set Transaction Guard `guard` for the Safe. Make sure you trust the guard.
     * @param guard The address of the guard to be used or the 0 address to disable the guard
     */
    function setGuard(address guard) external authorized {
        if (guard != address(0)) {
            require(Guard(guard).supportsInterface(type(Guard).interfaceId), "GS300");
        }
        bytes32 slot = GUARD_STORAGE_SLOT;
        // solhint-disable-next-line no-inline-assembly
        assembly {
            sstore(slot, guard)
        }
        emit ChangedGuard(guard);
    }

    /**
     * @dev Internal method to retrieve the current guard
     *      We do not have a public method because we're short on bytecode size limit,
     *      to retrieve the guard address, one can use `getStorageAt` from `StorageAccessible` contract
     *      with the slot `GUARD_STORAGE_SLOT`
     * @return guard The address of the guard
     */
    function getGuard() internal view returns (address guard) {
        bytes32 slot = GUARD_STORAGE_SLOT;
        // solhint-disable-next-line no-inline-assembly
        assembly {
            guard := sload(slot)
        }
    }
}

// SPDX-License-Identifier: LGPL-3.0-only
pragma solidity >=0.7.0 <0.9.0;

/**
 * @title Enum - Collection of enums used in Safe contracts.
 * @author Richard Meissner - @rmeissner
 */
abstract contract Enum {
    enum Operation {
        Call,
        DelegateCall
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (interfaces/IERC165.sol)

pragma solidity ^0.8.0;

import "../utils/introspection/IERC165.sol";

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity ^0.8.20;

abstract contract TokenAuthorizer {
    event TokensAuthorized(address[] tokens);

    error TokenNotAuthorized(address token);

    mapping(address token => bool authorized) public authorizedTokens;

    constructor(address[] memory _authorizedTokens) {
        // Register authorized tokens
        uint256 length = _authorizedTokens.length;
        for (uint256 i = 0; i < length;) {
            authorizedTokens[_authorizedTokens[i]] = true;

            // will never overflow due to size of _authorizedTokens
            unchecked {
                ++i;
            }
        }

        emit TokensAuthorized(_authorizedTokens);
    }

    function isAuthorizedToken(address token) public view returns (bool) {
        return authorizedTokens[token];
    }

    function checkIsAuthorizedToken(address token) internal view {
        if (!isAuthorizedToken(token)) revert TokenNotAuthorized(token);
    }
}

// SPDX-License-Identifier: LGPL-3.0-only
pragma solidity >=0.7.0 <0.9.0;

/**
 * @title SelfAuthorized - Authorizes current contract to perform actions to itself.
 * @author Richard Meissner - @rmeissner
 */
abstract contract SelfAuthorized {
    function requireSelfCall() private view {
        require(msg.sender == address(this), "GS031");
    }

    modifier authorized() {
        // Modifiers are copied around during compilation. This is a function call as it minimized the bytecode size
        requireSelfCall();
        _;
    }
}

// SPDX-License-Identifier: LGPL-3.0-only
pragma solidity >=0.7.0 <0.9.0;

/// @notice More details at https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/utils/introspection/IERC165.sol
interface IERC165 {
    /**
     * @dev Returns true if this contract implements the interface defined by `interfaceId`.
     * See the corresponding EIP section
     * https://eips.ethereum.org/EIPS/eip-165#how-interfaces-are-identified
     * to learn more about how these ids are created.
     *
     * This function call must use less than 30 000 gas.
     */
    function supportsInterface(bytes4 interfaceId) external view returns (bool);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/introspection/IERC165.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC165 standard, as defined in the
 * https://eips.ethereum.org/EIPS/eip-165[EIP].
 *
 * Implementers can declare support of contract interfaces, which can then be
 * queried by others ({ERC165Checker}).
 *
 * For an implementation, see {ERC165}.
 */
interface IERC165 {
    /**
     * @dev Returns true if this contract implements the interface defined by
     * `interfaceId`. See the corresponding
     * https://eips.ethereum.org/EIPS/eip-165#how-interfaces-are-identified[EIP section]
     * to learn more about how these ids are created.
     *
     * This function call must use less than 30 000 gas.
     */
    function supportsInterface(bytes4 interfaceId) external view returns (bool);
}