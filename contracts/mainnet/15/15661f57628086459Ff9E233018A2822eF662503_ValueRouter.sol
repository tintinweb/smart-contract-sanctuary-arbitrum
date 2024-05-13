/**
 *Submitted for verification at Arbiscan.io on 2024-05-10
*/

/**
 *Submitted for verification at polygonscan.com on 2024-05-09
*/

// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

interface IERC20 {
    event Transfer(address indexed from, address indexed to, uint256 value);

    event Approval(
        address indexed owner,
        address indexed spender,
        uint256 value
    );

    function totalSupply() external view returns (uint256);

    function balanceOf(address account) external view returns (uint256);

    function transfer(address to, uint256 amount) external returns (bool);

    function allowance(address owner, address spender)
        external
        view
        returns (uint256);

    function approve(address spender, uint256 amount) external returns (bool);

    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) external returns (bool);
}

interface IMessageTransmitter {
    function sendMessageWithCaller(
        uint32 destinationDomain,
        bytes32 recipient,
        bytes32 destinationCaller,
        bytes calldata messageBody
    ) external returns (uint64);

    function receiveMessage(bytes calldata message, bytes calldata attestation)
        external
        returns (bool success);

    function replaceMessage(
        bytes calldata originalMessage,
        bytes calldata originalAttestation,
        bytes calldata newMessageBody,
        bytes32 newDestinationCaller
    ) external;

    function usedNonces(bytes32) external view returns (uint256);

    function localDomain() external view returns (uint32);
}

interface ITokenMessenger {
    function depositForBurnWithCaller(
        uint256 _amount,
        uint32 _destinationDomain,
        bytes32 _mintRecipient,
        address _burnToken,
        bytes32 destinationCaller
    ) external returns (uint64 _nonce);
}

library Bytes {
    function addressToBytes32(address addr) external pure returns (bytes32) {
        return bytes32(uint256(uint160(addr)));
    }

    function bytes32ToAddress(bytes32 _buf) public pure returns (address) {
        return address(uint160(uint256(_buf)));
    }

    function slice(
        bytes memory _bytes,
        uint256 _start,
        uint256 _length
    ) internal pure returns (bytes memory) {
        require(_length + 31 >= _length, "slice_overflow");
        require(_bytes.length >= _start + _length, "slice_outOfBounds");

        bytes memory tempBytes;

        assembly {
            switch iszero(_length)
            case 0 {
                tempBytes := mload(0x40)

                let lengthmod := and(_length, 31)

                let mc := add(
                    add(tempBytes, lengthmod),
                    mul(0x20, iszero(lengthmod))
                )
                let end := add(mc, _length)

                for {
                    let cc := add(
                        add(
                            add(_bytes, lengthmod),
                            mul(0x20, iszero(lengthmod))
                        ),
                        _start
                    )
                } lt(mc, end) {
                    mc := add(mc, 0x20)
                    cc := add(cc, 0x20)
                } {
                    mstore(mc, mload(cc))
                }

                mstore(tempBytes, _length)

                mstore(0x40, and(add(mc, 31), not(31)))
            }
            default {
                tempBytes := mload(0x40)
                mstore(tempBytes, 0)

                mstore(0x40, add(tempBytes, 0x20))
            }
        }

        return tempBytes;
    }
}

library CCTPMessage {
    using TypedMemView for bytes;
    using TypedMemView for bytes29;
    using Bytes for bytes;
    uint8 public constant SOURCE_DOMAIN_INDEX = 4;
    uint8 public constant SENDER_INDEX = 20;
    uint8 public constant DESTINATION_CALLER_INDEX = 84;
    uint8 public constant MESSAGE_BODY_INDEX = 116;

    function _sourceDomain(bytes29 _messageRef) private pure returns (uint32) {
        return uint32(_messageRef.indexUint(SOURCE_DOMAIN_INDEX, 4));
    }

    function sourceDomain(bytes memory _message) public pure returns (uint32) {
        return _sourceDomain(_message.ref(0));
    }

    function _sender(bytes29 _messageRef) private pure returns (bytes32) {
        return _messageRef.index(SENDER_INDEX, 32);
    }

    function sender(bytes memory _message) public pure returns (bytes32) {
        return _sender(_message.ref(0));
    }

    function _destinationCaller(bytes29 _message)
        private
        pure
        returns (bytes32)
    {
        return _message.index(DESTINATION_CALLER_INDEX, 32);
    }

    function destinationCaller(bytes memory _message)
        public
        pure
        returns (bytes32)
    {
        return _destinationCaller(_message.ref(0));
    }

    function body(bytes memory message) public pure returns (bytes memory) {
        return
            message.slice(
                MESSAGE_BODY_INDEX,
                message.length - MESSAGE_BODY_INDEX
            );
    }
}

