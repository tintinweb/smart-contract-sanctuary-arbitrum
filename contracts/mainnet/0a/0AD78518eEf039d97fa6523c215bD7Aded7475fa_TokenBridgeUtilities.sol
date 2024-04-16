// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v5.0.0) (token/ERC20/IERC20.sol)

pragma solidity ^0.8.20;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20 {
    /**
     * @dev Emitted when `value` tokens are moved from one account (`from`) to
     * another (`to`).
     *
     * Note that `value` may be zero.
     */
    event Transfer(address indexed from, address indexed to, uint256 value);

    /**
     * @dev Emitted when the allowance of a `spender` for an `owner` is set by
     * a call to {approve}. `value` is the new allowance.
     */
    event Approval(address indexed owner, address indexed spender, uint256 value);

    /**
     * @dev Returns the value of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the value of tokens owned by `account`.
     */
    function balanceOf(address account) external view returns (uint256);

    /**
     * @dev Moves a `value` amount of tokens from the caller's account to `to`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address to, uint256 value) external returns (bool);

    /**
     * @dev Returns the remaining number of tokens that `spender` will be
     * allowed to spend on behalf of `owner` through {transferFrom}. This is
     * zero by default.
     *
     * This value changes when {approve} or {transferFrom} are called.
     */
    function allowance(address owner, address spender) external view returns (uint256);

    /**
     * @dev Sets a `value` amount of tokens as the allowance of `spender` over the
     * caller's tokens.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * IMPORTANT: Beware that changing an allowance with this method brings the risk
     * that someone may use both the old and the new allowance by unfortunate
     * transaction ordering. One possible solution to mitigate this race
     * condition is to first reduce the spender's allowance to 0 and set the
     * desired value afterwards:
     * https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
     *
     * Emits an {Approval} event.
     */
    function approve(address spender, uint256 value) external returns (bool);

    /**
     * @dev Moves a `value` amount of tokens from `from` to `to` using the
     * allowance mechanism. `value` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(address from, address to, uint256 value) external returns (bool);
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import "../../interfaces/IERC20decimals.sol";

/**
 * @title TokenBridgeUtilities
 * @notice A set of internal utility functions
 */
library TokenBridgeUtilities {
    error TooManyDecimalPlaces();

    uint8 public constant MAX_DECIMALS = 8;

    /**
     * @dev This function checks if the asset amount is valid for the token bridge
     * @param assetAddress The address of the asset
     * @param assetAmount The amount of the asset
     */
    function requireAssetAmountValidForTokenBridge(address assetAddress, uint256 assetAmount) public view {
        uint8 decimals;
        if (assetAddress == address(0)) {
            // native ETH
            decimals = 18;
        } else {
            decimals = IERC20decimals(assetAddress).decimals();
        }

        if (decimals > MAX_DECIMALS && trimDust(assetAmount, decimals) != assetAmount) {
            revert TooManyDecimalPlaces();
        }
    }

    function trimDust(uint256 amount, uint8 decimals) public pure returns (uint256) {
        return denormalizeAmount(normalizeAmount(amount, decimals), decimals);
    }

    /**
     * @dev This function normalizes the amount based on the decimals
     * @param amount The amount to be normalized
     * @param decimals The number of decimals
     * @return The normalized amount
     */
    function normalizeAmount(uint256 amount, uint8 decimals) public pure returns (uint256) {
        if (decimals > MAX_DECIMALS) {
            amount /= uint256(10) ** (decimals - MAX_DECIMALS);
        }

        return amount;
    }

    /**
     * @dev This function normalizes the amount based on the decimals
     * @param amount The amount to be normalized
     * @param decimals The number of decimals
     * @return The normalized amount
     */
    function denormalizeAmount(uint256 amount, uint8 decimals) public pure returns (uint256) {
        if (decimals > MAX_DECIMALS) {
            amount *= uint256(10) ** (decimals - MAX_DECIMALS);
        }

        return amount;
    }
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

interface IERC20decimals is IERC20 {
    function decimals() external view returns (uint8);
}