//SPDX-License-Identifier: MIT

pragma solidity 0.8.0;

import "./SafeERC20.sol";
import "./IERC20.sol";

contract ARB_Pool {

    using SafeMath for uint256;
    using SafeERC20 for IERC20;

    // Address of our hotwallet
    address payable public hotWallet;

    // The token that will be bridged
    IERC20 public myToken;

    // Performance Fee (ETH)
    uint256 performanceFee;

    // Uinque identifier for TransferIn event
    uint256 private eventIdCounter;

    // Executed on deployment
    constructor(address _hotWallet, address _myToken) {
        hotWallet = payable(_hotWallet);
        myToken = IERC20(_myToken);
    }

    // Events
    // Emitted after we send the tokens
    event TransferIn(uint256 indexed id, address indexed sender, uint256 amount, string destination);
    event SendTokens(uint256 indexed id, address indexed to, uint256 amount);

    // Modifier
    // Functions that have this modifier can be executed only by the hot wallet
    modifier onlyHotWallet() {
        require(msg.sender == hotWallet, "You are not the hotWallet!");
        _;
    }

    function setPerformanceFee(uint256 _performanceFee) external onlyHotWallet {
        performanceFee = _performanceFee;
    }


    function transferIn(uint256 _amount, string memory _destination) public payable {
        require(msg.value == performanceFee, "A fee is required to use the bridge.");
        (bool sent, bytes memory data) = hotWallet.call{value: msg.value}("");
        require(sent, "Failed to send Ether");

        myToken.safeTransferFrom(msg.sender, address(this), _amount);

        emit TransferIn(eventIdCounter, msg.sender, _amount, _destination);
        eventIdCounter++;
    }

    function sendTokens(address _to, uint256 _amount, uint256 _id) external onlyHotWallet {
        require(myToken.balanceOf(address(this)) >= _amount, "Balance of the smart contract is too low!");

        myToken.safeTransfer(_to, _amount); // Send the tokens

        emit SendTokens(_id, _to, _amount);
    }

    function setHotWallet(address _hotWallet) external onlyHotWallet {
        hotWallet = payable(_hotWallet);
    }
}