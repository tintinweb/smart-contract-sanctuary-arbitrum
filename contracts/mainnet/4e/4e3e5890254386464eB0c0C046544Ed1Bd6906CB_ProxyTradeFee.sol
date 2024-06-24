//SPDX-License-Identifier: Unlicense
pragma solidity 0.8.19;

 
struct OrderCreation {
    /// Address of the ERC-20 token that the maker is offering as part of this order.
    /// Use the zero address to indicate that the maker is offering a native blockchain token (such as Ether, Matic, etc.).
    address giveTokenAddress;
    /// Amount of tokens the maker is offering.
    uint256 giveAmount;
    /// Address of the ERC-20 token that the maker is willing to accept on the destination chain.
    bytes takeTokenAddress;
    /// Amount of tokens the maker is willing to accept on the destination chain.
    uint256 takeAmount;
    // the ID of the chain where an order should be fulfilled.
    uint256 takeChainId;
    /// Address on the destination chain where funds should be sent upon order fulfillment.
    bytes receiverDst;
    /// Address on the source (current) chain authorized to patch the order by adding more input tokens, making it more attractive to takers.
    address givePatchAuthoritySrc;
    /// Address on the destination chain authorized to patch the order by reducing the take amount, making it more attractive to takers,
    /// and can also cancel the order in the take chain.
    bytes orderAuthorityAddressDst;
    // An optional address restricting anyone in the open market from fulfilling
    // this order but the given address. This can be useful if you are creating a order
    // for a specific taker. By default, set to empty bytes array (0x)
    bytes allowedTakerDst;
    /// An optional external call data payload.
    bytes externalCall;
    // An optional address on the source (current) chain where the given input tokens
    // would be transferred to in case order cancellation is initiated by the orderAuthorityAddressDst
    // on the destination chain. This property can be safely set to an empty bytes array (0x):
    // in this case, tokens would be transferred to the arbitrary address specified
    // by the orderAuthorityAddressDst upon order cancellation
    bytes allowedCancelBeneficiarySrc;
}

interface IERC20 {
    /**
     * @dev Emitted when `value` tokens are moved from one account (`from`) to
     * another (`to`).
     *
     * Note that `value` may be zero.
     */
    event Transfer(address indexed from, address indexed to, uint256 value);

    /**
     * @dev Emitted when the allowance of a `spender` for an `owner` is set by
     * a call to {approve}. `value` is the new allowance.
     */
    event Approval(address indexed owner, address indexed spender, uint256 value);

    /**
     * @dev Returns the value of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the value of tokens owned by `account`.
     */
    function balanceOf(address account) external view returns (uint256);

    /**
     * @dev Moves a `value` amount of tokens from the caller's account to `to`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address to, uint256 value) external returns (bool);

    /**
     * @dev Returns the remaining number of tokens that `spender` will be
     * allowed to spend on behalf of `owner` through {transferFrom}. This is
     * zero by default.
     *
     * This value changes when {approve} or {transferFrom} are called.
     */
    function allowance(address owner, address spender) external view returns (uint256);

    /**
     * @dev Sets a `value` amount of tokens as the allowance of `spender` over the
     * caller's tokens.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * IMPORTANT: Beware that changing an allowance with this method brings the risk
     * that someone may use both the old and the new allowance by unfortunate
     * transaction ordering. One possible solution to mitigate this race
     * condition is to first reduce the spender's allowance to 0 and set the
     * desired value afterwards:
     * https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
     *
     * Emits an {Approval} event.
     */
    function approve(address spender, uint256 value) external returns (bool);

    /**
     * @dev Moves a `value` amount of tokens from `from` to `to` using the
     * allowance mechanism. `value` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(address from, address to, uint256 value) external returns (bool);
}

interface IDlnSource {
    /**
     * @notice This function returns the global fixed fee in the native asset of the protocol.
     * @dev This fee is denominated in the native asset (like Ether in Ethereum).
     * @return uint88 This return value represents the global fixed fee in the native asset.
     */
    function globalFixedNativeFee() external view returns (uint88);

    /**
     * @notice This function provides the global transfer fee, expressed in Basis Points (BPS).
     * @dev It retrieves a global fee which is applied to order.giveAmount. The fee is represented in Basis Points (BPS), where 1 BPS equals 0.01%.
     * @return uint16 The return value represents the global transfer fee in BPS.
     */
    function globalTransferFeeBps() external returns (uint16);

    /**
     * @dev Places a new order with pseudo-random orderId onto the DLN
     * @notice deprecated
     * @param _orderCreation a structured parameter from the DlnOrderLib.OrderCreation library, containing all the necessary information required for creating a new order.
     * @param _affiliateFee a bytes parameter specifying the affiliate fee that will be rewarded to the beneficiary. It includes the beneficiary's details and the affiliate amount.
     * @param _referralCode a 32-bit unsigned integer containing the referral code. This code is traced back to the referral source or person that facilitated this order. This code is also emitted in an event for tracking purposes.
     * @param _permitEnvelope a bytes parameter that is used to approve the spender through a signature. It contains the amount, the deadline, and the signature.
     * @return bytes32 identifier (orderId) of a newly placed order
     */
    function createOrder(
        OrderCreation calldata _orderCreation,
        bytes calldata _affiliateFee,
        uint32 _referralCode,
        bytes calldata _permitEnvelope
    ) external payable returns (bytes32);

