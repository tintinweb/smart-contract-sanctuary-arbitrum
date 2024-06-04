// SPDX-License-Identifier: MIT
pragma solidity 0.8.21;

/* Openzeppelin Contracts */
import {AccessControl} from "@openzeppelin/contracts/access/AccessControl.sol";

/* DG Libraries */
import {DGErrors} from "src/libraries/DGErrors.sol";
import {DGDataTypes} from "src/libraries/DGDataTypes.sol";
import {DGEvents} from "src/libraries/DGEvents.sol";

/**
 * @title DGPVP_B
 * @author DG Technical Team
 * @notice Player VS Player game. This version allows for multiple entries per wallet per round
 *
 */
contract DGPVP_B is AccessControl{
    //     _____ __        __
    //    / ___// /_____ _/ /____  _____
    //    \__ \/ __/ __ `/ __/ _ \/ ___/
    //   ___/ / /_/ /_/ / /_/  __(__  )
    //  /____/\__/\__,_/\__/\___/____/

    /// @dev instanciate wager params
    DGDataTypes.WagerParams wager;

    /// @dev status of game 
    /// |---WAITING
    /// |---STARTED
    /// |---ENDED
    DGDataTypes.GameIs public gameIs;

    /// @dev The platforms address
    address platform;

    /// @dev array to hold all current player addresses
    address[] players;

    /// @dev array to hold all current playerseeds
    bytes20[] playerSeeds;

    /// @dev variable that holds
    uint8 public roundLength;

    /// @dev used to calculate percentages
    uint256 public constant DENOMINATOR = 10_000;

    /// @dev check the total amount wagered throughout the lifetime of this contract
    uint256 public totalWagered;

    /// @dev store current round entries
    uint256 public currentRoundEntries;

    /// @dev check amount wagered in the current round
    uint256 public currentRoundWagered;

    /// @dev unix timestamp for when current round ends
    uint256 public currentRoundCloses;

    /// @dev id for round, increments when new games are played
    uint256 public roundId;

    /// @dev Hashed version of the server seed that will be used to draw a random number
    bytes32 public hashedServerSeed;

    /// @dev public variable for holding players params
    mapping(address player => DGDataTypes.PlayParamsB params) public playParamsOf;

    /// @dev private variable to make sure that an operator is approved
    mapping (address operator => bool isApproved) approved;

    //     ______                 __                  __
    //    / ____/___  ____  _____/ /________  _______/ /_____  _____
    //   / /   / __ \/ __ \/ ___/ __/ ___/ / / / ___/ __/ __ \/ ___/
    //  / /___/ /_/ / / / (__  ) /_/ /  / /_/ / /__/ /_/ /_/ / /
    //  \____/\____/_/ /_/____/\__/_/   \__,_/\___/\__/\____/_/
    /**
     * @notice 
     *  Contract constructor
     *  Sets the default values for contract variables
     *
     * @param _platform address used for paying out the platforms cut
     * @param _admin address that will recieve ADMIN role once constructor is done
     *
     */
    constructor(address _platform, address _admin) {
        // Set max wager
        wager.max = 1 ether;

        // Set min wager. The wager will have to be diviable with this number
        wager.min = 0.001 ether;

        // Set operator fee in percentages (10_000 being 100%, so 70 = 0.7 %)
        wager.operatorFee = 70;

        // Set platform fee in percentages (10_000 being 100%, so 30 = 0.3 %)
        wager.platformFee = 30;

        // Set length of each round
        roundLength = 2 minutes;

        // Set the platform address
        platform = _platform;

        // Set initial first hashed version of server seed, using msg.sender for startvalue
        hashedServerSeed = keccak256(abi.encodePacked(msg.sender));

        // Give deployer temporary admin capabilities to finish the constructor
        _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);

        // Grant default admin the DEFAULT_ADMIN_ROLE
        _grantRole(DEFAULT_ADMIN_ROLE, _admin);

        // Make sure now remove the default admin role from the msg.sender
        _revokeRole(DEFAULT_ADMIN_ROLE, msg.sender);

        // Interupt deployment if we did not manage to revoke DEFAULT_ADMIN_ROLE from deployer
        if (hasRole(DEFAULT_ADMIN_ROLE, msg.sender)) revert DGErrors.DEPLOYER_STILL_DEFAULT_ADMIN_ROLE();
    }


    //      ______     __                        __   ______                 __  _
    //     / ____/  __/ /____  _________  ____ _/ /  / ____/_  ______  _____/ /_(_)___  ____  _____
    //    / __/ | |/_/ __/ _ \/ ___/ __ \/ __ `/ /  / /_  / / / / __ \/ ___/ __/ / __ \/ __ \/ ___/
    //   / /____>  </ /_/  __/ /  / / / / /_/ / /  / __/ / /_/ / / / / /__/ /_/ / /_/ / / / (__  )
    //  /_____/_/|_|\__/\___/_/  /_/ /_/\__,_/_/  /_/    \__,_/_/ /_/\___/\__/_/\____/_/ /_/____/

    /**
     * @notice 
     *  Function to allow users to play a game
     *
     * @param _operator Address of operator, must be an approved operator
     * @param _playerSeed the seed of the player, defaults to the wallet address but can be manually set by player
     *
     */
    function play(address _operator, bytes20 _playerSeed) external payable {
        // Make sure that wager format is correct (which it will be by default if played through frontend)
        if (
            msg.value % wager.min != 0 ||
            msg.value > wager.max ||
            msg.value < wager.min ||
            msg.value + playParamsOf[msg.sender].wager > wager.max
        ) revert DGErrors.UNALLOWED_WAGER_USE_FRONTEND();

        // Make sure that operator is approved
        if (!approved[_operator]) revert DGErrors.UNAPPROVED_OPERATOR();

        // Make sure that round is open
        if (
            gameIs == DGDataTypes.GameIs.ENDED ||
            block.timestamp > currentRoundCloses &&
            currentRoundCloses != 0
        ) revert DGErrors.ROUND_IS_CLOSED();

        // Calculate the operators cut
        uint256 operatorCut = (msg.value * wager.operatorFee) / DENOMINATOR;

        // Send the operator their cut right away
        (bool ok,) = payable(_operator).call{
            value: operatorCut
        }("");

        // if the transaction did not go throug, revert
        if (!ok) revert DGErrors.FAILED_TO_PAY_OPERATOR();

        // If it is the players first time joining this round...
        if (playParamsOf[msg.sender].wager == 0 ) {
            // Push the player address to the players array...
            players.push(msg.sender);

            // And push the player seed to the playerSeeds array..
            playerSeeds.push(_playerSeed);
        }

        // If the amount of players are 2...
        if (
            players.length == 2 &&
            gameIs == DGDataTypes.GameIs.WAITING
        ) {
            // ... Start the countdown ...
            currentRoundCloses = block.timestamp + roundLength;

            // ... set game is state to started
            gameIs = DGDataTypes.GameIs.STARTED;
        }

        // Calculate entries from whats been sent
        uint64 entries = uint64(msg.value) / wager.min;

        // Since this is only addition math we leave it unchecked
        unchecked {
            // Increment the wager
            playParamsOf[msg.sender].wager += uint64(msg.value);

            // Increment the amount of entries for the player
            playParamsOf[msg.sender].entries += entries;

            // Increment totalWagered with the players wager
            totalWagered += msg.value;

            // Increment currentRoundWagered with the players wager
            currentRoundWagered += msg.value;

            // Increment current round entires
            currentRoundEntries += entries;
        }

        // Emit an event that a game has been played
        emit DGEvents.GamePlayedB(
            playParamsOf[msg.sender],
            _operator,
            operatorCut,
            msg.sender,
            _playerSeed,
            players.length,
            currentRoundWagered,
            currentRoundEntries,
            currentRoundCloses,
            roundId
        );
    }

    /**
     * @notice 
     *  Withdrawal function in case of low trafic. Only the first player can withdraw as long as no one else has joined
     *
     */
    function withdraw() external {
        // Make sure that round is still waiting
        if (
            gameIs == DGDataTypes.GameIs.STARTED ||
            players.length > 1 ||
            uint256(playParamsOf[msg.sender].wager) != currentRoundWagered
        ) revert DGErrors.ROUND_STARTED_WITHDRAWAL_NOT_POSSIBLE();

        // Make sure that it is the valid player that is calling this function
        if (players[0] != msg.sender) revert DGErrors.YOU_HAVE_NOT_ENTERED_ROUND();

        // Calculate what to send the platform
        uint256 platformCut = (currentRoundWagered * wager.platformFee) / DENOMINATOR;

        // calculate total cut, but keep in mind operator fee is already drawn
        uint256 totalCut = (currentRoundWagered * (wager.operatorFee + wager.platformFee)) / DENOMINATOR;

        // Instanciate a variable to check that payments are going through
        bool ok;

        // Send platform cut to the platform
        (ok, ) = payable(platform).call{value: platformCut}("");

        // Revert if transaction didnt go through
        if (!ok) revert DGErrors.FAILED_TO_PAY_THE_PLATFORM();

        // Next up transfer back the wager to the player
        (ok, ) = payable(msg.sender).call{value: (currentRoundWagered - totalCut)}("");

        // Revert if transaction to payer didnt go through
        if(!ok) revert DGErrors.FAILED_TO_PAY_PLAYER();

        // Emit event that player has withdrawn funds
        emit DGEvents.PlayerWithdrawal(
            msg.sender,
            currentRoundWagered - totalCut,
            roundId
        );

        // remove wager from totalWagered
        totalWagered -= currentRoundWagered;

        // Zero out currentRoundWagered variable
        currentRoundWagered = 0;

        // Zero out currentRoundEntries variable
        currentRoundEntries = 0;

        // Delete players array
        delete players;

        // delete playerSeeds array
        delete playerSeeds;

        // Delete play params of total sender
        delete playParamsOf[msg.sender];
    }

    //     ____        __         ____                              ______                 __  _
    //    / __ \____  / /_  __   / __ \_      ______  ___  _____   / ____/_  ______  _____/ /_(_)___  ____  _____
    //   / / / / __ \/ / / / /  / / / / | /| / / __ \/ _ \/ ___/  / /_  / / / / __ \/ ___/ __/ / __ \/ __ \/ ___/
    //  / /_/ / / / / / /_/ /  / /_/ /| |/ |/ / / / /  __/ /     / __/ / /_/ / / / / /__/ /_/ / /_/ / / / (__  )
    //  \____/_/ /_/_/\__, /   \____/ |__/|__/_/ /_/\___/_/     /_/    \__,_/_/ /_/\___/\__/_/\____/_/ /_/____/
    //               /____/

    /**
     * @notice
     *  Draw a winner and clear out the round params
     *  only calleable by the DEFAULT_ADMIN_ROLE
     *
     * @param _seed the seed generated from the server to draw a random number
     *
     * @return _winner address of the winner chosen
     *
     */
    function drawWinner(bytes20 _seed) external onlyRole(DEFAULT_ADMIN_ROLE) returns(address _winner) {
        // Make sure that current round has passed
        if (block.timestamp < currentRoundCloses && currentRoundCloses != 0) revert DGErrors.ROUND_HASNT_CLOSED();

        // Make sure that a game has actually taken place
        if (gameIs != DGDataTypes.GameIs.STARTED) revert DGErrors.GAME_IS_FAULTY_STATE();

        // Make sure that this function is not called if there are no players
        if (players.length < 2) revert DGErrors.NOT_ENOUGH_PLAYERS_TO_DRAW_WINNER();

        // Make sure that the provided seed is untampered using the pre existing hash
        if (keccak256(abi.encodePacked(_seed)) != hashedServerSeed) revert DGErrors.SEED_DOES_NOT_MATCH_HASH();

        // Push the seed onto the playerSeeds array
        playerSeeds.push(_seed);

        // Full raw RNG result
        uint256 RNGResult = uint256(keccak256(abi.encodePacked(playerSeeds)));

        // Formatted RNG result to fit tree length
        uint256 formattedRNGResult = (RNGResult % currentRoundEntries) + 1;

        // Create a temporary entries variable
        uint256 tempEntries;

        // Start iterating through players
        for (uint256 i = 0; i < players.length; i++) {
            // Add players entries to temporary entries
            tempEntries += playParamsOf[players[i]].entries;

            // If RNG result is less then or equal to the temporary entries..
            if (formattedRNGResult <= tempEntries) {
                // ... set the current player we are iterating through as winner ...
                _winner = players[i];

                // ... And break the loop
                break;
            }
        }

        // Calculate what to send the platform
        uint256 platformCut = (currentRoundWagered * wager.platformFee) / DENOMINATOR;

        // calculate total cut, but keep in mind operator fee is already drawn
        uint256 totalCut = (currentRoundWagered * (wager.operatorFee + wager.platformFee)) / DENOMINATOR;

        // Instanciate a variable to check that payments are going through
        bool ok;

        // Send platform cut to the platform
        (ok, ) = payable(platform).call{value: platformCut}("");

        // Revert if transaction didnt go through
        if (!ok) revert DGErrors.FAILED_TO_PAY_THE_PLATFORM();

        // Next up transfer the winner payout to the winner
        (ok, ) = payable(_winner).call{value: (currentRoundWagered - totalCut)}("");

        // Revert if transaction didnt go through
        if (!ok) revert DGErrors.FAILED_TO_PAY_WINNER();

        emit DGEvents.WinnerDrawnB(
            _seed,
            players,
            playerSeeds,
            players.length,
            currentRoundEntries,
            RNGResult,
            formattedRNGResult,
            _winner,
            currentRoundWagered - totalCut,
            platformCut,
            roundId,
            msg.sender
        );

        // Zero out the current round ends variable
        currentRoundCloses = 0;

        // Set game status to pending
        gameIs = DGDataTypes.GameIs.ENDED;
    }

    /**
     * @notice
     *  Reseting previous rounds state and starts the next round
     *  Only callable by DEFAULT_ADMIN_ROLE
     *
     * @param _newHashedServerSeed the hashed version of the server seed for the new round
     *
     */
    function nextRound(bytes32 _newHashedServerSeed) external onlyRole(DEFAULT_ADMIN_ROLE) {
        // If state is not pending then revert transaction
        if (gameIs != DGDataTypes.GameIs.ENDED) revert DGErrors.GAME_NOT_ENDED_CANT_RESET_STATE();

        // Zero out currentRoundWagered variable
        currentRoundWagered = 0;

        // Zero out currentRoundEntries variable
        currentRoundEntries = 0;

        // Loop through player length
        for (uint16 i = 0; i < (players.length); i++) {
            // Delete playParams of player
            delete playParamsOf[players[i]];
        }

        // Delete players array
        delete players;

        // Delete  playerSeeds array
        delete playerSeeds;

        // Set game is status to open
        gameIs = DGDataTypes.GameIs.WAITING;

        // Set new hashed server seed
        hashedServerSeed = _newHashedServerSeed;

        // Increment round id
        roundId++;

        // Emit event for Next round
        emit DGEvents.NextRound(
            block.timestamp,
            roundId,
            msg.sender
        );
    }

    /**
     * @notice
     *  Set the approved status of a certain operator
     *  Only callable by DEFAULT_ADMIN_ROLE
     *
     * @param _operator address of the operator
     * @param _status boolean status to attribute to the operator
     *
     */
    function setOperatorStatus(address _operator, bool _status) external onlyRole(DEFAULT_ADMIN_ROLE) {
        // Toggle status of operator accordingly to bool argument
        approved[_operator] = _status;

        // Emit Operator Status Toggled event
        emit DGEvents.OperatorStatusToggled(
            _operator,
            _status,
            block.timestamp,
            msg.sender
        );
    }

    /**
     * @notice
     *  Function in case that can be used to change the wager params
     *  Only Callable by DEFAULT_ADMIN_ROLE
     *
     * @param _min minimum wager amount
     * @param _max maximum wager amount
     * @param _operatorFee operator fee in percentages (Denominator: 100 % = 10_000)
     * @param _platformFee platform fee in percentages (Denominator: 100 % = 10_000)
     *
     */
    function setWagerParams(uint64 _min, uint64 _max, uint16 _operatorFee, uint16 _platformFee) external onlyRole(DEFAULT_ADMIN_ROLE) {
        // Make sure that minimum wager amount is less than maximum, else the game will be DoSed
        if (_min > _max) revert DGErrors.MIN_LARGER_THAN_MAX_NOT_ALLOWED();

        // Make sure that neither operating fee or degaming fee is equal to or above 100 % aka 10_000
        if (
            _operatorFee >= DENOMINATOR || 
            _platformFee >= DENOMINATOR ||
            _operatorFee + _platformFee >= DENOMINATOR
        ) revert DGErrors.FEE_ABOVE_HUNDRED_PERCENT();

        // Set all the new params within the wager datatype
        wager = DGDataTypes.WagerParams(
            _min,
            _max,
            _operatorFee,
            _platformFee
        );

        // Emit event with potential rellevant info
        emit DGEvents.WagerParamsChanged(
            wager,
            block.timestamp,
            msg.sender
        );
    }

    /**
     * @notice
     *  Set a new round length
     *  Only Callable by DEFAULT_ADMIN_ROLE
     *
     * @param _newRoundLength new length in seconds
     *
     */
    function setRoundLength(uint8 _newRoundLength) external onlyRole(DEFAULT_ADMIN_ROLE) {
        // Set new Round length
        roundLength = _newRoundLength;

        // Emit RoundLengthChanged event
        emit DGEvents.RoundLengthChanged(
            _newRoundLength,
            block.timestamp,
            msg.sender
        );
    }

    /**
     * @notice
     *  Emergency function in case something breaks, so that the platform can save the funds. This will DoS the contract
     *  Only callable by DEFAULT_ADMIN_ROLE
     *
     * @param _amount amount to withdraw
     *
     * @return _success if the transfer went through as expected
     *
     */
    function emergencyWithdraw(uint256 _amount) external onlyRole(DEFAULT_ADMIN_ROLE) returns(bool _success) {
        // Send transaction to sender
        (_success,) = payable(msg.sender).call{value: _amount}("");

        // Emit FundsWithdrawn event
        emit DGEvents.FundsEmergencyWithdrawn(
            _amount,
            block.timestamp,
            msg.sender,
            roundId
        );
    }

    /**
     * @notice
     *  Emergency function to restore eth balance and undo the DoS
     *  Only callable by DEFAULT_ADMIN ROLE
     *
     */

    function deposit() external payable onlyRole(DEFAULT_ADMIN_ROLE) {
        // Make sure that this transaction actually will unlock the DoS
        if (address(this).balance + msg.value < currentRoundWagered) revert DGErrors.NOT_ENOUGH_TO_RESTORE();

        // Emit FundsDeposited event
        emit DGEvents.FundsDeposited(
            msg.value,
            block.timestamp,
            msg.sender
        );
    }

    //     ____                     ______                 __  _
    //    / __ \__  __________     / ____/_  ______  _____/ /_(_)___  ____  _____
    //   / /_/ / / / / ___/ _ \   / /_  / / / / __ \/ ___/ __/ / __ \/ __ \/ ___/
    //  / ____/ /_/ / /  /  __/  / __/ / /_/ / / / / /__/ /_/ / /_/ / / / (__  )
    // /_/    \__,_/_/   \___/  /_/    \__,_/_/ /_/\___/\__/_/\____/_/ /_/____/

    /**
     * @notice
     *  Pass in the variables from the game you'd like to control and check what it generates
     *
     * @param _seed the server side seed, generated on chain previous to the round by the platform
     * @param _playerSeeds the array of participating players seeds for this round
     * @param _amountOfEntries This is used for formatting the raw RNG result
     *
     * @return _encodedPacked encoded version of players with seed pushed to the end
     * @return _hash keccak256 hashed version of the _encodePacked
     * @return _RNGResult unformatted uint coversion from the _hashedSeed
     * @return _formattedRNGResult RNG result formatted to fit the length of the keys, thereby giving a result
     *
     */
    function controlProvableFairNumber(
        bytes20 _seed,
        bytes20[] memory _playerSeeds,
        uint256 _amountOfEntries
    ) external pure returns(bytes memory _encodedPacked, bytes32 _hash, uint256 _RNGResult, uint256 _formattedRNGResult) {
        // Calculate the length of the new temporary array
        uint256 newLength = _playerSeeds.length + 1;

        // Create a static array of the length we calculated
        bytes20[] memory tempSeedsArray = new bytes20[](newLength);

        // Assign values from playerSeeds over to our new array
        for (uint256 i = 0; i < _playerSeeds.length; i++) {
            tempSeedsArray[i] = _playerSeeds[i];
        }

        // push the serverseed to the end of our temporary players array
        tempSeedsArray[_playerSeeds.length] = _seed;

        // Encode and pack the array
        _encodedPacked = abi.encodePacked(tempSeedsArray);

        // Hash this and return for second argument
        _hash = keccak256(_encodedPacked);

        // Convert to a uint and return for third argument
        _RNGResult = uint256(_hash);

        // Format it to fit within the tree length and return for last argument
        _formattedRNGResult = (_RNGResult % _amountOfEntries) + 1;
    }

    /**
     * @notice
     *  A pure function to input a string and recieve a bytes20 formatted seed to use for play functions
     *  If, however, the string inputed is too large to fit into bytes20, this function will revert
     *
     * @param _playerSeedString input string from player in order to generate their bytes formatted seed
     *
     */
    function stringAsBytes20(string memory _playerSeedString) public pure returns(bytes20 _playerSeedBytes) {
        // Make sure that string is not to long
        if (bytes(_playerSeedString).length > 20) revert DGErrors.STRING_TOO_LONG();

        // Return string in bytes format
        _playerSeedBytes = bytes20(abi.encodePacked(_playerSeedString));
    }

    //   _    ___                 ______                 __  _
    //  | |  / (_)__ _      __   / ____/_  ______  _____/ /_(_)___  ____  _____
    //  | | / / / _ \ | /| / /  / /_  / / / / __ \/ ___/ __/ / __ \/ __ \/ ___/
    //  | |/ / /  __/ |/ |/ /  / __/ / /_/ / / / / /__/ /_/ / /_/ / / / (__  )
    //  |___/_/\___/|__/|__/  /_/    \__,_/_/ /_/\___/\__/_/\____/_/ /_/____/

    /**
     * @notice
     *  Get all the current players
     *
     * @return _players the array of player addresses
     *
     */
    function getPlayers() external view returns (address[] memory _players) {
        // return player array
        _players = players;
    }

    /**
     * @notice
     *  Get all the current player seeds
     *
     * @return _playerSeeds the array of playerSeeds
     *
     */
    function getPlayerSeeds() external view returns (bytes20[] memory _playerSeeds) {
        // Return playerSeeds array
        _playerSeeds = playerSeeds;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v5.0.0) (access/AccessControl.sol)

