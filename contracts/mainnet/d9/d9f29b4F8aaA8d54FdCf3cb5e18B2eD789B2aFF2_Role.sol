// SPDX-License-Identifier: BUSL-1.1

pragma solidity ^0.8.17;

import {Governable} from "./Governable.sol";
import {IRole} from "./IRole.sol";

contract Role is IRole, Governable {
    mapping(address => bool) public distributionProvider;
    mapping(address => bool) public liquidationProvider;

    constructor() Governable(msg.sender) {}

    function setDistributionProvider(address _user, bool _bool) public override onlyGov {
        require(_user != address(0) && _user != address(this), "Invalid distribution provider");
        distributionProvider[_user] = _bool;
        emit DistributionProvider(_user, _bool);
    }

    function isDistributionProvider(address _user) external view override returns (bool) {
        return distributionProvider[_user];
    }

    function setLiquidationProvider(address _user, bool _bool) external override onlyGov {
        require(_user != address(0) && _user != address(this), "Invalid liquidation provider");
        liquidationProvider[_user] = _bool;
        emit LiquidationProvider(_user, _bool);
    }

    function isLiquidationProvider(address _user) external view override returns (bool) {
        return liquidationProvider[_user];
    }
}