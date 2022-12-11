/**
 *Submitted for verification at Arbiscan on 2022-12-10
*/

pragma solidity ^0.8.0;

// Randomizer protocol interface
interface IRandomizer {
    function request(uint256 callbackGasLimit) external returns (uint256);
    function clientWithdrawTo(address _to, uint256 _amount) external;
}

// Coinflip contract
contract CoinFlip {
	IRandomizer public randomizer;
	address public owner = msg.sender;

	// Stores each game to the player
    mapping(uint128 => address) public flipToAddress;
    bool public allow;

    // Events
    event Win(address winner, bytes32 value);
    event Lose(address loser, bytes32 value);

    event ID(uint128 id);

	modifier onlyOwner() {
		require(msg.sender == owner, "Sender is not owner");
        _;
	}

    constructor(
        IRandomizer _randomizer
    ) {
        randomizer = _randomizer;
    }

    // The coin flip containing the random request
    function flip() external returns (uint128) {
        // Get the latest randomizer contract from the testnet proxy
        // Request a random number from the randomizer contract (50k callback limit)
        uint128 id = uint128(randomizer.request(50000));
        // Store the flip ID and the player address
        flipToAddress[id] = msg.sender;
        // Return the flip ID
        emit ID(id);
        return id;
    }

    // Callback function called by the randomizer contract when the random value is generated
    function randomizerCallback(uint128 _id, bytes32 _value) external {
		require(allow, "Not allowed");
        //Callback can only be called by randomizer
		require(msg.sender == address(randomizer), "Caller not Randomizer");
        // Get the player address from the flip ID
        address player = flipToAddress[_id];
        // Convert the random bytes to a number between 0 and 99
        uint256 random = uint256(_value) % 99;
        // If the random number is less than 50, the player wins
        if (random < 50) {
            emit Win(player, _value);
        } else {
            emit Lose(player, _value);
        }
    }

    function setRequire(bool _allow) external {
        allow = _allow;
    }

    receive() external payable {}
 
    // Allows the owner to withdraw their deposited randomizer funds
    function randomizerWithdraw(uint256 amount)
        external
        onlyOwner
    {
        randomizer.clientWithdrawTo(msg.sender, amount);
    }
}