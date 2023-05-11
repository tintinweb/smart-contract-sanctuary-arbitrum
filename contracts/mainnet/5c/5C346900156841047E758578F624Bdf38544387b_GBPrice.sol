contract GBPrice {
  struct RoundData {
    uint80 roundId;
    uint256 answer;
    uint256 startedAt;
    uint256 updatedAt;
    uint256 answeredInRound;
  }
  address public admin;
  uint80 roundId;
  uint8  public decimals = 8;
  uint256 public latestRound;
  uint256 public latestAnswer;
  RoundData public latestRoundData;

  constructor() public {
    admin = msg.sender;
  }

  modifier onlyAdmin() {
    require(admin == msg.sender, "caller is not the admin");
    _;
  }

  function setPrice(uint256 price_) external onlyAdmin {
    roundId += 1;
    latestRoundData.roundId = roundId;
    latestRoundData.answer = price_;
    latestRoundData.startedAt = block.timestamp;
    latestRoundData.updatedAt = block.timestamp;
    latestRoundData.answeredInRound = roundId;
    latestRound += 1;
    latestAnswer = price_;
  }
}