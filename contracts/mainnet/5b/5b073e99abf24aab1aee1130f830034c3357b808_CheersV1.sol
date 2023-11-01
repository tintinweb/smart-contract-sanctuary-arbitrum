// SPDX-License-Identifier: UNLICENSED
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



// downgrade
pragma solidity >=0.8.2 <0.9.0;

import "./ABDKMath64x64.sol";
import {CheersVaultFacotry} from "./CheersVaultFactory.sol";
import "./CheersVault.sol";


contract CheersV1 is Ownable {
    using ABDKMath64x64 for int128;

    address public protocolFeeDestination;
    uint256 public protocolFeePercent;
    uint256 public subjectFeePercent;
    uint256 public subjectSubscriptionPrice;
    address public CheersVaultFacotryAddress;

    CheersVaultFacotry private vaultFacotry;
    CheersVault private cheersVault;
    CheersVault private subsVault;

    uint256 public sub_timestamp = 30 days;

    uint256 public subject_fee_percent_cap = 100000000000000000;        // 10%
    uint256 public subs_vault_fee_percent_cap = 100000000000000000;     // 10%
    uint256 public cheers_vault_fee_percent_cap = 950000000000000000;   // 95%

    event Trade(address trader, address subject, bool isBuy, uint256 cheersAmount, uint256 ethAmount, uint256 protocolEthAmount, uint256 subjectEthAmount, uint256 supply);
    event Subscribe(address trader, address subject, uint256 blocktimestamp, uint256 ethAmount, uint256 protocolEthAmount);
    event Tipping(address from, address to, uint256 amount);

    // Setting args
    event setSubjectFeePercentByOwnerEvent(address cheersSubject, uint256 feePercent);
    event setSubsVaultFeePercentByOwnerEvent(address cheersSubject, uint256 feePercent);
    event setSubscriptionPriceByOwnerEvent(address cheersSubject, uint256 price);
    event setCheersVaultFeePercentByOwnerEvent(address cheersSubject, uint256 feePercent);

    // CheersSubject => (Holder => Balance)
    mapping(address => mapping(address => uint256)) public cheersBalance;

    mapping(address => address) public Vaults;

    // CheersSubject => Supply
    mapping(address => uint256) public cheersSupply;
    mapping(address => uint256) public subscriptionsSupply;

    // CheersSubject => (Holder => Subscriptions expire block)
    mapping(address => mapping(address => uint256)) public subsBalance;

    // CheersSubject => Fee
    mapping(address => uint256) public feesMapping;
    mapping(address => uint256) public SubsVaultFeesMapping;
    mapping(address => uint256) public CheersVaultFeesMapping;

    // CheersSubject => SubscriptionPrice
    mapping(address => uint256) public SubscriptionPriceMapping;

    function divide(int128 a, int128 b) public pure returns (int128) {
        require(b != 0, "Division by zero");
        int128 result = ABDKMath64x64.div(a, b);
        return result;
    }

    function setCheersVaultFacotryAddress(address _CheersVaultFacotryAddress) public onlyOwner {
            CheersVaultFacotryAddress = _CheersVaultFacotryAddress;
    }

    function setFeeDestination(address _feeDestination) public onlyOwner {
        protocolFeeDestination = _feeDestination;
    }

    function setProtocolFeePercent(uint256 _feePercent) public onlyOwner {
        protocolFeePercent = _feePercent;
    }

    function setSubjectFeePercent(uint256 _feePercent) public onlyOwner {
        subjectFeePercent = _feePercent;
    }

    function setSubjectSubscriptionPrice(uint256 _subPrice) public onlyOwner{
        subjectSubscriptionPrice = _subPrice;
    }

    function setSubscriptionDuration(uint256 _timestamp) public onlyOwner{
        sub_timestamp = _timestamp;
    }

    function setSubjectFeePercentByOwner(address cheersSubject, uint256 _feePercent) public{
        require(cheersSubject == msg.sender, "Only the cheers' subject can adjust fee percent");
        require(_feePercent >= 0 && _feePercent <= subject_fee_percent_cap, "fee percent out of range");
        feesMapping[cheersSubject] = _feePercent;
        emit setSubjectFeePercentByOwnerEvent(cheersSubject, _feePercent);
    }

    function setSubsVaultFeePercentByOwner(address cheersSubject, uint256 _feePercent) public{
        require(cheersSubject == msg.sender, "Only the cheers' subject can adjust fee percent");
        require(_feePercent >= 0 && _feePercent <= subs_vault_fee_percent_cap, "fee percent out of range");
        SubsVaultFeesMapping[cheersSubject] = _feePercent;
        emit setSubsVaultFeePercentByOwnerEvent(cheersSubject, _feePercent);
    }

    function setSubscriptionPriceByOwner(address cheersSubject, uint256 _price) public {
        require(cheersSubject == msg.sender, "Only the cheers' subject can adjust price");
        require(_price >= 0, "fee percent out of range");
        SubscriptionPriceMapping[cheersSubject] = _price;
        emit setSubscriptionPriceByOwnerEvent(cheersSubject, _price);
    }

    function setCheersVaultFeePercentByOwner(address cheersSubject, uint256 _feePercent) public{
        require(cheersSubject == msg.sender, "Only the cheers' subject can adjust fee percent");
        require(_feePercent >= 0 && _feePercent <= cheers_vault_fee_percent_cap, "fee percent out of range");
        CheersVaultFeesMapping[cheersSubject] = _feePercent;
        emit setCheersVaultFeePercentByOwnerEvent(cheersSubject, _feePercent);
    }

    function calSummation(uint256 supply, uint256 amount) public pure returns (uint256) {
        if (supply == 0 && amount == 1) {
            return 0;
        } else if (supply == 1 && amount == 1){
            return 0;
        } else {
        int128 one = ABDKMath64x64.fromInt(1); 
        int128 _amount = ABDKMath64x64.fromUInt(amount);
        int128 x64x64 = ABDKMath64x64.fromUInt(supply);
        int128 lnX = ABDKMath64x64.ln(x64x64);
        int128 lnX_amount = ABDKMath64x64.ln(x64x64+_amount);
        int128 sum1 = ABDKMath64x64.mul(ABDKMath64x64.mul(ABDKMath64x64.sub(x64x64, one), x64x64), ABDKMath64x64.sub(lnX, one));
        int128 sum2 = ABDKMath64x64.mul(ABDKMath64x64.mul(ABDKMath64x64.sub(x64x64+_amount, one), x64x64+_amount), ABDKMath64x64.sub(lnX_amount, one));
        return ABDKMath64x64.toUInt(sum2-sum1);
        }
    }

    function getPrice(uint256 supply, uint256 amount) public pure returns (uint256) {
        uint256 price = calSummation(supply, amount) * 1 ether / 800;
        return price;
    }

    function getBuyPrice(address cheersSubject, uint256 amount) public view returns (uint256) {
        return getPrice(cheersSupply[cheersSubject], amount);
    }

    function getSubjectFeePercent(address cheersSubject) public view returns (uint256){
        uint256 _subjectFeePercent = feesMapping[cheersSubject];
        if (_subjectFeePercent == 0) {
            return subjectFeePercent;
        } else {
            return _subjectFeePercent;
        }
    }

    function getSubsVaultFeePercent(address cheersSubject) public view returns(uint256){
        uint256 _vaultFeePercent = SubsVaultFeesMapping[cheersSubject];
        if (_vaultFeePercent == 0) {
            return protocolFeePercent;
        } else {
            return _vaultFeePercent;
        }
    }

    function getCheersVaultFeePercent(address cheersSubject) public view returns(uint256){
        uint256 _vaultFeePercent = CheersVaultFeesMapping[cheersSubject];
        if (_vaultFeePercent == 0) {
            return protocolFeePercent;
        } else {
            return _vaultFeePercent;
        }
    }

    function getSubscriptionPrice(address cheersSubject) public view returns(uint256){
        uint256 _subscriptionPrice = SubscriptionPriceMapping[cheersSubject];
        if (_subscriptionPrice == 0) {
            return subjectSubscriptionPrice;
        } else {
            return _subscriptionPrice;
        }
    }

    function getSubPriceAfterFee(address cheersSubject) public view returns (uint256) {
        uint256 price = getSubscriptionPrice(cheersSubject);
        uint256 protocolFee = price * protocolFeePercent / 1 ether;
        uint256 toCheersVaultFee = price * getCheersVaultFeePercent(cheersSubject) / 1 ether;
        return price + protocolFee + toCheersVaultFee;
    }

    function getSellPrice(address cheersSubject, uint256 amount) public view returns (uint256) {
        return getPrice(cheersSupply[cheersSubject] - amount, amount);
    }

    function getBuyPriceAfterFee(address cheersSubject, uint256 amount) public view returns (uint256) {
        uint256 price = getBuyPrice(cheersSubject, amount);
        uint256 protocolFee = price * protocolFeePercent / 1 ether;
        uint256 subjectFee = price * getSubjectFeePercent(cheersSubject) / 1 ether;
        uint256 toSubsVaultFee = price * protocolFeePercent / 1 ether;
        return price + protocolFee + subjectFee + toSubsVaultFee;
    }

    function getSellPriceAfterFee(address cheersSubject, uint256 amount) public view returns (uint256) {
        uint256 price = getSellPrice(cheersSubject, amount);
        uint256 protocolFee = price * protocolFeePercent / 1 ether;
        uint256 subjectFee = price * getSubjectFeePercent(cheersSubject) / 1 ether;
        uint256 toSubsVaultFee = price * protocolFeePercent / 1 ether;
        return price - protocolFee - subjectFee - toSubsVaultFee;
    }

    function buyCheers(address cheersSubject, uint256 amount) public payable {
        uint256 supply = cheersSupply[cheersSubject];
        require(supply > 0 || cheersSubject == msg.sender, "Only the cheers' subject can buy the first cheers");
        uint256 price = getPrice(supply, amount);
        uint256 protocolFee = price * protocolFeePercent / 1 ether;
        uint256 subjectFee = price * getSubjectFeePercent(cheersSubject) / 1 ether;
        uint256 toSubsVaultFee = price * getSubsVaultFeePercent(cheersSubject) / 1 ether;
        require(msg.value >= price + protocolFee + subjectFee + toSubsVaultFee, "Insufficient payment");
        // create a subs vault
        if (supply == 0 && cheersSubject == msg.sender) {
            vaultFacotry = CheersVaultFacotry(CheersVaultFacotryAddress);
            address vaultAddress = vaultFacotry.createVault(cheersSubject, address(this));
            Vaults[cheersSubject] = vaultAddress;
        }
        cheersBalance[cheersSubject][msg.sender] = cheersBalance[cheersSubject][msg.sender] + amount;
        cheersSupply[cheersSubject] = supply + amount;
        emit Trade(msg.sender, cheersSubject, true, amount, price, protocolFee, subjectFee, supply + amount);
        (bool success1, ) = protocolFeeDestination.call{value: protocolFee}("");
        (bool success2, ) = cheersSubject.call{value: subjectFee}("");
        // send fee to sub vault
        cheersVault = CheersVault(Vaults[cheersSubject]);
        cheersVault.deposit{value: toSubsVaultFee}(msg.sender, 1, 1, amount);
        require(success1 && success2, "Unable to send funds");
    }

    function sellCheers(address cheersSubject, uint256 amount) public payable {
        uint256 supply = cheersSupply[cheersSubject];
        require(supply > amount, "Cannot sell the last cheers");
        uint256 price = getPrice(supply - amount, amount);
        uint256 protocolFee = price * protocolFeePercent / 1 ether;
        uint256 subjectFee = price * getSubjectFeePercent(cheersSubject) / 1 ether;
        uint256 toSubsVaultFee = price * getSubsVaultFeePercent(cheersSubject) / 1 ether;
        require(cheersBalance[cheersSubject][msg.sender] >= amount, "Insufficient cheers");
        cheersBalance[cheersSubject][msg.sender] = cheersBalance[cheersSubject][msg.sender] - amount;
        cheersSupply[cheersSubject] = supply - amount;
        emit Trade(msg.sender, cheersSubject, false, amount, price, protocolFee, subjectFee, supply - amount);
        (bool success1, ) = msg.sender.call{value: price - protocolFee - subjectFee - toSubsVaultFee}("");
        (bool success2, ) = protocolFeeDestination.call{value: protocolFee}("");
        (bool success3, ) = cheersSubject.call{value: subjectFee}("");
        // send fee to sub vault
        cheersVault = CheersVault(Vaults[cheersSubject]);
        cheersVault.deposit{value: toSubsVaultFee}(msg.sender, 0, 1, amount);
        require(success1 && success2 && success3, "Unable to send funds");
    }

    function buySubscriptions(address cheersSubject) public payable {
        require(Vaults[cheersSubject] != address(0), "Need cheers owner buy first cheers");
        uint256 _subscriptionPrice = getSubscriptionPrice(cheersSubject);
        uint256 expireblock = subsBalance[cheersSubject][msg.sender];
        uint256 protocolFee = _subscriptionPrice * protocolFeePercent / 1 ether;
        uint256 toCheersVaultFee = _subscriptionPrice * getCheersVaultFeePercent(cheersSubject) / 1 ether;
        require(msg.value >= _subscriptionPrice + protocolFee + toCheersVaultFee, "Insufficient payment");
        uint _expireblock = (expireblock == 0 || expireblock < block.timestamp) ? block.timestamp + sub_timestamp : expireblock + sub_timestamp;
        subsBalance[cheersSubject][msg.sender] = _expireblock;
        emit Subscribe(msg.sender, cheersSubject, sub_timestamp, _subscriptionPrice, protocolFee);
        (bool success1, ) = protocolFeeDestination.call{value: protocolFee}("");
        (bool success2, ) = cheersSubject.call{value: _subscriptionPrice}("");
        // send fee to cheers vault
        cheersVault = CheersVault(Vaults[cheersSubject]);
        cheersVault.deposit{value: toCheersVaultFee}(msg.sender, 1, 2, _expireblock);
        require(success1 && success2, "Unable to send funds");
    }

    function sendTippingTransaction(address cheersSubject) public payable{
        require(msg.value > 0, "Insufficient payment");
        uint256 protocolFee = msg.value * protocolFeePercent / 1 ether;
        emit Tipping(msg.sender, cheersSubject, msg.value);
        (bool success1, ) = protocolFeeDestination.call{value: protocolFee}("");
        (bool success2, ) = cheersSubject.call{value: msg.value - protocolFee}("");
        require(success1 && success2, "Unable to send funds");
    }
}