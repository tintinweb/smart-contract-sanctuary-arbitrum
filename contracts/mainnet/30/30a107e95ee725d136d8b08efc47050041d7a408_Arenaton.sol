//                     _.-'-._
//                  _.'       '-.
//              _.-'   _.   .    '-._
//           _.'   _.eEEE   EEe..    '-._
//       _.-'   _.eEE* EE   EE`*EEe._    '-.
//    _.'   _.eEEE'  . EE   EE .  `*EEe._   '-
//    |   eEEP*'_.eEE' EP   YE  Ee._ `'*EE.   |
//    |   EE  .eEEEE' AV  .. VA.'EEEEe.  EE   |
//    |   EE |EEEEP  AV  /  \ VA.'*E***--**---'._     .------------.    .----------._          /\       .------------.     _.--------._    .-----------._
//    |   EE |EEEP  EEe./    \eEE. E|   _  ___   '    '------------'    |  .......   .        /  \      '----.  .----'    |   ______   .   |   .......   .
//    |   EE |EEP AVVEE/  /\  \EEEA |  |_EE___|   )   .----------- .    |  |      |  |       / /\ \          |  |         |  |      |  |   |  |       |  |
//    |   EE |EP AV  `   /EE\  \ 'EA|            .    '------------'    |  |      |  |      / /  \ \         |  |         |  |      |  |   |  |       |  |
//    |   EE ' _AV   /  /EE|"   \ `E|  |-ee-\   \     .------------.    |  |      |  |     / /  --' \        |  |         |  '------'  .   |  |       |  |
//    |   EE.eEEP   /__/*EE|_____\  '--|.EE  '---'.   '------------'    '--'      '--'    /-/   -----\       '--'          '..........'    '--'       '--'
//    |   EEP            EEE          `'*EE   |
//    |   *   _.eEEEEEEEEEEEEEEEEEEE._   `*   |
//    |     <EEE<  .eeeeeeeeeeeee. `>EEE>     |
//    '-._   `*EEe. `'*EEEEEEE*' _.eEEP'   _.-'
//        `-._   `"Ee._ `*E*'_.eEEP'   _.-'
//            `-.   `*EEe._.eEE*'   _.'
//               `-._   `*V*'   _.-'
//                   '-_     _-'
//                      '-.-'

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "./libraries/AStructs.sol";
import "./libraries/Tools.sol";
import "./libraries/EventsLib.sol";

