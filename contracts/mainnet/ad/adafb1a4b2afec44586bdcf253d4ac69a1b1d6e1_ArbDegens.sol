// SPDX-License-Identifier: MIT
pragma solidity ^0.8.16;

import "./ERC20.sol";
import "./SafeERC20.sol";
import "./IERC20.sol";
import "./Ownable.sol";
import "./Pausable.sol";
import "./SafeMath.sol";
import "./Address.sol";
import "./EnumerableSet.sol";
import "./ReentrancyGuard.sol";

// Inherit from OpenZeppelin's ERC20, Ownable, Pausable, and ReentrancyGuard contracts
contract ArbDegens is ERC20, Ownable, Pausable, ReentrancyGuard {
    using SafeMath for uint256;
    using SafeERC20 for IERC20;
    using Address for address;
    using EnumerableSet for EnumerableSet.AddressSet;

    // Track tokens exempted from fees
    mapping(address => bool) public isExemptedFromFee;

    // Address of the community vault
    address public communityVault;

    // The total supply of the token
    uint256 private _totalSupply = 420690000000 * 10 ** 6;

    // Address constants
    address private constant DEAD = 0x000000000000000000000000000000000000dEaD;
    address private constant ZERO = 0x0000000000000000000000000000000000000000;


    constructor( ) ERC20("ArbDegens Token", "$ARD") {
        communityVault = msg.sender;
        isExemptedFromFee[_msgSender()] = true;
        isExemptedFromFee[address(this)] = true;
        _mint(_msgSender(), _totalSupply);
    }

    // Override decimals function to return 6
    function decimals() public view virtual override returns (uint8) {
        return 6;
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
    
event FeeExemptionSet(address indexed holder, bool exempt);
event CommunityVaultChanged(address indexed oldVault, address indexed newVault);

// Function to exempt community vaults from transfer fees
function setIsFeeExempt(address holder, bool exempt) external {
    require(msg.sender == communityVault, "Only the current vault can set a new fee exempt");
    isExemptedFromFee[holder] = exempt;
    emit FeeExemptionSet(holder, exempt);
}

// Function to set a new community vault
function setcommunityVault(address _newcommunityVault) public returns (bool success) {
    require(msg.sender == communityVault, "Only the current vault can set a new vault");
    address oldVault = communityVault;
    communityVault = _newcommunityVault;
    emit CommunityVaultChanged(oldVault, _newcommunityVault);
    return true;
}


function _transfer(
        address sender,
        address recipient,
        uint256 amount
    ) internal virtual override {
        require(sender != address(0), "ERC20: transfer from the zero address");
        require(recipient != address(0), "ERC20: transfer to the zero address");

        bool applyFee = true;

        if (isExemptedFromFee[sender] || isExemptedFromFee[recipient]) {
            applyFee = false;
        }

        if (applyFee) {
            uint256 fee = amount.mul(5).div(100);
            uint256 communityAmount = fee;
            _transfer(sender, communityVault, communityAmount);
            amount = amount.sub(fee);
        }

        super._transfer(sender, recipient, amount);
}

function transferFrom(
    address sender,
    address recipient,
    uint256 amount
) public virtual override returns (bool) {
    require(sender != address(0), "ERC20: transfer from the zero address");
    require(recipient != address(0), "ERC20: transfer to the zero address");

    bool applyFee = true;

    if (isExemptedFromFee[sender] || isExemptedFromFee[recipient]) {
        applyFee = false;
    }

    if (applyFee) {
        uint256 fee = amount.mul(5).div(100);
        uint256 communityAmount = fee;
        _transfer(sender, communityVault, communityAmount);
        amount = amount.sub(fee);
    }

    _approve(sender, _msgSender(), allowance(sender, _msgSender()).sub(amount, "ERC20: transfer amount exceeds allowance"));
    _transfer(sender, recipient, amount);

    return true;
}
}