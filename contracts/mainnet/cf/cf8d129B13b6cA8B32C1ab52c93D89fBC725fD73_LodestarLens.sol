// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v5.0.0) (access/Ownable.sol)

pragma solidity ^0.8.20;

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
// OpenZeppelin Contracts (last updated v5.0.0) (access/Ownable2Step.sol)

pragma solidity ^0.8.20;

import {Ownable} from "./Ownable.sol";

/**
 * @dev Contract module which provides access control mechanism, where
 * there is an account (an owner) that can be granted exclusive access to
 * specific functions.
 *
 * The initial owner is specified at deployment time in the constructor for `Ownable`. This
 * can later be changed with {transferOwnership} and {acceptOwnership}.
 *
 * This module is used through inheritance. It will make available all functions
 * from parent (Ownable).
 */
abstract contract Ownable2Step is Ownable {
    address private _pendingOwner;

    event OwnershipTransferStarted(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Returns the address of the pending owner.
     */
    function pendingOwner() public view virtual returns (address) {
        return _pendingOwner;
    }

    /**
     * @dev Starts the ownership transfer of the contract to a new account. Replaces the pending transfer if there is one.
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual override onlyOwner {
        _pendingOwner = newOwner;
        emit OwnershipTransferStarted(owner(), newOwner);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`) and deletes any pending owner.
     * Internal function without access restriction.
     */
    function _transferOwnership(address newOwner) internal virtual override {
        delete _pendingOwner;
        super._transferOwnership(newOwner);
    }

    /**
     * @dev The new owner accepts the ownership transfer.
     */
    function acceptOwnership() public virtual {
        address sender = _msgSender();
        if (pendingOwner() != sender) {
            revert OwnableUnauthorizedAccount(sender);
        }
        _transferOwnership(sender);
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v5.0.1) (utils/Context.sol)

pragma solidity ^0.8.20;

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

//SPDX-License-Identifier: BSD-3-Clause
pragma solidity 0.8.20;

import "lodestar-helper/contracts/Interfaces/ICERC20.sol";
import "lodestar-helper/contracts/Interfaces/LodestarInterfaces.sol";
import "@openzeppelin/contracts/access/Ownable2Step.sol";

contract LodestarLens is Ownable2Step{
    IPOPE public ORACLE;
    ComptrollerInterface public COMPTROLLER;
    address public ETHER_MARKET;


    struct MarketInfo {
        ICERC20 marketAddress;
        address underlyingAddress;
        uint256 underlyingPrice;
        uint256 priceInUSD;
        uint256 totalSuppliedUnderlying;
        uint256 totalSuppliedUSD;
        uint256 totalBorrowedUnderlying;
        uint256 totalBorrowedUSD;
        uint256 cash;
        uint256 reserves;
        uint256 borrowRatePerBlock;
        uint256 supplyRatePerBlock;
        uint256 collateralFactor;
        uint256 exchangeRate;
        address interestRateModel;
        string name;
        string symbol;
        string underlyingName;
        string underlyingSymbol;
        uint256 accrualBlockNumber;
    }

    struct MarketsInfo {
        MarketInfo[] markets;
        uint256 totalSuppliedUSD;
        uint256 totalBorrowedUSD;
    }

    struct UserMarketInfo {
        address marketAddress;
        uint256 totalSuppliedUnderlying;
        uint256 totalSuppliedETH;
        uint256 totalSuppliedUSD;
        uint256 totalBorrowedUnderlying;
        uint256 totalBorrowedETH;
        uint256 totalBorrowedUSD;
        uint256 totalCollateralETH;
    }

    struct UserInfo {
        address userAddress;
        UserMarketInfo[] userMarkets;
        uint256 health;
        uint256 liquidity;
        uint256 shortfall;
        uint256 pendingLODERewards;
    }

    struct StakingInfo {
        uint256 lodeStaked;
        uint256 lockTime;
        uint256 startTime;
        uint256 esLodeStaked;
        uint256 convertibleEsLode;
        uint256 pendingRewards;
        uint256 claimableEsLode;
    }

    struct VotingInfo {
        uint256 votingPower;
        address delegate;
        uint256 lastVotedWeek;
        uint256 lastVotedTimestamp;
    }

    constructor(IPOPE oracle_, ComptrollerInterface comptroller_, address ether_market_) Ownable(msg.sender) {
        ORACLE = oracle_;
        COMPTROLLER = comptroller_;
        ETHER_MARKET = ether_market_;
    }

    function convertPriceToUSD (uint256 priceInETH) internal view returns (uint256) {
        //logic to convert price returned from oracle in ETH with decimal conversion to USD scaled to 6 decimals
    }

    function convertCTokensToUSD (uint256 cTokens, ICERC20 market) internal view returns (uint256) {
        //logic to convert an amount of cTokens to an amount of USD given the balance of cTokens and the market
    }

    function convertUnderlyingToUSD (uint256 underlying, ICERC20 market) internal view returns (uint256) {
        //logic to convert an amount of underlying assets to an amount of USD given the balance of tokens and the market
    }

    function getCollateralFactor (ICERC20 market) public view returns (uint256) {
        ( , uint256 cFactor, ) = COMPTROLLER.markets(address(market));
        return cFactor;
    }

    function getMarketInfo(ICERC20 market) public view returns (MarketInfo memory marketInfo) {
        marketInfo.marketAddress = market;
        if(address(market) != ETHER_MARKET) {
            marketInfo.underlyingAddress = address(market.underlying());
        } else {
            marketInfo.underlyingAddress = address(0);
        }
        marketInfo.underlyingPrice = ORACLE.getUnderlyingPrice(address(market));
        marketInfo.priceInUSD = convertPriceToUSD(marketInfo.underlyingPrice);
        marketInfo.totalSuppliedUnderlying = market.totalSupply();
        marketInfo.totalSuppliedUSD = convertCTokensToUSD(market.totalSupply(), market);
        marketInfo.totalBorrowedUnderlying = market.totalBorrows();
        marketInfo.totalBorrowedUSD = convertUnderlyingToUSD(market.totalBorrows(), market);
        marketInfo.cash = market.getCash();
        marketInfo.reserves = market.totalReserves();
        marketInfo.borrowRatePerBlock = market.borrowRatePerBlock();
        marketInfo.supplyRatePerBlock = market.supplyRatePerBlock();
        marketInfo.collateralFactor = getCollateralFactor(market);
        marketInfo.exchangeRate = market.exchangeRateStored();
        marketInfo.interestRateModel = market.interestRateModel();
        marketInfo.accrualBlockNumber = market.accrualBlockNumber();
    }

    function getMarketsInfo(ICERC20[] memory markets) external view returns (MarketsInfo memory marketsInfo) {
        uint256 totalSuppliedUSD;
        uint256 totalBorrowedUSD;
        for(uint i = 0; i < markets.length; i++) {
            marketsInfo.markets[i] = (getMarketInfo(markets[i]));
            totalSuppliedUSD += marketsInfo.markets[i].totalSuppliedUSD;
            totalBorrowedUSD += marketsInfo.markets[i].totalBorrowedUSD;
        }
        marketsInfo.totalSuppliedUSD = totalSuppliedUSD;
        marketsInfo.totalBorrowedUSD = totalBorrowedUSD;
    }

    // markets(where: {id: "${address}"}) {
    //       borrowRatePerBlock done
    //       cash done
    //       collateralFactor done
    //       exchangeRate done
    //       interestRateModelAddress done
    //       name done
    //       reserves done
    //       supplyRatePerBlock done
    //       symbol done
    //       totalBorrows done
    //       totalSupply done
    //       underlyingAddress done
    //       underlyingName done
    //       underlyingPrice done
    //       underlyingSymbol done 
    //       accrualBlockNumber
    //       blockTimestamp
    //       borrowIndex
    //       reserveFactor
    //       underlyingPriceUSD
    //       underlyingDecimals
    //     },
    //     accountCTokens (first: 1000,  where: {symbol: "${token?.cToken?.symbol}"}) {
    //       cTokenBalance
    //       storedBorrowBalance
    //     },

    function updateComptroller(ComptrollerInterface newComptroller) external onlyOwner {

    }
}

//SPDX-License-Identifier: BSD-3-Clause
pragma solidity 0.8.20;

import "./IERC20.sol";

interface ICERC20 is IERC20 {
    // CToken
    /**
     * @notice Get the underlying balance of the `owner`
     * @dev This also accrues interest in a transaction
     * @param owner The address of the account to query
     * @return The amount of underlying owned by `owner`
     */
    function balanceOfUnderlying(address owner) external returns (uint256);

    /**
     * @notice Returns the current per-block borrow interest rate for this cToken
     * @return The borrow interest rate per block, scaled by 1e18
     */
    function borrowRatePerBlock() external view returns (uint256);

    /**
     * @notice Returns the current per-block supply interest rate for this cToken
     * @return The supply interest rate per block, scaled by 1e18
     */
    function supplyRatePerBlock() external view returns (uint256);

    /**
     * @notice Accrue interest then return the up-to-date exchange rate
     * @return Calculated exchange rate scaled by 1e18
     */
    function exchangeRateCurrent() external returns (uint256);

    // Cerc20
    function mint(uint256 mintAmount) external returns (uint256);

    function redeem(uint256 redeemTokens) external returns (uint256);

    function underlying() external view returns (address);

    function liquidateBorrow(
        address borrower,
        uint256 repayAmount,
        address cTokenCollateral
    ) external;

    function name() external view returns (string memory);

    function symbol() external view returns (string memory);

    function approve(address spender, uint256 amount) external returns (bool);

    function getAccountSnapshot(address account) external view returns (uint, uint, uint, uint);

    function totalBorrows() external view returns (uint);
    
    function totalSupply() external view returns (uint);

    function totalReserves() external view returns (uint);

    function getCash() external view returns (uint);

    function reserveFactorMantissa() external view returns (uint);

    function interestRateModel() external view returns (address);

    function exchangeRateStored() external view returns (uint);

    function accrualBlockNumber() external view returns (uint);
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

//SPDX-License-Identifier: BSD-3-Clause
pragma solidity 0.8.20;

interface StakingRewardsInterface {
    struct StakingInfo {
        uint256 lodeAmount;
        uint256 stLODEAmount;
        uint256 startTime;
        uint256 lockTime;
        uint256 relockStLODEAmount;
        uint256 nextStakeId;
        uint256 totalEsLODEStakedByUser;
        uint256 threeMonthRelockCount;
        uint256 sixMonthRelockCount;
    }

    function stakeLODE(uint256 amount, uint256 lockTime) external;

    function unstakeLODE(uint256 amount) external;

    function convertEsLODEToLODE() external returns (uint256);

    function relock(uint256 lockTime) external;

    function claimRewards() external;

    function getStLODEAmount(address _address) external view returns (uint256);

    function getStLodeLockTime(
        address _address
    ) external view returns (uint256);

    function getEsLODEStaked(address _address) external view returns (uint256);

    function stakers(address user) external view returns (StakingInfo memory);

    function pendingRewards(
        address _user
    ) external view returns (uint256 _pendingweth);
}

interface VotingPowerInterface {
    enum OperationType {
        SUPPLY,
        BORROW
    }

    function vote(
        string[] calldata tokens,
        OperationType[] calldata operations,
        uint256[] calldata shares
    ) external;

    function delegateVotes(address delegatee) external;

    function delegate(address delegatee) external;

    function delegates(address account) external view returns (address);

    function getRawVotingPower(address _user) external view returns (uint256);

    function delegateBySig(
        address delegatee,
        uint256 nonce,
        uint256 expiry,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external;

    function getPastVotes(
        address account,
        uint256 timepoint
    ) external view returns (uint256);
}

interface ComptrollerInterface {
    function claimComp(address holder) external;

    function enterMarkets(
        address[] calldata cTokens
    ) external returns (uint[] memory);

    function exitMarket(address cToken) external returns (uint);

    function enableLooping(bool state) external returns (bool);

    function isLoopingEnabled(address user) external view returns (bool);

    function getAccountLiquidity(
        address account
    ) external view returns (uint, uint, uint);

    function getHypotheticalAccountLiquidity(
        address account,
        address cTokenModify,
        uint redeemTokens,
        uint borrowAmount
    ) external view returns (uint, uint, uint);

    function checkMembership(
        address account,
        address cToken
    ) external view returns (bool);

    function oracle() external view returns (address);

    function markets(
        address cToken
    ) external view returns (bool, uint256, bool);
}

interface LensInterface {
    struct CompBalanceMetadataExt {
        uint balance;
        uint votes;
        address delegate;
        uint allocated;
    }

    function getCompBalanceMetadataExt(
        address comp,
        address comptroller,
        address account
    ) external returns (CompBalanceMetadataExt memory);
}

interface ILODE {
    function allowance(
        address account,
        address spender
    ) external view returns (uint);

    function approve(address spender, uint rawAmount) external returns (bool);

    function balanceOf(address account) external view returns (uint);

    function transfer(address dst, uint rawAmount) external returns (bool);

    function transferFrom(
        address src,
        address dst,
        uint rawAmount
    ) external returns (bool);

    function delegate(address delegatee) external;

    function delegateBySig(
        address delegatee,
        uint nonce,
        uint expiry,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external;

    function getCurrentVotes(address account) external view returns (uint96);

    function getPriorVotes(
        address account,
        uint blockNumber
    ) external view returns (uint96);
}

interface IPOPE {
    function getUnderlyingPrice(address cToken) external view returns (uint256);
}