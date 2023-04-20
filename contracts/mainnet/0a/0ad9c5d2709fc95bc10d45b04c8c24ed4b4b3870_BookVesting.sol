// SPDX-License-Identifier: MIT
pragma solidity ^0.8.15;

import { Ownable } from "@openzeppelin/contracts/access/Ownable.sol";
import { ReentrancyGuard } from "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import { IBookToken } from "./interfaces/IBookToken.sol";

contract BookVesting is Ownable, ReentrancyGuard {

    mapping(address => uint256) public allotments;
    mapping(address => uint256) public withdrawn;

    address public immutable book;

    uint256 public immutable startTime; // beginning of 60 month vesting window (unix timestamp)
    uint256 public immutable totalAllotments; // Total $BOOK tokens vested
    uint256 public totalWithdrawn;
    bool private allotmentsSet;

    string public CONTRACT_DESCRIPTION;
    uint256 private constant A_FACTOR = 10**18;
    uint256 public constant PERIOD_DIVISOR = 16666666666666666;
    
    event TokensClaimed(address indexed account, uint256 amountBook);
    event AccountUpdated(address oldAccount, address newAccount, uint256 allotted, uint256 withdrawn);
   
    constructor(address _vestAdmin, uint256 _startTime, uint256 _totalVested, string memory _description) {
        _transferOwnership(_vestAdmin);
        startTime = _startTime; 
        totalAllotments = _totalVested;
        CONTRACT_DESCRIPTION = _description;
        book = msg.sender;
    }

    function setAllotments(
        address[] calldata _accounts, 
        uint16[] calldata _percentShare
    ) external onlyOwner returns (int256 allocated, int256 variance) {
        require(!allotmentsSet, "Allotments already set");
        require(_accounts.length == _percentShare.length, "Array length mismatch");
        uint256 s;
        for (uint256 i = 0; i < _accounts.length; i++) {
            require(allotments[_accounts[i]] == 0, "Duplicate account");
            s = (totalAllotments * _percentShare[i]) / 10000;
            allotments[_accounts[i]] = s;
            allocated += int256(s);
        }
        variance = int256(totalAllotments) - allocated;
        require(variance < 0 ? variance > -1 ether : variance < 1 ether, "Incorrect amounts allotted");
        allotmentsSet = true;
    }

    function updateAccountAddress(address _oldAccount, address _newAccount) external {
        require(msg.sender == _oldAccount, "Only callable by _oldAccount");
        require(allotments[_oldAccount] > 0, "_oldAccount has no allotments");
        require(allotments[_newAccount] == 0, "_newAccount already allotted");
        allotments[_newAccount] = allotments[_oldAccount];
        withdrawn[_newAccount] = withdrawn[_oldAccount];
        delete allotments[_oldAccount];
        delete withdrawn[_oldAccount];

        emit AccountUpdated(_oldAccount, _newAccount, allotments[_newAccount], withdrawn[_newAccount]);
    }

    function recoverAccount(address _oldAccount, address _newAccount) external onlyOwner {
        require(allotments[_oldAccount] > 0, "_oldAccount has no allotments");
        require(allotments[_newAccount] == 0, "_newAccount already allotted");
        allotments[_newAccount] = allotments[_oldAccount];
        withdrawn[_newAccount] = withdrawn[_oldAccount];
        delete allotments[_oldAccount];
        delete withdrawn[_oldAccount];

        emit AccountUpdated(_oldAccount, _newAccount, allotments[_newAccount], withdrawn[_newAccount]);
    }

    function claimTokens() external nonReentrant {
        uint256 withdrawable = _calculateWithdrawableAmounts(msg.sender);
        require(withdrawable > 0, "Nothing to claim right now");

        IBookToken(book).mintVestedTokens(withdrawable, msg.sender);
        withdrawn[msg.sender] += withdrawable;
        totalWithdrawn += withdrawable;

        emit TokensClaimed(msg.sender, withdrawable);
    }

    function calculateWithdrawableAmounts(address _account) external view returns (uint256 withdrawable) {
        return _calculateWithdrawableAmounts(_account);
    }

    function claimableBook() external view returns (uint256 withdrawable) {
        if (block.timestamp < startTime) { return 0; }
        uint256 available = totalAllotments - totalWithdrawn; // amount left that can be claimed
        uint256 periodAmount = (totalAllotments * PERIOD_DIVISOR) / A_FACTOR; // 1/60th of original allotment;

        uint256 vestedTime = (getElapsedTime() / 30 days) + 1;
        uint256 unlocked = periodAmount * vestedTime;
        uint256 unclaimed = unlocked - totalWithdrawn;
        withdrawable = unclaimed < available ? unclaimed : available;
    }

    function _calculateWithdrawableAmounts(address _address) internal view returns (uint256 withdrawable) {
        if (block.timestamp < startTime) { return 0; }
        uint256 original = allotments[_address]; // initial allotment
        uint256 claimed = withdrawn[_address]; // amount user has claimed
        uint256 available = original - claimed; // amount left that can be claimed
        uint256 periodAmount = (original * PERIOD_DIVISOR) / A_FACTOR; // 1/60th of user's original allotment;

        uint256 vestedTime = (getElapsedTime() / 30 days) + 1;
        uint256 unlocked = periodAmount * vestedTime;
        uint256 unclaimed = unlocked - claimed;
        withdrawable = unclaimed < available ? unclaimed : available;    
    }

    function getElapsedTime() internal view returns (uint256) {
        return block.timestamp - startTime;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.16;

interface IBookToken {

	event BridgeInitiated(address indexed user, uint256 amount, uint256 fromChain, uint256 toChain);
    
    event BridgeCompleted(address indexed user, uint256 amount, uint256 fromChain, uint256 toChain);
    
    event BridgeCanceled(address indexed user, uint256 amount, uint256 fromChain, uint256 toChain);
    
    event CrossChainExecutorSet(address indexed executor);
    
    event FutureRewardsMinted(address indexed to, uint256 amount, uint256 remainingFutureMint);

    event VestedTokensMinted(address indexed vestingContract, address indexed to, uint256 amount);
    
    event ContractUnpaused(uint256 timeStamp);
    
    event CrossChainEnabled(uint256 timeStamp);
    
    event SingleChainEnabled(uint256 enabledChainId, uint256 gasForBridge, uint256 timeStamp);
    
    event SingleChainDisabled(uint256 disabledChainId, uint256 timeStamp);
    
    event CrossChainDisabled(uint256 timeStamp);
    
    event TokenRescued(address indexed token, uint256 amount);

    function setAllowedWhilePaused(address account, bool flag) external;
    
    function unPauseContract() external;

    function setCrossChainExecutor(address _executor, bool revoke) external;

    function enableCrossChain(uint256[] calldata _chainIds, uint256[] calldata _gas) external;

    function enableSingleChain(uint256 _chainId, uint256 _gas) external;

    function disableSingleChain(uint256 _chainId) external;

    function pauseCrossChain() external;

    function bridgeFrom(uint256 amount, uint256 toChain) external payable;

    function bridgeTo(address account, uint256 amount, uint256 fromChain) external;

    function cancelBridge(address account, uint256 amount, uint256 toChain) external;

    function mintFutureRewards(uint256 amount) external;

    function mintFutureRewards(uint256 amount, address to) external;

    function mintVestedTokens(uint256 amount, address to) external;

    function rescueERC20(address token, uint256 amount) external;

    function burn(uint256 amount) external;

    function getEnabledChains() external view returns (uint256[] memory);

    function maxSupply() external view returns (uint256);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.8.0) (security/ReentrancyGuard.sol)

pragma solidity ^0.8.0;

/**
 * @dev Contract module that helps prevent reentrant calls to a function.
 *
 * Inheriting from `ReentrancyGuard` will make the {nonReentrant} modifier
 * available, which can be applied to functions to make sure there are no nested
 * (reentrant) calls to them.
 *
 * Note that because there is a single `nonReentrant` guard, functions marked as
 * `nonReentrant` may not call one another. This can be worked around by making
 * those functions `private`, and then adding `external` `nonReentrant` entry
 * points to them.
 *
 * TIP: If you would like to learn more about reentrancy and alternative ways
 * to protect against it, check out our blog post
 * https://blog.openzeppelin.com/reentrancy-after-istanbul/[Reentrancy After Istanbul].
 */
abstract contract ReentrancyGuard {
    // Booleans are more expensive than uint256 or any type that takes up a full
    // word because each write operation emits an extra SLOAD to first read the
    // slot's contents, replace the bits taken up by the boolean, and then write
    // back. This is the compiler's defense against contract upgrades and
    // pointer aliasing, and it cannot be disabled.

    // The values being non-zero value makes deployment a bit more expensive,
    // but in exchange the refund on every call to nonReentrant will be lower in
    // amount. Since refunds are capped to a percentage of the total
    // transaction's gas, it is best to keep them low in cases like this one, to
    // increase the likelihood of the full refund coming into effect.
    uint256 private constant _NOT_ENTERED = 1;
    uint256 private constant _ENTERED = 2;

    uint256 private _status;

    constructor() {
        _status = _NOT_ENTERED;
    }

    /**
     * @dev Prevents a contract from calling itself, directly or indirectly.
     * Calling a `nonReentrant` function from another `nonReentrant`
     * function is not supported. It is possible to prevent this from happening
     * by making the `nonReentrant` function external, and making it call a
     * `private` function that does the actual work.
     */
    modifier nonReentrant() {
        _nonReentrantBefore();
        _;
        _nonReentrantAfter();
    }

    function _nonReentrantBefore() private {
        // On the first call to nonReentrant, _status will be _NOT_ENTERED
        require(_status != _ENTERED, "ReentrancyGuard: reentrant call");

        // Any calls to nonReentrant after this point will fail
        _status = _ENTERED;
    }

    function _nonReentrantAfter() private {
        // By storing the original value once again, a refund is triggered (see
        // https://eips.ethereum.org/EIPS/eip-2200)
        _status = _NOT_ENTERED;
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