/**
 *Submitted for verification at Arbiscan on 2023-01-19
*/

// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.0;

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
abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
}
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


contract LaunchPad is Ownable {
    event BuyEvent(uint poolId, address to, uint amount, uint price);

    // pool datas
    struct Pool {
        address owner;
        // terms
        address tokenAddress;
        address paymentToken;
        uint tokenAmount;
        uint price;
        uint startTime;
        uint endTime;
        bool isPublicSale;
        // cap
        uint hardCap;
        // amount
        uint minAmountPerWallet;
        uint maxAmountPerWallet;
        // user data
        uint saledAmount;
        uint raisedAmount;
        mapping(address => bool) isWhiteList;
        mapping(address => uint) spots;
    }
    mapping(uint => Pool) public pools;

    // modifiers
    modifier onlyPoolOwner(uint id) {
        require(msg.sender == pools[id].owner, "You don't have permission");
        _;
    }

    modifier onlyOnSales(uint id) {
        require(
            pools[id].startTime <= block.timestamp &&
                block.timestamp <= pools[id].endTime,
            "Is not on sales"
        );
        require(
            pools[id].saledAmount < pools[id].hardCap,
            "sale is already success"
        );
        _;
    }

    modifier onlyOnSaleEnded(uint id) {
        require(
            block.timestamp > pools[id].endTime ||
                pools[id].saledAmount >= pools[id].hardCap,
            "sale is not ended"
        );
        _;
    }

    // global datas
    uint cPoolCount = 0;
    address public WETH;

    // check if payment token is ETH
    function setETH(address wethAddress) external onlyOwner {
        WETH = wethAddress;
    }

    function checkETH(address tokenAddress) public view returns (bool) {
        return tokenAddress == WETH;
    }

    // create new pool
    function createPool(
        address tokenAddress,
        address paymentToken,
        uint tokenAmount,
        uint price, // decimal 1e6
        uint startTime,
        uint period,
        bool isPublicSale,
        uint hardCap,
        uint minAmountPerWallet,
        uint maxAmountPerWallet
    ) public {
        pools[cPoolCount].owner = msg.sender;
        pools[cPoolCount].tokenAddress = tokenAddress;
        pools[cPoolCount].paymentToken = paymentToken;
        pools[cPoolCount].tokenAmount = tokenAmount;
        pools[cPoolCount].price = price;
        pools[cPoolCount].startTime = block.timestamp + startTime;
        pools[cPoolCount].endTime = block.timestamp + startTime + period;
        pools[cPoolCount].isPublicSale = isPublicSale;
        pools[cPoolCount].hardCap = hardCap;
        pools[cPoolCount].minAmountPerWallet = minAmountPerWallet;
        pools[cPoolCount].maxAmountPerWallet = maxAmountPerWallet;

        IERC20(tokenAddress).transferFrom(
            msg.sender,
            address(this),
            tokenAmount
        );
        cPoolCount++;
    }

    // admin action
    // white list

    function addWhiteLists(
        uint poolId,
        address[] calldata tos,
        bool[] calldata isWLs
    ) public onlyPoolOwner(poolId) {
        require(tos.length == isWLs.length, "Invalid parameters");
        for (uint i = 0; i < tos.length; i++) {
            pools[poolId].isWhiteList[tos[i]] = isWLs[i];
        }
    }

    function isInWhiteList(uint poolId, address to) public view returns (bool) {
        if (pools[poolId].isPublicSale) return true;
        return pools[poolId].isWhiteList[to];
    }

    function withdraw(uint poolId)
        external
        onlyPoolOwner(poolId)
        onlyOnSaleEnded(poolId)
    {
        uint raisedAmount = pools[poolId].raisedAmount;
        pools[poolId].raisedAmount = 0;
        if (checkETH(pools[poolId].paymentToken)) {
            payable(msg.sender).transfer(raisedAmount);
        } else {
            IERC20(pools[poolId].paymentToken).transfer(
                msg.sender,
                raisedAmount
            );
        }
    }

    function claimRestToken(uint poolId)
        external
        onlyPoolOwner(poolId)
        onlyOnSaleEnded(poolId)
    {
        uint restAmount = pools[poolId].tokenAmount - pools[poolId].saledAmount;
        pools[poolId].tokenAmount = pools[poolId].saledAmount;
        IERC20(pools[poolId].tokenAddress).transfer(msg.sender, restAmount);
    }

    // user action
    function buy(uint poolId, uint amount)
        external
        payable
        onlyOnSales(poolId)
    {
        uint paymentAmount = (amount * pools[poolId].price) / 1e6;
        require(isInWhiteList(poolId, msg.sender), "You are not in WL");
        require(
            pools[poolId].minAmountPerWallet < amount &&
                amount + pools[poolId].spots[msg.sender] <=
                pools[poolId].maxAmountPerWallet,
            "Invalid Amount"
        );
        if (checkETH(pools[poolId].paymentToken)) {
            require(msg.value >= paymentAmount, "Invalid payment amount");
        } else {
            IERC20(pools[poolId].paymentToken).transferFrom(
                msg.sender,
                address(this),
                paymentAmount
            );
        }
        // update user spot, raised amount, saled amount
        pools[poolId].spots[msg.sender] += amount;
        pools[poolId].saledAmount += amount;
        pools[poolId].raisedAmount += paymentAmount;
        emit BuyEvent(poolId, msg.sender, amount, pools[poolId].price);
    }

    function claim(uint poolId) external onlyOnSaleEnded(poolId) {
        uint spotAmount = pools[poolId].spots[msg.sender];
        pools[poolId].spots[msg.sender] = 0;
        IERC20(pools[poolId].tokenAddress).transfer(msg.sender, spotAmount);
    }

    function emergencyWithdraw(address tokenAddress, uint amount)
        external
        onlyOwner
    {
        if (checkETH(tokenAddress)) {
            payable(msg.sender).transfer(amount);
        } else {
            IERC20(tokenAddress).transfer(msg.sender, amount);
        }
    }
}