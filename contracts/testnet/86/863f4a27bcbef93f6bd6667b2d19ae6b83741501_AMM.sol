// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity >=0.8.0;

/// @notice Simple single owner authorization mixin.
/// @author Solmate (https://github.com/transmissions11/solmate/blob/main/src/auth/Owned.sol)
abstract contract Owned {
    /*//////////////////////////////////////////////////////////////
                                 EVENTS
    //////////////////////////////////////////////////////////////*/

    event OwnerUpdated(address indexed user, address indexed newOwner);

    /*//////////////////////////////////////////////////////////////
                            OWNERSHIP STORAGE
    //////////////////////////////////////////////////////////////*/

    address public owner;

    modifier onlyOwner() virtual {
        require(msg.sender == owner, "UNAUTHORIZED");

        _;
    }

    /*//////////////////////////////////////////////////////////////
                               CONSTRUCTOR
    //////////////////////////////////////////////////////////////*/

    constructor(address _owner) {
        owner = _owner;

        emit OwnerUpdated(address(0), _owner);
    }

    /*//////////////////////////////////////////////////////////////
                             OWNERSHIP LOGIC
    //////////////////////////////////////////////////////////////*/

    function setOwner(address newOwner) public virtual onlyOwner {
        owner = newOwner;

        emit OwnerUpdated(msg.sender, newOwner);
    }
}

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity >=0.8.0;

/// @notice Modern and gas efficient ERC20 + EIP-2612 implementation.
/// @author Solmate (https://github.com/transmissions11/solmate/blob/main/src/tokens/ERC20.sol)
/// @author Modified from Uniswap (https://github.com/Uniswap/uniswap-v2-core/blob/master/contracts/UniswapV2ERC20.sol)
/// @dev Do not manually set balances without updating totalSupply, as the sum of all user balances must not exceed it.
abstract contract ERC20 {
    /*//////////////////////////////////////////////////////////////
                                 EVENTS
    //////////////////////////////////////////////////////////////*/

    event Transfer(address indexed from, address indexed to, uint256 amount);

    event Approval(address indexed owner, address indexed spender, uint256 amount);

    /*//////////////////////////////////////////////////////////////
                            METADATA STORAGE
    //////////////////////////////////////////////////////////////*/

    string public name;

    string public symbol;

    uint8 public immutable decimals;

    /*//////////////////////////////////////////////////////////////
                              ERC20 STORAGE
    //////////////////////////////////////////////////////////////*/

    uint256 public totalSupply;

    mapping(address => uint256) public balanceOf;

    mapping(address => mapping(address => uint256)) public allowance;

    /*//////////////////////////////////////////////////////////////
                            EIP-2612 STORAGE
    //////////////////////////////////////////////////////////////*/

    uint256 internal immutable INITIAL_CHAIN_ID;

    bytes32 internal immutable INITIAL_DOMAIN_SEPARATOR;

    mapping(address => uint256) public nonces;

    /*//////////////////////////////////////////////////////////////
                               CONSTRUCTOR
    //////////////////////////////////////////////////////////////*/

    constructor(
        string memory _name,
        string memory _symbol,
        uint8 _decimals
    ) {
        name = _name;
        symbol = _symbol;
        decimals = _decimals;

        INITIAL_CHAIN_ID = block.chainid;
        INITIAL_DOMAIN_SEPARATOR = computeDomainSeparator();
    }

    /*//////////////////////////////////////////////////////////////
                               ERC20 LOGIC
    //////////////////////////////////////////////////////////////*/

    function approve(address spender, uint256 amount) public virtual returns (bool) {
        allowance[msg.sender][spender] = amount;

        emit Approval(msg.sender, spender, amount);

        return true;
    }

    function transfer(address to, uint256 amount) public virtual returns (bool) {
        balanceOf[msg.sender] -= amount;

        // Cannot overflow because the sum of all user
        // balances can't exceed the max uint256 value.
        unchecked {
            balanceOf[to] += amount;
        }

        emit Transfer(msg.sender, to, amount);

        return true;
    }

    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) public virtual returns (bool) {
        uint256 allowed = allowance[from][msg.sender]; // Saves gas for limited approvals.

        if (allowed != type(uint256).max) allowance[from][msg.sender] = allowed - amount;

        balanceOf[from] -= amount;

        // Cannot overflow because the sum of all user
        // balances can't exceed the max uint256 value.
        unchecked {
            balanceOf[to] += amount;
        }

        emit Transfer(from, to, amount);

        return true;
    }

    /*//////////////////////////////////////////////////////////////
                             EIP-2612 LOGIC
    //////////////////////////////////////////////////////////////*/

    function permit(
        address owner,
        address spender,
        uint256 value,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) public virtual {
        require(deadline >= block.timestamp, "PERMIT_DEADLINE_EXPIRED");

        // Unchecked because the only math done is incrementing
        // the owner's nonce which cannot realistically overflow.
        unchecked {
            address recoveredAddress = ecrecover(
                keccak256(
                    abi.encodePacked(
                        "\x19\x01",
                        DOMAIN_SEPARATOR(),
                        keccak256(
                            abi.encode(
                                keccak256(
                                    "Permit(address owner,address spender,uint256 value,uint256 nonce,uint256 deadline)"
                                ),
                                owner,
                                spender,
                                value,
                                nonces[owner]++,
                                deadline
                            )
                        )
                    )
                ),
                v,
                r,
                s
            );

            require(recoveredAddress != address(0) && recoveredAddress == owner, "INVALID_SIGNER");

            allowance[recoveredAddress][spender] = value;
        }

        emit Approval(owner, spender, value);
    }

    function DOMAIN_SEPARATOR() public view virtual returns (bytes32) {
        return block.chainid == INITIAL_CHAIN_ID ? INITIAL_DOMAIN_SEPARATOR : computeDomainSeparator();
    }

    function computeDomainSeparator() internal view virtual returns (bytes32) {
        return
            keccak256(
                abi.encode(
                    keccak256("EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)"),
                    keccak256(bytes(name)),
                    keccak256("1"),
                    block.chainid,
                    address(this)
                )
            );
    }

    /*//////////////////////////////////////////////////////////////
                        INTERNAL MINT/BURN LOGIC
    //////////////////////////////////////////////////////////////*/

    function _mint(address to, uint256 amount) internal virtual {
        totalSupply += amount;

        // Cannot overflow because the sum of all user
        // balances can't exceed the max uint256 value.
        unchecked {
            balanceOf[to] += amount;
        }

        emit Transfer(address(0), to, amount);
    }

    function _burn(address from, uint256 amount) internal virtual {
        balanceOf[from] -= amount;

        // Cannot underflow because a user's balance
        // will never be larger than the total supply.
        unchecked {
            totalSupply -= amount;
        }

        emit Transfer(from, address(0), amount);
    }
}

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity >=0.8.0;

