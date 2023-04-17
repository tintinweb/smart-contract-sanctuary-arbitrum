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

pragma solidity =0.8.4;

interface IReferralStorage {
    function setReferralCode(address _account, bytes32 _code) external;
}

// SPDX-License-Identifier: MIT

pragma solidity =0.8.4;

import { Ownable } from "@openzeppelin/contracts/access/Ownable.sol";
import { IReferralStorage } from "./interfaces/IReferralStorage.sol";

contract ReferralStorage is Ownable, IReferralStorage {
    mapping(bytes32 => address) public codeOwners;
    mapping(address => bytes32) public referralCodes;
    mapping(address => uint256) public codeCounts;
    mapping(address => mapping(uint256 => bytes32)) public numberToCodes;
    mapping(address => bool) public isHandler;

    event RegisterCode(address _recipient, bytes32 _code);
    event SetReferralCode(address _recipient, bytes32 _code);
    event SetHandler(address _handler, bool _isActive);

    modifier onlyHandler() {
        require(isHandler[msg.sender], "ReferralStorage: Forbidden");
        _;
    }

    function setHandler(address _handler, bool _isActive) external onlyOwner {
        isHandler[_handler] = _isActive;
        emit SetHandler(_handler, _isActive);
    }

    function registerCode(bytes32 _code) external {
        require(_code != bytes32(0), "ReferralStorage: Invalid _code");
        require(codeOwners[_code] == address(0), "ReferralStorage: Code already exists");

        codeCounts[msg.sender]++;
        codeOwners[_code] = msg.sender;
        numberToCodes[msg.sender][codeCounts[msg.sender]] = _code;

        emit RegisterCode(msg.sender, _code);
    }

    function setReferralCode(address _recipient, bytes32 _code) external override onlyHandler {
        _setReferralCode(_recipient, _code);
    }

    function setReferralCodeByUser(bytes32 _code) external {
        _setReferralCode(msg.sender, _code);
    }

    function _setReferralCode(address _recipient, bytes32 _code) private {
        referralCodes[_recipient] = _code;

        emit SetReferralCode(_recipient, _code);
    }

    function getReferralInfo(address _recipient) external view returns (bytes32 code, address referrer) {
        code = referralCodes[_recipient];

        if (code != bytes32(0)) {
            referrer = codeOwners[code];
        }
    }
}