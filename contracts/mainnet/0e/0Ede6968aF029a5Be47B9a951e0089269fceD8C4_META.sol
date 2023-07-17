// SPDX-License-Identifier: BUSL-1.1

pragma solidity ^0.8.17;

import {ERC20} from "./ERC20.sol";
import {Constants} from "./Constants.sol";
import {Allowed} from "./Allowed.sol";

contract META is ERC20, Allowed {
    address public metaMgr;
    uint256 maxSupply = Constants.META_MAX_SUPPLY;

    constructor(address _metaMgr) ERC20("META Finance Token", "META") Allowed(msg.sender) {
        metaMgr = _metaMgr;
    }

    function setMetaManager(address _metaMgr) external onlyOwner {
        metaMgr = _metaMgr;
    }

    function mint(address user, uint256 amount) external returns (bool) {
        require(msg.sender == metaMgr, "Meta: Only meta fund authorised");
        require(totalSupply() + amount <= maxSupply, "Meta: Exceeding total supply");
        _mint(user, amount);
        return true;
    }

    function burn(address user, uint256 amount) external returns (bool) {
        require(msg.sender == metaMgr, "Meta: Only meta fund authorised");
        require(balanceOf(user) >= amount, "Meta: Insufficient balance");
        _burn(user, amount);
        return true;
    }
}