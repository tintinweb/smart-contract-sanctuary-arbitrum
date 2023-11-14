/**
 *Submitted for verification at Arbiscan.io on 2023-11-03
*/

//SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

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

interface INFT {
    function ownerOf(uint256 tokenId) external view returns (address);
}

contract FoxifyMaxi is Ownable, IERC20 {

    using SafeMath for uint256;

    // Staking Token
    IERC20 public immutable token;

    // NFT Contract Address
    address public immutable nft;

    // Staking Protocol Token Info
    string private constant _name = "Foxify MAXI";
    string private constant _symbol = "FoxifyMAXI";
    uint8 private immutable _decimals;

    // Trackable User Info
    struct UserInfo {

        // standard user info
        uint256 balance; // cumulative of staked amount, total vested amount, and nonwithdrawable amount
        uint256 unlockBlock;
        uint256 totalStaked;
        uint256 totalWithdrawn;        

        // staked user info
        uint256 startTime;
        uint256 lastUpdated;
        uint256 duration;
        uint256 remainingVest;
        uint256 totalVestedAtStart;
        uint256 totalNonWithdrawable;
    }

    // User -> UserInfo
    mapping ( address => UserInfo ) public userInfo;

    // NFT ID -> UserInfo
    mapping ( uint256 => UserInfo ) public nftInfo;

    // Unstake Early Fee
    uint256 public leaveEarlyFee;

    // Unstake Early Fee Recipient
    address public leaveEarlyFeeRecipient;

    // Timer For Leave Early Fee
    uint256 public leaveEarlyFeeTimer;

    // total supply of MAXI
    uint256 private _totalSupply;

    // Pause Deposits and Withdraws
    bool public paused;

    // precision factor
    uint256 private constant precision = 10**18;

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

    modifier ownsNFTs(uint256[] calldata ids) {
        if (msg.sender == this.getOwner()) {
            _;
        } else {
            uint len = ids.length;
            for (uint i = 0; i < len;) {
                require(
                    INFT(nft).ownerOf(ids[i]) == msg.sender,
                    'Not NFT Owner'
                );
                unchecked { ++i; }
            }
            _;
        }
    }

    // Events
    event Deposit(address depositor, uint256 amountToken);
    event Withdraw(address withdrawer, uint256 amountToken);
    event FeeTaken(uint256 fee);

    constructor(
        address token_,
        address nft_
    ) {
        require(token_ != address(0), 'Zero Address');

        // pair token data
        _decimals = IERC20(token_).decimals();

        // staking data
        leaveEarlyFeeRecipient = msg.sender;
        leaveEarlyFee = 0;
        leaveEarlyFeeTimer = 0;

        // pair staking token
        token = IERC20(token_);

        // set NFT address
        nft = nft_;

        // set reentrancy
        _status = _NOT_ENTERED;
        
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

    function balanceOfNFT(uint256 id) public view returns (uint256) {
        return ReflectionsFromContractBalance(nftInfo[id].balance);
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


    ////////////////////////////////////////////////////////////
    //////////////      OWNER FUNCTIONS        /////////////////
    ////////////////////////////////////////////////////////////
    


    function setLeaveEarlyFee(uint256 newLeaveEarlyFee) external onlyOwner {
        require(
            newLeaveEarlyFee <= 500,
            'Early Fee Too High'
        );
        leaveEarlyFee = newLeaveEarlyFee;
    }
    function setLeaveEarlyFeeRecipient(address newLeaveEarlyFeeRecipient) external onlyOwner {
        require(
            newLeaveEarlyFeeRecipient != address(0),
            'Zero Address'
        );
        leaveEarlyFeeRecipient = newLeaveEarlyFeeRecipient;
    }
    function setLeaveEarlyFeeTimer(uint256 newLeaveEarlyFeeTimer) external onlyOwner {
        require(
            newLeaveEarlyFeeTimer <= 10**8,
            'Fee Timer Too High'
        );
        leaveEarlyFeeTimer = newLeaveEarlyFeeTimer;
    }

    function withdrawBNB() external onlyOwner {
        (bool s,) = payable(msg.sender).call{value: address(this).balance}("");
        require(s, 'Error On BNB Withdrawal');
    }

    function recoverForeignToken(IERC20 _token) external onlyOwner {
        require(
            _token.transfer(msg.sender, _token.balanceOf(address(this))),
            'Error Withdrawing Foreign Token'
        );
    }

    function setPaused(bool isPaused) external onlyOwner {
        paused = isPaused;
    }

    function setBatchVestingScheduleData(
        uint256[] calldata amount, 
        address[] calldata user,
        uint256[] calldata startTime,
        uint256[] calldata duration,
        uint256[] calldata remainingVests,
        uint256[] calldata totalNonWithdrawable
    ) external onlyOwner {
        uint len = amount.length;
        for (uint i = 0; i < len;) {
            setVestingScheduleData(amount[i], user[i], startTime[i], duration[i], remainingVests[i], totalNonWithdrawable[i]);
            unchecked { ++i; }
        }
    }

    function setBatchNFTData(
        uint256[] calldata amount, 
        uint256 startID,
        uint256 endID,
        uint256[] calldata startTime,
        uint256[] calldata duration,
        uint256[] calldata remainingVests,
        uint256[] calldata totalNonWithdrawable
    ) external onlyOwner {
        for (uint i = startID; i < endID;) {
            
            // Track Balance Before Deposit
            uint previousBalance = token.balanceOf(address(this));

            // Transfer In Token
            uint received = _transferIn(amount[i]);

            if (_totalSupply == 0 || previousBalance == 0) {
                _registerFirstPurchaseNFT(i, received);
            } else {
                _mintToNFT(i, received, previousBalance);
            }

            // set staking info
            nftInfo[i].startTime = startTime[i];
            nftInfo[i].lastUpdated = block.timestamp;
            nftInfo[i].duration = duration[i];
            nftInfo[i].remainingVest += remainingVests[i];
            nftInfo[i].totalVestedAtStart += remainingVests[i];
            nftInfo[i].totalNonWithdrawable += totalNonWithdrawable[i];

            unchecked { ++i; }
        }
    }

    function editUserTotalUnwithdrawable(
        address user,
        uint256 newUnwithdrawable
    ) external onlyOwner {
        require(
            balanceOf(user) >= newUnwithdrawable,
            'Cannot Set To Be Higher Than Balance'
        );
        userInfo[user].totalNonWithdrawable = newUnwithdrawable;
    }

    function editNFTTotalUnwithdrawable(
        uint256[] calldata ids,
        uint256 newUnwithdrawable
    ) external onlyOwner {

        for (uint i = 0; i < ids.length; i++) {
            require(
                balanceOfNFT(ids[i]) >= newUnwithdrawable,
                'Cannot Set To Be Higher Than Balance'
            );
            nftInfo[ids[i]].totalNonWithdrawable = newUnwithdrawable;
        }
    }

    function removeVester(address vester) external onlyOwner {
        if (isVesting(vester)) {
            
            // clear data
            uint remaining = userInfo[vester].remainingVest;
            delete userInfo[vester].remainingVest;
            delete userInfo[vester].duration;
            delete userInfo[vester].lastUpdated;
            delete userInfo[vester].startTime;

            // burn the remaining amount from their maxi balance
            uint256 maxiAmount = TokenToContractBalance(remaining);
            _burn(vester, maxiAmount, remaining);

            // increment total withdrawn
            unchecked {
                userInfo[vester].totalWithdrawn += remaining;
            }

            // transfer their share to the owner
            require(
                token.transfer(msg.sender, remaining),
                'Error On Token Transfer'
            );

            emit Withdraw(vester, remaining);
        }
    }


    ////////////////////////////////////////////////////////////
    //////////////      PUBLIC FUNCTIONS        ////////////////
    ////////////////////////////////////////////////////////////

    function updateVesting() external nonReentrant {
        _updateVesting(msg.sender);
    }

    function updateVestingNFT(uint256[] calldata ids) external ownsNFTs(ids) nonReentrant {
        for (uint i = 0; i < ids.length; i++) {
            _updateVestingNFT(ids[i]);
        }
    }

    receive() external payable {}

    /**
        Transfers in `amount` of Token From Sender
        And Locks In Contract, Minting MAXI Tokens
     */
    function deposit(uint256 amount) external nonReentrant {
        require(
            !paused,
            'PAUSED'
        );
        require(
            amount > 0,
            'Zero Amount'
        );

        // Track Balance Before Deposit
        uint previousBalance = token.balanceOf(address(this));

        // Transfer In Token
        uint received = _transferIn(amount);

        if (_totalSupply == 0 || previousBalance == 0) {
            _registerFirstPurchase(msg.sender, received);
        } else {
            _mintTo(msg.sender, received, previousBalance);
        }        
    }

    /**
        Redeems `amount` of Underlying Tokens, As Seen From BalanceOf()
     */
    function withdraw(uint256 amount) public nonReentrant returns (uint256) {
        require(
            !paused,
            'PAUSED'
        );

        // Token Amount Into Contract Balance Amount
        uint MAXI_Amount = amount == balanceOf(msg.sender) ? userInfo[msg.sender].balance : TokenToContractBalance(amount);
        
        // Ensure The User Has Enough Balance
        require(
            userInfo[msg.sender].balance > 0 &&
            userInfo[msg.sender].balance >= MAXI_Amount &&
            balanceOf(msg.sender) >= amount &&
            amount > 0 &&
            MAXI_Amount > 0,
            'Insufficient Funds'
        );

        // update users vesting, if applicable
        _updateVesting(msg.sender);
        
        // burn MAXI Tokens From Sender
        _burn(msg.sender, MAXI_Amount, amount);

        // ensure their balance is above the threshold they cannot go under
        require(
            balanceOf(msg.sender) >= ( userInfo[msg.sender].totalNonWithdrawable + userInfo[msg.sender].remainingVest ),
            'Has Not Vested Yet'
        );

        // increment total withdrawn
        unchecked {
            userInfo[msg.sender].totalWithdrawn += amount;
        }

        // Take Fee If Withdrawn Before Timer
        uint fee = remainingLockTime(msg.sender) == 0 ? 0 : _takeFee(amount.mul(leaveEarlyFee).div(1000));

        // send amount less fee
        uint256 sendAmount = amount.sub(fee);
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

    /**
        Redeems `amount` of Underlying Tokens, As Seen From BalanceOf()
     */
    function withdrawNFT(uint256[] calldata ids, uint256 amount) external ownsNFTs(ids) nonReentrant returns (uint256) {
        require(
            !paused,
            'PAUSED'
        );

        address withdrawOwner = INFT(nft).ownerOf(ids[0]);
        uint len = ids.length;
        uint totalSendAmount = 0;
        for (uint i = 0; i < len;) {

            // Token Amount Into Contract Balance Amount
            uint MAXI_Amount = amount == balanceOfNFT(ids[i]) ? nftInfo[ids[i]].balance : TokenToContractBalance(amount);
            
            // Ensure The User Has Enough Balance
            require(
                nftInfo[ids[i]].balance > 0 &&
                nftInfo[ids[i]].balance >= MAXI_Amount &&
                balanceOfNFT(ids[i]) >= amount &&
                amount > 0 &&
                MAXI_Amount > 0,
                'Insufficient Funds'
            );

            // update users vesting, if applicable
            _updateVestingNFT(ids[i]);
            
            // burn MAXI Tokens From Sender
            _burnNFT(ids[i], MAXI_Amount, amount);

            // ensure their balance is above the threshold they cannot go under
            require(
                balanceOfNFT(ids[i]) >= ( nftInfo[ids[i]].totalNonWithdrawable + nftInfo[ids[i]].remainingVest ),
                'Has Not Vested Yet'
            );

            // increment total withdrawn
            unchecked {
                nftInfo[ids[i]].totalWithdrawn += amount;
            }

            // Take Fee If Withdrawn Before Timer
            uint fee = remainingLockTimeNFT(ids[i]) == 0 ? 0 : _takeFee(amount.mul(leaveEarlyFee).div(1000));

            // send amount less fee
            uint256 sendAmount = amount - fee;

            // increment total send amount
            totalSendAmount += sendAmount;

            // increment loop
            unchecked { ++i; }
        }

        // emit withdrawal event
        emit Withdraw(nft, totalSendAmount);

        // transfer token to sender
        require(
            token.transfer(withdrawOwner, totalSendAmount),
            'Error On Token Transfer'
        );
        return totalSendAmount;
    }



    ////////////////////////////////////////////////////////////
    /////////////      INTERNAL FUNCTIONS        ///////////////
    ////////////////////////////////////////////////////////////

    /**
        Sets Vesting Schedule Data For A User
     */
    function setVestingScheduleData(
        uint256 amount, 
        address user,
        uint256 startTime,
        uint256 duration,
        uint256 remainingVests,
        uint256 totalNonWithdrawable
    ) internal {

        // Track Balance Before Deposit
        uint previousBalance = token.balanceOf(address(this));

        // Transfer In Token
        uint received = _transferIn(amount);

        if (_totalSupply == 0 || previousBalance == 0) {
            _registerFirstPurchase(user, received);
        } else {
            _mintTo(user, received, previousBalance);
        }

        // set staking info
        userInfo[user].startTime = startTime;
        userInfo[user].lastUpdated = block.timestamp;
        userInfo[user].duration = duration;
        userInfo[user].remainingVest += remainingVests;
        userInfo[user].totalVestedAtStart += remainingVests;
        userInfo[user].totalNonWithdrawable += totalNonWithdrawable;
    }

    /**
        Registers the First Stake
     */
    function _registerFirstPurchase(address user, uint received) internal {
        
        // increment total staked
        unchecked {
            userInfo[user].totalStaked += received;
        }

        // mint MAXI Tokens To Sender
        _mint(user, received, received);

        emit Deposit(user, received);
    }

    /**
        Registers the First Stake
     */
    function _registerFirstPurchaseNFT(uint256 id, uint received) internal {
        
        // increment total staked
        unchecked {
            nftInfo[id].totalStaked += received;
        }

        // mint MAXI Tokens To Sender
        _mintNFT(id, received, received);

        emit Deposit(nft, received);
    }


    function _takeFee(uint256 fee) internal returns (uint256) {
        if (fee <= 10) {
            return fee;
        }
        require(
            token.transfer(leaveEarlyFeeRecipient, fee),
            'Failure On Fee Transfer'
        );
        emit FeeTaken(fee);
        return fee;
    }

    function _mintTo(address sender, uint256 received, uint256 previousBalance) internal {
        // Number Of Maxi Tokens To Mint
        uint nToMint = (_totalSupply.mul(received).div(previousBalance));
        require(
            nToMint > 0,
            'Zero To Mint'
        );

        // increment total staked
        unchecked {
            userInfo[sender].totalStaked += received;
        }

        // mint MAXI Tokens To Sender
        _mint(sender, nToMint, received);

        emit Deposit(sender, received);
    }

    function _mintToNFT(uint256 id, uint256 received, uint256 previousBalance) internal {
        // Number Of Maxi Tokens To Mint
        uint nToMint = (_totalSupply.mul(received).div(previousBalance));
        require(
            nToMint > 0,
            'Zero To Mint'
        );

        // increment total staked
        unchecked {
            nftInfo[id].totalStaked += received;
        }

        // mint MAXI Tokens To Sender
        _mintNFT(id, nToMint, received);

        emit Deposit(nft, received);
    }

    function _transferIn(uint256 amount) internal returns (uint256) {
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
     * Burns `amount` of Contract Balance Token
     */
    function _burnNFT(uint256 id, uint256 amount, uint256 amountToken) private {
        nftInfo[id].balance = nftInfo[id].balance.sub(amount);
        _totalSupply = _totalSupply.sub(amount);
        emit Transfer(nft, address(0), amountToken);
    }

    /**
     * Mints `amount` of Contract Balance Token
     */
    function _mint(address to, uint256 amount, uint256 stablesWorth) private {
        
        // allocate
        unchecked {
            userInfo[to].balance += amount;
            _totalSupply += amount;
        }

        // update locker info
        userInfo[to].unlockBlock = block.number + leaveEarlyFeeTimer;
        emit Transfer(address(0), to, stablesWorth);
    }

    /**
     * Mints `amount` of Contract Balance Token
     */
    function _mintNFT(uint256 id, uint256 amount, uint256 stablesWorth) private {
        
        // allocate
        unchecked {
            nftInfo[id].balance += amount;
            _totalSupply += amount;
        }
        
        // update locker info
        nftInfo[id].unlockBlock = block.number + leaveEarlyFeeTimer;
        emit Transfer(address(0), nft, stablesWorth);
    }

    function _updateVesting(address user) internal {
        if (isVesting(user)) {
            uint pending = pendingVest(user);
            if (pending == 0) {
                return;
            }
            if (pending >= userInfo[user].remainingVest) {
                delete userInfo[user].remainingVest;
                delete userInfo[user].duration;
                delete userInfo[user].lastUpdated;
                delete userInfo[user].startTime;
            } else {
                userInfo[user].remainingVest -= pending;
                userInfo[user].lastUpdated = block.timestamp;
            }
        }
    }

    function _updateVestingNFT(uint256 id) internal {
        if (isVestingNFT(id)) {
            uint pending = pendingVestNFT(id);
            if (pending == 0) {
                return;
            }
            if (pending >= nftInfo[id].remainingVest) {
                delete nftInfo[id].remainingVest;
                delete nftInfo[id].duration;
                delete nftInfo[id].lastUpdated;
                delete nftInfo[id].startTime;
            } else {
                nftInfo[id].remainingVest -= pending;
                nftInfo[id].lastUpdated = block.timestamp;
            }
        }
    }



    ////////////////////////////////////////////////////////////
    ///////////////      READ FUNCTIONS        /////////////////
    ////////////////////////////////////////////////////////////


    function isVesting(address user) public view returns (bool) {
        return userInfo[user].remainingVest > 0;
    }

    function getStakeInAdditionToRemainingPayout(address user) external view returns (uint256) {
        uint remaining = remainingVest(user);
        uint owned = balanceOf(user);
        return owned - remaining;
    }

    function pendingVest(address user) public view returns (uint256) {
        uint timeSince = timeSinceLastClaim(user);
        uint tps = tokensPerSecond(user);
        if (tps == 0 || timeSince == 0) {
            return 0;
        }
        uint unclamped = tps * timeSince;
        return unclamped > userInfo[user].remainingVest ? userInfo[user].remainingVest : unclamped;
    }

    function tokensPerSecond(address user) public view returns (uint256) {
        if ( userInfo[user].duration == 0 || userInfo[user].remainingVest == 0 ) {
            return 0;
        }
        return userInfo[user].totalVestedAtStart / userInfo[user].duration;
    }

    function timeRemaining(address user) public view returns (uint256) {
        uint256 _endTime = endTime(user);
        return _endTime > block.timestamp ? _endTime - block.timestamp : 0;
    }

    function endTime(address user) public view returns (uint256) {
        return userInfo[user].startTime + userInfo[user].duration;
    }

    function timeSinceLastClaim(address user) public view returns (uint256) {
        if (isVesting(user) == false || userInfo[user].startTime == 0 || userInfo[user].startTime >= block.timestamp) {
            return 0;
        }
        uint endTimeForUser = endTime(user);
        if (endTimeForUser == 0) {
            return 0;
        }
        uint lastUpdate = userInfo[user].startTime > userInfo[user].lastUpdated ? userInfo[user].startTime : userInfo[user].lastUpdated; 
        return block.timestamp > lastUpdate ? block.timestamp - lastUpdate : 0;
    }

    function remainingVest(address user) public view returns (uint256) {
        return userInfo[user].remainingVest;
    }

    function totalAmountVested(address user) external view returns (uint256) {
        return userInfo[user].totalVestedAtStart - userInfo[user].remainingVest;
    }

    function totalAmountVestedWithPending(address user) external view returns (uint256) {
        return ( ( userInfo[user].totalVestedAtStart + pendingVest(user) ) - userInfo[user].remainingVest );
    }

    function totalAmountUnclaimable(address user) external view returns (uint256) {
        return userInfo[user].totalNonWithdrawable;
    }

    function getTotalVestedAtStart(address user) external view returns (uint256) {
        return userInfo[user].totalVestedAtStart;
    }

    function minTokensToRemainInPool(address user) public view returns (uint256) {
        return userInfo[user].totalNonWithdrawable + userInfo[user].remainingVest - pendingVest(user);
    }

    function maxWithdrawableTokens(address user) external view returns (uint256) {
        return balanceOf(user) - minTokensToRemainInPool(user);
    }



    function isVestingNFT(uint256 id) public view returns (bool) {
        return nftInfo[id].remainingVest > 0;
    }

    function getStakeInAdditionToRemainingPayoutNFT(uint256 id) external view returns (uint256) {
        uint remaining = remainingVestNFT(id);
        uint owned = balanceOfNFT(id);
        return owned - remaining;
    }

    function pendingVestNFT(uint256 id) public view returns (uint256) {
        uint timeSince = timeSinceLastClaimNFT(id);
        uint tps = tokensPerSecondNFT(id);
        if (tps == 0 || timeSince == 0) {
            return 0;
        }
        uint unclamped = tps * timeSince;
        return unclamped > nftInfo[id].remainingVest ? nftInfo[id].remainingVest : unclamped;
    }

    function tokensPerSecondNFT(uint256 id) public view returns (uint256) {
        if ( nftInfo[id].duration == 0 || nftInfo[id].remainingVest == 0 ) {
            return 0;
        }
        return nftInfo[id].totalVestedAtStart / nftInfo[id].duration;
    }

    function timeRemainingNFT(uint256 id) public view returns (uint256) {
        uint256 _endTime = endTimeNFT(id);
        return _endTime > block.timestamp ? _endTime - block.timestamp : 0;
    }

    function endTimeNFT(uint256 id) public view returns (uint256) {
        return nftInfo[id].startTime + nftInfo[id].duration;
    }

    function timeSinceLastClaimNFT(uint256 id) public view returns (uint256) {
        if (isVestingNFT(id) == false || nftInfo[id].startTime == 0 || nftInfo[id].startTime >= block.timestamp) {
            return 0;
        }
        uint endTimeForUser = endTimeNFT(id);
        if (endTimeForUser == 0) {
            return 0;
        }
        uint lastUpdate = nftInfo[id].startTime > nftInfo[id].lastUpdated ? nftInfo[id].startTime : nftInfo[id].lastUpdated; 
        return block.timestamp > lastUpdate ? block.timestamp - lastUpdate : 0;
    }

    function remainingVestNFT(uint256 id) public view returns (uint256) {
        return nftInfo[id].remainingVest;
    }

    function totalAmountVestedNFT(uint256 id) external view returns (uint256) {
        return nftInfo[id].totalVestedAtStart - nftInfo[id].remainingVest;
    }

    function totalAmountVestedWithPendingNFT(uint256 id) external view returns (uint256) {
        return ( ( nftInfo[id].totalVestedAtStart + pendingVestNFT(id) ) - nftInfo[id].remainingVest );
    }

    function totalAmountUnclaimableNFT(uint256 id) external view returns (uint256) {
        return nftInfo[id].totalNonWithdrawable;
    }

    function getTotalVestedAtStartNFT(uint256 id) external view returns (uint256) {
        return nftInfo[id].totalVestedAtStart;
    }

    function minTokensToRemainInPoolNFT(uint256 id) public view returns (uint256) {
        return nftInfo[id].totalNonWithdrawable + nftInfo[id].remainingVest - pendingVestNFT(id);
    }

    function maxWithdrawableTokensNFT(uint256 id) external view returns (uint256) {
        return balanceOfNFT(id) - minTokensToRemainInPoolNFT(id);
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

    /**
        Lock Time Remaining For Stakers
     */
    function remainingLockTime(address user) public view returns (uint256) {
        return userInfo[user].unlockBlock < block.number ? 0 : userInfo[user].unlockBlock - block.number;
    }

    /** Returns Total Profit for User In Token From MAXI */
    function getTotalProfits(address user) external view returns (uint256) {
        uint top = balanceOf(user) + userInfo[user].totalWithdrawn;
        return top <= userInfo[user].totalStaked ? 0 : top - userInfo[user].totalStaked;
    }

    /**
        Lock Time Remaining For NFT Holder
     */
    function remainingLockTimeNFT(uint256 id) public view returns (uint256) {
        return nftInfo[id].unlockBlock < block.number ? 0 : nftInfo[id].unlockBlock - block.number;
    }

    /** Returns Total Profit for NFT Holder In Token From MAXI */
    function getTotalProfitsNFT(uint256 id) external view returns (uint256) {
        uint top = balanceOfNFT(id) + nftInfo[id].totalWithdrawn;
        return top <= nftInfo[id].totalStaked ? 0 : top - nftInfo[id].totalStaked;
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