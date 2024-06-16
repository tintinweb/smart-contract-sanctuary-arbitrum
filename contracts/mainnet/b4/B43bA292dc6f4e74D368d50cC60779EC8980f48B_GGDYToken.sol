// SPDX-License-Identifier: GPL-3.0

/**
####################################

This token has been created using Bitbond Token Tool: https://tokentool.bitbond.com/

Token Tool enables users to easily configure and deploy smart contracts without coding such as fungible / non-fungible tokens, crowdsale contracts, token lockers, and multisenders.

Bitbond is not associated with the token creator or the respective company / project.

Join the Bitbond Token Tool Crypto Affiliate Program to get discounts and earn rewards: https://tokentool.bitbond.com/crypto-affiliate-program

####################################
*/

pragma solidity 0.8.17;

import { Ownable } from "@openzeppelin/contracts/access/Ownable.sol";
import { LibCommon } from "./lib/LibCommon.sol";
import { ReflectiveERC20 } from "./ReflectiveERC20.sol";

/// @title A Defi Token implementation with extended functionalities
/// @notice Implements ERC20 standards with additional features like tax and deflation
contract GGDYToken is ReflectiveERC20, Ownable {
  // Constants
  uint256 private constant MAX_BPS_AMOUNT = 10_000;
  uint256 private constant MAX_ALLOWED_BPS = 2_000;
  string public constant VERSION = "defi_v_4";
  string public constant CONTRACT_NAME = "GGDYToken";
  bytes32 public constant CONTRACT_HASH = 0x227a30d8796d17868cebf5bc577a0ca763aa5b3cfddc93817b7270f8265c2040;

  // State Variables
  string public initialDocumentUri;
  string public documentUri;
  uint256 public immutable initialSupply;
  uint256 public immutable initialMaxTokenAmountPerAddress;
  uint256 public maxTokenAmountPerAddress;
  uint256 public maxTotalSupply;

  /// @notice Configuration properties for the ERC20 token
  struct ERC20ConfigProps {
    bool _isMintable;
    bool _isBurnable;
    bool _isDocumentAllowed;
    bool _isMaxAmountOfTokensSet;
    bool _isMaxSupplySet;
    bool _isTaxable;
    bool _isDeflationary;
    bool _isReflective;
  }
  ERC20ConfigProps private configProps;

  address public immutable initialTokenOwner;
  uint8 private immutable _decimals;
  address public taxAddress;
  uint256 public taxBPS;
  uint256 public deflationBPS;

  // Events
  event DocumentUriSet(string newDocUri);
  event MaxTokenAmountPerSet(uint256 newMaxTokenAmount);
  event TaxConfigSet(address indexed _taxAddress, uint256 indexed _taxBPS);
  event DeflationConfigSet(uint256 indexed _deflationBPS);
  event ReflectionConfigSet(uint256 indexed _feeBPS);

  // Custom Errors
  error InvalidMaxTokenAmount(uint256 maxTokenAmount);
  error InvalidDecimals(uint8 decimals);
  error MaxTokenAmountPerAddrLtPrevious();
  error DestBalanceExceedsMaxAllowed(address addr);
  error DocumentUriNotAllowed();
  error MaxTokenAmountNotAllowed();
  error TokenIsNotTaxable();
  error TokenIsNotDeflationary();
  error InvalidTotalBPS(uint256 bps);
  error InvalidReflectiveConfig();
  error InvalidMaxSupplyConfig();
  error TotalSupplyExceedsMaxAllowedAmount();

  /// @notice Constructor to initialize the DeFi token
  /// @param name_ Name of the token
  /// @param symbol_ Symbol of the token
  /// @param initialSupplyToSet Initial supply of tokens
  /// @param decimalsToSet Number of decimals for the token
  /// @param tokenOwner Address of the initial token owner
  /// @param customConfigProps Configuration properties for the token
  /// @param newDocumentUri URI for the document associated with the token
  /// @param _taxAddress Address where tax will be sent
  /// @param bpsParams array of BPS values in this order:
  ///           taxBPS = bpsParams[0],
  ///           deflationBPS = bpsParams[1],
  ///           rewardFeeBPS = bpsParams[2],
  /// @param amountParams array of amounts for amount specific config:
  ///           maxTokenAmount = amountParams[0], Maximum token amount per address
  ///           maxSupplyAmount = amountParams[1], Maximum token token supply amount

  constructor(
    string memory name_,
    string memory symbol_,
    uint256 initialSupplyToSet,
    uint8 decimalsToSet,
    address tokenOwner,
    ERC20ConfigProps memory customConfigProps,
    string memory newDocumentUri,
    address _taxAddress,
    uint256[3] memory bpsParams,
    uint256[2] memory amountParams
  )
    ReflectiveERC20(
      name_,
      symbol_,
      tokenOwner,
      initialSupplyToSet,
      decimalsToSet,
      initialSupplyToSet != 0 ? bpsParams[2] : 0,
      customConfigProps._isReflective
    )
  {
    // reflection feature can't be used in combination with burning/minting/deflation
    // or reflection config is invalid if no reflection BPS amount is provided
    if (
      (customConfigProps._isReflective &&
        (customConfigProps._isBurnable ||
          customConfigProps._isMintable ||
          customConfigProps._isDeflationary)) ||
      (!customConfigProps._isReflective && bpsParams[2] != 0)
    ) {
      revert InvalidReflectiveConfig();
    }

    if (customConfigProps._isMaxAmountOfTokensSet) {
      if (amountParams[0] == 0) {
        revert InvalidMaxTokenAmount(amountParams[0]);
      }
    }
    if (decimalsToSet > 18) {
      revert InvalidDecimals(decimalsToSet);
    }

    if (
      customConfigProps._isMaxSupplySet &&
      (!customConfigProps._isMintable || (totalSupply() > amountParams[1]))
    ) {
      revert InvalidMaxSupplyConfig();
    }

    bpsInitChecks(customConfigProps, bpsParams, _taxAddress);

    LibCommon.validateAddress(tokenOwner);

    taxAddress = _taxAddress;

    taxBPS = bpsParams[0];
    deflationBPS = bpsParams[1];
    initialSupply = initialSupplyToSet;
    initialMaxTokenAmountPerAddress = amountParams[0];
    initialDocumentUri = newDocumentUri;
    initialTokenOwner = tokenOwner;
    _decimals = decimalsToSet;
    configProps = customConfigProps;
    documentUri = newDocumentUri;
    maxTokenAmountPerAddress = amountParams[0];
    maxTotalSupply = amountParams[1];

    if (tokenOwner != msg.sender) {
      transferOwnership(tokenOwner);
    }
  }

  function bpsInitChecks(
    ERC20ConfigProps memory customConfigProps,
    uint256[3] memory bpsParams,
    address _taxAddress
  ) private pure {
    uint256 totalBPS = 0;
    if (customConfigProps._isTaxable) {
      LibCommon.validateAddress(_taxAddress);

      totalBPS += bpsParams[0];
    }
    if (customConfigProps._isDeflationary) {
      totalBPS += bpsParams[1];
    }
    if (customConfigProps._isReflective) {
      totalBPS += bpsParams[2];
    }
    if (totalBPS > MAX_ALLOWED_BPS) {
      revert InvalidTotalBPS(totalBPS);
    }
  }

  // Public and External Functions

  /// @notice Checks if the token is mintable
  /// @return True if the token can be minted
  function isMintable() public view returns (bool) {
    return configProps._isMintable;
  }

  /// @notice Checks if the token is burnable
  /// @return True if the token can be burned
  function isBurnable() public view returns (bool) {
    return configProps._isBurnable;
  }

  /// @notice Checks if the maximum amount of tokens per address is set
  /// @return True if there is a maximum limit for token amount per address
  function isMaxAmountOfTokensSet() public view returns (bool) {
    return configProps._isMaxAmountOfTokensSet;
  }

  /// @notice Checks if the maximum amount of token supply is set
  /// @return True if there is a maximum limit for token supply
  function isMaxSupplySet() public view returns (bool) {
    return configProps._isMaxSupplySet;
  }

  /// @notice Checks if setting a document URI is allowed
  /// @return True if setting a document URI is allowed
  function isDocumentUriAllowed() public view returns (bool) {
    return configProps._isDocumentAllowed;
  }

  /// @notice Returns the number of decimals used for the token
  /// @return The number of decimals
  function decimals() public view virtual override returns (uint8) {
    return _decimals;
  }

  /// @notice Checks if the token is taxable
  /// @return True if the token has tax applied on transfers
  function isTaxable() public view returns (bool) {
    return configProps._isTaxable;
  }

  /// @notice Checks if the token is deflationary
  /// @return True if the token has deflation applied on transfers
  function isDeflationary() public view returns (bool) {
    return configProps._isDeflationary;
  }

  /// @notice Checks if the token is reflective
  /// @return True if the token has reflection (ie. holder rewards) applied on transfers
  function isReflective() public view returns (bool) {
    return configProps._isReflective;
  }

  /// @notice Sets a new document URI
  /// @dev Can only be called by the contract owner
  /// @param newDocumentUri The new URI to be set
  function setDocumentUri(string memory newDocumentUri) external onlyOwner {
    if (!isDocumentUriAllowed()) {
      revert DocumentUriNotAllowed();
    }
    documentUri = newDocumentUri;
    emit DocumentUriSet(newDocumentUri);
  }

  /// @notice Sets a new maximum token amount per address
  /// @dev Can only be called by the contract owner
  /// @param newMaxTokenAmount The new maximum token amount per address
  function setMaxTokenAmountPerAddress(
    uint256 newMaxTokenAmount
  ) external onlyOwner {
    if (!isMaxAmountOfTokensSet()) {
      revert MaxTokenAmountNotAllowed();
    }
    if (newMaxTokenAmount <= maxTokenAmountPerAddress) {
      revert MaxTokenAmountPerAddrLtPrevious();
    }

    maxTokenAmountPerAddress = newMaxTokenAmount;
    emit MaxTokenAmountPerSet(newMaxTokenAmount);
  }

  /// @notice Sets a new reflection fee
  /// @dev Can only be called by the contract owner
  /// @param _feeBPS The reflection fee in basis points
  function setReflectionConfig(uint256 _feeBPS) external onlyOwner {
    if (!isReflective()) {
      revert TokenIsNotReflective();
    }
    super._setReflectionFee(_feeBPS);

    emit ReflectionConfigSet(_feeBPS);
  }

  /// @notice Sets a new tax configuration
  /// @dev Can only be called by the contract owner
  /// @param _taxAddress The address where tax will be sent
  /// @param _taxBPS The tax rate in basis points
  function setTaxConfig(
    address _taxAddress,
    uint256 _taxBPS
  ) external onlyOwner {
    if (!isTaxable()) {
      revert TokenIsNotTaxable();
    }

    uint256 totalBPS = deflationBPS + tFeeBPS + _taxBPS;
    if (totalBPS > MAX_ALLOWED_BPS) {
      revert InvalidTotalBPS(totalBPS);
    }
    LibCommon.validateAddress(_taxAddress);
    taxAddress = _taxAddress;
    taxBPS = _taxBPS;
    emit TaxConfigSet(_taxAddress, _taxBPS);
  }

  /// @notice Sets a new deflation configuration
  /// @dev Can only be called by the contract owner
  /// @param _deflationBPS The deflation rate in basis points
  function setDeflationConfig(uint256 _deflationBPS) external onlyOwner {
    if (!isDeflationary()) {
      revert TokenIsNotDeflationary();
    }
    uint256 totalBPS = deflationBPS + tFeeBPS + _deflationBPS;
    if (totalBPS > MAX_ALLOWED_BPS) {
      revert InvalidTotalBPS(totalBPS);
    }
    deflationBPS = _deflationBPS;
    emit DeflationConfigSet(_deflationBPS);
  }

  /// @notice Transfers tokens to a specified address
  /// @dev Overrides the ERC20 transfer function with added tax and deflation logic
  /// @param to The address to transfer tokens to
  /// @param amount The amount of tokens to be transferred
  /// @return True if the transfer was successful
  function transfer(
    address to,
    uint256 amount
  ) public virtual override returns (bool) {
    uint256 taxAmount = _taxAmount(msg.sender, amount);
    uint256 deflationAmount = _deflationAmount(amount);
    uint256 amountToTransfer = amount - taxAmount - deflationAmount;

    if (isMaxAmountOfTokensSet()) {
      if (balanceOf(to) + amountToTransfer > maxTokenAmountPerAddress) {
        revert DestBalanceExceedsMaxAllowed(to);
      }
    }

    if (taxAmount != 0) {
      _transferNonReflectedTax(msg.sender, taxAddress, taxAmount);
    }
    if (deflationAmount != 0) {
      _burn(msg.sender, deflationAmount);
    }
    return super.transfer(to, amountToTransfer);
  }

  /// @notice Transfers tokens from one address to another
  /// @dev Overrides the ERC20 transferFrom function with added tax and deflation logic
  /// @param from The address which you want to send tokens from
  /// @param to The address which you want to transfer to
  /// @param amount The amount of tokens to be transferred
  /// @return True if the transfer was successful
  function transferFrom(
    address from,
    address to,
    uint256 amount
  ) public virtual override returns (bool) {
    uint256 taxAmount = _taxAmount(from, amount);
    uint256 deflationAmount = _deflationAmount(amount);
    uint256 amountToTransfer = amount - taxAmount - deflationAmount;

    if (isMaxAmountOfTokensSet()) {
      if (balanceOf(to) + amountToTransfer > maxTokenAmountPerAddress) {
        revert DestBalanceExceedsMaxAllowed(to);
      }
    }

    if (taxAmount != 0) {
      _transferNonReflectedTax(from, taxAddress, taxAmount);
    }
    if (deflationAmount != 0) {
      _burn(from, deflationAmount);
    }

    return super.transferFrom(from, to, amountToTransfer);
  }

  /// @notice Mints new tokens to a specified address
  /// @dev Can only be called by the contract owner and if minting is enabled
  /// @param to The address to mint tokens to
  /// @param amount The amount of tokens to mint
  function mint(address to, uint256 amount) external onlyOwner {
    if (!isMintable()) {
      revert MintingNotEnabled();
    }
    if (isMaxAmountOfTokensSet()) {
      if (balanceOf(to) + amount > maxTokenAmountPerAddress) {
        revert DestBalanceExceedsMaxAllowed(to);
      }
    }
    if (isMaxSupplySet()) {
      if (totalSupply() + amount > maxTotalSupply) {
        revert TotalSupplyExceedsMaxAllowedAmount();
      }
    }

    super._mint(to, amount);
  }

  /// @notice Burns a specific amount of tokens
  /// @dev Can only be called by the contract owner and if burning is enabled
  /// @param amount The amount of tokens to be burned
  function burn(uint256 amount) external onlyOwner {
    if (!isBurnable()) {
      revert BurningNotEnabled();
    }
    _burn(msg.sender, amount);
  }

  /// @notice Renounces ownership of the contract
  /// @dev Leaves the contract without an owner, disabling any functions that require the owner's authorization
  function renounceOwnership() public override onlyOwner {
    super.renounceOwnership();
  }

  /// @notice Transfers ownership of the contract to a new account
  /// @dev Can only be called by the current owner
  /// @param newOwner The address of the new owner
  function transferOwnership(address newOwner) public override onlyOwner {
    super.transferOwnership(newOwner);
  }

  // Internal Functions

  /// @notice Calculates the tax amount for a transfer
  /// @param sender The address initiating the transfer
  /// @param amount The amount of tokens being transferred
  /// @return taxAmount The calculated tax amount
  function _taxAmount(
    address sender,
    uint256 amount
  ) internal view returns (uint256 taxAmount) {
    taxAmount = 0;
    if (taxBPS != 0 && sender != taxAddress) {
      taxAmount = (amount * taxBPS) / MAX_BPS_AMOUNT;
    }
  }

  /// @notice Calculates the deflation amount for a transfer
  /// @param amount The amount of tokens being transferred
  /// @return deflationAmount The calculated deflation amount
  function _deflationAmount(
    uint256 amount
  ) internal view returns (uint256 deflationAmount) {
    deflationAmount = 0;
    if (deflationBPS != 0) {
      deflationAmount = (amount * deflationBPS) / MAX_BPS_AMOUNT;
    }
  }
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
// OpenZeppelin Contracts (last updated v4.9.4) (utils/Context.sol)

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

    function _contextSuffixLength() internal view virtual returns (uint256) {
        return 0;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

library LibCommon {
  /*´:°•.°+.*•´.*:˚.°*.˚•´.°:°•.°•.*•´.*:˚.°*.˚•´.°:°•.°+.*•´.*:*/
  /*                       CUSTOM ERRORS                        */
  /*.•°:°.´+˚.*°.˚:*.´•*.+°.•°:´*.´•*.•°.•°:°.´:•˚°.*°.˚:*.´+°.•*/

  /// @dev The ETH transfer has failed.
  error ETHTransferFailed();

  /// @dev The address is the zero address.
  error ZeroAddress();

  /// @notice raised when an ERC20 transfer fails
  error TransferFailed();

  /*´:°•.°+.*•´.*:˚.°*.˚•´.°:°•.°•.*•´.*:˚.°*.˚•´.°:°•.°+.*•´.*:*/
  /*                       ETH OPERATIONS                       */
  /*.•°:°.´+˚.*°.˚:*.´•*.+°.•°:´*.´•*.•°.•°:°.´:•˚°.*°.˚:*.´+°.•*/

  /// @notice Taken from Solady (https://github.com/vectorized/solady/blob/main/src/utils/SafeTransferLib.sol)
  /// @dev Sends `amount` (in wei) ETH to `to`.
  /// Reverts upon failure.
  function safeTransferETH(address to, uint256 amount) internal {
    // solhint-disable-next-line no-inline-assembly
    assembly {
      // Transfer the ETH and check if it succeeded or not.
      if iszero(call(gas(), to, amount, 0, 0, 0, 0)) {
        // Store the function selector of `ETHTransferFailed()`.
        // bytes4(keccak256(bytes("ETHTransferFailed()"))) = 0xb12d13eb
        mstore(0x00, 0xb12d13eb)
        // Revert with (offset, size).
        revert(0x1c, 0x04)
      }
    }
  }

  /// @notice Validates that the address is not the zero address using assembly.
  /// @dev Reverts if the address is the zero address.
  function validateAddress(address addr) internal pure {
    // solhint-disable-next-line no-inline-assembly
    assembly {
      if iszero(shl(96, addr)) {
        // Store the function selector of `ZeroAddress()`.
        // bytes4(keccak256(bytes("ZeroAddress()"))) = 0xd92e233d
        mstore(0x00, 0xd92e233d)
        // Revert with (offset, size).
        revert(0x1c, 0x04)
      }
    }
  }

  /// @notice Helper function to transfer ERC20 tokens without the need for SafeERC20.
  /// @dev Reverts if the ERC20 transfer fails.
  /// @param tokenAddress The address of the ERC20 token.
  /// @param from The address to transfer the tokens from.
  /// @param to The address to transfer the tokens to.
  /// @param amount The amount of tokens to transfer.
  function safeTransferFrom(
    address tokenAddress,
    address from,
    address to,
    uint256 amount
  ) internal returns (bool) {
    // solhint-disable-next-line avoid-low-level-calls
    (bool success, bytes memory data) = tokenAddress.call(
      abi.encodeWithSignature(
        "transferFrom(address,address,uint256)",
        from,
        to,
        amount
      )
    );
    if (!success) {
      if (data.length != 0) {
        // bubble up error
        // solhint-disable-next-line no-inline-assembly
        assembly {
          let returndata_size := mload(data)
          revert(add(32, data), returndata_size)
        }
      } else {
        revert TransferFailed();
      }
    }
    return true;
  }

  /// @notice Helper function to transfer ERC20 tokens without the need for SafeERC20.
  /// @dev Reverts if the ERC20 transfer fails.
  /// @param tokenAddress The address of the ERC20 token.
  /// @param to The address to transfer the tokens to.
  /// @param amount The amount of tokens to transfer.
  function safeTransfer(
    address tokenAddress,
    address to,
    uint256 amount
  ) internal returns (bool) {
    // solhint-disable-next-line avoid-low-level-calls
    (bool success, bytes memory data) = tokenAddress.call(
      abi.encodeWithSignature("transfer(address,uint256)", to, amount)
    );
    if (!success) {
      if (data.length != 0) {
        // bubble up error
        // solhint-disable-next-line no-inline-assembly
        assembly {
          let returndata_size := mload(data)
          revert(add(32, data), returndata_size)
        }
      } else {
        revert TransferFailed();
      }
    }
    return true;
  }
}

// SPDX-License-Identifier: GPL-3.0

pragma solidity 0.8.17;

import { ERC20 } from "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import { LibCommon } from "./lib/LibCommon.sol";

/// @title A ERC20 implementation with extended reflection token functionalities
/// @notice Implements ERC20 standards with additional token holder reward feature
abstract contract ReflectiveERC20 is ERC20 {
  // Constants
  uint256 private constant BPS_DIVISOR = 10_000;

  mapping(address => uint256) private _rOwned;
  mapping(address => uint256) private _tOwned;

  uint256 private constant UINT_256_MAX = type(uint256).max;
  uint256 private _rTotal;
  uint256 private _tFeeTotal;

  uint256 public tFeeBPS;
  bool private immutable isReflective;

  // custom errors
  error TokenIsNotReflective();
  error TotalReflectionTooSmall();
  error ZeroTransferError();
  error MintingNotEnabled();
  error BurningNotEnabled();
  error ERC20InsufficientBalance(
    address recipient,
    uint256 fromBalance,
    uint256 balance
  );

  /// @notice Gets total supply of the erc20 token
  /// @return Token total supply
  function _tTotal() public view virtual returns (uint256) {
    return totalSupply();
  }

  /// @notice Constructor to initialize the ReflectionErc20 token
  /// @param name_ Name of the token
  /// @param symbol_ Symbol of the token
  /// @param tokenOwner Address of the token owner
  /// @param totalSupply_ Initial total supply
  /// @param decimalsToSet Token decimal number
  /// @param decimalsToSet Token reward (reflection fee BPS value
  constructor(
    string memory name_,
    string memory symbol_,
    address tokenOwner,
    uint256 totalSupply_,
    uint8 decimalsToSet,
    uint256 tFeeBPS_,
    bool isReflective_
  ) ERC20(name_, symbol_) {
    if (totalSupply_ != 0) {
      super._mint(tokenOwner, totalSupply_ * 10 ** decimalsToSet);
      _rTotal = (UINT_256_MAX - (UINT_256_MAX % totalSupply_));
    }

    _rOwned[tokenOwner] = _rTotal;
    tFeeBPS = tFeeBPS_;
    isReflective = isReflective_;
  }

  // public standard ERC20 functions

  /// @notice Gets balance the erc20 token for specific address
  /// @param account Account address
  /// @return Token balance
  function balanceOf(address account) public view override returns (uint256) {
    if (isReflective) {
      return tokenFromReflection(_rOwned[account]);
    } else {
      return super.balanceOf(account);
    }
  }

  /// @notice Transfers allowed tokens between accounts
  /// @param from From account
  /// @param to To account
  /// @param value Transferred value
  /// @return Success
  function transferFrom(
    address from,
    address to,
    uint256 value
  ) public virtual override returns (bool) {
    address spender = super._msgSender();
    _spendAllowance(from, spender, value);
    _transfer(from, to, value);
    return true;
  }

  /// @notice Transfers tokens from owner to an account
  /// @param to To account
  /// @param value Transferred value
  /// @return Success
  function transfer(
    address to,
    uint256 value
  ) public virtual override returns (bool) {
    address owner = super._msgSender();
    _transfer(owner, to, value);
    return true;
  }

  // override internal OZ standard ERC20 functions related to transfer

  /// @notice Transfers tokens from owner to an account
  /// @param to To account
  /// @param amount Transferred amount
  function _transfer(
    address from,
    address to,
    uint256 amount
  ) internal override {
    if (isReflective) {
      LibCommon.validateAddress(from);
      LibCommon.validateAddress(to);
      if (amount == 0) {
        revert ZeroTransferError();
      }

      _transferReflected(from, to, amount);
    } else {
      super._transfer(from, to, amount);
    }
  }

  // override incompatible internal OZ standard ERC20 functions to disable them in case
  // reflection mechanism is used, ie. tFeeBPS is non zero

  /// @notice Creates specified amount of tokens, it either uses standard OZ ERC function
  ///         or in case of reflection logic, it is prohibited
  /// @param account Account new tokens will be transferred to
  /// @param value Created tokens value
  function _mint(address account, uint256 value) internal override {
    if (isReflective) {
      revert MintingNotEnabled();
    } else {
      super._mint(account, value);
    }
  }

  /// @notice Destroys specified amount of tokens, it either uses standard OZ ERC function
  ///         or in case of reflection logic, it is prohibited
  /// @param account Account in which tokens will be destroyed
  /// @param value Destroyed tokens value
  function _burn(address account, uint256 value) internal override {
    if (isReflective) {
      revert BurningNotEnabled();
    } else {
      super._burn(account, value);
    }
  }

  // public reflection custom functions

  /// @notice Sets a new reflection fee
  /// @dev Should only be called by the contract owner
  /// @param _tFeeBPS The reflection fee in basis points
  function _setReflectionFee(uint256 _tFeeBPS) internal {
    if (!isReflective) {
      revert TokenIsNotReflective();
    }

    tFeeBPS = _tFeeBPS;
  }

  /// @notice Calculates number of tokens from reflection amount
  /// @param rAmount Reflection token amount
  function tokenFromReflection(uint256 rAmount) public view returns (uint256) {
    if (rAmount > _rTotal) {
      revert TotalReflectionTooSmall();
    }

    uint256 currentRate = _getRate();
    return rAmount / currentRate;
  }

  // private reflection custom functions

  /// @notice Transfers reflected amount of tokens
  /// @param sender Account to transfer tokens from
  /// @param recipient Account to transfer tokens to
  /// @param tAmount Total token amount
  function _transferReflected(
    address sender,
    address recipient,
    uint256 tAmount
  ) private {
    uint256 tFee = calculateFee(tAmount);
    uint256 tTransferAmount = tAmount - tFee;
    (uint256 rAmount, uint256 rFee, uint256 rTransferAmount) = _getRValues(
      tAmount,
      tFee,
      tTransferAmount
    );

    if (tAmount != 0) {
      _rUpdate(sender, recipient, rAmount, rTransferAmount);

      _reflectFee(rFee, tFee);
      emit Transfer(sender, recipient, tAmount);
    }
  }

  /// @notice Deducts reflection fee from reflection supply to 'distribute' token holder rewards
  /// @param rFee Reflection fee
  /// @param tFee Token fee
  function _reflectFee(uint256 rFee, uint256 tFee) private {
    _rTotal = _rTotal - rFee;
    _tFeeTotal = _tFeeTotal + tFee;
  }

  /// @notice Calculates the reflection fee from token amount
  /// @param _amount Amount of tokens to calculate fee from
  function calculateFee(uint256 _amount) private view returns (uint256) {
    return (_amount * tFeeBPS) / BPS_DIVISOR;
  }

  /// @notice Transfers Tax related tokens and do not apply reflection fees
  /// @param from Account to transfer tokens from
  /// @param to Account to transfer tokens to
  /// @param tAmount Total token amount
  function _transferNonReflectedTax(
    address from,
    address to,
    uint256 tAmount
  ) internal {
    if (isReflective) {
      if (tAmount != 0) {
        uint256 currentRate = _getRate();
        uint256 rAmount = tAmount * currentRate;

        _rUpdate(from, to, rAmount, rAmount);
        emit Transfer(from, to, tAmount);
      }
    } else {
      super._transfer(from, to, tAmount);
    }
  }

  /// @notice Get reflective values from token values
  /// @param tAmount Token amount
  /// @param tFee Token fee
  /// @param tTransferAmount Transfer amount
  function _getRValues(
    uint256 tAmount,
    uint256 tFee,
    uint256 tTransferAmount
  ) private view returns (uint256, uint256, uint256) {
    uint256 currentRate = _getRate();
    uint256 rAmount = tAmount * currentRate;
    uint256 rFee = tFee * currentRate;
    uint256 rTransferAmount = tTransferAmount * currentRate;

    return (rAmount, rFee, rTransferAmount);
  }

  /// @notice Get ratio rate between reflective and token supply
  /// @return Reflective rate
  function _getRate() private view returns (uint256) {
    (uint256 rSupply, uint256 tSupply) = _getCurrentSupply();
    return rSupply / tSupply;
  }

  /// @notice Get reflective and token supplies
  /// @return Reflective and token supplies
  function _getCurrentSupply() private view returns (uint256, uint256) {
    return (_rTotal, _tTotal());
  }

  /// @notice Update reflective balances to reflect amount transfer,
  ///         with or without a fee applied. If a fee is applied,
  ///         the amount deducted from the sender will differ
  ///         from amount added to the recipient
  /// @param sender Sender address
  /// @param recipient Recipient address
  /// @param rSubAmount Amount to be deducted from sender
  /// @param rTransferAmount Amount to be added to recipient
  function _rUpdate(
    address sender,
    address recipient,
    uint256 rSubAmount,
    uint256 rTransferAmount
  ) private {
    uint256 fromBalance = _rOwned[sender];
    if (fromBalance < rSubAmount) {
      revert ERC20InsufficientBalance(recipient, fromBalance, rSubAmount);
    }
    _rOwned[sender] = _rOwned[sender] - rSubAmount;
    _rOwned[recipient] = _rOwned[recipient] + rTransferAmount;
  }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.9.0) (token/ERC20/ERC20.sol)

pragma solidity ^0.8.0;

import "./IERC20.sol";
import "./extensions/IERC20Metadata.sol";
import "../../utils/Context.sol";

/**
 * @dev Implementation of the {IERC20} interface.
 *
 * This implementation is agnostic to the way tokens are created. This means
 * that a supply mechanism has to be added in a derived contract using {_mint}.
 * For a generic mechanism see {ERC20PresetMinterPauser}.
 *
 * TIP: For a detailed writeup see our guide
 * https://forum.openzeppelin.com/t/how-to-implement-erc20-supply-mechanisms/226[How
 * to implement supply mechanisms].
 *
 * The default value of {decimals} is 18. To change this, you should override
 * this function so it returns a different value.
 *
 * We have followed general OpenZeppelin Contracts guidelines: functions revert
 * instead returning `false` on failure. This behavior is nonetheless
 * conventional and does not conflict with the expectations of ERC20
 * applications.
 *
 * Additionally, an {Approval} event is emitted on calls to {transferFrom}.
 * This allows applications to reconstruct the allowance for all accounts just
 * by listening to said events. Other implementations of the EIP may not emit
 * these events, as it isn't required by the specification.
 *
 * Finally, the non-standard {decreaseAllowance} and {increaseAllowance}
 * functions have been added to mitigate the well-known issues around setting
 * allowances. See {IERC20-approve}.
 */
contract ERC20 is Context, IERC20, IERC20Metadata {
    mapping(address => uint256) private _balances;

    mapping(address => mapping(address => uint256)) private _allowances;

    uint256 private _totalSupply;

    string private _name;
    string private _symbol;

    /**
     * @dev Sets the values for {name} and {symbol}.
     *
     * All two of these values are immutable: they can only be set once during
     * construction.
     */
    constructor(string memory name_, string memory symbol_) {
        _name = name_;
        _symbol = symbol_;
    }

    /**
     * @dev Returns the name of the token.
     */
    function name() public view virtual override returns (string memory) {
        return _name;
    }

    /**
     * @dev Returns the symbol of the token, usually a shorter version of the
     * name.
     */
    function symbol() public view virtual override returns (string memory) {
        return _symbol;
    }

    /**
     * @dev Returns the number of decimals used to get its user representation.
     * For example, if `decimals` equals `2`, a balance of `505` tokens should
     * be displayed to a user as `5.05` (`505 / 10 ** 2`).
     *
     * Tokens usually opt for a value of 18, imitating the relationship between
     * Ether and Wei. This is the default value returned by this function, unless
     * it's overridden.
     *
     * NOTE: This information is only used for _display_ purposes: it in
     * no way affects any of the arithmetic of the contract, including
     * {IERC20-balanceOf} and {IERC20-transfer}.
     */
    function decimals() public view virtual override returns (uint8) {
        return 18;
    }

    /**
     * @dev See {IERC20-totalSupply}.
     */
    function totalSupply() public view virtual override returns (uint256) {
        return _totalSupply;
    }

    /**
     * @dev See {IERC20-balanceOf}.
     */
    function balanceOf(address account) public view virtual override returns (uint256) {
        return _balances[account];
    }

    /**
     * @dev See {IERC20-transfer}.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     * - the caller must have a balance of at least `amount`.
     */
    function transfer(address to, uint256 amount) public virtual override returns (bool) {
        address owner = _msgSender();
        _transfer(owner, to, amount);
        return true;
    }

    /**
     * @dev See {IERC20-allowance}.
     */
    function allowance(address owner, address spender) public view virtual override returns (uint256) {
        return _allowances[owner][spender];
    }

    /**
     * @dev See {IERC20-approve}.
     *
     * NOTE: If `amount` is the maximum `uint256`, the allowance is not updated on
     * `transferFrom`. This is semantically equivalent to an infinite approval.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function approve(address spender, uint256 amount) public virtual override returns (bool) {
        address owner = _msgSender();
        _approve(owner, spender, amount);
        return true;
    }

    /**
     * @dev See {IERC20-transferFrom}.
     *
     * Emits an {Approval} event indicating the updated allowance. This is not
     * required by the EIP. See the note at the beginning of {ERC20}.
     *
     * NOTE: Does not update the allowance if the current allowance
     * is the maximum `uint256`.
     *
     * Requirements:
     *
     * - `from` and `to` cannot be the zero address.
     * - `from` must have a balance of at least `amount`.
     * - the caller must have allowance for ``from``'s tokens of at least
     * `amount`.
     */
    function transferFrom(address from, address to, uint256 amount) public virtual override returns (bool) {
        address spender = _msgSender();
        _spendAllowance(from, spender, amount);
        _transfer(from, to, amount);
        return true;
    }

    /**
     * @dev Atomically increases the allowance granted to `spender` by the caller.
     *
     * This is an alternative to {approve} that can be used as a mitigation for
     * problems described in {IERC20-approve}.
     *
     * Emits an {Approval} event indicating the updated allowance.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function increaseAllowance(address spender, uint256 addedValue) public virtual returns (bool) {
        address owner = _msgSender();
        _approve(owner, spender, allowance(owner, spender) + addedValue);
        return true;
    }

    /**
     * @dev Atomically decreases the allowance granted to `spender` by the caller.
     *
     * This is an alternative to {approve} that can be used as a mitigation for
     * problems described in {IERC20-approve}.
     *
     * Emits an {Approval} event indicating the updated allowance.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     * - `spender` must have allowance for the caller of at least
     * `subtractedValue`.
     */
    function decreaseAllowance(address spender, uint256 subtractedValue) public virtual returns (bool) {
        address owner = _msgSender();
        uint256 currentAllowance = allowance(owner, spender);
        require(currentAllowance >= subtractedValue, "ERC20: decreased allowance below zero");
        unchecked {
            _approve(owner, spender, currentAllowance - subtractedValue);
        }

        return true;
    }

    /**
     * @dev Moves `amount` of tokens from `from` to `to`.
     *
     * This internal function is equivalent to {transfer}, and can be used to
     * e.g. implement automatic token fees, slashing mechanisms, etc.
     *
     * Emits a {Transfer} event.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `from` must have a balance of at least `amount`.
     */
    function _transfer(address from, address to, uint256 amount) internal virtual {
        require(from != address(0), "ERC20: transfer from the zero address");
        require(to != address(0), "ERC20: transfer to the zero address");

        _beforeTokenTransfer(from, to, amount);

        uint256 fromBalance = _balances[from];
        require(fromBalance >= amount, "ERC20: transfer amount exceeds balance");
        unchecked {
            _balances[from] = fromBalance - amount;
            // Overflow not possible: the sum of all balances is capped by totalSupply, and the sum is preserved by
            // decrementing then incrementing.
            _balances[to] += amount;
        }

        emit Transfer(from, to, amount);

        _afterTokenTransfer(from, to, amount);
    }

    /** @dev Creates `amount` tokens and assigns them to `account`, increasing
     * the total supply.
     *
     * Emits a {Transfer} event with `from` set to the zero address.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     */
    function _mint(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: mint to the zero address");

        _beforeTokenTransfer(address(0), account, amount);

        _totalSupply += amount;
        unchecked {
            // Overflow not possible: balance + amount is at most totalSupply + amount, which is checked above.
            _balances[account] += amount;
        }
        emit Transfer(address(0), account, amount);

        _afterTokenTransfer(address(0), account, amount);
    }

    /**
     * @dev Destroys `amount` tokens from `account`, reducing the
     * total supply.
     *
     * Emits a {Transfer} event with `to` set to the zero address.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     * - `account` must have at least `amount` tokens.
     */
    function _burn(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: burn from the zero address");

        _beforeTokenTransfer(account, address(0), amount);

        uint256 accountBalance = _balances[account];
        require(accountBalance >= amount, "ERC20: burn amount exceeds balance");
        unchecked {
            _balances[account] = accountBalance - amount;
            // Overflow not possible: amount <= accountBalance <= totalSupply.
            _totalSupply -= amount;
        }

        emit Transfer(account, address(0), amount);

        _afterTokenTransfer(account, address(0), amount);
    }

    /**
     * @dev Sets `amount` as the allowance of `spender` over the `owner` s tokens.
     *
     * This internal function is equivalent to `approve`, and can be used to
     * e.g. set automatic allowances for certain subsystems, etc.
     *
     * Emits an {Approval} event.
     *
     * Requirements:
     *
     * - `owner` cannot be the zero address.
     * - `spender` cannot be the zero address.
     */
    function _approve(address owner, address spender, uint256 amount) internal virtual {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    /**
     * @dev Updates `owner` s allowance for `spender` based on spent `amount`.
     *
     * Does not update the allowance amount in case of infinite allowance.
     * Revert if not enough allowance is available.
     *
     * Might emit an {Approval} event.
     */
    function _spendAllowance(address owner, address spender, uint256 amount) internal virtual {
        uint256 currentAllowance = allowance(owner, spender);
        if (currentAllowance != type(uint256).max) {
            require(currentAllowance >= amount, "ERC20: insufficient allowance");
            unchecked {
                _approve(owner, spender, currentAllowance - amount);
            }
        }
    }

    /**
     * @dev Hook that is called before any transfer of tokens. This includes
     * minting and burning.
     *
     * Calling conditions:
     *
     * - when `from` and `to` are both non-zero, `amount` of ``from``'s tokens
     * will be transferred to `to`.
     * - when `from` is zero, `amount` tokens will be minted for `to`.
     * - when `to` is zero, `amount` of ``from``'s tokens will be burned.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _beforeTokenTransfer(address from, address to, uint256 amount) internal virtual {}

    /**
     * @dev Hook that is called after any transfer of tokens. This includes
     * minting and burning.
     *
     * Calling conditions:
     *
     * - when `from` and `to` are both non-zero, `amount` of ``from``'s tokens
     * has been transferred to `to`.
     * - when `from` is zero, `amount` tokens have been minted for `to`.
     * - when `to` is zero, `amount` of ``from``'s tokens have been burned.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _afterTokenTransfer(address from, address to, uint256 amount) internal virtual {}
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