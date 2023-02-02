/**
 *Submitted for verification at Arbiscan on 2023-02-02
*/

// File: @openzeppelin/contracts/token/ERC721/IERC721Receiver.sol


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

// File: @openzeppelin/contracts/utils/introspection/IERC165.sol


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

// File: @openzeppelin/contracts/token/ERC721/IERC721.sol


// OpenZeppelin Contracts (last updated v4.8.0) (token/ERC721/IERC721.sol)

pragma solidity ^0.8.0;


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

// File: @openzeppelin/contracts/token/ERC20/IERC20.sol


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

// File: contracts/raffle.sol

//SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity ^0.8.0;

// ============ Imports ============




 interface IRandomizer {
    function request(uint256 callbackGasLimit) external returns (uint128);
    function clientWithdrawTo(address to, uint256 amount) external;
} 

contract Arbflle is IERC721Receiver {


  // ============ Immutable storage ============
  //randomizer address
   IRandomizer private randomizer;
  // NFT owner
  address public immutable owner;
  // Price (in Ether) per raffle slot
  uint256 public immutable slotPrice;
  // Number of total available raffle slots
  uint256 public immutable numSlotsAvailable;
  // Address of NFT contract
  address public immutable nftContract;
  // NFT ID
  uint256 public immutable nftID;

  //Raffle start date
  uint256 public raffleStartDate;
  //Raffle End date
  uint256 public raffleEndDate;
  //address of the raffle winner
  address public raffleWinner;
  // ============ Mutable storage ============

  // Result of randomizing
  uint256 public randomResult = 0;
  // Toggled when contract requests random result
  bool public randomResultRequested = false;
  // Number of filled raffle slots
  uint256 public numSlotsFilled = 0;
  // Array of slot owners
  address[] public slotOwners;
  // Mapping of slot owners to number of slots owned
  mapping(address => uint256) public addressToSlotsOwned;
  // Toggled when contract holds NFT to raffle
  bool public nftOwned = false;

  //================== Structures ==================
  struct Details{
    address owner;
    address nftContract;
    uint256 nftID;
    uint256 slotPrice;
    uint256 numSlotsAvailable;
    uint256 raffleStartDate;
    uint256 raffleEndDate;
    address[] slotOwners;
    bool raffleActive;
    address raffleWinner;
  }

  // ============ Events ============

  // Address of slot claimee and number of slots claimed
  event SlotsClaimed(address indexed claimee, uint256 numClaimed);
  //Requested for random number
  event Roll(address gamee, uint256 id);
  // Address of slot refunder and number of slots refunded
  event SlotsRefunded(address indexed refunder, uint256 numRefunded);
  // Address of raffle winner
  event RaffleWon(address indexed winner);
  //received nft
  event NftReceived(address operator,address from,uint256 tokenId);

  // ============ Constructor ============

  constructor(
    address _owner,
    address _nftContract,
    uint256 _nftID,
    uint256 _slotPrice, 
    uint256 _numSlotsAvailable,
    address _randomizer,
    uint256 _raffleStartDate,
    uint256 _raffleEndDate

  )  {
    owner = _owner;
    nftContract = _nftContract;
    nftID = _nftID;
    slotPrice = _slotPrice;
    numSlotsAvailable = _numSlotsAvailable;
    randomizer = IRandomizer(_randomizer);
    raffleStartDate = _raffleStartDate;
    raffleEndDate = _raffleEndDate;
  }

  // ============ Functions ============

  /**
   * Enables purchasing _numSlots slots in the raffle
   */
  function purchaseSlot(uint256 _numSlots,uint256 currentTime) payable external {
    //Require that raffle date is still valid
    require(currentTime < raffleEndDate,"Raffle has ended.");
    // Require purchasing at least 1 slot
    require(_numSlots > 0, " Cannot purchase 0 slots.");
    // Require the raffle contract to own the NFT to raffle
    require(nftOwned == true, " Contract does not own raffleable NFT.");
    // Require there to be available raffle slots
    require(numSlotsFilled < numSlotsAvailable, " All raffle slots are filled.");
    // Prevent claiming after winner selection
    require(randomResultRequested == false, " Cannot purchase slot after winner has been chosen.");
    // Require appropriate payment for number of slots to purchase
    require(msg.value == _numSlots * slotPrice, " Insufficient ETH provided to purchase slots.");
    // Require number of slots to purchase to be <= number of available slots
    require(_numSlots <= numSlotsAvailable - numSlotsFilled, " Requesting to purchase too many slots.");

    // For each _numSlots
    for (uint256 i = 0; i < _numSlots; i++) {
      // Add address to slot owners array
      slotOwners.push(msg.sender);
    }

    // Increment filled slots
    numSlotsFilled = numSlotsFilled + _numSlots;
    // Increment slots owned by address
    addressToSlotsOwned[msg.sender] = addressToSlotsOwned[msg.sender] + _numSlots;

    // Emit claim event
    emit SlotsClaimed(msg.sender, _numSlots);
  }
  
  /*** 
  function estimateGasFee(address _randomizer) public {
        
    }
  **/
  /**
   * Deletes raffle slots and decrements filled slots
   * @dev gas optimization: could force one-tx-per-slot-deletion to prevent iteration
   */
  function refundSlot(uint256 _numSlots) external {
    // Require the raffle contract to own the NFT to raffle
    require(nftOwned == true, " Contract does not own raffleable NFT.");
    // Prevent refunding after winner selection
    require(randomResultRequested == false, " Cannot refund slot after winner has been chosen.");
    // Require number of slots owned by address to be >= _numSlots requested for refund
    require(addressToSlotsOwned[msg.sender] >= _numSlots, " Address does not own number of requested slots.");

    // Delete slots
    uint256 idx = 0;
    uint256 numToDelete = _numSlots;
    // Loop through all entries while numToDelete still exist
    while (idx < slotOwners.length && numToDelete > 0) {
      // If address is not a match
      if (slotOwners[idx] != msg.sender) {
        // Only increment for non-matches. In case of match keep same to check against last idx item
        idx++;
      } else {
        // Swap and pop
        slotOwners[idx] = slotOwners[slotOwners.length - 1];
        slotOwners.pop();
        // Decrement num to delete
        numToDelete--;
      }
    }

    // Repay raffle participant
    payable(msg.sender).transfer(_numSlots * slotPrice);
    // Decrement filled slots
    numSlotsFilled = numSlotsFilled - _numSlots;
    // Decrement slots owned by address
    addressToSlotsOwned[msg.sender] = addressToSlotsOwned[msg.sender] - _numSlots;

    // Emit refund event
    emit SlotsRefunded(msg.sender, _numSlots);
  }
  /********************Need to make payable and check if msg.sender sends sufficient fees******************************************/
  /**
   * Collects randomness to propose a winner.
   */
  function collectRandomWinner(address _randomizer) external {
    //Require randomizer ai gas fee 
    //require(msg.value >= feeEstimate);
    // Require at least 1 raffle slot to be filled
    require(numSlotsFilled > 0, " No slots are filled");
    // Require NFT to be owned by raffle contract
    require(nftOwned == true, " Contract does not own raffleable NFT.");
    // Require caller to be raffle deployer
    require(msg.sender == owner, " Only owner can call winner collection.");
    // Require this to be the first time that randomness is requested
    require(randomResultRequested == false, " Cannot collect winner twice.");
    
    // Toggle randomness requested
    randomResultRequested = true;

    //Request a random number from the randomizer contract (50k callback limit) store random number as randomResult
     uint256 id = IRandomizer(_randomizer).request(20000);
     emit Roll(msg.sender, id);
  }

  // Callback function called by the randomizer contract when the random value is generated
  function randomizerCallback(uint128 _id, bytes32 _value) external {
    //Callback can only be called by randomizer
		require(msg.sender == address(randomizer), "Caller not Randomizer");
     randomResult = uint256(_value) % 99;
  }

  function randomizerWithdraw(address _randomizer, uint256 amount) external {
      require(msg.sender == owner);
      IRandomizer(_randomizer).clientWithdrawTo(msg.sender, amount);
  }

  

  /**
   * Disburses NFT to winner and raised raffle pool to owner
   */
  function disburseWinner() external {
    // Require to be owner, check other implementations
    // Require that the contract holds the NFT
    require(nftOwned == true, " Cannot disurbse NFT to winner without holding NFT.");
    // Require that a winner has been collected already
    require(randomResultRequested == true, " Cannot disburse to winner without having collected one.");
    // Require that the random result is not 0
    require(randomResult != 0, " Please wait for Chainlink VRF to update the winner first.");

    // Transfer raised raffle pool to owner
    payable(owner).transfer(address(this).balance);

    // Find winner of NFT
    address winner = slotOwners[randomResult % numSlotsFilled];

    //set raffle winner
    raffleWinner = winner;

    // Transfer NFT to winner
    IERC721(nftContract).safeTransferFrom(address(this), winner, nftID);

    // Toggle nftOwned
    nftOwned = false;

    // Emit raffle winner
    emit RaffleWon(winner);
  }

  /**
   * Deletes raffle, assuming that contract owns NFT and a winner has not been selected
   */
  function deleteRaffle() external {
    // Require being owner to delete raffle
    require(msg.sender == owner, " Only owner can delete raffle.");
    // Require that the contract holds the NFT
    require(nftOwned == true, "Cannot cancel raffle without raffleable NFT.");
    // Require that a winner has not been collected already
    require(randomResultRequested == false, " Cannot delete raffle after collecting winner.");

    // Transfer NFT to original owner
    IERC721(nftContract).safeTransferFrom(address(this), msg.sender, nftID);
  
    // Toggle nftOwned
    nftOwned = false;

    // For each slot owner
    for (uint256 i = numSlotsFilled - 1; i >= 0; i--) {
      // Refund slot owner
      payable(slotOwners[i]).transfer(slotPrice);

      // Pop address from slot owners array
      slotOwners.pop();
    }
  }

  /**
   * Receive NFT to raffle
   */
  function onERC721Received(
    address operator,
    address from, 
    uint256 tokenId,
    bytes calldata data
  ) external override returns (bytes4) {
    // Require NFT from owner
    require(msg.sender == nftContract, " Raffle not initiated with this NFT contract.");
    // Require correct NFT ID
    require(tokenId == nftID, " Raffle not initiated with this NFT ID.");
    // Toggle contract NFT ownership
    nftOwned = true;

    //emit nft received event
    emit NftReceived(operator,from,tokenId);

    // Return required successful interface bytes
    return this.onERC721Received.selector;
  }
    /**
    * @dev Raffle Timing function
    */   

    function isRaffleEnded(uint256 currentTime) public view returns(bool){
        return currentTime > raffleEndDate;
    }
    
    //get raffle current details
    function currentState(uint256 currentTime) public view returns(Details memory){
      bool isActive = currentTime < raffleEndDate;
      Details memory currentDetails = Details(
        owner,
        nftContract,
        nftID,
        slotPrice,
        numSlotsAvailable,
        raffleStartDate,
        raffleEndDate,
        slotOwners,
        isActive,
        raffleWinner

      );
      return currentDetails;
    }
}