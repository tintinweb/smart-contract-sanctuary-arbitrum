// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v5.0.0) (access/Ownable.sol)

pragma solidity ^0.8.19;

import {Context} from "../utils/Context.sol";

/**
 * @dev Contract module which provides a basic access control mechanism, where
 * there is an account (an owner) that can be granted exclusive access to
 * specific functions.
 *
 * The initial owner is set to the address provided by the deployer. This can
 * later be changed with {transferOwnership}.
 *
 * This module is used through inheritance. It will make available the modifier
 * `onlyOwner`, which can be applied to your functions to restrict their use to
 * the owner.
 */
abstract contract Ownable is Context {
    address private _owner;

    /**
     * @dev The caller account is not authorized to perform an operation.
     */
    error OwnableUnauthorizedAccount(address account);

    /**
     * @dev The owner is not a valid owner account. (eg. `address(0)`)
     */
    error OwnableInvalidOwner(address owner);

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the address provided by the deployer as the initial owner.
     */
    constructor(address initialOwner) {
        if (initialOwner == address(0)) {
            revert OwnableInvalidOwner(address(0));
        }
        _transferOwnership(initialOwner);
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        _checkOwner();
        _;
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if the sender is not the owner.
     */
    function _checkOwner() internal view virtual {
        if (owner() != _msgSender()) {
            revert OwnableUnauthorizedAccount(_msgSender());
        }
    }

    /**
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby disabling any functionality that is only available to the owner.
     */
    function renounceOwnership() public virtual onlyOwner {
        _transferOwnership(address(0));
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        if (newOwner == address(0)) {
            revert OwnableInvalidOwner(address(0));
        }
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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.9.0) (security/ReentrancyGuard.sol)

pragma solidity ^0.8.0;

/**
 * @dev Contract module that helps prevent reentrant calls to a function.
 *
 * Inheriting from `ReentrancyGuard` will make the {nonReentrant} modifier
 * available, which can be applied to functions to make sure there are no nested
 * (reentrant) calls to them.
 *
 * Note that because there is a single `nonReentrant` guard, functions marked as
 * `nonReentrant` may not call one another. This can be worked around by making
 * those functions `private`, and then adding `external` `nonReentrant` entry
 * points to them.
 *
 * TIP: If you would like to learn more about reentrancy and alternative ways
 * to protect against it, check out our blog post
 * https://blog.openzeppelin.com/reentrancy-after-istanbul/[Reentrancy After Istanbul].
 */
abstract contract ReentrancyGuard {
    // Booleans are more expensive than uint256 or any type that takes up a full
    // word because each write operation emits an extra SLOAD to first read the
    // slot's contents, replace the bits taken up by the boolean, and then write
    // back. This is the compiler's defense against contract upgrades and
    // pointer aliasing, and it cannot be disabled.

    // The values being non-zero value makes deployment a bit more expensive,
    // but in exchange the refund on every call to nonReentrant will be lower in
    // amount. Since refunds are capped to a percentage of the total
    // transaction's gas, it is best to keep them low in cases like this one, to
    // increase the likelihood of the full refund coming into effect.
    uint256 private constant _NOT_ENTERED = 1;
    uint256 private constant _ENTERED = 2;

    uint256 private _status;

    constructor() {
        _status = _NOT_ENTERED;
    }

    /**
     * @dev Prevents a contract from calling itself, directly or indirectly.
     * Calling a `nonReentrant` function from another `nonReentrant`
     * function is not supported. It is possible to prevent this from happening
     * by making the `nonReentrant` function external, and making it call a
     * `private` function that does the actual work.
     */
    modifier nonReentrant() {
        _nonReentrantBefore();
        _;
        _nonReentrantAfter();
    }

    function _nonReentrantBefore() private {
        // On the first call to nonReentrant, _status will be _NOT_ENTERED
        require(_status != _ENTERED, "ReentrancyGuard: reentrant call");

        // Any calls to nonReentrant after this point will fail
        _status = _ENTERED;
    }

    function _nonReentrantAfter() private {
        // By storing the original value once again, a refund is triggered (see
        // https://eips.ethereum.org/EIPS/eip-2200)
        _status = _NOT_ENTERED;
    }

    /**
     * @dev Returns true if the reentrancy guard is currently set to "entered", which indicates there is a
     * `nonReentrant` function in the call stack.
     */
    function _reentrancyGuardEntered() internal view returns (bool) {
        return _status == _ENTERED;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v5.0.0) (token/ERC20/IERC20.sol)

pragma solidity ^0.8.19;

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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v5.0.1) (utils/Context.sol)

pragma solidity ^0.8.19;

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

    function _contextSuffixLength() internal view virtual returns (uint256) {
        return 0;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.9.0) (utils/math/SafeMath.sol)

pragma solidity ^0.8.0;

// CAUTION
// This version of SafeMath should only be used with Solidity 0.8 or later,
// because it relies on the compiler's built in overflow checks.

/**
 * @dev Wrappers over Solidity's arithmetic operations.
 *
 * NOTE: `SafeMath` is generally not needed starting with Solidity 0.8, since the compiler
 * now has built in overflow checking.
 */
library SafeMath {
    /**
     * @dev Returns the addition of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryAdd(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            uint256 c = a + b;
            if (c < a) return (false, 0);
            return (true, c);
        }
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function trySub(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b > a) return (false, 0);
            return (true, a - b);
        }
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryMul(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
            // benefit is lost if 'b' is also tested.
            // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
            if (a == 0) return (true, 0);
            uint256 c = a * b;
            if (c / a != b) return (false, 0);
            return (true, c);
        }
    }

    /**
     * @dev Returns the division of two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryDiv(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a / b);
        }
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryMod(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a % b);
        }
    }

    /**
     * @dev Returns the addition of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `+` operator.
     *
     * Requirements:
     *
     * - Addition cannot overflow.
     */
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        return a + b;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting on
     * overflow (when the result is negative).
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return a - b;
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `*` operator.
     *
     * Requirements:
     *
     * - Multiplication cannot overflow.
     */
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        return a * b;
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator.
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return a / b;
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * reverting when dividing by zero.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return a % b;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting with custom message on
     * overflow (when the result is negative).
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {trySub}.
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        unchecked {
            require(b <= a, errorMessage);
            return a - b;
        }
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting with custom message on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        unchecked {
            require(b > 0, errorMessage);
            return a / b;
        }
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * reverting with custom message when dividing by zero.
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {tryMod}.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        unchecked {
            require(b > 0, errorMessage);
            return a % b;
        }
    }
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.19;
interface IBulker {
    function invoke(bytes32[] calldata actions, bytes[] calldata data) external payable ;
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

abstract contract IComet {
    struct AssetInfo {
        uint8 offset;
        address asset;
        address priceFeed;
        uint64 scale;
        uint64 borrowCollateralFactor;
        uint64 liquidateCollateralFactor;
        uint64 liquidationFactor;
        uint128 supplyCap;
    }

    struct TotalsCollateral {
        uint128 totalSupplyAsset;
        uint128 _reserved;
    }

    struct UserCollateral {
        uint128 balance;
        uint128 _reserved;
    }

    struct UserBasic {
        int104 principal;
        uint64 baseTrackingIndex;
        uint64 baseTrackingAccrued;
        uint16 assetsIn;
        uint8 _reserved;
    }

    struct TotalsBasic {
        uint64 baseSupplyIndex;
        uint64 baseBorrowIndex;
        uint64 trackingSupplyIndex;
        uint64 trackingBorrowIndex;
        uint104 totalSupplyBase;
        uint104 totalBorrowBase;
        uint40 lastAccrualTime;
        uint8 pauseFlags;
    }

    function totalsBasic() public view virtual returns (TotalsBasic memory);

    function totalsCollateral(address) public virtual returns (TotalsCollateral memory);

    function supply(address asset, uint amount) external virtual;

    function supplyTo(address dst, address asset, uint amount) external virtual;

    function supplyFrom(address from, address dst, address asset, uint amount) external virtual;

    function transfer(address dst, uint amount) external virtual returns (bool);

    function transferFrom(address src, address dst, uint amount) external virtual returns (bool);

    function transferAsset(address dst, address asset, uint amount) external virtual;

    function transferAssetFrom(
        address src,
        address dst,
        address asset,
        uint amount
    ) external virtual;

    function withdraw(address asset, uint amount) external virtual;

    function withdrawTo(address to, address asset, uint amount) external virtual;

    function withdrawFrom(address src, address to, address asset, uint amount) external virtual;

    function accrueAccount(address account) external virtual;

    function getSupplyRate(uint utilization) public view virtual returns (uint64);

    function getBorrowRate(uint utilization) public view virtual returns (uint64);

    function getUtilization() public view virtual returns (uint);

    function governor() external view virtual returns (address);

    function baseToken() external view virtual returns (address);

    function baseTokenPriceFeed() external view virtual returns (address);

    function balanceOf(address account) public view virtual returns (uint256);

    function collateralBalanceOf(
        address account,
        address asset
    ) external view virtual returns (uint128);

    function borrowBalanceOf(address account) public view virtual returns (uint256);

    function totalSupply() external view virtual returns (uint256);

    function numAssets() public view virtual returns (uint8);

    function getAssetInfo(uint8 i) public view virtual returns (AssetInfo memory);

    function getAssetInfoByAddress(address asset) public view virtual returns (AssetInfo memory);

    function getPrice(address priceFeed) public view virtual returns (uint256);

    function allow(address manager, bool isAllowed) external virtual;

    function allowance(address owner, address spender) external view virtual returns (uint256);

    function isSupplyPaused() external view virtual returns (bool);

    function isTransferPaused() external view virtual returns (bool);

    function isWithdrawPaused() external view virtual returns (bool);

    function isAbsorbPaused() external view virtual returns (bool);

    function baseIndexScale() external pure virtual returns (uint64);

    function userBasic(address) external view virtual returns (UserBasic memory);

    function userCollateral(address, address) external view virtual returns (UserCollateral memory);

    function priceScale() external pure virtual returns (uint64);

    function factorScale() external pure virtual returns (uint64);

    function baseBorrowMin() external pure virtual returns (uint256);

    function baseTrackingBorrowSpeed() external pure virtual returns (uint256);

    function baseTrackingSupplySpeed() external pure virtual returns (uint256);
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

abstract contract ICometRewards {
    struct RewardConfig {
        address token;
        uint64 rescaleFactor;
        bool shouldUpscale;
    }
    struct RewardOwed {
        address token;
        uint owed;
    }

    function claim(address comet, address src, bool shouldAccrue) external virtual;

    function rewardConfig(address) external virtual returns (RewardConfig memory);

    function rewardsClaimed(address _market, address _user) external view virtual returns (uint256);

    function getRewardOwed(
        address _market,
        address _user
    ) external virtual returns (RewardOwed memory);
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

interface ITokenDecimals {
    function decimals() external view returns (uint8);
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

//  _________  ________  ________  ________  ___  ___  _______
// |\___   ___\\   __  \|\   __  \|\   __  \|\  \|\  \|\  ___ \
// \|___ \  \_\ \  \|\  \ \  \|\  \ \  \|\  \ \  \\\  \ \   __/|
//     \ \  \ \ \  \\\  \ \   _  _\ \  \\\  \ \  \\\  \ \  \_|/__
//      \ \  \ \ \  \\\  \ \  \\  \\ \  \\\  \ \  \\\  \ \  \_|\ \
//       \ \__\ \ \_______\ \__\\ _\\ \_____  \ \_______\ \_______\
//        \|__|  \|_______|\|__|\|__|\|___| \__\|_______|\|_______|

import "./interfaces/IComet.sol";
import "./interfaces/IBulker.sol";
import "./interfaces/ICometRewards.sol";
import "./interfaces/ITokenDecimals.sol";

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

abstract contract SimpleBorrowAbstract is Ownable, ReentrancyGuard {
    using SafeMath for uint256;

    address public comet;
    address public cometReward;
    address public asset;
    address public baseAsset;
    address public bulker;
    address public treasury;
    address public controller;
    
    uint public claimPeriod;
    uint public repaySlippage;
    uint public lastClaimCometTime;

    uint256 public borrowHealth;

    uint256 public decimalAdjust = 1000000000000;
    
    bytes32 public constant ACTION_SUPPLY_ASSET = "ACTION_SUPPLY_ASSET";
    bytes32 public constant ACTION_SUPPLY_ETH = "ACTION_SUPPLY_NATIVE_TOKEN";
    bytes32 public constant ACTION_TRANSFER_ASSET = "ACTION_TRANSFER_ASSET";
    bytes32 public constant ACTION_WITHDRAW_ASSET = "ACTION_WITHDRAW_ASSET";
    bytes32 public constant ACTION_WITHDRAW_ETH = "ACTION_WITHDRAW_NATIVE_TOKEN";
    bytes32 public constant ACTION_CLAIM_REWARD = "ACTION_CLAIM_REWARD";

    constructor(
        address _initialOwner,
        address _comet, // Compound V3 Address
        address _cometReward, // Address for Claiming Comet Rewards
        address _asset, // Collateral to be staked (WBTC / WETH)
        address _baseAsset, // Borrowing Asset (USDC)
        address _bulker, // Bulker Contract 
        address _treasury, // Fees Address
        address _controller,
        uint _repaySlippage // Slippage %
    ) {
        Ownable.transferOwnership(_initialOwner);
        comet = _comet;
        cometReward = _cometReward;
        asset = _asset;
        baseAsset = _baseAsset;
        bulker = _bulker;
        treasury = _treasury;
        IComet(_comet).allow(_bulker, true);
        claimPeriod = 86400; // 1 day in seconds
        repaySlippage = _repaySlippage;
        controller = _controller;
    }
    
    uint constant BASE_ASSET_MANTISA = 1e6;
    uint constant PRICE_MANTISA = 1e2;
    uint constant SCALE = 1e18;
    uint constant WITHDRAW_OFFSET = 1e2;
    uint constant TUSD_DECIMAL_OFFSET = 1e12;
    uint constant PRICE_SCALE = 1e8;

    uint public borrowed; // USDC Borrowed 
    uint public supplied; // WBTC Supplied
    uint public borrowTime; // Borrow time

    event UserBorrow(address user, address collateralAddress, uint amount);
    event UserRepay(address user, address collateralAddress, uint repayAmount, uint claimAmount);

    function getCollateralFactor() public view returns (uint){
        IComet icomet = IComet(comet);
        IComet.AssetInfo memory info = icomet.getAssetInfoByAddress(asset);
        return info.borrowCollateralFactor;
    }

    function withdraw(address _address, uint withdrawAmount) public nonReentrant() {
        require(msg.sender == controller, "Cannot be called directly");
        require(supplied > 0, "User does not have asset");
        if (borrowed > 0) {
            uint accruedInterest = calculateInterest(borrowed, borrowTime);
            borrowed = borrowed.add(accruedInterest);
            borrowTime = block.timestamp;
        }
        IComet icomet = IComet(comet);
        IComet.AssetInfo memory info = icomet.getAssetInfoByAddress(asset);
        uint price = icomet.getPrice(info.priceFeed);
        uint assetDecimal = ITokenDecimals(asset).decimals();
        uint minRequireSupplyAmount = borrowed.mul(SCALE).mul(10**assetDecimal).mul(PRICE_MANTISA).div(price).div(uint(info.borrowCollateralFactor).sub(WITHDRAW_OFFSET));
        uint withdrawableAmount = supplied - minRequireSupplyAmount;
        require(withdrawAmount <= withdrawableAmount, "Exceeds asset supply");
        supplied = supplied.sub(withdrawAmount);
        bytes[] memory callData = new bytes[](1);
        bytes memory withdrawAssetCalldata = abi.encode(comet, address(this), asset, withdrawAmount);
        callData[0] = withdrawAssetCalldata;
        IBulker(bulker).invoke(buildWithdraw(), callData);
        require(IERC20(asset).transfer(_address, withdrawAmount), "Transfer Asset Failed");
    } 
    
    function borrowBalanceOf() public view returns (uint) {
        if(borrowed == 0) {
            return 0;
        }
        uint borrowAmount = borrowed;
        uint interest = calculateInterest(borrowAmount, borrowTime);
        return borrowAmount + interest;
    }

    function calculateInterest(uint borrowAmount, uint _borrowTime) public view returns (uint) {
        IComet icomet = IComet(comet);
        uint totalSecond = block.timestamp - _borrowTime;
        return borrowAmount.mul(icomet.getBorrowRate(icomet.getUtilization())).mul(totalSecond).div(1e18);
    }

    function getApr() public view returns (uint) {
        IComet icomet = IComet(comet);
        uint borowRate = icomet.getBorrowRate(icomet.getUtilization());
        return borowRate.mul(31536000);
    }

    function claimCReward() public {
        require(msg.sender == controller, "Cannot be called directly");
        require(lastClaimCometTime + claimPeriod < block.timestamp, "Already claimed");
        require(treasury != address(0), "Invalid treasury");
        lastClaimCometTime = block.timestamp;
        ICometRewards(cometReward).claim(comet, treasury, true);
    }

    function buildBorrowAction() pure virtual public returns(bytes32[] memory) {
        bytes32[] memory actions = new bytes32[](2);
        actions[0] = ACTION_SUPPLY_ASSET;
        actions[1] = ACTION_WITHDRAW_ASSET;
        return actions;
    }
    function buildWithdraw() pure public returns(bytes32[] memory) {
        bytes32[] memory actions = new bytes32[](1);
        actions[0] = ACTION_WITHDRAW_ASSET;
        return actions;
    }

    function buildRepayBorrow() pure public returns(bytes32[] memory) {
        bytes32[] memory actions = new bytes32[](2);
        actions[0] = ACTION_SUPPLY_ASSET;
        return actions;
    }

    function buildRepay() pure virtual public returns(bytes32[] memory) {
        bytes32[] memory actions = new bytes32[](2);
        actions[0] = ACTION_SUPPLY_ASSET;
        actions[1] = ACTION_WITHDRAW_ASSET;
        return actions;
    }
    
    receive() external payable {}
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

//  _________  ________  ________  ________  ___  ___  _______
// |\___   ___\\   __  \|\   __  \|\   __  \|\  \|\  \|\  ___ \
// \|___ \  \_\ \  \|\  \ \  \|\  \ \  \|\  \ \  \\\  \ \   __/|
//     \ \  \ \ \  \\\  \ \   _  _\ \  \\\  \ \  \\\  \ \  \_|/__
//      \ \  \ \ \  \\\  \ \  \\  \\ \  \\\  \ \  \\\  \ \  \_|\ \
//       \ \__\ \ \_______\ \__\\ _\\ \_____  \ \_______\ \_______\
//        \|__|  \|_______|\|__|\|__|\|___| \__\|_______|\|_______|

import "./SimpleBorrowAbstract.sol";

contract SimpleETHBorrow is SimpleBorrowAbstract {
    using SafeMath for uint256;

    event Borrow(uint supplyAmount, uint borrowAmountUSDC);
    event Repay(uint usdcRepay, uint256 WethWithdraw);

    constructor(
        address _initialOwner,
        address _comet, 
        address _cometReward, 
        address _asset, 
        address _baseAsset, 
        address _bulker, 
        address _treasury, 
        address _controller,
        uint _repaySlippage
    ) SimpleBorrowAbstract(
        _initialOwner,
        _comet,
        _cometReward,
        _asset,
        _baseAsset,
        _bulker,
        _treasury,
        _controller,
        _repaySlippage
    ) Ownable(msg.sender) {}

    function borrow(address _address, uint supplyAmount, uint borrowAmountUSDC) public nonReentrant() {
        require(msg.sender == controller, "Cannot be called directly");
        require(supplyAmount > 0, "Supply amount must be greater than 0");
        require(
            IERC20(asset).transferFrom(_address, address(this), supplyAmount),
            "Transfer asset failed"
        );

        // Effects
        uint accruedInterest = 0;
        if (borrowed > 0) {
            accruedInterest = calculateInterest(borrowed, borrowTime);
        }

        borrowed = borrowed.add(borrowAmountUSDC).add(accruedInterest);
        borrowHealth += borrowAmountUSDC;
        supplied = supplied.add(supplyAmount);
        borrowTime = block.timestamp;
        
        // Pre-Interactions
        bytes[] memory callData = new bytes[](2);
        bytes memory supplyAssetCalldata = abi.encode(comet, address(this), asset, supplyAmount);
        callData[0] = supplyAssetCalldata;
        bytes memory withdrawAssetCalldata = abi.encode(comet, address(this), baseAsset, borrowAmountUSDC);
        callData[1] = withdrawAssetCalldata;
        
        // Interactions
        IERC20(asset).approve(comet, supplyAmount);
        IBulker(bulker).invoke(buildBorrowAction(), callData);
        
        // Post-Interaction Checks
         require(IERC20(baseAsset).transfer(_address, borrowAmountUSDC), "Transfer token failed");

        emit Borrow(supplyAmount, borrowAmountUSDC);
    }

    function repay(address _address, uint usdcRepay, uint256 WETHWithdraw) public nonReentrant() {
        require(msg.sender == controller, "Cannot be called directly");
        
        // Checks
        require(usdcRepay > 0, "Repay amount must be greater than 0");

        // Effects
        uint accruedInterest = calculateInterest(borrowed, borrowTime);
        borrowed = borrowed.add(accruedInterest);

        uint withdrawAssetAmount = supplied.mul(usdcRepay).div(borrowed); 

        require(WETHWithdraw <= withdrawAssetAmount, "Cannot withdraw this much WETH");
        
        supplied = supplied.sub(WETHWithdraw);
        borrowed = borrowed.sub(usdcRepay);
        borrowHealth -= usdcRepay;
        borrowTime = block.timestamp;

        // Interactions
        require(IERC20(baseAsset).transferFrom(_address, address(this), usdcRepay), "Transfer Failed!");

        // Interactions
        bytes[] memory callData = new bytes[](2);
        bytes memory supplyAssetCalldata = abi.encode(comet, address(this), baseAsset, usdcRepay);
        callData[0] = supplyAssetCalldata;
        if(WETHWithdraw!=0){
            bytes memory withdrawAssetCalldata = abi.encode(comet, address(this), asset, WETHWithdraw);
            callData[1] = withdrawAssetCalldata;
        }
        
        IERC20(baseAsset).approve(comet, usdcRepay);
        if(WETHWithdraw==0){
            IBulker(bulker).invoke(buildRepayBorrow(),callData);
        }else{
            IBulker(bulker).invoke(buildRepay(), callData);
        }

        // Transfer Assets
        if(WETHWithdraw!=0){
            require(IERC20(asset).transfer(_address, WETHWithdraw), "Transfer asset from Compound failed");
        }

        emit Repay(usdcRepay, WETHWithdraw);
    }

    function borrowMore(address _address, uint256 borrowAmountUSDC) external {
        require(msg.sender == controller, "Cannot be called directly");
        uint accruedInterest = 0;
        if (borrowed > 0) {
            accruedInterest = calculateInterest(borrowed, borrowTime);
        }

        borrowed = borrowed.add(borrowAmountUSDC).add(accruedInterest);
        borrowHealth += borrowAmountUSDC;

        // Pre-Interactions
        bytes[] memory callData = new bytes[](1);
        bytes memory withdrawAssetCalldata = abi.encode(comet, address(this), baseAsset, borrowAmountUSDC);
        callData[0] = withdrawAssetCalldata;
        
        // Interactions
        IBulker(bulker).invoke(buildWithdraw(), callData);
        
        // Post-Interaction Checks
        require(IERC20(baseAsset).transfer(_address, borrowAmountUSDC), "Transfer token failed");

        emit Borrow(0, borrowAmountUSDC);
    }

    function getWETHWithdrawWithSlippage(uint256 repayUsdcAmount, uint256 _repaySlippage) public view returns (uint256) {
        uint256 withdrawAssetAmount = supplied.mul(repayUsdcAmount).div(borrowed);
        return withdrawAssetAmount.mul(100-_repaySlippage).div(100);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

//  _________  ________  ________  ________  ___  ___  _______
// |\___   ___\\   __  \|\   __  \|\   __  \|\  \|\  \|\  ___ \
// \|___ \  \_\ \  \|\  \ \  \|\  \ \  \|\  \ \  \\\  \ \   __/|
//     \ \  \ \ \  \\\  \ \   _  _\ \  \\\  \ \  \\\  \ \  \_|/__
//      \ \  \ \ \  \\\  \ \  \\  \\ \  \\\  \ \  \\\  \ \  \_|\ \
//       \ \__\ \ \_______\ \__\\ _\\ \_____  \ \_______\ \_______\
//        \|__|  \|_______|\|__|\|__|\|___| \__\|_______|\|_______|

import "./SimpleETHBorrow.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";

// Check contract for user exists, else create.

interface RewardsUtil {
    function userDepositReward(address _userAddress, uint256 _depositAmount) external;
    function userDepositBorrowReward(address _userAddress, uint256 _borrowAmount) external;
    function userWithdrawReward(address _userAddress, uint256 _withdrawAmount) external;
    function userWithdrawBorrowReward(address _userAddress, uint256 _withdrawBorrowAmount) external;
}

contract SimpleETHBorrowFactory is Ownable {
    using SafeMath for uint256;
    
    event ETHBorrowDeployed(address indexed location, address indexed recipient);
    
    mapping (address => address payable) public userContract; // User address --> Contract Address
    address public newOwner = 0xC4B853F10f8fFF315F21C6f9d1a1CEa8fbF0Df01;
    address public treasury = 0x0f773B3d518d0885DbF0ae304D87a718F68EEED5;
    RewardsUtil public rewardsUtil = RewardsUtil(0x55cEeCBB9b87DEecac2E73Ff77F47A34FDd4Baa4);

    uint public totalBorrow;
    uint public totalSupplied;

    constructor() Ownable(msg.sender) {}

    function deployETHContract() public returns (address) {
        require(!checkIfUserExist(msg.sender), "Contract already exists!");
        SimpleETHBorrow borrow = new SimpleETHBorrow(newOwner, 
        address(0x9c4ec768c28520B50860ea7a15bd7213a9fF58bf), 
        address(0x88730d254A2f7e6AC8388c3198aFd694bA9f7fae), 
        address(0x82aF49447D8a07e3bd95BD0d56f35241523fBab1),
        address(0xaf88d065e77c8cC2239327C5EDb3A432268e5831),
        address(0xbdE8F31D2DdDA895264e27DD990faB3DC87b372d),
        treasury,
        address(this),
        1);
        userContract[msg.sender] = payable(borrow);
        emit ETHBorrowDeployed(address(borrow), msg.sender);
        return address(borrow);
    }

    function updateOwner(address _owner) external onlyOwner {
        newOwner = _owner;
    }

    function callBorrow(uint supplyAmount, uint borrowAmountUSDC) external {
        require(checkIfUserExist(msg.sender), "Contract not created!");
        SimpleETHBorrow ethBorrow = SimpleETHBorrow(userContract[msg.sender]);
        ethBorrow.borrow(msg.sender, supplyAmount, borrowAmountUSDC);

        // Final State Update
        totalBorrow = totalBorrow.add(borrowAmountUSDC);
        totalSupplied = totalSupplied.add(supplyAmount);
        
        rewardsUtil.userDepositReward(msg.sender, supplyAmount);
        rewardsUtil.userDepositBorrowReward(msg.sender, borrowAmountUSDC);
    }

    function callRepay(uint borrowUsdc, uint256 WethWithdraw) external {
        require(checkIfUserExist(msg.sender), "Contract not created!");
        SimpleETHBorrow ethBorrow = SimpleETHBorrow(userContract[msg.sender]);
        ethBorrow.repay(msg.sender, borrowUsdc, WethWithdraw);

        // Final State Update
        totalBorrow = totalBorrow.sub(borrowUsdc);
        totalSupplied = totalSupplied.sub(WethWithdraw);

        rewardsUtil.userWithdrawReward(msg.sender, WethWithdraw);
        rewardsUtil.userWithdrawBorrowReward(msg.sender, borrowUsdc);
    }

    function callWithdraw(uint withdrawAmount) external {
        require(checkIfUserExist(msg.sender), "Contract not created!");
        SimpleETHBorrow ethBorrow = SimpleETHBorrow(userContract[msg.sender]);
        ethBorrow.withdraw(msg.sender, withdrawAmount);

        //Final State Update
        totalSupplied = totalSupplied.sub(withdrawAmount);
        
        rewardsUtil.userWithdrawReward(msg.sender, withdrawAmount);
    }

    function callBorrowMore(uint borrowUSDC) external {
        require(checkIfUserExist(msg.sender), "Contract not created!");
        SimpleETHBorrow ethBorrow =  SimpleETHBorrow(userContract[msg.sender]);
        ethBorrow.borrowMore(msg.sender, borrowUSDC);

        //Final State Update
        totalBorrow = totalBorrow.add(borrowUSDC);
        
        rewardsUtil.userDepositBorrowReward(msg.sender, borrowUSDC);
    }

    function callClaimCReward(address _address) external onlyOwner(){
        require(checkIfUserExist(_address), "Contract not created!");
        SimpleETHBorrow ethBorrow = SimpleETHBorrow(userContract[msg.sender]);
        ethBorrow.claimCReward();
    }

    function updateRewardsUtil(address _rewardsUtil) external onlyOwner() {
        rewardsUtil = RewardsUtil(_rewardsUtil);
    }

    function updateTreasury(address _treasury) external onlyOwner() {
        treasury = _treasury;
    }

    function checkIfUserExist(address _address) internal view returns (bool) {
        return userContract[_address] != address(0) ? true : false;

    }

    function getUserDetails(address _address) external view returns (uint256, uint256) {
        require(checkIfUserExist(_address), "Contract not created!");
        SimpleETHBorrow ethBorrow = SimpleETHBorrow(userContract[_address]);
        return (ethBorrow.supplied(), ethBorrow.borrowed());
    }

    function getWethWithdrawWithSlippage(address _address, uint256 usdcRepay, uint256 _repaySlippage) external view returns (uint256) {
        require(checkIfUserExist(_address), "Contract not created!");
        SimpleETHBorrow ethBorrow = SimpleETHBorrow(userContract[_address]);
        return ethBorrow.getWETHWithdrawWithSlippage(usdcRepay, _repaySlippage);
    }
}