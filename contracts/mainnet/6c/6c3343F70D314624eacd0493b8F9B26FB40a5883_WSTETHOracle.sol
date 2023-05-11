interface IChainLink {
   struct RoundData {
    uint80 roundId;
    uint256 answer;
    uint256 startedAt;
    uint256 updatedAt;
    uint256 answeredInRound;
  }
  function latestRoundData() external view returns (RoundData memory); 
}

contract WSTETHOracle {
 
  address public admin;
  IChainLink public priceFeedETH;
  IChainLink public priceFeedwstETH;
  uint256 public decimals = 8;

  constructor(IChainLink priceFeedETH_, IChainLink priceFeedwstETH_) {
    admin = msg.sender;
    priceFeedETH = priceFeedETH_;
    priceFeedwstETH = priceFeedwstETH_;
  }

  modifier onlyAdmin() {
    require(admin == msg.sender, "caller is not the admin!");
    _;
  }

  function latestRoundData() external view returns(IChainLink.RoundData memory) {
    IChainLink.RoundData memory roundData = priceFeedETH.latestRoundData();
    IChainLink.RoundData memory wstRoundData = priceFeedwstETH.latestRoundData();
    wstRoundData.answer =  roundData.answer * wstRoundData.answer / 1e18;
    return wstRoundData;
  }

}