//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "./interfaces/IReferrals.sol";

contract Referrals is Ownable, IReferrals {

    bool private isInit;

    address public protocol;

    mapping(bytes32 => address) private _referral;
    mapping(address => bytes32) private _referred;

    function createReferralCode(bytes32 _hash) external {
        require(_referral[_hash] == address(0), "Referral code already exists");
        _referral[_hash] = _msgSender();
        emit ReferralCreated(_msgSender(), _hash);
    }

    function setReferred(address _referredTrader, bytes32 _hash) external onlyProtocol {
        if (_referred[_referredTrader] != bytes32(0)) {
            return;
        }
        if (_referredTrader == _referral[_hash]) {
            return;
        }
        _referred[_referredTrader] = _hash;
        emit Referred(_referredTrader, _hash);
    }

    function getReferred(address _trader) external view returns (bytes32) {
        return _referred[_trader];
    }

    function getReferral(bytes32 _hash) external view returns (address) {
        return _referral[_hash];
    }

    // Owner

    function setProtocol(address _protocol) external onlyOwner {
        protocol = _protocol;
    }

    function initRefs(
        address[] memory _codeOwners,
        bytes32[] memory _ownedCodes,
        address[] memory _referredA,
        bytes32[] memory _referredTo
    ) external onlyOwner {
        require(!isInit);
        isInit = true;
        uint _codeOwnersL = _codeOwners.length;
        uint _referredAL = _referredA.length;
        for (uint i=0; i<_codeOwnersL; i++) {
            _referral[_ownedCodes[i]] = _codeOwners[i];
        }
        for (uint i=0; i<_referredAL; i++) {
            _referred[_referredA[i]] = _referredTo[i];
        }
    }

    // Modifiers

    modifier onlyProtocol() {
        require(_msgSender() == address(protocol), "!Protocol");
        _;
    }

    event ReferralCreated(address _referrer, bytes32 _hash);
    event Referred(address _referredTrader, bytes32 _hash);

}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

interface IReferrals {

    function createReferralCode(bytes32 _hash) external;
    function setReferred(address _referredTrader, bytes32 _hash) external;
    function getReferred(address _trader) external view returns (bytes32);
    function getReferral(bytes32 _hash) external view returns (address);
    
}

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