struct SwapMessage {
    uint32 version;
    bytes32 bridgeNonceHash;
    uint256 sellAmount;
    bytes32 buyToken;
    uint256 guaranteedBuyAmount;
    bytes32 recipient;
}

library SwapMessageCodec {
    using Bytes for *;

    uint8 public constant VERSION_END_INDEX = 4;
    uint8 public constant BRIDGENONCEHASH_END_INDEX = 36;
    uint8 public constant SELLAMOUNT_END_INDEX = 68;
    uint8 public constant BUYTOKEN_END_INDEX = 100;
    uint8 public constant BUYAMOUNT_END_INDEX = 132;
    uint8 public constant RECIPIENT_END_INDEX = 164;

    function encode(SwapMessage memory swapMessage)
        public
        pure
        returns (bytes memory)
    {
        return
            abi.encodePacked(
                swapMessage.version,
                swapMessage.bridgeNonceHash,
                swapMessage.sellAmount,
                swapMessage.buyToken,
                swapMessage.guaranteedBuyAmount,
                swapMessage.recipient
            );
    }

    function decode(bytes memory message)
        public
        pure
        returns (SwapMessage memory)
    {
        uint32 version;
        bytes32 bridgeNonceHash;
        uint256 sellAmount;
        bytes32 buyToken;
        uint256 guaranteedBuyAmount;
        bytes32 recipient;
        assembly {
            version := mload(add(message, VERSION_END_INDEX))
            bridgeNonceHash := mload(add(message, BRIDGENONCEHASH_END_INDEX))
            sellAmount := mload(add(message, SELLAMOUNT_END_INDEX))
            buyToken := mload(add(message, BUYTOKEN_END_INDEX))
            guaranteedBuyAmount := mload(add(message, BUYAMOUNT_END_INDEX))
            recipient := mload(add(message, RECIPIENT_END_INDEX))
        }

        return
            SwapMessage(
                version,
                bridgeNonceHash,
                sellAmount,
                buyToken,
                guaranteedBuyAmount,
                recipient
            );
    }

    /*
    function testEncode() public pure returns (bytes memory) {
        return
            encode(
                SwapMessage(
                    3,
                    0xaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa,
                    1000,
                    0xbBbBBBBbbBBBbbbBbbBbbbbBBbBbbbbBbBbbBBbB
                        .addressToBytes32(),
                    2000,
                    0xCcCCccccCCCCcCCCCCCcCcCccCcCCCcCcccccccC
                        .addressToBytes32(),
                )
            );
        //hex
        //00000003
        //aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa
        //00000000000000000000000000000000000000000000000000000000000003e8
        //000000000000000000000000bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb
        //00000000000000000000000000000000000000000000000000000000000007d0
        //000000000000000000000000cccccccccccccccccccccccccccccccccccccccc
    }

    function testDecode() public pure returns (SwapMessage memory) {
        return
            decode(
                hex"00000003aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa00000000000000000000000000000000000000000000000000000000000003e8000000000000000000000000bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb00000000000000000000000000000000000000000000000000000000000007d0000000000000000000000000cccccccccccccccccccccccccccccccccccccccc
            );
    }

    function testMessageCodec() public pure returns (bool) {
        bytes
            memory message = hex"00000003aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa00000000000000000000000000000000000000000000000000000000000003e8000000000000000000000000bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb00000000000000000000000000000000000000000000000000000000000007d0000000000000000000000000cccccccccccccccccccccccccccccccccccccccc";
        SwapMessage memory args = decode(message);
        bytes memory encoded = encode(args);
        require(keccak256(message) == keccak256(encoded));
        return true;
    }
*/
}

