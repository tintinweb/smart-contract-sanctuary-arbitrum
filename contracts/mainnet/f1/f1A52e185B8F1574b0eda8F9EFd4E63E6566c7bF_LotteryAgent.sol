// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "./libraries/Ownable.sol";

/// @title Handles Agent-related functions in the FairLottery system.
/// @notice Facilitates registering and calculation of agents and fees.
/// @dev Uses Linear Congruential Generator (LCG) to generate sequential codes that look randomized.
/// https://en.wikipedia.org/wiki/Linear_congruential_generator
/// Using the parameters from Numerical Recipes, maximum up to 2 ** 32 = 4,294,967,296.
/// This cycle period is mathetically proven to be larger than (36 ** 6), preventing conflicts.
contract LotteryAgent is Ownable {
    /// @dev Mapping of agent codes to agent address.
    mapping (string => address) public agents;
    /// @dev Mapping of agent address to agent codes.
    mapping (address => string) public agentCodes;
    
    /// @dev Returns if address has an agent code assigned.
    mapping (address => bool) public isCodeAssigned;

    /// @dev Mapping of user address to his agent address.
    mapping (address => address) public agentMapping;

    /// @dev % Fees per agent tier. (direct, 2nd, 3rd)
    uint256[3] public AGENT_FEES_PERC = [5, 3, 2];
    
    /// @dev Total number of agents registered.
    uint256 public totalAgents;

    /// @dev Address of the lottery system.
    address public fairLotteryAddress;

    /// @dev Seed (X0) for the LCG.
    uint256 private seed = 1;
    /// @dev Multiplier (a) for the LCG.
    uint256 private constant multiplier = 1664525;
    /// @dev Increment (c) for the LCG.
    uint256 private constant increment = 1013904223;
    /// @dev Modulo (m) for the LCG.
    uint256 private constant modulo = 2 ** 32;

    /// @dev Length of the agent code. Maximum possible combinations = 36 ** 6 = 2,176,782,336.
    uint256 public constant STRING_LENGTH = 6;

    /// @dev Simple mapping for base36 conversion (0-9, A-Z)
    string private constant BASE36_CHARS = "0123456789ABCDEFGHIJKLMNOPQRSTUVWXYZ";

    event AddressesChanged(address oldLotteryAddress, address newLotteryAddress);

    event CodeRegistered(address user, string code);
    event AgentEntrusted(address user, address agent);

    // Ownership will be renounced after addresses updated.
    constructor() 
    {
        ownerAddress = msg.sender;
    }

    /// @dev Allows only the Owner to update addresses references.
    function UpdateAddresses(address _fairLotteryAddress) external onlyOwner {
        emit AddressesChanged(fairLotteryAddress, _fairLotteryAddress);
        fairLotteryAddress = _fairLotteryAddress;

    }

    /// @dev Registers and returns the agent code for (`user`).
    /// @dev To prevent overlaps, users after the 4,294,967,296th signup will not receive codes.
    function registerAgentCode(address user) internal returns (string memory code){
        require (msg.sender == fairLotteryAddress, "Invalid sender");
        require (bytes(agentCodes[user]).length == 0, "Code Exists");

        // We've already assigned all unique codes, mark this as assigned without a code.
        if (totalAgents >= modulo) {
            isCodeAssigned[user] = true;
            return ""; 
        }

        // Maximum value of seed here would be multiplier * (2 ** 32 - 1) + increment
        // Which is 7.149...e15, lower than uint256 limits. (2 ** 256 - 1).
        seed = (multiplier * seed + increment) % modulo;

        // Convert the generated number to an 8-character base36 string
        code = toBase36String(seed);

        // Store the unique code
        agentCodes[user] = code;
        agents[code] = user;
        isCodeAssigned[user] = true;

        totalAgents += 1;
        emit CodeRegistered(user, code);
    }

    /// @dev Entrusts an agent with (`agentCode`) for (`user`).
    /// Agents cannot be removed or updated.
    function EntrustAgent(address user, string memory agentCode) external {
        require (msg.sender == fairLotteryAddress, "Invalid Perms");

        // Register this user a code if he doesn't have one.
        if (!isCodeAssigned[user]) {
            registerAgentCode(user);
        }

        if (bytes(agentCode).length == 0 || agentMapping[user] != address(0) || agents[agentCode] == address(0)) {
            // No/invalid code or already entrusted, return.
            return;
        }

        require (agents[agentCode] != user, "No Self Referral");

        // Mark this user's direct agent.
        agentMapping[user] = agents[agentCode];
        emit AgentEntrusted(user, agentMapping[user]);
    }

    /// @dev Returns the agents up to 3 levels for (`user`).
    function GetUserAgents(address user) public view returns (address[3] memory userAgents) {
        if (agentMapping[user] != address(0)) {
            userAgents[0] = agentMapping[user];
        } else {
            return userAgents;
        }

        for (uint256 i = 1; i < userAgents.length; i += 1) {
            address nextAgent = agentMapping[userAgents[i - 1]];
            if (nextAgent != address(0) && !containsAddress(userAgents, nextAgent) && nextAgent != user) {
                userAgents[i] = nextAgent;
            }
        }
    }

    /// @dev Returns the agents fees up to 3 levels for (`user`) based on (`amount`).
    function GetAgentFees(uint256 amount, address user) external view 
    returns (address[3] memory userAgents, uint256[3] memory agentFees) {
        userAgents = GetUserAgents(user);

        for (uint256 i = 0; i < userAgents.length; i += 1) {
            if (userAgents[i] != address(0)) {
                agentFees[i] = amount * AGENT_FEES_PERC[i] / 100;
            }
        }
    }

    /// @dev Converts a number to a string based on BASE36_CHARS.
    function toBase36String(uint256 number) internal pure returns (string memory) {
        bytes memory buffer = new bytes(STRING_LENGTH); // Fixed length for the code
        for (uint256 i = 0; i < STRING_LENGTH; i += 1) {
            buffer[STRING_LENGTH - 1 - i] = bytes(BASE36_CHARS)[number % 36];
            number /= 36;
        }
        return string(buffer);
    }

    /// @dev Helper function to check if an address exists in array.
    function containsAddress(address[3] memory _array, address agent) internal pure returns (bool) {
        for (uint256 i = 0; i < _array.length; i++) {
            if (_array[i] == agent) {
                return true;
            }
        }
        return false;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

/// @title Handles Access Control for a single Owner/multiple Admins.
/// @dev Facilitates ACL via onlyOwner modifiers.
contract Ownable {
    /// @notice Address with Owner privileges.
    address public ownerAddress;
    address public potentialOwner;

    event OwnershipTransferred(address oldOwner, address newOwner);
    event OwnerNominated(address potentialOwner);
    
    /// @dev Throws if the sender is not the owner.
    function _onlyOwner() private view {
        require(msg.sender == ownerAddress, "Not Owner");
    }

    /// @dev Throws if called by any account other than the owner.
    modifier onlyOwner() {
        _onlyOwner();
        _;
    }

    /// @dev Transfers ownership to (`newOwner`).
    function TransferOwnership(address pendingOwner) external onlyOwner {
        require(pendingOwner != address(0), "Invalid owner");
        potentialOwner = pendingOwner;
        emit OwnerNominated(potentialOwner);
    }

    /// @dev Allows nominated owner to accept ownership.
    function AcceptOwnership() external {
        require(msg.sender == potentialOwner, 'Not nominated');
        emit OwnershipTransferred(ownerAddress, potentialOwner);
        ownerAddress = potentialOwner;
        potentialOwner = address(0); 
    }

    /// @dev Revoke ownership.
    /// Transfer to zero address to renounce ownership to disable `onlyOwner` functionality.
    function RevokeOwnership() external onlyOwner {
        emit OwnershipTransferred(ownerAddress, address(0));
        ownerAddress = address(0);
        potentialOwner = address(0);
    }
}