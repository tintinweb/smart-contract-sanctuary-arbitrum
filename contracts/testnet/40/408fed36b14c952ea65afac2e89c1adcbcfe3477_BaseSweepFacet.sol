// SPDX-License-Identifier: MIT
pragma solidity ^0.8.14;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/token/ERC1155/IERC1155.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

import {LibSweep, PaymentTokenNotGiven} from "../../libraries/LibSweep.sol";
import "../OwnershipFacet.sol";

import "../../../../token/ANFTReceiver.sol";
import "../../../libraries/SettingsBitFlag.sol";
import "../../../libraries/Math.sol";
import "../../../../treasure/interfaces/ITroveMarketplace.sol";
import "../../../interfaces/ISmolSweeper.sol";
import "../../../errors/BuyError.sol";

contract BaseSweepFacet is OwnershipModifers {
  using SafeERC20 for IERC20;

  constructor() OwnershipModifers() {}

  function sweepFee() public view returns (uint256) {
    return LibSweep.diamondStorage().sweepFee;
  }

  function feeBasisPoints() public pure returns (uint256) {
    return LibSweep.FEE_BASIS_POINTS;
  }

  function calculateFee(uint256 _amount) external view returns (uint256) {
    return LibSweep._calculateFee(_amount);
  }

  function calculateAmountAmountWithoutFees(uint256 _amountWithFee)
    external
    view
    returns (uint256)
  {
    return LibSweep._calculateAmountWithoutFees(_amountWithFee);
  }

  function setFee(uint256 _fee) external onlyOwner {
    LibSweep.diamondStorage().sweepFee = _fee;
  }

  function getFee() external view onlyOwner returns (uint256) {
    return LibSweep.diamondStorage().sweepFee;
  }

  function _approveERC20TokenToContract(
    IERC20 _token,
    address _contract,
    uint256 _amount
  ) internal {
    _token.safeApprove(address(_contract), uint256(_amount));
  }

  function approveERC20TokenToContract(
    IERC20 _token,
    address _contract,
    uint256 _amount
  ) external onlyOwner {
    _approveERC20TokenToContract(_token, _contract, _amount);
  }

  // rescue functions
  function transferETHTo(address payable _to, uint256 _amount)
    external
    onlyOwner
  {
    _to.transfer(_amount);
  }

  function transferERC20TokenTo(
    IERC20 _token,
    address _address,
    uint256 _amount
  ) external onlyOwner {
    _token.safeTransfer(address(_address), uint256(_amount));
  }

  function transferERC721To(
    IERC721 _token,
    address _to,
    uint256 _tokenId
  ) external onlyOwner {
    _token.safeTransferFrom(address(this), _to, _tokenId);
  }

  function transferERC1155To(
    IERC1155 _token,
    address _to,
    uint256[] calldata _tokenIds,
    uint256[] calldata _amounts,
    bytes calldata _data
  ) external onlyOwner {
    _token.safeBatchTransferFrom(
      address(this),
      _to,
      _tokenIds,
      _amounts,
      _data
    );
  }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC20/IERC20.sol)

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
    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) external returns (bool);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC721/IERC721.sol)

pragma solidity ^0.8.0;

import "../../utils/introspection/IERC165.sol";

/**
 * @dev Required interface of an ERC721 compliant contract.
 */
interface IERC721 is IERC165 {
    /**
     * @dev Emitted when `tokenId` token is transferred from `from` to `to`.
     */
    event Transfer(address indexed from, address indexed to, uint256 indexed tokenId);

    /**
     * @dev Emitted when `owner` enables `approved` to manage the `tokenId` token.
     */
    event Approval(address indexed owner, address indexed approved, uint256 indexed tokenId);

    /**
     * @dev Emitted when `owner` enables or disables (`approved`) `operator` to manage all of its assets.
     */
    event ApprovalForAll(address indexed owner, address indexed operator, bool approved);

    /**
     * @dev Returns the number of tokens in ``owner``'s account.
     */
    function balanceOf(address owner) external view returns (uint256 balance);

    /**
     * @dev Returns the owner of the `tokenId` token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function ownerOf(uint256 tokenId) external view returns (address owner);

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If the caller is not `from`, it must be approved to move this token by either {approve} or {setApprovalForAll}.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes calldata data
    ) external;

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`, checking first that contract recipients
     * are aware of the ERC721 protocol to prevent tokens from being forever locked.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If the caller is not `from`, it must be have been allowed to move this token by either {approve} or {setApprovalForAll}.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;

    /**
     * @dev Transfers `tokenId` token from `from` to `to`.
     *
     * WARNING: Usage of this method is discouraged, use {safeTransferFrom} whenever possible.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must be owned by `from`.
     * - If the caller is not `from`, it must be approved to move this token by either {approve} or {setApprovalForAll}.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;

    /**
     * @dev Gives permission to `to` to transfer `tokenId` token to another account.
     * The approval is cleared when the token is transferred.
     *
     * Only a single account can be approved at a time, so approving the zero address clears previous approvals.
     *
     * Requirements:
     *
     * - The caller must own the token or be an approved operator.
     * - `tokenId` must exist.
     *
     * Emits an {Approval} event.
     */
    function approve(address to, uint256 tokenId) external;

    /**
     * @dev Approve or remove `operator` as an operator for the caller.
     * Operators can call {transferFrom} or {safeTransferFrom} for any token owned by the caller.
     *
     * Requirements:
     *
     * - The `operator` cannot be the caller.
     *
     * Emits an {ApprovalForAll} event.
     */
    function setApprovalForAll(address operator, bool _approved) external;

    /**
     * @dev Returns the account approved for `tokenId` token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function getApproved(uint256 tokenId) external view returns (address operator);

    /**
     * @dev Returns if the `operator` is allowed to manage all of the assets of `owner`.
     *
     * See {setApprovalForAll}
     */
    function isApprovedForAll(address owner, address operator) external view returns (bool);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC1155/IERC1155.sol)

pragma solidity ^0.8.0;

import "../../utils/introspection/IERC165.sol";

/**
 * @dev Required interface of an ERC1155 compliant contract, as defined in the
 * https://eips.ethereum.org/EIPS/eip-1155[EIP].
 *
 * _Available since v3.1._
 */
interface IERC1155 is IERC165 {
    /**
     * @dev Emitted when `value` tokens of token type `id` are transferred from `from` to `to` by `operator`.
     */
    event TransferSingle(address indexed operator, address indexed from, address indexed to, uint256 id, uint256 value);

    /**
     * @dev Equivalent to multiple {TransferSingle} events, where `operator`, `from` and `to` are the same for all
     * transfers.
     */
    event TransferBatch(
        address indexed operator,
        address indexed from,
        address indexed to,
        uint256[] ids,
        uint256[] values
    );

    /**
     * @dev Emitted when `account` grants or revokes permission to `operator` to transfer their tokens, according to
     * `approved`.
     */
    event ApprovalForAll(address indexed account, address indexed operator, bool approved);

    /**
     * @dev Emitted when the URI for token type `id` changes to `value`, if it is a non-programmatic URI.
     *
     * If an {URI} event was emitted for `id`, the standard
     * https://eips.ethereum.org/EIPS/eip-1155#metadata-extensions[guarantees] that `value` will equal the value
     * returned by {IERC1155MetadataURI-uri}.
     */
    event URI(string value, uint256 indexed id);

    /**
     * @dev Returns the amount of tokens of token type `id` owned by `account`.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     */
    function balanceOf(address account, uint256 id) external view returns (uint256);

    /**
     * @dev xref:ROOT:erc1155.adoc#batch-operations[Batched] version of {balanceOf}.
     *
     * Requirements:
     *
     * - `accounts` and `ids` must have the same length.
     */
    function balanceOfBatch(address[] calldata accounts, uint256[] calldata ids)
        external
        view
        returns (uint256[] memory);

    /**
     * @dev Grants or revokes permission to `operator` to transfer the caller's tokens, according to `approved`,
     *
     * Emits an {ApprovalForAll} event.
     *
     * Requirements:
     *
     * - `operator` cannot be the caller.
     */
    function setApprovalForAll(address operator, bool approved) external;

    /**
     * @dev Returns true if `operator` is approved to transfer ``account``'s tokens.
     *
     * See {setApprovalForAll}.
     */
    function isApprovedForAll(address account, address operator) external view returns (bool);

    /**
     * @dev Transfers `amount` tokens of token type `id` from `from` to `to`.
     *
     * Emits a {TransferSingle} event.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     * - If the caller is not `from`, it must be have been approved to spend ``from``'s tokens via {setApprovalForAll}.
     * - `from` must have a balance of tokens of type `id` of at least `amount`.
     * - If `to` refers to a smart contract, it must implement {IERC1155Receiver-onERC1155Received} and return the
     * acceptance magic value.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 id,
        uint256 amount,
        bytes calldata data
    ) external;

    /**
     * @dev xref:ROOT:erc1155.adoc#batch-operations[Batched] version of {safeTransferFrom}.
     *
     * Emits a {TransferBatch} event.
     *
     * Requirements:
     *
     * - `ids` and `amounts` must have the same length.
     * - If `to` refers to a smart contract, it must implement {IERC1155Receiver-onERC1155BatchReceived} and return the
     * acceptance magic value.
     */
    function safeBatchTransferFrom(
        address from,
        address to,
        uint256[] calldata ids,
        uint256[] calldata amounts,
        bytes calldata data
    ) external;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC20/utils/SafeERC20.sol)

pragma solidity ^0.8.0;

import "../IERC20.sol";
import "../../../utils/Address.sol";

/**
 * @title SafeERC20
 * @dev Wrappers around ERC20 operations that throw on failure (when the token
 * contract returns false). Tokens that return no value (and instead revert or
 * throw on failure) are also supported, non-reverting calls are assumed to be
 * successful.
 * To use this library you can add a `using SafeERC20 for IERC20;` statement to your contract,
 * which allows you to call the safe operations as `token.safeTransfer(...)`, etc.
 */
