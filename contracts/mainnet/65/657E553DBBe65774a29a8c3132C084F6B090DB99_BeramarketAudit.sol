pragma solidity 0.8.14;

interface IDatabase {
    function beingAudited(address previous) external;
}

/// @notice Audit For Beramarket via Hyacinth
/// @author jeffx
contract BeramarketAudit {
    constructor(address database) {
        IDatabase(database).beingAudited(0x0000000000000000000000000000000000000000);
    }
}