pragma solidity ^0.8.20;

import {IAccessControl} from "./IAccessControl.sol";
import {Context} from "../utils/Context.sol";
import {ERC165} from "../utils/introspection/ERC165.sol";

/**
 * @dev Contract module that allows children to implement role-based access
 * control mechanisms. This is a lightweight version that doesn't allow enumerating role
 * members except through off-chain means by accessing the contract event logs. Some
 * applications may benefit from on-chain enumerability, for those cases see
 * {AccessControlEnumerable}.
 *
 * Roles are referred to by their `bytes32` identifier. These should be exposed
 * in the external API and be unique. The best way to achieve this is by
 * using `public constant` hash digests:
 *
 * ```solidity
 * bytes32 public constant MY_ROLE = keccak256("MY_ROLE");
 * ```
 *
 * Roles can be used to represent a set of permissions. To restrict access to a
 * function call, use {hasRole}:
 *
 * ```solidity
 * function foo() public {
 *     require(hasRole(MY_ROLE, msg.sender));
 *     ...
 * }
 * ```
 *
 * Roles can be granted and revoked dynamically via the {grantRole} and
 * {revokeRole} functions. Each role has an associated admin role, and only
 * accounts that have a role's admin role can call {grantRole} and {revokeRole}.
 *
 * By default, the admin role for all roles is `DEFAULT_ADMIN_ROLE`, which means
 * that only accounts with this role will be able to grant or revoke other
 * roles. More complex role relationships can be created by using
 * {_setRoleAdmin}.
 *
 * WARNING: The `DEFAULT_ADMIN_ROLE` is also its own admin: it has permission to
 * grant and revoke this role. Extra precautions should be taken to secure
 * accounts that have been granted it. We recommend using {AccessControlDefaultAdminRules}
 * to enforce additional security measures for this role.
 */
