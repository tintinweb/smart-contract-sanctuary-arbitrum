// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/introspection/IERC165.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC165 standard, as defined in the
 * https://eips.ethereum.org/EIPS/eip-165[EIP].
 *
 * Implementers can declare support of contract interfaces, which can then be
 * queried by others ({ERC165Checker}).
 *
 * For an implementation, see {ERC165}.
 */
interface IERC165 {
    /**
     * @dev Returns true if this contract implements the interface defined by
     * `interfaceId`. See the corresponding
     * https://eips.ethereum.org/EIPS/eip-165#how-interfaces-are-identified[EIP section]
     * to learn more about how these ids are created.
     *
     * This function call must use less than 30 000 gas.
     */
    function supportsInterface(bytes4 interfaceId) external view returns (bool);
}

// SPDX-License-Identifier: GPLv3
pragma solidity 0.8.13;

abstract contract RangePoolManagerEvents {
    event FactoryChanged(address indexed previousFactory, address indexed newFactory);
    event FeeTierEnabled(uint16 swapFee, int24 tickSpacing);
    event FeeToTransfer(address indexed previousFeeTo, address indexed newFeeTo);
    event OwnerTransfer(address indexed previousOwner, address indexed newOwner);
    event ProtocolFeeUpdated(address[] pool, uint16 protocolFee);
    event ProtocolFeeCollected(address[] pool, uint128[] token0Fees, uint128[] token1Fees);
}

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity 0.8.13;

import './IRangePoolStructs.sol';
import './IRangePoolManager.sol';

interface IRangePool is IRangePoolStructs {
    function mint(MintParams calldata mintParams) external;

    function burn(BurnParams calldata burnParams) external;

    function swap(
        address recipient,
        address refundRecipient,
        bool zeroForOne,
        uint256 amountIn,
        uint160 priceLimit
    ) external returns (
        int256 amount0,
        int256 amount1
    );

    function quote(
        bool zeroForOne,
        uint256 amountIn,
        uint160 priceLimit
    ) external view returns (
        uint256 inAmount,
        uint256 outAmount,
        uint160 priceAfter
    );

    function increaseSampleLength(
        uint16 sampleLengthNext
    ) external;

    function protocolFees(
        uint16 protocolFee,
        bool setFee
    ) external returns (
        uint128 token0Fees,
        uint128 token1Fees
    );

    function owner() external view returns (
        address
    );

    function tickSpacing() external view returns (
        int24
    );

    function samples(uint256) external view returns (
        uint32,
        int56,
        uint160
    );

    function poolState() external view returns (
        uint8,
        uint16,
        int24,
        int56,
        uint160,
        uint160,
        uint128,
        uint128,
        uint200,
        uint200,
        SampleState memory,
        ProtocolFees memory
    );

    function ticks(int24) external view returns (
        int128,
        uint200,
        uint200,
        int56,
        uint160
    );
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.13;

import "@openzeppelin/contracts/utils/introspection/IERC165.sol";

interface IRangePoolERC1155 is IERC165 {
    event TransferSingle(
        address indexed sender,
        address indexed from,
        address indexed to,
        uint256 id,
        uint256 amount
    );

    event TransferBatch(
        address indexed sender,
        address indexed from,
        address indexed to,
        uint256[] ids,
        uint256[] amounts
    );

    event ApprovalForAll(
        address indexed account,
        address indexed sender,
        bool approve
    );

    function name() external view returns (string memory);

    function symbol() external view returns (string memory);

    function balanceOf(address account, uint256 id) external view returns (uint256);

    function balanceOfBatch(
        address[] calldata accounts,
        uint256[] calldata ids
    ) external view returns (
        uint256[] memory batchBalances
    );

    function totalSupply(uint256 id) external view returns (uint256);

    function isApprovedForAll(address owner, address spender) external view returns (bool);

    function setApprovalForAll(address sender, bool approved) external;

    function mintFungible(
        address account,
        uint256 id,
        uint256 amount
    ) external;

    function burnFungible(
        address account,
        uint256 id,
        uint256 amount
    ) external;

    function safeTransferFrom(
        address from,
        address to,
        uint256 id,
        uint256 amount
    ) external;

