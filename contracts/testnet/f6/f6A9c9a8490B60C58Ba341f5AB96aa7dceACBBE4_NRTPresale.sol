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
// OpenZeppelin Contracts (last updated v4.9.0) (token/ERC721/IERC721.sol)

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
     * - If the caller is not `from`, it must have been allowed to move this token by either {approve} or {setApprovalForAll}.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
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
     * - The `operator` cannot be the caller.
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

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

// dummy NFT contract on arbitrum goerli : 0x94fCa01B9BACcc386f9808C90Bba491826Db94E9


/**
 * @title NRTPresale
 * @dev Store & retrieve value in a variable
 * @custom:dev-run-script ./scripts/deploy_with_ethers.ts
 */
contract NRTPresale is Ownable {

    IERC721 public GMX; // adress == 0x17f4BAa9D35Ee54fFbCb2608e20786473c7aa49f // (check it tho)
    IERC20 public StableCoin;

    mapping(address => bool) public isWhitelisted;
    mapping(address => uint) totalInvestedUSD;
    mapping(address => uint) totalInvestedNRT;
    mapping(address => uint) amountLeftToWithdraw;
    mapping(address => uint) amountWithdrawn;
    mapping(address => uint) secondsForOneNRT;
    mapping(address => uint) lastWithdrawTimestamp;

    mapping(address => uint) public totalPrivateSaleVault;
    mapping(address => uint) public currentPrivateSaleVault;

    uint256 public PRIVATE_SALE_VESTING_END_DATE;
    uint256 public PRIVATE_SALE_VESTING_MONTHLY_UNLOCK_RATE = 10;
    // seconds to 100% full unlock : 17515872

    uint totalNRTInvested;
    uint totalUSDInvested;

    address teamWallet;


    constructor (address _GMXContract, address _USDCContract, address _teamWallet) {
        GMX = IERC721(_GMXContract);
        StableCoin = IERC20(_USDCContract);
        teamWallet = _teamWallet;
        PRIVATE_SALE_VESTING_END_DATE = block.timestamp + 3; //+ 26274240; <==== REMETTRE CA // 26274240 == (nb seconds in a day) x 304.1 days (10 months).

        // lastWithdrawTimestamp[msg.sender] = PRIVATE_SALE_VESTING_END_DATE; // delete de là
        //totalInvestedNRT[0x5B38Da6a701c568545dCfcB03FcB875f56beddC4] = 317377; 
        //amountLeftToWithdraw[0x5B38Da6a701c568545dCfcB03FcB875f56beddC4] = 317377;
        // secondsForOneNRT[msg.sender] = (26274240 / totalInvestedNRT[msg.sender]); //... à là
    }


    function changeStableCoinInterface (address _newStableCoinContract) external onlyOwner {
        StableCoin = IERC20(_newStableCoinContract);
    }

    function whitelistManyUsers(address[] memory _users) external onlyOwner {
        for (uint256 i = 0; i < _users.length; i++) {
            isWhitelisted[_users[i]] = true;
        }
    }

    function allowedInvestingamount () public view returns (uint) {
        uint nbrOfGMXAssets;
        uint total;
        nbrOfGMXAssets = GMX.balanceOf(msg.sender);
        if (isWhitelisted[msg.sender])
            total = (nbrOfGMXAssets * 500) + 2000;
        else
            total = (nbrOfGMXAssets * 500);
        return (total * 10**6 - totalInvestedUSD[msg.sender]);
    }

    function allowStableCoinContractToSpend (uint _USDamount) external {
        _USDamount = _USDamount * 10**6;
        require (isWhitelisted[msg.sender] || GMX.balanceOf(msg.sender) > 0, "You either are not whitelisted or do not possess any GMX NFT.");
        require ((totalInvestedUSD[msg.sender] + _USDamount) < allowedInvestingamount(), "You cannot invest that much.");
        require(StableCoin.approve(address(this), _USDamount), "Stable coin contract failed to make an allowance for you.");
    }

    function invest (uint _USDamount) external {
        _USDamount = _USDamount * 10**6;
        require (isWhitelisted[msg.sender] || GMX.balanceOf(msg.sender) > 0, "You either are not whitelisted or do not possess any GMX NFT.");
        require ((totalInvestedUSD[msg.sender] + _USDamount) < allowedInvestingamount(), "You cannot invest that much.");
        
        require(StableCoin.balanceOf(msg.sender) >= _USDamount, "Insufficient stableCoin balance.");
        //StableCoin.approve(address(this), _USDamount);
        StableCoin.transferFrom(msg.sender, teamWallet, _USDamount);

        totalInvestedUSD[msg.sender] += _USDamount;
        totalInvestedNRT[msg.sender] += (_USDamount * 20) / 1000000;
        amountLeftToWithdraw[msg.sender] = totalInvestedNRT[msg.sender];
        secondsForOneNRT[msg.sender] = (17515872 / totalInvestedNRT[msg.sender]);
        totalNRTInvested += (_USDamount * 20) / 1000000;
        totalUSDInvested += _USDamount;
    }

    function tryInvest1() public {
        require(StableCoin.balanceOf(msg.sender) >= (149 * 10**6), "Insufficient stableCoin balance.");
        //require(StableCoin.approve(address(this), (149 * 10**6)), "approve fail");
        require(StableCoin.transferFrom(msg.sender, teamWallet, (149 * 10**6)), "transfer fail");
    }

    function releasePrivatesaleVesting () external {
        require(totalPrivateSaleVault[msg.sender] > 0, "You are not part of the private sale investors.");
        require(block.timestamp > PRIVATE_SALE_VESTING_END_DATE, "End date has not been reached yet for privates sale investors.");
        uint i = 0;
        i = 1;
    }

    function getTimeLeftForPrivateSaleVestingRelease () public view returns (uint) {
        return (PRIVATE_SALE_VESTING_END_DATE - block.timestamp);
    }

    function getWidthdrawableAmount () public view returns (uint) {
        require(block.timestamp > PRIVATE_SALE_VESTING_END_DATE, "End date has not been reached yet for privates sale investors.");
        uint _amount = (block.timestamp - lastWithdrawTimestamp[msg.sender]) / secondsForOneNRT[msg.sender];
        return (_amount);
    }

    function getSecondsForUnlockingAnNRT () public view returns (uint) {
        return (secondsForOneNRT[msg.sender]);
    }

    function getTotalUSDInvested () external onlyOwner view returns (uint) {
        return (totalUSDInvested);
    }

    function getTotalNRTInvested () external onlyOwner view returns (uint) {
        return (totalNRTInvested);
    }
}