// SPDX-License-Identifier: LGPL-3.0-or-later
pragma solidity ^0.8.11;

import "../_abstract/BuddleSource.sol";

import "./ext/ITokenGateway.sol";
import "@arbitrum/nitro-contracts/src/precompiles/ArbSys.sol";
import "@arbitrum/nitro-contracts/src/libraries/AddressAliasHelper.sol";

// TODO import from package (fix incompatible solidity version issue)
// import "arb-bridge-peripherals/contracts/tokenbridge/libraries/gateway/ITokenGateway.sol";

/**
 *
 *
 */
contract BuddleSrcArbitrum is BuddleSource {

    uint256 constant public CHAIN = 421611; // Arbitrum-Rinkeby

    address public arbSys;
    address public router;

    mapping(address => address) public l1TokenMap; 

    /********************** 
     * onlyOwner functions *
     ***********************/
    
    function setXDomainMessenger(
        address _arbSys,
        address _gatewayRouter
    ) external onlyOwner checkInitialization {
        arbSys = _arbSys;
        router = _gatewayRouter;
    }

    function updateArbSys(address _arbSys) external {
        arbSys = _arbSys;
    }

    function updateGatewayRouter(address _gatewayRouter) external {
        router = _gatewayRouter;
    }

    function addL1Token(
        address _l1Token,
        address _l2Token
    ) external onlyOwner {
        require(tokenMapping[_l2Token], "L2 token address unknown to contract");
        l1TokenMap[_l2Token] = _l1Token;
    }

    function updateL1Token(
        address _l1Token,
        address _l2Token
    ) external onlyOwner {
        require(l1TokenMap[_l2Token] != address(0), "Token never stored in contract");
        l1TokenMap[_l2Token] = _l1Token;
    }


    /********************** 
     * internal functions *
     ***********************/

    /**
     * @inheritdoc BuddleSource
     */
    function isBridgeContract() internal view override returns (bool) {
        return (AddressAliasHelper.undoL1ToL2Alias(msg.sender) == buddleBridge);
    }

    /**
     * @inheritdoc BuddleSource
     */
    function _emitTransfer(
        TransferData memory _data,
        uint256 _id,
        bytes32 _node
    ) internal override {
        emit TransferStarted(_data, _id, _node, CHAIN);
    }

    /**
     * @inheritdoc BuddleSource
     */
    function _bridgeFunds(
        uint256 _destChain,
        address[] memory _tokens,
        uint256[] memory _tokenAmounts,
        uint256[] memory _bountyAmounts,
        address _provider
    ) internal override {

        ITokenGateway _router = ITokenGateway(router); // TODO change to GatewayRouter

        for (uint n = 0; n < _tokens.length; n++) {
            if(_tokens[n] == BASE_TOKEN_ADDRESS) {
                ArbSys(arbSys).withdrawEth{value: _tokenAmounts[n]+_bountyAmounts[n]}(_provider);
            } else {
                _router.outboundTransfer(
                    // l1 token
                    l1TokenMap[_tokens[n]],
                    // to
                    _provider,
                    // amount
                    _tokenAmounts[n]+_bountyAmounts[n],
                    // data
                    bytes("")
                );
            }
            tokenAmounts[_destChain][_tokens[n]] -= _tokenAmounts[n];
            bountyAmounts[_destChain][_tokens[n]] -= _bountyAmounts[n];
        }
    }
}

// SPDX-License-Identifier: LGPL-3.0-or-later
pragma solidity ^0.8.11;

import "../_interface/IBuddleSource.sol";

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

/**
 *
 *
 */
