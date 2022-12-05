// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.9; 

interface StakedGLP {
  function balanceOf(address account) external returns(uint256);
  function transfer(address to, uint256 amount) external returns(bool);
}

interface RewardRouter {
  function mintAndStakeGlpETH(uint256 minUSDG, uint256 minGLP) external payable;
}

contract AutoGLP {

  address public constant GMX_REWARD_ROUTER = 0xA906F338CB21815cBc4Bc87ace9e68c87eF8d8F1;
  address public constant STAKED_GLP = 0x5402B5F40310bDED796c7D0F3FF6683f5C0cFfdf;
  address public immutable MULTISIG;

  uint256 public lastTimeGLPBought;

  event GLPSent(address indexed sender, address indexed beneficiary, uint256 glpSent);
  event GLPBought(address indexed sender, address indexed beneficiary, uint256 glpBought, uint256 amountEthConverted, uint256 _timestamp);

  error AutoGLP_Cannot_Send_GLP();

  constructor(
    address multisig
  ) {
    MULTISIG = multisig;

    lastTimeGLPBought = block.timestamp;
  }

  function convertEthBalanceIntoGLP() external {
    uint256 ethBalance = address(this).balance;
    uint256 glpBalanceBefore = StakedGLP(STAKED_GLP).balanceOf(address(this));

    RewardRouter(GMX_REWARD_ROUTER).mintAndStakeGlpETH{value: ethBalance}(0, 0);

    uint256 glpBalanceAfter = StakedGLP(STAKED_GLP).balanceOf(address(this));

    lastTimeGLPBought = block.timestamp;

    emit GLPBought(msg.sender, address(this), glpBalanceAfter - glpBalanceBefore, ethBalance, block.timestamp);
  }

  function sendGLPToMultisig() external {
    if (block.timestamp < lastTimeGLPBought + 1020) revert AutoGLP_Cannot_Send_GLP();
  
    uint256 glpBalance = StakedGLP(STAKED_GLP).balanceOf(address(this));

    require(StakedGLP(STAKED_GLP).transfer(MULTISIG, glpBalance));

    emit GLPSent(msg.sender, MULTISIG, glpBalance);
  }

  receive() external payable {
    
  }
}