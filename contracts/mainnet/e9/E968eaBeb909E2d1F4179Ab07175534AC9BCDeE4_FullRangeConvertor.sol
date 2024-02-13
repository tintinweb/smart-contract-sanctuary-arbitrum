// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.8.0) (security/ReentrancyGuard.sol)

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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC721/IERC721Receiver.sol)

pragma solidity ^0.8.0;

/**
 * @title ERC721 token receiver interface
 * @dev Interface for any contract that wants to support safeTransfers
 * from ERC721 asset contracts.
 */
interface IERC721Receiver {
    /**
     * @dev Whenever an {IERC721} `tokenId` token is transferred to this contract via {IERC721-safeTransferFrom}
     * by `operator` from `from`, this function is called.
     *
     * It must return its Solidity selector to confirm the token transfer.
     * If any other value is returned or the interface is not implemented by the recipient, the transfer will be reverted.
     *
     * The selector can be obtained in Solidity with `IERC721Receiver.onERC721Received.selector`.
     */
    function onERC721Received(
        address operator,
        address from,
        uint256 tokenId,
        bytes calldata data
    ) external returns (bytes4);
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity >=0.5.0;

/// @title The interface for the Uniswap V3 Factory
/// @notice The Uniswap V3 Factory facilitates creation of Uniswap V3 pools and control over the protocol fees
interface IUniswapV3Factory {
    /// @notice Emitted when the owner of the factory is changed
    /// @param oldOwner The owner before the owner was changed
    /// @param newOwner The owner after the owner was changed
    event OwnerChanged(address indexed oldOwner, address indexed newOwner);

    /// @notice Emitted when a pool is created
    /// @param token0 The first token of the pool by address sort order
    /// @param token1 The second token of the pool by address sort order
    /// @param fee The fee collected upon every swap in the pool, denominated in hundredths of a bip
    /// @param tickSpacing The minimum number of ticks between initialized ticks
    /// @param pool The address of the created pool
    event PoolCreated(
        address indexed token0,
        address indexed token1,
        uint24 indexed fee,
        int24 tickSpacing,
        address pool
    );

    /// @notice Emitted when a new fee amount is enabled for pool creation via the factory
    /// @param fee The enabled fee, denominated in hundredths of a bip
    /// @param tickSpacing The minimum number of ticks between initialized ticks for pools created with the given fee
    event FeeAmountEnabled(uint24 indexed fee, int24 indexed tickSpacing);

    /// @notice Returns the current owner of the factory
    /// @dev Can be changed by the current owner via setOwner
    /// @return The address of the factory owner
    function owner() external view returns (address);

    /// @notice Returns the tick spacing for a given fee amount, if enabled, or 0 if not enabled
    /// @dev A fee amount can never be removed, so this value should be hard coded or cached in the calling context
    /// @param fee The enabled fee, denominated in hundredths of a bip. Returns 0 in case of unenabled fee
    /// @return The tick spacing
    function feeAmountTickSpacing(uint24 fee) external view returns (int24);

    /// @notice Returns the pool address for a given pair of tokens and a fee, or address 0 if it does not exist
    /// @dev tokenA and tokenB may be passed in either token0/token1 or token1/token0 order
    /// @param tokenA The contract address of either token0 or token1
    /// @param tokenB The contract address of the other token
    /// @param fee The fee collected upon every swap in the pool, denominated in hundredths of a bip
    /// @return pool The pool address
    function getPool(
        address tokenA,
        address tokenB,
        uint24 fee
    ) external view returns (address pool);

    /// @notice Creates a pool for the given two tokens and fee
    /// @param tokenA One of the two tokens in the desired pool
    /// @param tokenB The other of the two tokens in the desired pool
    /// @param fee The desired fee for the pool
    /// @dev tokenA and tokenB may be passed in either order: token0/token1 or token1/token0. tickSpacing is retrieved
    /// from the fee. The call will revert if the pool already exists, the fee is invalid, or the token arguments
    /// are invalid.
    /// @return pool The address of the newly created pool
    function createPool(
        address tokenA,
        address tokenB,
        uint24 fee
    ) external returns (address pool);

    /// @notice Updates the owner of the factory
    /// @dev Must be called by the current owner
    /// @param _owner The new owner of the factory
    function setOwner(address _owner) external;