abstract contract BuddleSource is IBuddleSource, Ownable {
    using SafeERC20 for IERC20;

    bytes32 public VERSION;
    address constant BASE_TOKEN_ADDRESS = address(0);

    uint256 public CONTRACT_FEE_BASIS_POINTS;
    uint256 public CONTRACT_FEE_RAMP_UP;
    
    uint constant public MERKLE_TREE_DEPTH = 32;
    uint constant public MAX_DEPOSIT_COUNT = 2 ** MERKLE_TREE_DEPTH - 1;
    
    bytes32[MERKLE_TREE_DEPTH] internal zeroes;
    mapping(uint256 => bytes32[MERKLE_TREE_DEPTH]) internal branch;

    address public buddleBridge;
    mapping(uint256 => address) public buddleDestination;

    address[] public tokens;
    mapping(address => bool) public tokenMapping;
    mapping(uint256 => mapping(address => uint256)) internal tokenAmounts;
    mapping(uint256 => mapping(address => uint256)) internal bountyAmounts;

    mapping(uint256 => uint256) public transferCount;
    mapping(uint256 => uint256) public lastConfirmedTransfer;
    mapping(uint256 => mapping(bytes32 => bool)) internal tickets;

    /********** 
     * events *
     **********/

    event TransferStarted(
        TransferData transferData,
        uint256 transferID,
        bytes32 node,
        uint256 srcChain
    );
    
    event TicketCreated(
        bytes32 ticket,
        uint256 destChain,
        address[] tokens,
        uint256[] amounts,
        uint256[] bounty,
        uint256 firstIdForTicket,
        uint256 lastIdForTicket,
        bytes32 stateRoot
    );

    event TicketConfirmed(
        bytes32 ticket,
        bytes32 stateRoot
    );

    /************
     * modifers *
     ************/

    /**
     * Checks whether the contract is initialized
     *
     */
    modifier checkInitialization() {
        require(bytes32(VERSION).length > 0, "Contract not yet initialzied");
        _;
    }

    /**
     * Checks whether a destination contract exists for the given chain id
     *
     */
    modifier supportedChain(uint256 _chain) {
        require(buddleDestination[_chain] != address(0), 
            "A destination contract on the desired chain does not exist yet"
        );
        _;
    }

    /**
     * Checks whether the given token is supported by this contract
     *
     */
    modifier supportedToken(address _token) {
        require(tokenMapping[_token], "This token is not supported yet");
        _;
    }

    /********************** 
     * virtual functions *
     ***********************/
    
    /**
    * Returns true if the msg.sender is the buddleBridge contract address
    *
    */
    function isBridgeContract() internal virtual returns (bool);

    /**
    * Emits the TransferStarted event with the constant CHAIN id in derived contract
    *
    * @param _data The TransferData to be emitted
    * @param _id The Transfer ID to be emitted
    * @param _node The hashed node corresponding to the transfer data and id
    */
    function _emitTransfer(
        TransferData memory _data,
        uint256 _id,
        bytes32 _node
    ) internal virtual;

    /**
    * Bridges the funds as described by _tokenAmounts and _bountyAmounts to the _provider
    * on layer 1.
    * @notice called by confirmTicket(...)
    *
    * @param _destChain The destination chain id for the ticket created
    * @param _tokens The list of ERC20 contract addresses included in ticket
    * @param _tokenAmounts The corresponding list of transfer amounts summed
    * @param _bountyAmounts The corresponding list of bounty fees summed
    * @param _provider The bounty seeker on layer 1
    */
    function _bridgeFunds(
        uint256 _destChain,
        address[] memory _tokens,
        uint256[] memory _tokenAmounts,
        uint256[] memory _bountyAmounts,
        address _provider
    ) internal virtual;

    /********************** 
     * onlyOwner functions *
     ***********************/

    /**
     * @inheritdoc IBuddleSource
     */
    function initialize(
        bytes32 _version,
        uint256 _feeBasisPoints,
        uint256 _feeRampUp,
        address _buddleBridge
    ) external onlyOwner {
        require(bytes32(VERSION).length == 0, "Contract already initialized!");
        
        VERSION = _version;
        CONTRACT_FEE_BASIS_POINTS = _feeBasisPoints;
        CONTRACT_FEE_RAMP_UP = _feeRampUp;
        buddleBridge = _buddleBridge;

        // Initialize the empty sparse merkle tree
        for (uint height = 0; height < MERKLE_TREE_DEPTH - 1; height++) {
            zeroes[height + 1] = sha256(abi.encodePacked(zeroes[height], zeroes[height]));
        }

        // Add underlying token to supported tokens
        tokens.push(BASE_TOKEN_ADDRESS);
        tokenMapping[BASE_TOKEN_ADDRESS] = true;
    }

    /**
     * @inheritdoc IBuddleSource
     */
    function addTokens(
        address[] memory _tokens
    ) external onlyOwner checkInitialization {
        for(uint i = 0; i < _tokens.length; i++) {
            // Add token to contract only if it doesn't already exist
            if (!tokenMapping[_tokens[i]]) {
                tokens.push(_tokens[i]);
                tokenMapping[_tokens[i]] = true;
            }
        }
    }

    /**
     * @inheritdoc IBuddleSource
     */
    function addDestination(
        uint256 _chain,
        address _contract
    ) external onlyOwner checkInitialization {
        require(buddleDestination[_chain] == address(0), 
            "Destination contract already exists for given chain id"
        );
        buddleDestination[_chain] = _contract;
    }

    /**
     * @inheritdoc IBuddleSource
     */
    function updateContractFeeBasisPoints(
        uint256 _newContractFeeBasisPoints
    ) external onlyOwner checkInitialization {
        CONTRACT_FEE_BASIS_POINTS = _newContractFeeBasisPoints;
    }

    /**
     * @inheritdoc IBuddleSource
     */
    function updateContractFeeRampUp(
        uint256 _newContractFeeRampUp
    ) external onlyOwner checkInitialization {
        CONTRACT_FEE_RAMP_UP = _newContractFeeRampUp;
    }

    /**
     * @inheritdoc IBuddleSource
     */
    function updateBuddleBridge(
        address _newBridgeAddress
    ) external onlyOwner checkInitialization {
        buddleBridge = _newBridgeAddress;
    }

    /**
     * @inheritdoc IBuddleSource
     */
    function updateDestination(
        uint256 _chain,
        address _contract
    ) external onlyOwner checkInitialization supportedChain(_chain) {
        buddleDestination[_chain] = _contract;
    }

    /********************** 
     * public functions *
     ***********************/

    /**
     * @inheritdoc IBuddleSource
     */
    function deposit(
        address _tokenAddress,
        uint256 _amount,
        address _destination,
        uint256 _destChain
    ) external payable 
      checkInitialization
      supportedChain(_destChain)
      supportedToken(_tokenAddress)
      returns(bytes32) {

        require(transferCount[_destChain] < MAX_DEPOSIT_COUNT,
            "Maximum deposit count reached for given destination chain"
        );

        // Calculate fee
        uint256 amountPlusFee = (_amount * (10000 + CONTRACT_FEE_BASIS_POINTS)) / 10000;

        // Build transfer data
        TransferData memory data;
        data.tokenAddress = _tokenAddress;
        data.destination = _destination;
        data.amount = _amount;
        data.fee = amountPlusFee - data.amount;
        data.startTime = block.timestamp;
        data.feeRampup = CONTRACT_FEE_RAMP_UP;
        data.chain = _destChain;
        
        if (data.tokenAddress == address(0)) {
            require(msg.value >= amountPlusFee, "Insufficient amount");
        } else {
            IERC20 token = IERC20(data.tokenAddress);
            token.safeTransferFrom(msg.sender, address(this), amountPlusFee);
        }
        transferCount[_destChain] += 1;
        tokenAmounts[_destChain][_tokenAddress] += data.amount;
        bountyAmounts[_destChain][_tokenAddress] += data.fee;
        
        // Hash Transfer Information and store in tree
        bytes32 transferDataHash = sha256(abi.encodePacked(
            data.tokenAddress,
            data.destination,
            data.amount,
            data.fee,
            data.startTime,
            data.feeRampup,
            data.chain
        ));
        bytes32 node = sha256(abi.encodePacked(
            transferDataHash,
            sha256(abi.encodePacked(buddleDestination[_destChain])),
            sha256(abi.encodePacked(transferCount[_destChain]))
        ));
        updateMerkle(_destChain, node);
        
        _emitTransfer(data, transferCount[_destChain], node);

        return node;
    }

    /**
     * @inheritdoc IBuddleSource
     */
    function createTicket(uint256 _destChain) external checkInitialization returns(bytes32) {
        uint256[] memory _tokenAmounts = new uint256[](tokens.length);
        uint256[] memory _bountyAmounts = new uint256[](tokens.length);
        bytes32 _ticket;
        for (uint n = 0; n < tokens.length; n++) {
            _tokenAmounts[n] = tokenAmounts[_destChain][tokens[n]];
            _bountyAmounts[n] = bountyAmounts[_destChain][tokens[n]];
            _ticket = sha256(abi.encodePacked(_ticket, tokens[n], _tokenAmounts[n]+_bountyAmounts[n]));
        }
        bytes32 _root = getMerkleRoot(_destChain);
        _ticket = sha256(abi.encodePacked(_ticket, lastConfirmedTransfer[_destChain]));
        _ticket = sha256(abi.encodePacked(_ticket, transferCount[_destChain]));
        _ticket = sha256(abi.encodePacked(_ticket, _root));
        tickets[_destChain][_ticket] = true;

        emit TicketCreated(
            _ticket,
            _destChain,
            tokens,
            _tokenAmounts,
            _bountyAmounts,
            lastConfirmedTransfer[_destChain],
            transferCount[_destChain],
            _root
        );
        
        return _ticket;
    }

    /**
     * @inheritdoc IBuddleSource
     */
    function confirmTicket(
        bytes32 _ticket,
        uint256 _destChain,
        address[] memory _tokens,
        uint256[] memory _tokenAmounts,
        uint256[] memory _bountyAmounts,
        uint256 _firstTransferInTicket, 
        uint256 _lastTransferInTicket,
        bytes32 _stateRoot,
        address _provider
    ) external checkInitialization {

        require(isBridgeContract(), "Only the Buddle Bridge contract can call this method");
        
        // Build ticket to check validity of data
        bytes32 ticket;
        for (uint n = 0; n < _tokens.length; n++) {
            ticket = sha256(abi.encodePacked(ticket, _tokens[n], _tokenAmounts[n]+_bountyAmounts[n]));
        }
        ticket = sha256(abi.encodePacked(ticket, _firstTransferInTicket));
        ticket = sha256(abi.encodePacked(ticket, _lastTransferInTicket));
        ticket = sha256(abi.encodePacked(ticket, _stateRoot));
        require(ticket == _ticket, "Invalid ticket formed");
        require(tickets[_destChain][_ticket], "Ticket unknown to contract");

        lastConfirmedTransfer[_destChain] = _lastTransferInTicket;
        tickets[_destChain][_ticket] = false; // Reset to prevent double spend

        _bridgeFunds(_destChain, _tokens, _tokenAmounts, _bountyAmounts, _provider);

        emit TicketConfirmed(_ticket, _stateRoot);
    }

    /********************** 
     * internal functions *
     ***********************/

    /**
     * Update the Merkle Tree representation with the new node
     * @dev Taken from Ethereum's deposit contract
     * @dev see https://etherscan.io/address/0x00000000219ab540356cbb839cbe05303d7705fa#code#L1
     */
    function updateMerkle(uint256 _chain, bytes32 _node) internal {
        uint size = transferCount[_chain] % MAX_DEPOSIT_COUNT;
        for (uint height = 0; height < MERKLE_TREE_DEPTH; height++) {

            // Check odd, ie, left neighbour
            if ((size & 1) == 1) {
                branch[_chain][height] = _node;
                return;
            }

            _node = sha256(abi.encodePacked(branch[_chain][height], _node));
            size /= 2;
        }
        
        // As the loop should always end prematurely with the `return` statement,
        // this code should be unreachable. We assert `false` just to be safe.
        assert(false);
    }

    /**
     * Get the current merkle root stored in the contract
     * @dev Taken from Ethereum's deposit contract
     * @dev see https://etherscan.io/address/0x00000000219ab540356cbb839cbe05303d7705fa#code#L1
     *
     */
    function getMerkleRoot(uint256 _chain) internal view checkInitialization returns (bytes32) {
        bytes32 node;
        uint size = transferCount[_chain] % MAX_DEPOSIT_COUNT;
        for (uint height = 0; height < MERKLE_TREE_DEPTH; height++) {
            if ((size & 1) == 1)
                node = sha256(abi.encodePacked(branch[_chain][height], node));
            else
                node = sha256(abi.encodePacked(node, zeroes[height]));
            size /= 2;
        }
        return node;
    }

}