contract Arenaton is ERC20, ReentrancyGuard {
  uint256 constant premium = 200000;
  uint256 constant pct_denom = 10000000;

  // Mapping for storing event and player data
  mapping(bytes8 => AStructs.Event) private events;
  mapping(address => AStructs.Player) private players;

  // Array for tracking active events
  bytes8[] private activeEvents;
  bytes8[] private closedEvents;

  // Represents the total accumulated commission per token
  uint256 public accumulatedCommissionPerToken;

  // Stores the total commission in ATON
  uint256 public totalCommissionInATON;

  address private owner;
  mapping(address => bool) private authorizedAddresses;

  // Constructor to initialize the contract with the owner
  constructor() ERC20("Arenaton", "ATON") {
    owner = msg.sender;
  }

  // ░█████╗░██╗░░░██╗████████╗██╗░░██╗░█████╗░██████╗░██╗███████╗░█████╗░████████╗██╗░█████╗░███╗░░██╗░██████╗
  // ██╔══██╗██║░░░██║╚══██╔══╝██║░░██║██╔══██╗██╔══██╗██║╚════██║██╔══██╗╚══██╔══╝██║██╔══██╗████╗░██║██╔════╝
  // ███████║██║░░░██║░░░██║░░░███████║██║░░██║██████╔╝██║░░███╔═╝███████║░░░██║░░░██║██║░░██║██╔██╗██║╚█████╗░
  // ██╔══██║██║░░░██║░░░██║░░░██╔══██║██║░░██║██╔══██╗██║██╔══╝░░██╔══██║░░░██║░░░██║██║░░██║██║╚████║░╚═══██╗
  // ██║░░██║╚██████╔╝░░░██║░░░██║░░██║╚█████╔╝██║░░██║██║███████╗██║░░██║░░░██║░░░██║╚█████╔╝██║░╚███║██████╔╝
  // ╚═╝░░╚═╝░╚═════╝░░░░╚═╝░░░╚═╝░░╚═╝░╚════╝░╚═╝░░╚═╝╚═╝╚══════╝╚═╝░░╚═╝░░░╚═╝░░░╚═╝░╚════╝░╚═╝░░╚══╝╚═════╝░

  modifier onlyOwner() {
    require(msg.sender == owner, "Caller is not the owner");
    _;
  }

  modifier onlyAuthorized() {
    require(authorizedAddresses[msg.sender], "Caller is not authorized");
    _;
  }

  /**
   * @dev Adds or removes an authorized address.
   * @param authorizedAddress The address to be added or removed.
   */
  function setAuthorizedAddress(address authorizedAddress) external onlyOwner {
    require(msg.sender == owner, "Caller is not the owner");
    authorizedAddresses[authorizedAddress] = !authorizedAddresses[authorizedAddress];
  }

  // ███████╗██╗░░░██╗███████╗███╗░░██╗████████╗░██████╗
  // ██╔════╝██║░░░██║██╔════╝████╗░██║╚══██╔══╝██╔════╝
  // █████╗░░╚██╗░██╔╝█████╗░░██╔██╗██║░░░██║░░░╚█████╗░
  // ██╔══╝░░░╚████╔╝░██╔══╝░░██║╚████║░░░██║░░░░╚═══██╗
  // ███████╗░░╚██╔╝░░███████╗██║░╚███║░░░██║░░░██████╔╝
  // ╚══════╝░░░╚═╝░░░╚══════╝╚═╝░░╚══╝░░░╚═╝░░░╚═════╝░

  /**
   * @dev Adds a new event to the platform.
   * @param _eventId The unique identifier for the event.
   * @param _startDate The start date of the event.
   * @param _sport The sport associated with the event.
   */
  function addEvent(string memory _eventId, uint256 _startDate, uint8 _sport) external onlyAuthorized {
    bytes8 eid = Tools._stringToBytes8(_eventId); // Convert event ID to bytes8 format

    // Validate event parameters
    require(_startDate > block.timestamp && !events[eid].closed && !events[eid].active, "Event invalid");

    // Populate the event struct with the provided details
    AStructs.populateEvent(events[eid], eid, _startDate, _sport);
    activeEvents.push(eid);

    // Emit an event indicating the event creation
    emit EventsLib.EventStateChanged(_eventId, _eventId, int8(_sport), _startDate, 0);
  }

  // External function to allow a player to stake with ETH or ATON on a specific event
  /**
   * @dev Allows a player to stake with ETH or ATON on a specific event.
   * @param _eventId The unique identifier for the event.
   * @param _amountATON The amount of ATON tokens to stake. If 0, the stake is in ETH.
   * @param _team The team to stake on.
   * @param isGasless Whether the staking should be gasless (true) or not (false).
   * @param _player The player who is staking (only relevant for gasless staking).
   */
  function stake(
    string memory _eventId,
    uint256 _amountATON,
    uint8 _team,
    bool isGasless,
    address _player
  ) external payable nonReentrant {
    bool isETH = msg.value > 0;
    require(isETH || _amountATON > 0, "Cannot stake 0 value");

    address staker = isGasless ? _player : msg.sender;
    if (isGasless) {
      require(authorizedAddresses[msg.sender], "Not authorized to stake");
    }

    if (!isETH) {
      _transfer(staker, address(this), _amountATON); // Ensure _transfer is correctly defined
    }

    _stake(_eventId, isETH ? msg.value : 0, isETH ? 0 : _amountATON, _team, staker);
  }

  // Internal function to handle the shared staking logic
  /**
   * @dev Internal function to handle the staking logic.
   * @param _eventId The unique identifier for the event.
   * @param _amountETH The amount of ETH to stake.
   * @param _amountATON The amount of ATON tokens to stake.
   * @param _team The team to stake on.
   * @param _player The address of the player staking.
   */
  function _stake(
    string memory _eventId,
    uint256 _amountETH,
    uint256 _amountATON,
    uint8 _team,
    address _player
  ) internal {
    bytes8 eid = Tools._stringToBytes8(_eventId); // Convert event ID to bytes8 format
    AStructs.EventDTO memory eventInfo = _getEventDTO(eid, _player);

    // Validate event status and parameters
    require(
      eventInfo.active && !eventInfo.closed && eventInfo.startDate > block.timestamp && (_team == 1 || _team == 2),
      "Invalid event or team"
    );

    // Mint only the ETH amount to the contract
    if (_amountETH > 0) {
      _mint(address(this), _amountETH); // Ensure _mint is correctly defined to handle ETH minting
    }

    uint256 amount = _amountETH + _amountATON; // Calculate the total stake amount

    AStructs.Event storage currEvent = events[eid];
    AStructs.Stake storage playerStake = currEvent.stakes[_player];

    if (playerStake.amount == 0) {
      currEvent.players.push(_player);
      playerStake.amount = amount;
      playerStake.team = _team;
      players[_player].activeEvents.push(eid);
    } else {
      require(playerStake.team == _team, "Wrong team");
      playerStake.amount += amount;
    }

    currEvent.total[_team - 1] += amount;

    emit EventsLib.PlayerAction(_eventId, _player, _eventId, _player, amount, 0); // 0 represents the actionType for StakeAdded
  }

  /**
   * @dev Closes an event, specifying the winner
   * @param eventId The unique identifier for the event.
   * @param _winner The winning team of the event.
   */
  function closeEvent(string memory eventId, int8 _winner) external onlyAuthorized {
    // Convert event ID to bytes8 format
    bytes8 eid = Tools._stringToBytes8(eventId);

    // Validate event status
    require(events[eid].startDate < block.timestamp && !events[eid].closed && events[eid].active, "Event invalid");

    // Update event details with final results
    events[eid].winner = _winner;
    events[eid].closed = true;

    // Remove the event from active events list
    _removeEvent(eid, activeEvents);

    closedEvents.push(eid);

    if (events[eid].players.length > 1) {
      uint256 commission = ((events[eid].total[0] + events[eid].total[1]) * premium) / pct_denom;
      _accumulateCommission(commission);
    }

    emit EventsLib.EventStateChanged(eventId, eventId, _winner, block.timestamp, 1); // 1 represents the eventType for EventClosed
  }

  /**
   * @dev Processes payouts for a specified event in batches.
   * @param _eventId The unique identifier for the event.
   * @param _batchSize The number of players to process in this batch.
   */
  function payEvent(string memory _eventId, uint8 _batchSize) external onlyAuthorized {
    bytes8 eventIdBytes = Tools._stringToBytes8(_eventId);
    AStructs.Event storage eventDetail = events[eventIdBytes];
    int8 winner = eventDetail.winner;
    uint256 totalStake = eventDetail.total[0] + eventDetail.total[1];
    uint256[2] memory teamStakes = [eventDetail.total[0], eventDetail.total[1]];
    uint8 winnerTeam = winner == 1 ? 0 : winner == 2 ? 1 : 255;

    // Remove the event from the closed events list
    _removeEvent(eventIdBytes, closedEvents);

    // Handle case when there are no players
    if (eventDetail.players.length == 0) {
      eventDetail.paid = true;
    }
    // Handle case when there is only one player
    else if (eventDetail.players.length == 1) {
      address solePlayer = eventDetail.players[0];
      eventDetail.stakeFinalized[solePlayer] = true;
      distributeEarnings(solePlayer, totalStake, true);
      eventDetail.paid = true;
    }
    // Handle case when there are multiple players
    else {
      uint256 playersProcessed = 0;
      while (playersProcessed < _batchSize && eventDetail.playersPaid < eventDetail.players.length) {
        address _player = eventDetail.players[eventDetail.playersPaid];

        if (eventDetail.stakes[_player].amount > 0 && !eventDetail.stakeFinalized[_player]) {
          _finalizeStakeInline(eventIdBytes, _player, winner, winnerTeam, totalStake, teamStakes, eventDetail);
        }
        eventDetail.playersPaid++;
        playersProcessed++;
      }

      // Mark the event as paid if all players have been processed
      if (eventDetail.playersPaid >= eventDetail.players.length) {
        eventDetail.paid = true;
      }
    }

    // Emit an event indicating the finalization of the event
    emit EventsLib.EventStateChanged(_eventId, _eventId, 0, block.timestamp, 2); // 2 represents the eventType for EventFinalized
  }

  /**
   * @dev Finalizes the stake for a player (inlined version).
   * @param eventIdBytes The unique identifier for the event in bytes8 format.
   * @param _player The address of the player.
   * @param winner The winner of the event.
   * @param winnerTeam The team that won the event.
   * @param totalStake The total amount staked in the event.
   * @param teamStakes The amount staked by each team.
   * @param eventDetail The storage reference to the event detail.
   */
  function _finalizeStakeInline(
    bytes8 eventIdBytes,
    address _player,
    int8 winner,
    uint8 winnerTeam,
    uint256 totalStake,
    uint256[2] memory teamStakes,
    AStructs.Event storage eventDetail
  ) private {
    require(winner >= -3 && winner <= 2, "Invalid winner value");
    require(winnerTeam == 0 || winnerTeam == 1 || winnerTeam == 255, "Invalid winner team");

    eventDetail.stakeFinalized[_player] = true;
    _removeEvent(eventIdBytes, players[_player].activeEvents);

    players[_player].closedEvents.push(eventIdBytes);
    uint256 playerStake = eventDetail.stakes[_player].amount;
    uint256 playerShare;

    if (winnerTeam != 255 && winner == int8(eventDetail.stakes[_player].team)) {
      players[_player].level += 3;
      playerShare = (playerStake * totalStake) / teamStakes[winnerTeam];
    } else if (winner == -2 || winner == -3) {
      players[_player].level += 2;
      uint8 playerTeam = eventDetail.stakes[_player].team;
      uint8 otherTeam = playerTeam == 1 ? 1 : 0;
      playerShare = (teamStakes[otherTeam] * playerStake) / teamStakes[playerTeam - 1];
    } else {
      players[_player].level += 1;
      return;
    }

    distributeEarnings(_player, playerShare, false); // Do not waive the commission
  }

  /**
   * @dev Distributes rewards to a player.
   * @param _player The address of the player.
   * @param playerShare The amount to be paid to the player.
   * @param waiveCommission A boolean indicating if the commission should be waived.
   */
  function distributeEarnings(address _player, uint256 playerShare, bool waiveCommission) private {
    if (!waiveCommission) {
      uint256 fee = (playerShare * premium) / pct_denom;
      playerShare -= fee;
    }

    _distributeTransfer(address(this), _player, playerShare);
  }

  /**
   * @dev Removes an event from the specified list of events.
   * @param eventIdBytes The event ID in bytes8 format.
   * @param eventList The list of events (active , closed, player active).
   */
  function _removeEvent(bytes8 eventIdBytes, bytes8[] storage eventList) internal {
    uint256 length = eventList.length;
    uint256 indexToRemove = length;
    for (uint256 i = 0; i < length; i++) {
      if (eventList[i] == eventIdBytes) {
        indexToRemove = i;
        break;
      }
    }

    require(indexToRemove < length, "Event not found");

    eventList[indexToRemove] = eventList[length - 1];
    eventList.pop();
  }

  // ░██████╗░██╗░░░██╗███████╗██████╗░██╗███████╗░██████╗
  // ██╔═══██╗██║░░░██║██╔════╝██╔══██╗██║██╔════╝██╔════╝
  // ██║██╗██║██║░░░██║█████╗░░██████╔╝██║█████╗░░╚█████╗░
  // ╚██████╔╝██║░░░██║██╔══╝░░██╔══██╗██║██╔══╝░░░╚═══██╗
  // ░╚═██╔═╝░╚██████╔╝███████╗██║░░██║██║███████╗██████╔╝
  // ░░░╚═╝░░░░╚═════╝░╚══════╝╚═╝░░╚═╝╚═╝╚══════╝╚═════╝░

  /**
   * @dev Retrieves summaries of multiple players' data and includes global commission data.
   * @param playerAddresses The addresses of the players.
   * @return summaries An array of PlayerSummary structs containing the players' summary data.
   * @return totalCommission The total commission in ATON.
   * @return accumulatedCommission The accumulated commission per token.
   */
  function playerSummary(
    address[] memory playerAddresses
  )
    external
    view
    returns (AStructs.PlayerSummary[] memory summaries, uint256 totalCommission, uint256 accumulatedCommission)
  {
    // Initialize the array to store player summaries
    summaries = new AStructs.PlayerSummary[](playerAddresses.length);

    // Iterate over each player address and retrieve their summary
    for (uint256 i = 0; i < playerAddresses.length; i++) {
      address playerAddress = playerAddresses[i];
      AStructs.Player storage player = players[playerAddress];

      // Store the player's summary in the array
      summaries[i] = AStructs.PlayerSummary({
        level: player.level, // Player's current level
        ethBalance: playerAddress.balance, // Player's ETH balance
        atonBalance: balanceOf(playerAddress), // Player's ATON token balance
        unclaimedCommission: _playerCommission(playerAddress), // Player's unclaimed commission
        totalClaimedCommission: player.claimedCommissionsByPlayer // Player's total claimed commission
      });
    }

    // Assign the global data to the return values
    totalCommission = totalCommissionInATON;
    accumulatedCommission = accumulatedCommissionPerToken;

    // Return the array of player summaries along with the global commission data
    return (summaries, totalCommission, accumulatedCommission);
  }

  /**
   * @dev Retrieves detailed information about an event.
   * @param _eventId The event ID.
   * @param _player The player's address.
   * @return The event details.
   */
  function getEventDTO(string memory _eventId, address _player) external view returns (AStructs.EventDTO memory) {
    bytes8 eventIdBytes = Tools._stringToBytes8(_eventId);
    AStructs.EventDTO memory eventDTO = _getEventDTO(eventIdBytes, _player);
    eventDTO.eventState = _calculateEventState(eventDTO);
    return eventDTO;
  }

  /**
   * @dev Internal function to get detailed information about an event.
   * @param eventIdBytes The event ID in bytes8 format.
   * @param _player The player's address.
   * @return The event details.
   */
  function _getEventDTO(bytes8 eventIdBytes, address _player) internal view returns (AStructs.EventDTO memory) {
    return
      AStructs.EventDTO(
        Tools._bytes8ToString(events[eventIdBytes].eventIdBytes),
        events[eventIdBytes].startDate,
        events[eventIdBytes].sport,
        events[eventIdBytes].total[0],
        events[eventIdBytes].total[1],
        events[eventIdBytes].total[0] + events[eventIdBytes].total[1],
        events[eventIdBytes].winner,
        0,
        events[eventIdBytes].stakes[_player],
        events[eventIdBytes].active,
        events[eventIdBytes].closed,
        events[eventIdBytes].paid
      );
  }

  /**
   * @dev Retrieves events for a specific sport based on the provided filters.
   * @param _sport The sport identifier.
   * @param _step Indicates the status of the events to retrieve (Opened, Closed, Paid).
   * @return A list of event details based on the provided filters.
   */
  function listArenatonEvents(int8 _sport, AStructs.Step _step) external view returns (AStructs.EventDTO[] memory) {
    if (_step == AStructs.Step.Opened) {
      return _listEvents(_sport, true, false);
    } else if (_step == AStructs.Step.Closed) {
      return _listEvents(_sport, true, true);
    } else if (_step == AStructs.Step.Paid) {
      return _listEvents(_sport, false, false);
    }

    return new AStructs.EventDTO[](0);
  }

  /**
   * @dev Internal function to retrieve events based on custom criteria.
   * @param _sport The sport identifier.
   * @param isActive Indicates whether to check active events (true) or closed events (false).
   * @param isClosable Indicates whether to filter by closable status.
   * @return A list of event details based on the criteria.
   */

  function _listEvents(int8 _sport, bool isActive, bool isClosable) internal view returns (AStructs.EventDTO[] memory) {
    bytes8[] storage eventList = isActive ? activeEvents : closedEvents;
    AStructs.EventDTO[] memory tempEventsDTO = new AStructs.EventDTO[](eventList.length);
    uint256 count = 0;

    for (uint256 i = 0; i < eventList.length; i++) {
      AStructs.EventDTO memory currentEvent = _getEventDTO(eventList[i], address(0));
      currentEvent.eventState = _calculateEventState(currentEvent);

      bool sportMatch = currentEvent.sport == uint8(_sport) || _sport < 0;
      bool closableMatch = isClosable
        ? (isActive ? currentEvent.startDate < block.timestamp : currentEvent.closed && !currentEvent.paid)
        : true;

      if (sportMatch && closableMatch) {
        tempEventsDTO[count] = currentEvent;
        count++;
      }
    }

    AStructs.EventDTO[] memory finalEventsDTO = new AStructs.EventDTO[](count);
    for (uint256 i = 0; i < count; i++) {
      finalEventsDTO[i] = tempEventsDTO[i];
    }

    return finalEventsDTO;
  }

  /**
   * @dev Calculates the current state of an event.
   * @param _eventDTO The event details.
   * @return eventState The current state of the event.
   */
  function _calculateEventState(AStructs.EventDTO memory _eventDTO) internal view returns (uint8) {
    if (_eventDTO.paid) {
      return uint8(AStructs.EventState.Finalized);
    } else if (_eventDTO.closed) {
      return uint8(AStructs.EventState.Ended);
    } else if (_eventDTO.active) {
      return uint8(AStructs.EventState.Live);
    } else if (_eventDTO.startDate == 0) {
      return uint8(AStructs.EventState.NotInitialized);
    } else if (_eventDTO.startDate > block.timestamp) {
      return uint8(AStructs.EventState.Open);
    } else {
      return uint8(AStructs.EventState.NotInitialized); // Default state if none of the conditions are met
    }
  }

  // ░█████╗░░█████╗░███╗░░░███╗███╗░░░███╗██╗░██████╗░██████╗██╗░█████╗░███╗░░██╗
  // ██╔══██╗██╔══██╗████╗░████║████╗░████║██║██╔════╝██╔════╝██║██╔══██╗████╗░██║
  // ██║░░╚═╝██║░░██║██╔████╔██║██╔████╔██║██║╚█████╗░╚█████╗░██║██║░░██║██╔██╗██║
  // ██║░░██╗██║░░██║██║╚██╔╝██║██║╚██╔╝██║██║░╚═══██╗░╚═══██╗██║██║░░██║██║╚████║
  // ╚█████╔╝╚█████╔╝██║░╚═╝░██║██║░╚═╝░██║██║██████╔╝██████╔╝██║╚█████╔╝██║░╚███║
  // ░╚════╝░░╚════╝░╚═╝░░░░░╚═╝╚═╝░░░░░╚═╝╚═╝╚═════╝░╚═════╝░╚═╝░╚════╝░╚═╝░░╚══╝

  // ░██████╗██╗░░██╗░█████╗░██████╗░██╗███╗░░██╗░██████╗░
  // ██╔════╝██║░░██║██╔══██╗██╔══██╗██║████╗░██║██╔════╝░
  // ╚█████╗░███████║███████║██████╔╝██║██╔██╗██║██║░░██╗░
  // ░╚═══██╗██╔══██║██╔══██║██╔══██╗██║██║╚████║██║░░╚██╗
  // ██████╔╝██║░░██║██║░░██║██║░░██║██║██║░╚███║╚██████╔╝
  // ╚═════╝░╚═╝░░╚═╝╚═╝░░╚═╝╚═╝░░╚═╝╚═╝╚═╝░░╚══╝░╚═════╝░

  /**
   * @dev This function accumulates commission generated from swaps. Commissions are stored as ATON tokens.
   * @param newCommissionATON The commission amount in ATON tokens.
   */
  function _accumulateCommission(uint256 newCommissionATON) internal {
    // Calculate commission per token and update total commission.
    accumulatedCommissionPerToken += (newCommissionATON * (10 ** decimals())) / totalSupply();

    totalCommissionInATON += newCommissionATON;
    emit EventsLib.Accumulate(newCommissionATON, accumulatedCommissionPerToken, totalCommissionInATON);
  }

  /**
   * @dev Distributes accumulated commission to a specified player based on their ATON token holdings. The distribution ensures players get their share of profits from commission.
   * @param player Address of the player receiving the commission.
   */
  function _distributeCommission(address player) internal {
    uint256 unclaimedCommission = _playerCommission(player);

    if (unclaimedCommission > 0) {
      address recipient = (player == address(this)) ? owner : player;
      super._transfer(address(this), recipient, unclaimedCommission);
      players[recipient].claimedCommissionsByPlayer += unclaimedCommission;
      emit EventsLib.PlayerAction(
        "",
        recipient,
        "",
        recipient,
        unclaimedCommission,
        uint8((player == address(this)) ? AStructs.EarningCategory.VaultFee : AStructs.EarningCategory.Commission)
      );
    }

    players[player].lastCommissionPerTokenForPlayer = accumulatedCommissionPerToken;
  }

  /**
   * @dev Computes the unclaimed commission for a specified player based on their ATON token holdings.
   * @param player Address of the player.
   * @return unclaimedCommission The amount of ATON tokens the player can claim as commission.
   */
  function _playerCommission(address player) internal view returns (uint256) {
    // Calculate the amount of commission owed per token since the last update for the player
    uint256 owedPerToken = accumulatedCommissionPerToken - players[player].lastCommissionPerTokenForPlayer;

    // Return the unclaimed commission for the player, if any
    return owedPerToken > 0 ? (balanceOf(player) * owedPerToken) / (10 ** decimals()) : 0;
  }

  /**
   * @dev Allows a player to donate ATON tokens to the contract. The donated amount is added to the total commission.
   * @param _amount The amount of ATON tokens to donate.
   */
  function donateATON(uint256 _amount) external nonReentrant {
    _distributeTransfer(msg.sender, address(this), _amount);
    // Accumulate the donated amount into the total commission
    _accumulateCommission(_amount);
  }

  /**
   * @dev Transfers ATON tokens from the sender to the specified recipient.
   * Before the transfer, it distributes any unclaimed commissions to both the sender and the recipient.
   * @param to The address of the recipient.
   * @param value The amount of ATON tokens to transfer.
   * @return A boolean value indicating whether the operation succeeded.
   */
  function transfer(address to, uint256 value) public virtual override returns (bool) {
    _distributeTransfer(msg.sender, to, value);
    return true;
  }

  /**
   * @dev Internal function that handles the transfer and distribution of commissions.
   * @param from The address of the sender.
   * @param to The address of the recipient.
   * @param amount The amount of ATON tokens to transfer.
   */
  function _distributeTransfer(address from, address to, uint256 amount) internal {
    // Distribute any unclaimed commission to the sender before making the transfer
    _distributeCommission(from);

    // Distribute any unclaimed commission to the recipient before receiving the transfer
    _distributeCommission(to);

    // Transfer the specified amount of ATON tokens from the sender to the recipient
    _transfer(from, to, amount);
  }

  // ░██████╗░██╗░░░░░░░██╗░█████╗░██████╗░
  // ██╔════╝░██║░░██╗░░██║██╔══██╗██╔══██╗
  // ╚█████╗░░╚██╗████╗██╔╝███████║██████╔╝
  // ░╚═══██╗░░████╔═████║░██╔══██║██╔═══╝░
  // ██████╔╝░░╚██╔╝░╚██╔╝░██║░░██║██║░░░░░
  // ╚═════╝░░░░╚═╝░░░╚═╝░░╚═╝░░╚═╝╚═╝░░░░░

  /**
   * @dev Swaps ATON tokens for ETH at a 1:1 ratio.
   * @param _amountAton The amount of ATON tokens to swap.
   * @return success True if the swap was successful.
   */
  function swap(uint256 _amountAton) external nonReentrant returns (bool success) {
    require(
      _amountAton > 0 && balanceOf(msg.sender) >= _amountAton && address(this).balance >= _amountAton,
      "Invalid swap conditions"
    );

    _distributeTransfer(msg.sender, address(this), _amountAton);

    (bool sent, ) = msg.sender.call{ value: _amountAton }("");
    require(sent, "Failed to send ETH");

    emit EventsLib.Swap(msg.sender, msg.sender, _amountAton);

    return true;
  }
}

