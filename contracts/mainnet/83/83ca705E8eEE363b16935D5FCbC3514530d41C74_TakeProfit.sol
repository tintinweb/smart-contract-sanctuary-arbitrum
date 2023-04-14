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
// OpenZeppelin Contracts (last updated v4.8.0) (token/ERC721/IERC721.sol)

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
     * - If the caller is not `from`, it must have been allowed to move this token by either {approve} or {setApprovalForAll}.
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
     * WARNING: Note that the caller is responsible to confirm that the recipient is capable of receiving ERC721
     * or else they may be permanently lost. Usage of {safeTransferFrom} prevents loss, though the caller must
     * understand this adds an external call which potentially creates a reentrancy vulnerability.
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

/**
 * SPDX-License-Identifier: GPL-3.0-or-later
 * DeDeLend
 * Copyright (C) 2023 DeDeLend
 *
 * This program is free software: you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation, either version 3 of the License, or
 * (at your option) any later version.
 *
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with this program.  If not, see <http://www.gnu.org/licenses/>.
 **/

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";

interface IHegicStrategy {
    /**
     * @return The address of the price provider.
     */
    function priceProvider() external view returns (address);

    /**
     * @param optionID The ID of the option.
     * @return The profit amount for the specified option.
     */
    function payOffAmount(uint256 optionID)
        external
        view
        returns (uint256);
}

interface IOperationalTreasury {
    enum LockedLiquidityState { Unlocked, Locked }

    /**
     * @param positionID The position ID to pay off.
     * @param account The address to receive the pay off.
     */
    function payOff(uint256 positionID, address account) external;

    /**
     * @param id The locked liquidity ID.
     * @return state The state of the locked liquidity.
     * @return strategy The strategy associated with the locked liquidity.
     * @return negativepnl The negative profit and loss value.
     * @return positivepnl The positive profit and loss value.
     * @return expiration The expiration time of the locked liquidity.
     */
    function lockedLiquidity(uint256 id)
        external
        view
        returns (
            LockedLiquidityState state,
            IHegicStrategy strategy,
            uint128 negativepnl,
            uint128 positivepnl,
            uint32 expiration
        );
}

/**
 * @title TakeProfit
 * @dev A contract that enables users to set and execute take-profit orders on ERC721 tokens.
 * The contract allows users to set a price target, and when the price target is met,
 * the contract automatically executes the order and sends the profit to the user.
 */
