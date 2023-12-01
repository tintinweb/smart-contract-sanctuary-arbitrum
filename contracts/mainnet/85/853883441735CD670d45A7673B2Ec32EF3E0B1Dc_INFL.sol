// SPDX-License-Identifier: Unlicensed
pragma solidity ^0.8.0;

interface IERC20 {

    function totalSupply() external view returns (uint256);
    function balanceOf(address account) external view returns (uint256);
    function transfer(address recipient, uint256 amount) external returns (bool);
    function allowance(address owner, address spender) external view returns (uint256);
    function approve(address spender, uint256 amount) external returns (bool);
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

// SPDX-License-Identifier: Unlicensed
pragma solidity ^0.8.0;

interface Iinfl {

    function addPayment() external payable;

    function emergencyWithdraw() external;

    function inflWithdraw() external;

    function setTokenAddress(address _token) external;

    function addInfl(address _infl, uint256 _percent) external;

    function deleteInfl(address infl) external;
}

// SPDX-License-Identifier: Unlicensed
pragma solidity ^0.8.0;

import "./IERC20.sol";

interface IOE is IERC20 {
    function getIsOdd() external view returns(bool);
}

// SPDX-License-Identifier: Unlicensed
pragma solidity ^0.8.0;

import "./Ownable.sol";
import "../interfaces/Iinfl.sol";
import "../interfaces/IOE.sol";

contract INFL is Ownable, Iinfl {

    struct infl {
        uint256 balance;
        uint256 totalIncome;
        uint256 totalWithdraw;
        uint256 percent;
    }

    mapping(address => infl) public users;
    address[] public activeUsers;
    uint256 public totalShare;

    address public token;

    receive() external payable {}

    fallback() external payable {}

    function _getInfl(address _infl) internal view returns(address, uint256) {
        address zInfl = address(0);
        for (uint256 i = 0; i < activeUsers.length; ++i) {
            if (activeUsers[i] == _infl) {
                return (activeUsers[i], i);
            }
        }
        return (zInfl, 0);
    }

    function setTokenAddress(address _token) external onlyOwner {
        require(_token != address(0), 'Error: zero address');
        token = _token;
    }

    function addInfl(address _infl, uint256 _percent) external onlyOwner {
        (address rInfl,) = _getInfl(_infl);

        if (rInfl == address(0)) {
            activeUsers.push(_infl);
        }
        if (users[_infl].percent > 0) {
            totalShare -= users[_infl].percent;
        }

        users[_infl].percent = _percent;
        totalShare += users[_infl].percent;
    }

    function deleteInfl(address _infl) external onlyOwner {
        (address rInfl, uint256 index) = _getInfl(_infl);
        require(rInfl != address(0), 'Error: user is not exist');

        address lastUser = activeUsers[activeUsers.length - 1];

        totalShare -= users[rInfl].percent;

        activeUsers[index] = lastUser;
        activeUsers.pop();
    }

    function emergencyWithdraw() external onlyOwner {
        uint256 balance = address(this).balance;

        payable(owner()).transfer(balance);
    }

    function inflWithdraw() external {
        uint256 balance = users[msg.sender].balance;
        users[msg.sender].balance = 0;
        users[msg.sender].totalWithdraw += balance;

        payable(msg.sender).transfer(balance);
    }

    function addPayment() external payable {
        uint256 amount = msg.value;
        uint256 chunk = amount / totalShare;

        for (uint256 i = 0; i < activeUsers.length; ++i) {
            users[activeUsers[i]].balance += chunk * users[activeUsers[i]].percent;
            users[activeUsers[i]].totalIncome += chunk * users[activeUsers[i]].percent;
        }
    }
}

// SPDX-License-Identifier: Unlicensed
pragma solidity ^0.8.0;

abstract contract Context {

    function _msgSender() internal view virtual returns (address payable) {
        return payable(msg.sender);
    }

    function _msgData() internal view virtual returns (bytes memory) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
}

contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    constructor () {
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

    function waiveOwnership() public virtual onlyOwner {
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }

    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}