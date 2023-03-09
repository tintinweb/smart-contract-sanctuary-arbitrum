// SPDX-License-Identifier: MIT
pragma solidity 0.8.18;

import { FeeDistributor } from "./utils/FeeDistributor.sol";
import { Signatures } from "./utils/Signatures.sol";
import { ITokenBuyer } from "./interfaces/ITokenBuyer.sol";
import { IUniversalRouter } from "./interfaces/external/IUniversalRouter.sol";
import { LibAddress } from "./lib/LibAddress.sol";
import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

/// @title A smart contract for buying any kind of tokens and taking a fee.
contract TokenBuyer is ITokenBuyer, FeeDistributor, Signatures {
    using LibAddress for address payable;

    address payable public immutable universalRouter;
    address public immutable permit2;

    /// @param universalRouter_ The address of Uniswap's Universal router.
    /// @param universalRouter_ The address of the Permit2 contract.
    /// @param feeCollector_ The address that will receive a fee from the funds.
    /// @param feePercentBps_ The percentage of the fee expressed in basis points (e.g 500 for a 5% cut).
    constructor(
        address payable universalRouter_,
        address permit2_,
        address payable feeCollector_,
        uint96 feePercentBps_
    ) FeeDistributor(feeCollector_, feePercentBps_) {
        universalRouter = universalRouter_;
        permit2 = permit2_;
    }

    function getAssets(
        uint256 guildId,
        PayToken calldata payToken,
        bytes calldata uniCommands,
        bytes[] calldata uniInputs
    ) external payable {
        IERC20 token = IERC20(payToken.tokenAddress);

        // Get the tokens from the user and send the fee collector's share
        if (address(token) == address(0)) feeCollector.sendEther(calculateFee(address(0), msg.value));
        else {
            if (!token.transferFrom(msg.sender, address(this), payToken.amount))
                revert TransferFailed(msg.sender, address(this));
            if (!token.transfer(feeCollector, calculateFee(address(token), payToken.amount)))
                revert TransferFailed(address(this), feeCollector);
            if (token.allowance(address(this), permit2) < payToken.amount) token.approve(permit2, type(uint256).max);
        }

        IUniversalRouter(universalRouter).execute{ value: address(this).balance }(uniCommands, uniInputs);

        // Send out any remaining tokens
        if (address(token) != address(0) && !token.transfer(msg.sender, token.balanceOf(address(this))))
            revert TransferFailed(address(this), msg.sender);

        emit TokensBought(guildId);
    }

    function sweep(address token, address payable recipient, uint256 amount) external onlyFeeCollector {
        if (!IERC20(token).transfer(recipient, amount)) revert TransferFailed(address(this), feeCollector);
        emit TokensSweeped(token, recipient, amount);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.18;

import { IFeeDistributor } from "../interfaces/IFeeDistributor.sol";

contract FeeDistributor is IFeeDistributor {
    address payable public feeCollector;
    uint96 public feePercentBps;

    mapping(address => uint256) public baseFee;

    /// @param feeCollector_ The address that will receive a fee from the funds.
    /// @param feePercentBps_ The percentage of the fee expressed in basis points (e.g 500 for a 5% cut).
    constructor(address payable feeCollector_, uint96 feePercentBps_) {
        feeCollector = feeCollector_;
        feePercentBps = feePercentBps_;
    }

    modifier onlyFeeCollector() {
        if (msg.sender != feeCollector) revert AccessDenied(msg.sender, feeCollector);
        _;
    }

    function setBaseFee(address token, uint256 newFee) external onlyFeeCollector {
        baseFee[token] = newFee;
        emit BaseFeeChanged(token, newFee);
    }

    function setFeeCollector(address payable newFeeCollector) external onlyFeeCollector {
        feeCollector = newFeeCollector;
        emit FeeCollectorChanged(newFeeCollector);
    }

    function setFeePercentBps(uint96 newShare) external onlyFeeCollector {
        feePercentBps = newShare;
        emit FeePercentBpsChanged(newShare);
    }

    /// @notice Calculate the fee from the full amount + fee
    function calculateFee(address token, uint256 amount) internal view returns (uint256 fee) {
        uint256 baseFeeAmount = baseFee[token];
        uint256 withoutBaseFee = amount - baseFeeAmount;
        return withoutBaseFee - ((withoutBaseFee / (10000 + feePercentBps)) * 10000) + baseFeeAmount;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IFeeDistributor {
    /// @notice The base fee of a swap on top of the percentual fee.
    /// @param token The token whose base fee is queried.
    /// @return baseFee The amount of the fee in wei.
    function baseFee(address token) external returns (uint256 baseFee);

    /// @notice Sets the base fee for a given token.
    /// @dev Callable only by the current fee collector.
    /// @param token The token whose base fee is set.
    /// @param newFee The new base fee in wei.
    function setBaseFee(address token, uint256 newFee) external;

    /// @notice Sets the address that receives the fee from the funds.
    /// @dev Callable only by the current fee collector.
    /// @param newFeeCollector The new address of feeCollector.
    function setFeeCollector(address payable newFeeCollector) external;

    /// @notice Sets the fee's amount from the funds.
    /// @dev Callable only by the fee collector.
    /// @param newShare The percentual value expressed in basis points.
    function setFeePercentBps(uint96 newShare) external;

    /// @notice Returns the address that receives the fee from the funds.
    function feeCollector() external view returns (address payable);

    /// @notice Returns the percentage of the fee expressed in basis points.
    function feePercentBps() external view returns (uint96);

    /// @notice Event emitted when a token's base fee is changed.
    /// @param token The address of the token whose fee was changed. 0 for ether.
    /// @param newFee The new amount of base fee in wei.
    event BaseFeeChanged(address token, uint256 newFee);

    /// @notice Event emitted when the fee collector address is changed.
    /// @param newFeeCollector The new address of feeCollector.
    event FeeCollectorChanged(address newFeeCollector);

    /// @notice Event emitted when the share of the fee collector changes.
    /// @param newShare The new value of feePercentBps.
    event FeePercentBpsChanged(uint96 newShare);

    /// @notice Error thrown when a function is attempted to be called by the wrong address.
    /// @param sender The address that sent the transaction.
    /// @param owner The address that is allowed to call the function.
    error AccessDenied(address sender, address owner);
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.18;

import { ITokenBuyer } from "../interfaces/ITokenBuyer.sol";

contract Signatures {
    // bytes4(keccak256("isValidSignature(bytes32,bytes)")
    bytes4 internal constant MAGICVALUE = 0x1626ba7e;

    /// @notice Accepts signatures from permit2, rejects otherwise.
    /// @param hash Hash of the data to be signed.
    /// @param signature Signature byte array associated with hash.
    /// @return magicValue The function selector if the function passes.
    function isValidSignature(bytes32 hash, bytes memory signature) public view returns (bytes4 magicValue) {
        if (msg.sender == ITokenBuyer(address(this)).permit2()) return MAGICVALUE;

        hash;
        signature;
        return bytes4(0);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import { IFeeDistributor } from "./IFeeDistributor.sol";
import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

/// @title A smart contract for buying any kind of tokens and taking a fee.
interface ITokenBuyer is IFeeDistributor {
    /// @notice A token address-amount pair.
    struct PayToken {
        address tokenAddress;
        uint256 amount;
    }

    /// @notice Executes token swaps and takes a fee.
    /// @param guildId The id of the guild where the payment was made. Used only for analytics.
    /// @param payToken The address and the amount of the token that's used for paying. 0 for ether.
    /// @param uniCommands A set of concatenated commands, each 1 byte in length.
    /// @param uniInputs An array of byte strings containing abi encoded inputs for each command.
    function getAssets(
        uint256 guildId,
        PayToken calldata payToken,
        bytes calldata uniCommands,
        bytes[] calldata uniInputs
    ) external payable;

    /// @notice Allows the feeCollector to withdraw any tokens stuck in the contract. Used to rescue funds.
    /// @param token The address of the token to sweep. 0 for ether.
    /// @param recipient The recipient of the tokens.
    /// @param amount The amount of the tokens to sweep.
    function sweep(address token, address payable recipient, uint256 amount) external;

    /// @notice Returns the address of Uniswap's Universal Router.
    function universalRouter() external view returns (address payable);

    /// @notice Returns the address the Permit2 contract.
    function permit2() external view returns (address);

    /// @notice Event emitted when a call to {getAssets} succeeds.
    /// @param guildId The id of the guild where the payment was made. Used only for analytics.
    event TokensBought(uint256 guildId);

    /// @notice Event emitted when tokens are sweeped from the contract.
    /// @dev Callable only by the current fee collector.
    /// @param token The address of the token sweeped. 0 for ether.
    /// @param recipient The recipient of the tokens.
    /// @param amount The amount of the tokens sweeped.
    event TokensSweeped(address token, address payable recipient, uint256 amount);

    /// @notice Error thrown when an ERC20 transfer failed.
    /// @param from The sender of the token.
    /// @param to The recipient of the token.
    error TransferFailed(address from, address to);
}

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.17;

import { IERC721Receiver } from "@openzeppelin/contracts/token/ERC721/IERC721Receiver.sol";
import { IERC1155Receiver } from "@openzeppelin/contracts/token/ERC1155/IERC1155Receiver.sol";
import { IRewardsCollector } from "./IRewardsCollector.sol";

interface IUniversalRouter is IRewardsCollector, IERC721Receiver, IERC1155Receiver {
    /// @notice Thrown when a required command has failed
    error ExecutionFailed(uint256 commandIndex, bytes message);

    /// @notice Thrown when attempting to send ETH directly to the contract
    error ETHNotAccepted();

    /// @notice Thrown executing commands with an expired deadline
    error TransactionDeadlinePassed();

    /// @notice Thrown executing commands with an expired deadline
    error LengthMismatch();

    /// @notice Executes encoded commands along with provided inputs. Reverts if deadline has expired.
    /// @param commands A set of concatenated commands, each 1 byte in length
    /// @param inputs An array of byte strings containing abi encoded inputs for each command
    /// @param deadline The deadline by which the transaction must be executed
    function execute(bytes calldata commands, bytes[] calldata inputs, uint256 deadline) external payable;

    /// @notice Executes encoded commands along with provided inputs.
    /// @param commands A set of concatenated commands, each 1 byte in length
    /// @param inputs An array of byte strings containing abi encoded inputs for each command
    function execute(bytes calldata commands, bytes[] calldata inputs) external payable;
}

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.15;

import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

/// @title LooksRare Rewards Collector
/// @notice Implements a permissionless call to fetch LooksRare rewards earned by Universal Router users
/// and transfers them to an external rewards distributor contract
interface IRewardsCollector {
    /// @notice Fetches users' LooksRare rewards and sends them to the distributor contract
    /// @param looksRareClaim The data required by LooksRare to claim reward tokens
    function collectRewards(bytes calldata looksRareClaim) external;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/// @title Library for functions related to addresses.
library LibAddress {
    /// @notice Error thrown when sending ether fails.
    /// @param recipient The address that could not receive the ether.
    error FailedToSendEther(address recipient);

    /// @notice Send ether to an address, forwarding all available gas and reverting on errors.
    /// @param recipient The recipient of the ether.
    /// @param amount The amount of ether to send in wei.
    function sendEther(address payable recipient, uint256 amount) internal {
        // solhint-disable-next-line avoid-low-level-calls
        (bool success, ) = recipient.call{ value: amount }("");
        if (!success) revert FailedToSendEther(recipient);
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