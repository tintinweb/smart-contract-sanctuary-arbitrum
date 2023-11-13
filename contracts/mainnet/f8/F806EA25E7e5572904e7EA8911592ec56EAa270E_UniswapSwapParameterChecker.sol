// SPDX-License-Identifier: GPL-3.0
pragma solidity >=0.8.0 <0.9.0;

interface IParameterChecker {

    /**
     * @dev Return [] on error, return [ 'to' ] if no address to return
     * @param to Destination address of the transaction
     * @param selector Selector of the transaction
     * @param data Data payload of the transaction
     * @return addressList Array of address to be checked with the whitelist
     */
    function getAddressListForChecking(address to, bytes4 selector, bytes memory data) external view returns (address[] memory);
}

// SPDX-License-Identifier: GPL-3.0
pragma solidity >=0.8.0 <0.9.0;

import "../interfaces/IParameterChecker.sol";

contract UniswapSwapParameterChecker is IParameterChecker {
    
    event FeeCollectorUpdated(address indexed from, address indexed to);

    address public gov;
    address public feeCollector;
    
    constructor() {
        gov = msg.sender;
        feeCollector = address(0);
    }
    
    modifier onlyGov() {
        require(gov == msg.sender, "Gov only");
        _;
    }
    
    function updateFeeCollector(address feeCollector_) public onlyGov {
        address _feeCollector = feeCollector;
        feeCollector = feeCollector_;
        emit FeeCollectorUpdated(_feeCollector, feeCollector_);
    }

    function getAddressListForChecking(
        address to,
        bytes4 selector,
        bytes calldata data
    ) external override view returns (address[] memory) {

        if (selector == 0x24856bc3 // execute(commands:bytes,inputs:bytes[])
          || selector == 0x3593564c // execute(commands:bytes,inputs:bytes[],deadline:uint256)
         ) {    
            bytes calldata commands;
            bytes[] calldata inputs;
            assembly{
                let dataOffset := add(data.offset, 4)

                let commandsOffset := calldataload(dataOffset)
                commands.offset := add(add(dataOffset, commandsOffset), 0x20)
                commands.length := calldataload(add(dataOffset, commandsOffset))
                
                let inputsOffset := calldataload(add(dataOffset, 0x20))
                inputs.offset := add(add(dataOffset, inputsOffset), 0x20)
                inputs.length := calldataload(add(dataOffset, inputsOffset))                
            }            

            address[] memory rv = getAddressArrayFromExecute(commands, inputs, to);
            if (rv.length == 0){
                // in case all check is valid but no address to check, we return "to" instead of empty array
                rv = new address[](1);
                rv[0] = to;
            }
            return rv;
        }
        return new address[](0);
    }

    function getAddressArrayFromExecute(bytes calldata commands, bytes[] calldata inputs, address to) internal view returns (address[] memory) {
        address[][] memory _addressArrays = new address[][](commands.length);
        uint256 _addressCount = 0;
        for (uint256 i = 0; i < commands.length; i++) {
            address[] memory _addressArray = dispatch(commands[i], inputs[i]);
            _addressCount += _addressArray.length;
            _addressArrays[i] = _addressArray;
        }
        
        address[] memory rv = new address[](_addressCount);
        uint256 x = 0;
        for (uint256 i = 0; i < _addressArrays.length; i++) {
            for (uint256 j = 0; j < _addressArrays[i].length; j++) {
                rv[x++] = map(_addressArrays[i][j], to);
            }
        }
        return rv;
    }

    function dispatch(bytes1 commandType, bytes calldata inputs) internal view returns (address[] memory rv) {
        uint256 command = uint8(commandType & Commands.COMMAND_TYPE_MASK);

        if (command == Commands.V3_SWAP_EXACT_IN) {
            // equivalent: abi.decode(inputs, (address, uint256, uint256, bytes, bool))
            address recipient;
            bool payerIsUser;
            assembly {
                recipient := calldataload(inputs.offset)
                payerIsUser := calldataload(add(inputs.offset, 0x80))
            }
            bytes calldata path = toBytes(inputs, 3);
            (address token0, address token1) = toPathTokensV3(path);
            if (!payerIsUser) {
                rv = new address[](2);
                rv[0] = recipient;
                rv[1] = token1;
            } else if (recipient == address(2)) {
                rv = new address[](1);
                rv[0] = token0;
            } else {
                rv = new address[](3);
                rv[0] = recipient;
                rv[1] = token0;
                rv[2] = token1;
            }
            return rv;
        } else if (command == Commands.V2_SWAP_EXACT_IN) {
            // equivalent: abi.decode(inputs, (address, uint256, uint256, bytes, bool))
            address recipient;
            bool payerIsUser;
            assembly {
                recipient := calldataload(inputs.offset)
                payerIsUser := calldataload(add(inputs.offset, 0x80))
            }
            bytes calldata path = toBytes(inputs, 3);
            (address token0, address token1) = toPathTokensV2(path);
            if (!payerIsUser) {
                rv = new address[](2);
                rv[0] = recipient;
                rv[1] = token1;
            } else if (recipient == address(2)) {
                rv = new address[](1);
                rv[0] = token0;
            } else {
                rv = new address[](3);
                rv[0] = recipient;
                rv[1] = token0;
                rv[2] = token1;
            }
            return rv;
        } else if (command == Commands.V3_SWAP_EXACT_OUT) {
            // equivalent: abi.decode(inputs, (address, uint256, uint256, bytes, bool))
            address recipient;
            bool payerIsUser;
            assembly {
                recipient := calldataload(inputs.offset)
                payerIsUser := calldataload(add(inputs.offset, 0x80))
            }
            bytes calldata path = toBytes(inputs, 3);
            (address token0, address token1) = toPathTokensV3(path);
            if (!payerIsUser) {
                rv = new address[](2);
                rv[0] = recipient;
                rv[1] = token0;
            } else if (recipient == address(2)) {
                rv = new address[](1);
                rv[0] = token1;
            } else {
                rv = new address[](3);
                rv[0] = recipient;
                rv[1] = token0;
                rv[2] = token1;
            }
            return rv;
        }else if (command == Commands.V2_SWAP_EXACT_OUT) {
            // equivalent: abi.decode(inputs, (address, uint256, uint256, bytes, bool))
            address recipient;
            bool payerIsUser;
            assembly {
                recipient := calldataload(inputs.offset)
                payerIsUser := calldataload(add(inputs.offset, 0x80))
            }
            bytes calldata path = toBytes(inputs, 3);
            (address token0, address token1) = toPathTokensV2(path);
            if (!payerIsUser) {
                rv = new address[](2);
                rv[0] = recipient;
                rv[1] = token0;
            } else if (recipient == address(2)) {
                rv = new address[](1);
                rv[0] = token1;
            } else {
                rv = new address[](3);
                rv[0] = recipient;
                rv[1] = token0;
                rv[2] = token1;
            }
            return rv;
        } else if (command == Commands.PERMIT2_TRANSFER_FROM
                || command == Commands.SWEEP
                || command == Commands.TRANSFER
        ) {
            // equivalent:  abi.decode(inputs, (address, address, uintxxx))            
            address token;
            address recipient;
            assembly {
                token := calldataload(inputs.offset)
                recipient := calldataload(add(inputs.offset, 0x20))
            }
            rv = new address[](2);
            rv[0] = recipient;
            rv[1] = token;
            return rv;
        } else if (command == Commands.PAY_PORTION
        ) {
            // equivalent:  abi.decode(inputs, (address, address, uintxxx))            
            address token;
            address recipient;
            assembly {
                token := calldataload(inputs.offset)
                recipient := calldataload(add(inputs.offset, 0x20))
            }
            if (feeCollector != address(0) && recipient == feeCollector) {
                rv = new address[](1);
                rv[0] = token;
                return rv;
            }
            else {
                rv = new address[](2);
                rv[0] = recipient;
                rv[1] = token;
                return rv;
            }            
        } else if (command == Commands.PERMIT2_PERMIT_BATCH) { // To be implemented
            (PermitBatch memory permitBatch,) = abi.decode(inputs, (PermitBatch, bytes));      
            rv = new address[](permitBatch.details.length + 1);            
            for (uint256 i = 0; i < permitBatch.details.length; i++)
            {
                rv[i] = permitBatch.details[i].token;                
            }
            rv[permitBatch.details.length] = permitBatch.spender;
            return rv;
        } else if (command == Commands.PERMIT2_PERMIT) {
            // equivalent: abi.decode(inputs, (IAllowanceTransfer.PermitSingle, bytes))
            PermitSingle calldata permitSingle;
            assembly {
                permitSingle := inputs.offset
            }            
            rv = new address[](2);
            rv[0] = permitSingle.spender;
            rv[1] = permitSingle.details.token;
            return rv;
        } else if (command == Commands.WRAP_ETH
                || command == Commands.UNWRAP_WETH
                ) {
            // equivalent: abi.decode(inputs, (address, uint256))
            address recipient;
            assembly {
                recipient := calldataload(inputs.offset)
            }
            rv = new address[](1);
            rv[0] = recipient;
            return rv;                        
        } else if (command == Commands.WRAP_ETH
                || command == Commands.UNWRAP_WETH
                ) {
            // equivalent: abi.decode(inputs, (address, uint256))
            address recipient;
            assembly {
                recipient := calldataload(inputs.offset)
            }
            rv = new address[](1);
            rv[0] = recipient;
            return rv;                        
        } else if (command == Commands.PERMIT2_TRANSFER_FROM_BATCH) {
            (AllowanceTransferDetails[] memory batchDetails) = abi.decode(inputs, (AllowanceTransferDetails[]));            
            rv = new address[](batchDetails.length * 2);
            uint256 x = 0;
            for (uint256 i = 0; i < batchDetails.length; i++)
            {
                rv[x++] = batchDetails[i].to;
                rv[x++] = batchDetails[i].token;
            }
            return rv;                 
        } else if (command == Commands.BALANCE_CHECK_ERC20) {
            // equivalent: abi.decode(inputs, (address, address, uint256))                        
            return new address[](0);
        }
        revert("unsupported comand");
    }


    function toPathTokensV3(bytes calldata _bytes) internal pure returns (address token0, address token1) {
        assembly {
            let firstWord := calldataload(_bytes.offset)
            token0 := shr(96, firstWord)
            token1 := shr(96, calldataload(sub(add(_bytes.offset, _bytes.length), 20)))
        }
    }

    function toPathTokensV2(bytes calldata _bytes) internal pure returns (address token0, address token1) {
        assembly {
            let firstWord := calldataload(_bytes.offset)
            token0 := calldataload(_bytes.offset)
            token1 := calldataload(add(_bytes.offset, shl(5, sub(_bytes.length, 1))))
        }
    }

    function toBytes(bytes calldata _bytes, uint256 _arg) internal pure returns (bytes calldata res) {
        assembly {
            let lengthPtr := add(_bytes.offset, calldataload(add(_bytes.offset, shl(5, _arg))))            
            res.length := calldataload(lengthPtr)
            res.offset := add(lengthPtr, 0x20)
        }
    }    

    function map(address recipient, address to) internal view returns (address) {
        if (recipient == address(1)) {
            return msg.sender;
        } else if (recipient == address(2)) {
            return to;
        } else {
            return recipient;
        }
    }

    struct PermitDetails {
        // ERC20 token address
        address token;
        // the maximum amount allowed to spend
        uint160 amount;
        // timestamp at which a spender's token allowances become invalid
        uint48 expiration;
        // an incrementing value indexed per owner,token,and spender for each signature
        uint48 nonce;
    }

    /// @notice The permit message signed for a single token allownce
    struct PermitSingle {
        // the permit data for a single token alownce
        PermitDetails details;
        // address permissioned on the allowed tokens
        address spender;
        // deadline on the permit signature
        uint256 sigDeadline;
    }

    /// @notice The permit message signed for multiple token allowances
    struct PermitBatch {
        // the permit data for multiple token allowances
        PermitDetails[] details;
        // address permissioned on the allowed tokens
        address spender;
        // deadline on the permit signature
        uint256 sigDeadline;
    }
        
    struct AllowanceTransferDetails {
        // the owner of the token
        address from;
        // the recipient of the token
        address to;
        // the amount of the token
        uint160 amount;
        // the token to be transferred
        address token;
    }
}

