// SPDX-License-Identifier: MIT

pragma solidity ^0.8.18;

import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {IERC20Metadata} from "@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol";
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

contract GmAggregator {
    address public GMXV2_READER;
    address public GMXV2_DATASTORE;
    IReader public reader;

    constructor() {
        GMXV2_READER = 0xf60becbba223EEA9495Da3f606753867eC10d139;
        GMXV2_DATASTORE = 0xFD70de6b91282D8017aA4E741e9Ae325CAb992d8;
        reader = IReader(GMXV2_READER);
    }

    function changeGmxV2Reader(address newAddress) public {
        GMXV2_READER = newAddress;
        reader = IReader(GMXV2_READER);
    }

    function changeGmxV2Datastore(address newAddress) public {
        GMXV2_DATASTORE = newAddress;
    }

    function _getMarkets() internal virtual view returns(GmxV2Market[] memory markets){
        return reader.getMarkets(GMXV2_DATASTORE, 0, 20);
    }

    function _getMarketTokenPrice(GmxV2Market memory market) internal virtual view returns(int256 price, GmxV2MarketPoolValueInfo memory poolValueInfo) {
        (price, poolValueInfo) = reader.getMarketTokenPrice(GMXV2_DATASTORE, market, GmxV2Price(0, 0), GmxV2Price(0,1), GmxV2Price(0,1), keccak256(abi.encode("MAX_PNL_FACTOR_FOR_WITHDRAWALS")), true);
        return (price, poolValueInfo);
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

            markets[i] = Market(user, token.name(), token.symbol(), token.decimals(), token.balanceOf(user), token.totalSupply(), poolValue, poolValueInfo.netPnl, poolValueInfo.totalBorrowingFees, Balance(gms[i].longToken, longToken.name(), longToken.symbol(), longToken.decimals(), longBal, poolValueInfo.longTokenAmount, longToken.totalSupply()), Balance(gms[i].shortToken, shortToken.name(), shortToken.symbol(), shortToken.decimals(), shortBal, poolValueInfo.shortTokenAmount, shortToken.totalSupply()));
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