library TypedMemView {
    // The null view
    bytes29 public constant NULL =
        hex"ffffffffffffffffffffffffffffffffffffffffffffffffffffffffff";
    // Mask a low uint96
    uint256 constant LOW_12_MASK = 0xffffffffffffffffffffffff;
    // Shift constants
    uint8 constant SHIFT_TO_LEN = 24;
    uint8 constant SHIFT_TO_LOC = 96 + 24;
    uint8 constant SHIFT_TO_TYPE = 96 + 96 + 24;
    // For nibble encoding
    bytes private constant NIBBLE_LOOKUP = "0123456789abcdef";

    /**
     * @notice Returns the encoded hex character that represents the lower 4 bits of the argument.
     * @param _byte The byte
     * @return _char The encoded hex character
     */
    function nibbleHex(uint8 _byte) internal pure returns (uint8 _char) {
        uint8 _nibble = _byte & 0x0f; // keep bottom 4, 0 top 4
        _char = uint8(NIBBLE_LOOKUP[_nibble]);
    }

    /**
     * @notice      Returns a uint16 containing the hex-encoded byte.
     * @param _b    The byte
     * @return      encoded - The hex-encoded byte
     */
    function byteHex(uint8 _b) internal pure returns (uint16 encoded) {
        encoded |= nibbleHex(_b >> 4); // top 4 bits
        encoded <<= 8;
        encoded |= nibbleHex(_b); // lower 4 bits
    }

    /**
     * @notice      Encodes the uint256 to hex. `first` contains the encoded top 16 bytes.
     *              `second` contains the encoded lower 16 bytes.
     *
     * @param _b    The 32 bytes as uint256
     * @return      first - The top 16 bytes
     * @return      second - The bottom 16 bytes
     */
    function encodeHex(uint256 _b)
        internal
        pure
        returns (uint256 first, uint256 second)
    {
        for (uint8 i = 31; i > 15; i -= 1) {
            uint8 _byte = uint8(_b >> (i * 8));
            first |= byteHex(_byte);
            if (i != 16) {
                first <<= 16;
            }
        }

        // abusing underflow here =_=
        for (uint8 i = 15; i < 255; i -= 1) {
            uint8 _byte = uint8(_b >> (i * 8));
            second |= byteHex(_byte);
            if (i != 0) {
                second <<= 16;
            }
        }
    }

    /**
     * @notice      Create a mask with the highest `_len` bits set.
     * @param _len  The length
     * @return      mask - The mask
     */
    function leftMask(uint8 _len) private pure returns (uint256 mask) {
        // ugly. redo without assembly?
        assembly {
            // solium-disable-previous-line security/no-inline-assembly
            mask := sar(
                sub(_len, 1),
                0x8000000000000000000000000000000000000000000000000000000000000000
            )
        }
    }

    /**
     * @notice          Unsafe raw pointer construction. This should generally not be called
     *                  directly. Prefer `ref` wherever possible.
     * @dev             Unsafe raw pointer construction. This should generally not be called
     *                  directly. Prefer `ref` wherever possible.
     * @param _type     The type
     * @param _loc      The memory address
     * @param _len      The length
     * @return          newView - The new view with the specified type, location and length
     */
    function unsafeBuildUnchecked(
        uint256 _type,
        uint256 _loc,
        uint256 _len
    ) private pure returns (bytes29 newView) {
        uint256 _uint96Bits = 96;
        uint256 _emptyBits = 24;
        assembly {
            // solium-disable-previous-line security/no-inline-assembly
            newView := shl(_uint96Bits, or(newView, _type)) // insert type
            newView := shl(_uint96Bits, or(newView, _loc)) // insert loc
            newView := shl(_emptyBits, or(newView, _len)) // empty bottom 3 bytes
        }
    }

    /**
     * @notice          Instantiate a new memory view. This should generally not be called
     *                  directly. Prefer `ref` wherever possible.
     * @dev             Instantiate a new memory view. This should generally not be called
     *                  directly. Prefer `ref` wherever possible.
     * @param _type     The type
     * @param _loc      The memory address
     * @param _len      The length
     * @return          newView - The new view with the specified type, location and length
     */
    function build(
        uint256 _type,
        uint256 _loc,
        uint256 _len
    ) internal pure returns (bytes29 newView) {
        uint256 _end = _loc + _len;
        assembly {
            // solium-disable-previous-line security/no-inline-assembly
            if gt(_end, mload(0x40)) {
                _end := 0
            }
        }
        if (_end == 0) {
            return NULL;
        }
        newView = unsafeBuildUnchecked(_type, _loc, _len);
    }

    /**
     * @notice          Instantiate a memory view from a byte array.
     * @dev             Note that due to Solidity memory representation, it is not possible to
     *                  implement a deref, as the `bytes` type stores its len in memory.
     * @param arr       The byte array
     * @param newType   The type
     * @return          bytes29 - The memory view
     */
    function ref(bytes memory arr, uint40 newType)
        internal
        pure
        returns (bytes29)
    {
        uint256 _len = arr.length;

        uint256 _loc;
        assembly {
            // solium-disable-previous-line security/no-inline-assembly
            _loc := add(arr, 0x20) // our view is of the data, not the struct
        }

        return build(newType, _loc, _len);
    }

    /**
     * @notice          Return the memory address of the underlying bytes.
     * @param memView   The view
     * @return          _loc - The memory address
     */
    function loc(bytes29 memView) internal pure returns (uint96 _loc) {
        uint256 _mask = LOW_12_MASK; // assembly can't use globals
        uint256 _shift = SHIFT_TO_LOC;
        assembly {
            // solium-disable-previous-line security/no-inline-assembly
            _loc := and(shr(_shift, memView), _mask)
        }
    }

    /**
     * @notice          The number of bytes of the view.
     * @param memView   The view
     * @return          _len - The length of the view
     */
    function len(bytes29 memView) internal pure returns (uint96 _len) {
        uint256 _mask = LOW_12_MASK; // assembly can't use globals
        uint256 _emptyBits = 24;
        assembly {
            // solium-disable-previous-line security/no-inline-assembly
            _len := and(shr(_emptyBits, memView), _mask)
        }
    }

    /**
     * @notice          Construct an error message for an indexing overrun.
     * @param _loc      The memory address
     * @param _len      The length
     * @param _index    The index
     * @param _slice    The slice where the overrun occurred
     * @return          err - The err
     */
    function indexErrOverrun(
        uint256 _loc,
        uint256 _len,
        uint256 _index,
        uint256 _slice
    ) internal pure returns (string memory err) {
        (, uint256 a) = encodeHex(_loc);
        (, uint256 b) = encodeHex(_len);
        (, uint256 c) = encodeHex(_index);
        (, uint256 d) = encodeHex(_slice);
        err = string(
            abi.encodePacked(
                "TypedMemView/index - Overran the view. Slice is at 0x",
                uint48(a),
                " with length 0x",
                uint48(b),
                ". Attempted to index at offset 0x",
                uint48(c),
                " with length 0x",
                uint48(d),
                "."
            )
        );
    }

    /**
     * @notice          Load up to 32 bytes from the view onto the stack.
     * @dev             Returns a bytes32 with only the `_bytes` highest bytes set.
     *                  This can be immediately cast to a smaller fixed-length byte array.
     *                  To automatically cast to an integer, use `indexUint`.
     * @param memView   The view
     * @param _index    The index
     * @param _bytes    The bytes
     * @return          result - The 32 byte result
     */
    function index(
        bytes29 memView,
        uint256 _index,
        uint8 _bytes
    ) internal pure returns (bytes32 result) {
        if (_bytes == 0) {
            return bytes32(0);
        }
        if (_index + _bytes > len(memView)) {
            revert(
                indexErrOverrun(
                    loc(memView),
                    len(memView),
                    _index,
                    uint256(_bytes)
                )
            );
        }
        require(
            _bytes <= 32,
            "TypedMemView/index - Attempted to index more than 32 bytes"
        );

        uint8 bitLength;
        unchecked {
            bitLength = _bytes * 8;
        }
        uint256 _loc = loc(memView);
        uint256 _mask = leftMask(bitLength);
        assembly {
            // solium-disable-previous-line security/no-inline-assembly
            result := and(mload(add(_loc, _index)), _mask)
        }
    }

    /**
     * @notice          Parse an unsigned integer from the view at `_index`.
     * @dev             Requires that the view have >= `_bytes` bytes following that index.
     * @param memView   The view
     * @param _index    The index
     * @param _bytes    The bytes
     * @return          result - The unsigned integer
     */
    function indexUint(
        bytes29 memView,
        uint256 _index,
        uint8 _bytes
    ) internal pure returns (uint256 result) {
        return uint256(index(memView, _index, _bytes)) >> ((32 - _bytes) * 8);
    }
}

