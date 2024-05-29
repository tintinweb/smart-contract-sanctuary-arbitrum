// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v5.0.0) (interfaces/draft-IERC6093.sol)
pragma solidity ^0.8.20;

/**
 * @dev Standard ERC20 Errors
 * Interface of the https://eips.ethereum.org/EIPS/eip-6093[ERC-6093] custom errors for ERC20 tokens.
 */
interface IERC20Errors {
    /**
     * @dev Indicates an error related to the current `balance` of a `sender`. Used in transfers.
     * @param sender Address whose tokens are being transferred.
     * @param balance Current balance for the interacting account.
     * @param needed Minimum amount required to perform a transfer.
     */
    error ERC20InsufficientBalance(address sender, uint256 balance, uint256 needed);

    /**
     * @dev Indicates a failure with the token `sender`. Used in transfers.
     * @param sender Address whose tokens are being transferred.
     */
    error ERC20InvalidSender(address sender);

    /**
     * @dev Indicates a failure with the token `receiver`. Used in transfers.
     * @param receiver Address to which tokens are being transferred.
     */
    error ERC20InvalidReceiver(address receiver);

    /**
     * @dev Indicates a failure with the `spender`’s `allowance`. Used in transfers.
     * @param spender Address that may be allowed to operate on tokens without being their owner.
     * @param allowance Amount of tokens a `spender` is allowed to operate with.
     * @param needed Minimum amount required to perform a transfer.
     */
    error ERC20InsufficientAllowance(address spender, uint256 allowance, uint256 needed);

    /**
     * @dev Indicates a failure with the `approver` of a token to be approved. Used in approvals.
     * @param approver Address initiating an approval operation.
     */
    error ERC20InvalidApprover(address approver);

    /**
     * @dev Indicates a failure with the `spender` to be approved. Used in approvals.
     * @param spender Address that may be allowed to operate on tokens without being their owner.
     */
    error ERC20InvalidSpender(address spender);
}

/**
 * @dev Standard ERC721 Errors
 * Interface of the https://eips.ethereum.org/EIPS/eip-6093[ERC-6093] custom errors for ERC721 tokens.
 */
interface IERC721Errors {
    /**
     * @dev Indicates that an address can't be an owner. For example, `address(0)` is a forbidden owner in EIP-20.
     * Used in balance queries.
     * @param owner Address of the current owner of a token.
     */
    error ERC721InvalidOwner(address owner);

    /**
     * @dev Indicates a `tokenId` whose `owner` is the zero address.
     * @param tokenId Identifier number of a token.
     */
    error ERC721NonexistentToken(uint256 tokenId);

    /**
     * @dev Indicates an error related to the ownership over a particular token. Used in transfers.
     * @param sender Address whose tokens are being transferred.
     * @param tokenId Identifier number of a token.
     * @param owner Address of the current owner of a token.
     */
    error ERC721IncorrectOwner(address sender, uint256 tokenId, address owner);

    /**
     * @dev Indicates a failure with the token `sender`. Used in transfers.
     * @param sender Address whose tokens are being transferred.
     */
    error ERC721InvalidSender(address sender);

    /**
     * @dev Indicates a failure with the token `receiver`. Used in transfers.
     * @param receiver Address to which tokens are being transferred.
     */
    error ERC721InvalidReceiver(address receiver);

    /**
     * @dev Indicates a failure with the `operator`’s approval. Used in transfers.
     * @param operator Address that may be allowed to operate on tokens without being their owner.
     * @param tokenId Identifier number of a token.
     */
    error ERC721InsufficientApproval(address operator, uint256 tokenId);

    /**
     * @dev Indicates a failure with the `approver` of a token to be approved. Used in approvals.
     * @param approver Address initiating an approval operation.
     */
    error ERC721InvalidApprover(address approver);

    /**
     * @dev Indicates a failure with the `operator` to be approved. Used in approvals.
     * @param operator Address that may be allowed to operate on tokens without being their owner.
     */
    error ERC721InvalidOperator(address operator);
}

/**
 * @dev Standard ERC1155 Errors
 * Interface of the https://eips.ethereum.org/EIPS/eip-6093[ERC-6093] custom errors for ERC1155 tokens.
 */
interface IERC1155Errors {
    /**
     * @dev Indicates an error related to the current `balance` of a `sender`. Used in transfers.
     * @param sender Address whose tokens are being transferred.
     * @param balance Current balance for the interacting account.
     * @param needed Minimum amount required to perform a transfer.
     * @param tokenId Identifier number of a token.
     */
    error ERC1155InsufficientBalance(address sender, uint256 balance, uint256 needed, uint256 tokenId);

    /**
     * @dev Indicates a failure with the token `sender`. Used in transfers.
     * @param sender Address whose tokens are being transferred.
     */
    error ERC1155InvalidSender(address sender);

