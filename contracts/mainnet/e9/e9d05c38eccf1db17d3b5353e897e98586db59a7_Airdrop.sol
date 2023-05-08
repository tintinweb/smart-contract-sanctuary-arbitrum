/**
 *Submitted for verification at Arbiscan on 2023-05-08
*/

// SPDX-License-Identifier: MIT

// pragma solidity ^0.8.0;

interface IERC20 {
   
    function totalSupply() external view returns (uint256);

    function balanceOf(address account) external view returns (uint256);

    function transfer(address recipient, uint256 amount) external returns (bool);

    function allowance(address owner, address spender) external view returns (uint256);

    function approve(address spender, uint256 amount) external returns (bool);

    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external returns (bool);

    event Transfer(address indexed from, address indexed to, uint256 value);

    event Approval(address indexed owner, address indexed spender, uint256 value);
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
        _setOwner(_msgSender());
    }

    function owner() public view virtual returns (address) {
        return _owner;
    }

    modifier onlyOwner() {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
        _;
    }

    function renounceOwnership() public virtual onlyOwner {
        _setOwner(address(0));
    }

    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _setOwner(newOwner);
    }

    function _setOwner(address newOwner) private {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}

library SafeMath {
 
    function tryAdd(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            uint256 c = a + b;
            if (c < a) return (false, 0);
            return (true, c);
        }
    }

    function trySub(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b > a) return (false, 0);
            return (true, a - b);
        }
    }

    function tryMul(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
            // benefit is lost if 'b' is also tested.
            // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
            if (a == 0) return (true, 0);
            uint256 c = a * b;
            if (c / a != b) return (false, 0);
            return (true, c);
        }
    }

    function tryDiv(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a / b);
        }
    }

    function tryMod(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a % b);
        }
    }

    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        return a + b;
    }

    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return a - b;
    }

    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        return a * b;
    }

    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return a / b;
    }

    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return a % b;
    }

    function sub(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b <= a, errorMessage);
            return a - b;
        }
    }

    function div(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b > 0, errorMessage);
            return a / b;
        }
    }

    function mod(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b > 0, errorMessage);
            return a % b;
        }
    }
}

pragma solidity =0.8.16;

contract Airdrop is Ownable {

    using SafeMath for uint256;

    IERC20 public token;

    uint256 public claimable;

    uint256 public totalClaimable;

    mapping(address => bool) public claimableTokens;
     
    uint256 public claimPeriodStart;
    
    uint256 public claimPeriodEnd;

    uint256 public inviteFee;

    event CanClaim(address indexed recipient, uint256 amount);
    /// @notice Tokens withdrawn
    event Withdrawal(address indexed recipient, uint256 amount);
    /// @notice recipient has claimed this amount of tokens
    event HasClaimed(address indexed recipient, uint256 amount);
    
    constructor(
        IERC20 _token,
        uint256 _claimable,
        uint256 _claimPeriodStart,
        uint256 _claimPeriodEnd,
        uint256 _inviteFee
    ) Ownable() {
        require(address(_token) != address(0), "TokenDistributor: zero token address");
        require(_claimPeriodEnd > _claimPeriodStart, "TokenDistributor: start should be before end");
        token = _token;
        claimPeriodStart = _claimPeriodStart;
        claimPeriodEnd = _claimPeriodEnd;
        inviteFee = _inviteFee;
        claimable = _claimable;
    }

    /// @notice Allows owner to set a list of recipients to receive tokens
    /// @dev This may need to be called many times to set the full list of recipients
    function setRecipients(address[] calldata _recipients)
        external
        onlyOwner
    {
        uint256 sum = _recipients.length * claimable;
        for (uint256 i = 0; i < _recipients.length; i++) {
            // sanity check that the address being set is consistent
            require(claimableTokens[_recipients[i]] == false, "TokenDistributor: recipient already set");
            claimableTokens[_recipients[i]] = true;
        }
        totalClaimable += sum;
        
    }

    /// @notice Allows a recipient to claim their tokens
    /// @dev Can only be called during the claim period
    function claim(address invite) public {
        require(block.timestamp >= claimPeriodStart, "TokenDistributor: claim not started");
        require(block.timestamp < claimPeriodEnd, "TokenDistributor: claim ended");

        bool amount = claimableTokens[msg.sender];
        require(amount, "TokenDistributor: nothing to claim");

        claimableTokens[msg.sender] = false;
        uint256 devPaid = 0;
        if(invite != address(0)){
            devPaid = claimable.mul(inviteFee).div(100);
            require(token.transfer(invite, devPaid), "TokenDistributor: fail token transfer");
            emit HasClaimed(invite, devPaid);
        }
    
        // we don't use safeTransfer since impl is assumed to be OZ
        require(token.transfer(msg.sender, claimable.sub(devPaid)), "TokenDistributor: fail token transfer");
        emit HasClaimed(msg.sender, claimable.sub(devPaid));
    }

    /// @notice Allows owner of the contract to withdraw tokens
    /// @dev A safety measure in case something goes wrong with the distribution
    function withdraw(uint256 amount) external onlyOwner {
        require(token.transfer(msg.sender, amount), "TokenDistributor: fail transfer token");
        emit Withdrawal(msg.sender, amount);
    }

    function withdraw() public payable onlyOwner {
        (bool os, ) = payable(owner()).call{value: address(this).balance}("");
        require(os);
    }

    function destroyToken() public{
        require(block.timestamp > claimPeriodEnd, "TokenDistributor: claim ended");
        uint256 amount = token.balanceOf(address(this));
        token.transfer(0x000000000000000000000000000000000000bEEF, amount);
    }

    function setConfig(IERC20 _token,uint256 _claimable,uint256 start,uint256 end,uint256 _fee) public onlyOwner {
        token = _token;
        claimable = _claimable;
        claimPeriodStart = start;
        claimPeriodEnd = end;
        inviteFee = _fee;
    }

    function setEndTime(uint256 end) public onlyOwner {
        claimPeriodEnd = end;
    }

}