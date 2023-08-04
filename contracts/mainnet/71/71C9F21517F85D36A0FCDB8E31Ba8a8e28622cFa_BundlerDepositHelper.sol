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

// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.12;

import "@openzeppelin/contracts/access/Ownable.sol";
import "../interfaces/IStorage.sol";
import "../interfaces/IStakeManager.sol";

contract BundlerDepositHelper is Ownable {
    mapping(address => bool) public vaildEntryPoint;

    constructor(address _owner) {
        _transferOwnership(_owner);
    }

    function setValidEntryPoint(
        address entryPoint,
        bool isValid
    ) public onlyOwner {
        vaildEntryPoint[entryPoint] = isValid;
    }

    function batchDepositForBundler(
        address entryPoint,
        address[] memory bundlers,
        uint256[] memory amounts
    ) public payable {
        uint256 loopLength = bundlers.length;

        require(
            vaildEntryPoint[entryPoint],
            "BundlerDepositHelper: Invalid EntryPoint"
        );
        require(
            loopLength == amounts.length,
            "BundlerDepositHelper: Invalid input"
        );

        for (uint256 i = 0; i < loopLength; i++) {
            address bundler = bundlers[i];
            uint256 amount = amounts[i];

            require(
                IStorage(entryPoint).officialBundlerWhiteList(bundler),
                "BundlerDepositHelper: Invalid bundler"
            );

            payable(bundler).transfer(amount);
        }

        require(
            address(this).balance == 0,
            "BundlerDepositHelper: Invalid value"
        );
    }
}

// SPDX-License-Identifier: GPL-3.0-only
pragma solidity ^0.8.12;

/**
 * manage deposits and stakes.
 * deposit is just a balance used to pay for UserOperations (either by a paymaster or an account)
 * stake is value locked for at least "unstakeDelay" by a paymaster.
 */
interface IStakeManager {
    event Deposited(
        address from,
        address to,
        address account,
        uint256 increaseDeposit,
        uint256 totalDeposit
    );

    event Withdrawn(
        address indexed account,
        address withdrawAddress,
        uint256 amount
    );

    event RefundDeposit(address from, address to, uint256 refundAmount);

    /// Emitted once a stake is scheduled for withdrawal
    event StakeLocked(
        address indexed account,
        uint256 totalStaked,
        uint256 withdrawTime
    );

    /// Emitted once a stake is scheduled for withdrawal
    event StakeUnlocked(address indexed account, uint256 withdrawTime);

    event StakeWithdrawn(
        address indexed account,
        address withdrawAddress,
        uint256 amount
    );

    /**
     * @param deposit the account's deposit
     * @param staked true if this account is staked as a paymaster
     * @param stake actual amount of ether staked for this paymaster.
     * @param unstakeDelaySec minimum delay to withdraw the stake. must be above the global unstakeDelaySec
     * @param withdrawTime - first block timestamp where 'withdrawStake' will be callable, or zero if already locked
     * @dev sizes were chosen so that (deposit,staked) fit into one cell (used during handleOps)
     *    and the rest fit into a 2nd cell.
     *    112 bit allows for 2^15 eth
     *    64 bit for full timestamp
     *    32 bit allow 150 years for unstake delay
     */
    struct DepositInfo {
        uint112 deposit;
        bool staked;
        uint112 stake;
        uint32 unstakeDelaySec;
        uint64 withdrawTime;
    }

    //API struct used by getStakeInfo and simulateValidation
    struct StakeInfo {
        uint256 stake;
        uint256 unstakeDelaySec;
    }

    function getDepositInfo(
        address account
    ) external view returns (DepositInfo memory info);

    /// return the deposit (for gas payment) of the account
    function balanceOf(address account) external view returns (uint256);

    /**
     * add to the deposit of the given account
     */
    function depositTo(address account) external payable;

    /**
     * withdraw from the deposit.
     * @param withdrawAddress the address to send withdrawn value.
     * @param withdrawAmount the amount to withdraw.
     */
    function withdrawTo(
        address payable withdrawAddress,
        uint256 withdrawAmount
    ) external;
}

// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.12;

interface IStorage {
    struct bundlerInformation {
        address bundler;
        uint256 registeTime;
    }
    event UnrestrictedWalletSet(bool allowed);
    event UnrestrictedBundlerSet(bool allowed);
    event UnrestrictedModuleSet(bool allowed);
    event WalletFactoryWhitelistSet(address walletProxyFactory);
    event BundlerWhitelistSet(address indexed bundler, bool allowed);
    event ModuleWhitelistSet(address indexed module, bool allowed);

    function officialBundlerWhiteList(
        address bundler
    ) external view returns (bool);

    function moduleWhiteList(address module) external view returns (bool);

    function setUnrestrictedWallet(bool allowed) external;

    function setUnrestrictedBundler(bool allowed) external;

    function setUnrestrictedModule(bool allowed) external;

    function setBundlerOfficialWhitelist(
        address bundler,
        bool allowed
    ) external;

    function setWalletProxyFactoryWhitelist(address walletFactory) external;

    function setModuleWhitelist(address module, bool allowed) external;

    function validateModuleWhitelist(address module) external;

    function validateWalletWhitelist(address sender) external view;
}