library Commands {
    // Masks to extract certain bits of commands
    bytes1 internal constant FLAG_ALLOW_REVERT = 0x80;
    bytes1 internal constant COMMAND_TYPE_MASK = 0x3f;

    // Command Types. Maximum supported command at this moment is 0x3f.

    // Command Types where value<0x08, executed in the first nested-if block
    uint256 constant V3_SWAP_EXACT_IN = 0x00;
    uint256 constant V3_SWAP_EXACT_OUT = 0x01;
    uint256 constant PERMIT2_TRANSFER_FROM = 0x02;
    uint256 constant PERMIT2_PERMIT_BATCH = 0x03;
    uint256 constant SWEEP = 0x04;
    uint256 constant TRANSFER = 0x05;
    uint256 constant PAY_PORTION = 0x06;
    // COMMAND_PLACEHOLDER = 0x07;

    // The commands are executed in nested if blocks to minimise gas consumption
    // The following constant defines one of the boundaries where the if blocks split commands
    uint256 constant FIRST_IF_BOUNDARY = 0x08;

    // Command Types where 0x08<=value<=0x0f, executed in the second nested-if block
    uint256 constant V2_SWAP_EXACT_IN = 0x08;
    uint256 constant V2_SWAP_EXACT_OUT = 0x09;
    uint256 constant PERMIT2_PERMIT = 0x0a;
    uint256 constant WRAP_ETH = 0x0b;
    uint256 constant UNWRAP_WETH = 0x0c;
    uint256 constant PERMIT2_TRANSFER_FROM_BATCH = 0x0d;
    uint256 constant BALANCE_CHECK_ERC20 = 0x0e;
    // COMMAND_PLACEHOLDER = 0x0f;

    // The commands are executed in nested if blocks to minimise gas consumption
    // The following constant defines one of the boundaries where the if blocks split commands
    uint256 constant SECOND_IF_BOUNDARY = 0x10;

    // Command Types where 0x10<=value<0x18, executed in the third nested-if block
    uint256 constant SEAPORT_V1_5 = 0x10;
    uint256 constant LOOKS_RARE_V2 = 0x11;
    uint256 constant NFTX = 0x12;
    uint256 constant CRYPTOPUNKS = 0x13;
    // 0x14;
    uint256 constant OWNER_CHECK_721 = 0x15;
    uint256 constant OWNER_CHECK_1155 = 0x16;
    uint256 constant SWEEP_ERC721 = 0x17;

    // The commands are executed in nested if blocks to minimise gas consumption
    // The following constant defines one of the boundaries where the if blocks split commands
    uint256 constant THIRD_IF_BOUNDARY = 0x18;

    // Command Types where 0x18<=value<=0x1f, executed in the final nested-if block
    uint256 constant X2Y2_721 = 0x18;
    uint256 constant SUDOSWAP = 0x19;
    uint256 constant NFT20 = 0x1a;
    uint256 constant X2Y2_1155 = 0x1b;
    uint256 constant FOUNDATION = 0x1c;
    uint256 constant SWEEP_ERC1155 = 0x1d;
    uint256 constant ELEMENT_MARKET = 0x1e;
    // COMMAND_PLACEHOLDER = 0x1f;

    // The commands are executed in nested if blocks to minimise gas consumption
    // The following constant defines one of the boundaries where the if blocks split commands
    uint256 constant FOURTH_IF_BOUNDARY = 0x20;

    // Command Types where 0x20<=value
    uint256 constant SEAPORT_V1_4 = 0x20;
    uint256 constant EXECUTE_SUB_PLAN = 0x21;
    uint256 constant APPROVE_ERC20 = 0x22;
    // COMMAND_PLACEHOLDER for 0x23 to 0x3f (all unused)
}