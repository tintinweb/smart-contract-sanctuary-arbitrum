// SPDX-License-Identifier: None
// Raffl Protocol (last updated v1.0.0) (RafflFactory.sol)
pragma solidity ^0.8.25;

import { VRFV2PlusClient } from "@chainlink/contracts/src/v0.8/vrf/dev/libraries/VRFV2PlusClient.sol";
import { VRFConsumerBaseV2Plus } from "@chainlink/contracts/src/v0.8/vrf/dev/VRFConsumerBaseV2Plus.sol";
import { AutomationCompatibleInterface } from "@chainlink/contracts/src/v0.8/automation/AutomationCompatible.sol";

import { Errors } from "./libraries/RafflFactoryErrors.sol";

import { FactoryFeeManager } from "./abstracts/FactoryFeeManager.sol";

import { IRaffl } from "./interfaces/IRaffl.sol";
import { IFactoryFeeManager } from "./interfaces/IFactoryFeeManager.sol";

/*
                                                                       
  _____            ______ ______ _      
 |  __ \     /\   |  ____|  ____| |     
 | |__) |   /  \  | |__  | |__  | |     
 |  _  /   / /\ \ |  __| |  __| | |     
 | | \ \  / ____ \| |    | |    | |____ 
 |_|  \_\/_/    \_\_|    |_|    |______|                               
                                                                       
 */

