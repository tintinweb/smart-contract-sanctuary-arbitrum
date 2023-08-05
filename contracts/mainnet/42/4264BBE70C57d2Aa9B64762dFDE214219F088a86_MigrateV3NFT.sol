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

// SPDX-License-Identifier: UNLICENSED

pragma solidity 0.8.19;

import "./uniswap-updated/INonfungiblePositionManager.sol";

/**
 * @dev Interface of the MigrateV3NFT contract
 */
interface IMigrateV3NFT {
  function migrate (uint256 lockId, INonfungiblePositionManager nftPositionManager, uint256 tokenId) external returns (bool);
}

// SPDX-License-Identifier: UNLICENSED
// ALL RIGHTS RESERVED
// UNCX by SDDTech reserves all rights on this code. You may not copy these contracts.

pragma solidity 0.8.19;

import "./uniswap-updated/INonfungiblePositionManager.sol";

/**
 * @dev Interface of the UNCX UniswapV3 Liquidity Locker
 */
interface IUNCX_ProofOfReservesV2_UniV3 {
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
    function acceptLockOwnership (uint256 lockId) external;
    function decreaseLiquidity(uint256 lockId, INonfungiblePositionManager.DecreaseLiquidityParams calldata params) external payable returns (uint256 amount0, uint256 amount1);
    function increaseLiquidity(uint256 lockId, INonfungiblePositionManager.IncreaseLiquidityParams calldata params) external payable returns (uint128 liquidity, uint256 amount0, uint256 amount1);

    // Admin functions
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

    event onTransferLockOwnership(uint256 lockId, address oldOwner, address newOwner);

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
    
}

// SPDX-License-Identifier: UNLICENSED
// ALL RIGHTS RESERVED
// UNCX by SDDTech reserves all rights on this code. You may not copy these contracts.

pragma solidity 0.8.19;

import "@openzeppelin/contracts/token/ERC721/IERC721Receiver.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

import "./IMigrateV3NFT.sol";
import "./uniswap-updated/INonfungiblePositionManager.sol";
import "./v1/IUNCX_ProofOfReservesUniV3.sol";
import "./IUNCX_ProofOfReservesV2_UniV3.sol";

contract MigrateV3NFT is IMigrateV3NFT, IERC721Receiver, ReentrancyGuard {
    IUNCX_ProofOfReservesUniV3 public OLD_ProofOfReservesUniV3;
    IUNCX_ProofOfReservesV2_UniV3 public NEW_ProofOfReservesUniV3;

    constructor(IUNCX_ProofOfReservesUniV3 _Old_ProofOfReservesUniV3, IUNCX_ProofOfReservesV2_UniV3 _New_ProofOfReservesUniV3) {
        OLD_ProofOfReservesUniV3 = _Old_ProofOfReservesUniV3;
        NEW_ProofOfReservesUniV3 = _New_ProofOfReservesUniV3;
    }

    function migrate (uint256 _lockId, INonfungiblePositionManager _nftPositionManager, uint256 _tokenId) external override nonReentrant returns (bool) {
        require(msg.sender == address(OLD_ProofOfReservesUniV3), "SENDER NOT UNCX LOCKER");
        _nftPositionManager.safeTransferFrom(msg.sender, address(this), _tokenId);
        _nftPositionManager.approve(address(NEW_ProofOfReservesUniV3), _tokenId);
        
        IUNCX_ProofOfReservesUniV3.Lock memory v1lock = OLD_ProofOfReservesUniV3.getLock(_lockId);
        IUNCX_ProofOfReservesV2_UniV3.LockParams memory v2LockParams;

        v2LockParams.nftPositionManager = v1lock.nftPositionManager;
        v2LockParams.nft_id = v1lock.nft_id;
        v2LockParams.dustRecipient = v1lock.collectAddress;
        v2LockParams.owner = v1lock.owner;
        v2LockParams.additionalCollector = v1lock.additionalCollector;
        v2LockParams.collectAddress = v1lock.collectAddress;
        v2LockParams.unlockDate = v1lock.unlockDate;
        v2LockParams.countryCode = v1lock.countryCode;
        v2LockParams.r = new bytes[](1);
        v2LockParams.r[0] = abi.encode(v1lock.ucf);

        if (v2LockParams.unlockDate <= block.timestamp) {
            v2LockParams.unlockDate = block.timestamp + 1;
        }

        NEW_ProofOfReservesUniV3.lock(v2LockParams);

        return true;
    }

    function onERC721Received(
        address operator,
        address from,
        uint256 tokenId,
        bytes calldata data
    ) public pure override returns (bytes4) {
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

// SPDX-License-Identifier: UNLICENSED
// ALL RIGHTS RESERVED
// UNCX by SDDTech reserves all rights on this code. You may not copy these contracts.

pragma solidity 0.8.19;

import "../uniswap-updated/INonfungiblePositionManager.sol";

/**
 * @dev Interface of the UNCX UniswapV3 Liquidity Locker
 */
interface IUNCX_ProofOfReservesUniV3 {
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
    function acceptLockOwnership (uint256 lockId) external;
    function decreaseLiquidity(uint256 lockId, INonfungiblePositionManager.DecreaseLiquidityParams calldata params) external payable returns (uint256 amount0, uint256 amount1);
    function increaseLiquidity(uint256 lockId, INonfungiblePositionManager.IncreaseLiquidityParams calldata params) external payable returns (uint128 liquidity, uint256 amount0, uint256 amount1);

    // Admin functions
    function setMigrator(address migrator) external;
    function setUCF(uint256 lockId, uint256 ucf) external;

    // Getters
    function getLocksLength() external view returns (uint256);
    function getLock(uint256 lockId) external view returns (Lock memory lock);

    function getNumUserLocks(address user) external view returns (uint256 numLocks);
    function getUserLockAtIndex(address user, uint256 index) external view returns (Lock memory lock);

    function getFee (string memory name) external view returns (FeeStruct memory);
    function getAmountsForLiquidity (int24 currentTick, int24 tickLower, int24 tickHigher, uint128 liquidity) external pure returns (uint256 amount0, uint256 amount1);

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

    event onTransferLockOwnership(uint256 lockId, address oldOwner, address newOwner);

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
}