    /**
     * @dev Places a new order with deterministic orderId onto the DLN
     * @param _orderCreation a structured parameter from the DlnOrderLib.OrderCreation library, containing all the necessary information required for creating a new order.
     * @param _salt an input source of randomness for getting a deterministic identifier of an order (orderId)
     * @param _affiliateFee a bytes parameter specifying the affiliate fee that will be rewarded to the beneficiary. It includes the beneficiary's details and the affiliate amount.
     * @param _referralCode a 32-bit unsigned integer containing the referral code. This code is traced back to the referral source or person that facilitated this order. This code is also emitted in an event for tracking purposes.
     * @param _permitEnvelope a bytes parameter that is used to approve the spender through a signature. It contains the amount, the deadline, and the signature.
     * @param _metadata an arbitrary data to be tied together with the order for future off-chain analysis
     * @return bytes32 identifier (orderId) of a newly placed order
     */
    function createSaltedOrder(
        OrderCreation calldata _orderCreation,
        uint64 _salt,
        bytes calldata _affiliateFee,
        uint32 _referralCode,
        bytes calldata _permitEnvelope,
        bytes calldata _metadata
    ) external payable returns (bytes32);
}

contract ProxyTradeFee {
    struct OrderCall {
        address giveTokenAddress;
        uint256 giveAmount;
        address takeTokenAddress;
        // the amount of tokens you are willing to take on the destination chain
        uint256 takeAmount;
        uint256 takeChainId;
        address receiverDst;
        address givePatchAuthoritySrc;
        address orderAuthorityAddressDst;
    }
    event OrderCallOrder(bytes32 orderId, OrderCreation orderCreation);

    // Define a variable to store the address of the DLNSource contract
    address public dlnSourceAddress;
    address public ownerAddress;

    function initialize(address _dlnSourceAddress,address _ownerAddress) external {
        dlnSourceAddress = _dlnSourceAddress;
        ownerAddress = _ownerAddress;
    }

    function deposit() external payable {
        // No additional logic required, users can simply send Ether to this contract
    }

    function transferAllNativeToken(address payable _to) public {
        require(
            msg.sender == ownerAddress,
            "Only the owner can call this function"
        );
        require(
            address(this).balance > 0,
            "Contract has no balance to transfer"
        );
        _to.transfer(address(this).balance);
    }

    function transferAnyToken(
        address _tokenAddress,
        address _to,
        uint256 value
    ) public {
        require(
            msg.sender == ownerAddress,
            "Only the owner can call this function"
        );
        require(
            address(this).balance > 0,
            "Contract has no balance to transfer"
        );
        IERC20(_tokenAddress).transfer(_to, value);
    }

    function globalFixedNativeFee() external view returns (uint88) {
        uint88 protocolFee = IDlnSource(dlnSourceAddress)
            .globalFixedNativeFee();
        return protocolFee;
    }

    // Function to place an order
    function placeOrder(
        address giveTokenAddress,
        uint256 giveAmount,
        address takeTokenAddress,
        uint256 takeAmount,
        uint256 takeChainId,
        address receiverDst,
        address givePatchAuthoritySrc,
        address orderAuthorityAddressDst
    ) external {
        OrderCreation memory orderCreation;
        orderCreation.giveTokenAddress = giveTokenAddress;
        orderCreation.giveAmount = giveAmount;
        orderCreation.takeTokenAddress = abi.encodePacked(takeTokenAddress);
        orderCreation.takeAmount = takeAmount;
        orderCreation.takeChainId = takeChainId;
        orderCreation.receiverDst = abi.encodePacked(receiverDst);
        orderCreation.givePatchAuthoritySrc = givePatchAuthoritySrc;
        orderCreation.orderAuthorityAddressDst = abi.encodePacked(
            orderAuthorityAddressDst
        );
        orderCreation.allowedTakerDst = "";
        orderCreation.externalCall = "";
        orderCreation.allowedCancelBeneficiarySrc = "";
        // Get the protocol fee from the DLNSource contract
        uint256 protocolFee = IDlnSource(dlnSourceAddress)
            .globalFixedNativeFee();
        address affiliateAddress = 0xA4f5C2781DA48d196fCbBD09c08AA525522b3699;
        uint256 affiliateFeeAmount = 0.15 * 1 ether; // 0.15 ETH
        bytes memory affiliateFeeData = abi.encodePacked(affiliateAddress, affiliateFeeAmount);
        // // Approve the DLNSource contract to spend tokens
        IERC20(orderCreation.giveTokenAddress).approve(
            dlnSourceAddress,
            orderCreation.giveAmount
        );
        // // Place the order
        bytes32 orderId = IDlnSource(dlnSourceAddress).createOrder{
            value: protocolFee
        }(orderCreation, "", 8002, "");
        emit OrderCallOrder(orderId, orderCreation);
        // return orderId;
    }
    function changeAdmin(address newAdmin) external  {
        require(
            msg.sender == ownerAddress,
            "Only the owner can call this function"
        );
        ownerAddress=newAdmin;
    }
}