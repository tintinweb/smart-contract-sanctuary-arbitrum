// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (access/Ownable.sol)

pragma solidity ^0.8.0;

import "../utils/Context.sol";

/**
 * @dev Contract module which provides a basic access control mechanism, where
 * there is an account (an owner) that can be granted exclusive access to
 * specific functions.
 *
 * By default, the owner account will be the one that deploys the contract. This
 * can later be changed with {transferOwnership}.
 *
 * This module is used through inheritance. It will make available the modifier
 * `onlyOwner`, which can be applied to your functions to restrict their use to
 * the owner.
 */
abstract contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor() {
        _transferOwnership(_msgSender());
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        _checkOwner();
        _;
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if the sender is not the owner.
     */
    function _checkOwner() internal view virtual {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
    }

    /**
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions anymore. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby removing any functionality that is only available to the owner.
     */
    function renounceOwnership() public virtual onlyOwner {
        _transferOwnership(address(0));
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _transferOwnership(newOwner);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Internal function without access restriction.
     */
    function _transferOwnership(address newOwner) internal virtual {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.8.0) (security/ReentrancyGuard.sol)

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
        _nonReentrantBefore();
        _;
        _nonReentrantAfter();
    }

    function _nonReentrantBefore() private {
        // On the first call to nonReentrant, _status will be _NOT_ENTERED
        require(_status != _ENTERED, "ReentrancyGuard: reentrant call");

        // Any calls to nonReentrant after this point will fail
        _status = _ENTERED;
    }

    function _nonReentrantAfter() private {
        // By storing the original value once again, a refund is triggered (see
        // https://eips.ethereum.org/EIPS/eip-2200)
        _status = _NOT_ENTERED;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/Context.sol)

pragma solidity ^0.8.0;

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
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.16;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

interface IEtherWars1v1Vrf {
    function requestRandomWords(
        uint256 _wager,
        address _attacker,
        address _defender
    ) external returns (uint256 requestId);
}

interface INameRegistry {
    enum Faction {
        None,
        Human,
        Troll,
        Goblin
    }

    function namingEnabled() external view returns (bool);

    function registerProfile(address user, string memory name, Faction faction) external returns (bool);

    function getUserProfile(address _user) external view returns (string memory name, Faction faction);
}

interface ISpinToWin {
    function addSpinPoints(
        address _winner,
        uint256 _spinCountWinner,
        address _loser,
        uint256 _spinCountLoser
    ) external;
}

contract EtherWars1v1 is Ownable, ReentrancyGuard {
    uint256 private tester1;

    IEtherWars1v1Vrf public vrfConsumer;
    INameRegistry public nameRegistry;

    ISpinToWin public spinToWinContract;

    uint256 public devFeePercentage = 5;
    uint256 public currentDevFees;
    uint256 public spinCountWinner = 5;
    uint256 public spinCountLoser = 3;
    uint256[] public wagerAmounts;

    mapping(uint256 => address) public list;
    mapping(address => uint256) public contenderCooldown;
    mapping(address => mapping(uint256 => bool)) public hasJoinedGame;
    mapping(address => uint256) public lifetimeEthWagered;

    bool public isOnline = false;

    event NewContender(
        address indexed contender,
        string username,
        INameRegistry.Faction faction,
        uint256 indexed wager
    );
    event Attack(
        uint256 indexed wager,
        address indexed attacker,
        string username,
        INameRegistry.Faction faction,
        address indexed defender
    );
    event CombatResults(
        address indexed attacker,
        address indexed defender,
        uint256 randomOutcome,
        uint256 wager
    );
    event OwnerWithdrawal(uint256 currentDevFees);
    event DevFeeSet(uint256 fee);
    event SpinPointsSet(uint256 winner, uint256 loser);
    event NewVRFConsumer(address vrfConsumer);
    event NewSpinToWinContract(address newAddress);
    event EtherWars1v1Online();
    event EtherWars1v1Offline();
    event WagerAmountsSet(uint256[] wagerAmounts);
    event PlayerExit(address contender, uint256 wager);

    error InvalidWager();
    error AttackerIsDefender();
    error AlreadyInArena();
    error NotVRFConsumer();
    error ArenaOffline();
    error SendEthFailed(uint256 amount);
    error EmptyList();
    error ZeroWagerAmount();
    error FullArena();
    error EmptyName();
    error NotInGame(address contender, uint256 wager);
    error NotEnoughFunds();

    constructor(address _nameRegistry) {
        require(_nameRegistry != address(0), "Address 0");
        nameRegistry = INameRegistry(_nameRegistry);
    }

    modifier onlyVRFConsumer() {
        if (IEtherWars1v1Vrf(msg.sender) != vrfConsumer) revert NotVRFConsumer();
        _;
    }

    modifier checkArena() {
        if (!isOnline) revert ArenaOffline();
        _;
    }

    function enterArena(
        string calldata _username,
        INameRegistry.Faction _faction,
        uint256 _wagerIndex
    ) external payable checkArena {
        uint256 wager = wagerAmounts[_wagerIndex];
        if (msg.value != wager) revert InvalidWager();

        address contender = msg.sender;
        bool contenderStatus = hasJoinedGame[contender][wager];

        address listDefender = list[wager];
        if (listDefender == contender || contenderStatus) revert AlreadyInArena();
        if (listDefender != address(0) && listDefender != contender) revert FullArena();

        if (nameRegistry.namingEnabled()) {
            if (bytes(_username).length == 0) revert EmptyName();

            (string memory registeredName, ) = nameRegistry.getUserProfile(contender);

            // Check if user has not registered before, or if they have, that the name is different
            if (keccak256(bytes(registeredName)) != keccak256(bytes(_username))) {
                nameRegistry.registerProfile(contender, _username, _faction);
            }
        }

        hasJoinedGame[contender][wager] = true;
        list[wager] = contender;
        lifetimeEthWagered[contender] += msg.value;

        emit NewContender(contender, _username, _faction, wager);
    }

    function attack(
        string calldata _username,
        INameRegistry.Faction _faction,
        uint256 _wagerIndex
    ) external payable nonReentrant checkArena {
        uint256 wager = wagerAmounts[_wagerIndex];
        if (msg.value != wager) revert InvalidWager();
        if (list[wager] == address(0)) revert EmptyList();

        address attacker = msg.sender;
        address defender = list[wager];

        if (attacker == defender) revert AttackerIsDefender();

        if (nameRegistry.namingEnabled()) {
            if (bytes(_username).length == 0) revert EmptyName();

            (string memory registeredName, ) = nameRegistry.getUserProfile(attacker);

            // Check if user has not registered before, or if they have, that the name is different
            if (keccak256(bytes(registeredName)) != keccak256(bytes(_username))) {
                nameRegistry.registerProfile(attacker, _username, _faction);
            }
        }

        vrfConsumer.requestRandomWords(wager, attacker, defender);
        emit Attack(wager, attacker, _username, _faction, defender);
    }

    function beginCombat(
        address _attacker,
        address _defender,
        uint256 _wager,
        uint256[] calldata _randomWords
    ) external onlyVRFConsumer nonReentrant {
        delete list[_wager];
        delete hasJoinedGame[_defender][_wager];
        uint256 randomOutcome;

        // Transform the result to a number between 1 and 2 inclusively to determine the winner
        randomOutcome = (_randomWords[0] % 2) + 1;

        if (_attacker == _defender) revert AttackerIsDefender();

        uint256 devFee = ((_wager * 2) * devFeePercentage) / 100;
        uint256 prize = (_wager * 2) - devFee;

        // If the attacker wins
        if (randomOutcome == 1) {
            spinToWinContract.addSpinPoints(_attacker, spinCountWinner, _defender, spinCountLoser);
            sendViaCall(payable(_attacker), prize);
        } else {
            // If the defender wins
            spinToWinContract.addSpinPoints(_defender, spinCountWinner, _attacker, spinCountLoser);
            sendViaCall(payable(_defender), prize);
        }

        currentDevFees += devFee;

        emit CombatResults(_attacker, _defender, randomOutcome, _wager);
    }

    function exitMatch(uint256 _wagerIndex) external nonReentrant {
        uint256 wager = wagerAmounts[_wagerIndex];
        address contender = msg.sender;
        bool contenderStatus = hasJoinedGame[contender][wager];

        if (!contenderStatus) revert NotInGame(contender, wager);
        if (list[wager] == address(0)) revert EmptyList();
        if (address(this).balance < wager) revert NotEnoughFunds();

        delete list[wager];
        delete hasJoinedGame[contender][wager];
        sendViaCall(payable(contender), wager);

        emit PlayerExit(contender, wager);
    }

    function ownerWithdrawFees() external onlyOwner {
        uint256 amount = currentDevFees;
        currentDevFees = 0;
        sendViaCall(payable(owner()), amount);
        emit OwnerWithdrawal(amount);
    }

    function setWagerAmounts(uint256[] calldata _wagerAmounts) external onlyOwner {
        for (uint i = 0; i < _wagerAmounts.length; i++) {
            if (_wagerAmounts[i] == 0) revert ZeroWagerAmount();
        }

        wagerAmounts = _wagerAmounts;
        emit WagerAmountsSet(_wagerAmounts);
    }

    function setDevFee(uint256 _devFee) external onlyOwner {
        require(_devFee <= 10, "Too high");
        devFeePercentage = _devFee;
        emit DevFeeSet(_devFee);
    }

    function setVRFConsumer(address _vrfConsumer) external onlyOwner {
        require(_vrfConsumer != address(0), "Address 0");
        vrfConsumer = IEtherWars1v1Vrf(_vrfConsumer);
        emit NewVRFConsumer(_vrfConsumer);
    }

    function setSpinToWinContract(address _address) external onlyOwner {
        require(_address != address(0), "Address 0");
        spinToWinContract = ISpinToWin(_address);
        emit NewSpinToWinContract(_address);
    }

    function enableArena() external onlyOwner {
        isOnline = true;
        emit EtherWars1v1Online();
    }

    function disableArena() external onlyOwner {
        isOnline = false;
        emit EtherWars1v1Offline();
    }

    function setSpinPoints(uint256 _winner, uint256 _loser) external onlyOwner {
        spinCountWinner = _winner;
        spinCountLoser = _loser;
        emit SpinPointsSet(_winner, _loser);
    }

    function sendViaCall(address payable _to, uint256 _amount) private {
        (bool sent, ) = _to.call{ value: _amount }("");
        if (!sent) revert SendEthFailed(_amount);
    }
}