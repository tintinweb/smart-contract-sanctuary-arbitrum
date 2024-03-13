// ⌘ ⌘ ⌘ ⌘ ⌘ ⌘ ⌘ ⌘ ⌘ ⌘ ⌘ ⌘ ⌘ ⌘ ⌘ ⌘ ⌘ ⌘ ⌘
// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity ^0.8.24;

/// @notice Simple nontransferable xNANI voting token.
/// @dev Includes method for staking and unstaking NANI.
/// @author nani.eth (Nani DAO)
contract NaniBar {
    event Transfer(address indexed from, address indexed to, uint256 amount);
    event Approval(address indexed from, address indexed to, uint256 amount);

    string public constant name = "NaniBar";
    string public constant symbol = "xNANI";
    uint256 public constant decimals = 18;
    address public constant NANI = 0x000000000000C6A645b0E51C9eCAA4CA580Ed8e8;
    uint256 public totalSupply;

    mapping(address => uint256) public balanceOf;
    mapping(address => mapping(address => uint256)) public allowance;
    mapping(address staker => mapping(uint256 timestamp => uint256)) 
        public staked;

    function approve(address to, uint256 amount) public returns (bool) {
        allowance[msg.sender][to] = amount;
        emit Approval(msg.sender, to, amount);
        return true;
    }

    function transfer(address, uint256) public returns (bool) {} // Nope.
    function transferFrom(address, address, uint256) public returns (bool) {}

    function stake(uint256 amount) public {
        uint256 totalNani = IToken(NANI).balanceOf(this);
        uint256 totalShares = totalSupply;
        if (totalShares == 0 || totalNani == 0) {
            unchecked {
                staked[msg.sender][block.timestamp] = (balanceOf[msg.sender] += amount);
                totalSupply += amount;
                emit Transfer(address(0), msg.sender, amount);
            }
        } else {
            unchecked {
                uint256 what = amount * totalShares / totalNani;
                staked[msg.sender][block.timestamp] = (balanceOf[msg.sender] += what);
                totalSupply += what;
                emit Transfer(address(0), msg.sender, what);
            }
        }
        IToken(NANI).transferFrom(msg.sender, this, amount);
    }

    function unstake(uint256 share) public {
        uint256 totalShares = totalSupply;
        uint256 what = share * IToken(NANI).balanceOf(this) / totalShares;
        balanceOf[msg.sender] -= share;
        unchecked {
            totalSupply -= share;
        }
        IToken(NANI).transfer(msg.sender, what);
        emit Transfer(msg.sender, address(0), share);
    }
}

/// @notice Simple token interaction interface.
interface IToken {
    function balanceOf(NaniBar) external returns (uint256);
    function transfer(address, uint256) external returns (bool);
    function transferFrom(address, NaniBar, uint256) external returns (bool);
}