/**
 *Submitted for verification at Arbiscan on 2023-06-23
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

    function transferFrom(
        address sender,
        address recipient,
        uint amount
    ) external returns (bool);

    function mint(address recipient, uint256 amount) external returns (bool);
}

contract DBRewardPool  is Ownable {
    bool shouldMint = true;

    mapping(address => bool) public isMinter;

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

    function setMint(bool should) public onlyOwner {
        shouldMint = should;
    }

    function mint(uint256 amount, IERC20 token, address recipient) public onlyMinters {
        if (token.balanceOf(address(this)) >= amount) {
            token.transfer(recipient, amount);
        } else {
            if(shouldMint) {
                token.mint(recipient, amount);
            } else {
                return;
            }
        }
    }
}