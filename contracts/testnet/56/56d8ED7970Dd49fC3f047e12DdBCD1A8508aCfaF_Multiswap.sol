// SPDX-License-Identifier: Unlicense
pragma solidity 0.8.11;
pragma experimental ABIEncoderV2;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract Multiswap {

    address public immutable router;

    constructor(address _router) {
        router = _router;
    }

    error ErrorSwapping(uint index);

    event Multiswapped(address indexed _token, uint _amountIn, uint[] amountsOut);

    /// @notice Swaps an asset to up to 5 other assets according to predetermined weights
    /// @param _token           The asset to swap (address(0) if ETH)
    /// @param _amount          The amount to swap (0 if _token is ETH)
    /// @param _weights         The respective weights to be attributed to each assets (in basis points, 10000 = 100%)
    /// @param _swapData        An array of data to be passed to each swap
    /// @return amountsOut An array with the respective amounts of assets received
    function multiswap(
        address _token,
        uint _amount,
        bytes[] memory _swapData,
        uint[] calldata _weights
    ) external payable returns (uint[] memory) {
        uint length = _swapData.length;
        // Checks
        require(length > 1 && length <= 5 && _weights.length == length, "length");
        require(_assertWeights(_weights), "wrong weights");
        // Effects
        uint[] memory amountsOut = new uint[](length);
        bool eth;
        uint preBalance;
        uint postBalance;
        if (eth = (_token == address(0))) {
            // Caller wants to multiswap some ETH
            require(msg.value > 0 && msg.value > 10000, "no ETH sent");
            preBalance = address(this).balance;
            for (uint i = 0; i < length; ++i) { 
                uint amount_ = msg.value * _weights[i] / 10000;
                (bool success, bytes memory data) = router.call{value: amount_}(_swapData[i]);
                if (!success) revert ErrorSwapping(i);
                uint[] memory out = abi.decode(data, (uint[]));
                amountsOut[i] = out[out.length - 1];
            }
            postBalance = address(this).balance;
        } else {
            // Caller wants to multiswap a token
            require(_amount > 0 && _amount > 10000, "no tokens sent");
            preBalance = IERC20(_token).balanceOf(address(this));
            IERC20(_token).transferFrom(msg.sender, address(this), _amount);
            IERC20(_token).approve(router, _amount);
            for (uint i = 0; i < length; ++i) {
                (bool success, bytes memory data) = router.call(_swapData[i]);
                if (!success) revert ErrorSwapping(i);
                uint[] memory out = abi.decode(data, (uint[]));
                amountsOut[i] = out[out.length - 1];
            }
            postBalance = IERC20(_token).balanceOf(address(this));
        }

        uint delta = postBalance - preBalance;
        if (delta > 0) {
            if (eth) {
                // Return any ETH left over to the caller
                (bool success,) = msg.sender.call{value:delta}(new bytes(0));
                require(success, "ETH transfer failed");
            } else {
                // Return any tokens left over to the caller
                _safeTransfer(_token, msg.sender, delta);
            }
        }

        emit Multiswapped(_token, eth ? msg.value : _amount, amountsOut);

        return amountsOut;
    }

    // ***** INTERNAL *****
    function _assertWeights(uint[] calldata _weights) internal pure returns (bool) {
        uint totalWeight = 10000; // Basis points
        uint weightSum = 0;
        uint length = _weights.length;
        for (uint i = 0; i < length; ++i) {
            if (i == 0) return false;
            weightSum += _weights[i];
            
        }
        return weightSum == totalWeight;
    }

    function _safeTransfer(address token, address to, uint256 value) internal {
        require(token.code.length > 0);
        (bool success, bytes memory data) =
        token.call(abi.encodeWithSelector(IERC20.transfer.selector, to, value));
        require(success && (data.length == 0 || abi.decode(data, (bool))));
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC20/IERC20.sol)

pragma solidity ^0.8.0;

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
     * @dev Returns the amount of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the amount of tokens owned by `account`.
     */
    function balanceOf(address account) external view returns (uint256);

    /**
     * @dev Moves `amount` tokens from the caller's account to `to`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address to, uint256 amount) external returns (bool);

    /**
     * @dev Returns the remaining number of tokens that `spender` will be
     * allowed to spend on behalf of `owner` through {transferFrom}. This is
     * zero by default.
     *
     * This value changes when {approve} or {transferFrom} are called.
     */
    function allowance(address owner, address spender) external view returns (uint256);

    /**
     * @dev Sets `amount` as the allowance of `spender` over the caller's tokens.
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
    function approve(address spender, uint256 amount) external returns (bool);

    /**
     * @dev Moves `amount` tokens from `from` to `to` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) external returns (bool);
}