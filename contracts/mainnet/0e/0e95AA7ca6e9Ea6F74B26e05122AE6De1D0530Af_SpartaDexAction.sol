/**
 *Submitted for verification at Arbiscan.io on 2023-11-30
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.6;

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
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);

    function mint(address _account, uint256 _amount) external;
    
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

interface IPromotionCodeManager {
    function usePromotionCode(address, address, uint256, uint256) external returns (address, uint256);

    function getPromotionCodeDetail(address) external view returns (address, uint256);
}

interface ISpartaDexRouter {
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
}

contract SpartaDexAction is Ownable{
    address public campaign;

    address public tokenA;
    uint256 public tokenAAmount = 10 * 1e6;
    uint256 public tokenAMin = 99 * 1e5;

    address public tokenB;
    uint256 public tokenBAmount = 10 * 1e6;
    uint256 public tokenBMin = 99 * 1e5;

    address public router;

    address public promotionCodeManager;

    modifier onlyCampaign(){
        require(msg.sender == campaign, "PromotionCodeAction: check campaign and action");
        _;
    }

    constructor(address _tokenA, address _tokenB, address _router){
        tokenA = _tokenA;
        tokenB = _tokenB;

        router = _router;

        IERC20(tokenA).approve(router, type(uint256).max);
        IERC20(tokenB).approve(router, type(uint256).max);
    }

    function setCampaign(address _campaign) external onlyOwner {
        campaign = _campaign;
    }

    function setPromotionCodeManager(address _promotionCodeManager) public onlyOwner {
        promotionCodeManager = _promotionCodeManager;
    }

    // to help users who accidentally send their tokens to this contract
    function withdrawToken(address _token, address _account, uint256 _amount) external onlyOwner {
        IERC20(_token).transfer(_account, _amount);
    }

    function execute(address _account, bytes calldata _data) external onlyCampaign{
        address user = _account;

        (address promotionCode, uint256 tokenId) = abi.decode(_data, (address, uint256));

        uint256 tokenAInput = tokenAAmount;
        uint256 tokenBInput = tokenBAmount;

        uint256 beforeTokenABalance = IERC20(tokenA).balanceOf(address(this));
        uint256 beforeTokenBBalance = IERC20(tokenB).balanceOf(address(this));

        if(promotionCode != address(0)){
            (address rewardToken, uint256 rewardAmount) = IPromotionCodeManager(promotionCodeManager).getPromotionCodeDetail(promotionCode);
            
            require(rewardToken == tokenA || rewardToken == tokenB, "PromotionCodeAction: wrong promotion code");

            if(rewardToken == tokenA){
                tokenAInput = rewardAmount >= tokenAAmount ? 0 : tokenAAmount - rewardAmount;

                IPromotionCodeManager(promotionCodeManager).usePromotionCode(user, promotionCode, tokenId, rewardAmount >= tokenAAmount ? tokenAAmount : rewardAmount);
            }else{
                tokenBInput = rewardAmount >= tokenBAmount ? 0 : tokenBAmount - rewardAmount;

                IPromotionCodeManager(promotionCodeManager).usePromotionCode(user, promotionCode, tokenId, rewardAmount >= tokenBAmount ? tokenBAmount : rewardAmount);
            }
        }

        if(tokenAInput != 0){
            IERC20(tokenA).transferFrom(user, address(this), tokenAInput);
        }

        if(tokenBInput != 0){
            IERC20(tokenB).transferFrom(user, address(this), tokenBInput);
        }

        ISpartaDexRouter(router).addLiquidity(
            tokenA,
            tokenB,
            tokenAAmount,
            tokenBAmount,
            tokenAMin,
            tokenBMin,
            user,
            block.timestamp + 1 days
        );

        uint256 afterTokenABalance = IERC20(tokenA).balanceOf(address(this));
        uint256 afterTokenBBalance = IERC20(tokenB).balanceOf(address(this));

        uint256 tokenADiff = afterTokenABalance - beforeTokenABalance;
        uint256 tokenBDiff = afterTokenBBalance - beforeTokenBBalance;        

        if(tokenADiff != 0){
            IERC20(tokenA).transfer(user, tokenADiff);
        }
      
        if(tokenBDiff != 0){
            IERC20(tokenB).transfer(user, tokenBDiff);
        }
    }
}