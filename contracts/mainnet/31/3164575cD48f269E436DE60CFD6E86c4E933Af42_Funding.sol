// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";

interface IInsuranceFund {
    function getAllAmms() external view returns (IAmm[] memory);
}

interface IAmm {
    function nextFundingTime() external view returns (uint256);
}

interface IClearingHouse {
    function settleFunding(address _amm) external;
}

contract Funding is Ownable {
    IInsuranceFund insuranceFund;
    IClearingHouse clearingHouse;
    mapping(address => bool) private _whitelistAmms;

    constructor(address _insuranceFund, address _clearingHouse) {
        insuranceFund = IInsuranceFund(_insuranceFund);
        clearingHouse = IClearingHouse(_clearingHouse);
    }

    function setWhitelist(address[] memory _wls, bool[] memory _statuses)
        external
        onlyOwner
    {
        uint256 len = _wls.length;
        require(len == _statuses.length, "length mismatch");
        for (uint256 i; i < len; ) {
            address wl = _wls[i];
            bool status = _statuses[i];
            bool currentStatus = _whitelistAmms[wl];
            if (status != currentStatus) {
                _whitelistAmms[wl] = status;
            }
            unchecked {
                ++i;
            }
        }
    }

    function updateBaseContracts(address _insuranceFund, address _clearingHouse)
        external
        onlyOwner
    {
        insuranceFund = IInsuranceFund(_insuranceFund);
        clearingHouse = IClearingHouse(_clearingHouse);
    }

    function action() external {
        IAmm[] memory amms = insuranceFund.getAllAmms();

        bool executed = false;
        for (uint256 i; i < amms.length; i++) {
            uint256 nextFundingTime = amms[i].nextFundingTime();
            if (
                nextFundingTime <= block.timestamp &&
                _whitelistAmms[address(amms[i])]
            ) {
                clearingHouse.settleFunding(address(amms[i]));
                executed = true;
            }
        }

        if (!executed) {
            revert("funding not ready");
        }
    }

    function checker()
        external
        view
        returns (bool canExec, bytes memory execPayload)
    {
        execPayload = abi.encodeCall(Funding.action, ());

        IAmm[] memory amms = insuranceFund.getAllAmms();

        for (uint256 i; i < amms.length; i++) {
            uint256 nextFundingTime = amms[i].nextFundingTime();
            if (nextFundingTime <= block.timestamp) return (true, execPayload);
        }
        return (false, bytes("funding not ready"));
    }
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