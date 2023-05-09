/**
 *Submitted for verification at Arbiscan on 2023-05-08
*/

// Randomizer protocol interface
	interface IRandomizer {
		function request(uint256 callbackGasLimit) external returns (uint256);
		function request(uint256 callbackGasLimit, uint256 confirmations) external returns (uint256);
		function clientWithdrawTo(address _to, uint256 _amount) external;
	}
	
	// Coinflip contract
	contract exampleContract {
		// Arbitrum goerli
		IRandomizer public randomizer = IRandomizer(0x923096Da90a3b60eb7E12723fA2E1547BA9236Bc);
		address public owner;
		
		// Stores each game to the player
		mapping(uint256 => address) public flipToAddress;
		
		// Events
		event Win(address winner);
		event Lose(address loser);
		
		modifier onlyOwner() {
			require(msg.sender == owner, "Sender is not owner");
			_;
		}
		
		// The coin flip containing the random request
		function flip() external returns (uint256) {
			// Get the latest randomizer contract from the testnet proxy
			// Request a random number from the randomizer contract (50k callback limit)
			uint256 id = randomizer.request(50000);
			// You can also do randomizer.request(50000, 20) to get a callback after 20 confirmations for increased finality security (you can do 1-40 confirmations).
			// Store the flip ID and the player address
			flipToAddress[id] = msg.sender;
			// Return the flip ID
			return id;
		}
		
		// Callback function called by the randomizer contract when the random value is generated
		function randomizerCallback(uint256 _id, bytes32 _value) external {
			//Callback can only be called by randomizer
			require(msg.sender == address(randomizer), "Caller not Randomizer");
			// Get the player address from the flip ID
			address player = flipToAddress[_id];
			// Convert the random bytes to a number between 0 and 99
			uint256 random = uint256(_value) % 99;
			// If the random number is less than 50, the player wins
			if (random < 50) {
				emit Win(player);
			} else {
				emit Lose(player);
			}
		}
		
		// Allows the owner to withdraw their deposited randomizer funds
		function randomizerWithdraw(uint256 amount)
		external
		onlyOwner
		{
			randomizer.clientWithdrawTo(msg.sender, amount);
		}
	}