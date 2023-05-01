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

//SPDX-License-Identifier: MIT

///@notice this is a helper contract to add LP directly to the peg-weth balancer pool. Weighted 80% peg, 20% weth
///@author https://github.com/jayusjay

pragma solidity 0.8.19;

import { IERC20 } from "openzeppelin-contracts/contracts/token/ERC20/IERC20.sol";
import { IAsset, IVault, IWeightedPool } from "./interfaces/IWeightedPoolFactory.sol";

contract AddLP {
    address public constant WETH = 0x82aF49447D8a07e3bd95BD0d56f35241523fBab1;
    address public constant PEG = 0x4fc2A3Fb655847b7B72E19EAA2F10fDB5C2aDdbe;
    address public constant VAULT_ADDRESS = 0xBA12222222228d8Ba445958a75a0704d566BF2C8;
    bytes32 public constant POOL_ID = 0x3efd3e18504dc213188ed2b694f886a305a6e5ed00020000000000000000041d;
    //lp token address: 0x3eFd3E18504dC213188Ed2b694F886A305a6e5ed

    event AddedLP(uint256 wethAmount, uint256 pegAmount, uint256 minBlpOut);

    function addLP(uint256 wethAmount, uint256 pegAmount, uint256 minBlpOut) external {
        (address token0, address token1) = sortTokens(PEG, WETH);
        IAsset[] memory assets = new IAsset[](2);
        assets[0] = IAsset(token0);
        assets[1] = IAsset(token1);

        uint256[] memory maxAmountsIn = new uint256[](2);
        if (token0 == WETH) {
            maxAmountsIn[0] = wethAmount;
            maxAmountsIn[1] = pegAmount;
        } else {
            maxAmountsIn[0] = pegAmount;
            maxAmountsIn[1] = wethAmount;
        }

        require(IERC20(WETH).transferFrom(msg.sender, address(this), wethAmount), "weth transfer failed");
        require(IERC20(PEG).transferFrom(msg.sender, address(this), pegAmount), "peg transfer failed");

        IERC20(PEG).approve(VAULT_ADDRESS, pegAmount);
        IERC20(WETH).approve(VAULT_ADDRESS, wethAmount);

        bytes memory userDataEncoded = abi.encode(
            IWeightedPool.JoinKind.EXACT_TOKENS_IN_FOR_BPT_OUT,
            maxAmountsIn,
            minBlpOut
        );
        IVault.JoinPoolRequest memory inRequest = IVault.JoinPoolRequest(assets, maxAmountsIn, userDataEncoded, false);
        IVault(VAULT_ADDRESS).joinPool(POOL_ID, address(this), msg.sender, inRequest);

        emit AddedLP(wethAmount, pegAmount, minBlpOut);
    }

    function sortTokens(address tokenA, address tokenB) public pure returns (address token0, address token1) {
        require(tokenA != tokenB, "IDENTICAL_ADDRESSES");
        require(tokenA != address(0), "ZERO_ADDRESS");
        (token0, token1) = tokenA < tokenB ? (tokenA, tokenB) : (tokenB, tokenA);
    }
}

// SPDX-License-Identifier: agpl-3.0
pragma solidity 0.8.19;
import { IERC20 } from "openzeppelin-contracts/contracts/token/ERC20/IERC20.sol";

interface IBasePool is IERC20 {
    function getSwapFeePercentage() external view returns (uint256);

    function setSwapFeePercentage(uint256 swapFeePercentage) external;

    function setAssetManagerPoolConfig(IERC20 token, IAssetManager.PoolConfig memory poolConfig) external;

    function setPaused(bool paused) external;

    function getVault() external view returns (IVault);

    function getPoolId() external view returns (bytes32);

    function getOwner() external view returns (address);
}

interface IWeightedPoolFactory {
    function create(
        string memory name,
        string memory symbol,
        IERC20[] memory tokens,
        uint256[] memory weights,
        address[] memory rateProviders,
        uint256 swapFeePercentage,
        address owner
    ) external returns (address);
}

interface IWeightedPool is IBasePool {
    function getSwapEnabled() external view returns (bool);

    function getNormalizedWeights() external view returns (uint256[] memory);

    function getGradualWeightUpdateParams()
        external
        view
        returns (uint256 startTime, uint256 endTime, uint256[] memory endWeights);

    function setSwapEnabled(bool swapEnabled) external;

    function updateWeightsGradually(uint256 startTime, uint256 endTime, uint256[] memory endWeights) external;

    function withdrawCollectedManagementFees(address recipient) external;

    enum JoinKind {
        INIT,
        EXACT_TOKENS_IN_FOR_BPT_OUT,
        TOKEN_IN_FOR_EXACT_BPT_OUT
    }
    enum ExitKind {
        EXACT_BPT_IN_FOR_ONE_TOKEN_OUT,
        EXACT_BPT_IN_FOR_TOKENS_OUT,
        BPT_IN_FOR_EXACT_TOKENS_OUT
    }
}

interface IAssetManager {
    struct PoolConfig {
        uint64 targetPercentage;
        uint64 criticalPercentage;
        uint64 feePercentage;
    }

