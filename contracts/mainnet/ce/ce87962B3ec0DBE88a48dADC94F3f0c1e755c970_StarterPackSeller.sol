// SPDX-License-Identifier: MIT
pragma solidity >=0.8.7 <0.9.0;

/*
  _______                   ____  _____  
 |__   __|                 |___ \|  __ \ 
    | | ___  __ _ _ __ ___   __) | |  | |
    | |/ _ \/ _` | '_ ` _ \ |__ <| |  | |
    | |  __/ (_| | | | | | |___) | |__| |
    |_|\___|\__,_|_| |_| |_|____/|_____/ 

    https://team3d.io
    https://discord.gg/team3d
    Starter Pack Seller for Inventory System

    @author Team3d.R&D
*/

import "./UniswapV3Integration.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "../IInventory.sol";
import "@chainlink/contracts/src/v0.8/VRFConsumerBaseV2.sol";
import "@chainlink/contracts/src/v0.8/interfaces/VRFCoordinatorV2Interface.sol";
import "@chainlink/contracts/src/v0.8/interfaces/LinkTokenInterface.sol";

contract StarterPackSeller is ReentrancyGuard, Ownable, VRFConsumerBaseV2, UniswapV3Integration {
    event CostUpdate(uint256 cost);
    event NftUpdate(address indexed NFT);
    event Success(bool success, address location);
    event TemplateAdded(uint256 templateId);
    event ChangeSubscriptionId(uint64 indexed newId);

    uint256 public packCost = 0.005 ether;
    address public nft;
    address public splitter = 0xac49fE36C3519030B8Bd9677471219baF19d9466;
    address public vault;
    uint256 public split;
    uint256 public referralSplit;
    uint256 public vaultSplit;
    uint256 public linkCut;
    uint256 public totalSplit;
    address constant primaryToken = 0x3d48ae69a2F35D02d6F0c5E84CFE66bE885f3963;
    bytes transferData;

    LinkTokenInterface linkToken = LinkTokenInterface(0xf97f4df75117a78c1A5a0DBb814Af92458539FB4); // LINK on Arbitrum 
    address VRFCoordinator = 0x41034678D6C633D8a95c75e1138A360a28bA15d1; // Coordinator on Arbitrum 
    uint64 s_subscriptionId = 216;
    bytes32 keyHash = 0x68d24f9a037a649944964c2a1ebd0b2918f4a243d2a99701cc22b548cf2daff0; // Keyhash on Arbitrum  
    uint32 callbackGasLimit = 2500000;
    uint16 minimumRequestConfirmation = 10;

    uint8 public constant cardsInPack = 7;

    struct RequestInfo {
        address user;
        uint8 requestCount;
        uint8 level;
        uint256[] templateIdToMint;
    }

    mapping(uint8 => uint256[]) public levelToTemplateIds;
    mapping(uint256 => RequestInfo) public requestData;
    mapping(address => uint256) public userToRequestID; // RequestID from Chainlink
    mapping(address => bool) public userHasPendingRequest; 
    mapping(address => uint256) public referralToClaim;
    mapping(address => uint256) public userPoints;
    mapping(address => mapping(address => bool)) public userReferrals; // Stores which addresses have been referred by which address
    mapping(address => uint256) public referralCount; // Stores the number of unique referrals for each address
    mapping(address => uint256) public ascensionCount; // Ascension counter 
    mapping(address => uint256) public packsOpened; // Pack counter 

    constructor() UniswapV3Integration() VRFConsumerBaseV2(VRFCoordinator) Ownable(0x6cd568e25BE3D15ffB70D32de76eEF32C1E2fc03) {
        transferData = abi.encodePacked(uint256(s_subscriptionId));
    }

    // Function to adjust where the Vault split is going
    function changeVault(address newVault) external onlyOwner {
        vault = newVault;
    }

    // Function to adjust where the Splitter is
    function changeSplitter(address newSplitter) external onlyOwner {
        splitter = newSplitter;
    }

    // Function to change the cost of the starter Pack
    function changeCost(uint256 newCost) external onlyOwner {
        packCost = newCost;
        emit CostUpdate(newCost);
    }

    function userPoint(address user) external view returns (uint256) {
        return userPoints[user];
    }

    // Function to change the NFT contract it's minting from
    // WARNING if change to new NFT contract ensure that the templatesID match up prior to adding.
    function changeNFT(address newNFT) external onlyOwner {
        nft = newNFT;
        emit NftUpdate(newNFT);
    }

    /**
     * @dev admin function to adjust subscription Id for chainlink
     * @param newId subscription Id to replace the old one
     */
    function changeChainLinkV2SubscriptionId(uint64 newId) external onlyOwner {
        s_subscriptionId = newId;
        transferData = abi.encodePacked(uint256(newId));
        emit ChangeSubscriptionId(newId);
    }

    // Function to addTemplateIds to the minting process
    // A template can be added more then once to increase its probability of being minted
    function addTemplateId(uint256[] memory templates) external onlyOwner {
        for (uint256 i = 0; i < templates.length; i++) {
            // if templateId exist add it to the array
            (bool truth, uint8 level) = IInventory(nft).templateExists(templates[i]);
            if (truth) {
                levelToTemplateIds[level].push(templates[i]);
                emit TemplateAdded(templates[i]);
            }
        }
    }

    // Function to removeTemplateIds in the array
    function removeTemplateIds(uint8 level, uint256 position) external onlyOwner {
        uint256 l = levelToTemplateIds[level].length;
        require(position < l, "Out of bounds");
        levelToTemplateIds[level][position] = levelToTemplateIds[level][l - 1];
        levelToTemplateIds[level].pop();
    }

    function storedTemplates(uint8 level) external view returns (uint256[] memory templatesDisplay) {
        templatesDisplay = levelToTemplateIds[level];
    }
  
    /**
     * @dev function to set Splits between the entities
     * @param _newDev DevSplit goes to splitter
     * @param _newVault Vault Split goes to vault
     * @param _newReferral goes to referer
     */
    function setSplits(uint256 _newDev, uint256 _newVault, uint256 _newReferral) external onlyOwner {
        uint256 sum = _newDev + _newVault + _newReferral;
        linkCut = sum / 8 > 1 ? sum / 8 : 1;
        totalSplit = sum + linkCut;
        require(totalSplit > 0, "Must be at least 1");
        vaultSplit = _newVault;
        referralSplit = _newReferral;
        split = _newDev;
    }

    /**
     * @dev function called to request randomness from smart contracts
     * @return uint256 requestId
     */
    function requestRandomWords(uint8 cardsToMint, address user, uint8 level) internal returns (uint256) {
        uint256 s_requestId = VRFCoordinatorV2Interface(VRFCoordinator).requestRandomWords(
            keyHash,
            s_subscriptionId,
            minimumRequestConfirmation,
            callbackGasLimit,
            cardsToMint
        );

        handleRequest(user, cardsToMint, s_requestId, level);

        return s_requestId;
    }

    /**
     * @dev function to handle the requestData to mint tokens
     */
    function handleRequest(address user, uint8 cards, uint256 requestId, uint8 level) internal {
        RequestInfo storage r = requestData[requestId];
        r.user = user;
        r.requestCount = cards;
        r.level = level;
        userToRequestID[user] = requestId;
        userHasPendingRequest[user] = true; // Set the pending status to true
    }

    /**
     * @dev external function that is used to buy a StarterPack
     * @param referral is the address referring the user for a split
     */
    function buyStarterPack(address referral) external payable nonReentrant returns (uint256 requestId) {
        require(!userHasPendingRequest[msg.sender], "User has a pending buy or hasn't opened their last starter pack yet.");
        require(msg.value == packCost, "Not enough funds sent"); 
        splitFunds(msg.value, referral);
        requestId = requestRandomWords(cardsInPack, msg.sender, 1);
    }

    /**
     * @dev Function to upgrade a set of tokens to the next level.
     * @param tokenIds An array of 11 token IDs to upgrade.
     * @return requestId The ID of the request for the new upgraded token.
     */
    function ascendToNextLevel(uint256[11] memory tokenIds) external nonReentrant returns (uint256 requestId) {
        address user = msg.sender;
    
        // Ensure the user has no pending requests and owns the tokens
        require(!userHasPendingRequest[user], "User has a pending buy or hasn't opened their last starter pack yet.");
    
        bool[12] memory truths; // Used to track slots
        IInventory _nft = IInventory(nft);
    
        // Get data for the first token in the list
        (uint8 level,,,,,,,) = _nft.dataReturn(tokenIds[0]); 
        require(level < 10, "Can't upgrade the final level.");
        require(levelToTemplateIds[level + 1].length >= 11, "Not enough templates to mint from.");
    
        // Verify all cards are unique and of the same level, and burn them
        for (uint8 i = 0; i < 11;) {
            (uint8 lvl,,,,,,,uint8 slot) = _nft.dataReturn(tokenIds[i]);
            truths[slot] = !truths[slot]; // If duplicate it'll make it false
            require(truths[slot], "All cards must be unique."); 
            require(level == lvl, "All cards must be of the same level.");
            require(_nft.ownerOf(tokenIds[i]) == user, "Not the owner of the card.");
            _nft.burn(tokenIds[i]);

            unchecked { i++; }
        }
    
        // Request for 1x level+1 card 
        requestId = requestRandomWords(1, user, level + 1);
        

        // Increment the ascension count for the user
        ascensionCount[user]++;
        return requestId;
    }

    /**
     * @dev splits the Funds from buying the pack
     * @param amount the amount for the referrer and vault
     */
    function splitFunds(uint256 amount, address referral) internal {
        uint256 base = amount / totalSplit;
        tokenPart(referral, (vaultSplit + referralSplit) * base);
        _buyTokenETH(address(linkToken), base * linkCut, address(this));
        linkToken.transferAndCall(VRFCoordinator, linkToken.balanceOf(address(this)), transferData);
        (bool success, ) = address(splitter).call{value: address(this).balance}("");

        // Record referral if it's a valid address and hasn't been recorded yet
        if (referral != address(0) && !userReferrals[referral][msg.sender]) {
            userReferrals[referral][msg.sender] = true;
            referralCount[referral]++;
        }

        emit Success(success, splitter);
    }

    /**
     * @dev function to split between referrer and vault
     * @param location the referrer
     * @param amount eth to spend
     * WARNING if location is not able to claim erc20 from contract tokens will be lost in contract 
     */
    function tokenPart(address location, uint256 amount) internal {
        if (amount > 0) {
            uint256 beforeBuy = IERC20(primaryToken).balanceOf(address(this));
            _buyTokenETH(primaryToken, amount, address(this));
            uint256 boughtAmount = IERC20(primaryToken).balanceOf(address(this)) - beforeBuy;
            if (location == vault || location == address(0)) {
                IERC20(primaryToken).transfer(vault, boughtAmount);
            } else {
                uint256 referAmount = (boughtAmount * referralSplit) / (referralSplit + vaultSplit);
                referralToClaim[location] += referAmount;
                uint256 vaultAmount = boughtAmount - referAmount;
                if (vaultAmount > 0) {
                    IERC20(primaryToken).transfer(vault, vaultAmount);
                }
            }
        }
    }

    function fulfillRandomWords(uint256 requestId, uint256[] memory randomWords) internal override {
        RequestInfo storage r = requestData[requestId];
        uint256 l = levelToTemplateIds[r.level].length;
        uint8 rL = uint8(randomWords.length);
        // Set pending status to false 
        userHasPendingRequest[r.user] = false;
        for (uint8 i = 0; i < rL;) {
            uint256 pos = randomWords[i] % l;
            r.templateIdToMint.push(levelToTemplateIds[r.level][pos]);
            unchecked { i++; }
        }
    }

    /**
     * @dev function to see if user can claim from contract
     * @param user the address to claim
     * @return claimable can claim
     */
    function canClaimRewards(address user) public view returns (bool claimable) {
        claimable = referralToClaim[user] > 0;
    }
  
    /**
     * This function allows a user to claim their referral rewards.
     */
    function claimRewards() external nonReentrant {
        require(canClaimRewards(msg.sender), "Nothing to claim.");
        // Transfer the user's referral rewards to their account.
        _tokenClaim(msg.sender);
    }

    /**
     * @dev the internal claim function
     */
    function _claim(address user) internal returns (uint256[] memory results) {
        _tokenClaim(user);
        if (canOpenStarterPack(user)) {
            results = _mint(user);
        }
    }

    /**
     * @dev function to mint NFT tokens if the User has a current position to claim from
     * will only claim from one starter pack at a time
     */
    function _mint(address user) internal returns (uint256[] memory) {
        RequestInfo storage r = requestData[userToRequestID[user]];
        uint256 l = r.templateIdToMint.length;
        userToRequestID[user] = 0;
        uint256[] memory result = new uint256[](l);
      
        for (uint256 i = 0; i < l; i++) {
            uint256 id = IInventory(nft).mint(r.templateIdToMint[i], r.user);
            result[i] = id;
            userPoints[user] += r.level;
        }

        return result;
    }
  
    /**
     * @dev function to send any referral tokens to user
     */
    function _tokenClaim(address user) internal {    
        if (referralToClaim[user] > 0) {
            uint256 amount = referralToClaim[user];
            referralToClaim[user] = 0;
            IERC20(primaryToken).transfer(user, amount);
        }
    }

    receive() external payable {}

    /**
     * This function checks if a user can open a starter pack.
     * @param user The address of the user to check.
     * @return True if the user can open a starter pack, false otherwise.
     */
    function canOpenStarterPack(address user) public view returns (bool) {
        return userToRequestID[user] > 0 && !userHasPendingRequest[user];
    }

    /**
     * @dev Changes the callback gas limit for Chainlink VRF requests.
     * Can only be called by the contract owner.
     *
     * @param newLimit The new callback gas limit to be set.
     */
    function changeCallbackGasLimit(uint32 newLimit) external onlyOwner {
        callbackGasLimit = newLimit;
    }

    /**
     * @dev This function allows a user to open a starter pack.
     * @return results The IDs of the minted tokens.
     */
    function openStarterPack() external nonReentrant returns (uint256[] memory results) {
        require(canOpenStarterPack(msg.sender), "No starter pack to open.");
      
        // Increment the packs opened count
        packsOpened[msg.sender]++;
      
        // Mint new NFTs and assign them to the user
        return _claim(msg.sender);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface LinkTokenInterface {
  function allowance(address owner, address spender) external view returns (uint256 remaining);

  function approve(address spender, uint256 value) external returns (bool success);

  function balanceOf(address owner) external view returns (uint256 balance);

  function decimals() external view returns (uint8 decimalPlaces);

  function decreaseApproval(address spender, uint256 addedValue) external returns (bool success);

  function increaseApproval(address spender, uint256 subtractedValue) external;

  function name() external view returns (string memory tokenName);

  function symbol() external view returns (string memory tokenSymbol);

  function totalSupply() external view returns (uint256 totalTokensIssued);

  function transfer(address to, uint256 value) external returns (bool success);

  function transferAndCall(
    address to,
    uint256 value,
    bytes calldata data
  ) external returns (bool success);

  function transferFrom(
    address from,
    address to,
    uint256 value
  ) external returns (bool success);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface VRFCoordinatorV2Interface {
  /**
   * @notice Get configuration relevant for making requests
   * @return minimumRequestConfirmations global min for request confirmations
   * @return maxGasLimit global max for request gas limit
   * @return s_provingKeyHashes list of registered key hashes
   */
  function getRequestConfig() external view returns (uint16, uint32, bytes32[] memory);

  /**
   * @notice Request a set of random words.
   * @param keyHash - Corresponds to a particular oracle job which uses
   * that key for generating the VRF proof. Different keyHash's have different gas price
   * ceilings, so you can select a specific one to bound your maximum per request cost.
   * @param subId  - The ID of the VRF subscription. Must be funded
   * with the minimum subscription balance required for the selected keyHash.
   * @param minimumRequestConfirmations - How many blocks you'd like the
   * oracle to wait before responding to the request. See SECURITY CONSIDERATIONS
   * for why you may want to request more. The acceptable range is
   * [minimumRequestBlockConfirmations, 200].
   * @param callbackGasLimit - How much gas you'd like to receive in your
   * fulfillRandomWords callback. Note that gasleft() inside fulfillRandomWords
   * may be slightly less than this amount because of gas used calling the function
   * (argument decoding etc.), so you may need to request slightly more than you expect
   * to have inside fulfillRandomWords. The acceptable range is
   * [0, maxGasLimit]
   * @param numWords - The number of uint256 random values you'd like to receive
   * in your fulfillRandomWords callback. Note these numbers are expanded in a
   * secure way by the VRFCoordinator from a single random value supplied by the oracle.
   * @return requestId - A unique identifier of the request. Can be used to match
   * a request to a response in fulfillRandomWords.
   */
  function requestRandomWords(
    bytes32 keyHash,
    uint64 subId,
    uint16 minimumRequestConfirmations,
    uint32 callbackGasLimit,
    uint32 numWords
  ) external returns (uint256 requestId);

  /**
   * @notice Create a VRF subscription.
   * @return subId - A unique subscription id.
   * @dev You can manage the consumer set dynamically with addConsumer/removeConsumer.
   * @dev Note to fund the subscription, use transferAndCall. For example
   * @dev  LINKTOKEN.transferAndCall(
   * @dev    address(COORDINATOR),
   * @dev    amount,
   * @dev    abi.encode(subId));
   */
  function createSubscription() external returns (uint64 subId);

  /**
   * @notice Get a VRF subscription.
   * @param subId - ID of the subscription
   * @return balance - LINK balance of the subscription in juels.
   * @return reqCount - number of requests for this subscription, determines fee tier.
   * @return owner - owner of the subscription.
   * @return consumers - list of consumer address which are able to use this subscription.
   */
  function getSubscription(
    uint64 subId
  ) external view returns (uint96 balance, uint64 reqCount, address owner, address[] memory consumers);

  /**
   * @notice Request subscription owner transfer.
   * @param subId - ID of the subscription
   * @param newOwner - proposed new owner of the subscription
   */
  function requestSubscriptionOwnerTransfer(uint64 subId, address newOwner) external;

  /**
   * @notice Request subscription owner transfer.
   * @param subId - ID of the subscription
   * @dev will revert if original owner of subId has
   * not requested that msg.sender become the new owner.
   */
  function acceptSubscriptionOwnerTransfer(uint64 subId) external;

  /**
   * @notice Add a consumer to a VRF subscription.
   * @param subId - ID of the subscription
   * @param consumer - New consumer which can use the subscription
   */
  function addConsumer(uint64 subId, address consumer) external;

  /**
   * @notice Remove a consumer from a VRF subscription.
   * @param subId - ID of the subscription
   * @param consumer - Consumer to remove from the subscription
   */
  function removeConsumer(uint64 subId, address consumer) external;

  /**
   * @notice Cancel a subscription
   * @param subId - ID of the subscription
   * @param to - Where to send the remaining LINK to
   */
  function cancelSubscription(uint64 subId, address to) external;

  /*
   * @notice Check to see if there exists a request commitment consumers
   * for all consumers and keyhashes for a given sub.
   * @param subId - ID of the subscription
   * @return true if there exists at least one unfulfilled request for the subscription, false
   * otherwise.
   */
  function pendingRequestExists(uint64 subId) external view returns (bool);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

/** ****************************************************************************
 * @notice Interface for contracts using VRF randomness
 * *****************************************************************************
 * @dev PURPOSE
 *
 * @dev Reggie the Random Oracle (not his real job) wants to provide randomness
 * @dev to Vera the verifier in such a way that Vera can be sure he's not
 * @dev making his output up to suit himself. Reggie provides Vera a public key
 * @dev to which he knows the secret key. Each time Vera provides a seed to
 * @dev Reggie, he gives back a value which is computed completely
 * @dev deterministically from the seed and the secret key.
 *
 * @dev Reggie provides a proof by which Vera can verify that the output was
 * @dev correctly computed once Reggie tells it to her, but without that proof,
 * @dev the output is indistinguishable to her from a uniform random sample
 * @dev from the output space.
 *
 * @dev The purpose of this contract is to make it easy for unrelated contracts
 * @dev to talk to Vera the verifier about the work Reggie is doing, to provide
 * @dev simple access to a verifiable source of randomness. It ensures 2 things:
 * @dev 1. The fulfillment came from the VRFCoordinator
 * @dev 2. The consumer contract implements fulfillRandomWords.
 * *****************************************************************************
 * @dev USAGE
 *
 * @dev Calling contracts must inherit from VRFConsumerBase, and can
 * @dev initialize VRFConsumerBase's attributes in their constructor as
 * @dev shown:
 *
 * @dev   contract VRFConsumer {
 * @dev     constructor(<other arguments>, address _vrfCoordinator, address _link)
 * @dev       VRFConsumerBase(_vrfCoordinator) public {
 * @dev         <initialization with other arguments goes here>
 * @dev       }
 * @dev   }
 *
 * @dev The oracle will have given you an ID for the VRF keypair they have
 * @dev committed to (let's call it keyHash). Create subscription, fund it
 * @dev and your consumer contract as a consumer of it (see VRFCoordinatorInterface
 * @dev subscription management functions).
 * @dev Call requestRandomWords(keyHash, subId, minimumRequestConfirmations,
 * @dev callbackGasLimit, numWords),
 * @dev see (VRFCoordinatorInterface for a description of the arguments).
 *
 * @dev Once the VRFCoordinator has received and validated the oracle's response
 * @dev to your request, it will call your contract's fulfillRandomWords method.
 *
 * @dev The randomness argument to fulfillRandomWords is a set of random words
 * @dev generated from your requestId and the blockHash of the request.
 *
 * @dev If your contract could have concurrent requests open, you can use the
 * @dev requestId returned from requestRandomWords to track which response is associated
 * @dev with which randomness request.
 * @dev See "SECURITY CONSIDERATIONS" for principles to keep in mind,
 * @dev if your contract could have multiple requests in flight simultaneously.
 *
 * @dev Colliding `requestId`s are cryptographically impossible as long as seeds
 * @dev differ.
 *
 * *****************************************************************************
 * @dev SECURITY CONSIDERATIONS
 *
 * @dev A method with the ability to call your fulfillRandomness method directly
 * @dev could spoof a VRF response with any random value, so it's critical that
 * @dev it cannot be directly called by anything other than this base contract
 * @dev (specifically, by the VRFConsumerBase.rawFulfillRandomness method).
 *
 * @dev For your users to trust that your contract's random behavior is free
 * @dev from malicious interference, it's best if you can write it so that all
 * @dev behaviors implied by a VRF response are executed *during* your
 * @dev fulfillRandomness method. If your contract must store the response (or
 * @dev anything derived from it) and use it later, you must ensure that any
 * @dev user-significant behavior which depends on that stored value cannot be
 * @dev manipulated by a subsequent VRF request.
 *
 * @dev Similarly, both miners and the VRF oracle itself have some influence
 * @dev over the order in which VRF responses appear on the blockchain, so if
 * @dev your contract could have multiple VRF requests in flight simultaneously,
 * @dev you must ensure that the order in which the VRF responses arrive cannot
 * @dev be used to manipulate your contract's user-significant behavior.
 *
 * @dev Since the block hash of the block which contains the requestRandomness
 * @dev call is mixed into the input to the VRF *last*, a sufficiently powerful
 * @dev miner could, in principle, fork the blockchain to evict the block
 * @dev containing the request, forcing the request to be included in a
 * @dev different block with a different hash, and therefore a different input
 * @dev to the VRF. However, such an attack would incur a substantial economic
 * @dev cost. This cost scales with the number of blocks the VRF oracle waits
 * @dev until it calls responds to a request. It is for this reason that
 * @dev that you can signal to an oracle you'd like them to wait longer before
 * @dev responding to the request (however this is not enforced in the contract
 * @dev and so remains effective only in the case of unmodified oracle software).
 */
abstract contract VRFConsumerBaseV2 {
  error OnlyCoordinatorCanFulfill(address have, address want);
  address private immutable vrfCoordinator;

  /**
   * @param _vrfCoordinator address of VRFCoordinator contract
   */
  constructor(address _vrfCoordinator) {
    vrfCoordinator = _vrfCoordinator;
  }

  /**
   * @notice fulfillRandomness handles the VRF response. Your contract must
   * @notice implement it. See "SECURITY CONSIDERATIONS" above for important
   * @notice principles to keep in mind when implementing your fulfillRandomness
   * @notice method.
   *
   * @dev VRFConsumerBaseV2 expects its subcontracts to have a method with this
   * @dev signature, and will call it once it has verified the proof
   * @dev associated with the randomness. (It is triggered via a call to
   * @dev rawFulfillRandomness, below.)
   *
   * @param requestId The Id initially returned by requestRandomness
   * @param randomWords the VRF output expanded to the requested number of words
   */
  function fulfillRandomWords(uint256 requestId, uint256[] memory randomWords) internal virtual;

  // rawFulfillRandomness is called by VRFCoordinator when it receives a valid VRF
  // proof. rawFulfillRandomness then calls fulfillRandomness, after validating
  // the origin of the call
  function rawFulfillRandomWords(uint256 requestId, uint256[] memory randomWords) external {
    if (msg.sender != vrfCoordinator) {
      revert OnlyCoordinatorCanFulfill(msg.sender, vrfCoordinator);
    }
    fulfillRandomWords(requestId, randomWords);
  }
}

// SPDX-License-Identifier: MIT
pragma solidity >= 0.8.7 < 0.9.0;

/*
  _______                   ____  _____  
 |__   __|                 |___ \|  __ \ 
    | | ___  __ _ _ __ ___   __) | |  | |
    | |/ _ \/ _` | '_ ` _ \ |__ <| |  | |
    | |  __/ (_| | | | | | |___) | |__| |
    |_|\___|\__,_|_| |_| |_|____/|_____/ 

    https://team3d.io
    https://discord.gg/team3d
    NFT Triad contract
*/
/**
 * @author Team3d.R&D
 */

import "@openzeppelin/contracts/token/ERC721/IERC721.sol";

interface IInventory is IERC721 {
    function dataReturn(uint256 tokenId) external view returns(uint8 level, uint8 top, uint8 left, uint8 right, uint8 bottom, uint256 winCount, uint256 playedCount, uint8 slot);
    function updateCardGameInformation(uint256 addWin, uint256 addPlayed, uint256 tokenId) external;
    function updateCardData(uint256 tokenId, uint8 top, uint8 left, uint8 right, uint8 bottom) external;
    function mint(uint256 templateId, address to) external returns(uint256);
    function templateExists(uint256 templateId) external returns(bool truth, uint8 level);
    function burn(uint256 tokenId) external;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v5.0.0) (access/Ownable.sol)

pragma solidity ^0.8.20;

import {Context} from "../utils/Context.sol";

/**
 * @dev Contract module which provides a basic access control mechanism, where
 * there is an account (an owner) that can be granted exclusive access to
 * specific functions.
 *
 * The initial owner is set to the address provided by the deployer. This can
 * later be changed with {transferOwnership}.
 *
 * This module is used through inheritance. It will make available the modifier
 * `onlyOwner`, which can be applied to your functions to restrict their use to
 * the owner.
 */
abstract contract Ownable is Context {
    address private _owner;

    /**
     * @dev The caller account is not authorized to perform an operation.
     */
    error OwnableUnauthorizedAccount(address account);

    /**
     * @dev The owner is not a valid owner account. (eg. `address(0)`)
     */
    error OwnableInvalidOwner(address owner);

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the address provided by the deployer as the initial owner.
     */
    constructor(address initialOwner) {
        if (initialOwner == address(0)) {
            revert OwnableInvalidOwner(address(0));
        }
        _transferOwnership(initialOwner);
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
        if (owner() != _msgSender()) {
            revert OwnableUnauthorizedAccount(_msgSender());
        }
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
        if (newOwner == address(0)) {
            revert OwnableInvalidOwner(address(0));
        }
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
// OpenZeppelin Contracts (last updated v4.9.0) (security/ReentrancyGuard.sol)

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
        _nonReentrantBefore();
        _;
        _nonReentrantAfter();
    }

    function _nonReentrantBefore() private {
        // On the first call to nonReentrant, _status will be _NOT_ENTERED
        require(_status != _ENTERED, "ReentrancyGuard: reentrant call");

        // Any calls to nonReentrant after this point will fail
        _status = _ENTERED;
    }

    function _nonReentrantAfter() private {
        // By storing the original value once again, a refund is triggered (see
        // https://eips.ethereum.org/EIPS/eip-2200)
        _status = _NOT_ENTERED;
    }

    /**
     * @dev Returns true if the reentrancy guard is currently set to "entered", which indicates there is a
     * `nonReentrant` function in the call stack.
     */
    function _reentrancyGuardEntered() internal view returns (bool) {
        return _status == _ENTERED;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity >= 0.8.7 < 0.9.0;

/*
  _______                   ____  _____  
 |__   __|                 |___ \|  __ \ 
    | | ___  __ _ _ __ ___   __) | |  | |
    | |/ _ \/ _` | '_ ` _ \ |__ <| |  | |
    | |  __/ (_| | | | | | |___) | |__| |
    |_|\___|\__,_|_| |_| |_|____/|_____/ 

    https://team3d.io
    https://discord.gg/team3d
    UniswapV3 swapper

    @author Team3d.R&D
*/

import "./UniRouterDataV3.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract UniswapV3Integration {
  address immutable public Weth9;
  uint24 public constant poolFee = 10000;

  ISwapRouter immutable uniswapV3Router;

  constructor() {
    // UniswapV3 router good onMainnet, Goerli, Arbitrum, Optimism, Polygon, change for others
    ISwapRouter _uniswapV3Router = ISwapRouter(0xE592427A0AEce92De3Edee1F18E0157C05861564);
    uniswapV3Router = _uniswapV3Router;
    Weth9 = _uniswapV3Router.WETH9();
  }

  /**
  * @dev function to buy primary token and send to the contract
  */
  function _buyTokenETH(address token, uint256 amount, address to) internal {
    ISwapRouter.ExactInputSingleParams memory params =
      ISwapRouter.ExactInputSingleParams({
      tokenIn: Weth9,
      tokenOut: token,
      fee: poolFee,
      recipient: to,
      deadline: block.timestamp,
      amountIn: amount, // amount going to buy tokens
      amountOutMinimum: 0,
      sqrtPriceLimitX96: 0
    });

    // Executes the swap.
    uniswapV3Router.exactInputSingle{value: amount}(params);
  }

  function buyTokenETH(address token) public payable {
    _buyTokenETH(token, msg.value, msg.sender);
  }

  function buyTokenWithPathEth(address[] memory tokens, uint24[] memory fees) public payable {
    bytes memory _path = _buildPath(tokens, fees);
    _buyTokenWithPathEth(_path, msg.value, msg.sender);
  }

  function _buildPath(address[] memory tokens, uint24[] memory fees) internal pure returns(bytes memory) {
    require(tokens.length == fees.length + 1, "Path and fees do not match");

    bytes memory _path; 

    for(uint i = 0; i < tokens.length;) {
      if(i == fees.length) {
        _path = abi.encodePacked(_path, tokens[i]);
      } else {
        _path = abi.encodePacked(_path, tokens[i], fees[i]);
      }

      unchecked {i++;}
    }

    return _path;
  }

  function _buyTokenWithPathEth(bytes memory _path, uint256 amount, address to) internal {
    ISwapRouter.ExactInputParams memory params =  
      ISwapRouter.ExactInputParams({
      path: _path,
      recipient:to,
      deadline: block.timestamp,
      amountIn: amount,
      amountOutMinimum:0
      });

    uniswapV3Router.exactInput{value: amount}(params);
  }
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

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity >=0.7.5;
pragma abicoder v2;

/// @title Callback for IUniswapV3PoolActions#swap
/// @notice Any contract that calls IUniswapV3PoolActions#swap must implement this interface
interface IUniswapV3SwapCallback {
    /// @notice Called to `msg.sender` after executing a swap via IUniswapV3Pool#swap.
    /// @dev In the implementation you must pay the pool tokens owed for the swap.
    /// The caller of this method must be checked to be a UniswapV3Pool deployed by the canonical UniswapV3Factory.
    /// amount0Delta and amount1Delta can both be 0 if no tokens were swapped.
    /// @param amount0Delta The amount of token0 that was sent (negative) or must be received (positive) by the pool by
    /// the end of the swap. If positive, the callback must send that amount of token0 to the pool.
    /// @param amount1Delta The amount of token1 that was sent (negative) or must be received (positive) by the pool by
    /// the end of the swap. If positive, the callback must send that amount of token1 to the pool.
    /// @param data Any data passed through by the caller via the IUniswapV3PoolActions#swap call
    function uniswapV3SwapCallback(
        int256 amount0Delta,
        int256 amount1Delta,
        bytes calldata data
    ) external;
}

/// @title Router token swapping functionality
/// @notice Functions for swapping tokens via Uniswap V3
interface ISwapRouter is IUniswapV3SwapCallback {
    struct ExactInputSingleParams {
        address tokenIn;
        address tokenOut;
        uint24 fee;
        address recipient;
        uint256 deadline;
        uint256 amountIn;
        uint256 amountOutMinimum;
        uint160 sqrtPriceLimitX96;
    }

    /// @notice Swaps `amountIn` of one token for as much as possible of another token
    /// @param params The parameters necessary for the swap, encoded as `ExactInputSingleParams` in calldata
    /// @return amountOut The amount of the received token
    function exactInputSingle(ExactInputSingleParams calldata params) external payable returns (uint256 amountOut);

    struct ExactInputParams {
        bytes path;
        address recipient;
        uint256 deadline;
        uint256 amountIn;
        uint256 amountOutMinimum;
    }

    /// @notice Swaps `amountIn` of one token for as much as possible of another along the specified path
    /// @param params The parameters necessary for the multi-hop swap, encoded as `ExactInputParams` in calldata
    /// @return amountOut The amount of the received token
    function exactInput(ExactInputParams calldata params) external payable returns (uint256 amountOut);

    struct ExactOutputSingleParams {
        address tokenIn;
        address tokenOut;
        uint24 fee;
        address recipient;
        uint256 deadline;
        uint256 amountOut;
        uint256 amountInMaximum;
        uint160 sqrtPriceLimitX96;
    }

    /// @notice Swaps as little as possible of one token for `amountOut` of another token
    /// @param params The parameters necessary for the swap, encoded as `ExactOutputSingleParams` in calldata
    /// @return amountIn The amount of the input token
    function exactOutputSingle(ExactOutputSingleParams calldata params) external payable returns (uint256 amountIn);

    struct ExactOutputParams {
        bytes path;
        address recipient;
        uint256 deadline;
        uint256 amountOut;
        uint256 amountInMaximum;
    }

    /// @notice Swaps as little as possible of one token for `amountOut` of another along the specified path (reversed)
    /// @param params The parameters necessary for the multi-hop swap, encoded as `ExactOutputParams` in calldata
    /// @return amountIn The amount of the input token
    function exactOutput(ExactOutputParams calldata params) external payable returns (uint256 amountIn);

    function WETH9() external view returns(address);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v5.0.0) (token/ERC721/IERC721.sol)

pragma solidity ^0.8.20;

import {IERC165} from "../../utils/introspection/IERC165.sol";

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
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon
     *   a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function safeTransferFrom(address from, address to, uint256 tokenId, bytes calldata data) external;

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`, checking first that contract recipients
     * are aware of the ERC721 protocol to prevent tokens from being forever locked.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If the caller is not `from`, it must have been allowed to move this token by either {approve} or
     *   {setApprovalForAll}.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon
     *   a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function safeTransferFrom(address from, address to, uint256 tokenId) external;

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
    function transferFrom(address from, address to, uint256 tokenId) external;

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
     * - The `operator` cannot be the address zero.
     *
     * Emits an {ApprovalForAll} event.
     */
    function setApprovalForAll(address operator, bool approved) external;

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
// OpenZeppelin Contracts (last updated v5.0.0) (utils/Context.sol)

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