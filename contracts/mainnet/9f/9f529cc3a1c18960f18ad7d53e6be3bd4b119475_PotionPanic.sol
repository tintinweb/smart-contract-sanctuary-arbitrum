// SPDX-License-Identifier: MIT
//  ______           _                ______             _          _
// (_____ \      _  (_)              (_____ \           (_)        | |
//  _____) )__ _| |_ _  ___  ____     _____) )____ ____  _  ____   | |
// |  ____/ _ (_   _) |/ _ \|  _ \   |  ____(____ |  _ \| |/ ___)  |_|
// | |   | |_| || |_| | |_| | | | |  | |    / ___ | | | | ( (___    _
// |_|    \___/  \__)_|\___/|_| |_|  |_|    \_____|_| |_|_|\____)  |_|
//

pragma solidity >=0.8.0;

import {IERC20} from "openzeppelin/interfaces/IERC20.sol";
import {IFeeCollector} from "interfaces/IFeeCollector.sol";
import {IElixETH} from "interfaces/IElixETH.sol";
import {Operatable} from "mixins/Operatable.sol";
import {IPlayerCard} from "interfaces/IPlayerCard.sol";

/// @title PotionPanic
/// @author 0xCalibur
/// @author Inspired by the Bullet Game Dark Portal Telegram game.
/// @notice Game Mechanism: The winner takes all the bets minus the fee.
contract PotionPanic is Operatable {
    error ErrInvalidFeeBips();
    error ErrInvalidFeeOperator(address);

    error ErrInvalidNumIngredients();
    error ErrProofNotMatching();
    error ErrAlreadyStarted();
    error ErrInvalidNumPlayers();
    error ErrNotStarted();
    error ErrInvalidBetAmount();
    error ErrInvalidWinner();
    error ErrInvalidTipAmount();
    error ErrCannotCoverTransactionFee();
    error ErrInvalidUserdata();
    error ErrUnauthorized();

    event LogStarted(uint256 betAmount, uint8 numIngredients, address[] players, bytes32 commitment);
    event LogEnded(address indexed winner, uint256 rewards, uint256 fee, bytes proof);
    event LogTipped(address indexed from, address indexed to, uint256 amount);
    event LogRegister(address indexed sender, uint256 code);
    event LogAborted();
    event LogFeeParametersChanged(address indexed feeCollector, uint16 feeAmount);
    event LogHardMinBetChanged(uint256 amount);
    event LogAccountCreated(address indexed account, uint256 id);

    IERC20 public immutable token;
    IPlayerCard public immutable card;

    /// -=-=-=-=-=-=--=-=-=-=-=-=--=-=-=-=-=-=--=-=-=-=-=-=--=-=-=-=-=-=-
    /// Global Parameters
    /// -=-=-=-=-=-=--=-=-=-=-=-=--=-=-=-=-=-=--=-=-=-=-=-=--=-=-=-=-=-=-
    uint16 public feeBips;
    address public feeCollector;
    uint256 public hardMinBet;

    /// -=-=-=-=-=-=--=-=-=-=-=-=--=-=-=-=-=-=--=-=-=-=-=-=--=-=-=-=-=-=-
    /// Game State
    /// -=-=-=-=-=-=--=-=-=-=-=-=--=-=-=-=-=-=--=-=-=-=-=-=--=-=-=-=-=-=-
    bool public started;
    uint8 public numIngredients;
    bytes32 public commitment;
    uint256 public bet;
    address[] public players;
    mapping(address user => bool active) public playerMap;

    constructor(IERC20 _token, IPlayerCard _card, address _owner) Operatable(_owner) {
        token = _token;
        card = _card;
    }

    /// @notice Used to get the number of bets.
    function playerLength() public view returns (uint256) {
        return players.length;
    }

    /// @notice Link a player to an address,
    /// optionally mint some ElixETH
    function register(uint256 _code) external payable returns (uint256 id) {
        id = card.idOf(msg.sender);

        if (msg.value > 0) {
            IElixETH(address(token)).depositTo{value: msg.value}(msg.sender);
        }

        // user doesn't have a card, mint one
        if (id == 0) {
            id = card.mint(msg.sender);
            emit LogAccountCreated(msg.sender, id);
        }
        emit LogRegister(msg.sender, _code);
    }

    /// -=-=-=-=-=-=--=-=-=-=-=-=--=-=-=-=-=-=--=-=-=-=-=-=--=-=-=-=-=-=-
    /// Operator functions
    /// -=-=-=-=-=-=--=-=-=-=-=-=--=-=-=-=-=-=--=-=-=-=-=-=--=-=-=-=-=-=-

    /// @notice Starts a game instance, only one can be active at a time.
    /// @param _players The players.
    /// @param _bet The bet amount.
    /// @param _numIngredients The number of ingredients.
    /// @param _commitment The commitment of the game. Hash composed of the random number and the salts.
    /// When the game ends, the random number will be revealed along with the salts to verify the commitment.
    function start(address[] memory _players, uint256 _bet, uint8 _numIngredients, bytes32 _commitment) external onlyOperators {
        if (started) {
            revert ErrAlreadyStarted();
        }
        if (_numIngredients < 2) {
            revert ErrInvalidNumIngredients();
        }
        if (_players.length < 2 || _players.length > _numIngredients) {
            revert ErrInvalidNumPlayers();
        }
        if (_bet < hardMinBet) {
            revert ErrInvalidBetAmount();
        }

        started = true;
        numIngredients = _numIngredients;
        commitment = _commitment;
        bet = _bet;
        players = _players;

        for (uint256 i = 0; i < _players.length; ) {
            if (card.idOf(_players[i]) == 0) {
                revert ErrUnauthorized();
            }

            playerMap[_players[i]] = true;
            token.transferFrom(_players[i], address(this), _bet);

            unchecked {
                ++i;
            }
        }

        emit LogStarted(_bet, _numIngredients, _players, _commitment);
    }

    /// @notice End the game and distribute the rewards from the loser's bet
    /// @param winner The address of the winner.
    /// @param _proof The proof of the commitment, composed of the random number and the salts.
    function end(address winner, bytes memory _proof, bytes[] calldata userdata) external onlyOperators returns (uint256 winnerReward) {
        if (!started) {
            revert ErrNotStarted();
        }
        if (!playerMap[winner]) {
            revert ErrInvalidWinner();
        }
        if (players.length != userdata.length) {
            revert ErrInvalidUserdata();
        }
        if (keccak256(_proof) != commitment) {
            revert ErrProofNotMatching();
        }

        winnerReward = bet * players.length;
        uint256 fee = (winnerReward * feeBips) / 10_000;
        winnerReward -= fee;

        // redistribute the bet amount to the winning players
        for (uint256 i = 0; i < players.length; ) {
            delete playerMap[players[i]];

            // update player's card
            card.updateOwnerData(players[i], userdata[i]);

            unchecked {
                ++i;
            }
        }

        // return winner's reward
        token.transfer(winner, winnerReward);

        IElixETH(address(token)).withdrawTo(feeCollector, fee);
        _resetState();

        emit LogEnded(winner, winnerReward, fee, _proof);
    }

    /// @notice This function is used to abort the game.
    function abort() external onlyOperators {
        if (!started) {
            revert ErrNotStarted();
        }

        // refund users
        for (uint256 i = 0; i < players.length; i++) {
            delete playerMap[players[i]];
            token.transfer(players[i], bet);
        }

        _resetState();
        emit LogAborted();
    }

    /// @notice This function is used to set the minimum bet amount.
    /// @param _hardMinBet The minimum bet amount.
    function setHardMinBet(uint256 _hardMinBet) external onlyOperators {
        hardMinBet = _hardMinBet;
        emit LogHardMinBetChanged(_hardMinBet);
    }

    /// -=-=-=-=-=-=--=-=-=-=-=-=--=-=-=-=-=-=--=-=-=-=-=-=--=-=-=-=-=-=-
    /// Admin functions
    /// -=-=-=-=-=-=--=-=-=-=-=-=--=-=-=-=-=-=--=-=-=-=-=-=--=-=-=-=-=-=-

    /// @notice This function is used to set the fee parameters.
    /// @param _feeCollector The address of the fee collector.
    /// @param _feeBips The fee amount in bips.
    function setFeeParameters(address _feeCollector, uint16 _feeBips) external onlyOwner {
        if (feeBips > 10_000) {
            revert ErrInvalidFeeBips();
        }

        feeCollector = _feeCollector;
        feeBips = _feeBips;

        emit LogFeeParametersChanged(_feeCollector, _feeBips);
    }

    /// -=-=-=-=-=-=--=-=-=-=-=-=--=-=-=-=-=-=--=-=-=-=-=-=--=-=-=-=-=-=-
    /// Private functions
    /// -=-=-=-=-=-=--=-=-=-=-=-=--=-=-=-=-=-=--=-=-=-=-=-=--=-=-=-=-=-=-

    /// @notice This function is used to reset the game state.
    function _resetState() private {
        delete players;
        delete numIngredients;
        delete commitment;
        delete bet;
        started = false;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (interfaces/IERC20.sol)

pragma solidity ^0.8.0;

import "../token/ERC20/IERC20.sol";

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0;

interface IFeeCollector {
    function distribute() external;
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0;

import {IERC20} from "openzeppelin/interfaces/IERC20.sol";

interface IElixETH is IERC20 {
    function deposit() external payable;

    function depositTo(address to) external payable;

    function withdraw(uint256 amount) external;

    function withdrawTo(address to, uint256 amount) external;
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0;

import {Owned} from "solmate/auth/Owned.sol";

contract Operatable is Owned {
    event LogOperatorChanged(address indexed, bool);
    error ErrNotAllowedOperator();

    mapping(address => bool) public operators;

    constructor(address _owner) Owned(_owner) {}

    modifier onlyOperators() {
        if (!operators[msg.sender] && msg.sender != owner) {
            revert ErrNotAllowedOperator();
        }
        _;
    }

    function setOperator(address operator, bool status) external onlyOwner {
        operators[operator] = status;
        emit LogOperatorChanged(operator, status);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0;

interface IPlayerCard {
    function ownerOf(uint256 id) external view returns (address owner);

    function idOf(address owner) external view returns (uint256 id);

    function balanceOf(address _owner) external view returns (uint256);

    function mint() external returns (uint256);

    function mint(address to) external returns (uint256);

    function ownerData(uint256 id) external view returns (bytes memory);

    function updateOwnerData(address owner, bytes memory data) external;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.9.0) (token/ERC20/IERC20.sol)

pragma solidity ^0.8.0;

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
     * @dev Returns the amount of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the amount of tokens owned by `account`.
     */
    function balanceOf(address account) external view returns (uint256);

    /**
     * @dev Moves `amount` tokens from the caller's account to `to`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address to, uint256 amount) external returns (bool);

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
     * @dev Moves `amount` tokens from `from` to `to` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(address from, address to, uint256 amount) external returns (bool);
}

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity >=0.8.0;

/// @notice Simple single owner authorization mixin.
/// @author Solmate (https://github.com/transmissions11/solmate/blob/main/src/auth/Owned.sol)
abstract contract Owned {
    /*//////////////////////////////////////////////////////////////
                                 EVENTS
    //////////////////////////////////////////////////////////////*/

    event OwnershipTransferred(address indexed user, address indexed newOwner);

    /*//////////////////////////////////////////////////////////////
                            OWNERSHIP STORAGE
    //////////////////////////////////////////////////////////////*/

    address public owner;

    modifier onlyOwner() virtual {
        require(msg.sender == owner, "UNAUTHORIZED");

        _;
    }

    /*//////////////////////////////////////////////////////////////
                               CONSTRUCTOR
    //////////////////////////////////////////////////////////////*/

    constructor(address _owner) {
        owner = _owner;

        emit OwnershipTransferred(address(0), _owner);
    }

    /*//////////////////////////////////////////////////////////////
                             OWNERSHIP LOGIC
    //////////////////////////////////////////////////////////////*/

    function transferOwnership(address newOwner) public virtual onlyOwner {
        owner = newOwner;

        emit OwnershipTransferred(msg.sender, newOwner);
    }
}