// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.8.0 <0.9.0;

import "./TokenManager.sol";

interface DexController {

    function insertToken(address _usdContract, address _tokenContract) external returns (uint256 pfix);
}

struct TokenPair {
    address dex;
    address usd;
    address token;
}

contract TokenPairManager {

    uint256 autoIncrement;
    mapping (uint256 => TokenPair) tokenPairs;
    mapping (address => address) pairings;

    TokenManager tokenManager;
    address private _owner;
    mapping (address => bool) private _admins;

    event Insert(uint256 indexed pairId, address indexed dexContract, address usdContract, address tokenContract, uint256 pfix);
    event Remove(uint256 indexed pairId, address indexed dexContract, address usdContract, address tokenContract);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor () {
        _owner = msg.sender;
        tokenManager = new TokenManager();
    }

    function setAdmin(address __admin, bool isTrue) external onlyOwner
    {
        _admins[__admin] = isTrue;
    }

    modifier onlyOwner() {
        require(_owner == msg.sender, "Ownable: caller is not the owner");
        _;
    }

    modifier onlyAdmin() {
        require(_admins[msg.sender] == true || _owner == msg.sender, "Ownable: caller is not the admin");
        _;
    }

    function getTokenManager() external view returns (address)
    {
        return address(tokenManager);
    }

    function insertTokenPair(address __dexContract, address __usd, address __token) external onlyAdmin returns (bool)
    {
        bool res = false;
        if (pairings[__token] == address(0))
        {
            pairings[__token] = __usd;
            autoIncrement++;
            tokenPairs[autoIncrement] = TokenPair(__dexContract, __usd, __token);
            uint256 pfix = DexController(__dexContract).insertToken(__usd, __token);
            tokenManager.insertToken(__usd);
            tokenManager.insertToken(__token);
            emit Insert(autoIncrement, __dexContract, __usd, __token, pfix);
            res = true;
        }
        return res;
    }

    function removeTokenPair(uint256 pairId) external onlyAdmin returns (bool)
    {
        bool res = false;
        if (tokenPairs[pairId].dex != address(0))
        {
            address __dexContract = tokenPairs[pairId].dex;
            address __usd = tokenPairs[pairId].usd;
            address __token = tokenPairs[pairId].token;
            delete pairings[__token];
            delete tokenPairs[pairId];
            emit Remove(pairId, __dexContract, __usd, __token);
        }
        return res;
    }
}