    /// @notice Enables a fee amount with the given tickSpacing
    /// @dev Fee amounts may never be removed once enabled
    /// @param fee The fee amount to enable, denominated in hundredths of a bip (i.e. 1e-6)
    /// @param tickSpacing The spacing between ticks to be enforced for all pools created with the given fee amount
    function enableFeeAmount(uint24 fee, int24 tickSpacing) external;
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity >=0.6.0;

import '@openzeppelin/contracts/token/ERC20/IERC20.sol';

library TransferHelper {
    /// @notice Transfers tokens from the targeted address to the given destination
    /// @notice Errors with 'STF' if transfer fails
    /// @param token The contract address of the token to be transferred
    /// @param from The originating address from which the tokens will be transferred
    /// @param to The destination address of the transfer
    /// @param value The amount to be transferred
    function safeTransferFrom(
        address token,
        address from,
        address to,
        uint256 value
    ) internal {
        (bool success, bytes memory data) =
            token.call(abi.encodeWithSelector(IERC20.transferFrom.selector, from, to, value));
        require(success && (data.length == 0 || abi.decode(data, (bool))), 'STF');
    }

    /// @notice Transfers tokens from msg.sender to a recipient
    /// @dev Errors with ST if transfer fails
    /// @param token The contract address of the token which will be transferred
    /// @param to The recipient of the transfer
    /// @param value The value of the transfer
    function safeTransfer(
        address token,
        address to,
        uint256 value
    ) internal {
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(IERC20.transfer.selector, to, value));
        require(success && (data.length == 0 || abi.decode(data, (bool))), 'ST');
    }

    /// @notice Approves the stipulated contract to spend the given allowance in the given token
    /// @dev Errors with 'SA' if transfer fails
    /// @param token The contract address of the token to be approved
    /// @param to The target of the approval
    /// @param value The amount of the given token the target will be allowed to spend
    function safeApprove(
        address token,
        address to,
        uint256 value
    ) internal {
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(IERC20.approve.selector, to, value));
        require(success && (data.length == 0 || abi.decode(data, (bool))), 'SA');
    }

    /// @notice Transfers ETH to the recipient address
    /// @dev Fails with `STE`
    /// @param to The destination of the transfer
    /// @param value The value to be transferred
    function safeTransferETH(address to, uint256 value) internal {
        (bool success, ) = to.call{value: value}(new bytes(0));
        require(success, 'STE');
    }
}

// SPDX-License-Identifier: UNLICENSED
// ALL RIGHTS RESERVED
// UNCX by SDDTech reserves all rights on this code. You may not copy these contracts.

pragma solidity 0.8.19;

import "./uniswap-updated/INonfungiblePositionManager.sol";

/**
 * @dev Interface of the UNCX UniswapV3 Liquidity Locker
 */
interface IUNCX_LiquidityLocker_UniV3 {
    struct FeeStruct {
        string name; // name by which the fee is accessed
        uint256 lpFee; // 100 = 1%, 10,000 = 100%
        uint256 collectFee; // 100 = 1%, 10,000 = 100%
        uint256 flatFee; // in amount tokens
        address flatFeeToken; // address(0) = ETH otherwise ERC20 address expected
    }

    struct Lock {
        uint256 lock_id; // unique nonce per lock
        INonfungiblePositionManager nftPositionManager; // the nft position manager of the uniswap fork
        address pool; // the pool address
        uint256 nft_id; // the nft token id of the nft belonging to the nftPositionManager (there could be two nfts with id = 1, belonging to different amm forks and position managers)
        address owner; // the owner who can collect and withdraw
        address pendingOwner; //  two step process ownership transfer, the pending owner must accept ownership to own the lock
        address additionalCollector; // an additional address allowed to call collect (ideal for contracts to auto collect without having to use owner)
        address collectAddress; // The address to which automatic collections are sent
        uint256 unlockDate; // unlock date of the lock in seconds
        uint16 countryCode; // the country code of the locker / business
        uint256 ucf; // collect fee
    }

    struct LockParams {
        INonfungiblePositionManager nftPositionManager; // the NFT Position manager of the Uniswap V3 fork
        uint256 nft_id; // the nft token_id
        address dustRecipient; // receiver of dust tokens which do not fit into liquidity and initial collection fees
        address owner; // owner of the lock
        address additionalCollector; // an additional address allowed to call collect (ideal for contracts to auto collect without having to use owner)
        address collectAddress; // The address to which automatic collections are sent
        uint256 unlockDate; // unlock date of the lock in seconds
        uint16 countryCode; // the country code of the locker / business
        string feeName; // The fee name key you wish to accept, use "DEFAULT" if in doubt
        bytes[] r; // use an empty array => []
    }

