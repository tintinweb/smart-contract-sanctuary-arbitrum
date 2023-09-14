/**
 *Submitted for verification at Arbiscan.io on 2023-09-14
*/

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity 0.8.17;

/**
 * @title Stores common interface names used throughout Spire contracts by registration in the ConfigStore.
 */
library ConfigStoreInterfaces {
    // Receives staked treasure from Contest winners and ETH from minting losing entries.
    bytes32 public constant BENEFICIARY = "BENEFICIARY";
    // Creates new Contests
    bytes32 public constant CONTEST_FACTORY = "CONTEST_FACTORY";
    // Creates new ToggleGovernors
    bytes32 public constant TOGGLE_GOVERNOR_FACTORY = "TOGGLE_GOVERNOR_FACTORY";
    // Creates new TEAM
    bytes32 public constant TEAM = "TEAM";
    // Creates new TEAMPERCENT
    bytes32 public constant TEAM_PERCENT = "TEAM_PERCENT";
}

/**
 * @title Global constants used throughout Spire contracts.
 *
 */
library GlobalConstants {
    uint256 public constant GENESIS_TEXT_COUNT = 6;
    uint256 public constant CONTEST_REWARD_AMOUNT = 100;
    uint256 public constant INITIAL_ECHO_COUNT = 5;
    uint256 public constant DEFAULT_CONTEST_MINIMUM_TIME = 7 days;
    uint256 public constant DEFAULT_CONTEST_MINIMUM_APPROVED_ENTRIES = 8;
    uint256 public constant MAX_CHAPTER_COUNT = 100;
    bytes32 public constant SUPER_ADMIN_ROLE = bytes32(keccak256("SPIRE_SUPER_ADMIN"));
    bytes32 public constant MID_ADMIN_ROLE = bytes32(keccak256("SPIRE_MID_ADMIN"));
}