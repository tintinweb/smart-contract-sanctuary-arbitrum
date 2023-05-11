// SPDX-License-Identifier: GPL-2.0-or-later

pragma solidity ^0.7.6;
pragma abicoder v2;

import { SafeMath } from "@openzeppelin/contracts/math/SafeMath.sol";
import { Staking } from "../../staking/Staking.sol";
import { IL2StakingBase } from "./IL2StakingBase.sol";
import { IL2Staking } from "./IL2Staking.sol";
import { Stakes } from "../../staking/libs/Stakes.sol";

/**
 * @title L2Staking contract
 * @dev This contract is the L2 variant of the Staking contract. It adds a function
 * to receive an indexer's stake or delegation from L1. Note that this contract inherits Staking,
 * which uses a StakingExtension contract to implement the full IStaking interface through delegatecalls.
 */
contract L2Staking is Staking, IL2StakingBase {
    using SafeMath for uint256;
    using Stakes for Stakes.Indexer;

    /**
     * @dev Emitted when `delegator` delegated `tokens` to the `indexer`, the delegator
     * gets `shares` for the delegation pool proportionally to the tokens staked.
     * This is copied from IStakingExtension, but we can't inherit from it because we
     * don't implement the full interface here.
     */
    event StakeDelegated(
        address indexed indexer,
        address indexed delegator,
        uint256 tokens,
        uint256 shares
    );

    /**
     * @dev Checks that the sender is the L2GraphTokenGateway as configured on the Controller.
     */
    modifier onlyL2Gateway() {
        require(msg.sender == address(graphTokenGateway()), "ONLY_GATEWAY");
        _;
    }

    /**
     * @notice Receive ETH into the L2Staking contract: this will always revert
     * @dev This function is only here to prevent ETH from being sent to the contract
     */
    receive() external payable {
        revert("RECEIVE_ETH_NOT_ALLOWED");
    }

    /**
     * @notice Receive tokens with a callhook from the bridge.
     * @dev The encoded _data can contain information about an indexer's stake
     * or a delegator's delegation.
     * See L1MessageCodes in IL2Staking for the supported messages.
     * @param _from Token sender in L1
     * @param _amount Amount of tokens that were transferred
     * @param _data ABI-encoded callhook data which must include a uint8 code and either a ReceiveIndexerStakeData or ReceiveDelegationData struct.
     */
    function onTokenTransfer(
        address _from,
        uint256 _amount,
        bytes calldata _data
    ) external override notPartialPaused onlyL2Gateway {
        require(_from == counterpartStakingAddress, "ONLY_L1_STAKING_THROUGH_BRIDGE");
        (uint8 code, bytes memory functionData) = abi.decode(_data, (uint8, bytes));

        if (code == uint8(IL2Staking.L1MessageCodes.RECEIVE_INDEXER_STAKE_CODE)) {
            IL2Staking.ReceiveIndexerStakeData memory indexerData = abi.decode(
                functionData,
                (IL2Staking.ReceiveIndexerStakeData)
            );
            _receiveIndexerStake(_amount, indexerData);
        } else if (code == uint8(IL2Staking.L1MessageCodes.RECEIVE_DELEGATION_CODE)) {
            IL2Staking.ReceiveDelegationData memory delegationData = abi.decode(
                functionData,
                (IL2Staking.ReceiveDelegationData)
            );
            _receiveDelegation(_amount, delegationData);
        } else {
            revert("INVALID_CODE");
        }
    }

    /**
     * @dev Receive an Indexer's stake from L1.
     * The specified amount is added to the indexer's stake; the indexer's
     * address is specified in the _indexerData struct.
     * @param _amount Amount of tokens that were transferred
     * @param _indexerData struct containing the indexer's address
     */
    function _receiveIndexerStake(
        uint256 _amount,
        IL2Staking.ReceiveIndexerStakeData memory _indexerData
    ) internal {
        address _indexer = _indexerData.indexer;
        // Deposit tokens into the indexer stake
        __stakes[_indexer].deposit(_amount);

        // Initialize the delegation pool the first time
        if (__delegationPools[_indexer].updatedAtBlock == 0) {
            _setDelegationParameters(_indexer, MAX_PPM, MAX_PPM, __delegationParametersCooldown);
        }

        emit StakeDeposited(_indexer, _amount);
    }

    /**
     * @dev Receive a Delegator's delegation from L1.
     * The specified amount is added to the delegator's delegation; the delegator's
     * address and the indexer's address are specified in the _delegationData struct.
     * Note that no delegation tax is applied here.
     * @param _amount Amount of tokens that were transferred
     * @param _delegationData struct containing the delegator's address and the indexer's address
     */
    function _receiveDelegation(
        uint256 _amount,
        IL2Staking.ReceiveDelegationData memory _delegationData
    ) internal {
        // Get the delegation pool of the indexer
        DelegationPool storage pool = __delegationPools[_delegationData.indexer];
        Delegation storage delegation = pool.delegators[_delegationData.delegator];

        // Calculate shares to issue (without applying any delegation tax)
        uint256 shares = (pool.tokens == 0) ? _amount : _amount.mul(pool.shares).div(pool.tokens);

        if (shares == 0) {
            // If no shares would be issued (probably a rounding issue or attack), return the tokens to the delegator
            graphToken().transfer(_delegationData.delegator, _amount);
            emit TransferredDelegationReturnedToDelegator(
                _delegationData.indexer,
                _delegationData.delegator,
                _amount
            );
        } else {
            // Update the delegation pool
            pool.tokens = pool.tokens.add(_amount);
            pool.shares = pool.shares.add(shares);

            // Update the individual delegation
            delegation.shares = delegation.shares.add(shares);

            emit StakeDelegated(
                _delegationData.indexer,
                _delegationData.delegator,
                _amount,
                shares
            );
        }
    }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

/**
 * @dev Wrappers over Solidity's arithmetic operations with added overflow
 * checks.
 *
 * Arithmetic operations in Solidity wrap on overflow. This can easily result
 * in bugs, because programmers usually assume that an overflow raises an
 * error, which is the standard behavior in high level programming languages.
 * `SafeMath` restores this intuition by reverting the transaction when an
 * operation overflows.
 *
 * Using this library instead of the unchecked operations eliminates an entire
 * class of bugs, so it's recommended to use it always.
 */
library SafeMath {
    /**
     * @dev Returns the addition of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryAdd(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        uint256 c = a + b;
        if (c < a) return (false, 0);
        return (true, c);
    }

    /**
     * @dev Returns the substraction of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function trySub(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        if (b > a) return (false, 0);
        return (true, a - b);
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryMul(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
        // benefit is lost if 'b' is also tested.
        // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
        if (a == 0) return (true, 0);
        uint256 c = a * b;
        if (c / a != b) return (false, 0);
        return (true, c);
    }

    /**
     * @dev Returns the division of two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryDiv(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        if (b == 0) return (false, 0);
        return (true, a / b);
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryMod(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        if (b == 0) return (false, 0);
        return (true, a % b);
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
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");
        return c;
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
        require(b <= a, "SafeMath: subtraction overflow");
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
        if (a == 0) return 0;
        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");
        return c;
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting on
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
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b > 0, "SafeMath: division by zero");
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
        require(b > 0, "SafeMath: modulo by zero");
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
        require(b <= a, errorMessage);
        return a - b;
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting with custom message on
     * division by zero. The result is rounded towards zero.
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {tryDiv}.
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
        require(b > 0, errorMessage);
        return a / b;
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
        require(b > 0, errorMessage);
        return a % b;
    }
}

// SPDX-License-Identifier: GPL-2.0-or-later

pragma solidity ^0.7.6;
pragma abicoder v2;

import { SafeMath } from "@openzeppelin/contracts/math/SafeMath.sol";
import { ECDSA } from "@openzeppelin/contracts/cryptography/ECDSA.sol";

import { Multicall } from "../base/Multicall.sol";
import { GraphUpgradeable } from "../upgrades/GraphUpgradeable.sol";
import { TokenUtils } from "../utils/TokenUtils.sol";
import { IGraphToken } from "../token/IGraphToken.sol";
import { IStakingBase } from "./IStakingBase.sol";
import { StakingV3Storage } from "./StakingStorage.sol";
import { MathUtils } from "./libs/MathUtils.sol";
import { Rebates } from "./libs/Rebates.sol";
import { Stakes } from "./libs/Stakes.sol";
import { Managed } from "../governance/Managed.sol";
import { ICuration } from "../curation/ICuration.sol";
import { IRewardsManager } from "../rewards/IRewardsManager.sol";
import { StakingExtension } from "./StakingExtension.sol";

/**
 * @title Base Staking contract
 * @dev The Staking contract allows Indexers to Stake on Subgraphs. Indexers Stake by creating
 * Allocations on a Subgraph. It also allows Delegators to Delegate towards an Indexer. The
 * contract also has the slashing functionality.
 * The contract is abstract as the implementation that is deployed depends on each layer: L1Staking on mainnet
 * and L2Staking on Arbitrum.
 * Note that this contract delegates part of its functionality to a StakingExtension contract.
 * This is due to the 24kB contract size limit on Ethereum.
 */
abstract contract Staking is StakingV3Storage, GraphUpgradeable, IStakingBase, Multicall {
    using SafeMath for uint256;
    using Stakes for Stakes.Indexer;
    using Rebates for Rebates.Pool;

    /// @dev 100% in parts per million
    uint32 internal constant MAX_PPM = 1000000;

    // -- Events are declared in IStakingBase -- //

    /**
     * @notice Delegates the current call to the StakingExtension implementation.
     * @dev This function does not return to its internal call site, it will return directly to the
     * external caller.
     */
    // solhint-disable-next-line payable-fallback, no-complex-fallback
    fallback() external {
        require(_implementation() != address(0), "only through proxy");
        // solhint-disable-next-line no-inline-assembly
        assembly {
            // (a) get free memory pointer
            let ptr := mload(0x40)

            // (b) get address of the implementation
            // CAREFUL here: this only works because extensionImpl is the first variable in this slot
            // (otherwise we may have to apply an offset)
            let impl := and(sload(extensionImpl.slot), 0xffffffffffffffffffffffffffffffffffffffff)

            // (1) copy incoming call data
            calldatacopy(ptr, 0, calldatasize())

            // (2) forward call to logic contract
            let result := delegatecall(gas(), impl, ptr, calldatasize(), 0, 0)
            let size := returndatasize()

            // (3) retrieve return data
            returndatacopy(ptr, 0, size)

            // (4) forward return data back to caller
            switch result
            case 0 {
                revert(ptr, size)
            }
            default {
                return(ptr, size)
            }
        }
    }

    /**
     * @notice Initialize this contract.
     * @param _controller Address of the controller that manages this contract
     * @param _minimumIndexerStake Minimum amount of tokens that an indexer must stake
     * @param _thawingPeriod Number of epochs that tokens get locked after unstaking
     * @param _protocolPercentage Percentage of query fees that are burned as protocol fee (in PPM)
     * @param _curationPercentage Percentage of query fees that are given to curators (in PPM)
     * @param _channelDisputeEpochs The period in epochs that needs to pass before fees in rebate pool can be claimed
     * @param _maxAllocationEpochs The maximum number of epochs that an allocation can be active
     * @param _delegationUnbondingPeriod The period in epochs that tokens get locked after undelegating
     * @param _delegationRatio The ratio between an indexer's own stake and the delegation they can use
     * @param _rebateAlphaNumerator The numerator of the alpha factor used to calculate the rebate
     * @param _rebateAlphaDenominator The denominator of the alpha factor used to calculate the rebate
     * @param _extensionImpl Address of the StakingExtension implementation
     */
    function initialize(
        address _controller,
        uint256 _minimumIndexerStake,
        uint32 _thawingPeriod,
        uint32 _protocolPercentage,
        uint32 _curationPercentage,
        uint32 _channelDisputeEpochs,
        uint32 _maxAllocationEpochs,
        uint32 _delegationUnbondingPeriod,
        uint32 _delegationRatio,
        uint32 _rebateAlphaNumerator,
        uint32 _rebateAlphaDenominator,
        address _extensionImpl
    ) external override onlyImpl {
        Managed._initialize(_controller);

        // Settings
        _setMinimumIndexerStake(_minimumIndexerStake);
        _setThawingPeriod(_thawingPeriod);

        _setProtocolPercentage(_protocolPercentage);
        _setCurationPercentage(_curationPercentage);

        _setChannelDisputeEpochs(_channelDisputeEpochs);
        _setMaxAllocationEpochs(_maxAllocationEpochs);

        _setRebateRatio(_rebateAlphaNumerator, _rebateAlphaDenominator);

        extensionImpl = _extensionImpl;

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, ) = extensionImpl.delegatecall(
            abi.encodeWithSelector(
                StakingExtension.initialize.selector,
                _delegationUnbondingPeriod,
                0,
                _delegationRatio,
                0
            )
        );
        require(success, "Extension init failed");
        emit ExtensionImplementationSet(_extensionImpl);
    }

    /**
     * @notice Set the address of the StakingExtension implementation.
     * @dev This function can only be called by the governor.
     * @param _extensionImpl Address of the StakingExtension implementation
     */
    function setExtensionImpl(address _extensionImpl) external override onlyGovernor {
        extensionImpl = _extensionImpl;
        emit ExtensionImplementationSet(_extensionImpl);
    }

    /**
     * @notice Set the address of the counterpart (L1 or L2) staking contract.
     * @dev This function can only be called by the governor.
     * @param _counterpart Address of the counterpart staking contract in the other chain, without any aliasing.
     */
    function setCounterpartStakingAddress(address _counterpart) external override onlyGovernor {
        counterpartStakingAddress = _counterpart;
        emit ParameterUpdated("counterpartStakingAddress");
    }

    /**
     * @notice Set the minimum stake required to be an indexer.
     * @param _minimumIndexerStake Minimum indexer stake
     */
    function setMinimumIndexerStake(uint256 _minimumIndexerStake) external override onlyGovernor {
        _setMinimumIndexerStake(_minimumIndexerStake);
    }

    /**
     * @notice Set the thawing period for unstaking.
     * @param _thawingPeriod Period in blocks to wait for token withdrawals after unstaking
     */
    function setThawingPeriod(uint32 _thawingPeriod) external override onlyGovernor {
        _setThawingPeriod(_thawingPeriod);
    }

    /**
     * @notice Set the curation percentage of query fees sent to curators.
     * @param _percentage Percentage of query fees sent to curators
     */
    function setCurationPercentage(uint32 _percentage) external override onlyGovernor {
        _setCurationPercentage(_percentage);
    }

    /**
     * @notice Set a protocol percentage to burn when collecting query fees.
     * @param _percentage Percentage of query fees to burn as protocol fee
     */
    function setProtocolPercentage(uint32 _percentage) external override onlyGovernor {
        _setProtocolPercentage(_percentage);
    }

    /**
     * @notice Set the period in epochs that need to pass before fees in rebate pool can be claimed.
     * @param _channelDisputeEpochs Period in epochs
     */
    function setChannelDisputeEpochs(uint32 _channelDisputeEpochs) external override onlyGovernor {
        _setChannelDisputeEpochs(_channelDisputeEpochs);
    }

    /**
     * @notice Set the max time allowed for indexers to allocate on a subgraph
     * before others are allowed to close the allocation.
     * @param _maxAllocationEpochs Allocation duration limit in epochs
     */
    function setMaxAllocationEpochs(uint32 _maxAllocationEpochs) external override onlyGovernor {
        _setMaxAllocationEpochs(_maxAllocationEpochs);
    }

    /**
     * @notice Set the rebate ratio (fees to allocated stake).
     * @param _alphaNumerator Numerator of `alpha` in the cobb-douglas function
     * @param _alphaDenominator Denominator of `alpha` in the cobb-douglas function
     */
    function setRebateRatio(uint32 _alphaNumerator, uint32 _alphaDenominator)
        external
        override
        onlyGovernor
    {
        _setRebateRatio(_alphaNumerator, _alphaDenominator);
    }

    /**
     * @notice Set an address as allowed asset holder.
     * @param _assetHolder Address of allowed source for state channel funds
     * @param _allowed True if asset holder is allowed
     */
    function setAssetHolder(address _assetHolder, bool _allowed) external override onlyGovernor {
        require(_assetHolder != address(0), "!assetHolder");
        __assetHolders[_assetHolder] = _allowed;
        emit AssetHolderUpdate(msg.sender, _assetHolder, _allowed);
    }

    /**
     * @notice Authorize or unauthorize an address to be an operator for the caller.
     * @param _operator Address to authorize or unauthorize
     * @param _allowed Whether the operator is authorized or not
     */
    function setOperator(address _operator, bool _allowed) external override {
        require(_operator != msg.sender, "operator == sender");
        __operatorAuth[msg.sender][_operator] = _allowed;
        emit SetOperator(msg.sender, _operator, _allowed);
    }

    /**
     * @notice Deposit tokens on the indexer's stake.
     * The amount staked must be over the minimumIndexerStake.
     * @param _tokens Amount of tokens to stake
     */
    function stake(uint256 _tokens) external override {
        stakeTo(msg.sender, _tokens);
    }

    /**
     * @notice Unstake tokens from the indexer stake, lock them until the thawing period expires.
     * @dev NOTE: The function accepts an amount greater than the currently staked tokens.
     * If that happens, it will try to unstake the max amount of tokens it can.
     * The reason for this behaviour is to avoid time conditions while the transaction
     * is in flight.
     * @param _tokens Amount of tokens to unstake
     */
    function unstake(uint256 _tokens) external override notPartialPaused {
        address indexer = msg.sender;
        Stakes.Indexer storage indexerStake = __stakes[indexer];

        require(indexerStake.tokensStaked > 0, "!stake");

        // Tokens to lock is capped to the available tokens
        uint256 tokensToLock = MathUtils.min(indexerStake.tokensAvailable(), _tokens);
        require(tokensToLock > 0, "!stake-avail");

        // Ensure minimum stake
        uint256 newStake = indexerStake.tokensSecureStake().sub(tokensToLock);
        require(newStake == 0 || newStake >= __minimumIndexerStake, "!minimumIndexerStake");

        // Before locking more tokens, withdraw any unlocked ones if possible
        uint256 tokensToWithdraw = indexerStake.tokensWithdrawable();
        if (tokensToWithdraw > 0) {
            _withdraw(indexer);
        }

        // Update the indexer stake locking tokens
        indexerStake.lockTokens(tokensToLock, __thawingPeriod);

        emit StakeLocked(indexer, indexerStake.tokensLocked, indexerStake.tokensLockedUntil);
    }

    /**
     * @notice Withdraw indexer tokens once the thawing period has passed.
     */
    function withdraw() external override notPaused {
        _withdraw(msg.sender);
    }

    /**
     * @notice Set the destination where to send rewards for an indexer.
     * @param _destination Rewards destination address. If set to zero, rewards will be restaked
     */
    function setRewardsDestination(address _destination) external override {
        __rewardsDestination[msg.sender] = _destination;
        emit SetRewardsDestination(msg.sender, _destination);
    }

    /**
     * @notice Allocate available tokens to a subgraph deployment.
     * @param _subgraphDeploymentID ID of the SubgraphDeployment where tokens will be allocated
     * @param _tokens Amount of tokens to allocate
     * @param _allocationID The allocation identifier
     * @param _metadata IPFS hash for additional information about the allocation
     * @param _proof A 65-bytes Ethereum signed message of `keccak256(indexerAddress,allocationID)`
     */
    function allocate(
        bytes32 _subgraphDeploymentID,
        uint256 _tokens,
        address _allocationID,
        bytes32 _metadata,
        bytes calldata _proof
    ) external override notPaused {
        _allocate(msg.sender, _subgraphDeploymentID, _tokens, _allocationID, _metadata, _proof);
    }

    /**
     * @notice Allocate available tokens to a subgraph deployment from and indexer's stake.
     * The caller must be the indexer or the indexer's operator.
     * @param _indexer Indexer address to allocate funds from.
     * @param _subgraphDeploymentID ID of the SubgraphDeployment where tokens will be allocated
     * @param _tokens Amount of tokens to allocate
     * @param _allocationID The allocation identifier
     * @param _metadata IPFS hash for additional information about the allocation
     * @param _proof A 65-bytes Ethereum signed message of `keccak256(indexerAddress,allocationID)`
     */
    function allocateFrom(
        address _indexer,
        bytes32 _subgraphDeploymentID,
        uint256 _tokens,
        address _allocationID,
        bytes32 _metadata,
        bytes calldata _proof
    ) external override notPaused {
        _allocate(_indexer, _subgraphDeploymentID, _tokens, _allocationID, _metadata, _proof);
    }

    /**
     * @notice Close an allocation and free the staked tokens.
     * To be eligible for rewards a proof of indexing must be presented.
     * Presenting a bad proof is subject to slashable condition.
     * To opt out of rewards set _poi to 0x0
     * @param _allocationID The allocation identifier
     * @param _poi Proof of indexing submitted for the allocated period
     */
    function closeAllocation(address _allocationID, bytes32 _poi) external override notPaused {
        _closeAllocation(_allocationID, _poi);
    }

    /**
     * @notice Collect query fees from state channels and assign them to an allocation.
     * Funds received are only accepted from a valid sender.
     * @dev To avoid reverting on the withdrawal from channel flow this function will:
     * 1) Accept calls with zero tokens.
     * 2) Accept calls after an allocation passed the dispute period, in that case, all
     *    the received tokens are burned.
     * @param _tokens Amount of tokens to collect
     * @param _allocationID Allocation where the tokens will be assigned
     */
    function collect(uint256 _tokens, address _allocationID) external override {
        // Allocation identifier validation
        require(_allocationID != address(0), "!alloc");

        // The contract caller must be an authorized asset holder
        require(__assetHolders[msg.sender] == true, "!assetHolder");

        // Allocation must exist
        AllocationState allocState = _getAllocationState(_allocationID);
        require(allocState != AllocationState.Null, "!collect");

        // Get allocation
        Allocation storage alloc = __allocations[_allocationID];
        uint256 queryFees = _tokens;
        uint256 curationFees = 0;
        bytes32 subgraphDeploymentID = alloc.subgraphDeploymentID;

        // Process query fees only if non-zero amount
        if (queryFees > 0) {
            // Pull tokens to collect from the authorized sender
            IGraphToken graphToken = graphToken();
            TokenUtils.pullTokens(graphToken, msg.sender, _tokens);

            // -- Collect protocol tax --
            // If the Allocation is not active or closed we are going to charge a 100% protocol tax
            uint256 usedProtocolPercentage = (allocState == AllocationState.Active ||
                allocState == AllocationState.Closed)
                ? __protocolPercentage
                : MAX_PPM;
            uint256 protocolTax = _collectTax(graphToken, queryFees, usedProtocolPercentage);
            queryFees = queryFees.sub(protocolTax);

            // -- Collect curation fees --
            // Only if the subgraph deployment is curated
            curationFees = _collectCurationFees(
                graphToken,
                subgraphDeploymentID,
                queryFees,
                __curationPercentage
            );
            queryFees = queryFees.sub(curationFees);

            // Add funds to the allocation
            alloc.collectedFees = alloc.collectedFees.add(queryFees);

            // When allocation is closed redirect funds to the rebate pool
            // This way we can keep collecting tokens even after the allocation is closed and
            // before it gets to the finalized state.
            if (allocState == AllocationState.Closed) {
                Rebates.Pool storage rebatePool = __rebates[alloc.closedAtEpoch];
                rebatePool.fees = rebatePool.fees.add(queryFees);
            }
        }

        emit AllocationCollected(
            alloc.indexer,
            subgraphDeploymentID,
            epochManager().currentEpoch(),
            _tokens,
            _allocationID,
            msg.sender,
            curationFees,
            queryFees
        );
    }

    /**
     * @notice Claim tokens from the rebate pool.
     * @param _allocationID Allocation from where we are claiming tokens
     * @param _restake True if restake fees instead of transfer to indexer
     */
    function claim(address _allocationID, bool _restake) external override notPaused {
        _claim(_allocationID, _restake);
    }

    /**
     * @dev Claim tokens from the rebate pool for many allocations.
     * @param _allocationID Array of allocations from where we are claiming tokens
     * @param _restake True if restake fees instead of transfer to indexer
     */
    function claimMany(address[] calldata _allocationID, bool _restake)
        external
        override
        notPaused
    {
        for (uint256 i = 0; i < _allocationID.length; i++) {
            _claim(_allocationID[i], _restake);
        }
    }

    /**
     * @notice Return if allocationID is used.
     * @param _allocationID Address used as signer by the indexer for an allocation
     * @return True if allocationID already used
     */
    function isAllocation(address _allocationID) external view override returns (bool) {
        return _getAllocationState(_allocationID) != AllocationState.Null;
    }

    /**
     * @notice Getter that returns if an indexer has any stake.
     * @param _indexer Address of the indexer
     * @return True if indexer has staked tokens
     */
    function hasStake(address _indexer) external view override returns (bool) {
        return __stakes[_indexer].tokensStaked > 0;
    }

    /**
     * @notice Return the allocation by ID.
     * @param _allocationID Address used as allocation identifier
     * @return Allocation data
     */
    function getAllocation(address _allocationID)
        external
        view
        override
        returns (Allocation memory)
    {
        return __allocations[_allocationID];
    }

    /**
     * @notice Return the current state of an allocation
     * @param _allocationID Allocation identifier
     * @return AllocationState enum with the state of the allocation
     */
    function getAllocationState(address _allocationID)
        external
        view
        override
        returns (AllocationState)
    {
        return _getAllocationState(_allocationID);
    }

    /**
     * @notice Return the total amount of tokens allocated to subgraph.
     * @param _subgraphDeploymentID Deployment ID for the subgraph
     * @return Total tokens allocated to subgraph
     */
    function getSubgraphAllocatedTokens(bytes32 _subgraphDeploymentID)
        external
        view
        override
        returns (uint256)
    {
        return __subgraphAllocations[_subgraphDeploymentID];
    }

    /**
     * @notice Get the total amount of tokens staked by the indexer.
     * @param _indexer Address of the indexer
     * @return Amount of tokens staked by the indexer
     */
    function getIndexerStakedTokens(address _indexer) external view override returns (uint256) {
        return __stakes[_indexer].tokensStaked;
    }

    /**
     * @notice Deposit tokens on the Indexer stake, on behalf of the Indexer.
     * The amount staked must be over the minimumIndexerStake.
     * @param _indexer Address of the indexer
     * @param _tokens Amount of tokens to stake
     */
    function stakeTo(address _indexer, uint256 _tokens) public override notPartialPaused {
        require(_tokens > 0, "!tokens");

        // Transfer tokens to stake from caller to this contract
        TokenUtils.pullTokens(graphToken(), msg.sender, _tokens);

        // Stake the transferred tokens
        _stake(_indexer, _tokens);
    }

    /**
     * @notice Set the delegation parameters for the caller.
     * @param _indexingRewardCut Percentage of indexing rewards left for the indexer
     * @param _queryFeeCut Percentage of query fees left for the indexer
     * @param _cooldownBlocks Period that need to pass to update delegation parameters
     */
    function setDelegationParameters(
        uint32 _indexingRewardCut,
        uint32 _queryFeeCut,
        uint32 _cooldownBlocks
    ) public override {
        _setDelegationParameters(msg.sender, _indexingRewardCut, _queryFeeCut, _cooldownBlocks);
    }

    /**
     * @notice Get the total amount of tokens available to use in allocations.
     * This considers the indexer stake and delegated tokens according to delegation ratio
     * @param _indexer Address of the indexer
     * @return Amount of tokens available to allocate including delegation
     */
    function getIndexerCapacity(address _indexer) public view override returns (uint256) {
        Stakes.Indexer memory indexerStake = __stakes[_indexer];
        uint256 tokensDelegated = __delegationPools[_indexer].tokens;

        uint256 tokensDelegatedCap = indexerStake.tokensSecureStake().mul(
            uint256(__delegationRatio)
        );
        uint256 tokensDelegatedCapacity = MathUtils.min(tokensDelegated, tokensDelegatedCap);

        return indexerStake.tokensAvailableWithDelegation(tokensDelegatedCapacity);
    }

    /**
     * @notice Return true if operator is allowed for indexer.
     * @param _operator Address of the operator
     * @param _indexer Address of the indexer
     * @return True if operator is allowed for indexer, false otherwise
     */
    function isOperator(address _operator, address _indexer) public view override returns (bool) {
        return __operatorAuth[_indexer][_operator];
    }

    /**
     * @dev Internal: Set the minimum indexer stake required.
     * @param _minimumIndexerStake Minimum indexer stake
     */
    function _setMinimumIndexerStake(uint256 _minimumIndexerStake) private {
        require(_minimumIndexerStake > 0, "!minimumIndexerStake");
        __minimumIndexerStake = _minimumIndexerStake;
        emit ParameterUpdated("minimumIndexerStake");
    }

    /**
     * @dev Internal: Set the thawing period for unstaking.
     * @param _thawingPeriod Period in blocks to wait for token withdrawals after unstaking
     */
    function _setThawingPeriod(uint32 _thawingPeriod) private {
        require(_thawingPeriod > 0, "!thawingPeriod");
        __thawingPeriod = _thawingPeriod;
        emit ParameterUpdated("thawingPeriod");
    }

    /**
     * @dev Internal: Set the curation percentage of query fees sent to curators.
     * @param _percentage Percentage of query fees sent to curators
     */
    function _setCurationPercentage(uint32 _percentage) private {
        // Must be within 0% to 100% (inclusive)
        require(_percentage <= MAX_PPM, ">percentage");
        __curationPercentage = _percentage;
        emit ParameterUpdated("curationPercentage");
    }

    /**
     * @dev Internal: Set a protocol percentage to burn when collecting query fees.
     * @param _percentage Percentage of query fees to burn as protocol fee
     */
    function _setProtocolPercentage(uint32 _percentage) private {
        // Must be within 0% to 100% (inclusive)
        require(_percentage <= MAX_PPM, ">percentage");
        __protocolPercentage = _percentage;
        emit ParameterUpdated("protocolPercentage");
    }

    /**
     * @dev Internal: Set the period in epochs that need to pass before fees in rebate pool can be claimed.
     * @param _channelDisputeEpochs Period in epochs
     */
    function _setChannelDisputeEpochs(uint32 _channelDisputeEpochs) private {
        require(_channelDisputeEpochs > 0, "!channelDisputeEpochs");
        __channelDisputeEpochs = _channelDisputeEpochs;
        emit ParameterUpdated("channelDisputeEpochs");
    }

    /**
     * @dev Internal: Set the max time allowed for indexers stake on allocations.
     * @param _maxAllocationEpochs Allocation duration limit in epochs
     */
    function _setMaxAllocationEpochs(uint32 _maxAllocationEpochs) private {
        __maxAllocationEpochs = _maxAllocationEpochs;
        emit ParameterUpdated("maxAllocationEpochs");
    }

    /**
     * @dev Set the rebate ratio (fees to allocated stake).
     * @param _alphaNumerator Numerator of `alpha` in the cobb-douglas function
     * @param _alphaDenominator Denominator of `alpha` in the cobb-douglas function
     */
    function _setRebateRatio(uint32 _alphaNumerator, uint32 _alphaDenominator) private {
        require(_alphaNumerator > 0 && _alphaDenominator > 0, "!alpha");
        __alphaNumerator = _alphaNumerator;
        __alphaDenominator = _alphaDenominator;
        emit ParameterUpdated("rebateRatio");
    }

    /**
     * @dev Set the delegation parameters for a particular indexer.
     * @param _indexer Indexer to set delegation parameters
     * @param _indexingRewardCut Percentage of indexing rewards left for delegators
     * @param _queryFeeCut Percentage of query fees left for delegators
     * @param _cooldownBlocks Period that need to pass to update delegation parameters
     */
    function _setDelegationParameters(
        address _indexer,
        uint32 _indexingRewardCut,
        uint32 _queryFeeCut,
        uint32 _cooldownBlocks
    ) internal {
        // Incentives must be within bounds
        require(_queryFeeCut <= MAX_PPM, ">queryFeeCut");
        require(_indexingRewardCut <= MAX_PPM, ">indexingRewardCut");

        // Cooldown period set by indexer cannot be below protocol global setting
        require(_cooldownBlocks >= __delegationParametersCooldown, "<cooldown");

        // Verify the cooldown period passed
        DelegationPool storage pool = __delegationPools[_indexer];
        require(
            pool.updatedAtBlock == 0 ||
                pool.updatedAtBlock.add(uint256(pool.cooldownBlocks)) <= block.number,
            "!cooldown"
        );

        // Update delegation params
        pool.indexingRewardCut = _indexingRewardCut;
        pool.queryFeeCut = _queryFeeCut;
        pool.cooldownBlocks = _cooldownBlocks;
        pool.updatedAtBlock = block.number;

        emit DelegationParametersUpdated(
            _indexer,
            _indexingRewardCut,
            _queryFeeCut,
            _cooldownBlocks
        );
    }

    /**
     * @dev Stake tokens on the indexer.
     * This function does not check minimum indexer stake requirement to allow
     * to be called by functions that increase the stake when collecting rewards
     * without reverting
     * @param _indexer Address of staking party
     * @param _tokens Amount of tokens to stake
     */
    function _stake(address _indexer, uint256 _tokens) internal {
        // Ensure minimum stake
        require(
            __stakes[_indexer].tokensSecureStake().add(_tokens) >= __minimumIndexerStake,
            "!minimumIndexerStake"
        );

        // Deposit tokens into the indexer stake
        __stakes[_indexer].deposit(_tokens);

        // Initialize the delegation pool the first time
        if (__delegationPools[_indexer].updatedAtBlock == 0) {
            _setDelegationParameters(_indexer, MAX_PPM, MAX_PPM, __delegationParametersCooldown);
        }

        emit StakeDeposited(_indexer, _tokens);
    }

    /**
     * @dev Withdraw indexer tokens once the thawing period has passed.
     * @param _indexer Address of indexer to withdraw funds from
     */
    function _withdraw(address _indexer) private {
        // Get tokens available for withdraw and update balance
        uint256 tokensToWithdraw = __stakes[_indexer].withdrawTokens();
        require(tokensToWithdraw > 0, "!tokens");

        // Return tokens to the indexer
        TokenUtils.pushTokens(graphToken(), _indexer, tokensToWithdraw);

        emit StakeWithdrawn(_indexer, tokensToWithdraw);
    }

    /**
     * @dev Allocate available tokens to a subgraph deployment.
     * @param _indexer Indexer address to allocate funds from.
     * @param _subgraphDeploymentID ID of the SubgraphDeployment where tokens will be allocated
     * @param _tokens Amount of tokens to allocate
     * @param _allocationID The allocationID will work to identify collected funds related to this allocation
     * @param _metadata Metadata related to the allocation
     * @param _proof A 65-bytes Ethereum signed message of `keccak256(indexerAddress,allocationID)`
     */
    function _allocate(
        address _indexer,
        bytes32 _subgraphDeploymentID,
        uint256 _tokens,
        address _allocationID,
        bytes32 _metadata,
        bytes calldata _proof
    ) private {
        require(_isAuth(_indexer), "!auth");

        // Check allocation
        require(_allocationID != address(0), "!alloc");
        require(_getAllocationState(_allocationID) == AllocationState.Null, "!null");

        // Caller must prove that they own the private key for the allocationID address
        // The proof is an Ethereum signed message of KECCAK256(indexerAddress,allocationID)
        bytes32 messageHash = keccak256(abi.encodePacked(_indexer, _allocationID));
        bytes32 digest = ECDSA.toEthSignedMessageHash(messageHash);
        require(ECDSA.recover(digest, _proof) == _allocationID, "!proof");

        require(
            __stakes[_indexer].tokensSecureStake() >= __minimumIndexerStake,
            "!minimumIndexerStake"
        );
        if (_tokens > 0) {
            // Needs to have free capacity not used for other purposes to allocate
            require(getIndexerCapacity(_indexer) >= _tokens, "!capacity");
        }

        // Creates an allocation
        // Allocation identifiers are not reused
        // The assetHolder address can send collected funds to the allocation
        Allocation memory alloc = Allocation(
            _indexer,
            _subgraphDeploymentID,
            _tokens, // Tokens allocated
            epochManager().currentEpoch(), // createdAtEpoch
            0, // closedAtEpoch
            0, // Initialize collected fees
            0, // Initialize effective allocation
            (_tokens > 0) ? _updateRewards(_subgraphDeploymentID) : 0 // Initialize accumulated rewards per stake allocated
        );
        __allocations[_allocationID] = alloc;

        // -- Rewards Distribution --

        // Process non-zero-allocation rewards tracking
        if (_tokens > 0) {
            // Mark allocated tokens as used
            __stakes[_indexer].allocate(alloc.tokens);

            // Track total allocations per subgraph
            // Used for rewards calculations
            __subgraphAllocations[alloc.subgraphDeploymentID] = __subgraphAllocations[
                alloc.subgraphDeploymentID
            ].add(alloc.tokens);
        }

        emit AllocationCreated(
            _indexer,
            _subgraphDeploymentID,
            alloc.createdAtEpoch,
            alloc.tokens,
            _allocationID,
            _metadata
        );
    }

    /**
     * @dev Close an allocation and free the staked tokens.
     * @param _allocationID The allocation identifier
     * @param _poi Proof of indexing submitted for the allocated period
     */
    function _closeAllocation(address _allocationID, bytes32 _poi) private {
        // Allocation must exist and be active
        AllocationState allocState = _getAllocationState(_allocationID);
        require(allocState == AllocationState.Active, "!active");

        // Get allocation
        Allocation memory alloc = __allocations[_allocationID];

        // Validate that an allocation cannot be closed before one epoch
        alloc.closedAtEpoch = epochManager().currentEpoch();
        uint256 epochs = MathUtils.diffOrZero(alloc.closedAtEpoch, alloc.createdAtEpoch);
        require(epochs > 0, "<epochs");

        // Indexer or operator can close an allocation
        // Anyone is allowed to close ONLY under two concurrent conditions
        // - After maxAllocationEpochs passed
        // - When the allocation is for non-zero amount of tokens
        bool isIndexer = _isAuth(alloc.indexer);
        if (epochs <= __maxAllocationEpochs || alloc.tokens == 0) {
            require(isIndexer, "!auth");
        }

        // Close the allocation and start counting a period to settle remaining payments from
        // state channels.
        __allocations[_allocationID].closedAtEpoch = alloc.closedAtEpoch;

        // -- Rebate Pool --

        // Calculate effective allocation for the amount of epochs it remained allocated
        alloc.effectiveAllocation = _getEffectiveAllocation(
            __maxAllocationEpochs,
            alloc.tokens,
            epochs
        );
        __allocations[_allocationID].effectiveAllocation = alloc.effectiveAllocation;

        // Account collected fees and effective allocation in rebate pool for the epoch
        Rebates.Pool storage rebatePool = __rebates[alloc.closedAtEpoch];
        if (!rebatePool.exists()) {
            rebatePool.init(__alphaNumerator, __alphaDenominator);
        }
        rebatePool.addToPool(alloc.collectedFees, alloc.effectiveAllocation);

        // -- Rewards Distribution --

        // Process non-zero-allocation rewards tracking
        if (alloc.tokens > 0) {
            // Distribute rewards if proof of indexing was presented by the indexer or operator
            if (isIndexer && _poi != 0) {
                _distributeRewards(_allocationID, alloc.indexer);
            } else {
                _updateRewards(alloc.subgraphDeploymentID);
            }

            // Free allocated tokens from use
            __stakes[alloc.indexer].unallocate(alloc.tokens);

            // Track total allocations per subgraph
            // Used for rewards calculations
            __subgraphAllocations[alloc.subgraphDeploymentID] = __subgraphAllocations[
                alloc.subgraphDeploymentID
            ].sub(alloc.tokens);
        }

        emit AllocationClosed(
            alloc.indexer,
            alloc.subgraphDeploymentID,
            alloc.closedAtEpoch,
            alloc.tokens,
            _allocationID,
            alloc.effectiveAllocation,
            msg.sender,
            _poi,
            !isIndexer
        );
    }

    /**
     * @dev Claim tokens from the rebate pool.
     * @param _allocationID Allocation from where we are claiming tokens
     * @param _restake True if restake fees instead of transfer to indexer
     */
    function _claim(address _allocationID, bool _restake) private {
        // Funds can only be claimed after a period of time passed since allocation was closed
        AllocationState allocState = _getAllocationState(_allocationID);
        require(allocState == AllocationState.Finalized, "!finalized");

        // Get allocation
        Allocation memory alloc = __allocations[_allocationID];

        // Only the indexer or operator can decide if to restake
        bool restake = _isAuth(alloc.indexer) ? _restake : false;

        // Process rebate reward
        Rebates.Pool storage rebatePool = __rebates[alloc.closedAtEpoch];
        uint256 tokensToClaim = rebatePool.redeem(alloc.collectedFees, alloc.effectiveAllocation);

        // Add delegation rewards to the delegation pool
        uint256 delegationRewards = _collectDelegationQueryRewards(alloc.indexer, tokensToClaim);
        tokensToClaim = tokensToClaim.sub(delegationRewards);

        // Purge allocation data except for:
        // - indexer: used in disputes and to avoid reusing an allocationID
        // - subgraphDeploymentID: used in disputes
        __allocations[_allocationID].tokens = 0;
        __allocations[_allocationID].createdAtEpoch = 0; // This avoid collect(), close() and claim() to be called
        __allocations[_allocationID].closedAtEpoch = 0;
        __allocations[_allocationID].collectedFees = 0;
        __allocations[_allocationID].effectiveAllocation = 0;
        __allocations[_allocationID].accRewardsPerAllocatedToken = 0;

        // -- Interactions --

        IGraphToken graphToken = graphToken();

        // When all allocations processed then burn unclaimed fees and prune rebate pool
        if (rebatePool.unclaimedAllocationsCount == 0) {
            TokenUtils.burnTokens(graphToken, rebatePool.unclaimedFees());
            delete __rebates[alloc.closedAtEpoch];
        }

        // When there are tokens to claim from the rebate pool, transfer or restake
        _sendRewards(graphToken, tokensToClaim, alloc.indexer, restake);

        emit RebateClaimed(
            alloc.indexer,
            alloc.subgraphDeploymentID,
            _allocationID,
            epochManager().currentEpoch(),
            alloc.closedAtEpoch,
            tokensToClaim,
            rebatePool.unclaimedAllocationsCount,
            delegationRewards
        );
    }

    /**
     * @dev Collect the delegation rewards for query fees.
     * This function will assign the collected fees to the delegation pool.
     * @param _indexer Indexer to which the tokens to distribute are related
     * @param _tokens Total tokens received used to calculate the amount of fees to collect
     * @return Amount of delegation rewards
     */
    function _collectDelegationQueryRewards(address _indexer, uint256 _tokens)
        private
        returns (uint256)
    {
        uint256 delegationRewards = 0;
        DelegationPool storage pool = __delegationPools[_indexer];
        if (pool.tokens > 0 && pool.queryFeeCut < MAX_PPM) {
            uint256 indexerCut = uint256(pool.queryFeeCut).mul(_tokens).div(MAX_PPM);
            delegationRewards = _tokens.sub(indexerCut);
            pool.tokens = pool.tokens.add(delegationRewards);
        }
        return delegationRewards;
    }

    /**
     * @dev Collect the delegation rewards for indexing.
     * This function will assign the collected fees to the delegation pool.
     * @param _indexer Indexer to which the tokens to distribute are related
     * @param _tokens Total tokens received used to calculate the amount of fees to collect
     * @return Amount of delegation rewards
     */
    function _collectDelegationIndexingRewards(address _indexer, uint256 _tokens)
        private
        returns (uint256)
    {
        uint256 delegationRewards = 0;
        DelegationPool storage pool = __delegationPools[_indexer];
        if (pool.tokens > 0 && pool.indexingRewardCut < MAX_PPM) {
            uint256 indexerCut = uint256(pool.indexingRewardCut).mul(_tokens).div(MAX_PPM);
            delegationRewards = _tokens.sub(indexerCut);
            pool.tokens = pool.tokens.add(delegationRewards);
        }
        return delegationRewards;
    }

    /**
     * @dev Collect the curation fees for a subgraph deployment from an amount of tokens.
     * This function transfer curation fees to the Curation contract by calling Curation.collect
     * @param _graphToken Token to collect
     * @param _subgraphDeploymentID Subgraph deployment to which the curation fees are related
     * @param _tokens Total tokens received used to calculate the amount of fees to collect
     * @param _curationPercentage Percentage of tokens to collect as fees
     * @return Amount of curation fees
     */
    function _collectCurationFees(
        IGraphToken _graphToken,
        bytes32 _subgraphDeploymentID,
        uint256 _tokens,
        uint256 _curationPercentage
    ) private returns (uint256) {
        if (_tokens == 0) {
            return 0;
        }

        ICuration curation = curation();
        bool isCurationEnabled = _curationPercentage > 0 && address(curation) != address(0);

        if (isCurationEnabled && curation.isCurated(_subgraphDeploymentID)) {
            uint256 curationFees = uint256(_curationPercentage).mul(_tokens).div(MAX_PPM);
            if (curationFees > 0) {
                // Transfer and call collect()
                // This function transfer tokens to a trusted protocol contracts
                // Then we call collect() to do the transfer bookeeping
                TokenUtils.pushTokens(_graphToken, address(curation), curationFees);
                curation.collect(_subgraphDeploymentID, curationFees);
            }
            return curationFees;
        }
        return 0;
    }

    /**
     * @dev Collect tax to burn for an amount of tokens.
     * @param _graphToken Token to burn
     * @param _tokens Total tokens received used to calculate the amount of tax to collect
     * @param _percentage Percentage of tokens to burn as tax
     * @return Amount of tax charged
     */
    function _collectTax(
        IGraphToken _graphToken,
        uint256 _tokens,
        uint256 _percentage
    ) private returns (uint256) {
        uint256 tax = uint256(_percentage).mul(_tokens).div(MAX_PPM);
        TokenUtils.burnTokens(_graphToken, tax); // Burn tax if any
        return tax;
    }

    /**
     * @dev Triggers an update of rewards due to a change in allocations.
     * @param _subgraphDeploymentID Subgraph deployment updated
     * @return Accumulated rewards per allocated token for the subgraph deployment
     */
    function _updateRewards(bytes32 _subgraphDeploymentID) private returns (uint256) {
        IRewardsManager rewardsManager = rewardsManager();
        if (address(rewardsManager) == address(0)) {
            return 0;
        }
        return rewardsManager.onSubgraphAllocationUpdate(_subgraphDeploymentID);
    }

    /**
     * @dev Assign rewards for the closed allocation to indexer and delegators.
     * @param _allocationID Allocation
     * @param _indexer Address of the indexer that did the allocation
     */
    function _distributeRewards(address _allocationID, address _indexer) private {
        IRewardsManager rewardsManager = rewardsManager();
        if (address(rewardsManager) == address(0)) {
            return;
        }

        // Automatically triggers update of rewards snapshot as allocation will change
        // after this call. Take rewards mint tokens for the Staking contract to distribute
        // between indexer and delegators
        uint256 totalRewards = rewardsManager.takeRewards(_allocationID);
        if (totalRewards == 0) {
            return;
        }

        // Calculate delegation rewards and add them to the delegation pool
        uint256 delegationRewards = _collectDelegationIndexingRewards(_indexer, totalRewards);
        uint256 indexerRewards = totalRewards.sub(delegationRewards);

        // Send the indexer rewards
        _sendRewards(
            graphToken(),
            indexerRewards,
            _indexer,
            __rewardsDestination[_indexer] == address(0)
        );
    }

    /**
     * @dev Send rewards to the appropiate destination.
     * @param _graphToken Graph token
     * @param _amount Number of rewards tokens
     * @param _beneficiary Address of the beneficiary of rewards
     * @param _restake Whether to restake or not
     */
    function _sendRewards(
        IGraphToken _graphToken,
        uint256 _amount,
        address _beneficiary,
        bool _restake
    ) private {
        if (_amount == 0) return;

        if (_restake) {
            // Restake to place fees into the indexer stake
            _stake(_beneficiary, _amount);
        } else {
            // Transfer funds to the beneficiary's designated rewards destination if set
            address destination = __rewardsDestination[_beneficiary];
            TokenUtils.pushTokens(
                _graphToken,
                destination == address(0) ? _beneficiary : destination,
                _amount
            );
        }
    }

    /**
     * @dev Check if the caller is authorized to operate on behalf of
     * an indexer (i.e. the caller is the indexer or an operator)
     * @param _indexer Indexer address
     * @return True if the caller is authorized to operate on behalf of the indexer
     */
    function _isAuth(address _indexer) private view returns (bool) {
        return msg.sender == _indexer || isOperator(msg.sender, _indexer) == true;
    }

    /**
     * @dev Return the current state of an allocation
     * @param _allocationID Allocation identifier
     * @return AllocationState enum with the state of the allocation
     */
    function _getAllocationState(address _allocationID) private view returns (AllocationState) {
        Allocation storage alloc = __allocations[_allocationID];

        if (alloc.indexer == address(0)) {
            return AllocationState.Null;
        }
        if (alloc.createdAtEpoch == 0) {
            return AllocationState.Claimed;
        }

        uint256 closedAtEpoch = alloc.closedAtEpoch;
        if (closedAtEpoch == 0) {
            return AllocationState.Active;
        }

        uint256 epochs = epochManager().epochsSince(closedAtEpoch);
        if (epochs >= __channelDisputeEpochs) {
            return AllocationState.Finalized;
        }
        return AllocationState.Closed;
    }

    /**
     * @dev Get the effective stake allocation considering epochs from allocation to closing.
     * @param _maxAllocationEpochs Max amount of epochs to cap the allocated stake
     * @param _tokens Amount of tokens allocated
     * @param _numEpochs Number of epochs that passed from allocation to closing
     * @return Effective allocated tokens across epochs
     */
    function _getEffectiveAllocation(
        uint256 _maxAllocationEpochs,
        uint256 _tokens,
        uint256 _numEpochs
    ) private pure returns (uint256) {
        bool shouldCap = _maxAllocationEpochs > 0 && _numEpochs > _maxAllocationEpochs;
        return _tokens.mul((shouldCap) ? _maxAllocationEpochs : _numEpochs);
    }
}

// SPDX-License-Identifier: GPL-2.0-or-later

pragma solidity ^0.7.6;

import { ICallhookReceiver } from "../../gateway/ICallhookReceiver.sol";

/**
 * @title Base interface for the L2Staking contract.
 * @notice This interface is used to define the callhook receiver interface that is implemented by L2Staking.
 * @dev Note it includes only the L2-specific functionality, not the full IStaking interface.
 */
interface IL2StakingBase is ICallhookReceiver {
    event TransferredDelegationReturnedToDelegator(
        address indexed indexer,
        address indexed delegator,
        uint256 amount
    );
}

// SPDX-License-Identifier: GPL-2.0-or-later

pragma solidity >=0.6.12 <0.8.0;
pragma abicoder v2;

import { IStaking } from "../../staking/IStaking.sol";
import { IL2StakingBase } from "./IL2StakingBase.sol";

/**
 * @title Interface for the L2 Staking contract
 * @notice This is the interface that should be used when interacting with the L2 Staking contract.
 * It extends the IStaking interface with the functions that are specific to L2, adding the callhook receiver
 * to receive transferred stake and delegation from L1.
 * @dev Note that L2Staking doesn't actually inherit this interface. This is because of
 * the custom setup of the Staking contract where part of the functionality is implemented
 * in a separate contract (StakingExtension) to which calls are delegated through the fallback function.
 */
interface IL2Staking is IStaking, IL2StakingBase {
    /// @dev Message codes for the L1 -> L2 bridge callhook
    enum L1MessageCodes {
        RECEIVE_INDEXER_STAKE_CODE,
        RECEIVE_DELEGATION_CODE
    }

    /// @dev Encoded message struct when receiving indexer stake through the bridge
    struct ReceiveIndexerStakeData {
        address indexer;
    }

    /// @dev Encoded message struct when receiving delegation through the bridge
    struct ReceiveDelegationData {
        address indexer;
        address delegator;
    }
}

// SPDX-License-Identifier: GPL-2.0-or-later

pragma solidity ^0.7.6;
pragma abicoder v2;

import "@openzeppelin/contracts/math/SafeMath.sol";

import "./MathUtils.sol";

/**
 * @title A collection of data structures and functions to manage the Indexer Stake state.
 *        Used for low-level state changes, require() conditions should be evaluated
 *        at the caller function scope.
 */
library Stakes {
    using SafeMath for uint256;
    using Stakes for Stakes.Indexer;

    struct Indexer {
        uint256 tokensStaked; // Tokens on the indexer stake (staked by the indexer)
        uint256 tokensAllocated; // Tokens used in allocations
        uint256 tokensLocked; // Tokens locked for withdrawal subject to thawing period
        uint256 tokensLockedUntil; // Block when locked tokens can be withdrawn
    }

    /**
     * @dev Deposit tokens to the indexer stake.
     * @param stake Stake data
     * @param _tokens Amount of tokens to deposit
     */
    function deposit(Stakes.Indexer storage stake, uint256 _tokens) internal {
        stake.tokensStaked = stake.tokensStaked.add(_tokens);
    }

    /**
     * @dev Release tokens from the indexer stake.
     * @param stake Stake data
     * @param _tokens Amount of tokens to release
     */
    function release(Stakes.Indexer storage stake, uint256 _tokens) internal {
        stake.tokensStaked = stake.tokensStaked.sub(_tokens);
    }

    /**
     * @dev Allocate tokens from the main stack to a SubgraphDeployment.
     * @param stake Stake data
     * @param _tokens Amount of tokens to allocate
     */
    function allocate(Stakes.Indexer storage stake, uint256 _tokens) internal {
        stake.tokensAllocated = stake.tokensAllocated.add(_tokens);
    }

    /**
     * @dev Unallocate tokens from a SubgraphDeployment back to the main stack.
     * @param stake Stake data
     * @param _tokens Amount of tokens to unallocate
     */
    function unallocate(Stakes.Indexer storage stake, uint256 _tokens) internal {
        stake.tokensAllocated = stake.tokensAllocated.sub(_tokens);
    }

    /**
     * @dev Lock tokens until a thawing period pass.
     * @param stake Stake data
     * @param _tokens Amount of tokens to unstake
     * @param _period Period in blocks that need to pass before withdrawal
     */
    function lockTokens(
        Stakes.Indexer storage stake,
        uint256 _tokens,
        uint256 _period
    ) internal {
        // Take into account period averaging for multiple unstake requests
        uint256 lockingPeriod = _period;
        if (stake.tokensLocked > 0) {
            lockingPeriod = MathUtils.weightedAverage(
                MathUtils.diffOrZero(stake.tokensLockedUntil, block.number), // Remaining thawing period
                stake.tokensLocked, // Weighted by remaining unstaked tokens
                _period, // Thawing period
                _tokens // Weighted by new tokens to unstake
            );
        }

        // Update balances
        stake.tokensLocked = stake.tokensLocked.add(_tokens);
        stake.tokensLockedUntil = block.number.add(lockingPeriod);
    }

    /**
     * @dev Unlock tokens.
     * @param stake Stake data
     * @param _tokens Amount of tokens to unkock
     */
    function unlockTokens(Stakes.Indexer storage stake, uint256 _tokens) internal {
        stake.tokensLocked = stake.tokensLocked.sub(_tokens);
        if (stake.tokensLocked == 0) {
            stake.tokensLockedUntil = 0;
        }
    }

    /**
     * @dev Take all tokens out from the locked stake for withdrawal.
     * @param stake Stake data
     * @return Amount of tokens being withdrawn
     */
    function withdrawTokens(Stakes.Indexer storage stake) internal returns (uint256) {
        // Calculate tokens that can be released
        uint256 tokensToWithdraw = stake.tokensWithdrawable();

        if (tokensToWithdraw > 0) {
            // Reset locked tokens
            stake.unlockTokens(tokensToWithdraw);

            // Decrease indexer stake
            stake.release(tokensToWithdraw);
        }

        return tokensToWithdraw;
    }

    /**
     * @dev Return the amount of tokens used in allocations and locked for withdrawal.
     * @param stake Stake data
     * @return Token amount
     */
    function tokensUsed(Stakes.Indexer memory stake) internal pure returns (uint256) {
        return stake.tokensAllocated.add(stake.tokensLocked);
    }

    /**
     * @dev Return the amount of tokens staked not considering the ones that are already going
     * through the thawing period or are ready for withdrawal. We call it secure stake because
     * it is not subject to change by a withdraw call from the indexer.
     * @param stake Stake data
     * @return Token amount
     */
    function tokensSecureStake(Stakes.Indexer memory stake) internal pure returns (uint256) {
        return stake.tokensStaked.sub(stake.tokensLocked);
    }

    /**
     * @dev Tokens free balance on the indexer stake that can be used for any purpose.
     * Any token that is allocated cannot be used as well as tokens that are going through the
     * thawing period or are withdrawable
     * Calc: tokensStaked - tokensAllocated - tokensLocked
     * @param stake Stake data
     * @return Token amount
     */
    function tokensAvailable(Stakes.Indexer memory stake) internal pure returns (uint256) {
        return stake.tokensAvailableWithDelegation(0);
    }

    /**
     * @dev Tokens free balance on the indexer stake that can be used for allocations.
     * This function accepts a parameter for extra delegated capacity that takes into
     * account delegated tokens
     * @param stake Stake data
     * @param _delegatedCapacity Amount of tokens used from delegators to calculate availability
     * @return Token amount
     */
    function tokensAvailableWithDelegation(Stakes.Indexer memory stake, uint256 _delegatedCapacity)
        internal
        pure
        returns (uint256)
    {
        uint256 tokensCapacity = stake.tokensStaked.add(_delegatedCapacity);
        uint256 _tokensUsed = stake.tokensUsed();
        // If more tokens are used than the current capacity, the indexer is overallocated.
        // This means the indexer doesn't have available capacity to create new allocations.
        // We can reach this state when the indexer has funds allocated and then any
        // of these conditions happen:
        // - The delegationCapacity ratio is reduced.
        // - The indexer stake is slashed.
        // - A delegator removes enough stake.
        if (_tokensUsed > tokensCapacity) {
            // Indexer stake is over allocated: return 0 to avoid stake to be used until
            // the overallocation is restored by staking more tokens, unallocating tokens
            // or using more delegated funds
            return 0;
        }
        return tokensCapacity.sub(_tokensUsed);
    }

    /**
     * @dev Tokens available for withdrawal after thawing period.
     * @param stake Stake data
     * @return Token amount
     */
    function tokensWithdrawable(Stakes.Indexer memory stake) internal view returns (uint256) {
        // No tokens to withdraw before locking period
        if (stake.tokensLockedUntil == 0 || block.number < stake.tokensLockedUntil) {
            return 0;
        }
        return stake.tokensLocked;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

/**
 * @dev Elliptic Curve Digital Signature Algorithm (ECDSA) operations.
 *
 * These functions can be used to verify that a message was signed by the holder
 * of the private keys of a given address.
 */
library ECDSA {
    /**
     * @dev Returns the address that signed a hashed message (`hash`) with
     * `signature`. This address can then be used for verification purposes.
     *
     * The `ecrecover` EVM opcode allows for malleable (non-unique) signatures:
     * this function rejects them by requiring the `s` value to be in the lower
     * half order, and the `v` value to be either 27 or 28.
     *
     * IMPORTANT: `hash` _must_ be the result of a hash operation for the
     * verification to be secure: it is possible to craft signatures that
     * recover to arbitrary addresses for non-hashed data. A safe way to ensure
     * this is by receiving a hash of the original message (which may otherwise
     * be too long), and then calling {toEthSignedMessageHash} on it.
     */
    function recover(bytes32 hash, bytes memory signature) internal pure returns (address) {
        // Check the signature length
        if (signature.length != 65) {
            revert("ECDSA: invalid signature length");
        }

        // Divide the signature in r, s and v variables
        bytes32 r;
        bytes32 s;
        uint8 v;

        // ecrecover takes the signature parameters, and the only way to get them
        // currently is to use assembly.
        // solhint-disable-next-line no-inline-assembly
        assembly {
            r := mload(add(signature, 0x20))
            s := mload(add(signature, 0x40))
            v := byte(0, mload(add(signature, 0x60)))
        }

        return recover(hash, v, r, s);
    }

    /**
     * @dev Overload of {ECDSA-recover-bytes32-bytes-} that receives the `v`,
     * `r` and `s` signature fields separately.
     */
    function recover(bytes32 hash, uint8 v, bytes32 r, bytes32 s) internal pure returns (address) {
        // EIP-2 still allows signature malleability for ecrecover(). Remove this possibility and make the signature
        // unique. Appendix F in the Ethereum Yellow paper (https://ethereum.github.io/yellowpaper/paper.pdf), defines
        // the valid range for s in (281): 0 < s < secp256k1n ÷ 2 + 1, and for v in (282): v ∈ {27, 28}. Most
        // signatures from current libraries generate a unique signature with an s-value in the lower half order.
        //
        // If your library generates malleable signatures, such as s-values in the upper range, calculate a new s-value
        // with 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFEBAAEDCE6AF48A03BBFD25E8CD0364141 - s1 and flip v from 27 to 28 or
        // vice versa. If your library also generates signatures with 0/1 for v instead 27/28, add 27 to v to accept
        // these malleable signatures as well.
        require(uint256(s) <= 0x7FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF5D576E7357A4501DDFE92F46681B20A0, "ECDSA: invalid signature 's' value");
        require(v == 27 || v == 28, "ECDSA: invalid signature 'v' value");

        // If the signature is valid (and not malleable), return the signer address
        address signer = ecrecover(hash, v, r, s);
        require(signer != address(0), "ECDSA: invalid signature");

        return signer;
    }

    /**
     * @dev Returns an Ethereum Signed Message, created from a `hash`. This
     * replicates the behavior of the
     * https://github.com/ethereum/wiki/wiki/JSON-RPC#eth_sign[`eth_sign`]
     * JSON-RPC method.
     *
     * See {recover}.
     */
    function toEthSignedMessageHash(bytes32 hash) internal pure returns (bytes32) {
        // 32 is the length in bytes of hash,
        // enforced by the type signature above
        return keccak256(abi.encodePacked("\x19Ethereum Signed Message:\n32", hash));
    }
}

// SPDX-License-Identifier: GPL-2.0-or-later

pragma solidity ^0.7.6;
pragma abicoder v2;

import "./IMulticall.sol";

// Inspired by https://github.com/Uniswap/uniswap-v3-periphery/blob/main/contracts/base/Multicall.sol
// Note: Removed payable from the multicall

/**
 * @title Multicall
 * @notice Enables calling multiple methods in a single call to the contract
 */
abstract contract Multicall is IMulticall {
    /// @inheritdoc IMulticall
    function multicall(bytes[] calldata data) external override returns (bytes[] memory results) {
        results = new bytes[](data.length);
        for (uint256 i = 0; i < data.length; i++) {
            (bool success, bytes memory result) = address(this).delegatecall(data[i]);

            if (!success) {
                // Next 5 lines from https://ethereum.stackexchange.com/a/83577
                if (result.length < 68) revert();
                assembly {
                    result := add(result, 0x04)
                }
                revert(abi.decode(result, (string)));
            }

            results[i] = result;
        }
    }
}

// SPDX-License-Identifier: GPL-2.0-or-later

pragma solidity ^0.7.6;

import { IGraphProxy } from "./IGraphProxy.sol";

/**
 * @title Graph Upgradeable
 * @dev This contract is intended to be inherited from upgradeable contracts.
 */
abstract contract GraphUpgradeable {
    /**
     * @dev Storage slot with the address of the current implementation.
     * This is the keccak-256 hash of "eip1967.proxy.implementation" subtracted by 1, and is
     * validated in the constructor.
     */
    bytes32 internal constant IMPLEMENTATION_SLOT =
        0x360894a13ba1a3210667c828492db98dca3e2076cc3735a920a3ca505d382bbc;

    /**
     * @dev Check if the caller is the proxy admin.
     */
    modifier onlyProxyAdmin(IGraphProxy _proxy) {
        require(msg.sender == _proxy.admin(), "Caller must be the proxy admin");
        _;
    }

    /**
     * @dev Check if the caller is the implementation.
     */
    modifier onlyImpl() {
        require(msg.sender == _implementation(), "Only implementation");
        _;
    }

    /**
     * @dev Returns the current implementation.
     * @return impl Address of the current implementation
     */
    function _implementation() internal view returns (address impl) {
        bytes32 slot = IMPLEMENTATION_SLOT;
        // solhint-disable-next-line no-inline-assembly
        assembly {
            impl := sload(slot)
        }
    }

    /**
     * @notice Accept to be an implementation of proxy.
     * @param _proxy Proxy to accept
     */
    function acceptProxy(IGraphProxy _proxy) external onlyProxyAdmin(_proxy) {
        _proxy.acceptUpgrade();
    }

    /**
     * @notice Accept to be an implementation of proxy and then call a function from the new
     * implementation as specified by `_data`, which should be an encoded function call. This is
     * useful to initialize new storage variables in the proxied contract.
     * @param _proxy Proxy to accept
     * @param _data Calldata for the initialization function call (including selector)
     */
    function acceptProxyAndCall(IGraphProxy _proxy, bytes calldata _data)
        external
        onlyProxyAdmin(_proxy)
    {
        _proxy.acceptUpgradeAndCall(_data);
    }
}

// SPDX-License-Identifier: GPL-2.0-or-later

pragma solidity ^0.7.6;

import "../token/IGraphToken.sol";

library TokenUtils {
    /**
     * @dev Pull tokens from an address to this contract.
     * @param _graphToken Token to transfer
     * @param _from Address sending the tokens
     * @param _amount Amount of tokens to transfer
     */
    function pullTokens(
        IGraphToken _graphToken,
        address _from,
        uint256 _amount
    ) internal {
        if (_amount > 0) {
            require(_graphToken.transferFrom(_from, address(this), _amount), "!transfer");
        }
    }

    /**
     * @dev Push tokens from this contract to a receiving address.
     * @param _graphToken Token to transfer
     * @param _to Address receiving the tokens
     * @param _amount Amount of tokens to transfer
     */
    function pushTokens(
        IGraphToken _graphToken,
        address _to,
        uint256 _amount
    ) internal {
        if (_amount > 0) {
            require(_graphToken.transfer(_to, _amount), "!transfer");
        }
    }

    /**
     * @dev Burn tokens held by this contract.
     * @param _graphToken Token to burn
     * @param _amount Amount of tokens to burn
     */
    function burnTokens(IGraphToken _graphToken, uint256 _amount) internal {
        if (_amount > 0) {
            _graphToken.burn(_amount);
        }
    }
}

// SPDX-License-Identifier: GPL-2.0-or-later

pragma solidity ^0.7.6;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

interface IGraphToken is IERC20 {
    // -- Mint and Burn --

    function burn(uint256 amount) external;

    function burnFrom(address _from, uint256 amount) external;

    function mint(address _to, uint256 _amount) external;

    // -- Mint Admin --

    function addMinter(address _account) external;

    function removeMinter(address _account) external;

    function renounceMinter() external;

    function isMinter(address _account) external view returns (bool);

    // -- Permit --

    function permit(
        address _owner,
        address _spender,
        uint256 _value,
        uint256 _deadline,
        uint8 _v,
        bytes32 _r,
        bytes32 _s
    ) external;

    // -- Allowance --

    function increaseAllowance(address spender, uint256 addedValue) external returns (bool);

    function decreaseAllowance(address spender, uint256 subtractedValue) external returns (bool);
}

// SPDX-License-Identifier: GPL-2.0-or-later

pragma solidity >=0.6.12 <0.8.0;
pragma abicoder v2;

import { IStakingData } from "./IStakingData.sol";

/**
 * @title Base interface for the Staking contract.
 * @dev This interface includes only what's implemented in the base Staking contract.
 * It does not include the L1 and L2 specific functionality. It also does not include
 * several functions that are implemented in the StakingExtension contract, and are called
 * via delegatecall through the fallback function. See IStaking.sol for an interface
 * that includes the full functionality.
 */
interface IStakingBase is IStakingData {
    /**
     * @dev Emitted when `indexer` stakes `tokens` amount.
     */
    event StakeDeposited(address indexed indexer, uint256 tokens);

    /**
     * @dev Emitted when `indexer` unstaked and locked `tokens` amount until `until` block.
     */
    event StakeLocked(address indexed indexer, uint256 tokens, uint256 until);

    /**
     * @dev Emitted when `indexer` withdrew `tokens` staked.
     */
    event StakeWithdrawn(address indexed indexer, uint256 tokens);

    /**
     * @dev Emitted when `indexer` allocated `tokens` amount to `subgraphDeploymentID`
     * during `epoch`.
     * `allocationID` indexer derived address used to identify the allocation.
     * `metadata` additional information related to the allocation.
     */
    event AllocationCreated(
        address indexed indexer,
        bytes32 indexed subgraphDeploymentID,
        uint256 epoch,
        uint256 tokens,
        address indexed allocationID,
        bytes32 metadata
    );

    /**
     * @dev Emitted when `indexer` collected `tokens` amount in `epoch` for `allocationID`.
     * These funds are related to `subgraphDeploymentID`.
     * The `from` value is the sender of the collected funds.
     */
    event AllocationCollected(
        address indexed indexer,
        bytes32 indexed subgraphDeploymentID,
        uint256 epoch,
        uint256 tokens,
        address indexed allocationID,
        address from,
        uint256 curationFees,
        uint256 rebateFees
    );

    /**
     * @dev Emitted when `indexer` close an allocation in `epoch` for `allocationID`.
     * An amount of `tokens` get unallocated from `subgraphDeploymentID`.
     * The `effectiveAllocation` are the tokens allocated from creation to closing.
     * This event also emits the POI (proof of indexing) submitted by the indexer.
     * `isPublic` is true if the sender was someone other than the indexer.
     */
    event AllocationClosed(
        address indexed indexer,
        bytes32 indexed subgraphDeploymentID,
        uint256 epoch,
        uint256 tokens,
        address indexed allocationID,
        uint256 effectiveAllocation,
        address sender,
        bytes32 poi,
        bool isPublic
    );

    /**
     * @dev Emitted when `indexer` claimed a rebate on `subgraphDeploymentID` during `epoch`
     * related to the `forEpoch` rebate pool.
     * The rebate is for `tokens` amount and `unclaimedAllocationsCount` are left for claim
     * in the rebate pool. `delegationFees` collected and sent to delegation pool.
     */
    event RebateClaimed(
        address indexed indexer,
        bytes32 indexed subgraphDeploymentID,
        address indexed allocationID,
        uint256 epoch,
        uint256 forEpoch,
        uint256 tokens,
        uint256 unclaimedAllocationsCount,
        uint256 delegationFees
    );

    /**
     * @dev Emitted when `indexer` update the delegation parameters for its delegation pool.
     */
    event DelegationParametersUpdated(
        address indexed indexer,
        uint32 indexingRewardCut,
        uint32 queryFeeCut,
        uint32 cooldownBlocks
    );

    /**
     * @dev Emitted when `caller` set `assetHolder` address as `allowed` to send funds
     * to staking contract.
     */
    event AssetHolderUpdate(address indexed caller, address indexed assetHolder, bool allowed);

    /**
     * @dev Emitted when `indexer` set `operator` access.
     */
    event SetOperator(address indexed indexer, address indexed operator, bool allowed);

    /**
     * @dev Emitted when `indexer` set an address to receive rewards.
     */
    event SetRewardsDestination(address indexed indexer, address indexed destination);

    /**
     * @dev Emitted when `extensionImpl` was set as the address of the StakingExtension contract
     * to which extended functionality is delegated.
     */
    event ExtensionImplementationSet(address extensionImpl);

    /**
     * @dev Possible states an allocation can be.
     * States:
     * - Null = indexer == address(0)
     * - Active = not Null && tokens > 0
     * - Closed = Active && closedAtEpoch != 0
     * - Finalized = Closed && closedAtEpoch + channelDisputeEpochs > now()
     * - Claimed = not Null && tokens == 0
     */
    enum AllocationState {
        Null,
        Active,
        Closed,
        Finalized,
        Claimed
    }

    /**
     * @notice Initialize this contract.
     * @param _controller Address of the controller that manages this contract
     * @param _minimumIndexerStake Minimum amount of tokens that an indexer must stake
     * @param _thawingPeriod Number of blocks that tokens get locked after unstaking
     * @param _protocolPercentage Percentage of query fees that are burned as protocol fee (in PPM)
     * @param _curationPercentage Percentage of query fees that are given to curators (in PPM)
     * @param _channelDisputeEpochs The period in epochs that needs to pass before fees in rebate pool can be claimed
     * @param _maxAllocationEpochs The maximum number of epochs that an allocation can be active
     * @param _delegationUnbondingPeriod The period in epochs that tokens get locked after undelegating
     * @param _delegationRatio The ratio between an indexer's own stake and the delegation they can use
     * @param _rebateAlphaNumerator The numerator of the alpha factor used to calculate the rebate
     * @param _rebateAlphaDenominator The denominator of the alpha factor used to calculate the rebate
     * @param _extensionImpl Address of the StakingExtension implementation
     */
    function initialize(
        address _controller,
        uint256 _minimumIndexerStake,
        uint32 _thawingPeriod,
        uint32 _protocolPercentage,
        uint32 _curationPercentage,
        uint32 _channelDisputeEpochs,
        uint32 _maxAllocationEpochs,
        uint32 _delegationUnbondingPeriod,
        uint32 _delegationRatio,
        uint32 _rebateAlphaNumerator,
        uint32 _rebateAlphaDenominator,
        address _extensionImpl
    ) external;

    /**
     * @notice Set the address of the StakingExtension implementation.
     * @dev This function can only be called by the governor.
     * @param _extensionImpl Address of the StakingExtension implementation
     */
    function setExtensionImpl(address _extensionImpl) external;

    /**
     * @notice Set the address of the counterpart (L1 or L2) staking contract.
     * @dev This function can only be called by the governor.
     * @param _counterpart Address of the counterpart staking contract in the other chain, without any aliasing.
     */
    function setCounterpartStakingAddress(address _counterpart) external;

    /**
     * @notice Set the minimum stake needed to be an Indexer
     * @dev This function can only be called by the governor.
     * @param _minimumIndexerStake Minimum amount of tokens that an indexer must stake
     */
    function setMinimumIndexerStake(uint256 _minimumIndexerStake) external;

    /**
     * @notice Set the number of blocks that tokens get locked after unstaking
     * @dev This function can only be called by the governor.
     * @param _thawingPeriod Number of blocks that tokens get locked after unstaking
     */
    function setThawingPeriod(uint32 _thawingPeriod) external;

    /**
     * @notice Set the curation percentage of query fees sent to curators.
     * @dev This function can only be called by the governor.
     * @param _percentage Percentage of query fees sent to curators
     */
    function setCurationPercentage(uint32 _percentage) external;

    /**
     * @notice Set a protocol percentage to burn when collecting query fees.
     * @dev This function can only be called by the governor.
     * @param _percentage Percentage of query fees to burn as protocol fee
     */
    function setProtocolPercentage(uint32 _percentage) external;

    /**
     * @notice Set the period in epochs that need to pass before fees in rebate pool can be claimed.
     * @dev This function can only be called by the governor.
     * @param _channelDisputeEpochs Period in epochs
     */
    function setChannelDisputeEpochs(uint32 _channelDisputeEpochs) external;

    /**
     * @notice Set the max time allowed for indexers to allocate on a subgraph
     * before others are allowed to close the allocation.
     * @dev This function can only be called by the governor.
     * @param _maxAllocationEpochs Allocation duration limit in epochs
     */
    function setMaxAllocationEpochs(uint32 _maxAllocationEpochs) external;

    /**
     * @notice Set the rebate ratio (fees to allocated stake).
     * @dev This function can only be called by the governor.
     * @param _alphaNumerator Numerator of `alpha` in the cobb-douglas function
     * @param _alphaDenominator Denominator of `alpha` in the cobb-douglas function
     */
    function setRebateRatio(uint32 _alphaNumerator, uint32 _alphaDenominator) external;

    /**
     * @notice Set an address as allowed asset holder.
     * @dev This function can only be called by the governor.
     * @param _assetHolder Address of allowed source for state channel funds
     * @param _allowed True if asset holder is allowed
     */
    function setAssetHolder(address _assetHolder, bool _allowed) external;

    /**
     * @notice Authorize or unauthorize an address to be an operator for the caller.
     * @param _operator Address to authorize or unauthorize
     * @param _allowed Whether the operator is authorized or not
     */
    function setOperator(address _operator, bool _allowed) external;

    /**
     * @notice Deposit tokens on the indexer's stake.
     * The amount staked must be over the minimumIndexerStake.
     * @param _tokens Amount of tokens to stake
     */
    function stake(uint256 _tokens) external;

    /**
     * @notice Deposit tokens on the Indexer stake, on behalf of the Indexer.
     * The amount staked must be over the minimumIndexerStake.
     * @param _indexer Address of the indexer
     * @param _tokens Amount of tokens to stake
     */
    function stakeTo(address _indexer, uint256 _tokens) external;

    /**
     * @notice Unstake tokens from the indexer stake, lock them until the thawing period expires.
     * @dev NOTE: The function accepts an amount greater than the currently staked tokens.
     * If that happens, it will try to unstake the max amount of tokens it can.
     * The reason for this behaviour is to avoid time conditions while the transaction
     * is in flight.
     * @param _tokens Amount of tokens to unstake
     */
    function unstake(uint256 _tokens) external;

    /**
     * @notice Withdraw indexer tokens once the thawing period has passed.
     */
    function withdraw() external;

    /**
     * @notice Set the destination where to send rewards for an indexer.
     * @param _destination Rewards destination address. If set to zero, rewards will be restaked
     */
    function setRewardsDestination(address _destination) external;

    /**
     * @notice Set the delegation parameters for the caller.
     * @param _indexingRewardCut Percentage of indexing rewards left for the indexer
     * @param _queryFeeCut Percentage of query fees left for the indexer
     * @param _cooldownBlocks Period that need to pass to update delegation parameters
     */
    function setDelegationParameters(
        uint32 _indexingRewardCut,
        uint32 _queryFeeCut,
        uint32 _cooldownBlocks
    ) external;

    /**
     * @notice Allocate available tokens to a subgraph deployment.
     * @param _subgraphDeploymentID ID of the SubgraphDeployment where tokens will be allocated
     * @param _tokens Amount of tokens to allocate
     * @param _allocationID The allocation identifier
     * @param _metadata IPFS hash for additional information about the allocation
     * @param _proof A 65-bytes Ethereum signed message of `keccak256(indexerAddress,allocationID)`
     */
    function allocate(
        bytes32 _subgraphDeploymentID,
        uint256 _tokens,
        address _allocationID,
        bytes32 _metadata,
        bytes calldata _proof
    ) external;

    /**
     * @notice Allocate available tokens to a subgraph deployment from and indexer's stake.
     * The caller must be the indexer or the indexer's operator.
     * @param _indexer Indexer address to allocate funds from.
     * @param _subgraphDeploymentID ID of the SubgraphDeployment where tokens will be allocated
     * @param _tokens Amount of tokens to allocate
     * @param _allocationID The allocation identifier
     * @param _metadata IPFS hash for additional information about the allocation
     * @param _proof A 65-bytes Ethereum signed message of `keccak256(indexerAddress,allocationID)`
     */
    function allocateFrom(
        address _indexer,
        bytes32 _subgraphDeploymentID,
        uint256 _tokens,
        address _allocationID,
        bytes32 _metadata,
        bytes calldata _proof
    ) external;

    /**
     * @notice Close an allocation and free the staked tokens.
     * To be eligible for rewards a proof of indexing must be presented.
     * Presenting a bad proof is subject to slashable condition.
     * To opt out of rewards set _poi to 0x0
     * @param _allocationID The allocation identifier
     * @param _poi Proof of indexing submitted for the allocated period
     */
    function closeAllocation(address _allocationID, bytes32 _poi) external;

    /**
     * @notice Collect query fees from state channels and assign them to an allocation.
     * Funds received are only accepted from a valid sender.
     * @dev To avoid reverting on the withdrawal from channel flow this function will:
     * 1) Accept calls with zero tokens.
     * 2) Accept calls after an allocation passed the dispute period, in that case, all
     *    the received tokens are burned.
     * @param _tokens Amount of tokens to collect
     * @param _allocationID Allocation where the tokens will be assigned
     */
    function collect(uint256 _tokens, address _allocationID) external;

    /**
     * @notice Claim tokens from the rebate pool.
     * @param _allocationID Allocation from where we are claiming tokens
     * @param _restake True if restake fees instead of transfer to indexer
     */
    function claim(address _allocationID, bool _restake) external;

    /**
     * @dev Claim tokens from the rebate pool for many allocations.
     * @param _allocationID Array of allocations from where we are claiming tokens
     * @param _restake True if restake fees instead of transfer to indexer
     */
    function claimMany(address[] calldata _allocationID, bool _restake) external;

    /**
     * @notice Return true if operator is allowed for indexer.
     * @param _operator Address of the operator
     * @param _indexer Address of the indexer
     * @return True if operator is allowed for indexer, false otherwise
     */
    function isOperator(address _operator, address _indexer) external view returns (bool);

    /**
     * @notice Getter that returns if an indexer has any stake.
     * @param _indexer Address of the indexer
     * @return True if indexer has staked tokens
     */
    function hasStake(address _indexer) external view returns (bool);

    /**
     * @notice Get the total amount of tokens staked by the indexer.
     * @param _indexer Address of the indexer
     * @return Amount of tokens staked by the indexer
     */
    function getIndexerStakedTokens(address _indexer) external view returns (uint256);

    /**
     * @notice Get the total amount of tokens available to use in allocations.
     * This considers the indexer stake and delegated tokens according to delegation ratio
     * @param _indexer Address of the indexer
     * @return Amount of tokens available to allocate including delegation
     */
    function getIndexerCapacity(address _indexer) external view returns (uint256);

    /**
     * @notice Return the allocation by ID.
     * @param _allocationID Address used as allocation identifier
     * @return Allocation data
     */
    function getAllocation(address _allocationID) external view returns (Allocation memory);

    /**
     * @notice Return the current state of an allocation
     * @param _allocationID Allocation identifier
     * @return AllocationState enum with the state of the allocation
     */
    function getAllocationState(address _allocationID) external view returns (AllocationState);

    /**
     * @notice Return if allocationID is used.
     * @param _allocationID Address used as signer by the indexer for an allocation
     * @return True if allocationID already used
     */
    function isAllocation(address _allocationID) external view returns (bool);

    /**
     * @notice Return the total amount of tokens allocated to subgraph.
     * @param _subgraphDeploymentID Deployment ID for the subgraph
     * @return Total tokens allocated to subgraph
     */
    function getSubgraphAllocatedTokens(bytes32 _subgraphDeploymentID)
        external
        view
        returns (uint256);
}

// SPDX-License-Identifier: GPL-2.0-or-later

pragma solidity ^0.7.6;

import { Managed } from "../governance/Managed.sol";

import { IStakingData } from "./IStakingData.sol";
import { Rebates } from "./libs/Rebates.sol";
import { Stakes } from "./libs/Stakes.sol";

/**
 * @title StakingV1Storage
 * @notice This contract holds all the storage variables for the Staking contract, version 1
 * @dev Note that we use a double underscore prefix for variable names; this prefix identifies
 * variables that used to be public but are now internal, getters can be found on StakingExtension.sol.
 */
// solhint-disable-next-line max-states-count
contract StakingV1Storage is Managed {
    // -- Staking --

    /// @dev Minimum amount of tokens an indexer needs to stake
    uint256 internal __minimumIndexerStake;

    /// @dev Time in blocks to unstake
    uint32 internal __thawingPeriod; // in blocks

    /// @dev Percentage of fees going to curators
    /// Parts per million. (Allows for 4 decimal points, 999,999 = 99.9999%)
    uint32 internal __curationPercentage;

    /// @dev Percentage of fees burned as protocol fee
    /// Parts per million. (Allows for 4 decimal points, 999,999 = 99.9999%)
    uint32 internal __protocolPercentage;

    /// @dev Period for allocation to be finalized
    uint32 internal __channelDisputeEpochs;

    /// @dev Maximum allocation time
    uint32 internal __maxAllocationEpochs;

    /// @dev Rebate ratio numerator
    uint32 internal __alphaNumerator;

    /// @dev Rebate ratio denominator
    uint32 internal __alphaDenominator;

    /// @dev Indexer stakes : indexer => Stake
    mapping(address => Stakes.Indexer) internal __stakes;

    /// @dev Allocations : allocationID => Allocation
    mapping(address => IStakingData.Allocation) internal __allocations;

    /// @dev Subgraph Allocations: subgraphDeploymentID => tokens
    mapping(bytes32 => uint256) internal __subgraphAllocations;

    /// @dev Rebate pools : epoch => Pool
    mapping(uint256 => Rebates.Pool) internal __rebates;

    // -- Slashing --

    /// @dev List of addresses allowed to slash stakes
    mapping(address => bool) internal __slashers;

    // -- Delegation --

    /// @dev Set the delegation capacity multiplier defined by the delegation ratio
    /// If delegation ratio is 100, and an Indexer has staked 5 GRT,
    /// then they can use up to 500 GRT from the delegated stake
    uint32 internal __delegationRatio;

    /// @dev Time in blocks an indexer needs to wait to change delegation parameters
    uint32 internal __delegationParametersCooldown;

    /// @dev Time in epochs a delegator needs to wait to withdraw delegated stake
    uint32 internal __delegationUnbondingPeriod; // in epochs

    /// @dev Percentage of tokens to tax a delegation deposit
    /// Parts per million. (Allows for 4 decimal points, 999,999 = 99.9999%)
    uint32 internal __delegationTaxPercentage;

    /// @dev Delegation pools : indexer => DelegationPool
    mapping(address => IStakingData.DelegationPool) internal __delegationPools;

    // -- Operators --

    /// @dev Operator auth : indexer => operator => is authorized
    mapping(address => mapping(address => bool)) internal __operatorAuth;

    // -- Asset Holders --

    /// @dev Allowed AssetHolders that can collect query fees: assetHolder => is allowed
    mapping(address => bool) internal __assetHolders;
}

/**
 * @title StakingV2Storage
 * @notice This contract holds all the storage variables for the Staking contract, version 2
 * @dev Note that we use a double underscore prefix for variable names; this prefix identifies
 * variables that used to be public but are now internal, getters can be found on StakingExtension.sol.
 */
contract StakingV2Storage is StakingV1Storage {
    /// @dev Destination of accrued rewards : beneficiary => rewards destination
    mapping(address => address) internal __rewardsDestination;
}

/**
 * @title StakingV3Storage
 * @notice This contract holds all the storage variables for the base Staking contract, version 3.
 * @dev Note that this is the first version that includes a storage gap - if adding
 * future versions, make sure to move the gap to the new version and
 * reduce the size of the gap accordingly.
 */
contract StakingV3Storage is StakingV2Storage {
    /// @dev Address of the counterpart Staking contract on L1/L2
    address internal counterpartStakingAddress;
    /// @dev Address of the StakingExtension implementation
    address internal extensionImpl;
    /// @dev Gap to allow adding variables in future upgrades (since L1Staking and L2Staking can have their own storage as well)
    uint256[50] private __gap;
}

// SPDX-License-Identifier: GPL-2.0-or-later

pragma solidity ^0.7.6;

import "@openzeppelin/contracts/math/SafeMath.sol";

/**
 * @title MathUtils Library
 * @notice A collection of functions to perform math operations
 */
library MathUtils {
    using SafeMath for uint256;

    /**
     * @dev Calculates the weighted average of two values pondering each of these
     * values based on configured weights. The contribution of each value N is
     * weightN/(weightA + weightB).
     * @param valueA The amount for value A
     * @param weightA The weight to use for value A
     * @param valueB The amount for value B
     * @param weightB The weight to use for value B
     */
    function weightedAverage(
        uint256 valueA,
        uint256 weightA,
        uint256 valueB,
        uint256 weightB
    ) internal pure returns (uint256) {
        return valueA.mul(weightA).add(valueB.mul(weightB)).div(weightA.add(weightB));
    }

    /**
     * @dev Returns the minimum of two numbers.
     */
    function min(uint256 x, uint256 y) internal pure returns (uint256) {
        return x <= y ? x : y;
    }

    /**
     * @dev Returns the difference between two numbers or zero if negative.
     */
    function diffOrZero(uint256 x, uint256 y) internal pure returns (uint256) {
        return (x > y) ? x.sub(y) : 0;
    }
}

// SPDX-License-Identifier: GPL-2.0-or-later

pragma solidity ^0.7.6;
pragma abicoder v2;

import "@openzeppelin/contracts/math/SafeMath.sol";

import "./Cobbs.sol";

/**
 * @title A collection of data structures and functions to manage Rebates
 *        Used for low-level state changes, require() conditions should be evaluated
 *        at the caller function scope.
 */
library Rebates {
    using SafeMath for uint256;
    using Rebates for Rebates.Pool;

    // Tracks stats for allocations closed on a particular epoch for claiming
    // The pool also keeps tracks of total query fees collected and stake used
    // Only one rebate pool exists per epoch
    struct Pool {
        uint256 fees; // total query fees in the rebate pool
        uint256 effectiveAllocatedStake; // total effective allocation of stake
        uint256 claimedRewards; // total claimed rewards from the rebate pool
        uint32 unclaimedAllocationsCount; // amount of unclaimed allocations
        uint32 alphaNumerator; // numerator of `alpha` in the cobb-douglas function
        uint32 alphaDenominator; // denominator of `alpha` in the cobb-douglas function
    }

    /**
     * @dev Init the rebate pool with the rebate ratio.
     * @param _alphaNumerator Numerator of `alpha` in the cobb-douglas function
     * @param _alphaDenominator Denominator of `alpha` in the cobb-douglas function
     */
    function init(
        Rebates.Pool storage pool,
        uint32 _alphaNumerator,
        uint32 _alphaDenominator
    ) internal {
        pool.alphaNumerator = _alphaNumerator;
        pool.alphaDenominator = _alphaDenominator;
    }

    /**
     * @dev Return true if the rebate pool was already initialized.
     */
    function exists(Rebates.Pool storage pool) internal view returns (bool) {
        return pool.effectiveAllocatedStake > 0;
    }

    /**
     * @dev Return the amount of unclaimed fees.
     */
    function unclaimedFees(Rebates.Pool storage pool) internal view returns (uint256) {
        return pool.fees.sub(pool.claimedRewards);
    }

    /**
     * @dev Deposit tokens into the rebate pool.
     * @param _indexerFees Amount of fees collected in tokens
     * @param _indexerEffectiveAllocatedStake Effective stake allocated by indexer for a period of epochs
     */
    function addToPool(
        Rebates.Pool storage pool,
        uint256 _indexerFees,
        uint256 _indexerEffectiveAllocatedStake
    ) internal {
        pool.fees = pool.fees.add(_indexerFees);
        pool.effectiveAllocatedStake = pool.effectiveAllocatedStake.add(
            _indexerEffectiveAllocatedStake
        );
        pool.unclaimedAllocationsCount += 1;
    }

    /**
     * @dev Redeem tokens from the rebate pool.
     * @param _indexerFees Amount of fees collected in tokens
     * @param _indexerEffectiveAllocatedStake Effective stake allocated by indexer for a period of epochs
     * @return Amount of reward tokens according to Cobb-Douglas rebate formula
     */
    function redeem(
        Rebates.Pool storage pool,
        uint256 _indexerFees,
        uint256 _indexerEffectiveAllocatedStake
    ) internal returns (uint256) {
        uint256 rebateReward = 0;

        // Calculate the rebate rewards for the indexer
        if (pool.fees > 0 && pool.effectiveAllocatedStake > 0) {
            rebateReward = LibCobbDouglas.cobbDouglas(
                pool.fees, // totalRewards
                _indexerFees,
                pool.fees,
                _indexerEffectiveAllocatedStake,
                pool.effectiveAllocatedStake,
                pool.alphaNumerator,
                pool.alphaDenominator
            );

            // Under NO circumstance we will reward more than total fees in the pool
            uint256 _unclaimedFees = pool.unclaimedFees();
            if (rebateReward > _unclaimedFees) {
                rebateReward = _unclaimedFees;
            }
        }

        // Update pool state
        pool.unclaimedAllocationsCount -= 1;
        pool.claimedRewards = pool.claimedRewards.add(rebateReward);

        return rebateReward;
    }
}

// SPDX-License-Identifier: GPL-2.0-or-later

pragma solidity ^0.7.6;

import { IController } from "./IController.sol";

import { ICuration } from "../curation/ICuration.sol";
import { IEpochManager } from "../epochs/IEpochManager.sol";
import { IRewardsManager } from "../rewards/IRewardsManager.sol";
import { IStaking } from "../staking/IStaking.sol";
import { IGraphToken } from "../token/IGraphToken.sol";
import { ITokenGateway } from "../arbitrum/ITokenGateway.sol";
import { IGNS } from "../discovery/IGNS.sol";

import { IManaged } from "./IManaged.sol";

/**
 * @title Graph Managed contract
 * @dev The Managed contract provides an interface to interact with the Controller.
 * It also provides local caching for contract addresses. This mechanism relies on calling the
 * public `syncAllContracts()` function whenever a contract changes in the controller.
 *
 * Inspired by Livepeer:
 * https://github.com/livepeer/protocol/blob/streamflow/contracts/Controller.sol
 */
abstract contract Managed is IManaged {
    // -- State --

    /// Controller that manages this contract
    IController public override controller;
    /// @dev Cache for the addresses of the contracts retrieved from the controller
    mapping(bytes32 => address) private _addressCache;
    /// @dev Gap for future storage variables
    uint256[10] private __gap;

    // Immutables
    bytes32 private immutable CURATION = keccak256("Curation");
    bytes32 private immutable EPOCH_MANAGER = keccak256("EpochManager");
    bytes32 private immutable REWARDS_MANAGER = keccak256("RewardsManager");
    bytes32 private immutable STAKING = keccak256("Staking");
    bytes32 private immutable GRAPH_TOKEN = keccak256("GraphToken");
    bytes32 private immutable GRAPH_TOKEN_GATEWAY = keccak256("GraphTokenGateway");
    bytes32 private immutable GNS = keccak256("GNS");

    // -- Events --

    /// Emitted when a contract parameter has been updated
    event ParameterUpdated(string param);
    /// Emitted when the controller address has been set
    event SetController(address controller);

    /// Emitted when contract with `nameHash` is synced to `contractAddress`.
    event ContractSynced(bytes32 indexed nameHash, address contractAddress);

    // -- Modifiers --

    /**
     * @dev Revert if the controller is paused or partially paused
     */
    function _notPartialPaused() internal view {
        require(!controller.paused(), "Paused");
        require(!controller.partialPaused(), "Partial-paused");
    }

    /**
     * @dev Revert if the controller is paused
     */
    function _notPaused() internal view virtual {
        require(!controller.paused(), "Paused");
    }

    /**
     * @dev Revert if the caller is not the governor
     */
    function _onlyGovernor() internal view {
        require(msg.sender == controller.getGovernor(), "Only Controller governor");
    }

    /**
     * @dev Revert if the caller is not the Controller
     */
    function _onlyController() internal view {
        require(msg.sender == address(controller), "Caller must be Controller");
    }

    /**
     * @dev Revert if the controller is paused or partially paused
     */
    modifier notPartialPaused() {
        _notPartialPaused();
        _;
    }

    /**
     * @dev Revert if the controller is paused
     */
    modifier notPaused() {
        _notPaused();
        _;
    }

    /**
     * @dev Revert if the caller is not the Controller
     */
    modifier onlyController() {
        _onlyController();
        _;
    }

    /**
     * @dev Revert if the caller is not the governor
     */
    modifier onlyGovernor() {
        _onlyGovernor();
        _;
    }

    // -- Functions --

    /**
     * @dev Initialize a Managed contract
     * @param _controller Address for the Controller that manages this contract
     */
    function _initialize(address _controller) internal {
        _setController(_controller);
    }

    /**
     * @notice Set Controller. Only callable by current controller.
     * @param _controller Controller contract address
     */
    function setController(address _controller) external override onlyController {
        _setController(_controller);
    }

    /**
     * @dev Set controller.
     * @param _controller Controller contract address
     */
    function _setController(address _controller) internal {
        require(_controller != address(0), "Controller must be set");
        controller = IController(_controller);
        emit SetController(_controller);
    }

    /**
     * @dev Return Curation interface
     * @return Curation contract registered with Controller
     */
    function curation() internal view returns (ICuration) {
        return ICuration(_resolveContract(CURATION));
    }

    /**
     * @dev Return EpochManager interface
     * @return Epoch manager contract registered with Controller
     */
    function epochManager() internal view returns (IEpochManager) {
        return IEpochManager(_resolveContract(EPOCH_MANAGER));
    }

    /**
     * @dev Return RewardsManager interface
     * @return Rewards manager contract registered with Controller
     */
    function rewardsManager() internal view returns (IRewardsManager) {
        return IRewardsManager(_resolveContract(REWARDS_MANAGER));
    }

    /**
     * @dev Return Staking interface
     * @return Staking contract registered with Controller
     */
    function staking() internal view returns (IStaking) {
        return IStaking(_resolveContract(STAKING));
    }

    /**
     * @dev Return GraphToken interface
     * @return Graph token contract registered with Controller
     */
    function graphToken() internal view returns (IGraphToken) {
        return IGraphToken(_resolveContract(GRAPH_TOKEN));
    }

    /**
     * @dev Return GraphTokenGateway (L1 or L2) interface
     * @return Graph token gateway contract registered with Controller
     */
    function graphTokenGateway() internal view returns (ITokenGateway) {
        return ITokenGateway(_resolveContract(GRAPH_TOKEN_GATEWAY));
    }

    /**
     * @dev Return GNS (L1 or L2) interface.
     * @return Address of the GNS contract registered with Controller, as an IGNS interface.
     */
    function gns() internal view returns (IGNS) {
        return IGNS(_resolveContract(GNS));
    }

    /**
     * @dev Resolve a contract address from the cache or the Controller if not found.
     * @param _nameHash keccak256 hash of the contract name
     * @return Address of the contract
     */
    function _resolveContract(bytes32 _nameHash) internal view returns (address) {
        address contractAddress = _addressCache[_nameHash];
        if (contractAddress == address(0)) {
            contractAddress = controller.getContractProxy(_nameHash);
        }
        return contractAddress;
    }

    /**
     * @dev Cache a contract address from the Controller registry.
     * @param _nameHash keccak256 hash of the name of the contract to sync into the cache
     */
    function _syncContract(bytes32 _nameHash) internal {
        address contractAddress = controller.getContractProxy(_nameHash);
        if (_addressCache[_nameHash] != contractAddress) {
            _addressCache[_nameHash] = contractAddress;
            emit ContractSynced(_nameHash, contractAddress);
        }
    }

    /**
     * @notice Sync protocol contract addresses from the Controller registry
     * @dev This function will cache all the contracts using the latest addresses
     * Anyone can call the function whenever a Proxy contract change in the
     * controller to ensure the protocol is using the latest version
     */
    function syncAllContracts() external override {
        _syncContract(CURATION);
        _syncContract(EPOCH_MANAGER);
        _syncContract(REWARDS_MANAGER);
        _syncContract(STAKING);
        _syncContract(GRAPH_TOKEN);
        _syncContract(GRAPH_TOKEN_GATEWAY);
        _syncContract(GNS);
    }
}

// SPDX-License-Identifier: GPL-2.0-or-later

pragma solidity ^0.7.6;

/**
 * @title Curation Interface
 * @dev Interface for the Curation contract (and L2Curation too)
 */
interface ICuration {
    // -- Configuration --

    /**
     * @notice Update the default reserve ratio to `_defaultReserveRatio`
     * @param _defaultReserveRatio Reserve ratio (in PPM)
     */
    function setDefaultReserveRatio(uint32 _defaultReserveRatio) external;

    /**
     * @notice Update the minimum deposit amount needed to intialize a new subgraph
     * @param _minimumCurationDeposit Minimum amount of tokens required deposit
     */
    function setMinimumCurationDeposit(uint256 _minimumCurationDeposit) external;

    /**
     * @notice Set the curation tax percentage to charge when a curator deposits GRT tokens.
     * @param _percentage Curation tax percentage charged when depositing GRT tokens
     */
    function setCurationTaxPercentage(uint32 _percentage) external;

    /**
     * @notice Set the master copy to use as clones for the curation token.
     * @param _curationTokenMaster Address of implementation contract to use for curation tokens
     */
    function setCurationTokenMaster(address _curationTokenMaster) external;

    // -- Curation --

    /**
     * @notice Deposit Graph Tokens in exchange for signal of a SubgraphDeployment curation pool.
     * @param _subgraphDeploymentID Subgraph deployment pool from where to mint signal
     * @param _tokensIn Amount of Graph Tokens to deposit
     * @param _signalOutMin Expected minimum amount of signal to receive
     * @return Amount of signal minted
     * @return Amount of curation tax burned
     */
    function mint(
        bytes32 _subgraphDeploymentID,
        uint256 _tokensIn,
        uint256 _signalOutMin
    ) external returns (uint256, uint256);

    /**
     * @notice Burn _signal from the SubgraphDeployment curation pool
     * @param _subgraphDeploymentID SubgraphDeployment the curator is returning signal
     * @param _signalIn Amount of signal to return
     * @param _tokensOutMin Expected minimum amount of tokens to receive
     * @return Tokens returned
     */
    function burn(
        bytes32 _subgraphDeploymentID,
        uint256 _signalIn,
        uint256 _tokensOutMin
    ) external returns (uint256);

    /**
     * @notice Assign Graph Tokens collected as curation fees to the curation pool reserve.
     * @param _subgraphDeploymentID SubgraphDeployment where funds should be allocated as reserves
     * @param _tokens Amount of Graph Tokens to add to reserves
     */
    function collect(bytes32 _subgraphDeploymentID, uint256 _tokens) external;

    // -- Getters --

    /**
     * @notice Check if any GRT tokens are deposited for a SubgraphDeployment.
     * @param _subgraphDeploymentID SubgraphDeployment to check if curated
     * @return True if curated, false otherwise
     */
    function isCurated(bytes32 _subgraphDeploymentID) external view returns (bool);

    /**
     * @notice Get the amount of signal a curator has in a curation pool.
     * @param _curator Curator owning the signal tokens
     * @param _subgraphDeploymentID Subgraph deployment curation pool
     * @return Amount of signal owned by a curator for the subgraph deployment
     */
    function getCuratorSignal(address _curator, bytes32 _subgraphDeploymentID)
        external
        view
        returns (uint256);

    /**
     * @notice Get the amount of signal in a curation pool.
     * @param _subgraphDeploymentID Subgraph deployment curation poool
     * @return Amount of signal minted for the subgraph deployment
     */
    function getCurationPoolSignal(bytes32 _subgraphDeploymentID) external view returns (uint256);

    /**
     * @notice Get the amount of token reserves in a curation pool.
     * @param _subgraphDeploymentID Subgraph deployment curation poool
     * @return Amount of token reserves in the curation pool
     */
    function getCurationPoolTokens(bytes32 _subgraphDeploymentID) external view returns (uint256);

    /**
     * @notice Calculate amount of signal that can be bought with tokens in a curation pool.
     * This function considers and excludes the deposit tax.
     * @param _subgraphDeploymentID Subgraph deployment to mint signal
     * @param _tokensIn Amount of tokens used to mint signal
     * @return Amount of signal that can be bought
     * @return Amount of tokens that will be burned as curation tax
     */
    function tokensToSignal(bytes32 _subgraphDeploymentID, uint256 _tokensIn)
        external
        view
        returns (uint256, uint256);

    /**
     * @notice Calculate number of tokens to get when burning signal from a curation pool.
     * @param _subgraphDeploymentID Subgraph deployment to burn signal
     * @param _signalIn Amount of signal to burn
     * @return Amount of tokens to get for the specified amount of signal
     */
    function signalToTokens(bytes32 _subgraphDeploymentID, uint256 _signalIn)
        external
        view
        returns (uint256);

    /**
     * @notice Tax charged when curators deposit funds.
     * Parts per million. (Allows for 4 decimal points, 999,999 = 99.9999%)
     * @return Curation tax percentage expressed in PPM
     */
    function curationTaxPercentage() external view returns (uint32);
}

// SPDX-License-Identifier: GPL-2.0-or-later

pragma solidity ^0.7.6;

interface IRewardsManager {
    /**
     * @dev Stores accumulated rewards and snapshots related to a particular SubgraphDeployment.
     */
    struct Subgraph {
        uint256 accRewardsForSubgraph;
        uint256 accRewardsForSubgraphSnapshot;
        uint256 accRewardsPerSignalSnapshot;
        uint256 accRewardsPerAllocatedToken;
    }

    // -- Config --

    function setIssuancePerBlock(uint256 _issuancePerBlock) external;

    function setMinimumSubgraphSignal(uint256 _minimumSubgraphSignal) external;

    // -- Denylist --

    function setSubgraphAvailabilityOracle(address _subgraphAvailabilityOracle) external;

    function setDenied(bytes32 _subgraphDeploymentID, bool _deny) external;

    function setDeniedMany(bytes32[] calldata _subgraphDeploymentID, bool[] calldata _deny)
        external;

    function isDenied(bytes32 _subgraphDeploymentID) external view returns (bool);

    // -- Getters --

    function getNewRewardsPerSignal() external view returns (uint256);

    function getAccRewardsPerSignal() external view returns (uint256);

    function getAccRewardsForSubgraph(bytes32 _subgraphDeploymentID)
        external
        view
        returns (uint256);

    function getAccRewardsPerAllocatedToken(bytes32 _subgraphDeploymentID)
        external
        view
        returns (uint256, uint256);

    function getRewards(address _allocationID) external view returns (uint256);

    // -- Updates --

    function updateAccRewardsPerSignal() external returns (uint256);

    function takeRewards(address _allocationID) external returns (uint256);

    // -- Hooks --

    function onSubgraphSignalUpdate(bytes32 _subgraphDeploymentID) external returns (uint256);

    function onSubgraphAllocationUpdate(bytes32 _subgraphDeploymentID) external returns (uint256);
}

// SPDX-License-Identifier: GPL-2.0-or-later

pragma solidity ^0.7.6;
pragma abicoder v2;

import { SafeMath } from "@openzeppelin/contracts/math/SafeMath.sol";
import { StakingV3Storage } from "./StakingStorage.sol";
import { IStakingExtension } from "./IStakingExtension.sol";
import { TokenUtils } from "../utils/TokenUtils.sol";
import { IGraphToken } from "../token/IGraphToken.sol";
import { GraphUpgradeable } from "../upgrades/GraphUpgradeable.sol";
import { Rebates } from "./libs/Rebates.sol";
import { Stakes } from "./libs/Stakes.sol";
import { IStakingData } from "./IStakingData.sol";
import { MathUtils } from "./libs/MathUtils.sol";

/**
 * @title StakingExtension contract
 * @dev This contract provides the logic to manage delegations and other Staking
 * extension features (e.g. storage getters). It is meant to be called through delegatecall from the
 * Staking contract, and is only kept separate to keep the Staking contract size
 * within limits.
 */
contract StakingExtension is StakingV3Storage, GraphUpgradeable, IStakingExtension {
    using SafeMath for uint256;
    using Stakes for Stakes.Indexer;

    /// @dev 100% in parts per million
    uint32 private constant MAX_PPM = 1000000;

    /**
     * @dev Check if the caller is the slasher.
     */
    modifier onlySlasher() {
        require(__slashers[msg.sender] == true, "!slasher");
        _;
    }

    /**
     * @notice Initialize the StakingExtension contract
     * @dev This function is meant to be delegatecalled from the Staking contract's
     * initialize() function, so it uses the same access control check to ensure it is
     * being called by the Staking implementation as part of the proxy upgrade process.
     * @param _delegationUnbondingPeriod Delegation unbonding period in blocks
     * @param _cooldownBlocks Minimum time between changes to delegation parameters, in blocks
     * @param _delegationRatio Delegation capacity multiplier (e.g. 10 means 10x the indexer stake)
     * @param _delegationTaxPercentage Percentage of delegated tokens to burn as delegation tax, expressed in parts per million
     */
    function initialize(
        uint32 _delegationUnbondingPeriod,
        uint32 _cooldownBlocks,
        uint32 _delegationRatio,
        uint32 _delegationTaxPercentage
    ) external onlyImpl {
        _setDelegationUnbondingPeriod(_delegationUnbondingPeriod);
        _setDelegationParametersCooldown(_cooldownBlocks);
        _setDelegationRatio(_delegationRatio);
        _setDelegationTaxPercentage(_delegationTaxPercentage);
    }

    /**
     * @notice Set a delegation tax percentage to burn when delegated funds are deposited.
     * @dev This function is only callable by the governor
     * @param _percentage Percentage of delegated tokens to burn as delegation tax, expressed in parts per million
     */
    function setDelegationTaxPercentage(uint32 _percentage) external override onlyGovernor {
        _setDelegationTaxPercentage(_percentage);
    }

    /**
     * @notice Set the delegation ratio.
     * If set to 10 it means the indexer can use up to 10x the indexer staked amount
     * from their delegated tokens
     * @dev This function is only callable by the governor
     * @param _delegationRatio Delegation capacity multiplier
     */
    function setDelegationRatio(uint32 _delegationRatio) external override onlyGovernor {
        _setDelegationRatio(_delegationRatio);
    }

    /**
     * @notice Set the minimum time in blocks an indexer needs to wait to change delegation parameters.
     * Indexers can set a custom amount time for their own cooldown, but it must be greater than this.
     * @dev This function is only callable by the governor
     * @param _blocks Number of blocks to set the delegation parameters cooldown period
     */
    function setDelegationParametersCooldown(uint32 _blocks) external override onlyGovernor {
        _setDelegationParametersCooldown(_blocks);
    }

    /**
     * @notice Set the time, in epochs, a Delegator needs to wait to withdraw tokens after undelegating.
     * @dev This function is only callable by the governor
     * @param _delegationUnbondingPeriod Period in epochs to wait for token withdrawals after undelegating
     */
    function setDelegationUnbondingPeriod(uint32 _delegationUnbondingPeriod)
        external
        override
        onlyGovernor
    {
        _setDelegationUnbondingPeriod(_delegationUnbondingPeriod);
    }

    /**
     * @notice Set or unset an address as allowed slasher.
     * @param _slasher Address of the party allowed to slash indexers
     * @param _allowed True if slasher is allowed
     */
    function setSlasher(address _slasher, bool _allowed) external override onlyGovernor {
        require(_slasher != address(0), "!slasher");
        __slashers[_slasher] = _allowed;
        emit SlasherUpdate(msg.sender, _slasher, _allowed);
    }

    /**
     * @notice Delegate tokens to an indexer.
     * @param _indexer Address of the indexer to which tokens are delegated
     * @param _tokens Amount of tokens to delegate
     * @return Amount of shares issued from the delegation pool
     */
    function delegate(address _indexer, uint256 _tokens)
        external
        override
        notPartialPaused
        returns (uint256)
    {
        address delegator = msg.sender;

        // Transfer tokens to delegate to this contract
        TokenUtils.pullTokens(graphToken(), delegator, _tokens);

        // Update state
        return _delegate(delegator, _indexer, _tokens);
    }

    /**
     * @notice Undelegate tokens from an indexer. Tokens will be locked for the unbonding period.
     * @param _indexer Address of the indexer to which tokens had been delegated
     * @param _shares Amount of shares to return and undelegate tokens
     * @return Amount of tokens returned for the shares of the delegation pool
     */
    function undelegate(address _indexer, uint256 _shares)
        external
        override
        notPartialPaused
        returns (uint256)
    {
        return _undelegate(msg.sender, _indexer, _shares);
    }

    /**
     * @notice Withdraw undelegated tokens once the unbonding period has passed, and optionally
     * re-delegate to a new indexer.
     * @param _indexer Withdraw available tokens delegated to indexer
     * @param _newIndexer Re-delegate to indexer address if non-zero, withdraw if zero address
     */
    function withdrawDelegated(address _indexer, address _newIndexer)
        external
        override
        notPaused
        returns (uint256)
    {
        return _withdrawDelegated(msg.sender, _indexer, _newIndexer);
    }

    /**
     * @notice Slash the indexer stake. Delegated tokens are not subject to slashing.
     * @dev Can only be called by the slasher role.
     * @param _indexer Address of indexer to slash
     * @param _tokens Amount of tokens to slash from the indexer stake
     * @param _reward Amount of reward tokens to send to a beneficiary
     * @param _beneficiary Address of a beneficiary to receive a reward for the slashing
     */
    function slash(
        address _indexer,
        uint256 _tokens,
        uint256 _reward,
        address _beneficiary
    ) external override onlySlasher notPartialPaused {
        Stakes.Indexer storage indexerStake = __stakes[_indexer];

        // Only able to slash a non-zero number of tokens
        require(_tokens > 0, "!tokens");

        // Rewards comes from tokens slashed balance
        require(_tokens >= _reward, "rewards>slash");

        // Cannot slash stake of an indexer without any or enough stake
        require(indexerStake.tokensStaked > 0, "!stake");
        require(_tokens <= indexerStake.tokensStaked, "slash>stake");

        // Validate beneficiary of slashed tokens
        require(_beneficiary != address(0), "!beneficiary");

        // Slashing more tokens than freely available (over allocation condition)
        // Unlock locked tokens to avoid the indexer to withdraw them
        if (_tokens > indexerStake.tokensAvailable() && indexerStake.tokensLocked > 0) {
            uint256 tokensOverAllocated = _tokens.sub(indexerStake.tokensAvailable());
            uint256 tokensToUnlock = MathUtils.min(tokensOverAllocated, indexerStake.tokensLocked);
            indexerStake.unlockTokens(tokensToUnlock);
        }

        // Remove tokens to slash from the stake
        indexerStake.release(_tokens);

        // -- Interactions --

        IGraphToken graphToken = graphToken();

        // Set apart the reward for the beneficiary and burn remaining slashed stake
        TokenUtils.burnTokens(graphToken, _tokens.sub(_reward));

        // Give the beneficiary a reward for slashing
        TokenUtils.pushTokens(graphToken, _beneficiary, _reward);

        emit StakeSlashed(_indexer, _tokens, _reward, _beneficiary);
    }

    /**
     * @notice Return the delegation from a delegator to an indexer.
     * @param _indexer Address of the indexer where funds have been delegated
     * @param _delegator Address of the delegator
     * @return Delegation data
     */
    function getDelegation(address _indexer, address _delegator)
        external
        view
        override
        returns (Delegation memory)
    {
        return __delegationPools[_indexer].delegators[_delegator];
    }

    /**
     * @notice Getter for the delegationRatio, i.e. the delegation capacity multiplier:
     * If delegation ratio is 100, and an Indexer has staked 5 GRT,
     * then they can use up to 500 GRT from the delegated stake
     * @return Delegation ratio
     */
    function delegationRatio() external view override returns (uint32) {
        return __delegationRatio;
    }

    /**
     * @notice Getter for delegationParametersCooldown:
     * Minimum time in blocks an indexer needs to wait to change delegation parameters
     * @return Delegation parameters cooldown in blocks
     */
    function delegationParametersCooldown() external view override returns (uint32) {
        return __delegationParametersCooldown;
    }

    /**
     * @notice Getter for delegationUnbondingPeriod:
     * Time in epochs a delegator needs to wait to withdraw delegated stake
     * @return Delegation unbonding period in epochs
     */
    function delegationUnbondingPeriod() external view override returns (uint32) {
        return __delegationUnbondingPeriod;
    }

    /**
     * @notice Getter for delegationTaxPercentage:
     * Percentage of tokens to tax a delegation deposit, expressed in parts per million
     * @return Delegation tax percentage in parts per million
     */
    function delegationTaxPercentage() external view override returns (uint32) {
        return __delegationTaxPercentage;
    }

    /**
     * @notice Getter for delegationPools[_indexer]:
     * gets the delegation pool structure for a particular indexer.
     * @param _indexer Address of the indexer for which to query the delegation pool
     * @return Delegation pool as a DelegationPoolReturn struct
     */
    function delegationPools(address _indexer)
        external
        view
        override
        returns (DelegationPoolReturn memory)
    {
        DelegationPool storage pool = __delegationPools[_indexer];
        return
            DelegationPoolReturn(
                pool.cooldownBlocks, // Blocks to wait before updating parameters
                pool.indexingRewardCut, // in PPM
                pool.queryFeeCut, // in PPM
                pool.updatedAtBlock, // Block when the pool was last updated
                pool.tokens, // Total tokens as pool reserves
                pool.shares // Total shares minted in the pool
            );
    }

    /**
     * @notice Getter for rewardsDestination[_indexer]:
     * returns the address where the indexer's rewards are sent.
     * @param _indexer The indexer address for which to query the rewards destination
     * @return The address where the indexer's rewards are sent, zero if none is set in which case rewards are re-staked
     */
    function rewardsDestination(address _indexer) external view override returns (address) {
        return __rewardsDestination[_indexer];
    }

    /**
     * @notice Getter for assetHolders[_maybeAssetHolder]:
     * returns true if the address is an asset holder, i.e. an entity that can collect
     * query fees into the Staking contract.
     * @param _maybeAssetHolder The address that may or may not be an asset holder
     * @return True if the address is an asset holder
     */
    function assetHolders(address _maybeAssetHolder) external view override returns (bool) {
        return __assetHolders[_maybeAssetHolder];
    }

    /**
     * @notice Getter for operatorAuth[_indexer][_maybeOperator]:
     * returns true if the operator is authorized to operate on behalf of the indexer.
     * @param _indexer The indexer address for which to query authorization
     * @param _maybeOperator The address that may or may not be an operator
     * @return True if the operator is authorized to operate on behalf of the indexer
     */
    function operatorAuth(address _indexer, address _maybeOperator)
        external
        view
        override
        returns (bool)
    {
        return __operatorAuth[_indexer][_maybeOperator];
    }

    /**
     * @notice Getter for subgraphAllocations[_subgraphDeploymentId]:
     * returns the amount of tokens allocated to a subgraph deployment.
     * @param _subgraphDeploymentId The subgraph deployment for which to query the allocations
     * @return The amount of tokens allocated to the subgraph deployment
     */
    function subgraphAllocations(bytes32 _subgraphDeploymentId)
        external
        view
        override
        returns (uint256)
    {
        return __subgraphAllocations[_subgraphDeploymentId];
    }

    /**
     * @notice Getter for rebates[_epoch]:
     * gets the rebate pool for a particular epoch.
     * @param _epoch Epoch for which to query the rebate pool
     * @return Rebate pool for the specified epoch, as a Rebates.Pool struct
     */
    function rebates(uint256 _epoch) external view override returns (Rebates.Pool memory) {
        return __rebates[_epoch];
    }

    /**
     * @notice Getter for slashers[_maybeSlasher]:
     * returns true if the address is a slasher, i.e. an entity that can slash indexers
     * @param _maybeSlasher Address for which to check the slasher role
     * @return True if the address is a slasher
     */
    function slashers(address _maybeSlasher) external view override returns (bool) {
        return __slashers[_maybeSlasher];
    }

    /**
     * @notice Getter for minimumIndexerStake: the minimum
     * amount of GRT that an indexer needs to stake.
     * @return Minimum indexer stake in GRT
     */
    function minimumIndexerStake() external view override returns (uint256) {
        return __minimumIndexerStake;
    }

    /**
     * @notice Getter for thawingPeriod: the time in blocks an
     * indexer needs to wait to unstake tokens.
     * @return Thawing period in blocks
     */
    function thawingPeriod() external view override returns (uint32) {
        return __thawingPeriod;
    }

    /**
     * @notice Getter for curationPercentage: the percentage of
     * query fees that are distributed to curators.
     * @return Curation percentage in parts per million
     */
    function curationPercentage() external view override returns (uint32) {
        return __curationPercentage;
    }

    /**
     * @notice Getter for protocolPercentage: the percentage of
     * query fees that are burned as protocol fees.
     * @return Protocol percentage in parts per million
     */
    function protocolPercentage() external view override returns (uint32) {
        return __protocolPercentage;
    }

    /**
     * @notice Getter for channelDisputeEpochs: the time in epochs
     * between closing an allocation and the moment it becomes finalized so
     * query fees can be claimed.
     * @return Channel dispute period in epochs
     */
    function channelDisputeEpochs() external view override returns (uint32) {
        return __channelDisputeEpochs;
    }

    /**
     * @notice Getter for maxAllocationEpochs: the maximum time in epochs
     * that an allocation can be open before anyone is allowed to close it. This
     * also caps the effective allocation when sending the allocation's query fees
     * to the rebate pool.
     * @return Maximum allocation period in epochs
     */
    function maxAllocationEpochs() external view override returns (uint32) {
        return __maxAllocationEpochs;
    }

    /**
     * @notice Getter for alphaNumerator: the numerator of the Cobb-Douglas
     * rebate ratio.
     * @return Rebate ratio numerator
     */
    function alphaNumerator() external view override returns (uint32) {
        return __alphaNumerator;
    }

    /**
     * @notice Getter for alphaDenominator: the denominator of the Cobb-Douglas
     * rebate ratio.
     * @return Rebate ratio denominator
     */
    function alphaDenominator() external view override returns (uint32) {
        return __alphaDenominator;
    }

    /**
     * @notice Getter for stakes[_indexer]:
     * gets the stake information for an indexer as a Stakes.Indexer struct.
     * @param _indexer Indexer address for which to query the stake information
     * @return Stake information for the specified indexer, as a Stakes.Indexer struct
     */
    function stakes(address _indexer) external view override returns (Stakes.Indexer memory) {
        return __stakes[_indexer];
    }

    /**
     * @notice Getter for allocations[_allocationID]:
     * gets an allocation's information as an IStakingData.Allocation struct.
     * @param _allocationID Allocation ID for which to query the allocation information
     * @return The specified allocation, as an IStakingData.Allocation struct
     */
    function allocations(address _allocationID)
        external
        view
        override
        returns (IStakingData.Allocation memory)
    {
        return __allocations[_allocationID];
    }

    /**
     * @notice Return whether the delegator has delegated to the indexer.
     * @param _indexer Address of the indexer where funds have been delegated
     * @param _delegator Address of the delegator
     * @return True if delegator has tokens delegated to the indexer
     */
    function isDelegator(address _indexer, address _delegator) public view override returns (bool) {
        return __delegationPools[_indexer].delegators[_delegator].shares > 0;
    }

    /**
     * @notice Returns amount of delegated tokens ready to be withdrawn after unbonding period.
     * @param _delegation Delegation of tokens from delegator to indexer
     * @return Amount of tokens to withdraw
     */
    function getWithdraweableDelegatedTokens(Delegation memory _delegation)
        public
        view
        override
        returns (uint256)
    {
        // There must be locked tokens and period passed
        uint256 currentEpoch = epochManager().currentEpoch();
        if (_delegation.tokensLockedUntil > 0 && currentEpoch >= _delegation.tokensLockedUntil) {
            return _delegation.tokensLocked;
        }
        return 0;
    }

    /**
     * @dev Internal: Set a delegation tax percentage to burn when delegated funds are deposited.
     * @param _percentage Percentage of delegated tokens to burn as delegation tax
     */
    function _setDelegationTaxPercentage(uint32 _percentage) private {
        // Must be within 0% to 100% (inclusive)
        require(_percentage <= MAX_PPM, ">percentage");
        __delegationTaxPercentage = _percentage;
        emit ParameterUpdated("delegationTaxPercentage");
    }

    /**
     * @dev Internal: Set the delegation ratio.
     * If set to 10 it means the indexer can use up to 10x the indexer staked amount
     * from their delegated tokens
     * @param _delegationRatio Delegation capacity multiplier
     */
    function _setDelegationRatio(uint32 _delegationRatio) private {
        __delegationRatio = _delegationRatio;
        emit ParameterUpdated("delegationRatio");
    }

    /**
     * @dev Internal: Set the time in blocks an indexer needs to wait to change delegation parameters.
     * @param _blocks Number of blocks to set the delegation parameters cooldown period
     */
    function _setDelegationParametersCooldown(uint32 _blocks) private {
        __delegationParametersCooldown = _blocks;
        emit ParameterUpdated("delegationParametersCooldown");
    }

    /**
     * @dev Internal: Set the period for undelegation of stake from indexer.
     * @param _delegationUnbondingPeriod Period in epochs to wait for token withdrawals after undelegating
     */
    function _setDelegationUnbondingPeriod(uint32 _delegationUnbondingPeriod) private {
        require(_delegationUnbondingPeriod > 0, "!delegationUnbondingPeriod");
        __delegationUnbondingPeriod = _delegationUnbondingPeriod;
        emit ParameterUpdated("delegationUnbondingPeriod");
    }

    /**
     * @dev Delegate tokens to an indexer.
     * @param _delegator Address of the delegator
     * @param _indexer Address of the indexer to delegate tokens to
     * @param _tokens Amount of tokens to delegate
     * @return Amount of shares issued of the delegation pool
     */
    function _delegate(
        address _delegator,
        address _indexer,
        uint256 _tokens
    ) private returns (uint256) {
        // Only delegate a non-zero amount of tokens
        require(_tokens > 0, "!tokens");
        // Only delegate to non-empty address
        require(_indexer != address(0), "!indexer");
        // Only delegate to staked indexer
        require(__stakes[_indexer].tokensStaked > 0, "!stake");

        // Get the delegation pool of the indexer
        DelegationPool storage pool = __delegationPools[_indexer];
        Delegation storage delegation = pool.delegators[_delegator];

        // Collect delegation tax
        uint256 delegationTax = _collectTax(graphToken(), _tokens, __delegationTaxPercentage);
        uint256 delegatedTokens = _tokens.sub(delegationTax);

        // Calculate shares to issue
        uint256 shares = (pool.tokens == 0)
            ? delegatedTokens
            : delegatedTokens.mul(pool.shares).div(pool.tokens);
        require(shares > 0, "!shares");

        // Update the delegation pool
        pool.tokens = pool.tokens.add(delegatedTokens);
        pool.shares = pool.shares.add(shares);

        // Update the individual delegation
        delegation.shares = delegation.shares.add(shares);

        emit StakeDelegated(_indexer, _delegator, delegatedTokens, shares);

        return shares;
    }

    /**
     * @dev Undelegate tokens from an indexer.
     * @param _delegator Address of the delegator
     * @param _indexer Address of the indexer where tokens had been delegated
     * @param _shares Amount of shares to return and undelegate tokens
     * @return Amount of tokens returned for the shares of the delegation pool
     */
    function _undelegate(
        address _delegator,
        address _indexer,
        uint256 _shares
    ) private returns (uint256) {
        // Can only undelegate a non-zero amount of shares
        require(_shares > 0, "!shares");

        // Get the delegation pool of the indexer
        DelegationPool storage pool = __delegationPools[_indexer];
        Delegation storage delegation = pool.delegators[_delegator];

        // Delegator need to have enough shares in the pool to undelegate
        require(delegation.shares >= _shares, "!shares-avail");

        // Withdraw tokens if available
        if (getWithdraweableDelegatedTokens(delegation) > 0) {
            _withdrawDelegated(_delegator, _indexer, address(0));
        }

        // Calculate tokens to get in exchange for the shares
        uint256 tokens = _shares.mul(pool.tokens).div(pool.shares);

        // Update the delegation pool
        pool.tokens = pool.tokens.sub(tokens);
        pool.shares = pool.shares.sub(_shares);

        // Update the delegation
        delegation.shares = delegation.shares.sub(_shares);
        delegation.tokensLocked = delegation.tokensLocked.add(tokens);
        delegation.tokensLockedUntil = epochManager().currentEpoch().add(
            __delegationUnbondingPeriod
        );

        emit StakeDelegatedLocked(
            _indexer,
            _delegator,
            tokens,
            _shares,
            delegation.tokensLockedUntil
        );

        return tokens;
    }

    /**
     * @dev Withdraw delegated tokens once the unbonding period has passed.
     * @param _delegator Delegator that is withdrawing tokens
     * @param _indexer Withdraw available tokens delegated to indexer
     * @param _delegateToIndexer Re-delegate to indexer address if non-zero, withdraw if zero address
     * @return Amount of tokens withdrawn or re-delegated
     */
    function _withdrawDelegated(
        address _delegator,
        address _indexer,
        address _delegateToIndexer
    ) private returns (uint256) {
        // Get the delegation pool of the indexer
        DelegationPool storage pool = __delegationPools[_indexer];
        Delegation storage delegation = pool.delegators[_delegator];

        // Validation
        uint256 tokensToWithdraw = getWithdraweableDelegatedTokens(delegation);
        require(tokensToWithdraw > 0, "!tokens");

        // Reset lock
        delegation.tokensLocked = 0;
        delegation.tokensLockedUntil = 0;

        emit StakeDelegatedWithdrawn(_indexer, _delegator, tokensToWithdraw);

        // -- Interactions --

        if (_delegateToIndexer != address(0)) {
            // Re-delegate tokens to a new indexer
            _delegate(_delegator, _delegateToIndexer, tokensToWithdraw);
        } else {
            // Return tokens to the delegator
            TokenUtils.pushTokens(graphToken(), _delegator, tokensToWithdraw);
        }

        return tokensToWithdraw;
    }

    /**
     * @dev Collect tax to burn for an amount of tokens.
     * @param _graphToken Token to burn
     * @param _tokens Total tokens received used to calculate the amount of tax to collect
     * @param _percentage Percentage of tokens to burn as tax
     * @return Amount of tax charged
     */
    function _collectTax(
        IGraphToken _graphToken,
        uint256 _tokens,
        uint256 _percentage
    ) private returns (uint256) {
        uint256 tax = uint256(_percentage).mul(_tokens).div(MAX_PPM);
        TokenUtils.burnTokens(_graphToken, tax); // Burn tax if any
        return tax;
    }
}

// SPDX-License-Identifier: GPL-2.0-or-later

pragma solidity ^0.7.6;
pragma abicoder v2;

/**
 * @title Multicall interface
 * @notice Enables calling multiple methods in a single call to the contract
 */
interface IMulticall {
    /**
     * @notice Call multiple functions in the current contract and return the data from all of them if they all succeed
     * @param data The encoded function data for each of the calls to make to this contract
     * @return results The results from each of the calls passed in via data
     */
    function multicall(bytes[] calldata data) external returns (bytes[] memory results);
}

// SPDX-License-Identifier: GPL-2.0-or-later

pragma solidity ^0.7.6;

interface IGraphProxy {
    function admin() external returns (address);

    function setAdmin(address _newAdmin) external;

    function implementation() external returns (address);

    function pendingImplementation() external returns (address);

    function upgradeTo(address _newImplementation) external;

    function acceptUpgrade() external;

    function acceptUpgradeAndCall(bytes calldata data) external;
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20 {
    /**
     * @dev Returns the amount of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the amount of tokens owned by `account`.
     */
    function balanceOf(address account) external view returns (uint256);

    /**
     * @dev Moves `amount` tokens from the caller's account to `recipient`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address recipient, uint256 amount) external returns (bool);

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
     * @dev Moves `amount` tokens from `sender` to `recipient` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);

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
}

// SPDX-License-Identifier: GPL-2.0-or-later

pragma solidity >=0.6.12 <0.8.0;

/**
 * @title Staking Data interface
 * @dev This interface defines some structures used by the Staking contract.
 */
interface IStakingData {
    /**
     * @dev Allocate GRT tokens for the purpose of serving queries of a subgraph deployment
     * An allocation is created in the allocate() function and consumed in claim()
     */
    struct Allocation {
        address indexer;
        bytes32 subgraphDeploymentID;
        uint256 tokens; // Tokens allocated to a SubgraphDeployment
        uint256 createdAtEpoch; // Epoch when it was created
        uint256 closedAtEpoch; // Epoch when it was closed
        uint256 collectedFees; // Collected fees for the allocation
        uint256 effectiveAllocation; // Effective allocation when closed
        uint256 accRewardsPerAllocatedToken; // Snapshot used for reward calc
    }

    // -- Delegation Data --

    /**
     * @dev Delegation pool information. One per indexer.
     */
    struct DelegationPool {
        uint32 cooldownBlocks; // Blocks to wait before updating parameters
        uint32 indexingRewardCut; // in PPM
        uint32 queryFeeCut; // in PPM
        uint256 updatedAtBlock; // Block when the pool was last updated
        uint256 tokens; // Total tokens as pool reserves
        uint256 shares; // Total shares minted in the pool
        mapping(address => Delegation) delegators; // Mapping of delegator => Delegation
    }

    /**
     * @dev Individual delegation data of a delegator in a pool.
     */
    struct Delegation {
        uint256 shares; // Shares owned by a delegator in the pool
        uint256 tokensLocked; // Tokens locked for undelegation
        uint256 tokensLockedUntil; // Block when locked tokens can be withdrawn
    }
}

// SPDX-License-Identifier: GPL-2.0-or-later

pragma solidity >=0.6.12 <0.8.0;

interface IController {
    function getGovernor() external view returns (address);

    // -- Registry --

    function setContractProxy(bytes32 _id, address _contractAddress) external;

    function unsetContractProxy(bytes32 _id) external;

    function updateController(bytes32 _id, address _controller) external;

    function getContractProxy(bytes32 _id) external view returns (address);

    // -- Pausing --

    function setPartialPaused(bool _partialPaused) external;

    function setPaused(bool _paused) external;

    function setPauseGuardian(address _newPauseGuardian) external;

    function paused() external view returns (bool);

    function partialPaused() external view returns (bool);
}

// SPDX-License-Identifier: GPL-2.0-or-later

pragma solidity ^0.7.6;

interface IEpochManager {
    // -- Configuration --

    function setEpochLength(uint256 _epochLength) external;

    // -- Epochs

    function runEpoch() external;

    // -- Getters --

    function isCurrentEpochRun() external view returns (bool);

    function blockNum() external view returns (uint256);

    function blockHash(uint256 _block) external view returns (bytes32);

    function currentEpoch() external view returns (uint256);

    function currentEpochBlock() external view returns (uint256);

    function currentEpochBlockSinceStart() external view returns (uint256);

    function epochsSince(uint256 _epoch) external view returns (uint256);

    function epochsSinceUpdate() external view returns (uint256);
}

// SPDX-License-Identifier: GPL-2.0-or-later

pragma solidity >=0.6.12 <0.8.0;
pragma abicoder v2;

import { IStakingBase } from "./IStakingBase.sol";
import { IStakingExtension } from "./IStakingExtension.sol";
import { Stakes } from "./libs/Stakes.sol";
import { IStakingData } from "./IStakingData.sol";
import { Rebates } from "./libs/Rebates.sol";
import { IMulticall } from "../base/IMulticall.sol";
import { IManaged } from "../governance/IManaged.sol";

/**
 * @title Interface for the Staking contract
 * @notice This is the interface that should be used when interacting with the Staking contract.
 * @dev Note that Staking doesn't actually inherit this interface. This is because of
 * the custom setup of the Staking contract where part of the functionality is implemented
 * in a separate contract (StakingExtension) to which calls are delegated through the fallback function.
 */
interface IStaking is IStakingBase, IStakingExtension, IMulticall, IManaged {
    // Nothing to see here
}

// SPDX-License-Identifier: Apache-2.0

/*
 * Copyright 2020, Offchain Labs, Inc.
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *    http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 *
 * Originally copied from:
 * https://github.com/OffchainLabs/arbitrum/tree/e3a6307ad8a2dc2cad35728a2a9908cfd8dd8ef9/packages/arb-bridge-peripherals
 *
 * MODIFIED from Offchain Labs' implementation:
 * - Changed solidity version to 0.7.6 ([email protected])
 *
 */

pragma solidity ^0.7.6;

interface ITokenGateway {
    /// @notice event deprecated in favor of DepositInitiated and WithdrawalInitiated
    // event OutboundTransferInitiated(
    //     address token,
    //     address indexed _from,
    //     address indexed _to,
    //     uint256 indexed _transferId,
    //     uint256 _amount,
    //     bytes _data
    // );

    /// @notice event deprecated in favor of DepositFinalized and WithdrawalFinalized
    // event InboundTransferFinalized(
    //     address token,
    //     address indexed _from,
    //     address indexed _to,
    //     uint256 indexed _transferId,
    //     uint256 _amount,
    //     bytes _data
    // );

    function outboundTransfer(
        address _token,
        address _to,
        uint256 _amount,
        uint256 _maxGas,
        uint256 _gasPriceBid,
        bytes calldata _data
    ) external payable returns (bytes memory);

    function finalizeInboundTransfer(
        address _token,
        address _from,
        address _to,
        uint256 _amount,
        bytes calldata _data
    ) external payable;

    /**
     * @notice Calculate the address used when bridging an ERC20 token
     * @dev the L1 and L2 address oracles may not always be in sync.
     * For example, a custom token may have been registered but not deployed or the contract self destructed.
     * @param l1ERC20 address of L1 token
     * @return L2 address of a bridged ERC20 token
     */
    function calculateL2TokenAddress(address l1ERC20) external view returns (address);
}

// SPDX-License-Identifier: GPL-2.0-or-later

pragma solidity ^0.7.6;

/**
 * @title Interface for GNS
 */
interface IGNS {
    // -- Pool --

    /**
     * @dev The SubgraphData struct holds information about subgraphs
     * and their signal; both nSignal (i.e. name signal at the GNS level)
     * and vSignal (i.e. version signal at the Curation contract level)
     */
    struct SubgraphData {
        uint256 vSignal; // The token of the subgraph-deployment bonding curve
        uint256 nSignal; // The token of the subgraph bonding curve
        mapping(address => uint256) curatorNSignal;
        bytes32 subgraphDeploymentID;
        uint32 reserveRatioDeprecated; // Ratio for the bonding curve, always 1 in PPM, deprecated.
        bool disabled;
        uint256 withdrawableGRT;
    }

    /**
     * @dev The LegacySubgraphKey struct holds the account and sequence ID
     * used to generate subgraph IDs in legacy subgraphs.
     */
    struct LegacySubgraphKey {
        address account;
        uint256 accountSeqID;
    }

    // -- Configuration --

    /**
     * @notice Approve curation contract to pull funds.
     */
    function approveAll() external;

    /**
     * @notice Set the owner fee percentage. This is used to prevent a subgraph owner to drain all
     * the name curators tokens while upgrading or deprecating and is configurable in parts per million.
     * @param _ownerTaxPercentage Owner tax percentage
     */
    function setOwnerTaxPercentage(uint32 _ownerTaxPercentage) external;

    // -- Publishing --

    /**
     * @notice Allows a graph account to set a default name
     * @param _graphAccount Account that is setting its name
     * @param _nameSystem Name system account already has ownership of a name in
     * @param _nameIdentifier The unique identifier that is used to identify the name in the system
     * @param _name The name being set as default
     */
    function setDefaultName(
        address _graphAccount,
        uint8 _nameSystem,
        bytes32 _nameIdentifier,
        string calldata _name
    ) external;

    /**
     * @notice Allows a subgraph owner to update the metadata of a subgraph they have published
     * @param _subgraphID Subgraph ID
     * @param _subgraphMetadata IPFS hash for the subgraph metadata
     */
    function updateSubgraphMetadata(uint256 _subgraphID, bytes32 _subgraphMetadata) external;

    /**
     * @notice Publish a new subgraph.
     * @param _subgraphDeploymentID Subgraph deployment for the subgraph
     * @param _versionMetadata IPFS hash for the subgraph version metadata
     * @param _subgraphMetadata IPFS hash for the subgraph metadata
     */
    function publishNewSubgraph(
        bytes32 _subgraphDeploymentID,
        bytes32 _versionMetadata,
        bytes32 _subgraphMetadata
    ) external;

    /**
     * @notice Publish a new version of an existing subgraph.
     * @param _subgraphID Subgraph ID
     * @param _subgraphDeploymentID Subgraph deployment ID of the new version
     * @param _versionMetadata IPFS hash for the subgraph version metadata
     */
    function publishNewVersion(
        uint256 _subgraphID,
        bytes32 _subgraphDeploymentID,
        bytes32 _versionMetadata
    ) external;

    /**
     * @notice Deprecate a subgraph. The bonding curve is destroyed, the vSignal is burned, and the GNS
     * contract holds the GRT from burning the vSignal, which all curators can withdraw manually.
     * Can only be done by the subgraph owner.
     * @param _subgraphID Subgraph ID
     */
    function deprecateSubgraph(uint256 _subgraphID) external;

    // -- Curation --

    /**
     * @notice Deposit GRT into a subgraph and mint signal.
     * @param _subgraphID Subgraph ID
     * @param _tokensIn The amount of tokens the nameCurator wants to deposit
     * @param _nSignalOutMin Expected minimum amount of name signal to receive
     */
    function mintSignal(
        uint256 _subgraphID,
        uint256 _tokensIn,
        uint256 _nSignalOutMin
    ) external;

    /**
     * @notice Burn signal for a subgraph and return the GRT.
     * @param _subgraphID Subgraph ID
     * @param _nSignal The amount of nSignal the nameCurator wants to burn
     * @param _tokensOutMin Expected minimum amount of tokens to receive
     */
    function burnSignal(
        uint256 _subgraphID,
        uint256 _nSignal,
        uint256 _tokensOutMin
    ) external;

    /**
     * @notice Move subgraph signal from sender to `_recipient`
     * @param _subgraphID Subgraph ID
     * @param _recipient Address to send the signal to
     * @param _amount The amount of nSignal to transfer
     */
    function transferSignal(
        uint256 _subgraphID,
        address _recipient,
        uint256 _amount
    ) external;

    /**
     * @notice Withdraw tokens from a deprecated subgraph.
     * When the subgraph is deprecated, any curator can call this function and
     * withdraw the GRT they are entitled for its original deposit
     * @param _subgraphID Subgraph ID
     */
    function withdraw(uint256 _subgraphID) external;

    // -- Getters --

    /**
     * @notice Return the owner of a subgraph.
     * @param _tokenID Subgraph ID
     * @return Owner address
     */
    function ownerOf(uint256 _tokenID) external view returns (address);

    /**
     * @notice Return the total signal on the subgraph.
     * @param _subgraphID Subgraph ID
     * @return Total signal on the subgraph
     */
    function subgraphSignal(uint256 _subgraphID) external view returns (uint256);

    /**
     * @notice Return the total tokens on the subgraph at current value.
     * @param _subgraphID Subgraph ID
     * @return Total tokens on the subgraph
     */
    function subgraphTokens(uint256 _subgraphID) external view returns (uint256);

    /**
     * @notice Calculate subgraph signal to be returned for an amount of tokens.
     * @param _subgraphID Subgraph ID
     * @param _tokensIn Tokens being exchanged for subgraph signal
     * @return Amount of subgraph signal and curation tax
     */
    function tokensToNSignal(uint256 _subgraphID, uint256 _tokensIn)
        external
        view
        returns (
            uint256,
            uint256,
            uint256
        );

    /**
     * @notice Calculate tokens returned for an amount of subgraph signal.
     * @param _subgraphID Subgraph ID
     * @param _nSignalIn Subgraph signal being exchanged for tokens
     * @return Amount of tokens returned for an amount of subgraph signal
     */
    function nSignalToTokens(uint256 _subgraphID, uint256 _nSignalIn)
        external
        view
        returns (uint256, uint256);

    /**
     * @notice Calculate subgraph signal to be returned for an amount of subgraph deployment signal.
     * @param _subgraphID Subgraph ID
     * @param _vSignalIn Amount of subgraph deployment signal to exchange for subgraph signal
     * @return Amount of subgraph signal that can be bought
     */
    function vSignalToNSignal(uint256 _subgraphID, uint256 _vSignalIn)
        external
        view
        returns (uint256);

    /**
     * @notice Calculate subgraph deployment signal to be returned for an amount of subgraph signal.
     * @param _subgraphID Subgraph ID
     * @param _nSignalIn Subgraph signal being exchanged for subgraph deployment signal
     * @return Amount of subgraph deployment signal that can be returned
     */
    function nSignalToVSignal(uint256 _subgraphID, uint256 _nSignalIn)
        external
        view
        returns (uint256);

    /**
     * @notice Get the amount of subgraph signal a curator has.
     * @param _subgraphID Subgraph ID
     * @param _curator Curator address
     * @return Amount of subgraph signal owned by a curator
     */
    function getCuratorSignal(uint256 _subgraphID, address _curator)
        external
        view
        returns (uint256);

    /**
     * @notice Return whether a subgraph is published.
     * @param _subgraphID Subgraph ID
     * @return Return true if subgraph is currently published
     */
    function isPublished(uint256 _subgraphID) external view returns (bool);

    /**
     * @notice Return whether a subgraph is a legacy subgraph (created before subgraph NFTs).
     * @param _subgraphID Subgraph ID
     * @return Return true if subgraph is a legacy subgraph
     */
    function isLegacySubgraph(uint256 _subgraphID) external view returns (bool);

    /**
     * @notice Returns account and sequence ID for a legacy subgraph (created before subgraph NFTs).
     * @param _subgraphID Subgraph ID
     * @return account Account that created the subgraph (or 0 if it's not a legacy subgraph)
     * @return seqID Sequence number for the subgraph
     */
    function getLegacySubgraphKey(uint256 _subgraphID)
        external
        view
        returns (address account, uint256 seqID);
}

// SPDX-License-Identifier: GPL-2.0-or-later

pragma solidity ^0.7.6;

import { IController } from "./IController.sol";

/**
 * @title Managed Interface
 * @dev Interface for contracts that can be managed by a controller.
 */
interface IManaged {
    /**
     * @notice Set the controller that manages this contract
     * @dev Only the current controller can set a new controller
     * @param _controller Address of the new controller
     */
    function setController(address _controller) external;

    /**
     * @notice Sync protocol contract addresses from the Controller registry
     * @dev This function will cache all the contracts using the latest addresses.
     * Anyone can call the function whenever a Proxy contract change in the
     * controller to ensure the protocol is using the latest version.
     */
    function syncAllContracts() external;

    /**
     * @notice Get the Controller that manages this contract
     * @return The Controller as an IController interface
     */
    function controller() external view returns (IController);
}

// SPDX-License-Identifier: GPL-2.0-or-later

pragma solidity >=0.6.12 <0.8.0;
pragma abicoder v2;

import { IStakingData } from "./IStakingData.sol";
import { Rebates } from "./libs/Rebates.sol";
import { Stakes } from "./libs/Stakes.sol";

/**
 * @title Interface for the StakingExtension contract
 * @dev This interface defines the events and functions implemented
 * in the StakingExtension contract, which is used to extend the functionality
 * of the Staking contract while keeping it within the 24kB mainnet size limit.
 * In particular, this interface includes delegation functions and various storage
 * getters.
 */
interface IStakingExtension is IStakingData {
    /**
     * @dev DelegationPool struct as returned by delegationPools(), since
     * the original DelegationPool in IStakingData.sol contains a nested mapping.
     */
    struct DelegationPoolReturn {
        uint32 cooldownBlocks; // Blocks to wait before updating parameters
        uint32 indexingRewardCut; // in PPM
        uint32 queryFeeCut; // in PPM
        uint256 updatedAtBlock; // Block when the pool was last updated
        uint256 tokens; // Total tokens as pool reserves
        uint256 shares; // Total shares minted in the pool
    }

    /**
     * @dev Emitted when `delegator` delegated `tokens` to the `indexer`, the delegator
     * gets `shares` for the delegation pool proportionally to the tokens staked.
     */
    event StakeDelegated(
        address indexed indexer,
        address indexed delegator,
        uint256 tokens,
        uint256 shares
    );

    /**
     * @dev Emitted when `delegator` undelegated `tokens` from `indexer`.
     * Tokens get locked for withdrawal after a period of time.
     */
    event StakeDelegatedLocked(
        address indexed indexer,
        address indexed delegator,
        uint256 tokens,
        uint256 shares,
        uint256 until
    );

    /**
     * @dev Emitted when `delegator` withdrew delegated `tokens` from `indexer`.
     */
    event StakeDelegatedWithdrawn(
        address indexed indexer,
        address indexed delegator,
        uint256 tokens
    );

    /**
     * @dev Emitted when `indexer` was slashed for a total of `tokens` amount.
     * Tracks `reward` amount of tokens given to `beneficiary`.
     */
    event StakeSlashed(
        address indexed indexer,
        uint256 tokens,
        uint256 reward,
        address beneficiary
    );

    /**
     * @dev Emitted when `caller` set `slasher` address as `allowed` to slash stakes.
     */
    event SlasherUpdate(address indexed caller, address indexed slasher, bool allowed);

    /**
     * @notice Set the delegation ratio.
     * If set to 10 it means the indexer can use up to 10x the indexer staked amount
     * from their delegated tokens
     * @dev This function is only callable by the governor
     * @param _delegationRatio Delegation capacity multiplier
     */
    function setDelegationRatio(uint32 _delegationRatio) external;

    /**
     * @notice Set the minimum time in blocks an indexer needs to wait to change delegation parameters.
     * Indexers can set a custom amount time for their own cooldown, but it must be greater than this.
     * @dev This function is only callable by the governor
     * @param _blocks Number of blocks to set the delegation parameters cooldown period
     */
    function setDelegationParametersCooldown(uint32 _blocks) external;

    /**
     * @notice Set the time, in epochs, a Delegator needs to wait to withdraw tokens after undelegating.
     * @dev This function is only callable by the governor
     * @param _delegationUnbondingPeriod Period in epochs to wait for token withdrawals after undelegating
     */
    function setDelegationUnbondingPeriod(uint32 _delegationUnbondingPeriod) external;

    /**
     * @notice Set a delegation tax percentage to burn when delegated funds are deposited.
     * @dev This function is only callable by the governor
     * @param _percentage Percentage of delegated tokens to burn as delegation tax, expressed in parts per million
     */
    function setDelegationTaxPercentage(uint32 _percentage) external;

    /**
     * @notice Set or unset an address as allowed slasher.
     * @dev This function can only be called by the governor.
     * @param _slasher Address of the party allowed to slash indexers
     * @param _allowed True if slasher is allowed
     */
    function setSlasher(address _slasher, bool _allowed) external;

    /**
     * @notice Delegate tokens to an indexer.
     * @param _indexer Address of the indexer to which tokens are delegated
     * @param _tokens Amount of tokens to delegate
     * @return Amount of shares issued from the delegation pool
     */
    function delegate(address _indexer, uint256 _tokens) external returns (uint256);

    /**
     * @notice Undelegate tokens from an indexer. Tokens will be locked for the unbonding period.
     * @param _indexer Address of the indexer to which tokens had been delegated
     * @param _shares Amount of shares to return and undelegate tokens
     * @return Amount of tokens returned for the shares of the delegation pool
     */
    function undelegate(address _indexer, uint256 _shares) external returns (uint256);

    /**
     * @notice Withdraw undelegated tokens once the unbonding period has passed, and optionally
     * re-delegate to a new indexer.
     * @param _indexer Withdraw available tokens delegated to indexer
     * @param _newIndexer Re-delegate to indexer address if non-zero, withdraw if zero address
     */
    function withdrawDelegated(address _indexer, address _newIndexer) external returns (uint256);

    /**
     * @notice Slash the indexer stake. Delegated tokens are not subject to slashing.
     * @dev Can only be called by the slasher role.
     * @param _indexer Address of indexer to slash
     * @param _tokens Amount of tokens to slash from the indexer stake
     * @param _reward Amount of reward tokens to send to a beneficiary
     * @param _beneficiary Address of a beneficiary to receive a reward for the slashing
     */
    function slash(
        address _indexer,
        uint256 _tokens,
        uint256 _reward,
        address _beneficiary
    ) external;

    /**
     * @notice Return the delegation from a delegator to an indexer.
     * @param _indexer Address of the indexer where funds have been delegated
     * @param _delegator Address of the delegator
     * @return Delegation data
     */
    function getDelegation(address _indexer, address _delegator)
        external
        view
        returns (Delegation memory);

    /**
     * @notice Return whether the delegator has delegated to the indexer.
     * @param _indexer Address of the indexer where funds have been delegated
     * @param _delegator Address of the delegator
     * @return True if delegator has tokens delegated to the indexer
     */
    function isDelegator(address _indexer, address _delegator) external view returns (bool);

    /**
     * @notice Returns amount of delegated tokens ready to be withdrawn after unbonding period.
     * @param _delegation Delegation of tokens from delegator to indexer
     * @return Amount of tokens to withdraw
     */
    function getWithdraweableDelegatedTokens(Delegation memory _delegation)
        external
        view
        returns (uint256);

    /**
     * @notice Getter for the delegationRatio, i.e. the delegation capacity multiplier:
     * If delegation ratio is 100, and an Indexer has staked 5 GRT,
     * then they can use up to 500 GRT from the delegated stake
     * @return Delegation ratio
     */
    function delegationRatio() external view returns (uint32);

    /**
     * @notice Getter for delegationParametersCooldown:
     * Minimum time in blocks an indexer needs to wait to change delegation parameters
     * @return Delegation parameters cooldown in blocks
     */
    function delegationParametersCooldown() external view returns (uint32);

    /**
     * @notice Getter for delegationUnbondingPeriod:
     * Time in epochs a delegator needs to wait to withdraw delegated stake
     * @return Delegation unbonding period in epochs
     */
    function delegationUnbondingPeriod() external view returns (uint32);

    /**
     * @notice Getter for delegationTaxPercentage:
     * Percentage of tokens to tax a delegation deposit, expressed in parts per million
     * @return Delegation tax percentage in parts per million
     */
    function delegationTaxPercentage() external view returns (uint32);

    /**
     * @notice Getter for delegationPools[_indexer]:
     * gets the delegation pool structure for a particular indexer.
     * @param _indexer Address of the indexer for which to query the delegation pool
     * @return Delegation pool as a DelegationPoolReturn struct
     */
    function delegationPools(address _indexer) external view returns (DelegationPoolReturn memory);

    /**
     * @notice Getter for operatorAuth[_indexer][_maybeOperator]:
     * returns true if the operator is authorized to operate on behalf of the indexer.
     * @param _indexer The indexer address for which to query authorization
     * @param _maybeOperator The address that may or may not be an operator
     * @return True if the operator is authorized to operate on behalf of the indexer
     */
    function operatorAuth(address _indexer, address _maybeOperator) external view returns (bool);

    /**
     * @notice Getter for rewardsDestination[_indexer]:
     * returns the address where the indexer's rewards are sent.
     * @param _indexer The indexer address for which to query the rewards destination
     * @return The address where the indexer's rewards are sent, zero if none is set in which case rewards are re-staked
     */
    function rewardsDestination(address _indexer) external view returns (address);

    /**
     * @notice Getter for assetHolders[_maybeAssetHolder]:
     * returns true if the address is an asset holder, i.e. an entity that can collect
     * query fees into the Staking contract.
     * @param _maybeAssetHolder The address that may or may not be an asset holder
     * @return True if the address is an asset holder
     */
    function assetHolders(address _maybeAssetHolder) external view returns (bool);

    /**
     * @notice Getter for subgraphAllocations[_subgraphDeploymentId]:
     * returns the amount of tokens allocated to a subgraph deployment.
     * @param _subgraphDeploymentId The subgraph deployment for which to query the allocations
     * @return The amount of tokens allocated to the subgraph deployment
     */
    function subgraphAllocations(bytes32 _subgraphDeploymentId) external view returns (uint256);

    /**
     * @notice Getter for rebates[_epoch]:
     * gets the rebate pool for a particular epoch.
     * @param _epoch Epoch for which to query the rebate pool
     * @return Rebate pool for the specified epoch, as a Rebates.Pool struct
     */
    function rebates(uint256 _epoch) external view returns (Rebates.Pool memory);

    /**
     * @notice Getter for slashers[_maybeSlasher]:
     * returns true if the address is a slasher, i.e. an entity that can slash indexers
     * @param _maybeSlasher Address for which to check the slasher role
     * @return True if the address is a slasher
     */
    function slashers(address _maybeSlasher) external view returns (bool);

    /**
     * @notice Getter for minimumIndexerStake: the minimum
     * amount of GRT that an indexer needs to stake.
     * @return Minimum indexer stake in GRT
     */
    function minimumIndexerStake() external view returns (uint256);

    /**
     * @notice Getter for thawingPeriod: the time in blocks an
     * indexer needs to wait to unstake tokens.
     * @return Thawing period in blocks
     */
    function thawingPeriod() external view returns (uint32);

    /**
     * @notice Getter for curationPercentage: the percentage of
     * query fees that are distributed to curators.
     * @return Curation percentage in parts per million
     */
    function curationPercentage() external view returns (uint32);

    /**
     * @notice Getter for protocolPercentage: the percentage of
     * query fees that are burned as protocol fees.
     * @return Protocol percentage in parts per million
     */
    function protocolPercentage() external view returns (uint32);

    /**
     * @notice Getter for channelDisputeEpochs: the time in epochs
     * between closing an allocation and the moment it becomes finalized so
     * query fees can be claimed.
     * @return Channel dispute period in epochs
     */
    function channelDisputeEpochs() external view returns (uint32);

    /**
     * @notice Getter for maxAllocationEpochs: the maximum time in epochs
     * that an allocation can be open before anyone is allowed to close it. This
     * also caps the effective allocation when sending the allocation's query fees
     * to the rebate pool.
     * @return Maximum allocation period in epochs
     */
    function maxAllocationEpochs() external view returns (uint32);

    /**
     * @notice Getter for alphaNumerator: the numerator of the Cobb-Douglas
     * rebate ratio.
     * @return Rebate ratio numerator
     */
    function alphaNumerator() external view returns (uint32);

    /**
     * @notice Getter for alphaDenominator: the denominator of the Cobb-Douglas
     * rebate ratio.
     * @return Rebate ratio denominator
     */
    function alphaDenominator() external view returns (uint32);

    /**
     * @notice Getter for stakes[_indexer]:
     * gets the stake information for an indexer as a Stakes.Indexer struct.
     * @param _indexer Indexer address for which to query the stake information
     * @return Stake information for the specified indexer, as a Stakes.Indexer struct
     */
    function stakes(address _indexer) external view returns (Stakes.Indexer memory);

    /**
     * @notice Getter for allocations[_allocationID]:
     * gets an allocation's information as an IStakingData.Allocation struct.
     * @param _allocationID Allocation ID for which to query the allocation information
     * @return The specified allocation, as an IStakingData.Allocation struct
     */
    function allocations(address _allocationID)
        external
        view
        returns (IStakingData.Allocation memory);
}

/*

  Copyright 2019 ZeroEx Intl.

  Licensed under the Apache License, Version 2.0 (the "License");
  you may not use this file except in compliance with the License.
  You may obtain a copy of the License at

    http://www.apache.org/licenses/LICENSE-2.0

  Unless required by applicable law or agreed to in writing, software
  distributed under the License is distributed on an "AS IS" BASIS,
  WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
  See the License for the specific language governing permissions and
  limitations under the License.

*/

// SPDX-License-Identifier: Apache-2.0

pragma solidity ^0.7.6;
pragma abicoder v2;

import "./LibFixedMath.sol";

library LibCobbDouglas {
    /// @dev The cobb-douglas function used to compute fee-based rewards for
    ///      staking pools in a given epoch. This function does not perform
    ///      bounds checking on the inputs, but the following conditions
    ///      need to be true:
    ///         0 <= fees / totalFees <= 1
    ///         0 <= stake / totalStake <= 1
    ///         0 <= alphaNumerator / alphaDenominator <= 1
    /// @param totalRewards collected over an epoch.
    /// @param fees Fees attributed to the the staking pool.
    /// @param totalFees Total fees collected across all pools that earned rewards.
    /// @param stake Stake attributed to the staking pool.
    /// @param totalStake Total stake across all pools that earned rewards.
    /// @param alphaNumerator Numerator of `alpha` in the cobb-douglas function.
    /// @param alphaDenominator Denominator of `alpha` in the cobb-douglas
    ///        function.
    /// @return rewards Rewards owed to the staking pool.
    function cobbDouglas(
        uint256 totalRewards,
        uint256 fees,
        uint256 totalFees,
        uint256 stake,
        uint256 totalStake,
        uint32 alphaNumerator,
        uint32 alphaDenominator
    ) public pure returns (uint256 rewards) {
        int256 feeRatio = LibFixedMath.toFixed(fees, totalFees);
        int256 stakeRatio = LibFixedMath.toFixed(stake, totalStake);
        if (feeRatio == 0 || stakeRatio == 0) {
            return rewards = 0;
        }
        // The cobb-doublas function has the form:
        // `totalRewards * feeRatio ^ alpha * stakeRatio ^ (1-alpha)`
        // This is equivalent to:
        // `totalRewards * stakeRatio * e^(alpha * (ln(feeRatio / stakeRatio)))`
        // However, because `ln(x)` has the domain of `0 < x < 1`
        // and `exp(x)` has the domain of `x < 0`,
        // and fixed-point math easily overflows with multiplication,
        // we will choose the following if `stakeRatio > feeRatio`:
        // `totalRewards * stakeRatio / e^(alpha * (ln(stakeRatio / feeRatio)))`

        // Compute
        // `e^(alpha * ln(feeRatio/stakeRatio))` if feeRatio <= stakeRatio
        // or
        // `e^(alpa * ln(stakeRatio/feeRatio))` if feeRatio > stakeRatio
        int256 n = feeRatio <= stakeRatio
            ? LibFixedMath.div(feeRatio, stakeRatio)
            : LibFixedMath.div(stakeRatio, feeRatio);
        n = LibFixedMath.exp(
            LibFixedMath.mulDiv(
                LibFixedMath.ln(n),
                int256(alphaNumerator),
                int256(alphaDenominator)
            )
        );
        // Compute
        // `totalRewards * n` if feeRatio <= stakeRatio
        // or
        // `totalRewards / n` if stakeRatio > feeRatio
        // depending on the choice we made earlier.
        n = feeRatio <= stakeRatio
            ? LibFixedMath.mul(stakeRatio, n)
            : LibFixedMath.div(stakeRatio, n);
        // Multiply the above with totalRewards.
        rewards = LibFixedMath.uintMul(n, totalRewards);
    }
}

/*

  Copyright 2017 Bprotocol Foundation, 2019 ZeroEx Intl.

  Licensed under the Apache License, Version 2.0 (the "License");
  you may not use this file except in compliance with the License.
  You may obtain a copy of the License at

    http://www.apache.org/licenses/LICENSE-2.0

  Unless required by applicable law or agreed to in writing, software
  distributed under the License is distributed on an "AS IS" BASIS,
  WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
  See the License for the specific language governing permissions and
  limitations under the License.

*/

// SPDX-License-Identifier: Apache-2.0

pragma solidity ^0.7.6;

// solhint-disable indent
/// @dev Signed, fixed-point, 127-bit precision math library.
library LibFixedMath {
    // 1
    int256 private constant FIXED_1 =
        int256(0x0000000000000000000000000000000080000000000000000000000000000000);
    // 2**255
    int256 private constant MIN_FIXED_VAL =
        int256(0x8000000000000000000000000000000000000000000000000000000000000000);
    // 1^2 (in fixed-point)
    int256 private constant FIXED_1_SQUARED =
        int256(0x4000000000000000000000000000000000000000000000000000000000000000);
    // 1
    int256 private constant LN_MAX_VAL = FIXED_1;
    // e ^ -63.875
    int256 private constant LN_MIN_VAL =
        int256(0x0000000000000000000000000000000000000000000000000000000733048c5a);
    // 0
    int256 private constant EXP_MAX_VAL = 0;
    // -63.875
    int256 private constant EXP_MIN_VAL =
        -int256(0x0000000000000000000000000000001ff0000000000000000000000000000000);

    /// @dev Get one as a fixed-point number.
    function one() internal pure returns (int256 f) {
        f = FIXED_1;
    }

    /// @dev Returns the addition of two fixed point numbers, reverting on overflow.
    function add(int256 a, int256 b) internal pure returns (int256 c) {
        c = _add(a, b);
    }

    /// @dev Returns the addition of two fixed point numbers, reverting on overflow.
    function sub(int256 a, int256 b) internal pure returns (int256 c) {
        if (b == MIN_FIXED_VAL) {
            revert("out-of-bounds");
        }
        c = _add(a, -b);
    }

    /// @dev Returns the multiplication of two fixed point numbers, reverting on overflow.
    function mul(int256 a, int256 b) internal pure returns (int256 c) {
        c = _mul(a, b) / FIXED_1;
    }

    /// @dev Returns the division of two fixed point numbers.
    function div(int256 a, int256 b) internal pure returns (int256 c) {
        c = _div(_mul(a, FIXED_1), b);
    }

    /// @dev Performs (a * n) / d, without scaling for precision.
    function mulDiv(
        int256 a,
        int256 n,
        int256 d
    ) internal pure returns (int256 c) {
        c = _div(_mul(a, n), d);
    }

    /// @dev Returns the unsigned integer result of multiplying a fixed-point
    ///      number with an integer, reverting if the multiplication overflows.
    ///      Negative results are clamped to zero.
    function uintMul(int256 f, uint256 u) internal pure returns (uint256) {
        if (int256(u) < int256(0)) {
            revert("out-of-bounds");
        }
        int256 c = _mul(f, int256(u));
        if (c <= 0) {
            return 0;
        }
        return uint256(uint256(c) >> 127);
    }

    /// @dev Returns the absolute value of a fixed point number.
    function abs(int256 f) internal pure returns (int256 c) {
        if (f == MIN_FIXED_VAL) {
            revert("out-of-bounds");
        }
        if (f >= 0) {
            c = f;
        } else {
            c = -f;
        }
    }

    /// @dev Returns 1 / `x`, where `x` is a fixed-point number.
    function invert(int256 f) internal pure returns (int256 c) {
        c = _div(FIXED_1_SQUARED, f);
    }

    /// @dev Convert signed `n` / 1 to a fixed-point number.
    function toFixed(int256 n) internal pure returns (int256 f) {
        f = _mul(n, FIXED_1);
    }

    /// @dev Convert signed `n` / `d` to a fixed-point number.
    function toFixed(int256 n, int256 d) internal pure returns (int256 f) {
        f = _div(_mul(n, FIXED_1), d);
    }

    /// @dev Convert unsigned `n` / 1 to a fixed-point number.
    ///      Reverts if `n` is too large to fit in a fixed-point number.
    function toFixed(uint256 n) internal pure returns (int256 f) {
        if (int256(n) < int256(0)) {
            revert("out-of-bounds");
        }
        f = _mul(int256(n), FIXED_1);
    }

    /// @dev Convert unsigned `n` / `d` to a fixed-point number.
    ///      Reverts if `n` / `d` is too large to fit in a fixed-point number.
    function toFixed(uint256 n, uint256 d) internal pure returns (int256 f) {
        if (int256(n) < int256(0)) {
            revert("out-of-bounds");
        }
        if (int256(d) < int256(0)) {
            revert("out-of-bounds");
        }
        f = _div(_mul(int256(n), FIXED_1), int256(d));
    }

    /// @dev Convert a fixed-point number to an integer.
    function toInteger(int256 f) internal pure returns (int256 n) {
        return f / FIXED_1;
    }

    /// @dev Get the natural logarithm of a fixed-point number 0 < `x` <= LN_MAX_VAL
    function ln(int256 x) internal pure returns (int256 r) {
        if (x > LN_MAX_VAL) {
            revert("out-of-bounds");
        }
        if (x <= 0) {
            revert("too-small");
        }
        if (x == FIXED_1) {
            return 0;
        }
        if (x <= LN_MIN_VAL) {
            return EXP_MIN_VAL;
        }

        int256 y;
        int256 z;
        int256 w;

        // Rewrite the input as a quotient of negative natural exponents and a single residual q, such that 1 < q < 2
        // For example: log(0.3) = log(e^-1 * e^-0.25 * 1.0471028872385522)
        //              = 1 - 0.25 - log(1 + 0.0471028872385522)
        // e ^ -32
        if (x <= int256(0x00000000000000000000000000000000000000000001c8464f76164760000000)) {
            r -= int256(0x0000000000000000000000000000001000000000000000000000000000000000); // - 32
            x =
                (x * FIXED_1) /
                int256(0x00000000000000000000000000000000000000000001c8464f76164760000000); // / e ^ -32
        }
        // e ^ -16
        if (x <= int256(0x00000000000000000000000000000000000000f1aaddd7742e90000000000000)) {
            r -= int256(0x0000000000000000000000000000000800000000000000000000000000000000); // - 16
            x =
                (x * FIXED_1) /
                int256(0x00000000000000000000000000000000000000f1aaddd7742e90000000000000); // / e ^ -16
        }
        // e ^ -8
        if (x <= int256(0x00000000000000000000000000000000000afe10820813d78000000000000000)) {
            r -= int256(0x0000000000000000000000000000000400000000000000000000000000000000); // - 8
            x =
                (x * FIXED_1) /
                int256(0x00000000000000000000000000000000000afe10820813d78000000000000000); // / e ^ -8
        }
        // e ^ -4
        if (x <= int256(0x0000000000000000000000000000000002582ab704279ec00000000000000000)) {
            r -= int256(0x0000000000000000000000000000000200000000000000000000000000000000); // - 4
            x =
                (x * FIXED_1) /
                int256(0x0000000000000000000000000000000002582ab704279ec00000000000000000); // / e ^ -4
        }
        // e ^ -2
        if (x <= int256(0x000000000000000000000000000000001152aaa3bf81cc000000000000000000)) {
            r -= int256(0x0000000000000000000000000000000100000000000000000000000000000000); // - 2
            x =
                (x * FIXED_1) /
                int256(0x000000000000000000000000000000001152aaa3bf81cc000000000000000000); // / e ^ -2
        }
        // e ^ -1
        if (x <= int256(0x000000000000000000000000000000002f16ac6c59de70000000000000000000)) {
            r -= int256(0x0000000000000000000000000000000080000000000000000000000000000000); // - 1
            x =
                (x * FIXED_1) /
                int256(0x000000000000000000000000000000002f16ac6c59de70000000000000000000); // / e ^ -1
        }
        // e ^ -0.5
        if (x <= int256(0x000000000000000000000000000000004da2cbf1be5828000000000000000000)) {
            r -= int256(0x0000000000000000000000000000000040000000000000000000000000000000); // - 0.5
            x =
                (x * FIXED_1) /
                int256(0x000000000000000000000000000000004da2cbf1be5828000000000000000000); // / e ^ -0.5
        }
        // e ^ -0.25
        if (x <= int256(0x0000000000000000000000000000000063afbe7ab2082c000000000000000000)) {
            r -= int256(0x0000000000000000000000000000000020000000000000000000000000000000); // - 0.25
            x =
                (x * FIXED_1) /
                int256(0x0000000000000000000000000000000063afbe7ab2082c000000000000000000); // / e ^ -0.25
        }
        // e ^ -0.125
        if (x <= int256(0x0000000000000000000000000000000070f5a893b608861e1f58934f97aea57d)) {
            r -= int256(0x0000000000000000000000000000000010000000000000000000000000000000); // - 0.125
            x =
                (x * FIXED_1) /
                int256(0x0000000000000000000000000000000070f5a893b608861e1f58934f97aea57d); // / e ^ -0.125
        }
        // `x` is now our residual in the range of 1 <= x <= 2 (or close enough).

        // Add the taylor series for log(1 + z), where z = x - 1
        z = y = x - FIXED_1;
        w = (y * y) / FIXED_1;
        r += (z * (0x100000000000000000000000000000000 - y)) / 0x100000000000000000000000000000000;
        z = (z * w) / FIXED_1; // add y^01 / 01 - y^02 / 02
        r += (z * (0x0aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa - y)) / 0x200000000000000000000000000000000;
        z = (z * w) / FIXED_1; // add y^03 / 03 - y^04 / 04
        r += (z * (0x099999999999999999999999999999999 - y)) / 0x300000000000000000000000000000000;
        z = (z * w) / FIXED_1; // add y^05 / 05 - y^06 / 06
        r += (z * (0x092492492492492492492492492492492 - y)) / 0x400000000000000000000000000000000;
        z = (z * w) / FIXED_1; // add y^07 / 07 - y^08 / 08
        r += (z * (0x08e38e38e38e38e38e38e38e38e38e38e - y)) / 0x500000000000000000000000000000000;
        z = (z * w) / FIXED_1; // add y^09 / 09 - y^10 / 10
        r += (z * (0x08ba2e8ba2e8ba2e8ba2e8ba2e8ba2e8b - y)) / 0x600000000000000000000000000000000;
        z = (z * w) / FIXED_1; // add y^11 / 11 - y^12 / 12
        r += (z * (0x089d89d89d89d89d89d89d89d89d89d89 - y)) / 0x700000000000000000000000000000000;
        z = (z * w) / FIXED_1; // add y^13 / 13 - y^14 / 14
        r += (z * (0x088888888888888888888888888888888 - y)) / 0x800000000000000000000000000000000; // add y^15 / 15 - y^16 / 16
    }

    /// @dev Compute the natural exponent for a fixed-point number EXP_MIN_VAL <= `x` <= 1
    function exp(int256 x) internal pure returns (int256 r) {
        if (x < EXP_MIN_VAL) {
            // Saturate to zero below EXP_MIN_VAL.
            return 0;
        }
        if (x == 0) {
            return FIXED_1;
        }
        if (x > EXP_MAX_VAL) {
            revert("out-of-bounds");
        }

        // Rewrite the input as a product of natural exponents and a
        // single residual q, where q is a number of small magnitude.
        // For example: e^-34.419 = e^(-32 - 2 - 0.25 - 0.125 - 0.044)
        //              = e^-32 * e^-2 * e^-0.25 * e^-0.125 * e^-0.044
        //              -> q = -0.044

        // Multiply with the taylor series for e^q
        int256 y;
        int256 z;
        // q = x % 0.125 (the residual)
        z = y = x % 0x0000000000000000000000000000000010000000000000000000000000000000;
        z = (z * y) / FIXED_1;
        r += z * 0x10e1b3be415a0000; // add y^02 * (20! / 02!)
        z = (z * y) / FIXED_1;
        r += z * 0x05a0913f6b1e0000; // add y^03 * (20! / 03!)
        z = (z * y) / FIXED_1;
        r += z * 0x0168244fdac78000; // add y^04 * (20! / 04!)
        z = (z * y) / FIXED_1;
        r += z * 0x004807432bc18000; // add y^05 * (20! / 05!)
        z = (z * y) / FIXED_1;
        r += z * 0x000c0135dca04000; // add y^06 * (20! / 06!)
        z = (z * y) / FIXED_1;
        r += z * 0x0001b707b1cdc000; // add y^07 * (20! / 07!)
        z = (z * y) / FIXED_1;
        r += z * 0x000036e0f639b800; // add y^08 * (20! / 08!)
        z = (z * y) / FIXED_1;
        r += z * 0x00000618fee9f800; // add y^09 * (20! / 09!)
        z = (z * y) / FIXED_1;
        r += z * 0x0000009c197dcc00; // add y^10 * (20! / 10!)
        z = (z * y) / FIXED_1;
        r += z * 0x0000000e30dce400; // add y^11 * (20! / 11!)
        z = (z * y) / FIXED_1;
        r += z * 0x000000012ebd1300; // add y^12 * (20! / 12!)
        z = (z * y) / FIXED_1;
        r += z * 0x0000000017499f00; // add y^13 * (20! / 13!)
        z = (z * y) / FIXED_1;
        r += z * 0x0000000001a9d480; // add y^14 * (20! / 14!)
        z = (z * y) / FIXED_1;
        r += z * 0x00000000001c6380; // add y^15 * (20! / 15!)
        z = (z * y) / FIXED_1;
        r += z * 0x000000000001c638; // add y^16 * (20! / 16!)
        z = (z * y) / FIXED_1;
        r += z * 0x0000000000001ab8; // add y^17 * (20! / 17!)
        z = (z * y) / FIXED_1;
        r += z * 0x000000000000017c; // add y^18 * (20! / 18!)
        z = (z * y) / FIXED_1;
        r += z * 0x0000000000000014; // add y^19 * (20! / 19!)
        z = (z * y) / FIXED_1;
        r += z * 0x0000000000000001; // add y^20 * (20! / 20!)
        r = r / 0x21c3677c82b40000 + y + FIXED_1; // divide by 20! and then add y^1 / 1! + y^0 / 0!

        // Multiply with the non-residual terms.
        x = -x;
        // e ^ -32
        if ((x & int256(0x0000000000000000000000000000001000000000000000000000000000000000)) != 0) {
            r =
                (r * int256(0x00000000000000000000000000000000000000f1aaddd7742e56d32fb9f99744)) /
                int256(0x0000000000000000000000000043cbaf42a000812488fc5c220ad7b97bf6e99e); // * e ^ -32
        }
        // e ^ -16
        if ((x & int256(0x0000000000000000000000000000000800000000000000000000000000000000)) != 0) {
            r =
                (r * int256(0x00000000000000000000000000000000000afe10820813d65dfe6a33c07f738f)) /
                int256(0x000000000000000000000000000005d27a9f51c31b7c2f8038212a0574779991); // * e ^ -16
        }
        // e ^ -8
        if ((x & int256(0x0000000000000000000000000000000400000000000000000000000000000000)) != 0) {
            r =
                (r * int256(0x0000000000000000000000000000000002582ab704279e8efd15e0265855c47a)) /
                int256(0x0000000000000000000000000000001b4c902e273a58678d6d3bfdb93db96d02); // * e ^ -8
        }
        // e ^ -4
        if ((x & int256(0x0000000000000000000000000000000200000000000000000000000000000000)) != 0) {
            r =
                (r * int256(0x000000000000000000000000000000001152aaa3bf81cb9fdb76eae12d029571)) /
                int256(0x00000000000000000000000000000003b1cc971a9bb5b9867477440d6d157750); // * e ^ -4
        }
        // e ^ -2
        if ((x & int256(0x0000000000000000000000000000000100000000000000000000000000000000)) != 0) {
            r =
                (r * int256(0x000000000000000000000000000000002f16ac6c59de6f8d5d6f63c1482a7c86)) /
                int256(0x000000000000000000000000000000015bf0a8b1457695355fb8ac404e7a79e3); // * e ^ -2
        }
        // e ^ -1
        if ((x & int256(0x0000000000000000000000000000000080000000000000000000000000000000)) != 0) {
            r =
                (r * int256(0x000000000000000000000000000000004da2cbf1be5827f9eb3ad1aa9866ebb3)) /
                int256(0x00000000000000000000000000000000d3094c70f034de4b96ff7d5b6f99fcd8); // * e ^ -1
        }
        // e ^ -0.5
        if ((x & int256(0x0000000000000000000000000000000040000000000000000000000000000000)) != 0) {
            r =
                (r * int256(0x0000000000000000000000000000000063afbe7ab2082ba1a0ae5e4eb1b479dc)) /
                int256(0x00000000000000000000000000000000a45af1e1f40c333b3de1db4dd55f29a7); // * e ^ -0.5
        }
        // e ^ -0.25
        if ((x & int256(0x0000000000000000000000000000000020000000000000000000000000000000)) != 0) {
            r =
                (r * int256(0x0000000000000000000000000000000070f5a893b608861e1f58934f97aea57d)) /
                int256(0x00000000000000000000000000000000910b022db7ae67ce76b441c27035c6a1); // * e ^ -0.25
        }
        // e ^ -0.125
        if ((x & int256(0x0000000000000000000000000000000010000000000000000000000000000000)) != 0) {
            r =
                (r * int256(0x00000000000000000000000000000000783eafef1c0a8f3978c7f81824d62ebf)) /
                int256(0x0000000000000000000000000000000088415abbe9a76bead8d00cf112e4d4a8); // * e ^ -0.125
        }
    }

    /// @dev Returns the multiplication two numbers, reverting on overflow.
    function _mul(int256 a, int256 b) private pure returns (int256 c) {
        if (a == 0) {
            return 0;
        }
        c = a * b;
        if (c / a != b || c / b != a) {
            revert("overflow");
        }
    }

    /// @dev Returns the division of two numbers, reverting on division by zero.
    function _div(int256 a, int256 b) private pure returns (int256 c) {
        if (b == 0) {
            revert("overflow");
        }
        if (a == MIN_FIXED_VAL && b == -1) {
            revert("overflow");
        }
        c = a / b;
    }

    /// @dev Adds two numbers, reverting on overflow.
    function _add(int256 a, int256 b) private pure returns (int256 c) {
        c = a + b;
        if ((a < 0 && b < 0 && c > a) || (a > 0 && b > 0 && c < a)) {
            revert("overflow");
        }
    }
}

// SPDX-License-Identifier: GPL-2.0-or-later

/**
 * @title Interface for contracts that can receive callhooks through the Arbitrum GRT bridge
 * @dev Any contract that can receive a callhook on L2, sent through the bridge from L1, must
 * be allowlisted by the governor, but also implement this interface that contains
 * the function that will actually be called by the L2GraphTokenGateway.
 */
pragma solidity ^0.7.6;

interface ICallhookReceiver {
    /**
     * @notice Receive tokens with a callhook from the bridge
     * @param _from Token sender in L1
     * @param _amount Amount of tokens that were transferred
     * @param _data ABI-encoded callhook data
     */
    function onTokenTransfer(
        address _from,
        uint256 _amount,
        bytes calldata _data
    ) external;
}