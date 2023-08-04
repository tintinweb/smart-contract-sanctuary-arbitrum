/**
 *Submitted for verification at Arbiscan on 2023-08-04
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
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
}
abstract contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);
    constructor() {
        _transferOwnership(_msgSender());
    }

    function owner() public view virtual returns (address) {
        return _owner;
    }

    modifier onlyOwner() {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
        _;
    }

    function renounceOwnership() public virtual onlyOwner {
        _transferOwnership(address(0));
    }

    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _transferOwnership(newOwner);
    }

    function _transferOwnership(address newOwner) internal virtual {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}

contract DBFarmsAdmin is Ownable {
    using SafeMath for uint256;

    uint256 public vaultMultiplier = 100;
    mapping (uint => bool) public blockedFarms;
    mapping (address => bool) public allowedAddress;

    function getVaultMultiplier() public view returns(uint256) {
        return vaultMultiplier;
    }
    function isAllowed(address account) public view returns(bool) {
        return allowedAddress[account];
    }
    function isBlocked(uint _pid) public view returns(bool) {
        return blockedFarms[_pid];
    }

    function setVaultMultiplier(uint256 _newMultiplier) public onlyOwner {
        vaultMultiplier = _newMultiplier;
    }
    function blockFarm(uint _pid) public onlyOwner {
        blockedFarms[_pid] = true;
    }
    function unblockFarm(uint _pid) public onlyOwner {
        blockedFarms[_pid] = false;
    }
    function allowAddress(address account) public onlyOwner {
        allowedAddress[account] = true;
    }
    function unAllowAddress(address account) public onlyOwner {
        allowedAddress[account] = false;
    }
}