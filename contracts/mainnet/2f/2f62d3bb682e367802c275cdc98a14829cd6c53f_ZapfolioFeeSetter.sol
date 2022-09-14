/**
 *Submitted for verification at Arbiscan on 2022-09-14
*/

// Sources flattened with hardhat v2.6.4 https://hardhat.org



pragma solidity >=0.5.0;

interface IZapfolioFactory {
    event PairCreated(address indexed token0, address indexed token1, address pair, uint);

    function INIT_CODE_PAIR_HASH() external pure returns (bytes32);
    function feeTo() external view returns (address);
    function protocolFeeDenominator() external view returns (uint8);
    function feeToSetter() external view returns (address);

    function getPair(address tokenA, address tokenB) external view returns (address pair);
    function allPairs(uint) external view returns (address pair);
    function allPairsLength() external view returns (uint);

    function createPair(address tokenA, address tokenB) external returns (address pair);

    function setFeeTo(address) external;
    function setFeeToSetter(address) external;
    function setProtocolFee(uint8 _protocolFee) external;
    function setSwapFee(address pair, uint32 swapFee) external;
}




pragma solidity =0.5.16;

contract ZapfolioFeeSetter {
    address public owner;
    mapping(address => address) public pairOwners;
    IZapfolioFactory public factory;
  
    constructor(address _owner, address _factory) public {
        owner = _owner;
        factory = IZapfolioFactory(_factory);
    }

    function transferOwnership(address newOwner) external {
        require(msg.sender == owner, 'ZapfolioFeeSetter: FORBIDDEN');
        owner = newOwner;
    }
    
    function transferPairOwnership(address pair, address newOwner) external {
        require(msg.sender == owner, 'ZapfolioFeeSetter: FORBIDDEN');
        pairOwners[pair] = newOwner;
    }

    function setFeeTo(address feeTo) external {
        require(msg.sender == owner, 'ZapfolioFeeSetter: FORBIDDEN');
        factory.setFeeTo(feeTo);
    }

    function setFeeToSetter(address feeToSetter) external {
        require(msg.sender == owner, 'ZapfolioFeeSetter: FORBIDDEN');
        factory.setFeeToSetter(feeToSetter);
    }
    
    function setProtocolFee(uint8 protocolFeeDenominator) external {
        require(msg.sender == owner, 'ZapfolioFeeSetter: FORBIDDEN');
        factory.setProtocolFee(protocolFeeDenominator);
    }
    
    function setSwapFee(address pair, uint32 swapFee) external {
        require((msg.sender == owner) || ((msg.sender == pairOwners[pair])), 'ZapfolioFeeSetter: FORBIDDEN');
        factory.setSwapFee(pair, swapFee);
    }
}