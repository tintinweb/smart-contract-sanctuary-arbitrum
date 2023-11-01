// SPDX-License-Identifier: MIT

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
        _setOwner(_msgSender());
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
        _;
    }

    /**
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions anymore. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby removing any functionality that is only available to the owner.
     */
    function renounceOwnership() public virtual onlyOwner {
        _setOwner(address(0));
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _setOwner(newOwner);
    }

    function _setOwner(address newOwner) private {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}

// SPDX-License-Identifier: MIT

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
pragma solidity ^0.8.0;
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";

contract arbiBallTreasury is Ownable{
    
    address public arbiBall;
    uint16 public ownerFee = 2500; // 25%
    
    event OwnerFeeUpdated(uint16 _ownerFee);
    event MaxRaffleAmountUpdated(uint32 _raffleId, uint256 _amount);
    event ValidCallerUpdated(address _caller, bool _value);
    event WithdrawFromRaffle(address _user, uint32 _raffleId, uint256 _amount);
    event DepositFromRaffle(uint32 _raffleId, uint256 _amount);
    event WithdrawOwnerFee(uint32 _raffleId, uint256 _amount);
    
    mapping (address => bool) public isValidCaller;
    mapping (uint32 => uint256) public ownerFeeAccumulatedInRaffle;
    mapping (uint32 => uint256) public fundsAccumulatedInRaffle; // Can remove this; need to think more about it
    mapping (uint32 => uint256) public amountWithdrawnFromRaffle;
    mapping (uint32 => uint256) public maxRaffleAmount;
    
    modifier validateCall () {
        require(isValidCaller[msg.sender] || msg.sender == address(arbiBall), "Treasury: Caller is not valid");
        _;
    }
    
    constructor(address _arbiBall) {
        arbiBall = _arbiBall;
    }
    
    function withdrawFromRaffle(address payable _user, uint32 _raffleId, uint256 _amount) external validateCall{
        require(_user != address(0), "Token address cannot be 0");
        require(_amount > 0, "Amount should be greater than 0");
        require(
            amountWithdrawnFromRaffle[_raffleId] + _amount <= maxRaffleAmount[_raffleId],
            "Amount exceeds max raffle amount"
        );
        amountWithdrawnFromRaffle[_raffleId] += _amount;
        _user.transfer(_amount);
        emit WithdrawFromRaffle(_user, _raffleId, _amount);
    }
    
    function depositFromRaffle(uint32 _raffleId) external payable validateCall{
        require(msg.value > 0, "Amount should be greater than 0");
        uint256 ownerFeeAmount = msg.value * ownerFee / 10000;
        ownerFeeAccumulatedInRaffle[_raffleId] += ownerFeeAmount;
        fundsAccumulatedInRaffle[_raffleId] += msg.value - ownerFeeAmount;
        emit DepositFromRaffle(_raffleId, msg.value);
    }
    
    function withdrawOwnerFee(uint32 _raffleId, address _to) external onlyOwner {
        require(ownerFeeAccumulatedInRaffle[_raffleId] > 0, "No owner fee accumulated");
        uint256 amount = ownerFeeAccumulatedInRaffle[_raffleId];
        ownerFeeAccumulatedInRaffle[_raffleId] = 0;
        payable(_to).transfer(amount);
        emit WithdrawOwnerFee(_raffleId, amount);
    }
    
    function depositToARaffle(uint32 _raffleId) external payable {
        require(msg.value > 0, "Amount should be greater than 0");
        emit DepositFromRaffle(_raffleId, msg.value);
    }
    
    // Setter
    
    function setArbiBall(address _arbiBall) external onlyOwner {
        arbiBall = _arbiBall;
    }
    
    function setOwnerFee(uint16 _ownerFee) external onlyOwner {
        ownerFee = _ownerFee;
        emit OwnerFeeUpdated(_ownerFee);
    }
    
    function setValidCaller(address _caller, bool _value) external onlyOwner {
        isValidCaller[_caller] = _value;
        emit ValidCallerUpdated(_caller, _value);
    }
    
    function setMaxRaffleAmount(uint32 _raffleId, uint256 _amount) external validateCall{
        maxRaffleAmount[_raffleId] = _amount;
        emit MaxRaffleAmountUpdated(_raffleId, _amount);
    }
    
    // Getter
    
    function getFundsAccumulatedInRaffle(uint32 _raffleId) external view returns(uint256) {
        return fundsAccumulatedInRaffle[_raffleId];
    }
    
}