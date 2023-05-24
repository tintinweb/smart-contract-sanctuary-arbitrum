/**
 *Submitted for verification at Arbiscan on 2023-05-24
*/

pragma solidity 0.8.19;

interface IRandomizer {
    function request(uint256 callbackGasLimit) external returns (uint256);

    function request(uint256 callbackGasLimit, uint256 confirmations) external returns (uint256);

    function estimateFee(uint256 callbackGasLimit) external view returns (uint256);

    function estimateFee(uint256 callbackGasLimit, uint256 confirmations) external view returns (uint256);

    function clientDeposit(address _client) external payable;

    function getFeeStats(uint256 requestId) external view returns (uint256[2] memory);

    function clientWithdrawTo(address _to, uint256 _amount) external;

    function clientBalanceOf(address _client) external view returns (uint256 deposit, uint256 reserved);
}

contract RandomizerTest {

    IRandomizer public randomizer;
    uint256 public gasLimit = 900000;
    uint256 public randomNumber;
    uint256 public lastID;

    constructor() {
        randomizer = IRandomizer(0x923096Da90a3b60eb7E12723fA2E1547BA9236Bc);
    }


    function requestNumber() public payable {

            uint256 requestFee = randomizer.estimateFee(gasLimit);
            
            if (msg.value < requestFee) {
                revert("insufficient funds");
            }

            //transfer request fee funds to our 'subscription' on the randomizer contract
            randomizer.clientDeposit{value: msg.value}(address(this));
            randomizer.request(gasLimit);

    }

    function randomizerCallback(uint256 _id, bytes32 _value) external {
        lastID = _id;
        randomNumber = uint256(_value);
    }

    function estimateFee() public view returns(uint256) {
        return randomizer.estimateFee(gasLimit);
    }

    function setGasLimit(uint256 limit) public {
        gasLimit = limit;
    }
}