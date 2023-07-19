// SPDX-License-Identifier: agpl-3.0
pragma solidity 0.8.19;

error GovernanceInitializationAlreadyPopulated();
error GovernanceInitializationBadBlockNumber();
error OnlyDAO();
error CoraTokenUnpauseNotReady();
error ProtocolPaused();
error DaoInvalidDelaysConfiguration();
error OnlyDelayAdmin();
error DaoInvalidProposal();
error TokenBadInitialTotalSupply();

//SPDX-License-Identifier: agpl-3.0
pragma solidity 0.8.19;

import { IDeployer } from "../interfaces/IDeployer.sol";

import "./GovernanceErrors.sol";

/**
 * @title GovernanceInitiationData
 * @author Cora Dev Team
 * @notice This contract is used to initiate the Cora governance.
 * @dev This contract will hold information that can be passed to the other contracts of the governance system.
 * This contract will be deployed first and then populated. So other contracts can consume this information.
 */
contract GovernanceInitiationData {
  struct SetupData {
    address tokenAddress;
    address timelockAddress;
    address governorAddress;
  }

  SetupData internal data;
  bool populated = false;
  uint256 deployedBlockNumber;

  constructor() {
    deployedBlockNumber = block.number;
  }

  function populate(SetupData calldata _data) external virtual {
    if (populated) {
      revert GovernanceInitializationAlreadyPopulated();
    }

    if (block.number != deployedBlockNumber) {
      revert GovernanceInitializationBadBlockNumber();
    }
    data = _data;
    populated = true;
  }

  function tokenAddress() public view returns (address) {
    return data.tokenAddress;
  }

  function timelockAddress() public view returns (address) {
    return data.timelockAddress;
  }

  function governorAddress() public view returns (address) {
    return data.governorAddress;
  }
}

//SPDX-License-Identifier: agpl-3.0
pragma solidity 0.8.19;

interface IDeployer {
  event Deployed(address indexed sender, address indexed addr);

  function deploy(bytes memory _initCode, bytes32 _salt)
    external
    returns (address payable createdContract);
}