contract TakeProfit is Ownable {
    enum TakeType { GreaterThanOrEqual, LessThanOrEqual }

    // TokenInfo struct to store information related to a token for which a take-profit order is set
    struct TokenInfo {
        uint256 tokenId;
        uint256 takeProfitPrice;
        uint256 expirationTime;
        address owner;
        TakeType takeType;
        uint256 commissionPaid;
    }

    // Contract and treasury addresses, and mappings to store relevant data
    IERC721 public erc721Contract;
    IOperationalTreasury public operationalTreasury;
    mapping(uint256 => TokenInfo) public tokenIdToTokenInfo;
    uint256 public commissionSize = 0.001 * 1e18;
    uint256 public withdrawableBalance;

    uint256 private activeTakeCount;
    uint256 public maxActiveTakes = 400;
    mapping(uint256 => uint256) public indexTokenToTokenId;
    mapping(uint256 => uint256) public idTokenToIndexToken;

    // Events to emit when a take-profit order is set, deleted, updated, or executed
    event TakeProfitSet(uint256 indexed tokenId, uint256 takeProfitPrice, TakeType takeType);
    event TakeProfitDeleted(uint256 indexed tokenId);
    event TakeProfitUpdated(uint256 indexed tokenId, uint256 newTakeProfitPrice, TakeType newTakeType);
    event TakeProfitExecuted(uint256 indexed tokenId);

    // Constructor to initialize the contract with the required ERC721 contract and operational treasury addresses
    constructor(address _erc721Address, address _operationalTreasury) {
        erc721Contract = IERC721(_erc721Address);
        operationalTreasury = IOperationalTreasury(_operationalTreasury);
    }

    // Function to set the commission size
    function setCommissionSize(uint256 newCommissionSize) external onlyOwner {
        commissionSize = newCommissionSize;
    }

    // Function to set the maximum number of active takes
    function setMaxActiveTakes(uint256 newMaxActiveTakes) external onlyOwner {
        maxActiveTakes = newMaxActiveTakes;
    }

    // Function for the contract owner to withdraw the profit
    function withdrawProfit() external onlyOwner {
        uint256 contractBalance = address(this).balance;
        require(contractBalance > withdrawableBalance, "No profit available to withdraw");

        uint256 profit = contractBalance - withdrawableBalance;
        withdrawableBalance = contractBalance - profit;
        payable(owner()).transfer(profit);
    }

    // Function to get the count of active take-profit orders
    function getActiveTakeCount() external view returns (uint256) {
        return activeTakeCount;
    }

    // Function to set a take-profit order
    function setTakeProfit(
        uint256 tokenId,
        uint256 takeProfitPrice,
        TakeType takeType
    ) external payable {
        require(erc721Contract.ownerOf(tokenId) == msg.sender, "Caller must be the owner of the token");
        require(msg.value >= commissionSize, "Not enough commission sent");

        uint256 refund = msg.value - commissionSize;
        if (refund > 0) {
            payable(msg.sender).transfer(refund);
        }
        withdrawableBalance += commissionSize;

        // Add token to the active list
        activeTakeCount++;
        indexTokenToTokenId[activeTakeCount] = tokenId;
        idTokenToIndexToken[tokenId] = activeTakeCount;

        erc721Contract.transferFrom(msg.sender, address(this), tokenId);
        uint256 expirationTime = getExpirationTime(tokenId);
        tokenIdToTokenInfo[tokenId] = TokenInfo(
            tokenId,
            takeProfitPrice,
            expirationTime,
            msg.sender,
            takeType,
            commissionSize
        );

        emit TakeProfitSet(tokenId, takeProfitPrice, takeType);
    }

    // Function to delete a take-profit order
    function deleteTakeProfit(uint256 tokenId) external {
        TokenInfo memory tokenInfo = tokenIdToTokenInfo[tokenId];
        require(tokenInfo.owner == msg.sender, "Caller must be the owner of the token");
        require(tokenInfo.expirationTime > 0, "No token set for take profit");

        uint256 commissionToReturn = tokenInfo.commissionPaid;
        withdrawableBalance -= commissionToReturn;
        payable(msg.sender).transfer(commissionToReturn);

        // Remove token from the active list
        _removeTokenFromActiveList(tokenId);

        delete tokenIdToTokenInfo[tokenId];
        erc721Contract.transferFrom(address(this), msg.sender, tokenId);

        emit TakeProfitDeleted(tokenId);
    }

    // Function to update a take-profit order
    function updateTakeProfit(
        uint256 tokenId,
        uint256 newTakeProfitPrice,
        TakeType newTakeType
    ) external {
        TokenInfo storage tokenInfo = tokenIdToTokenInfo[tokenId];
        require(tokenInfo.owner == msg.sender, "Caller must be the owner of the token");

        tokenInfo.takeProfitPrice = newTakeProfitPrice;
        tokenInfo.takeType = newTakeType;

        emit TakeProfitUpdated(tokenId, newTakeProfitPrice, newTakeType);
    }

    // Function to execute a take-profit order
    function executeTakeProfit(uint256 tokenId) external {
        TokenInfo memory tokenInfo = tokenIdToTokenInfo[tokenId];
        require(checkTakeProfit(tokenId), "Take profit conditions not met");

        uint256 commissionToReturn = tokenInfo.commissionPaid;
        withdrawableBalance -= commissionToReturn;

        // Remove token from the active list
        _removeTokenFromActiveList(tokenId);

        delete tokenIdToTokenInfo[tokenId];
        payOff(tokenInfo);

        emit TakeProfitExecuted(tokenId);
    }

    // Function to check if the conditions for a take-profit order are met
    function checkTakeProfit(uint256 tokenId) public view returns (bool) {
        TokenInfo memory tokenInfo = tokenIdToTokenInfo[tokenId];
        if (tokenInfo.expirationTime == 0) {
            return false;
        }

        uint256 timeToExpiration = tokenInfo.expirationTime - block.timestamp;
        if (timeToExpiration < 30 minutes && getPayOffAmount(tokenId) > 0) {
            return true;
        }

        uint256 currentPrice = getCurrentPrice(tokenInfo.tokenId);
        bool takeProfitTriggered = false;
        if (tokenInfo.takeType == TakeType.GreaterThanOrEqual) {
            takeProfitTriggered = currentPrice >= tokenInfo.takeProfitPrice;
        } else if (tokenInfo.takeType == TakeType.LessThanOrEqual) {
            takeProfitTriggered = currentPrice <= tokenInfo.takeProfitPrice;
        }
        return takeProfitTriggered;
    }
    
    function _removeTokenFromActiveList(uint256 tokenId) private {
        uint256 indexToRemove = idTokenToIndexToken[tokenId];
        uint256 lastTokenId = indexTokenToTokenId[activeTakeCount];

        // Move the last token to the removed token's position
        indexTokenToTokenId[indexToRemove] = lastTokenId;
        idTokenToIndexToken[lastTokenId] = indexToRemove;

        // Remove the last token from the active list
        delete indexTokenToTokenId[activeTakeCount];
        delete idTokenToIndexToken[tokenId];
        activeTakeCount--;
    }

    // Private function to pay off the profit when the take-profit order is executed
    function payOff(TokenInfo memory tokenInfo) private {
        operationalTreasury.payOff(tokenInfo.tokenId, tokenInfo.owner);
        erc721Contract.transferFrom(address(this), tokenInfo.owner, tokenInfo.tokenId);
    }

    // Function to get the pay off amount for a specific token
    function getPayOffAmount(uint256 tokenId) public view returns (uint256) {
        (, IHegicStrategy strategy, , , ) = operationalTreasury.lockedLiquidity(tokenId);
        return strategy.payOffAmount(tokenId);
    } 

    // Function to get the current price of a specific token
    function getCurrentPrice(uint256 tokenId) public view returns (uint256) {
        (, IHegicStrategy strategy, , , ) = operationalTreasury.lockedLiquidity(tokenId);
        (, int256 latestPrice, , , ) = AggregatorV3Interface(strategy.priceProvider()).latestRoundData();
        return uint256(latestPrice);
    }

    // Function to get the expiration time of a specific token
    function getExpirationTime(uint256 tokenId) public view returns (uint256) {
        (, , , , uint32 expiration) = operationalTreasury.lockedLiquidity(tokenId);
        return uint256(expiration);
    }
}