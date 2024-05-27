// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import {ContestStatus} from "../../core/ContestStatus.sol";
import {Contest} from "../../Contest.sol";
import {IExecution} from "../../interfaces/IExecution.sol";
import {ModuleType} from "../../core/ModuleType.sol";

contract EmptyExecution is IExecution {
    string public constant MODULE_NAME = "EmptyExecution_v0.1.1";

    ModuleType public constant MODULE_TYPE = ModuleType.Execution;

    Contest public contest;

    function initialize(address _contest, bytes memory) public {
        contest = Contest(_contest);
    }

    function execute(bytes memory) public {
        require(contest.getStatus() == ContestStatus.Finalized, "Contest is not finalized");
        contest.execute();
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

enum ContestStatus {
    None,
    Populating,
    Voting,
    Continuous,
    Finalized,
    Executed
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import {ReentrancyGuard} from "openzeppelin-contracts/contracts/security/ReentrancyGuard.sol";

import "./interfaces/IFinalizationStrategy.sol";
import "./interfaces/IVotes.sol";
import "./interfaces/IPoints.sol";
import "./interfaces/IChoices.sol";
import "./interfaces/IContest.sol";

import {ContestStatus} from "./core/ContestStatus.sol";

/// @title Stem Contest
/// @author @jord<https://github.com/jordanlesich>, @dekanbro<https://github.com/dekanbro>
/// @notice Simple, minimalistic TCR Voting contract that composes voting, allocation, choices, and execution modules and orders their interactions
contract Contest is ReentrancyGuard {
    /// ===============================
    /// ========== Events =============
    /// ===============================

    /// @notice Emitted when the Contest is initialized
    event ContestInitialized(
        address votesModule,
        address pointsModule,
        address choicesModule,
        address executionModule,
        bool isContinuous,
        bool isRetractable,
        ContestStatus status
    );

    /// @notice Emitted when the Contest Status is updated to a new status
    event ContestStatusChanged(ContestStatus status);

    /// ================================
    /// ========== Storage =============
    /// ================================

    /// @notice Contest version
    string public constant CONTEST_VERSION = "0.1.0";

    /// @notice Reference to the Voting contract module.
    IVotes public votesModule;

    /// @notice Reference to the Points contract module.
    IPoints public pointsModule;

    /// @notice Reference to the Choices contract module.
    IChoices public choicesModule;

    /// @notice Address of the Execution contract module.
    address public executionModule;

    /// @notice Current status of the Contest.
    ContestStatus public contestStatus;

    /// @notice Flag to determine if the contest is continuous.
    bool public isContinuous;

    /// @notice Flag to determine if voting is retractable.
    bool public isRetractable;

    /// ===============================
    /// ======== Modifiers ============
    /// ===============================

    modifier onlyVotingPeriod() {
        require(
            contestStatus == ContestStatus.Voting || (contestStatus == ContestStatus.Continuous && isContinuous),
            "Contest is not in voting state"
        );
        _;
    }

    /// @notice Modifier to check if the choice is valid (usually used to check if the choice exists)
    /// @dev Throws if the choice does not exist or is invalid
    modifier onlyValidChoice(bytes32 choiceId) {
        require(choicesModule.isValidChoice(choiceId), "Choice does not exist");
        _;
    }

    /// @notice Modifier to check if the voter has enough points to allocate
    /// @dev Throws if voter does not have enough points to allocate
    modifier onlyCanAllocate(address _voter, uint256 _amount) {
        require(pointsModule.hasVotingPoints(_voter, _amount), "Insufficient points available");
        _;
    }

    /// @notice Modifier to check if the voter has enough points allocated
    /// @dev Throws if voter does not have enough points allocated
    modifier onlyHasAllocated(address _voter, uint256 _amount) {
        require(pointsModule.hasAllocatedPoints(_voter, _amount), "Insufficient points allocated");
        _;
    }

    /// @notice Modifier to check if the contest is retractable
    /// @dev Throws if the contest is not retractable
    modifier onlyContestRetractable() {
        require(isRetractable, "Votes are not retractable");
        _;
    }

    /// ===============================
    /// ========= Initialize ==========
    /// ===============================

    constructor() {}

    /// @notice Initialize the strategy
    /// @param  _initData The data to initialize the contest (votes, points, choices, execution, isContinuous, isRetractable)
    function initialize(bytes memory _initData) public {
        (
            address _votesContract,
            address _pointsContract,
            address _choicesContract,
            address _executionContract,
            bool _isContinuous,
            bool _isRetractable
        ) = abi.decode(_initData, (address, address, address, address, bool, bool));

        votesModule = IVotes(_votesContract);
        pointsModule = IPoints(_pointsContract);
        choicesModule = IChoices(_choicesContract);
        executionModule = _executionContract;
        isRetractable = _isRetractable;

        if (isContinuous) {
            contestStatus = ContestStatus.Continuous;
        } else {
            contestStatus = ContestStatus.Populating;
        }

        isContinuous = _isContinuous;

        emit ContestInitialized(
            _votesContract,
            _pointsContract,
            _choicesContract,
            _executionContract,
            _isContinuous,
            _isRetractable,
            contestStatus
        );
    }

    /// ===============================
    /// ====== Module Interactions ====
    /// ===============================

    /// @notice Claim points from the Points module
    function claimPoints() public virtual onlyVotingPeriod {
        pointsModule.claimPoints();
    }

    /// @notice Vote on a choice
    /// @param _choiceId The ID of the choice to vote on
    /// @param _amount The amount of points to vote with
    /// @param _data Additional data to include with the vote
    function vote(bytes32 _choiceId, uint256 _amount, bytes memory _data)
        public
        virtual
        nonReentrant
        onlyVotingPeriod
        onlyValidChoice(_choiceId)
        onlyCanAllocate(msg.sender, _amount)
    {
        _vote(_choiceId, _amount, _data);
    }

    /// @notice Retract a vote on a choice
    /// @param _choiceId The ID of the choice to retract the vote from
    /// @param _amount The amount of points to retract
    /// @param _data Additional data to include with the retraction
    function retractVote(bytes32 _choiceId, uint256 _amount, bytes memory _data)
        public
        virtual
        nonReentrant
        onlyVotingPeriod
        onlyContestRetractable
        onlyValidChoice(_choiceId)
        onlyHasAllocated(msg.sender, _amount)
    {
        _retractVote(_choiceId, _amount, _data);
    }

    /// @notice Change a vote from one choice to another
    /// @param _oldChoiceId The ID of the choice to retract the vote from
    /// @param _newChoiceId The ID of the choice to vote on
    /// @param _amount The amount of points to vote with
    /// @param _data Additional data to include with the vote
    function changeVote(bytes32 _oldChoiceId, bytes32 _newChoiceId, uint256 _amount, bytes memory _data)
        public
        virtual
        nonReentrant
        onlyVotingPeriod
        onlyContestRetractable
        onlyValidChoice(_oldChoiceId)
        onlyValidChoice(_newChoiceId)
        onlyHasAllocated(msg.sender, _amount)
    {
        _retractVote(_oldChoiceId, _amount, _data);
        require(pointsModule.hasVotingPoints(msg.sender, _amount), "Insufficient points available");
        _vote(_newChoiceId, _amount, _data);
    }

    /// @notice Batch vote on multiple choices
    /// @param _choiceIds The IDs of the choices to vote on
    /// @param _amounts The amounts of points to vote with
    /// @param _data Additional data to include with the votes
    /// @param _totalAmount The total amount of points to vote with
    function batchVote(
        bytes32[] memory _choiceIds,
        uint256[] memory _amounts,
        bytes[] memory _data,
        uint256 _totalAmount
    ) public virtual nonReentrant onlyVotingPeriod onlyCanAllocate(msg.sender, _totalAmount) {
        require(
            _choiceIds.length == _amounts.length && _choiceIds.length == _data.length,
            "Array mismatch: Invalid input length"
        );

        uint256 totalAmount = 0;

        for (uint256 i = 0; i < _choiceIds.length;) {
            require(choicesModule.isValidChoice(_choiceIds[i]), "Choice does not exist");
            totalAmount += _amounts[i];

            _vote(_choiceIds[i], _amounts[i], _data[i]);

            unchecked {
                i++;
            }
        }

        require(totalAmount == _totalAmount, "Invalid total amount");
    }

    /// @notice Batch retract votes on multiple choices
    /// @param _choiceIds The IDs of the choices to retract votes from
    /// @param _amounts The amounts of points to retract
    /// @param _data Additional data to include with the retractions
    /// @param _totalAmount The total amount of points to retract
    function batchRetractVote(
        bytes32[] memory _choiceIds,
        uint256[] memory _amounts,
        bytes[] memory _data,
        uint256 _totalAmount
    ) public virtual nonReentrant onlyVotingPeriod onlyContestRetractable onlyHasAllocated(msg.sender, _totalAmount) {
        require(
            _choiceIds.length == _amounts.length && _choiceIds.length == _data.length,
            "Array mismatch: Invalid input length"
        );

        uint256 totalAmount = 0;

        for (uint256 i = 0; i < _choiceIds.length;) {
            require(choicesModule.isValidChoice(_choiceIds[i]), "Choice does not exist");
            totalAmount += _amounts[i];

            _retractVote(_choiceIds[i], _amounts[i], _data[i]);

            unchecked {
                i++;
            }
        }

        require(totalAmount == _totalAmount, "Invalid total amount");
    }

    /// ===============================
    /// ========== Setters ============
    /// ===============================

    /// @notice Finalize the choices
    /// @dev Only callable by the Choices module
    function finalizeChoices() external {
        require(contestStatus == ContestStatus.Populating, "Contest is not in populating state");
        require(msg.sender == address(choicesModule), "Only choices module");
        contestStatus = ContestStatus.Voting;

        emit ContestStatusChanged(ContestStatus.Voting);
    }

    /// @notice Finalize the voting period
    /// @dev Only callable by the Votes module
    function finalizeVoting() external onlyVotingPeriod {
        require(msg.sender == address(votesModule), "Only votes module");
        contestStatus = ContestStatus.Finalized;

        emit ContestStatusChanged(ContestStatus.Finalized);
    }

    /// @notice Finalize the continuous voting period
    /// @dev Only callable by the Votes or Choices module
    function finalizeContinuous() external {
        require(contestStatus == ContestStatus.Continuous, "Contest is not continuous");
        require(
            msg.sender == address(votesModule) || msg.sender == address(choicesModule), "Only votes or choices module"
        );
        contestStatus = ContestStatus.Finalized;

        emit ContestStatusChanged(ContestStatus.Finalized);
    }

    /// @notice Execute the contest
    /// @dev Only callable by the Execution module
    function execute() public virtual {
        require(contestStatus == ContestStatus.Finalized, "Contest is not finalized");
        require(msg.sender == address(executionModule), "Only execution module");
        contestStatus = ContestStatus.Executed;

        emit ContestStatusChanged(ContestStatus.Executed);
    }

    /// ===============================
    /// ========== Internal ===========
    /// ===============================

    /// @notice Internal function to vote on a choice
    /// @param _choiceId The ID of the choice to vote on
    /// @param _amount The amount of points to vote with
    /// @param _data Additional data to include with the vote
    function _vote(bytes32 _choiceId, uint256 _amount, bytes memory _data) internal {
        pointsModule.allocatePoints(msg.sender, _amount);
        votesModule.vote(msg.sender, _choiceId, _amount, _data);
    }

    /// @notice Internal function to retract a vote on a choice
    /// @param _choiceId The ID of the choice to retract the vote from
    /// @param _amount The amount of points to retract
    /// @param _data Additional data to include with the retraction
    function _retractVote(bytes32 _choiceId, uint256 _amount, bytes memory _data) internal {
        pointsModule.releasePoints(msg.sender, _amount);
        votesModule.retractVote(msg.sender, _choiceId, _amount, _data);
    }

    /// ===============================
    /// ========== Getters ============
    /// ===============================

    /// @notice Get the current status of the Contest
    /// @return The current status of the Contest
    function getStatus() public view returns (ContestStatus) {
        return contestStatus;
    }

    /// @notice Check if the Contest is in a specific status
    /// @param _status The status to check
    /// @return True if the Contest is in the specified status
    function isStatus(ContestStatus _status) public view returns (bool) {
        return contestStatus == _status;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import {IModule} from "../interfaces/IModule.sol";

interface IExecution is IModule {
    function execute(bytes memory _data) external;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

enum ModuleType {
    Unknown,
    Choices,
    Votes,
    Points,
    Execution
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (security/ReentrancyGuard.sol)

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
        // On the first call to nonReentrant, _notEntered will be true
        require(_status != _ENTERED, "ReentrancyGuard: reentrant call");

        // Any calls to nonReentrant after this point will fail
        _status = _ENTERED;

        _;

        // By storing the original value once again, a refund is triggered (see
        // https://eips.ethereum.org/EIPS/eip-2200)
        _status = _NOT_ENTERED;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

interface IFinalizationStrategy {
    function execute(address contestAddress, bytes32[] calldata choices)
        external
        returns (bytes32[] memory winningChoices);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import {IModule} from "./IModule.sol";

interface IVotes is IModule {
    function vote(address voter, bytes32 choiceId, uint256 amount, bytes memory data) external;

    function retractVote(address voter, bytes32 choiceId, uint256 amount, bytes memory data) external;

    function getTotalVotesForChoice(bytes32 choiceId) external view returns (uint256);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import {IModule} from "./IModule.sol";

interface IPoints is IModule {
    /**
     * @dev Event emitted when a user claims voting points.
     * @param user The address of the user claiming the points.
     * @param amount The number of points claimed.
     */
    event PointsClaimed(address indexed user, uint256 amount);

    /**
     * @dev Event emitted when voting points are allocated for a user.
     * @param user The address of the user for whom points are allocated.
     * @param amount The amount of points allocated.
     */
    event PointsAllocated(address indexed user, uint256 amount);

    /**
     * @dev Event emitted when voting points are released for a user.
     * @param user The address of the user for whom points are released.
     * @param amount The amount of points released.
     */
    event PointsReleased(address indexed user, uint256 amount);

    /**
     * @dev Users claim their voting points based on their current token balance.
     * Points are calculated as the total token balance minus any already allocated points.
     */
    function claimPoints() external;

    /**
     * @dev Allocate points for voting, reducing the available points and increasing the allocated points.
     * @param voter The address of the voter who is allocating points.
     * @param amount The number of points to allocate.
     */
    function allocatePoints(address voter, uint256 amount) external;

    /**
     * @dev Release points after voting, moving them from allocated to available.
     * @param voter The address of the voter who is releasing points.
     * @param amount The number of points to release.
     */
    function releasePoints(address voter, uint256 amount) external;

    /**
     * @dev Retrieve the current available voting points for a user.
     * @param user The address of the user to query voting points.
     * @return The current number of available voting points for the user.
     */
    function getPoints(address user) external view returns (uint256);

    function hasVotingPoints(address user, uint256 amount) external view returns (bool);

    function hasAllocatedPoints(address user, uint256 amount) external view returns (bool);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import {Metadata} from "../core/Metadata.sol";
import {IModule} from "./IModule.sol";

interface IChoices is IModule {
    // Note: Edited to remove uri as we can incorporate that into data param

    function registerChoice(bytes32 choiceId, bytes memory data) external;

    function removeChoice(bytes32 choiceId, bytes memory data) external;

    function isValidChoice(bytes32 choiceId) external view returns (bool);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

interface IContest {
    function getTotalVotesForChoice(bytes32 choiceId) external view returns (uint256);

    function getChoices() external view returns (bytes32[] memory);

    function isFinalized() external view returns (bool);

    function claimPoints() external;

    function vote(bytes32 choiceId, uint256 amount, bytes memory data) external;

    function retractVote(bytes32 choiceId, uint256 amount, bytes memory data) external;

    function finalize() external;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import {ModuleType} from "../core/ModuleType.sol";

interface IModule {
    function MODULE_NAME() external view returns (string memory);
    function MODULE_TYPE() external view returns (ModuleType);

    function initialize(address _contest, bytes calldata initData) external;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

struct Metadata {
    /// @notice Protocol ID corresponding to a specific protocol (currently using IPFS = 1)
    uint256 protocol;
    /// @notice Pointer (hash) to fetch metadata for the specified protocol
    string pointer;
}