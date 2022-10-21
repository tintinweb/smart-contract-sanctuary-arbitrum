// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import {Errors} from "../utils/Errors.sol";
import {Helpers} from "../utils/Helpers.sol";
import {IAccount} from "../interface/core/IAccount.sol";
import {IERC20} from "../interface/tokens/IERC20.sol";

/**
    @title Sentiment Account
    @notice Contract that acts as a dynamic and distributed asset reserve
        which holds a user’s collateral and loaned assets
*/
contract Account is IAccount {
    using Helpers for address;

    /* -------------------------------------------------------------------------- */
    /*                              STATE VARIABLES                             */
    /* -------------------------------------------------------------------------- */

    /// @notice Block number for when the account is activated
    uint public activationBlock;

    /**
        @notice Address of account manager
        @dev If the value is 0x0 the contract is not initialized
    */
    address public accountManager;


    /// @notice A list of ERC-20 assets (Collaterals + Borrows) present in the account
    address[] public assets;

    /// @notice A list of borrowed ERC-20 assets present in the account
    address[] public borrows;

    /// @notice A mapping of ERC-20 assets present in the account
    mapping(address => bool) public hasAsset;

    /* -------------------------------------------------------------------------- */
    /*                              CUSTOM MODIFIERS                              */
    /* -------------------------------------------------------------------------- */

    modifier accountManagerOnly() {
        if (msg.sender != accountManager) revert Errors.AccountManagerOnly();
        _;
    }

    /* -------------------------------------------------------------------------- */
    /*                             EXTERNAL FUNCTIONS                             */
    /* -------------------------------------------------------------------------- */

    /**
        @notice Initializes the account by setting the address of the account
            manager
        @dev Can only be called as long as the address of the accountManager is
            0x0
        @param _accountManager address of the account manager
    */
    function init(address _accountManager) external {
        if (accountManager != address(0))
            revert Errors.ContractAlreadyInitialized();
        accountManager = _accountManager;
    }

    /**
        @notice Activates an account by setting the activationBlock to the
            current block number
    */
    function activate() external accountManagerOnly {
        activationBlock = block.number;
    }

    /**
        @notice Deactivates an account by setting the activationBlock to 0
    */
    function deactivate() external accountManagerOnly {
        activationBlock = 0;
    }

    /**
        @notice Returns a list of ERC-20 assets deposited and borrowed by the owner
        @return assets List of addresses
    */
    function getAssets() external view returns (address[] memory) {
        return assets;
    }

    /**
        @notice Returns a list of ERC-20 assets borrowed by the owner
        @return borrows List of addresses
    */
    function getBorrows() external view returns (address[] memory) {
        return borrows;
    }

    /**
        @notice Adds a given ERC-20 token to the assets list
        @param token Address of the ERC-20 token to add
    */
    function addAsset(address token) external accountManagerOnly {
        assets.push(token);
        hasAsset[token] = true;
    }

    /**
        @notice Adds a given ERC-20 token to the borrows list
        @param token Address of the ERC-20 token to add
    */
    function addBorrow(address token) external accountManagerOnly {
        borrows.push(token);
    }

    /**
        @notice Removes a given ERC-20 token from the assets list
        @param token Address of the ERC-20 token to remove
    */
    function removeAsset(address token) external accountManagerOnly {
        _remove(assets, token);
        hasAsset[token] = false;
    }

    /**
        @notice Removes a given ERC-20 token from the borrows list
        @param token Address of the ERC-20 token to remove
    */
    function removeBorrow(address token) external accountManagerOnly {
        _remove(borrows, token);
    }

    /**
        @notice Returns whether the account has debt or not by checking the length
            of the borrows list
        @return hasNoDebt bool
    */
    function hasNoDebt() external view returns (bool) {
        return borrows.length == 0;
    }

    /**
        @notice Generalized utility function to transact with a given contract
        @param target Address of contract to transact with
        @param amt Amount of Eth to send to the target contract
        @param data Encoded sig + params of the function to transact with in the
            target contract
        @return success True if transaction was successful, false otherwise
        @return retData Data returned by given target contract after
            the transaction
    */
    function exec(address target, uint amt, bytes calldata data)
        external
        accountManagerOnly
        returns (bool, bytes memory)
    {
        (bool success, bytes memory retData) = target.call{value: amt}(data);
        return (success, retData);
    }

    /**
        @notice Utility function to transfer all assets to a specified account
            and delete all assets
        @param toAddress address of the account to send the assets to
    */
    function sweepTo(address toAddress) external accountManagerOnly {
        uint assetsLen = assets.length;
        for(uint i; i < assetsLen; ++i) {
            try IERC20(assets[i]).transfer(
                toAddress, assets[i].balanceOf(address(this))
            ) {} catch {}
            if (assets[i].balanceOf(address(this)) == 0)
                hasAsset[assets[i]] = false;
        }
        delete assets;
        toAddress.safeTransferEth(address(this).balance);
    }

    /* -------------------------------------------------------------------------- */
    /*                             INTERNAL FUNCTIONS                             */
    /* -------------------------------------------------------------------------- */

    /**
        @dev Utility function to remove a given address from a list of addresses
        @param arr A list of addresses
        @param token Address to remove
    */
    function _remove(address[] storage arr, address token) internal {
        uint len = arr.length;
        for(uint i; i < len; ++i) {
            if (arr[i] == token) {
                arr[i] = arr[arr.length - 1];
                arr.pop();
                break;
            }
        }
    }

    receive() external payable {}
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

interface IAccount {
    function activate() external;
    function deactivate() external;
    function addAsset(address token) external;
    function addBorrow(address token) external;
    function removeAsset(address token) external;
    function sweepTo(address toAddress) external;
    function removeBorrow(address token) external;
    function init(address accountManager) external;
    function hasAsset(address) external returns (bool);
    function assets(uint) external returns (address);
    function hasNoDebt() external view returns (bool);
    function activationBlock() external view returns (uint);
    function accountManager() external view returns (address);
    function getAssets() external view returns (address[] memory);
    function getBorrows() external view returns (address[] memory);
    function exec(
        address target,
        uint amt,
        bytes calldata data
    ) external returns (bool, bytes memory);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

interface IERC20 {
    function decimals() external view returns (uint8);
    function balanceOf(address _owner) external view returns (uint256 balance);
    function transfer(address _to, uint256 _value)
        external returns (bool success);
    function approve(address _spender, uint256 _value)
        external returns (bool success);
    function allowance(address _owner, address _spender)
        external view returns (uint256 remaining);
    function transferFrom(address _from, address _to, uint256 _value)
        external returns (bool success);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

library Errors {
    error AdminOnly();
    error MaxSupply();
    error ZeroShares();
    error ZeroAssets();
    error ZeroAddress();
    error MinimumShares();
    error ContractPaused();
    error OutstandingDebt();
    error AccountOwnerOnly();
    error TokenNotContract();
    error AddressNotContract();
    error ContractNotPaused();
    error LTokenUnavailable();
    error LiquidationFailed();
    error EthTransferFailure();
    error AccountManagerOnly();
    error RiskThresholdBreached();
    error FunctionCallRestricted();
    error AccountNotLiquidatable();
    error CollateralTypeRestricted();
    error IncorrectConstructorArgs();
    error ContractAlreadyInitialized();
    error AccountDeactivationFailure();
    error AccountInteractionFailure(address, address, uint, bytes);
}

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity ^0.8.17;

import {Errors} from "./Errors.sol";
import {IERC20} from "../interface/tokens/IERC20.sol";
import {IAccount} from "../interface/core/IAccount.sol";

/// @author Modified from Rari-Capital/Solmate
library Helpers {
    function safeTransferFrom(
        address token,
        address from,
        address to,
        uint256 amt
    ) internal {
        if (!isContract(token)) revert Errors.TokenNotContract();
        (bool success, bytes memory data) = address(token).call(
            abi.encodeWithSelector(IERC20.transferFrom.selector, from, to, amt)
        );
        require(success && (data.length == 0 || abi.decode(data, (bool))), "TRANSFER_FROM_FAILED");
    }

    function safeTransfer(
        address token,
        address to,
        uint256 amt
    ) internal {
        if (!isContract(token)) revert Errors.TokenNotContract();
        (bool success, bytes memory data) = address(token).call(
            abi.encodeWithSelector(IERC20.transfer.selector, to, amt)
        );
        require(success && (data.length == 0 || abi.decode(data, (bool))), "TRANSFER_FAILED");
    }

    function safeTransferEth(address to, uint256 amt) internal {
        (bool success, ) = to.call{value: amt}(new bytes(0));
        if(!success) revert Errors.EthTransferFailure();
    }

    function balanceOf(address token, address owner) internal view returns (uint) {
        return IERC20(token).balanceOf(owner);
    }

    function withdrawEth(address account, address to, uint amt) internal {
        (bool success, ) = IAccount(account).exec(to, amt, new bytes(0));
        if(!success) revert Errors.EthTransferFailure();
    }

    function withdraw(address account, address to, address token, uint amt) internal {
        if (!isContract(token)) revert Errors.TokenNotContract();
        (bool success, bytes memory data) = IAccount(account).exec(token, 0,
                abi.encodeWithSelector(IERC20.transfer.selector, to, amt));
        require(success && (data.length == 0 || abi.decode(data, (bool))), "TRANSFER_FAILED");
    }

    function safeApprove(address account, address token, address spender, uint amt) internal {
        (bool success, bytes memory data) = IAccount(account).exec(token, 0,
            abi.encodeWithSelector(IERC20.approve.selector, spender, amt));
        require(success && (data.length == 0 || abi.decode(data, (bool))), "APPROVE_FAILED");
    }

    function isContract(address token) internal view returns (bool) {
        return token.code.length > 0;
    }

    function functionDelegateCall(
        address target,
        bytes calldata data
    ) internal {
        if (!isContract(target)) revert Errors.AddressNotContract();
        (bool success, ) = target.delegatecall(data);
        require(success, "CALL_FAILED");
    }
}