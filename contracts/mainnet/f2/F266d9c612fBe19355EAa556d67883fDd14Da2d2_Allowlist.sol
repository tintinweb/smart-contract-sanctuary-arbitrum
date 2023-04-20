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

import { Ownable } from "@openzeppelin/contracts/access/Ownable.sol";

import { IAllowlist } from "./interfaces/IAllowlist.sol";
import { IAllowlistPlugin } from "./interfaces/IAllowlistPlugin.sol";

/* 
The Allowlist contract is primarily used to set up a list of whitelisted users. 
The CreditCaller contract will bind to this contract address, 
and when a user applies for a loan, it will check whether the user is on the whitelist.
*/

contract Allowlist is Ownable, IAllowlist {
    bool public passed;
    uint256 public totalPlugins;

    mapping(address => bool) public accounts;
    mapping(uint256 => address) public plugins;
    mapping(address => bool) private governors;

    event Permit(address[] indexed _account, uint256 _timestamp);
    event Forbid(address[] indexed _account, uint256 _timestamp);
    event TogglePassed(bool _currentState, uint256 _timestamp);
    event NewGovernor(address _newGovernor);
    event AddPlugin(uint256 _totalPlugins, address _plugin);

    modifier onlyGovernors() {
        require(isGovernor(msg.sender), "Allowlist: Caller is not governor");
        _;
    }

    /// @notice used to initialize the contract
    constructor(bool _passed) {
        passed = _passed;
    }

    /// @notice add plugin
    /// @param _plugin plugin address
    function addPlugin(address _plugin) public onlyOwner {
        require(_plugin != address(0), "Allowlist: _plugin cannot be 0x0");

        totalPlugins++;
        plugins[totalPlugins] = _plugin;

        emit AddPlugin(totalPlugins, _plugin);
    }

    /// @notice remove plugin
    /// @param _index plugin index
    function removePlugin(uint256 _index) public onlyOwner {
        require(_index > 0, "Allowlist: _plugin cannot be 0");
        require(plugins[_index] != address(0), "Allowlist: The plugin does not exist");

        totalPlugins--;
        delete plugins[_index];
    }

    /// @notice judge if its governor
    /// @param _governor owner address
    /// @return bool value
    function isGovernor(address _governor) public view returns (bool) {
        return governors[_governor];
    }

    /// @notice add governor
    /// @param _newGovernor governor address
    function addGovernor(address _newGovernor) public onlyOwner {
        require(_newGovernor != address(0), "Allowlist: _newGovernor cannot be 0x0");
        require(!isGovernor(_newGovernor), "Allowlist: _newGovernor is already governor");

        governors[_newGovernor] = true;

        emit NewGovernor(_newGovernor);
    }

    // @notice permit account
    /// @param _accounts user array
    function permit(address[] calldata _accounts) public onlyGovernors {
        for (uint256 i = 0; i < _accounts.length; i++) {
            require(_accounts[i] != address(0), "Allowlist: Account cannot be 0x0");

            accounts[_accounts[i]] = true;
        }

        emit Permit(_accounts, block.timestamp);
    }

    /// @notice forbid account
    /// @param _accounts user array
    function forbid(address[] calldata _accounts) public onlyGovernors {
        for (uint256 i = 0; i < _accounts.length; i++) {
            accounts[_accounts[i]] = false;
        }

        emit Forbid(_accounts, block.timestamp);
    }

    /// @notice toggle allow list
    function togglePassed() public onlyGovernors {
        passed = !passed;

        emit TogglePassed(passed, block.timestamp);
    }

    /// @notice check account
    /// @param _account user address
    /// @return boolean
    function can(address _account) external view override returns (bool) {
        if (passed) return true;

        for (uint256 i = 1; i <= totalPlugins; i++) {
            if (IAllowlistPlugin(plugins[i]).can(_account)) return true;
        }

        return accounts[_account];
    }

    /// @dev Rewriting methods to prevent accidental operations by the owner.
    function renounceOwnership() public virtual override onlyOwner {
        revert("Allowlist: Not allowed");
    }
}

// SPDX-License-Identifier: MIT

pragma solidity =0.8.4;

interface IAllowlist {
    function can(address _account) external view returns (bool);
}

// SPDX-License-Identifier: MIT

pragma solidity =0.8.4;

interface IAllowlistPlugin {
    function can(address _account) external view returns (bool);
}