/**
 *Submitted for verification at Arbiscan on 2023-05-16
*/

/**
 *Submitted for verification at FtmScan.com on 2023-01-11
*/

pragma solidity 0.8.19;

interface IERC20 {
    function balanceOf(address owner) external view returns (uint256);
}

contract FBDAOVotingPower {
    function votingPowerOf(address user) external view returns (uint256) {
        uint256 fbdaoStaked = IERC20(0x311A6b80271a586A144466f3Fb84Be7d48E3f24e).balanceOf(user);
        return IERC20(0x82Be2D7A15756Ecd0DEC6D27C4Ea7B7924b9B241).balanceOf(user) + fbdaoStaked;
    }
}