    // User functions
    function lock (LockParams calldata params) external payable returns (uint256 lockId);
    function collect (uint256 lockId, address recipient, uint128 amount0Max, uint128 amount1Max) external returns (uint256 amount0, uint256 amount1, uint256 fee0, uint256 fee1);
    function withdraw (uint256 lockId, address receiver) external;
    function migrate (uint256 lockId) external;
    function relock(uint256 lockId, uint256 unlockDate) external;
    function setAdditionalCollector (uint256 lockId, address additionalCollector) external;
    function setCollectAddress (uint256 lockId, address collectAddress) external;
    function transferLockOwnership (uint256 lockId, address newOwner) external;
    function acceptLockOwnership (uint256 lockId, address collectAddress) external;
    function decreaseLiquidity(uint256 lockId, INonfungiblePositionManager.DecreaseLiquidityParams calldata params) external payable returns (uint256 amount0, uint256 amount1);
    function increaseLiquidity(uint256 lockId, INonfungiblePositionManager.IncreaseLiquidityParams calldata params) external payable returns (uint128 liquidity, uint256 amount0, uint256 amount1);

    // Admin functions
    function allowNftPositionManager (address nftPositionManager) external;
    function setMigrator(address migrator) external;
    function setUCF(uint256 lockId, uint256 ucf) external;
    function setMigrateInContract (address migrateInContract) external;

    // Getters
    function getLocksLength() external view returns (uint256);
    function getLock(uint256 lockId) external view returns (Lock memory lock);

    function getNumUserLocks(address user) external view returns (uint256 numLocks);
    function getUserLockAtIndex(address user, uint256 index) external view returns (Lock memory lock);

    function getFee (string memory name) external view returns (FeeStruct memory);
    function getAmountsForLiquidity (int24 currentTick, int24 tickLower, int24 tickHigher, uint128 liquidity) external pure returns (uint256 amount0, uint256 amount1);

    function nftPositionManagerIsAllowed (address nftPositionManager) external view returns (bool);

    // Events
    event onLock(
        uint256 lock_id,
        address nftPositionManager,
        uint256 nft_id,
        address owner,
        address additionalCollector,
        address collectAddress,
        uint256 unlockDate,
        uint16 countryCode,
        uint256 collectFee,
        address poolAddress,
        INonfungiblePositionManager.Position position
    );

    event onWithdraw(uint256 lock_id, address owner, address receiver);

    event onLockOwnershipTransferStarted(uint256 lockId, address currentOwner, address pendingOwner);

    event onTransferLockOwnership(uint256 lockId, address oldOwner, address newOwner, address newCollectAddress);

    event onMigrate(uint256 lockId);

    event onSetAdditionalCollector(uint256 lockId, address additionalCollector);

    event onSetCollectAddress(uint256 lockId, address collectAddress);

    event onSetMigrator(address migrator);

    event onRelock(uint256 lockId, uint256 unlockDate);

    event onIncreaseLiquidity(uint256 lockId);

    event onDecreaseLiquidity(uint256 lockId);

    event onRemoveFee(bytes32 nameHash);

    event onAddFee(bytes32 nameHash, string name, uint256 lpFee, uint256 collectFee, uint256 flatFee, address flatFeeToken);

    event onEditFee(bytes32 nameHash, string name, uint256 lpFee, uint256 collectFee, uint256 flatFee, address flatFeeToken);

    event onSetUCF(uint256 lockId, uint256 ucf);

    event OnAllowNftPositionManager(address nftPositionManager);
    
}

// SPDX-License-Identifier: UNLICENSED
// Code Author: UNCX by SDDTech

pragma solidity 0.8.19;

import {IERC721Receiver} from "@openzeppelin/contracts/token/ERC721/IERC721Receiver.sol";
import {ReentrancyGuard} from "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {INonfungiblePositionManager} from "../uniswap-updated/INonfungiblePositionManager.sol";
import {TransferHelper} from "@uniswap/v3-periphery/contracts/libraries/TransferHelper.sol";
import {IUniswapV3Factory} from "@uniswap/v3-core/contracts/interfaces/IUniswapV3Factory.sol";
import {IUNCX_LiquidityLocker_UniV3} from "../IUNCX_LiquidityLocker_UniV3.sol";

