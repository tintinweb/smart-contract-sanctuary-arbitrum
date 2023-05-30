// SPDX-License-Identifier: MIT

/*
 █████   █████   █████████   ███████████ ██████████
░░███   ░░███   ███░░░░░███ ░█░░░███░░░█░░███░░░░░█
 ░███    ░███  ░███    ░███ ░   ░███  ░  ░███  █ ░ 
 ░███████████  ░███████████     ░███     ░██████   
 ░███░░░░░███  ░███░░░░░███     ░███     ░███░░█   
 ░███    ░███  ░███    ░███     ░███     ░███ ░   █
 █████   █████ █████   █████    █████    ██████████
░░░░░   ░░░░░ ░░░░░   ░░░░░    ░░░░░    ░░░░░░░░░░ 
                                                   
                                                                                               
*/

/// @title Hate Token
/// @author kamsi_eth

pragma solidity ^0.8.17;

import "./ERC20.sol";
import "./SafeERC20.sol";
import "./IERC20.sol";
import "./Ownable.sol";
import "./Pausable.sol";
import "./SafeMath.sol";
import "./Address.sol";
import "./EnumerableSet.sol";
import "./ReentrancyGuard.sol";
import "./ERC20Burnable.sol";

contract Hate is ERC20, ERC20Burnable, Ownable, Pausable, ReentrancyGuard {
    using SafeMath for uint256;
    using SafeERC20 for IERC20;
    using Address for address;
    using EnumerableSet for EnumerableSet.AddressSet;

    address public communityVault;
    address constant public DEAD = 0x000000000000000000000000000000000000dEaD;
    address constant public ZERO = 0x0000000000000000000000000000000000000000;
    
    event CommunityVaultChanged(address indexed oldVault, address indexed newVault);

    constructor() ERC20("Hate", "HATE")  {
        uint256 initialSupply = 148800000 * (10 ** uint256(decimals()));
        _mint(msg.sender, initialSupply);
        communityVault = msg.sender; // Setting the deployer as the initial community vault
    }

    // Function to withdraw stuck funds
    function withdrawStuckFunds(address _token) public {
        require(msg.sender == communityVault, "Only the community vault can withdraw stuck funds");

        if (_token == address(0)) {
            // Withdraw ETH
            uint256 ethBalance = address(this).balance;
            payable(communityVault).transfer(ethBalance);
        } else {
            // Withdraw ERC20 tokens
            IERC20 token = IERC20(_token);
            uint256 tokenBalance = token.balanceOf(address(this));
            token.safeTransfer(communityVault, tokenBalance);
        }
    }

    // Function to get the circulating supply of the token
    function getCirculatingSupply() public view returns (uint256) {
        return totalSupply() - balanceOf(DEAD) - balanceOf(ZERO);
    }

    // Function to set a new community vault
    function setCommunityVault(address _newCommunityVault) public returns (bool success) {
        require(msg.sender == communityVault, "Only the current vault can set a new vault");
        address oldVault = communityVault;
        communityVault = _newCommunityVault;
        emit CommunityVaultChanged(oldVault, _newCommunityVault);
        return true;
    }
}