// All rights reserved. This software and associated documentation files (the "Software"),
// cannot be used, copied, modified, merged, published, distributed, sublicensed, and/or
// sold without the express and written permission of the owner.

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v5.0.0) (utils/ReentrancyGuard.sol)

pragma solidity ^0.8.20;

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
    uint256 private constant NOT_ENTERED = 1;
    uint256 private constant ENTERED = 2;

    uint256 private _status;

    /**
     * @dev Unauthorized reentrant call.
     */
    error ReentrancyGuardReentrantCall();

    constructor() {
        _status = NOT_ENTERED;
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
        // On the first call to nonReentrant, _status will be NOT_ENTERED
        if (_status == ENTERED) {
            revert ReentrancyGuardReentrantCall();
        }

        // Any calls to nonReentrant after this point will fail
        _status = ENTERED;
    }

    function _nonReentrantAfter() private {
        // By storing the original value once again, a refund is triggered (see
        // https://eips.ethereum.org/EIPS/eip-2200)
        _status = NOT_ENTERED;
    }

    /**
     * @dev Returns true if the reentrancy guard is currently set to "entered", which indicates there is a
     * `nonReentrant` function in the call stack.
     */
    function _reentrancyGuardEntered() internal view returns (bool) {
        return _status == ENTERED;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v5.0.0) (token/ERC20/ERC20.sol)

