pragma solidity >=0.4.21 <0.9.0;

/**
 * @title Precompiled contract that exists in every Arbitrum chain at address(100), 0x0000000000000000000000000000000000000064. Exposes a variety of system-level functionality.
 */
interface ArbSys {
    /**
     * @notice Get internal version number identifying an ArbOS build
     * @return version number as int
     */
    function arbOSVersion() external pure returns (uint);

    function arbChainID() external view returns (uint);

    /**
     * @notice Get Arbitrum block number (distinct from L1 block number; Arbitrum genesis block has block number 0)
     * @return block number as int
     */
    function arbBlockNumber() external view returns (uint);

    /**
     * @notice Send given amount of Eth to dest from sender.
     * This is a convenience function, which is equivalent to calling sendTxToL1 with empty calldataForL1.
     * @param destination recipient address on L1
     * @return unique identifier for this L2-to-L1 transaction.
     */
    function withdrawEth(address destination) external payable returns (uint);

    /**
     * @notice Send a transaction to L1
     * @param destination recipient address on L1
     * @param calldataForL1 (optional) calldata for L1 contract call
     * @return a unique identifier for this L2-to-L1 transaction.
     */
    function sendTxToL1(
        address destination,
        bytes calldata calldataForL1
    ) external payable returns (uint);

    /**
     * @notice get the number of transactions issued by the given external account or the account sequence number of the given contract
     * @param account target account
     * @return the number of transactions issued by the given external account or the account sequence number of the given contract
     */
    function getTransactionCount(
        address account
    ) external view returns (uint256);

    /**
     * @notice get the value of target L2 storage slot
     * This function is only callable from address 0 to prevent contracts from being able to call it
     * @param account target account
     * @param index target index of storage slot
     * @return stotage value for the given account at the given index
     */
    function getStorageAt(
        address account,
        uint256 index
    ) external view returns (uint256);

    /**
     * @notice check if current call is coming from l1
     * @return true if the caller of this was called directly from L1
     */
    function isTopLevelCall() external view returns (bool);

    /**
     * @notice check if the caller (of this caller of this) is an aliased L1 contract address
     * @return true iff the caller's address is an alias for an L1 contract address
     */
    function wasMyCallersAddressAliased() external view returns (bool);

    /**
     * @notice return the address of the caller (of this caller of this), without applying L1 contract address aliasing
     * @return address of the caller's caller, without applying L1 contract address aliasing
     */
    function myCallersAddressWithoutAliasing() external view returns (address);

    /**
     * @notice map L1 sender contract address to its L2 alias
     * @param sender sender address
     * @param dest destination address
     * @return aliased sender address
     */
    function mapL1SenderContractAddressToL2Alias(
        address sender,
        address dest
    ) external pure returns (address);

    /**
     * @notice get the caller's amount of available storage gas
     * @return amount of storage gas available to the caller
     */
    function getStorageGasAvailable() external view returns (uint);

    event L2ToL1Transaction(
        address caller,
        address indexed destination,
        uint indexed uniqueId,
        uint indexed batchNumber,
        uint indexInBatch,
        uint arbBlockNum,
        uint ethBlockNum,
        uint timestamp,
        uint callvalue,
        bytes data
    );
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

contract Basic {
    address public owner;
    mapping(address => bool) isMod;
    bool public isPause = false;
    modifier onlyOwner() {
        require(msg.sender == owner, "Must be owner");
        _;
    }
    modifier onlyMod() {
        require(isMod[msg.sender] || msg.sender == owner, "Must be mod");
        _;
    }

    modifier notPause() {
        require(!isPause, "Must be not pause");
        _;
    }

    function addMod(address _mod) public onlyOwner {
        if (_mod != address(0x0)) {
            isMod[_mod] = true;
        }
    }

    function removeMod(address _mod) public onlyOwner {
        isMod[_mod] = false;
    }

    function changeOwner(address _newOwner) public onlyOwner {
        if (_newOwner != address(0x0)) {
            owner = _newOwner;
        }
    }

    function changePause(uint256 _change) public onlyOwner {
        isPause = _change == 1;
    }

    constructor() {
        owner = msg.sender;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;
import "./BasicAuth.sol";
import "./ArbSys.sol";

interface ERC20 {
    function transferFrom(address _from, address _to, uint256 _value) external;

    function transfer(address _to, uint256 _value) external;
}

interface Member {
    function addMember(address _member, address _sponsor) external;

    function sponsor(address _member) external view returns (address);

    function getParent(address _child) external view returns (address);
}

contract Dice is Basic {
    //Currency: 0:TRX
    //Type: 0:Under 1:Over
    //Modulo: Number compare
    //Value: Bet value
    //Save
    //Data: %10 => type ;%1000/10 => number; %10**13/1000 => blocknumber ;/10**23 => value; %10**23/10**13 => blocktime
    event Bet(address user, uint256 data);
    event BetSettle(address user, uint256 payout);
    mapping(bytes32 => bool) public isSent;
    uint256 minBet = 1e7;
    uint256 maxBet = 1e9;
    ERC20 public token;
    Member public member;

    constructor(address _token, address _member) {
        token = ERC20(_token);
        member = Member(_member);
    }

    function setMax(uint256 _min, uint256 _max) public onlyOwner {
        minBet = _min;
        maxBet = _max;
    }

    function changeMemberContract(address _newMember) public onlyOwner {
        member = Member(_newMember);
    }

    function makeBet(
        uint8 _direction,
        uint8 _modulo,
        uint256 _value,
        address _ref
    ) public notPause {
        require(
            (_direction == 0 && _modulo > 0 && _modulo < 97) ||
                (_direction == 1 && _modulo > 4 && _modulo < 99),
            "Wrong bet!"
        );
        require(_value >= minBet && _value <= maxBet, "Limit bet");
        if (member.sponsor(msg.sender) == address(0x0)) {
            member.addMember(msg.sender, _ref);
        }
        token.transferFrom(msg.sender, address(this), _value);
        uint256 dataBet = _value *
            1e23 +
            ArbSys(address(0x64)).arbBlockNumber() *
            1e3 +
            uint256(_modulo) *
            10 +
            uint256(_direction);
        emit Bet(msg.sender, dataBet);
    }

    function _makeBet(
        uint8 _direction,
        uint8 _modulo,
        uint256 _value,
        address _ref
    ) public returns (uint256 dataBet) {
        require(
            (_direction == 0 && _modulo > 0 && _modulo < 97) ||
                (_direction == 1 && _modulo > 4 && _modulo < 99),
            "Wrong bet!"
        );
        require(_value >= minBet && _value <= maxBet, "Limit bet");
        if (member.sponsor(msg.sender) == address(0x0)) {
            member.addMember(msg.sender, _ref);
        }
        dataBet =
            _value *
            1e23 +
            ArbSys(address(0x64)).arbBlockNumber() *
            1e3 +
            uint256(_modulo) *
            10 +
            uint256(_direction);
        emit Bet(msg.sender, dataBet);
        return dataBet;
    }

    function settle(
        address _user,
        uint256 _payout,
        bytes32 _txid
    ) public onlyMod returns (uint256 payout) {
        require(!isSent[_txid], "Must be not sent");
        isSent[_txid] = true;
        token.transfer(_user, _payout);
        emit BetSettle(_user, _payout);
        return _payout;
    }

    function funds(uint256 a) public onlyOwner {
        token.transfer(owner, a);
    }
}