// SPDX-License-Identifier: Apache-2.0

/*
 * Copyright 2020, Offchain Labs, Inc.
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

// @dev Changed from ^0.6.11
// @dev see https://github.com/OffchainLabs/arbitrum/blob/master/packages/arb-bridge-peripherals/contracts/tokenbridge/libraries/gateway/ITokenGateway.sol
pragma solidity ^0.8.11;

interface ITokenGateway {
    /// @notice event deprecated in favor of DepositInitiated and WithdrawalInitiated
    // event OutboundTransferInitiated(
    //     address token,
    //     address indexed _from,
    //     address indexed _to,
    //     uint256 indexed _transferId,
    //     uint256 _amount,
    //     bytes _data
    // );

    /// @notice event deprecated in favor of DepositFinalized and WithdrawalFinalized
    // event InboundTransferFinalized(
    //     address token,
    //     address indexed _from,
    //     address indexed _to,
    //     uint256 indexed _transferId,
    //     uint256 _amount,
    //     bytes _data
    // );

    function outboundTransfer(
        address _token,
        address _to,
        uint256 _amount,
        uint256 _maxGas,
        uint256 _gasPriceBid,
        bytes calldata _data
    ) external payable returns (bytes memory);

    function finalizeInboundTransfer(
        address _token,
        address _from,
        address _to,
        uint256 _amount,
        bytes calldata _data
    ) external payable;

    /**
     * @notice Calculate the address used when bridging an ERC20 token
     * @dev the L1 and L2 address oracles may not always be in sync.
     * For example, a custom token may have been registered but not deploy or the contract self destructed.
     * @param l1ERC20 address of L1 token
     * @return L2 address of a bridged ERC20 token
     */
    function calculateL2TokenAddress(address l1ERC20) external view returns (address);

    /**
     * @notice Taken from GatewayRouter : 
     * https://github.com/OffchainLabs/arbitrum/blob/master/packages/arb-bridge-peripherals/contracts/tokenbridge/libraries/gateway/GatewayRouter.sol#L115
     * @dev temporary solution to incompatible solidity versions
     */
    function getGateway(address _token) external view returns (address gateway);

    /**
     * @notice Taken from L2GatewayRouter :
     * https://github.com/OffchainLabs/arbitrum/blob/master/packages/arb-bridge-peripherals/contracts/tokenbridge/arbitrum/gateway/L2GatewayRouter.sol#L57
     * @dev temporary solution to incompatible solidity versions
     */
    function outboundTransfer(
        address _l1Token,
        address _to,
        uint256 _amount,
        bytes calldata _data
    ) external payable returns (bytes memory);
}

