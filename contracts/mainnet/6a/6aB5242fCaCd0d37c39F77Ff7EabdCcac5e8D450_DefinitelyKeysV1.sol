// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v5.0.0) (access/Ownable.sol)

pragma solidity ^0.8.20;

import {Context} from "../utils/Context.sol";

/**
 * @dev Contract module which provides a basic access control mechanism, where
 * there is an account (an owner) that can be granted exclusive access to
 * specific functions.
 *
 * The initial owner is set to the address provided by the deployer. This can
 * later be changed with {transferOwnership}.
 *
 * This module is used through inheritance. It will make available the modifier
 * `onlyOwner`, which can be applied to your functions to restrict their use to
 * the owner.
 */
abstract contract Ownable is Context {
    address private _owner;

    /**
     * @dev The caller account is not authorized to perform an operation.
     */
    error OwnableUnauthorizedAccount(address account);

    /**
     * @dev The owner is not a valid owner account. (eg. `address(0)`)
     */
    error OwnableInvalidOwner(address owner);

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the address provided by the deployer as the initial owner.
     */
    constructor(address initialOwner) {
        if (initialOwner == address(0)) {
            revert OwnableInvalidOwner(address(0));
        }
        _transferOwnership(initialOwner);
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
        if (owner() != _msgSender()) {
            revert OwnableUnauthorizedAccount(_msgSender());
        }
    }

    /**
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby disabling any functionality that is only available to the owner.
     */
    function renounceOwnership() public virtual onlyOwner {
        _transferOwnership(address(0));
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        if (newOwner == address(0)) {
            revert OwnableInvalidOwner(address(0));
        }
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
// OpenZeppelin Contracts (last updated v4.9.0) (security/ReentrancyGuard.sol)

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

    /**
     * @dev Returns true if the reentrancy guard is currently set to "entered", which indicates there is a
     * `nonReentrant` function in the call stack.
     */
    function _reentrancyGuardEntered() internal view returns (bool) {
        return _status == _ENTERED;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v5.0.0) (utils/Context.sol)

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
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

contract DefinitelyKeysV1 is Ownable, ReentrancyGuard  {

    constructor() Ownable(msg.sender) {
        bytes32 initialInviteCode = keccak256(abi.encodePacked("DEFINITELY"));
        referralOwners[initialInviteCode] = msg.sender;
        protocolFeeDestination = msg.sender;
        protocolFeePercent =  0.05 ether;
        subjectFeePercent =  0.05 ether;
        referralFeePercent =  0.01 ether;
        subjectCreationFee = 0.002 ether;
    }

    address public protocolFeeDestination;
    uint256 public protocolFeePercent;
    uint256 public subjectFeePercent;
    uint256 public referralFeePercent;
    uint256 public subjectCreationFee;
    bool public transferEnabled = false;

    event Trade(address trader, address subject, bool isBuy, uint256 keyAmount, uint256 ethAmount, uint256 balance, uint256 supply);
    event Transfer(address from, address to, uint256 amount, address subject);

    mapping(address => mapping(address => uint256)) public keysBalance;
    mapping(address => uint256) public keysSupply;
    mapping(bytes32 => address) public referralOwners;
    mapping(address => bytes32) public subjectReferralTargets;

    function setFeeDestination(address _feeDestination) public onlyOwner {
        protocolFeeDestination = _feeDestination;
    }

    function setProtocolFeePercent(uint256 _feePercent) public onlyOwner {
        protocolFeePercent = _feePercent;
    }

    function setSubjectFeePercent(uint256 _feePercent) public onlyOwner {
        subjectFeePercent = _feePercent;
    }

    function setReferralFeePercent(uint256 _feePercent) public onlyOwner {
        referralFeePercent = _feePercent;
    }

    function setSubjectCreationFeet(uint256 _fee) public onlyOwner {
        subjectCreationFee = _fee;
    }

    function setTransferEnabled() public onlyOwner {
        transferEnabled = true;
    }

    function createSubject(bytes32 inviteCode, bytes32 myInviteCode) public payable nonReentrant {
        require(msg.value >= subjectCreationFee, "DefinitelyKeysV1: createSubject: insufficient funds");
        require(keysSupply[msg.sender] == 0, "DefinitelyKeysV1: createSubject: keysSubject already exists");
        require(referralOwners[myInviteCode] == address(0), "DefinitelyKeysV1: createSubject: invite code already set");
        referralOwners[myInviteCode] = msg.sender;
        require(referralOwners[inviteCode] != address(0), "DefinitelyKeysV1: createSubject: invalid invite code");
        subjectReferralTargets[msg.sender] = inviteCode;
        keysSupply[msg.sender] = 100;
        keysBalance[msg.sender][msg.sender] = 100;
         if(msg.value > subjectCreationFee) {
            uint256 refundAmount = msg.value - subjectCreationFee;
            (bool refundSuccess,) = msg.sender.call{value: refundAmount}("");
            require(refundSuccess, "DefinitelyKeysV1: createSubject: Refund failed");
        }
        emit Trade(msg.sender, referralOwners[inviteCode], true, 100, 0, 100, 100);
        (bool success, ) = protocolFeeDestination.call{value: subjectCreationFee}(""); //account opening fee
        require(success, "DefinitelyKeysV1: createSubject: account creation failed");
    }

    function getTotalCostForRange(uint256 supply, uint256 amount) public pure returns (uint256) {
        uint256 sum1 = (supply - 1 )* (supply) * (2 * (supply - 1) + 1) / 6;
        uint256 sum2 = (supply - 1 + amount) * (supply + amount) * (2 * (supply - 1 + amount) + 1) / 6;
        uint256 summation = sum2 - sum1;
        return summation * 1 ether / 16000000000;
    }

    function buyKeys(address keysSubject, uint256 amount) public payable nonReentrant  {
        require(amount > 0, "DefinitelyKeysV1: buyKeys: 0 amount");
        uint256 supply = keysSupply[keysSubject];
        require(supply >= 100, "DefinitelyKeysV1: subject not found");
        keysSupply[keysSubject] = supply + amount;
        keysBalance[keysSubject][msg.sender] += amount;
        uint256 totalCost = getTotalCostForRange(supply, amount);
        uint256 protocolFee = totalCost * protocolFeePercent / 1 ether;
        uint256 subjectFee = totalCost * subjectFeePercent / 1 ether;
        uint256 referralFee = totalCost * referralFeePercent / 1 ether;
        uint256 totalFees = totalCost + protocolFee + subjectFee + referralFee;
        require(msg.value >= totalFees, "DefinitelyKeysV1: buyKeys: insufficient funds");
        if(msg.value > totalFees) {
            uint256 refundAmount = msg.value - totalFees;
            (bool refundSuccess,) = msg.sender.call{value: refundAmount}("");
            require(refundSuccess, "DefinitelyKeysV1: buyKeys: Refund failed");
        }
        emit Trade(msg.sender, keysSubject, true, amount, totalCost, keysBalance[keysSubject][msg.sender], supply + amount);
        address referralOwner = referralOwners[subjectReferralTargets[keysSubject]];
        (bool success1, ) = protocolFeeDestination.call{value: protocolFee}("");
        (bool success2, ) = keysSubject.call{value: subjectFee}("");
        (bool success3, ) = referralOwner.call{value: referralFee}("");
        require(success1 && success2, "DefinitelyKeysV1: buyKeys: transfer failed");
        if (!success3){
            (bool success4, ) = protocolFeeDestination.call{value: referralFee}("");
            require(success4, "DefinitelyKeysV1: buyKeys: transfer failed");
        }
    }

    function sellKeys(address keysSubject, uint256 amount, uint256 minEthReturn) public nonReentrant {
        require(amount > 0, "DefinitelyKeysV1: sellKeys: 0 amount");
        uint256 supply = keysSupply[keysSubject];
        require(supply - amount >= 100, "DefinitelyKeysV1: sellKeys: last 100 unit cannot be sold");
        require(keysBalance[keysSubject][msg.sender] >= amount, "DefinitelyKeysV1: sellKeys: insufficient keys");
        keysSupply[keysSubject] = supply - amount;
        keysBalance[keysSubject][msg.sender] -= amount;
        uint256 totalCost =  getTotalCostForRange(supply - amount, amount);
        uint256 protocolFee = totalCost * protocolFeePercent / 1 ether;
        uint256 subjectFee = totalCost * subjectFeePercent / 1 ether;
        uint256 referralFee = totalCost * referralFeePercent / 1 ether;
        require(totalCost - protocolFee - subjectFee - referralFee >= minEthReturn, "DefinitelyKeysV1: sellKeys: Slippage too high");
        emit Trade(msg.sender, keysSubject, false, amount, totalCost, keysBalance[keysSubject][msg.sender], supply - amount);
        address referralOwner = referralOwners[subjectReferralTargets[keysSubject]];
        (bool success1,) = msg.sender.call{value: totalCost - protocolFee - subjectFee - referralFee}("");
        (bool success2,) = protocolFeeDestination.call{value: protocolFee}("");
        (bool success3,) = keysSubject.call{value: subjectFee}("");
        (bool success4,) = referralOwner.call{value: referralFee}("");
        require(success1 && success2 && success3, "DefinitelyKeysV1: sellKeys: transfer failed");
        if (!success4){
            (bool success5, ) = protocolFeeDestination.call{value: referralFee}("");
            require(success5, "DefinitelyKeysV1: buyKeys: transfer failed");
        }
    }

    function transferKeys(address keysSubject, address to, uint256 amount) public nonReentrant {
        require(transferEnabled, "DefinitelyKeysV1: transferKeys: transfer is not enabled yet");
        require(keysBalance[keysSubject][msg.sender] >= amount, "DefinitelyKeysV1: transferKeys: insufficient balance");
        require(to != address(0), "DefinitelyKeysV1: transferKeys: transfer to the zero address");
        keysBalance[keysSubject][msg.sender] -= amount;
        keysBalance[keysSubject][to] += amount;
        emit Transfer(msg.sender, to, amount, keysSubject);
    }
}