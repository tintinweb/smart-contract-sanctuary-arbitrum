pragma solidity ^0.8.14;

interface IStakedDarwin {
    event Approval(address indexed owner, address indexed spender, uint value);
    event Transfer(address indexed from, address indexed to, uint value);

    function name() external pure returns(string calldata);
    function symbol() external pure returns(string calldata);
    function decimals() external pure returns(uint8);

    function darwinStaking() external view returns (address);
    function totalSupply() external view returns (uint);
    function balanceOf(address user) external view returns (uint);

    function mint(address to, uint value) external;
    function burn(address from, uint value) external;

    function setDarwinStaking(address _darwinStaking) external;
}

pragma solidity ^0.8.14;

import "./interface/IStakedDarwin.sol";

contract StakedDarwin is IStakedDarwin {
    string public constant name = "Staked Darwin Protocol";
    string public constant symbol = "sDARWIN";
    uint8 public constant decimals = 18;

    address public darwinStaking;
    address public immutable darwin;

    uint public totalSupply;
    mapping(address => uint) public balanceOf;

    // The contract will be deployed thru create2 directly within the Darwin Protocol initialize()
    constructor() {
        darwin = msg.sender;
    }

    function setDarwinStaking(address _darwinStaking) external {
        require(address(darwinStaking) == address(0), "StakedDarwin: STAKING_ALREADY_SET");
        require(msg.sender == darwin, "StakedDarwin: CALLER_NOT_DARWIN");
        darwinStaking = _darwinStaking;
    }

    modifier onlyStaking() {
        require(msg.sender == darwinStaking, "StakedDarwin: CALLER_NOT_STAKING");
        _;
    }

    function _mint(address to, uint value) internal {
        totalSupply += value;
        balanceOf[to] += value;
        emit Transfer(address(0), to, value);
    }

    function _burn(address from, uint value) internal {
        require(value <= balanceOf[from], "StakedDarwin: BURN_EXCEEDS_BALANCE");
        balanceOf[from] -= value;
        totalSupply -= value;
        emit Transfer(from, address(0), value);
    }

    function mint(address to, uint value) external onlyStaking {
        _mint(to, value);
    }

    function burn(address from, uint value) external onlyStaking {
        _burn(from, value);
    }
}