// Copyright 2021-2022, Offchain Labs, Inc.
// For license information, see https://github.com/nitro/blob/master/LICENSE
// SPDX-License-Identifier: BUSL-1.1

pragma solidity >=0.4.21 <0.9.0;

/**
 * @title System level functionality
 * @notice For use by contracts to interact with core L2-specific functionality.
 * Precompiled contract that exists in every Arbitrum chain at address(100), 0x0000000000000000000000000000000000000064.
 */
interface ArbSys {
    /**
     * @notice Get Arbitrum block number (distinct from L1 block number; Arbitrum genesis block has block number 0)
     * @return block number as int
     */
    function arbBlockNumber() external view returns (uint256);

    /**
     * @notice Get Arbitrum block hash (reverts unless currentBlockNum-256 <= arbBlockNum < currentBlockNum)
     * @return block hash
     */
    function arbBlockHash(uint256 arbBlockNum) external view returns (bytes32);

    /**
     * @notice Gets the rollup's unique chain identifier
     * @return Chain identifier as int
     */
    function arbChainID() external view returns (uint256);

    /**
     * @notice Get internal version number identifying an ArbOS build
     * @return version number as int
     */
    function arbOSVersion() external view returns (uint256);

    /**
     * @notice Returns 0 since Nitro has no concept of storage gas
     * @return int 0
     */
    function getStorageGasAvailable() external returns (uint256);

