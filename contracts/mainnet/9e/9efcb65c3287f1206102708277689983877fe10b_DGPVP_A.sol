// SPDX-License-Identifier: MIT
pragma solidity 0.8.21;


/* BokkyPooBah Libraries */
import {BokkyPooBahsRedBlackTreeLibrary} from "@BokkyPooBah/RedBlackTree/contracts/BokkyPooBahsRedBlackTreeLibrary.sol";

/* Openzeppelin Contracts */
import {AccessControl} from "@openzeppelin/contracts/access/AccessControl.sol";

/* DG Libraries */
import {DGErrors} from "src/libraries/DGErrors.sol";
import {DGDataTypes} from "src/libraries/DGDataTypes.sol";
import {DGEvents} from "src/libraries/DGEvents.sol";

/**
 * @title DGPVP
 * @author DG Technical Team
 * @notice Player VS Player game
 *
 */
contract DGPVP_A is AccessControl{
    /// @dev Setup library for red black trees
    using BokkyPooBahsRedBlackTreeLibrary for BokkyPooBahsRedBlackTreeLibrary.Tree;

    //     _____ __        __
    //    / ___// /_____ _/ /____  _____
    //    \__ \/ __/ __ `/ __/ _ \/ ___/
    //   ___/ / /_/ /_/ / /_/  __(__  )
    //  /____/\__/\__,_/\__/\___/____/
    /// @dev instanciate red black tree
    BokkyPooBahsRedBlackTreeLibrary.Tree tree;

    /// @dev instanciate wager params
    DGDataTypes.WagerParams wager;

    /// @dev status of game 
    /// |---WAITING
    /// |---STARTED
    /// |---ENDED
    DGDataTypes.GameIs public gameIs;

    /// @dev The platforms address
    address platform;

    /// @dev variable that holds
    uint8 public roundLength;

    /// @dev used to calculate percentages
    uint256 public constant DENOMINATOR = 10_000;

    /// @dev check the total amount wagered throughout the lifetime of this contract
    uint256 public totalWagered;

    /// @dev check amount wagered in the current round
    uint256 public currentRoundWagered;

    /// @dev unix timestamp for when current round ends
    uint256 public currentRoundCloses;

    /// @dev id for round, increments when new games are played
    uint256 public roundId;

    /// @dev array to hold all current player addresses
    address[] players;

    /// @dev Hashed version of the server seed that will be used to draw a random number
    bytes32 public hashedServerSeed;

    /// @dev public variable for holding players params
    mapping(address player => DGDataTypes.PlayParams params) public playParamsOf;

    /// @dev private variable that stores the owner of a certain entry key
    mapping(uint64 entryKey => address player) holderOfKey;

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
        wager.max = 0.1 ether;

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
     *
     */
    function play(address _operator) external payable {
        // Make sure that wager format is correct (which it will be by default if played through frontend)
        if (
            msg.value % wager.min != 0 ||
            msg.value > wager.max ||
            msg.value < wager.min
        ) revert DGErrors.UNALLOWED_WAGER_USE_FRONTEND();

        // Make sure that operator is approved
        if (!approved[_operator]) revert DGErrors.UNAPPROVED_OPERATOR();

        // Make sure that player isn't already participating in this round
        if (
            playParamsOf[msg.sender].wager != 0 ||
            playParamsOf[msg.sender].rangeStart != 0 ||
            playParamsOf[msg.sender].entryKey != 0
        ) revert DGErrors.YOU_HAVE_ALREADY_ENTERED_CURRENT_ROUND();

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

        uint64 lastEntry = uint64(tree.last());

        // Calculate the entry key for the player (this will be used later to determine the winner)
        uint64 entryKey = lastEntry + (uint64(msg.value)/ uint64(wager.min));

        // Create player params
        playParamsOf[msg.sender] = DGDataTypes.PlayParams(
            uint64(msg.value),
            lastEntry + 1,
            entryKey
        );

        // Insert entrykey into the red black tree
        tree.insert(entryKey);

        // set holder of key variable to easily be able to fetch the player from this value
        holderOfKey[entryKey] = msg.sender;

        // push player address into the array of players for the current round
        players.push(msg.sender);

        // If the amount of players are 2...
        if (players.length == 2) {
            // ... Start the countdown ...
            currentRoundCloses = block.timestamp + roundLength;

            // ... set game is state to started
            gameIs = DGDataTypes.GameIs.STARTED;
        }

        // Since this is only addition math we leave it unchecked
        unchecked {
            // Increment totalWagered with the players wager
            totalWagered += msg.value;

            // Increment currentRoundWagered with the players wager
            currentRoundWagered += msg.value;
        }

        // Emit a Game Played event
        emit DGEvents.GamePlayed(
            playParamsOf[msg.sender],
            tree.last(),
            _operator,
            operatorCut,
            msg.sender,
            players.length,
            totalWagered,
            currentRoundWagered,
            currentRoundCloses,
            roundId,
            block.timestamp
        );
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

        players.push(address(_seed));

        // Full raw RNG result
        uint256 RNGResult = uint256(keccak256(abi.encodePacked(players)));

        // Formatted RNG result to fit tree length
        uint256 formattedRNGResult = (RNGResult % tree.last()) + 1;

        // Fetch the first key
        uint256 key = tree.first();

        players.pop();

        // Start iterating through players
        for (uint256 i = 0; i < players.length; i++) {
            // If the formatted result is withing players range...
            if (formattedRNGResult <= key) {
                // ... return this player as the winner ...
                _winner = players[i];

                // ... and break this loop ...
                break;
            }

            // ... else check the next key from our tree
            key = tree.next(key);
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

        // Emit the Winner Drawn event
        emit DGEvents.WinnerDrawn(
            _seed,
            players,
            players.length,
            tree.last(),
            RNGResult,
            formattedRNGResult,
            _winner,
            platformCut,
            currentRoundWagered - totalCut,
            roundId,
            block.timestamp,
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
     *  Only callable by ADMIN_ROLE
     *
     * @param _newHashedServerSeed the hashed version of the server seed for the new round
     *
     */
    function nextRound(bytes32 _newHashedServerSeed) external onlyRole(DEFAULT_ADMIN_ROLE) {
        // If state is not pending then revert transaction
        if (gameIs != DGDataTypes.GameIs.ENDED) revert DGErrors.GAME_NOT_ENDED_CANT_RESET_STATE();

        // Zero out currentRoundWagered variable
        currentRoundWagered = 0;

        // Instanciate a temporary variable that will be used to hold info within loop
        DGDataTypes.PlayParams memory temporaryParams;

        // Loop through player length
        for (uint256 i = 0; i < (players.length); i++) {
            // Fetch temporary params of player of index i in array
            temporaryParams = playParamsOf[players[i]];

            // Null out the entry key to address param
            holderOfKey[temporaryParams.entryKey] = address(0);

            // Remove entrykey from tree
            tree.remove(temporaryParams.entryKey);

            // Null out bottom range
            temporaryParams.rangeStart = 0;

            // Null out entry key param within playParamsOf player
            temporaryParams.entryKey = 0;

            // Null out wager param within playParamsOf player
            temporaryParams.wager = 0;

            // Set the new nulled out params to the mapping to 0 out all data
            playParamsOf[players[i]] = temporaryParams;
        }

        // Delete players array
        delete players;

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
     *  Only callable by ADMIN_ROLE
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
     *  Only Callable by ADMIN_ROLE
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
            _platformFee >= DENOMINATOR
        ) revert DGErrors.FEE_ABOVE_HUNDRED_PERCENT();

        // Reset all the params within the wager dataType
        wager.max = _max;
        wager.min = _min;
        wager.operatorFee = _operatorFee;
        wager.platformFee = _platformFee;

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
     *  Only Callable by ADMIN_ROLE
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
     *  Only callable by ADMIN_ROLE
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
     *  Only callable by ADMIN ROLE
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

    //   _    ___                 ______                 __  _
    //  | |  / (_)__ _      __   / ____/_  ______  _____/ /_(_)___  ____  _____
    //  | | / / / _ \ | /| / /  / /_  / / / / __ \/ ___/ __/ / __ \/ __ \/ ___/
    //  | |/ / /  __/ |/ |/ /  / __/ / /_/ / / / / /__/ /_/ / /_/ / / / (__  )
    //  |___/_/\___/|__/|__/  /_/    \__,_/_/ /_/\___/\__/_/\____/_/ /_/____/

    /**
     * @notice
     *  Pass in the variables from the game you'd like to controll and check what it generates
     *
     * @param _seed the server side seed, generated on chain previous to the round by the platform
     * @param _players the array of participating players for this round, used as playe seeds
     * @param _length length of keys in the tree. This is used for formatting the raw RNG result
     *
     * @return _encodedPacked encoded version of players with seed pushed to the end
     * @return _hash keccak256 hashed version of the _encodePacked
     * @return _RNGResult unformatted uint coversion from the _hashedSeed
     * @return _formattedRNGResult RNG result formatted to fit the length of the keys, thereby giving a result
     *
     */
    function controllProvableFairNumber(
        bytes20 _seed,
        address[] memory _players,
        uint256 _length
    ) external pure returns(bytes memory _encodedPacked, bytes32 _hash, uint256 _RNGResult, uint256 _formattedRNGResult) {
        uint256 newLength = _players.length + 1;

        address[] memory tempPlayerArray = new address[](newLength);

        for (uint256 i = 0; i < _players.length; i++) {
            tempPlayerArray[i] = _players[i];
        }

        // push the serverseed to the end of our temporary players array
        tempPlayerArray[_players.length] = address(_seed);

        // Encode and pack the array
        _encodedPacked = abi.encodePacked(tempPlayerArray);

        // Hash this and return for second argument
        _hash = keccak256(_encodedPacked);

        // Convert to a uint and return for third argument
        _RNGResult = uint256(_hash);

        // Format it to fit within the tree length and return for last argument
        _formattedRNGResult = (_RNGResult % _length) + 1;
    }

    /**
     * @notice 
     *  Get length of tree
     *
     * @return _length length of the tree
     *
     */
    function getKeyLength() external view returns (uint256 _length) {
        // fetch tree length
        _length = tree.last();
    }

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
}

pragma solidity ^0.8.0;

// ----------------------------------------------------------------------------
// BokkyPooBah's Red-Black Tree Library v1.0-pre-release-a
//
// A Solidity Red-Black Tree binary search library to store and access a sorted
// list of unsigned integer data. The Red-Black algorithm rebalances the binary
// search tree, resulting in O(log n) insert, remove and search time (and ~gas)
//
// https://github.com/bokkypoobah/BokkyPooBahsRedBlackTreeLibrary
//
//
// Enjoy. (c) BokkyPooBah / Bok Consulting Pty Ltd 2020. The MIT Licence.
// ----------------------------------------------------------------------------
library BokkyPooBahsRedBlackTreeLibrary {

    struct Node {
        uint parent;
        uint left;
        uint right;
        bool red;
    }

    struct Tree {
        uint root;
        mapping(uint => Node) nodes;
    }

    uint private constant EMPTY = 0;

    function first(Tree storage self) internal view returns (uint _key) {
        _key = self.root;
        if (_key != EMPTY) {
            while (self.nodes[_key].left != EMPTY) {
                _key = self.nodes[_key].left;
            }
        }
    }
    function last(Tree storage self) internal view returns (uint _key) {
        _key = self.root;
        if (_key != EMPTY) {
            while (self.nodes[_key].right != EMPTY) {
                _key = self.nodes[_key].right;
            }
        }
    }
    function next(Tree storage self, uint target) internal view returns (uint cursor) {
        require(target != EMPTY);
        if (self.nodes[target].right != EMPTY) {
            cursor = treeMinimum(self, self.nodes[target].right);
        } else {
            cursor = self.nodes[target].parent;
            while (cursor != EMPTY && target == self.nodes[cursor].right) {
                target = cursor;
                cursor = self.nodes[cursor].parent;
            }
        }
    }
    function prev(Tree storage self, uint target) internal view returns (uint cursor) {
        require(target != EMPTY);
        if (self.nodes[target].left != EMPTY) {
            cursor = treeMaximum(self, self.nodes[target].left);
        } else {
            cursor = self.nodes[target].parent;
            while (cursor != EMPTY && target == self.nodes[cursor].left) {
                target = cursor;
                cursor = self.nodes[cursor].parent;
            }
        }
    }
    function exists(Tree storage self, uint key) internal view returns (bool) {
        return (key != EMPTY) && ((key == self.root) || (self.nodes[key].parent != EMPTY));
    }
    function isEmpty(uint key) internal pure returns (bool) {
        return key == EMPTY;
    }
    function getEmpty() internal pure returns (uint) {
        return EMPTY;
    }
    function getNode(Tree storage self, uint key) internal view returns (uint _returnKey, uint _parent, uint _left, uint _right, bool _red) {
        require(exists(self, key));
        return(key, self.nodes[key].parent, self.nodes[key].left, self.nodes[key].right, self.nodes[key].red);
    }

    function insert(Tree storage self, uint key) internal {
        require(key != EMPTY);
        require(!exists(self, key));
        uint cursor = EMPTY;
        uint probe = self.root;
        while (probe != EMPTY) {
            cursor = probe;
            if (key < probe) {
                probe = self.nodes[probe].left;
            } else {
                probe = self.nodes[probe].right;
            }
        }
        self.nodes[key] = Node({parent: cursor, left: EMPTY, right: EMPTY, red: true});
        if (cursor == EMPTY) {
            self.root = key;
        } else if (key < cursor) {
            self.nodes[cursor].left = key;
        } else {
            self.nodes[cursor].right = key;
        }
        insertFixup(self, key);
    }
    function remove(Tree storage self, uint key) internal {
        require(key != EMPTY);
        require(exists(self, key));
        uint probe;
        uint cursor;
        if (self.nodes[key].left == EMPTY || self.nodes[key].right == EMPTY) {
            cursor = key;
        } else {
            cursor = self.nodes[key].right;
            while (self.nodes[cursor].left != EMPTY) {
                cursor = self.nodes[cursor].left;
            }
        }
        if (self.nodes[cursor].left != EMPTY) {
            probe = self.nodes[cursor].left;
        } else {
            probe = self.nodes[cursor].right;
        }
        uint yParent = self.nodes[cursor].parent;
        self.nodes[probe].parent = yParent;
        if (yParent != EMPTY) {
            if (cursor == self.nodes[yParent].left) {
                self.nodes[yParent].left = probe;
            } else {
                self.nodes[yParent].right = probe;
            }
        } else {
            self.root = probe;
        }
        bool doFixup = !self.nodes[cursor].red;
        if (cursor != key) {
            replaceParent(self, cursor, key);
            self.nodes[cursor].left = self.nodes[key].left;
            self.nodes[self.nodes[cursor].left].parent = cursor;
            self.nodes[cursor].right = self.nodes[key].right;
            self.nodes[self.nodes[cursor].right].parent = cursor;
            self.nodes[cursor].red = self.nodes[key].red;
            (cursor, key) = (key, cursor);
        }
        if (doFixup) {
            removeFixup(self, probe);
        }
        delete self.nodes[cursor];
    }

    function treeMinimum(Tree storage self, uint key) private view returns (uint) {
        while (self.nodes[key].left != EMPTY) {
            key = self.nodes[key].left;
        }
        return key;
    }
    function treeMaximum(Tree storage self, uint key) private view returns (uint) {
        while (self.nodes[key].right != EMPTY) {
            key = self.nodes[key].right;
        }
        return key;
    }

    function rotateLeft(Tree storage self, uint key) private {
        uint cursor = self.nodes[key].right;
        uint keyParent = self.nodes[key].parent;
        uint cursorLeft = self.nodes[cursor].left;
        self.nodes[key].right = cursorLeft;
        if (cursorLeft != EMPTY) {
            self.nodes[cursorLeft].parent = key;
        }
        self.nodes[cursor].parent = keyParent;
        if (keyParent == EMPTY) {
            self.root = cursor;
        } else if (key == self.nodes[keyParent].left) {
            self.nodes[keyParent].left = cursor;
        } else {
            self.nodes[keyParent].right = cursor;
        }
        self.nodes[cursor].left = key;
        self.nodes[key].parent = cursor;
    }
    function rotateRight(Tree storage self, uint key) private {
        uint cursor = self.nodes[key].left;
        uint keyParent = self.nodes[key].parent;
        uint cursorRight = self.nodes[cursor].right;
        self.nodes[key].left = cursorRight;
        if (cursorRight != EMPTY) {
            self.nodes[cursorRight].parent = key;
        }
        self.nodes[cursor].parent = keyParent;
        if (keyParent == EMPTY) {
            self.root = cursor;
        } else if (key == self.nodes[keyParent].right) {
            self.nodes[keyParent].right = cursor;
        } else {
            self.nodes[keyParent].left = cursor;
        }
        self.nodes[cursor].right = key;
        self.nodes[key].parent = cursor;
    }

    function insertFixup(Tree storage self, uint key) private {
        uint cursor;
        while (key != self.root && self.nodes[self.nodes[key].parent].red) {
            uint keyParent = self.nodes[key].parent;
            if (keyParent == self.nodes[self.nodes[keyParent].parent].left) {
                cursor = self.nodes[self.nodes[keyParent].parent].right;
                if (self.nodes[cursor].red) {
                    self.nodes[keyParent].red = false;
                    self.nodes[cursor].red = false;
                    self.nodes[self.nodes[keyParent].parent].red = true;
                    key = self.nodes[keyParent].parent;
                } else {
                    if (key == self.nodes[keyParent].right) {
                      key = keyParent;
                      rotateLeft(self, key);
                    }
                    keyParent = self.nodes[key].parent;
                    self.nodes[keyParent].red = false;
                    self.nodes[self.nodes[keyParent].parent].red = true;
                    rotateRight(self, self.nodes[keyParent].parent);
                }
            } else {
                cursor = self.nodes[self.nodes[keyParent].parent].left;
                if (self.nodes[cursor].red) {
                    self.nodes[keyParent].red = false;
                    self.nodes[cursor].red = false;
                    self.nodes[self.nodes[keyParent].parent].red = true;
                    key = self.nodes[keyParent].parent;
                } else {
                    if (key == self.nodes[keyParent].left) {
                      key = keyParent;
                      rotateRight(self, key);
                    }
                    keyParent = self.nodes[key].parent;
                    self.nodes[keyParent].red = false;
                    self.nodes[self.nodes[keyParent].parent].red = true;
                    rotateLeft(self, self.nodes[keyParent].parent);
                }
            }
        }
        self.nodes[self.root].red = false;
    }

    function replaceParent(Tree storage self, uint a, uint b) private {
        uint bParent = self.nodes[b].parent;
        self.nodes[a].parent = bParent;
        if (bParent == EMPTY) {
            self.root = a;
        } else {
            if (b == self.nodes[bParent].left) {
                self.nodes[bParent].left = a;
            } else {
                self.nodes[bParent].right = a;
            }
        }
    }
    function removeFixup(Tree storage self, uint key) private {
        uint cursor;
        while (key != self.root && !self.nodes[key].red) {
            uint keyParent = self.nodes[key].parent;
            if (key == self.nodes[keyParent].left) {
                cursor = self.nodes[keyParent].right;
                if (self.nodes[cursor].red) {
                    self.nodes[cursor].red = false;
                    self.nodes[keyParent].red = true;
                    rotateLeft(self, keyParent);
                    cursor = self.nodes[keyParent].right;
                }
                if (!self.nodes[self.nodes[cursor].left].red && !self.nodes[self.nodes[cursor].right].red) {
                    self.nodes[cursor].red = true;
                    key = keyParent;
                } else {
                    if (!self.nodes[self.nodes[cursor].right].red) {
                        self.nodes[self.nodes[cursor].left].red = false;
                        self.nodes[cursor].red = true;
                        rotateRight(self, cursor);
                        cursor = self.nodes[keyParent].right;
                    }
                    self.nodes[cursor].red = self.nodes[keyParent].red;
                    self.nodes[keyParent].red = false;
                    self.nodes[self.nodes[cursor].right].red = false;
                    rotateLeft(self, keyParent);
                    key = self.root;
                }
            } else {
                cursor = self.nodes[keyParent].left;
                if (self.nodes[cursor].red) {
                    self.nodes[cursor].red = false;
                    self.nodes[keyParent].red = true;
                    rotateRight(self, keyParent);
                    cursor = self.nodes[keyParent].left;
                }
                if (!self.nodes[self.nodes[cursor].right].red && !self.nodes[self.nodes[cursor].left].red) {
                    self.nodes[cursor].red = true;
                    key = keyParent;
                } else {
                    if (!self.nodes[self.nodes[cursor].left].red) {
                        self.nodes[self.nodes[cursor].right].red = false;
                        self.nodes[cursor].red = true;
                        rotateLeft(self, cursor);
                        cursor = self.nodes[keyParent].left;
                    }
                    self.nodes[cursor].red = self.nodes[keyParent].red;
                    self.nodes[keyParent].red = false;
                    self.nodes[self.nodes[cursor].left].red = false;
                    rotateRight(self, keyParent);
                    key = self.root;
                }
            }
        }
        self.nodes[key].red = false;
    }
}
// ----------------------------------------------------------------------------
// End - BokkyPooBah's Red-Black Tree Library
// ----------------------------------------------------------------------------

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
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.21;

/**
 * @title DGDataTypes
 * @author DG Technical Team
 * @notice Library containing DG contracts' custom data types
 */
library DGDataTypes {
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

    /// @dev Enum that holds the status of the game
    enum GameIs {
        WAITING,
        STARTED,
        ENDED
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