// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface AggregatorV3Interface {
  function decimals() external view returns (uint8);

  function description() external view returns (string memory);

  function version() external view returns (uint256);

  function getRoundData(
    uint80 _roundId
  ) external view returns (uint80 roundId, int256 answer, uint256 startedAt, uint256 updatedAt, uint80 answeredInRound);

  function latestRoundData()
    external
    view
    returns (uint80 roundId, int256 answer, uint256 startedAt, uint256 updatedAt, uint80 answeredInRound);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.8;

import "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";
import "./PriceConverter.sol";

error NotOwner();

contract FundMe {
    using PriceConverter for uint256;

    mapping(address => uint256) public addressToAmountFunded;
    address[] public funders;

    // Could we make this constant?  /* hint: no! We should make it immutable! */
    address public /* immutable */ i_owner;
    uint256 public constant MINIMUM_USD = 50 * 10 ** 18;
    
    AggregatorV3Interface public priceFeed;
    constructor(address priceFeedAddress) {
        i_owner = msg.sender;
        priceFeed = AggregatorV3Interface(priceFeedAddress);
    }

    function fund() public payable {
        require(msg.value.getConversionRate(priceFeed) >= MINIMUM_USD, "You need to spend more ETH!");
        // require(PriceConverter.getConversionRate(msg.value) >= MINIMUM_USD, "You need to spend more ETH!");
        addressToAmountFunded[msg.sender] += msg.value;
        funders.push(msg.sender);
    }
    
    
    modifier onlyOwner {
        // require(msg.sender == owner);
        if (msg.sender != i_owner) revert NotOwner();
        _;
    }
    
    function withdraw() public onlyOwner {
        for (uint256 funderIndex=0; funderIndex < funders.length; funderIndex++){
            address funder = funders[funderIndex];
            addressToAmountFunded[funder] = 0;
        }
        funders = new address[](0);
        // // transfer
        // payable(msg.sender).transfer(address(this).balance);
        // // send
        // bool sendSuccess = payable(msg.sender).send(address(this).balance);
        // require(sendSuccess, "Send failed");
        // call
        (bool callSuccess, ) = payable(msg.sender).call{value: address(this).balance}("");
        require(callSuccess, "Call failed");
    }
    // Explainer from: https://solidity-by-example.org/fallback/
    // Ether is sent to contract
    //      is msg.data empty?
    //          /   \ 
    //         yes  no
    //         /     \
    //    receive()?  fallback() 
    //     /   \ 
    //   yes   no
    //  /        \
    //receive()  fallback()

    fallback() external payable {
        fund();
    }

    receive() external payable {
        fund();
    }

}

// Concepts we didn't cover yet (will cover in later sections)
// 1. Enum
// 2. Events
// 3. Try / Catch
// 4. Function Selector
// 5. abi.encode / decode
// 6. Hash with keccak256
// 7. Yul / Assembly

// SPDX-License-Identifier: MIT
pragma solidity  ^0.8.0;

import "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";

library PriceConverter{
    // convert USD to ETH
    function getPrice(AggregatorV3Interface priceFeed)
        internal
        view
        returns(uint256)
    {
        // ABI
        // Address 0x1b44F3514812d835EB1BDB0acB33d3fA3351Ee43
        
        // sepolia ETH to USD address 0x65E8d79f3e8e36fE48eC31A2ae935e92F5bBF529
        //AggregatorV3Interface priceFeed = AggregatorV3Interface(0x65E8d79f3e8e36fE48eC31A2ae935e92F5bBF529);
        
        // fantom ETH to USD address 0x65E8d79f3e8e36fE48eC31A2ae935e92F5bBF529
        // AggregatorV3Interface priceFeed = AggregatorV3Interface(0x65E8d79f3e8e36fE48eC31A2ae935e92F5bBF529);
        (,int256 price,,,) = priceFeed.latestRoundData();
        // ETH om terms of USD
        // it will return a long number, there are 8 zeros after the point
        return uint256(price * 1e10);
    }
    function getVersion() internal view returns (uint256){
        // sepolia ETH to USD address 0x65E8d79f3e8e36fE48eC31A2ae935e92F5bBF529
        //AggregatorV3Interface priceFeed = AggregatorV3Interface(0x65E8d79f3e8e36fE48eC31A2ae935e92F5bBF529);
        
        // fantom address 0x65E8d79f3e8e36fE48eC31A2ae935e92F5bBF529
        AggregatorV3Interface priceFeed = AggregatorV3Interface(0x65E8d79f3e8e36fE48eC31A2ae935e92F5bBF529);
        return priceFeed.version();
    }
    function getConversionRate(
        uint256  ethAmount, AggregatorV3Interface priceFeed
    ) internal view returns(uint256){
        uint256 ehPrice = getPrice(priceFeed);
        uint256 ethAmountInUSD = (ehPrice * ethAmount) / 1e18;
        return  ethAmountInUSD;
    }
}