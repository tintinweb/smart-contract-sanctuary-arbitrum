// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface AggregatorV3Interface {
  function decimals() external view returns (uint8);

  function description() external view returns (string memory);

  function version() external view returns (uint256);

  function getRoundData(uint80 _roundId)
    external
    view
    returns (
      uint80 roundId,
      int256 answer,
      uint256 startedAt,
      uint256 updatedAt,
      uint80 answeredInRound
    );

  function latestRoundData()
    external
    view
    returns (
      uint80 roundId,
      int256 answer,
      uint256 startedAt,
      uint256 updatedAt,
      uint80 answeredInRound
    );
}

//Get funds from users
//Withdraw funds
//Set a minimum funding value in USD

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol"; //Import chainlink interface directly from GitHub. Interface gives ABI of function in a standardized manner to interact with data feeds and other chainlink functions.
import "./PriceConverter.sol";

contract FundMe2 {
    using PriceConverter for uint256;
    uint256 public minUSD = 50 * 1e18; // Comparison price will have 18 zeros for accuracy
    address[] public funders;
    mapping(address => uint256) addressToFunded;

    address public owner;

    AggregatorV3Interface public priceFeed;

    // Constructor fuction that gets called immediately when the contract is deployed
    constructor(address priceFeedAddress) {
        owner = msg.sender;
        priceFeed = AggregatorV3Interface(priceFeedAddress);
    }

    //Create a function for people to send a min fund amount
    function fund() public payable {
        //payable makes possible for contract to hold ETH
        require(
            msg.value.getConversionRate(priceFeed) >= minUSD,
            "Didn't send enough"
        ); // transactions are in WEI so 1 ETH = 10^18 WEI, if the requirement isn't met the function actions are reverted and gas is sent back.
        funders.push(msg.sender);
        addressToFunded[msg.sender] = msg.value;
    }

    /*// Get's version of Oracle
    function getVersion() public view returns (uint256) {
        // ETH/USD price feed address of Goerli Network.
        AggregatorV3Interface priceFeed = AggregatorV3Interface(
            0xD4a33860578De61DBAbDc8BFdb98FD742fA7028e
        );
        return priceFeed.version();
    }*/

    function withdraw() public onlyOwner {
        //Perform actions in Onlyowner modifier first before executing function
        //require(msg.sender == owner, "Sender is not Owner"); //Another way to check owner

        //reset the mapping
        for (
            uint256 funderIndex = 0;
            funderIndex < funders.length;
            funderIndex++
        ) {
            //(Starting index, ending index, increment)

            address funder = funders[funderIndex];
            addressToFunded[funder] = 0;
        }

        funders = new address[](0); // Resets to new array with 0 elements;

        //withdraw funds
        //transfer
        //payable(msg.sender).transfer(address(this).balance);
        //Max 2300 gas, fails if more gas required and reverts

        //send
        //bool sendSuccess = payable(msg.sender).send(address(this).balance);
        //require(sendSuccess, "Send failed”);
        //Max 2300 gas, fails if more gas required and reverts a boolean values, require  		  statements makes function try sending until successful

        //call
        (bool callSuccess, ) = payable(msg.sender).call{
            value: address(this).balance
        }("");
        //The call function gets the balance in the contract, payable sends the money
        require(callSuccess, "Call failed");
    }

    modifier onlyOwner() {
        require(msg.sender == owner, "Sender is not Owner");
        _; // tells fuction to execute rest of the code after modifier, if it was above the require statement then the require statment will execute after all the function code
    }

    //Both Receive and Fallback directs senders to the fund function so they can be registered an min ETH value for transaction is met.
    fallback() external payable {
        fund();
    }

    receive() external payable {
        fund();
    }
}

//SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";

library PriceConverter {
    function getPrice(
        AggregatorV3Interface priceFeed
    ) internal view returns (uint256) {
        //ABI
        //Address: 0x8A753747A1Fa494EC906cE90E9f37563A8AF630e

        (, int price, , , ) = priceFeed.latestRoundData(); //ETH Price in USD 300000000000, use decimal function to get decimals
        return uint256(price * 1e10); //Type casting price from Int to Uint
    }

    function getConversionRate(
        uint256 ethAmount,
        AggregatorV3Interface priceFeed
    ) internal view returns (uint256) {
        //Gets Eth amount in USD using ETH Amount as Input
        uint256 ethPrice = getPrice(priceFeed);
        uint256 ethAmountInUSD = (ethPrice * ethAmount) / 1e18; //Dividing by 1e18 and not 1e36 for accuracy
        return ethAmountInUSD;
    }
}