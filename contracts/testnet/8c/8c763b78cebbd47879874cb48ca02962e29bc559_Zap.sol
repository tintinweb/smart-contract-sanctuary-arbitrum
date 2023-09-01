// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

import { IAsyncSwapper, SwapParams } from "src/interfaces/swapper/IAsyncSwapper.sol";
import { IRegistry } from "src/interfaces/pool/IRegistry.sol";
import { IPool } from "src/interfaces/pool/IPool.sol";
import { IStargateRouter } from "src/interfaces/stargate/IStargateRouter.sol";
import { ITokenKeeper } from "src/interfaces/zap/ITokenKeeper.sol";
import { IZap } from "src/interfaces/zap/IZap.sol";

import { Error } from "src/librairies/Error.sol";
import { ERC20Utils } from "src/librairies/ERC20Utils.sol";

import { Address } from "openzeppelin-contracts/contracts/utils/Address.sol";
import { IERC20 } from "openzeppelin-contracts/contracts/token/ERC20/IERC20.sol";
import { SafeERC20 } from "openzeppelin-contracts/contracts/token/ERC20/utils/SafeERC20.sol";
import { Ownable, Ownable2Step } from "openzeppelin-contracts/contracts/access/Ownable2Step.sol";

contract Zap is IZap, Ownable2Step {
    using SafeERC20 for IERC20;
    using Address for address;

    address public immutable swapper;
    address public immutable registry;
    address public immutable stargateRouter;
    address public immutable tokenKeeper;

    uint256 public constant DST_GAS = 200_000;

    // chainId -> stargateReceiver
    mapping(uint16 => address) public stargateDestinations;

    /*///////////////////////////////////////////////////////////////
                            CONSTRUCTOR
    ///////////////////////////////////////////////////////////////*/

    constructor(
        address _swapper,
        address _registry,
        address _stargateRouter,
        address _tokenKeeper,
        address _owner
    ) Ownable(_owner) {
        if (_swapper == address(0)) revert Error.ZeroAddress();
        if (_registry == address(0)) revert Error.ZeroAddress();
        if (_stargateRouter == address(0)) revert Error.ZeroAddress();
        if (_tokenKeeper == address(0)) revert Error.ZeroAddress();
        swapper = _swapper;
        registry = _registry;
        stargateRouter = _stargateRouter;
        tokenKeeper = _tokenKeeper;
    }

    /*///////////////////////////////////////////////////////////////
                        MUTATIVE FUNCTIONS
    ///////////////////////////////////////////////////////////////*/

    /// @inheritdoc IZap
    function stake(address _pool, uint256 _amount) external poolExists(_pool) {
        if (_amount == 0) revert Error.ZeroAmount();

        IERC20 token = IPool(_pool).token();
        token.safeTransferFrom(msg.sender, address(this), _amount);

        _stake(_pool, address(token), _amount);
    }

    /// @inheritdoc IZap
    function stakeFromBridge(address _pool) external poolExists(_pool) {
        IERC20 token = IPool(_pool).token();
        uint256 amount = ITokenKeeper(tokenKeeper).pullToken(address(token), msg.sender);

        _stake(_pool, address(token), amount);
    }

    /// @inheritdoc IZap
    function swapAndStake(SwapParams memory _swapParams, address _pool) external poolExists(_pool) {
        if (_swapParams.buyTokenAddress != address(IPool(_pool).token())) revert WrongPoolToken();

        IERC20 sellToken = IERC20(_swapParams.sellTokenAddress);
        sellToken.safeTransferFrom(msg.sender, address(this), _swapParams.sellAmount);

        uint256 amountSwapped = _swap(_swapParams);
        _stake(_pool, _swapParams.buyTokenAddress, amountSwapped);
    }

    /// @inheritdoc IZap
    function swapAndStakeFromBridge(SwapParams memory _swapParams, address _pool) external poolExists(_pool) {
        if (_swapParams.buyTokenAddress != address(IPool(_pool).token())) revert WrongPoolToken();

        IERC20 sellToken = IERC20(_swapParams.sellTokenAddress);
        uint256 amountToSwap = ITokenKeeper(tokenKeeper).pullToken(address(sellToken), msg.sender);
        if (_swapParams.sellAmount != amountToSwap) revert WrongAmount();

        uint256 amountSwapped = _swap(_swapParams);
        _stake(_pool, _swapParams.buyTokenAddress, amountSwapped);
    }

    /// @inheritdoc IZap
    function swapAndBridge(
        SwapParams memory _swapParams,
        uint256 _minAmount,
        uint16 _dstChainId,
        uint256 _srcPoolId,
        uint256 _dstPoolId,
        address _dstAccount
    ) external payable {
        IERC20 sellToken = IERC20(_swapParams.sellTokenAddress);
        sellToken.safeTransferFrom(msg.sender, address(this), _swapParams.sellAmount);
        uint256 amountSwapped = _swap(_swapParams);
        _bridge(
            _swapParams.buyTokenAddress, amountSwapped, _minAmount, _dstChainId, _srcPoolId, _dstPoolId, _dstAccount
        );
    }

    /// @inheritdoc IZap
    function bridge(
        address _token,
        uint256 _amount,
        uint256 _minAmount,
        uint16 _dstChainId,
        uint256 _srcPoolId,
        uint256 _dstPoolId,
        address _dstAccount
    ) external payable {
        IERC20(_token).safeTransferFrom(msg.sender, address(this), _amount);
        _bridge(_token, _amount, _minAmount, _dstChainId, _srcPoolId, _dstPoolId, _dstAccount);
    }

    /*///////////////////////////////////////////////////////////////
                            SETTERS
    ///////////////////////////////////////////////////////////////*/

    /// @inheritdoc IZap
    function setStargateDestinations(uint16[] calldata chainIds, address[] calldata destinations) external onlyOwner {
        uint256 len = chainIds.length;
        if (len == 0) revert Error.ZeroAmount();
        if (len != destinations.length) revert Error.ArrayLengthMismatch();

        for (uint256 i = 0; i < len; ++i) {
            uint16 chainId = chainIds[i];
            if (chainId == 0) revert InvalidChainId();
            // Zero address is ok here to allow for cancelling of chains
            stargateDestinations[chainId] = destinations[i];
        }

        emit StargateDestinationsSet(chainIds, destinations);
    }

    /*///////////////////////////////////////////////////////////////
    					    INTERNAL FUNCTIONS
    ///////////////////////////////////////////////////////////////*/

    /**
     * @notice Bridges tokens to a specific chain using Stargate
     *  @param _token The token address
     *  @param _amount The amount of token to bridge
     *  @param _minAmount The minimum amount of bridged tokens caller is willing to accept
     *  @param _dstChainId The destination chain ID
     *  @param _srcPoolId The source pool ID
     *  @param _dstPoolId The destination pool ID
     *  @param _dstAccount The destination account
     */
    function _bridge(
        address _token,
        uint256 _amount,
        uint256 _minAmount,
        uint16 _dstChainId,
        uint256 _srcPoolId,
        uint256 _dstPoolId,
        address _dstAccount
    ) internal {
        address dstStargateReceiver = stargateDestinations[_dstChainId];
        if (_token == address(0)) revert Error.ZeroAddress();
        if (_amount == 0) revert Error.ZeroAmount();
        if (dstStargateReceiver == address(0)) revert InvalidChainId();
        if (_dstAccount == address(0)) revert Error.ZeroAddress();

        ERC20Utils._approve(IERC20(_token), stargateRouter, _amount);

        bytes memory data = abi.encode(_dstAccount);

        IStargateRouter(stargateRouter).swap{ value: msg.value }(
            _dstChainId,
            _srcPoolId,
            _dstPoolId,
            payable(msg.sender),
            _amount,
            _minAmount,
            IStargateRouter.lzTxObj(DST_GAS, 0, "0x"),
            abi.encodePacked(dstStargateReceiver),
            data
        );
    }

    /**
     * @notice Calls the stakeFor function of a Pool contract
     * @param _pool The pool address
     * @param _token The token used in the pool
     * @param _amount The stake amount
     */
    function _stake(address _pool, address _token, uint256 _amount) internal {
        ERC20Utils._approve(IERC20(_token), _pool, _amount);
        IPool(_pool).stakeFor(msg.sender, _amount);
    }

    /**
     * @notice Calls IAsyncSwapper.Swap() using delegateCall
     * @param _swapParams A struct containing all necessary params allowing a token swap
     * @return The amount of tokens which got swapped
     */
    function _swap(SwapParams memory _swapParams) internal returns (uint256) {
        bytes memory returnedData = swapper.functionDelegateCall(
            abi.encodeWithSelector(IAsyncSwapper.swap.selector, _swapParams), _delegateSwapFailed
        );
        return abi.decode(returnedData, (uint256));
    }

    /**
     * @notice A default revert function used in case the error
     * from a reverted delegatecall isn't returned
     */
    // slither-disable-start dead-code
    function _delegateSwapFailed() internal pure {
        revert DelegateSwapFailed();
    }

    // slither-disable-end dead-code

    /*///////////////////////////////////////////////////////////////
    					    MODIFIERS
    ///////////////////////////////////////////////////////////////*/

    /// @notice modifier checking if a pool is registered
    modifier poolExists(address _pool) {
        if (!IRegistry(registry).hasPool(_pool, false)) revert PoolNotRegistered();
        _;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

struct SwapParams {
    /// @dev The address of the token to be sold.
    address sellTokenAddress;
    /// @dev The amount of tokens to be sold.
    uint256 sellAmount;
    /// @dev The address of the token to be bought.
    address buyTokenAddress;
    /// @dev The expected minimum amount of tokens to be bought.
    uint256 buyAmount;
    /// @dev Data payload generated off-chain.
    bytes data;
}

interface IAsyncSwapper {
    error SwapFailed();
    error InsufficientBuyAmountReceived(address buyTokenAddress, uint256 buyTokenAmountReceived, uint256 buyAmount);

    event Swapped(
        address indexed sellTokenAddress,
        address indexed buyTokenAddress,
        uint256 sellAmount,
        uint256 buyAmount,
        uint256 buyTokenAmountReceived
    );

    /**
     * @notice Swaps sellToken for buyToken
     * @dev Only payable so it can be called from bridge fn
     * @param swapParams Encoded swap data
     * @return buyTokenAmountReceived The amount of buyToken received from the swap
     */
    function swap(SwapParams memory swapParams) external payable returns (uint256 buyTokenAmountReceived);
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

interface IRegistry {
    /*///////////////////////////////////////////////////////////////
                                EVENTS
    ///////////////////////////////////////////////////////////////*/

    event FactorySet(address indexed oldFactory, address indexed newFactory);

    event PoolApproved(address indexed pool);

    event PoolPending(address indexed pool);

    event PoolRejected(address indexed pool);

    event PoolRemoved(address indexed pool);

    /*///////////////////////////////////////////////////////////////
                            VIEW FUNCTIONS
    ///////////////////////////////////////////////////////////////*/

    /**
     * @notice Returns the address of a pool located at _index
     *  @param _index The index of a pool stored in the EnumerableSet
     *  @param _isPending True if looking into the pending pools, false for the approved ones
     * @return The address of a pool
     */
    function getPoolAt(uint256 _index, bool _isPending) external view returns (address);

    /**
     * @notice Returns the total number of pools
     * @param _isPending True if looking into the pending pools, false for the approved ones
     * @return The total number of pools
     */
    function getPoolCount(bool _isPending) external view returns (uint256);

    /**
     * @notice Checks if an address is stored in the pools set
     * @param _pool The address of a pool
     * @param _isPending True if looking into the pending pools, false for the approved ones
     * @return True if the pool has been found, false otherwise
     */
    function hasPool(address _pool, bool _isPending) external view returns (bool);

    /*///////////////////////////////////////////////////////////////
                                SETTERS
    ///////////////////////////////////////////////////////////////*/

    /**
     * @notice Modifies the factory address
     * @param _newFactory The new factory address
     */
    function setFactory(address _newFactory) external;

    /*///////////////////////////////////////////////////////////////
                            MUTATIVE FUNCTIONS
    ///////////////////////////////////////////////////////////////*/

    /**
     * @notice Registers a new pool in the pending queue
     * @param _newPool The address of a pool
     */
    function registerPool(address _newPool) external;

    /**
     * @notice Approves a pool from the pending queue
     * @param _pool The address of a pool
     */
    function approvePool(address _pool) external;

    /**
     * @notice Rejects a pool from the pending queue
     * @param _pool The address of a pool
     */
    function rejectPool(address _pool) external;

    /**
     * @notice Removes a pool from the approved pool Set
     * @param _pool The address of a pool
     */
    function removePool(address _pool) external;
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

import { IERC20 } from "openzeppelin-contracts/contracts/token/ERC20/IERC20.sol";

interface IPool {
    /*///////////////////////////////////////////////////////////////
                            STRUCTS/ENUMS
    ///////////////////////////////////////////////////////////////*/

    enum Status {
        Uninitialized,
        Created,
        Approved,
        Rejected,
        Seeding,
        Locked,
        Unlocked
    }

    struct StakingSchedule {
        /// @notice The timestamp when the seeding period starts.
        uint256 seedingStart;
        /// @notice The duration of the seeding period.
        uint256 seedingPeriod;
        /// @notice The timestamp when the locked period starts.
        uint256 lockedStart;
        /// @notice The duration of the lock period, which is also the duration of rewards.
        uint256 lockPeriod;
        /// @notice The timestamp when the rewards period ends.
        uint256 periodFinish;
    }

    /*///////////////////////////////////////////////////////////////
                                ERRORS
    ///////////////////////////////////////////////////////////////*/

    error StakeLimitMismatch();

    /*///////////////////////////////////////////////////////////////
                                EVENTS
    ///////////////////////////////////////////////////////////////*/

    event PoolInitialized(
        address indexed token,
        address indexed creator,
        uint256 seedingPeriod,
        uint256 lockPeriod,
        uint256 amount,
        uint256 fee,
        uint256 maxStakePerAddress,
        uint256 maxStakePerPool
    );

    event PoolApproved();

    event PoolRejected();

    event PoolStarted(uint256 seedingStart, uint256 periodFinish);

    event RewardsRetrieved(address indexed creator, uint256 amount);

    event Staked(address indexed account, uint256 amount);

    event Unstaked(address indexed account, uint256 amount);

    event RewardPaid(address indexed account, uint256 amount);

    event ProtocolFeePaid(address indexed treasury, uint256 amount);

    /*///////////////////////////////////////////////////////////////
                            INITIALIZER
    ///////////////////////////////////////////////////////////////*/

    /**
     * @notice Initializes a new staking pool
     * @param _creator The address of pool creator
     * @param _treasury The address of the treasury where the rewards will be distributed
     * @param _token The address of the token to be staked
     * @param _seedingPeriod The period in seconds during which users are able to stake
     * @param _lockPeriod The period in seconds during which the staked tokens are locked
     * @param _maxStakePerAddress The maximum amount of tokens that can be staked by a single address
     * @param _protocolFeeBps The fee charged by the protocol for each pool in bps
     * @param _maxStakePerPool The maximum amount of tokens that can be staked in the pool
     */
    function initialize(
        address _creator,
        address _treasury,
        address _token,
        uint256 _seedingPeriod,
        uint256 _lockPeriod,
        uint256 _maxStakePerAddress,
        uint256 _protocolFeeBps,
        uint256 _maxStakePerPool
    ) external;

    /*///////////////////////////////////////////////////////////////
                            VIEW FUNCTIONS
    ///////////////////////////////////////////////////////////////*/

    /**
     * @notice Returns the current operational status of the pool.
     * @return The current status of the pool.
     */
    function status() external view returns (Status);

    /**
     * @notice Returns the earned rewards of a specific account
     * @param account The address of the account
     * @return The amount of rewards earned by the account
     */
    function earned(address account) external view returns (uint256);

    /**
     * @notice Calculates the rewards per token for the current time.
     * @dev The total amount of rewards available in the system is fixed, and it needs to be distributed among the users
     * based on their token balances and the lock duration.
     * Rewards per token represent the amount of rewards that each token is entitled to receive at the current time.
     * The calculation takes into account the reward rate (rewardAmount / lockPeriod), the time duration since the last
     * update,
     * and the total supply of tokens in the pool.
     * @return The updated rewards per token value for the current block.
     */
    function rewardPerToken() external view returns (uint256);

    /**
     * @notice Get the last time where rewards are applicable.
     * @return The last time where rewards are applicable.
     */
    function lastTimeRewardApplicable() external view returns (uint256);

    /**
     * @notice Get the token used in the pool
     * @return The ERC20 token used in the pool
     */
    function token() external view returns (IERC20);

    /*///////////////////////////////////////////////////////////////
    					MUTATIVE FUNCTIONS
    ///////////////////////////////////////////////////////////////*/

    /// @notice Approves the pool to start accepting stakes
    function approvePool() external;

    /// @notice Rejects the pool
    function rejectPool() external;

    /// @notice Retrieves the reward tokens from the pool if the pool is rejected
    function retrieveRewardToken() external;

    /// @notice Starts the seeding period for the pool, during which deposits are accepted
    function start() external;

    /**
     * @notice Stakes a certain amount of tokens
     * @param _amount The amount of tokens to stake
     */
    function stake(uint256 _amount) external;

    /**
     * @notice Stakes a certain amount of tokens for a specified address
     * @param _staker The address for which the tokens are being staked
     * @param _amount The amount of tokens to stake
     */
    function stakeFor(address _staker, uint256 _amount) external;

    /**
     * @notice Unstakes all staked tokens
     */
    function unstakeAll() external;

    /**
     * @notice Claims the earned rewards
     */
    function claim() external;
}

// SPDX-License-Identifier: BUSL-1.1
// Ref'd from: https://stargateprotocol.gitbook.io/stargate/interfaces/evm-solidity-interfaces/istargaterouter.sol

// solhint-disable func-name-mixedcase,contract-name-camelcase,max-line-length

pragma solidity 0.8.19;

interface IStargateRouter {
    struct lzTxObj {
        uint256 dstGasForCall;
        uint256 dstNativeAmount;
        bytes dstNativeAddr;
    }

    /// @param _dstChainId the destination chain id
    /// @param _srcPoolId the source Stargate poolId
    /// @param _dstPoolId the destination Stargate poolId
    /// @param _refundAddress refund address. if msg.sender pays too much gas, return extra eth
    /// @param _amountLD total tokens to send to destination chain
    /// @param _minAmountLD min amount allowed out
    /// @param _lzTxParams default lzTxObj
    /// @param _to destination address, the sgReceive() implementer
    /// @param _payload bytes payload
    function swap(
        uint16 _dstChainId,
        uint256 _srcPoolId,
        uint256 _dstPoolId,
        address payable _refundAddress,
        uint256 _amountLD,
        uint256 _minAmountLD,
        lzTxObj memory _lzTxParams,
        bytes calldata _to,
        bytes calldata _payload
    ) external payable;

    function redeemRemote(
        uint16 _dstChainId,
        uint256 _srcPoolId,
        uint256 _dstPoolId,
        address payable _refundAddress,
        uint256 _amountLP,
        uint256 _minAmountLD,
        bytes calldata _to,
        lzTxObj memory _lzTxParams
    ) external payable;

    function instantRedeemLocal(uint16 _srcPoolId, uint256 _amountLP, address _to) external returns (uint256);

    function redeemLocal(
        uint16 _dstChainId,
        uint256 _srcPoolId,
        uint256 _dstPoolId,
        address payable _refundAddress,
        uint256 _amountLP,
        bytes calldata _to,
        lzTxObj memory _lzTxParams
    ) external payable;

    function sendCredits(
        uint16 _dstChainId,
        uint256 _srcPoolId,
        uint256 _dstPoolId,
        address payable _refundAddress
    ) external payable;

    function quoteLayerZeroFee(
        uint16 _dstChainId,
        uint8 _functionType,
        bytes calldata _toAddress,
        bytes calldata _transferAndCallPayload,
        lzTxObj memory _lzTxParams
    ) external view returns (uint256, uint256);
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

interface ITokenKeeper {
    /*///////////////////////////////////////////////////////////////
                                EVENTS
    ///////////////////////////////////////////////////////////////*/

    event BridgedTokensReceived(address indexed account, address indexed token, uint256 amount);

    event ZapSet(address indexed zap);

    event StargateReceiverSet(address indexed receiver);

    event TokenTransferred(address indexed from, address indexed to, address indexed token, uint256 amount);

    /*///////////////////////////////////////////////////////////////
    											VIEW FUNCTIONS
    ///////////////////////////////////////////////////////////////*/

    /**
     * @notice Returns an account's balance for a specific token
     *  @param _account The address of the account
     *  @param _token The address of the token
     * @return The account's token balance
     */
    function balances(address _account, address _token) external returns (uint256);

    /*///////////////////////////////////////////////////////////////
    											SETTER FUNCTIONS
    ///////////////////////////////////////////////////////////////*/

    /**
     * @notice Sets both Zap and StargateReceiver addresses
     *  @param _zap The Zap contract address
     *  @param _receiver The StargateReceiver contract address
     */
    function setZapAndStargateReceiver(address _zap, address _receiver) external;

    /**
     * @notice Sets the Zap address
     *  @param _zap The Zap contract address
     */
    function setZap(address _zap) external;

    /**
     * @notice Sets the StargateReceiver address
     *  @param _receiver The StargateReceiver contract address
     */
    function setStargateReceiver(address _receiver) external;

    /*///////////////////////////////////////////////////////////////
    											MUTATIVE FUNCTIONS
    ///////////////////////////////////////////////////////////////*/

    /**
     * @notice Transfers and registers the bridged tokens for an account
     *  @param _account The address of the account
     *  @param _token The address of the token
     *  @param _amount The bridged amount
     */
    function transferFromStargateReceiver(address _account, address _token, uint256 _amount) external;

    /**
     * @notice Transfers tokens to Zap contract for an account
     *  @param _token The address of the token
     *  @param _account The address of the account
     *  @return The transferred amount
     */
    function pullToken(address _token, address _account) external returns (uint256);

    /**
     * @notice Allows an account to withdraw their token balance
     *  @param _token The address of the token
     *  @return The transferred amount
     */
    function withdraw(address _token) external returns (uint256);
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

import { SwapParams } from "src/swapper/AsyncSwapper.sol";

interface IZap {
    /*///////////////////////////////////////////////////////////////
                                ERRORS
    ///////////////////////////////////////////////////////////////*/

    error DelegateSwapFailed();

    error PoolNotRegistered();

    error WrongPoolToken();

    error WrongAmount();

    error InvalidChainId();

    /*///////////////////////////////////////////////////////////////
                                EVENTS
    ///////////////////////////////////////////////////////////////*/

    event StargateDestinationsSet(uint16[] chainIds, address[] destinations);

    /*///////////////////////////////////////////////////////////////
                          MUTATIVE FUNCTIONS
    ///////////////////////////////////////////////////////////////*/

    /**
     * @notice Wrapper function calling the stakeFor function of a Pool contract
     * Pulls the funds from msg.sender
     *  @param _pool The pool address
     *  @param _amount The stake amount
     */
    function stake(address _pool, uint256 _amount) external;

    /**
     * @notice Wrapper function calling the stakeFor function of a Pool contract
     * Pulls the funds from the TokenKeeper contract
     *  @param _pool The pool address
     */
    function stakeFromBridge(address _pool) external;

    /**
     * @notice Swaps a token for another using the swapper then stakes it in the pool
     *  @param _swapParams A struct containing all necessary params allowing a token swap
     *  @param _pool The pool address
     */
    function swapAndStake(SwapParams memory _swapParams, address _pool) external;

    /**
     * @notice Swaps a token for another using the swapper then stakes it in the pool
     * Pulls the funds from the TokenKeeper contract
     *  @param _swapParams A struct containing all necessary params allowing a token swap
     *  @param _pool The pool address
     */
    function swapAndStakeFromBridge(SwapParams memory _swapParams, address _pool) external;

    /**
     *  @notice Swaps a token for another using the swapper then bridges it
     *  @param _swapParams A struct containing all necessary params allowing a token swap
     *  @param _minAmount The minimum amount of bridged tokens caller is willing to accept
     *  @param _dstChainId The destination chain ID
     *  @param _srcPoolId The source pool ID
     *  @param _dstPoolId The destination pool ID
     *  @param _dstAccount The destination account
     */
    function swapAndBridge(
        SwapParams memory _swapParams,
        uint256 _minAmount,
        uint16 _dstChainId,
        uint256 _srcPoolId,
        uint256 _dstPoolId,
        address _dstAccount
    ) external payable;

    /**
     * @notice Bridges tokens to a specific chain using Stargate
     *  @param _token The token address
     *  @param _amount The amount of token to bridge
     *  @param _minAmount The minimum amount of bridged tokens caller is willing to accept
     *  @param _dstChainId The destination chain ID
     *  @param _srcPoolId The source pool ID
     *  @param _dstPoolId The destination pool ID
     *  @param _dstAccount The destination account
     */
    function bridge(
        address _token,
        uint256 _amount,
        uint256 _minAmount,
        uint16 _dstChainId,
        uint256 _srcPoolId,
        uint256 _dstPoolId,
        address _dstAccount
    ) external payable;

    /*///////////////////////////////////////////////////////////////
                            SETTERS
    ///////////////////////////////////////////////////////////////*/

    /// @notice Configure our Stargate receivers on destination chains
    /// @dev Arrays are expected to be index synced
    /// @param _chainIds List of Stargate chain ids to configure
    /// @param _destinations List of our receivers on chain id
    function setStargateDestinations(uint16[] calldata _chainIds, address[] calldata _destinations) external;
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

library Error {
    error AlreadyInitialized();
    error ZeroAddress();
    error ZeroAmount();
    error ArrayLengthMismatch();
    error AddFailed();
    error RemoveFailed();
    error Unauthorized();
    error UnknownTemplate();
    error DeployerNotFound();
    error PoolNotRejected();
    error PoolNotApproved();
    error DepositsDisabled();
    error WithdrawalsDisabled();
    error InsufficientBalance();
    error MaxStakePerAddressExceeded();
    error MaxStakePerPoolExceeded();
    error FeeTooHigh();
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

import { IERC20 } from "openzeppelin-contracts/contracts/token/ERC20/IERC20.sol";
import { SafeERC20 } from "openzeppelin-contracts/contracts/token/ERC20/utils/SafeERC20.sol";

library ERC20Utils {
    using SafeERC20 for IERC20;

    function _approve(IERC20 _token, address _spender, uint256 _amount) internal {
        uint256 currentAllowance = _token.allowance(address(this), _spender);
        if (currentAllowance > 0) {
            _token.safeDecreaseAllowance(_spender, currentAllowance);
        }
        _token.safeIncreaseAllowance(_spender, _amount);
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.9.0) (utils/Address.sol)

pragma solidity ^0.8.19;

/**
 * @dev Collection of functions related to the address type
 */
library Address {
    /**
     * @dev The ETH balance of the account is not enough to perform the operation.
     */
    error AddressInsufficientBalance(address account);

    /**
     * @dev There's no code at `target` (it is not a contract).
     */
    error AddressEmptyCode(address target);

    /**
     * @dev A call to an address target failed. The target may have reverted.
     */
    error FailedInnerCall();

    /**
     * @dev Replacement for Solidity's `transfer`: sends `amount` wei to
     * `recipient`, forwarding all available gas and reverting on errors.
     *
     * https://eips.ethereum.org/EIPS/eip-1884[EIP1884] increases the gas cost
     * of certain opcodes, possibly making contracts go over the 2300 gas limit
     * imposed by `transfer`, making them unable to receive funds via
     * `transfer`. {sendValue} removes this limitation.
     *
     * https://consensys.net/diligence/blog/2019/09/stop-using-soliditys-transfer-now/[Learn more].
     *
     * IMPORTANT: because control is transferred to `recipient`, care must be
     * taken to not create reentrancy vulnerabilities. Consider using
     * {ReentrancyGuard} or the
     * https://solidity.readthedocs.io/en/v0.8.0/security-considerations.html#use-the-checks-effects-interactions-pattern[checks-effects-interactions pattern].
     */
    function sendValue(address payable recipient, uint256 amount) internal {
        if (address(this).balance < amount) {
            revert AddressInsufficientBalance(address(this));
        }

        (bool success, ) = recipient.call{value: amount}("");
        if (!success) {
            revert FailedInnerCall();
        }
    }

    /**
     * @dev Performs a Solidity function call using a low level `call`. A
     * plain `call` is an unsafe replacement for a function call: use this
     * function instead.
     *
     * If `target` reverts with a revert reason, it is bubbled up by this
     * function (like regular Solidity function calls).
     *
     * Returns the raw returned data. To convert to the expected return value,
     * use https://solidity.readthedocs.io/en/latest/units-and-global-variables.html?highlight=abi.decode#abi-encoding-and-decoding-functions[`abi.decode`].
     *
     * Requirements:
     *
     * - `target` must be a contract.
     * - calling `target` with `data` must not revert.
     */
    function functionCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionCallWithValue(target, data, 0, defaultRevert);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`], but with a
     * `customRevert` function as a fallback when `target` reverts.
     *
     * Requirements:
     *
     * - `customRevert` must be a reverting function.
     */
    function functionCall(
        address target,
        bytes memory data,
        function() internal view customRevert
    ) internal returns (bytes memory) {
        return functionCallWithValue(target, data, 0, customRevert);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but also transferring `value` wei to `target`.
     *
     * Requirements:
     *
     * - the calling contract must have an ETH balance of at least `value`.
     * - the called Solidity function must be `payable`.
     */
    function functionCallWithValue(address target, bytes memory data, uint256 value) internal returns (bytes memory) {
        return functionCallWithValue(target, data, value, defaultRevert);
    }

    /**
     * @dev Same as {xref-Address-functionCallWithValue-address-bytes-uint256-}[`functionCallWithValue`], but
     * with a `customRevert` function as a fallback revert reason when `target` reverts.
     *
     * Requirements:
     *
     * - `customRevert` must be a reverting function.
     */
    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value,
        function() internal view customRevert
    ) internal returns (bytes memory) {
        if (address(this).balance < value) {
            revert AddressInsufficientBalance(address(this));
        }
        (bool success, bytes memory returndata) = target.call{value: value}(data);
        return verifyCallResultFromTarget(target, success, returndata, customRevert);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a static call.
     */
    function functionStaticCall(address target, bytes memory data) internal view returns (bytes memory) {
        return functionStaticCall(target, data, defaultRevert);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a static call.
     */
    function functionStaticCall(
        address target,
        bytes memory data,
        function() internal view customRevert
    ) internal view returns (bytes memory) {
        (bool success, bytes memory returndata) = target.staticcall(data);
        return verifyCallResultFromTarget(target, success, returndata, customRevert);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a delegate call.
     */
    function functionDelegateCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionDelegateCall(target, data, defaultRevert);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a delegate call.
     */
    function functionDelegateCall(
        address target,
        bytes memory data,
        function() internal view customRevert
    ) internal returns (bytes memory) {
        (bool success, bytes memory returndata) = target.delegatecall(data);
        return verifyCallResultFromTarget(target, success, returndata, customRevert);
    }

    /**
     * @dev Tool to verify that a low level call to smart-contract was successful, and revert (either by bubbling
     * the revert reason or using the provided `customRevert`) in case of unsuccessful call or if target was not a contract.
     */
    function verifyCallResultFromTarget(
        address target,
        bool success,
        bytes memory returndata,
        function() internal view customRevert
    ) internal view returns (bytes memory) {
        if (success) {
            if (returndata.length == 0) {
                // only check if target is a contract if the call was successful and the return data is empty
                // otherwise we already know that it was a contract
                if (target.code.length == 0) {
                    revert AddressEmptyCode(target);
                }
            }
            return returndata;
        } else {
            _revert(returndata, customRevert);
        }
    }

    /**
     * @dev Tool to verify that a low level call was successful, and revert if it wasn't, either by bubbling the
     * revert reason or with a default revert error.
     */
    function verifyCallResult(bool success, bytes memory returndata) internal view returns (bytes memory) {
        return verifyCallResult(success, returndata, defaultRevert);
    }

    /**
     * @dev Same as {xref-Address-verifyCallResult-bool-bytes-}[`verifyCallResult`], but with a
     * `customRevert` function as a fallback when `success` is `false`.
     *
     * Requirements:
     *
     * - `customRevert` must be a reverting function.
     */
    function verifyCallResult(
        bool success,
        bytes memory returndata,
        function() internal view customRevert
    ) internal view returns (bytes memory) {
        if (success) {
            return returndata;
        } else {
            _revert(returndata, customRevert);
        }
    }

    /**
     * @dev Default reverting function when no `customRevert` is provided in a function call.
     */
    function defaultRevert() internal pure {
        revert FailedInnerCall();
    }

    function _revert(bytes memory returndata, function() internal view customRevert) private view {
        // Look for revert reason and bubble it up if present
        if (returndata.length > 0) {
            // The easiest way to bubble the revert reason is using memory via assembly
            /// @solidity memory-safe-assembly
            assembly {
                let returndata_size := mload(returndata)
                revert(add(32, returndata), returndata_size)
            }
        } else {
            customRevert();
            revert FailedInnerCall();
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.9.0) (token/ERC20/IERC20.sol)

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
// OpenZeppelin Contracts (last updated v4.9.0) (token/ERC20/utils/SafeERC20.sol)

pragma solidity ^0.8.19;

import {IERC20} from "../IERC20.sol";
import {IERC20Permit} from "../extensions/IERC20Permit.sol";
import {Address} from "../../../utils/Address.sol";

/**
 * @title SafeERC20
 * @dev Wrappers around ERC20 operations that throw on failure (when the token
 * contract returns false). Tokens that return no value (and instead revert or
 * throw on failure) are also supported, non-reverting calls are assumed to be
 * successful.
 * To use this library you can add a `using SafeERC20 for IERC20;` statement to your contract,
 * which allows you to call the safe operations as `token.safeTransfer(...)`, etc.
 */
library SafeERC20 {
    using Address for address;

    /**
     * @dev An operation with an ERC20 token failed.
     */
    error SafeERC20FailedOperation(address token);

    /**
     * @dev Indicates a failed `decreaseAllowance` request.
     */
    error SafeERC20FailedDecreaseAllowance(address spender, uint256 currentAllowance, uint256 requestedDecrease);

    /**
     * @dev Transfer `value` amount of `token` from the calling contract to `to`. If `token` returns no value,
     * non-reverting calls are assumed to be successful.
     */
    function safeTransfer(IERC20 token, address to, uint256 value) internal {
        _callOptionalReturn(token, abi.encodeCall(token.transfer, (to, value)));
    }

    /**
     * @dev Transfer `value` amount of `token` from `from` to `to`, spending the approval given by `from` to the
     * calling contract. If `token` returns no value, non-reverting calls are assumed to be successful.
     */
    function safeTransferFrom(IERC20 token, address from, address to, uint256 value) internal {
        _callOptionalReturn(token, abi.encodeCall(token.transferFrom, (from, to, value)));
    }

    /**
     * @dev Increase the calling contract's allowance toward `spender` by `value`. If `token` returns no value,
     * non-reverting calls are assumed to be successful.
     */
    function safeIncreaseAllowance(IERC20 token, address spender, uint256 value) internal {
        uint256 oldAllowance = token.allowance(address(this), spender);
        forceApprove(token, spender, oldAllowance + value);
    }

    /**
     * @dev Decrease the calling contract's allowance toward `spender` by `requestedDecrease`. If `token` returns no value,
     * non-reverting calls are assumed to be successful.
     */
    function safeDecreaseAllowance(IERC20 token, address spender, uint256 requestedDecrease) internal {
        unchecked {
            uint256 currentAllowance = token.allowance(address(this), spender);
            if (currentAllowance < requestedDecrease) {
                revert SafeERC20FailedDecreaseAllowance(spender, currentAllowance, requestedDecrease);
            }
            forceApprove(token, spender, currentAllowance - requestedDecrease);
        }
    }

    /**
     * @dev Set the calling contract's allowance toward `spender` to `value`. If `token` returns no value,
     * non-reverting calls are assumed to be successful. Meant to be used with tokens that require the approval
     * to be set to zero before setting it to a non-zero value, such as USDT.
     */
    function forceApprove(IERC20 token, address spender, uint256 value) internal {
        bytes memory approvalCall = abi.encodeCall(token.approve, (spender, value));

        if (!_callOptionalReturnBool(token, approvalCall)) {
            _callOptionalReturn(token, abi.encodeCall(token.approve, (spender, 0)));
            _callOptionalReturn(token, approvalCall);
        }
    }

    /**
     * @dev Use a ERC-2612 signature to set the `owner` approval toward `spender` on `token`.
     * Revert on invalid signature.
     */
    function safePermit(
        IERC20Permit token,
        address owner,
        address spender,
        uint256 value,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) internal {
        uint256 nonceBefore = token.nonces(owner);
        token.permit(owner, spender, value, deadline, v, r, s);
        uint256 nonceAfter = token.nonces(owner);
        if (nonceAfter != nonceBefore + 1) {
            revert SafeERC20FailedOperation(address(token));
        }
    }

    /**
     * @dev Imitates a Solidity high-level call (i.e. a regular function call to a contract), relaxing the requirement
     * on the return value: the return value is optional (but if data is returned, it must not be false).
     * @param token The token targeted by the call.
     * @param data The call data (encoded using abi.encode or one of its variants).
     */
    function _callOptionalReturn(IERC20 token, bytes memory data) private {
        // We need to perform a low level call here, to bypass Solidity's return data size checking mechanism, since
        // we're implementing it ourselves. We use {Address-functionCall} to perform this call, which verifies that
        // the target address contains contract code and also asserts for success in the low-level call.

        bytes memory returndata = address(token).functionCall(data);
        if (returndata.length != 0 && !abi.decode(returndata, (bool))) {
            revert SafeERC20FailedOperation(address(token));
        }
    }

    /**
     * @dev Imitates a Solidity high-level call (i.e. a regular function call to a contract), relaxing the requirement
     * on the return value: the return value is optional (but if data is returned, it must not be false).
     * @param token The token targeted by the call.
     * @param data The call data (encoded using abi.encode or one of its variants).
     *
     * This is a variant of {_callOptionalReturn} that silents catches all reverts and returns a bool instead.
     */
    function _callOptionalReturnBool(IERC20 token, bytes memory data) private returns (bool) {
        // We need to perform a low level call here, to bypass Solidity's return data size checking mechanism, since
        // we're implementing it ourselves. We cannot use {Address-functionCall} here since this should return false
        // and not revert is the subcall reverts.

        (bool success, bytes memory returndata) = address(token).call(data);
        return success && (returndata.length == 0 || abi.decode(returndata, (bool))) && address(token).code.length > 0;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.9.0) (access/Ownable2Step.sol)

pragma solidity ^0.8.19;

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
pragma solidity 0.8.19;

import { IERC20 } from "openzeppelin-contracts/contracts/token/ERC20/IERC20.sol";
import { ReentrancyGuard } from "openzeppelin-contracts/contracts/security/ReentrancyGuard.sol";

import { IAsyncSwapper, SwapParams } from "src/interfaces/swapper/IAsyncSwapper.sol";
import { Error } from "src/librairies/Error.sol";
import { ERC20Utils } from "src/librairies/ERC20Utils.sol";

contract AsyncSwapper is IAsyncSwapper, ReentrancyGuard {
    address public immutable aggregator;

    constructor(address _aggregator) {
        if (_aggregator == address(0)) revert Error.ZeroAddress();
        aggregator = _aggregator;
    }

    /// @inheritdoc IAsyncSwapper
    function swap(SwapParams memory swapParams)
        public
        payable
        virtual
        nonReentrant
        returns (uint256 buyTokenAmountReceived)
    {
        if (swapParams.buyTokenAddress == address(0)) revert Error.ZeroAddress();
        if (swapParams.sellTokenAddress == address(0)) revert Error.ZeroAddress();
        if (swapParams.sellAmount == 0) revert Error.ZeroAmount();
        if (swapParams.buyAmount == 0) revert Error.ZeroAmount();

        IERC20 sellToken = IERC20(swapParams.sellTokenAddress);
        IERC20 buyToken = IERC20(swapParams.buyTokenAddress);

        uint256 sellTokenBalance = sellToken.balanceOf(address(this));

        if (sellTokenBalance < swapParams.sellAmount) revert Error.InsufficientBalance();

        ERC20Utils._approve(sellToken, aggregator, swapParams.sellAmount);

        uint256 buyTokenBalanceBefore = buyToken.balanceOf(address(this));

        // we don't need the returned value, we calculate the buyTokenAmountReceived ourselves
        // slither-disable-start low-level-calls,unchecked-lowlevel
        // solhint-disable-next-line avoid-low-level-calls
        (bool success,) = aggregator.call(swapParams.data);
        // slither-disable-end low-level-calls,unchecked-lowlevel

        if (!success) revert SwapFailed();

        uint256 buyTokenBalanceAfter = buyToken.balanceOf(address(this));
        buyTokenAmountReceived = buyTokenBalanceAfter - buyTokenBalanceBefore;

        if (buyTokenAmountReceived < swapParams.buyAmount) {
            revert InsufficientBuyAmountReceived(address(buyToken), buyTokenAmountReceived, swapParams.buyAmount);
        }

        emit Swapped(
            swapParams.sellTokenAddress,
            swapParams.buyTokenAddress,
            swapParams.sellAmount,
            swapParams.buyAmount,
            buyTokenAmountReceived
        );

        return buyTokenAmountReceived;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.9.0) (token/ERC20/extensions/IERC20Permit.sol)

pragma solidity ^0.8.19;

/**
 * @dev Interface of the ERC20 Permit extension allowing approvals to be made via signatures, as defined in
 * https://eips.ethereum.org/EIPS/eip-2612[EIP-2612].
 *
 * Adds the {permit} method, which can be used to change an account's ERC20 allowance (see {IERC20-allowance}) by
 * presenting a message signed by the account. By not relying on {IERC20-approve}, the token holder account doesn't
 * need to send a transaction, and thus is not required to hold Ether at all.
 */
interface IERC20Permit {
    /**
     * @dev Sets `value` as the allowance of `spender` over ``owner``'s tokens,
     * given ``owner``'s signed approval.
     *
     * IMPORTANT: The same issues {IERC20-approve} has related to transaction
     * ordering also apply here.
     *
     * Emits an {Approval} event.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     * - `deadline` must be a timestamp in the future.
     * - `v`, `r` and `s` must be a valid `secp256k1` signature from `owner`
     * over the EIP712-formatted function arguments.
     * - the signature must use ``owner``'s current nonce (see {nonces}).
     *
     * For more information on the signature format, see the
     * https://eips.ethereum.org/EIPS/eip-2612#specification[relevant EIP
     * section].
     */
    function permit(
        address owner,
        address spender,
        uint256 value,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external;

    /**
     * @dev Returns the current nonce for `owner`. This value must be
     * included whenever a signature is generated for {permit}.
     *
     * Every successful call to {permit} increases ``owner``'s nonce by one. This
     * prevents a signature from being used multiple times.
     */
    function nonces(address owner) external view returns (uint256);

    /**
     * @dev Returns the domain separator used in the encoding of the signature for {permit}, as defined by {EIP712}.
     */
    // solhint-disable-next-line func-name-mixedcase
    function DOMAIN_SEPARATOR() external view returns (bytes32);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.9.0) (access/Ownable.sol)

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

pragma solidity ^0.8.19;

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

    /**
     * @dev Unauthorized reentrant call.
     */
    error ReentrancyGuardReentrantCall();

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
        if (_status == _ENTERED) {
            revert ReentrancyGuardReentrantCall();
        }

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
// OpenZeppelin Contracts v4.4.1 (utils/Context.sol)

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
}