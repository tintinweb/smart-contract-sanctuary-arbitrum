// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.16;

import { HedgersStorage, Hedger } from "./HedgersStorage.sol";
import { HedgersInternal } from "./HedgersInternal.sol";
import { IHedgersEvents } from "./IHedgersEvents.sol";

contract Hedgers is IHedgersEvents {
    using HedgersStorage for HedgersStorage.Layout;

    /* ========== VIEWS ========== */

    function getHedgerByAddress(address _hedger) external view returns (bool success, Hedger memory hedger) {
        return HedgersInternal.getHedgerByAddress(_hedger);
    }

    function getHedgers() external view returns (Hedger[] memory hedgerList) {
        return HedgersInternal.getHedgers();
    }

    function getHedgersLength() external view returns (uint256 length) {
        return HedgersInternal.getHedgersLength();
    }

    /* ========== WRITES ========== */

    function enlist() external returns (Hedger memory hedger) {
        HedgersStorage.Layout storage s = HedgersStorage.layout();

        require(msg.sender != address(0), "Invalid address");
        require(s.hedgerMap[msg.sender].addr != msg.sender, "Hedger already exists");

        hedger = Hedger(msg.sender);
        s.hedgerMap[msg.sender] = hedger;
        s.hedgerList.push(hedger);

        emit Enlist(msg.sender, block.timestamp);
    }
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.16;

import { HedgersStorage, Hedger } from "./HedgersStorage.sol";

library HedgersInternal {
    using HedgersStorage for HedgersStorage.Layout;

    /* ========== VIEWS ========== */

    function getHedgerByAddress(address _hedger) internal view returns (bool success, Hedger memory hedger) {
        hedger = HedgersStorage.layout().hedgerMap[_hedger];
        return hedger.addr == address(0) ? (false, hedger) : (true, hedger);
    }

    function getHedgerByAddressOrThrow(address partyB) internal view returns (Hedger memory) {
        (bool success, Hedger memory hedger) = getHedgerByAddress(partyB);
        require(success, "Hedger is not valid");
        return hedger;
    }

    function getHedgers() internal view returns (Hedger[] memory hedgerList) {
        return HedgersStorage.layout().hedgerList;
    }

    function getHedgersLength() internal view returns (uint256 length) {
        return HedgersStorage.layout().hedgerList.length;
    }
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.16;

struct Hedger {
    address addr;
}

library HedgersStorage {
    bytes32 internal constant STORAGE_SLOT = keccak256("diamond.standard.hedgers.storage");

    struct Layout {
        mapping(address => Hedger) hedgerMap;
        Hedger[] hedgerList;
    }

    function layout() internal pure returns (Layout storage l) {
        bytes32 slot = STORAGE_SLOT;
        assembly {
            l.slot := slot
        }
    }
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.16;

interface IHedgersEvents {
    event Enlist(address indexed hedger, uint256 timestamp);
}