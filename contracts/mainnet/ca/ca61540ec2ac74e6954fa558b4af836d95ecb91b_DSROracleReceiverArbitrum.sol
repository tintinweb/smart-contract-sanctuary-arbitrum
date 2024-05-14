// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity ^0.8.0;

import { ArbitrumReceiver } from 'xchain-helpers/ArbitrumReceiver.sol';

import { IDSRAuthOracle, IDSROracle } from '../interfaces/IDSRAuthOracle.sol';

contract DSROracleReceiverArbitrum is ArbitrumReceiver {

    IDSRAuthOracle public oracle;

    constructor(
        address _l1Authority,
        IDSRAuthOracle _oracle
    ) ArbitrumReceiver(_l1Authority) {
        oracle = _oracle;
    }

    function setPotData(IDSROracle.PotData calldata data) external onlyCrossChainMessage {
        oracle.setPotData(data);
    }

}

// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity ^0.8.0;

/**
 * @title ArbitrumReceiver
 * @notice Receive messages to an Arbitrum-style chain.
 */
abstract contract ArbitrumReceiver {

    address public immutable l1Authority;

    constructor(
        address _l1Authority
    ) {
        l1Authority = _l1Authority;
    }

    function _getL1MessageSender() internal view returns (address) {
        unchecked {
            return address(uint160(msg.sender) - uint160(0x1111000000000000000000000000000000001111));
        }
    }

    function _onlyCrossChainMessage() internal view {
        require(_getL1MessageSender() == l1Authority, "Receiver/invalid-l1Authority");
    }

    modifier onlyCrossChainMessage() {
        _onlyCrossChainMessage();
        _;
    }

}

// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity >=0.8.0;

import { IDSROracle } from './IDSROracle.sol';

/**
 * @title  IDSRAuthOracle
 * @notice Consolidated DSR reporting along with some convenience functions.
 */
interface IDSRAuthOracle is IDSROracle {

    /** 
     * @notice Emitted when the maxDSR is updated.
     */
    event SetMaxDSR(uint256 maxDSR);

    /**
     * @notice The data provider role.
     */
    function DATA_PROVIDER_ROLE() external view returns (bytes32);

    /**
     * @notice Get the max dsr.
     */
    function maxDSR() external view returns (uint256);

    /**
     * @notice Set the max dsr.
     * @param  maxDSR The max dsr.
     * @dev    Only callable by the admin role.
     */
    function setMaxDSR(uint256 maxDSR) external;

    /**
     * @notice Update the pot data.
     * @param  data The max dsr.
     * @dev    Only callable by the data provider role.
     */
    function setPotData(IDSROracle.PotData calldata data) external;

}

// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity >=0.8.0;

/**
 * @title  IDSROracle
 * @notice Consolidated DSR reporting along with some convenience functions.
 */
interface IDSROracle {

    struct PotData {
        uint96  dsr;  // Dai Savings Rate in per-second value [ray]
        uint120 chi;  // Last computed conversion rate [ray]
        uint40  rho;  // Last computed timestamp [seconds]
    }

    /**
     * @notice Emitted when the PotData is updated.
     * @param  nextData The new PotData struct.
     */
    event SetPotData(PotData nextData);

    /**
     * @notice Retrieve the current PotData: dsr, chi, and rho.
     * @return The current PotData struct.
     */
    function getPotData() external view returns (PotData memory);

    /**
     * @notice Get the current Dai Savings Rate.
     * @return The Dai Savings Rate in per-second value [ray].
     */
    function getDSR() external view returns (uint256);

    /**
     * @notice Get the last computed conversion rate.
     * @return The last computed conversion rate [ray].
     */
    function getChi() external view returns (uint256);

    /**
     * @notice Get the last computed timestamp.
     * @return The last computed timestamp [seconds].
     */
    function getRho() external view returns (uint256);

    /**
     * @notice Get the Annual Percentage Rate.
     * @return The APR.
     */
    function getAPR() external view returns (uint256);

    /**
     * @notice Get the conversion rate at the current timestamp.
     * @return The conversion rate.
     */
    function getConversionRate() external view returns (uint256);

    /**
     * @notice Get the conversion rate at a specified timestamp.
     * @dev    Timestamp must be greater than or equal to the current timestamp.
     * @param  timestamp The timestamp at which to retrieve the conversion rate.
     * @return The conversion rate.
     */
    function getConversionRate(uint256 timestamp) external view returns (uint256);

    /**
     * @notice Get the binomial approximated conversion rate at the current timestamp.
     * @return The binomial approximated conversion rate.
     */
    function getConversionRateBinomialApprox() external view returns (uint256);

    /**
     * @notice Get the binomial approximated conversion rate at a specified timestamp.
     * @dev    Timestamp must be greater than or equal to the current timestamp.
     * @param  timestamp The timestamp at which to retrieve the binomial approximated conversion rate.
     * @return The binomial approximated conversion rate.
     */
    function getConversionRateBinomialApprox(uint256 timestamp) external view returns (uint256);

    /**
     * @notice Get the linear approximated conversion rate at the current timestamp.
     * @return The linear approximated conversion rate.
     */
    function getConversionRateLinearApprox() external view returns (uint256);

    /**
     * @notice Get the linear approximated conversion rate at a specified timestamp.
     * @dev    Timestamp must be greater than or equal to the current timestamp.
     * @param  timestamp The timestamp at which to retrieve the linear approximated conversion rate.
     * @return The linear approximated conversion rate.
     */
    function getConversionRateLinearApprox(uint256 timestamp) external view returns (uint256);

}