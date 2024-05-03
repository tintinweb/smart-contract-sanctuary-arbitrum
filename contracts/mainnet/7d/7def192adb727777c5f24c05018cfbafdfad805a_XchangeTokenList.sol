/**
 *Submitted for verification at Arbiscan.io on 2024-05-03
*/

// SPDX-License-Identifier: MIT
pragma solidity =0.8.25;

interface IFactory {
    function getPair(
        address tokenA,
        address tokenB
    ) external view returns (address pair);
}

contract XchangeTokenList {
    address public treasury;
    uint256 public fee;
    address public owner;

    mapping(address => bool) public registeredTokens;
    address[] public registeredTokenList;

    event TokenAdded(address indexed tokenAddress, address indexed addedBy);
    event FeeAmended(uint256 newFee, address indexed amendedBy);
    event OwnerChanged(address indexed newOwner, address indexed changedBy);
    event TokenRemoved(address indexed tokenAddress, address indexed removedBy);

    modifier onlyOwner() {
        require(msg.sender == owner, "Not the owner");
        _;
    }

    constructor() {
        treasury = address(0x70001BA1BA4d85739E7B6A7C646B8aba5ed6c888);
        fee = 0;
        owner = address(0x6BB243B75B306c7276D883d8b9c2232bf84660cE);
    }

    function addToken(
        address _tokenAddress,
        address _pairedAddress,
        address _factoryAddress
    ) external payable {
        require(!registeredTokens[_tokenAddress], "Token already registered");

        // Check if the token has a liquidity pair on a dex
        require(
            pairExists(_tokenAddress, _pairedAddress, _factoryAddress),
            "Token has no liquidity pair on a dex"
        );

        if (fee > 0) {
            require(msg.value == fee, "Incorrect fee sent");
            payable(treasury).transfer(msg.value);
        }

        registeredTokens[_tokenAddress] = true;
        registeredTokenList.push(_tokenAddress);
        emit TokenAdded(_tokenAddress, msg.sender);
    }

    function addMultipleTokens(address[] memory _initialTokens) external onlyOwner  {
        require(_initialTokens.length > 0, "Mismatched array lengths");

        for (uint256 i = 0; i < _initialTokens.length; i++) {
            address token = _initialTokens[i];

            registeredTokens[token] = true;
            registeredTokenList.push(token);
            emit TokenAdded(token, msg.sender);
        }
    }

    function amendFee(uint256 _newFee) external onlyOwner {
        fee = _newFee;
        emit FeeAmended(_newFee, msg.sender);
    }

    function changeOwner(address _newOwner) external onlyOwner {
        require(_newOwner != address(0), "Invalid new owner address");
        owner = _newOwner;
        emit OwnerChanged(_newOwner, msg.sender);
    }

    function getRegisteredTokens() external view returns (address[] memory) {
        return registeredTokenList;
    }

    function pairExists(
        address _tokenAddress,
        address _pairedAddress,
        address _factoryAddress
    ) internal view returns (bool) {
        address pair = IFactory(_factoryAddress).getPair(
            _tokenAddress,
            _pairedAddress
        );
        return pair != address(0);
    }

    function removeToken(address _tokenAddress) external onlyOwner {
        require(registeredTokens[_tokenAddress], "Token not registered");

        for (uint256 i = 0; i < registeredTokenList.length; i++) {
            if (registeredTokenList[i] == _tokenAddress) {
                registeredTokenList[i] = registeredTokenList[
                    registeredTokenList.length - 1
                ];
                registeredTokenList.pop();
                break;
            }
        }

        delete registeredTokens[_tokenAddress];

        emit TokenRemoved(_tokenAddress, msg.sender);
    }
}