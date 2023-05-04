/**
 *Submitted for verification at Arbiscan on 2023-05-04
*/

// SPDX-License-Identifier: GPL-3.0
pragma solidity =0.8.19;

abstract contract Adminable {
    address public admin;
    address public candidate;

    event AdminChanged(address indexed previousAdmin, address indexed newAdmin);
    event AdminCandidateRegistered(address indexed admin, address indexed candidate);

    constructor(address _admin) {
        require(_admin != address(0), "admin is the zero address");
        admin = _admin;
        emit AdminChanged(address(0), _admin);
    }

    modifier onlyAdmin() {
        require(msg.sender == admin, "only admin");
        _;
    }

    function isAdmin(address account) public view returns (bool) {
        return account == admin;
    }

    function registerAdminCandidate(address _newAdmin) external onlyAdmin {
        require(_newAdmin != address(0), "new admin is the zero address");
        candidate = _newAdmin;
        emit AdminCandidateRegistered(admin, _newAdmin);
    }

    function confirmAdmin() external {
        require(msg.sender == candidate, "only candidate");
        emit AdminChanged(admin, candidate);
        admin = candidate;
        candidate = address(0);
    }
}


abstract contract AdminableInitializable {
    address public admin;
    address public candidate;

    event AdminUpdated(address indexed previousAdmin, address indexed newAdmin);
    event AdminCandidateRegistered(address indexed admin, address indexed candidate);

    constructor() {}

    function __Adminable_init(address _admin) internal {
        require(_admin != address(0), "admin is the zero address");
        admin = _admin;
        emit AdminUpdated(address(0), _admin);
    }

    modifier onlyAdmin() {
        require(msg.sender == admin, "only admin");
        _;
    }

    function registerAdminCandidate(address _newAdmin) external onlyAdmin {
        require(_newAdmin != address(0), "new admin is the zero address");
        candidate = _newAdmin;
        emit AdminCandidateRegistered(admin, _newAdmin);
    }

    function confirmAdmin() external {
        require(msg.sender == candidate, "only candidate");
        emit AdminUpdated(admin, candidate);
        admin = candidate;
        candidate = address(0);
    }

    uint256[64] private __gap;
}



interface IConvertingFeeCalculator {
    function calculateConvertingFee(
        address account,
        uint256 amount,
        address token
    ) external view returns (uint256);
}


interface IStakingFeeCalculator {
    function calculateStakingFee(
        address account,
        uint256 amount,
        address stakingToken,
        address rewardToken
    ) external view returns (uint256);
}


contract FeeCalculator is IStakingFeeCalculator, IConvertingFeeCalculator {
    uint16 public constant FEE_PERCENTAGE_BASE = 10000;
    uint16 public constant GMXKEY_CONVERTING_FEE_PERCENTAGE = 50; //0.5%
    uint16 public constant DEFAULT_CONVERTING_FEE_PERCENTAGE = 250; //2.5%
    uint16 public constant DEFAULT_STAKING_FEE_PERCENTAGE = 500; //5%

    address public immutable gmxKey;
    address public immutable esGmxKey;
    address public immutable mpKey;

    constructor(address _gmxKey, address _esGmxKey, address _mpKey) {
        require(_gmxKey != address(0), "Converter: gmxKey is the zero address");
        require(_esGmxKey != address(0), "Converter: esGmxKey is the zero address");
        require(_mpKey != address(0), "Converter: mpKey is the zero address");

        gmxKey = _gmxKey;
        esGmxKey = _esGmxKey;
        mpKey = _mpKey;
    }

    function calculateStakingFee(
        address, // account
        uint256 amount,
        address, // stakingToken
        address // rewardToken
    ) public pure returns (uint256) {
        return amount * DEFAULT_STAKING_FEE_PERCENTAGE / FEE_PERCENTAGE_BASE;
    }

    function calculateConvertingFee(
        address, // account
        uint256 amount,
        address convertingToken
    ) public view returns (uint256) {
        if (convertingToken == gmxKey) {
            return amount * GMXKEY_CONVERTING_FEE_PERCENTAGE / FEE_PERCENTAGE_BASE;
        } else {
            return amount * DEFAULT_CONVERTING_FEE_PERCENTAGE / FEE_PERCENTAGE_BASE;
        }
    }
}