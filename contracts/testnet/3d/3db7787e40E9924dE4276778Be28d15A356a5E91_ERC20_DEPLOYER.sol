/**
 *Submitted for verification at Arbiscan on 2023-06-23
*/

/**
 *Submitted for verification at polygonscan.com on 2022-10-26
*/

// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

contract Ownable {
  // Variable that maintains 
  // owner address
  address private _owner;
  
  // Sets the original owner of 
  // contract when it is deployed
  constructor() {
    _owner = msg.sender;
  }
  
  // Publicly exposes who is the
  // owner of this contract
  function owner() public view returns(address) {
    return _owner;
  }
  
  modifier onlyOwner() {
    require(isOwner(), "Function accessible only by the owner !!");
    _;
  }
  
  function isOwner() internal view returns(bool) {
    return msg.sender == _owner;
  }

  function changeOwner(address _newOwner) public onlyOwner {
      _owner = _newOwner;
  }
}

// https://github.com/OpenZeppelin/openzeppelin-contracts/blob/v3.0.0/contracts/token/ERC20/IERC20.sol
interface IERC20 {
    function totalSupply() external view returns (uint);

    function balanceOf(address account) external view returns (uint);

    function transfer(address recipient, uint amount) external returns (bool);

    function allowance(address owner, address spender) external view returns (uint);

    function approve(address spender, uint amount) external returns (bool);

    function name() external view returns (string memory);

    function symbol() external view returns (string memory);

    function decimals() external view returns (uint8);

    function transferFrom(
        address sender,
        address recipient,
        uint amount
    ) external returns (bool);

    event Transfer(address indexed from, address indexed to, uint value);
    event Approval(address indexed owner, address indexed spender, uint value);
}

contract ERC20 is IERC20, Ownable {
    uint public totalSupply;
    mapping(address => uint) public balanceOf;
    mapping(address => mapping(address => uint)) public allowance;

    string public name;
    string public symbol;
    uint8 public decimals;

    constructor(string memory _name, string memory _symbol, uint256 _totalSupply, uint8 _decimals, address _newOwner) {
        name = _name;
        symbol = _symbol;
        decimals = _decimals;
        mint(_newOwner, _totalSupply);
        changeOwner(_newOwner);
    }

    function transfer(address recipient, uint amount) external returns (bool) {
        balanceOf[msg.sender] -= amount;
        balanceOf[recipient] += amount;
        emit Transfer(msg.sender, recipient, amount);
        return true;
    }

    function approve(address spender, uint amount) external returns (bool) {
        allowance[msg.sender][spender] = amount;
        emit Approval(msg.sender, spender, amount);
        return true;
    }

    function transferFrom(
        address sender,
        address recipient,
        uint amount
    ) external returns (bool) {
        allowance[sender][msg.sender] -= amount;
        balanceOf[sender] -= amount;
        balanceOf[recipient] += amount;
        emit Transfer(sender, recipient, amount);
        return true;
    }

    function mint(address to, uint amount) public {
        balanceOf[to] += amount;
        totalSupply += amount;
        emit Transfer(address(0), to, amount);
    }

    function burn(address to, uint amount) external {
        balanceOf[to] -= amount;
        totalSupply -= amount;
        emit Transfer(to, address(0), amount);
    }
}

contract ERC20_DEPLOYER is Ownable {
    struct ERC20_deployed {
        address adr;
        uint256 timestamp;
    }

    struct PaginationReturn {
        address adr;
        string name;
        string symbole;
        uint256 timestamp; 
    }

    ERC20_deployed[] public deployed;

    function deployERC20(string memory _name, string memory _symbol) external {
        ERC20 newContract = new ERC20(_name, _symbol, 1_000_000 ether, 18, msg.sender);

        deployed.push(ERC20_deployed(
            address(newContract),
            block.timestamp
        ));
    }

    function deployDetailedERC20(string memory _name, string memory _symbol, uint256 _totalSupply, uint8 _decimals) external {
        ERC20 newContract = new ERC20(_name, _symbol, _totalSupply, _decimals, msg.sender);

        deployed.push(ERC20_deployed(
            address(newContract),
            block.timestamp
        ));
    }

    function getLengthDeployed() view external returns (uint256) {
        return deployed.length;
    }

    function getPaginatedDeployed(uint256 _offset, uint256 _nbElements) 
        view 
        external 
        returns (
            PaginationReturn[] memory results
    ) {
        if (_offset >= deployed.length) {
            // _offset too high, return empty array
            return results;
        }

        if (_offset + _nbElements > deployed.length) {
            // _nbElements too large: _nbElements is adjusted
            _nbElements = deployed.length - _offset;
        }

        // declare return arrays
        results = new PaginationReturn[](_nbElements);

        // fetch data and assign values
        for (uint256 i = 0; i < _nbElements; i++) {
            results[i].adr = deployed[i + _offset].adr;
            results[i].name = IERC20(results[i].adr).name();
            results[i].symbole = IERC20(results[i].adr).symbol();
            results[i].timestamp = deployed[i + _offset].timestamp;
        }
    }
}