    /**
     * @notice check if current call is coming from l1
     * @return true if the caller of this was called directly from L1
     */
    function isTopLevelCall() external view returns (bool);

    /**
     * @notice map L1 sender contract address to its L2 alias
     * @param sender sender address
     * @param unused argument no longer used
     * @return aliased sender address
     */
    function mapL1SenderContractAddressToL2Alias(address sender, address unused)
        external
        pure
        returns (address);

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
     * @notice Send given amount of Eth to dest from sender.
     * This is a convenience function, which is equivalent to calling sendTxToL1 with empty data.
     * @param destination recipient address on L1
     * @return unique identifier for this L2-to-L1 transaction.
     */
    function withdrawEth(address destination) external payable returns (uint256);

    /**
     * @notice Send a transaction to L1
     * @param destination recipient address on L1
     * @param data (optional) calldata for L1 contract call
     * @return a unique identifier for this L2-to-L1 transaction.
     */
    function sendTxToL1(address destination, bytes calldata data)
        external
        payable
        returns (uint256);

    /**
     * @notice Get send Merkle tree state
     * @return size number of sends in the history
     * @return root root hash of the send history
     * @return partials hashes of partial subtrees in the send history tree
     */
    function sendMerkleTreeState()
        external
        view
        returns (
            uint256 size,
            bytes32 root,
            bytes32[] memory partials
        );

    /**
     * @notice creates a send txn from L2 to L1
     * @param position = (level << 192) + leaf = (0 << 192) + leaf = leaf
     */
    event L2ToL1Transaction(
        address caller,
        address indexed destination,
        uint256 indexed hash,
        uint256 indexed position,
        uint256 indexInBatch,
        uint256 arbBlockNum,
        uint256 ethBlockNum,
        uint256 timestamp,
        uint256 callvalue,
        bytes data
    );

    /**
     * @notice logs a merkle branch for proof sythesis
     * @param reserved an index meant only to align the 4th index with L2ToL1Transaction's 4th event
     * @param hash the merkle hash
     * @param position = (level << 192) + leaf
     */
    event SendMerkleUpdate(
        uint256 indexed reserved,
        bytes32 indexed hash,
        uint256 indexed position
    );
}

// Copyright 2021-2022, Offchain Labs, Inc.
// For license information, see https://github.com/nitro/blob/master/LICENSE
// SPDX-License-Identifier: BUSL-1.1

pragma solidity ^0.8.0;

library AddressAliasHelper {
    uint160 internal constant OFFSET = uint160(0x1111000000000000000000000000000000001111);

    /// @notice Utility function that converts the address in the L1 that submitted a tx to
    /// the inbox to the msg.sender viewed in the L2
    /// @param l1Address the address in the L1 that triggered the tx to L2
    /// @return l2Address L2 address as viewed in msg.sender
    function applyL1ToL2Alias(address l1Address) internal pure returns (address l2Address) {
        unchecked {
            l2Address = address(uint160(l1Address) + OFFSET);
        }
    }

    /// @notice Utility function that converts the msg.sender viewed in the L2 to the
    /// address in the L1 that submitted a tx to the inbox
    /// @param l2Address L2 address as viewed in msg.sender
    /// @return l1Address the address in the L1 that triggered the tx to L2
    function undoL1ToL2Alias(address l2Address) internal pure returns (address l1Address) {
        unchecked {
            l1Address = address(uint160(l2Address) - OFFSET);
        }
    }
}