contract FullRangeConvertor is IERC721Receiver, ReentrancyGuard {

    IUNCX_LiquidityLocker_UniV3 public UNIV3_LOCKER;

    constructor(IUNCX_LiquidityLocker_UniV3 _univ3_locker) {
      UNIV3_LOCKER = _univ3_locker;
    }

    function convertToFullRangeAndLock (IUNCX_LiquidityLocker_UniV3.LockParams memory _lockParams, uint256 _amount0Min, uint256 _amount1Min) external nonReentrant returns (uint256 newLockId) {
      _lockParams.nftPositionManager.safeTransferFrom(msg.sender, address(this), _lockParams.nft_id);

      INonfungiblePositionManager.Position memory position;
      (
        , // nonce
        , // operator
        , // token0
        , // token1
        position.fee, // fee
        position.tickLower, // tickLower
        position.tickUpper, // tickUpper
        , // liquidity
        , // feeGrowthInside0LastX128
        , // feeGrowthInside1LastX128
        , // tokensOwed0
          // tokensOwed1
      ) = _lockParams.nftPositionManager.positions(_lockParams.nft_id);

      IUniswapV3Factory factory = IUniswapV3Factory(_lockParams.nftPositionManager.factory());
      int24 maxTick = tickSpacingToMaxTick(factory.feeAmountTickSpacing(position.fee));
      
      uint256 nftToLock;
      if (position.tickLower == -maxTick && position.tickUpper == maxTick) {
          nftToLock = _lockParams.nft_id;
      } else {
        // convert the position to full range by minting a new full range NFT
        nftToLock = _convertPositionToFullRange(_lockParams.nftPositionManager, _lockParams.nft_id, maxTick, _lockParams.dustRecipient, _amount0Min, _amount1Min);
      }
      
      _lockParams.nftPositionManager.approve(address(UNIV3_LOCKER), nftToLock);
      _lockParams.nft_id = nftToLock;
      newLockId = UNIV3_LOCKER.lock(_lockParams);
    }

    function _convertPositionToFullRange (INonfungiblePositionManager _nftPositionManager, uint256 _tokenId, int24 _maxTick, address _dustRecipient, uint256 _amount0Min, uint256 _amount1Min) private returns (uint256) {
        INonfungiblePositionManager.MintParams memory mintParams;
        uint128 positionLiquidity;
        (
          , // nonce
          , // operator
          mintParams.token0, // token0
          mintParams.token1, // token1
          mintParams.fee, // fee
          , // tickLower
          , // tickUpper
          positionLiquidity,
          , // feeGrowthInside0LastX128
          , // feeGrowthInside1LastX128
          , // tokensOwed0
           // tokensOwed1
        ) = _nftPositionManager.positions(_tokenId);

        _nftPositionManager.decreaseLiquidity(INonfungiblePositionManager.DecreaseLiquidityParams(_tokenId, positionLiquidity, 0, 0, block.timestamp));
        _nftPositionManager.collect(INonfungiblePositionManager.CollectParams(_tokenId, address(this), type(uint128).max, type(uint128).max));

        mintParams.tickLower = -_maxTick;
        mintParams.tickUpper = _maxTick;
        mintParams.amount0Desired = IERC20(mintParams.token0).balanceOf(address(this));
        mintParams.amount1Desired = IERC20(mintParams.token1).balanceOf(address(this));
        mintParams.amount0Min = _amount0Min;
        mintParams.amount1Min = _amount1Min;
        mintParams.recipient = address(this);
        mintParams.deadline = block.timestamp;

        TransferHelper.safeApprove(mintParams.token0, address(_nftPositionManager), mintParams.amount0Desired);
        TransferHelper.safeApprove(mintParams.token1, address(_nftPositionManager), mintParams.amount1Desired);

        (uint256 newNftId,,,) = _nftPositionManager.mint(mintParams);

        _nftPositionManager.burn(_tokenId);

        // Refund the tokens which dont fit into full range liquidity
        uint256 balance0 = IERC20(mintParams.token0).balanceOf(address(this));
        uint256 balance1 = IERC20(mintParams.token1).balanceOf(address(this));
        if (balance0 > 0) {
            TransferHelper.safeTransfer(mintParams.token0, _dustRecipient, balance0);
        }
        if (balance1 > 0) {
            TransferHelper.safeTransfer(mintParams.token1, _dustRecipient, balance1);
        }
        return newNftId;
    }

    /**
    * @dev gets the maximum tick for a tickSpacing
    * source: https://github.com/Uniswap/v3-core/blob/main/contracts/libraries/Tick.sol
    */
    function tickSpacingToMaxTick(int24 tickSpacing) public pure returns (int24 maxTick) {
        maxTick = (887272 / tickSpacing) * tickSpacing;
    }

    function onERC721Received(
        address operator,
        address from,
        uint256 tokenId,
        bytes calldata data
    ) external override returns (bytes4) {
        return IERC721Receiver.onERC721Received.selector;
    }
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

// Importing from @uniswap doesnt work with @openzepplins latest release so this is refactored
// Source: https://github.com/Uniswap/v3-periphery/blob/main/contracts/interfaces/INonfungiblePositionManager.sol

interface INonfungiblePositionManager {

    function approve(address to, uint256 tokenId) external;
    
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;

    struct MintParams {
        address token0;
        address token1;
        uint24 fee;
        int24 tickLower;
        int24 tickUpper;
        uint256 amount0Desired;
        uint256 amount1Desired;
        uint256 amount0Min;
        uint256 amount1Min;
        address recipient;
        uint256 deadline;
    }

    function mint(
        MintParams calldata params
    )
        external
        payable
        returns (
            uint256 tokenId,
            uint128 liquidity,
            uint256 amount0,
            uint256 amount1
        );

    struct Position {
        uint96 nonce;
        address operator;
        address token0;
        address token1;
        uint24 fee;
        int24 tickLower;
        int24 tickUpper;
        uint128 liquidity;
        uint256 feeGrowthInside0LastX128;
        uint256 feeGrowthInside1LastX128;
        uint128 tokensOwed0;
        uint128 tokensOwed1;
    }

    function positions(
        uint256 tokenId
    )
        external
        view
        returns (
            uint96 nonce,
            address operator,
            address token0,
            address token1,
            uint24 fee,
            int24 tickLower,
            int24 tickUpper,
            uint128 liquidity,
            uint256 feeGrowthInside0LastX128,
            uint256 feeGrowthInside1LastX128,
            uint128 tokensOwed0,
            uint128 tokensOwed1
        );

    struct IncreaseLiquidityParams {
        uint256 tokenId;
        uint256 amount0Desired;
        uint256 amount1Desired;
        uint256 amount0Min;
        uint256 amount1Min;
        uint256 deadline;
    }

    /// @notice Increases the amount of liquidity in a position, with tokens paid by the `msg.sender`
    /// @param params tokenId The ID of the token for which liquidity is being increased,
    /// amount0Desired The desired amount of token0 to be spent,
    /// amount1Desired The desired amount of token1 to be spent,
    /// amount0Min The minimum amount of token0 to spend, which serves as a slippage check,
    /// amount1Min The minimum amount of token1 to spend, which serves as a slippage check,
    /// deadline The time by which the transaction must be included to effect the change
    /// @return liquidity The new liquidity amount as a result of the increase
    /// @return amount0 The amount of token0 to acheive resulting liquidity
    /// @return amount1 The amount of token1 to acheive resulting liquidity
    function increaseLiquidity(IncreaseLiquidityParams calldata params)
        external
        payable
        returns (
            uint128 liquidity,
            uint256 amount0,
            uint256 amount1
        );

    struct DecreaseLiquidityParams {
        uint256 tokenId;
        uint128 liquidity;
        uint256 amount0Min;
        uint256 amount1Min;
        uint256 deadline;
    }

    /// @notice Decreases the amount of liquidity in a position and accounts it to the position
    /// @param params tokenId The ID of the token for which liquidity is being decreased,
    /// amount The amount by which liquidity will be decreased,
    /// amount0Min The minimum amount of token0 that should be accounted for the burned liquidity,
    /// amount1Min The minimum amount of token1 that should be accounted for the burned liquidity,
    /// deadline The time by which the transaction must be included to effect the change
    /// @return amount0 The amount of token0 accounted to the position's tokens owed
    /// @return amount1 The amount of token1 accounted to the position's tokens owed
    function decreaseLiquidity(DecreaseLiquidityParams calldata params)
        external
        payable
        returns (uint256 amount0, uint256 amount1);

    struct CollectParams {
        uint256 tokenId;
        address recipient;
        uint128 amount0Max;
        uint128 amount1Max;
    }

    function collect(
        CollectParams calldata params
    ) external payable returns (uint256 amount0, uint256 amount1);

    function factory() external view returns (address);

    function burn(uint256 tokenId) external payable;
}