/// @notice Gas optimized reentrancy protection for smart contracts.
/// @author Solmate (https://github.com/transmissions11/solmate/blob/main/src/utils/ReentrancyGuard.sol)
/// @author Modified from OpenZeppelin (https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/security/ReentrancyGuard.sol)
abstract contract ReentrancyGuard {
    uint256 private locked = 1;

    modifier nonReentrant() virtual {
        require(locked == 1, "REENTRANCY");

        locked = 2;

        _;

        locked = 1;
    }
}

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity ^0.8.15;

import {ERC20} from "solmate/tokens/ERC20.sol";
import {ReentrancyGuard} from "solmate/utils/ReentrancyGuard.sol";
import "../interfaces/ILayerZeroReceiver.sol";
import "../interfaces/ILayerZeroEndpoint.sol";
import "./interfaces/IStargateRouter.sol";
import {Voucher} from "./Voucher.sol";
import "../Message.sol";

contract AMM is Message, ReentrancyGuard {

    ILayerZeroEndpoint public lzEndpoint;
    IStargateRouter public stargateRouter;
    address public L1Target;

    ///@notice The bridged token A.
    ERC20 public token0;
    address public L1Token0;
    Voucher public voucher0;

    ///@notice The bridged token B.
    ERC20 public token1;
    address public L1Token1;
    Voucher public voucher1;

    uint256 public reserve0; // initially should be set with the L1 data
    uint256 public reserve1; // initially should be set with the L1 data
    uint256 public balance0;
    uint256 public balance1;
    uint256 public fees0;
    uint256 public fees1;


    constructor(
        address _token0,
        address _L1Token0,
        address _token1,
        address _L1Token1,
        address _lzEndpoint,
        address _stargateRouter,
        address _L1Target
    ) {
        lzEndpoint = ILayerZeroEndpoint(_lzEndpoint);
        stargateRouter = IStargateRouter(_stargateRouter);
        L1Target = _L1Target;
        
        token0 = ERC20(_token0);
        L1Token0 = _L1Token0;
        token1 = ERC20(_token1);
        L1Token1 = _L1Token1;

        voucher0 = new Voucher(string.concat("v", token0.name()), string.concat("v", token0.symbol()), token0.decimals());
        voucher1 = new Voucher(string.concat("v", token1.name()), string.concat("v", token1.symbol()), token1.decimals());
    }

    function setReserves(uint256 _reserve0, uint256 _reserve1) external {
        reserve0 = _reserve0;
        reserve1 = _reserve1;
    }

    /// @notice Swaps token A/B for token B/A.
    /// @param amount0In The amount of token A to swap.
    /// @param amount1In The amount of token B to swap.
    /// @return amountOut The amount of the token we swap out.
    function swap(uint256 amount0In, uint256 amount1In) nonReentrant external returns (uint256 amountOut) {
        require(amount0In > 0 || amount1In > 0, "Amounts are 0");
        (
            ERC20 tokenIn,
            Voucher voucherOut,
            uint256 amountIn,
            uint256 reserveIn,
            uint256 reserveOut
        ) = amount0In > 0 ? (token0, voucher1, amount0In, reserve0, reserve1) : (token1, voucher0, amount1In, reserve1, reserve0);
        tokenIn.transferFrom(msg.sender, address(this), amountIn);
        uint fees = amountIn / 100; // 1%
        amountIn -= fees;
        amountOut = (amountIn * reserveOut) / (reserveIn + amountIn);
        

        // update reserves
        if (amount0In > 0) {
            fees0 += fees;
            balance0 += amountIn;
            reserve0 += amount0In;
            reserve1 -= amountOut;
        } else {
            fees1 += fees;
            reserve0 -= amountOut;
            reserve1 += amount1In;
            balance1 += amountIn;
        }
        voucherOut.mint(msg.sender, amountOut);
    }


    function syncToL1(
        uint16 destChainId,
        uint256 srcPoolId0,
        uint256 dstPoolId0,
        uint256 srcPoolId1,
        uint256 dstPoolId1
    ) external payable {
        // swap token0
        bytes memory payload = abi.encode(
            voucher0.totalSupply(),
            balance0
        );
        token0.approve(address(stargateRouter), balance0 + fees0);
        stargateRouter.swap{value : msg.value / 2}(
            destChainId,
            srcPoolId0,
            dstPoolId0,
            payable(msg.sender),
            balance0 + fees0,
            0,
            IStargateRouter.lzTxObj(10**6, 0, "0x"),
            abi.encodePacked(L1Target),
            payload
        );
        fees0 = 0;
        balance0 = 0;
        // swap token1
        payload = abi.encode(
            voucher1.totalSupply(),
            balance1
        );
        token1.approve(address(stargateRouter), balance1 + fees1);
        stargateRouter.swap{value : msg.value / 2}(
            destChainId,
            srcPoolId1,
            dstPoolId1,
            payable(msg.sender),
            balance1 + fees1,
            0,
            IStargateRouter.lzTxObj(10**6, 0, "0x"),
            abi.encodePacked(L1Target),
            payload
        );
        fees1 = 0;
        balance1 = 0;
    }

    function burnVouchers(uint16 destChainId, uint256 amount0, uint256 amount1) nonReentrant external payable {
        uint256 fee = amount0 > 0 && amount1 > 0 ? msg.value / 2 : msg.value;
        // tell L1 that vouchers been burned
        bytes memory remoteAndLocalAddresses = abi.encodePacked(L1Target, address(this));
        if (amount0 > 0) {
            voucher0.burn(msg.sender, amount0);
            bytes memory payload = abi.encode(
                MessageType.BurnVoucher,
                L1Token0,
                msg.sender,
                amount0
            );
            lzEndpoint.send{value:fee}(
                destChainId,                        // destination LayerZero chainId
                remoteAndLocalAddresses,    // send to this address on the destination          
                payload,                    // bytes payload
                payable(msg.sender),        // refund address
                address(0x0),               // future parameter
                bytes("")                   // adapterParams (see "Advanced Features")
            );
        }
        if (amount1 > 0) {
            voucher1.burn(msg.sender, amount1);
            bytes memory payload = abi.encode(
                MessageType.BurnVoucher,
                L1Token1,
                msg.sender,
                amount1
            );
            lzEndpoint.send{value:fee}(
                destChainId,                        // destination LayerZero chainId
                remoteAndLocalAddresses,    // send to this address on the destination          
                payload,                    // bytes payload
                payable(msg.sender),        // refund address
                address(0x0),               // future parameter
                bytes("")                   // adapterParams (see "Advanced Features")
            );
        }
    }


    function estimateFeeForSingleVoucherBurn(uint16 destChainId) external view returns (uint256 fee) {
        (,bytes memory payload) = this.getVoucherBurnPayload(true, msg.sender, 1);
        (fee,) = lzEndpoint.estimateFees(
            destChainId,
            address(this),
            payload,
            false,
            bytes("")
            );
    }

    function getVoucherBurnPayload(
        bool isVoucher0,
        address user,
        uint256 amount
    ) external view returns (bytes memory remoteAndLocalAddresses, bytes memory payload) {
        remoteAndLocalAddresses = abi.encodePacked(L1Target, address(this));
        if (isVoucher0) {
            payload = abi.encode(
                MessageType.BurnVoucher,
                L1Token0,
                user,
                amount
            );
        } else {
            payload = abi.encode(
                MessageType.BurnVoucher,
                L1Token1,
                user,
                amount
            );
        }
    }
}

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity ^0.8.15;

