/**
 *Submitted for verification at Arbiscan on 2023-05-11
*/

//SPDX-License-Identifier: MIT

pragma solidity 0.8.18;

interface ISRG20 {
    function balanceOf(address account) external view returns (uint256);
    function approveMax(address spender) external returns (bool);
    function _buy(uint256 buyAmount, uint256 minTokenOut, uint256 deadline) external returns (bool);
    function performBurn(uint256 amount) external;
    function allowance(address _owner, address spender) external view returns (uint256);
}

contract SRG20_BURNER {

    address public MAIN_TOKEN;
    address public SRG;
    address public CONTRACT;

    ISRG20 private srg;
    ISRG20 private main;

    constructor(address mainToken_, address srg_) {
        MAIN_TOKEN = mainToken_;
        SRG = srg_;

        srg = ISRG20(SRG);
        main = ISRG20(MAIN_TOKEN);
        CONTRACT = address(this);

        srg.approveMax(CONTRACT);
        srg.approveMax(mainToken_);

        main.approveMax(CONTRACT);
        main.approveMax(srg_);
    }

    function buyAndBurn() public {

        uint256 srg_bal = srg.balanceOf(CONTRACT);
        main._buy(srg_bal, 0, block.timestamp + 10 minutes);

        uint256 main_bal = main.balanceOf(CONTRACT);
        main.performBurn(main_bal);
    }

    function getSRGBalance() public view returns (uint256) {
        return srg.balanceOf(CONTRACT);
    }

    function getMainBalance() public view returns (uint256) {
        return main.balanceOf(CONTRACT);
    }

    function getAllowance() public view returns (uint256, uint256) {
        return (
            srg.allowance(CONTRACT, CONTRACT),
            main.allowance(CONTRACT, CONTRACT)
        );
    }

    function process() external {
        buyAndBurn();
    }

}