// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v5.0.0) (token/ERC1155/IERC1155Receiver.sol)

pragma solidity ^0.8.20;

import {IERC165} from "../../utils/introspection/IERC165.sol";

/**
 * @dev Interface that must be implemented by smart contracts in order to receive
 * ERC-1155 token transfers.
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
// OpenZeppelin Contracts (last updated v5.0.0) (token/ERC721/IERC721Receiver.sol)

pragma solidity ^0.8.20;

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
     * If any other value is returned or the interface is not implemented by the recipient, the transfer will be
     * reverted.
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
// OpenZeppelin Contracts (last updated v5.0.0) (utils/introspection/IERC165.sol)

pragma solidity ^0.8.20;

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

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity >=0.6.0;

import '@openzeppelin/contracts/token/ERC20/IERC20.sol';

library TransferHelper {
    /// @notice Transfers tokens from the targeted address to the given destination
    /// @notice Errors with 'STF' if transfer fails
    /// @param token The contract address of the token to be transferred
    /// @param from The originating address from which the tokens will be transferred
    /// @param to The destination address of the transfer
    /// @param value The amount to be transferred
    function safeTransferFrom(
        address token,
        address from,
        address to,
        uint256 value
    ) internal {
        (bool success, bytes memory data) =
            token.call(abi.encodeWithSelector(IERC20.transferFrom.selector, from, to, value));
        require(success && (data.length == 0 || abi.decode(data, (bool))), 'STF');
    }

    /// @notice Transfers tokens from msg.sender to a recipient
    /// @dev Errors with ST if transfer fails
    /// @param token The contract address of the token which will be transferred
    /// @param to The recipient of the transfer
    /// @param value The value of the transfer
    function safeTransfer(
        address token,
        address to,
        uint256 value
    ) internal {
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(IERC20.transfer.selector, to, value));
        require(success && (data.length == 0 || abi.decode(data, (bool))), 'ST');
    }

    /// @notice Approves the stipulated contract to spend the given allowance in the given token
    /// @dev Errors with 'SA' if transfer fails
    /// @param token The contract address of the token to be approved
    /// @param to The target of the approval
    /// @param value The amount of the given token the target will be allowed to spend
    function safeApprove(
        address token,
        address to,
        uint256 value
    ) internal {
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(IERC20.approve.selector, to, value));
        require(success && (data.length == 0 || abi.decode(data, (bool))), 'SA');
    }

    /// @notice Transfers ETH to the recipient address
    /// @dev Fails with `STE`
    /// @param to The destination of the transfer
    /// @param value The value to be transferred
    function safeTransferETH(address to, uint256 value) internal {
        (bool success, ) = to.call{value: value}(new bytes(0));
        require(success, 'STE');
    }
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.5.17 <0.9.0;

interface IMintableERC20 {
  function mint(address account, uint256 amount) external returns (bool);

  function transfer(address recipient, uint256 amount) external returns (bool);

  function totalSupply() external view returns (uint256);

  function balanceOf(address account) external view returns (uint256);

  function approve(address spender, uint256 amount) external returns (bool);

  function decimals() external view returns (uint8);
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.5.17 <0.9.0;

interface IPermit2 {
  function approve(
    address token,
    address spender,
    uint160 amount,
    uint48 expiration
  ) external;
}

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.17;

import {IERC721Receiver} from "@openzeppelin/contracts/token/ERC721/IERC721Receiver.sol";
import {IERC1155Receiver} from "@openzeppelin/contracts/token/ERC1155/IERC1155Receiver.sol";

interface IUniversalRouter is IERC721Receiver, IERC1155Receiver {
  /// @notice Thrown when a required command has failed
  error ExecutionFailed(uint256 commandIndex, bytes message);

  /// @notice Thrown when attempting to send ETH directly to the contract
  error ETHNotAccepted();

  /// @notice Thrown when executing commands with an expired deadline
  error TransactionDeadlinePassed();

  /// @notice Thrown when attempting to execute commands and an incorrect number of inputs are provided
  error LengthMismatch();

  /// @notice Executes encoded commands along with provided inputs.
  /// @param commands A set of concatenated commands, each 1 byte in length
  /// @param inputs An array of byte strings containing abi encoded inputs for each command
  function execute(
    bytes calldata commands,
    bytes[] calldata inputs
  ) external payable;

  /// @notice Executes encoded commands along with provided inputs. Reverts if deadline has expired.
  /// @param commands A set of concatenated commands, each 1 byte in length
  /// @param inputs An array of byte strings containing abi encoded inputs for each command
  /// @param deadline The deadline by which the transaction must be executed
  function execute(
    bytes calldata commands,
    bytes[] calldata inputs,
    uint256 deadline
  ) external payable;
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.24;

import "./interfaces/IUniversalRouter.sol";
import "@uniswap/v3-periphery/contracts/libraries/TransferHelper.sol";
import "./interfaces/IMintableERC20.sol";
import "./interfaces/IPermit2.sol";

// events
event UDTSwapSuccess(uint amountSwapped, uint amountReceived);

// errors
error UDTSwapFailed(address tokenIn, uint amount);

error UnauthorizedSwap();

error UnsafeCast();

contract SwapArbForUdt {
    address public arb = 0x912CE59144191C1204E64559FE8253a0e49E6548;
    address public udt = 0xd5d3aA404D7562d09a848F96a8a8d5D65977bF90;
    address public weth = 0x82aF49447D8a07e3bd95BD0d56f35241523fBab1;
    address public dao = 0x28ffDfB0A6e6E06E95B3A1f928Dc4024240bD87c;
    address public uniswapUniversalRouter =
        0x4C60051384bd2d3C01bfc845Cf5F4b44bcbE9de5;
    address public permit2 = 0x000000000022D473030F116dDEE9F6B43aC78BA3;

    // specified in https://docs.uniswap.org/contracts/universal-router/technical-reference#v3_swap_exact_in
    uint256 constant V3_SWAP_EXACT_IN = 0x00;

    constructor() {
        uint160 maxAmount = 2 ** 160 - 1;
        // approve PERMIT2 to manipulate the token
        IMintableERC20(arb).approve(permit2, maxAmount);

        // issue PERMIT2 Allowance
        IPermit2(permit2).approve(
            arb,
            uniswapUniversalRouter,
            uint160(maxAmount),
            uint48(block.timestamp + 60 * 60 * 24 * 365 * 100) // expires after 100 years
        );
    }

    function swap() public payable returns (uint amount) {
        // get total balance of token to swap
        uint tokenAmount = IMintableERC20(arb).balanceOf(address(this));

        // Approve the router to spend src ERC20
        TransferHelper.safeApprove(arb, uniswapUniversalRouter, tokenAmount);

        // Going thru WETH
        bytes memory defaultPath = abi.encodePacked(
            weth,
            uint24(3000), // default UDT pool fee is set to 0.3%
            udt
        );

        // encode parameters for the swap om UniversalRouter
        bytes memory commands = abi.encodePacked(
            bytes1(uint8(V3_SWAP_EXACT_IN))
        );
        bytes[] memory inputs = new bytes[](1);
        inputs[0] = abi.encode(
            address(this), // recipient
            tokenAmount, // amountIn
            0, // amountOutMinimum
            abi.encodePacked(arb, uint24(500), defaultPath), // path
            true // funds are not coming from PERMIT2
        );

        IUniversalRouter(uniswapUniversalRouter).execute(
            commands,
            inputs,
            block.timestamp + 60 // expires after 1min
        );

        uint amountUDTOut = IMintableERC20(udt).balanceOf(address(this));
        if (amountUDTOut == 0) {
            revert UDTSwapFailed(uniswapUniversalRouter, tokenAmount);
        }

        bool success = IMintableERC20(udt).transfer(dao, amountUDTOut);
        if (success == false) {
            revert UDTSwapFailed(uniswapUniversalRouter, tokenAmount);
        } else {
            emit UDTSwapSuccess(tokenAmount, amountUDTOut);
        }

        return amountUDTOut;
    }
}