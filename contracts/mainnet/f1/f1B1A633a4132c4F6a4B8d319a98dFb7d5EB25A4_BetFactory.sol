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
pragma solidity ^0.8.24;

import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

error Unauthorized();
error Expired();
error InvalidStatus();
error FailedTransfer();
error FundsAlreadyWithdrawn();
error BadInput();

contract Bet {
    uint256 private immutable BET_ID;
    address private immutable CREATOR;
    address private immutable PARTICIPANT;
    uint256 private immutable AMOUNT;
    IERC20 private immutable TOKEN;
    string private MESSAGE;
    address private immutable ARBITRATOR;
    uint256 private immutable VALID_UNTIL;
    address private immutable FACTORY_CONTRACT;

    enum Status {
        Pending,
        Declined,
        Accepted,
        Settled
    }
    Status private status = Status.Pending;

    bool private fundsWithdrawn = false;
    address public winner;

    constructor(
        uint256 _betId,
        address _creator,
        address _participant,
        uint256 _amount,
        address _token,
        string memory _message,
        address _arbitrator,
        uint256 _validFor,
        address _factoryContract
    ) {
        BET_ID = _betId;
        CREATOR = _creator;
        PARTICIPANT = _participant;
        AMOUNT = _amount;
        TOKEN = IERC20(_token);
        MESSAGE = _message;
        ARBITRATOR = _arbitrator;
        VALID_UNTIL = block.timestamp + _validFor;
        FACTORY_CONTRACT = _factoryContract;
    }

    event BetAccepted(address indexed factoryContract);
    event BetDeclined(address indexed factoryContract);
    event BetSettled(address indexed factoryContract, address indexed winner);

    modifier onlyCreator() {
        if (msg.sender != CREATOR) revert Unauthorized();
        _;
    }
    modifier onlyParticipant() {
        if (msg.sender != PARTICIPANT) revert Unauthorized();
        _;
    }
    modifier onlyArbitrator() {
        if (msg.sender != ARBITRATOR) revert Unauthorized();
        _;
    }

    function betDetails()
        public
        view
        returns (
            uint256 betId,
            address creator,
            address participant,
            uint256 amount,
            IERC20 token,
            string memory message,
            address arbitrator,
            uint256 validUntil
        )
    {
        return (
            BET_ID,
            CREATOR,
            PARTICIPANT,
            AMOUNT,
            TOKEN,
            MESSAGE,
            ARBITRATOR,
            VALID_UNTIL
        );
    }
    function isExpired() private view returns (bool) {
        return block.timestamp >= VALID_UNTIL && status == Status.Pending;
    }
    function getStatus() public view returns (string memory) {
        if (isExpired()) {
            return "expired";
        } else if (status == Status.Pending) {
            return "pending";
        } else if (status == Status.Declined) {
            return "declined";
        } else if (status == Status.Accepted) {
            return "accepted";
        } else {
            return "settled";
        }
    }

    function acceptBet() public onlyParticipant {
        if (isExpired()) revert Expired();
        if (status != Status.Pending) revert InvalidStatus();

        // Transfer tokens to contract
        bool success = TOKEN.transferFrom(msg.sender, address(this), AMOUNT);
        if (!success) revert FailedTransfer();

        // Update state variables
        status = Status.Accepted;
        // Emit event
        emit BetAccepted(FACTORY_CONTRACT);
    }

    function declineBet() public onlyParticipant {
        if (isExpired()) revert Expired();
        if (status != Status.Pending) revert InvalidStatus();

        // Return tokens to original party
        bool success = TOKEN.transfer(CREATOR, AMOUNT);
        if (!success) revert FailedTransfer();

        // Update state variables
        status = Status.Declined;
        // Emit event
        emit BetDeclined(FACTORY_CONTRACT);
    }

    function retrieveTokens() public onlyCreator {
        if (!isExpired()) revert Unauthorized();
        if (fundsWithdrawn) revert FundsAlreadyWithdrawn();

        // Return tokens to bet creator
        bool success = TOKEN.transfer(CREATOR, AMOUNT);
        if (!success) revert FailedTransfer();

        // Update state
        fundsWithdrawn = true;
    }

    function settleBet(address _winner) public onlyArbitrator {
        if (status != Status.Accepted) revert InvalidStatus();
        if (
            _winner != CREATOR &&
            _winner != PARTICIPANT &&
            _winner != 0x0000000000000000000000000000000000000000
        ) revert BadInput();

        // Transfer tokens to winner
        if (_winner == 0x0000000000000000000000000000000000000000) {
            // In tie event, the funds are returned
            bool success1 = TOKEN.transfer(CREATOR, AMOUNT);
            if (!success1) {
                revert FailedTransfer();
            }
            bool success2 = TOKEN.transfer(PARTICIPANT, AMOUNT);
            if (!success2) {
                revert FailedTransfer();
            }
        } else {
            // In winning event, all funds are transfered to the winner
            bool success = TOKEN.transfer(_winner, AMOUNT * 2);
            if (!success) {
                revert FailedTransfer();
            }
        }

        // Update state variables
        status = Status.Settled;
        winner = _winner;
        // Emit event
        emit BetSettled(FACTORY_CONTRACT, _winner);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {Bet} from "contracts/Bet.sol";

contract BetFactory {
    uint256 public betCount = 0;
    // bet id -> contract address
    mapping(uint256 _betId => address contractAddress) public betAddresses;
    // contract address -> bet id
    mapping(address _contractAddress => uint256 betId) public betIds;
    // user address -> bet
    struct BetInfo {
        uint256 betId;
        address contractAddress;
        bool isCreator;
        bool isParticipant;
        bool isArbitrator;
    }
    mapping(address _userAddress => BetInfo[] betInfo) public userBets;

    function userBetCount(address _userAddress) public view returns (uint256) {
        return userBets[_userAddress].length;
    }

    constructor() {}

    event BetCreated(
        address indexed contractAddress,
        address indexed creator,
        address participant,
        uint256 indexed amount
    );

    function createBet(
        address _participant,
        uint256 _amount,
        address _token,
        string memory _message,
        address _arbitrator,
        uint256 _validFor
    ) public {
        require(msg.sender != _participant, "Cannot bet against yourself");
        require(_amount > 0, "Bet amount must be greater than 0");
        require(_validFor >= 3600, "Bet must be valid for at least 1 hour");
        require(
            _amount <= IERC20(_token).allowance(msg.sender, address(this)),
            "Must give approval to send tokens"
        );

        try
            new Bet(
                betCount + 1,
                msg.sender,
                _participant,
                _amount,
                _token,
                _message,
                _arbitrator,
                _validFor,
                address(this)
            )
        returns (Bet newBet) {
            // Transfer tokens to new contract
            bool success = IERC20(_token).transferFrom(
                msg.sender,
                address(newBet),
                _amount
            );
            require(success, "Token transfer failed");
            // Update state variables
            betCount++;
            betAddresses[betCount] = address(newBet);
            betIds[address(newBet)] = betCount;
            userBets[msg.sender].push(
                BetInfo(
                    betCount,
                    address(newBet),
                    true,
                    false,
                    msg.sender == _arbitrator
                )
            );
            userBets[_participant].push(
                BetInfo(
                    betCount,
                    address(newBet),
                    false,
                    true,
                    _participant == _arbitrator
                )
            );
            if (_arbitrator != msg.sender && _arbitrator != _participant)
                userBets[_arbitrator].push(
                    BetInfo(betCount, address(newBet), false, false, true)
                );
            // Emit event
            emit BetCreated(address(newBet), msg.sender, _participant, _amount);
        } catch {
            revert("Deployment or token transfer failed");
        }
    }
}