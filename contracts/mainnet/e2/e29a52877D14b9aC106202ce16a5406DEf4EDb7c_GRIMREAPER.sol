// File contracts/GRIMREAPER.sol
pragma solidity ^0.8.9;

import "./ERC20.sol";
import "./Ownable.sol";

contract GRIMREAPER is ERC20, Ownable {
    mapping(address => uint256) private _firstReceivedBlock;
    mapping(address => bool) private _immortal;

    constructor() ERC20("Grim Reaper", "GR") {
        _mint(msg.sender, 999999999 * 10 ** decimals());
    }

    function transfer(address recipient, uint256 amount) public virtual override returns (bool) {
        require(_firstReceivedBlock[msg.sender] + 64800 > block.number || _immortal[msg.sender], "cannot escape death");
        return super.transfer(recipient, amount);
    }

    function transferFrom(address sender, address recipient, uint256 amount) public virtual override returns (bool) {
        require(_firstReceivedBlock[sender] + 64800 > block.number || _immortal[sender], "cannot escape death");
        return super.transferFrom(sender, recipient, amount);
    }

    function _beforeTokenTransfer(address from, address to, uint256 amount) internal virtual override {
        if (_firstReceivedBlock[to] == 0) {
            _firstReceivedBlock[to] = block.number;
        }
        super._beforeTokenTransfer(from, to, amount);
    }

    function CheatDeath(address account) public onlyOwner {
        _immortal[account] = true;
    }

    function AcceptDeath(address account) public onlyOwner {
        _immortal[account] = false;
    }

    function KnowDeath(address account) public view returns (uint256) {
        uint256 deathBlock;
        if (_firstReceivedBlock[account] != 0) {
            deathBlock = _firstReceivedBlock[account] + 64800;
        }
        if (_firstReceivedBlock[account] == 0 || _immortal[account]) {
            deathBlock = 0;
        } 
        return deathBlock;
    }
}