    function safeBatchTransferFrom(
        address from,
        address to,
        uint256[] calldata id,
        uint256[] calldata amount
    ) external;
}

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity 0.8.13;

import './IRangePoolStructs.sol';
import './IRangePoolERC1155.sol';

interface IRangePoolManager {
    function owner() external view returns (address);
    function feeTo() external view returns (address);
    function protocolFees(address pool) external view returns (uint16);
    function feeTiers(uint16 swapFee) external view returns (int24);
}

// SPDX-License-Identifier: GPLv3
pragma solidity 0.8.13;

import "./IRangePoolERC1155.sol";

interface IRangePoolStructs {
    struct PoolState {
        uint8   unlocked;
        uint16  protocolFee;
        int24   tickAtPrice;
        int56   tickSecondsAccum;
        uint160 secondsPerLiquidityAccum;
        uint160 price;               /// @dev Starting price current
        uint128 liquidity;           /// @dev Liquidity currently active
        uint128 liquidityGlobal;     /// @dev Globally deposited liquidity
        uint200 feeGrowthGlobal0;
        uint200 feeGrowthGlobal1;
        SampleState  samples;
        ProtocolFees protocolFees;
    }

    struct SampleState {
        uint16  index;
        uint16  length;
        uint16  lengthNext;
    }

    struct Tick {
        int128  liquidityDelta;
        uint200 feeGrowthOutside0; // Per unit of liquidity.
        uint200 feeGrowthOutside1;
        int56   tickSecondsAccumOutside;
        uint160 secondsPerLiquidityAccumOutside;
    }

    struct TickMap {
        uint256 blocks;                     /// @dev - sets of words
        mapping(uint256 => uint256) words;  /// @dev - sets to words
        mapping(uint256 => uint256) ticks;  /// @dev - words to ticks
    }

    struct TickParams {
        TickMap tickMap;
        mapping(int24 => Tick) ticks;
    }

    struct Position {
        uint128 liquidity;
        uint128 amount0;
        uint128 amount1;
        uint256 feeGrowthInside0Last;
        uint256 feeGrowthInside1Last;
    }

    struct Sample {
        uint32  blockTimestamp;
        int56   tickSecondsAccum;
        uint160 secondsPerLiquidityAccum;
    }

    struct ProtocolFees {
        uint128 token0;
        uint128 token1;
    }

    struct Immutables {
        uint16 swapFee;
        int24  tickSpacing;
    }

    struct MintParams {
        address to;
        int24 lower;
        int24 upper;
        uint128 amount0;
        uint128 amount1;
        bool fungible;
    }

    struct BurnParams {
        address to;
        int24 lower;
        int24 upper;
        uint128 amount;
        bool fungible;
        bool collect;
    }

    struct CompoundParams {
        address owner;
        int24 lower;
        int24 upper;
        bool fungible;
    }

    struct SwapParams {
        address recipient;
        bool zeroForOne;
        uint160 priceLimit;
        uint256 amountIn;
    }

    struct SampleParams {
        uint16 sampleIndex;
        uint16 sampleLength;
        uint32 time;
        uint32[] secondsAgos;
        int24 tick;
        uint128 liquidity;
    }

    struct AddParams {
        PoolState state;
        MintParams mint;
        uint128 amount;
        uint128 liquidity;
    }

    struct RemoveParams {
        uint128 amount0;
        uint128 amount1;
    }

    struct UpdateParams {
        address owner;
        int24 lower;
        int24 upper;
        uint128 amount;
        bool fungible;
    }

    struct MintCache {
        PoolState pool;
        MintParams params;
        Position position;
    }

    struct SwapCache {
        bool    cross;
        int24   tick;
        int24   crossTick;
        uint16  swapFee;
        uint16  protocolFee;
        int56   tickSecondsAccum;
        uint160 secondsPerLiquidityAccum;
        uint160 crossPrice;
        uint256 input;
        uint256 output;
        uint256 amountIn;
    }

    struct PositionCache {
        uint160 priceLower;
        uint160 priceUpper;
        uint256 liquidityOnPosition;
        uint256 liquidityAmount;
        uint256 totalSupply;
        uint256 tokenId;
    }

    struct UpdatePositionCache {
        Position position;
        uint160 priceLower;
        uint160 priceUpper;
        bool removeLower;
        bool removeUpper;
        int128 amountInDelta;
        int128 amountOutDelta;
    }

