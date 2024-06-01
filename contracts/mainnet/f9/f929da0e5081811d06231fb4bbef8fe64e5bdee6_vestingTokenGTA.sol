/**
 *Submitted for verification at Arbiscan.io on 2024-06-01
*/

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

// File @openzeppelin/contracts/access/[email protected]

// OpenZeppelin Contracts v4.4.0 (access/Ownable.sol)

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

pragma solidity ^0.8.17;

interface IERC20 {
    function totalSupply() external view returns (uint256);

    function balanceOf(address account) external view returns (uint256);

    function transfer(address recipient, uint256 amount) external returns (bool);

    function allowance(address owner, address spender) external view returns (uint256);

    function approve(address spender, uint256 amount) external returns (bool);

    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external returns (bool);

    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

library SafeMath {
  function mul(uint256 a, uint256 b) internal pure returns (uint256) {
    if (a == 0) {
        return 0;
    }
    uint256 c = a * b;
    require(c / a == b);
    return c;
  }

  function div(uint256 a, uint256 b) internal pure returns (uint256) {
    require(b > 0);
    uint256 c = a / b;
    return c;
  }

  function sub(uint256 a, uint256 b) internal pure returns (uint256) {
    require(b <= a);
    uint256 c = a - b;
    return c;
  }

  function add(uint256 a, uint256 b) internal pure returns (uint256) {
    uint256 c = a + b;
    require(c >= a);
    return c;
  }
}

contract vestingTokenGTA  is Ownable {
    using SafeMath for uint256;

    IERC20 private token;
    address public tokenAddress;

    bool lock;
    // uint256 public duration = 30 days;
    uint256 public duration = 5 minutes;
    // uint256 public cliffDuration = 15 * 30 days;
    uint256 public cliffDuration = 15 minutes;
    uint256 public vestingCycle = 3;
    uint256 public startTime;
    uint256 public totalInvestor;
    uint256 public totalSellToken;
    address[] public addressList; 

    struct Investment {
        bool active;
        uint256 amount; 
        uint256 vestedTokens;
        uint256 claimTime;
        uint256 lastVestedTime;
    }

    mapping(address => Investment) public investments;
    mapping(address => bool) public whitelist;

    event Lock(uint256 _startTime, uint256 _nextClaimTime);
    event Distribute(uint256 _distributedToken, address _recipient, uint256 _nextClaimTime);

    constructor(address _tokenAddress) {        
        tokenAddress = _tokenAddress;
        token = IERC20(tokenAddress);
    }

    modifier isNotLock() {
        require(!lock, "Lock has already been completed.");
        _;
    }

    function startLock() external onlyOwner isNotLock {
        lock = true;
        startTime = block.timestamp;
        uint256 nextClaimTime = startTime.add(cliffDuration);

        for (uint256 i = 0; i < addressList.length; i++) {            
            if (investments[addressList[i]].active == true) {
                investments[addressList[i]].claimTime = nextClaimTime;
            }
        }

        emit Lock(startTime, nextClaimTime);
    }

    function addInvest(address _investor, uint256 _amount) external onlyOwner isNotLock {
        require(isValidAddress(_investor), "Addres is not valid.");
        require(investments[_investor].active == false, "Investor is added");

        investments[_investor].active = true;
        investments[_investor].amount = _amount; 
        totalSellToken = totalSellToken.add(_amount);
        totalInvestor++; 
        addressList.push(_investor); 
    }

    function editInvest(address _investor, uint256 _amount) external onlyOwner isNotLock {
        
        if (_amount != 0) {
            totalSellToken = totalSellToken.sub(investments[_investor].amount).add(_amount);     
            investments[_investor].amount = _amount;      
        } else {
            investments[_investor].active = false; 
            totalSellToken = totalSellToken.sub(investments[_investor].amount); 
            investments[_investor].amount = 0;  
        }     
    }

    function claim() external { 
        require(lock, "The lock has not been completed."); 
        require(token.balanceOf(address(this)) > 0, "Balance is empty.");

        Investment storage investor = investments[_msgSender()];

        require(investor.active == true, "Not in list vesting.");
        require(investor.claimTime < block.timestamp, "The time to withdraw funds has not yet come.");  

        uint256 amount = investor.amount.div(vestingCycle);

        if (amount > investor.amount - investor.vestedTokens) {
            amount = investor.amount - investor.vestedTokens;  
        }   

        if (amount > 0) {
            investor.vestedTokens = investor.vestedTokens.add(amount);
            investor.claimTime = investor.claimTime.add(duration);
            investor.lastVestedTime = block.timestamp;
            token.transfer(_msgSender(), amount);

            emit Distribute(amount, _msgSender(), investor.claimTime);
        } 
    }

    function cancelSettings() external onlyOwner isNotLock {
        uint256 amount = token.balanceOf(address(this));
        token.transfer(_msgSender(), amount);
    }

    function distributeVestingForAll() external onlyOwner { 
        require(lock, "The lock has not been completed."); 
        require(token.balanceOf(address(this)) > 0, "Balance is empty.");
        uint256 amount;

        for (uint256 i = 0; i < addressList.length; i++) {            
            Investment storage investor = investments[addressList[i]];

            if (investor.active == true && investor.claimTime < block.timestamp) {
                amount = investor.amount.div(vestingCycle);

                if (amount > investor.amount - investor.vestedTokens) {
                    amount = investor.amount - investor.vestedTokens;  
                }   

                if (amount > 0) {
                    investor.vestedTokens = investor.vestedTokens.add(amount);
                    investor.claimTime = investor.claimTime.add(duration);
                    investor.lastVestedTime = block.timestamp;
                    token.transfer(addressList[i], amount);

                    emit Distribute(amount, _msgSender(), investor.claimTime);
                } 
            }
        }    
    }    
    
    function depositForVesting(uint256 _amount) external onlyOwner isNotLock {
        require(token.allowance(_msgSender(), address(this)) >= _amount, "Insufficient allowance.");
        require(token.balanceOf(_msgSender()) >= _amount);        

        token.transferFrom(_msgSender(), address(this), _amount);
    }

    function isValidAddress(address _address) internal pure returns (bool) {
        return _address != address(0);
    }
}