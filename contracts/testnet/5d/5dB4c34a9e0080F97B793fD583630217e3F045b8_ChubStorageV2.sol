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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.6.0) (utils/math/SafeMath.sol)

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
    function sub(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
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
    function div(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
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
    function mod(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b > 0, errorMessage);
            return a % b;
        }
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.7;

import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import {SafeMath} from "@openzeppelin/contracts/utils/math/SafeMath.sol";
import {ICollateralHub} from "./interfaces/ICollateralHub.sol";
import {INUONController} from "./interfaces/INUONController.sol";

contract ChubStorageV2 is Ownable {
    using SafeMath for uint256;

    ICollateralHub public chub;
    INUONController public controller;

    constructor(ICollateralHub _chub, INUONController _controller) {
        chub = _chub;
        controller = _controller;
    }

    function depositWithoutMintEstimation(
        uint256 _amount,
        address _user
    ) public view returns (uint256, uint256, uint256) {
        require(_amount > chub.minimumDepositAmount(), "Please deposit more than the min required amount");
        uint256 collateralAmountAfterFees = _amount.sub(
            _amount.mul(controller.getMintingFee(address(chub))).div(100).div(1e18)
        );

        uint256 userAm = chub.viewUserCollateralAmount(_user);
        uint256 mintedAm = chub.viewUserMintedAmount(_user);
        uint256 ratio = controller.getGlobalCollateralRatio(address(chub));
        if (userAm > 0) {
            uint256 userTVL = (((userAm.add(_amount)) * chub.assetMultiplier()) * chub.getCollateralPrice()) / 1e18;
            uint256 totalNUON = mintedAm;
            uint256 mintedValue = (totalNUON * chub.getTargetPeg()) / 1e18;
            uint256 result = ((userTVL * 1e18) / mintedValue) * 100;
            uint256 rat = ((1e18 * 1e18) / result) * 100;
            require(rat < ratio, "This will liquidate you");
            return (result, collateralAmountAfterFees, userTVL);
        } else {
            return (0, 0, 0);
        }
    }

    function mintWithoutDepositEstimation(
        uint256 _amount,
        address _user
    ) public view returns (uint256, uint256, uint256, uint256) {
        uint256 userAm = chub.viewUserCollateralAmount(_user);
        uint256 mintedAm = chub.viewUserMintedAmount(_user);

        require(userAm > 0, "You do not have a position in the CHUB");
        if (userAm > 0) {
            uint256 userTVL = ((userAm * chub.assetMultiplier()) * chub.getCollateralPrice()) / 1e18;
            uint256 mintedValue = ((mintedAm.add(_amount)) * chub.getTargetPeg()) / 1e18;
            uint256 result = ((userTVL * 1e18) / mintedValue) * 100;
            (uint256 collateralRequired, ) = chub.mintLiquidityHelper(_amount);

            require(
                (((1e18 * 1e18) / result) * 100) < controller.getGlobalCollateralRatio(address(chub)),
                "This will liquidate you"
            );
            require(
                chub.getUserLiquidityCoverage(_user, _amount) > chub.liquidityCheck(),
                "Increase your liquidity coverage"
            );
            return (result, _amount, (mintedAm.add(_amount)), collateralRequired);
        } else {
            return (0, 0, 0, 0);
        }
    }

    function redeemWithoutNuonEstimation(
        uint256 _collateralAmount,
        address _user
    ) public view returns (uint256, uint256, uint256) {
        uint256 userAm = chub.viewUserCollateralAmount(_user);
        uint256 mintedAm = chub.viewUserMintedAmount(_user);
        uint256 ratio = controller.getGlobalCollateralRatio(address(chub));
        require(userAm > 0, "You do not have any balance in that CHUB");
        require(_collateralAmount < userAm, "Cannot withdraw all the collaterals");

        uint256 fees = _collateralAmount.mul(controller.getRedeemFee(address(chub))).div(100).div(1e18);
        uint256 toUser = _collateralAmount.sub(fees);

        if (userAm > 0) {
            uint256 camount = userAm.sub(_collateralAmount);
            uint256 userTVL = ((camount * chub.assetMultiplier()) * chub.getCollateralPrice()) / 1e18;
            uint256 totalNUON = mintedAm;
            uint256 mintedValue = (totalNUON * chub.getTargetPeg()) / 1e18;
            uint256 result = ((userTVL * 1e18) / mintedValue) * 100;
            uint256 rat = ((1e18 * 1e18) / result) * 100;
            require(rat < ratio, "This will liquidate you");
            return (result, toUser, camount);
        } else {
            return (0, 0, 0);
        }
    }

    function burnNUONEstimation(uint256 _NUONAmount, address _user) public view returns (uint256, uint256, uint256) {
        uint256 ratio = controller.getGlobalCollateralRatio(address(chub));

        uint256 userAm = chub.viewUserCollateralAmount(_user);
        uint256 mintedAm = chub.viewUserMintedAmount(_user);
        require(userAm > 0, "You do not have any balance in that CHUB");
        uint256 maxBurn = mintedAm.mul(chub.maxNuonBurnPercent()).div(100);
        require(_NUONAmount < maxBurn, "Cannot burn your whole balance of NUON");

        if (userAm > 0) {
            uint256 userTVL = ((userAm * chub.assetMultiplier()) * chub.getCollateralPrice()) / 1e18;
            uint256 totalNUON = mintedAm.sub(_NUONAmount);
            uint256 mintedValue = (totalNUON * chub.getTargetPeg()) / 1e18;
            uint256 result = ((userTVL * 1e18) / mintedValue) * 100;
            uint256 rat = ((1e18 * 1e18) / result) * 100;
            require(rat < ratio, "This will liquidate you");
            return (result, _NUONAmount, totalNUON);
        } else {
            return (0, 0, 0);
        }
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.7;

interface ICollateralHub {
    function collateralUsed() external view returns (address);

    function getTargetPeg() external view returns (uint256);

    function getCollateralPrice() external view returns (uint256);

    function assetMultiplier() external view returns (uint256);

    function _deleteUsersData(address _user) external;

    function _reAssignNewOwnerBalances(address _user, address _receiver, bool _hasPosition, uint256 _tokenId) external;

    function userposition(
        address _owner,
        uint256 _pos
    ) external view returns (uint256, uint256, bytes32, address, uint256, uint256, uint256, uint256);

    function minimumDepositAmount() external view returns (uint256);

    function mintLiquidityHelper(uint256 _NUONAmountD18) external view returns (uint256, uint256);

    function getPositionOwned(address _owner) external view returns (uint256);

    function getUserLiquidityCoverage(address _user, uint256 _extraAmount) external view returns (uint256);

    function liquidityCheck() external view returns (uint256);

    function maxNuonBurnPercent() external view returns (uint256);

    function viewUserCollateralAmount(address _user) external view returns (uint256);

    function viewUserMintedAmount(address _user) external view returns (uint256);
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.7;

interface INUONController {
    function getMintLimit(uint256 _nuonAmount) external view returns (uint256);

    function addPool(address pool_address) external;

    function getPools() external view returns (address[] memory);

    function addPools(address[] memory poolAddress) external;

    function removePool(address pool_address) external;

    function getNUONSupply() external view returns (uint256);

    function isPool(address pool) external view returns (bool);

    function isMintPaused() external view returns (bool);

    function isRedeemPaused() external view returns (bool);

    function isAllowedToMint(address _minter) external view returns (bool);

    function setFeesParameters(uint256 _mintingFee, uint256 _redeemFee) external;

    function setGlobalCollateralRatio(uint256 _globalCollateralRatio) external;

    function getMintingFee(address _CHUB) external view returns (uint256);

    function getRedeemFee(address _CHUB) external view returns (uint256);

    function getGlobalCollateralRatio(address _CHUB) external view returns (uint256);

    function getGlobalCollateralValue() external view returns (uint256);

    function toggleMinting() external;

    function toggleRedeeming() external;

    function getTargetCollateralValue() external view returns (uint256);

    function getMaxCratio(address _CHUB) external view returns (uint256);
}