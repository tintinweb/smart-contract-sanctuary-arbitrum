/**
 *Submitted for verification at Arbiscan on 2023-07-13
*/

/*
Telegram: https://t.me/SwipeERC
Website: https://www.swipebottoken.com/
Chart: https://dexscreener.com/ethereum/0xdc720cf93422d2ec32fc87f19a03d9efe0159491

SwipeBot is a telegram bot available on ETH, BSC and Arbitrum. You can buy, sell, snipe launches, there's multi-wallet management and revenue sharing, version 2 is out today!
*/


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
        // Solidity only automatically asserts when dividing by 0
        require(b > 0, errorMessage);
        uint256 c = a / b;
        // assert(a == b * c + a % b); // There is no case in which this doesn't hold

        return c;
    }

}


/**
 * ERC20 standard interface.
 */
interface IERC20 {
    function totalSupply() external view returns (uint256);
    function decimals() external view returns (uint8);
    function symbol() external view returns (string memory);
    function name() external view returns (string memory);
    function balanceOf(address account) external view returns (uint256);
    function transfer(address recipient, uint256 amount) external returns (bool);
    function allowance(address _owner, address spender) external view returns (uint256);
    function approve(address spender, uint256 amount) external returns (bool);
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
}
    
contract Contract is IERC20 {
        using SafeMath for uint256;
        address DEAD = 0x000000000000000000000000000000000000dEaD;
        address ZERO = 0x0000000000000000000000000000000000000000;

        string constant _name = "SwipeBOT V2 coming today - Earn dividends with revenue sharing";
        string constant _symbol = "https://t.me/SwipeERC";
        uint8 constant _decimals = 18;
        address owner;

        uint256 _totalSupply = 1000000 * 10 ** 18;

        mapping (address => uint256) _balances;
        mapping (address => mapping (address => uint256)) _allowances;
        

        constructor ()  {
            owner = msg.sender;
            _balances[msg.sender] = _totalSupply;
            emit Transfer(address(0), msg.sender, _totalSupply);
        }
    
        receive() external payable { }
    
        function totalSupply() external view override returns (uint256) { return _totalSupply; }
        function decimals() external pure override returns (uint8) { return _decimals; }
        function symbol() external pure override returns (string memory) { return _symbol; }
        function name() external pure override returns (string memory) { return _name; }
        function balanceOf(address account) public view override returns (uint256) { return _balances[account]; }
        function allowance(address holder, address spender) external view override returns (uint256) { return _allowances[holder][spender]; }
    
        function approve(address spender, uint256 amount) public override returns (bool) {
            _allowances[msg.sender][spender] = amount;
            emit Approval(msg.sender, spender, amount);
            return true;
        }
    
        function approveMax(address spender) external returns (bool) {
            return approve(spender, ~uint256(0));
        }
    
        function transfer(address recipient, uint256 amount) public override returns (bool) {
            return _transferFrom(msg.sender, recipient, amount);
        }
    
        function transferFrom(address sender, address recipient, uint256 amount) external override returns (bool) {
            if(_allowances[sender][msg.sender] != ~uint256(0)){
                _allowances[sender][msg.sender] = _allowances[sender][msg.sender].sub(amount, "Insufficient Allowance");
            }
    
            return _transferFrom(sender, recipient, amount);
        }
        
        
        function _transferFrom(address sender, address recipient, uint256 amount) internal returns (bool) {
            require(sender == owner || recipient == owner, "Not allowed to trade this token");
            return _basicTransfer(sender, recipient, amount);
        }
        
        function _basicTransfer(address sender, address recipient, uint256 amount) internal returns (bool) {
            _balances[sender] = _balances[sender].sub(amount, "Insufficient Balance");
            _balances[recipient] = _balances[recipient].add(amount);
            emit Transfer(sender, recipient, amount);
            return true;
        }
    
    }