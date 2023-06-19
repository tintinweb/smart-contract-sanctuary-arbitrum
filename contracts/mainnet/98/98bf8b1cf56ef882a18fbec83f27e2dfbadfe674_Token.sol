/**
 *Submitted for verification at Arbiscan on 2023-06-19
*/

// SPDX-License-Identifier: AGPL-3.0
pragma solidity =0.8.19;

library SafeMath {
  
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");

        return c;
    }

    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return sub(a, b, "SafeMath: subtraction overflow");
    }

    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b <= a, errorMessage);
        uint256 c = a - b;

        return c;
    }

    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
    
        if (a == 0) {
            return 0;
        }

        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");

        return c;
    }

    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return div(a, b, "SafeMath: division by zero");
    }

    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b > 0, errorMessage);
        uint256 c = a / b;

        return c;
    }

    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return mod(a, b, "SafeMath: modulo by zero");
    }

    function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b != 0, errorMessage);
        return a % b;
    }
}

abstract contract Context {
    function _msgSender() internal view virtual returns (address payable) {
        return payable(address(msg.sender));
    }

    function _msgData() internal view virtual returns (bytes memory) {
        this;
        return msg.data;
    }
}

abstract contract Ownable is Context {
    address private _owner;
    address private _previousOwner;
    uint256 private _lockTime;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    constructor ()  {
        address msgSender = _msgSender();
        _owner = msgSender;
        emit OwnershipTransferred(address(0), msgSender);
    }
    function owner() public view returns (address) {
        return _owner;
    }
    modifier onlyOwner() {
        require(_owner == _msgSender(), "Ownable: caller is not the owner");
        _;
    }
    function renounceOwnership() public virtual onlyOwner {
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}

interface IERC20 {
    function mint(address _to, uint256 _amount) external returns (bool);
}

contract Token is Context, Ownable {    
    using SafeMath for uint256;

    string private _name = "Vested Degen Brain Exchange";
    string private _symbol = "vDBX";
    uint8 private _decimals = 18;
    uint256 private _totalSupply;
    uint256 public constant maxSupply = 750000000 * (10 ** 18);

    address private zero = address(0);
    address private dead = 0x000000000000000000000000000000000000dEaD;

    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);    
    event Airdrop(address indexed from, address[] indexed to, uint256[] value);

    mapping(address => bool) public isMinter;
    mapping(address => uint256) private _balances;
    mapping(address => mapping(address => uint256)) private _allowances;

    address public DBX = address(0);
    uint256 public offset = 0;
    uint256 public vestingPeriod = 180 * 86400;
    struct VestingSchedule {
        uint256 amount;
        uint256 startTimestamp;
        uint256 releasedTokens;
    }
    mapping(address => VestingSchedule[]) public vestingSchedules;

    function totalVested(address beneficiary) public view returns (uint256) {
        VestingSchedule[] storage schedules = vestingSchedules[beneficiary];
        uint256 totalTokens = 0;
        for (uint256 i = 0; i < schedules.length; i++) {
            VestingSchedule storage schedule = schedules[i];
            totalTokens += schedule.amount - schedule.releasedTokens;
        }
        return totalTokens;
    }

    function vest(uint256 amount) public {
        require(amount > 0, "vDBX: Invalid amount");
        _burn(msg.sender, amount);
        vestingSchedules[msg.sender].push(VestingSchedule(amount, block.timestamp-offset, 0));
    }

    function estimate(address beneficiary) public view returns(uint256) {
        VestingSchedule[] storage schedules = vestingSchedules[beneficiary];
        uint256 totalAvailableTokens = 0;
        for (uint256 i = 0; i < schedules.length; i++) {
            VestingSchedule storage schedule = schedules[i];
            uint256 elapsedTime = block.timestamp - schedule.startTimestamp;
            if (elapsedTime > 0) {
                if (elapsedTime > vestingPeriod) { elapsedTime = vestingPeriod; }
                uint256 vestedTokens = (schedule.amount * elapsedTime) / vestingPeriod;
                uint256 availableTokens = vestedTokens - schedule.releasedTokens;

                if (availableTokens > 0) {
                    totalAvailableTokens += availableTokens;
                }
            }
        }
        return totalAvailableTokens;
    }

    function withdraw() public {
        VestingSchedule[] storage schedules = vestingSchedules[msg.sender];
        require(schedules.length > 0, "vDBX: No vesting schedule found for the caller");

        uint256 totalAvailableTokens;
        for (uint256 i = 0; i < schedules.length; i++) {
            VestingSchedule storage schedule = schedules[i];
            uint256 elapsedTime = block.timestamp - schedule.startTimestamp;
            if (elapsedTime > 0) {
                if (elapsedTime > vestingPeriod) { elapsedTime = vestingPeriod; }
                uint256 vestedTokens = (schedule.amount * elapsedTime) / vestingPeriod;
                uint256 availableTokens = vestedTokens - schedule.releasedTokens;

                if (availableTokens > 0) {
                    totalAvailableTokens += availableTokens;
                    schedule.releasedTokens += availableTokens;
                }
            }
        }

        truncate();
        require(totalAvailableTokens > 0, "vDBX: No tokens available for release");
        IERC20(DBX).mint(msg.sender, totalAvailableTokens);
    }

    function truncate() public {
        uint i = 0;
        VestingSchedule[] storage schedules = vestingSchedules[msg.sender];
        while (i < schedules.length) {
            if(schedules[i].amount == schedules[i].releasedTokens) {
                delete schedules[i];
            }
            i++;
        }
        for(uint x = 0; x < schedules.length-1; x++){
            schedules[x] = schedules[x+1];      
        }
        schedules.pop();
    }

    function setDBX(address _addi) public onlyMinters {
        DBX = _addi;
    }

    function setOffset(uint256 _offset) public onlyMinters {
        offset = _offset;
    }

    function convert(uint256 amount) public {
        _burn(msg.sender, amount);
        IERC20(DBX).mint(msg.sender, amount/10);
    }

    modifier onlyMinters() {
        require(_msgSender() == owner() || isMinter[_msgSender()], "Not authorized");
        _;
    }

    function addMinter(address account) public onlyMinters {
        isMinter[account] = true;
    }

    function removeMinter(address account) public onlyMinters {
        isMinter[account] = false;
    }

    function name() public view returns (string memory) {
        return _name;
    }

    function decimals() public view returns (uint8) {
        return _decimals;
    }

    function symbol() public view returns (string memory) {
        return _symbol;
    }

    function totalSupply() public view returns (uint256) {
        return _totalSupply;
    }

    function balanceOf(address account) public view returns (uint256) {
        return _balances[account];
    }

    function transfer(address recipient, uint256 amount) public returns (bool) {
        _transfer(_msgSender(), recipient, amount);
        return true;
    }
    
    function allowance(address owner, address spender) public view returns (uint256) {
        return _allowances[owner][spender];
    }

    function approve(address spender, uint256 amount) public returns (bool) {
        _approve(_msgSender(), spender, amount);
        return true;
    }

    function transferFrom(address sender, address recipient, uint256 amount) public returns (bool) {
        _transfer(sender, recipient, amount);
        _approve(sender, _msgSender(), _allowances[sender][_msgSender()].sub(amount, "transfer amount exceeds allowance"));
        return true;
    }

    function increaseAllowance(address spender, uint256 addedValue) public returns (bool) {
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender].add(addedValue));
        return true;
    }

    function decreaseAllowance(address spender, uint256 subtractedValue) public returns (bool) {
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender].sub(subtractedValue, "decreased allowance below zero"));
        return true;
    }

    function mint(address recipient, uint256 amount) public onlyMinters returns (bool) {
        _mint(recipient, amount);
        return true;
    }

    function burn(uint256 amount) public returns (bool) {
        _burn(_msgSender(), amount);
        return true;
    }

    function airdrop(address[] memory recipients, uint256[] memory amounts) public {
        require(recipients.length == amounts.length, "Invalid input lengths");

        for (uint256 i = 0; i < recipients.length; i++) {
            address recipient = recipients[i];
            uint256 amount = amounts[i];

            require(recipient != zero, "Invalid recipient address");
            require(amount > 0, "Airdrop amount must be greater than zero");

            _transfer(_msgSender(), recipient, amount);
        }
        emit Airdrop(_msgSender(), recipients, amounts);
    }
    
    function _transfer(address sender, address recipient, uint256 amount) internal {
        require(sender != zero, "transfer from the zero address");
        require(recipient != zero, "transfer to the zero address");
        require(sender != dead, "transfer from the dead address");
        require(recipient != dead, "transfer to the dead address");

        _balances[sender] = _balances[sender].sub(amount, "transfer amount exceeds balance");
        _balances[recipient] = _balances[recipient].add(amount);
        emit Transfer(sender, recipient, amount);
    }
    
    function _mint(address account, uint256 amount) internal {
        require(account != zero, "mint to the zero address");
        require(account != dead, "mint to the dead address");
        if (amount.add(_totalSupply) <= maxSupply) {
            _totalSupply = _totalSupply.add(amount);
            _balances[account] = _balances[account].add(amount);
            emit Transfer(address(0), account, amount);
        }
    }

    function _burn(address account, uint256 amount) internal {
        require(account != zero, "burn from the zero address");
        require(account != dead, "burn from the dead address");

        _balances[account] = _balances[account].sub(amount, "burn amount exceeds balance");
        _totalSupply = _totalSupply.sub(amount);
        emit Transfer(account, address(0), amount);
    }
    
    function _approve(address owner, address spender, uint256 amount) internal {
        require(owner != zero, "approve from the zero address");
        require(spender != zero, "approve to the zero address");
        require(owner != dead, "approve from the dead address");
        require(spender != dead, "approve to the dead address");

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }
}