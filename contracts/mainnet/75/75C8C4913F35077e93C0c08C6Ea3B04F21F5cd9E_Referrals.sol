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

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

interface IReferrals {
    function setReferred(address _referredTrader, address _referrer) external;
    function getReferred(address _trader) external view returns (address, uint);
    function addRefFees(address _trader, address _tigAsset, uint _fees) external;
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

import "@openzeppelin/contracts/access/Ownable.sol";
import "./interfaces/IReferrals.sol";

contract Referrals is Ownable, IReferrals {

    address public protocol;
    mapping(address trader => address referrer) public referral;
    mapping(address referrer => uint) public refTier;
    uint[] public tiers;
    mapping(address referrer => uint) public totalFees;
    mapping(address => uint256) public tigAssetValue;
    uint[] public requirement;

    // Events
    event Referred(address referredTrader, address referrer);

    // Modifiers
    modifier onlyProtocol() {
        require(_msgSender() == address(protocol), "!Protocol");
        _;
    }

    constructor() {
        tiers = [50e4, 100e4, 125e4, 150e4];
        requirement = [0, 1000e18, 5000e18, 50000e18];
    }

    /**
    * @notice set the ref data
    * @dev only callable by trading
    * @param _referredTrader address of the trader
    * @param _referrer address of the referrer
    */
    function setReferred(address _referredTrader, address _referrer) external onlyProtocol {
        if (referral[_referredTrader] != address(0) || _referrer == address(0) || _referredTrader == _referrer) return;
        referral[_referredTrader] = _referrer;
        emit Referred(_referredTrader, _referrer);
    }

    function getReferred(address _trader) external view returns (address _referrer, uint256 _referrerFees) {
        _referrer = referral[_trader];
        if(_referrer != address(0)) {
            _referrerFees = tiers[refTier[_referrer]];
        } else {
            _referrerFees = 0;
        }
    }

    // 0 default first tier: 5% - no fees required
    // 1 second tier: 10% - $1000 (10M crypto volume)
    // 2 third tier: 12.5% - $5000 (50M crypto volume)
    function addRefFees(address _referrer, address _tigAsset, uint _fees) external onlyProtocol {
        if (_referrer == address(0)) return;
        _fees = _fees * tigAssetValue[_tigAsset] / 1e18;
        totalFees[_referrer] += _fees;

        uint256 _tier = refTier[_referrer];
        if (_tier >= 2) return;
        uint256 _totalFees = totalFees[_referrer];
        if(_totalFees >= requirement[2] && _tier < 2) {
            refTier[_referrer] = 2;
        } else if(_totalFees >= requirement[1] && _tier < 1) {
            refTier[_referrer] = 1;
        }
    }

    // Owner
    function setProtocol(address _protocol) external onlyOwner {
        protocol = _protocol;
    }

    function setRefTier(address _referrer, uint _tier) external onlyOwner {
        require(_tier < tiers.length, "!tier");
        refTier[_referrer] = _tier;
    }

    function setTiers(uint[] calldata _newTiers) external onlyOwner {
        require(_newTiers.length == 4, "!length");
        tiers = _newTiers;
    }

    function setTigAssetValue(address _tigAsset, uint256 _value) external onlyOwner {
        tigAssetValue[_tigAsset] = _value;
    }

    function setRequirement(uint[] calldata _requirement) external onlyOwner {
        require(_requirement.length == 4, "!length");
        requirement = _requirement;
    }
}