abstract contract AdminControl {
    address public admin;
    address public pendingAdmin;

    event ChangeAdmin(address indexed _old, address indexed _new);
    event ApplyAdmin(address indexed _old, address indexed _new);

    constructor(address _admin) {
        require(_admin != address(0), "AdminControl: address(0)");
        admin = _admin;
        emit ChangeAdmin(address(0), _admin);
    }

    modifier onlyAdmin() {
        require(msg.sender == admin, "AdminControl: not admin");
        _;
    }

    function changeAdmin(address _admin) external onlyAdmin {
        require(_admin != address(0), "AdminControl: address(0)");
        pendingAdmin = _admin;
        emit ChangeAdmin(admin, _admin);
    }

    function applyAdmin() external {
        require(msg.sender == pendingAdmin, "AdminControl: Forbidden");
        emit ApplyAdmin(admin, pendingAdmin);
        admin = pendingAdmin;
        pendingAdmin = address(0);
    }
}

struct MessageWithAttestation {
    bytes message;
    bytes attestation;
}

struct SellArgs {
    address sellToken;
    uint256 sellAmount;
    uint256 guaranteedBuyAmount;
    uint256 sellcallgas;
    bytes sellcalldata;
}

struct BuyArgs {
    bytes32 buyToken;
    uint256 guaranteedBuyAmount;
    uint256 buycallgas;
    bytes buycalldata;
}

