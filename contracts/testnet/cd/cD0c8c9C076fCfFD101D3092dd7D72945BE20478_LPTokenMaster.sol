// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface AggregatorV3Interface {
  function decimals() external view returns (uint8);

  function description() external view returns (string memory);

  function version() external view returns (uint256);

  function getRoundData(uint80 _roundId)
    external
    view
    returns (
      uint80 roundId,
      int256 answer,
      uint256 startedAt,
      uint256 updatedAt,
      uint80 answeredInRound
    );

  function latestRoundData()
    external
    view
    returns (
      uint80 roundId,
      int256 answer,
      uint256 startedAt,
      uint256 updatedAt,
      uint80 answeredInRound
    );
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.9.0) (access/Ownable.sol)

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
// OpenZeppelin Contracts (last updated v4.9.0) (access/Ownable2Step.sol)

pragma solidity ^0.8.0;

import "./Ownable.sol";

/**
 * @dev Contract module which provides access control mechanism, where
 * there is an account (an owner) that can be granted exclusive access to
 * specific functions.
 *
 * By default, the owner account will be the one that deploys the contract. This
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
        require(pendingOwner() == sender, "Ownable2Step: caller is not the new owner");
        _transferOwnership(sender);
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (interfaces/IERC20Metadata.sol)

pragma solidity ^0.8.0;

import "../token/ERC20/extensions/IERC20Metadata.sol";

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC20/extensions/IERC20Metadata.sol)

pragma solidity ^0.8.0;

import "../IERC20.sol";

/**
 * @dev Interface for the optional metadata functions from the ERC20 standard.
 *
 * _Available since v4.1._
 */
interface IERC20Metadata is IERC20 {
    /**
     * @dev Returns the name of the token.
     */
    function name() external view returns (string memory);

    /**
     * @dev Returns the symbol of the token.
     */
    function symbol() external view returns (string memory);

    /**
     * @dev Returns the decimals places of the token.
     */
    function decimals() external view returns (uint8);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.9.0) (token/ERC20/IERC20.sol)