    struct SnapshotCache {
        int24   tick;
        uint160 price;
        uint32  blockTimestamp;
        uint32  secondsOutsideLower;
        uint32  secondsOutsideUpper;
        int56   tickSecondsAccum;
        int56   tickSecondsAccumLower;
        int56   tickSecondsAccumUpper;
        uint128 liquidity;
        uint160 secondsPerLiquidityAccum;
        uint160 secondsPerLiquidityAccumLower;
        uint160 secondsPerLiquidityAccumUpper;
        SampleState samples;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (access/Ownable.sol)

pragma solidity ^0.8.0;

import '../interfaces/IRangePool.sol';
import '../interfaces/IRangePoolManager.sol';
import '../base/events/RangePoolManagerEvents.sol';

/**
 * @dev Defines the actions which can be executed by the factory admin.
 */
contract RangePoolManager is 
    IRangePoolManager,
    RangePoolManagerEvents
{
    address public _owner;
    address private _feeTo;
    address private _factory;
    uint16 internal constant MAX_FEE = 1e4; // @dev - max fee of 1%

    mapping(uint16 => int24)   public feeTiers;
    mapping(address => uint16) public protocolFees;

    error OwnerOnly();
    error FeeToOnly();
    error FeeTierAlreadyEnabled();
    error TransferredToZeroAddress();
    error FeeTierTickSpacingInvalid();
    error ProtocolFeeMaxExceeded();
    
    constructor() {
        _owner = msg.sender;
        _feeTo = msg.sender;
        emit OwnerTransfer(address(0), msg.sender);

        feeTiers[500] = 10;
        emit FeeTierEnabled(500, 10);

        feeTiers[3000] = 60;
        emit FeeTierEnabled(3000, 60);

        feeTiers[10000] = 200;
        emit FeeTierEnabled(10000, 200);
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        _checkOwner();
        _;
    }

    modifier onlyFeeTo() {
        _checkFeeTo();
        _;
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function feeTo() public view virtual returns (address) {
        return _feeTo;
    }

    function factory() public view virtual returns (address) {
        return _factory;
    }

    /**
     * @dev Throws if the sender is not the owner.
     */
    function _checkOwner() internal view virtual {
        if (owner() != msg.sender) revert OwnerOnly();
    }

    /**
     * @dev Throws if the sender is not the feeTo.
     */
    function _checkFeeTo() internal view virtual {
        if (feeTo() != msg.sender) revert FeeToOnly();
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwner(address newOwner) public virtual onlyOwner {
        if(newOwner == address(0)) revert TransferredToZeroAddress();
        _transferOwner(newOwner);
    }

    function transferFeeTo(address newFeeTo) public virtual onlyFeeTo {
        if(newFeeTo == address(0)) revert TransferredToZeroAddress();
        _transferFeeTo(newFeeTo);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Internal function without access restriction.
     */
    function _transferOwner(address newOwner) internal virtual {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnerTransfer(oldOwner, newOwner);
    }

    /**
     * @dev Transfers fee collection to a new account (`newFeeTo`).
     * Internal function without access restriction.
     */
    function _transferFeeTo(address newFeeTo) internal virtual {
        address oldFeeTo = _feeTo;
        _feeTo = newFeeTo;
        emit OwnerTransfer(oldFeeTo, newFeeTo);
    }

    function enableFeeTier(
        uint16 swapFee,
        int24 tickSpacing
    ) external onlyOwner {
        if (feeTiers[swapFee] != 0) {
            revert FeeTierAlreadyEnabled();
        }
        if(tickSpacing <= 0 || tickSpacing >= 16384) revert FeeTierTickSpacingInvalid();
        feeTiers[swapFee] = tickSpacing;
        emit FeeTierEnabled(swapFee, tickSpacing);
    }

    function setFactory(
        address factory_
    ) external onlyOwner {
        emit FactoryChanged(_factory, factory_);
        _factory = factory_;
    }

    function setTopPools(
        address[] calldata removePools,
        address[] calldata addPools,
        uint16 protocolFee
    ) external onlyOwner {
        if (protocolFee > MAX_FEE) revert ProtocolFeeMaxExceeded();
        uint128[] memory token0Fees = new uint128[](removePools.length);
        uint128[] memory token1Fees = new uint128[](removePools.length);
        for (uint i; i < removePools.length; i++) {
            (token0Fees[i], token1Fees[i]) = IRangePool(removePools[i]).protocolFees(0, true); 
        }
        if (removePools.length > 0) {
            emit ProtocolFeeUpdated(removePools, protocolFee);
            emit ProtocolFeeCollected(removePools, token0Fees, token1Fees);
        }
        token0Fees = new uint128[](addPools.length);
        token1Fees = new uint128[](addPools.length);
        for (uint i; i < addPools.length; i++) {
            (token0Fees[i], token1Fees[i]) = IRangePool(addPools[i]).protocolFees(protocolFee, true);
        }
        if (addPools.length > 0) {
            emit ProtocolFeeUpdated(removePools, protocolFee);
            emit ProtocolFeeCollected(removePools, token0Fees, token1Fees);
        }
    }

    function collectTopPools(
        address[] calldata collectPools
    ) external onlyFeeTo {
        uint128[] memory token0Fees = new uint128[](collectPools.length);
        uint128[] memory token1Fees = new uint128[](collectPools.length);
        for (uint i; i < collectPools.length; i++) {
            (token0Fees[i], token1Fees[i]) = IRangePool(collectPools[i]).protocolFees(0, false);
            emit ProtocolFeeCollected(collectPools, token0Fees, token1Fees);
        }
    }
}