struct Fee {
    uint256 bridgeFee;
    uint256 swapFee;
}

interface IValueRouter {
    event TakeFee(address to, uint256 amount);

    event SwapAndBridge(
        address sellToken,
        address buyToken,
        uint256 bridgeUSDCAmount,
        uint32 destDomain,
        address recipient,
        uint64 bridgeNonce,
        uint64 swapMessageNonce,
        bytes32 bridgeHash
    );

    event ReplaceSwapMessage(
        address buyToken,
        uint32 destDomain,
        address recipient,
        uint64 swapMessageNonce
    );

    event LocalSwap(
        address msgsender,
        address sellToken,
        uint256 sellAmount,
        address buyToken,
        uint256 boughtAmount
    );

    event BridgeArrive(bytes32 bridgeNonceHash, uint256 amount);

    event DestSwapFailed(bytes32 bridgeNonceHash);

    event DestSwapSuccess(bytes32 bridgeNonceHash);

    function version() external view returns (uint16);

    function fee(uint32 domain) external view returns (uint256, uint256);

    function swap(
        bytes calldata swapcalldata,
        uint256 callgas,
        address sellToken,
        uint256 sellAmount,
        address buyToken,
        uint256 guaranteedBuyAmount,
        address recipient
    ) external payable;

    function swapAndBridge(
        SellArgs calldata sellArgs,
        BuyArgs calldata buyArgs,
        uint32 destDomain,
        bytes32 recipient
    ) external payable returns (uint64, uint64);

    function relay(
        MessageWithAttestation calldata bridgeMessage,
        MessageWithAttestation calldata swapMessage,
        bytes calldata swapdata,
        uint256 callgas
    ) external;
}

