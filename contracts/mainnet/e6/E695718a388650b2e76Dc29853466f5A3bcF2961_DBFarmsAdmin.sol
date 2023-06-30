/**
 *Submitted for verification at Arbiscan on 2023-06-30
*/

// SPDX-License-Identifier: AGPL-3.0
pragma solidity =0.8.19;

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
interface IERC20 {
    function totalSupply() external view returns (uint);
    function balanceOf(address account) external view returns (uint);
    function transfer(address recipient, uint amount) external returns (bool);
    function allowance(address owner, address spender) external view returns (uint);
    function approve(address spender, uint amount) external returns (bool);
    function mint(address _to, uint256 _amount) external returns (bool);
    function transferFrom(address sender, address recipient, uint amount) external returns (bool);
    function decimals() external view returns (uint8);
}
interface Master {
    function setRewardWallet(address _newWallet) external;
    function addPool(string memory _name, uint256 _allocPoint, IERC20 _lpToken, bool _isLp) external;
    function setPool(uint256 _pid, uint256 _allocPoint) external;
    function setMultiplier(uint256 _newValue) external;
}

contract DBFarmsAdmin is Ownable {
    address internal masterContract;

    constructor(address _masterContract) {
        masterContract = _masterContract;
    }

    function setRewardWallet(address _newWallet) public onlyOwner {
        Master(masterContract).setRewardWallet(_newWallet);
    }
    function setMultiplier(uint256 _newValue) public onlyOwner {
        Master(masterContract).setMultiplier(_newValue);
    }
    function addPool(string memory _name, uint256 _allocPoint, IERC20 _lpToken, bool _isLp) public onlyOwner {
        Master(masterContract).addPool(_name, _allocPoint, _lpToken, _isLp);
    }
    function setPool(uint256 _pid, uint256 _allocPoint) public onlyOwner {
        Master(masterContract).setPool(_pid, _allocPoint);
    }
}