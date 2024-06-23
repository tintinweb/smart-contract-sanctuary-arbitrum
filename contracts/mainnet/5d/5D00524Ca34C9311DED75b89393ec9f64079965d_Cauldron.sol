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
    Distribution contract
*/
/**
 * @author Team3d.R&D
 */

import "../IInventory.sol";
import "./DistributionSystem.sol";
import "@openzeppelin/contracts/access/Ownable.sol";


contract Cauldron is Ownable(0x6cd568e25BE3D15ffB70D32de76eEF32C1E2fc03), DistributionSystem {
    event GatewaySet(address _gateway);
    IInventory immutable nft;
	
    uint256 public spillage;
	uint256 public totalCardsBurned;
	  uint8 public highestLevelBurned;
    address public gateway;
	
	uint256[11] public pointPerLevel;

	mapping(uint8 => mapping(uint8 => uint256)) public levelToSlotToBurnCount;
	mapping(address => uint256) public agnosia; 
	mapping(address => uint256) public totalCardsBurnedPerUser; 
	mapping(address => uint256) public highestLevelBurnedPerUser; 

    constructor(address _rewardToken, address _nft) DistributionSystem(_rewardToken) {
        nft = IInventory(_nft);
    }

    function gatewaySet() public view returns(bool) {
        return gateway != address(0);
    }

    function setGateway(address _gateway) external onlyOwner() {
        require(!gatewaySet(), "Gateway already set");
        gateway = _gateway;
		
        emit GatewaySet(gateway);
    }

    function _processClaim(address user, uint256 tokensToClaim) internal override {
        spillage += ((16 - highestLevelBurned) * tokensToClaim / 100); // max 15% to a minium of 6% of tokensToClaim go to future gateway
        if(gatewaySet()) {
            _transferClaim(gateway, spillage);
            spillage = 0;
        }
		
        super._processClaim(user, tokensToClaim);
    }

    function rewardSupply() public override view returns(uint256 supply) {
        supply = super.rewardSupply();
        if(!gatewaySet()) {
            supply -= spillage;
        }
    }

    function UIHelperForUser(address user) external view returns(uint256 _tokensClaimable, uint256 userWeight, uint256 totalWeight, uint256 _rewardsClaimed) {
        (_tokensClaimable, userWeight, totalWeight) = tokensClaimable(user);
        _rewardsClaimed = rewardsClaimed[user];
    }

    function UIHelperForGeneralInformation() external view returns( uint256 _totalClaimed, uint256 _totalBurned) {
        _totalBurned = totalCardsBurned;
        _totalClaimed = totalRewardsClaimed;
    }

    function increaseCauldronPortion(uint256[] memory tokenIds) external {
        uint256 weightToAdd;
        for(uint i = 0; i < tokenIds.length;) {
            require(nft.ownerOf(tokenIds[i]) == msg.sender, "Not the card owner.");
			
			agnosia[msg.sender]++; 
			
            (uint8 level,,,,, uint256 winCount,, uint8 slot) = nft.dataReturn(tokenIds[i]);
            nft.burn(tokenIds[i]);
			
            // Do point math...
            weightToAdd += (bonusMultiplier(tokenIds[i]) * (pointPerLevel[level] + (winCount/level)));
            levelToSlotToBurnCount[level][slot]++;
            highestLevelBurned = level > highestLevelBurned ? level : highestLevelBurned;
			highestLevelBurnedPerUser[msg.sender] = level > highestLevelBurnedPerUser[msg.sender] ? level : highestLevelBurnedPerUser[msg.sender];
            unchecked {i++;}
        }
		
        totalCardsBurned += tokenIds.length;
		totalCardsBurnedPerUser[msg.sender]++; 
        _addWeight(msg.sender, weightToAdd);
    }

    function initialize() external onlyOwner() {
        pointPerLevel[1] = 1;
		
        for(uint i = 2; i < 11;) {
            pointPerLevel[i] = (12 * pointPerLevel[i-1]);
            unchecked {i++;}
        }
    }

    function bonusMultiplier(uint256 _tokenId) public view returns(uint256 bonusMulti) {
        (uint8 _level,,,,,,,uint8 _slot) = nft.dataReturn(_tokenId);
        bonusMulti = (50/(levelToSlotToBurnCount[_level][_slot]+1)) > 0 ? (50/(levelToSlotToBurnCount[_level][_slot]+1)): 1;
    }

    function getBatchBrewValueMulti(uint256[] memory _tokenIds) public view returns(uint256[] memory cardsPointValue, uint256 sumOfCards, uint256 userPoints, uint256 contractPoints){
        cardsPointValue = new uint256[](_tokenIds.length);
        uint256[12][12] memory sutoCardBurner;
        address user = msg.sender;
        for(uint x =0; x< _tokenIds.length; x++){

            (uint8 _level,,,,,uint256 _wincount,,uint8 _slot) = nft.dataReturn(_tokenIds[x]);
            sutoCardBurner[_level][_slot]++;
            uint256 b = (50/(levelToSlotToBurnCount[_level][_slot]+sutoCardBurner[_level][_slot])) > 0 ? (50/(levelToSlotToBurnCount[_level][_slot]+sutoCardBurner[_level][_slot])): 1;
            cardsPointValue[x] = b * (pointPerLevel[_level] + (_wincount/_level));
            sumOfCards += cardsPointValue[x];
        }

        (,userPoints, contractPoints) = tokensClaimable(user);

    }
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
    Agnosia Distribution System contract
*/
/**
 * @author Team3d.R&D
*/

import "./WeightedSystem.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";


contract DistributionSystem is WeightedSystem {
    event Claimed(address user, uint256 amount);

    IERC20 immutable public rewardToken;
	
    uint256 timeSet = 730 days;
    uint256 public totalRewardsClaimed;

    mapping(address => uint256) public lastClaim;
    mapping(address => uint256) public rewardsClaimed;

    constructor(address _rewardToken) {
        rewardToken = IERC20(_rewardToken);
    }

    function claim() external {
	require(lastClaim[msg.sender] > 0, "Has not burned cards yet");
        _claim(msg.sender);
    }

    function _claim(address user) internal {
        if(lastClaim[user] == 0) {
            lastClaim[user] = block.timestamp;
        } else {
            (uint256 tokensToClaim,,) = tokensClaimable(user);
            require(tokensToClaim > 0, "Nothing to claim.");
            lastClaim[user] = block.timestamp;
            _processClaim(user, tokensToClaim);
        }
    }

    function _processClaim(address user, uint256 tokensToClaim) internal virtual {
        if(tokensToClaim > rewardSupply()) {
            tokensToClaim = rewardSupply();
        }
		
        _transferClaim(user, tokensToClaim);
        totalRewardsClaimed += tokensToClaim;
        rewardsClaimed[user] += tokensToClaim;
		
        emit Claimed(user, tokensToClaim);
    }

    function _transferClaim(address user, uint256 amount) internal {
		rewardToken.transfer(user, amount);
    }

    function _addWeight(address user, uint256 weightToAdd) internal override {
        _claim(user);
        super._addWeight(user, weightToAdd);
    }
	
    function tokensClaimable(address user) public view returns(uint256 tokensToClaim, uint256 userWeight, uint256 totalWeight) {
        (userWeight, totalWeight) = weights(user);
		
        if(userWeight == 0) {
			tokensToClaim = 0;
		} else {
           tokensToClaim = calculateClaim(user, userWeight, totalWeight);
        }
    }

    function rewardSupply() public virtual view returns(uint256 supply) {
        supply = rewardToken.balanceOf(address(this));
    }

    function calculateClaim(address user, uint256 uw, uint256 tw) internal view returns(uint256 amount) {
        uint256 timeDiff = block.timestamp - lastClaim[user];
        amount = (((rewardSupply() / timeSet) * timeDiff) / tw) * uw;
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
    Agnosia Burn Point System contract
*/
/**
 * @author Team3d.R&D
*/

import "../IInventory.sol";


contract WeightedSystem {
	event weightUpdated(uint256 _totalWeight, address indexed user, uint256 _userWeight);

	uint256 public totalWeight;
	mapping(address => uint256) public userWeights;
	address[] public users;

	function _addWeight(address user, uint256 weightToAdd) internal virtual {
		require(totalWeight < type(uint256).max - weightToAdd, "Weights are capped out.");
		
		if(userWeights[user] == 0) users.push(user);
		userWeights[user] += weightToAdd;
		totalWeight += weightToAdd;
		
		emit weightUpdated(totalWeight, user, userWeights[user]);
	}

	function weights(address user) public view returns(uint256 userW, uint256 totalW) {
		 userW = userWeights[user];
		totalW = totalWeight;
	}
  	function usersList()public view returns(address[] memory _users){
    		_users = users;
  	}
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