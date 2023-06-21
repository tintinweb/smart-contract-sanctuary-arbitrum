/**
 *Submitted for verification at Arbiscan on 2023-06-21
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

library SafeMath {
    /**
     * @dev Multiplies two unsigned integers, reverts on overflow.
     */
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
        // benefit is lost if 'b' is also tested.
        // See: https://github.com/OpenZeppelin/openzeppelin-solidity/pull/522
        if (a == 0) {
            return 0;
        }
        uint256 c = a * b;
        require(c / a == b);
        return c;
    }

    /**
     * @dev Integer division of two unsigned integers truncating the quotient, reverts on division by zero.
     */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        // Solidity only automatically asserts when dividing by 0
        require(b > 0);
        uint256 c = a / b;
        // assert(a == b * c + a % b); // There is no case in which this doesn't hold
        return c;
    }

    /**
     * @dev Subtracts two unsigned integers, reverts on overflow (i.e. if subtrahend is greater than minuend).
     */
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b <= a);
        uint256 c = a - b;
        return c;
    }

    /**
     * @dev Adds two unsigned integers, reverts on overflow.
     */
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a);
        return c;
    }

    /**
     * @dev Divides two unsigned integers and returns the remainder (unsigned integer modulo),
     * reverts when dividing by zero.
     */
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b != 0);
        return a % b;
    }
}

contract com_Contract{
    
    using SafeMath for uint256; 
    uint256 private percentage88 = 88;
    uint256 private percentage12 = 12;
    uint256 private percentage19 = 19;
    uint256 private percentage70 = 70;
    uint256 private percentage6 = 6;
    uint256 private Devpercentage = 5;
    uint256 private FirstLevelPer = 5;
    uint256 private BuyerLevelPer1_10 = 4;
    uint256 private BuyerLevelPer11_20 = 2;
    uint256 private BuyerLevelPer21_30 = 1;
    uint256 private constant baseDivider = 100;
    
    function percentage(uint256 _tokenAmount, uint256 _round) 
    public view returns(uint256[] memory)
    {
        uint256[] memory levelPercentage = new uint256[](7);
        if(_round < 2)
        {
            levelPercentage[0] = (_tokenAmount.mul(percentage88)).div(baseDivider);
            levelPercentage[1] = (_tokenAmount.mul(percentage12)).div(baseDivider);
            levelPercentage[2] = (_tokenAmount.mul(FirstLevelPer)).div(baseDivider);
            levelPercentage[3]  = (_tokenAmount.mul(BuyerLevelPer1_10)).div(baseDivider);
            levelPercentage[4] = (_tokenAmount.mul(BuyerLevelPer11_20)).div(baseDivider);
            levelPercentage[5] = (_tokenAmount.mul(BuyerLevelPer21_30)).div(baseDivider);
            levelPercentage[6] = (_tokenAmount.mul(percentage6)).div(baseDivider);
        }
        else{
            levelPercentage[0] = (_tokenAmount.mul(percentage70)).div(baseDivider);
            levelPercentage[1] = (_tokenAmount.mul(percentage19)).div(baseDivider);
            levelPercentage[2] = (_tokenAmount.mul(FirstLevelPer)).div(baseDivider);
            levelPercentage[3]  = (_tokenAmount.mul(BuyerLevelPer1_10)).div(baseDivider);
            levelPercentage[4] = (_tokenAmount.mul(BuyerLevelPer11_20)).div(baseDivider);
            levelPercentage[5] = (_tokenAmount.mul(BuyerLevelPer21_30)).div(baseDivider);
            levelPercentage[6] = (_tokenAmount.mul(percentage6)).div(baseDivider);

        }
        return levelPercentage;
    }
  
}