/// @title RafflFactory
/// @author JA (@ubinatus)
/// @notice Raffl is a decentralized platform built on the Ethereum blockchain, allowing users to create and participate
/// in raffles/lotteries with complete transparency, security, and fairness.
/// @dev The RafflFactory contract can be used to create raffle contracts, leveraging Chainlink VRF and Chainlink
/// Automations.
contract RafflFactory is AutomationCompatibleInterface, VRFConsumerBaseV2Plus, FactoryFeeManager {
    /// @dev Max gas to bump to
    bytes32 keyHash;

    /// @dev Callback gas limit for the Chainlink VRF
    uint32 callbackGasLimit = 500_000;

    /// @dev Number of requests confirmations for the Chainlink VRF
    uint16 requestConfirmations = 3;

    /// @dev Chainlink subscription ID
    uint256 public subscriptionId;

    /// @param raffle Address of the created raffle
    event RaffleCreated(address raffle);

    /// @notice The address that will be used as a delegate call target for `Raffl`s.
    address public immutable implementation;

    /// @dev It will be used as the salt for create2
    bytes32 internal _salt;

    /// @dev Maps the created `Raffl`s addresses
    mapping(address => bool) internal _raffles;

    /// @dev Maps the VRF `requestId` to the `Raffl`s address
    mapping(uint256 => address) internal _requestIds;

    /// @dev `raffle` the address of the raffle
    /// @dev `deadline` is the timestamp that marks the start time to perform the upkeep effect.
    struct ActiveRaffle {
        address raffle;
        uint256 deadline;
    }

    /// @dev Stores the active raffles, which upkeep is pending to be performed
    ActiveRaffle[] internal _activeRaffles;

    /**
     * @dev Creates a `Raffl` factory contract.
     *
     * Requirements:
     *
     * - `implementationAddress` has to be a contract.
     * - `feeCollectorAddress` can't be address 0x0.
     * - `poolFeePercentage` must be within 0 and maxFee range.
     * - `vrfCoordinator` can't be address 0x0.
     *
     * @param implementationAddress Address of `Raffl` contract implementation.
     * @param feeCollectorAddress   Address of `feeCollector`.
     * @param creationFeeValue    Value for `creationFee` that will be charged on new `Raffl`s deployed.
     * @param poolFeePercentage    Value for `poolFeePercentage` that will be charged from the `Raffl`s pool on success
     * draw.
     * @param vrfCoordinator VRF Coordinator address
     * @param _keyHash The gas lane to use, which specifies the maximum gas price to bump to
     * @param _subscriptionId The subscription ID that this contract uses for funding VRF requests
     */
    constructor(
        address implementationAddress,
        address feeCollectorAddress,
        uint64 creationFeeValue,
        uint64 poolFeePercentage,
        address vrfCoordinator,
        bytes32 _keyHash,
        uint256 _subscriptionId
    )
        VRFConsumerBaseV2Plus(vrfCoordinator)
    {
        if (implementationAddress == address(0)) revert Errors.AddressCanNotBeZero();
        if (feeCollectorAddress == address(0)) revert Errors.AddressCanNotBeZero();
        if (vrfCoordinator == address(0)) revert Errors.AddressCanNotBeZero();
        if (poolFeePercentage > MAX_POOL_FEE) revert Errors.FeeOutOfRange();

        bytes32 seed;
        assembly ("memory-safe") {
            seed := chainid()
        }
        _salt = seed;

        implementation = implementationAddress;
        _feeData.feeCollector = feeCollectorAddress;
        _upcomingCreationFee.nextValue = creationFeeValue;
        _upcomingPoolFee.nextValue = poolFeePercentage;

        keyHash = _keyHash;
        subscriptionId = _subscriptionId;
    }

    /// @notice Increments the salt one step.
    function nextSalt() public {
        _salt = keccak256(abi.encode(_salt));
    }

    /**
     * @notice Creates new `Raffl` contracts.
     *
     * Requirements:
     *
     * - `underlyingTokenAddress` cannot be the zero address.
     * - `timestamps` must be given in ascending order.
     * - `percentages` must be given in ascending order and the last one must always be 1 eth, where 1 eth equals to
     * 100%.
     *
     * @param entryToken        The address of the ERC-20 token as entry. If address zero, entry is the network token
     * @param entryPrice        The value of each entry for the raffle.
     * @param minEntries        The minimum number of entries to consider make the draw.
     * @param deadline          The block timestamp until the raffle will receive entries
     *                          and that will perform the draw if criteria is met.
     * @param prizes            The prizes that will be held by this contract.
     * @param tokenGates        The token gating that will be imposed to users.
     * @param extraRecipient    The extra recipient that will share the rewards (optional).
     */
    function createRaffle(
        address entryToken,
        uint256 entryPrice,
        uint256 minEntries,
        uint256 deadline,
        IRaffl.Prize[] calldata prizes,
        IRaffl.TokenGate[] calldata tokenGates,
        IRaffl.ExtraRecipient calldata extraRecipient
    )
        external
        payable
        returns (address raffle)
    {
        if (block.timestamp >= deadline) revert Errors.DeadlineIsNotFuture();

        address impl = implementation;
        bytes32 salt = _salt;

        // Deploys and returns the address of a clone that mimics the behaviour of `implementation`.
        assembly ("memory-safe") {
            // Cleans the upper 96 bits of the `implementation` word, then packs the first 3 bytes
            // of the `implementation` address with the bytecode before the address.
            mstore(0x00, or(shr(0xe8, shl(0x60, impl)), 0x3d602d80600a3d3981f3363d3d373d3d3d363d73000000))
            // Packs the remaining 17 bytes of `implementation` with the bytecode after the address.
            mstore(0x20, or(shl(0x78, impl), 0x5af43d82803e903d91602b57fd5bf3))
            raffle := create2(0, 0x09, 0x37, salt)
        }

        if (raffle == address(0)) revert Errors.FailedToDeploy();
        nextSalt();

        _processCreationFee(msg.sender);

        IRaffl(raffle).initialize(
            entryToken, entryPrice, minEntries, deadline, msg.sender, prizes, tokenGates, extraRecipient
        );

        uint256 i = prizes.length;
        for (i; i != 0;) {
            unchecked {
                --i;
            }

            if (prizes[i].assetType == IRaffl.AssetType.ERC20 && prizes[i].value == 0) {
                revert Errors.ERC20PrizeAmountIsZero();
            }
            (bool success,) = prizes[i].asset.call(
                abi.encodeWithSignature("transferFrom(address,address,uint256)", msg.sender, raffle, prizes[i].value)
            );

            if (!success) revert Errors.UnsuccessfulTransferFromPrize();
        }

        _raffles[raffle] = true;
        _activeRaffles.push(ActiveRaffle(raffle, deadline));
        emit RaffleCreated(raffle);
    }

    /// @notice Exposes the `_raffles` mapping
    function isRaffle(address raffle) public view returns (bool) {
        return _raffles[raffle];
    }

    /// @notice Exposes the `ActiveRaffle`s
    function activeRaffles() public view returns (ActiveRaffle[] memory) {
        return _activeRaffles;
    }

    /// @notice Sets the Chainlink VRF subscription settings
    /// @param _subscriptionId The subscription ID that this contract uses for funding VRF requests
    /// @param _keyHash The gas lane to use, which specifies the maximum gas price to bump to
    /// @param _callbackGasLimit Callback gas limit for the Chainlink VRF
    /// @param _requestConfirmations Number of requests confirmations for the Chainlink VRF
    function handleSubscription(
        uint64 _subscriptionId,
        bytes32 _keyHash,
        uint32 _callbackGasLimit,
        uint16 _requestConfirmations
    )
        external
        onlyOwner
    {
        subscriptionId = _subscriptionId;
        keyHash = _keyHash;
        callbackGasLimit = _callbackGasLimit;
        requestConfirmations = _requestConfirmations;
    }

    /**
     * @notice Method called by the Chainlink Automation Nodes to check if `performUpkeep` must be done.
     * @dev Performs the computation to the array of `_activeRaffles`. This opens the possibility of having several
     * checkUpkeeps done at the same time.
     * @param checkData Encoded binary data which contains the lower bound and upper bound of the `_activeRaffles` array
     * on which to perform the computation
     * @return upkeepNeeded Whether the upkeep must be performed or not
     * @return performData Encoded binary data which contains the raffle address and index of the `_activeRaffles`
     */
    function checkUpkeep(bytes calldata checkData)
        external
        view
        override
        returns (bool upkeepNeeded, bytes memory performData)
    {
        if (_activeRaffles.length == 0) revert Errors.NoActiveRaffles();
        (uint256 lowerBound, uint256 upperBound) = abi.decode(checkData, (uint256, uint256));
        if (lowerBound >= upperBound) revert Errors.InvalidLowerAndUpperBounds();
        // Compute the active raffle that needs to be settled
        uint256 index;
        address raffle;
        for (uint256 i = 0; i < upperBound - lowerBound + 1; ++i) {
            if (_activeRaffles.length <= lowerBound + i) break;
            if (_activeRaffles[lowerBound + i].deadline <= block.timestamp) {
                index = lowerBound + i;
                raffle = _activeRaffles[lowerBound + i].raffle;
                break;
            }
        }
        if (_raffles[raffle] && !IRaffl(raffle).upkeepPerformed()) {
            upkeepNeeded = true;
        }
        performData = abi.encode(raffle, index);
    }

    /// @notice Permisionless write method usually called by the Chainlink Automation Nodes.
    /// @dev Either starts the draw for a raffle or cancels the raffle if criteria is not met.
    /// @param performData Encoded binary data which contains the raffle address and index of the `_activeRaffles`
    function performUpkeep(bytes calldata performData) external override {
        (address raffle, uint256 index) = abi.decode(performData, (address, uint256));
        if (_activeRaffles.length <= index) revert Errors.UpkeepConditionNotMet();
        if (_activeRaffles[index].raffle != raffle) revert Errors.UpkeepConditionNotMet();
        if (_activeRaffles[index].deadline > block.timestamp) revert Errors.UpkeepConditionNotMet();
        if (IRaffl(raffle).upkeepPerformed()) revert Errors.UpkeepConditionNotMet();
        bool criteriaMet = IRaffl(raffle).criteriaMet();
        if (criteriaMet) {
            uint256 requestId = s_vrfCoordinator.requestRandomWords(
                VRFV2PlusClient.RandomWordsRequest({
                    keyHash: keyHash,
                    subId: subscriptionId,
                    requestConfirmations: requestConfirmations,
                    callbackGasLimit: callbackGasLimit,
                    numWords: 1,
                    extraArgs: VRFV2PlusClient._argsToBytes(VRFV2PlusClient.ExtraArgsV1({ nativePayment: false }))
                })
            );
            IRaffl(raffle).setSuccessCriteria(requestId);
            _requestIds[requestId] = raffle;
        } else {
            IRaffl(raffle).setFailedCriteria();
        }
        _burnActiveRaffle(index);
    }

    /// @notice Method called by the Chainlink VRF Coordinator
    /// @param requestId Id of the VRF request
    /// @param randomWords Provably fair and verifiable array of random words
    function fulfillRandomWords(uint256 requestId, uint256[] memory randomWords) internal override {
        IRaffl(_requestIds[requestId]).disperseRewards(requestId, randomWords[0]);
    }

    /// @notice Helper function to remove a raffle from the `_activeRaffles` array
    /// @dev Move the last element to the deleted stop and removes the last element
    /// @param i Element index to remove
    function _burnActiveRaffle(uint256 i) internal {
        if (i >= _activeRaffles.length) revert Errors.ActiveRaffleIndexOutOfBounds();
        _activeRaffles[i] = _activeRaffles[_activeRaffles.length - 1];
        _activeRaffles.pop();
    }

    /// @inheritdoc IFactoryFeeManager
    function setFeeCollector(address newFeeCollector) external override onlyOwner {
        if (newFeeCollector == address(0)) revert Errors.AddressCanNotBeZero();

        _feeData.feeCollector = newFeeCollector;
        emit FeeCollectorChange(newFeeCollector);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

// End consumer library.
library VRFV2PlusClient {
  // extraArgs will evolve to support new features
  bytes4 public constant EXTRA_ARGS_V1_TAG = bytes4(keccak256("VRF ExtraArgsV1"));
  struct ExtraArgsV1 {
    bool nativePayment;
  }

  struct RandomWordsRequest {
    bytes32 keyHash;
    uint256 subId;
    uint16 requestConfirmations;
    uint32 callbackGasLimit;
    uint32 numWords;
    bytes extraArgs;
  }

  function _argsToBytes(ExtraArgsV1 memory extraArgs) internal pure returns (bytes memory bts) {
    return abi.encodeWithSelector(EXTRA_ARGS_V1_TAG, extraArgs);
  }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import {IVRFCoordinatorV2Plus} from "./interfaces/IVRFCoordinatorV2Plus.sol";
import {IVRFMigratableConsumerV2Plus} from "./interfaces/IVRFMigratableConsumerV2Plus.sol";
import {ConfirmedOwner} from "../../shared/access/ConfirmedOwner.sol";

/** ****************************************************************************
 * @notice Interface for contracts using VRF randomness
 * *****************************************************************************
 * @dev PURPOSE
 *
 * @dev Reggie the Random Oracle (not his real job) wants to provide randomness
 * @dev to Vera the verifier in such a way that Vera can be sure he's not
 * @dev making his output up to suit himself. Reggie provides Vera a public key
 * @dev to which he knows the secret key. Each time Vera provides a seed to
 * @dev Reggie, he gives back a value which is computed completely
 * @dev deterministically from the seed and the secret key.
 *
 * @dev Reggie provides a proof by which Vera can verify that the output was
 * @dev correctly computed once Reggie tells it to her, but without that proof,
 * @dev the output is indistinguishable to her from a uniform random sample
 * @dev from the output space.
 *
 * @dev The purpose of this contract is to make it easy for unrelated contracts
 * @dev to talk to Vera the verifier about the work Reggie is doing, to provide
 * @dev simple access to a verifiable source of randomness. It ensures 2 things:
 * @dev 1. The fulfillment came from the VRFCoordinatorV2Plus.
 * @dev 2. The consumer contract implements fulfillRandomWords.
 * *****************************************************************************
 * @dev USAGE
 *
 * @dev Calling contracts must inherit from VRFConsumerBaseV2Plus, and can
 * @dev initialize VRFConsumerBaseV2Plus's attributes in their constructor as
 * @dev shown:
 *
 * @dev   contract VRFConsumerV2Plus is VRFConsumerBaseV2Plus {
 * @dev     constructor(<other arguments>, address _vrfCoordinator, address _subOwner)
 * @dev       VRFConsumerBaseV2Plus(_vrfCoordinator, _subOwner) public {
 * @dev         <initialization with other arguments goes here>
 * @dev       }
 * @dev   }
 *
 * @dev The oracle will have given you an ID for the VRF keypair they have
 * @dev committed to (let's call it keyHash). Create a subscription, fund it
 * @dev and your consumer contract as a consumer of it (see VRFCoordinatorInterface
 * @dev subscription management functions).
 * @dev Call requestRandomWords(keyHash, subId, minimumRequestConfirmations,
 * @dev callbackGasLimit, numWords, extraArgs),
 * @dev see (IVRFCoordinatorV2Plus for a description of the arguments).
 *
 * @dev Once the VRFCoordinatorV2Plus has received and validated the oracle's response
 * @dev to your request, it will call your contract's fulfillRandomWords method.
 *
 * @dev The randomness argument to fulfillRandomWords is a set of random words
 * @dev generated from your requestId and the blockHash of the request.
 *
 * @dev If your contract could have concurrent requests open, you can use the
 * @dev requestId returned from requestRandomWords to track which response is associated
 * @dev with which randomness request.
 * @dev See "SECURITY CONSIDERATIONS" for principles to keep in mind,
 * @dev if your contract could have multiple requests in flight simultaneously.
 *
 * @dev Colliding `requestId`s are cryptographically impossible as long as seeds
 * @dev differ.
 *
 * *****************************************************************************
 * @dev SECURITY CONSIDERATIONS
 *
 * @dev A method with the ability to call your fulfillRandomness method directly
 * @dev could spoof a VRF response with any random value, so it's critical that
 * @dev it cannot be directly called by anything other than this base contract
 * @dev (specifically, by the VRFConsumerBaseV2Plus.rawFulfillRandomness method).
 *
 * @dev For your users to trust that your contract's random behavior is free
 * @dev from malicious interference, it's best if you can write it so that all
 * @dev behaviors implied by a VRF response are executed *during* your
 * @dev fulfillRandomness method. If your contract must store the response (or
 * @dev anything derived from it) and use it later, you must ensure that any
 * @dev user-significant behavior which depends on that stored value cannot be
 * @dev manipulated by a subsequent VRF request.
 *
 * @dev Similarly, both miners and the VRF oracle itself have some influence
 * @dev over the order in which VRF responses appear on the blockchain, so if
 * @dev your contract could have multiple VRF requests in flight simultaneously,
 * @dev you must ensure that the order in which the VRF responses arrive cannot
 * @dev be used to manipulate your contract's user-significant behavior.
 *
 * @dev Since the block hash of the block which contains the requestRandomness
 * @dev call is mixed into the input to the VRF *last*, a sufficiently powerful
 * @dev miner could, in principle, fork the blockchain to evict the block
 * @dev containing the request, forcing the request to be included in a
 * @dev different block with a different hash, and therefore a different input
 * @dev to the VRF. However, such an attack would incur a substantial economic
 * @dev cost. This cost scales with the number of blocks the VRF oracle waits
 * @dev until it calls responds to a request. It is for this reason that
 * @dev that you can signal to an oracle you'd like them to wait longer before
 * @dev responding to the request (however this is not enforced in the contract
 * @dev and so remains effective only in the case of unmodified oracle software).
 */
abstract contract VRFConsumerBaseV2Plus is IVRFMigratableConsumerV2Plus, ConfirmedOwner {
  error OnlyCoordinatorCanFulfill(address have, address want);
  error OnlyOwnerOrCoordinator(address have, address owner, address coordinator);
  error ZeroAddress();

  // s_vrfCoordinator should be used by consumers to make requests to vrfCoordinator
  // so that coordinator reference is updated after migration
  IVRFCoordinatorV2Plus public s_vrfCoordinator;

  /**
   * @param _vrfCoordinator address of VRFCoordinator contract
   */
  constructor(address _vrfCoordinator) ConfirmedOwner(msg.sender) {
    if (_vrfCoordinator == address(0)) {
      revert ZeroAddress();
    }
    s_vrfCoordinator = IVRFCoordinatorV2Plus(_vrfCoordinator);
  }

  /**
   * @notice fulfillRandomness handles the VRF response. Your contract must
   * @notice implement it. See "SECURITY CONSIDERATIONS" above for important
   * @notice principles to keep in mind when implementing your fulfillRandomness
   * @notice method.
   *
   * @dev VRFConsumerBaseV2Plus expects its subcontracts to have a method with this
   * @dev signature, and will call it once it has verified the proof
   * @dev associated with the randomness. (It is triggered via a call to
   * @dev rawFulfillRandomness, below.)
   *
   * @param requestId The Id initially returned by requestRandomness
   * @param randomWords the VRF output expanded to the requested number of words
   */
  // solhint-disable-next-line chainlink-solidity/prefix-internal-functions-with-underscore
  function fulfillRandomWords(uint256 requestId, uint256[] memory randomWords) internal virtual;

  // rawFulfillRandomness is called by VRFCoordinator when it receives a valid VRF
  // proof. rawFulfillRandomness then calls fulfillRandomness, after validating
  // the origin of the call
  function rawFulfillRandomWords(uint256 requestId, uint256[] memory randomWords) external {
    if (msg.sender != address(s_vrfCoordinator)) {
      revert OnlyCoordinatorCanFulfill(msg.sender, address(s_vrfCoordinator));
    }
    fulfillRandomWords(requestId, randomWords);
  }

  /**
   * @inheritdoc IVRFMigratableConsumerV2Plus
   */
  function setCoordinator(address _vrfCoordinator) external override onlyOwnerOrCoordinator {
    if (_vrfCoordinator == address(0)) {
      revert ZeroAddress();
    }
    s_vrfCoordinator = IVRFCoordinatorV2Plus(_vrfCoordinator);

    emit CoordinatorSet(_vrfCoordinator);
  }

  modifier onlyOwnerOrCoordinator() {
    if (msg.sender != owner() && msg.sender != address(s_vrfCoordinator)) {
      revert OnlyOwnerOrCoordinator(msg.sender, owner(), address(s_vrfCoordinator));
    }
    _;
  }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {AutomationBase} from "./AutomationBase.sol";
import {AutomationCompatibleInterface} from "./interfaces/AutomationCompatibleInterface.sol";

abstract contract AutomationCompatible is AutomationBase, AutomationCompatibleInterface {}

// SPDX-License-Identifier: None
// Raffl Protocol (last updated v1.0.0) (libraries/RafflFactoryErrors.sol)
pragma solidity ^0.8.25;

/// @title Errors Library for RafflFactory.sol
library Errors {
    /// @notice Thrown if the provided address is a zero address.
    error AddressCanNotBeZero();

    /// @notice Thrown if contract deployment fails.
    error FailedToDeploy();

    /// @notice Thrown if the fee does falls outside the allowed range.
    error FeeOutOfRange();

    /// @notice Thrown if the sender is not a fee collector.
    error NotFeeCollector();

    /// @notice Thrown if the provided deadline is not in the future.
    error DeadlineIsNotFuture();

    /// @notice Thrown if transfer from prize pool fails.
    error UnsuccessfulTransferFromPrize();

    /// @notice Thrown if the prize amount in ERC20 token is zero.
    error ERC20PrizeAmountIsZero();

    /// @notice Thrown if the upkeep condition is not met.
    error UpkeepConditionNotMet();

    /// @notice Thrown if there are no active raffles.
    error NoActiveRaffles();

    /// @notice Thrown if the lower and upper bounds of raffle are invalid.
    error InvalidLowerAndUpperBounds();

    /// @notice Thrown if the active raffle index is out of bounds.
    error ActiveRaffleIndexOutOfBounds();

    /// @notice Error to indicate that the creation fee is insufficient.
    error InsufficientCreationFee();

    /// @notice Error to indicate an unsuccessful transfer of the creation fee.
    error UnsuccessfulCreationFeeTransfer();
}

// SPDX-License-Identifier: None
// Raffl Protocol (last updated v1.0.0) (abstracts/FactoryFeeManager.sol)
pragma solidity ^0.8.25;

import { Errors } from "../libraries/RafflFactoryErrors.sol";
import { IFeeManager } from "../interfaces/IFeeManager.sol";
import { IFactoryFeeManager } from "../interfaces/IFactoryFeeManager.sol";

/// @title FactoryFeeManager
/// @notice See the documentation in {IFactoryFeeManager}.
/// @author JA (@ubinatus)
abstract contract FactoryFeeManager is IFactoryFeeManager {
    /**
     *
     * CONSTANTS
     *
     */

    /// @dev Pool fee is calculated using 18 decimals where 0.05 ether is 5%.
    uint64 internal constant MAX_POOL_FEE = 0.1 ether;

    /**
     *
     * STATE
     *
     */

    /// @dev Stores fee related information for collection purposes.
    FeeData internal _feeData;

    /// @dev Stores the info necessary for an upcoming change of the global creation fee.
    UpcomingFeeData internal _upcomingCreationFee;

    /// @dev Stores the info necessary for an upcoming change of the global pool fee.
    UpcomingFeeData internal _upcomingPoolFee;

    /// @dev Maps a user address to a custom creation fee struct.
    mapping(address => CustomFeeData) internal _creationFeeByUser;

    /// @dev Maps a user address to a custom pool fee struct.
    mapping(address => CustomFeeData) internal _poolFeeByUser;

    /// @notice Reverts if called by anyone other than the factory fee collector.
    modifier onlyFeeCollector() {
        if (msg.sender != _feeData.feeCollector) {
            revert Errors.NotFeeCollector();
        }
        _;
    }

    /**
     *
     * FUNCTIONS
     *
     */

    /// @inheritdoc IFactoryFeeManager
    function minPoolFee() external pure override returns (uint64) {
        return 0;
    }

    /// @inheritdoc IFactoryFeeManager
    function maxPoolFee() external pure override returns (uint64) {
        return MAX_POOL_FEE;
    }

    /// @inheritdoc IFactoryFeeManager
    function feeCollector() external view override returns (address) {
        return _feeData.feeCollector;
    }

    /// @inheritdoc IFactoryFeeManager
    function globalCreationFee() external view override returns (uint64) {
        return block.timestamp >= _upcomingCreationFee.valueChangeAt
            ? _upcomingCreationFee.nextValue
            : _feeData.creationFee;
    }

    /// @inheritdoc IFactoryFeeManager
    function globalPoolFee() external view override returns (uint64) {
        return
            block.timestamp >= _upcomingPoolFee.valueChangeAt ? _upcomingPoolFee.nextValue : _feeData.poolFeePercentage;
    }

    /// @inheritdoc IFeeManager
    function creationFeeData(address user)
        external
        view
        returns (address feeCollectorAddress, uint64 creationFeeValue)
    {
        feeCollectorAddress = _feeData.feeCollector;
        creationFeeValue = _getCurrentFee(_feeData.creationFee, _upcomingCreationFee, _creationFeeByUser[user]);
    }

    /// @notice Returns the current pool fee for a specific Raffle, considering any pending updates.
    /// @param user Address of the user.
    function poolFeeData(address user) external view returns (address feeCollectorAddress, uint64 poolFeePercentage) {
        feeCollectorAddress = _feeData.feeCollector;
        poolFeePercentage = _getCurrentFee(_feeData.poolFeePercentage, _upcomingPoolFee, _poolFeeByUser[user]);
    }

    /// @inheritdoc IFactoryFeeManager
    function scheduleGlobalCreationFee(uint64 newFeeValue) external override onlyFeeCollector {
        if (_upcomingCreationFee.valueChangeAt <= block.timestamp) {
            _feeData.creationFee = _upcomingCreationFee.nextValue;
        }

        _upcomingCreationFee.nextValue = newFeeValue;
        _upcomingCreationFee.valueChangeAt = uint64(block.timestamp + 1 hours);

        emit GlobalCreationFeeChange(newFeeValue);
    }

    /// @inheritdoc IFactoryFeeManager
    function scheduleGlobalPoolFee(uint64 newFeePercentage) external override onlyFeeCollector {
        if (newFeePercentage > MAX_POOL_FEE) revert Errors.FeeOutOfRange();

        _upcomingPoolFee.nextValue = newFeePercentage;
        _upcomingPoolFee.valueChangeAt = uint64(block.timestamp + 1 hours);

        emit GlobalPoolFeeChange(newFeePercentage);
    }

    /// @inheritdoc IFactoryFeeManager
    function scheduleCustomCreationFee(address user, uint64 newFeeValue) external override onlyFeeCollector {
        CustomFeeData storage customFee = _creationFeeByUser[user];

        if (customFee.valueChangeAt <= block.timestamp) {
            customFee.value = customFee.nextValue;
        }

        uint64 ts = uint64(block.timestamp + 1 hours);

        customFee.nextEnableState = true;
        customFee.statusChangeAt = ts;
        customFee.nextValue = newFeeValue;
        customFee.valueChangeAt = ts;

        emit CustomCreationFeeChange(user, newFeeValue);
    }

    /// @inheritdoc IFactoryFeeManager
    function scheduleCustomPoolFee(address user, uint64 newFeePercentage) external override onlyFeeCollector {
        if (newFeePercentage > MAX_POOL_FEE) revert Errors.FeeOutOfRange();

        CustomFeeData storage customFee = _poolFeeByUser[user];

        if (customFee.valueChangeAt <= block.timestamp) {
            customFee.value = customFee.nextValue;
        }

        uint64 ts = uint64(block.timestamp + 1 hours);

        customFee.nextEnableState = true;
        customFee.statusChangeAt = ts;
        customFee.nextValue = newFeePercentage;
        customFee.valueChangeAt = ts;

        emit CustomPoolFeeChange(user, newFeePercentage);
    }

    /// @inheritdoc IFactoryFeeManager
    function toggleCustomCreationFee(address user, bool enable) external override onlyFeeCollector {
        CustomFeeData storage customFee = _creationFeeByUser[user];

        if (customFee.statusChangeAt <= block.timestamp) {
            customFee.isEnabled = customFee.nextEnableState;
        }

        customFee.nextEnableState = enable;
        customFee.statusChangeAt = uint64(block.timestamp + 1 hours);

        emit CustomCreationFeeToggle(user, enable);
    }

    /// @inheritdoc IFactoryFeeManager
    function toggleCustomPoolFee(address user, bool enable) external override onlyFeeCollector {
        CustomFeeData storage customFee = _poolFeeByUser[user];

        if (customFee.statusChangeAt <= block.timestamp) {
            customFee.isEnabled = customFee.nextEnableState;
        }

        customFee.nextEnableState = enable;
        customFee.statusChangeAt = uint64(block.timestamp + 1 hours);

        emit CustomPoolFeeToggle(user, enable);
    }

    /// @notice Calculates the current fee based on global, custom, and upcoming fee data.
    /// @dev This function considers the current timestamp and determines the appropriate fee
    /// based on whether a custom or upcoming fee should be applied.
    /// @param globalValue The default global fee value used when no custom fees are applicable.
    /// @param upcomingGlobalFee A struct containing data about an upcoming fee change, including the timestamp
    /// for the change and the new value to be applied.
    /// @param customFee A struct containing data about the custom fee, including its enablement status,
    /// timestamps for changes, and its values (current and new).
    /// @return currentValue The calculated current fee value, taking into account the global value,
    /// custom fee, and upcoming fee data based on the current timestamp.
    function _getCurrentFee(
        uint64 globalValue,
        UpcomingFeeData memory upcomingGlobalFee,
        CustomFeeData memory customFee
    )
        internal
        view
        returns (uint64 currentValue)
    {
        if (block.timestamp >= customFee.statusChangeAt) {
            // If isCustomFee is true based on status, directly return the value based on the customFee conditions.
            if (customFee.nextEnableState) {
                return block.timestamp >= customFee.valueChangeAt ? customFee.nextValue : customFee.value;
            }
        } else if (customFee.isEnabled) {
            // This block handles the case where current timestamp is not past statusChangeAt, but custom is enabled.
            return block.timestamp >= customFee.valueChangeAt ? customFee.nextValue : customFee.value;
        }

        // If none of the custom fee conditions apply, return the global or upcoming fee value.
        return block.timestamp >= upcomingGlobalFee.valueChangeAt ? upcomingGlobalFee.nextValue : globalValue;
    }

    /// @notice Processes the creation fee for a transaction.
    /// @dev This function retrieves the creation fee data from the manager contract and, if the creation fee is greater
    /// than zero, sends the `msg.value` to the fee collector address. Reverts if the transferred value is less than the
    /// required creation fee or if the transfer fails.
    function _processCreationFee(address user) internal {
        uint64 creationFeeValue = _getCurrentFee(_feeData.creationFee, _upcomingCreationFee, _creationFeeByUser[user]);

        if (creationFeeValue != 0) {
            if (msg.value < creationFeeValue) revert Errors.InsufficientCreationFee();

            bytes4 unsuccessfulClaimFeeTransfer = Errors.UnsuccessfulCreationFeeTransfer.selector;
            address feeCollectorAddress = _feeData.feeCollector;

            assembly {
                let ptr := mload(0x40)
                let sendSuccess := call(gas(), feeCollectorAddress, callvalue(), 0x00, 0x00, 0x00, 0x00)
                if iszero(sendSuccess) {
                    mstore(ptr, unsuccessfulClaimFeeTransfer)
                    revert(ptr, 0x04)
                }
            }
        }
    }
}

// SPDX-License-Identifier: None
// Raffl Protocol (last updated v1.0.0) (interfaces/IRaffl.sol)
pragma solidity ^0.8.25;

/// @dev Interface that describes the Prize struct, the GameStatus and initialize function so the `RafflFactory` knows
/// how to initialize the `Raffl`.
/// @title IRaffl
interface IRaffl {
    /// @dev Asset type describe the kind of token behind the prize tok describes how the periods between release
    /// tokens.
    enum AssetType {
        ERC20,
        ERC721
    }

    /// @dev `asset` represents the address of the asset considered as a prize
    /// @dev `assetType` defines the type of asset
    /// @dev `value` represents the value of the prize. If asset is an ERC20, it's the amount. If asset is an ERC721,
    /// it's the tokenId.
    struct Prize {
        address asset;
        AssetType assetType;
        uint256 value;
    }

    /// @dev `token` represents the address of the token gating asset
    /// @dev `amount` represents the minimum value of the token gating
    struct TokenGate {
        address token;
        uint256 amount;
    }

    /// @dev `recipient` represents the address of the extra recipient of the pooled funds
    /// @dev `feePercentage` is the percentage of the pooled funds (after fees) that will be shared to the extra
    /// recipient
    struct ExtraRecipient {
        address recipient;
        uint64 sharePercentage;
    }

    /**
     * @dev GameStatus defines the possible states of the game
     * (0) Initialized: Raffle is initialized and ready to receive entries until the deadline
     * (1) FailedDraw: Raffle deadline was hit by the Chailink Upkeep but minimum entries were not met
     * (2) DrawStarted: Raffle deadline was hit by the Chainlink Upkeep and it's waiting for the Chainlink VRF
     *  with the lucky winner
     * (3) SuccessDraw: Raffle received the provably fair and verifiable random lucky winner and distributed rewards.
     */
    enum GameStatus {
        Initialized,
        FailedDraw,
        DrawStarted,
        SuccessDraw
    }

    /// @notice Emit when a new raffle is initialized.
    event RaffleInitialized();

    /// @notice Emit when a user buys entries.
    /// @param user The address of the user who purchased the entries.
    /// @param entriesBought The number of entries bought.
    /// @param value The value of the entries bought.
    event EntriesBought(address indexed user, uint256 entriesBought, uint256 value);

    /// @notice Emit when a user gets refunded for their entries.
    /// @param user The address of the user who got the refund.
    /// @param entriesRefunded The number of entries refunded.
    /// @param value The value of the entries refunded.
    event EntriesRefunded(address indexed user, uint256 entriesRefunded, uint256 value);

    /// @notice Emit when prizes are refunded.
    event PrizesRefunded();

    /// @notice Emit when a draw is successful.
    /// @param requestId The indexed ID of the draw request.
    /// @param winnerEntry The entry that won the draw.
    /// @param user The address of the winner.
    /// @param entries The entries the winner had.
    event DrawSuccess(uint256 indexed requestId, uint256 winnerEntry, address user, uint256 entries);

    /// @notice Emit when the criteria for deadline success is met.
    /// @param requestId The indexed ID of the deadline request.
    /// @param entries The number of entries at the time of the deadline.
    /// @param minEntries The minimum number of entries required for success.
    event DeadlineSuccessCriteria(uint256 indexed requestId, uint256 entries, uint256 minEntries);

    /// @notice Emit when the criteria for deadline failure is met.
    /// @param entries The number of entries at the time of the deadline.
    /// @param minEntries The minimum number of entries required for success.
    event DeadlineFailedCriteria(uint256 entries, uint256 minEntries);

    /// @notice Emit when changes are made to token-gating parameters.
    event TokenGatingChanges();

    /**
     * @notice Initializes the contract by setting up the raffle variables and the
     * `prices` information.
     *
     * @param entryToken        The address of the ERC-20 token as entry. If address zero, entry is the network token
     * @param entryPrice        The value of each entry for the raffle.
     * @param minEntries        The minimum number of entries to consider make the draw.
     * @param deadline          The block timestamp until the raffle will receive entries
     *                          and that will perform the draw if criteria is met.
     * @param creator           The address of the raffle creator
     * @param prizes            The prizes that will be held by this contract.
     * @param tokenGates        The token gating that will be imposed to users.
     * @param extraRecipient    The extra recipient that will share the rewards (optional).
     */
    function initialize(
        address entryToken,
        uint256 entryPrice,
        uint256 minEntries,
        uint256 deadline,
        address creator,
        Prize[] calldata prizes,
        TokenGate[] calldata tokenGates,
        ExtraRecipient calldata extraRecipient
    )
        external;

    /// @notice Checks if the raffle has met the minimum entries
    function criteriaMet() external view returns (bool);

    /// @notice Checks if the deadline has passed
    function deadlineExpired() external view returns (bool);

    /// @notice Checks if raffle already perfomed the upkeep
    function upkeepPerformed() external view returns (bool);

    /// @notice Sets the criteria as settled, sets the `GameStatus` as `DrawStarted` and emits event
    /// `DeadlineSuccessCriteria`
    /// @dev Access control: `factory` is the only allowed to called this method
    function setSuccessCriteria(uint256 requestId) external;

    /// @notice Sets the criteria as settled, sets the `GameStatus` as `FailedDraw` and emits event
    /// `DeadlineFailedCriteria`
    /// @dev Access control: `factory` is the only allowed to called this method
    function setFailedCriteria() external;

    /**
     * @notice Purchase entries for the raffle.
     * @dev Handles the acquisition of entries for three scenarios:
     * i) Entry is paid with network tokens,
     * ii) Entry is paid with ERC-20 tokens,
     * iii) Entry is free (allows up to 1 entry per user)
     * @param quantity The quantity of entries to purchase.
     *
     * Requirements:
     * - If entry is paid with network tokens, the required amount of network tokens.
     * - If entry is paid with ERC-20, the contract must be approved to spend ERC-20 tokens.
     * - If entry is free, no payment is required.
     *
     * Emits `EntriesBought` event
     */
    function buyEntries(uint256 quantity) external payable;

    /// @notice Refund entries for a specific user.
    /// @dev Invokable when the draw was not made because the min entries were not enought
    /// @dev This method is not available if the `entryPrice` was zero
    /// @param user The address of the user whose entries will be refunded.
    function refundEntries(address user) external;

    /// @notice Refund prizes to the creator.
    /// @dev Invokable when the draw was not made because the min entries were not enought
    function refundPrizes() external;

    /// @notice Transfers the `prizes` to the provably fair and verifiable entrant, sets the `GameStatus` as
    /// `SuccessDraw` and emits event `DrawSuccess`
    /// @dev Access control: `factory` is the only allowed to called this method through the Chainlink VRF Coordinator
    function disperseRewards(uint256 requestId, uint256 randomNumber) external;
}

// SPDX-License-Identifier: None
// Raffl Protocol (last updated v1.0.0) (interfaces/FactoryFeeManager.sol)
pragma solidity ^0.8.25;

import { IFeeManager } from "./IFeeManager.sol";

/// @title IFactoryFeeManager
/// @dev Interface that describes the struct and accessor function for the data related to the collection of fees.
interface IFactoryFeeManager is IFeeManager {
    /**
     *
     * EVENTS
     *
     */

    /// @param feeCollector Address of the new fee collector.
    event FeeCollectorChange(address indexed feeCollector);

    /// @param creationFeeValue Value for the new creation fee.
    event GlobalCreationFeeChange(uint64 creationFeeValue);

    /// @param poolFeePercentage Value for the new pool fee.
    event GlobalPoolFeeChange(uint64 poolFeePercentage);

    /// @param user Address of the user.
    /// @param creationFeeValue Value for the new creation fee.
    event CustomCreationFeeChange(address indexed user, uint64 creationFeeValue);

    /// @param user Address of the user.
    /// @param enable Indicates the enabled state of the fee.
    event CustomCreationFeeToggle(address indexed user, bool enable);

    /// @param user Address of the user.
    /// @param poolFeePercentage Value for the new pool fee.
    event CustomPoolFeeChange(address indexed user, uint64 poolFeePercentage);

    /// @param user Address of the user.
    /// @param enable Indicates the enabled state of the fee.
    event CustomPoolFeeToggle(address indexed user, bool enable);

    /**
     *
     * FUNCTIONS
     *
     */

    /// @dev Set address of fee collector.
    ///
    /// Requirements:
    ///
    /// - `msg.sender` has to be the owner of the factory.
    /// - `newFeeCollector` can't be address 0x0.
    ///
    /// @param newFeeCollector Address of `feeCollector`.
    ///
    function setFeeCollector(address newFeeCollector) external;

    /// @notice Sets a new global creation fee value, to take effect after 1 hour.
    /// @dev `msg.sender` has to be the fee collector of the factory.
    /// @param newFeeValue Value for `creationFee` that will be charged on `Raffl`'s deployments.
    function scheduleGlobalCreationFee(uint64 newFeeValue) external;

    /// @notice Sets a new global pool fee percentage, to take effect after 1 hour.
    ///
    /// @dev Percentages and fees are calculated using 18 decimals where 1 ether is 100%.
    ///
    /// Requirements:
    ///
    /// - `newFeePercentage` must be within minPoolFee and maxPoolFee.
    /// - `msg.sender` has to be the fee collector of the factory.
    ///
    /// @param newFeePercentage Value for `poolFeePercentage` that will be charged on `Raffl`'s pools.
    function scheduleGlobalPoolFee(uint64 newFeePercentage) external;

    /// @notice Sets a new custom creation fee value for a specific User, to be enabled and take effect
    /// after 1 hour from the time of this transaction.
    ///
    /// @dev Allows the contract owner to modify the creation fee associated with a specific User.
    /// The new fee becomes effective after a delay of 1 hour, aiming to provide a buffer for users to be aware of the
    /// upcoming fee change.
    /// This function updates the fee and schedules its activation, ensuring transparency and predictability in fee
    /// adjustments.
    /// The fee is specified in wei, allowing for granular control over the fee structure. Emits a
    /// `CustomCreationFeeChange` event upon successful fee update.
    ///
    /// Requirements:
    /// - `msg.sender` has to be the fee collector of the factory.
    ///
    /// @param user Address of the `user`.
    /// @param newFeeValue The new creation fee amount to be set, in wei, to replace the current fee after the specified
    /// delay.
    function scheduleCustomCreationFee(address user, uint64 newFeeValue) external;

    /// @notice Sets a new custom pool fee percentage for a specific User, to be enabled and take effect
    /// after 1 hour from the time of this transaction.
    ///
    /// @dev This function allows the contract owner to adjust the pool fee for a User.
    /// The fee adjustment is delayed by 1 hour to provide transparency and predictability. Fees are calculated with
    /// precision to 18 decimal places, where 1 ether equals 100% fee.
    /// The function enforces fee limits; `newFeePercentage` must be within the predefined 0-`MAX_POOL_FEE` bounds.
    /// If the custom fee was previously disabled or set to a different value, this operation schedules the new fee to
    /// take effect after the delay, enabling it if necessary.
    /// Emits a `CustomPoolFeeChange` event upon successful execution.
    ///
    /// Requirements:
    /// - `msg.sender` has to be the fee collector of the factory.
    /// - `newFeePercentage` must be within the range limited by `MAX_POOL_FEE`.
    ///
    /// @param user Address of the `user`.
    /// @param newFeePercentage The new pool fee percentage to be applied, expressed in ether terms (18 decimal
    /// places) where 1 ether represents 100%.
    function scheduleCustomPoolFee(address user, uint64 newFeePercentage) external;

    /// @notice Enables or disables the custom creation fee for a given Raffle, with the change taking effect
    /// after 1 hour.
    /// @dev `msg.sender` has to be the fee collector of the factory.
    /// @param user Address of the `user`.
    /// @param enable True to enable the fee, false to disable it.
    function toggleCustomCreationFee(address user, bool enable) external;

    /// @notice Enables or disables the custom pool fee for a given Raffle, to take effect after 1 hour.
    /// @dev `msg.sender` has to be the fee collector of the factory.
    /// @param user Address of the `user`.
    /// @param enable True to enable the fee, false to disable it.
    function toggleCustomPoolFee(address user, bool enable) external;

    /// @dev Exposes the minimum pool fee.
    function minPoolFee() external pure returns (uint64);

    /// @dev Exposes the maximum pool fee.
    function maxPoolFee() external pure returns (uint64);

    /// @notice Exposes the `FeeData.feeCollector` to users.
    function feeCollector() external view returns (address);

    /// @notice Retrieves the current global creation fee to users.
    function globalCreationFee() external view returns (uint64);

    /// @notice Retrieves the current global pool fee percentage to users.
    function globalPoolFee() external view returns (uint64);

    /// @notice Returns the current creation fee for a specific user, considering any pending updates.
    /// @param user Address of the `user`.
    function creationFeeData(address user)
        external
        view
        override
        returns (address feeCollectorAddress, uint64 creationFeeValue);

    /// @notice Returns the current pool fee for a specific user, considering any pending updates.
    /// @param user Address of the `user`.
    function poolFeeData(address user)
        external
        view
        override
        returns (address feeCollectorAddress, uint64 poolFeePercentage);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {VRFV2PlusClient} from "../libraries/VRFV2PlusClient.sol";
import {IVRFSubscriptionV2Plus} from "./IVRFSubscriptionV2Plus.sol";

// Interface that enables consumers of VRFCoordinatorV2Plus to be future-proof for upgrades
// This interface is supported by subsequent versions of VRFCoordinatorV2Plus
interface IVRFCoordinatorV2Plus is IVRFSubscriptionV2Plus {
  /**
   * @notice Request a set of random words.
   * @param req - a struct containing following fields for randomness request:
   * keyHash - Corresponds to a particular oracle job which uses
   * that key for generating the VRF proof. Different keyHash's have different gas price
   * ceilings, so you can select a specific one to bound your maximum per request cost.
   * subId  - The ID of the VRF subscription. Must be funded
   * with the minimum subscription balance required for the selected keyHash.
   * requestConfirmations - How many blocks you'd like the
   * oracle to wait before responding to the request. See SECURITY CONSIDERATIONS
   * for why you may want to request more. The acceptable range is
   * [minimumRequestBlockConfirmations, 200].
   * callbackGasLimit - How much gas you'd like to receive in your
   * fulfillRandomWords callback. Note that gasleft() inside fulfillRandomWords
   * may be slightly less than this amount because of gas used calling the function
   * (argument decoding etc.), so you may need to request slightly more than you expect
   * to have inside fulfillRandomWords. The acceptable range is
   * [0, maxGasLimit]
   * numWords - The number of uint256 random values you'd like to receive
   * in your fulfillRandomWords callback. Note these numbers are expanded in a
   * secure way by the VRFCoordinator from a single random value supplied by the oracle.
   * extraArgs - abi-encoded extra args
   * @return requestId - A unique identifier of the request. Can be used to match
   * a request to a response in fulfillRandomWords.
   */
  function requestRandomWords(VRFV2PlusClient.RandomWordsRequest calldata req) external returns (uint256 requestId);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/// @notice The IVRFMigratableConsumerV2Plus interface defines the
/// @notice method required to be implemented by all V2Plus consumers.
/// @dev This interface is designed to be used in VRFConsumerBaseV2Plus.
interface IVRFMigratableConsumerV2Plus {
  event CoordinatorSet(address vrfCoordinator);

  /// @notice Sets the VRF Coordinator address
  /// @notice This method should only be callable by the coordinator or contract owner
  function setCoordinator(address vrfCoordinator) external;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {ConfirmedOwnerWithProposal} from "./ConfirmedOwnerWithProposal.sol";

/// @title The ConfirmedOwner contract
/// @notice A contract with helpers for basic contract ownership.
contract ConfirmedOwner is ConfirmedOwnerWithProposal {
  constructor(address newOwner) ConfirmedOwnerWithProposal(newOwner, address(0)) {}
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract AutomationBase {
  error OnlySimulatedBackend();

  /**
   * @notice method that allows it to be simulated via eth_call by checking that
   * the sender is the zero address.
   */
  function _preventExecution() internal view {
    // solhint-disable-next-line avoid-tx-origin
    if (tx.origin != address(0) && tx.origin != address(0x1111111111111111111111111111111111111111)) {
      revert OnlySimulatedBackend();
    }
  }

  /**
   * @notice modifier that allows it to be simulated via eth_call by checking
   * that the sender is the zero address.
   */
  modifier cannotExecute() {
    _preventExecution();
    _;
  }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface AutomationCompatibleInterface {
  /**
   * @notice method that is simulated by the keepers to see if any work actually
   * needs to be performed. This method does does not actually need to be
   * executable, and since it is only ever simulated it can consume lots of gas.
   * @dev To ensure that it is never called, you may want to add the
   * cannotExecute modifier from KeeperBase to your implementation of this
   * method.
   * @param checkData specified in the upkeep registration so it is always the
   * same for a registered upkeep. This can easily be broken down into specific
   * arguments using `abi.decode`, so multiple upkeeps can be registered on the
   * same contract and easily differentiated by the contract.
   * @return upkeepNeeded boolean to indicate whether the keeper should call
   * performUpkeep or not.
   * @return performData bytes that the keeper should call performUpkeep with, if
   * upkeep is needed. If you would like to encode data to decode later, try
   * `abi.encode`.
   */
  function checkUpkeep(bytes calldata checkData) external returns (bool upkeepNeeded, bytes memory performData);

  /**
   * @notice method that is actually executed by the keepers, via the registry.
   * The data returned by the checkUpkeep simulation will be passed into
   * this method to actually be executed.
   * @dev The input to this method should not be trusted, and the caller of the
   * method should not even be restricted to any single registry. Anyone should
   * be able call it, and the input should be validated, there is no guarantee
   * that the data passed in is the performData returned from checkUpkeep. This
   * could happen due to malicious keepers, racing keepers, or simply a state
   * change while the performUpkeep transaction is waiting for confirmation.
   * Always validate the data passed in.
   * @param performData is the data which was passed back from the checkData
   * simulation. If it is encoded, it can easily be decoded into other types by
   * calling `abi.decode`. This data should not be trusted, and should be
   * validated against the contract's current state.
   */
  function performUpkeep(bytes calldata performData) external;
}

// SPDX-License-Identifier: None
// Raffl Protocol (last updated v1.0.0) (interfaces/IFeeManager.sol)
pragma solidity ^0.8.25;

/// @title IFeeManager
/// @dev Interface that describes the struct and accessor function for the data related to the collection of fees.
interface IFeeManager {
    /// @dev The `FeeData` struct is used to store fee configurations such as the collection address and fee amounts for
    /// various transaction types in the contract.
    struct FeeData {
        /// @notice The address designated to collect fees.
        /// @dev This address is responsible for receiving fees generated from various sources.
        address feeCollector;
        /// @notice The fixed fee amount required to be sent as value with each `createRaffle` operation.
        /// @dev `creationFee` is denominated in the smallest unit of the token. It must be sent as the transaction
        /// value during the execution of the payable `createRaffle` function.
        uint64 creationFee;
        /// @notice The transfer fee expressed in ether, where 0.01 ether corresponds to a 1% fee.
        /// @dev `poolFeePercentage` is not in basis points but in ether units, with each ether unit representing a
        /// percentage that will be collected from the pool on success draws.
        uint64 poolFeePercentage;
    }

    /// @dev Stores global fee data upcoming change and timestamp for that change.
    struct UpcomingFeeData {
        /// @notice The new fee value in wei to be applied at `valueChangeAt`.
        uint64 nextValue;
        /// @notice Timestamp at which a new fee value becomes effective.
        uint64 valueChangeAt;
    }

    /// @dev Stores custom fee data, including its current state, upcoming changes, and the timestamps for those
    /// changes.
    struct CustomFeeData {
        /// @notice Indicates if the custom fee is currently enabled.
        bool isEnabled;
        /// @notice The current fee value in wei.
        uint64 value;
        /// @notice The new fee value in wei to be applied at `valueChangeAt`.
        uint64 nextValue;
        /// @notice Timestamp at which a new fee value becomes effective.
        uint64 valueChangeAt;
        /// @notice Indicates the future state of `isEnabled` after `statusChangeAt`.
        bool nextEnableState;
        /// @notice Timestamp at which the change to `isEnabled` becomes effective.
        uint64 statusChangeAt;
    }

    /// @notice Exposes the creation fee for new `Raffl`s deployments.
    /// @param raffle Address of the `Raffl`.
    /// @dev Enabled custom fees overrides the global creation fee.
    function creationFeeData(address raffle) external view returns (address feeCollector, uint64 creationFeeValue);

    /// @notice Exposes the fee that will be collected from the pool on success draws for `Raffl`s.
    /// @param raffle Address of the `Raffl`.
    /// @dev Enabled custom fees overrides the global transfer fee.
    function poolFeeData(address raffle) external view returns (address feeCollector, uint64 poolFeePercentage);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/// @notice The IVRFSubscriptionV2Plus interface defines the subscription
/// @notice related methods implemented by the V2Plus coordinator.
interface IVRFSubscriptionV2Plus {
  /**
   * @notice Add a consumer to a VRF subscription.
   * @param subId - ID of the subscription
   * @param consumer - New consumer which can use the subscription
   */
  function addConsumer(uint256 subId, address consumer) external;

  /**
   * @notice Remove a consumer from a VRF subscription.
   * @param subId - ID of the subscription
   * @param consumer - Consumer to remove from the subscription
   */
  function removeConsumer(uint256 subId, address consumer) external;

  /**
   * @notice Cancel a subscription
   * @param subId - ID of the subscription
   * @param to - Where to send the remaining LINK to
   */
  function cancelSubscription(uint256 subId, address to) external;

  /**
   * @notice Accept subscription owner transfer.
   * @param subId - ID of the subscription
   * @dev will revert if original owner of subId has
   * not requested that msg.sender become the new owner.
   */
  function acceptSubscriptionOwnerTransfer(uint256 subId) external;

  /**
   * @notice Request subscription owner transfer.
   * @param subId - ID of the subscription
   * @param newOwner - proposed new owner of the subscription
   */
  function requestSubscriptionOwnerTransfer(uint256 subId, address newOwner) external;

  /**
   * @notice Create a VRF subscription.
   * @return subId - A unique subscription id.
   * @dev You can manage the consumer set dynamically with addConsumer/removeConsumer.
   * @dev Note to fund the subscription with LINK, use transferAndCall. For example
   * @dev  LINKTOKEN.transferAndCall(
   * @dev    address(COORDINATOR),
   * @dev    amount,
   * @dev    abi.encode(subId));
   * @dev Note to fund the subscription with Native, use fundSubscriptionWithNative. Be sure
   * @dev  to send Native with the call, for example:
   * @dev COORDINATOR.fundSubscriptionWithNative{value: amount}(subId);
   */
  function createSubscription() external returns (uint256 subId);

  /**
   * @notice Get a VRF subscription.
   * @param subId - ID of the subscription
   * @return balance - LINK balance of the subscription in juels.
   * @return nativeBalance - native balance of the subscription in wei.
   * @return reqCount - Requests count of subscription.
   * @return owner - owner of the subscription.
   * @return consumers - list of consumer address which are able to use this subscription.
   */
  function getSubscription(
    uint256 subId
  )
    external
    view
    returns (uint96 balance, uint96 nativeBalance, uint64 reqCount, address owner, address[] memory consumers);

  /*
   * @notice Check to see if there exists a request commitment consumers
   * for all consumers and keyhashes for a given sub.
   * @param subId - ID of the subscription
   * @return true if there exists at least one unfulfilled request for the subscription, false
   * otherwise.
   */
  function pendingRequestExists(uint256 subId) external view returns (bool);

  /**
   * @notice Paginate through all active VRF subscriptions.
   * @param startIndex index of the subscription to start from
   * @param maxCount maximum number of subscriptions to return, 0 to return all
   * @dev the order of IDs in the list is **not guaranteed**, therefore, if making successive calls, one
   * @dev should consider keeping the blockheight constant to ensure a holistic picture of the contract state
   */
  function getActiveSubscriptionIds(uint256 startIndex, uint256 maxCount) external view returns (uint256[] memory);

  /**
   * @notice Fund a subscription with native.
   * @param subId - ID of the subscription
   * @notice This method expects msg.value to be greater than or equal to 0.
   */
  function fundSubscriptionWithNative(uint256 subId) external payable;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {IOwnable} from "../interfaces/IOwnable.sol";

/// @title The ConfirmedOwner contract
/// @notice A contract with helpers for basic contract ownership.
contract ConfirmedOwnerWithProposal is IOwnable {
  address private s_owner;
  address private s_pendingOwner;

  event OwnershipTransferRequested(address indexed from, address indexed to);
  event OwnershipTransferred(address indexed from, address indexed to);

  constructor(address newOwner, address pendingOwner) {
    // solhint-disable-next-line gas-custom-errors
    require(newOwner != address(0), "Cannot set owner to zero");

    s_owner = newOwner;
    if (pendingOwner != address(0)) {
      _transferOwnership(pendingOwner);
    }
  }

  /// @notice Allows an owner to begin transferring ownership to a new address.
  function transferOwnership(address to) public override onlyOwner {
    _transferOwnership(to);
  }

  /// @notice Allows an ownership transfer to be completed by the recipient.
  function acceptOwnership() external override {
    // solhint-disable-next-line gas-custom-errors
    require(msg.sender == s_pendingOwner, "Must be proposed owner");

    address oldOwner = s_owner;
    s_owner = msg.sender;
    s_pendingOwner = address(0);

    emit OwnershipTransferred(oldOwner, msg.sender);
  }

  /// @notice Get the current owner
  function owner() public view override returns (address) {
    return s_owner;
  }

  /// @notice validate, transfer ownership, and emit relevant events
  function _transferOwnership(address to) private {
    // solhint-disable-next-line gas-custom-errors
    require(to != msg.sender, "Cannot transfer to self");

    s_pendingOwner = to;

    emit OwnershipTransferRequested(s_owner, to);
  }

  /// @notice validate access
  function _validateOwnership() internal view {
    // solhint-disable-next-line gas-custom-errors
    require(msg.sender == s_owner, "Only callable by owner");
  }

  /// @notice Reverts if called by anyone other than the contract owner.
  modifier onlyOwner() {
    _validateOwnership();
    _;
  }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IOwnable {
  function owner() external returns (address);

  function transferOwnership(address recipient) external;

  function acceptOwnership() external;
}