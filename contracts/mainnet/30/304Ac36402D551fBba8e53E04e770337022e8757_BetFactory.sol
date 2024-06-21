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
import {BetFactory} from "./BetFactory.sol";

contract Bet {
    // -> Type declarations
    enum Status {
        Pending,
        Declined,
        Accepted,
        Settled
    }

    // -> State variables
    uint256 private immutable _BET_ID;
    address private immutable _CREATOR;
    address private immutable _PARTICIPANT;
    uint256 private immutable _AMOUNT;
    IERC20 private immutable _TOKEN;
    string private _MESSAGE;
    address private immutable _ARBITRATOR;
    uint256 private immutable _VALID_UNTIL;
    BetFactory private immutable _BET_FACTORY;

    Status private _status = Status.Pending;
    bool private _fundsWithdrawn = false;
    address public winner;

    // -> Events
    event BetAccepted(address indexed factoryContract);
    event BetDeclined(address indexed factoryContract);
    event BetSettled(address indexed factoryContract, address indexed winner);

    // -> Errors
    error BET__Unauthorized();
    error BET__Expired();
    error BET__InvalidStatus();
    error BET__FailedTransfer();
    error BET__FailedEthTransfer();
    error BET__FundsAlreadyWithdrawn();
    error BET__BadInput();
    error BET__FeeNotEnough();

    // -> Modifiers
    modifier onlyCreator() {
        if (msg.sender != _CREATOR) revert BET__Unauthorized();
        _;
    }

    modifier onlyParticipant() {
        if (msg.sender != _PARTICIPANT) revert BET__Unauthorized();
        _;
    }

    modifier onlyArbitrator() {
        if (msg.sender != _ARBITRATOR) revert BET__Unauthorized();
        _;
    }

    // -> Functions
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
        _BET_ID = _betId;
        _CREATOR = _creator;
        _PARTICIPANT = _participant;
        _AMOUNT = _amount;
        _TOKEN = IERC20(_token);
        _MESSAGE = _message;
        _ARBITRATOR = _arbitrator;
        _VALID_UNTIL = block.timestamp + _validFor;
        _BET_FACTORY = BetFactory(_factoryContract);
    }

    function acceptBet() public payable onlyParticipant {
        if (msg.value < _BET_FACTORY.fee()) revert BET__FeeNotEnough();
        if (_isExpired()) revert BET__Expired();
        if (_status != Status.Pending) revert BET__InvalidStatus();

        // Transfer tokens to contract
        bool success = _TOKEN.transferFrom(msg.sender, address(this), _AMOUNT);
        if (!success) revert BET__FailedTransfer();

        // Send fee to factory contract owner
        (bool feeSuccess, ) = payable(_BET_FACTORY.owner()).call{
            value: msg.value
        }("");
        if (!feeSuccess) revert BET__FailedEthTransfer();

        // Update state variables
        _status = Status.Accepted;
        // Emit event
        emit BetAccepted(address(_BET_FACTORY));
    }

    function declineBet() public onlyParticipant {
        if (_isExpired()) revert BET__Expired();
        if (_status != Status.Pending) revert BET__InvalidStatus();

        // Return tokens to original party
        bool success = _TOKEN.transfer(_CREATOR, _AMOUNT);
        if (!success) revert BET__FailedTransfer();

        // Update state variables
        _status = Status.Declined;
        // Emit event
        emit BetDeclined(address(_BET_FACTORY));
    }

    function retrieveTokens() public onlyCreator {
        if (!_isExpired()) revert BET__InvalidStatus();
        if (_fundsWithdrawn) revert BET__FundsAlreadyWithdrawn();

        // Return tokens to bet creator
        bool success = _TOKEN.transfer(_CREATOR, _AMOUNT);
        if (!success) revert BET__FailedTransfer();

        // Update state
        _fundsWithdrawn = true;
    }

    function settleBet(address _winner) public onlyArbitrator {
        if (_status != Status.Accepted) revert BET__InvalidStatus();
        if (
            _winner != _CREATOR &&
            _winner != _PARTICIPANT &&
            _winner != 0x0000000000000000000000000000000000000000
        ) revert BET__BadInput();

        // Transfer tokens to winner
        if (_winner == 0x0000000000000000000000000000000000000000) {
            // In tie event, the funds are returned
            bool success1 = _TOKEN.transfer(_CREATOR, _AMOUNT);
            bool success2 = _TOKEN.transfer(_PARTICIPANT, _AMOUNT);
            if (!success1 || !success2) revert BET__FailedTransfer();
        } else {
            // In winning event, all funds are transfered to the winner
            bool success = _TOKEN.transfer(_winner, _AMOUNT * 2);
            if (!success) revert BET__FailedTransfer();
        }

        // Update state variables
        _status = Status.Settled;
        winner = _winner;
        // Emit event
        emit BetSettled(address(_BET_FACTORY), _winner);
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
            _BET_ID,
            _CREATOR,
            _PARTICIPANT,
            _AMOUNT,
            _TOKEN,
            _MESSAGE,
            _ARBITRATOR,
            _VALID_UNTIL
        );
    }

    function getStatus() public view returns (string memory) {
        if (_isExpired()) {
            return "expired";
        } else if (_status == Status.Pending) {
            return "pending";
        } else if (_status == Status.Declined) {
            return "declined";
        } else if (_status == Status.Accepted) {
            return "accepted";
        } else {
            return "settled";
        }
    }

    function _isExpired() private view returns (bool) {
        return block.timestamp >= _VALID_UNTIL && _status == Status.Pending;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {Bet} from "contracts/Bet.sol";

contract BetFactory {
    // -> Type declarations
    struct BetInfo {
        uint256 betId;
        address contractAddress;
        bool isCreator;
        bool isParticipant;
        bool isArbitrator;
    }

    // -> State variables
    address public owner;
    uint256 public fee;
    uint256 public betCount = 0;
    mapping(uint256 _betId => address contractAddress) public betAddresses;
    mapping(address _contractAddress => uint256 betId) public betIds;
    mapping(address _userAddress => BetInfo[] betInfo) public userBets;

    // -> Events
    event BetCreated(
        address indexed contractAddress,
        address indexed creator,
        address participant,
        uint256 indexed amount
    );

    // -> Errors
    error BET__Unauthorized();
    error BET__FeeNotEnough();
    error BET__FailedTokenTransfer();
    error BET__FailedEthTransfer();
    error BET__BadInput();

    // -> Modifiers
    modifier onlyOwner() {
        if (owner != msg.sender) revert BET__Unauthorized();
        _;
    }

    // -> Functions
    constructor(uint256 _initialFee) {
        owner = msg.sender;
        fee = _initialFee;
    }

    function transferOwnership(address _newOwner) public virtual onlyOwner {
        owner = _newOwner;
    }

    function changeFee(uint256 _newFee) public virtual onlyOwner {
        fee = _newFee;
    }

    function createBet(
        address _participant,
        uint256 _amount,
        address _token,
        string memory _message,
        address _arbitrator,
        uint256 _validFor
    ) public payable {
        if (msg.value < fee) revert BET__FeeNotEnough();
        if (msg.sender == _participant) revert BET__BadInput();
        if (_amount <= 0) revert BET__BadInput();
        if (_validFor < 3600) revert("Bet must be valid for at least 1 hour");

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
            bool tokenSuccess = IERC20(_token).transferFrom(
                msg.sender,
                address(newBet),
                _amount
            );
            if (!tokenSuccess) revert BET__FailedTokenTransfer();

            // Send fee to owner
            (bool feeSuccess, ) = payable(owner).call{value: msg.value}("");
            if (!feeSuccess) revert BET__FailedEthTransfer();

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

    function userBetCount(address _userAddress) public view returns (uint256) {
        return userBets[_userAddress].length;
    }
}