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
// OpenZeppelin Contracts (last updated v4.8.0) (access/Ownable2Step.sol)

pragma solidity ^0.8.0;

import "./Ownable.sol";

/**
 * @dev Contract module which provides access control mechanism, where
 * there is an account (an owner) that can be granted exclusive access to
 * specific functions.
 *
 * By default, the owner account will be the one that deploys the contract. This
 * can later be changed with {transferOwnership} and {acceptOwnership}.
 *
 * This module is used through inheritance. It will make available all functions
 * from parent (Ownable).
 */
abstract contract Ownable2Step is Ownable {
    address private _pendingOwner;

    event OwnershipTransferStarted(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Returns the address of the pending owner.
     */
    function pendingOwner() public view virtual returns (address) {
        return _pendingOwner;
    }

    /**
     * @dev Starts the ownership transfer of the contract to a new account. Replaces the pending transfer if there is one.
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual override onlyOwner {
        _pendingOwner = newOwner;
        emit OwnershipTransferStarted(owner(), newOwner);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`) and deletes any pending owner.
     * Internal function without access restriction.
     */
    function _transferOwnership(address newOwner) internal virtual override {
        delete _pendingOwner;
        super._transferOwnership(newOwner);
    }

    /**
     * @dev The new owner accepts the ownership transfer.
     */
    function acceptOwnership() external {
        address sender = _msgSender();
        require(pendingOwner() == sender, "Ownable2Step: caller is not the new owner");
        _transferOwnership(sender);
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

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable2Step.sol";
import "./RentalPaymentRecord.sol";
import "./RentalPaymentAgreement.sol";

contract RentalAgreementFactory is Ownable2Step {
    RentalPaymentRecord public paymentRecord;
    address[] public agreements;
    
    mapping(address => uint256) public balanceOf;
    mapping(address => address[]) private landlordAgreements;

    constructor(address _paymentRecord) {
        paymentRecord = RentalPaymentRecord(_paymentRecord);
    }

    function createRentalAgreement(
        address tenant,
        uint256 startTime,
        uint256 length,
        uint256 totalAmount,
        uint256 amountPerBill,
        uint256 penaltyAmount,
        uint256 amountToAccept
    ) external returns (address) {
        RentalPaymentAgreement agreement = new RentalPaymentAgreement(
            msg.sender,
            tenant,
            startTime,
            length,
            totalAmount,
            amountPerBill,
            penaltyAmount,
            amountToAccept,
            address(paymentRecord)
        );
        agreements.push(address(agreement));

        // Add the new agreement to the list of authorized contracts in the payment record
        paymentRecord.addAuthorizedContract(address(agreement));

        
        balanceOf[msg.sender]++;
        landlordAgreements[msg.sender].push(address(agreement));
        
        return address(agreement);
    }

    function getAgreements() external view returns (address[] memory) {
        return agreements;
    }
    
    function contractByIndex(address landlord, uint256 index) external view returns (address) {
        require(index < balanceOf[landlord], "Index out of bounds");
        return landlordAgreements[landlord][index];
    }
}

pragma solidity ^0.8.0;

import "./RentalPaymentRecord.sol";

contract RentalPaymentAgreement {
    address public landlord;
    address public tenant;
    uint256 public startTime;
    uint256 public length;
    uint256 public totalAmount;
    uint256 public amountPerBill;
    uint256 public maxOverdueAmount;
    uint256 public penaltyAmount;
    uint256 public amountToAccept;
    uint256 public totalPaidAmount;
    bool public agreementAccepted = false;
    bool public ownerTerminated = false;
    bool public tenantTerminated = false;
    RentalPaymentRecord public paymentRecord;


    event PaymentReceived(uint256 amount, uint256 timestamp);

    // the agreement sets a maximum overdue amount (threshold), every exceeded amount will incur a penalty

    constructor(
        address _landlord,
        address _tenant,
        uint256 _startTime,
        uint256 _length,
        uint256 _totalAmount,
        uint256 _amountPerBill,
        uint256 _penaltyAmount,
        uint256 _amountToAccept,
        address _paymentRecord
    ) {

        require(_amountPerBill <= _totalAmount, "Amount per bill cannot be greater than total amount");
        require(_amountToAccept <= _totalAmount, "Amount to accept agreement cannot be greater than total amount");

        landlord = _landlord;
        tenant = _tenant;
        startTime = _startTime;
        length = _length;
        totalAmount = _totalAmount;
        penaltyAmount = _penaltyAmount;
        amountToAccept = _amountToAccept;
        paymentRecord = RentalPaymentRecord(_paymentRecord);
    }

    function acceptAgreement() external payable {
        require(msg.sender == tenant, "Only tenant can accept the agreement");
        require(block.timestamp < startTime, "Cannot accept after start time");

        if(amountToAccept > 0) {
            require(msg.value == amountToAccept, "Incorrect amount to accept agreement");
        }

        agreementAccepted = true;
    }

    function payRent() external payable {
        require(agreementAccepted, "Agreement not accepted");
        uint256 amountOverdue = getAmountOverdue();

        if(amountOverdue > 0) {
            require(msg.value >= amountOverdue, "Amount paid is less than overdue amount");
            payable(landlord).transfer(amountOverdue);
            payable(tenant).transfer(msg.value - amountOverdue);
        } else {
            require(msg.value == amountPerBill, "Incorrect amount to pay rent");
            payable(landlord).transfer(msg.value);
        } 

        // TODO: record payments behaviour in a unified PaymentRecord contract
        // paymentRecord.recordPayment(tenant, isGoodPayment);
        totalPaidAmount += msg.value;

        emit PaymentReceived(msg.value, block.timestamp);
    }

    function withdrawRentalPayment() external {
        require(msg.sender == landlord, "Only landlord can withdraw rent");
        payable(landlord).transfer(address(this).balance);
    }

    function transferLandlordship(address newLandlord) external {
        require(msg.sender == landlord, "Only landlord can transfer ownership");
        landlord = newLandlord;
    }

    function getAmountPerSecond() public view returns (uint256) {
        return totalAmount / length;
    }

    function getPaidSeconds() public view returns (uint256) {
        uint256 amountPerSecond = getAmountPerSecond();
        return totalPaidAmount / amountPerSecond;
    }

    function getPaidUntil() public view returns (uint256) {
        uint256 paidSeconds = getPaidSeconds();
        return startTime + paidSeconds;
    }

    function getAmountOverdue() public view returns (uint256) {
        uint256 paidUntil = getPaidUntil();
        if (block.timestamp > paidUntil) {
            uint256 overdueSeconds = block.timestamp - paidUntil;
            uint256 amountPerSecond = getAmountPerSecond();
            return overdueSeconds * amountPerSecond;
        } else {
            return 0;
        }
    }
}

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable2Step.sol";

contract RentalPaymentRecord is Ownable2Step {
    mapping(address => uint256) public goodPayments;
    mapping(address => uint256) public latePayments;
    mapping(address => uint256) public missedPayments;
    mapping(address => bool) private authorizedContracts;
    mapping(address => bool) private authorizedFactory;

    modifier onlyAuthorizedContracts() {
        require(
            authorizedContracts[msg.sender],
            "Caller is not an authorized contract"
        );
        _;
    }

    modifier onlyAuthorizedFactory() {
        require(
            authorizedFactory[msg.sender],
            "Caller is not an authorized factory"
        );
        _;
    }

    function addAuthorizedContract(address contractAddress) external onlyAuthorizedFactory {
        authorizedContracts[contractAddress] = true;
    }

    function recordPayment(address tenant, bool isOnTime, uint256 count) external onlyAuthorizedContracts {
        if (!isOnTime) {
            latePayments[tenant] += count;
        } else {
            goodPayments[tenant] += count;
        }
    }

    function setAuthorizedFactory(address _factoryAddress, bool _isAuthorized) external onlyOwner {
        authorizedFactory[_factoryAddress] = _isAuthorized;
    }
}