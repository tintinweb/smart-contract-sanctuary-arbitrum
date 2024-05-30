// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v5.0.0) (access/Ownable.sol)

pragma solidity ^0.8.20;

import {Context} from "../utils/Context.sol";

/**
 * @dev Contract module which provides a basic access control mechanism, where
 * there is an account (an owner) that can be granted exclusive access to
 * specific functions.
 *
 * The initial owner is set to the address provided by the deployer. This can
 * later be changed with {transferOwnership}.
 *
 * This module is used through inheritance. It will make available the modifier
 * `onlyOwner`, which can be applied to your functions to restrict their use to
 * the owner.
 */
abstract contract Ownable is Context {
    address private _owner;

    /**
     * @dev The caller account is not authorized to perform an operation.
     */
    error OwnableUnauthorizedAccount(address account);

    /**
     * @dev The owner is not a valid owner account. (eg. `address(0)`)
     */
    error OwnableInvalidOwner(address owner);

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the address provided by the deployer as the initial owner.
     */
    constructor(address initialOwner) {
        if (initialOwner == address(0)) {
            revert OwnableInvalidOwner(address(0));
        }
        _transferOwnership(initialOwner);
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
        if (owner() != _msgSender()) {
            revert OwnableUnauthorizedAccount(_msgSender());
        }
    }

    /**
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby disabling any functionality that is only available to the owner.
     */
    function renounceOwnership() public virtual onlyOwner {
        _transferOwnership(address(0));
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        if (newOwner == address(0)) {
            revert OwnableInvalidOwner(address(0));
        }
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
// OpenZeppelin Contracts (last updated v5.0.0) (token/ERC20/IERC20.sol)

pragma solidity ^0.8.20;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20 {
    /**
     * @dev Emitted when `value` tokens are moved from one account (`from`) to
     * another (`to`).
     *
     * Note that `value` may be zero.
     */
    event Transfer(address indexed from, address indexed to, uint256 value);

    /**
     * @dev Emitted when the allowance of a `spender` for an `owner` is set by
     * a call to {approve}. `value` is the new allowance.
     */
    event Approval(address indexed owner, address indexed spender, uint256 value);

    /**
     * @dev Returns the value of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the value of tokens owned by `account`.
     */
    function balanceOf(address account) external view returns (uint256);

    /**
     * @dev Moves a `value` amount of tokens from the caller's account to `to`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address to, uint256 value) external returns (bool);

    /**
     * @dev Returns the remaining number of tokens that `spender` will be
     * allowed to spend on behalf of `owner` through {transferFrom}. This is
     * zero by default.
     *
     * This value changes when {approve} or {transferFrom} are called.
     */
    function allowance(address owner, address spender) external view returns (uint256);

    /**
     * @dev Sets a `value` amount of tokens as the allowance of `spender` over the
     * caller's tokens.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * IMPORTANT: Beware that changing an allowance with this method brings the risk
     * that someone may use both the old and the new allowance by unfortunate
     * transaction ordering. One possible solution to mitigate this race
     * condition is to first reduce the spender's allowance to 0 and set the
     * desired value afterwards:
     * https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
     *
     * Emits an {Approval} event.
     */
    function approve(address spender, uint256 value) external returns (bool);

    /**
     * @dev Moves a `value` amount of tokens from `from` to `to` using the
     * allowance mechanism. `value` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(address from, address to, uint256 value) external returns (bool);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v5.0.1) (utils/Context.sol)

pragma solidity ^0.8.20;

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

    function _contextSuffixLength() internal view virtual returns (uint256) {
        return 0;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v5.0.0) (utils/ReentrancyGuard.sol)

pragma solidity ^0.8.20;

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
    uint256 private constant NOT_ENTERED = 1;
    uint256 private constant ENTERED = 2;

    uint256 private _status;

    /**
     * @dev Unauthorized reentrant call.
     */
    error ReentrancyGuardReentrantCall();

    constructor() {
        _status = NOT_ENTERED;
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
        // On the first call to nonReentrant, _status will be NOT_ENTERED
        if (_status == ENTERED) {
            revert ReentrancyGuardReentrantCall();
        }

        // Any calls to nonReentrant after this point will fail
        _status = ENTERED;
    }

    function _nonReentrantAfter() private {
        // By storing the original value once again, a refund is triggered (see
        // https://eips.ethereum.org/EIPS/eip-2200)
        _status = NOT_ENTERED;
    }

    /**
     * @dev Returns true if the reentrancy guard is currently set to "entered", which indicates there is a
     * `nonReentrant` function in the call stack.
     */
    function _reentrancyGuardEntered() internal view returns (bool) {
        return _status == ENTERED;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

/**
 * @title Endoweth - an ERC-20 endowment contract that distributes tokens based on expected returns
 * @author @actuallymentor aka mentor.eth
 * @notice This contract is in beta and unaudited. Use at your own risk.
 */
contract Endoweth is Ownable, ReentrancyGuard {
    // Endowee is the address that receives the distributed tokens
    address public endowee;

    // Interval for distribution in seconds
    uint256 public distributionInterval;

    /**
     * @dev Constructor to set the endowee and distribution interval
     * @param _owner The address that deploys the contract
     * @param _endowee The address that receives the distributed tokens
     * @param _distributionInterval Interval for distribution in seconds
     * @notice The endowee cannot be the zero address
     * @notice The distribution interval cannot be zero
     */
    constructor(
        address _owner,
        address _endowee,
        uint256 _distributionInterval
    ) Ownable(_owner) {
        require(_endowee != address(0), "Endowee cannot be the zero address");
        require(
            _distributionInterval > 0,
            "Interval must be greater than zero"
        );
        endowee = _endowee;
        distributionInterval = _distributionInterval;
    }

    /* ///////////////////////
    // 👩‍🦳 Accountant section
    /////////////////////// */

    // Permission modifier for owner or accountants
    modifier onlyOwnerOrAccountant() {
        require(
            owner() == _msgSender() || accountants[_msgSender()],
            "Accountant Unauthorized"
        );
        _;
    }

    // Keep track of accountants in both mapping (for quick lookup) and array (for iteration)
    mapping(address => bool) public accountants;
    address[] public accountantsList;

    // Accountant events
    event AccountantAdded(address indexed accountant);
    event AccountantRemoved(address indexed accountant);

    /**
     * @dev Add accountant
     * @param accountant The address of the accountant
     */
    function addAccountant(address accountant) external onlyOwner {
        // If the accountant is alread in the list, error
        for (uint i = 0; i < accountantsList.length; i++) {
            if (accountantsList[i] == accountant) {
                revert("Accountant already added");
            }
        }

        // Mark address as accountant and add to accountant list
        accountants[accountant] = true;
        accountantsList.push(accountant);
        emit AccountantAdded(accountant);
    }

    /**
     * @dev Remove accountant
     * @param accountant The address of the accountant
     */
    function removeAccountant(address accountant) external onlyOwner {
        require(accountants[accountant], "Accountant not found");
        accountants[accountant] = false;
        for (uint256 i = 0; i < accountantsList.length; i++) {
            if (accountantsList[i] == accountant) {
                accountantsList[i] = accountantsList[
                    accountantsList.length - 1
                ];
                accountantsList.pop();
                break;
            }
        }
        emit AccountantRemoved(accountant);
    }

    /* ///////////////////////
    // 📝 Accounting section
    /////////////////////// */

    // Accounting events
    event EndoweeChanged(address newEndowee);
    event TokenAdded(address token);
    event TokenRemoved(address token);
    event ExpectedReturnUpdated(address token, uint256 newExpectedReturn);

    // Save token info for accounting
    struct TokenInfo {
        uint256 expectedAnnualReturn; // Percentage of expected annual return (e.g., 500 for 5%)
        uint256 lastDistributionTime;
    }
    mapping(address => TokenInfo) public tokens;

    // Save token list for accounting
    address[] public tokenList;

    /**
     * @dev Add ERC-20 token to the endowment. Adding a token means that the contract will distribute it based on the expected return. Tokens held by the address that are not in the token list will not be distributed.
     * @param token The address of the token
     * @param expectedReturn Percentage of expected annual return (e.g., 500 for 5%)
     */
    function addToken(
        address token,
        uint256 expectedReturn
    ) external onlyOwnerOrAccountant {
        require(tokens[token].lastDistributionTime == 0, "Token already added");
        require(token != address(0), "Token address cannot be zero");
        require(
            expectedReturn > 0,
            "Expected return must be greater than zero"
        );
        require(
            tokens[token].expectedAnnualReturn == 0,
            "Token already managed"
        );

        // Set the token data
        tokens[token] = TokenInfo(expectedReturn, block.timestamp);
        tokenList.push(token);
        emit TokenAdded(token);
    }

    /**
     * @dev Remove token from the endowment. Removed tokens are not touched by the contract anymore.
     * @param token The address of the token
     */
    function removeToken(address token) external onlyOwnerOrAccountant {
        require(tokens[token].expectedAnnualReturn > 0, "Token not managed");
        delete tokens[token];
        for (uint256 i = 0; i < tokenList.length; i++) {
            // If the token is not the one we're looking for, continue
            if (tokenList[i] != token) continue;

            // If the token is the one we're looking for, remove it from the list and break the loop
            tokenList[i] = tokenList[tokenList.length - 1];
            tokenList.pop();
            emit TokenRemoved(token);
            break;
        }
    }

    function changeEndowee(address newEndowee) external onlyOwner {
        require(newEndowee != address(0), "Endowee cannot be the zero address");
        endowee = newEndowee;
        emit EndoweeChanged(newEndowee);
    }

    /* ///////////////////////////////
    // 📈 Distribution administration
    /////////////////////////////// */

    event DistributionIntervalUpdated(uint256 newInterval);
    event Distributed(address token, uint256 amount);

    /**
     * @dev Update expected return for a token
     * @param token The address of the token
     * @param newExpectedReturn Percentage of expected annual return (e.g., 500 for 5%)
     */
    function updateExpectedReturn(
        address token,
        uint256 newExpectedReturn
    ) external onlyOwnerOrAccountant {
        require(
            newExpectedReturn > 0,
            "Expected return must be greater than zero"
        );
        tokens[token].expectedAnnualReturn = newExpectedReturn;
        emit ExpectedReturnUpdated(token, newExpectedReturn);
    }

    /**
     * @dev Update distribution interval
     * @param newInterval Interval for distribution in seconds
     */
    function updateDistributionInterval(
        uint256 newInterval
    ) external onlyOwnerOrAccountant {
        require(newInterval > 0, "Interval must be greater than zero");
        distributionInterval = newInterval;
        emit DistributionIntervalUpdated(newInterval);
    }

    /* ///////////////////////
    // 📤 Distribution logic
    /////////////////////// */

    /**
     * @dev Trigger distribution of accumulated tokens
     * @notice This function can be called by anyone
     */
    function triggerDistribution() external nonReentrant {
        // Check which tokens in the list are ready for distribution
        for (uint256 i = 0; i < tokenList.length; i++) {
            // Get token info
            address token = tokenList[i];

            // Calculate distributable amount based on return stats and whether the distribution interval passed
            uint256 distributableAmount = calculateDistributableAmount(token);

            // Check if the contract has enough tokens to distribute the calculated amount
            bool hasSufficientBalance = IERC20(token).balanceOf(
                address(this)
            ) >= distributableAmount;

            // If there is a distributable amount and the contract has enough tokens, distribute the tokens
            // this should always be the case as calculateDistributableAmount should return 0 if there are no tokens
            if (distributableAmount > 0 && hasSufficientBalance) {
                // Transfer the tokens to the endowee
                require(
                    IERC20(token).transfer(endowee, distributableAmount),
                    "Transfer failed"
                );
                // Update the accumulated balance and last distribution time
                tokens[token].lastDistributionTime = block.timestamp;
                emit Distributed(token, distributableAmount);
            }

            // Emit an insufficient balance event if the contract does not have enough tokens
            if (distributableAmount > 0 && !hasSufficientBalance) {
                emit Distributed(token, 0);
            }
        }
    }

    /**
     * @dev Calculate distributable amount for a token
     * @param token The address of the token
     * @return The amount of tokens that can be distributed
     */
    function calculateDistributableAmount(
        address token
    ) internal view returns (uint256) {
        // Check if the expected return and last distribution time are set
        require(
            tokens[token].expectedAnnualReturn > 0,
            "Expected return not set"
        );
        require(
            tokens[token].lastDistributionTime > 0,
            "Last distribution time not set"
        );

        // Calculate the time elapsed since the last distribution
        TokenInfo memory info = tokens[token];

        // Calculate the seconds elapsed since the last distribution
        uint256 secondsElapsed = block.timestamp - info.lastDistributionTime;

        // Solidity doesn't do float math, so we'll use another base
        uint256 calcBase = 1e32;
        uint256 yearInSeconds = 31536000;

        // Take the yearly expected return, and convert it to expected return per second with high precision
        // note the percentage is expressed as an int, so 500 is 5%.
        uint256 returnWithLargeBase = (info.expectedAnnualReturn * calcBase) /
            10_000;
        uint256 expectedReturnPerSecond = returnWithLargeBase / yearInSeconds;

        // Calculate the distribution based on seconds passed since the last distribution
        uint256 distributableAmountWithLargeBase = (expectedReturnPerSecond *
            secondsElapsed *
            IERC20(token).balanceOf(address(this)));
        uint256 distributableAmount = distributableAmountWithLargeBase /
            calcBase;

        return distributableAmount;
    }

    /**
     * @dev Helper function that returns the amount of tokens that have distributable amounts
     * @return The amount of tokens that have distributable amounts
     */
    function getDistributableTokenCount() external view returns (uint256) {
        uint256 count = 0;
        for (uint256 i = 0; i < tokenList.length; i++) {
            if (calculateDistributableAmount(tokenList[i]) > 0) {
                count++;
            }
        }
        return count;
    }

    /**
     * @dev Helper function that returns the distributable amounts of each token
     * @return The distributable amounts of each token
     */
    function getDistributableAmounts()
        external
        view
        returns (address[] memory, uint256[] memory)
    {
        // Create arrays to store tokens with distributable amounts and their amounts
        address[] memory tokensWithDistributableAmounts = new address[](
            tokenList.length
        );
        uint256[] memory distributableAmounts = new uint256[](tokenList.length);

        // Iterate over the token list and calculate the distributable amount for each token
        for (uint256 i = 0; i < tokenList.length; i++) {
            uint256 distributableAmount = calculateDistributableAmount(
                tokenList[i]
            );
            if (distributableAmount > 0) {
                tokensWithDistributableAmounts[i] = tokenList[i];
                distributableAmounts[i] = distributableAmount;
            }
        }

        // Return the arrays, where the index of the address in the first array corresponds to the index of the amount in the second array
        return (tokensWithDistributableAmounts, distributableAmounts);
    }

    /* ///////////////////////////////
    // 🧶 Unwinding logic
    // /////////////////////////////*/

    /**
     * @dev Send the full ERC20 balance of a token address that is unmanaged to the contract owner
     * @param token The address of the token
     * @notice This function can only be called by the owner
     */
    function unwindToken(address token) external onlyOwner {
        // Only allow unmanaged tokens to be unwound
        require(tokens[token].expectedAnnualReturn == 0, "Token managed");

        // Get the balance of the token
        uint256 balance = IERC20(token).balanceOf(address(this));

        // Transfer the balance to the owner
        require(IERC20(token).transfer(owner(), balance), "Transfer failed");

        // Emit an event with the unwound token and the amount
        emit Distributed(token, balance);
    }
}