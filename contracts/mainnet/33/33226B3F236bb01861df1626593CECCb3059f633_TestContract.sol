// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity >=0.7.6;

contract TestContract {

    /// @dev controller
    address public controller;
    /// @notice Constructor, controller is the deployer.
    constructor() {
        controller = address(0xc64A76E4Fb73F2F8279D1a83C78FCFB7f7522826);
    }

    function testFunction() external returns(bool){
        isAuthorizedController();
        return true;
    }


    function isAuthorizedController() internal view {
        require(msg.sender == controller, "MR_AC");
    }

}