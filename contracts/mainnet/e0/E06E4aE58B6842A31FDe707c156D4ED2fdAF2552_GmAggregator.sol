// SPDX-License-Identifier: MIT

pragma solidity ^0.8.18;

import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {IERC20Metadata} from "@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import {IReader} from "../interfaces/IReader.sol";
import {GmxV2Market} from "../types/GmxV2Market.sol";
import {GmxV2Price} from "../types/GmxV2Price.sol";
import {GmxV2MarketPoolValueInfo} from "../types/GmxV2MarketPoolValueInfo.sol";

struct Market {
    address addr;
    string name;
    string symbol;
    uint8 decimals;
    uint256 balance;
    uint256 totalSupply;
    int256 poolValue;
    int256 netPnl;
    uint256 totalBorrowingFees;
    Balance longBalance;
    Balance shortBalance;
}

struct Balance {
    address addr;
    string name;
    string symbol;
    uint8 decimals;
    uint256 balance;
    uint256 poolBalance;
    uint256 totalSupply;
} 

contract GmAggregator is Ownable {
    address public GMXV2_READER;
    address public GMXV2_DATASTORE;
    IReader private reader;

    constructor() {
        GMXV2_READER = 0xf60becbba223EEA9495Da3f606753867eC10d139;
        GMXV2_DATASTORE = 0xFD70de6b91282D8017aA4E741e9Ae325CAb992d8;
        reader = IReader(GMXV2_READER);
    }

    function changeGmxV2Reader(address newAddress) public onlyOwner {
        GMXV2_READER = newAddress;
        reader = IReader(GMXV2_READER);
    }

    function changeGmxV2Datastore(address newAddress) public onlyOwner {
        GMXV2_DATASTORE = newAddress;
    }

    function _getMarkets() internal virtual view returns(GmxV2Market[] memory markets){
        return reader.getMarkets(GMXV2_DATASTORE, 0, 20);
    }

    function _getMarketTokenPrice(GmxV2Market memory market) internal virtual view returns(int256 poolValue, GmxV2MarketPoolValueInfo memory poolValueInfo) {
        try reader.getMarketTokenPrice(GMXV2_DATASTORE, market, GmxV2Price(1, 1), GmxV2Price(1,1), GmxV2Price(1,1), keccak256(abi.encode("MAX_PNL_FACTOR_FOR_WITHDRAWALS")), true) returns (int256 pv, GmxV2MarketPoolValueInfo memory pvi) {
            return (pv, pvi);
        } catch {
            return (poolValue, poolValueInfo);
        }
    }

    function _calculateMarket(address gmAddress, address userAddress, GmxV2MarketPoolValueInfo memory poolVal) internal virtual view returns(uint256 longBal, uint256 shortBal) {
        IERC20 token = IERC20(gmAddress);
        IERC20Metadata gmToken = IERC20Metadata(gmAddress);

        longBal = (token.balanceOf(userAddress) * 1e18) / gmToken.totalSupply() * uint256(poolVal.longTokenAmount);
        shortBal = (token.balanceOf(userAddress) * 1e18) / gmToken.totalSupply() * uint256(poolVal.shortTokenAmount);

        return (longBal, shortBal);
    }

    function getBalances(address user) public virtual view returns(Market[] memory markets) {
        GmxV2Market[] memory gms = _getMarkets();
        markets = new Market[](gms.length);
        for (uint256 i=0;i<gms.length;i++) {
            IERC20Metadata token = IERC20Metadata(gms[i].marketToken);
            IERC20Metadata longToken = IERC20Metadata(gms[i].longToken);
            IERC20Metadata shortToken = IERC20Metadata(gms[i].shortToken);

            (int256 poolValue, GmxV2MarketPoolValueInfo memory poolValueInfo) = _getMarketTokenPrice(gms[i]);
            (uint256 longBal, uint256 shortBal) = _calculateMarket(gms[i].marketToken, user, poolValueInfo);
            
            markets[i] = Market(gms[i].marketToken, string.concat(token.name()," ",longToken.name(),"/",shortToken.name()), token.symbol(), token.decimals(), token.balanceOf(user), token.totalSupply(), poolValue, poolValueInfo.netPnl, poolValueInfo.totalBorrowingFees, Balance(gms[i].longToken, longToken.name(), longToken.symbol(), longToken.decimals(), longBal, poolValueInfo.longTokenAmount, longToken.totalSupply()), Balance(gms[i].shortToken, shortToken.name(), shortToken.symbol(), shortToken.decimals(), shortBal, poolValueInfo.shortTokenAmount, shortToken.totalSupply()));
        }
        return markets;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.18;

struct GmxV2Price {
    uint256 min;
    uint256 max;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.18;

struct GmxV2MarketPoolValueInfo {
    int256 poolValue;
    int256 longPnl;
    int256 shortPnl;
    int256 netPnl;

    uint256 longTokenAmount;
    uint256 shortTokenAmount;
    uint256 longTokenUsd;
    uint256 shortTokenUsd;

    uint256 totalBorrowingFees;
    uint256 borrowingFeePoolFactor;

    uint256 impactPoolAmount;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.18;

struct GmxV2Market {
    address marketToken;
    address indexToken;
    address longToken;
    address shortToken;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import {GmxV2Market} from "../types/GmxV2Market.sol";
import {GmxV2Price} from "../types/GmxV2Price.sol";
import {GmxV2MarketPoolValueInfo} from "../types/GmxV2MarketPoolValueInfo.sol";

interface IReader {
  function getMarketTokenPrice ( address dataStore, GmxV2Market memory market, GmxV2Price memory indexTokenPrice, GmxV2Price memory longTokenPrice, GmxV2Price memory shortTokenPrice, bytes32 pnlFactorType, bool maximize ) external view returns ( int256, GmxV2MarketPoolValueInfo memory );
  function getMarkets ( address dataStore, uint256 start, uint256 end ) external view returns ( GmxV2Market[] memory );
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
// OpenZeppelin Contracts v4.4.1 (token/ERC20/extensions/IERC20Metadata.sol)

pragma solidity ^0.8.0;

import "../IERC20.sol";

/**
 * @dev Interface for the optional metadata functions from the ERC20 standard.
 *
 * _Available since v4.1._
 */
interface IERC20Metadata is IERC20 {
    /**
     * @dev Returns the name of the token.
     */
    function name() external view returns (string memory);

    /**
     * @dev Returns the symbol of the token.
     */
    function symbol() external view returns (string memory);

    /**
     * @dev Returns the decimals places of the token.
     */
    function decimals() external view returns (uint8);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.9.0) (token/ERC20/IERC20.sol)

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
    function transferFrom(address from, address to, uint256 amount) external returns (bool);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.9.0) (access/Ownable.sol)

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
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
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