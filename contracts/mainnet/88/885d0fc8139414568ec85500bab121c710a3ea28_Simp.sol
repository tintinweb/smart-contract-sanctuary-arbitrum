/*
Simp Token
Telegram: https://t.me/egirl_money
twitter: https://twitter.com/egirl_money
Website: https://egirl.money/
*/


pragma solidity ^0.8.19;
import "./ERC20.sol";
import "./Ownable.sol";
import "./IUniswapV2Factory.sol";
contract Simp is ERC20, Ownable {
    
    address public immutable UNISWAP_V2_FACTORY_ADDRESS=0xc35DADB65012eC5796536bD9864eD8773aBc74C4;
    address public immutable USDC=0xFF970A61A04b1cA14834A43f5dE4533eBDDB5CC8;      
    address public uniswapV2Pair;    

    mapping(address => bool) public farmContracts;
    constructor() {
        uniswapV2Pair = IUniswapV2Factory(UNISWAP_V2_FACTORY_ADDRESS).createPair(
            address(this),
            USDC
        );        
        _initializeOwner(msg.sender);
        _mint(msg.sender, 69_000_000_000_000 * 1e18);
        
    }

    modifier onlyFarm() {
        require(
           farmContracts[msg.sender],
            "Only farm contract can call this function"
        );
        _;
    }

    function removeFutureContract(address _farmContract) public onlyOwner {
        delete farmContracts[_farmContract];
    }

    function addFarmContract(address _farmContract) public onlyOwner {
        farmContracts[_farmContract] = true;
    }

    function farmMint(address recipient, uint256 amount) external onlyFarm {
        _mint(recipient, amount);
    }

    function farmBurn(address recipient, uint256 amount) external onlyFarm {
        _burn(recipient, amount);
    }

    function name() public pure override returns (string memory) {
        return "Simp";
    }

    function symbol() public pure override returns (string memory) {
        return "SIMP";
    }

    function decimals() public pure override returns (uint8) {
        return 18;
    }
   
}