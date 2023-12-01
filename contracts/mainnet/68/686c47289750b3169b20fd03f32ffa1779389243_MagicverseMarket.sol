/**
 *Submitted for verification at Arbiscan.io on 2023-11-28
*/

// SPDX-License-Identifier: MIT

/*

███╗░░░███╗░█████╗░░██████╗░██╗░█████╗░██╗░░░██╗███████╗██████╗░░██████╗███████╗
████╗░████║██╔══██╗██╔════╝░██║██╔══██╗██║░░░██║██╔════╝██╔══██╗██╔════╝██╔════╝
██╔████╔██║███████║██║░░██╗░██║██║░░╚═╝╚██╗░██╔╝█████╗░░██████╔╝╚█████╗░█████╗░░
██║╚██╔╝██║██╔══██║██║░░╚██╗██║██║░░██╗░╚████╔╝░██╔══╝░░██╔══██╗░╚═══██╗██╔══╝░░
██║░╚═╝░██║██║░░██║╚██████╔╝██║╚█████╔╝░░╚██╔╝░░███████╗██║░░██║██████╔╝███████╗
╚═╝░░░░░╚═╝╚═╝░░╚═╝░╚═════╝░╚═╝░╚════╝░░░░╚═╝░░░╚══════╝╚═╝░░╚═╝╚═════╝░╚══════╝

*/

pragma solidity ^0.8.18;

/**
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accesssed in such a direct
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

/**
 * @title Counters
 * @author Matt Condon (@shrugs)
 * @dev Provides counters that can only be incremented, decremented or reset. This can be used e.g. to track the number
 * of elements in a mapping, issuing ERC721 ids, or counting request ids.
 *
 * Include with `using Counters for Counters.Counter;`
 */
library Counters {
    struct Counter {
        // This variable should never be directly accessed by users of the library: interactions must be restricted to
        // the library's function. As of Solidity v0.5.2, this cannot be enforced, though there is a proposal to add
        // this feature: see https://github.com/ethereum/solidity/issues/4637
        uint256 _value; // default: 0
    }

    function current(Counter storage counter) internal view returns (uint256) {
        return counter._value;
    }

    function increment(Counter storage counter) internal {
        unchecked {
            counter._value += 1;
        }
    }

    function decrement(Counter storage counter) internal {
        uint256 value = counter._value;
        require(value > 0, "Counter: decrement overflow");
        unchecked {
            counter._value = value - 1;
        }
    }

    function reset(Counter storage counter) internal {
        counter._value = 0;
    }
}

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