import {ERC20} from "solmate/tokens/ERC20.sol";
import {Owned} from "solmate/auth/Owned.sol";

/// @notice A voucher ERC20.
contract Voucher is ERC20, Owned {

    constructor(
        string memory _name,
        string memory _symbol,
        uint8 _decimals
    )
    ERC20(_name, _symbol, _decimals)
    Owned(msg.sender)
    {
    }

    function mint(address to, uint256 amount) public onlyOwner {
        _mint(to, amount);
    }

    function burn(address from, uint256 amount) public onlyOwner {
        _burn(from, amount);
    }

    

}

// SPDX-License-Identifier: BUSL-1.1

pragma solidity >=0.7.6;
pragma abicoder v2;

interface IStargateRouter {
    struct lzTxObj {
        uint256 dstGasForCall;
        uint256 dstNativeAmount;
        bytes dstNativeAddr;
    }

    function addLiquidity(
        uint256 _poolId,
        uint256 _amountLD,
        address _to
    ) external;

    function swap(
        uint16 _dstChainId,
        uint256 _srcPoolId,
        uint256 _dstPoolId,
        address payable _refundAddress,
        uint256 _amountLD,
        uint256 _minAmountLD,
        lzTxObj memory _lzTxParams,
        bytes calldata _to,
        bytes calldata _payload
    ) external payable;