abstract contract AccessControl is Context, IAccessControl, ERC165 {
    struct RoleData {
        mapping(address account => bool) hasRole;
        bytes32 adminRole;
    }

    mapping(bytes32 role => RoleData) private _roles;

    bytes32 public constant DEFAULT_ADMIN_ROLE = 0x00;

    /**
     * @dev Modifier that checks that an account has a specific role. Reverts
     * with an {AccessControlUnauthorizedAccount} error including the required role.
     */
    modifier onlyRole(bytes32 role) {
        _checkRole(role);
        _;
    }

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return interfaceId == type(IAccessControl).interfaceId || super.supportsInterface(interfaceId);
    }

    /**
     * @dev Returns `true` if `account` has been granted `role`.
     */
    function hasRole(bytes32 role, address account) public view virtual returns (bool) {
        return _roles[role].hasRole[account];
    }

    /**
     * @dev Reverts with an {AccessControlUnauthorizedAccount} error if `_msgSender()`
     * is missing `role`. Overriding this function changes the behavior of the {onlyRole} modifier.
     */
    function _checkRole(bytes32 role) internal view virtual {
        _checkRole(role, _msgSender());
    }

    /**
     * @dev Reverts with an {AccessControlUnauthorizedAccount} error if `account`
     * is missing `role`.
     */
    function _checkRole(bytes32 role, address account) internal view virtual {
        if (!hasRole(role, account)) {
            revert AccessControlUnauthorizedAccount(account, role);
        }
    }

    /**
     * @dev Returns the admin role that controls `role`. See {grantRole} and
     * {revokeRole}.
     *
     * To change a role's admin, use {_setRoleAdmin}.
     */
    function getRoleAdmin(bytes32 role) public view virtual returns (bytes32) {
        return _roles[role].adminRole;
    }

    /**
     * @dev Grants `role` to `account`.
     *
     * If `account` had not been already granted `role`, emits a {RoleGranted}
     * event.
     *
     * Requirements:
     *
     * - the caller must have ``role``'s admin role.
     *
     * May emit a {RoleGranted} event.
     */
    function grantRole(bytes32 role, address account) public virtual onlyRole(getRoleAdmin(role)) {
        _grantRole(role, account);
    }

    /**
     * @dev Revokes `role` from `account`.
     *
     * If `account` had been granted `role`, emits a {RoleRevoked} event.
     *
     * Requirements:
     *
     * - the caller must have ``role``'s admin role.
     *
     * May emit a {RoleRevoked} event.
     */
    function revokeRole(bytes32 role, address account) public virtual onlyRole(getRoleAdmin(role)) {
        _revokeRole(role, account);
    }

    /**
     * @dev Revokes `role` from the calling account.
     *
     * Roles are often managed via {grantRole} and {revokeRole}: this function's
     * purpose is to provide a mechanism for accounts to lose their privileges
     * if they are compromised (such as when a trusted device is misplaced).
     *
     * If the calling account had been revoked `role`, emits a {RoleRevoked}
     * event.
     *
     * Requirements:
     *
     * - the caller must be `callerConfirmation`.
     *
     * May emit a {RoleRevoked} event.
     */
    function renounceRole(bytes32 role, address callerConfirmation) public virtual {
        if (callerConfirmation != _msgSender()) {
            revert AccessControlBadConfirmation();
        }

        _revokeRole(role, callerConfirmation);
    }

    /**
     * @dev Sets `adminRole` as ``role``'s admin role.
     *
     * Emits a {RoleAdminChanged} event.
     */
    function _setRoleAdmin(bytes32 role, bytes32 adminRole) internal virtual {
        bytes32 previousAdminRole = getRoleAdmin(role);
        _roles[role].adminRole = adminRole;
        emit RoleAdminChanged(role, previousAdminRole, adminRole);
    }

    /**
     * @dev Attempts to grant `role` to `account` and returns a boolean indicating if `role` was granted.
     *
     * Internal function without access restriction.
     *
     * May emit a {RoleGranted} event.
     */
    function _grantRole(bytes32 role, address account) internal virtual returns (bool) {
        if (!hasRole(role, account)) {
            _roles[role].hasRole[account] = true;
            emit RoleGranted(role, account, _msgSender());
            return true;
        } else {
            return false;
        }
    }

    /**
     * @dev Attempts to revoke `role` to `account` and returns a boolean indicating if `role` was revoked.
     *
     * Internal function without access restriction.
     *
     * May emit a {RoleRevoked} event.
     */
    function _revokeRole(bytes32 role, address account) internal virtual returns (bool) {
        if (hasRole(role, account)) {
            _roles[role].hasRole[account] = false;
            emit RoleRevoked(role, account, _msgSender());
            return true;
        } else {
            return false;
        }
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.21;

/**
 * @title DGErrors
 * @author DG Technical Team
 * @notice Library containing DG contracts' custom errors
 */
library DGErrors {
    /// @dev error thrown if payment to operator fails
    error FAILED_TO_PAY_OPERATOR();

    /// @dev error thrown if payment to winner fails
    error FAILED_TO_PAY_WINNER();

    /// @dev error thrown if payment to the platform fails
    error FAILED_TO_PAY_THE_PLATFORM();

    /// @dev error thrown if a payment to a withdrawing player fails
    error FAILED_TO_PAY_PLAYER();

    /// @dev Error thrown when format of wager is wrong
    error UNALLOWED_WAGER_USE_FRONTEND();

    /// @dev Error thrown when operator that player used is not approved
    error UNAPPROVED_OPERATOR();

    /// @dev Error thrown when trying to draw a winner before round has closed
    error ROUND_HASNT_CLOSED();

    /// @dev Error thrown when trying to draw a winner from a faulty gameIs state
    error GAME_IS_FAULTY_STATE();

    /// @dev Error thrown when player has already wagered during this round
    error YOU_HAVE_ALREADY_ENTERED_CURRENT_ROUND();

    /// @dev Error thrown when round is closed
    error ROUND_IS_CLOSED();

    /// @dev Error thrown when trying to reset the states without it being possible
    error GAME_NOT_ENDED_CANT_RESET_STATE();

    /// @dev Error thrown when trying to open round without it being possible
    error GAME_NOT_RESET_CANT_OPEN_ROUND();

    /// @dev Error thrown in the constructor if we did not succeed to remove default admin role from deployer
    error DEPLOYER_STILL_DEFAULT_ADMIN_ROLE();

    /// @dev Error thrown when tryingto change wager params in a way that would dos the game
    error MIN_LARGER_THAN_MAX_NOT_ALLOWED();

    /// @dev Error thrown when admin try to set to high fee
    error FEE_ABOVE_HUNDRED_PERCENT();

    /// @dev Error thrown when trying to to little deposit funds after emergency withdraw
    error NOT_ENOUGH_TO_RESTORE();

    /// @dev Error thrown if we try to draw a winner with to little players
    error NOT_ENOUGH_PLAYERS_TO_DRAW_WINNER();

    /// @dev Error thrown when provided seed doesnt match the pre hashed seed
    error SEED_DOES_NOT_MATCH_HASH();

    /// @dev Error thrown if a player tries to withdraw funds after a round is already started
    error ROUND_STARTED_WITHDRAWAL_NOT_POSSIBLE();

    /// @dev Error thrown when a player tries to withdraw funds that arent theirs
    error YOU_HAVE_NOT_ENTERED_ROUND();

    /// @dev Error thrown if string that should be converted to bytes20 is too long
    error STRING_TOO_LONG();
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.21;

/**
 * @title DGDataTypes
 * @author DG Technical Team
 * @notice Library containing DG contracts' custom data types
 */
library DGDataTypes {
    // UNIVERSAL DATATYPES

    /**
     * @notice 
     *  Wager params set for the DGPVP contract, keeping track of param info
     *
     * @param min minimum bet size
     * @param max maximum bet size
     * @param operatorFee operator fee in percentage format (DENOMINATOR: 100 % = 10_000)
     * @param platformFee platform fee in percentage format (DENOMINATOR: 100 % = 10_000)
     *
     */
    struct WagerParams {
        uint64 min;
        uint64 max;
        uint16 operatorFee;
        uint16 platformFee;
    }

    /// @dev Enum that holds the status of the game
    enum GameIs {
        WAITING,
        STARTED,
        ENDED
    }

    // DGPVP_A DATATYPES

    /**
     * @notice
     *  Play params that will be unique per round per player
     *
     * @param wager The amount that the player wagered
     * @param entryKey Entry key that the player has in the tree
     *
     */
    struct PlayParams {
        uint64 wager;
        uint64 rangeStart;
        uint64 entryKey;
    }

    // DGPVP_B DATATYPES

    /**
     * @notice
     *  Play params for a participating player
     *
     * @param wager The amount that the player wagered
     * @param entries amount of entries that player holds for this round
     */
    struct PlayParamsB {
        uint64 wager;
        uint64 entries;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.21;

import {DGDataTypes} from "src/libraries/DGDataTypes.sol";

/**
 * @title DGEvents
 * @author DG Technical Team
 * @notice Library containing DeGaming contracts' custom events
 */
library DGEvents {
    // DGPVP_A EVENTS

    /// @dev Event emitted when a game is played
    event GamePlayed(
        DGDataTypes.PlayParams params,
        uint256 totalKeys,
        address indexed operator,
        uint256 operatorCut,
        address indexed player,
        uint256 amountOfPlayers,
        uint256 totalWagered,
        uint256 currentRoundWagered,
        uint256 currentRoundCloses,
        uint256 indexed roundId,
        uint256 timestamp
    );

    /// @dev Event emitted when a winner is drawn
    event WinnerDrawn(
        bytes20 seed,
        address[] players,
        uint256 amountOfPlayers,
        uint256 totalKeys,
        uint256 RNGResult,
        uint256 RNGResultFormatted,
        address indexed winner,
        uint256 platformCut,
        uint256 winnerPayout,
        uint256 indexed roundId,
        uint256 timestamp,
        address indexed executor
    );

    // DGPVP_B EVENTS

    /// @dev Event emited when a game is played
    event GamePlayedB(
        DGDataTypes.PlayParamsB params,
        address indexed operator,
        uint256 operatorCut,
        address indexed player,
        bytes20 playerSeed,
        uint256 amountOfPlayers,
        uint256 currentRoundWagered,
        uint256 currentRoundEntries,
        uint256 currentRoundCloses,
        uint256 indexed roundId
    );

    event WinnerDrawnB(
        bytes20 serverSeed,
        address[] players,
        bytes20[] playerSeeds,
        uint256 amountOfPlayers,
        uint256 currentRoundEntries,
        uint256 RNGResult,
        uint256 formattedRNGResult,
        address indexed winner,
        uint256 winnerPayout,
        uint256 platformCut,
        uint256 indexed roundId,
        address indexed executor
    );

    // GENERIC EVENTS

    /// @dev Event emitted when a round is opened
    event NextRound(
        uint256 timestamp,
        uint256 indexed roundId,
        address indexed executor
    );

    /// @dev Event emitted when an Operators status is toggled
    event OperatorStatusToggled(
        address indexed operator,
        bool status,
        uint256 timestamp,
        address indexed executor
    );

    /// @dev Event Emitted when WagerParamsChanged
    event WagerParamsChanged(
        DGDataTypes.WagerParams newWagerParams,
        uint256 timestamp,
        address indexed executor
    );

    /// @dev Event Emitted when RoundLengthChanged
    event RoundLengthChanged(
        uint8 newRoundLength,
        uint256 timeStamp,
        address indexed executor
    );

    /// @dev Event emitted when player funds are withdrawn
    event PlayerWithdrawal(
        address player,
        uint256 amount,
        uint256 indexed roundId
    );

    /// @dev Event Emitted when Funds are being withdrawn in case of emergency
    event FundsEmergencyWithdrawn(
        uint256 amount,
        uint256 timeStamp,
        address indexed executor,
        uint256 indexed roundId
    );

    /// @dev event emitted when funds are re-deposited after they been withdrawn
    event FundsDeposited(
        uint256 amount,
        uint256 timeStamp,
        address indexed executor
    );
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v5.0.0) (access/IAccessControl.sol)

pragma solidity ^0.8.20;

/**
 * @dev External interface of AccessControl declared to support ERC165 detection.
 */
interface IAccessControl {
    /**
     * @dev The `account` is missing a role.
     */
    error AccessControlUnauthorizedAccount(address account, bytes32 neededRole);

    /**
     * @dev The caller of a function is not the expected one.
     *
     * NOTE: Don't confuse with {AccessControlUnauthorizedAccount}.
     */
    error AccessControlBadConfirmation();

    /**
     * @dev Emitted when `newAdminRole` is set as ``role``'s admin role, replacing `previousAdminRole`
     *
     * `DEFAULT_ADMIN_ROLE` is the starting admin for all roles, despite
     * {RoleAdminChanged} not being emitted signaling this.
     */
    event RoleAdminChanged(bytes32 indexed role, bytes32 indexed previousAdminRole, bytes32 indexed newAdminRole);

    /**
     * @dev Emitted when `account` is granted `role`.
     *
     * `sender` is the account that originated the contract call, an admin role
     * bearer except when using {AccessControl-_setupRole}.
     */
    event RoleGranted(bytes32 indexed role, address indexed account, address indexed sender);

    /**
     * @dev Emitted when `account` is revoked `role`.
     *
     * `sender` is the account that originated the contract call:
     *   - if using `revokeRole`, it is the admin role bearer
     *   - if using `renounceRole`, it is the role bearer (i.e. `account`)
     */
    event RoleRevoked(bytes32 indexed role, address indexed account, address indexed sender);

    /**
     * @dev Returns `true` if `account` has been granted `role`.
     */
    function hasRole(bytes32 role, address account) external view returns (bool);

    /**
     * @dev Returns the admin role that controls `role`. See {grantRole} and
     * {revokeRole}.
     *
     * To change a role's admin, use {AccessControl-_setRoleAdmin}.
     */
    function getRoleAdmin(bytes32 role) external view returns (bytes32);

    /**
     * @dev Grants `role` to `account`.
     *
     * If `account` had not been already granted `role`, emits a {RoleGranted}
     * event.
     *
     * Requirements:
     *
     * - the caller must have ``role``'s admin role.
     */
    function grantRole(bytes32 role, address account) external;

    /**
     * @dev Revokes `role` from `account`.
     *
     * If `account` had been granted `role`, emits a {RoleRevoked} event.
     *
     * Requirements:
     *
     * - the caller must have ``role``'s admin role.
     */
    function revokeRole(bytes32 role, address account) external;

    /**
     * @dev Revokes `role` from the calling account.
     *
     * Roles are often managed via {grantRole} and {revokeRole}: this function's
     * purpose is to provide a mechanism for accounts to lose their privileges
     * if they are compromised (such as when a trusted device is misplaced).
     *
     * If the calling account had been granted `role`, emits a {RoleRevoked}
     * event.
     *
     * Requirements:
     *
     * - the caller must be `callerConfirmation`.
     */
    function renounceRole(bytes32 role, address callerConfirmation) external;
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
// OpenZeppelin Contracts (last updated v5.0.0) (utils/introspection/ERC165.sol)

pragma solidity ^0.8.20;

import {IERC165} from "./IERC165.sol";

/**
 * @dev Implementation of the {IERC165} interface.
 *
 * Contracts that want to implement ERC165 should inherit from this contract and override {supportsInterface} to check
 * for the additional interface id that will be supported. For example:
 *
 * ```solidity
 * function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
 *     return interfaceId == type(MyInterface).interfaceId || super.supportsInterface(interfaceId);
 * }
 * ```
 */
abstract contract ERC165 is IERC165 {
    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual returns (bool) {
        return interfaceId == type(IERC165).interfaceId;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v5.0.0) (utils/introspection/IERC165.sol)

pragma solidity ^0.8.20;

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