contract MagicverseMarket is ReentrancyGuard, Ownable {
    using Counters for Counters.Counter;
    Counters.Counter private _itemIds;
    mapping(uint=>address) private AcceptedNFTContracts;
    uint private AcceptedContracts = 2;
    address public MagicFarm;
    address public Team;
    uint256 public MagicFarmPercentage = 400;
    uint256 public TeamPercentage = 200;
    uint256[] public IdsUnsold;
    uint256[] public ItemsSold;
     constructor(address _MAContract,address _EPhoenexes,address _MagicFarm, address _Team) {
         AcceptedNFTContracts[0] = _MAContract;
         AcceptedNFTContracts[1] = _EPhoenexes;
         MagicFarm = _MagicFarm;
         Team = _Team;
     }
     
     struct MarketItem {
         uint itemId;
         address nftContract;
         uint256 tokenId;
         uint amount;
         address payable seller;
         address payable owner;
         uint256 price;
         bool finished;
         uint256 indexOfUnsold;
         uint256 TimeofPurchase;
     }
     
     mapping(uint256 => MarketItem) private idToMarketItem;
     
     event MarketItemCreated (
        uint indexed itemId,
        address indexed nftContract,
        uint256 indexed tokenId,
        uint amount,
        address seller,
        address owner,
        uint256 price,
        bool finished,
        uint256 indexOfUnsold
     );
     
     event MarketItemSold (
         uint indexed itemId,
         address owner
         );

     event MarketItemUnlisted (
         uint indexed itemId,
         address owner
         );
    
   
    
    function createMarketItem(
        address nftContract,
        uint256 tokenId,
        uint amount,
        uint256 price
        ) public payable nonReentrant {
           
            bool isAccepted = false;

             for (uint i=0; i<AcceptedContracts; i++){
               if (AcceptedNFTContracts[i] == nftContract) {
                   isAccepted = true;
               }
            }
            require(isAccepted, "Not Accepted NFT Contract");
            require(price > 0, "Price must be greater than 0");
            
            _itemIds.increment();
            uint256 itemId = _itemIds.current();
            uint256 indexOfUnsold = IdsUnsold.length;
            idToMarketItem[itemId] =  MarketItem(
                itemId,
                nftContract,
                tokenId,
                amount,
                payable(msg.sender),
                payable(address(0)),
                price,
                false,
                indexOfUnsold,
                0
            );

            IdsUnsold.push(itemId);

            IERC1155(nftContract).safeTransferFrom(msg.sender, address(this), tokenId, amount, '');
                
            emit MarketItemCreated(
                itemId,
                nftContract,
                tokenId,
                amount,
                msg.sender,
                address(0),
                price,
                false,
                indexOfUnsold
            );
        }

    function onERC1155Received(
        address operator,
        address from,
        uint256 id,
        uint256 value,
        bytes calldata data
    ) external returns (bytes4) {
        return bytes4(keccak256("onERC1155Received(address,address,uint256,uint256,bytes)"));
    }

    function createMarketSale(
        address nftContract,
        uint256 itemId
        ) public payable nonReentrant {
            uint price = idToMarketItem[itemId].price;
            uint tokenId = idToMarketItem[itemId].tokenId;
            uint amount = idToMarketItem[itemId].amount;
            bool finished = idToMarketItem[itemId].finished;
            address seller = idToMarketItem[itemId].seller;
            require(msg.value == price, "Please submit the asking price in order to complete the purchase");
            require(finished != true, "This Sale has alredy finnished");
            emit MarketItemSold(
                itemId,
                msg.sender
                );
            uint256 CROforMagicFarm = msg.value*MagicFarmPercentage/10000;
            uint256 CROforTeam = msg.value*TeamPercentage/10000;
            uint256 CROforSeller = msg.value-CROforMagicFarm-CROforTeam;
            payable(seller).transfer(CROforSeller);
            payable(MagicFarm).transfer(CROforMagicFarm);
            payable(Team).transfer(CROforTeam);
            IERC1155(nftContract).safeTransferFrom(address(this), msg.sender, tokenId, amount, "");
            idToMarketItem[itemId].owner = payable(msg.sender);

            idToMarketItem[itemId].finished = true;
            idToMarketItem[itemId].TimeofPurchase = block.timestamp;
            
            uint256 indexInMarket = idToMarketItem[itemId].indexOfUnsold;
            
            idToMarketItem[IdsUnsold[IdsUnsold.length-1]].indexOfUnsold = indexInMarket;
            IdsUnsold[indexInMarket] = IdsUnsold[IdsUnsold.length-1];
            IdsUnsold.pop();
            
            ItemsSold.push(itemId);
        }
        
    function unlistMarketItem(
        address nftContract,
        uint256 itemId
        ) public  nonReentrant {
            uint tokenId = idToMarketItem[itemId].tokenId;
            uint amount = idToMarketItem[itemId].amount;
            bool finished = idToMarketItem[itemId].finished;
            address seller = idToMarketItem[itemId].seller;
            require(msg.sender == seller, "Not the Owner");
            require(finished != true, "This Sale has alredy finnished");
             emit MarketItemUnlisted(
                itemId,
                msg.sender
                );
            IERC1155(nftContract).safeTransferFrom(address(this), msg.sender, tokenId, amount, "");
            idToMarketItem[itemId].owner = payable(msg.sender);
            
            idToMarketItem[itemId].finished = true;
            
            uint256 indexInMarket = idToMarketItem[itemId].indexOfUnsold;
            idToMarketItem[IdsUnsold[IdsUnsold.length-1]].indexOfUnsold = indexInMarket;
            IdsUnsold[indexInMarket] = IdsUnsold[IdsUnsold.length-1];
            IdsUnsold.pop();
            

        }

    function fetchMarketItems(uint cursor) public view returns (MarketItem[] memory) {
        uint start_point = cursor*400;
        uint end_point;
        IdsUnsold.length < start_point + 400 ? end_point = IdsUnsold.length : end_point = start_point + 400;
        uint MarketItems = end_point - start_point ;
        MarketItem[] memory items = new MarketItem[](MarketItems);
        uint currentindex;
        for (uint i = start_point; i < end_point; i++) {
         uint256 itemId =  IdsUnsold[i];
         MarketItem storage currentItem = idToMarketItem[itemId];
         items[currentindex] = currentItem;
        currentindex += 1;
        }
        return items;
    }
     
     
    function fetchSoldItems(uint cursor) public view returns (MarketItem[] memory) {
        uint start_point = cursor*400;
        uint end_point;
        ItemsSold.length < start_point + 400 ? end_point = ItemsSold.length : end_point = start_point + 400;
        uint SoldItems = end_point - start_point ;
        MarketItem[] memory items = new MarketItem[](SoldItems);
        uint currentindex;
        for (uint i = start_point; i < end_point; i++) {
         uint256 itemId =  ItemsSold[i];
         MarketItem storage currentItem = idToMarketItem[itemId];
         items[currentindex] = currentItem;
        currentindex += 1;
        }
        return items;
    }
     
     function TotalItemsonMarket () public view returns(uint256){
       return IdsUnsold.length;
     }
     
     function TotalItemsSold () public view returns(uint256){
       return ItemsSold.length;
     }

     function AddNFTContracts(address _NFTcontract) external onlyOwner{
       uint index = AcceptedContracts;
       AcceptedNFTContracts[index] = _NFTcontract;
       AcceptedContracts ++;
     } 
     
      function ChangeFees(uint256 _MagicFarmFee, uint256 _TeamFee) external onlyOwner{
          MagicFarmPercentage = _MagicFarmFee;
          TeamPercentage = _TeamFee;
      }

      function ChangeMagicFarm(address _MagicFarm) external onlyOwner {
         MagicFarm = _MagicFarm;
     }

     function ChangeTeamAddress(address _Team) external onlyOwner {
         Team = _Team;
     }
}