//SPDX-License-Identifier: LGPL-3.0-or-later
pragma solidity ^0.8.11;

/**
 *
 *
 */
interface IBuddleSource {

    struct TransferData {
        address tokenAddress;
        address destination;
        uint256 amount;
        uint256 fee;
        uint256 startTime;
        uint256 feeRampup;
        uint256 chain;
    }

    /********************** 
     * onlyOwner functions *
     ***********************/

    /**
     * Initialize the contract with state variables
     * 
     * @param _version Contract version
     * @param _feeBasisPoints The fee per transfer in basis points
     * @param _feeRampUp The fee ramp up for each transfer
     * @param _buddleBridge The Layer-1 Buddle Bridge contract
     */
    function initialize(
        bytes32 _version,
        uint256 _feeBasisPoints,
        uint256 _feeRampUp,
        address _buddleBridge
    ) external;

    /**
     * Add supported tokens to the contract
     *
     */
    function addTokens(
        address[] memory _tokens
    ) external;

    /**
     * Add the destination contract address for a given chain id
     *
     */
    function addDestination(
        uint256 _destChain,
        address _contract
    ) external;

    /**
     * Change the contract fee basis points
     *
     */
    function updateContractFeeBasisPoints(
        uint256 _newContractFeeBasisPoints
    ) external;

    /**
     * Change the contract fee ramp up
     *
     */
    function updateContractFeeRampUp(
        uint256 _newContractFeeRampUp
    ) external;

    /**
     * Change the buddle bridge address
     *
     */
    function updateBuddleBridge(
        address _newBridgeAddress
    ) external;

    /**
     * Change the Destination contract address for the given chain id
     *
     */
    function updateDestination(
        uint256 _destChain,
        address _contract
    ) external;

    /********************** 
     * public functions *
     ***********************/

    /**
     * @notice previously `widthdraw`
     * 
     * Deposit funds into the contract to start the bridging process
     * 
     * @param _tokenAddress The contract address of the token being bridged
     *  is address(0) if base token
     * @param _destination The destination address for the bridged tokens
     * @param _amount The amount of tokens to be bridged
     * @param _destChain The chain ID for the destination blockchain
     */
    function deposit(
        address _tokenAddress,
        uint256 _amount,
        address _destination,
        uint256 _destChain
    ) external payable returns(bytes32 node);

    /**
     * Create a ticket before providing liquidity to the L1 bridge
     * LP creates this ticket and provides liquidity to win the bounty
     *
     * @param _destChain The chain ID for the destination blockchain
     */
    function createTicket(
        uint256 _destChain
    ) external returns(bytes32 node);

    /**
     * Confirms the ticket once liquidity is provided on the Layer-1 Buddle Bridge contract
     * @notice can only be called by the cross domain messenger
     *
     * @param _ticket The ticket to be confirmed
     * @param _destChain The chain ID for the destination blockchain
     * @param _tokens The token addresses included in the ticket
     * @param _tokenAmounts The token amounts included in the ticket
     * @param _bountyAmounts The bounty amounts included in the ticket
     * @param _firstTransferInTicket The initial transfer ID included in ticket
     * @param _lastTransferInTicket The final transfer ID included in ticket
     * @param _stateRoot The state root included in ticket
     * @param _provider The liquidity provider on the L1 bridge contract
     */
    function confirmTicket(
        bytes32 _ticket,
        uint256 _destChain,
        address[] memory _tokens,
        uint256[] memory _tokenAmounts,
        uint256[] memory _bountyAmounts,
        uint256 _firstTransferInTicket, 
        uint256 _lastTransferInTicket, 
        bytes32 _stateRoot,
        address _provider
    ) external;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (access/Ownable.sol)

pragma solidity ^0.8.0;

import "../utils/Context.sol";

/**
 * @dev Contract module which provides a basic access control mechanism, where
 * there is an account (an owner) that can be granted exclusive access to
 * specific functions.
 *
 * By default, the owner account will be the one that deploys the contract. This
 * can later be changed with {transferOwnership}.
 *
 * This module is used through inheritance. It will make available the modifier
 * `onlyOwner`, which can be applied to your functions to restrict their use to
 * the owner.
 */
abstract contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor() {
        _transferOwnership(_msgSender());
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
        _;
    }

