// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8;

import '@coti-cvi/contracts-cvi/contracts/Liquidation.sol';

contract CVIUSDCLiquidation is Liquidation {
  constructor(uint16 _maxCVIValue) Liquidation(_maxCVIValue) {}
}

contract CVIUSDCLiquidation2X is Liquidation {
  constructor(uint16 _maxCVIValue) Liquidation(_maxCVIValue) {}
}

// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8;

import "@openzeppelin/contracts/access/Ownable.sol";
import "./interfaces/ILiquidation.sol";

contract Liquidation is ILiquidation, Ownable {

    uint8 private constant MAX_LEVERAGE = 8;

    uint16 public liquidationMinRewardPercent = 5;
    uint256 public constant LIQUIDATION_MAX_FEE_PERCENTAGE = 1000;

    uint16[MAX_LEVERAGE] public liquidationMinThresholdPercents = [50, 50, 100, 100, 150, 150, 200, 200];
    uint16[MAX_LEVERAGE] public liquidationMaxRewardPercents = [30, 30, 30, 30, 30, 30, 30, 30];

    uint32 public maxCVIValue;

    constructor(uint32 _maxCVIValue) {
        maxCVIValue = _maxCVIValue;
    }

    function setMinLiquidationThresholdPercents(uint16[MAX_LEVERAGE] calldata _newMinThresholdPercents) external override onlyOwner {
        for (uint256 i = 0; i < MAX_LEVERAGE; i++) {
            require(_newMinThresholdPercents[i] >= liquidationMaxRewardPercents[i], "Threshold less than some max");    
        }

        liquidationMinThresholdPercents = _newMinThresholdPercents;
    }

    function setMinLiquidationRewardPercent(uint16 _newMinRewardPercent) external override onlyOwner {
        for (uint256 i = 0; i < MAX_LEVERAGE; i++) {
            require(_newMinRewardPercent <= liquidationMaxRewardPercents[i], "Min greater than some max");    
        }
        
        liquidationMinRewardPercent = _newMinRewardPercent;
    }

    function setMaxLiquidationRewardPercents(uint16[MAX_LEVERAGE] calldata _newMaxRewardPercents) external override onlyOwner {
        for (uint256 i = 0; i < MAX_LEVERAGE; i++) {
            require(_newMaxRewardPercents[i] <= liquidationMinThresholdPercents[i], "Some max greater than threshold");
            require(_newMaxRewardPercents[i] >= liquidationMinRewardPercent, "Some max less than min");
        }

        liquidationMaxRewardPercents = _newMaxRewardPercents;
    }

    function isLiquidationCandidate(uint256 _positionBalance, bool _isPositive, uint168 _positionUnitsAmount, uint32 _openCVIValue, uint8 _leverage) public view override returns (bool) {
        uint256 originalBalance = calculateOriginalBalance(_positionUnitsAmount, _openCVIValue, _leverage);
        return (!_isPositive ||  _positionBalance < originalBalance * liquidationMinThresholdPercents[_leverage - 1] / LIQUIDATION_MAX_FEE_PERCENTAGE);
    }

    function getLiquidationReward(uint256 _positionBalance, bool _isPositive, uint168 _positionUnitsAmount, uint32 _openCVIValue, uint8 _leverage) external view override returns (uint256 finderFeeAmount) {
        if (!isLiquidationCandidate(_positionBalance, _isPositive, _positionUnitsAmount, _openCVIValue, _leverage)) {
            return 0;
        }

        uint256 originalBalance = calculateOriginalBalance(_positionUnitsAmount, _openCVIValue, _leverage);
        uint256 minLiuquidationReward = originalBalance * liquidationMinRewardPercent / LIQUIDATION_MAX_FEE_PERCENTAGE;

        if (!_isPositive || _positionBalance < minLiuquidationReward) {
            return minLiuquidationReward;
        }

        uint256 maxLiquidationReward = originalBalance * liquidationMaxRewardPercents[_leverage - 1] / LIQUIDATION_MAX_FEE_PERCENTAGE;
        
        if (_isPositive && _positionBalance >= minLiuquidationReward && _positionBalance <= maxLiquidationReward) {
            finderFeeAmount = _positionBalance;
        } else {
            finderFeeAmount = maxLiquidationReward;
        }
    }

    function calculateOriginalBalance(uint168 _positionUnitsAmount, uint32 _openCVIValue, uint8 _leverage) private view returns (uint256) {
        return _positionUnitsAmount * _openCVIValue / maxCVIValue - _positionUnitsAmount * _openCVIValue / maxCVIValue * (_leverage - 1) / _leverage;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (access/Ownable.sol)

pragma solidity ^0.8.0;

import "../utils/Context.sol";

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
        _transferOwnership(_msgSender());
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
        _transferOwnership(address(0));
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _transferOwnership(newOwner);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Internal function without access restriction.
     */
    function _transferOwnership(address newOwner) internal virtual {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}

// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8;

interface ILiquidation {	
	function setMinLiquidationThresholdPercents(uint16[8] calldata newMinThresholdPercents) external;
	function setMinLiquidationRewardPercent(uint16 newMinRewardPercent) external;
	function setMaxLiquidationRewardPercents(uint16[8] calldata newMaxRewardPercents) external;
	function isLiquidationCandidate(uint256 positionBalance, bool isPositive, uint168 positionUnitsAmount, uint32 openCVIValue, uint8 leverage) external view returns (bool);
	function getLiquidationReward(uint256 positionBalance, bool isPositive, uint168 positionUnitsAmount, uint32 openCVIValue, uint8 leverage) external view returns (uint256 finderFeeAmount);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/Context.sol)

pragma solidity ^0.8.0;

/**
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
        return msg.data;
    }
}