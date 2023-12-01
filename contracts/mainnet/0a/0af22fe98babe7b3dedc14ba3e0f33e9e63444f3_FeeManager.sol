// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Ownable} from "openzeppelin-contracts/access/Ownable.sol";

/// @title Station Network Fee Manager Contract
/// @author 👦🏻👦🏻.eth

/// @dev This contract stores state for all fees set on both default and per-collection basis
/// Handles fee calculations when called by modules inquiring about the total fees involved in a mint, including ERC20 support
contract FeeManager is Ownable {
    /// @dev Struct of fee data, including FeeSetting enum and both base and variable fees, all packed into 1 slot
    /// Since `type(uint120).max` ~= 1.3e36, it suffices for fees of up to 1.3e18 ETH or ERC20 tokens, far beyond realistic scenarios.
    /// @param exist boolean indicating whether the fee values exist
    /// @param baseFee The flat fee charged by Station Network on a per item basis
    /// @param variableFee The variable fee (in BPS) charged by Station Network on volume basis
    /// Accounts for each item's cost and total amount of items
    struct Fees {
        bool exist;
        uint120 baseFee;
        uint120 variableFee;
    }

    /*============
        ERRORS
    ============*/

    error FeesNotSet();

    /*============
        EVENTS
    ============*/

    event DefaultFeesUpdated(Fees fees);
    event TokenFeesUpdated(address indexed token, Fees fees);
    event CollectionFeesUpdated(address indexed collection, address indexed token, Fees fees);

    /*=============
        STORAGE
    =============*/

    /// @dev Denominator used to calculate variable fee on a BPS basis
    /// @dev Not actually kept in storage as it is marked `constant`, saving gas by putting its value in contract bytecode instead
    uint256 private constant bpsDenominator = 10_000;

    /// @dev Baseline fee struct that serves as a stand in for all token addresses that have been registered
    /// in a stablecoin purchase module but not had their default fees set
    Fees internal defaultFees;

    /// @dev Mapping that stores default fees associated with a given token address
    mapping(address => Fees) internal tokenFees;

    /// @dev Mapping that stores override fees associated with specific collections, i.e. for discounts
    mapping(address => mapping(address => Fees)) internal collectionFees;

    /*================
        FEEMANAGER
    ================*/

    /// @notice Constructor will be deprecated in favor of an initialize() UUPS proxy call once logic is finalized & approved
    /// @param _newOwner The initialization of the contract's owner address, managed by Station
    /// @param _defaultBaseFee The initialization of default baseFees for all token addresses that have not (yet) been given defaults
    /// @param _defaultVariableFee The initialization of default variableFees for all token addresses that have not (yet) been given defaults
    /// @param _networkTokenBaseFee The initialization of default baseFees for the network's token
    /// @param _networkTokenVariableFee The initialization of default variableFees for the network's token
    constructor(
        address _newOwner,
        uint120 _defaultBaseFee,
        uint120 _defaultVariableFee,
        uint120 _networkTokenBaseFee,
        uint120 _networkTokenVariableFee
    ) {
        Fees memory _defaultFees = Fees(true, _defaultBaseFee, _defaultVariableFee);
        defaultFees = _defaultFees;
        emit DefaultFeesUpdated(_defaultFees);

        Fees memory _networkTokenFees = Fees(true, _networkTokenBaseFee, _networkTokenVariableFee);
        tokenFees[address(0x0)] = _networkTokenFees;
        emit TokenFeesUpdated(address(0x0), _networkTokenFees);

        _transferOwnership(_newOwner);
    }

    /// @dev Function to set baseline base and variable fees across all collections without specified defaults
    /// @dev Only callable by contract owner, an address managed by Station
    /// @param baseFee The new baseFee to apply as default
    /// @param variableFee The new variableFee to apply as default
    function setDefaultFees(uint120 baseFee, uint120 variableFee) external onlyOwner {
        Fees memory fees = Fees(true, baseFee, variableFee);
        defaultFees = fees;
        emit DefaultFeesUpdated(fees);
    }

    /// @dev Function to set base and variable fees for a specific token
    /// @dev Only callable by contract owner, an address managed by Station
    /// @param token The token for which to set new base and variable fees
    /// @param baseFee The new baseFee to apply to the token
    /// @param variableFee The new variableFee to apply to the token
    function setTokenFees(address token, uint120 baseFee, uint120 variableFee) external onlyOwner {
        Fees memory fees = Fees(true, baseFee, variableFee);
        tokenFees[token] = fees;
        emit TokenFeesUpdated(token, fees);
    }

    /// @dev Function to remove base and variable fees for a specific token
    /// @dev Only callable by contract owner, an address managed by Station
    /// @param token The token for which to remove fees
    function removeTokenFees(address token) external onlyOwner {
        Fees memory fees = Fees(false, 0, 0);
        tokenFees[token] = fees;
        emit TokenFeesUpdated(token, fees);
    }

    /// @dev Function to set override base and variable fees on a per-collection basis
    /// @param collection The collection for which to set override fees
    /// @param token The token for which to set new base and variable fees
    /// @param baseFee The new baseFee to apply to the collection and token
    /// @param variableFee The new variableFee to apply to the collection and token
    function setCollectionFees(address collection, address token, uint120 baseFee, uint120 variableFee)
        external
        onlyOwner
    {
        Fees memory fees = Fees(true, baseFee, variableFee);
        collectionFees[collection][token] = fees;
        emit CollectionFeesUpdated(collection, token, fees);
    }

    /// @dev Function to remove base and variable fees for a specific token
    /// @dev Only callable by contract owner, an address managed by Station
    /// @param collection The collection for which to remove fees
    /// @param token The token for which to remove fees
    function removeCollectionFees(address collection, address token) external onlyOwner {
        Fees memory fees = Fees(false, 0, 0);
        tokenFees[token] = fees;
        emit CollectionFeesUpdated(collection, token, fees);
    }

    /*============
        VIEWS
    ============*/

    /// @dev Function to get collection fees
    /// @param collection The collection whose fees will be read, including checks for client-specific fee discounts
    /// @param paymentToken The ERC20 token address used to pay fees. Will use base currency (ETH, MATIC, etc) when == address(0)
    /// @param /*recipient*/ The address to mint to. Included to support future discounts on a per user basis
    /// @param quantity The amount of tokens for which to compute total baseFee
    /// @param unitPrice The price of each token, used to compute subtotal on which to apply variableFee
    /// @param feeTotal The returned total incl fees for the given collection.
    function getFeeTotals(
        address collection,
        address paymentToken,
        address, /*recipient*/
        uint256 quantity,
        uint256 unitPrice
    ) external view returns (uint256 feeTotal) {
        // get existing fees, first checking for override fees or discounts if they have already been set
        Fees memory fees = getFees(collection, paymentToken);

        // if being called in free mint context results in only base fee
        (uint256 baseFeeTotal, uint256 variableFeeTotal) =
            calculateFees(fees.baseFee, fees.variableFee, quantity, unitPrice);
        return baseFeeTotal + variableFeeTotal;
    }

    /// @dev Function to get baseline fees for all tokens
    function getDefaultFees() public view returns (Fees memory fees) {
        fees = defaultFees;
    }

    /// @dev Function to get default fees for a token if they have been set
    /// @param token The token address to query against tokenFees mapping
    function getTokenFees(address token) public view returns (Fees memory fees) {
        fees = tokenFees[token];
        if (!fees.exist) revert FeesNotSet();
    }

    /// @dev Function to get override fees for a collection and token if they have been set
    /// @param collection The collection address to query against collectionFees mapping
    /// @param token The token address to query against collectionFees mapping
    function getCollectionFees(address collection, address token) public view returns (Fees memory fees) {
        fees = collectionFees[collection][token];
        if (!fees.exist) revert FeesNotSet();
    }

    /// @dev Function to evaluate whether override fees have been set for a specific collection
    /// and whether default fees have been set for the given token
    function getFees(address _collection, address _token) public view returns (Fees memory fees) {
        // if collectionFees exist, return overrides
        Fees memory collectionOverrides = collectionFees[_collection][_token];
        if (collectionOverrides.exist) {
            return collectionOverrides;
        }
        // if tokenFees exist, return overrides
        Fees memory tokenOverrides = tokenFees[_token];
        if (tokenOverrides.exist) {
            return tokenOverrides;
        }
        // no overrides set, return defaults
        return defaultFees;
    }

    /// @dev Function to calculate fees using base and variable fee structures, agnostic to ETH or ERC20 values
    /// @param baseFee The base fee denominated either in ETH or ERC20 tokens
    /// @param variableFee The variable fee denominated either in ETH or ERC20 tokens
    /// @param quantity The number of tokens being minted
    /// @param unitPrice The price per unit of tokens being minted
    function calculateFees(uint256 baseFee, uint256 variableFee, uint256 quantity, uint256 unitPrice)
        public
        pure
        returns (uint256 baseFeeTotal, uint256 variableFeeTotal)
    {
        // calculate baseFee total (quantity * unitPrice), set to baseFee
        baseFeeTotal = quantity * baseFee;
        // apply variable fee on total volume
        variableFeeTotal = unitPrice * quantity * variableFee / bpsDenominator;
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