library SafeERC20 {
    using Address for address;

    function safeTransfer(
        IERC20 token,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
    }

    function safeTransferFrom(
        IERC20 token,
        address from,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transferFrom.selector, from, to, value));
    }

    /**
     * @dev Deprecated. This function has issues similar to the ones found in
     * {IERC20-approve}, and its usage is discouraged.
     *
     * Whenever possible, use {safeIncreaseAllowance} and
     * {safeDecreaseAllowance} instead.
     */
    function safeApprove(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        // safeApprove should only be called when setting an initial allowance,
        // or when resetting it to zero. To increase and decrease it, use
        // 'safeIncreaseAllowance' and 'safeDecreaseAllowance'
        require(
            (value == 0) || (token.allowance(address(this), spender) == 0),
            "SafeERC20: approve from non-zero to non-zero allowance"
        );
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, value));
    }

    function safeIncreaseAllowance(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        uint256 newAllowance = token.allowance(address(this), spender) + value;
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    function safeDecreaseAllowance(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        unchecked {
            uint256 oldAllowance = token.allowance(address(this), spender);
            require(oldAllowance >= value, "SafeERC20: decreased allowance below zero");
            uint256 newAllowance = oldAllowance - value;
            _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
        }
    }

    /**
     * @dev Imitates a Solidity high-level call (i.e. a regular function call to a contract), relaxing the requirement
     * on the return value: the return value is optional (but if data is returned, it must not be false).
     * @param token The token targeted by the call.
     * @param data The call data (encoded using abi.encode or one of its variants).
     */
    function _callOptionalReturn(IERC20 token, bytes memory data) private {
        // We need to perform a low level call here, to bypass Solidity's return data size checking mechanism, since
        // we're implementing it ourselves. We use {Address.functionCall} to perform this call, which verifies that
        // the target address contains contract code and also asserts for success in the low-level call.

        bytes memory returndata = address(token).functionCall(data, "SafeERC20: low-level call failed");
        if (returndata.length > 0) {
            // Return data is optional
            require(abi.decode(returndata, (bool)), "SafeERC20: ERC20 operation did not succeed");
        }
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/token/ERC1155/IERC1155.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "../../../treasure/interfaces/ITroveMarketplace.sol";

import {LibDiamond} from "./LibDiamond.sol";
import {LibMarketplaces} from "./LibMarketplaces.sol";

import "../../errors/BuyError.sol";
import "../../../token/ANFTReceiver.sol";
import "../../libraries/SettingsBitFlag.sol";
import "../../libraries/Math.sol";
import "../../../treasure/interfaces/ITroveMarketplace.sol";
import "../../../stratos/ExchangeV5.sol";

import "../../structs/BuyOrder.sol";

import "@contracts/sweep/structs/Swap.sol";

// import "@forge-std/src/console.sol";

error InvalidNFTAddress();
error FirstBuyReverted(bytes message);
error AllReverted();

error InvalidMsgValue();
error MsgValueShouldBeZero();
error PaymentTokenNotGiven(address _paymentToken);

error InvalidMarketplaceId();
error InvalidMarketplace();

library LibSweep {
  using SafeERC20 for IERC20;

  event SuccessBuyItem(
    address indexed _nftAddress,
    uint256 _tokenId,
    // address indexed _seller,
    address indexed _buyer,
    uint256 _quantity,
    uint256 _price
  );

  event CaughtFailureBuyItem(
    address indexed _nftAddress,
    uint256 _tokenId,
    // address indexed _seller,
    address indexed _buyer,
    uint256 _quantity,
    uint256 _price,
    bytes _errorReason
  );
  event RefundedToken(address tokenAddress, uint256 amount);

  bytes32 constant DIAMOND_STORAGE_POSITION =
    keccak256("diamond.standard.sweep.storage");

  struct SweepStorage {
    // owner of the contract
    uint256 sweepFee;
    IERC721 sweepNFT;
  }

  uint256 constant FEE_BASIS_POINTS = 1_000_000;

  bytes4 internal constant INTERFACE_ID_ERC721 = 0x80ac58cd;
  bytes4 internal constant INTERFACE_ID_ERC1155 = 0xd9b67a26;

  function diamondStorage() internal pure returns (SweepStorage storage ds) {
    bytes32 position = DIAMOND_STORAGE_POSITION;
    assembly {
      ds.slot := position
    }
  }

  function _calculateFee(uint256 _amount) internal view returns (uint256) {
    SweepStorage storage ds = diamondStorage();
    return (_amount * ds.sweepFee) / FEE_BASIS_POINTS;
  }

  function _calculateAmountWithoutFees(uint256 _amountWithFee)
    internal
    view
    returns (uint256)
  {
    SweepStorage storage ds = diamondStorage();
    return ((_amountWithFee * FEE_BASIS_POINTS) /
      (FEE_BASIS_POINTS + ds.sweepFee));
  }

  function tryBuyItemTrove(
    address _troveMarketplace,
    BuyItemParams[] memory _buyOrders
  ) internal returns (bool success, bytes memory data) {
    (success, data) = _troveMarketplace.call{
      value: (_buyOrders[0].usingEth)
        ? (_buyOrders[0].maxPricePerItem * _buyOrders[0].quantity)
        : 0
    }(abi.encodeWithSelector(ITroveMarketplace.buyItems.selector, _buyOrders));
  }

  // function tryBuyItemStratos(
  //   BuyOrder memory _buyOrder,
  //   address _paymentERC20,
  //   address _buyer,
  //   bool _usingETH
  // ) internal returns (bool success, bytes memory data) {
  //   bytes memory encoded = abi.encodeWithSelector(
  //     ExchangeV5.fillSellOrder.selector,
  //     _buyOrder.seller,
  //     _buyOrder.assetAddress,
  //     _buyOrder.tokenId,
  //     _buyOrder.startTime,
  //     _buyOrder.expiration,
  //     _buyOrder.price,
  //     _buyOrder.quantity,
  //     _buyOrder.createdAtBlockNumber,
  //     _paymentERC20,
  //     _buyOrder.signature,
  //     _buyer
  //   );
  //   (success, data) = (_buyOrder.marketplaceAddress).call{
  //     value: (_usingETH) ? (_buyOrder.price * _buyOrder.quantity) : 0
  //   }(encoded);
  // }

  function tryBuyItemStratosMulti(
    MultiTokenBuyOrder memory _buyOrder,
    address payable _buyer
  ) internal returns (bool success, bytes memory data) {
    (success, data) = _buyOrder.marketplaceAddress.call{
      value: (_buyOrder.usingETH) ? (_buyOrder.price * _buyOrder.quantity) : 0
    }(
      abi.encodeWithSelector(
        ExchangeV5.fillSellOrder.selector,
        _buyOrder.seller,
        _buyOrder.assetAddress,
        _buyOrder.tokenId,
        _buyOrder.startTime,
        _buyOrder.expiration,
        _buyOrder.price,
        _buyOrder.quantity,
        _buyOrder.createdAtBlockNumber,
        _buyOrder.paymentToken,
        _buyOrder.signature,
        _buyer
      )
    );
  }

  function _maxSpendWithoutFees(uint256[] memory _maxSpendIncFees)
    internal
    view
    returns (uint256[] memory maxSpends)
  {
    uint256 maxSpendLength = _maxSpendIncFees.length;
    maxSpends = new uint256[](maxSpendLength);

    for (uint256 i = 0; i < maxSpendLength; ) {
      maxSpends[i] = LibSweep._calculateAmountWithoutFees(_maxSpendIncFees[i]);
      unchecked {
        ++i;
      }
    }
  }

  function _getTokenIndex(
    address[] memory _paymentTokens,
    address _buyOrderPaymentToken
  ) internal pure returns (uint256 j) {
    uint256 paymentTokensLength = _paymentTokens.length;
    for (; j < paymentTokensLength; ) {
      if (_paymentTokens[j] == _buyOrderPaymentToken) {
        return j;
      }
      unchecked {
        ++j;
      }
    }
    revert PaymentTokenNotGiven(_buyOrderPaymentToken);
  }

  function _troveOrder(
    BuyOrder memory _buyOrder,
    uint64 _quantityToBuy,
    address _paymentToken,
    bool _usingETH,
    uint16 _inputSettingsBitFlag
  ) internal returns (uint256 spentAmount, bool success) {
    BuyItemParams[] memory buyItemParams = new BuyItemParams[](1);
    buyItemParams[0] = BuyItemParams(
      _buyOrder.assetAddress,
      _buyOrder.tokenId,
      _buyOrder.seller,
      _quantityToBuy,
      uint128(_buyOrder.price),
      _paymentToken,
      _usingETH
    );

    (bool spentSuccess, bytes memory data) = LibSweep.tryBuyItemTrove(
      _buyOrder.marketplaceAddress,
      buyItemParams
    );

    if (spentSuccess) {
      if (
        SettingsBitFlag.checkSetting(
          _inputSettingsBitFlag,
          SettingsBitFlag.EMIT_SUCCESS_EVENT_LOGS
        )
      ) {
        emit LibSweep.SuccessBuyItem(
          _buyOrder.assetAddress,
          _buyOrder.tokenId,
          payable(msg.sender),
          _quantityToBuy,
          _buyOrder.price
        );
      }

      if (
        IERC165(_buyOrder.assetAddress).supportsInterface(
          LibSweep.INTERFACE_ID_ERC721
        )
      ) {
        IERC721(_buyOrder.assetAddress).safeTransferFrom(
          address(this),
          msg.sender,
          _buyOrder.tokenId
        );
      } else if (
        IERC165(_buyOrder.assetAddress).supportsInterface(
          LibSweep.INTERFACE_ID_ERC1155
        )
      ) {
        IERC1155(_buyOrder.assetAddress).safeTransferFrom(
          address(this),
          msg.sender,
          _buyOrder.tokenId,
          _quantityToBuy,
          ""
        );
      } else revert InvalidNFTAddress();

      return (_buyOrder.price * _quantityToBuy, true);
    } else {
      if (
        SettingsBitFlag.checkSetting(
          _inputSettingsBitFlag,
          SettingsBitFlag.EMIT_FAILURE_EVENT_LOGS
        )
      ) {
        emit LibSweep.CaughtFailureBuyItem(
          _buyOrder.assetAddress,
          _buyOrder.tokenId,
          payable(msg.sender),
          _quantityToBuy,
          _buyOrder.price,
          data
        );
      }
      if (
        SettingsBitFlag.checkSetting(
          _inputSettingsBitFlag,
          SettingsBitFlag.MARKETPLACE_BUY_ITEM_REVERTED
        )
      ) revert FirstBuyReverted(data);
    }
    return (0, false);
  }

  function _troveOrderMultiToken(
    MultiTokenBuyOrder memory _buyOrder,
    uint64 _quantityToBuy,
    uint16 _inputSettingsBitFlag
  ) internal returns (uint256 spentAmount, bool success) {
    BuyItemParams[] memory buyItemParams = new BuyItemParams[](1);
    buyItemParams[0] = BuyItemParams(
      _buyOrder.assetAddress,
      _buyOrder.tokenId,
      _buyOrder.seller,
      uint64(_quantityToBuy),
      uint128(_buyOrder.price),
      _buyOrder.paymentToken,
      _buyOrder.usingETH
    );

    (bool spentSuccess, bytes memory data) = LibSweep.tryBuyItemTrove(
      _buyOrder.marketplaceAddress,
      buyItemParams
    );

    if (spentSuccess) {
      if (
        SettingsBitFlag.checkSetting(
          _inputSettingsBitFlag,
          SettingsBitFlag.EMIT_SUCCESS_EVENT_LOGS
        )
      ) {
        emit LibSweep.SuccessBuyItem(
          _buyOrder.assetAddress,
          _buyOrder.tokenId,
          payable(msg.sender),
          _quantityToBuy,
          _buyOrder.price
        );
      }

      if (
        IERC165(_buyOrder.assetAddress).supportsInterface(
          LibSweep.INTERFACE_ID_ERC721
        )
      ) {
        IERC721(_buyOrder.assetAddress).safeTransferFrom(
          address(this),
          msg.sender,
          _buyOrder.tokenId
        );
      } else if (
        IERC165(_buyOrder.assetAddress).supportsInterface(
          LibSweep.INTERFACE_ID_ERC1155
        )
      ) {
        IERC1155(_buyOrder.assetAddress).safeTransferFrom(
          address(this),
          msg.sender,
          _buyOrder.tokenId,
          _quantityToBuy,
          ""
        );
      } else revert InvalidNFTAddress();

      return (_buyOrder.price * _quantityToBuy, true);
    } else {
      if (
        SettingsBitFlag.checkSetting(
          _inputSettingsBitFlag,
          SettingsBitFlag.EMIT_FAILURE_EVENT_LOGS
        )
      ) {
        emit LibSweep.CaughtFailureBuyItem(
          _buyOrder.assetAddress,
          _buyOrder.tokenId,
          payable(msg.sender),
          _quantityToBuy,
          _buyOrder.price,
          data
        );
      }
      if (
        SettingsBitFlag.checkSetting(
          _inputSettingsBitFlag,
          SettingsBitFlag.MARKETPLACE_BUY_ITEM_REVERTED
        )
      ) revert FirstBuyReverted(data);
    }
    return (0, false);
  }

  // function _buyItemsSingleToken(
  //   BuyOrder[] memory _buyOrders,
  //   address _paymentToken,
  //   bool _usingETH,
  //   uint16 _inputSettingsBitFlag,
  //   uint256 _maxSpend
  // ) internal returns (uint256 totalSpentAmount, uint256 successCount) {
  //   // buy all assets
  //   for (uint256 i = 0; i < _buyOrders.length; ++i) {
  //     if (_buyOrders[i].marketplaceTypeId == LibMarketplaces.TROVE_ID) {
  //       // check if the listing exists
  //       uint64 quantityToBuy;

  //       ITroveMarketplace.ListingOrBid memory listing = ITroveMarketplace(
  //         _buyOrders[i].marketplaceAddress
  //       ).listings(
  //           _buyOrders[i].assetAddress,
  //           _buyOrders[i].tokenId,
  //           _buyOrders[i].seller
  //         );

  //       // check if total price is less than max spend allowance left
  //       if (
  //         (listing.pricePerItem * _buyOrders[i].quantity) >
  //         (_maxSpend - totalSpentAmount) &&
  //         SettingsBitFlag.checkSetting(
  //           _inputSettingsBitFlag,
  //           SettingsBitFlag.EXCEEDING_MAX_SPEND
  //         )
  //       ) break;

  //       // not enough listed items
  //       if (listing.quantity < _buyOrders[i].quantity) {
  //         if (
  //           SettingsBitFlag.checkSetting(
  //             _inputSettingsBitFlag,
  //             SettingsBitFlag.INSUFFICIENT_QUANTITY_ERC1155
  //           )
  //         ) {
  //           quantityToBuy = listing.quantity;
  //         } else {
  //           continue; // skip item
  //         }
  //       } else {
  //         quantityToBuy = uint64(_buyOrders[i].quantity);
  //       }

  //       // buy item
  //       (uint256 spentAmount, bool success) = LibSweep._troveOrder(
  //         _buyOrders[i],
  //         quantityToBuy,
  //         _paymentToken,
  //         _usingETH,
  //         _inputSettingsBitFlag
  //       );

  //       if (success) {
  //         totalSpentAmount += spentAmount;
  //         successCount++;
  //       }
  //     } else if (
  //       _buyOrders[i].marketplaceTypeId == LibMarketplaces.STRATOS_ID
  //     ) {
  //       // check if total price is less than max spend allowance left
  //       if (
  //         (_buyOrders[i].price * _buyOrders[i].quantity) >
  //         _maxSpend - totalSpentAmount &&
  //         SettingsBitFlag.checkSetting(
  //           _inputSettingsBitFlag,
  //           SettingsBitFlag.EXCEEDING_MAX_SPEND
  //         )
  //       ) break;

  //       (bool spentSuccess, bytes memory data) = LibSweep
  //         .tryBuyItemStratosMulti(MultiTokenBuyOrder(
  //           _buyOrders[i].marketplaceAddress,
  //           _buyOrders[i].assetAddress,
  //         ), payable(msg.sender));
  //       // (bool spentSuccess, bytes memory data) = LibSweep.tryBuyItemStratos(
  //       //   _buyOrders[i],
  //       //   _paymentToken,
  //       //   payable(msg.sender),
  //       //   _usingETH
  //       // );

  //       if (spentSuccess) {
  //         if (
  //           SettingsBitFlag.checkSetting(
  //             _inputSettingsBitFlag,
  //             SettingsBitFlag.EMIT_SUCCESS_EVENT_LOGS
  //           )
  //         ) {
  //           emit LibSweep.SuccessBuyItem(
  //             _buyOrders[0].assetAddress,
  //             _buyOrders[0].tokenId,
  //             payable(msg.sender),
  //             _buyOrders[0].quantity,
  //             _buyOrders[i].price
  //           );
  //         }
  //         totalSpentAmount += _buyOrders[i].price * _buyOrders[i].quantity;
  //         successCount++;
  //       } else {
  //         if (
  //           SettingsBitFlag.checkSetting(
  //             _inputSettingsBitFlag,
  //             SettingsBitFlag.EMIT_FAILURE_EVENT_LOGS
  //           )
  //         ) {
  //           emit LibSweep.CaughtFailureBuyItem(
  //             _buyOrders[0].assetAddress,
  //             _buyOrders[0].tokenId,
  //             payable(msg.sender),
  //             _buyOrders[0].quantity,
  //             _buyOrders[i].price,
  //             data
  //           );
  //         }
  //         if (
  //           SettingsBitFlag.checkSetting(
  //             _inputSettingsBitFlag,
  //             SettingsBitFlag.MARKETPLACE_BUY_ITEM_REVERTED
  //           )
  //         ) revert FirstBuyReverted(data);
  //       }
  //     } else revert InvalidMarketplaceId();
  //   }
  // }

  function _buyItemsMultiTokens(
    MultiTokenBuyOrder[] memory _buyOrders,
    uint16 _inputSettingsBitFlag,
    address[] memory _paymentTokens,
    uint256[] memory _maxSpends
  )
    internal
    returns (uint256[] memory totalSpentAmounts, uint256 successCount)
  {
    totalSpentAmounts = new uint256[](_paymentTokens.length);
    // // buy all assets
    for (uint256 i = 0; i < _buyOrders.length; ++i) {
      uint256 j = LibSweep._getTokenIndex(
        _paymentTokens,
        (_buyOrders[i].usingETH) ? address(0) : _buyOrders[i].paymentToken
      );

      if (_buyOrders[i].marketplaceTypeId == LibMarketplaces.TROVE_ID) {
        // check if the listing exists
        uint64 quantityToBuy;

        ITroveMarketplace.ListingOrBid memory listing = ITroveMarketplace(
          _buyOrders[i].marketplaceAddress
        ).listings(
            _buyOrders[i].assetAddress,
            _buyOrders[i].tokenId,
            _buyOrders[i].seller
          );

        // check if total price is less than max spend allowance left
        if (
          (listing.pricePerItem * _buyOrders[i].quantity) >
          (_maxSpends[j] - totalSpentAmounts[j]) &&
          SettingsBitFlag.checkSetting(
            _inputSettingsBitFlag,
            SettingsBitFlag.EXCEEDING_MAX_SPEND
          )
        ) break;

        // not enough listed items
        if (listing.quantity < _buyOrders[i].quantity) {
          if (
            SettingsBitFlag.checkSetting(
              _inputSettingsBitFlag,
              SettingsBitFlag.INSUFFICIENT_QUANTITY_ERC1155
            )
          ) {
            quantityToBuy = listing.quantity;
          } else {
            continue; // skip item
          }
        } else {
          quantityToBuy = uint64(_buyOrders[i].quantity);
        }

        // buy item
        (uint256 spentAmount, bool success) = LibSweep._troveOrderMultiToken(
          _buyOrders[i],
          quantityToBuy,
          _inputSettingsBitFlag
        );

        if (success) {
          totalSpentAmounts[j] += spentAmount;
          successCount++;
        }
      } else if (
        _buyOrders[i].marketplaceTypeId == LibMarketplaces.STRATOS_ID
      ) {
        // check if total price is less than max spend allowance left
        if (
          (_buyOrders[i].price * _buyOrders[i].quantity) >
          _maxSpends[j] - totalSpentAmounts[j] &&
          SettingsBitFlag.checkSetting(
            _inputSettingsBitFlag,
            SettingsBitFlag.EXCEEDING_MAX_SPEND
          )
        ) break;

        (bool spentSuccess, bytes memory data) = LibSweep
          .tryBuyItemStratosMulti(_buyOrders[i], payable(msg.sender));

        if (spentSuccess) {
          if (
            SettingsBitFlag.checkSetting(
              _inputSettingsBitFlag,
              SettingsBitFlag.EMIT_SUCCESS_EVENT_LOGS
            )
          ) {
            emit LibSweep.SuccessBuyItem(
              _buyOrders[0].assetAddress,
              _buyOrders[0].tokenId,
              payable(msg.sender),
              _buyOrders[0].quantity,
              _buyOrders[i].price
            );
          }
          totalSpentAmounts[j] += _buyOrders[i].price * _buyOrders[i].quantity;
          successCount++;
        } else {
          if (
            SettingsBitFlag.checkSetting(
              _inputSettingsBitFlag,
              SettingsBitFlag.EMIT_FAILURE_EVENT_LOGS
            )
          ) {
            emit LibSweep.CaughtFailureBuyItem(
              _buyOrders[0].assetAddress,
              _buyOrders[0].tokenId,
              payable(msg.sender),
              _buyOrders[0].quantity,
              _buyOrders[i].price,
              data
            );
          }
          if (
            SettingsBitFlag.checkSetting(
              _inputSettingsBitFlag,
              SettingsBitFlag.MARKETPLACE_BUY_ITEM_REVERTED
            )
          ) revert FirstBuyReverted(data);
        }
      } else revert InvalidMarketplaceId();
    }
  }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {IERC173} from "../interfaces/IERC173.sol";
import {LibOwnership} from "../libraries/LibOwnership.sol";
import {IDiamondInit} from "../interfaces/IDiamondInit.sol";

error NotOwner();

abstract contract OwnershipModifers {
  modifier onlyOwner() {
    if (msg.sender != LibOwnership.diamondStorage().contractOwner)
      revert NotOwner();
    _;
  }
}

contract OwnershipFacet is IERC173 {
  function transferOwnership(address _newOwner) external override {
    LibOwnership.enforceIsContractOwner();
    LibOwnership.setContractOwner(_newOwner);
  }

  function owner() external view override returns (address owner_) {
    owner_ = LibOwnership.contractOwner();
  }
}

contract OwnershipDiamondInit is IDiamondInit {
  function init() external {
    LibOwnership.setContractOwner(msg.sender);
  }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "../token/ERC1155/AERC1155Receiver.sol";
import "../token/ERC721/AERC721Receiver.sol";

abstract contract ANFTReceiver is AERC721Receiver, AERC1155Receiver {}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.11;

/**
 * @dev Settings for a buy order.
 */

library SettingsBitFlag {
    // default action is 0b00000000
    uint16 internal constant NONE = 0x00;

    // if marketplace fails to buy an item for some reason
    // default: will skip the item.
    // if 0x04 is set, will revert the entire buy transaction.
    uint16 internal constant MARKETPLACE_BUY_ITEM_REVERTED = 0x0001;

    // if the quantity of an item is less than the requested quantity (for ERC1155)
    // default: will skip the item.
    // if 0x02 is set, will buy as many items as possible (all listed items)
    uint16 internal constant INSUFFICIENT_QUANTITY_ERC1155 = 0x0002;

    // if total spend allowance is exceeded
    // default: will skip the item and continue.
    // if 0x08 is set, will skill the item and stop the transaction.
    uint16 internal constant EXCEEDING_MAX_SPEND = 0x0004;

    // refund in the input token
    // default: refunds in the payment token
    // if 0x10 is set, refunds in the input token
    uint16 internal constant REFUND_IN_INPUT_TOKEN = 0x0008;

    // turn on success event logging
    // default: will not log success events.
    // if 0x20 is set, will log success events.
    uint16 internal constant EMIT_SUCCESS_EVENT_LOGS = 0x000C;

    // turn on failure event logging
    // default: will not log failure events.
    // if 0x40 is set, will log failure events.
    uint16 internal constant EMIT_FAILURE_EVENT_LOGS = 0x0010;

    function checkSetting(uint16 _inputSettings, uint16 _settingBit)
        internal
        pure
        returns (bool)
    {
        return (_inputSettings & _settingBit) == _settingBit;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/math/Math.sol)

pragma solidity ^0.8.0;

/**
 * @dev Standard math utilities missing in the Solidity language.
 */

library Math {
    /**
     * @dev Returns the largest of two numbers.
     */
    function max(uint256 a, uint256 b) internal pure returns (uint256) {
        return a >= b ? a : b;
    }

    /**
     * @dev Returns the smallest of two numbers.
     */
    function min(uint256 a, uint256 b) internal pure returns (uint256) {
        return a < b ? a : b;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.12;

/// @title  Treasure NFT marketplace
/// @notice This contract allows you to buy and sell NFTs from token contracts that are approved by the contract owner.
///         Please note that this contract is upgradeable. In the event of a compromised ProxyAdmin contract owner,
///         collectable tokens and payments may be at risk. To prevent this, the ProxyAdmin is owned by a multi-sig
///         governed by the TreasureDAO council.
/// @dev    This contract does not store any tokens at any time, it's only collects details "the sale" and approvals
///         from both parties and preforms non-custodial transaction by transfering NFT from owner to buying and payment
///         token from buying to NFT owner.
interface ITroveMarketplace {
    struct ListingOrBid {
        /// @dev number of tokens for sale or requested (1 if ERC-721 token is active for sale) (for bids, quantity for ERC-721 can be greater than 1)
        uint64 quantity;
        /// @dev price per token sold, i.e. extended sale price equals this times quantity purchased. For bids, price offered per item.
        uint128 pricePerItem;
        /// @dev timestamp after which the listing/bid is invalid
        uint64 expirationTime;
        /// @dev the payment token for this listing/bid.
        address paymentTokenAddress;
    }

    struct CollectionOwnerFee {
        /// @dev the fee, out of 10,000, that this collection owner will be given for each sale
        uint32 fee;
        /// @dev the recipient of the collection specific fee
        address recipient;
    }

    enum TokenApprovalStatus {
        NOT_APPROVED,
        ERC_721_APPROVED,
        ERC_1155_APPROVED
    }

    /// @notice TREASURE_MARKETPLACE_ADMIN_ROLE role hash
    function TREASURE_MARKETPLACE_ADMIN_ROLE() external pure returns (bytes32);

    /// @notice the denominator for portion calculation, i.e. how many basis points are in 100%
    function BASIS_POINTS() external pure returns (uint256);

    /// @notice the maximum fee which the owner may set (in units of basis points)
    function MAX_FEE() external pure returns (uint256);

    /// @notice the maximum fee which the collection owner may set
    function MAX_COLLECTION_FEE() external pure returns (uint256);

    /// @notice the minimum price for which any item can be sold=
    function MIN_PRICE() external pure returns (uint256);

    /// @notice the default token that is used for marketplace sales and fee payments. Can be overridden by collectionToTokenAddress.
    function paymentToken() external view returns (address);

    /// @notice fee portion (in basis points) for each sale, (e.g. a value of 100 is 100/10000 = 1%). This is the fee if no collection owner fee is set.
    function fee() external view returns (uint256);

    /// @notice address that receives fees
    function feeReceipient() external view returns (address);

    /// @notice mapping for listings, maps: nftAddress => tokenId => offeror
    function listings(
        address _nftAddress,
        uint256 _tokenId,
        address _offeror
    ) external view returns (ListingOrBid memory);

    /// @notice NFTs which the owner has approved to be sold on the marketplace, maps: nftAddress => status
    function tokenApprovals(address _nftAddress)
        external
        view
        returns (TokenApprovalStatus);

    /// @notice fee portion (in basis points) for each sale. This is used if a separate fee has been set for the collection owner.
    function feeWithCollectionOwner() external view returns (uint256);

    /// @notice Maps the collection address to the fees which the collection owner collects. Some collections may not have a seperate fee, such as those owned by the Treasure DAO.
    function collectionToCollectionOwnerFee(address _collectionAddress)
        external
        view
        returns (CollectionOwnerFee memory);

    /// @notice Maps the collection address to the payment token that will be used for purchasing. If the address is the zero address, it will use the default paymentToken.
    function collectionToPaymentToken(address _collectionAddress)
        external
        view
        returns (address);

    /// @notice The address for weth.
    function weth() external view returns (address);

    /// @notice mapping for token bids (721/1155): nftAddress => tokneId => offeror
    function tokenBids(
        address _nftAddress,
        uint256 _tokenId,
        address _offeror
    ) external view returns (ListingOrBid memory);

    /// @notice mapping for collection level bids (721 only): nftAddress => offeror
    function collectionBids(address _nftAddress, address _offeror)
        external
        view
        returns (ListingOrBid memory);

    /// @notice Indicates if bid related functions are active.
    function areBidsActive() external view returns (bool);

    /// @notice The fee portion was updated
    /// @param  fee new fee amount (in units of basis points)
    event UpdateFee(uint256 fee);

    /// @notice The fee portion was updated for collections that have a collection owner.
    /// @param  fee new fee amount (in units of basis points)
    event UpdateFeeWithCollectionOwner(uint256 fee);

    /// @notice A collection's fees have changed
    /// @param  _collection  The collection
    /// @param  _recipient   The recipient of the fees. If the address is 0, the collection fees for this collection have been removed.
    /// @param  _fee         The fee amount (in units of basis points)
    event UpdateCollectionOwnerFee(
        address _collection,
        address _recipient,
        uint256 _fee
    );

    /// @notice The fee recipient was updated
    /// @param  feeRecipient the new recipient to get fees
    event UpdateFeeRecipient(address feeRecipient);

    /// @notice The approval status for a token was updated
    /// @param  nft    which token contract was updated
    /// @param  status the new status
    /// @param  paymentToken the token that will be used for payments for this collection
    event TokenApprovalStatusUpdated(
        address nft,
        TokenApprovalStatus status,
        address paymentToken
    );

    event TokenBidCreatedOrUpdated(
        address bidder,
        address nftAddress,
        uint256 tokenId,
        uint64 quantity,
        uint128 pricePerItem,
        uint64 expirationTime,
        address paymentToken
    );

    event CollectionBidCreatedOrUpdated(
        address bidder,
        address nftAddress,
        uint64 quantity,
        uint128 pricePerItem,
        uint64 expirationTime,
        address paymentToken
    );

    event TokenBidCancelled(
        address bidder,
        address nftAddress,
        uint256 tokenId
    );

    event CollectionBidCancelled(address bidder, address nftAddress);

    event BidAccepted(
        address seller,
        address bidder,
        address nftAddress,
        uint256 tokenId,
        uint64 quantity,
        uint128 pricePerItem,
        address paymentToken,
        BidType bidType
    );

    /// @notice An item was listed for sale
    /// @param  seller         the offeror of the item
    /// @param  nftAddress     which token contract holds the offered token
    /// @param  tokenId        the identifier for the offered token
    /// @param  quantity       how many of this token identifier are offered (or 1 for a ERC-721 token)
    /// @param  pricePerItem   the price (in units of the paymentToken) for each token offered
    /// @param  expirationTime UNIX timestamp after when this listing expires
    /// @param  paymentToken   the token used to list this item
    event ItemListed(
        address seller,
        address nftAddress,
        uint256 tokenId,
        uint64 quantity,
        uint128 pricePerItem,
        uint64 expirationTime,
        address paymentToken
    );

    /// @notice An item listing was updated
    /// @param  seller         the offeror of the item
    /// @param  nftAddress     which token contract holds the offered token
    /// @param  tokenId        the identifier for the offered token
    /// @param  quantity       how many of this token identifier are offered (or 1 for a ERC-721 token)
    /// @param  pricePerItem   the price (in units of the paymentToken) for each token offered
    /// @param  expirationTime UNIX timestamp after when this listing expires
    /// @param  paymentToken   the token used to list this item
    event ItemUpdated(
        address seller,
        address nftAddress,
        uint256 tokenId,
        uint64 quantity,
        uint128 pricePerItem,
        uint64 expirationTime,
        address paymentToken
    );

    /// @notice An item is no longer listed for sale
    /// @param  seller     former offeror of the item
    /// @param  nftAddress which token contract holds the formerly offered token
    /// @param  tokenId    the identifier for the formerly offered token
    event ItemCanceled(
        address indexed seller,
        address indexed nftAddress,
        uint256 indexed tokenId
    );

    /// @notice A listed item was sold
    /// @param  seller       the offeror of the item
    /// @param  buyer        the buyer of the item
    /// @param  nftAddress   which token contract holds the sold token
    /// @param  tokenId      the identifier for the sold token
    /// @param  quantity     how many of this token identifier where sold (or 1 for a ERC-721 token)
    /// @param  pricePerItem the price (in units of the paymentToken) for each token sold
    /// @param  paymentToken the payment token that was used to pay for this item
    event ItemSold(
        address seller,
        address buyer,
        address nftAddress,
        uint256 tokenId,
        uint64 quantity,
        uint128 pricePerItem,
        address paymentToken
    );

    /// @notice Perform initial contract setup
    /// @dev    The initializer modifier ensures this is only called once, the owner should confirm this was properly
    ///         performed before publishing this contract address.
    /// @param  _initialFee          fee to be paid on each sale, in basis points
    /// @param  _initialFeeRecipient wallet to collets fees
    /// @param  _initialPaymentToken address of the token that is used for settlement
    function initialize(
        uint256 _initialFee,
        address _initialFeeRecipient,
        address _initialPaymentToken
    ) external;

    /// @notice Creates an item listing. You must authorize this marketplace with your item's token contract to list.
    /// @param  _nftAddress     which token contract holds the offered token
    /// @param  _tokenId        the identifier for the offered token
    /// @param  _quantity       how many of this token identifier are offered (or 1 for a ERC-721 token)
    /// @param  _pricePerItem   the price (in units of the paymentToken) for each token offered
    /// @param  _expirationTime UNIX timestamp after when this listing expires
    function createListing(
        address _nftAddress,
        uint256 _tokenId,
        uint64 _quantity,
        uint128 _pricePerItem,
        uint64 _expirationTime,
        address _paymentToken
    ) external;

    /// @notice Updates an item listing
    /// @param  _nftAddress        which token contract holds the offered token
    /// @param  _tokenId           the identifier for the offered token
    /// @param  _newQuantity       how many of this token identifier are offered (or 1 for a ERC-721 token)
    /// @param  _newPricePerItem   the price (in units of the paymentToken) for each token offered
    /// @param  _newExpirationTime UNIX timestamp after when this listing expires
    function updateListing(
        address _nftAddress,
        uint256 _tokenId,
        uint64 _newQuantity,
        uint128 _newPricePerItem,
        uint64 _newExpirationTime,
        address _paymentToken
    ) external;

    /// @notice Remove an item listing
    /// @param  _nftAddress which token contract holds the offered token
    /// @param  _tokenId    the identifier for the offered token
    function cancelListing(address _nftAddress, uint256 _tokenId) external;

    function cancelManyBids(CancelBidParams[] calldata _cancelBidParams)
        external;

    /// @notice Creates a bid for a particular token.
    function createOrUpdateTokenBid(
        address _nftAddress,
        uint256 _tokenId,
        uint64 _quantity,
        uint128 _pricePerItem,
        uint64 _expirationTime,
        address _paymentToken
    ) external;

    function createOrUpdateCollectionBid(
        address _nftAddress,
        uint64 _quantity,
        uint128 _pricePerItem,
        uint64 _expirationTime,
        address _paymentToken
    ) external;

    function acceptCollectionBid(AcceptBidParams calldata _acceptBidParams)
        external;

    function acceptTokenBid(AcceptBidParams calldata _acceptBidParams) external;

    /// @notice Buy multiple listed items. You must authorize this marketplace with your payment token to completed the buy or purchase with eth if it is a weth collection.
    function buyItems(BuyItemParams[] calldata _buyItemParams) external payable;

    /// @notice Updates the fee amount which is collected during sales, for both collections with and without owner specific fees.
    /// @dev    This is callable only by the owner. Both fees may not exceed MAX_FEE
    /// @param  _newFee the updated fee amount is basis points
    function setFee(uint256 _newFee, uint256 _newFeeWithCollectionOwner)
        external;

    /// @notice Updates the fee amount which is collected during sales fro a specific collection
    /// @dev    This is callable only by the owner
    /// @param  _collectionAddress The collection in question. This must be whitelisted.
    /// @param _collectionOwnerFee The fee and recipient for the collection. If the 0 address is passed as the recipient, collection specific fees will not be collected.
    function setCollectionOwnerFee(
        address _collectionAddress,
        CollectionOwnerFee calldata _collectionOwnerFee
    ) external;

    /// @notice Updates the fee recipient which receives fees during sales
    /// @dev    This is callable only by the owner.
    /// @param  _newFeeRecipient the wallet to receive fees
    function setFeeRecipient(address _newFeeRecipient) external;

    /// @notice Sets a token as an approved kind of NFT or as ineligible for trading
    /// @dev    This is callable only by the owner.
    /// @param  _nft    address of the NFT to be approved
    /// @param  _status the kind of NFT approved, or NOT_APPROVED to remove approval
    function setTokenApprovalStatus(
        address _nft,
        TokenApprovalStatus _status,
        address _paymentToken
    ) external;

    function setWeth(address _wethAddress) external;

    function toggleAreBidsActive() external;

    /// @notice Pauses the marketplace, creatisgn and executing listings is paused
    /// @dev    This is callable only by the owner. Canceling listings is not paused.
    function pause() external;

    /// @notice Unpauses the marketplace, all functionality is restored
    /// @dev    This is callable only by the owner.
    function unpause() external;
}

struct BuyItemParams {
    /// which token contract holds the offered token
    address nftAddress;
    /// the identifier for the token to be bought
    uint256 tokenId;
    /// current owner of the item(s) to be bought
    address owner;
    /// how many of this token identifier to be bought (or 1 for a ERC-721 token)
    uint64 quantity;
    /// the maximum price (in units of the paymentToken) for each token offered
    uint128 maxPricePerItem;
    /// the payment token to be used
    address paymentToken;
    /// indicates if the user is purchasing this item with eth.
    bool usingEth;
}

struct AcceptBidParams {
    // Which token contract holds the given tokens
    address nftAddress;
    // The token id being given
    uint256 tokenId;
    // The user who created the bid initially
    address bidder;
    // The quantity of items being supplied to the bidder
    uint64 quantity;
    // The price per item that the bidder is offering
    uint128 pricePerItem;
    /// the payment token to be used
    address paymentToken;
}

struct CancelBidParams {
    BidType bidType;
    address nftAddress;
    uint256 tokenId;
}

enum BidType {
    TOKEN,
    COLLECTION
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.14;

//           _____                    _____                   _______                   _____            _____                    _____                    _____                    _____
//          /\    \                  /\    \                 /::\    \                 /\    \          /\    \                  /\    \                  /\    \                  /\    \
//         /::\    \                /::\____\               /::::\    \               /::\____\        /::\    \                /::\____\                /::\    \                /::\    \
//        /::::\    \              /::::|   |              /::::::\    \             /:::/    /       /::::\    \              /:::/    /               /::::\    \              /::::\    \
//       /::::::\    \            /:::::|   |             /::::::::\    \           /:::/    /       /::::::\    \            /:::/   _/___            /::::::\    \            /::::::\    \
//      /:::/\:::\    \          /::::::|   |            /:::/~~\:::\    \         /:::/    /       /:::/\:::\    \          /:::/   /\    \          /:::/\:::\    \          /:::/\:::\    \
//     /:::/__\:::\    \        /:::/|::|   |           /:::/    \:::\    \       /:::/    /       /:::/__\:::\    \        /:::/   /::\____\        /:::/__\:::\    \        /:::/__\:::\    \
//     \:::\   \:::\    \      /:::/ |::|   |          /:::/    / \:::\    \     /:::/    /        \:::\   \:::\    \      /:::/   /:::/    /       /::::\   \:::\    \      /::::\   \:::\    \
//   ___\:::\   \:::\    \    /:::/  |::|___|______   /:::/____/   \:::\____\   /:::/    /       ___\:::\   \:::\    \    /:::/   /:::/   _/___    /::::::\   \:::\    \    /::::::\   \:::\    \
//  /\   \:::\   \:::\    \  /:::/   |::::::::\    \ |:::|    |     |:::|    | /:::/    /       /\   \:::\   \:::\    \  /:::/___/:::/   /\    \  /:::/\:::\   \:::\    \  /:::/\:::\   \:::\____\
// /::\   \:::\   \:::\____\/:::/    |:::::::::\____\|:::|____|     |:::|    |/:::/____/       /::\   \:::\   \:::\____\|:::|   /:::/   /::\____\/:::/  \:::\   \:::\____\/:::/  \:::\   \:::|    |
// \:::\   \:::\   \::/    /\::/    / ~~~~~/:::/    / \:::\    \   /:::/    / \:::\    \       \:::\   \:::\   \::/    /|:::|__/:::/   /:::/    /\::/    \:::\  /:::/    /\::/    \:::\  /:::|____|
//  \:::\   \:::\   \/____/  \/____/      /:::/    /   \:::\    \ /:::/    /   \:::\    \       \:::\   \:::\   \/____/  \:::\/:::/   /:::/    /  \/____/ \:::\/:::/    /  \/_____/\:::\/:::/    /
//   \:::\   \:::\    \                  /:::/    /     \:::\    /:::/    /     \:::\    \       \:::\   \:::\    \       \::::::/   /:::/    /            \::::::/    /            \::::::/    /
//    \:::\   \:::\____\                /:::/    /       \:::\__/:::/    /       \:::\    \       \:::\   \:::\____\       \::::/___/:::/    /              \::::/    /              \::::/    /
//     \:::\  /:::/    /               /:::/    /         \::::::::/    /         \:::\    \       \:::\  /:::/    /        \:::\__/:::/    /               /:::/    /                \::/____/
//      \:::\/:::/    /               /:::/    /           \::::::/    /           \:::\    \       \:::\/:::/    /          \::::::::/    /               /:::/    /                  ~~
//       \::::::/    /               /:::/    /             \::::/    /             \:::\    \       \::::::/    /            \::::::/    /               /:::/    /
//        \::::/    /               /:::/    /               \::/____/               \:::\____\       \::::/    /              \::::/    /               /:::/    /
//         \::/    /                \::/    /                 ~~                      \::/    /        \::/    /                \::/____/                \::/    /
//          \/____/                  \/____/                                           \/____/          \/____/                  ~~                       \/____/

import "../../treasure/interfaces/ITroveMarketplace.sol";

import "../structs/BuyOrder.sol";

interface ISmolSweeper {
  // function buyItemsSingleToken(
  //   BuyOrder[] calldata _buyOrders,
  //   bool _usingETH,
  //   uint16 _inputSettingsBitFlag,
  //   address _paymentToken,
  //   uint256 _maxSpendIncFees
  // ) external payable;

  function buyItemsMultiTokens(
    MultiTokenBuyOrder[] calldata _buyOrders,
    uint16 _inputSettingsBitFlag,
    address[] calldata _paymentTokens,
    uint256[] calldata _maxSpendIncFees
  ) external payable;

  // function sweepItemsSingleToken(
  //   BuyOrder[] calldata _buyOrders,
  //   bytes[] memory _signatures,
  //   uint16 _inputSettingsBitFlag,
  //   address _inputTokenAddress,
  //   uint256 _maxSpendIncFees,
  //   uint256 _minSpend,
  //   uint32 _maxSuccesses,
  //   uint32 _maxFailures
  // ) external payable;

  // function sweepItemsMultiTokens(
  //   BuyOrder[] calldata _buyOrders,
  //   bytes[] memory _signatures,
  //   uint16 _inputSettingsBitFlag,
  //   address[] calldata _inputTokenAddresses,
  //   uint256[] calldata _maxSpendIncFees,
  //   uint256[] calldata _minSpends,
  //   uint32 _maxSuccesses,
  //   uint32 _maxFailures
  // ) external payable;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.11;

/**
 * @dev Errors
 */

enum BuyError {
  NONE,
  BUY_ITEM_REVERTED,
  INSUFFICIENT_QUANTITY_ERC1155,
  EXCEEDING_MAX_SPEND,
  OTHER
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/introspection/IERC165.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC165 standard, as defined in the
 * https://eips.ethereum.org/EIPS/eip-165[EIP].
 *
 * Implementers can declare support of contract interfaces, which can then be
 * queried by others ({ERC165Checker}).
 *
 * For an implementation, see {ERC165}.
 */
interface IERC165 {
    /**
     * @dev Returns true if this contract implements the interface defined by
     * `interfaceId`. See the corresponding
     * https://eips.ethereum.org/EIPS/eip-165#how-interfaces-are-identified[EIP section]
     * to learn more about how these ids are created.
     *
     * This function call must use less than 30 000 gas.
     */
    function supportsInterface(bytes4 interfaceId) external view returns (bool);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (utils/Address.sol)

pragma solidity ^0.8.1;

/**
 * @dev Collection of functions related to the address type
 */
library Address {
    /**
     * @dev Returns true if `account` is a contract.
     *
     * [IMPORTANT]
     * ====
     * It is unsafe to assume that an address for which this function returns
     * false is an externally-owned account (EOA) and not a contract.
     *
     * Among others, `isContract` will return false for the following
     * types of addresses:
     *
     *  - an externally-owned account
     *  - a contract in construction
     *  - an address where a contract will be created
     *  - an address where a contract lived, but was destroyed
     * ====
     *
     * [IMPORTANT]
     * ====
     * You shouldn't rely on `isContract` to protect against flash loan attacks!
     *
     * Preventing calls from contracts is highly discouraged. It breaks composability, breaks support for smart wallets
     * like Gnosis Safe, and does not provide security since it can be circumvented by calling from a contract
     * constructor.
     * ====
     */
    function isContract(address account) internal view returns (bool) {
        // This method relies on extcodesize/address.code.length, which returns 0
        // for contracts in construction, since the code is only stored at the end
        // of the constructor execution.

        return account.code.length > 0;
    }

    /**
     * @dev Replacement for Solidity's `transfer`: sends `amount` wei to
     * `recipient`, forwarding all available gas and reverting on errors.
     *
     * https://eips.ethereum.org/EIPS/eip-1884[EIP1884] increases the gas cost
     * of certain opcodes, possibly making contracts go over the 2300 gas limit
     * imposed by `transfer`, making them unable to receive funds via
     * `transfer`. {sendValue} removes this limitation.
     *
     * https://diligence.consensys.net/posts/2019/09/stop-using-soliditys-transfer-now/[Learn more].
     *
     * IMPORTANT: because control is transferred to `recipient`, care must be
     * taken to not create reentrancy vulnerabilities. Consider using
     * {ReentrancyGuard} or the
     * https://solidity.readthedocs.io/en/v0.5.11/security-considerations.html#use-the-checks-effects-interactions-pattern[checks-effects-interactions pattern].
     */
    function sendValue(address payable recipient, uint256 amount) internal {
        require(address(this).balance >= amount, "Address: insufficient balance");

        (bool success, ) = recipient.call{value: amount}("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }

    /**
     * @dev Performs a Solidity function call using a low level `call`. A
     * plain `call` is an unsafe replacement for a function call: use this
     * function instead.
     *
     * If `target` reverts with a revert reason, it is bubbled up by this
     * function (like regular Solidity function calls).
     *
     * Returns the raw returned data. To convert to the expected return value,
     * use https://solidity.readthedocs.io/en/latest/units-and-global-variables.html?highlight=abi.decode#abi-encoding-and-decoding-functions[`abi.decode`].
     *
     * Requirements:
     *
     * - `target` must be a contract.
     * - calling `target` with `data` must not revert.
     *
     * _Available since v3.1._
     */
    function functionCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionCall(target, data, "Address: low-level call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`], but with
     * `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        return functionCallWithValue(target, data, 0, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but also transferring `value` wei to `target`.
     *
     * Requirements:
     *
     * - the calling contract must have an ETH balance of at least `value`.
     * - the called Solidity function must be `payable`.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value
    ) internal returns (bytes memory) {
        return functionCallWithValue(target, data, value, "Address: low-level call with value failed");
    }

    /**
     * @dev Same as {xref-Address-functionCallWithValue-address-bytes-uint256-}[`functionCallWithValue`], but
     * with `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(address(this).balance >= value, "Address: insufficient balance for call");
        require(isContract(target), "Address: call to non-contract");

        (bool success, bytes memory returndata) = target.call{value: value}(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(address target, bytes memory data) internal view returns (bytes memory) {
        return functionStaticCall(target, data, "Address: low-level static call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal view returns (bytes memory) {
        require(isContract(target), "Address: static call to non-contract");

        (bool success, bytes memory returndata) = target.staticcall(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function functionDelegateCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionDelegateCall(target, data, "Address: low-level delegate call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function functionDelegateCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(isContract(target), "Address: delegate call to non-contract");

        (bool success, bytes memory returndata) = target.delegatecall(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Tool to verifies that a low level call was successful, and revert if it wasn't, either by bubbling the
     * revert reason using the provided one.
     *
     * _Available since v4.3._
     */
    function verifyCallResult(
        bool success,
        bytes memory returndata,
        string memory errorMessage
    ) internal pure returns (bytes memory) {
        if (success) {
            return returndata;
        } else {
            // Look for revert reason and bubble it up if present
            if (returndata.length > 0) {
                // The easiest way to bubble the revert reason is using memory via assembly

                assembly {
                    let returndata_size := mload(returndata)
                    revert(add(32, returndata), returndata_size)
                }
            } else {
                revert(errorMessage);
            }
        }
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/******************************************************************************\
* Author: Nick Mudge <[email protected]> (https://twitter.com/mudgen)
* EIP-2535 Diamonds: https://eips.ethereum.org/EIPS/eip-2535
/******************************************************************************/
import {IDiamondCut} from "../interfaces/IDiamondCut.sol";

library LibDiamond {
  error InValidFacetCutAction();
  error NotDiamondOwner();
  error NoSelectorsInFacet();
  error NoZeroAddress();
  error SelectorExists(bytes4 selector);
  error SameSelectorReplacement(bytes4 selector);
  error MustBeZeroAddress();
  error NoCode();
  error NonExistentSelector(bytes4 selector);
  error ImmutableFunction(bytes4 selector);
  error NonEmptyCalldata();
  error EmptyCalldata();
  error InitCallFailed();
  
  bytes32 constant DIAMOND_STORAGE_POSITION =
    keccak256("diamond.standard.diamond.storage");

  struct FacetAddressAndPosition {
    address facetAddress;
    uint96 functionSelectorPosition; // position in facetFunctionSelectors.functionSelectors array
  }

  struct FacetFunctionSelectors {
    bytes4[] functionSelectors;
    uint256 facetAddressPosition; // position of facetAddress in facetAddresses array
  }

  struct DiamondStorage {
    // maps function selector to the facet address and
    // the position of the selector in the facetFunctionSelectors.selectors array
    mapping(bytes4 => FacetAddressAndPosition) selectorToFacetAndPosition;
    // maps facet addresses to function selectors
    mapping(address => FacetFunctionSelectors) facetFunctionSelectors;
    // facet addresses
    address[] facetAddresses;
    // Used to query if a contract implements an interface.
    // Used to implement ERC-165.
    mapping(bytes4 => bool) supportedInterfaces;
    // owner of the contract
  }

  function diamondStorage() internal pure returns (DiamondStorage storage ds) {
    bytes32 position = DIAMOND_STORAGE_POSITION;
    assembly {
      ds.slot := position
    }
  }

  event DiamondCut(
    IDiamondCut.FacetCut[] _diamondCut,
    address _init,
    bytes _calldata
  );

  // Internal function version of diamondCut
  function diamondCut(
    IDiamondCut.FacetCut[] memory _diamondCut,
    address _init,
    bytes memory _calldata
  ) internal {
    for (uint256 facetIndex; facetIndex < _diamondCut.length; facetIndex++) {
      IDiamondCut.FacetCutAction action = _diamondCut[facetIndex].action;
      if (action == IDiamondCut.FacetCutAction.Add) {
        addFunctions(
          _diamondCut[facetIndex].facetAddress,
          _diamondCut[facetIndex].functionSelectors
        );
      } else if (action == IDiamondCut.FacetCutAction.Replace) {
        replaceFunctions(
          _diamondCut[facetIndex].facetAddress,
          _diamondCut[facetIndex].functionSelectors
        );
      } else if (action == IDiamondCut.FacetCutAction.Remove) {
        removeFunctions(
          _diamondCut[facetIndex].facetAddress,
          _diamondCut[facetIndex].functionSelectors
        );
      } else {
        revert InValidFacetCutAction();
      }
    }
    emit DiamondCut(_diamondCut, _init, _calldata);
    initializeDiamondCut(_init, _calldata);
  }

  function addFunctions(
    address _facetAddress,
    bytes4[] memory _functionSelectors
  ) internal {
    if (_functionSelectors.length <= 0) revert NoSelectorsInFacet();
    DiamondStorage storage ds = diamondStorage();
    if (_facetAddress == address(0)) revert NoZeroAddress();
    uint96 selectorPosition = uint96(
      ds.facetFunctionSelectors[_facetAddress].functionSelectors.length
    );
    // add new facet address if it does not exist
    if (selectorPosition == 0) {
      addFacet(ds, _facetAddress);
    }
    for (
      uint256 selectorIndex;
      selectorIndex < _functionSelectors.length;
      selectorIndex++
    ) {
      bytes4 selector = _functionSelectors[selectorIndex];
      address oldFacetAddress = ds
        .selectorToFacetAndPosition[selector]
        .facetAddress;
      if (oldFacetAddress != address(0)) revert SelectorExists(selector);
      addFunction(ds, selector, selectorPosition, _facetAddress);
      selectorPosition++;
    }
  }

  function replaceFunctions(
    address _facetAddress,
    bytes4[] memory _functionSelectors
  ) internal {
    if (_functionSelectors.length <= 0) revert NoSelectorsInFacet();
    DiamondStorage storage ds = diamondStorage();
    if (_facetAddress == address(0)) revert NoZeroAddress();
    uint96 selectorPosition = uint96(
      ds.facetFunctionSelectors[_facetAddress].functionSelectors.length
    );
    // add new facet address if it does not exist
    if (selectorPosition == 0) {
      addFacet(ds, _facetAddress);
    }
    for (
      uint256 selectorIndex;
      selectorIndex < _functionSelectors.length;
      selectorIndex++
    ) {
      bytes4 selector = _functionSelectors[selectorIndex];
      address oldFacetAddress = ds
        .selectorToFacetAndPosition[selector]
        .facetAddress;
      if (oldFacetAddress == _facetAddress)
        revert SameSelectorReplacement(selector);
      removeFunction(ds, oldFacetAddress, selector);
      addFunction(ds, selector, selectorPosition, _facetAddress);
      selectorPosition++;
    }
  }

  function removeFunctions(
    address _facetAddress,
    bytes4[] memory _functionSelectors
  ) internal {
    if (_functionSelectors.length <= 0) revert NoSelectorsInFacet();
    DiamondStorage storage ds = diamondStorage();
    // if function does not exist then do nothing and return
    if (_facetAddress != address(0)) revert MustBeZeroAddress();
    for (
      uint256 selectorIndex;
      selectorIndex < _functionSelectors.length;
      selectorIndex++
    ) {
      bytes4 selector = _functionSelectors[selectorIndex];
      address oldFacetAddress = ds
        .selectorToFacetAndPosition[selector]
        .facetAddress;
      removeFunction(ds, oldFacetAddress, selector);
    }
  }

  function addFacet(DiamondStorage storage ds, address _facetAddress) internal {
    enforceHasContractCode(_facetAddress);
    ds.facetFunctionSelectors[_facetAddress].facetAddressPosition = ds
      .facetAddresses
      .length;
    ds.facetAddresses.push(_facetAddress);
  }

  function addFunction(
    DiamondStorage storage ds,
    bytes4 _selector,
    uint96 _selectorPosition,
    address _facetAddress
  ) internal {
    ds
      .selectorToFacetAndPosition[_selector]
      .functionSelectorPosition = _selectorPosition;
    ds.facetFunctionSelectors[_facetAddress].functionSelectors.push(_selector);
    ds.selectorToFacetAndPosition[_selector].facetAddress = _facetAddress;
  }

  function removeFunction(
    DiamondStorage storage ds,
    address _facetAddress,
    bytes4 _selector
  ) internal {
    if (_facetAddress == address(0)) revert NonExistentSelector(_selector);
    // an immutable function is a function defined directly in a diamond
    if (_facetAddress == address(this)) revert ImmutableFunction(_selector);
    // replace selector with last selector, then delete last selector
    uint256 selectorPosition = ds
      .selectorToFacetAndPosition[_selector]
      .functionSelectorPosition;
    uint256 lastSelectorPosition = ds
      .facetFunctionSelectors[_facetAddress]
      .functionSelectors
      .length - 1;
    // if not the same then replace _selector with lastSelector
    if (selectorPosition != lastSelectorPosition) {
      bytes4 lastSelector = ds
        .facetFunctionSelectors[_facetAddress]
        .functionSelectors[lastSelectorPosition];
      ds.facetFunctionSelectors[_facetAddress].functionSelectors[
          selectorPosition
        ] = lastSelector;
      ds
        .selectorToFacetAndPosition[lastSelector]
        .functionSelectorPosition = uint96(selectorPosition);
    }
    // delete the last selector
    ds.facetFunctionSelectors[_facetAddress].functionSelectors.pop();
    delete ds.selectorToFacetAndPosition[_selector];

    // if no more selectors for facet address then delete the facet address
    if (lastSelectorPosition == 0) {
      // replace facet address with last facet address and delete last facet address
      uint256 lastFacetAddressPosition = ds.facetAddresses.length - 1;
      uint256 facetAddressPosition = ds
        .facetFunctionSelectors[_facetAddress]
        .facetAddressPosition;
      if (facetAddressPosition != lastFacetAddressPosition) {
        address lastFacetAddress = ds.facetAddresses[lastFacetAddressPosition];
        ds.facetAddresses[facetAddressPosition] = lastFacetAddress;
        ds
          .facetFunctionSelectors[lastFacetAddress]
          .facetAddressPosition = facetAddressPosition;
      }
      ds.facetAddresses.pop();
      delete ds.facetFunctionSelectors[_facetAddress].facetAddressPosition;
    }
  }

  function initializeDiamondCut(address _init, bytes memory _calldata)
    internal
  {
    if (_init == address(0)) {
      if (_calldata.length > 0) revert NonEmptyCalldata();
    } else {
      if (_calldata.length == 0) revert EmptyCalldata();
      if (_init != address(this)) {
        enforceHasContractCode(_init);
      }
      (bool success, bytes memory error) = _init.delegatecall(_calldata);
      if (!success) {
        if (error.length > 0) {
          // bubble up the error
          revert(string(error));
        } else {
          revert InitCallFailed();
        }
      }
    }
  }

  function enforceHasContractCode(address _contract) internal view {
    uint256 contractSize;
    assembly {
      contractSize := extcodesize(_contract)
    }
    if (contractSize <= 0) revert NoCode();
  }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/token/ERC1155/IERC1155.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "../../../treasure/interfaces/ITroveMarketplace.sol";

struct MarketplaceData {
  address[] paymentTokens;
  uint16 marketplaceTypeId;
}

error InvalidMarketplaceId();
error InvalidMarketplace();

library LibMarketplaces {
  bytes32 constant DIAMOND_STORAGE_POSITION =
    keccak256("diamond.standard.sweep.storage");

  struct MarketplacesStorage {
    mapping(address => MarketplaceData) marketplacesData;
  }

  uint16 internal constant TROVE_ID = 0;
  uint16 internal constant STRATOS_ID = 1;

  function diamondStorage()
    internal
    pure
    returns (MarketplacesStorage storage ds)
  {
    bytes32 position = DIAMOND_STORAGE_POSITION;
    assembly {
      ds.slot := position
    }
  }

  function _addMarketplace(
    address _marketplace,
    uint16 _marketplaceTypeId,
    address[] memory _paymentTokens
  ) internal {
    if (_marketplace == address(0)) revert InvalidMarketplace();

    diamondStorage().marketplacesData[_marketplace] = MarketplaceData(
      _paymentTokens,
      _marketplaceTypeId
    );

    for (uint256 i = 0; i < _paymentTokens.length; i++) {
      if (_paymentTokens[i] != address(0)) {
        IERC20(_paymentTokens[i]).approve(_marketplace, type(uint256).max);
      }
    }
  }

  function _setMarketplaceTypeId(
    address _marketplace,
    uint16 _marketplaceTypeId
  ) internal {
    diamondStorage()
      .marketplacesData[_marketplace]
      .marketplaceTypeId = _marketplaceTypeId;
  }

  function _addMarketplaceToken(address _marketplace, address _token) internal {
    diamondStorage().marketplacesData[_marketplace].paymentTokens.push(_token);
    IERC20(_token).approve(_marketplace, type(uint256).max);
  }

  function _getMarketplaceData(address _marketplace)
    internal
    view
    returns (MarketplaceData storage marketplaceData)
  {
    marketplaceData = diamondStorage().marketplacesData[_marketplace];
  }

  function _getMarketplacePaymentTokens(address _marketplace)
    internal
    view
    returns (address[] storage paymentTokens)
  {
    paymentTokens = diamondStorage()
      .marketplacesData[_marketplace]
      .paymentTokens;
  }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/* Interfaces */
import "./IRoyaltyRegistry.sol";
import "./ICancellationRegistry.sol";

/* Libraries */
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/interfaces/IERC721.sol";
import "@openzeppelin/contracts/interfaces/IERC1155.sol";
import "@openzeppelin/contracts/utils/introspection/ERC165Checker.sol";
import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import "@openzeppelin/contracts/utils/Address.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

contract ExchangeV5 is Ownable, Pausable, ReentrancyGuard {
    // ERC-165 identifiers
    bytes4 INTERFACE_ID_ERC721 = 0x80ac58cd;
    bytes4 INTERFACE_ID_ERC1155 = 0xd9b67a26;

    bytes32 constant EIP712_DOMAIN_TYPE_HASH =
        keccak256("EIP712Domain(string name,string version)");
    bytes32 constant DOMAIN_SEPARATOR =
        keccak256(
            abi.encode(
                EIP712_DOMAIN_TYPE_HASH,
                keccak256(bytes("Quixotic")),
                keccak256(bytes("5"))
            )
        );

    address payable _makerWallet;
    uint256 _makerFeePerMille = 25;
    uint256 _maxRoyaltyPerMille = 150;

    IRoyaltyRegistry royaltyRegistry;
    ICancellationRegistry cancellationRegistry;

    event SellOrderFilled(
        address indexed seller,
        address payable buyer,
        address indexed contractAddress,
        uint256 indexed tokenId,
        uint256 price
    );

    struct SellOrder {
        address payable seller; // Seller of the NFT
        address contractAddress; // Contract address of NFT
        uint256 tokenId; // Token id of NFT to sell
        uint256 startTime; // Start time in unix timestamp
        uint256 expiration; // Expiration in unix timestamp
        uint256 price; // Price in wei
        uint256 quantity; // Number of tokens to transfer; should be 1 for ERC721
        uint256 createdAtBlockNumber; // Block number that this order was created at
        address paymentERC20; // Should be address(0). Kept for backwards compatibility.
    }

    /********************
     * Public Functions *
     ********************/

    /*
     * @dev External trade function. This accepts the details of the sell order and signed sell
     * order (the signature) as a meta-transaction.
     *
     * Emits a {SellOrderFilled} event via `_fillSellOrder`.
     */
    function fillSellOrder(
        address payable seller,
        address contractAddress,
        uint256 tokenId,
        uint256 startTime,
        uint256 expiration,
        uint256 price,
        uint256 quantity,
        uint256 createdAtBlockNumber,
        address paymentERC20,
        bytes memory signature,
        address payable buyer
    ) external payable whenNotPaused nonReentrant {
        require(paymentERC20 == address(0), "ERC20 payments are disabled.");
        require(
            msg.value >= price,
            "Transaction doesn't have the required ETH amount."
        );

        SellOrder memory sellOrder = SellOrder(
            seller,
            contractAddress,
            tokenId,
            startTime,
            expiration,
            price,
            quantity,
            createdAtBlockNumber,
            paymentERC20
        );

        // Make sure the order is not cancelled
        require(
            cancellationRegistry.getSellOrderCancellationBlockNumber(
                seller,
                contractAddress,
                tokenId
            ) < createdAtBlockNumber,
            "This order has been cancelled."
        );

        // Check signature
        require(
            _validateSellerSignature(sellOrder, signature),
            "Signature is not valid for SellOrder."
        );

        // Check has started
        require(
            (block.timestamp > startTime),
            "SellOrder start time is in the future."
        );

        // Check not expired
        require((block.timestamp < expiration), "This sell order has expired.");

        _fillSellOrder(sellOrder, buyer);
    }

    /*
     * @dev Sets the royalty as an int out of 1000 that the creator should receive and the address to pay.
     */
    function setRoyalty(
        address contractAddress,
        address payable _payoutAddress,
        uint256 _payoutPerMille
    ) external {
        require(
            _payoutPerMille <= _maxRoyaltyPerMille,
            "Royalty must be between 0 and 15%"
        );
        require(
            ERC165Checker.supportsInterface(
                contractAddress,
                INTERFACE_ID_ERC721
            ) ||
                ERC165Checker.supportsInterface(
                    contractAddress,
                    INTERFACE_ID_ERC1155
                ),
            "Is not ERC721 or ERC1155"
        );

        Ownable ownableNFTContract = Ownable(contractAddress);
        require(_msgSender() == ownableNFTContract.owner());

        royaltyRegistry.setRoyalty(
            contractAddress,
            _payoutAddress,
            _payoutPerMille
        );
    }

    /*
     * @dev Implements one-order-cancels-the-other (OCO) for a token
     */
    function cancelPreviousSellOrders(
        address addr,
        address tokenAddr,
        uint256 tokenId
    ) external {
        require(
            (addr == _msgSender() || owner() == _msgSender()),
            "Caller must be Exchange Owner or Order Signer"
        );
        cancellationRegistry.cancelPreviousSellOrders(addr, tokenAddr, tokenId);
    }

    function calculateCurrentPrice(
        uint256 startTime,
        uint256 endTime,
        uint256 startPrice,
        uint256 endPrice
    ) public view returns (uint256) {
        uint256 auctionDuration = (endTime - startTime);
        uint256 timeRemaining = (endTime - block.timestamp);

        uint256 perMilleRemaining = (1000000000000000 / auctionDuration) /
            (1000000000000 / timeRemaining);

        uint256 variableAmount = startPrice - endPrice;
        uint256 variableAmountRemaining = (perMilleRemaining * variableAmount) /
            1000;
        return endPrice + variableAmountRemaining;
    }

    /*
     * @dev Gets the royalty payout address.
     */
    function getRoyaltyPayoutAddress(address contractAddress)
        external
        view
        returns (address)
    {
        return royaltyRegistry.getRoyaltyPayoutAddress(contractAddress);
    }

    /*
     * @dev Gets the royalty as a int out of 1000 that the creator should receive.
     */
    function getRoyaltyPayoutRate(address contractAddress)
        external
        view
        returns (uint256)
    {
        return royaltyRegistry.getRoyaltyPayoutRate(contractAddress);
    }

    /*******************
     * Admin Functions *
     *******************/

    /*
     * @dev Sets the wallet for the exchange.
     */
    function setMakerWallet(address payable _newMakerWallet)
        external
        onlyOwner
    {
        _makerWallet = _newMakerWallet;
    }

    /*
     * @dev Sets the registry contracts for the exchange.
     */
    function setRegistryContracts(
        address _royaltyRegistry,
        address _cancellationRegistry
    ) external onlyOwner {
        royaltyRegistry = IRoyaltyRegistry(_royaltyRegistry);
        cancellationRegistry = ICancellationRegistry(_cancellationRegistry);
    }

    /*
     * @dev Pauses trading on the exchange. To be used for emergencies.
     */
    function pause() external onlyOwner {
        _pause();
    }

    /*
     * @dev Resumes trading on the exchange. To be used for emergencies.
     */
    function unpause() external onlyOwner {
        _unpause();
    }

    /*
     * Withdraw just in case Ether is accidentally sent to this contract.
     */
    function withdraw() external onlyOwner {
        uint256 balance = address(this).balance;
        payable(msg.sender).transfer(balance);
    }

    /**********************
     * Internal Functions *
     **********************/

    /*
     * @dev Executes a trade given a sell order.
     *
     * Emits a {SellOrderFilled} event.
     */
    function _fillSellOrder(SellOrder memory sellOrder, address payable buyer)
        internal
    {
        // Cancels the order so that future attempts to purchase the NFT fail
        cancellationRegistry.cancelPreviousSellOrders(
            sellOrder.seller,
            sellOrder.contractAddress,
            sellOrder.tokenId
        );

        emit SellOrderFilled(
            sellOrder.seller,
            buyer,
            sellOrder.contractAddress,
            sellOrder.tokenId,
            sellOrder.price
        );

        // Transfer NFT to buyer
        _transferNFT(
            sellOrder.contractAddress,
            sellOrder.tokenId,
            sellOrder.seller,
            buyer,
            sellOrder.quantity
        );

        // Sends payments to seller, royalty receiver, and marketplace
        _sendETHPaymentsWithRoyalties(
            sellOrder.contractAddress,
            sellOrder.seller
        );
    }

    /*
     * @dev Sends out ETH payments to marketplace, royalty, and the final recipients
     */
    function _sendETHPaymentsWithRoyalties(
        address contractAddress,
        address payable finalRecipient
    ) internal {
        uint256 royaltyPayout = (royaltyRegistry.getRoyaltyPayoutRate(
            contractAddress
        ) * msg.value) / 1000;
        uint256 makerPayout = (_makerFeePerMille * msg.value) / 1000;
        uint256 remainingPayout = msg.value - royaltyPayout - makerPayout;

        if (royaltyPayout > 0) {
            Address.sendValue(
                royaltyRegistry.getRoyaltyPayoutAddress(contractAddress),
                royaltyPayout
            );
        }

        Address.sendValue(_makerWallet, makerPayout);
        Address.sendValue(finalRecipient, remainingPayout);
    }

    /*
     * @dev Validate the sell order against the signature of the meta-transaction.
     */
    function _validateSellerSignature(
        SellOrder memory sellOrder,
        bytes memory signature
    ) internal pure returns (bool) {
        bytes32 SELLORDER_TYPEHASH = keccak256(
            "SellOrder(address seller,address contractAddress,uint256 tokenId,uint256 startTime,uint256 expiration,uint256 price,uint256 quantity,uint256 createdAtBlockNumber,address paymentERC20)"
        );

        bytes32 structHash = keccak256(
            abi.encode(
                SELLORDER_TYPEHASH,
                sellOrder.seller,
                sellOrder.contractAddress,
                sellOrder.tokenId,
                sellOrder.startTime,
                sellOrder.expiration,
                sellOrder.price,
                sellOrder.quantity,
                sellOrder.createdAtBlockNumber,
                sellOrder.paymentERC20
            )
        );

        bytes32 digest = ECDSA.toTypedDataHash(DOMAIN_SEPARATOR, structHash);

        address recoveredAddress = ECDSA.recover(digest, signature);
        return recoveredAddress == sellOrder.seller;
    }

    function _transferNFT(
        address contractAddress,
        uint256 tokenId,
        address seller,
        address buyer,
        uint256 quantity
    ) internal {
        if (
            ERC165Checker.supportsInterface(
                contractAddress,
                INTERFACE_ID_ERC721
            )
        ) {
            IERC721 erc721 = IERC721(contractAddress);

            // require is approved for all */
            require(
                erc721.isApprovedForAll(seller, address(this)),
                "The Exchange is not approved to operate this NFT"
            );

            /////////////////
            ///  Transfer ///
            /////////////////
            erc721.transferFrom(seller, buyer, tokenId);
        } else if (
            ERC165Checker.supportsInterface(
                contractAddress,
                INTERFACE_ID_ERC1155
            )
        ) {
            IERC1155 erc1155 = IERC1155(contractAddress);

            /////////////////
            ///  Transfer ///
            /////////////////
            erc1155.safeTransferFrom(seller, buyer, tokenId, quantity, "");
        } else {
            revert(
                "We don't recognize the NFT as either an ERC721 or ERC1155."
            );
        }
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.14;

//           _____                    _____                   _______                   _____            _____                    _____                    _____                    _____
//          /\    \                  /\    \                 /::\    \                 /\    \          /\    \                  /\    \                  /\    \                  /\    \
//         /::\    \                /::\____\               /::::\    \               /::\____\        /::\    \                /::\____\                /::\    \                /::\    \
//        /::::\    \              /::::|   |              /::::::\    \             /:::/    /       /::::\    \              /:::/    /               /::::\    \              /::::\    \
//       /::::::\    \            /:::::|   |             /::::::::\    \           /:::/    /       /::::::\    \            /:::/   _/___            /::::::\    \            /::::::\    \
//      /:::/\:::\    \          /::::::|   |            /:::/~~\:::\    \         /:::/    /       /:::/\:::\    \          /:::/   /\    \          /:::/\:::\    \          /:::/\:::\    \
//     /:::/__\:::\    \        /:::/|::|   |           /:::/    \:::\    \       /:::/    /       /:::/__\:::\    \        /:::/   /::\____\        /:::/__\:::\    \        /:::/__\:::\    \
//     \:::\   \:::\    \      /:::/ |::|   |          /:::/    / \:::\    \     /:::/    /        \:::\   \:::\    \      /:::/   /:::/    /       /::::\   \:::\    \      /::::\   \:::\    \
//   ___\:::\   \:::\    \    /:::/  |::|___|______   /:::/____/   \:::\____\   /:::/    /       ___\:::\   \:::\    \    /:::/   /:::/   _/___    /::::::\   \:::\    \    /::::::\   \:::\    \
//  /\   \:::\   \:::\    \  /:::/   |::::::::\    \ |:::|    |     |:::|    | /:::/    /       /\   \:::\   \:::\    \  /:::/___/:::/   /\    \  /:::/\:::\   \:::\    \  /:::/\:::\   \:::\____\
// /::\   \:::\   \:::\____\/:::/    |:::::::::\____\|:::|____|     |:::|    |/:::/____/       /::\   \:::\   \:::\____\|:::|   /:::/   /::\____\/:::/  \:::\   \:::\____\/:::/  \:::\   \:::|    |
// \:::\   \:::\   \::/    /\::/    / ~~~~~/:::/    / \:::\    \   /:::/    / \:::\    \       \:::\   \:::\   \::/    /|:::|__/:::/   /:::/    /\::/    \:::\  /:::/    /\::/    \:::\  /:::|____|
//  \:::\   \:::\   \/____/  \/____/      /:::/    /   \:::\    \ /:::/    /   \:::\    \       \:::\   \:::\   \/____/  \:::\/:::/   /:::/    /  \/____/ \:::\/:::/    /  \/_____/\:::\/:::/    /
//   \:::\   \:::\    \                  /:::/    /     \:::\    /:::/    /     \:::\    \       \:::\   \:::\    \       \::::::/   /:::/    /            \::::::/    /            \::::::/    /
//    \:::\   \:::\____\                /:::/    /       \:::\__/:::/    /       \:::\    \       \:::\   \:::\____\       \::::/___/:::/    /              \::::/    /              \::::/    /
//     \:::\  /:::/    /               /:::/    /         \::::::::/    /         \:::\    \       \:::\  /:::/    /        \:::\__/:::/    /               /:::/    /                \::/____/
//      \:::\/:::/    /               /:::/    /           \::::::/    /           \:::\    \       \:::\/:::/    /          \::::::::/    /               /:::/    /                  ~~
//       \::::::/    /               /:::/    /             \::::/    /             \:::\    \       \::::::/    /            \::::::/    /               /:::/    /
//        \::::/    /               /:::/    /               \::/____/               \:::\____\       \::::/    /              \::::/    /               /:::/    /
//         \::/    /                \::/    /                 ~~                      \::/    /        \::/    /                \::/____/                \::/    /
//          \/____/                  \/____/                                           \/____/          \/____/                  ~~                       \/____/

struct BuyOrder {
  address assetAddress;
  uint256 tokenId;
  address payable seller;
  uint256 quantity;
  uint256 price;
  uint256 createdAtBlockNumber;
  uint64 startTime;
  uint64 expiration;
  address marketplaceAddress;
  uint16 marketplaceTypeId;
  bytes signature;
}

struct MultiTokenBuyOrder {
  address assetAddress;
  uint256 tokenId;
  address payable seller;
  uint256 quantity;
  uint256 price;
  uint256 createdAtBlockNumber;
  uint64 startTime;
  uint64 expiration;
  address marketplaceAddress;
  uint16 marketplaceTypeId;
  bytes signature;
  address paymentToken;
  bool usingETH;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.14;

import "@v2-periphery/contracts/interfaces/IUniswapV2Router02.sol";

enum SwapType {
  NO_SWAP,
  SWAP_ETH_TO_EXACT_TOKEN,
  SWAP_TOKEN_TO_EXACT_ETH,
  SWAP_TOKEN_TO_EXACT_TOKEN
}

struct Swap {
  uint256 amountIn;
  uint256 amountOut;
  IUniswapV2Router02 router;
  SwapType swapType;
  address[] path;
  uint64 deadline;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/// @title ERC-173 Contract Ownership Standard
///  Note: the ERC-165 identifier for this interface is 0x7f5828d0
/* is ERC165 */
interface IERC173 {
  /// @dev This emits when ownership of a contract changes.
  event OwnershipTransferred(
    address indexed previousOwner,
    address indexed newOwner
  );

  /// @notice Get the address of the owner
  /// @return owner_ The address of the owner.
  function owner() external view returns (address owner_);

  /// @notice Set the address of the new owner of the contract
  /// @dev Set _newOwner to address(0) to renounce any ownership.
  /// @param _newOwner The address of the new owner of the contract
  function transferOwnership(address _newOwner) external;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {LibDiamond} from "./LibDiamond.sol";

error NotDiamondOwner();

library LibOwnership {
  bytes32 constant DIAMOND_STORAGE_POSITION =
    keccak256("diamond.standard.ownership.storage");

  struct DiamondStorage {
    // owner of the contract
    address contractOwner;
  }

  event OwnershipTransferred(
    address indexed previousOwner,
    address indexed newOwner
  );

  function diamondStorage() internal pure returns (DiamondStorage storage ds) {
    bytes32 position = DIAMOND_STORAGE_POSITION;
    assembly {
      ds.slot := position
    }
  }

  function setContractOwner(address _newOwner) internal {
    DiamondStorage storage ds = diamondStorage();
    address previousOwner = ds.contractOwner;
    ds.contractOwner = _newOwner;
    emit OwnershipTransferred(previousOwner, _newOwner);
  }

  function contractOwner() internal view returns (address contractOwner_) {
    contractOwner_ = diamondStorage().contractOwner;
  }

  function enforceIsContractOwner() internal view {
    if (msg.sender != diamondStorage().contractOwner) revert NotDiamondOwner();
  }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IDiamondInit {
  function init() external;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.11;
import "@openzeppelin/contracts/token/ERC1155/IERC1155Receiver.sol";

abstract contract AERC1155Receiver is IERC1155Receiver {
    /**
     * Always returns `IERC1155Receiver.onERC1155ReceivedFrom.selector`.
     */
    function onERC1155Received(
        address,
        address,
        uint256,
        uint256,
        bytes calldata
    ) public virtual override returns (bytes4) {
        return this.onERC1155Received.selector;
    }

    /**
     * Always returns `IERC1155Receiver.onERC1155BatchReceived.selector`.
     */
    function onERC1155BatchReceived(
        address,
        address,
        uint256[] calldata,
        uint256[] calldata,
        bytes calldata
    ) public virtual override returns (bytes4) {
        return this.onERC1155BatchReceived.selector;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
import "@openzeppelin/contracts/token/ERC721/IERC721Receiver.sol";

abstract contract AERC721Receiver is IERC721Receiver {
    /**
     * Always returns `IERC721Receiver.onERC721Received.selector`.
     */
    function onERC721Received(
        address,
        address,
        uint256,
        bytes memory
    ) public virtual override returns (bytes4) {
        return this.onERC721Received.selector;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/******************************************************************************\
* Author: Nick Mudge <[email protected]> (https://twitter.com/mudgen)
* EIP-2535 Diamonds: https://eips.ethereum.org/EIPS/eip-2535
/******************************************************************************/

interface IDiamondCut {
  enum FacetCutAction {
    Add,
    Replace,
    Remove
  }
  // Add=0, Replace=1, Remove=2

  struct FacetCut {
    address facetAddress;
    FacetCutAction action;
    bytes4[] functionSelectors;
  }

  /// @notice Add/replace/remove any number of functions and optionally execute
  ///         a function with delegatecall
  /// @param _diamondCut Contains the facet addresses and function selectors
  /// @param _init The address of the contract or facet to execute _calldata
  /// @param _calldata A function call, including function selector and arguments
  ///                  _calldata is executed with delegatecall on _init
  function diamondCut(
    FacetCut[] calldata _diamondCut,
    address _init,
    bytes calldata _calldata
  ) external;

  event DiamondCut(FacetCut[] _diamondCut, address _init, bytes _calldata);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IRoyaltyRegistry {
    function addRegistrant(address registrant) external;

    function removeRegistrant(address registrant) external;

    function setRoyalty(address _erc721address, address payable _payoutAddress, uint256 _payoutPerMille) external;

    function getRoyaltyPayoutAddress(address _erc721address) external view returns (address payable);

    function getRoyaltyPayoutRate(address _erc721address) external view returns (uint256);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface ICancellationRegistry {
    function addRegistrant(address registrant) external;

    function removeRegistrant(address registrant) external;

    function cancelOrder(bytes memory signature) external;

    function isOrderCancelled(bytes memory signature) external view returns (bool);

    function cancelPreviousSellOrders(address seller, address tokenAddr, uint256 tokenId) external;

    function getSellOrderCancellationBlockNumber(address addr, address tokenAddr, uint256 tokenId) external view returns (uint256);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (access/Ownable.sol)

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
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
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
// OpenZeppelin Contracts v4.4.1 (interfaces/IERC721.sol)

pragma solidity ^0.8.0;

import "../token/ERC721/IERC721.sol";

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (interfaces/IERC1155.sol)

pragma solidity ^0.8.0;

import "../token/ERC1155/IERC1155.sol";

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/introspection/ERC165Checker.sol)

pragma solidity ^0.8.0;

import "./IERC165.sol";

/**
 * @dev Library used to query support of an interface declared via {IERC165}.
 *
 * Note that these functions return the actual result of the query: they do not
 * `revert` if an interface is not supported. It is up to the caller to decide
 * what to do in these cases.
 */
library ERC165Checker {
    // As per the EIP-165 spec, no interface should ever match 0xffffffff
    bytes4 private constant _INTERFACE_ID_INVALID = 0xffffffff;

    /**
     * @dev Returns true if `account` supports the {IERC165} interface,
     */
    function supportsERC165(address account) internal view returns (bool) {
        // Any contract that implements ERC165 must explicitly indicate support of
        // InterfaceId_ERC165 and explicitly indicate non-support of InterfaceId_Invalid
        return
            _supportsERC165Interface(account, type(IERC165).interfaceId) &&
            !_supportsERC165Interface(account, _INTERFACE_ID_INVALID);
    }

    /**
     * @dev Returns true if `account` supports the interface defined by
     * `interfaceId`. Support for {IERC165} itself is queried automatically.
     *
     * See {IERC165-supportsInterface}.
     */
    function supportsInterface(address account, bytes4 interfaceId) internal view returns (bool) {
        // query support of both ERC165 as per the spec and support of _interfaceId
        return supportsERC165(account) && _supportsERC165Interface(account, interfaceId);
    }

    /**
     * @dev Returns a boolean array where each value corresponds to the
     * interfaces passed in and whether they're supported or not. This allows
     * you to batch check interfaces for a contract where your expectation
     * is that some interfaces may not be supported.
     *
     * See {IERC165-supportsInterface}.
     *
     * _Available since v3.4._
     */
    function getSupportedInterfaces(address account, bytes4[] memory interfaceIds)
        internal
        view
        returns (bool[] memory)
    {
        // an array of booleans corresponding to interfaceIds and whether they're supported or not
        bool[] memory interfaceIdsSupported = new bool[](interfaceIds.length);

        // query support of ERC165 itself
        if (supportsERC165(account)) {
            // query support of each interface in interfaceIds
            for (uint256 i = 0; i < interfaceIds.length; i++) {
                interfaceIdsSupported[i] = _supportsERC165Interface(account, interfaceIds[i]);
            }
        }

        return interfaceIdsSupported;
    }

    /**
     * @dev Returns true if `account` supports all the interfaces defined in
     * `interfaceIds`. Support for {IERC165} itself is queried automatically.
     *
     * Batch-querying can lead to gas savings by skipping repeated checks for
     * {IERC165} support.
     *
     * See {IERC165-supportsInterface}.
     */
    function supportsAllInterfaces(address account, bytes4[] memory interfaceIds) internal view returns (bool) {
        // query support of ERC165 itself
        if (!supportsERC165(account)) {
            return false;
        }

        // query support of each interface in _interfaceIds
        for (uint256 i = 0; i < interfaceIds.length; i++) {
            if (!_supportsERC165Interface(account, interfaceIds[i])) {
                return false;
            }
        }

        // all interfaces supported
        return true;
    }

    /**
     * @notice Query if a contract implements an interface, does not check ERC165 support
     * @param account The address of the contract to query for support of an interface
     * @param interfaceId The interface identifier, as specified in ERC-165
     * @return true if the contract at account indicates support of the interface with
     * identifier interfaceId, false otherwise
     * @dev Assumes that account contains a contract that supports ERC165, otherwise
     * the behavior of this method is undefined. This precondition can be checked
     * with {supportsERC165}.
     * Interface identification is specified in ERC-165.
     */
    function _supportsERC165Interface(address account, bytes4 interfaceId) private view returns (bool) {
        bytes memory encodedParams = abi.encodeWithSelector(IERC165.supportsInterface.selector, interfaceId);
        (bool success, bytes memory result) = account.staticcall{gas: 30000}(encodedParams);
        if (result.length < 32) return false;
        return success && abi.decode(result, (bool));
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (utils/cryptography/ECDSA.sol)

pragma solidity ^0.8.0;

import "../Strings.sol";

/**
 * @dev Elliptic Curve Digital Signature Algorithm (ECDSA) operations.
 *
 * These functions can be used to verify that a message was signed by the holder
 * of the private keys of a given address.
 */
library ECDSA {
    enum RecoverError {
        NoError,
        InvalidSignature,
        InvalidSignatureLength,
        InvalidSignatureS,
        InvalidSignatureV
    }

    function _throwError(RecoverError error) private pure {
        if (error == RecoverError.NoError) {
            return; // no error: do nothing
        } else if (error == RecoverError.InvalidSignature) {
            revert("ECDSA: invalid signature");
        } else if (error == RecoverError.InvalidSignatureLength) {
            revert("ECDSA: invalid signature length");
        } else if (error == RecoverError.InvalidSignatureS) {
            revert("ECDSA: invalid signature 's' value");
        } else if (error == RecoverError.InvalidSignatureV) {
            revert("ECDSA: invalid signature 'v' value");
        }
    }

    /**
     * @dev Returns the address that signed a hashed message (`hash`) with
     * `signature` or error string. This address can then be used for verification purposes.
     *
     * The `ecrecover` EVM opcode allows for malleable (non-unique) signatures:
     * this function rejects them by requiring the `s` value to be in the lower
     * half order, and the `v` value to be either 27 or 28.
     *
     * IMPORTANT: `hash` _must_ be the result of a hash operation for the
     * verification to be secure: it is possible to craft signatures that
     * recover to arbitrary addresses for non-hashed data. A safe way to ensure
     * this is by receiving a hash of the original message (which may otherwise
     * be too long), and then calling {toEthSignedMessageHash} on it.
     *
     * Documentation for signature generation:
     * - with https://web3js.readthedocs.io/en/v1.3.4/web3-eth-accounts.html#sign[Web3.js]
     * - with https://docs.ethers.io/v5/api/signer/#Signer-signMessage[ethers]
     *
     * _Available since v4.3._
     */
    function tryRecover(bytes32 hash, bytes memory signature) internal pure returns (address, RecoverError) {
        // Check the signature length
        // - case 65: r,s,v signature (standard)
        // - case 64: r,vs signature (cf https://eips.ethereum.org/EIPS/eip-2098) _Available since v4.1._
        if (signature.length == 65) {
            bytes32 r;
            bytes32 s;
            uint8 v;
            // ecrecover takes the signature parameters, and the only way to get them
            // currently is to use assembly.
            /// @solidity memory-safe-assembly
            assembly {
                r := mload(add(signature, 0x20))
                s := mload(add(signature, 0x40))
                v := byte(0, mload(add(signature, 0x60)))
            }
            return tryRecover(hash, v, r, s);
        } else if (signature.length == 64) {
            bytes32 r;
            bytes32 vs;
            // ecrecover takes the signature parameters, and the only way to get them
            // currently is to use assembly.
            /// @solidity memory-safe-assembly
            assembly {
                r := mload(add(signature, 0x20))
                vs := mload(add(signature, 0x40))
            }
            return tryRecover(hash, r, vs);
        } else {
            return (address(0), RecoverError.InvalidSignatureLength);
        }
    }

    /**
     * @dev Returns the address that signed a hashed message (`hash`) with
     * `signature`. This address can then be used for verification purposes.
     *
     * The `ecrecover` EVM opcode allows for malleable (non-unique) signatures:
     * this function rejects them by requiring the `s` value to be in the lower
     * half order, and the `v` value to be either 27 or 28.
     *
     * IMPORTANT: `hash` _must_ be the result of a hash operation for the
     * verification to be secure: it is possible to craft signatures that
     * recover to arbitrary addresses for non-hashed data. A safe way to ensure
     * this is by receiving a hash of the original message (which may otherwise
     * be too long), and then calling {toEthSignedMessageHash} on it.
     */
    function recover(bytes32 hash, bytes memory signature) internal pure returns (address) {
        (address recovered, RecoverError error) = tryRecover(hash, signature);
        _throwError(error);
        return recovered;
    }

    /**
     * @dev Overload of {ECDSA-tryRecover} that receives the `r` and `vs` short-signature fields separately.
     *
     * See https://eips.ethereum.org/EIPS/eip-2098[EIP-2098 short signatures]
     *
     * _Available since v4.3._
     */
    function tryRecover(
        bytes32 hash,
        bytes32 r,
        bytes32 vs
    ) internal pure returns (address, RecoverError) {
        bytes32 s = vs & bytes32(0x7fffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff);
        uint8 v = uint8((uint256(vs) >> 255) + 27);
        return tryRecover(hash, v, r, s);
    }

    /**
     * @dev Overload of {ECDSA-recover} that receives the `r and `vs` short-signature fields separately.
     *
     * _Available since v4.2._
     */
    function recover(
        bytes32 hash,
        bytes32 r,
        bytes32 vs
    ) internal pure returns (address) {
        (address recovered, RecoverError error) = tryRecover(hash, r, vs);
        _throwError(error);
        return recovered;
    }

    /**
     * @dev Overload of {ECDSA-tryRecover} that receives the `v`,
     * `r` and `s` signature fields separately.
     *
     * _Available since v4.3._
     */
    function tryRecover(
        bytes32 hash,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) internal pure returns (address, RecoverError) {
        // EIP-2 still allows signature malleability for ecrecover(). Remove this possibility and make the signature
        // unique. Appendix F in the Ethereum Yellow paper (https://ethereum.github.io/yellowpaper/paper.pdf), defines
        // the valid range for s in (301): 0 < s < secp256k1n ÷ 2 + 1, and for v in (302): v ∈ {27, 28}. Most
        // signatures from current libraries generate a unique signature with an s-value in the lower half order.
        //
        // If your library generates malleable signatures, such as s-values in the upper range, calculate a new s-value
        // with 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFEBAAEDCE6AF48A03BBFD25E8CD0364141 - s1 and flip v from 27 to 28 or
        // vice versa. If your library also generates signatures with 0/1 for v instead 27/28, add 27 to v to accept
        // these malleable signatures as well.
        if (uint256(s) > 0x7FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF5D576E7357A4501DDFE92F46681B20A0) {
            return (address(0), RecoverError.InvalidSignatureS);
        }
        if (v != 27 && v != 28) {
            return (address(0), RecoverError.InvalidSignatureV);
        }

        // If the signature is valid (and not malleable), return the signer address
        address signer = ecrecover(hash, v, r, s);
        if (signer == address(0)) {
            return (address(0), RecoverError.InvalidSignature);
        }

        return (signer, RecoverError.NoError);
    }

    /**
     * @dev Overload of {ECDSA-recover} that receives the `v`,
     * `r` and `s` signature fields separately.
     */
    function recover(
        bytes32 hash,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) internal pure returns (address) {
        (address recovered, RecoverError error) = tryRecover(hash, v, r, s);
        _throwError(error);
        return recovered;
    }

    /**
     * @dev Returns an Ethereum Signed Message, created from a `hash`. This
     * produces hash corresponding to the one signed with the
     * https://eth.wiki/json-rpc/API#eth_sign[`eth_sign`]
     * JSON-RPC method as part of EIP-191.
     *
     * See {recover}.
     */
    function toEthSignedMessageHash(bytes32 hash) internal pure returns (bytes32) {
        // 32 is the length in bytes of hash,
        // enforced by the type signature above
        return keccak256(abi.encodePacked("\x19Ethereum Signed Message:\n32", hash));
    }

    /**
     * @dev Returns an Ethereum Signed Message, created from `s`. This
     * produces hash corresponding to the one signed with the
     * https://eth.wiki/json-rpc/API#eth_sign[`eth_sign`]
     * JSON-RPC method as part of EIP-191.
     *
     * See {recover}.
     */
    function toEthSignedMessageHash(bytes memory s) internal pure returns (bytes32) {
        return keccak256(abi.encodePacked("\x19Ethereum Signed Message:\n", Strings.toString(s.length), s));
    }

    /**
     * @dev Returns an Ethereum Signed Typed Data, created from a
     * `domainSeparator` and a `structHash`. This produces hash corresponding
     * to the one signed with the
     * https://eips.ethereum.org/EIPS/eip-712[`eth_signTypedData`]
     * JSON-RPC method as part of EIP-712.
     *
     * See {recover}.
     */
    function toTypedDataHash(bytes32 domainSeparator, bytes32 structHash) internal pure returns (bytes32) {
        return keccak256(abi.encodePacked("\x19\x01", domainSeparator, structHash));
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (security/Pausable.sol)

pragma solidity ^0.8.0;

import "../utils/Context.sol";

/**
 * @dev Contract module which allows children to implement an emergency stop
 * mechanism that can be triggered by an authorized account.
 *
 * This module is used through inheritance. It will make available the
 * modifiers `whenNotPaused` and `whenPaused`, which can be applied to
 * the functions of your contract. Note that they will not be pausable by
 * simply including this module, only once the modifiers are put in place.
 */
abstract contract Pausable is Context {
    /**
     * @dev Emitted when the pause is triggered by `account`.
     */
    event Paused(address account);

    /**
     * @dev Emitted when the pause is lifted by `account`.
     */
    event Unpaused(address account);

    bool private _paused;

    /**
     * @dev Initializes the contract in unpaused state.
     */
    constructor() {
        _paused = false;
    }

    /**
     * @dev Returns true if the contract is paused, and false otherwise.
     */
    function paused() public view virtual returns (bool) {
        return _paused;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is not paused.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    modifier whenNotPaused() {
        require(!paused(), "Pausable: paused");
        _;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is paused.
     *
     * Requirements:
     *
     * - The contract must be paused.
     */
    modifier whenPaused() {
        require(paused(), "Pausable: not paused");
        _;
    }

    /**
     * @dev Triggers stopped state.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    function _pause() internal virtual whenNotPaused {
        _paused = true;
        emit Paused(_msgSender());
    }

    /**
     * @dev Returns to normal state.
     *
     * Requirements:
     *
     * - The contract must be paused.
     */
    function _unpause() internal virtual whenPaused {
        _paused = false;
        emit Unpaused(_msgSender());
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (security/ReentrancyGuard.sol)

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
        // On the first call to nonReentrant, _notEntered will be true
        require(_status != _ENTERED, "ReentrancyGuard: reentrant call");

        // Any calls to nonReentrant after this point will fail
        _status = _ENTERED;

        _;

        // By storing the original value once again, a refund is triggered (see
        // https://eips.ethereum.org/EIPS/eip-2200)
        _status = _NOT_ENTERED;
    }
}

pragma solidity >=0.6.2;

import './IUniswapV2Router01.sol';

interface IUniswapV2Router02 is IUniswapV2Router01 {
    function removeLiquidityETHSupportingFeeOnTransferTokens(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    ) external returns (uint amountETH);
    function removeLiquidityETHWithPermitSupportingFeeOnTransferTokens(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline,
        bool approveMax, uint8 v, bytes32 r, bytes32 s
    ) external returns (uint amountETH);

    function swapExactTokensForTokensSupportingFeeOnTransferTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external;
    function swapExactETHForTokensSupportingFeeOnTransferTokens(
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external payable;
    function swapExactTokensForETHSupportingFeeOnTransferTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (token/ERC1155/IERC1155Receiver.sol)

pragma solidity ^0.8.0;

import "../../utils/introspection/IERC165.sol";

/**
 * @dev _Available since v3.1._
 */
interface IERC1155Receiver is IERC165 {
    /**
     * @dev Handles the receipt of a single ERC1155 token type. This function is
     * called at the end of a `safeTransferFrom` after the balance has been updated.
     *
     * NOTE: To accept the transfer, this must return
     * `bytes4(keccak256("onERC1155Received(address,address,uint256,uint256,bytes)"))`
     * (i.e. 0xf23a6e61, or its own function selector).
     *
     * @param operator The address which initiated the transfer (i.e. msg.sender)
     * @param from The address which previously owned the token
     * @param id The ID of the token being transferred
     * @param value The amount of tokens being transferred
     * @param data Additional data with no specified format
     * @return `bytes4(keccak256("onERC1155Received(address,address,uint256,uint256,bytes)"))` if transfer is allowed
     */
    function onERC1155Received(
        address operator,
        address from,
        uint256 id,
        uint256 value,
        bytes calldata data
    ) external returns (bytes4);

    /**
     * @dev Handles the receipt of a multiple ERC1155 token types. This function
     * is called at the end of a `safeBatchTransferFrom` after the balances have
     * been updated.
     *
     * NOTE: To accept the transfer(s), this must return
     * `bytes4(keccak256("onERC1155BatchReceived(address,address,uint256[],uint256[],bytes)"))`
     * (i.e. 0xbc197c81, or its own function selector).
     *
     * @param operator The address which initiated the batch transfer (i.e. msg.sender)
     * @param from The address which previously owned the token
     * @param ids An array containing ids of each token being transferred (order and length must match values array)
     * @param values An array containing amounts of each token being transferred (order and length must match ids array)
     * @param data Additional data with no specified format
     * @return `bytes4(keccak256("onERC1155BatchReceived(address,address,uint256[],uint256[],bytes)"))` if transfer is allowed
     */
    function onERC1155BatchReceived(
        address operator,
        address from,
        uint256[] calldata ids,
        uint256[] calldata values,
        bytes calldata data
    ) external returns (bytes4);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC721/IERC721Receiver.sol)

pragma solidity ^0.8.0;

/**
 * @title ERC721 token receiver interface
 * @dev Interface for any contract that wants to support safeTransfers
 * from ERC721 asset contracts.
 */
interface IERC721Receiver {
    /**
     * @dev Whenever an {IERC721} `tokenId` token is transferred to this contract via {IERC721-safeTransferFrom}
     * by `operator` from `from`, this function is called.
     *
     * It must return its Solidity selector to confirm the token transfer.
     * If any other value is returned or the interface is not implemented by the recipient, the transfer will be reverted.
     *
     * The selector can be obtained in Solidity with `IERC721Receiver.onERC721Received.selector`.
     */
    function onERC721Received(
        address operator,
        address from,
        uint256 tokenId,
        bytes calldata data
    ) external returns (bytes4);
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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/Strings.sol)

pragma solidity ^0.8.0;

/**
 * @dev String operations.
 */
library Strings {
    bytes16 private constant _HEX_SYMBOLS = "0123456789abcdef";
    uint8 private constant _ADDRESS_LENGTH = 20;

    /**
     * @dev Converts a `uint256` to its ASCII `string` decimal representation.
     */
    function toString(uint256 value) internal pure returns (string memory) {
        // Inspired by OraclizeAPI's implementation - MIT licence
        // https://github.com/oraclize/ethereum-api/blob/b42146b063c7d6ee1358846c198246239e9360e8/oraclizeAPI_0.4.25.sol

        if (value == 0) {
            return "0";
        }
        uint256 temp = value;
        uint256 digits;
        while (temp != 0) {
            digits++;
            temp /= 10;
        }
        bytes memory buffer = new bytes(digits);
        while (value != 0) {
            digits -= 1;
            buffer[digits] = bytes1(uint8(48 + uint256(value % 10)));
            value /= 10;
        }
        return string(buffer);
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation.
     */
    function toHexString(uint256 value) internal pure returns (string memory) {
        if (value == 0) {
            return "0x00";
        }
        uint256 temp = value;
        uint256 length = 0;
        while (temp != 0) {
            length++;
            temp >>= 8;
        }
        return toHexString(value, length);
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation with fixed length.
     */
    function toHexString(uint256 value, uint256 length) internal pure returns (string memory) {
        bytes memory buffer = new bytes(2 * length + 2);
        buffer[0] = "0";
        buffer[1] = "x";
        for (uint256 i = 2 * length + 1; i > 1; --i) {
            buffer[i] = _HEX_SYMBOLS[value & 0xf];
            value >>= 4;
        }
        require(value == 0, "Strings: hex length insufficient");
        return string(buffer);
    }

    /**
     * @dev Converts an `address` with fixed length of 20 bytes to its not checksummed ASCII `string` hexadecimal representation.
     */
    function toHexString(address addr) internal pure returns (string memory) {
        return toHexString(uint256(uint160(addr)), _ADDRESS_LENGTH);
    }
}

pragma solidity >=0.6.2;

interface IUniswapV2Router01 {
    function factory() external pure returns (address);
    function WETH() external pure returns (address);

    function addLiquidity(
        address tokenA,
        address tokenB,
        uint amountADesired,
        uint amountBDesired,
        uint amountAMin,
        uint amountBMin,
        address to,
        uint deadline
    ) external returns (uint amountA, uint amountB, uint liquidity);
    function addLiquidityETH(
        address token,
        uint amountTokenDesired,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    ) external payable returns (uint amountToken, uint amountETH, uint liquidity);
    function removeLiquidity(
        address tokenA,
        address tokenB,
        uint liquidity,
        uint amountAMin,
        uint amountBMin,
        address to,
        uint deadline
    ) external returns (uint amountA, uint amountB);
    function removeLiquidityETH(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    ) external returns (uint amountToken, uint amountETH);
    function removeLiquidityWithPermit(
        address tokenA,
        address tokenB,
        uint liquidity,
        uint amountAMin,
        uint amountBMin,
        address to,
        uint deadline,
        bool approveMax, uint8 v, bytes32 r, bytes32 s
    ) external returns (uint amountA, uint amountB);
    function removeLiquidityETHWithPermit(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline,
        bool approveMax, uint8 v, bytes32 r, bytes32 s
    ) external returns (uint amountToken, uint amountETH);
    function swapExactTokensForTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external returns (uint[] memory amounts);
    function swapTokensForExactTokens(
        uint amountOut,
        uint amountInMax,
        address[] calldata path,
        address to,
        uint deadline
    ) external returns (uint[] memory amounts);
    function swapExactETHForTokens(uint amountOutMin, address[] calldata path, address to, uint deadline)
        external
        payable
        returns (uint[] memory amounts);
    function swapTokensForExactETH(uint amountOut, uint amountInMax, address[] calldata path, address to, uint deadline)
        external
        returns (uint[] memory amounts);
    function swapExactTokensForETH(uint amountIn, uint amountOutMin, address[] calldata path, address to, uint deadline)
        external
        returns (uint[] memory amounts);
    function swapETHForExactTokens(uint amountOut, address[] calldata path, address to, uint deadline)
        external
        payable
        returns (uint[] memory amounts);

    function quote(uint amountA, uint reserveA, uint reserveB) external pure returns (uint amountB);
    function getAmountOut(uint amountIn, uint reserveIn, uint reserveOut) external pure returns (uint amountOut);
    function getAmountIn(uint amountOut, uint reserveIn, uint reserveOut) external pure returns (uint amountIn);
    function getAmountsOut(uint amountIn, address[] calldata path) external view returns (uint[] memory amounts);
    function getAmountsIn(uint amountOut, address[] calldata path) external view returns (uint[] memory amounts);
}