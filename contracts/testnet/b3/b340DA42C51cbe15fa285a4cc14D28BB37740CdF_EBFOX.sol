/**
 *Submitted for verification at Arbiscan.io on 2023-12-08
*/

//SPDX-License-Identifier: MIT
pragma solidity 0.8.20;

library SafeMath {
    /**
     * @dev Returns the addition of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `+` operator.
     *
     * Requirements:
     *
     * - Addition cannot overflow.
     */
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");

        return c;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting on
     * overflow (when the result is negative).
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return sub(a, b, "SafeMath: subtraction overflow");
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting with custom message on
     * overflow (when the result is negative).
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b <= a, errorMessage);
        uint256 c = a - b;

        return c;
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `*` operator.
     *
     * Requirements:
     *
     * - Multiplication cannot overflow.
     */
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
        // benefit is lost if 'b' is also tested.
        // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
        if (a == 0) {
            return 0;
        }

        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");

        return c;
    }

    /**
     * @dev Returns the integer division of two unsigned integers. Reverts on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return div(a, b, "SafeMath: division by zero");
    }

    /**
     * @dev Returns the integer division of two unsigned integers. Reverts with custom message on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b > 0, errorMessage);
        uint256 c = a / b;
        // assert(a == b * c + a % b); // There is no case in which this doesn't hold

        return c;
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * Reverts when dividing by zero.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return mod(a, b, "SafeMath: modulo by zero");
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * Reverts with custom message when dividing by zero.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b != 0, errorMessage);
        return a % b;
    }
}

/**
 * @title Owner
 * @dev Set & change owner
 */
contract Ownable {

    address private owner;
    
    // event for EVM logging
    event OwnerSet(address indexed oldOwner, address indexed newOwner);
    
    // modifier to check if caller is owner
    modifier onlyOwner() {
        // If the first argument of 'require' evaluates to 'false', execution terminates and all
        // changes to the state and to Ether balances are reverted.
        // This used to consume all gas in old EVM versions, but not anymore.
        // It is often a good idea to use 'require' to check if functions are called correctly.
        // As a second argument, you can also provide an explanation about what went wrong.
        require(msg.sender == owner, "Caller is not owner");
        _;
    }
    
    /**
     * @dev Set contract deployer as owner
     */
    constructor() {
        owner = msg.sender; // 'msg.sender' is sender of current call, contract deployer for a constructor
        emit OwnerSet(address(0), owner);
    }

    /**
     * @dev Change owner
     * @param newOwner address of new owner
     */
    function changeOwner(address newOwner) public onlyOwner {
        emit OwnerSet(owner, newOwner);
        owner = newOwner;
    }

    /**
     * @dev Return owner address 
     * @return address of owner
     */
    function getOwner() external view returns (address) {
        return owner;
    }
}

interface IERC20 {

    function totalSupply() external view returns (uint256);
    
    function symbol() external view returns(string memory);
    
    function name() external view returns(string memory);

    /**
     * @dev Returns the amount of tokens owned by `account`.
     */
    function balanceOf(address account) external view returns (uint256);
    
