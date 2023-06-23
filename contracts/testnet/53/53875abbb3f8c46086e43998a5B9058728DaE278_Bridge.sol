// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

contract Access {
    address public owner;
    mapping(address => bool) public governors;

    modifier onlyOwner() {
        require(msg.sender == owner, "only owner");
        _;
    }

    modifier onlyOwnerOrGovernor() {
        require(governors[msg.sender] || msg.sender == owner, "only owner or governor");
        _;
    }

    constructor() {
        owner = msg.sender;
    }

    function setGovernor(address _governor) external onlyOwner {
        governors[_governor] = true;
    }

    function revokeGovernor(address _governor) external onlyOwner {
        governors[_governor] = false;
    }

    function transferOwnership(address _owner) external onlyOwner {
        require(_owner != address(0), "invalid owner");
        owner = _owner;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import "./interfaces/IAxelarGateway.sol";
import "./interfaces/IFeeService.sol";
import "./interfaces/ITestToken.sol";
import "./Access.sol";
contract Bridge is Access {
    struct BridgeInfo {
        string bridgeAddr;
        bool set;
        bool open;
    }

    IAxelarGateway public axelarGateway;
    IFeeService public feeService;
    ITestToken public TestToken;
    mapping(string => BridgeInfo) public bridges;

    constructor(address _axelarGateway, address _feeService, address _TestToken) {
        axelarGateway = IAxelarGateway(_axelarGateway);
        feeService = IFeeService(_feeService);
        TestToken = ITestToken(_TestToken);
    }

    function bridgeOut(
        string calldata desChain,
        uint256 amount
    ) external payable {
        BridgeInfo memory bridge = bridges[desChain];
        require(bridge.set, "Bridge: invalid bridge");
        require(bridge.open, "Bridge: closed bridge");

        bytes memory payload = abi.encode(msg.sender ,amount);
        feeService.payNativeGasForContractCall{value: msg.value}(
            address(this), 
            desChain, 
            bridge.bridgeAddr, 
            payload, 
            msg.sender
        );
        TestToken.bridgeBurn(msg.sender, amount);
        axelarGateway.callContract(desChain, bridge.bridgeAddr, payload);
    }

    function execute(
        bytes32 commandId,
        string calldata sourceChain,
        string calldata sourceAddress,
        bytes calldata payload
    ) external {
        bytes32 bridgeAddrHash = keccak256(abi.encode(bridges[sourceChain].bridgeAddr));
        bytes32 sourceAddressHash = keccak256(abi.encode(sourceAddress));
        require(bridgeAddrHash == sourceAddressHash, "Bridge: invalid caller");

        bytes32 payloadHash = keccak256(payload);
        require(
            axelarGateway.validateContractCall(commandId, sourceChain, sourceAddress, payloadHash),
            "Bridge: invalid call"
        );

        (address account, uint256 amount) = abi.decode(payload, (address, uint256));
        TestToken.bridgeMint(account, amount);
    }

    function setBridges(
        string[] memory chains, 
        string[] memory bridgeAddrs, 
        bool[] memory open
    ) external onlyOwnerOrGovernor {
        for (uint256 i = 0; i < chains.length; i++) {
            bridges[chains[i]] = BridgeInfo(bridgeAddrs[i], true, open[i]);
        }
    }

    function setBridgeConnections(string[] memory chains, bool[] memory open) external onlyOwnerOrGovernor {
        for (uint256 i = 0; i < chains.length; i++) {
            require(bridges[chains[i]].set, "Bridge: unset bridge");
            bridges[chains[i]].open = open[i];
        }
    }

}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

interface IAxelarGateway {
    function callContract(
        string calldata destinationChain,
        string calldata contractAddress,
        bytes calldata payload
    ) external;

    function validateContractCall(
        bytes32 commandId,
        string calldata sourceChain,
        string calldata sourceAddress,
        bytes32 payloadHash
    ) external returns (bool);

}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

interface IFeeService {
    function payNativeGasForContractCall(
        address sender,
        string calldata destinationChain,
        string calldata destinationAddress,
        bytes calldata payload,
        address refundAddress
    ) external payable;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

interface ITestToken {
    function bridgeMint(address account, uint256 amount) external returns(bool);
    function bridgeBurn(address account, uint256 amount) external returns(bool);
    function balanceOf(address owner) external view returns(uint256);
}