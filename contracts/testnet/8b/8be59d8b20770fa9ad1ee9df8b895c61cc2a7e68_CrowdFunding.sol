/**
 *Submitted for verification at Arbiscan on 2022-05-29
*/

// File: @openzeppelin/contracts/utils/Context.sol


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

// File: @openzeppelin/contracts/access/Ownable.sol


// OpenZeppelin Contracts v4.4.1 (access/Ownable.sol)

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

// File: contracts/CrowFunding.sol


// OpenZeppelin Contracts v4.4.1 (utils/Context.sol)

pragma solidity ^0.8.0;


contract CrowdFunding is Ownable {
    struct Campaign {
        uint256 fundingId;
        address payable receiver;
        uint256 numFunder;
        uint256 fundGoal;
        uint256 totalAmount;
    }

    mapping(uint256 => Campaign) campaignMap;

    struct Funder {
        address user;
        uint256 amount;
    }

    mapping(uint256 => Funder[]) campaignFunderMap;

    mapping(uint256 => mapping(address => bool)) isBidMap;

    uint256 public nextFundingId;

    modifier isBid(uint256 _fundingId, address _user) {
        require(!isBidMap[_fundingId][_user], "bid repetition");
        _;
    }

    function newCampaign(address payable _receiver, uint256 _fundGoal)
        external
        onlyOwner
    {
        Campaign storage c = campaignMap[nextFundingId];
        c.fundingId = nextFundingId++;
        c.receiver = _receiver;
        c.fundGoal = _fundGoal;
    }

    function bid(uint256 _campaignId)
        external
        payable
        isBid(_campaignId, _msgSender())
    {
        require(_campaignId < nextFundingId, "funding not find");

        Campaign storage c = campaignMap[_campaignId];
        c.numFunder++;
        c.totalAmount += msg.value;

        campaignFunderMap[_campaignId].push(Funder(_msgSender(), msg.value));

        isBidMap[_campaignId][_msgSender()] = true;
    }

    function withDraw(uint256 _campaignId) external {
        require(
            campaignMap[_campaignId].receiver == _msgSender(),
            "not receiver"
        );
        require(
            campaignMap[_campaignId].totalAmount >=
                campaignMap[_campaignId].fundGoal,
            "crow unfinished"
        );
        payable(_msgSender()).transfer(campaignMap[_campaignId].totalAmount);
        campaignMap[_campaignId].totalAmount = 0;
    }

    function campaignInfo(uint256 _campaignId)
        public
        view
        returns (Campaign memory)
    {
        return campaignMap[_campaignId];
    }
}