    /**
     * @dev Indicates a failure with the token `receiver`. Used in transfers.
     * @param receiver Address to which tokens are being transferred.
     */
    error ERC1155InvalidReceiver(address receiver);

    /**
     * @dev Indicates a failure with the `operator`’s approval. Used in transfers.
     * @param operator Address that may be allowed to operate on tokens without being their owner.
     * @param owner Address of the current owner of a token.
     */
    error ERC1155MissingApprovalForAll(address operator, address owner);

    /**
     * @dev Indicates a failure with the `approver` of a token to be approved. Used in approvals.
     * @param approver Address initiating an approval operation.
     */
    error ERC1155InvalidApprover(address approver);

    /**
     * @dev Indicates a failure with the `operator` to be approved. Used in approvals.
     * @param operator Address that may be allowed to operate on tokens without being their owner.
     */
    error ERC1155InvalidOperator(address operator);

    /**
     * @dev Indicates an array length mismatch between ids and values in a safeBatchTransferFrom operation.
     * Used in batch transfers.
     * @param idsLength Length of the array of token identifiers
     * @param valuesLength Length of the array of token amounts
     */
    error ERC1155InvalidArrayLength(uint256 idsLength, uint256 valuesLength);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v5.0.0) (token/ERC20/ERC20.sol)

pragma solidity ^0.8.20;

import {IERC20} from "./IERC20.sol";
import {IERC20Metadata} from "./extensions/IERC20Metadata.sol";
import {Context} from "../../utils/Context.sol";
import {IERC20Errors} from "../../interfaces/draft-IERC6093.sol";

/**
 * @dev Implementation of the {IERC20} interface.
 *
 * This implementation is agnostic to the way tokens are created. This means
 * that a supply mechanism has to be added in a derived contract using {_mint}.
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
 */