    /**
     * @dev Returns the number of decimal places
     */
    function decimals() external view returns (uint8);

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

interface IFOX {
    function burn(uint256 amount) external;
}

contract EBFOX is Ownable, IERC20 {

    using SafeMath for uint256;

    // Staking Token
    IERC20 public immutable token;

    // Staking Protocol Token Info
    string private constant _name = "ebFOX";
    string private constant _symbol = "ebFOX";
    uint8 private immutable _decimals;

    // Trackable User Info
    struct UserInfo {
        uint256 balance;
        uint256 totalStaked;
        uint256 totalWithdrawn;
        bool isFeeExempt;
    }
    // User -> UserInfo
    mapping ( address => UserInfo ) public userInfo;

    // total supply of MAXI
    uint256 private _totalSupply;

    // Swapper To Purchase Token From ETH
    address public tokenSwapper;

    // precision factor
    uint256 private constant precision = 10**18;

    // Mint and Redeem fee
    uint256 public entryFee = 100;
    uint256 public exitFee = 150;
    uint256 public burnFeePercentage = 500;
    uint256 private constant FEE_DENOM = 1_000;

    // Reduced Mint Fee
    uint256 public reducedEntryFee = 0;

    // Pauses people from entering
    bool public paused;

    // Reentrancy Guard
    uint256 private constant _NOT_ENTERED = 1;
    uint256 private constant _ENTERED = 2;
    uint256 private _status;
    modifier nonReentrant() {
        require(_status != _ENTERED, "Reentrancy Guard call");
        _status = _ENTERED;
        _;
        _status = _NOT_ENTERED;
    }

    // Events
    event Deposit(address depositor, uint256 amountToken);
    event Withdraw(address withdrawer, uint256 amountToken);
    event FeeTaken(uint256 fee);

    constructor(
        address token_
    ) {

        require(token_ != address(0), 'Zero Address');

        // pair token data
        _decimals = IERC20(token_).decimals();

        // pair staking token
        token = IERC20(token_);

        // set reentrancy
        _status = _NOT_ENTERED;

        // Pause
        paused = true;
        
        // emit transfer so bscscan registers contract as token
        emit Transfer(address(0), msg.sender, 0);
    }

    function name() external pure override returns (string memory) {
        return _name;
    }
    function symbol() external pure override returns (string memory) {
        return _symbol;
    }
    function decimals() external view override returns (uint8) {
        return _decimals;
    }
    function totalSupply() external view override returns (uint256) {
        return token.balanceOf(address(this));
    }

    /** Shows The Value Of Users' Staked Token */
    function balanceOf(address account) public view override returns (uint256) {
        return ReflectionsFromContractBalance(userInfo[account].balance);
    }

    function transfer(address recipient, uint256 amount) external override returns (bool) {
        if (recipient == msg.sender) {
            withdraw(amount);
        }
        return true;
    }
    function transferFrom(address, address recipient, uint256 amount) external override returns (bool) {
        if (recipient == msg.sender) {
            withdraw(amount);
        }
        return true;
    }

    function setPaused(bool isPaused) external onlyOwner {
        paused = isPaused;
    }

    function setReducedEntryFee(uint256 newFee) external onlyOwner {
        require(
            newFee <= FEE_DENOM,
            'Fee Overflow'
        );
        reducedEntryFee = newFee;
    }

    function setEntryFee(uint256 newFee) external onlyOwner {
        require(
            newFee < FEE_DENOM,
            'Fee Overflow'
        );
        entryFee = newFee;
    }

    function setExitFee(uint256 newFee) external onlyOwner {
        require(
            newFee < FEE_DENOM,
            'Fee Overflow'
        );
        exitFee = newFee;
    }

    function setBurnFeePercentage(uint256 newFee) external onlyOwner {
        require(
            newFee <= FEE_DENOM,
            'Fee Overflow'
        );
        burnFeePercentage = newFee;
    }

    function setTokenSwapper(address newTokenSwapper) external onlyOwner {
        require(
            newTokenSwapper != address(0),
            'Zero Address'
        );
        tokenSwapper = newTokenSwapper;
    }

    function setFeeExempt(address user, bool isExempt) external onlyOwner {
        userInfo[user].isFeeExempt = isExempt;
    }

    function withdrawETH(address to, uint256 amount) external onlyOwner {
        (bool s,) = payable(to).call{value: amount}("");
        require(s, 'Error On ETH Withdrawal');
    }

    function recoverForeignToken(IERC20 _token) external onlyOwner {
        require(
            address(_token) != address(token),
            'Cannot Withdraw Staking Tokens'
        );
        require(
            _token.transfer(msg.sender, _token.balanceOf(address(this))),
            'Error Withdrawing Foreign Token'
        );
    }

    function depositForBatch(address[] calldata users, uint256[] calldata amounts) external onlyOwner {
        require(users.length == amounts.length, "Users and amounts length mismatch");

        for (uint256 i = 0; i < users.length; i++) {
            _depositFor(users[i], amounts[i]);
        }
    }


    function depositFor(address user, uint256 amount) external onlyOwner {
        _depositFor(user, amount);
    }


    function _depositFor(address user, uint256 amount) internal {
        // Track Balance Before Deposit
        uint previousBalance = token.balanceOf(address(this));

        // Transfer In Token
        uint received = _transferIn(amount);

        // Take Deposit
        uint fee = userInfo[user].isFeeExempt ? 0 : _takeFee(received, true, false);

        // send amount less fee
        uint256 reallyReceived = received.sub(fee);

        // mint tokens
        if (_totalSupply == 0 || previousBalance == 0) {
            _registerFirstPurchase(user, reallyReceived);
        } else {
            _mintTo(user, reallyReceived, previousBalance);
        }
    }



    /** Native Sent To Contract Will Buy And Stake Token
        Standard Token Purchase Rates Still Apply
     */
    receive() external payable {}

    /** Buy in with Native */
    function depositWithNative(uint256 minOut) external payable nonReentrant {
        require(
            paused == false,
            'PAUSED'
        );

        // Track Balance Before Deposit
        uint previousBalance = token.balanceOf(address(this));

        // buy token
        uint256 received = _buyToken(msg.value);
        require(received >= minOut, 'ERR: MINOUT');

        // Take Deposit
        uint fee = userInfo[msg.sender].isFeeExempt ? 0 : _takeFee(received, true, true);

        // send amount less fee
        uint256 reallyReceived = received - fee;

        // mint tokens
        if (_totalSupply == 0 || previousBalance == 0) {
            _registerFirstPurchase(msg.sender, reallyReceived);
        } else {
            _mintTo(msg.sender, reallyReceived, previousBalance);
        }
    }

    /**
        Transfers in `amount` of Token From Sender
        And Locks In Contract, Minting MAXI Tokens
     */
    function deposit(uint256 amount) external nonReentrant {
        require(
            paused == false,
            'PAUSED'
        );

        // Track Balance Before Deposit
        uint previousBalance = token.balanceOf(address(this));

        // Transfer In Token
        uint received = _transferIn(amount);

        // Take Deposit
        uint fee = userInfo[msg.sender].isFeeExempt ? 0 : _takeFee(received, true, false);

        // send amount less fee
        uint256 reallyReceived = received - fee;

        // mint tokens
        if (_totalSupply == 0 || previousBalance == 0) {
            _registerFirstPurchase(msg.sender, reallyReceived);
        } else {
            _mintTo(msg.sender, reallyReceived, previousBalance);
        }
    }

    /**
        Redeems `amount` of Underlying Tokens, As Seen From BalanceOf()
     */
    function withdraw(uint256 amount) public nonReentrant returns (uint256) {

        // Token Amount Into Contract Balance Amount
        uint MAXI_Amount = amount == balanceOf(msg.sender) ? userInfo[msg.sender].balance : TokenToContractBalance(amount);

        require(
            userInfo[msg.sender].balance > 0 &&
            userInfo[msg.sender].balance >= MAXI_Amount &&
            balanceOf(msg.sender) >= amount &&
            amount > 0 &&
            MAXI_Amount > 0,
            'Insufficient Funds'
        );

        // burn MAXI Tokens From Sender
        _burn(msg.sender, MAXI_Amount, amount);

        // increment total withdrawn
        unchecked {
            userInfo[msg.sender].totalWithdrawn += amount;
        }

        // Take Exit Fee
        uint fee = userInfo[msg.sender].isFeeExempt ? 0 : _takeFee(amount, false, false);

        // send amount less fee
        uint256 sendAmount = amount - fee;
        uint256 balance = token.balanceOf(address(this));
        if (sendAmount > balance) {
            sendAmount = balance;
        }
        
        // transfer token to sender
        require(
            token.transfer(msg.sender, sendAmount),
            'Error On Token Transfer'
        );

        emit Withdraw(msg.sender, sendAmount);
        return sendAmount;
    }

    function donate() external payable nonReentrant {
        require(
            _totalSupply > 0,
            'Zero Shares'
        );
        // apply burn + fees
        uint256 amount = _buyToken(msg.value);
        uint256 burnAmount = ( amount * burnFeePercentage ) / FEE_DENOM;
        if (burnAmount > 0) {
            IFOX(address(token)).burn(burnAmount);
        }
    }

    function giveRewards(uint256 amount) external nonReentrant {
        require(
            _totalSupply > 0,
            'Zero Shares'
        );
        // apply burn + fees
        uint256 tAmount = _transferIn(amount);
        uint256 burnAmount = ( tAmount * burnFeePercentage ) / FEE_DENOM;
        if (burnAmount > 0) {
            IFOX(address(token)).burn(burnAmount);
        }
    }

    /**
        Registers the First Stake
     */
    function _registerFirstPurchase(address user, uint received) internal {
        
        // increment total staked
        userInfo[user].totalStaked += received;

        // mint MAXI Tokens To Sender
        _mint(user, received, received);

        emit Deposit(user, received);
    }


    function _takeFee(uint256 amount, bool _deposit, bool reduced) internal returns (uint256) {

        // calculate fee
        uint256 fee = 0;

        // calculate fee for deposit vs withdrawal
        if (_deposit) {
            if (reduced) {
                fee = ( amount * reducedEntryFee ) / FEE_DENOM;
            } else {
                fee = ( amount * entryFee ) / FEE_DENOM;
            }
        } else {
            fee = ( amount * exitFee ) / FEE_DENOM;
        }

        // burn percentage of fee
        uint256 burnAmount = ( fee * burnFeePercentage ) / FEE_DENOM;
        if (burnAmount > 0) {
            IFOX(address(token)).burn(burnAmount);
        }

        // burn and reflect
        emit FeeTaken(fee);
        return fee;
    }

    function _mintTo(address sender, uint256 received, uint256 previousBalance) internal {
        // Number Of Maxi Tokens To Mint
        uint nToMint = (_totalSupply.mul(received).div(previousBalance)).sub(10);
        require(
            nToMint > 0,
            'Zero To Mint'
        );

        // increment total staked
        userInfo[sender].totalStaked += received;

        // mint MAXI Tokens To Sender
        _mint(sender, nToMint, received);

        emit Deposit(sender, received);
    }

    function _buyToken(uint amount) internal returns (uint256) {
        require(
            amount > 0,
            'Zero Amount'
        );
        uint before = token.balanceOf(address(this));
        (bool s,) = payable(tokenSwapper).call{value: amount}("");
        require(s, 'Failure On Token Purchase');
        uint received = token.balanceOf(address(this)).sub(before);
        require(received > 0, 'Zero Received');
        return received;
    }

    function _transferIn(uint256 amount) internal returns (uint256) {
        require(
            token.allowance(msg.sender, address(this)) >= amount,
            'Insufficient Allowance'
        );
        require(
            token.balanceOf(msg.sender) >= amount,
            'Insufficient Balance'
        );

        // transfer in token, taking note of balance changes
        uint before = token.balanceOf(address(this));
        require(
            token.transferFrom(msg.sender, address(this), amount),
            'Failure On TransferFrom'
        );
        uint After = token.balanceOf(address(this));
        require(
            After > before,
            'Error On Transfer In'
        );

        // return the amount that was received
        return After - before;
    }

    /**
     * Burns `amount` of Contract Balance Token
     */
    function _burn(address from, uint256 amount, uint256 amountToken) private {
        userInfo[from].balance = userInfo[from].balance.sub(amount);
        _totalSupply = _totalSupply.sub(amount);
        emit Transfer(from, address(0), amountToken);
    }

    /**
     * Mints `amount` of Contract Balance Token
     */
    function _mint(address to, uint256 amount, uint256 stablesWorth) private {
        // allocate
        userInfo[to].balance = userInfo[to].balance.add(amount);
        _totalSupply = _totalSupply.add(amount);
        emit Transfer(address(0), to, stablesWorth);
    }


    /**
        Converts A Staking Token Amount Into A MAXI Amount
     */
    function TokenToContractBalance(uint256 amount) public view returns (uint256) {
        return amount.mul(precision).div(_calculatePrice());
    }

    /**
        Converts A MAXI Amount Into An Token Amount
     */
    function ReflectionsFromContractBalance(uint256 amount) public view returns (uint256) {
        return amount.mul(_calculatePrice()).div(precision);
    }

    /** Conversion Ratio For MAXI -> Token */
    function calculatePrice() external view returns (uint256) {
        return _calculatePrice();
    }

    /** Returns Total Profit for User In Token From MAXI */
    function getTotalProfits(address user) external view returns (uint256) {
        uint top = balanceOf(user) + userInfo[user].totalWithdrawn;
        return top <= userInfo[user].totalStaked ? 0 : top - userInfo[user].totalStaked;
    }
    
    /** Conversion Ratio For MAXI -> Token */
    function _calculatePrice() internal view returns (uint256) {
        uint256 backingValue = token.balanceOf(address(this));
        return (backingValue.mul(precision)).div(_totalSupply);
    }

    /** function has no use in contract */
    function allowance(address, address) external pure override returns (uint256) { 
        return 0;
    }
    /** function has no use in contract */
    function approve(address spender, uint256) public override returns (bool) {
        emit Approval(msg.sender, spender, 0);
        return true;
    }
}