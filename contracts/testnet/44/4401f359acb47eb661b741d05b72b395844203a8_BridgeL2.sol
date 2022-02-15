/**
 *Submitted for verification at arbiscan.io on 2022-02-14
*/

// File: arb-shared-dependencies/contracts/AddressAliasHelper.sol



/*
 * Copyright 2019-2021, Offchain Labs, Inc.
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *    http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */

pragma solidity >=0.7.0;

library AddressAliasHelper {
    uint160 constant offset = uint160(0x1111000000000000000000000000000000001111);

    /// @notice Utility function that converts the address in the L1 that submitted a tx to
    /// the inbox to the msg.sender viewed in the L2
    /// @param l1Address the address in the L1 that triggered the tx to L2
    /// @return l2Address L2 address as viewed in msg.sender
    function applyL1ToL2Alias(address l1Address) internal pure returns (address l2Address) {
        l2Address = address(uint160(l1Address) + offset);
    }

    /// @notice Utility function that converts the msg.sender viewed in the L2 to the
    /// address in the L1 that submitted a tx to the inbox
    /// @param l2Address L2 address as viewed in msg.sender
    /// @return l1Address the address in the L1 that triggered the tx to L2
    function undoL1ToL2Alias(address l2Address) internal pure returns (address l1Address) {
        l1Address = address(uint160(l2Address) - offset);
    }
}

// File: arb-shared-dependencies/contracts/ArbSys.sol

pragma solidity >=0.7.0;

/**
* @title Precompiled contract that exists in every Arbitrum chain at address(100), 0x0000000000000000000000000000000000000064. Exposes a variety of system-level functionality.
 */
interface ArbSys {
    /**
    * @notice Get internal version number identifying an ArbOS build
    * @return version number as int
     */
    function arbOSVersion() external pure returns (uint);

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
    function withdrawEth(address destination) external payable returns(uint);

    /** 
    * @notice Send a transaction to L1
    * @param destination recipient address on L1 
    * @param calldataForL1 (optional) calldata for L1 contract call
    * @return a unique identifier for this L2-to-L1 transaction.
    */
    function sendTxToL1(address destination, bytes calldata calldataForL1) external payable returns(uint);


    /** 
    * @notice get the number of transactions issued by the given external account or the account sequence number of the given contract
    * @param account target account
    * @return the number of transactions issued by the given external account or the account sequence number of the given contract
    */
    function getTransactionCount(address account) external view returns(uint256);

    /**  
    * @notice get the value of target L2 storage slot 
    * This function is only callable from address 0 to prevent contracts from being able to call it
    * @param account target account
    * @param index target index of storage slot 
    * @return stotage value for the given account at the given index
    */
    function getStorageAt(address account, uint256 index) external view returns (uint256);

    /**
    * @notice check if current call is coming from l1
    * @return true if the caller of this was called directly from L1
    */
    function isTopLevelCall() external view returns (bool);

    event EthWithdrawal(address indexed destAddr, uint amount);

    event L2ToL1Transaction(address caller, address indexed destination, uint indexed uniqueId,
                            uint indexed batchNumber, uint indexInBatch,
                            uint arbBlockNum, uint ethBlockNum, uint timestamp,
                            uint callvalue, bytes data);
}
// File: contracts/BridgeL2.sol


pragma solidity ^0.7.0;



contract BridgeL2 {
    ArbSys constant arbsys = ArbSys(100);
    bytes4 private constant ABI_SETGREETING = bytes4(keccak256("setGreeting(string)"));
    bytes4 private constant ABI_MINTRESERVED = bytes4(keccak256("mintReserved(address, uint256"));

    /* ========== STATE VARIABLES ========== */
    address public l1Target;
    address public NFTContract;
    string  public greeting;

    bool public paused = true;  //Pauses the contract so the functions will revert if its true

    event L2ToL1TxCreated(uint256 indexed withdrawalId);

    /* ========== MODIFIERS ========== */

    /* ======== CONSTRUCTOR ======== */
    constructor() {}


    /* ======== ADMIN FUNCTIONS ======== */

    function togglePause() external {
        paused = !paused;
    }

    function setNFTContract(address _nftContract) public {
        NFTContract = _nftContract;
    }

    function setL1Target(address _l1Target) external {
        l1Target = _l1Target;
    }

    function updateGreeting(string memory _greeting) public {
        greeting = _greeting;
    }

    /* ======== VIEW FUNCTIONS ======== */

    function getNFTContract() external view returns(address){
        return NFTContract;
    }

    function getPaused() external view returns(bool){
        return paused;
    }



    /* ======== BRIDGEONLY FUNCTIONS ======== */

    function mintNFT(uint256 tokenid, address users_address) external returns (uint256, address) {
        //require(msg.sender == AddressAliasHelper.applyL1ToL2Alias(l1Target), "Only ETH side of the bridge can mint");
        require(paused != true, "Bridge is paused");
        bytes memory data = abi.encodeWithSelector(ABI_MINTRESERVED, users_address, tokenid);
        (bool success, ) = address(NFTContract).call(data);
        return (tokenid, users_address);
    }


    /// @notice only l1Target can update greeting
    function setGreeting(string memory _greeting) external {
        // To check that message came from L1, we check that the sender is the L1 contract's L2 alias.
        require(msg.sender == AddressAliasHelper.applyL1ToL2Alias(l1Target), "Greeting only updateable by L1");
        updateGreeting(_greeting);
    }

    /* ======== INTERNAL FUNCTIONS ======== */

    /* ======== EXTERNAL FUNCTIONS ======== */

    function setGreetingInL1(string memory _greeting) external returns (uint256) {
        bytes memory data =
        abi.encodeWithSelector(ABI_SETGREETING, _greeting);

        uint256 withdrawalId = arbsys.sendTxToL1(l1Target, data);

        emit L2ToL1TxCreated(withdrawalId);
        return withdrawalId;
    }
}