// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "./IERC721ReceiverUpgradeable.sol";
import "./ReentrancyGuardUpgradeable.sol";
import "./OwnableUpgradeable.sol";

import "./ImpishCrystal.sol";
import "./StakingV2.sol";
import "./SpiralBits.sol";

import "./console.sol";

contract RPS is IERC721ReceiverUpgradeable, ReentrancyGuardUpgradeable, OwnableUpgradeable {
  enum Stages {
    Commit,
    Reveal,
    Resolve,
    Claim,
    Shutdown
  }
  Stages public stage;
  uint32 public roundStartTime;

  //------------------
  // Stage transitions
  //-------------------
  modifier atStage(Stages _stage) {
    require(stage == _stage, "WrongStage");
    _;
  }

  modifier timedTransitions() {
    if (stage == Stages.Commit && block.timestamp >= roundStartTime + 3 days) {
      nextStage();
    }
    if (stage == Stages.Reveal && block.timestamp >= roundStartTime + 6 days) {
      nextStage();
    }
    _;
  }

  function nextStage() internal {
    stage = Stages(uint256(stage) + 1);
  }

  ImpishCrystal public crystals;
  StakingV2 public stakingv2;

  //------------------
  // Teams
  //-------------------
  struct TeamInfo {
    uint96 totalScore;
    uint96 winningSpiralBits;
    uint8 symmetriesLost;
    uint32 numCrystals;
  }
  TeamInfo[3] public teams;

  //------------------
  // Players
  //-------------------
  struct PlayerInfo {
    bool revealed;
    bool claimed;
    uint8 team;
    uint16 numCrystals;
    bytes32 commitment;
    uint32 allPlayersIndex;
    uint32[] crystalIDs;
  }

  // Data about all the bets made per address
  mapping(address => PlayerInfo) public players;
  // List of all addresses that are in the current round.
  address[] public allPlayers;

  struct SmallestTeamBonusInfo {
    uint96 bonusInSpiralBits;
    uint32 teamSize;
    uint32 totalCrystalsInSmallestTeams;
  }
  SmallestTeamBonusInfo public smallestTeamBonus;

  //------------------
  // Functions
  //-------------------
  function initialize(address payable _stakingv2) public initializer {
    // Call super initializers
    __Ownable_init();
    __ReentrancyGuard_init();
    
    stakingv2 = StakingV2(_stakingv2);
    crystals = ImpishCrystal(stakingv2.crystals());

    // Allow staking to work for this address with Crystals
    crystals.setApprovalForAll(_stakingv2, true);

    // Allow crystals to spend our spiralbits - Needed to reduce sym for offending players
    SpiralBits(stakingv2.spiralbits()).approve(address(crystals), 2**256 - 1);

    roundStartTime = uint32(block.timestamp);
    stage = Stages.Commit;
  }

  // Commit some Crystals to the game.
  function commit(
    bytes32 commitment,
    address player,
    uint32[] calldata crystalIDs
  ) external nonReentrant timedTransitions atStage(Stages.Commit) {
    require(crystalIDs.length > 0, "NeedAtLeastOne");

    bool alreadyPlaying = players[player].crystalIDs.length > 0;
    if (!alreadyPlaying) {
      // Create a new player
      players[player] = PlayerInfo(
        false,
        false,
        0,
        uint16(crystalIDs.length),
        commitment,
        uint32(allPlayers.length),
        crystalIDs
      );
      allPlayers.push(player);
    } else {
      // Update the existing player
      PlayerInfo storage playerInfo = players[player];

      // If you are adding, you need to use the same commitment (i.e, same password/team)
      require(playerInfo.commitment == commitment, "UseSameCommitment");
      playerInfo.numCrystals += uint16(crystalIDs.length);
      for (uint256 i = 0; i < crystalIDs.length; i++) {
        playerInfo.crystalIDs.push(crystalIDs[i]);
      }
    }

    // Make sure the user owns or has staked the Crystal
    uint32[] memory contractTokenIDs = new uint32[](crystalIDs.length);
    for (uint256 i = 0; i < crystalIDs.length; i++) {
      uint32 tokenId = crystalIDs[i];
      require(crystals.ownerOf(tokenId) == msg.sender, "NotYourCrystal");
      (uint8 currentCrystalSize, , uint8 currentSym, , ) = crystals.crystals(tokenId);
      require(currentCrystalSize == 100, "NeedFullyGrownCrystal");
      require(currentSym >= 5, "NeedAtLeast5Sym");

      // Transfer in all the Crystals and stake them.
      crystals.transferFrom(msg.sender, address(this), tokenId);
      contractTokenIDs[i] = 4_000_000 + tokenId;
    }

    // Stake all the Crystals, to start earning SPIRALBITS
    stakingv2.stakeNFTsForOwner(contractTokenIDs, address(this));
  }

  // Reveal the commitment
  // You can reveal commitments from day 3 to 6
  function revealCommitment(uint256 salt, uint8 team) external nonReentrant timedTransitions atStage(Stages.Reveal) {
    address player = msg.sender;
    require(players[player].numCrystals > 0, "NotPlaying");
    require(!players[player].revealed, "AlreadyRevealed");
    require(players[player].commitment == keccak256(abi.encodePacked(salt, team)), "BadCommitment");

    // Record all the info that was revealed
    players[player].team = team;
    players[player].revealed = true;

    // Do the team accounting.
    uint96 playerScore = 0;
    for (uint256 j = 0; j < players[player].crystalIDs.length; j++) {
      (, , , , uint192 spiralBitsStored) = crystals.crystals(players[player].crystalIDs[j]);
      playerScore += uint96(spiralBitsStored);
    }

    // Add the score to the team
    teams[team].totalScore += playerScore;
    teams[team].numCrystals += uint32(players[player].crystalIDs.length);
  }

  function _resolve() internal nonReentrant timedTransitions atStage(Stages.Resolve) {
    SpiralBits spiralBits = SpiralBits(stakingv2.spiralbits());

    // Shatter and burn all unrevealed crystals.
    for (uint256 i = 0; i < allPlayers.length; i++) {
      address player = allPlayers[i];

      // Collect all ContractTokenIDs for this player so we can unstake them
      uint32[] memory contractTokenIDs = new uint32[](players[player].crystalIDs.length);
      for (uint256 j = 0; j < players[player].crystalIDs.length; j++) {
        uint32 tokenId = players[player].crystalIDs[j];
        contractTokenIDs[j] = 4_000_000 + tokenId;
      }

      // Unstake and collect the spiralbits
      stakingv2.unstakeNFTs(contractTokenIDs, true);

      if (!players[player].revealed) {
        // BAD! Player didn't reveal their commitment, fine them by removing 2 symmetries
        // Mint and burn the SPIRALBITS needed to reduce Symmetries
        spiralBits.mintSpiralBits(address(this), players[player].crystalIDs.length * 2 * 20000 ether);
        for (uint256 j = 0; j < players[player].crystalIDs.length; j++) {
          uint32 tokenId = players[player].crystalIDs[j];
          crystals.decSym(tokenId, 2);

          // Send the crystal back to the user
          crystals.safeTransferFrom(address(this), player, tokenId);
        }
      }
    }

    // Record the smallest team size to calculate the bonus for being in the smallest team.
    uint32 smallestTeamSize = 2**32 - 1;

    // Each team attacks the next team and defends from the previous team
    for (uint256 i = 0; i < 3; i++) {
      if (teams[i].numCrystals < smallestTeamSize) {
        smallestTeamSize = teams[i].numCrystals;
      }

      uint256 nextTeam = (i + 1) % 3;
      if (teams[i].totalScore > teams[nextTeam].totalScore) {
        // 100 size * 1 symmetry * 1000 SPIRALBITS per size per sym * num of crystals involved
        uint96 winnings = 100 * 1 * 1000 ether * uint96(teams[nextTeam].numCrystals);

        teams[i].winningSpiralBits = winnings;
        teams[nextTeam].symmetriesLost = 1;
      } else {
        // Successfully defended, so nothing happens.
      }
    }

    // Find all the teams that have the smallest team size
    uint32 totalCrystalsInSmallestTeams = 0;
    for (uint256 i = 0; i < 3; i++) {
      if (teams[i].numCrystals == smallestTeamSize) {
        totalCrystalsInSmallestTeams += teams[i].numCrystals;
      }
    }

    // Record all the spiralbits we have for the smallest team bonus. Smallest team gets 1M SPIRALBITS bonus
    // plus all the staking SPIRALBITS income
    smallestTeamBonus = SmallestTeamBonusInfo(
      1_000_000 ether + uint96(spiralBits.balanceOf(address(this))),
      smallestTeamSize,
      totalCrystalsInSmallestTeams
    );
    // Burn the bonuses so we can mint it for the individual users again
    spiralBits.burn(spiralBits.balanceOf(address(this)));

    // Set the stage to claim, so everyone can claim their winnings and crystals
    stage = Stages.Claim;
  }

  // After all commitments are revealed, we need to resolve it
  function resolve() external {
    _resolve();
  }

  // Claim for msg.sender directly to save on gas
  function claim() external {
    claimForOwner(msg.sender);
  }

  // Claim the winnings or losses for a player. This can be called for anyone by anyone,
  // so that we can return the winnings to a user even if they don't claim in time.
  function claimForOwner(address player) public {
    require(players[player].revealed, "NotRevealed");

    if (stage == Stages.Reveal) {
      // Attempt to resolve first
      _resolve();
    }

    _claimForOwner(player);
  }

  // Claim for owner internal function
  function _claimForOwner(address player) internal nonReentrant atStage(Stages.Claim) {
    require(!players[player].claimed, "AlreadyClaimed");

    uint8 team = players[player].team;
    require(teams[team].numCrystals > 0, "SafetyAssert2");

    uint96 myWinnings = (teams[team].winningSpiralBits * uint96(players[player].crystalIDs.length)) /
      uint96(teams[team].numCrystals);

    // See if we got a small team bonus
    if (teams[team].numCrystals == smallestTeamBonus.teamSize && smallestTeamBonus.totalCrystalsInSmallestTeams > 0) {
      myWinnings +=
        (smallestTeamBonus.bonusInSpiralBits * uint96(players[player].crystalIDs.length)) /
        smallestTeamBonus.totalCrystalsInSmallestTeams;
    }

    // See if we lost, and if we did, remove a symmetry for each crystal
    if (teams[team].symmetriesLost > 0) {
      // It costs 20k SPIRALBITS to remove symmetries, so mint it. This will be burned
      SpiralBits(stakingv2.spiralbits()).mintSpiralBits(address(this), 20000 ether * players[player].crystalIDs.length);
      for (uint256 j = 0; j < players[player].crystalIDs.length; j++) {
        uint256 tokenId = players[player].crystalIDs[j];
        crystals.decSym(uint32(tokenId), 1);
      }
    }

    // Mark as claimed
    players[player].claimed = true;

    // Generate winnings for the user. Note that this includes the smallest team bonus,
    // which was previously burned, so we just mint it again. Saves on approvals.
    if (myWinnings > 0) {
      SpiralBits(stakingv2.spiralbits()).mintSpiralBits(player, myWinnings);
    }

    // And transfer the crystals back to the user
    for (uint256 j = 0; j < players[player].crystalIDs.length; j++) {
      uint256 tokenId = players[player].crystalIDs[j];
      crystals.safeTransferFrom(address(this), player, tokenId);
    }
  }

  // After a round is finished, reset for next round.
  function resetForNextRound(bool shutdown) external onlyOwner atStage(Stages.Claim) {
    // If not finished, then claim on behalf of all remaining people
    for (uint256 i = 0; i < allPlayers.length; i++) {
      if (players[allPlayers[i]].revealed && !players[allPlayers[i]].claimed) {
        claimForOwner(allPlayers[i]);
      }

      // Also delete the player info
      delete players[allPlayers[i]];
    }

    delete allPlayers;

    if (shutdown) {
      stage = Stages.Shutdown;
    } else {
      // Reset all the team info
      for (uint256 i = 0; i < 3; i++) {
        teams[i] = TeamInfo(0, 0, 0, 0);
      }
      smallestTeamBonus = SmallestTeamBonusInfo(0, 0, 0);
      stage = Stages.Commit;
      roundStartTime = uint32(block.timestamp);

      // Burn any remaining SPIRALBITS, happens if the smallest team was size 0
      SpiralBits spiralBits = SpiralBits(stakingv2.spiralbits());
      spiralBits.burn(spiralBits.balanceOf(address(this)));
    }
  }

  // Function that marks this contract can accept incoming NFT transfers
  function onERC721Received(
    address,
    address,
    uint256,
    bytes calldata
  ) public pure returns (bytes4) {
    // Return this value to accept the NFT
    return IERC721Receiver.onERC721Received.selector;
  }
}