    /**
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions anymore. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby removing any functionality that is only available to the owner.
     */
    function renounceOwnership() public virtual onlyOwner {
        _transferOwnership(address(0));
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _transferOwnership(newOwner);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Internal function without access restriction.
     */
    function _transferOwnership(address newOwner) internal virtual {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC20/IERC20.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20 {
    /**
     * @dev Emitted when `value` tokens are moved from one account (`from`) to
     * another (`to`).
     *
     * Note that `value` may be zero.
     */
    event Transfer(address indexed from, address indexed to, uint256 value);

    /**
     * @dev Emitted when the allowance of a `spender` for an `owner` is set by
     * a call to {approve}. `value` is the new allowance.
     */
    event Approval(address indexed owner, address indexed spender, uint256 value);

    /**
     * @dev Returns the amount of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the amount of tokens owned by `account`.
     */
    function balanceOf(address account) external view returns (uint256);

    /**
     * @dev Moves `amount` tokens from the caller's account to `to`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address to, uint256 amount) external returns (bool);

    /**
     * @dev Returns the remaining number of tokens that `spender` will be
     * allowed to spend on behalf of `owner` through {transferFrom}. This is
     * zero by default.
     *
     * This value changes when {approve} or {transferFrom} are called.
     */
    function allowance(address owner, address spender) external view returns (uint256);

    /**
     * @dev Sets `amount` as the allowance of `spender` over the caller's tokens.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * IMPORTANT: Beware that changing an allowance with this method brings the risk
     * that someone may use both the old and the new allowance by unfortunate
     * transaction ordering. One possible solution to mitigate this race
     * condition is to first reduce the spender's allowance to 0 and set the
     * desired value afterwards:
     * https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
     *
     * Emits an {Approval} event.
     */
    function approve(address spender, uint256 amount) external returns (bool);

    /**
     * @dev Moves `amount` tokens from `from` to `to` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) external returns (bool);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC20/utils/SafeERC20.sol)

pragma solidity ^0.8.0;

import "../IERC20.sol";
import "../../../utils/Address.sol";

/**
 * @title SafeERC20
 * @dev Wrappers around ERC20 operations that throw on failure (when the token
 * contract returns false). Tokens that return no value (and instead revert or
 * throw on failure) are also supported, non-reverting calls are assumed to be
 * successful.
 * To use this library you can add a `using SafeERC20 for IERC20;` statement to your contract,
 * which allows you to call the safe operations as `token.safeTransfer(...)`, etc.
 */
library SafeERC20 {
    using Address for address;

    function safeTransfer(
        IERC20 token,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
    }

    function safeTransferFrom(
        IERC20 token,
        address from,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transferFrom.selector, from, to, value));
    }

    /**
     * @dev Deprecated. This function has issues similar to the ones found in
     * {IERC20-approve}, and its usage is discouraged.
     *
     * Whenever possible, use {safeIncreaseAllowance} and
     * {safeDecreaseAllowance} instead.
     */
    function safeApprove(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        // safeApprove should only be called when setting an initial allowance,
        // or when resetting it to zero. To increase and decrease it, use
        // 'safeIncreaseAllowance' and 'safeDecreaseAllowance'
        require(
            (value == 0) || (token.allowance(address(this), spender) == 0),
            "SafeERC20: approve from non-zero to non-zero allowance"
        );
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, value));
    }

