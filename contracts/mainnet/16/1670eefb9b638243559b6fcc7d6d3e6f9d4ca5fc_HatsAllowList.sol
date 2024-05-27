// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import "../../interfaces/IChoices.sol";

import {IHats} from "hats-protocol/Interfaces/IHats.sol";
import {Contest} from "../../Contest.sol";
import {ContestStatus} from "../../core/ContestStatus.sol";
import {ModuleType} from "../../core/ModuleType.sol";

/// @title HatsAllowList
/// @author @jord<https://github.com/jordanlesich>, @dekanbro<https://github.com/dekanbro>
/// @notice Uses Hats to permission the selection of choices for a contest
contract HatsAllowList is IChoices {
    /// ===============================
    /// ========== Events =============
    /// ===============================

    /// @notice Emitted when the contract is initialized
    event Initialized(address contest, address hatsAddress, uint256 hatId);

    /// @notice Emitted when a choice is registered
    event Registered(bytes32 choiceId, ChoiceData choiceData, address contest);

    /// @notice Emitted when a choice is removed
    event Removed(bytes32 choiceId, address contest);

    /// ===============================
    /// ========== Struct =============
    /// ===============================

    /// @notice Struct to hold the metadata and bytes data of a choice
    struct ChoiceData {
        Metadata metadata;
        bytes data;
        bool exists;
    }

    /// ===============================
    /// ========== Storage ============
    /// ===============================

    /// @notice The name and version of the module
    string public constant MODULE_NAME = "HatsAllowList_v0.1.1";

    /// @notice The type of module
    ModuleType public constant MODULE_TYPE = ModuleType.Choices;

    /// @notice Reference to the Hats Protocol contract
    IHats public hats;

    /// @notice The hatId of the hat that is allowed to make choices
    uint256 public hatId;

    /// @notice Reference to the Contest contract
    Contest public contest;

    /// @notice This maps the data for each choice to its choiceId
    /// @dev choiceId => ChoiceData
    mapping(bytes32 => ChoiceData) public choices;

    /// ===============================
    /// ========== Modifiers ==========
    /// ===============================

    /// Review: It is likely that this check is redundant, as the caller must be in good standing to be a wearer, but need to test more

    /// @notice Ensures the caller is the wearer of the hat and in good standing
    /// @dev The caller must be the wearer of the hat and in good standing
    modifier onlyTrustedWearer() {
        require(
            hats.isWearerOfHat(msg.sender, hatId) && hats.isInGoodStanding(msg.sender, hatId),
            "Caller is not wearer or in good standing"
        );
        _;
    }

    /// @notice Ensures the contest is in the populating state
    /// @dev The contest must be in the populating state
    modifier onlyContestPopulating() {
        require(contest.isStatus(ContestStatus.Populating), "Contest is not in populating state");
        _;
    }

    /// ===============================
    /// ========== Init ===============
    /// ===============================

    constructor() {}

    /// @notice Initializes the contract with the contest, hats, and hatId
    /// @param _contest The address of the Contest contract
    /// @param _initData The initialization data for the contract
    /// @dev Bytes data includes the hats address, hatId, and prepopulated choices
    function initialize(address _contest, bytes calldata _initData) external override {
        (address _hats, uint256 _hatId, bytes[] memory _prepopulatedChoices) =
            abi.decode(_initData, (address, uint256, bytes[]));

        contest = Contest(_contest);

        hats = IHats(_hats);
        hatId = _hatId;

        if (_prepopulatedChoices.length > 0) {
            for (uint256 i = 0; i < _prepopulatedChoices.length;) {
                (bytes32 choiceId, bytes memory _data) = abi.decode(_prepopulatedChoices[i], (bytes32, bytes));
                _registerChoice(choiceId, _data);

                unchecked {
                    i++;
                }
            }
        }

        emit Initialized(_contest, _hats, _hatId);
    }

    /// ===============================
    /// ========== Setters ============
    /// ===============================

    /// @notice Registers a choice with the contract
    /// @param _choiceId The unique identifier for the choice
    /// @param _data The data for the choice
    /// @dev Bytes data includes the metadata and choice data
    function registerChoice(bytes32 _choiceId, bytes memory _data) external onlyTrustedWearer onlyContestPopulating {
        _registerChoice(_choiceId, _data);
    }

    /// @notice Internal function to register a choice
    /// @param _choiceId The unique identifier for the choice
    /// @param _data The data for the choice
    /// @dev Bytes data includes the metadata and choice data
    function _registerChoice(bytes32 _choiceId, bytes memory _data) private {
        (bytes memory _choiceData, Metadata memory _metadata) = abi.decode(_data, (bytes, Metadata));

        choices[_choiceId] = ChoiceData(_metadata, _choiceData, true);

        emit Registered(_choiceId, choices[_choiceId], address(contest));
    }

    /// @notice Removes a choice from the contract
    /// @param _choiceId The unique identifier for the choice
    function removeChoice(bytes32 _choiceId, bytes calldata) external onlyTrustedWearer onlyContestPopulating {
        require(isValidChoice(_choiceId), "Choice does not exist");

        delete choices[_choiceId];

        emit Removed(_choiceId, address(contest));
    }

    /// @notice Finalizes the choices for the contest
    function finalizeChoices() external onlyTrustedWearer onlyContestPopulating {
        contest.finalizeChoices();
    }

    /// ===============================
    /// ========== Getters ============
    /// ===============================

    /// @notice Checks if a choice is valid
    /// @param _choiceId The unique identifier for the choice
    function isValidChoice(bytes32 _choiceId) public view returns (bool) {
        return choices[_choiceId].exists;
    }
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

// SPDX-License-Identifier: AGPL-3.0
// Copyright (C) 2023 Haberdasher Labs
//
// This program is free software: you can redistribute it and/or modify
// it under the terms of the GNU Affero General Public License as published by
// the Free Software Foundation, either version 3 of the License, or
// (at your option) any later version.
//
// This program is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
// GNU Affero General Public License for more details.
//
// You should have received a copy of the GNU Affero General Public License
// along with this program.  If not, see <https://www.gnu.org/licenses/>.

pragma solidity >=0.8.13;

import "./IHatsIdUtilities.sol";
import "./HatsErrors.sol";
import "./HatsEvents.sol";

interface IHats is IHatsIdUtilities, HatsErrors, HatsEvents {
    function mintTopHat(address _target, string memory _details, string memory _imageURI)
        external
        returns (uint256 topHatId);

    function createHat(
        uint256 _admin,
        string calldata _details,
        uint32 _maxSupply,
        address _eligibility,
        address _toggle,
        bool _mutable,
        string calldata _imageURI
    ) external returns (uint256 newHatId);

    function batchCreateHats(
        uint256[] calldata _admins,
        string[] calldata _details,
        uint32[] calldata _maxSupplies,
        address[] memory _eligibilityModules,
        address[] memory _toggleModules,
        bool[] calldata _mutables,
        string[] calldata _imageURIs
    ) external returns (bool success);

    function getNextId(uint256 _admin) external view returns (uint256 nextId);

    function mintHat(uint256 _hatId, address _wearer) external returns (bool success);

    function batchMintHats(uint256[] calldata _hatIds, address[] calldata _wearers) external returns (bool success);

    function setHatStatus(uint256 _hatId, bool _newStatus) external returns (bool toggled);

    function checkHatStatus(uint256 _hatId) external returns (bool toggled);

    function setHatWearerStatus(uint256 _hatId, address _wearer, bool _eligible, bool _standing)
        external
        returns (bool updated);

    function checkHatWearerStatus(uint256 _hatId, address _wearer) external returns (bool updated);

    function renounceHat(uint256 _hatId) external;

    function transferHat(uint256 _hatId, address _from, address _to) external;

    /*//////////////////////////////////////////////////////////////
                              HATS ADMIN FUNCTIONS
    //////////////////////////////////////////////////////////////*/

    function makeHatImmutable(uint256 _hatId) external;

    function changeHatDetails(uint256 _hatId, string memory _newDetails) external;

    function changeHatEligibility(uint256 _hatId, address _newEligibility) external;

    function changeHatToggle(uint256 _hatId, address _newToggle) external;

    function changeHatImageURI(uint256 _hatId, string memory _newImageURI) external;

    function changeHatMaxSupply(uint256 _hatId, uint32 _newMaxSupply) external;

    function requestLinkTopHatToTree(uint32 _topHatId, uint256 _newAdminHat) external;

    function approveLinkTopHatToTree(
        uint32 _topHatId,
        uint256 _newAdminHat,
        address _eligibility,
        address _toggle,
        string calldata _details,
        string calldata _imageURI
    ) external;

    function unlinkTopHatFromTree(uint32 _topHatId, address _wearer) external;

    function relinkTopHatWithinTree(
        uint32 _topHatDomain,
        uint256 _newAdminHat,
        address _eligibility,
        address _toggle,
        string calldata _details,
        string calldata _imageURI
    ) external;

    /*//////////////////////////////////////////////////////////////
                              VIEW FUNCTIONS
    //////////////////////////////////////////////////////////////*/

    function viewHat(uint256 _hatId)
        external
        view
        returns (
            string memory details,
            uint32 maxSupply,
            uint32 supply,
            address eligibility,
            address toggle,
            string memory imageURI,
            uint16 lastHatId,
            bool mutable_,
            bool active
        );

    function isWearerOfHat(address _user, uint256 _hatId) external view returns (bool isWearer);

    function isAdminOfHat(address _user, uint256 _hatId) external view returns (bool isAdmin);

    function isInGoodStanding(address _wearer, uint256 _hatId) external view returns (bool standing);

    function isEligible(address _wearer, uint256 _hatId) external view returns (bool eligible);

    function getHatEligibilityModule(uint256 _hatId) external view returns (address eligibility);

    function getHatToggleModule(uint256 _hatId) external view returns (address toggle);

    function getHatMaxSupply(uint256 _hatId) external view returns (uint32 maxSupply);

    function hatSupply(uint256 _hatId) external view returns (uint32 supply);

    function getImageURIForHat(uint256 _hatId) external view returns (string memory _uri);

    function balanceOf(address wearer, uint256 hatId) external view returns (uint256 balance);

    function balanceOfBatch(address[] calldata _wearers, uint256[] calldata _hatIds)
        external
        view
        returns (uint256[] memory);

    function uri(uint256 id) external view returns (string memory _uri);
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

enum ModuleType {
    Unknown,
    Choices,
    Votes,
    Points,
    Execution
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

struct Metadata {
    /// @notice Protocol ID corresponding to a specific protocol (currently using IPFS = 1)
    uint256 protocol;
    /// @notice Pointer (hash) to fetch metadata for the specified protocol
    string pointer;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import {ModuleType} from "../core/ModuleType.sol";

interface IModule {
    function MODULE_NAME() external view returns (string memory);
    function MODULE_TYPE() external view returns (ModuleType);

    function initialize(address _contest, bytes calldata initData) external;
}

// SPDX-License-Identifier: AGPL-3.0
// Copyright (C) 2023 Haberdasher Labs
//
// This program is free software: you can redistribute it and/or modify
// it under the terms of the GNU Affero General Public License as published by
// the Free Software Foundation, either version 3 of the License, or
// (at your option) any later version.
//
// This program is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
// GNU Affero General Public License for more details.
//
// You should have received a copy of the GNU Affero General Public License
// along with this program.  If not, see <https://www.gnu.org/licenses/>.

pragma solidity >=0.8.13;

interface IHatsIdUtilities {
    function buildHatId(uint256 _admin, uint16 _newHat) external pure returns (uint256 id);

    function getHatLevel(uint256 _hatId) external view returns (uint32 level);

    function getLocalHatLevel(uint256 _hatId) external pure returns (uint32 level);

    function isTopHat(uint256 _hatId) external view returns (bool _topHat);

    function isLocalTopHat(uint256 _hatId) external pure returns (bool _localTopHat);

    function isValidHatId(uint256 _hatId) external view returns (bool validHatId);

    function getAdminAtLevel(uint256 _hatId, uint32 _level) external view returns (uint256 admin);

    function getAdminAtLocalLevel(uint256 _hatId, uint32 _level) external pure returns (uint256 admin);

    function getTopHatDomain(uint256 _hatId) external view returns (uint32 domain);

    function getTippyTopHatDomain(uint32 _topHatDomain) external view returns (uint32 domain);

    function noCircularLinkage(uint32 _topHatDomain, uint256 _linkedAdmin) external view returns (bool notCircular);

    function sameTippyTopHatDomain(uint32 _topHatDomain, uint256 _newAdminHat)
        external
        view
        returns (bool sameDomain);
}

// SPDX-License-Identifier: AGPL-3.0
// Copyright (C) 2023 Haberdasher Labs
//
// This program is free software: you can redistribute it and/or modify
// it under the terms of the GNU Affero General Public License as published by
// the Free Software Foundation, either version 3 of the License, or
// (at your option) any later version.
//
// This program is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
// GNU Affero General Public License for more details.
//
// You should have received a copy of the GNU Affero General Public License
// along with this program.  If not, see <https://www.gnu.org/licenses/>.

pragma solidity >=0.8.13;

interface HatsErrors {
    /// @notice Emitted when `user` is attempting to perform an action on `hatId` but is not wearing one of `hatId`'s admin hats
    /// @dev Can be equivalent to `NotHatWearer(buildHatId(hatId))`, such as when emitted by `approveLinkTopHatToTree` or `relinkTopHatToTree`
    error NotAdmin(address user, uint256 hatId);

    /// @notice Emitted when attempting to perform an action as or for an account that is not a wearer of a given hat
    error NotHatWearer();

    /// @notice Emitted when attempting to perform an action that requires being either an admin or wearer of a given hat
    error NotAdminOrWearer();

    /// @notice Emitted when attempting to mint `hatId` but `hatId`'s maxSupply has been reached
    error AllHatsWorn(uint256 hatId);

    /// @notice Emitted when attempting to create a hat with a level 14 hat as its admin
    error MaxLevelsReached();

    /// @notice Emitted when an attempted hat id has empty intermediate level(s)
    error InvalidHatId();

    /// @notice Emitted when attempting to mint `hatId` to a `wearer` who is already wearing the hat
    error AlreadyWearingHat(address wearer, uint256 hatId);

    /// @notice Emitted when attempting to mint a non-existant hat
    error HatDoesNotExist(uint256 hatId);

    /// @notice Emmitted when attempting to mint or transfer a hat that is not active
    error HatNotActive();

    /// @notice Emitted when attempting to mint or transfer a hat to an ineligible wearer
    error NotEligible();

    /// @notice Emitted when attempting to check or set a hat's status from an account that is not that hat's toggle module
    error NotHatsToggle();

    /// @notice Emitted when attempting to check or set a hat wearer's status from an account that is not that hat's eligibility module
    error NotHatsEligibility();

    /// @notice Emitted when array arguments to a batch function have mismatching lengths
    error BatchArrayLengthMismatch();

    /// @notice Emitted when attempting to mutate or transfer an immutable hat
    error Immutable();

    /// @notice Emitted when attempting to change a hat's maxSupply to a value lower than its current supply
    error NewMaxSupplyTooLow();

    /// @notice Emitted when attempting to link a tophat to a new admin for which the tophat serves as an admin
    error CircularLinkage();

    /// @notice Emitted when attempting to link or relink a tophat to a separate tree
    error CrossTreeLinkage();

    /// @notice Emitted when attempting to link a tophat without a request
    error LinkageNotRequested();

    /// @notice Emitted when attempting to unlink a tophat that does not have a wearer
    /// @dev This ensures that unlinking never results in a bricked tophat
    error InvalidUnlink();

    /// @notice Emmited when attempting to change a hat's eligibility or toggle module to the zero address
    error ZeroAddress();

    /// @notice Emmitted when attempting to change a hat's details or imageURI to a string with over 7000 bytes (~characters)
    /// @dev This protects against a DOS attack where an admin iteratively extend's a hat's details or imageURI
    ///      to be so long that reading it exceeds the block gas limit, breaking `uri()` and `viewHat()`
    error StringTooLong();
}

// SPDX-License-Identifier: AGPL-3.0
// Copyright (C) 2023 Haberdasher Labs
//
// This program is free software: you can redistribute it and/or modify
// it under the terms of the GNU Affero General Public License as published by
// the Free Software Foundation, either version 3 of the License, or
// (at your option) any later version.
//
// This program is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
// GNU Affero General Public License for more details.
//
// You should have received a copy of the GNU Affero General Public License
// along with this program.  If not, see <https://www.gnu.org/licenses/>.

pragma solidity >=0.8.13;

interface HatsEvents {
    /// @notice Emitted when a new hat is created
    /// @param id The id for the new hat
    /// @param details A description of the Hat
    /// @param maxSupply The total instances of the Hat that can be worn at once
    /// @param eligibility The address that can report on the Hat wearer's status
    /// @param toggle The address that can deactivate the Hat
    /// @param mutable_ Whether the hat's properties are changeable after creation
    /// @param imageURI The image uri for this hat and the fallback for its
    event HatCreated(
        uint256 id,
        string details,
        uint32 maxSupply,
        address eligibility,
        address toggle,
        bool mutable_,
        string imageURI
    );

    /// @notice Emitted when a hat wearer's standing is updated
    /// @dev Eligibility is excluded since the source of truth for eligibility is the eligibility module and may change without a transaction
    /// @param hatId The id of the wearer's hat
    /// @param wearer The wearer's address
    /// @param wearerStanding Whether the wearer is in good standing for the hat
    event WearerStandingChanged(uint256 hatId, address wearer, bool wearerStanding);

    /// @notice Emitted when a hat's status is updated
    /// @param hatId The id of the hat
    /// @param newStatus Whether the hat is active
    event HatStatusChanged(uint256 hatId, bool newStatus);

    /// @notice Emitted when a hat's details are updated
    /// @param hatId The id of the hat
    /// @param newDetails The updated details
    event HatDetailsChanged(uint256 hatId, string newDetails);

    /// @notice Emitted when a hat's eligibility module is updated
    /// @param hatId The id of the hat
    /// @param newEligibility The updated eligibiliy module
    event HatEligibilityChanged(uint256 hatId, address newEligibility);

    /// @notice Emitted when a hat's toggle module is updated
    /// @param hatId The id of the hat
    /// @param newToggle The updated toggle module
    event HatToggleChanged(uint256 hatId, address newToggle);

    /// @notice Emitted when a hat's mutability is updated
    /// @param hatId The id of the hat
    event HatMutabilityChanged(uint256 hatId);

    /// @notice Emitted when a hat's maximum supply is updated
    /// @param hatId The id of the hat
    /// @param newMaxSupply The updated max supply
    event HatMaxSupplyChanged(uint256 hatId, uint32 newMaxSupply);

    /// @notice Emitted when a hat's image URI is updated
    /// @param hatId The id of the hat
    /// @param newImageURI The updated image URI
    event HatImageURIChanged(uint256 hatId, string newImageURI);

    /// @notice Emitted when a tophat linkage is requested by its admin
    /// @param domain The domain of the tree tophat to link
    /// @param newAdmin The tophat's would-be admin in the parent tree
    event TopHatLinkRequested(uint32 domain, uint256 newAdmin);

    /// @notice Emitted when a tophat is linked to a another tree
    /// @param domain The domain of the newly-linked tophat
    /// @param newAdmin The tophat's new admin in the parent tree
    event TopHatLinked(uint32 domain, uint256 newAdmin);
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

interface IContest {
    function getTotalVotesForChoice(bytes32 choiceId) external view returns (uint256);

    function getChoices() external view returns (bytes32[] memory);

    function isFinalized() external view returns (bool);

    function claimPoints() external;

    function vote(bytes32 choiceId, uint256 amount, bytes memory data) external;

    function retractVote(bytes32 choiceId, uint256 amount, bytes memory data) external;

    function finalize() external;
}