    function redeemRemote(
        uint16 _dstChainId,
        uint256 _srcPoolId,
        uint256 _dstPoolId,
        address payable _refundAddress,
        uint256 _amountLP,
        uint256 _minAmountLD,
        bytes calldata _to,
        lzTxObj memory _lzTxParams
    ) external payable;

    function instantRedeemLocal(
        uint16 _srcPoolId,
        uint256 _amountLP,
        address _to
    ) external returns (uint256);

    function redeemLocal(
        uint16 _dstChainId,
        uint256 _srcPoolId,
        uint256 _dstPoolId,
        address payable _refundAddress,
        uint256 _amountLP,
        bytes calldata _to,
        lzTxObj memory _lzTxParams
    ) external payable;

    function sendCredits(
        uint16 _dstChainId,
        uint256 _srcPoolId,
        uint256 _dstPoolId,
        address payable _refundAddress
    ) external payable;

    function quoteLayerZeroFee(
        uint16 _dstChainId,
        uint8 _functionType,
        bytes calldata _toAddress,
        bytes calldata _transferAndCallPayload,
        lzTxObj memory _lzTxParams
    ) external view returns (uint256, uint256);
}

pragma solidity ^0.8.15;

abstract contract Message {
    enum MessageType {
        BurnVoucher
    }
}

// SPDX-License-Identifier: BUSL-1.1

pragma solidity >=0.5.0;

interface ILayerZeroEndpoint {
    // @notice send a LayerZero message to the specified address at a LayerZero endpoint.
    // @param _dstChainId - the destination chain identifier
    // @param _destination - the address on destination chain (in bytes). address length/format may vary by chains
    // @param _payload - a custom bytes payload to send to the destination contract
    // @param _refundAddress - if the source transaction is cheaper than the amount of value passed, refund the additional amount to this address
    // @param _zroPaymentAddress - the address of the ZRO token holder who would pay for the transaction
    // @param _adapterParams - parameters for custom functionality. e.g. receive airdropped native gas from the relayer on destination
    function send(uint16 _dstChainId, bytes calldata _destination, bytes calldata _payload, address payable _refundAddress, address _zroPaymentAddress, bytes calldata _adapterParams) external payable;

