// SPDX-License-Identifier: MIT

pragma solidity ^0.8.9;

import './libraries/Ownable.sol';

contract AugmentSocialProfile is Ownable {
    address public companyFeeDestination;
    address public communityFeeDestination;

    // Only when there is unclaimed referral fees.
    address public referralFeeDestination;

    uint256 public companyFeePercent;
    uint256 public subjectFeePercent;
    uint256 public communityFeePercent;

    /// @notice This is a subset of Company fee, and paid from Company wallet
    uint256 public referralFeePercent;

    event Trade(
        address trader,
        address subject,
        bool isBuy,
        uint256 ethAmount,
        uint256 companyEthAmount,
        uint256 subjectEthAmount,
        uint256 communityFeeAmount,
        uint256 referralEthAmount,
        uint256 supply
    );

    // SharesSubject => (Holder => Balance)
    mapping(address => mapping(address => uint256)) public sharesBalance;

    // SharesSubject => Supply
    mapping(address => uint256) public sharesSupply;

    // Maps the referee to referrer
    mapping(address => address) public referralData;

    constructor() Ownable() {
        subjectFeePercent = 50000000000000000; // 5% for share owner
        referralFeePercent = 30000000000000000; // 3% for referral pool
        communityFeePercent = 10000000000000000; // 1% for community pool
        companyFeePercent = 10000000000000000; // 1% for procotol
    }

    function setReferralData(address _referee, address _referrer) external onlyOwner {
        referralData[_referee] = _referrer;
    }

    function setCompanyFeeDestination(
        address _feeDestination
    ) public onlyOwner {
        companyFeeDestination = _feeDestination;
    }

    function setCommunityFeeDestination(
        address _feeDestination
    ) public onlyOwner {
        communityFeeDestination = _feeDestination;
    }

    function setReferralFeeDestination(
        address _feeDestination
    ) public onlyOwner {
        referralFeeDestination = _feeDestination;
    }

    function setCompantFeePercent(uint256 _feePercent) public onlyOwner {
        companyFeePercent = _feePercent;
    }

    function setSubjectFeePercent(uint256 _feePercent) public onlyOwner {
        subjectFeePercent = _feePercent;
    }

    function setCommunityFeePercent(uint256 _feePercent) public onlyOwner {
        communityFeePercent = _feePercent;
    }

    function sethReferralFeePercent(uint256 _feePercent) public onlyOwner {
        referralFeePercent = _feePercent;
    }

    function getPrice(
        uint256 supply,
        uint256 amount
    ) public pure returns (uint256) {
        uint256 calculationSupply = (supply + amount);

        return ((calculationSupply ** 2) * 1 ether) / 43370;
    }

    function getBuyPrice(address sharesSubject) public view returns (uint256) {
        return getPrice(sharesSupply[sharesSubject], 1);
    }

    function getSellPrice(address sharesSubject) public view returns (uint256) {
        return getPrice(sharesSupply[sharesSubject], 0);
    }

    function getBuyPriceAfterFee(
        address sharesSubject
    ) public view returns (uint256) {
        uint256 price = getBuyPrice(sharesSubject);
        uint256 referralFee = (price * referralFeePercent) / 1 ether;
        uint256 companyFee = (price * companyFeePercent) / 1 ether;
        uint256 subjectFee = (price * subjectFeePercent) / 1 ether;
        uint256 communityFee = (price * communityFeePercent) / 1 ether;
        return price + companyFee + subjectFee + communityFee + referralFee;
    }

    function getSellPriceAfterFee(
        address sharesSubject
    ) public view returns (uint256) {
        uint256 price = getSellPrice(sharesSubject);
        uint256 referralFee = (price * referralFeePercent) / 1 ether;
        uint256 companyFee = (price * companyFeePercent) / 1 ether;
        uint256 subjectFee = (price * subjectFeePercent) / 1 ether;
        uint256 communityFee = (price * communityFeePercent) / 1 ether;
        return price - companyFee - subjectFee - communityFee - referralFee;
    }

    function buyShare(address sharesSubject) public payable {
        uint256 supply = sharesSupply[sharesSubject];

        uint256 price = getBuyPrice(sharesSubject);
        uint256 referralFee = (price * referralFeePercent) / 1 ether;
        uint256 companyFee = (price * companyFeePercent) / 1 ether;
        uint256 subjectFee = (price * subjectFeePercent) / 1 ether;
        uint256 communityFee = (price * communityFeePercent) / 1 ether;

        require(
            msg.value >= price + companyFee + subjectFee + communityFee + referralFee,
            'Insufficient payment'
        );

        sharesBalance[sharesSubject][msg.sender] =
            sharesBalance[sharesSubject][msg.sender] +
            1;

        sharesSupply[sharesSubject] = supply + 1;
        emit Trade(
            msg.sender,
            sharesSubject,
            true,
            price,
            companyFee,
            subjectFee,
            communityFee,
            referralFee,
            supply + 1
        );

        // Protocol without referral fee fee (referral is paid from company wallet)
        (bool success1, ) = companyFeeDestination.call{
            value: companyFee
        }('');

        // Share owner fee
        (bool success2, ) = sharesSubject.call{value: subjectFee}('');

        // For the community
        (bool success3, ) = communityFeeDestination.call{
            value: communityFee
        }('');


        // Transfer referral fee to referer, or to the pool if not found referrer.
        address referralDestination = referralData[msg.sender] != address(0)
            ? referralData[msg.sender]
            : referralFeeDestination;

        (bool success4, ) = referralDestination.call{value: referralFee}('');

        require(success1 && success2 && success3 && success4, 'Unable to send funds');
    }

    function sellShare(address sharesSubject) public payable {
        uint256 supply = sharesSupply[sharesSubject];
        require(supply >= 1, 'bad supply');

        uint256 price = getSellPrice(sharesSubject);
        uint256 communityFee = (price * communityFeePercent) / 1 ether;
        uint256 referralFee = (price * referralFeePercent) / 1 ether;
        uint256 companyFee = (price * companyFeePercent) / 1 ether;
        uint256 subjectFee = (price * subjectFeePercent) / 1 ether;

        require(
            sharesBalance[sharesSubject][msg.sender] >= 1,
            'Insufficient shares'
        );

        sharesBalance[sharesSubject][msg.sender] =
            sharesBalance[sharesSubject][msg.sender] -
            1;

        sharesSupply[sharesSubject] = supply - 1;
        emit Trade(
            msg.sender,
            sharesSubject,
            false,
            price,
            companyFee,
            subjectFee,
            communityFee,
            referralFee,
            supply - 1
        );

        // Pay the seller the amount after fees
        (bool success1, ) = msg.sender.call{
            value: price - companyFee - referralFee - communityFee - subjectFee
        }('');

        // Pay the company fee
        (bool success2, ) = companyFeeDestination.call{
            value: companyFee
        }('');

        // Pay the share owner
        (bool success3, ) = sharesSubject.call{value: subjectFee}('');

        // Pay the community fee
        (bool success4, ) = communityFeeDestination.call{
            value: communityFee
        }('');

        // Transfer referral fee to referer, or to the pool if not found referrer.
        address referralDestination = referralData[msg.sender] != address(0)
            ? referralData[msg.sender]
            : referralFeeDestination;

        (bool success5, ) = referralDestination.call{value: referralFee}('');

        require(
            success1 && success2 && success3 && success4 && success5,
            'Unable to send funds'
        );
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.9;

// OpenZeppelin Contracts v4.4.1 (utils/Context.sol)

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

pragma solidity ^0.8.0;

import './Context.sol';

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

    event OwnershipTransferred(
        address indexed previousOwner,
        address indexed newOwner
    );

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
        require(owner() == _msgSender(), 'Ownable: caller is not the owner');
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
        require(
            newOwner != address(0),
            'Ownable: new owner is the zero address'
        );
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