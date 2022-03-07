pragma solidity ^0.8.0;
//SPDX-License-Identifier: MIT

import "./IEllerianHero.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

/** 
 * Tales of Elleria
*/
contract EllerianHeroToken is Ownable {

    bool private globalMintOpened;
    uint256 summoningId;
    uint256 summonMintLimit;

    uint256[][] private tokenMintPrice;
    address[][] private tokenMintPair;

    mapping(uint => mapping (address => uint256)) private mintingLimits;
    IEllerianHero private minterAbi;

    address private mintBurnAddress;
    address private feesAddress;

    function GetMintsLeft() public view returns (uint256) {
        return summonMintLimit - mintingLimits[summoningId][msg.sender];
    }

    function GetVariantMintCost(uint256 _variant) public view returns (uint256[] memory) {
        return tokenMintPrice[_variant];
    }

     function GetMintingPair(uint256 _variant) public view returns (address[] memory) {
        return tokenMintPair[_variant];
    }
    
    /*
    * Allows the owner to block or allow minting.
    */
    function SetGlobalMint(bool _allow) external onlyOwner {
        globalMintOpened = _allow;
    }

    /*  
    * Adjusts the prices and tokens used for payment.
    */
    function SetMintingPrices(uint256[][] memory _mintPricesInWEI, address[][] memory _mintPairAddresses) external onlyOwner{
        tokenMintPrice = _mintPricesInWEI;
        tokenMintPair = _mintPairAddresses;
        globalMintOpened = false;
    }

    /*  
    * Adjusts the summon ID to reset the maximum summon count.
    * If no need for a finite supply, this won't be used.
    */
    function SetBannerInformation(uint256 _summoningId, uint256 _summonLimit) external onlyOwner {
        summonMintLimit = _summonLimit;
        summoningId = _summoningId;
        globalMintOpened = false;
    }

    /*
    * Link with other contracts necessary for this to function.
    */
    function SetAddresses(address _minterAddress, address _feesAddress, address _mintBurnAddress) external onlyOwner {
        minterAbi = IEllerianHero(_minterAddress);

        feesAddress = _feesAddress;
        mintBurnAddress = _mintBurnAddress;
    }

    function AttemptMint(uint256 _variant, uint256 _amount) external {
        require (globalMintOpened, "ERR16");
        require (tx.origin == msg.sender, "9");

        mintingLimits[summoningId][msg.sender] = mintingLimits[summoningId][msg.sender] + _amount;
        require (mintingLimits[summoningId][msg.sender] < summonMintLimit + 1, "39");


        // Collect payments from both tokens. Main token will be burnt, second sent to treasury.
        IERC20(tokenMintPair[_variant][0]).transferFrom(msg.sender, mintBurnAddress, tokenMintPrice[_variant][0]);
        IERC20(tokenMintPair[_variant][1]).transferFrom(msg.sender, feesAddress, tokenMintPrice[_variant][1]);

        // Tell the main contract to let us mint~
        minterAbi.mintUsingToken(msg.sender, _amount, _variant);
    }
  

}

pragma solidity ^0.8.0;
//SPDX-License-Identifier: UNLICENSED

// Interface for Elleria's Heroes.
contract IEllerianHero {

  function safeTransferFrom (address _from, address _to, uint256 _tokenId) public {}
  function safeTransferFrom (address _from, address _to, uint256 _tokenId, bytes memory _data) public {}

  function mintUsingToken(address _recipient, uint256 _amount, uint256 _variant) public {}

  function burn (uint256 _tokenId, bool _isBurnt) public {}

  function ownerOf(uint256 tokenId) external view returns (address owner) {}
  function isApprovedForAll(address owner, address operator) external view returns (bool) {}
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.0 (utils/Context.sol)

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
// OpenZeppelin Contracts v4.4.0 (token/ERC20/IERC20.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20 {
    /**
     * @dev Returns the amount of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the amount of tokens owned by `account`.
     */
    function balanceOf(address account) external view returns (uint256);

    /**
     * @dev Moves `amount` tokens from the caller's account to `recipient`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address recipient, uint256 amount) external returns (bool);

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
     * @dev Moves `amount` tokens from `sender` to `recipient` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external returns (bool);

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
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.0 (access/Ownable.sol)

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