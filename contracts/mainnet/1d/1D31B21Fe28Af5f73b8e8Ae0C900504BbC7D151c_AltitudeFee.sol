/**
 *Submitted for verification at Arbiscan on 2023-07-07
*/

// SPDX-License-Identifier: MIT

pragma solidity 0.8.18;

/******************************************/
/*           Context starts here          */
/******************************************/

// File: @openzeppelin/contracts/GSN/Context.sol

/*
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
 *
 * This contract is only required for intermediate, library-like contracts.
 */
abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
}

/******************************************/
/*           Ownable starts here          */
/******************************************/

/**
 * @dev Contract module which provides a basic access control mechanism, where
 * there is an account (an owner) that can be granted exclusive access to
 * specific functions.
 *
 * By default, the owner account will be the one that deploys the contract. This
 * can later be changed with {transferOwnership}.
 *
 * This module is used through inheritance. It will make available the modifier
 * `onlyOwner`, which can be applied to your functions to restrict their use to
 * the owner.
 */

abstract contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor() {
        address msgSender = _msgSender();
        _owner = msgSender;
        emit OwnershipTransferred(address(0), msgSender);
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
        _;
    }

    /**
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions anymore. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby removing any functionality that is only available to the owner.
     */
    function renounceOwnership() public virtual onlyOwner {
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}

/******************************************/
/*         AltitudeFee starts here        */
/******************************************/

contract AltitudeFee is Ownable {

    // VARIABLES
    uint256 private P = 50 * 1e14;
    uint256 private D1 = 6000 * 1e14;
    uint256 private D2 = 500 * 1e14;
    uint256 private L1 = 40 * 1e14;
    uint256 private L2 = 9960 * 1e14;

    event FeeParametersUpdated(uint256 _protocolFee, uint256 _D1, uint256 _D2, uint256 _L1, uint256 _L2);

    /**
     * @dev Set the rebalance fee (denominator 1e18).
     */
    function setFeeParameters(uint256 _protocolFee, uint256 _D1, uint256 _D2, uint256 _L1, uint256 _L2) external onlyOwner {
        P = _protocolFee;
        D1 = _D1;
        D2 = _D2;
        L1 = _L1;
        L2 = _L2;
        emit FeeParametersUpdated(_protocolFee, _D1, _D2, _L1, _L2);
    }

    function getFeeParameters() external view returns (uint256, uint256, uint256, uint256, uint256) {
        return (P, D1, D2, L1, L2);
    }

    function getRebalanceFee(uint256 idealBalance, uint256 preBalance, uint256 amount) external view returns (uint256 rebalanceFee) {
        require(preBalance >= amount, "Altitude: not enough balance");
        uint256 postBalance = preBalance - amount;
        uint256 safeZoneMax = idealBalance * D1 / 1e18;
        uint256 safeZoneMin = idealBalance * D2 / 1e18;
        rebalanceFee = 0;
        if (postBalance >= safeZoneMax) {
        } else if (postBalance >= safeZoneMin) {
            uint256 proxyPreBalance = preBalance < safeZoneMax ? preBalance : safeZoneMax;
            rebalanceFee = _getTrapezoidArea(L1, 0, safeZoneMax, safeZoneMin, proxyPreBalance, postBalance);
        } else {
            if (preBalance >= safeZoneMin) {
                uint256 proxyPreBalance = preBalance < safeZoneMax ? preBalance : safeZoneMax;
                rebalanceFee = rebalanceFee + _getTrapezoidArea(L1, 0, safeZoneMax, safeZoneMin, proxyPreBalance, safeZoneMin);
                rebalanceFee = rebalanceFee + _getTrapezoidArea(L2, L1, safeZoneMin, 0, safeZoneMin, postBalance);
            } else {
                rebalanceFee = rebalanceFee + _getTrapezoidArea(L2, L1, safeZoneMin, 0, preBalance, postBalance);
            }
        }
        return rebalanceFee;
    }

    function _getTrapezoidArea(uint256 lambda, uint256 yOffset, uint256 xUpperBound, uint256 xLowerBound, uint256 xStart, uint256 xEnd) internal pure returns (uint256) {
        require(xEnd >= xLowerBound && xStart <= xUpperBound, "Altitude: balance out of bound");
        uint256 xBoundWidth = xUpperBound - xLowerBound;
        uint256 yStart = (xUpperBound - xStart) * lambda / xBoundWidth + yOffset;
        uint256 yEnd = (xUpperBound - xEnd) * lambda / xBoundWidth + yOffset;
        uint256 deltaX = xStart - xEnd;
        return (yStart + yEnd) * deltaX / 2 / 1e18;
    }
}