abstract contract ERC20 is Context, IERC20, IERC20Metadata, IERC20Errors {
    mapping(address account => uint256) private _balances;

    mapping(address account => mapping(address spender => uint256)) private _allowances;

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
    function name() public view virtual returns (string memory) {
        return _name;
    }

    /**
     * @dev Returns the symbol of the token, usually a shorter version of the
     * name.
     */
    function symbol() public view virtual returns (string memory) {
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
    function decimals() public view virtual returns (uint8) {
        return 18;
    }

    /**
     * @dev See {IERC20-totalSupply}.
     */
    function totalSupply() public view virtual returns (uint256) {
        return _totalSupply;
    }

    /**
     * @dev See {IERC20-balanceOf}.
     */
    function balanceOf(address account) public view virtual returns (uint256) {
        return _balances[account];
    }

    /**
     * @dev See {IERC20-transfer}.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     * - the caller must have a balance of at least `value`.
     */
    function transfer(address to, uint256 value) public virtual returns (bool) {
        address owner = _msgSender();
        _transfer(owner, to, value);
        return true;
    }

    /**
     * @dev See {IERC20-allowance}.
     */
    function allowance(address owner, address spender) public view virtual returns (uint256) {
        return _allowances[owner][spender];
    }

    /**
     * @dev See {IERC20-approve}.
     *
     * NOTE: If `value` is the maximum `uint256`, the allowance is not updated on
     * `transferFrom`. This is semantically equivalent to an infinite approval.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function approve(address spender, uint256 value) public virtual returns (bool) {
        address owner = _msgSender();
        _approve(owner, spender, value);
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
     * - `from` must have a balance of at least `value`.
     * - the caller must have allowance for ``from``'s tokens of at least
     * `value`.
     */
    function transferFrom(address from, address to, uint256 value) public virtual returns (bool) {
        address spender = _msgSender();
        _spendAllowance(from, spender, value);
        _transfer(from, to, value);
        return true;
    }

    /**
     * @dev Moves a `value` amount of tokens from `from` to `to`.
     *
     * This internal function is equivalent to {transfer}, and can be used to
     * e.g. implement automatic token fees, slashing mechanisms, etc.
     *
     * Emits a {Transfer} event.
     *
     * NOTE: This function is not virtual, {_update} should be overridden instead.
     */
    function _transfer(address from, address to, uint256 value) internal {
        if (from == address(0)) {
            revert ERC20InvalidSender(address(0));
        }
        if (to == address(0)) {
            revert ERC20InvalidReceiver(address(0));
        }
        _update(from, to, value);
    }

    /**
     * @dev Transfers a `value` amount of tokens from `from` to `to`, or alternatively mints (or burns) if `from`
     * (or `to`) is the zero address. All customizations to transfers, mints, and burns should be done by overriding
     * this function.
     *
     * Emits a {Transfer} event.
     */
    function _update(address from, address to, uint256 value) internal virtual {
        if (from == address(0)) {
            // Overflow check required: The rest of the code assumes that totalSupply never overflows
            _totalSupply += value;
        } else {
            uint256 fromBalance = _balances[from];
            if (fromBalance < value) {
                revert ERC20InsufficientBalance(from, fromBalance, value);
            }
            unchecked {
                // Overflow not possible: value <= fromBalance <= totalSupply.
                _balances[from] = fromBalance - value;
            }
        }

        if (to == address(0)) {
            unchecked {
                // Overflow not possible: value <= totalSupply or value <= fromBalance <= totalSupply.
                _totalSupply -= value;
            }
        } else {
            unchecked {
                // Overflow not possible: balance + value is at most totalSupply, which we know fits into a uint256.
                _balances[to] += value;
            }
        }

        emit Transfer(from, to, value);
    }

    /**
     * @dev Creates a `value` amount of tokens and assigns them to `account`, by transferring it from address(0).
     * Relies on the `_update` mechanism
     *
     * Emits a {Transfer} event with `from` set to the zero address.
     *
     * NOTE: This function is not virtual, {_update} should be overridden instead.
     */
    function _mint(address account, uint256 value) internal {
        if (account == address(0)) {
            revert ERC20InvalidReceiver(address(0));
        }
        _update(address(0), account, value);
    }

    /**
     * @dev Destroys a `value` amount of tokens from `account`, lowering the total supply.
     * Relies on the `_update` mechanism.
     *
     * Emits a {Transfer} event with `to` set to the zero address.
     *
     * NOTE: This function is not virtual, {_update} should be overridden instead
     */
    function _burn(address account, uint256 value) internal {
        if (account == address(0)) {
            revert ERC20InvalidSender(address(0));
        }
        _update(account, address(0), value);
    }

    /**
     * @dev Sets `value` as the allowance of `spender` over the `owner` s tokens.
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
     *
     * Overrides to this logic should be done to the variant with an additional `bool emitEvent` argument.
     */
    function _approve(address owner, address spender, uint256 value) internal {
        _approve(owner, spender, value, true);
    }

    /**
     * @dev Variant of {_approve} with an optional flag to enable or disable the {Approval} event.
     *
     * By default (when calling {_approve}) the flag is set to true. On the other hand, approval changes made by
     * `_spendAllowance` during the `transferFrom` operation set the flag to false. This saves gas by not emitting any
     * `Approval` event during `transferFrom` operations.
     *
     * Anyone who wishes to continue emitting `Approval` events on the`transferFrom` operation can force the flag to
     * true using the following override:
     * ```
     * function _approve(address owner, address spender, uint256 value, bool) internal virtual override {
     *     super._approve(owner, spender, value, true);
     * }
     * ```
     *
     * Requirements are the same as {_approve}.
     */
    function _approve(address owner, address spender, uint256 value, bool emitEvent) internal virtual {
        if (owner == address(0)) {
            revert ERC20InvalidApprover(address(0));
        }
        if (spender == address(0)) {
            revert ERC20InvalidSpender(address(0));
        }
        _allowances[owner][spender] = value;
        if (emitEvent) {
            emit Approval(owner, spender, value);
        }
    }

    /**
     * @dev Updates `owner` s allowance for `spender` based on spent `value`.
     *
     * Does not update the allowance value in case of infinite allowance.
     * Revert if not enough allowance is available.
     *
     * Does not emit an {Approval} event.
     */
    function _spendAllowance(address owner, address spender, uint256 value) internal virtual {
        uint256 currentAllowance = allowance(owner, spender);
        if (currentAllowance != type(uint256).max) {
            if (currentAllowance < value) {
                revert ERC20InsufficientAllowance(spender, currentAllowance, value);
            }
            unchecked {
                _approve(owner, spender, currentAllowance - value, false);
            }
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v5.0.0) (token/ERC20/extensions/IERC20Metadata.sol)

pragma solidity ^0.8.20;

import {IERC20} from "../IERC20.sol";

/**
 * @dev Interface for the optional metadata functions from the ERC20 standard.
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

//SPDX-License-Identifier: ISC
pragma solidity ^0.8.20;

interface IStrandsPosition {
  struct TradeDetails {
    string tag50;
    string tradeId;
    bool isLong;
    uint quantity;
    uint purchasePrice;
    uint executionTime;
  }

  struct AltSymbolInfo {
    string source;
    string altSymbol;
  }

  struct PositionDetails {
    string symbol;
    string exchange;
    string clearingFirm;
    string accountNumber;
    TradeDetails[] trades;
    uint lastTradingDate;
    bool expired;
    AltSymbolInfo[] altSymbolInfos;
  }

  function transferFrom(address from, address to, uint256 id) external;

  function getOwnerTokenIds(
    address target
  ) external view returns (uint256[] memory);

  function getTokenId(
    string memory clearingFirm_,
    string memory accountNumber_,
    string memory symbol_
  ) external view returns (uint);

  function getPositionDetails(
    uint tokenId
  ) external view returns (PositionDetails memory);
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.20;

import {ERC721} from "solmate/src/tokens/ERC721.sol";
import {ERC20} from "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import {StrandsOwned} from "../strands/StrandsOwned.sol";
import {IStrandsPosition} from "../interfaces/IStrandsPosition.sol";

contract StrandsPosition is ERC721, StrandsOwned, IStrandsPosition {
  uint256 MAX_UINT =
    0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff;
  uint public mintCounter;
  string tURI;
  mapping(uint => PositionDetails) private positionDetails;
  mapping(address => uint[]) private _ownedPositionIds; // Owner -> Owned Token Ids
  mapping(bytes32 => uint) private hashMap; /// bytes32 = keccak256(abi.encodePacked(firm, ac, symbol))

  event PositionExpired(
    address tokenOwner,
    uint tokenId,
    uint totalQuantity,
    bool isLong
  );

  constructor(
    string memory _name,
    string memory _symbol,
    string memory _tURI
  ) ERC721(_name, _symbol) StrandsOwned(msg.sender, msg.sender) {
    tURI = _tURI;
  }

  function tokenURI(
    uint tokenId
  ) public view override(ERC721) returns (string memory) {
    require(
      (mintCounter == 0 || tokenId <= mintCounter),
      "can't get URI for nonexistent token"
    );
    return tURI;
  }

  function setTokenURI(
    uint tokenId,
    string memory _tURI
  ) public onlyController {
    require(
      (mintCounter == 0 || tokenId <= mintCounter),
      "can't set URI for nonexistent token"
    );
    tURI = _tURI;
  }

  function getPositionDetails(
    uint tokenId
  ) public view returns (PositionDetails memory) {
    return positionDetails[tokenId];
  }

  function mint(
    address to,
    string memory symbol_,
    string memory exchange_,
    string memory clearingFirm_,
    string memory accountNumber_,
    uint lastTradingDate_,
    TradeDetails memory tradeDetails_
  ) public onlyController returns (uint) {
    // Check NFT exists with same clearingFirm_ and accountNumber_
    bytes32 hashMapKey = keccak256(
      abi.encodePacked(clearingFirm_, accountNumber_, symbol_)
    );
    require(hashMap[hashMapKey] == 0, "NFT already exists");

    mintCounter += 1;
    positionDetails[mintCounter].trades.push(tradeDetails_);

    positionDetails[mintCounter].symbol = symbol_;
    positionDetails[mintCounter].exchange = exchange_;
    positionDetails[mintCounter].clearingFirm = clearingFirm_;
    positionDetails[mintCounter].accountNumber = accountNumber_;
    positionDetails[mintCounter].lastTradingDate = lastTradingDate_;

    hashMap[hashMapKey] = mintCounter;

    _ownedPositionIds[to].push(mintCounter);
    _safeMint(to, mintCounter);

    return mintCounter;
  }

  function addTrade(
    address owner_,
    string memory symbol_,
    string memory exchange_,
    string memory clearingFirm_,
    string memory accountNumber_,
    uint lastTradingDate_,
    TradeDetails memory tradeDetails_,
    AltSymbolInfo[] memory altSymbolInfo_
  ) external onlyController {
    // Check owner is address(0)
    require(owner_ != address(0), "Invalid owner address");

    (
      bool isPositionAvailable,
      bool isTradeIdAvailable,
      uint tokenId,
      address tokenOwner
    ) = tradeIdExists(
        symbol_,
        clearingFirm_,
        accountNumber_,
        tradeDetails_.tradeId
      );

    // Mint position to owner_ when matching position not available
    if (!isPositionAvailable) {
      tokenId = mint(
        owner_,
        symbol_,
        exchange_,
        clearingFirm_,
        accountNumber_,
        lastTradingDate_,
        tradeDetails_
      );
    } else if (!isTradeIdAvailable && tokenId > 0) {
      require(owner_ == tokenOwner, "Not correct owner");
      positionDetails[tokenId].trades.push(tradeDetails_);
    }

    for (uint i = 0; i < altSymbolInfo_.length; ++i) {
      positionDetails[tokenId].altSymbolInfos.push(altSymbolInfo_[i]);
    }
  }

  function deleteTrade(
    address owner_,
    string memory tradeId_,
    string memory symbol_,
    string memory clearingFirm_,
    string memory accountNumber_
  ) external onlyController {
    // Check owner is address(0)
    require(owner_ != address(0), "Invalid owner address");

    (
      bool isPositionAvailable,
      bool isTradeIdAvailable,
      uint tokenId,
      address tokenOwner
    ) = tradeIdExists(symbol_, clearingFirm_, accountNumber_, tradeId_);
    require(isPositionAvailable && isTradeIdAvailable, "Trade doesnt exist");
    require(owner_ == tokenOwner, "Not correct owner");

    PositionDetails memory positionDetail = positionDetails[tokenId];
    uint length = positionDetail.trades.length;
    if (positionDetail.trades.length == 1) {
      burn(tokenId);
      bytes32 hashMapKey = keccak256(
        abi.encodePacked(clearingFirm_, accountNumber_, symbol_)
      );
      hashMap[hashMapKey] = 0;
    } else {
      (, uint index) = _tradeIdExists(tokenId, tradeId_);
      positionDetails[tokenId].trades[index] = positionDetails[tokenId].trades[
        length - 1
      ];
      positionDetails[tokenId].trades.pop();
    }
  }

  function expirePosition(uint tokenId_) public onlyController {
    require(
      positionDetails[tokenId_].lastTradingDate < block.timestamp,
      "before lastTradingDate"
    );
    PositionDetails memory positionDetail = positionDetails[tokenId_];
    address tokenOwner = _ownerOf[tokenId_];

    int totalQuantity;
    for (uint i = 0; i < positionDetail.trades.length; ) {
      if (positionDetail.trades[i].isLong) {
        totalQuantity += int(positionDetail.trades[i].quantity);
      } else {
        totalQuantity -= int(positionDetail.trades[i].quantity);
      }
      unchecked {
        ++i;
      }
    }

    positionDetails[tokenId_].expired = true;

    bool isLong = totalQuantity >= 0;
    uint positiveTotalQuantity;
    if (isLong) {
      positiveTotalQuantity = uint(totalQuantity);
    } else {
      positiveTotalQuantity = MAX_UINT - uint(totalQuantity) + 1;
    }

    emit PositionExpired(tokenOwner, tokenId_, positiveTotalQuantity, isLong);
  }

  function updateSymbol(
    uint tokenId,
    string memory newSymbol
  ) external onlyController {
    // Check if new symbol is empty
    require(bytes(newSymbol).length > 0, "Symbol name can't be blank");

    PositionDetails memory positionInfo = positionDetails[tokenId];
    bytes32 prevHashMapKey = keccak256(
      abi.encodePacked(
        positionInfo.clearingFirm,
        positionInfo.accountNumber,
        positionInfo.symbol
      )
    );
    bytes32 newHashMapKey = keccak256(
      abi.encodePacked(
        positionInfo.clearingFirm,
        positionInfo.accountNumber,
        newSymbol
      )
    );
    hashMap[prevHashMapKey] = 0;
    hashMap[newHashMapKey] = tokenId;

    positionDetails[tokenId].symbol = newSymbol;
  }

  function burn(uint tokenId_) internal {
    address tokenOwner = _ownerOf[tokenId_];
    uint length = _ownedPositionIds[tokenOwner].length;
    _burn(tokenId_);
    for (uint i = 0; i < length; ) {
      if (tokenId_ == _ownedPositionIds[tokenOwner][i]) {
        _ownedPositionIds[tokenOwner][i] = _ownedPositionIds[tokenOwner][
          length - 1
        ];
        _ownedPositionIds[tokenOwner].pop();
        break;
      }
      unchecked {
        ++i;
      }
    }
  }

  function transferFrom(
    address from,
    address to,
    uint id
  ) public override(ERC721, IStrandsPosition) onlyController {
    require(from == _ownerOf[id], "WRONG_FROM");
    require(to != address(0), "INVALID_RECIPIENT");

    unchecked {
      _balanceOf[from]--;
      _balanceOf[to]++;
    }
    _ownerOf[id] = to;
    uint length = _ownedPositionIds[from].length;
    for (uint i = 0; i < length; ) {
      if (id == _ownedPositionIds[from][i]) {
        _ownedPositionIds[from][i] = _ownedPositionIds[from][length - 1];
        _ownedPositionIds[from].pop();
        break;
      }
      unchecked {
        ++i;
      }
    }
    _ownedPositionIds[to].push(id);

    delete getApproved[id];
    emit Transfer(from, to, id);
  }

  /// @dev Returns isPositionAvailable, isTradeIdAvailable, tokenId, owner address
  function tradeIdExists(
    string memory symbol_,
    string memory clearingFirm_,
    string memory accountNumber_,
    string memory tradeId_
  ) public view returns (bool, bool, uint256, address) {
    uint tokenId = getTokenId(clearingFirm_, accountNumber_, symbol_);

    // Check tokenId exists
    if (tokenId > 0) {
      (bool _exist, ) = _tradeIdExists(tokenId, tradeId_);
      return (true, _exist, tokenId, ownerOf(tokenId));
    } else {
      return (false, false, 0, address(0));
    }
  }

  function _tradeIdExists(
    uint tokenId_,
    string memory tradeId_
  ) internal view returns (bool, uint) {
    PositionDetails memory positionDetail = positionDetails[tokenId_];
    for (uint j = 0; j < positionDetail.trades.length; ) {
      if (stringCompare(positionDetail.trades[j].tradeId, tradeId_)) {
        return (true, j);
      }
      unchecked {
        ++j;
      }
    }
    return (false, 0);
  }

  function getOwnerPositions(
    address target
  ) public view returns (PositionDetails[] memory) {
    //Only return unexpired positions
    uint length = _ownedPositionIds[target].length;
    uint resultLength;
    for (uint i = 0; i < length; ++i) {
      if (positionDetails[_ownedPositionIds[target][i]].expired == false) {
        resultLength += 1;
      }
    }

    PositionDetails[] memory result = new PositionDetails[](resultLength);
    uint idx = 0;
    for (uint i = 0; i < length; ++i) {
      if (positionDetails[_ownedPositionIds[target][i]].expired == false) {
        result[idx] = positionDetails[_ownedPositionIds[target][i]];
        ++idx;
      }
    }
    return result;
  }

  function getAllPositions(
    bool filterExpirePosition
  ) public view returns (PositionDetails[] memory) {
    uint resultLength;
    for (uint i = 1; i <= mintCounter; ++i) {
      if (positionDetails[i].expired == filterExpirePosition) {
        ++resultLength;
      }
    }

    PositionDetails[] memory result = new PositionDetails[](resultLength);
    uint idx = 0;
    for (uint i = 1; i <= mintCounter; ++i) {
      if (positionDetails[i].expired == filterExpirePosition) {
        result[idx] = positionDetails[i];
        ++idx;
      }
    }

    return result;
  }

  function getTradesBetween(
    uint fromTime,
    uint toTime
  ) public view returns (TradeDetails[] memory) {
    PositionDetails[] memory unexpiredPositions = getAllPositions(false);
    uint resultLength;

    for (uint i = 0; i < unexpiredPositions.length; ++i) {
      for (uint j = 0; j < unexpiredPositions[i].trades.length; ++j) {
        if (
          fromTime < unexpiredPositions[i].trades[j].executionTime &&
          unexpiredPositions[i].trades[j].executionTime < toTime
        ) {
          ++resultLength;
        }
      }
    }

    TradeDetails[] memory result = new TradeDetails[](resultLength);
    uint idx;
    for (uint i = 0; i < unexpiredPositions.length; ++i) {
      for (uint j = 0; j < unexpiredPositions[i].trades.length; ++j) {
        if (
          fromTime < unexpiredPositions[i].trades[j].executionTime &&
          unexpiredPositions[i].trades[j].executionTime < toTime
        ) {
          result[idx] = unexpiredPositions[i].trades[j];
          ++idx;
        }
      }
    }

    return result;
  }

  function getOwnerTokenIds(
    address target
  ) public view returns (uint256[] memory) {
    //Includes all tokens including expired ones
    return _ownedPositionIds[target];
  }

  function getTokenId(
    string memory clearingFirm_,
    string memory accountNumber_,
    string memory symbol_
  ) public view returns (uint) {
    bytes32 hashMapKey = keccak256(
      abi.encodePacked(clearingFirm_, accountNumber_, symbol_)
    );
    return hashMap[hashMapKey];
  }

  function stringCompare(
    string memory str1,
    string memory str2
  ) internal pure returns (bool) {
    if (bytes(str1).length != bytes(str2).length) {
      return false;
    }
    return
      keccak256(abi.encodePacked(str1)) == keccak256(abi.encodePacked(str2));
  }
}

// SPDX-License-Identifier: MIT

/**************************************************************
 * ░██████╗████████╗██████╗░░█████╗░███╗░░██╗██████╗░░██████╗ *
 * ██╔════╝╚══██╔══╝██╔══██╗██╔══██╗████╗░██║██╔══██╗██╔════╝ *
 * ╚█████╗░░░░██║░░░██████╔╝███████║██╔██╗██║██║░░██║╚█████╗░ *
 * ░╚═══██╗░░░██║░░░██╔══██╗██╔══██║██║╚████║██║░░██║░╚═══██╗ *
 * ██████╔╝░░░██║░░░██║░░██║██║░░██║██║░╚███║██████╔╝██████╔╝ *
 * ╚═════╝░░░░╚═╝░░░╚═╝░░╚═╝╚═╝░░╚═╝╚═╝░░╚══╝╚═════╝░╚═════╝░ *
 **************************************************************/

pragma solidity 0.8.20;

import "../synthetix/AbstractOwned.sol";

/**
 * @title StrandsOwned
 * @dev Modified version of the Owned contract that takes owner address as an argument in the constructor.
 */
contract StrandsOwned is AbstractOwned {
  address[] public controllers;

  constructor(address _owner, address _controller) {
    owner = _owner;
    controllers.push(_controller);
    emit OwnerChanged(address(0), _owner);
  }

  /// @dev Set whether the given address is a controller or not
  /// @param _controller the address of the new controller
  /// @param isController_ flag to be controller or not
  function setIsController(address _controller, bool isController_) external onlyOwner {
    (bool res, uint index) = _isController(_controller);
    if (res == isController_) {
      revert ControllerAlreadySet();
    }

    if (isController_) {
      // Add controller
      controllers.push(_controller);
    } else {
      // Remove the last element
      controllers[index] = controllers[controllers.length - 1];
      controllers.pop();
    }

    emit ControllerSet(_controller, isController_);
  }

  /// @dev Returns address is controller or not
  /// @param _controller the address of the controller
  function isController(address _controller) public view returns (bool) {
    (bool res, ) = _isController(_controller);
    return res;
  }

  /// @dev Returns address is controller or not and index
  /// @param _controller the address of the controller
  function _isController(address _controller) internal view returns (bool, uint) {
    for(uint i = 0; i < controllers.length;) {
      if (controllers[i] == _controller)
        return (true, i);
      unchecked {
        i += 1;
      }
    }
    return (false, 0);
  }

  ///////////////
  // Modifiers //
  ///////////////
  modifier onlyController() {
    (bool res, ) = _isController(msg.sender);
    if (!res) {
      revert OnlyController(address(this), msg.sender);
    }
    _;
  }

  //////////////
  // Events //
  ////////////
  event ControllerSet(address controller, bool isController);

  ////////////
  // ERRORS //
  ////////////
  error ControllerAlreadySet();
  error OnlyController(address thrower, address caller);
}

//SPDX-License-Identifier: MIT
//
//Copyright (c) 2019 Synthetix
//
//Permission is hereby granted, free of charge, to any person obtaining a copy
//of this software and associated documentation files (the "Software"), to deal
//in the Software without restriction, including without limitation the rights
//to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
//copies of the Software, and to permit persons to whom the Software is
//furnished to do so, subject to the following conditions:
//
//The above copyright notice and this permission notice shall be included in all
//copies or substantial portions of the Software.
//
//THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
//IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
//FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
//AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
//LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
//OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
//SOFTWARE.

pragma solidity 0.8.20;

/**
 * @title Owned
 * @author Synthetix
 * @dev Synthetix owned contract without constructor and custom errors
 * @dev https://docs.synthetix.io/contracts/source/contracts/owned
 */
abstract contract AbstractOwned {
  address public owner;
  address public nominatedOwner;
  uint[48] private __gap;

  function nominateNewOwner(address _owner) external onlyOwner {
    nominatedOwner = _owner;
    emit OwnerNominated(_owner);
  }

  function acceptOwnership() external {
    if (msg.sender != nominatedOwner) {
      revert OnlyNominatedOwner(address(this), msg.sender, nominatedOwner);
    }
    emit OwnerChanged(owner, nominatedOwner);
    owner = nominatedOwner;
    nominatedOwner = address(0);
  }

  modifier onlyOwner() {
    _onlyOwner();
    _;
  }

  function _onlyOwner() private view {
    if (msg.sender != owner) {
      revert OnlyOwner(address(this), msg.sender, owner);
    }
  }

  event OwnerNominated(address newOwner);
  event OwnerChanged(address oldOwner, address newOwner);

  ////////////
  // Errors //
  ////////////
  error OnlyOwner(address thrower, address caller, address owner);
  error OnlyNominatedOwner(address thrower, address caller, address nominatedOwner);
}

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity >=0.8.0;

/// @notice Modern, minimalist, and gas efficient ERC-721 implementation.
/// @author Solmate (https://github.com/transmissions11/solmate/blob/main/src/tokens/ERC721.sol)
abstract contract ERC721 {
    /*//////////////////////////////////////////////////////////////
                                 EVENTS
    //////////////////////////////////////////////////////////////*/

    event Transfer(address indexed from, address indexed to, uint256 indexed id);

    event Approval(address indexed owner, address indexed spender, uint256 indexed id);

    event ApprovalForAll(address indexed owner, address indexed operator, bool approved);

    /*//////////////////////////////////////////////////////////////
                         METADATA STORAGE/LOGIC
    //////////////////////////////////////////////////////////////*/

    string public name;

    string public symbol;

    function tokenURI(uint256 id) public view virtual returns (string memory);

    /*//////////////////////////////////////////////////////////////
                      ERC721 BALANCE/OWNER STORAGE
    //////////////////////////////////////////////////////////////*/

    mapping(uint256 => address) internal _ownerOf;

    mapping(address => uint256) internal _balanceOf;

    function ownerOf(uint256 id) public view virtual returns (address owner) {
        require((owner = _ownerOf[id]) != address(0), "NOT_MINTED");
    }

    function balanceOf(address owner) public view virtual returns (uint256) {
        require(owner != address(0), "ZERO_ADDRESS");

        return _balanceOf[owner];
    }

    /*//////////////////////////////////////////////////////////////
                         ERC721 APPROVAL STORAGE
    //////////////////////////////////////////////////////////////*/

    mapping(uint256 => address) public getApproved;

    mapping(address => mapping(address => bool)) public isApprovedForAll;

    /*//////////////////////////////////////////////////////////////
                               CONSTRUCTOR
    //////////////////////////////////////////////////////////////*/

    constructor(string memory _name, string memory _symbol) {
        name = _name;
        symbol = _symbol;
    }

    /*//////////////////////////////////////////////////////////////
                              ERC721 LOGIC
    //////////////////////////////////////////////////////////////*/

    function approve(address spender, uint256 id) public virtual {
        address owner = _ownerOf[id];

        require(msg.sender == owner || isApprovedForAll[owner][msg.sender], "NOT_AUTHORIZED");

        getApproved[id] = spender;

        emit Approval(owner, spender, id);
    }

    function setApprovalForAll(address operator, bool approved) public virtual {
        isApprovedForAll[msg.sender][operator] = approved;

        emit ApprovalForAll(msg.sender, operator, approved);
    }

    function transferFrom(
        address from,
        address to,
        uint256 id
    ) public virtual {
        require(from == _ownerOf[id], "WRONG_FROM");

        require(to != address(0), "INVALID_RECIPIENT");

        require(
            msg.sender == from || isApprovedForAll[from][msg.sender] || msg.sender == getApproved[id],
            "NOT_AUTHORIZED"
        );

        // Underflow of the sender's balance is impossible because we check for
        // ownership above and the recipient's balance can't realistically overflow.
        unchecked {
            _balanceOf[from]--;

            _balanceOf[to]++;
        }

        _ownerOf[id] = to;

        delete getApproved[id];

        emit Transfer(from, to, id);
    }

    function safeTransferFrom(
        address from,
        address to,
        uint256 id
    ) public virtual {
        transferFrom(from, to, id);

        require(
            to.code.length == 0 ||
                ERC721TokenReceiver(to).onERC721Received(msg.sender, from, id, "") ==
                ERC721TokenReceiver.onERC721Received.selector,
            "UNSAFE_RECIPIENT"
        );
    }

    function safeTransferFrom(
        address from,
        address to,
        uint256 id,
        bytes calldata data
    ) public virtual {
        transferFrom(from, to, id);

        require(
            to.code.length == 0 ||
                ERC721TokenReceiver(to).onERC721Received(msg.sender, from, id, data) ==
                ERC721TokenReceiver.onERC721Received.selector,
            "UNSAFE_RECIPIENT"
        );
    }

    /*//////////////////////////////////////////////////////////////
                              ERC165 LOGIC
    //////////////////////////////////////////////////////////////*/

    function supportsInterface(bytes4 interfaceId) public view virtual returns (bool) {
        return
            interfaceId == 0x01ffc9a7 || // ERC165 Interface ID for ERC165
            interfaceId == 0x80ac58cd || // ERC165 Interface ID for ERC721
            interfaceId == 0x5b5e139f; // ERC165 Interface ID for ERC721Metadata
    }

    /*//////////////////////////////////////////////////////////////
                        INTERNAL MINT/BURN LOGIC
    //////////////////////////////////////////////////////////////*/

    function _mint(address to, uint256 id) internal virtual {
        require(to != address(0), "INVALID_RECIPIENT");

        require(_ownerOf[id] == address(0), "ALREADY_MINTED");

        // Counter overflow is incredibly unrealistic.
        unchecked {
            _balanceOf[to]++;
        }

        _ownerOf[id] = to;

        emit Transfer(address(0), to, id);
    }

    function _burn(uint256 id) internal virtual {
        address owner = _ownerOf[id];

        require(owner != address(0), "NOT_MINTED");

        // Ownership check above ensures no underflow.
        unchecked {
            _balanceOf[owner]--;
        }

        delete _ownerOf[id];

        delete getApproved[id];

        emit Transfer(owner, address(0), id);
    }

    /*//////////////////////////////////////////////////////////////
                        INTERNAL SAFE MINT LOGIC
    //////////////////////////////////////////////////////////////*/

    function _safeMint(address to, uint256 id) internal virtual {
        _mint(to, id);

        require(
            to.code.length == 0 ||
                ERC721TokenReceiver(to).onERC721Received(msg.sender, address(0), id, "") ==
                ERC721TokenReceiver.onERC721Received.selector,
            "UNSAFE_RECIPIENT"
        );
    }

    function _safeMint(
        address to,
        uint256 id,
        bytes memory data
    ) internal virtual {
        _mint(to, id);

        require(
            to.code.length == 0 ||
                ERC721TokenReceiver(to).onERC721Received(msg.sender, address(0), id, data) ==
                ERC721TokenReceiver.onERC721Received.selector,
            "UNSAFE_RECIPIENT"
        );
    }
}

/// @notice A generic interface for a contract which properly accepts ERC721 tokens.
/// @author Solmate (https://github.com/transmissions11/solmate/blob/main/src/tokens/ERC721.sol)
abstract contract ERC721TokenReceiver {
    function onERC721Received(
        address,
        address,
        uint256,
        bytes calldata
    ) external virtual returns (bytes4) {
        return ERC721TokenReceiver.onERC721Received.selector;
    }
}