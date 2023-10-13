/**
 *Submitted for verification at Arbiscan.io on 2023-10-12
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

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


contract Protocol is Ownable {
    address public protocolFeeDestination;
    uint256 public protocolFeePercent;
    uint256 public subjectFeePercent;
    uint256 public referralFeePercent;
    uint256 public totalDistributedFees;
    uint256 public registerCost;

    event Trade(
        address trader,
        address subject,
        bool isBuy,
        uint256 shareAmount,
        uint256 ethAmount,
        uint256 protocolEthAmount,
        uint256 subjectEthAmount,
        uint256 referralEthAmount,
        uint256 totalDistributedFees
    );

    // SharesSubject => (Holder => Balance)
    mapping(address => mapping(address => uint256)) public sharesBalance;

    // SharesSubject => Supply
    mapping(address => uint256) public sharesSupply;

    //user address => user total subject fee
    mapping(address => uint256) public userTotalSubjectFee;

    //user address => referral fee
    mapping(address => uint256) public userReferralFee;

    mapping(address => address) public referances;
    mapping(address => bool) public builtinRefs;
    mapping(address => bool) public isSpecialRef;

    constructor() Ownable() {
        protocolFeePercent = 100000000000000000;
        subjectFeePercent = 50000000000000000;
        referralFeePercent = 50000000000000000;
        registerCost = 2000000000000000;
    }

    function setFeeDestination(address _feeDestination) public onlyOwner {
        protocolFeeDestination = _feeDestination;
    }

    function addToBuiltinRefs(address _address, bool status) public onlyOwner {
        builtinRefs[_address] = status;
    }

    function setSpecialReferrer(
        address _address,
        bool status
    ) public onlyOwner {
        isSpecialRef[_address] = status;
    }

    function setRegisterCost(uint256 _cost) public onlyOwner {
        registerCost = _cost;
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

    function getPrice(
        uint256 supply,
        uint256 amount
    ) public pure returns (uint256) {
        uint256 sum1 = supply == 0
            ? 0
            : ((supply - 1) * (supply) * (2 * (supply - 1) + 1)) / 6;
        uint256 sum2 = supply == 0 && amount == 1
            ? 0
            : ((supply - 1 + amount) *
                (supply + amount) *
                (2 * (supply - 1 + amount) + 1)) / 6;
        uint256 summation = sum2 - sum1;
        return (summation * 1 ether) / 16000;
    }

    function getBuyPrice(
        address sharesSubject,
        uint256 amount
    ) public view returns (uint256) {
        return getPrice(sharesSupply[sharesSubject], amount);
    }

    function getSellPrice(
        address sharesSubject,
        uint256 amount
    ) public view returns (uint256) {
        return getPrice(sharesSupply[sharesSubject] - amount, amount);
    }

    function getBuyPriceAfterFee(
        address sharesSubject,
        uint256 amount
    ) public view returns (uint256) {
        uint256 price = getBuyPrice(sharesSubject, amount);
        uint256 protocolFee = (price * protocolFeePercent) / 1 ether;
        uint256 subjectFee = (price * subjectFeePercent) / 1 ether;
        return price + protocolFee + subjectFee;
    }

    function getRefFeePercent(
        address _referancer
    ) public view returns (uint256) {
        return
            isSpecialRef[_referancer] == true
                ? referralFeePercent * 4
                : referralFeePercent;
    }

    function getSellPriceAfterFee(
        address sharesSubject,
        uint256 amount
    ) public view returns (uint256) {
        uint256 price = getSellPrice(sharesSubject, amount);
        uint256 protocolFee = (price * protocolFeePercent) / 1 ether;
        uint256 subjectFee = (price * subjectFeePercent) / 1 ether;
        return price - protocolFee - subjectFee;
    }

    function initAccount(address referrer) public payable {
        uint256 referrerSupply = sharesSupply[referrer];

        require(
            referrerSupply > 0 || builtinRefs[referrer] == true,
            "referrer must be initialized"
        );
        buyShares(msg.sender, 1, true);
        referances[msg.sender] = referrer;
    }

    function buyShares(
        address sharesSubject,
        uint256 amount,
        bool isForRegister
    ) public payable {
        uint256 _registerCost = 0;

        if (isForRegister) {
            require(sharesSubject == msg.sender, "first trader must be owner");
            _registerCost = registerCost;
        } else {
            require(
                sharesSupply[sharesSubject] > 0,
                "subject must be initialized first"
            );
        }

        address referrer = referances[sharesSubject];
        uint256 price = getPrice(sharesSupply[sharesSubject], amount);
        uint256 protocolFee = ((price * protocolFeePercent) / 1 ether) +
            _registerCost;
        uint256 subjectFee = (price * subjectFeePercent) / 1 ether;
        uint256 refFee = (protocolFee * getRefFeePercent(referrer)) / 1 ether;
        totalDistributedFees = totalDistributedFees + refFee + subjectFee;

        require(
            msg.value >= price + protocolFee + subjectFee,
            "Insufficient payment"
        );
        userTotalSubjectFee[msg.sender] =
            userTotalSubjectFee[msg.sender] +
            subjectFee;
        userReferralFee[referrer] = userReferralFee[referrer] + refFee;
        sharesBalance[sharesSubject][msg.sender] =
            sharesBalance[sharesSubject][msg.sender] +
            amount;
        sharesSupply[sharesSubject] = sharesSupply[sharesSubject] + amount;
        // NOTE: Make sure userTotalSubjectFee[msg.sender] returns updated subject fee

        emit Trade(
            msg.sender,
            sharesSubject,
            true,
            amount,
            price,
            protocolFee,
            subjectFee,
            refFee,
            totalDistributedFees
        );

        (bool success1, ) = protocolFeeDestination.call{
            value: protocolFee - refFee
        }("");
        (bool success2, ) = sharesSubject.call{value: subjectFee}("");
        (bool success3, ) = referrer.call{value: refFee}("");
        require(success1 && success2 && success3, "Unable to send funds");
    }

    function sellShares(address sharesSubject, uint256 amount) public payable {
        uint256 supply = sharesSupply[sharesSubject];
        require(supply > amount, "Cannot sell the last share");
        address referrer = referances[sharesSubject];
        uint256 price = getPrice(supply - amount, amount);
        uint256 protocolFee = (price * protocolFeePercent) / 1 ether;
        uint256 subjectFee = (price * subjectFeePercent) / 1 ether;
        uint256 refFee = (protocolFee * getRefFeePercent(referrer)) / 1 ether;
        totalDistributedFees = totalDistributedFees + refFee + subjectFee;

        require(
            sharesBalance[sharesSubject][msg.sender] >= amount,
            "Insufficient shares"
        );
        sharesBalance[sharesSubject][msg.sender] =
            sharesBalance[sharesSubject][msg.sender] -
            amount;
        sharesSupply[sharesSubject] = supply - amount;
        emit Trade(
            msg.sender,
            sharesSubject,
            false,
            amount,
            price,
            protocolFee,
            subjectFee,
            refFee,
            totalDistributedFees
        );
        (bool success1, ) = msg.sender.call{
            value: price - protocolFee - subjectFee
        }("");
        (bool success2, ) = protocolFeeDestination.call{
            value: protocolFee - refFee
        }("");
        (bool success3, ) = sharesSubject.call{value: subjectFee}("");
        (bool success4, ) = referrer.call{value: refFee}("");

        require(
            success1 && success2 && success3 && success4,
            "Unable to send funds"
        );
    }
}