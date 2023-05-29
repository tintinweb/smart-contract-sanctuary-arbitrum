// SPDX-License-Identifier: MIT

pragma solidity ^0.6.0;

import "../GSN/Context.sol";
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
contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor () internal {
        address msgSender = _msgSender();
        _owner = msgSender;
        emit OwnershipTransferred(address(0), msgSender);
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(_owner == _msgSender(), "Ownable: caller is not the owner");
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
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.6.0;

/*
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with GSN meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
 *
 * This contract is only required for intermediate, library-like contracts.
 */
abstract contract Context {
    function _msgSender() internal view virtual returns (address payable) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes memory) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.6.12;

interface IVault {
    event Deposit(
        address indexed caller,
        address indexed owner,
        uint256 assets,
        uint256 shares
    );

    event Withdraw(
        address indexed caller,
        address indexed receiver,
        uint256 assets,
        uint256 shares
    );

    event Fees(uint256 t0,uint256 t1);

    function deposit(uint256 amount, address receiver) external;

    function withdraw(
        uint256 amount,
        address receiver
    ) external returns (uint256 shares);

    function harvest() external;

    function pauseAndWithdraw() external;

    function unpauseAndDeposit() external;

    function emergencyExit(uint256 amount, address receiver) external;

    function changeAllowance(address token, address to) external;

    function pauseVault() external;

    function unpauseVault() external;

    function asset() external view returns (address);
}

// SPDX-License-Identifier: MIT

pragma solidity >0.6.0;

interface IVaultManager {
    struct VaultDetail {
        address vault;
        bool status;
    }
    event Status(address vault, bool isActive);
    event VaultAdded(address vault, address lpToken);

    function addVaultAddress(address lpToken, address vault) external;

    function changeAllowance(address token, address to, address vault) external;

    function emergencyPause(address vault) external;

    function unpauseVaultAndDepost(address vault) external;

    function pauseVault(address vault) external;

    function unpauseVault(address vault) external;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.6.12;

import "@openzeppelin/contracts/access/Ownable.sol";
import "../../interfaces/vaultManager/IVaultManager.sol";
import "../../interfaces/vault/IVault.sol";
contract VaultManager is IVaultManager, Ownable {
    address public immutable timelock;
    mapping(address => IVaultManager.VaultDetail) public Vault;

    constructor(address _timelock) public {
        require(_timelock != address(0), "Zero Address");
        timelock = _timelock;
    }

    modifier onlyTimelock() {
        require(msg.sender == timelock, "Call must come from timelock");
        _;
    }

    function addVaultAddress(
        address lpToken,
        address vault
    ) external override onlyOwner {
        require(IVault(vault).asset() == lpToken, "lpToken!=Vault's Asset");
        Vault[lpToken].vault = vault;
        Vault[lpToken].status = true;
        emit VaultAdded(lpToken, vault);
    }

    function emergencyPause(address vault) external override onlyTimelock {
        IVault(vault).pauseAndWithdraw();
        emit Status(vault, false);
    }

    function unpauseVaultAndDepost(
        address vault
    ) external override onlyTimelock {
        IVault(vault).unpauseAndDeposit();
        emit Status(vault, true);
    }

    function pauseVault(address vault) external override onlyTimelock {
        IVault(vault).pauseVault();
    }

    function unpauseVault(address vault) external override onlyTimelock {
        IVault(vault).unpauseVault();
    }

    function changeAllowance(
        address token,
        address to,
        address vault
    ) external override onlyTimelock {
        IVault(vault).changeAllowance(token, to);
    }
}