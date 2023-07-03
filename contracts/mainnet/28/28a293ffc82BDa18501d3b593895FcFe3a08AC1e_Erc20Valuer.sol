// SPDX-License-Identifier: MIT

pragma solidity ^0.8.8;

import { IERC20Internal } from './IERC20Internal.sol';

/**
 * @title ERC20 interface
 * @dev see https://github.com/ethereum/EIPs/issues/20
 */
interface IERC20 is IERC20Internal {
    /**
     * @notice query the total minted token supply
     * @return token supply
     */
    function totalSupply() external view returns (uint256);

    /**
     * @notice query the token balance of given account
     * @param account address to query
     * @return token balance
     */
    function balanceOf(address account) external view returns (uint256);

    /**
     * @notice query the allowance granted from given holder to given spender
     * @param holder approver of allowance
     * @param spender recipient of allowance
     * @return token allowance
     */
    function allowance(
        address holder,
        address spender
    ) external view returns (uint256);

    /**
     * @notice grant approval to spender to spend tokens
     * @dev prefer ERC20Extended functions to avoid transaction-ordering vulnerability (see https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729)
     * @param spender recipient of allowance
     * @param amount quantity of tokens approved for spending
     * @return success status (always true; otherwise function should revert)
     */
    function approve(address spender, uint256 amount) external returns (bool);

    /**
     * @notice transfer tokens to given recipient
     * @param recipient beneficiary of token transfer
     * @param amount quantity of tokens to transfer
     * @return success status (always true; otherwise function should revert)
     */
    function transfer(
        address recipient,
        uint256 amount
    ) external returns (bool);

    /**
     * @notice transfer tokens to given recipient on behalf of given holder
     * @param holder holder of tokens prior to transfer
     * @param recipient beneficiary of token transfer
     * @param amount quantity of tokens to transfer
     * @return success status (always true; otherwise function should revert)
     */
    function transferFrom(
        address holder,
        address recipient,
        uint256 amount
    ) external returns (bool);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.8;

/**
 * @title Partial ERC20 interface needed by internal functions
 */
interface IERC20Internal {
    event Transfer(address indexed from, address indexed to, uint256 value);

    event Approval(
        address indexed owner,
        address indexed spender,
        uint256 value
    );
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.8;

import { IERC20MetadataInternal } from './IERC20MetadataInternal.sol';

/**
 * @title ERC20 metadata interface
 */
interface IERC20Metadata is IERC20MetadataInternal {
    /**
     * @notice return token name
     * @return token name
     */
    function name() external view returns (string memory);

    /**
     * @notice return token symbol
     * @return token symbol
     */
    function symbol() external view returns (string memory);

    /**
     * @notice return token decimals, generally used only for display purposes
     * @return token decimals
     */
    function decimals() external view returns (uint8);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.8;

/**
 * @title ERC20 metadata internal interface
 */
interface IERC20MetadataInternal {

}

// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.0;

import { IERC20 } from '@solidstate/contracts/interfaces/IERC20.sol';
import { IERC20Metadata } from '@solidstate/contracts/token/ERC20/metadata/IERC20Metadata.sol';

import { IValuer } from '../valuers/IValuer.sol';

contract Erc20Valuer is IValuer {
    function getVaultValue(
        address vault,
        address asset,
        int256 unitPrice
    ) external view returns (uint256 minValue, uint256 maxValue) {
        return _getVaultValue(vault, asset, unitPrice);
    }

    function getAssetValue(
        uint amount,
        address asset,
        int256 unitPrice
    ) external view returns (uint256 minValue, uint256 maxValue) {
        return _getAssetValue(amount, asset, unitPrice);
    }

    function getAssetBreakdown(
        address vault,
        address asset,
        int256 unitPrice
    ) external view returns (AssetValue memory) {
        (uint min, uint max) = _getVaultValue(vault, asset, unitPrice);
        uint balance = IERC20(asset).balanceOf(vault);
        AssetBreakDown[] memory ab = new AssetBreakDown[](1);
        ab[0] = AssetBreakDown(asset, balance, min, max);
        return AssetValue(asset, min, max, ab);
    }

    function getAssetActive(
        address vault,
        address asset
    ) external view returns (bool) {
        return IERC20(asset).balanceOf(vault) > 0;
    }

    function _getVaultValue(
        address vault,
        address asset,
        int256 unitPrice
    ) internal view returns (uint256 minValue, uint256 maxValue) {
        uint balance = IERC20(asset).balanceOf(vault);
        return _getAssetValue(balance, asset, unitPrice);
    }

    function _getAssetValue(
        uint amount,
        address asset,
        int256 unitPrice
    ) internal view returns (uint256 minValue, uint256 maxValue) {
        uint decimals = IERC20Metadata(asset).decimals();
        uint value = (uint(unitPrice) * amount) / (10 ** decimals);
        return (value, value);
    }
}

// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.0;

interface IValuer {
    struct AssetValue {
        address asset;
        uint256 totalMinValue;
        uint256 totalMaxValue;
        AssetBreakDown[] breakDown;
    }

    struct AssetBreakDown {
        address asset;
        uint256 balance;
        uint256 minValue;
        uint256 maxValue;
    }

    function getVaultValue(
        address vault,
        address asset,
        int256 unitPrice
    ) external view returns (uint256 minValue, uint256 maxValue);

    function getAssetValue(
        uint amount,
        address asset,
        int256 unitPrice
    ) external view returns (uint256 minValue, uint256 maxValue);

    // This returns an array because later on we may support assets that have multiple tokens
    // Or we may want to break GMX down into individual positions
    function getAssetBreakdown(
        address vault,
        address asset,
        int256 unitPrice
    ) external view returns (AssetValue memory);

    function getAssetActive(
        address vault,
        address asset
    ) external view returns (bool);
}