// SPDX-License-Identifier: MIT

pragma solidity >0.8.0;
import "./IERC20.sol";

contract BirdFundsHolder {
    event FundHeld(string FundName, uint256 FundNo, address Token, address Receiver, uint256 Amount, uint256 ReleaseTime);
    event FundReleased(uint256 FundNo, address Token, address Receiver, uint256 Amount);
    struct Fund {
        string FundName;
        IERC20 Token;
        address Receiver;
        uint256 TokenAmount;
        uint256 ReleaseTime;
        bool Released;
    }
    string public Name;
    string public Twitter;
    uint256 public NoOfFundsHeld;
    mapping(uint256 => Fund) public FundsHeld;

    constructor() {
        Name = "Bird Funds Holder";
        Twitter = "https://twitter.com/BirdArbitrum";
    }

    function holdFunds(string memory _FundName, address _Token, address _Receiver, uint256 _TokenAmount, uint256 _ReleaseTime) external {
        require(_Token != address(0) && _Receiver != address(0) && _TokenAmount > 0 && _ReleaseTime > block.timestamp,"Fund Initiation Variables Error");
        NoOfFundsHeld++;
        IERC20(_Token).transferFrom(msg.sender, address(this), _TokenAmount);
        FundsHeld[NoOfFundsHeld] = Fund(_FundName, IERC20(_Token), _Receiver, _TokenAmount, _ReleaseTime, false);
        emit FundHeld(_FundName, NoOfFundsHeld, _Token, _Receiver, _TokenAmount, _ReleaseTime);
    }

    function releaseFunds(uint256 fundNo) external {
        Fund memory thisFund = FundsHeld[fundNo];
        require(block.timestamp >= thisFund.ReleaseTime,"Funds not released yet.");
        require(!thisFund.Released,"Funds already released.");
        FundsHeld[fundNo].Released = true;
        thisFund.Token.transfer(thisFund.Receiver, thisFund.TokenAmount);
        emit FundReleased(fundNo, address(thisFund.Token), thisFund.Receiver, thisFund.TokenAmount);
    }

}