pragma solidity ^0.8.20;

import {IERC20} from "./IERC20.sol";
import {IERC20Metadata} from "./extensions/IERC20Metadata.sol";
import {Context} from "../../utils/Context.sol";
import {IERC20Errors} from "../../interfaces/draft-IERC6093.sol";

/**
 * @dev Implementation of the {IERC20} interface.
 *
 * This implementation is agnostic to the way tokens are created. This means
 * that a supply mechanism has to be added in a derived contract using {_mint}.
 *
 * TIP: For a detailed writeup see our guide
 * https://forum.openzeppelin.com/t/how-to-implement-erc20-supply-mechanisms/226[How
 * to implement supply mechanisms].
 *
 * The default value of {decimals} is 18. To change this, you should override
 * this function so it returns a different value.
 *
 * We have followed general OpenZeppelin Contracts guidelines: functions revert
 * instead returning `false` on failure. This behavior is nonetheless
 * conventional and does not conflict with the expectations of ERC20
 * applications.
 *
 * Additionally, an {Approval} event is emitted on calls to {transferFrom}.
 * This allows applications to reconstruct the allowance for all accounts just
 * by listening to said events. Other implementations of the EIP may not emit
 * these events, as it isn't required by the specification.
 */
abstract contract ERC20 is Context, IERC20, IERC20Metadata, IERC20Errors {
    mapping(address account => uint256) private _balances;

    mapping(address account => mapping(address spender => uint256)) private _allowances;

    uint256 private _totalSupply;

    string private _name;
    string private _symbol;

    /**
     * @dev Sets the values for {name} and {symbol}.
     *
     * All two of these values are immutable: they can only be set once during
     * construction.
     */
    constructor(string memory name_, string memory symbol_) {
        _name = name_;
        _symbol = symbol_;
    }

    /**
     * @dev Returns the name of the token.
     */
    function name() public view virtual returns (string memory) {
        return _name;
    }

    /**
     * @dev Returns the symbol of the token, usually a shorter version of the
     * name.
     */
    function symbol() public view virtual returns (string memory) {
        return _symbol;
    }

    /**
     * @dev Returns the number of decimals used to get its user representation.
     * For example, if `decimals` equals `2`, a balance of `505` tokens should
     * be displayed to a user as `5.05` (`505 / 10 ** 2`).
     *
     * Tokens usually opt for a value of 18, imitating the relationship between
     * Ether and Wei. This is the default value returned by this function, unless
     * it's overridden.
     *
     * NOTE: This information is only used for _display_ purposes: it in
     * no way affects any of the arithmetic of the contract, including
     * {IERC20-balanceOf} and {IERC20-transfer}.
     */
    function decimals() public view virtual returns (uint8) {
        return 18;
    }

    /**
     * @dev See {IERC20-totalSupply}.
     */
    function totalSupply() public view virtual returns (uint256) {
        return _totalSupply;
    }

    /**
     * @dev See {IERC20-balanceOf}.
     */
    function balanceOf(address account) public view virtual returns (uint256) {
        return _balances[account];
    }

    /**
     * @dev See {IERC20-transfer}.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     * - the caller must have a balance of at least `value`.
     */
    function transfer(address to, uint256 value) public virtual returns (bool) {
        address owner = _msgSender();
        _transfer(owner, to, value);
        return true;
    }

    /**
     * @dev See {IERC20-allowance}.
     */
    function allowance(address owner, address spender) public view virtual returns (uint256) {
        return _allowances[owner][spender];
    }

    /**
     * @dev See {IERC20-approve}.
     *
     * NOTE: If `value` is the maximum `uint256`, the allowance is not updated on
     * `transferFrom`. This is semantically equivalent to an infinite approval.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function approve(address spender, uint256 value) public virtual returns (bool) {
        address owner = _msgSender();
        _approve(owner, spender, value);
        return true;
    }

    /**
     * @dev See {IERC20-transferFrom}.
     *
     * Emits an {Approval} event indicating the updated allowance. This is not
     * required by the EIP. See the note at the beginning of {ERC20}.
     *
     * NOTE: Does not update the allowance if the current allowance
     * is the maximum `uint256`.
     *
     * Requirements:
     *
     * - `from` and `to` cannot be the zero address.
     * - `from` must have a balance of at least `value`.
     * - the caller must have allowance for ``from``'s tokens of at least
     * `value`.
     */
    function transferFrom(address from, address to, uint256 value) public virtual returns (bool) {
        address spender = _msgSender();
        _spendAllowance(from, spender, value);
        _transfer(from, to, value);
        return true;
    }

    /**
     * @dev Moves a `value` amount of tokens from `from` to `to`.
     *
     * This internal function is equivalent to {transfer}, and can be used to
     * e.g. implement automatic token fees, slashing mechanisms, etc.
     *
     * Emits a {Transfer} event.
     *
     * NOTE: This function is not virtual, {_update} should be overridden instead.
     */
    function _transfer(address from, address to, uint256 value) internal {
        if (from == address(0)) {
            revert ERC20InvalidSender(address(0));
        }
        if (to == address(0)) {
            revert ERC20InvalidReceiver(address(0));
        }
        _update(from, to, value);
    }

    /**
     * @dev Transfers a `value` amount of tokens from `from` to `to`, or alternatively mints (or burns) if `from`
     * (or `to`) is the zero address. All customizations to transfers, mints, and burns should be done by overriding
     * this function.
     *
     * Emits a {Transfer} event.
     */
    function _update(address from, address to, uint256 value) internal virtual {
        if (from == address(0)) {
            // Overflow check required: The rest of the code assumes that totalSupply never overflows
            _totalSupply += value;
        } else {
            uint256 fromBalance = _balances[from];
            if (fromBalance < value) {
                revert ERC20InsufficientBalance(from, fromBalance, value);
            }
            unchecked {
                // Overflow not possible: value <= fromBalance <= totalSupply.
                _balances[from] = fromBalance - value;
            }
        }

        if (to == address(0)) {
            unchecked {
                // Overflow not possible: value <= totalSupply or value <= fromBalance <= totalSupply.
                _totalSupply -= value;
            }
        } else {
            unchecked {
                // Overflow not possible: balance + value is at most totalSupply, which we know fits into a uint256.
                _balances[to] += value;
            }
        }

        emit Transfer(from, to, value);
    }

    /**
     * @dev Creates a `value` amount of tokens and assigns them to `account`, by transferring it from address(0).
     * Relies on the `_update` mechanism
     *
     * Emits a {Transfer} event with `from` set to the zero address.
     *
     * NOTE: This function is not virtual, {_update} should be overridden instead.
     */
    function _mint(address account, uint256 value) internal {
        if (account == address(0)) {
            revert ERC20InvalidReceiver(address(0));
        }
        _update(address(0), account, value);
    }

    /**
     * @dev Destroys a `value` amount of tokens from `account`, lowering the total supply.
     * Relies on the `_update` mechanism.
     *
     * Emits a {Transfer} event with `to` set to the zero address.
     *
     * NOTE: This function is not virtual, {_update} should be overridden instead
     */
    function _burn(address account, uint256 value) internal {
        if (account == address(0)) {
            revert ERC20InvalidSender(address(0));
        }
        _update(account, address(0), value);
    }

    /**
     * @dev Sets `value` as the allowance of `spender` over the `owner` s tokens.
     *
     * This internal function is equivalent to `approve`, and can be used to
     * e.g. set automatic allowances for certain subsystems, etc.
     *
     * Emits an {Approval} event.
     *
     * Requirements:
     *
     * - `owner` cannot be the zero address.
     * - `spender` cannot be the zero address.
     *
     * Overrides to this logic should be done to the variant with an additional `bool emitEvent` argument.
     */
    function _approve(address owner, address spender, uint256 value) internal {
        _approve(owner, spender, value, true);
    }

    /**
     * @dev Variant of {_approve} with an optional flag to enable or disable the {Approval} event.
     *
     * By default (when calling {_approve}) the flag is set to true. On the other hand, approval changes made by
     * `_spendAllowance` during the `transferFrom` operation set the flag to false. This saves gas by not emitting any
     * `Approval` event during `transferFrom` operations.
     *
     * Anyone who wishes to continue emitting `Approval` events on the`transferFrom` operation can force the flag to
     * true using the following override:
     * ```
     * function _approve(address owner, address spender, uint256 value, bool) internal virtual override {
     *     super._approve(owner, spender, value, true);
     * }
     * ```
     *
     * Requirements are the same as {_approve}.
     */
    function _approve(address owner, address spender, uint256 value, bool emitEvent) internal virtual {
        if (owner == address(0)) {
            revert ERC20InvalidApprover(address(0));
        }
        if (spender == address(0)) {
            revert ERC20InvalidSpender(address(0));
        }
        _allowances[owner][spender] = value;
        if (emitEvent) {
            emit Approval(owner, spender, value);
        }
    }

    /**
     * @dev Updates `owner` s allowance for `spender` based on spent `value`.
     *
     * Does not update the allowance value in case of infinite allowance.
     * Revert if not enough allowance is available.
     *
     * Does not emit an {Approval} event.
     */
    function _spendAllowance(address owner, address spender, uint256 value) internal virtual {
        uint256 currentAllowance = allowance(owner, spender);
        if (currentAllowance != type(uint256).max) {
            if (currentAllowance < value) {
                revert ERC20InsufficientAllowance(spender, currentAllowance, value);
            }
            unchecked {
                _approve(owner, spender, currentAllowance - value, false);
            }
        }
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

library AStructs {

  // EarningCategory defines various types of earnings within the platform.
  // This enum enhances code readability by replacing numeric codes with descriptive names, making the contract logic clearer and easier to understand.
  enum EarningCategory {
    Win,        // Earnings from a won stake.
    Commission, // Commission earnings from the platform.
    VaultFee,   // Fees collected from the vault.
    Donation    // Donations received.
  }

  // EventState defines the various states an event can be in throughout its lifecycle.
  // This enum facilitates state management by providing descriptive status labels instead of using plain numbers.
  enum EventState {
    NotInitialized, // Event has not been initialized yet.
    Open,           // Staking is currently allowed for the event.
    Live,           // Event is currently live.
    Ended,          // Event has ended.
    Finalized       // Event is closed and finalized.
  }

  // Step defines the different steps an event can go through.
  // This enum provides clarity on the progression of an event from opening to final payment.
  enum Step {
    Opened, // Staking is currently allowed for the event.
    Closed, // Event has ended.
    Paid    // Event has been paid out.
  }

  // Structure representing a player's stake in an event.
  struct Stake {
    uint256 amount; // Amount of tokens staked by the player.
    uint8 team;     // The team the player is betting on: 1 = Team A, 2 = Team B.
  }

  // Structure representing an event for betting.
  struct Event {
    bytes8 eventIdBytes;             // Unique identifier for the event.
    uint256 startDate;               // Start date of the event.
    address[] players;               // List of players who have staked in the event.
    mapping(address => Stake) stakes;          // Mapping of player addresses to their stakes.
    mapping(address => bool) stakeFinalized;   // Mapping to check if a player's stake has been finalized and cashed out.
    uint256[2] total;                // Total stakes: index 0 for Team A, index 1 for Team B.
    int8 winner;                     // Winner of the event: 1 = Team A, 2 = Team B, -2 = Tie, -1 = No result yet, -3 = Event Canceled.
    uint8 sport;                     // ID representing the sport.
    uint256 playersPaid;             // Number of players who have been paid out.
    bool active;                      // Is the event opened?
    bool closed;                      // Is the event closed?
    bool paid;                     // Has the event payout been processed?
  }

  // Data transfer object for an event.
  struct EventDTO {
    string eventId;                 // Unique identifier for the event as a string.
    uint256 startDate;              // Start date of the event.
    uint8 sport;                    // ID representing the sport.
    uint256 total_A;                // Total stakes for Team A.
    uint256 total_B;                // Total stakes for Team B.
    uint256 total;                  // Total stakes for both teams.
    int8 winner;                    // Winner of the event: 1 = Team A, 2 = Team B, -2 = Tie, -1 = No result yet, -3 = Event Canceled.
    uint8 eventState;               // Current state of the event.
    Stake playerStake;              // Player's stake in the event.
    bool active;                      // Is the event opened?
    bool closed;                     // Is the event closed?
    bool paid;                    // Has all the players has been paid?
  }

  // Structure representing a player's data.
  struct Player {
    bytes8[] activeEvents;                      // Array of active event IDs in which the player is currently participating.
    bytes8[] closedEvents;                      // Array of event IDs for events in which the player has participated and that are now closed.
    uint32 level;                               // The player's current level, representing their experience or skill.
    uint256 claimedCommissionsByPlayer;         // Total commissions claimed by the player.
    uint256 lastCommissionPerTokenForPlayer;    // Last recorded commission per token for the player.
  }

  // Structure to hold a summary of the player's data for external view.
  struct PlayerSummary {
    uint32 level;                         // The player's current level.
    uint256 ethBalance;                   // Player's ETH balance.
    uint256 atonBalance;                  // Player's ATON balance.
    uint256 unclaimedCommission;          // Unclaimed commission for the player.
    uint256 totalClaimedCommission;       // Total commission claimed by the player.
  }

  // Function to populate an event structure with initial values.
  function populateEvent(Event storage e, bytes8 eventIdBytes, uint256 _startDate, uint8 _sport) internal {
    e.eventIdBytes = eventIdBytes;
    e.startDate = _startDate;
    e.active = true;
    e.closed = false;
    e.paid = false;
    e.winner = -1;
    e.sport = _sport;
  }
}
// All rights reserved. This software and associated documentation files (the "Software"),
// cannot be used, copied, modified, merged, published, distributed, sublicensed, and/or
// sold without the express and written permission of the owner.

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.26;
import './AStructs.sol';

library Tools {
    /**
     * @dev Converts a string to a bytes8 value.
     * @param source The input string to be converted.
     * @return result The bytes8 representation of the input string.
     * Internal function, not meant to be called directly.
     */
    function _stringToBytes8(string memory source) internal pure returns (bytes8 result) {
        bytes memory tempEmptyStringTest = bytes(source);
        if (tempEmptyStringTest.length == 0) {
            return 0x0;
        }

        assembly {
            result := mload(add(source, 32))
        }
    }

    /**
     * @dev Converts a bytes8 value to a string.
     * @param x The input bytes8 value to be converted.
     * @return string The string representation of the input bytes8 value.
     * Internal function, not meant to be called directly.
     */
    function _bytes8ToString(bytes8 x) internal pure returns (string memory) {
        bytes memory bytesString = new bytes(8);
        for (uint256 i = 0; i < 8; i++) {
            bytesString[i] = x[i];
        }
        return string(bytesString);
    }


}
// All rights reserved. This software and associated documentation files (the "Software"),
// cannot be used, copied, modified, merged, published, distributed, sublicensed, and/or
// sold without the express and written permission of the owner.

// SPDX-License-Identifier: MIT


pragma solidity ^0.8.26;

library EventsLib {
    /**
     * @title Staking and Event Management Events
     * @notice This section declares events related to staking and managing sports events.
     * These events provide external systems, like user interfaces, with a mechanism to track
     * and display on-chain actions performed by users in real-time.
     */

    /**
     * @dev This event is triggered for various player actions and earnings.
     *
     * @param eventIdIndexed - Indexed version of the event's unique identifier.
     * Useful for quick filtering in event queries.
     *
     * @param playerIndexed - Indexed version of the player's address involved in the action.
     * Allows for efficient filtering based on the player's address.
     *
     * @param eventId - The unique identifier of the event.
     *
     * @param player - The address of the player involved in the action.
     *
     * @param amount - The amount of ATON tokens involved in the action.
     *
     * @param actionType - A numeric identifier for the type of action.
     * E.g., 0 for Stake Added, 1 for Earnings.
     */
    event PlayerAction(
        string indexed eventIdIndexed,
        address indexed playerIndexed,
        string eventId,
        address player,
        uint256 amount,
        uint8 actionType
    );

    /**
     * @dev This event is triggered for various state changes of events.
     *
     * @param eventIdIndexed - Indexed version of the event's unique identifier.
     * Useful for quick filtering in event queries.
     *
     * @param eventId - The unique identifier of the event.
     *
     * @param sportOrWinner - The sport type for opened events, or the winner for closed events.
     * Use a default value or zero for finalized events where this parameter is not applicable.
     *
     * @param timestamp - The timestamp related to the event state change.
     * E.g., start time for opened events.
     *
     * @param eventType - A numeric identifier for the type of event state change.
     * E.g., 0 for Opened, 1 for Closed, 2 for Finalized.
     */
    event EventStateChanged(
        string indexed eventIdIndexed,
        string eventId,
        int8 sportOrWinner,
        uint256 timestamp,
        uint8 eventType
    );

    /**
     * @dev Emitted when a player swaps one token type for another.
     *
     * @param playerIndexed - Indexed address of the player performing the swap.
     *
     * @param player - The address of the player performing the swap.
     *
     * @param amount - The amount of `tokenOut` tokens the player received.
     */
    event Swap(address indexed playerIndexed, address player, uint256 amount);

    /**
     * @dev Emitted when the accumulated commission in ATON is updated.
     *
     * @param newCommissionATON - The new amount added to the commission.
     *
     * @param accumulatedCommissionPerToken - The cumulative commission per token up to the current point.
     *
     * @param totalCommissionInATON - The total commission in ATON after the new addition.
     */
    event Accumulate(uint256 newCommissionATON, uint256 accumulatedCommissionPerToken, uint256 totalCommissionInATON);
}

/**
 * Copyright Notice
 *
 * All rights reserved. This software and associated documentation files (the "Software"),
 * cannot be used, copied, modified, merged, published, distributed, sublicensed, and/or
 * sold without the express and written permission of the owner.
 */

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v5.0.0) (token/ERC20/IERC20.sol)

pragma solidity ^0.8.20;

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
// OpenZeppelin Contracts (last updated v5.0.0) (token/ERC20/extensions/IERC20Metadata.sol)

pragma solidity ^0.8.20;

import {IERC20} from "../IERC20.sol";

/**
 * @dev Interface for the optional metadata functions from the ERC20 standard.
 */
interface IERC20Metadata is IERC20 {
    /**
     * @dev Returns the name of the token.
     */
    function name() external view returns (string memory);

    /**
     * @dev Returns the symbol of the token.
     */
    function symbol() external view returns (string memory);

    /**
     * @dev Returns the decimals places of the token.
     */
    function decimals() external view returns (uint8);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v5.0.1) (utils/Context.sol)

pragma solidity ^0.8.20;

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

    function _contextSuffixLength() internal view virtual returns (uint256) {
        return 0;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v5.0.0) (interfaces/draft-IERC6093.sol)
pragma solidity ^0.8.20;

/**
 * @dev Standard ERC20 Errors
 * Interface of the https://eips.ethereum.org/EIPS/eip-6093[ERC-6093] custom errors for ERC20 tokens.
 */
interface IERC20Errors {
    /**
     * @dev Indicates an error related to the current `balance` of a `sender`. Used in transfers.
     * @param sender Address whose tokens are being transferred.
     * @param balance Current balance for the interacting account.
     * @param needed Minimum amount required to perform a transfer.
     */
    error ERC20InsufficientBalance(address sender, uint256 balance, uint256 needed);

    /**
     * @dev Indicates a failure with the token `sender`. Used in transfers.
     * @param sender Address whose tokens are being transferred.
     */
    error ERC20InvalidSender(address sender);

    /**
     * @dev Indicates a failure with the token `receiver`. Used in transfers.
     * @param receiver Address to which tokens are being transferred.
     */
    error ERC20InvalidReceiver(address receiver);

    /**
     * @dev Indicates a failure with the `spender`’s `allowance`. Used in transfers.
     * @param spender Address that may be allowed to operate on tokens without being their owner.
     * @param allowance Amount of tokens a `spender` is allowed to operate with.
     * @param needed Minimum amount required to perform a transfer.
     */
    error ERC20InsufficientAllowance(address spender, uint256 allowance, uint256 needed);

    /**
     * @dev Indicates a failure with the `approver` of a token to be approved. Used in approvals.
     * @param approver Address initiating an approval operation.
     */
    error ERC20InvalidApprover(address approver);

    /**
     * @dev Indicates a failure with the `spender` to be approved. Used in approvals.
     * @param spender Address that may be allowed to operate on tokens without being their owner.
     */
    error ERC20InvalidSpender(address spender);
}

/**
 * @dev Standard ERC721 Errors
 * Interface of the https://eips.ethereum.org/EIPS/eip-6093[ERC-6093] custom errors for ERC721 tokens.
 */
interface IERC721Errors {
    /**
     * @dev Indicates that an address can't be an owner. For example, `address(0)` is a forbidden owner in EIP-20.
     * Used in balance queries.
     * @param owner Address of the current owner of a token.
     */
    error ERC721InvalidOwner(address owner);

    /**
     * @dev Indicates a `tokenId` whose `owner` is the zero address.
     * @param tokenId Identifier number of a token.
     */
    error ERC721NonexistentToken(uint256 tokenId);

    /**
     * @dev Indicates an error related to the ownership over a particular token. Used in transfers.
     * @param sender Address whose tokens are being transferred.
     * @param tokenId Identifier number of a token.
     * @param owner Address of the current owner of a token.
     */
    error ERC721IncorrectOwner(address sender, uint256 tokenId, address owner);

    /**
     * @dev Indicates a failure with the token `sender`. Used in transfers.
     * @param sender Address whose tokens are being transferred.
     */
    error ERC721InvalidSender(address sender);

    /**
     * @dev Indicates a failure with the token `receiver`. Used in transfers.
     * @param receiver Address to which tokens are being transferred.
     */
    error ERC721InvalidReceiver(address receiver);

    /**
     * @dev Indicates a failure with the `operator`’s approval. Used in transfers.
     * @param operator Address that may be allowed to operate on tokens without being their owner.
     * @param tokenId Identifier number of a token.
     */
    error ERC721InsufficientApproval(address operator, uint256 tokenId);

    /**
     * @dev Indicates a failure with the `approver` of a token to be approved. Used in approvals.
     * @param approver Address initiating an approval operation.
     */
    error ERC721InvalidApprover(address approver);

    /**
     * @dev Indicates a failure with the `operator` to be approved. Used in approvals.
     * @param operator Address that may be allowed to operate on tokens without being their owner.
     */
    error ERC721InvalidOperator(address operator);
}

/**
 * @dev Standard ERC1155 Errors
 * Interface of the https://eips.ethereum.org/EIPS/eip-6093[ERC-6093] custom errors for ERC1155 tokens.
 */
interface IERC1155Errors {
    /**
     * @dev Indicates an error related to the current `balance` of a `sender`. Used in transfers.
     * @param sender Address whose tokens are being transferred.
     * @param balance Current balance for the interacting account.
     * @param needed Minimum amount required to perform a transfer.
     * @param tokenId Identifier number of a token.
     */
    error ERC1155InsufficientBalance(address sender, uint256 balance, uint256 needed, uint256 tokenId);

    /**
     * @dev Indicates a failure with the token `sender`. Used in transfers.
     * @param sender Address whose tokens are being transferred.
     */
    error ERC1155InvalidSender(address sender);

    /**
     * @dev Indicates a failure with the token `receiver`. Used in transfers.
     * @param receiver Address to which tokens are being transferred.
     */
    error ERC1155InvalidReceiver(address receiver);

    /**
     * @dev Indicates a failure with the `operator`’s approval. Used in transfers.
     * @param operator Address that may be allowed to operate on tokens without being their owner.
     * @param owner Address of the current owner of a token.
     */
    error ERC1155MissingApprovalForAll(address operator, address owner);

    /**
     * @dev Indicates a failure with the `approver` of a token to be approved. Used in approvals.
     * @param approver Address initiating an approval operation.
     */
    error ERC1155InvalidApprover(address approver);

    /**
     * @dev Indicates a failure with the `operator` to be approved. Used in approvals.
     * @param operator Address that may be allowed to operate on tokens without being their owner.
     */
    error ERC1155InvalidOperator(address operator);

    /**
     * @dev Indicates an array length mismatch between ids and values in a safeBatchTransferFrom operation.
     * Used in batch transfers.
     * @param idsLength Length of the array of token identifiers
     * @param valuesLength Length of the array of token amounts
     */
    error ERC1155InvalidArrayLength(uint256 idsLength, uint256 valuesLength);
}