    function setPoolConfig(bytes32 poolId, PoolConfig calldata config) external;
}

interface IAsset {}

interface IVault {
    function hasApprovedRelayer(address user, address relayer) external view returns (bool);

    function setRelayerApproval(address sender, address relayer, bool approved) external;

    event RelayerApprovalChanged(address indexed relayer, address indexed sender, bool approved);

    function getInternalBalance(address user, IERC20[] memory tokens) external view returns (uint256[] memory);

    function manageUserBalance(UserBalanceOp[] memory ops) external payable;

    struct UserBalanceOp {
        UserBalanceOpKind kind;
        IAsset asset;
        uint256 amount;
        address sender;
        address payable recipient;
    }

    enum UserBalanceOpKind {
        DEPOSIT_INTERNAL,
        WITHDRAW_INTERNAL,
        TRANSFER_INTERNAL,
        TRANSFER_EXTERNAL
    }
    event InternalBalanceChanged(address indexed user, IERC20 indexed token, int256 delta);
    event ExternalBalanceTransfer(IERC20 indexed token, address indexed sender, address recipient, uint256 amount);

    enum PoolSpecialization {
        GENERAL,
        MINIMAL_SWAP_INFO,
        TWO_TOKEN
    }

    function registerPool(PoolSpecialization specialization) external returns (bytes32);

    event PoolRegistered(bytes32 indexed poolId, address indexed poolAddress, PoolSpecialization specialization);

    function getPool(bytes32 poolId) external view returns (address, PoolSpecialization);

    function registerTokens(bytes32 poolId, IERC20[] memory tokens, address[] memory assetManagers) external;

    event TokensRegistered(bytes32 indexed poolId, IERC20[] tokens, address[] assetManagers);

    function deregisterTokens(bytes32 poolId, IERC20[] memory tokens) external;

    event TokensDeregistered(bytes32 indexed poolId, IERC20[] tokens);

    function getPoolTokenInfo(
        bytes32 poolId,
        IERC20 token
    ) external view returns (uint256 cash, uint256 managed, uint256 lastChangeBlock, address assetManager);

    function getPoolTokens(
        bytes32 poolId
    ) external view returns (IERC20[] memory tokens, uint256[] memory balances, uint256 lastChangeBlock);

    function joinPool(
        bytes32 poolId,
        address sender,
        address recipient,
        JoinPoolRequest memory request
    ) external payable;

    struct JoinPoolRequest {
        IAsset[] assets;
        uint256[] maxAmountsIn;
        bytes userData;
        bool fromInternalBalance;
    }

    function exitPool(
        bytes32 poolId,
        address sender,
        address payable recipient,
        ExitPoolRequest memory request
    ) external;

    struct ExitPoolRequest {
        IAsset[] assets;
        uint256[] minAmountsOut;
        bytes userData;
        bool toInternalBalance;
    }

    event PoolBalanceChanged(
        bytes32 indexed poolId,
        address indexed liquidityProvider,
        IERC20[] tokens,
        int256[] deltas,
        uint256[] protocolFeeAmounts
    );

    enum PoolBalanceChangeKind {
        JOIN,
        EXIT
    }

    enum SwapKind {
        GIVEN_IN,
        GIVEN_OUT
    }

    function swap(
        SingleSwap memory singleSwap,
        FundManagement memory funds,
        uint256 limit,
        uint256 deadline
    ) external payable returns (uint256);

    struct SingleSwap {
        bytes32 poolId;
        SwapKind kind;
        IAsset assetIn;
        IAsset assetOut;
        uint256 amount;
        bytes userData;
    }

    function batchSwap(
        SwapKind kind,
        BatchSwapStep[] memory swaps,
        IAsset[] memory assets,
        FundManagement memory funds,
        int256[] memory limits,
        uint256 deadline
    ) external payable returns (int256[] memory);

    struct BatchSwapStep {
        bytes32 poolId;
        uint256 assetInIndex;
        uint256 assetOutIndex;
        uint256 amount;
        bytes userData;
    }

    event Swap(
        bytes32 indexed poolId,
        IERC20 indexed tokenIn,
        IERC20 indexed tokenOut,
        uint256 amountIn,
        uint256 amountOut
    );
    struct FundManagement {
        address sender;
        bool fromInternalBalance;
        address payable recipient;
        bool toInternalBalance;
    }

    function queryBatchSwap(
        SwapKind kind,
        BatchSwapStep[] memory swaps,
        IAsset[] memory assets,
        FundManagement memory funds
    ) external returns (int256[] memory assetDeltas);

    function managePoolBalance(PoolBalanceOp[] memory ops) external;

    struct PoolBalanceOp {
        PoolBalanceOpKind kind;
        bytes32 poolId;
        IERC20 token;
        uint256 amount;
    }

    enum PoolBalanceOpKind {
        WITHDRAW,
        DEPOSIT,
        UPDATE
    }
    event PoolBalanceManaged(
        bytes32 indexed poolId,
        address indexed assetManager,
        IERC20 indexed token,
        int256 cashDelta,
        int256 managedDelta
    );

    function setPaused(bool paused) external;
}