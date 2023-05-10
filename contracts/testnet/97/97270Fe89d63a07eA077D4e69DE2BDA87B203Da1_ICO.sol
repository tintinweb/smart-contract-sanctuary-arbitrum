/**
 *Submitted for verification at Arbiscan on 2023-05-09
*/

// Sources flattened with hardhat v2.14.0 https://hardhat.org

// File @openzeppelin/contracts/utils/[email protected]

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


// File @openzeppelin/contracts/access/[email protected]

// OpenZeppelin Contracts (last updated v4.7.0) (access/Ownable.sol)

pragma solidity ^0.8.0;

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


// File @openzeppelin/contracts/security/[email protected]

// OpenZeppelin Contracts (last updated v4.8.0) (security/ReentrancyGuard.sol)

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
}


// File @openzeppelin/contracts/token/ERC20/[email protected]

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


// File contracts/ICO.sol

pragma solidity 0.8.18;



contract ICO is Ownable, ReentrancyGuard {
    // The token being sold
    IERC20 public saleToken;
    IERC20 public acceptToken;

    // Address where funds are collected
    address payable public wallet;
    uint8 public currentSale = 0;
    bool public isSaleLive;
    uint256 public totalTokenRelease;
    uint256 public totalUniqueAddress;

    uint256 public depositDeadline; //timestamp
    uint256 public cliff;
    uint256 public unlockPercentAtCliff;
    uint256 public unlockFrequency; // duration post cliff after which we unlock {unlockPercent} tokens
    uint256 public unlockPercent;
    uint256 public totalLockedTokens; // total tokens across all users
    uint256 public fundRaisedViaEth;
    uint256 public fundRaisedViaToken;

    struct Sale {
        bool lockIn;
        uint8 icoRate;
        uint256 startTime;
        uint256 endTime;
        uint256 minAmount;
        uint256 maxAmount;
        uint256 fundingTarget;
    }
    Sale[] public saleInfo;
    mapping(uint256 => uint256) public totalFunding;
    mapping(address => uint256) public fundingByAcccount;
    mapping(address => uint256) public depositAmount; //total deposited token by user
    mapping(address => uint256) public totalWithdrawnBalance; // total token withdrawn by user

    /**
     * Event for token purchase logging
     * @param purchaser who paid for the tokens
     * @param value weis paid for purchase
     * @param amount amount of tokens purchased
     */
    event TokenPurchase(
        address indexed purchaser,
        uint256 value,
        uint256 amount
    );

    event Deposit(
        address indexed sender,
        address indexed receiver,
        uint256 amount
    );

    event Withdraw(
        address indexed sender,
        address indexed receiver,
        uint256 amount
    );

    event UpdateLockInDeadLine(uint256 timelime);

    event SaleCreated(uint8 indexed saleId, Sale saleInfo);
    event SaleUpdated(uint8 indexed saleId, Sale saleInfo);

    /**
     * @param _wallet Address where collected funds will be forwarded to
     * @param _token Address of the token being sold
     */
    constructor(
        address _wallet,
        IERC20 _token,
        IERC20 _saleToken,
        uint256 _depositDeadline,
        uint256 _cliff,
        uint256 _unlockPercentAtCliff,
        uint256 _unlockFrequency,
        uint256 _unlockPercent
    ) {
        require(
            _wallet != address(0) &&
                address(_saleToken) != address(0) &&
                address(_token) != address(0),
            "Wallet address can't be zero address!"
        );
        require(
            address(_token) != address(_saleToken),
            "Sale and Accept token can't be the same!"
        );
        require(
            block.timestamp < _depositDeadline,
            "Deposit Deadline should be greator than current time"
        );
        require(
            _unlockPercentAtCliff > 0 && _unlockPercentAtCliff <= 100,
            "Values can't be zero and Percent values can't be more than 100"
        );

        wallet = payable(_wallet);
        acceptToken = _token;
        saleToken = _saleToken;

        depositDeadline = _depositDeadline;
        cliff = _cliff;
        unlockPercentAtCliff = _unlockPercentAtCliff;
        unlockFrequency = _unlockFrequency;
        unlockPercent = _unlockPercent;
    }

    modifier checkMinAndMaxAmount(uint256 amount) {
        require(
            amount >= saleInfo[currentSale].minAmount &&
                amount <= saleInfo[currentSale].maxAmount,
            "Amount does not meet min and max criteria!"
        );
        _;
    }

    modifier verifyAcceptTokenAllowance(uint256 amount) {
        require(
            IERC20(acceptToken).allowance(msg.sender, address(this)) >= amount,
            "Allowance is too low!"
        );
        _;
    }

    modifier isSaleActive() {
        require(
            isSaleLive && saleInfo[currentSale].endTime > block.timestamp,
            "Sale is not live or ended!"
        );
        _;
    }

    modifier capReached(uint256 _amount) {
        require(
            saleInfo[currentSale].fundingTarget >
                totalFunding[currentSale] + _amount,
            "Funding Target Wiil Be Reached, Try lesser amount!"
        );
        _;
    }

    function initiateSale(
        uint8 rate,
        uint256 startTime,
        uint256 endTime,
        uint256 minAmount,
        uint256 maxAmount,
        uint256 fundingTarget,
        bool lockin
    ) external onlyOwner {
        require(!isSaleLive, "Sale is live currently!");
        require(
            startTime > block.timestamp,
            "Start time should be more than current time!"
        );
        require(endTime > startTime, "Endtime can't be less then start time!");
        require(minAmount > 0, "Minimum Amount can't be zero!");
        require(
            maxAmount > minAmount,
            "Max amount can't be less than min amount!"
        );
        require(rate > 0, "Rate can't be zero!");
        require(fundingTarget > 0, "Funding target can't be zero!");
        saleInfo.push(
            Sale({
                startTime: startTime,
                endTime: endTime,
                minAmount: minAmount,
                maxAmount: maxAmount,
                fundingTarget: fundingTarget,
                icoRate: rate,
                lockIn: lockin
            })
        );
        currentSale = uint8(saleInfo.length - 1);
        emit SaleCreated(currentSale, saleInfo[currentSale]);
    }

    function updateAcceptToken(IERC20 _tokenAddress) external onlyOwner {
        require(address(_tokenAddress) != address(0));
        require(
            address(_tokenAddress) != address(saleToken),
            "Sale and Accept token can't be the same!"
        );
        acceptToken = _tokenAddress;
    }

    function updateSaleToken(IERC20 _tokenAddress) external onlyOwner {
        require(address(_tokenAddress) != address(0));
        require(
            address(_tokenAddress) != address(acceptToken),
            "Sale and Accept token can't be the same!"
        );
        saleToken = _tokenAddress;
    }

    function startSale() external onlyOwner returns (bool) {
        require(
            saleInfo[currentSale].startTime <= block.timestamp &&
                saleInfo[currentSale].endTime >= block.timestamp,
            "Sale time didn't match!"
        );
        isSaleLive = true;
        return true;
    }

    function endSale() external onlyOwner returns (bool) {
        isSaleLive = false;
        return true;
    }

    function updateRate(uint8 rate)
        external
        onlyOwner
        isSaleActive
        returns (bool)
    {
        require(rate > 0, "Rate can't be zero!");
        saleInfo[currentSale].icoRate = rate;
        emit SaleUpdated(currentSale, saleInfo[currentSale]);
        return true;
    }

    function extendSale(uint256 endTime)
        external
        onlyOwner
        isSaleActive
        returns (bool)
    {
        require(
            endTime > block.timestamp,
            "Sale end time should be more than current time!"
        );
        saleInfo[currentSale].endTime = endTime;
        emit SaleUpdated(currentSale, saleInfo[currentSale]);
        return true;
    }

    function updateLockInDeadLine(uint256 time) external onlyOwner {
        require(
            time > block.timestamp,
            "Lockin deadline time should be more than current time!"
        );
        emit UpdateLockInDeadLine(time);
        depositDeadline = time;
    }

    function buyToken(uint256 amount)
        external
        isSaleActive
        checkMinAndMaxAmount(amount)
        capReached(amount)
        verifyAcceptTokenAllowance(amount)
        nonReentrant
    {
        require(
            !saleInfo[currentSale].lockIn,
            "You're trying to buy in Lockin sale!"
        );
        uint256 tokens = saleInfo[currentSale].icoRate * amount;
        emit TokenPurchase(msg.sender, amount, tokens);
        totalFunding[currentSale] += amount;
        fundRaisedViaToken += amount;
        if (fundingByAcccount[msg.sender] == 0) {
            totalUniqueAddress++;
        }
        fundingByAcccount[msg.sender] += amount;
        totalTokenRelease += tokens;
        require(
            IERC20(acceptToken).transferFrom(msg.sender, wallet, amount),
            "Transfer Failed!"
        );

        require(
            IERC20(saleToken).transferFrom(wallet, msg.sender, tokens),
            "Transfer Failed!"
        );
    }

    function buyTokenWithEth()
        public
        payable
        isSaleActive
        checkMinAndMaxAmount(msg.value)
        capReached(msg.value)
    {
        require(
            !saleInfo[currentSale].lockIn,
            "You're trying to buy in Lockin sale!"
        );
        uint256 amount = msg.value;
        uint256 tokens = saleInfo[currentSale].icoRate * amount;
        emit TokenPurchase(msg.sender, amount, tokens);
        totalFunding[currentSale] += amount;
        fundRaisedViaEth += amount;
        if (fundingByAcccount[msg.sender] == 0) {
            totalUniqueAddress++;
        }
        fundingByAcccount[msg.sender] += amount;
        totalTokenRelease += tokens;

        _forwardFunds();
        require(
            IERC20(saleToken).transferFrom(wallet, msg.sender, tokens),
            "Transfer Failed!"
        );
    }

    function buyTokenWithLockIn(uint256 amount)
        external
        isSaleActive
        checkMinAndMaxAmount(amount)
        capReached(amount)
        verifyAcceptTokenAllowance(amount)
        nonReentrant
    {
        require(
            saleInfo[currentSale].lockIn,
            "You're trying to buy lock tokens!"
        );
        require(block.timestamp < depositDeadline, "deposit period over!");
        uint256 tokens = saleInfo[currentSale].icoRate * amount;
        emit TokenPurchase(msg.sender, amount, tokens);
        emit Deposit(msg.sender, address(this), amount);
        totalFunding[currentSale] += amount;
        fundRaisedViaToken += amount;
        if (fundingByAcccount[msg.sender] == 0) {
            totalUniqueAddress++;
        }
        fundingByAcccount[msg.sender] += amount;
        totalTokenRelease += tokens;
        depositAmount[msg.sender] += amount; //user balance updated
        totalLockedTokens += amount; // total contract tokens updated
        require(
            IERC20(acceptToken).transferFrom(msg.sender, wallet, amount),
            "Transfer Failed!"
        );
        require(
            IERC20(saleToken).transferFrom(wallet, address(this), amount),
            "Transfer Failed!"
        );
    }

    function buyTokenWithLockInWithEth()
        external
        payable
        isSaleActive
        checkMinAndMaxAmount(msg.value)
        capReached(msg.value)
    {
        require(
            saleInfo[currentSale].lockIn,
            "You're trying to buy lock tokens!"
        );
        require(block.timestamp < depositDeadline, "deposit period over!");
        uint256 amount = msg.value;
        uint256 tokens = saleInfo[currentSale].icoRate * amount;
        emit TokenPurchase(msg.sender, amount, tokens);
        emit Deposit(msg.sender, address(this), amount);
        totalFunding[currentSale] += amount;
        fundRaisedViaEth += amount;
        if (fundingByAcccount[msg.sender] == 0) {
            totalUniqueAddress++;
        }
        fundingByAcccount[msg.sender] += amount;
        totalTokenRelease += tokens;
        depositAmount[msg.sender] += amount; //user balance updated
        totalLockedTokens += amount; // total contract tokens updated

        _forwardFunds();
        require(
            IERC20(saleToken).transferFrom(wallet, address(this), amount),
            "Transfer Failed!"
        );
    }

    function withdraw(uint256 userRequestedWithdrawAmount) external {
        require(
            block.timestamp > depositDeadline,
            "Withdraw period not started!"
        );

        uint256 netWithdrawable = getNetWithdrawableBalance(msg.sender);

        require(
            netWithdrawable >= userRequestedWithdrawAmount,
            "Requested amount is higher than net withdrawable amount OR user has already withdrawn all the depositAmount"
        );

        emit Withdraw(address(this), msg.sender, userRequestedWithdrawAmount);
        // Withdraw available amount
        totalWithdrawnBalance[msg.sender] += userRequestedWithdrawAmount;
        totalLockedTokens -= userRequestedWithdrawAmount;

        require(
            IERC20(saleToken).transfer(msg.sender, userRequestedWithdrawAmount),
            "Transfer Failed!"
        );
    }

    function _forwardFunds() internal {
        wallet.transfer(msg.value);
    }

    function withdrawEth() external onlyOwner {
        wallet.transfer(address(this).balance);
    }

    receive() external payable {}

    fallback() external {}

    //Calculate netWithdrawable amount for a user
    function getNetWithdrawableBalance(address userAddress)
        public
        view
        returns (uint256)
    {
        uint256 currentWithdrawableBalance = getCurrentUnlockedBalance(
            userAddress
        );
        uint256 netWithdrawable = currentWithdrawableBalance -
            totalWithdrawnBalance[userAddress];
        return netWithdrawable;
    }

    // Calculate total unlocked balance of a user (including already withdrawn)
    function getCurrentUnlockedBalance(address userAddress)
        public
        view
        returns (uint256)
    {
        uint256 totalPercentUnlocked = 0;
        uint256 totalBalance = depositAmount[userAddress];
        uint256 unlockTime = depositDeadline + cliff; //Time at end of cliff

        //when the ico has not ended yet
        if (block.timestamp < unlockTime) {
            return 0;
        }

        if (unlockFrequency > 0) {
            totalPercentUnlocked =
                unlockPercentAtCliff +
                (((block.timestamp - unlockTime) * unlockPercent) /
                    unlockFrequency);
        } else if (unlockFrequency == 0) {
            totalPercentUnlocked = unlockPercentAtCliff;
        }

        if (totalPercentUnlocked > 100) totalPercentUnlocked = 100;
        return (totalPercentUnlocked * totalBalance) / 100;
    }

    //balance of tokens erc20
    function checkBalance() external view returns (uint256) {
        return IERC20(saleToken).balanceOf(msg.sender);
    }

    function checkAcceptTokenBalance() external view returns (uint256) {
        return IERC20(acceptToken).balanceOf(msg.sender);
    }

    function tokenReceivedAsPerRate(uint256 amount)
        external
        view
        returns (uint256)
    {
        return saleInfo[currentSale].icoRate * amount;
    }
}