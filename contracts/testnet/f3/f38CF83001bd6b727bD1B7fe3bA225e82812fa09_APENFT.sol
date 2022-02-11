/**
 *Submitted for verification at arbiscan.io on 2022-02-05
*/

// File: contracts/APENFT/contracts/Ownable.sol

pragma solidity ^0.4.18;


/**
 * @title Ownable
 * @dev The Ownable contract has an owner address, and provides basic authorization control
 * functions, this simplifies the implementation of "user permissions".
 */
contract Ownable {
    address public owner;


    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);


    /**
     * @dev The Ownable constructor sets the original `owner` of the contract to the sender
     * account.
     */
    function Ownable() public {
        owner = msg.sender;
    }


    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(msg.sender == owner);
        _;
    }


    /**
     * @dev Allows the current owner to transfer control of the contract to a newOwner.
     * @param newOwner The address to transfer ownership to.
     */
    function transferOwnership(address newOwner) public onlyOwner {
        require(newOwner != address(0));
        OwnershipTransferred(owner, newOwner);
        owner = newOwner;
    }

}

// File: contracts/APENFT/contracts/Pausable.sol

pragma solidity ^0.4.18;



/**
 * @title Pausable
 * @dev Base contract which allows children to implement an emergency stop mechanism.
 */
contract Pausable is Ownable {
    event Pause();
    event Unpause();

    bool public paused = false;


    /**
     * @dev Modifier to make a function callable only when the contract is not paused.
     */
    modifier whenNotPaused() {
        require(!paused);
        _;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is paused.
     */
    modifier whenPaused() {
        require(paused);
        _;
    }

    /**
     * @dev called by the owner to pause, triggers stopped state
     */
    function pause() onlyOwner whenNotPaused public {
        paused = true;
        Pause();
    }

    /**
     * @dev called by the owner to unpause, returns to normal state
     */
    function unpause() onlyOwner whenPaused public {
        paused = false;
        Unpause();
    }
}

// File: contracts/APENFT/contracts/SafeMath.sol

pragma solidity ^0.4.18;


/**
 * @title SafeMath
 * @dev Math operations with safety checks that throw on error
 */
library SafeMath {
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        if (a == 0) {
            return 0;
        }
        uint256 c = a * b;
        assert(c / a == b);
        return c;
    }

    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        // assert(b > 0); // Solidity automatically throws when dividing by 0
        uint256 c = a / b;
        // assert(a == b * c + a % b); // There is no case in which this doesn't hold
        return c;
    }

    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        assert(b <= a);
        return a - b;
    }

    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        assert(c >= a);
        return c;
    }
}

// File: contracts/APENFT/contracts/BasicToken.sol

pragma solidity ^0.4.18;


/**
 * @title TRC20Basic
 * @dev Simpler version of TRC20 interface
 */
contract TRC20Basic {
    function totalSupply() public constant returns (uint);
    function balanceOf(address who) public view returns (uint256);
    function transfer(address to, uint256 value) public returns (bool);
    event Transfer(address indexed from, address indexed to, uint256 value);
}

/**
 * @title Basic token
 * @dev Basic version of StandardToken, with no allowances.
 */
contract BasicToken is TRC20Basic {
    using SafeMath for uint256;

    mapping(address => uint256) balances;

    /**
    * @dev transfer token for a specified address
    * @param _to The address to transfer to.
    * @param _value The amount to be transferred.
    */
    function transfer(address _to, uint256 _value) public returns (bool) {
        require(_to != address(0));
        require(_value <= balances[msg.sender]);

        // SafeMath.sub will throw if there is not enough balance.
        balances[msg.sender] = balances[msg.sender].sub(_value);
        balances[_to] = balances[_to].add(_value);
        Transfer(msg.sender, _to, _value);
        return true;
    }

    /**
    * @dev Gets the balance of the specified address.
    * @param _owner The address to query the the balance of.
    * @return An uint256 representing the amount owned by the passed address.
    */
    function balanceOf(address _owner) public view returns (uint256 balance) {
        return balances[_owner];
    }

}

