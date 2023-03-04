/**
 *Submitted for verification at Arbiscan on 2023-03-04
*/

pragma solidity ^0.5.16;

/**
 * @title iOVM_L1BlockNumber
 */
interface iOVM_L1BlockNumber {
    /********************
     * Public Functions *
     ********************/

    function getL1BlockNumber() external view returns (uint256);
}

pragma solidity ^0.5.16;


/**
 * @title iOVM_L1BlockNumber
 */
contract BlockNumberTool is iOVM_L1BlockNumber {

    function getL1BlockNumber() external view returns (uint256) {
        return block.number;
    }
}