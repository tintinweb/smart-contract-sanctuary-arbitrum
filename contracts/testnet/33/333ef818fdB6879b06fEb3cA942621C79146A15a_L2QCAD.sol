// File: contracts/QCAD.sol

pragma solidity ^0.8.0;

import "./ERC20Pausable.sol";
import "./IArbToken.sol";

contract L2QCAD is ERC20Pausable, IArbToken {
  address public l2Gateway;
  address public override l1Address;

  function initialize(
    string calldata name,
    string calldata symbol,
    uint8 decimals,
    address[] calldata admins,
    address _l2Gateway,
    address _l1TokenAddress
  ) external initializer {
    ERC20Detailed.initialize(name, symbol, decimals);
    Ownable.initialize(_msgSender());
    Pausable.initialize();
    l2Gateway = _l2Gateway;
    l1Address = _l1TokenAddress;

    for (uint256 i = 0; i < admins.length; ++i) {
      _addAdmin(admins[i]);
    }
  }

  modifier onlyL2Gateway() {
    require(msg.sender == l2Gateway, "NOT_GATEWAY");
    _;
  }

  /**
   * @notice should increase token supply by amount, and should only be callable by the L2Gateway.
   */
  function bridgeMint(address account, uint256 amount)
    external
    override
    onlyL2Gateway
    whenNotPaused
  {
    _mint(account, amount);
  }

  /**
   * @notice should decrease token supply by amount, and should only be callable by the L2Gateway.
   */
  function bridgeBurn(address account, uint256 amount)
    external
    override
    onlyL2Gateway
    whenNotPaused
  {
    _burn(account, amount);
  }
}