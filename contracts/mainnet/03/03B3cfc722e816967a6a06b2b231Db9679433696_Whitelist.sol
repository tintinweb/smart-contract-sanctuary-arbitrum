// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IInscriptionFactory {
    struct Token {
        uint128         cap;                                // Hard cap of token
        uint128         limitPerMint;                       // Limitation per mint

        address         onlyContractAddress;
        uint32          maxMintSize;                        // max mint size, that means the max mint quantity is: maxMintSize * limitPerMint
        uint64          inscriptionId;                      // Inscription id

        uint128         onlyMinQuantity;
        uint128         crowdFundingRate;
				
        address         addr;                               // Contract address of inscribed token
        uint40          freezeTime;
        uint40          timestamp;                          // Inscribe timestamp
        uint16          liquidityTokenPercent;              // 10000 is 100%

        address         ifoContractAddress;                 // Initial fair offerting contract
        uint16          refundFee;                          // To avoid the refund attack, deploy sets this fee rate
        uint40          startTime;
        uint40          duration;

        address         customizedConditionContractAddress; // Customized condition for mint
        uint96          maxRollups;                         // max rollups

        address         deployer;                           // Deployer
        string          tick;                               // same as symbol in ERC20, max 5 chars, 10 bytes(80)
        uint16          liquidityEtherPercent;
        
        string          name;                               // full name of token, max 16 chars, 32 bytes(256)

        address         customizedVestingContractAddress;   // Customized contract for token vesting
        bool            isIFOMode;                          // is ifo mode
        bool            isWhitelist;                        // is whitelst condition
        bool            isVesting;
        bool            isVoted;
        
        string          logoUrl;                            // logo url, ifpfs cid, 64 chars, 128 bytes, 4 slots, ex.QmPK1s3pNYLi9ERiq3BDxKa4XosgWwFRQUydHUtz4YgpqB
    }

    function deploy(
        string memory _name,
        string memory _tick,
        uint256 _cap,
        uint256 _limitPerMint,
        uint256 _maxMintSize, // The max lots of each mint
        uint256 _freezeTime, // Freeze seconds between two mint, during this freezing period, the mint fee will be increased
        address _onlyContractAddress, // Only the holder of this asset can mint, optional
        uint256 _onlyMinQuantity, // The min quantity of asset for mint, optional
        uint256 _crowdFundingRate,
        address _crowdFundingAddress
    ) external returns (address _inscriptionAddress);

    function updateStockTick(string memory _tick, bool _status) external;

    function transferOwnership(address newOwner) external;

    function getIncriptionIdByAddress(address _addr) external view returns(uint256);

    function getIncriptionByAddress(address _addr) external view returns(Token memory tokens, uint256 totalSupplies, uint256 totalRollups);

    function fundingCommission() external view returns(uint16);

    function isExisting(string memory _tick) external view returns(bool);

    function isLiquidityAdded(address _addr) external view returns(bool);

}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import "./interfaces/IInscriptionFactory.sol";

contract Whitelist {
    IInscriptionFactory public inscriptionFactory;
    mapping(address => mapping(address => bool)) private whitelist;
    mapping(address => uint256) public count;
    mapping(address => address) public operator;

    event Set(address deployer, address tokenAddress, address participant, bool status);
    event SetOperator(address deployer, address tokenAddress, address operator);

    constructor(IInscriptionFactory _inscriptionFactory) {
        inscriptionFactory = _inscriptionFactory;
    }

    function set(address _tokenAddress, address _participant, bool _status) public {
        (IInscriptionFactory.Token memory token, ,) = IInscriptionFactory(inscriptionFactory).getIncriptionByAddress(_tokenAddress);
        require(token.addr == _tokenAddress, "Token has not deployed");
        require(token.isWhitelist, "condition not whitelist");
        require(msg.sender == token.deployer || msg.sender == operator[_tokenAddress], "Only deployer or operator can set whitelist");

        bool currentStatus = whitelist[_tokenAddress][_participant];
        if(_status && !currentStatus) {
            count[_tokenAddress] = count[_tokenAddress] + 1;
            whitelist[_tokenAddress][_participant] = _status;
        } else if(!_status && currentStatus) {
            count[_tokenAddress] = count[_tokenAddress] - 1;
            whitelist[_tokenAddress][_participant] = _status;
        }
        emit Set(msg.sender, _tokenAddress, _participant, _status);
    }

    function batchSet(address _tokenAddress, address[] calldata _participants, bool _status) public {
        (IInscriptionFactory.Token memory token, ,) = IInscriptionFactory(inscriptionFactory).getIncriptionByAddress(_tokenAddress);
        require(token.addr == _tokenAddress, "Tick has not deployed");
        require(token.isWhitelist, "condition not whitelist");
        require(msg.sender == token.deployer || msg.sender == operator[_tokenAddress], "Only deployer or operator can batch set whitelist");

        for(uint16 i = 0; i < _participants.length; i++) {
            bool currentStatus = whitelist[_tokenAddress][_participants[i]];
            if(_status && !currentStatus) {
                count[_tokenAddress] = count[_tokenAddress] + 1;
                whitelist[_tokenAddress][_participants[i]] = _status;
            } else if(!_status && currentStatus) {
                count[_tokenAddress] = count[_tokenAddress] - 1;
                whitelist[_tokenAddress][_participants[i]] = _status;
            }
            emit Set(msg.sender, _tokenAddress, _participants[i], _status);
        }
    }

    function setOperator(address _tokenAddress, address _operator) public {
        (IInscriptionFactory.Token memory token, ,) = IInscriptionFactory(inscriptionFactory).getIncriptionByAddress(_tokenAddress);
        require(token.addr == _tokenAddress, "Tick has not deployed");
        require(token.isWhitelist, "condition not whitelist");
        require(token.deployer == msg.sender, "Only deployer can add whitelist");
        operator[_tokenAddress] = _operator;
        emit SetOperator(msg.sender, _tokenAddress, _operator);
    }

    function getStatus(address _tokenAddress, address _participant) public view returns(bool) {
        return whitelist[_tokenAddress][_participant];
    }

    function getCount(address _tokenAddress) public view returns(uint256) {
        return count[_tokenAddress];
    }
}