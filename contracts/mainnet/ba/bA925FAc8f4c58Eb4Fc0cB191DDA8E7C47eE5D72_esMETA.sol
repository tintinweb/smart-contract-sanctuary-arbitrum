// SPDX-License-Identifier: BUSL-1.1

pragma solidity ^0.8.17;

import {ERC20Votes, ERC20Permit, ERC20} from "./ERC20Votes.sol";
import {Governable} from "./Governable.sol";
import {IMetaManager} from "./IMetaManager.sol";

import {Constants} from "./Constants.sol";

contract esMETA is ERC20Votes, Governable {
    mapping(address => bool) public esMETAMinter;
    IMetaManager public metaMgr;

    uint256 maxMinted = Constants.ESMETA_MAX_SUPPLY;
    uint256 public totalMinted;

    constructor(address _metaMgr) ERC20Permit("esMETA") 
    ERC20("Escrow Meta Token", "esMETA") Governable(msg.sender){
        metaMgr = IMetaManager(_metaMgr);
    }
    
     modifier onlyAllowed(){
        address caller = msg.sender;
        require(caller == address(metaMgr) || esMETAMinter[caller] == true,"esMeta: not authorized");
        _;
    }

    function _transfer(address from, address to, uint256 amount) internal virtual override {
        revert("not authorized");
    }

    function setMinter(address[] calldata _contracts, bool[] calldata _bools) external onlyGov {
        for (uint256 i = 0; i < _contracts.length; i++) {
            esMETAMinter[_contracts[i]] = _bools[i];
        }
    }

    function setMetaManager(address _metaMgr) external onlyGov {
        require(_metaMgr != address(0), "esMeta: Invalid metaManager address");
        metaMgr = IMetaManager(_metaMgr);
    }

    function mint(address _user, uint256 _amount) external onlyAllowed returns (bool) {
        address caller = msg.sender;
        uint256 reward = _amount; 
        if (caller != address(metaMgr)) {
            metaMgr.refreshReward(_user);
            if (totalMinted + reward > maxMinted) {
                reward = maxMinted - totalMinted;
            }
            totalMinted += reward;
        }
        _mint(_user, reward);
        return true;
    }

    function burn(address _user, uint256 _amount) external onlyAllowed returns (bool) {
        address caller = msg.sender;
             require(balanceOf(_user) >= _amount, "esMeta: Insufficient balance");
        if (caller != address(metaMgr)) {
            metaMgr.refreshReward(_user);
        }
        _burn(_user, _amount);
        return true;
    }
}