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

// SPDX-License-Identifier: MIT

///PRAGMA STATEMENTS
pragma solidity ^0.8.0;

///IMPORT STATEMENTS
import "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol"; //Import chainlink interface directly from GitHub. Interface gives ABI of function in a standardized manner to interact with data feeds and other chainlink functions.
import "./PriceConverter.sol";

//ERROR STATEMENTS
error FundMe__NotOwner();

///INTERFACES, LIBRARIES

///CONTRACTS
/// @title A Contract for Crowd Funding
/// @author Raagzzie
/// @notice Note to general people: This is a demo contract
/// @dev Note to developers: This impliments pricefeeds as a library

contract FundMe {
    ///Type Declarations
    using PriceConverter for uint256;

    ///State Variables
    address[] private s_funders;
    address private immutable i_owner;
    AggregatorV3Interface private s_priceFeed;

    mapping(address => uint256) private s_addressToFunded;
    uint256 public constant MIN_USD = 50 * 1e18; // Comparison price will have 18 zeros for accuracy

    ///CONSTRUCTOR
    // Constructor fuction that gets called immediately when the contract is deployed
    //NEED TO PROVIDE PRICE FEED ADDRESS
    constructor(address priceFeedAddress) {
        i_owner = msg.sender;
        s_priceFeed = AggregatorV3Interface(priceFeedAddress);
    }

    ///MODIFIER
    modifier onlyOwner() {
        //require(msg.sender == owner, "Sender is not Owner");
        if (msg.sender != i_owner) revert FundMe__NotOwner();
        _; // tells fuction to execute rest of the code after modifier, if it was above the require statement then the require statment will execute after all the function code
    }

    //FUNCTIONS

    /// @notice Create a function for people to send a min fund amount
    function fund() public payable {
        //payable makes possible for contract to hold ETH
        require(
            msg.value.getConversionRate(s_priceFeed) >= MIN_USD,
            "Didn't send enough"
        ); // transactions are in WEI so 1 ETH = 10^18 WEI, if the requirement isn't met the function actions are reverted and gas is sent back.
        s_funders.push(msg.sender);
        s_addressToFunded[msg.sender] = msg.value;
    }

    function withdraw() public onlyOwner {
        //Perform actions in Onlyowner modifier first before executing function
        //require(msg.sender == owner, "Sender is not Owner"); //Another way to check owner

        //reset the mapping
        for (
            uint256 funderIndex = 0;
            funderIndex < s_funders.length;
            funderIndex++
        ) {
            //(Starting index, ending index, increment)

            address funder = s_funders[funderIndex];
            s_addressToFunded[funder] = 0;
        }

        s_funders = new address[](0); // Resets to new array with 0 elements;

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

    function cheaperWithdraw() public payable onlyOwner {
        address[] memory funders = s_funders;
        for (
            uint256 funderIndex = 0;
            funderIndex < funders.length;
            funderIndex++ //(Starting index, ending index, increment)
        ) {
            address funder = funders[funderIndex];
            s_addressToFunded[funder] = 0;
        }
        s_funders = new address[](0);

        (bool callSuccess, ) = payable(msg.sender).call{
            value: address(this).balance
        }("");
        //The call function gets the balance in the contract, payable sends the money
        require(callSuccess, "Call failed");
    }

    //Both Receive and Fallback directs senders to the fund function so they can be registered an min ETH value for transaction is met.
    fallback() external payable {
        fund();
    }

    receive() external payable {
        fund();
    }

    //GETTER FUNCTIONS
    function getOwner() public view returns (address) {
        return i_owner;
    }

    function getFunders(uint256 index) public view returns (address) {
        return s_funders[index];
    }

    function getAddrerssToAmountFunded(
        address funder
    ) public view returns (uint256) {
        return s_addressToFunded[funder];
    }

    function getPriceFeed() public view returns (AggregatorV3Interface) {
        return s_priceFeed;
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