    function safeIncreaseAllowance(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        uint256 newAllowance = token.allowance(address(this), spender) + value;
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    function safeDecreaseAllowance(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        unchecked {
            uint256 oldAllowance = token.allowance(address(this), spender);
            require(oldAllowance >= value, "SafeERC20: decreased allowance below zero");
            uint256 newAllowance = oldAllowance - value;
            _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
        }
    }

    /**
     * @dev Imitates a Solidity high-level call (i.e. a regular function call to a contract), relaxing the requirement
     * on the return value: the return value is optional (but if data is returned, it must not be false).
     * @param token The token targeted by the call.
     * @param data The call data (encoded using abi.encode or one of its variants).
     */
    function _callOptionalReturn(IERC20 token, bytes memory data) private {
        // We need to perform a low level call here, to bypass Solidity's return data size checking mechanism, since
        // we're implementing it ourselves. We use {Address.functionCall} to perform this call, which verifies that
        // the target address contains contract code and also asserts for success in the low-level call.

        bytes memory returndata = address(token).functionCall(data, "SafeERC20: low-level call failed");
        if (returndata.length > 0) {
            // Return data is optional
            require(abi.decode(returndata, (bool)), "SafeERC20: ERC20 operation did not succeed");
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/Context.sol)

pragma solidity ^0.8.0;

/**
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
 *
 * This contract is only required for intermediate, library-like contracts.
 */
abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (utils/Address.sol)

pragma solidity ^0.8.1;

/**
 * @dev Collection of functions related to the address type
 */
library Address {
    /**
     * @dev Returns true if `account` is a contract.
     *
     * [IMPORTANT]
     * ====
     * It is unsafe to assume that an address for which this function returns
     * false is an externally-owned account (EOA) and not a contract.
     *
     * Among others, `isContract` will return false for the following
     * types of addresses:
     *
     *  - an externally-owned account
     *  - a contract in construction
     *  - an address where a contract will be created
     *  - an address where a contract lived, but was destroyed
     * ====
     *
     * [IMPORTANT]
     * ====
     * You shouldn't rely on `isContract` to protect against flash loan attacks!
     *
     * Preventing calls from contracts is highly discouraged. It breaks composability, breaks support for smart wallets
     * like Gnosis Safe, and does not provide security since it can be circumvented by calling from a contract
     * constructor.
     * ====
     */
    function isContract(address account) internal view returns (bool) {
        // This method relies on extcodesize/address.code.length, which returns 0
        // for contracts in construction, since the code is only stored at the end
        // of the constructor execution.

        return account.code.length > 0;
    }

    /**
     * @dev Replacement for Solidity's `transfer`: sends `amount` wei to
     * `recipient`, forwarding all available gas and reverting on errors.
     *
     * https://eips.ethereum.org/EIPS/eip-1884[EIP1884] increases the gas cost
     * of certain opcodes, possibly making contracts go over the 2300 gas limit
     * imposed by `transfer`, making them unable to receive funds via
     * `transfer`. {sendValue} removes this limitation.
     *
     * https://diligence.consensys.net/posts/2019/09/stop-using-soliditys-transfer-now/[Learn more].
     *
     * IMPORTANT: because control is transferred to `recipient`, care must be
     * taken to not create reentrancy vulnerabilities. Consider using
     * {ReentrancyGuard} or the
     * https://solidity.readthedocs.io/en/v0.5.11/security-considerations.html#use-the-checks-effects-interactions-pattern[checks-effects-interactions pattern].
     */
    function sendValue(address payable recipient, uint256 amount) internal {
        require(address(this).balance >= amount, "Address: insufficient balance");

        (bool success, ) = recipient.call{value: amount}("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }

    /**
     * @dev Performs a Solidity function call using a low level `call`. A
     * plain `call` is an unsafe replacement for a function call: use this
     * function instead.
     *
     * If `target` reverts with a revert reason, it is bubbled up by this
     * function (like regular Solidity function calls).
     *
     * Returns the raw returned data. To convert to the expected return value,
     * use https://solidity.readthedocs.io/en/latest/units-and-global-variables.html?highlight=abi.decode#abi-encoding-and-decoding-functions[`abi.decode`].
     *
     * Requirements:
     *
     * - `target` must be a contract.
     * - calling `target` with `data` must not revert.
     *
     * _Available since v3.1._
     */
    function functionCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionCall(target, data, "Address: low-level call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`], but with
     * `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        return functionCallWithValue(target, data, 0, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but also transferring `value` wei to `target`.
     *
     * Requirements:
     *
     * - the calling contract must have an ETH balance of at least `value`.
     * - the called Solidity function must be `payable`.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value
    ) internal returns (bytes memory) {
        return functionCallWithValue(target, data, value, "Address: low-level call with value failed");
    }

    /**
     * @dev Same as {xref-Address-functionCallWithValue-address-bytes-uint256-}[`functionCallWithValue`], but
     * with `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(address(this).balance >= value, "Address: insufficient balance for call");
        require(isContract(target), "Address: call to non-contract");

        (bool success, bytes memory returndata) = target.call{value: value}(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(address target, bytes memory data) internal view returns (bytes memory) {
        return functionStaticCall(target, data, "Address: low-level static call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal view returns (bytes memory) {
        require(isContract(target), "Address: static call to non-contract");

        (bool success, bytes memory returndata) = target.staticcall(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function functionDelegateCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionDelegateCall(target, data, "Address: low-level delegate call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function functionDelegateCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(isContract(target), "Address: delegate call to non-contract");

        (bool success, bytes memory returndata) = target.delegatecall(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Tool to verifies that a low level call was successful, and revert if it wasn't, either by bubbling the
     * revert reason using the provided one.
     *
     * _Available since v4.3._
     */
    function verifyCallResult(
        bool success,
        bytes memory returndata,
        string memory errorMessage
    ) internal pure returns (bytes memory) {
        if (success) {
            return returndata;
        } else {
            // Look for revert reason and bubble it up if present
            if (returndata.length > 0) {
                // The easiest way to bubble the revert reason is using memory via assembly

                assembly {
                    let returndata_size := mload(returndata)
                    revert(add(32, returndata), returndata_size)
                }
            } else {
                revert(errorMessage);
            }
        }
    }
}