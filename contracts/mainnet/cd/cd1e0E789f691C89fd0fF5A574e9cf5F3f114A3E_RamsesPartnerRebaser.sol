// SPDX-License-Identifier: MIT
/************************************************************************/
//PartnerRebaser contract to provide good actor anti-dilution to partners
/************************************************************************/
pragma solidity ^0.8.13;

interface IERC20 {
    function approve(address _spender, uint256 _amount) external;

    function transferFrom(address _from, address _to, uint256 _amount) external;

    function transfer(address _to, uint256 _amount) external;

    function balanceOf(address _wallet) external view returns (uint256);
}

interface IVeRAM {
    function increase_amount(uint256 _tokenID, uint256 _amount) external;

    function create_lock_for(
        uint256 _value,
        uint256 _lock,
        address _for
    ) external;
}

contract RamsesPartnerRebaser {
    uint256 public constant MAX_LOCK = 126144000; // 4 years

    address public constant timelock =
        0x9314fC5633329d285F744108D637E1222CEbae1c;
    address public constant multisig =
        0x20D630cF1f5628285BfB91DfaC8C89eB9087BE1A;
    IERC20 public constant ram =
        IERC20(0xAAA6C1E32C55A7Bfa8066A6FAE9b42650F262418);
    IVeRAM public constant veRAM =
        IVeRAM(0xAAA343032aA79eE9a6897Dab03bef967c3289a06);

    event RebasePartner(uint256 _veID, uint256 _amount);
    event AddNewPartnerNFT(address _for, uint256 _amount);

    modifier onlyRamsesTimelock() {
        require(msg.sender == timelock, "!authorized");
        _;
    }

    modifier onlyRamsesMultisig() {
        require(msg.sender == multisig, "!authorized");
        _;
    }

    constructor() {
        ram.approve(address(veRAM), type(uint256).max);
    }

    ///@dev send a direct partner rebase to their NFTID
    function boostPartnerRebase(
        uint256 _veID,
        uint256 _amount
    ) external onlyRamsesMultisig {
        veRAM.increase_amount(_veID, _amount);
        emit RebasePartner(_veID, _amount);
    }

    ///@dev initiate a new partner nft using amounts in the contract
    function initiateNewPartnerLock(
        uint256 _amount,
        address _for
    ) external onlyRamsesMultisig {
        veRAM.create_lock_for(_amount, MAX_LOCK, _for);
        emit AddNewPartnerNFT(_for, _amount);
    }

    function withdraw(
        address token,
        uint256 amount,
        address to
    ) external onlyRamsesTimelock {
        IERC20(token).transfer(to, amount);
    }
}