contract ValueRouter is AdminControl, IValueRouter {
    using Bytes for *;
    using TypedMemView for bytes;
    using TypedMemView for bytes29;
    using CCTPMessage for *;
    using SwapMessageCodec for *;

    mapping(uint32 => Fee) public fee;

    function setFee(uint32[] calldata domain, Fee[] calldata price)
        public
        onlyAdmin
    {
        for (uint256 i = 0; i < domain.length; i++) {
            fee[domain[i]] = price[i];
        }
    }

    address public immutable usdc;
    IMessageTransmitter public immutable messageTransmitter;
    ITokenMessenger public immutable tokenMessenger;
    address public immutable zeroEx;
    uint16 public immutable version = 1;

    bytes32 public nobleCaller;

    mapping(uint32 => bytes32) public remoteRouter;
    mapping(bytes32 => address) swapHashSender;

    constructor(
        address _usdc,
        address _messageTransmitter,
        address _tokenMessenger,
        address _zeroEx,
        address admin
    ) AdminControl(admin) {
        usdc = _usdc;
        messageTransmitter = IMessageTransmitter(_messageTransmitter);
        tokenMessenger = ITokenMessenger(_tokenMessenger);
        zeroEx = _zeroEx;
    }

    receive() external payable {}

    function setNobleCaller(bytes32 caller) public onlyAdmin {
        nobleCaller = caller;
    }

    function setRemoteRouter(uint32 remoteDomain, address router)
        public
        onlyAdmin
    {
        remoteRouter[remoteDomain] = router.addressToBytes32();
    }

    function setRemoteRouter(
        uint32[] calldata remoteDomains,
        bytes32[] calldata routers
    ) public onlyAdmin {
        for (uint256 i = 0; i < remoteDomains.length; i++) {
            remoteRouter[remoteDomains[i]] = routers[i];
        }
    }

    function takeFee(address to, uint256 amount) public onlyAdmin {
        bool succ = IERC20(usdc).transfer(to, amount);
        require(succ);
        emit TakeFee(to, amount);
    }

    /// @param recipient set recipient to address(0) to save token in the router contract.
    function zeroExSwap(
        bytes memory swapcalldata,
        uint256 callgas,
        address sellToken,
        uint256 sellAmount,
        address buyToken,
        uint256 guaranteedBuyAmount,
        address recipient
    ) public payable returns (uint256 boughtAmount) {
        // before swap
        // approve
        if (sellToken != 0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE) {
            require(
                IERC20(sellToken).approve(zeroEx, sellAmount),
                "erc20 approve failed"
            );
        }
        // check balance 0
        uint256 buyToken_bal_0;
        if (buyToken == 0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE) {
            buyToken_bal_0 = address(this).balance;
        } else {
            buyToken_bal_0 = IERC20(buyToken).balanceOf(address(this));
        }

        _zeroExSwap(swapcalldata, callgas);

        // after swap
        // cancel approval
        if (sellToken != 0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE) {
            // cancel approval
            require(
                IERC20(sellToken).approve(zeroEx, 0),
                "erc20 cancel approval failed"
            );
        }
        // check balance 1
        uint256 buyToken_bal_1;
        if (buyToken == 0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE) {
            buyToken_bal_1 = address(this).balance;
        } else {
            buyToken_bal_1 = IERC20(buyToken).balanceOf(address(this));
        }
        boughtAmount = buyToken_bal_1 - buyToken_bal_0;
        require(boughtAmount >= guaranteedBuyAmount, "swap output not enough");
        // send token to recipient
        if (recipient == address(0)) {
            return boughtAmount;
        }
        if (buyToken == 0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE) {
            (bool succ, ) = recipient.call{value: boughtAmount}("");
            require(succ, "send eth failed");
        } else {
            bool succ = IERC20(buyToken).transfer(recipient, boughtAmount);
            require(succ, "erc20 transfer failed");
        }

        return boughtAmount;
    }

    function _zeroExSwap(bytes memory swapcalldata, uint256 callgas) internal {
        (bool succ, ) = zeroEx.call{value: msg.value, gas: callgas}(
            swapcalldata
        );
        require(succ, "call swap failed");
    }

    function swap(
        bytes calldata swapcalldata,
        uint256 callgas,
        address sellToken,
        uint256 sellAmount,
        address buyToken,
        uint256 guaranteedBuyAmount,
        address recipient
    ) public payable {
        if (sellToken == 0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE) {
            require(msg.value >= sellAmount, "tx value is not enough");
        } else {
            bool succ = IERC20(sellToken).transferFrom(
                msg.sender,
                address(this),
                sellAmount
            );
            require(succ, "erc20 transfer failed");
        }
        uint256 boughtAmount = zeroExSwap(
            swapcalldata,
            callgas,
            sellToken,
            sellAmount,
            buyToken,
            guaranteedBuyAmount,
            recipient
        );
        emit LocalSwap(
            msg.sender,
            sellToken,
            sellAmount,
            buyToken,
            boughtAmount
        );
    }

    function isNoble(uint32 domain) public pure returns (bool) {
        return (domain == 4);
    }

    /// User entrance
    /// @param sellArgs : sell-token arguments
    /// @param buyArgs : buy-token arguments
    /// @param destDomain : destination domain
    /// @param recipient : token receiver on dest domain
    function swapAndBridge(
        SellArgs calldata sellArgs,
        BuyArgs calldata buyArgs,
        uint32 destDomain,
        bytes32 recipient
    ) public payable returns (uint64, uint64) {
        uint256 _fee = fee[destDomain].swapFee;
        if (buyArgs.buyToken == bytes32(0)) {
            _fee = fee[destDomain].bridgeFee;
        }
        require(msg.value >= _fee);
        if (recipient == bytes32(0)) {
            recipient = msg.sender.addressToBytes32();
        }

        // swap sellToken to usdc
        if (sellArgs.sellToken == 0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE) {
            require(msg.value >= sellArgs.sellAmount, "tx value is not enough");
        } else {
            bool succ = IERC20(sellArgs.sellToken).transferFrom(
                msg.sender,
                address(this),
                sellArgs.sellAmount
            );
            require(succ, "erc20 transfer failed");
        }
        uint256 bridgeUSDCAmount;
        if (sellArgs.sellToken == usdc) {
            bridgeUSDCAmount = sellArgs.sellAmount;
        } else {
            bridgeUSDCAmount = zeroExSwap(
                sellArgs.sellcalldata,
                sellArgs.sellcallgas,
                sellArgs.sellToken,
                sellArgs.sellAmount,
                usdc,
                sellArgs.guaranteedBuyAmount,
                address(0)
            );
        }

        // bridge usdc
        require(
            IERC20(usdc).approve(address(tokenMessenger), bridgeUSDCAmount),
            "erc20 approve failed"
        );

        uint64 bridgeNonce;
        if (isNoble(destDomain)) {
            bridgeNonce = tokenMessenger.depositForBurnWithCaller(
                bridgeUSDCAmount,
                destDomain,
                recipient,
                usdc,
                nobleCaller
            );
            emit SwapAndBridge(
                sellArgs.sellToken,
                buyArgs.buyToken.bytes32ToAddress(),
                bridgeUSDCAmount,
                destDomain,
                recipient.bytes32ToAddress(),
                bridgeNonce,
                0,
                bytes32(0)
            );
            return (bridgeNonce, 0);
        }

        bytes32 destRouter = remoteRouter[destDomain];

        bridgeNonce = tokenMessenger.depositForBurnWithCaller(
            bridgeUSDCAmount,
            destDomain,
            destRouter,
            usdc,
            destRouter
        );

        bytes32 bridgeNonceHash = keccak256(
            abi.encodePacked(messageTransmitter.localDomain(), bridgeNonce)
        );

        // send swap message
        SwapMessage memory swapMessage = SwapMessage(
            version,
            bridgeNonceHash,
            bridgeUSDCAmount,
            buyArgs.buyToken,
            buyArgs.guaranteedBuyAmount,
            recipient
        );
        bytes memory messageBody = swapMessage.encode();
        uint64 swapMessageNonce = messageTransmitter.sendMessageWithCaller(
            destDomain,
            destRouter, // remote router will receive this message
            destRouter, // message will only submited through the remote router (handleBridgeAndSwap)
            messageBody
        );
        emit SwapAndBridge(
            sellArgs.sellToken,
            buyArgs.buyToken.bytes32ToAddress(),
            bridgeUSDCAmount,
            destDomain,
            recipient.bytes32ToAddress(),
            bridgeNonce,
            swapMessageNonce,
            bridgeNonceHash
        );
        swapHashSender[
            keccak256(abi.encode(destDomain, swapMessageNonce))
        ] = msg.sender;
        return (bridgeNonce, swapMessageNonce);
    }

    function replaceSwapMessage(
        uint64 bridgeMessageNonce,
        uint64 swapMessageNonce,
        MessageWithAttestation calldata originalMessage,
        uint32 destDomain,
        BuyArgs calldata buyArgs,
        address recipient
    ) public {
        require(
            swapHashSender[
                keccak256(abi.encode(destDomain, swapMessageNonce))
            ] == msg.sender
        );

        bytes32 bridgeNonceHash = keccak256(
            abi.encodePacked(
                messageTransmitter.localDomain(),
                bridgeMessageNonce
            )
        );

        SwapMessage memory swapMessage = SwapMessage(
            version,
            bridgeNonceHash,
            0,
            buyArgs.buyToken,
            buyArgs.guaranteedBuyAmount,
            recipient.addressToBytes32()
        );

        messageTransmitter.replaceMessage(
            originalMessage.message,
            originalMessage.attestation,
            swapMessage.encode(),
            remoteRouter[destDomain]
        );
        emit ReplaceSwapMessage(
            buyArgs.buyToken.bytes32ToAddress(),
            destDomain,
            recipient,
            swapMessageNonce
        );
    }

    /// Relayer entrance
    function relay(
        MessageWithAttestation calldata bridgeMessage,
        MessageWithAttestation calldata swapMessage,
        bytes calldata swapdata,
        uint256 callgas
    ) public {
        uint32 sourceDomain = bridgeMessage.message.sourceDomain();
        require(
            swapMessage.message.sourceDomain() == sourceDomain,
            "inconsistent source domain"
        );
        if (isNoble(sourceDomain)) {
            require(
                swapMessage.message.sender() == swapMessage.message.sender(),
                "inconsistent noble messages sender"
            );
        }
        // 1. decode swap message, get binding bridge message nonce.
        SwapMessage memory swapArgs = swapMessage.message.body().decode();

        // 2. check bridge message nonce is unused.
        // ignore noble messages
        if (!isNoble(sourceDomain)) {
            require(
                messageTransmitter.usedNonces(swapArgs.bridgeNonceHash) == 0,
                "bridge message nonce is already used"
            );
        }

        // 3. verifys bridge message attestation and mint usdc to this contract.
        // reverts when atestation is invalid.
        uint256 usdc_bal_0 = IERC20(usdc).balanceOf(address(this));
        messageTransmitter.receiveMessage(
            bridgeMessage.message,
            bridgeMessage.attestation
        );
        uint256 usdc_bal_1 = IERC20(usdc).balanceOf(address(this));
        require(usdc_bal_1 >= usdc_bal_0, "usdc bridge error");

        // 4. check bridge message nonce is used.
        // ignore noble messages
        if (!isNoble(sourceDomain)) {
            require(
                messageTransmitter.usedNonces(swapArgs.bridgeNonceHash) == 1,
                "bridge message nonce is incorrect"
            );
        }

        // 5. verifys swap message attestation.
        // reverts when atestation is invalid.
        messageTransmitter.receiveMessage(
            swapMessage.message,
            swapMessage.attestation
        );

        address recipient = swapArgs.recipient.bytes32ToAddress();

        emit BridgeArrive(swapArgs.bridgeNonceHash, usdc_bal_1 - usdc_bal_0);

        uint256 bridgeUSDCAmount;
        if (swapArgs.sellAmount == 0) {
            bridgeUSDCAmount = usdc_bal_1 - usdc_bal_0;
        } else {
            bridgeUSDCAmount = swapArgs.sellAmount;
            if (bridgeUSDCAmount < (usdc_bal_1 - usdc_bal_0)) {
                // router did not receive enough usdc
                IERC20(usdc).transfer(recipient, bridgeUSDCAmount);
                return;
            }
        }

        uint256 swapAmount = bridgeUSDCAmount;

        require(swapArgs.version == version, "wrong swap message version");

        if (
            swapArgs.buyToken == bytes32(0) ||
            swapArgs.buyToken == usdc.addressToBytes32()
        ) {
            // receive usdc
            bool succ = IERC20(usdc).transfer(recipient, bridgeUSDCAmount);
            require(succ, "erc20 transfer failed");
        } else {
            try
                this.zeroExSwap(
                    swapdata,
                    callgas,
                    usdc,
                    swapAmount,
                    swapArgs.buyToken.bytes32ToAddress(),
                    swapArgs.guaranteedBuyAmount,
                    recipient
                )
            {} catch {
                IERC20(usdc).transfer(recipient, swapAmount);
                emit DestSwapFailed(swapArgs.bridgeNonceHash);
                return;
            }
            // transfer rem to recipient
            emit DestSwapSuccess(swapArgs.bridgeNonceHash);
        }
    }

    /// @dev Does not handle message.
    /// Returns a boolean to make message transmitter accept or refuse a message.
    function handleReceiveMessage(
        uint32 sourceDomain,
        bytes32 sender,
        bytes calldata messageBody
    ) external returns (bool) {
        require(
            msg.sender == address(messageTransmitter),
            "caller not allowed"
        );
        if (remoteRouter[sourceDomain] == sender || isNoble(sourceDomain)) {
            return true;
        }
        return false;
    }

    function usedNonces(bytes32 nonce) external view returns (uint256) {
        return messageTransmitter.usedNonces(nonce);
    }

    function localDomain() external view returns (uint32) {
        return messageTransmitter.localDomain();
    }
}