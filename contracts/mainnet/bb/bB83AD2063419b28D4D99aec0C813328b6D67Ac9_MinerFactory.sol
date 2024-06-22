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
// OpenZeppelin Contracts (last updated v5.0.0) (access/Ownable2Step.sol)

pragma solidity ^0.8.20;

import {Ownable} from "./Ownable.sol";

/**
 * @dev Contract module which provides access control mechanism, where
 * there is an account (an owner) that can be granted exclusive access to
 * specific functions.
 *
 * The initial owner is specified at deployment time in the constructor for `Ownable`. This
 * can later be changed with {transferOwnership} and {acceptOwnership}.
 *
 * This module is used through inheritance. It will make available all functions
 * from parent (Ownable).
 */
abstract contract Ownable2Step is Ownable {
    address private _pendingOwner;

    event OwnershipTransferStarted(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Returns the address of the pending owner.
     */
    function pendingOwner() public view virtual returns (address) {
        return _pendingOwner;
    }

    /**
     * @dev Starts the ownership transfer of the contract to a new account. Replaces the pending transfer if there is one.
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual override onlyOwner {
        _pendingOwner = newOwner;
        emit OwnershipTransferStarted(owner(), newOwner);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`) and deletes any pending owner.
     * Internal function without access restriction.
     */
    function _transferOwnership(address newOwner) internal virtual override {
        delete _pendingOwner;
        super._transferOwnership(newOwner);
    }

    /**
     * @dev The new owner accepts the ownership transfer.
     */
    function acceptOwnership() public virtual {
        address sender = _msgSender();
        if (pendingOwner() != sender) {
            revert OwnableUnauthorizedAccount(sender);
        }
        _transferOwnership(sender);
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
pragma solidity ^0.8.24;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
import "@openzeppelin/contracts/access/Ownable2Step.sol";

/**
 * @title MinerFactory
 * @dev This contract is responsible for creating instances of the Miner contract.
 * It inherits from the ReentrancyGuard and Ownable2Step contracts.
 */
contract MinerFactory is ReentrancyGuard, Ownable2Step {

    /**
     * @dev Public variable that stores the address of the miner contract.
     */
    address public minerContract;

    /**
     * @dev The ERC20 token used for Mint.
     * @notice This token has 6 decimal places.
     */
    IERC20 public tokenForMint;


    /**
     * @dev Public variable that stores the address of the beneficiaries.
     */
    address public beneficiaries;

    /**
     * @dev The timestamp when the MinerFactory contract starts.
     */
    uint256 public startTime;

    /**
     * @dev Represents the end time for a specific operation.
     */
    uint256 public endTime;

    /**
     * @dev A mapping that stores the prices of different miner types.
     * The keys of the mapping are instances of the enum type `MinerType`,
     * and the values are the corresponding prices represented as `uint256`.
     */
    mapping(MinerType => uint256) public minerPrices;

    /**
     * @dev Enum representing the different types of Haya Miners.
     * Mini: Represents a Mini Miner.
     * Bronze: Represents a Bronze Miner.
     * Silver: Represents a Silver Miner.
     * Gold: Represents a Gold Miner.
     */
    enum MinerType {
        Mini,
        Bronze,
        Silver,
        Gold
    }

    /**
     * @dev Emitted when a miner is minted.
     * @param user The address of the user who minted the miner.
     * @param minerType The type of the miner that was minted.
     * @param quantity The quantity of miners that were minted.
     */
    event MinerMinted(address indexed user, uint8 minerType, uint256 quantity);
    
    /**
     * @dev Emitted when the beneficiaries address is set.
     * @param beneficiaries The new address of the beneficiaries.
     */
    event BeneficiariesSet(address beneficiaries);

    /**
     * @dev Constructor function for the MinerFactory contract.
     * @param _minerContract The address of the miner contract.
     * @param _tokenForMint The address of the token used for minting.
     * @param _owner The address of the contract owner.
     * @param _startTime The start time of the contract.
     * @param _endTime The end time of the contract.
     * @param _beneficiaries The address of the beneficiaries.
     */
    constructor(
        address _minerContract,
        address _tokenForMint,
        address _owner,
        uint256 _startTime,
        uint256 _endTime,
        address _beneficiaries
    ) Ownable(_owner) {
        minerContract = _minerContract;
        tokenForMint = IERC20(_tokenForMint);
        startTime = _startTime;
        endTime = _endTime;
        beneficiaries = _beneficiaries;
        minerPrices[MinerType.Mini] = 10 * 10**6;
        minerPrices[MinerType.Bronze] = 100 * 10**6;
        minerPrices[MinerType.Silver] = 1_000 * 10**6;
        minerPrices[MinerType.Gold] = 10_000 * 10**6;
    }

    /**
     * @dev External function to mint multiple ERC1155 miners.
     * @param _minerTypes The types of miners to purchase.
     * @param _quantities The quantities of miners to purchase for each type.
     */
    function mintMiners(MinerType[] memory _minerTypes, uint256[] memory _quantities) external nonReentrant {
        require(_minerTypes.length == _quantities.length, "MinerFactory: Invalid input");
        require(startTime <= block.timestamp && (block.timestamp < endTime || endTime == 0), "MinerFactory: Invalid time");

        for (uint256 i = 0; i < _minerTypes.length; i++) {
            mintMiner(_minerTypes[i], _quantities[i]);
        }
    }

    /**
     * @dev Sets the end time for the mining process.
     * Can only be called by the contract owner.
     * 
     * @param _endTime The new end time for the mining process.
     */
    function setEndTime(uint256 _endTime) external onlyOwner {
        endTime = _endTime;
    }
    
    /**
     * @dev Sets the address of the beneficiaries.
     * Can only be called by the contract owner.
     * 
     * @param _beneficiaries The new address of the beneficiaries.
     */
    function setBeneficiaries(address _beneficiaries) external onlyOwner {
        beneficiaries = _beneficiaries;
        emit BeneficiariesSet(_beneficiaries);
    }

    /**
     * @dev Mints a specified quantity of miners of a given type for the caller.
     * @param _minerType The type of miner to be minted.
     * @param _quantity The quantity of miners to be minted.
     * @notice This function is internal and can only be called from within the contract.
     * @notice The caller must have a sufficient balance of the token for minting.
     * @notice The token for minting will be transferred from the caller to the beneficiaries.
     * @notice The minting process will be performed by the Miner contract.
     * @notice Emits a `MinerMinted` event with the caller's address, miner type, and quantity.
     */
    function mintMiner(MinerType _minerType, uint256 _quantity) internal {
        require(_minerType >= MinerType.Mini && _minerType <= MinerType.Gold, "MinerFactory: Invalid type");
        uint256 totalPrice = minerPrices[_minerType] * _quantity;
        require(tokenForMint.balanceOf(msg.sender) >= totalPrice, "MinerFactory: Insufficient balance");

        tokenForMint.transferFrom(msg.sender, beneficiaries, totalPrice);
        IMiner(minerContract).mint(msg.sender, uint256(_minerType), _quantity, "");
        emit MinerMinted(msg.sender, uint8(_minerType), _quantity);
    }

    /**
     * @dev Fallback function to reject any incoming Ether transfers.
     * Reverts the transaction to prevent accidental transfers to this contract.
     */
    receive() external payable {
        revert();
    }
}

/**
 * @title IMiner
 * @dev Interface for the Miner contract.
 */
interface IMiner {
    /**
     * @dev Mints new tokens and assigns them to the specified account.
     * @param account The address to which the tokens will be assigned.
     * @param id The unique identifier of the token.
     * @param amount The amount of tokens to mint.
     * @param data Additional data to pass to the mint function.
     */
    function mint(address account, uint256 id, uint256 amount, bytes calldata data) external;
}