// File: contracts/APENFT/contracts/StandardToken.sol

pragma solidity ^0.4.18;



/**
 * @title TRC20 interface
 */
contract TRC20 is TRC20Basic {
    function allowance(address owner, address spender) public view returns (uint256);
    function transferFrom(address from, address to, uint256 value) public returns (bool);
    function approve(address spender, uint256 value) public returns (bool);
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

/**
 * @title Standard TRC20 token
 *
 * @dev Implementation of the basic standard token.
 */
contract StandardToken is TRC20, BasicToken {

    mapping (address => mapping (address => uint256)) internal allowed;


    /**
     * @dev Transfer tokens from one address to another
     * @param _from address The address which you want to send tokens from
     * @param _to address The address which you want to transfer to
     * @param _value uint256 the amount of tokens to be transferred
     */
    function transferFrom(address _from, address _to, uint256 _value) public returns (bool) {
        require(_to != address(0));
        require(_value <= balances[_from]);
        require(_value <= allowed[_from][msg.sender]);

        balances[_from] = balances[_from].sub(_value);
        balances[_to] = balances[_to].add(_value);
        allowed[_from][msg.sender] = allowed[_from][msg.sender].sub(_value);
        Transfer(_from, _to, _value);
        return true;
    }

    /**
     * @dev Approve the passed address to spend the specified amount of tokens on behalf of msg.sender.
     *
     * Beware that changing an allowance with this method brings the risk that someone may use both the old
     * and the new allowance by unfortunate transaction ordering. One possible solution to mitigate this
     * race condition is to first reduce the spender's allowance to 0 and set the desired value afterwards:
     * @param _spender The address which will spend the funds.
     * @param _value The amount of tokens to be spent.
     */
    function approve(address _spender, uint256 _value) public returns (bool) {
        allowed[msg.sender][_spender] = _value;
        Approval(msg.sender, _spender, _value);
        return true;
    }

    /**
     * @dev Function to check the amount of tokens that an owner allowed to a spender.
     * @param _owner address The address which owns the funds.
     * @param _spender address The address which will spend the funds.
     * @return A uint256 specifying the amount of tokens still available for the spender.
     */
    function allowance(address _owner, address _spender) public view returns (uint256) {
        return allowed[_owner][_spender];
    }

    /**
     * approve should be called when allowed[_spender] == 0. To increment
     * allowed value is better to use this function to avoid 2 calls (and wait until
     * the first transaction is mined)
     * From MonolithDAO Token.sol
     */
    function increaseApproval(address _spender, uint _addedValue) public returns (bool) {
        allowed[msg.sender][_spender] = allowed[msg.sender][_spender].add(_addedValue);
        Approval(msg.sender, _spender, allowed[msg.sender][_spender]);
        return true;
    }

    function decreaseApproval(address _spender, uint _subtractedValue) public returns (bool) {
        uint oldValue = allowed[msg.sender][_spender];
        if (_subtractedValue > oldValue) {
            allowed[msg.sender][_spender] = 0;
        } else {
            allowed[msg.sender][_spender] = oldValue.sub(_subtractedValue);
        }
        Approval(msg.sender, _spender, allowed[msg.sender][_spender]);
        return true;
    }

}

// File: contracts/APENFT/contracts/StandardTokenWithFees.sol

pragma solidity ^0.4.18;



contract StandardTokenWithFees is StandardToken, Ownable {

    // Additional variables for use if transaction fees ever became necessary
    uint256 public basisPointsRate = 0;
    uint256 public maximumFee = 0;
    uint256 constant MAX_SETTABLE_BASIS_POINTS = 20;
    uint256 constant MAX_SETTABLE_FEE = 50;

    string public name;
    string public symbol;
    uint8 public decimals;
    uint public _totalSupply;

    uint public constant MAX_UINT = 2**256 - 1;

    function calcFee(uint _value) constant returns (uint) {
        uint fee = (_value.mul(basisPointsRate)).div(10000);
        if (fee > maximumFee) {
            fee = maximumFee;
        }
        return fee;
    }

    function transfer(address _to, uint _value) public returns (bool) {
        uint fee = calcFee(_value);
        uint sendAmount = _value.sub(fee);

        super.transfer(_to, sendAmount);
        if (fee > 0) {
            super.transfer(owner, fee);
        }
        return true;
    }

    function transferFrom(address _from, address _to, uint256 _value) public returns (bool) {
        require(_to != address(0));
        require(_value <= balances[_from]);
        require(_value <= allowed[_from][msg.sender]);

        uint fee = calcFee(_value);
        uint sendAmount = _value.sub(fee);

        balances[_from] = balances[_from].sub(_value);
        balances[_to] = balances[_to].add(sendAmount);
        if (allowed[_from][msg.sender] < MAX_UINT) {
            allowed[_from][msg.sender] = allowed[_from][msg.sender].sub(_value);
        }
        Transfer(_from, _to, sendAmount);
        if (fee > 0) {
            balances[owner] = balances[owner].add(fee);
            Transfer(_from, owner, fee);
        }
        return true;
    }

}

// File: contracts/APENFT/contracts/TimelockToken.sol



pragma solidity ^0.4.18;


/**
 * @dev Contract module which acts as a timelocked Token. When set as the
 * owner of an `Ownable` smart contract, it enforces a timelock on all
 * `onlyOwner` maintenance operations. This gives time for users of the
 * controlled contract to exit before a potentially dangerous maintenance
 * operation is applied.
 *
 * This contract is a modified version of:
 * https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/governance/TimelockController.sol
 *
 */
contract TimelockToken is StandardTokenWithFees{
    uint256 internal constant _DONE_TIMESTAMP = uint256(1);

    mapping(uint256 => action) public actions;

    uint256 private _minDelay = 3 days;

    uint256 public nonce;

    enum RequestType{
        Issue,
        Redeem
    }

    struct action {
        uint256 timestamp;
        RequestType requestType;
        uint256 value;
    }
    /**
     * @dev Emitted when a call is scheduled as part of operation `id`.
     */
    event RequestScheduled(uint256 indexed id, RequestType _type, uint256 value,  uint256 availableTime);


    /**
     * @dev Emitted when a call is performed as part of operation `id`.
     */
    event RequestExecuted(uint256 indexed id, RequestType _type, uint256 value);


    // Called when new token are issued
    event Issue(uint amount);

    // Called when tokens are redeemed
    event Redeem(uint amount);

    /**
     * @dev Emitted when operation `id` is cancelled.
     */
    event Cancelled(uint256 indexed id);

    /**
     * @dev Emitted when the minimum delay for future operations is modified.
     */
    event DelayTimeChange(uint256 oldDuration, uint256 newDuration);


    /**
     * @dev Initializes the contract with a given `minDelay`.
     */
    constructor() public {
        emit DelayTimeChange(0, 3 days);
    }

    /**
     * @dev Returns whether an id correspond to a registered operation. This
     * includes both Pending, Ready and Done operations.
     */
    function isOperation(uint256 id) public view returns (bool registered) {
        return getTimestamp(id) > 0;
    }

    /**
     * @dev Returns whether an operation is pending or not.
     */
    function isOperationPending(uint256 id) public view returns (bool pending) {
        return getTimestamp(id) > _DONE_TIMESTAMP;
    }

    /**
     * @dev Returns whether an operation is ready or not.
     */
    function isOperationReady(uint256 id) public view returns (bool ready) {
        uint256 timestamp = getTimestamp(id);
        // solhint-disable-next-line not-rely-on-time
        return timestamp > _DONE_TIMESTAMP && timestamp <= block.timestamp;
    }

    /**
     * @dev Returns whether an operation is done or not.
     */
    function isOperationDone(uint256 id) public view returns (bool done) {
        return getTimestamp(id) == _DONE_TIMESTAMP;
    }

    /**
     * @dev Returns the timestamp at with an operation becomes ready (0 for
     * unset operations, 1 for done operations).
     */
    function getTimestamp(uint256 id) public view returns (uint256 timestamp) {
        return actions[id].timestamp;
    }

    /**
     * @dev Returns the minimum delay for an operation to become valid.
     *
     * This value can be changed by executing an operation that calls `updateDelay`.
     */
    function getMinDelay() public view  returns (uint256 duration) {
        return _minDelay;
    }

    /**
     * @dev Schedule an operation.
     *
     * Emits a {RequestScheduled} event.
     *
     */
    function _request(RequestType _requestType, uint256 value) private {
        uint256 id = nonce;
        nonce ++;
        _schedule(id, _requestType, value,  _minDelay);
    }


    /**
     * @dev Schedule an operation that is to becomes valid after a given delay.
     */
    function _schedule(uint256 id, RequestType _type, uint256 value, uint256 delay) private {
        require(!isOperation(id), "TimelockToken: operation already scheduled");
        require(delay >= getMinDelay(), "TimelockToken: insufficient delay");
        // solhint-disable-next-line not-rely-on-time
        uint256 availableTime = block.timestamp + delay;
        actions[id].timestamp = availableTime;
        actions[id].requestType = _type;
        actions[id].value = value;
        emit RequestScheduled(id, _type, value,  availableTime);
    }

    /**
     * @dev Cancel an operation.
     *
     * Requirements:
     *
     * - the caller must have the 'owner' role.
     */
    function cancel(uint256 id) public onlyOwner {
        require(isOperationPending(id), "TimelockToken: operation cannot be cancelled");
        delete actions[id];
        emit Cancelled(id);
    }


    /**
     * @dev Checks before execution of an operation's calls.
     */
    function _beforeCall(uint256 id) private {
        require(isOperation(id), "TimelockToken: operation is not registered");
    }

    /**
     * @dev Checks after execution of an operation's calls.
     */
    function _afterCall(uint256 id) private {
        require(isOperationReady(id), "TimelockToken: operation is not ready");
        actions[id].timestamp = _DONE_TIMESTAMP;
    }


    /**
     * @dev Execute an operation's call.
     */
    function _call(uint256 id, address owner) private {
        uint256 amount = actions[id].value;
        // solhint-disable-next-line avoid-low-level-calls
        if(actions[id].requestType == RequestType.Issue) {
            balances[owner] = balances[owner].add(amount);
            _totalSupply = _totalSupply.add(amount);
            emit Transfer(address(0), owner, amount);
            emit Issue(amount);
        }
        else if(actions[id].requestType == RequestType.Redeem) {
            _totalSupply = _totalSupply.sub(amount);
            balances[owner] = balances[owner].sub(amount);
            emit Transfer(owner, address(0), amount);
            emit Redeem(amount);
        }
    }

    /*
     * Schedule to issue a new amount of tokens
     * these tokens are deposited into the owner address
     *
     * @param _amount Number of tokens to be issued
     * Requirements:
     *
     * - the caller must have the 'owner' role.
     */
    function requestIssue(uint256 amount) public onlyOwner {
        _request(RequestType.Issue, amount);
    }

    /*
     * Schedule to redeem a new amount of tokens
     * these tokens are deposited into the owner address
     *
     * @param _amount Number of tokens to be redeemed
     * Requirements:
     *
     * - the caller must have the 'owner' role.
     */
    function requestRedeem(uint256 amount) public onlyOwner {
        _request(RequestType.Redeem, amount);
    }

    /*
     * execute  a request
     *
     * @param id the target action id of the request
     * Requirements:
     *
     * - the caller must have the 'owner' role.
     */

    function executeRequest(uint256 id) public onlyOwner {
        _beforeCall(id);
        _call(id, msg.sender);
        _afterCall(id);
    }

}
// File: contracts/APENFT/contracts/APENFT.sol

pragma solidity ^0.4.18;



contract UpgradedStandardToken is StandardToken {
    // those methods are called by the legacy contract
    // and they must ensure msg.sender to be the contract address
    uint public _totalSupply;
    function transferByLegacy(address from, address to, uint value) public returns (bool);
    function transferFromByLegacy(address sender, address from, address spender, uint value) public returns (bool);
    function approveByLegacy(address from, address spender, uint value) public returns (bool);
    function increaseApprovalByLegacy(address from, address spender, uint addedValue) public returns (bool);
    function decreaseApprovalByLegacy(address from, address spender, uint subtractedValue) public returns (bool);
}


contract APENFT is Pausable, TimelockToken{

    address public upgradedAddress;
    bool public deprecated;

    //  The contract can be initialized with a number of tokens
    //  All the tokens are deposited to the owner address
    function APENFT() public {
        _totalSupply = 999990000000000000000;
        name = "APENFT";
        symbol = "NFT";
        decimals = 6;
        balances[owner] = _totalSupply;
        emit Transfer(address(0), msg.sender, _totalSupply);
        deprecated = false;
    }

    // Forward TRC20 methods to upgraded contract if this one is deprecated
    function transfer(address _to, uint _value) public whenNotPaused returns (bool) {
        if (deprecated) {
            return UpgradedStandardToken(upgradedAddress).transferByLegacy(msg.sender, _to, _value);
        } else {
            return super.transfer(_to, _value);
        }
    }

    // Forward TRC20 methods to upgraded contract if this one is deprecated
    function transferFrom(address _from, address _to, uint _value) public whenNotPaused returns (bool) {
        if (deprecated) {
            return UpgradedStandardToken(upgradedAddress).transferFromByLegacy(msg.sender, _from, _to, _value);
        } else {
            return super.transferFrom(_from, _to, _value);
        }
    }

    // Forward TRC20 methods to upgraded contract if this one is deprecated
    function balanceOf(address who) public constant returns (uint) {
        if (deprecated) {
            return UpgradedStandardToken(upgradedAddress).balanceOf(who);
        } else {
            return super.balanceOf(who);
        }
    }

    // Allow checks of balance at time of deprecation
    function oldBalanceOf(address who) public constant returns (uint) {
        if (deprecated) {
            return super.balanceOf(who);
        }
    }

    // Forward TRC20 methods to upgraded contract if this one is deprecated
    function approve(address _spender, uint _value) public whenNotPaused returns (bool) {
        if (deprecated) {
            return UpgradedStandardToken(upgradedAddress).approveByLegacy(msg.sender, _spender, _value);
        } else {
            return super.approve(_spender, _value);
        }
    }

    function increaseApproval(address _spender, uint _addedValue) public whenNotPaused returns (bool) {
        if (deprecated) {
            return UpgradedStandardToken(upgradedAddress).increaseApprovalByLegacy(msg.sender, _spender, _addedValue);
        } else {
            return super.increaseApproval(_spender, _addedValue);
        }
    }

    function decreaseApproval(address _spender, uint _subtractedValue) public whenNotPaused returns (bool) {
        if (deprecated) {
            return UpgradedStandardToken(upgradedAddress).decreaseApprovalByLegacy(msg.sender, _spender, _subtractedValue);
        } else {
            return super.decreaseApproval(_spender, _subtractedValue);
        }
    }

    // Forward TRC20 methods to upgraded contract if this one is deprecated
    function allowance(address _owner, address _spender) public constant returns (uint remaining) {
        if (deprecated) {
            return StandardToken(upgradedAddress).allowance(_owner, _spender);
        } else {
            return super.allowance(_owner, _spender);
        }
    }

    // deprecate current contract in favour of a new one
    function deprecate(address _upgradedAddress) public onlyOwner {
        require(_upgradedAddress != address(0));
        deprecated = true;
        upgradedAddress = _upgradedAddress;
        Deprecate(_upgradedAddress);
    }

    // deprecate current contract if favour of a new one
    function totalSupply() public constant returns (uint) {
        if (deprecated) {
            return StandardToken(upgradedAddress).totalSupply();
        } else {
            return _totalSupply;
        }
    }


    // Called when contract is deprecated
    event Deprecate(address newAddress);

}