    // @notice used by the messaging library to publish verified payload
    // @param _srcChainId - the source chain identifier
    // @param _srcAddress - the source contract (as bytes) at the source chain
    // @param _dstAddress - the address on destination chain
    // @param _nonce - the unbound message ordering nonce
    // @param _gasLimit - the gas limit for external contract execution
    // @param _payload - verified payload to send to the destination contract
    function receivePayload(uint16 _srcChainId, bytes calldata _srcAddress, address _dstAddress, uint64 _nonce, uint _gasLimit, bytes calldata _payload) external;

    // @notice get the inboundNonce of a receiver from a source chain which could be EVM or non-EVM chain
    // @param _srcChainId - the source chain identifier
    // @param _srcAddress - the source chain contract address
    function getInboundNonce(uint16 _srcChainId, bytes calldata _srcAddress) external view returns (uint64);

    // @notice get the outboundNonce from this source chain which, consequently, is always an EVM
    // @param _srcAddress - the source chain contract address
    function getOutboundNonce(uint16 _dstChainId, address _srcAddress) external view returns (uint64);

    // @notice gets a quote in source native gas, for the amount that send() requires to pay for message delivery
    // @param _dstChainId - the destination chain identifier
    // @param _userApplication - the user app address on this EVM chain
    // @param _payload - the custom message to send over LayerZero
    // @param _payInZRO - if false, user app pays the protocol fee in native token
    // @param _adapterParam - parameters for the adapter service, e.g. send some dust native token to dstChain
    function estimateFees(uint16 _dstChainId, address _userApplication, bytes calldata _payload, bool _payInZRO, bytes calldata _adapterParam) external view returns (uint nativeFee, uint zroFee);

    // @notice get this Endpoint's immutable source identifier
    function getChainId() external view returns (uint16);

    // @notice the interface to retry failed message on this Endpoint destination
    // @param _srcChainId - the source chain identifier
    // @param _srcAddress - the source chain contract address
    // @param _payload - the payload to be retried
    function retryPayload(uint16 _srcChainId, bytes calldata _srcAddress, bytes calldata _payload) external;

    // @notice query if any STORED payload (message blocking) at the endpoint.
    // @param _srcChainId - the source chain identifier
    // @param _srcAddress - the source chain contract address
    function hasStoredPayload(uint16 _srcChainId, bytes calldata _srcAddress) external view returns (bool);

    // @notice query if the _libraryAddress is valid for sending msgs.
    // @param _userApplication - the user app address on this EVM chain
    function getSendLibraryAddress(address _userApplication) external view returns (address);

    // @notice query if the _libraryAddress is valid for receiving msgs.
    // @param _userApplication - the user app address on this EVM chain
    function getReceiveLibraryAddress(address _userApplication) external view returns (address);

    // @notice query if the non-reentrancy guard for send() is on
    // @return true if the guard is on. false otherwise
    function isSendingPayload() external view returns (bool);

    // @notice query if the non-reentrancy guard for receive() is on
    // @return true if the guard is on. false otherwise
    function isReceivingPayload() external view returns (bool);

    // @notice get the configuration of the LayerZero messaging library of the specified version
    // @param _version - messaging library version
    // @param _chainId - the chainId for the pending config change
    // @param _userApplication - the contract address of the user application
    // @param _configType - type of configuration. every messaging library has its own convention.
    function getConfig(uint16 _version, uint16 _chainId, address _userApplication, uint _configType) external view returns (bytes memory);

    // @notice get the send() LayerZero messaging library version
    // @param _userApplication - the contract address of the user application
    function getSendVersion(address _userApplication) external view returns (uint16);

    // @notice get the lzReceive() LayerZero messaging library version
    // @param _userApplication - the contract address of the user application
    function getReceiveVersion(address _userApplication) external view returns (uint16);
}

pragma solidity >=0.5.0;

interface ILayerZeroReceiver {
    /// @notice LayerZero endpoint will invoke this function to deliver the message on the destination
    /// @param _srcChainId - the source endpoint identifier
    /// @param _srcAddress - the source sending contract address from the source chain
    /// @param _nonce - the ordered message nonce
    /// @param _payload - the signed payload is the UA bytes has encoded to be sent
    function lzReceive(uint16 _srcChainId, bytes calldata _srcAddress, uint64 _nonce, bytes calldata _payload) external;
}