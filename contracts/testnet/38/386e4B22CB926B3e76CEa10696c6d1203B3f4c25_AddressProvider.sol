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

// SPDX-License-Identifier: BUSL-1.1

pragma solidity 0.8.15;

import "@openzeppelin/contracts/access/Ownable.sol";
import "../Constant.sol";


contract Controllable is Ownable {

    address public controller;

    modifier onlyController() {
        require(msg.sender == controller, "Not controller");
        _;
    }

    event ChangeController(address oldAddress, address newAddress);

    function changeController(address newController) public onlyOwner {
        require(newController != Constant.ZERO_ADDRESS, "Invalid Address");
        emit ChangeController(controller, newController);
        controller = newController;
    }
}

// SPDX-License-Identifier: BUSL-1.1

pragma solidity 0.8.15;


import "../../base/Controllable.sol";
import "../../interfaces/IAddressProvider.sol";

contract AddressProvider is IAddressProvider, Controllable {

    mapping(AddressKey => address) public addressMap;

    event SetAddress(AddressKey key, address value);
 
    function setAddress(AddressKey key, address value) public onlyController {
        addressMap[key] = value;
        emit SetAddress(key, value);
    }

    function setAddresses(AddressKey[] memory keys, address[] memory values) public onlyController {
        uint len = keys.length;
        require(len > 0 && values.length == len, "Invalid inputs");

        AddressKey key;
        address value;
        for (uint n=0; n<len; n++) {
            key = keys[n];
            value = values[n];
            addressMap[key] = value;
            emit SetAddress(key, value);
        }
    }

    function getAddress(AddressKey key) external override view returns (address) {
        return addressMap[key];
    }

    function getOfficialAddresses() external override view returns (address a, address b) {
        a = addressMap[AddressKey.DaoMultiSig];
        b = addressMap[AddressKey.OfficialSigner];
    }

    function getTokenAddresses() external override view returns (address a, address b) {
        a = addressMap[AddressKey.Launch];
        b = addressMap[AddressKey.GovernanceLaunch];
    }

    function getFeeAddresses() external override view returns (address[3] memory values) {
        values[0] = addressMap[AddressKey.ReferralRewardVault];
        values[1] = addressMap[AddressKey.TreasuryVault];
        values[2] = addressMap[AddressKey.DevelopersVault];
    }
}

// SPDX-License-Identifier: BUSL-1.1


pragma solidity 0.8.15;

library Constant {

    address public constant ZERO_ADDRESS                        = address(0);
    uint    public constant E18                                 = 1e18;
    uint    public constant PCNT_100                            = 1e18;
    uint    public constant PCNT_50                             = 5e17;
    uint    public constant E12                                 = 1e12;
    
    // SaleTypes
    uint8    public constant TYPE_IDO                            = 0;
    uint8    public constant TYPE_OTC                            = 1;
    uint8    public constant TYPE_NFT                            = 2;

    uint8    public constant PUBLIC                              = 0;
    uint8    public constant STAKER                              = 1;
    uint8    public constant WHITELISTED                         = 2;

    // Register Campaign
    uint    public constant MAX_REBATE_PCNT                     = 5e16; // 5% max   

    // Misc
    bytes public constant ETH_SIGN_PREFIX                       = "\x19Ethereum Signed Message:\n32";

}

// SPDX-License-Identifier: BUSL-1.1

pragma solidity 0.8.15;

enum AddressKey {

    // Dao MultiSig
    DaoMultiSig,
    OfficialSigner,

    // Token
    Launch,
    GovernanceLaunch, // Staked Launch

    // Fees Addresses
    ReferralRewardVault,
    TreasuryVault,
    DevelopersVault
}

interface IAddressProvider {
    function getAddress(AddressKey key) external view returns (address);
    function getOfficialAddresses() external view returns (address a, address b);
    function getTokenAddresses() external view returns (address a, address b);
    function getFeeAddresses() external view returns (address[3] memory values);
}