pragma solidity ^0.8.0;

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
     * @dev Returns the amount of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the amount of tokens owned by `account`.
     */
    function balanceOf(address account) external view returns (uint256);

    /**
     * @dev Moves `amount` tokens from the caller's account to `to`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address to, uint256 amount) external returns (bool);

    /**
     * @dev Returns the remaining number of tokens that `spender` will be
     * allowed to spend on behalf of `owner` through {transferFrom}. This is
     * zero by default.
     *
     * This value changes when {approve} or {transferFrom} are called.
     */
    function allowance(address owner, address spender) external view returns (uint256);

    /**
     * @dev Sets `amount` as the allowance of `spender` over the caller's tokens.
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
    function approve(address spender, uint256 amount) external returns (bool);

    /**
     * @dev Moves `amount` tokens from `from` to `to` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(address from, address to, uint256 amount) external returns (bool);
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

// SPDX-License-Identifier: UNLICENSED

pragma solidity 0.8.19;

import "./IOwnable.sol";
import "./IUnifiedOracleAggregator.sol";

interface ILendingController is IOwnable {
    function oracleAggregator()
        external
        view
        returns (IUnifiedOracleAggregator);

    function liqFeeSystem(address _token) external view returns (uint256);

    function liqFeeCaller(address _token) external view returns (uint256);

    function colFactor(address _token) external view returns (uint256);

    function defaultColFactor() external view returns (uint256);

    function depositLimit(
        address _lendingPair,
        address _token
    ) external view returns (uint256);

    function borrowLimit(
        address _lendingPair,
        address _token
    ) external view returns (uint256);

    function tokenPrice(address _token) external view returns (uint256);

    function minBorrow(address _token) external view returns (uint256);

    function tokenPrices(
        address _tokenA,
        address _tokenB
    ) external view returns (uint256, uint256);

    function tokenSupported(address _token) external view returns (bool);

    function hasChainlinkOracle(address _token) external view returns (bool);

    function isBaseAsset(address _token) external view returns (bool);

    function minObservationCardinalityNext() external view returns (uint16);

    function preparePool(address _tokenA, address _tokenB) external;
}

// SPDX-License-Identifier: UNLICENSED

pragma solidity 0.8.19;

interface ILendingPair {
    function tokenA() external view returns (address);

    function tokenB() external view returns (address);

    function lpToken(address _token) external view returns (address);

    function transferLp(
        address _token,
        address _from,
        address _to,
        uint256 _amount
    ) external;

    function supplySharesOf(
        address _token,
        address _account
    ) external view returns (uint256);

    function totalSupplyShares(address _token) external view returns (uint256);

    function totalSupplyAmount(address _token) external view returns (uint256);

    function totalDebtShares(address _token) external view returns (uint256);

    function totalDebtAmount(address _token) external view returns (uint256);

    function debtOf(
        address _token,
        address _account
    ) external view returns (uint256);

    function supplyOf(
        address _token,
        address _account
    ) external view returns (uint256);

    function pendingSystemFees(address _token) external view returns (uint256);

    function supplyBalanceConverted(
        address _account,
        address _suppliedToken,
        address _returnToken
    ) external view returns (uint256);

    function initialize(
        address _lpTokenMaster,
        address _lendingController,
        address _feeRecipient,
        address _tokenA,
        address _tokenB
    ) external;
}

// SPDX-License-Identifier: UNLICENSED

pragma solidity 0.8.19;

import "@openzeppelin/contracts/interfaces/IERC20Metadata.sol";
import "./IOwnable.sol";

interface ILPTokenMaster is IOwnable, IERC20Metadata {
    function initialize(
        address _underlying,
        address _lendingController
    ) external;

    function underlying() external view returns (address);

    function lendingPair() external view returns (address);
}

// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.0;

interface IOwnable {
    function owner() external view returns (address);

    function transferOwnership(address _newOwner) external;

    function acceptOwnership() external;
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.19;

import "@openzeppelin/contracts/access/Ownable2Step.sol";
import "@openzeppelin/contracts/interfaces/IERC20Metadata.sol";
import "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";

/// @title Oracle aggergator for uni and link oracles
/// @author flora.loans
/// @notice Owner can set Chainlink oracles for specific tokens
/// @notice returns the token price from chainlink oracle (if available) otherwise the uni oracle will be used
interface IUnifiedOracleAggregator {
    function linkOracles(address) external view returns (address);

    function setOracle(address, AggregatorV3Interface) external;

    function preparePool(address, address, uint16) external;

    function tokenSupported(address) external view returns (bool);

    function tokenPrice(address) external view returns (uint256);

    function tokenPrices(
        address,
        address
    ) external view returns (uint256, uint256);

    /// @dev Not used in any code to save gas. But useful for external usage.
    function convertTokenValues(
        address,
        address,
        uint256
    ) external view returns (uint256);
}

// SPDX-License-Identifier: UNLICENSED

// Copyright (c) FloraLoans - All rights reserved
// https://twitter.com/Flora_Loans

// This contract is a wrapper around the LendingPair contract
// Each new LendingPair implementation delegates its calls to this contract
// It enables ERC20 functionality around the postion tokens

pragma solidity 0.8.19;

import "@openzeppelin/contracts/access/Ownable2Step.sol";

import "./interfaces/ILPTokenMaster.sol";
import "./interfaces/ILendingPair.sol";
import "./interfaces/ILendingController.sol";

/// @title LendingPairTokenMaster: An ERC20-like Master contract for Flora Loans
/// @author 0xdev & flora.loans
/// @notice This contract serves as a fungible token and is a wrapper around the LendingPair contract
/// @dev Each new LendingPair implementation delegates its calls to this contract, enabling ERC20 functionality around the position tokens
/// @dev Implements the ERC20 standard and serves as the master contract for managing tokens in lending pairs

contract LPTokenMaster is ILPTokenMaster, Ownable2Step {
    mapping(address account => mapping(address spender => uint256 amount))
        public
        override allowance;

    address public override underlying;
    address public lendingController;
    string public constant name = "Flora-Lendingpair";
    string public constant symbol = "FLORA-LP";
    uint8 public constant override decimals = 18;
    bool private _initialized;

    /// @notice Initialize the contract, called by the LendingPair during creation at PairFactory
    /// @param _underlying Address of the underlying token (e.g. WETH address if the token is WETH)
    /// @param _lendingController Address of the lending controller
    function initialize(
        address _underlying,
        address _lendingController
    ) external override {
        require(_initialized != true, "LPToken: already intialized");
        _transferOwnership(_msgSender());
        underlying = _underlying;
        lendingController = _lendingController;
        _initialized = true;
    }

    /// @notice Transfer tokens to a specified address
    /// @param _recipient The address to transfer to
    /// @param _amount The amount to be transferred
    /// @return A boolean value indicating whether the operation succeeded
    function transfer(
        address _recipient,
        uint256 _amount
    ) external override returns (bool /* transferSuccessful */) {
        _transfer(msg.sender, _recipient, _amount);
        return true;
    }

    /// @notice Approve the passed address to spend the specified amount of tokens on behalf of msg.sender
    /// @param _spender The address which will spend the funds
    /// @param _amount The amount of tokens to be spent
    /// @return A boolean value indicating whether the operation succeeded
    /// @dev Beware that changing an allowance with this method brings the risk that someone may use both the old
    /// and the new allowance by unfortunate transaction ordering. One possible solution to mitigate this
    /// race condition is to first reduce the spender's allowance to 0 and set the desired value afterwards:
    /// https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
    function approve(
        address _spender,
        uint256 _amount
    ) external override returns (bool /* approvalSuccesful */) {
        _approve(msg.sender, _spender, _amount);
        return true;
    }

    /// @notice Transfer tokens from one address to another.
    /// @param _sender The address which you want to send tokens from
    /// @param _recipient The address which you want to transfer to
    /// @param _amount The amount of tokens to be transferred
    /// @return A boolean value indicating whether the operation succeeded
    /// @dev Note that while this function emits an Approval event, this is not required as per the specification and other compliant implementations may not emit the event.
    function transferFrom(
        address _sender,
        address _recipient,
        uint256 _amount
    ) external override returns (bool /* transferFromsuccessful */) {
        _approve(_sender, msg.sender, allowance[_sender][msg.sender] - _amount);
        _transfer(_sender, _recipient, _amount);
        return true;
    }

    /// @notice Returns the associated LendingPair Contract
    /// @return The address of the associated LendingPair Contract
    function lendingPair()
        external
        view
        override
        returns (address /* LendingPair address */)
    {
        return owner();
    }

    /// @notice Gets the balance of the specified address
    /// @param _account The address to query the balance of
    /// @return A uint256 representing the shares credited to `account`
    function balanceOf(
        address _account
    ) external view override returns (uint256 /* supply shares of `account`*/) {
        return ILendingPair(owner()).supplySharesOf(underlying, _account);
    }

    /// @notice Get the total number of tokens in existence
    /// @return A uint256 representing the total supply of the token
    function totalSupply()
        external
        view
        override
        returns (uint256 /* totalSupplyShares*/)
    {
        return ILendingPair(owner()).totalSupplyShares(underlying);
    }

    /// @notice Returns the current owner of the contract.
    /// @return The address of the current owner. Should be the LendingPair
    function owner()
        public
        view
        override(IOwnable, Ownable)
        returns (address /* owner address */)
    {
        return Ownable.owner();
    }

    /// @notice Allows the pending owner to become the new owner.
    function acceptOwnership() public override(IOwnable, Ownable2Step) {
        return Ownable2Step.acceptOwnership();
    }

    /// @notice Transfers ownership of the contract to a new address.
    /// @param newOwner The address of the new owner.
    function transferOwnership(
        address newOwner
    ) public override(IOwnable, Ownable2Step) {
        return Ownable2Step.transferOwnership(newOwner);
    }

    /// @notice Internal function to transfer tokens between two addresses
    /// @dev Called by the external transfer and transferFrom functions
    /// @param _sender The address from which to transfer tokens
    /// @param _recipient The address to which to transfer tokens
    /// @param _amount The amount of tokens to transfer
    function _transfer(
        address _sender,
        address _recipient,
        uint256 _amount
    ) internal {
        require(_sender != address(0), "ERC20: transfer from the zero address");
        require(
            _recipient != address(0),
            "ERC20: transfer to the zero address"
        );

        ILendingPair(owner()).transferLp(
            underlying,
            _sender,
            _recipient,
            _amount
        );

        emit Transfer(_sender, _recipient, _amount);
    }

    /// @notice Internal function to approve an address to spend a specified amount of tokens on behalf of an owner
    /// @dev Called by the external approve function
    /// @param _owner The address of the token owner
    /// @param _spender The address to grant spending rights to
    /// @param _amount The amount of tokens to approve for spending
    function _approve(
        address _owner,
        address _spender,
        uint256 _amount
    ) internal {
        require(_owner != address(0), "ERC20: approve from the zero address");
        require(_spender != address(0), "ERC20: approve to the zero address");

        allowance[_owner][_spender] = _amount;
        emit Approval(_owner, _spender, _amount);
    }
}